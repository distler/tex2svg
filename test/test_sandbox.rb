$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'test/unit'
require 'tmpdir'
require 'open3'
require 'sandbox'

# Smoke test for the OS-level confinement (lib/sandbox.rb). When a backend is
# active (Landlock on Linux, sandbox-exec on macOS) it asserts that a command
# wrapped by Sandbox.wrap can read/write inside the job directory but cannot
# read a file outside it. On a host with no backend (passthrough) there is
# nothing to confine, so the confinement assertions are omitted rather than
# failing.
class TestSandbox < Test::Unit::TestCase
  # A read-only set big enough to run /bin/sh and /bin/cat on either platform.
  def ro
    Sandbox.ro_paths(pdflatex: '/usr/bin/true', pdf2svg: '/usr/bin/true')
  end

  def run_wrapped(cmd, job)
    argv = Sandbox.wrap(cmd, ro: ro, rw: job, enabled: true)
    out, status = Open3.capture2e(*argv)
    [out, status]
  end

  # Like Dir.mktmpdir but yields the *canonical* path. On macOS the temp dir is
  # under /var/folders, and /var is a symlink into /private; using the resolved
  # path keeps the command from traversing that symlink at runtime (which the
  # sandbox does not grant), matching how the real app's tmp dir (under the repo)
  # behaves. A no-op where the temp path has no symlinks.
  def mktmp
    Dir.mktmpdir { |d| yield File.realpath(d) }
  end

  def test_backend_is_known
    # backend is either a supported name or nil (passthrough); never a surprise.
    assert_include([nil, 'landlock', 'sandbox-exec'], Sandbox.backend)
  end

  def test_reads_and_writes_inside_job_dir_are_allowed
    omit 'no OS sandbox backend active here (passthrough)' if Sandbox.backend.nil?
    mktmp do |job|
      File.write(File.join(job, 'in.txt'), "INSIDE\n")
      out, status = run_wrapped("cat #{job}/in.txt && echo OUT > #{job}/out.txt", job)
      assert status.success?, "expected success inside job dir, got: #{out}"
      assert_match(/INSIDE/, out)
      assert_equal("OUT\n", File.read(File.join(job, 'out.txt')))
    end
  end

  def test_read_outside_job_dir_is_blocked
    omit 'no OS sandbox backend active here (passthrough)' if Sandbox.backend.nil?
    mktmp do |job|
      mktmp do |elsewhere|            # a directory NOT granted to the sandbox
        secret = File.join(elsewhere, 'secret.txt')
        File.write(secret, "TOP-SECRET\n")
        out, status = run_wrapped("cat #{secret}", job)
        assert !status.success?, "read outside job dir should fail, but succeeded: #{out}"
        assert_no_match(/TOP-SECRET/, out, 'secret contents leaked through the sandbox')
      end
    end
  end

  def test_write_outside_job_dir_is_blocked
    omit 'no OS sandbox backend active here (passthrough)' if Sandbox.backend.nil?
    mktmp do |job|
      mktmp do |elsewhere|
        target = File.join(elsewhere, 'planted.txt')
        _out, status = run_wrapped("echo pwned > #{target}", job)
        assert !status.success?, 'write outside job dir should fail'
        assert !File.exist?(target), 'a file was planted outside the job dir'
      end
    end
  end
end
