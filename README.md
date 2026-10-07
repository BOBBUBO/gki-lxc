# GKI Kernel Build with LXC/Docker Support

Build scripts for Android GKI kernel (android-12-5.10) with full LXC/Docker container support.

## Quick Start

### Local Build (Termux/Linux)

```bash
chmod +x build_gki_kernel.sh
./build_gki_kernel.sh
```

### GitHub Actions (CI/CD)

1. Push this repo to GitHub
2. Go to Actions tab → "Build GKI Kernel" → Run workflow
3. Select kernel branch and debug options
4. Download artifacts from workflow run

## What's Included

### LXC/Docker Kernel Configs Enabled

- **Namespaces**: UTS, IPC, PID, NET, USER, CGROUP
- **Cgroups**: devices, cpu, cpuacct, pids, freezer, cpuset, memory, blkio, bpf
- **Netfilter/iptables**: All matches, targets, NAT, connection tracking
- **IPVS**: Load balancing (RR, WRR, LC, WLC, etc.)
- **Bridge/VLAN**: Bridge netfilter, ebtables, 802.1Q
- **Traffic Control**: HTB, CBQ, FQ_CODEL, ingress, classifiers, actions
- **Virtual Networking**: veth, macvlan, ipvlan, geneve, GTP, VRF
- **Filesystems**: OverlayFS, FUSE, virtiofs, POSIX ACLs
- **Security**: SELinux, AppArmor, SMACK, YAMA, seccomp, BPF
- **Android**: Binder IPC, logger, lowmemorykiller
- **Debug**: Kprobes, ftrace, debugfs, lock debugging (optional)

## Output

- `out/dist/Image` - Kernel image
- `out/dist/*.dtb` - Device tree blobs
- `out/dist/*.ko` - Kernel modules
- `build.log` - Full build log

## Requirements

- Ubuntu 22.04+ / Termux / Debian-based Linux
- 50GB+ free disk space
- 8GB+ RAM (16GB+ recommended)
- Internet connection for toolchain/kernel download

## Customization

Edit `build_gki_kernel.sh` to:
- Change `KERNEL_VERSION` for different Android kernel branches
- Modify `LXC_CONFIGS` array to add/remove kernel options
- Adjust `JOBS` for parallel build count

## License

MIT