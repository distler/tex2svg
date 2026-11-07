#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Landlock-confined exec helper (Linux). Applies an unprivileged Landlock
# ruleset to itself, then execs the given command, which inherits the
# restriction across exec. Reads are confined to the given read-only paths
# plus the job directory and /dev; writes are confined to the job directory
# (and /dev, for /dev/null). No namespaces, privileges, or seccomp changes are
# needed, which is why this works where bubblewrap cannot (user namespaces
# disabled). See lib/sandbox.rb for how it is invoked.
#
# Usage: ruby landlock_exec.rb <rw_dir> <ro_path>... -- <command> [args...]
#
# Fails closed: if the Landlock ruleset cannot be built and enforced, the
# helper exits without running the command rather than running it unconfined.
# Sandbox#backend probes availability before this helper is ever used, so that
# path should not be reached in practice.

require 'fiddle'

LIBC = Fiddle.dlopen(nil)
SYSCALL = Fiddle::Function.new(LIBC['syscall'], [Fiddle::TYPE_LONG] * 6, Fiddle::TYPE_LONG)
PRCTL  = Fiddle::Function.new(LIBC['prctl'],  [Fiddle::TYPE_INT] * 5,  Fiddle::TYPE_INT)
OPEN   = Fiddle::Function.new(LIBC['open'],   [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)

# syscall() is variadic; Fiddle needs a fixed arity, so always pass six longs.
def sys(nr, *args)
  args += [0] * (5 - args.size)
  SYSCALL.call(nr, *args)
end

# Syscall numbers for landlock_{create_ruleset,add_rule,restrict_self}. These
# are identical on x86_64, arm64 and the other asm-generic architectures that
# matter for deployment (Debian amd64, Heroku amd64).
NR_CREATE  = 444
NR_ADD     = 445
NR_RESTRICT = 446

PR_SET_NO_NEW_PRIVS = 38
O_PATH_CLOEXEC = 0x200000 | 0x80000
RULE_PATH_BENEATH = 1

# FS access-right bits (uapi/linux/landlock.h), with the ABI version each was
# introduced in. We mask the rights we request to those the running kernel's
# ABI supports, so the ruleset degrades cleanly on older kernels.
FS_BITS = {
  execute: [1 << 0, 1], write_file: [1 << 1, 1], read_file: [1 << 2, 1],
  read_dir: [1 << 3, 1], remove_dir: [1 << 4, 1], remove_file: [1 << 5, 1],
  make_char: [1 << 6, 1], make_dir: [1 << 7, 1], make_reg: [1 << 8, 1],
  make_sock: [1 << 9, 1], make_fifo: [1 << 10, 1], make_block: [1 << 11, 1],
  make_sym: [1 << 12, 1], refer: [1 << 13, 2], truncate: [1 << 14, 3],
  ioctl_dev: [1 << 15, 5]
}.freeze

def die(msg)
  warn "landlock_exec: #{msg}"
  exit 1
end

# --probe: report whether Landlock is usable here (available and not blocked by
# seccomp). Exit 0 if a ruleset can be created, non-zero otherwise. Used by
# Sandbox#backend to decide whether to enable this backend.
if ARGV == ['--probe']
  abi = sys(NR_CREATE, 0, 0, 1)
  exit(abi > 0 ? 0 : 1)
end

# Parse argv: rw_dir, ro paths..., "--", command...
sep = ARGV.index('--') or die('missing -- separator')
paths = ARGV[0...sep]
command = ARGV[(sep + 1)..] || []
die('no command given') if command.empty?
rw_dir = paths.shift or die('no rw dir given')
ro_dirs = paths

abi = sys(NR_CREATE, 0, 0, 1)   # LANDLOCK_CREATE_RULESET_VERSION
die("landlock unavailable (abi=#{abi})") if abi <= 0

supported = FS_BITS.each_value.select { |(_, since)| since <= abi }.sum { |(bit, _)| bit }
ro_access = FS_BITS.values_at(:execute, :read_file, :read_dir).sum { |(bit, _)| bit } & supported
# Everything a job needs to create/update/remove its own files, masked to ABI.
rw_access = FS_BITS.values_at(:execute, :read_file, :read_dir, :write_file,
                              :remove_dir, :remove_file, :make_dir, :make_reg,
                              :make_sym, :make_fifo, :truncate).sum { |(bit, _)| bit } & supported
dev_access = FS_BITS.values_at(:read_file, :write_file, :read_dir).sum { |(bit, _)| bit } & supported

# Create the ruleset governing the full set of rights we will grant per-path.
attr = [rw_access].pack('Q<')   # struct { __u64 handled_access_fs; } (size 8)
ruleset = sys(NR_CREATE, Fiddle::Pointer[attr], attr.bytesize, 0)
die("create_ruleset failed (errno #{Fiddle.last_error})") if ruleset < 0

add_rule = lambda do |path, access|
  return unless File.exist?(path)
  fd = OPEN.call("#{path}\0", O_PATH_CLOEXEC)
  return if fd < 0   # unreadable/typo'd path: just don't grant it
  # struct landlock_path_beneath_attr { __u64 allowed_access; __s32 parent_fd; } __packed
  pb = [access].pack('Q<') + [fd].pack('l<')
  r = sys(NR_ADD, ruleset, RULE_PATH_BENEATH, Fiddle::Pointer[pb], 0)
  die("add_rule #{path} failed (errno #{Fiddle.last_error})") if r != 0
end

ro_dirs.uniq.each { |d| add_rule.call(d, ro_access) }
add_rule.call('/dev', dev_access)
add_rule.call(rw_dir, rw_access)

die('prctl(NO_NEW_PRIVS) failed') if PRCTL.call(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) != 0
die("restrict_self failed (errno #{Fiddle.last_error})") if sys(NR_RESTRICT, ruleset, 0) != 0

# Keep scratch writes inside the one writable location.
ENV['TMPDIR'] = rw_dir

exec(*command)
