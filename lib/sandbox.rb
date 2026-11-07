require 'rbconfig'

# OS-level filesystem confinement for the pdflatex/pdf2svg pipeline.
#
# As of TeX Live 2026 kpathsea's openin_any no longer restricts reading
# (kpathsea 6.4.2: the value "no longer has any effect ... now consider any
# filename to be ok for reading"). So we sandbox the typesetting process at the
# OS level: forbidden files are simply absent from its filesystem view,
# independent of anything TeX, kpathsea or PGF does.
#
#   Linux  -> Landlock (via lib/landlock_exec.rb): an unprivileged, namespace-
#             free LSM the process applies to itself and that is inherited across
#             exec. It only needs a kernel >= 5.13 (Landlock ABI >= 1).
#   macOS  -> sandbox-exec: an SBPL profile with the same read/write scope.
#   else   -> no OS sandbox; the inner defences still apply (sanitizer
#             allow-list, plot-file/gnuplot neutralization in the template,
#             --no-shell-escape, and openout_any=p, which still works).
#
# The backend is used only if it is present AND a start-up probe shows it can
# actually run here (e.g. the kernel offers Landlock and seccomp does not block
# its syscalls); otherwise the pipeline falls back to a plain shell so it keeps
# working rather than breaking.
module Sandbox
  module_function

  RUBY   = RbConfig.ruby
  HELPER = File.join(__dir__, 'landlock_exec.rb')

  # Where libcairo (needed by pdf2svg) and the system libraries/loader live.
  DARWIN_LIBS = %w[
    /usr /System /Library /bin /sbin /usr/local/bin
    /opt/sw/lib /opt/local/lib /usr/local/lib /opt/homebrew/lib /opt/X11/lib
    /private/var/db/timezone
  ].freeze
  LINUX_LIBS = %w[/usr /bin /lib /lib64 /etc/fonts /etc/alternatives].freeze

  def darwin?
    !!(RbConfig::CONFIG['host_os'] =~ /darwin/)
  end

  def linux?
    !!(RbConfig::CONFIG['host_os'] =~ /linux/)
  end

  # Name of a working backend for this platform, or nil. Memoized: the probe
  # runs a trivial check once and caches whether it succeeded. On Linux the
  # Landlock helper's --probe mode confirms the syscall is available and not
  # blocked by seccomp.
  def backend
    return @backend if defined?(@backend)
    @backend =
      if darwin? && which('sandbox-exec') && probe('sandbox-exec', '-p', '(version 1)(allow default)', 'true')
        'sandbox-exec'
      elsif linux? && probe(RUBY, HELPER, '--probe')
        'landlock'
      end
  end

  # Read-only paths the pipeline needs: the TeX trees (asked of kpathsea so we
  # follow the real install, including per-user TEXMFVAR/TEXMFCONFIG that live
  # under $HOME on macOS), the platform library dirs, and the directories of
  # the configured binaries (pdf2svg is often a separate install).
  def ro_paths(pdflatex:, pdf2svg:)
    kps = File.join(File.dirname(pdflatex), 'kpsewhich')
    kps = 'kpsewhich' unless File.executable?(kps)
    # Several of these resolve to a colon-separated search list rather than a
    # single directory (e.g. TEXMFCNF), and entries can carry kpathsea's "!!"
    # (ls-R only) prefix and "//" (recurse) suffix. Split and strip both.
    trees = %w[TEXMFDIST TEXMFMAIN TEXMFLOCAL TEXMFVAR TEXMFCONFIG TEXMFHOME
               TEXMFSYSVAR TEXMFSYSCONFIG TEXMFCNF]
            .flat_map { |v| `#{kps} -var-value=#{v} 2>/dev/null`.strip.split(File::PATH_SEPARATOR) }
            .map { |p| p.sub(/\A!!/, '').sub(%r{//+\z}, '') }
    libs = darwin? ? DARWIN_LIBS : LINUX_LIBS
    bins = [pdflatex, pdf2svg].map { |b| File.dirname(b) }
    # Absolute paths only: this drops kpathsea's "." element (the job dir is
    # bound read-write separately) and any blank entries.
    (trees + libs + bins).select { |p| p && p.start_with?('/') }.uniq
  end

  # Wrap shell command `inner` so it can only read `ro` and read/write `rw`.
  # Returns an argv array for Kernel#system. Falls back to a plain shell when
  # `enabled` is false or no working backend is present.
  def wrap(inner, ro:, rw:, enabled: true)
    return ['sh', '-c', inner] unless enabled
    case backend
    when 'landlock'     then [RUBY, HELPER, rw, *ro, '--', 'sh', '-c', inner]
    when 'sandbox-exec' then sandbox_exec(inner, ro, rw)
    else ['sh', '-c', inner]
    end
  end

  def sandbox_exec(inner, ro, rw)
    reads = ro.map { |p| "(subpath #{sbpl(p)})" }.join(' ')
    # The job dir needs read as well as write: pdflatex reads its own input
    # .tex and intermediate files from it. (literal "/") lets the shell/loader
    # list the root directory on start-up (top-level names only); neither grants
    # any other subtree, so reads under /Users, /etc, etc. remain denied unless
    # separately allow-listed above. system-info is pdftex's free-space check.
    profile = <<~SB
      (version 1)
      (deny default)
      (allow process-exec*)
      (allow process-fork)
      (allow sysctl-read)
      (allow system-info)
      (allow file-read-metadata)
      (allow file-read* #{reads} (subpath #{sbpl(rw)}) (literal "/") (literal "/dev/null") (literal "/dev/urandom") (literal "/dev/random"))
      (allow file-write* (subpath #{sbpl(rw)}) (literal "/dev/null"))
      (deny network*)
    SB
    ['sandbox-exec', '-p', profile, 'sh', '-c', inner]
  end

  # Quote a path as an SBPL string literal. Paths here are install/config
  # locations, not user input, but quote defensively all the same.
  def sbpl(path)
    '"' + path.gsub('\\', '\\\\\\\\').gsub('"', '\\"') + '"'
  end

  def probe(*argv)
    system(*argv, out: File::NULL, err: File::NULL)
  rescue StandardError
    false
  end

  def which(cmd)
    ENV['PATH'].to_s.split(File::PATH_SEPARATOR).any? do |d|
      File.executable?(File.join(d, cmd))
    end
  end
end
