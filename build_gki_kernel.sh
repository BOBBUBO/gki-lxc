#!/bin/bash
set -euo pipefail

# GKI Kernel Build Script for android-12-5.10 with LXC/Docker Support
# Run this script in a Termux/Linux environment with sufficient storage

KERNEL_VERSION="android-12-5.10"
KERNEL_DIR="kernel"
OUT_DIR="out"
TOOLCHAIN_DIR="toolchain"
JOBS=$(nproc)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Required kernel configs for LXC/Docker
LXC_CONFIGS=(
    # Namespaces
    "CONFIG_NAMESPACES=y"
    "CONFIG_UTS_NS=y"
    "CONFIG_IPC_NS=y"
    "CONFIG_PID_NS=y"
    "CONFIG_NET_NS=y"
    "CONFIG_USER_NS=y"
    "CONFIG_CGROUPS=y"
    
    # Cgroups
    "CONFIG_CGROUP_DEVICE=y"
    "CONFIG_CGROUP_SCHED=y"
    "CONFIG_CGROUP_CPUACCT=y"
    "CONFIG_CGROUP_PIDS=y"
    "CONFIG_CGROUP_FREEZER=y"
    "CONFIG_CPUSETS=y"
    "CONFIG_MEMCG=y"
    "CONFIG_MEMCG_SWAP=y"
    "CONFIG_MEMCG_SWAP_ENABLED=y"
    "CONFIG_BLK_CGROUP=y"
    "CONFIG_CGROUP_BPF=y"
    "CONFIG_CGROUP_PERF=y"
    
    # Network
    "CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y"
    "CONFIG_NETFILTER_XT_MATCH_COMMENT=y"
    "CONFIG_NETFILTER_XT_MATCH_CONNTRACK=y"
    "CONFIG_NETFILTER_XT_MATCH_IPVS=y"
    "CONFIG_NETFILTER_XT_MATCH_LIMIT=y"
    "CONFIG_NETFILTER_XT_MATCH_MAC=y"
    "CONFIG_NETFILTER_XT_MATCH_MARK=y"
    "CONFIG_NETFILTER_XT_MATCH_MULTIPORT=y"
    "CONFIG_NETFILTER_XT_MATCH_OWNER=y"
    "CONFIG_NETFILTER_XT_MATCH_POLICY=y"
    "CONFIG_NETFILTER_XT_MATCH_PKTTYPE=y"
    "CONFIG_NETFILTER_XT_MATCH_QUOTA=y"
    "CONFIG_NETFILTER_XT_MATCH_RATEEST=y"
    "CONFIG_NETFILTER_XT_MATCH_REALM=y"
    "CONFIG_NETFILTER_XT_MATCH_RECENT=y"
    "CONFIG_NETFILTER_XT_MATCH_SCTP=y"
    "CONFIG_NETFILTER_XT_MATCH_SOCKET=y"
    "CONFIG_NETFILTER_XT_MATCH_STATE=y"
    "CONFIG_NETFILTER_XT_MATCH_STATISTIC=y"
    "CONFIG_NETFILTER_XT_MATCH_STRING=y"
    "CONFIG_NETFILTER_XT_MATCH_TCPMSS=y"
    "CONFIG_NETFILTER_XT_MATCH_TIME=y"
    "CONFIG_NETFILTER_XT_MATCH_U32=y"
    
    # NAT
    "CONFIG_NF_NAT=y"
    "CONFIG_NF_NAT_IPV4=y"
    "CONFIG_NF_NAT_IPV6=y"
    "CONFIG_NF_NAT_MASQUERADE_IPV4=y"
    "CONFIG_NF_NAT_MASQUERADE_IPV6=y"
    "CONFIG_NF_NAT_PROTO_DCCP=y"
    "CONFIG_NF_NAT_PROTO_GRE=y"
    "CONFIG_NF_NAT_PROTO_SCTP=y"
    "CONFIG_NF_NAT_PROTO_UDPLITE=y"
    "CONFIG_NF_NAT_FTP=y"
    "CONFIG_NF_NAT_IRC=y"
    "CONFIG_NF_NAT_SIP=y"
    "CONFIG_NF_NAT_TFTP=y"
    "CONFIG_NF_NAT_AMANDA=y"
    
    # Netfilter
    "CONFIG_NETFILTER=y"
    "CONFIG_NETFILTER_ADVANCED=y"
    "CONFIG_NETFILTER_INGRESS=y"
    "CONFIG_NETFILTER_NETLINK=y"
    "CONFIG_NETFILTER_NETLINK_ACCT=y"
    "CONFIG_NETFILTER_NETLINK_QUEUE=y"
    "CONFIG_NETFILTER_NETLINK_LOG=y"
    "CONFIG_NETFILTER_XTABLES=y"
    
    # IPVS
    "CONFIG_IP_VS=y"
    "CONFIG_IP_VS_IPV6=y"
    "CONFIG_IP_VS_PROTO_TCP=y"
    "CONFIG_IP_VS_PROTO_UDP=y"
    "CONFIG_IP_VS_PROTO_AH_ESP=y"
    "CONFIG_IP_VS_PROTO_ESP=y"
    "CONFIG_IP_VS_PROTO_AH=y"
    "CONFIG_IP_VS_PROTO_SCTP=y"
    "CONFIG_IP_VS_RR=y"
    "CONFIG_IP_VS_WRR=y"
    "CONFIG_IP_VS_LC=y"
    "CONFIG_IP_VS_WLC=y"
    "CONFIG_IP_VS_FO=y"
    "CONFIG_IP_VS_OVF=y"
    "CONFIG_IP_VS_LBLC=y"
    "CONFIG_IP_VS_LBLCR=y"
    "CONFIG_IP_VS_DH=y"
    "CONFIG_IP_VS_SH=y"
    "CONFIG_IP_VS_MH=y"
    "CONFIG_IP_VS_SED=y"
    "CONFIG_IP_VS_NQ=y"
    "CONFIG_IP_VS_FTP=y"
    "CONFIG_IP_VS_NFCT=y"
    "CONFIG_IP_VS_PE_SIP=y"
    
    # Netfilter Connection Tracking
    "CONFIG_NF_CONNTRACK=y"
    "CONFIG_NF_LOG_COMMON=y"
    "CONFIG_NF_LOG_NETDEV=y"
    "CONFIG_NF_CONNTRACK_MARK=y"
    "CONFIG_NF_CONNTRACK_SECMARK=y"
    "CONFIG_NF_CONNTRACK_ZONES=y"
    "CONFIG_NF_CONNTRACK_PROCFS=y"
    "CONFIG_NF_CONNTRACK_EVENTS=y"
    "CONFIG_NF_CONNTRACK_TIMEOUT=y"
    "CONFIG_NF_CONNTRACK_TIMESTAMP=y"
    "CONFIG_NF_CONNTRACK_LABELS=y"
    "CONFIG_NF_CT_PROTO_DCCP=y"
    "CONFIG_NF_CT_PROTO_GRE=y"
    "CONFIG_NF_CT_PROTO_SCTP=y"
    "CONFIG_NF_CT_PROTO_UDPLITE=y"
    "CONFIG_NF_CT_NETLINK=y"
    "CONFIG_NF_CT_NETLINK_TIMEOUT=y"
    "CONFIG_NF_CT_NETLINK_HELPER=y"
    "CONFIG_NETFILTER_XT_TARGET_CONNTRACK=y"
    "CONFIG_NETFILTER_XT_TARGET_CT=y"
    "CONFIG_NETFILTER_XT_TARGET_NOTRACK=y"
    
    # Bridge
    "CONFIG_BRIDGE=y"
    "CONFIG_BRIDGE_IGMP_SNOOPING=y"
    "CONFIG_BRIDGE_VLAN_FILTERING=y"
    "CONFIG_BRIDGE_NETFILTER=y"
    "CONFIG_BRIDGE_NF_EBTABLES=y"
    "CONFIG_EBTABLES=y"
    "CONFIG_EBT_BROUTE=y"
    "CONFIG_EBT_T_FILTER=y"
    "CONFIG_EBT_T_NAT=y"
    "CONFIG_EBT_802_3=y"
    "CONFIG_EBT_AMONG=y"
    "CONFIG_EBT_ARP=y"
    "CONFIG_EBT_IP=y"
    "CONFIG_EBT_IP6=y"
    "CONFIG_EBT_LIMIT=y"
    "CONFIG_EBT_MARK=y"
    "CONFIG_EBT_MARK_T=y"
    "CONFIG_EBT_NFLOG=y"
    "CONFIG_EBT_PKTTYPE=y"
    "CONFIG_EBT_STP=y"
    "CONFIG_EBT_VLAN=y"
    "CONFIG_EBT_ARPREPLY=y"
    
    # VLAN
    "CONFIG_VLAN_8021Q=y"
    "CONFIG_VLAN_8021Q_GVRP=y"
    "CONFIG_VLAN_8021Q_MVRP=y"
    
    # Network Scheduling
    "CONFIG_NET_SCHED=y"
    "CONFIG_NET_SCH_CBQ=y"
    "CONFIG_NET_SCH_HTB=y"
    "CONFIG_NET_SCH_HFSC=y"
    "CONFIG_NET_SCH_PRIO=y"
    "CONFIG_NET_SCH_MULTIQ=y"
    "CONFIG_NET_SCH_RED=y"
    "CONFIG_NET_SCH_SFB=y"
    "CONFIG_NET_SCH_SFQ=y"
    "CONFIG_NET_SCH_TEQL=y"
    "CONFIG_NET_SCH_TBF=y"
    "CONFIG_NET_SCH_GRED=y"
    "CONFIG_NET_SCH_DSMARK=y"
    "CONFIG_NET_SCH_NETEM=y"
    "CONFIG_NET_SCH_DRR=y"
    "CONFIG_NET_SCH_MQPRIO=y"
    "CONFIG_NET_SCH_CHOKE=y"
    "CONFIG_NET_SCH_QFQ=y"
    "CONFIG_NET_SCH_CODEL=y"
    "CONFIG_NET_SCH_FQ_CODEL=y"
    "CONFIG_NET_SCH_FQ=y"
    "CONFIG_NET_SCH_HHF=y"
    "CONFIG_NET_SCH_PIE=y"
    "CONFIG_NET_SCH_INGRESS=y"
    "CONFIG_NET_SCH_PLUG=y"
    "CONFIG_NET_SCH_DEFAULT=y"
    "CONFIG_DEFAULT_FQ_CODEL=y"
    
    # Classification
    "CONFIG_NET_CLS=y"
    "CONFIG_NET_CLS_BASIC=y"
    "CONFIG_NET_CLS_TCINDEX=y"
    "CONFIG_NET_CLS_ROUTE4=y"
    "CONFIG_NET_CLS_FW=y"
    "CONFIG_NET_CLS_U32=y"
    "CONFIG_NET_CLS_RSVP=y"
    "CONFIG_NET_CLS_RSVP6=y"
    "CONFIG_NET_CLS_FLOW=y"
    "CONFIG_NET_CLS_CGROUP=y"
    "CONFIG_NET_CLS_BPF=y"
    "CONFIG_NET_CLS_FLOWER=y"
    "CONFIG_NET_CLS_MATCHALL=y"
    "CONFIG_NET_EMATCH=y"
    "CONFIG_NET_EMATCH_STACK=32"
    "CONFIG_NET_EMATCH_CMP=y"
    "CONFIG_NET_EMATCH_NBYTE=y"
    "CONFIG_NET_EMATCH_U32=y"
    "CONFIG_NET_EMATCH_META=y"
    "CONFIG_NET_EMATCH_TEXT=y"
    "CONFIG_NET_EMATCH_CANID=y"
    "CONFIG_NET_EMATCH_IPSET=y"
    "CONFIG_NET_EMATCH_IPVT=y"
    
    # Actions
    "CONFIG_NET_ACT_POLICE=y"
    "CONFIG_NET_ACT_GACT=y"
    "CONFIG_GACT_PROB=y"
    "CONFIG_NET_ACT_MIRRED=y"
    "CONFIG_NET_ACT_SAMPLE=y"
    "CONFIG_NET_ACT_IPT=y"
    "CONFIG_NET_ACT_NAT=y"
    "CONFIG_NET_ACT_PEDIT=y"
    "CONFIG_NET_ACT_SIMP=y"
    "CONFIG_NET_ACT_SKBEDIT=y"
    "CONFIG_NET_ACT_CSUM=y"
    "CONFIG_NET_ACT_MPLS=y"
    "CONFIG_NET_ACT_VLAN=y"
    "CONFIG_NET_ACT_BPF=y"
    "CONFIG_NET_ACT_CONNMARK=y"
    "CONFIG_NET_ACT_CTINFO=y"
    "CONFIG_NET_ACT_SKBMOD=y"
    "CONFIG_NET_ACT_IFE=y"
    "CONFIG_NET_ACT_TUNNEL_KEY=y"
    "CONFIG_NET_ACT_CT=y"
    "CONFIG_NET_ACT_GATE=y"
    "CONFIG_NET_IFE_SKBMARK=y"
    "CONFIG_NET_IFE_SKBTCINDEX=y"
    "CONFIG_NET_IFE_SKBVLANID=y"
    "CONFIG_NET_IFE_SKBVLANPRIO=y"
    "CONFIG_NET_IFE_SKBMAC=y"
    "CONFIG_NET_IFE_SKBETHER=y"
    "CONFIG_NET_IFE_SKBIPV4=y"
    "CONFIG_NET_IFE_SKBIPV6=y"
    "CONFIG_NET_IFE_SKBTUN=y"
    "CONFIG_NET_IFE_SKBGENEVE=y"
    
    # Indirect actions
    "CONFIG_NET_SCH_FIFO=y"
    
    # Network Testing
    "CONFIG_NET_PKTGEN=y"
    "CONFIG_NET_TCPPROBE=y"
    "CONFIG_NET_DROP_MONITOR=y"
    
    # VPN
    "CONFIG_TUN=y"
    "CONFIG_VETH=y"
    "CONFIG_MACVLAN=y"
    "CONFIG_MACVTAP=y"
    "CONFIG_IPVLAN=y"
    "CONFIG_IPVTAP=y"
    "CONFIG_NET_FOU=y"
    "CONFIG_NET_FOU_IP_TUNNELS=y"
    "CONFIG_NET_GENEVE=y"
    "CONFIG_NET_GTP=y"
    "CONFIG_NET_MPLS_GSO=y"
    "CONFIG_NET_NSH=y"
    "CONFIG_NET_VRF=y"
    "CONFIG_NET_VRF_DEV=y"
    
    # Checkpoint/Restore
    "CONFIG_CHECKPOINT_RESTORE=y"
    
    # Overlay FS
    "CONFIG_OVERLAY_FS=y"
    "CONFIG_OVERLAY_FS_REDIRECT_DIR=y"
    "CONFIG_OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW=y"
    "CONFIG_OVERLAY_FS_INDEX=y"
    "CONFIG_OVERLAY_FS_XINO_AUTO=y"
    "CONFIG_OVERLAY_FS_METACOPY=y"
    
    # Filesystems
    "CONFIG_FS_POSIX_ACL=y"
    "CONFIG_FSNOTIFY=y"
    "CONFIG_DNOTIFY=y"
    "CONFIG_INOTIFY_USER=y"
    "CONFIG_FANOTIFY=y"
    "CONFIG_FANOTIFY_ACCESS_PERMISSIONS=y"
    "CONFIG_QUOTA=y"
    "CONFIG_QUOTA_NETLINK_INTERFACE=y"
    "CONFIG_QUOTACTL=y"
    "CONFIG_AUTOFS4_FS=y"
    "CONFIG_FUSE_FS=y"
    "CONFIG_CUSE=y"
    "CONFIG_VIRTIO_FS=y"
    
    # Security
    "CONFIG_SECURITY=y"
    "CONFIG_SECURITY_NETWORK=y"
    "CONFIG_SECURITY_PATH=y"
    "CONFIG_SECURITY_SELINUX=y"
    "CONFIG_SECURITY_SELINUX_BOOTPARAM=y"
    "CONFIG_SECURITY_SELINUX_DEVELOP=y"
    "CONFIG_SECURITY_SELINUX_AVC_STATS=y"
    "CONFIG_SECURITY_SELINUX_CHECKREQPROT_VALUE=1"
    "CONFIG_SECURITY_SMACK=y"
    "CONFIG_SECURITY_TOMOYO=y"
    "CONFIG_SECURITY_APPARMOR=y"
    "CONFIG_SECURITY_APPARMOR_HASH=y"
    "CONFIG_SECURITY_APPARMOR_HASH_DEFAULT=y"
    "CONFIG_SECURITY_YAMA=y"
    "CONFIG_SECURITY_SAFESETID=y"
    "CONFIG_SECURITY_LOCKDOWN_LSM=y"
    "CONFIG_LSM_MMAP_MIN_ADDR=65536"
    "CONFIG_HAVE_HARDENED_USERCOPY_ALLOCATOR=y"
    "CONFIG_HARDENED_USERCOPY=y"
    "CONFIG_HARDENED_USERCOPY_FALLBACK=y"
    "CONFIG_FORTIFY_SOURCE=y"
    
    # Key retention
    "CONFIG_KEYS=y"
    "CONFIG_KEYS_REQUEST_CACHE=y"
    "CONFIG_PERSISTENT_KEYRINGS=y"
    "CONFIG_BIG_KEYS=y"
    "CONFIG_TRUSTED_KEYS=y"
    "CONFIG_ENCRYPTED_KEYS=y"
    "CONFIG_KEY_DH_OPERATIONS=y"
    
    # BPF
    "CONFIG_BPF=y"
    "CONFIG_BPF_SYSCALL=y"
    "CONFIG_BPF_JIT=y"
    "CONFIG_BPF_JIT_ALWAYS_ON=y"
    "CONFIG_BPF_LSM=y"
    "CONFIG_BPF_PRELOAD=y"
    "CONFIG_BPF_PRELOAD_UMD=y"
    "CONFIG_HAVE_EBPF_JIT=y"
    
    # Seccomp
    "CONFIG_SECCOMP=y"
    "CONFIG_SECCOMP_FILTER=y"
    
    # Device Drivers
    "CONFIG_DEVTMPFS=y"
    "CONFIG_DEVTMPFS_MOUNT=y"
    "CONFIG_STANDALONE=y"
    "CONFIG_PREVENT_FIRMWARE_BUILD=y"
    
    # Block devices
    "CONFIG_BLK_DEV_LOOP=y"
    "CONFIG_BLK_DEV_LOOP_MIN_COUNT=8"
    "CONFIG_BLK_DEV_NBD=y"
    "CONFIG_BLK_DEV_RAM=y"
    "CONFIG_BLK_DEV_RAM_COUNT=16"
    "CONFIG_BLK_DEV_RAM_SIZE=16384"
    
    # SCSI
    "CONFIG_SCSI=y"
    "CONFIG_SCSI_DMA=y"
    "CONFIG_SCSI_MQ_DEFAULT=y"
    "CONFIG_SCSI_PROC_FS=y"
    "CONFIG_BLK_DEV_SD=y"
    
    # NVMe
    "CONFIG_NVME_CORE=y"
    "CONFIG_BLK_DEV_NVME=y"
    
    # Input
    "CONFIG_INPUT=y"
    "CONFIG_INPUT_EVDEV=y"
    
    # Android
    "CONFIG_ANDROID=y"
    "CONFIG_ANDROID_BINDER_IPC=y"
    "CONFIG_ANDROID_BINDERFS=y"
    "CONFIG_ANDROID_BINDER_DEVICES=\"binder,hwbinder,vndbinder\""
    "CONFIG_ANDROID_BINDER_IPC_SELFTEST=y"
    
    # Logger
    "CONFIG_ANDROID_LOGGER=y"
    
    # Timed output
    "CONFIG_ANDROID_TIMED_OUTPUT=y"
    "CONFIG_ANDROID_TIMED_GPIO=y"
    
    # Low Memory Killer
    "CONFIG_ANDROID_LOW_MEMORY_KILLER=y"
    "CONFIG_ANDROID_LOW_MEMORY_KILLER_AUTODETECT_OOM_ADJ_VALUES=y"
    
    # IPC
    "CONFIG_SYSVIPC=y"
    "CONFIG_SYSVIPC_SYSCTL=y"
    "CONFIG_POSIX_MQUEUE=y"
    "CONFIG_POSIX_MQUEUE_SYSCTL=y"
    "CONFIG_CROSS_MEMORY_ATTACH=y"
    "CONFIG_HAVE_ARCH_SECCOMP_FILTER=y"
    "CONFIG_SECCOMP_FILTER=y"
    
    # Audit
    "CONFIG_AUDIT=y"
    "CONFIG_AUDITSYSCALL=y"
    "CONFIG_AUDIT_WATCH=y"
    "CONFIG_AUDIT_TREE=y"
    
    # Kprobes
    "CONFIG_KPROBES=y"
    "CONFIG_KRETPROBES=y"
    "CONFIG_UPROBES=y"
    "CONFIG_HAVE_KPROBES=y"
    "CONFIG_HAVE_KRETPROBES=y"
    "CONFIG_HAVE_UPROBES=y"
    
    # Ftrace
    "CONFIG_FUNCTION_TRACER=y"
    "CONFIG_FUNCTION_GRAPH_TRACER=y"
    "CONFIG_DYNAMIC_FTRACE=y"
    "CONFIG_DYNAMIC_FTRACE_WITH_REGS=y"
    "CONFIG_FTRACE_MCOUNT_RECORD=y"
    "CONFIG_TRACEPOINT_BENCHMARK=y"
    "CONFIG_RING_BUFFER=y"
    "CONFIG_EVENT_TRACING=y"
    "CONFIG_CONTEXT_SWITCH_TRACER=y"
    "CONFIG_RING_BUFFER_ALLOW_SWAP=y"
    "CONFIG_TRACING=y"
    "CONFIG_GENERIC_TRACER=y"
    "CONFIG_TRACING_SUPPORT=y"
    "CONFIG_FTRACE=y"
    "CONFIG_BRANCH_PROFILE_NONE=y"
    "CONFIG_BLK_DEV_IO_TRACE=y"
    "CONFIG_KPROBE_EVENTS=y"
    "CONFIG_UPROBE_EVENTS=y"
    "CONFIG_BPF_EVENTS=y"
    "CONFIG_DYNAMIC_EVENTS=y"
    "CONFIG_PROBE_EVENTS=y"
    "CONFIG_DYNAMIC_FTRACE=y"
    "CONFIG_FUNCTION_PROFILER=y"
    "CONFIG_STACK_TRACER=y"
    "CONFIG_SCHED_TRACER=y"
    "CONFIG_HIST_TRIGGERS=y"
    
    # Debug
    "CONFIG_DEBUG_INFO=y"
    "CONFIG_DEBUG_INFO_DWARF4=y"
    "CONFIG_DEBUG_INFO_BTF=y"
    "CONFIG_DEBUG_KERNEL=y"
    "CONFIG_DEBUG_MISC=y"
    "CONFIG_DEBUG_FS=y"
    "CONFIG_DEBUG_KMEMLEAK=y"
    "CONFIG_DEBUG_KMEMLEAK_EARLY_LOG_SIZE=400"
    "CONFIG_DEBUG_KMEMLEAK_DEFAULT_OFF=y"
    "CONFIG_DEBUG_STACK_USAGE=y"
    "CONFIG_DEBUG_VM=y"
    "CONFIG_DEBUG_VIRTUAL=y"
    "CONFIG_DEBUG_MEMORY_INIT=y"
    "CONFIG_DEBUG_PER_CPU_MAPS=y"
    "CONFIG_DEBUG_HIGHMEM=y"
    "CONFIG_DEBUG_LIST=y"
    "CONFIG_DEBUG_SG=y"
    "CONFIG_DEBUG_NOTIFIERS=y"
    "CONFIG_DEBUG_CREDENTIALS=y"
    "CONFIG_DEBUG_FORCE_WEAK_PER_CPU=y"
    "CONFIG_DEBUG_LOCKING_API_SELFTESTS=y"
    "CONFIG_DEBUG_RT_MUTEXES=y"
    "CONFIG_DEBUG_SPINLOCK=y"
    "CONFIG_DEBUG_MUTEXES=y"
    "CONFIG_DEBUG_WW_MUTEX_SLOWPATH=y"
    "CONFIG_DEBUG_RWSEMS=y"
    "CONFIG_DEBUG_LOCK_ALLOC=y"
    "CONFIG_DEBUG_ATOMIC_SLEEP=y"
    "CONFIG_DEBUG_LOCKDEP=y"
    "CONFIG_DEBUG_LIST=y"
    "CONFIG_DEBUG_PI_LIST=y"
    "CONFIG_DEBUG_SG=y"
    "CONFIG_DEBUG_NOTIFIERS=y"
    "CONFIG_DEBUG_CREDENTIALS=y"
    "CONFIG_DEBUG_FORCE_WEAK_PER_CPU=y"
    "CONFIG_DEBUG_PER_CPU_MAPS=y"
    "CONFIG_DEBUG_HIGHMEM=y"
    "CONFIG_DEBUG_OBJECTS=y"
    "CONFIG_DEBUG_OBJECTS_SELFTEST=y"
    "CONFIG_DEBUG_OBJECTS_FREE=y"
    "CONFIG_DEBUG_OBJECTS_TIMERS=y"
    "CONFIG_DEBUG_OBJECTS_WORK=y"
    "CONFIG_DEBUG_OBJECTS_RCU_HEAD=y"
    "CONFIG_DEBUG_OBJECTS_PERCPU_COUNTER=y"
    "CONFIG_DEBUG_OBJECTS_ENABLE_DEFAULT=1"
    "CONFIG_DEBUG_SLAB=y"
    "CONFIG_DEBUG_SLAB_LEAK=y"
    "CONFIG_SLUB_DEBUG_ON=y"
    "CONFIG_SLUB_STATS=y"
    "CONFIG_HAVE_DEBUG_KMEMLEAK=y"
    "CONFIG_DEBUG_KMEMLEAK=y"
    "CONFIG_DEBUG_KMEMLEAK_EARLY_LOG_SIZE=400"
    "CONFIG_DEBUG_KMEMLEAK_DEFAULT_OFF=y"
    "CONFIG_DEBUG_STACK_USAGE=y"
    "CONFIG_DEBUG_VM=y"
    "CONFIG_DEBUG_VIRTUAL=y"
    "CONFIG_DEBUG_MEMORY_INIT=y"
    "CONFIG_DEBUG_PER_CPU_MAPS=y"
    "CONFIG_DEBUG_HIGHMEM=y"
    
    # Lock debugging
    "CONFIG_PROVE_LOCKING=y"
    "CONFIG_LOCK_STAT=y"
    "CONFIG_DEBUG_RT_MUTEXES=y"
    "CONFIG_DEBUG_SPINLOCK=y"
    "CONFIG_DEBUG_MUTEXES=y"
    "CONFIG_DEBUG_WW_MUTEX_SLOWPATH=y"
    "CONFIG_DEBUG_RWSEMS=y"
    "CONFIG_DEBUG_LOCK_ALLOC=y"
    "CONFIG_DEBUG_ATOMIC_SLEEP=y"
    "CONFIG_DEBUG_LOCKDEP=y"
    "CONFIG_DEBUG_LIST=y"
    "CONFIG_DEBUG_PI_LIST=y"
    "CONFIG_DEBUG_SG=y"
    "CONFIG_DEBUG_NOTIFIERS=y"
    "CONFIG_DEBUG_CREDENTIALS=y"
    "CONFIG_DEBUG_FORCE_WEAK_PER_CPU=y"
    "CONFIG_DEBUG_PER_CPU_MAPS=y"
    "CONFIG_DEBUG_HIGHMEM=y"
)

install_dependencies() {
    log "Installing dependencies..."
    if command -v apt &>/dev/null; then
        apt update && apt install -y \
            git build-essential libssl-dev libncurses5-dev \
            bison flex libelf-dev bc cpio rsync \
            python3 python3-pip python3-setuptools \
            device-tree-compiler lz4 lzop \
            ccache pigz
    elif command -v pkg &>/dev/null; then
        pkg update && pkg install -y \
            git build-essential libssl-dev libncurses-dev \
            bison flex libelf-dev bc cpio rsync \
            python3 python3-pip \
            device-tree-compiler lz4 lzop \
            ccache pigz clang binutils
    else
        warn "Unknown package manager. Please install dependencies manually."
    fi
}

setup_toolchain() {
    log "Setting up toolchain..."
    mkdir -p "$TOOLCHAIN_DIR"
    cd "$TOOLCHAIN_DIR"
    
    if [[ ! -d "aarch64-linux-android-4.9" ]]; then
        log "Downloading AOSP prebuilt toolchain..."
        git clone --depth 1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
    fi
    
    if [[ ! -d "arm-linux-androideabi-4.9" ]]; then
        log "Downloading 32-bit toolchain..."
        git clone --depth 1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9
    fi
    
    export PATH="$PWD/aarch64-linux-android-4.9/bin:$PWD/arm-linux-androideabi-4.9/bin:$PATH"
    export CROSS_COMPILE=aarch64-linux-android-
    export CROSS_COMPILE_ARM32=arm-linux-androideabi-
    export ARCH=arm64
    export SUBARCH=arm64
    cd ..
}

clone_kernel() {
    log "Cloning kernel source..."
    if [[ ! -d "$KERNEL_DIR" ]]; then
        git clone --depth 1 -b "$KERNEL_VERSION" \
            https://android.googlesource.com/kernel/common "$KERNEL_DIR"
    else
        log "Kernel directory exists, updating..."
        cd "$KERNEL_DIR"
        git fetch --depth 1 origin "$KERNEL_VERSION"
        git checkout FETCH_HEAD
        cd ..
    fi
}

apply_gki_config() {
    log "Applying GKI configuration..."
    cd "$KERNEL_DIR"
    
    # Start with defconfig
    make O=../"$OUT_DIR" gki_defconfig
    
    # Apply LXC/Docker configs
    log "Applying LXC/Docker kernel configs..."
    for config in "${LXC_CONFIGS[@]}"; do
        echo "$config" >> ../"$OUT_DIR"/.config
    done
    
    # Ensure modules are enabled
    echo "CONFIG_MODULES=y" >> ../"$OUT_DIR"/.config
    echo "CONFIG_MODULE_UNLOAD=y" >> ../"$OUT_DIR"/.config
    echo "CONFIG_MODVERSIONS=y" >> ../"$OUT_DIR"/.config
    echo "CONFIG_MODULE_SRCVERSION_ALL=y" >> ../"$OUT_DIR"/.config
    echo "CONFIG_MODULE_SIG=y" >> ../"$OUT_DIR"/.config
    echo "CONFIG_MODULE_SIG_ALL=y" >> ../"$OUT_DIR"/.config
    echo "CONFIG_MODULE_SIG_SHA512=y" >> ../"$OUT_DIR"/.config
    echo "CONFIG_MODULE_SIG_KEY=\"certs/signing_key.pem\"" >> ../"$OUT_DIR"/.config
    echo "CONFIG_SYSTEM_TRUSTED_KEYRING=y" >> ../"$OUT_DIR"/.config
    echo "CONFIG_SYSTEM_EXTRA_CERTIFICATE=y" >> ../"$OUT_DIR"/.config
    
    # Re-run olddefconfig to resolve dependencies
    make O=../"$OUT_DIR" olddefconfig
    cd ..
}

build_kernel() {
    log "Building kernel..."
    cd "$KERNEL_DIR"
    
    # Build with ccache if available
    if command -v ccache &>/dev/null; then
        export CC="ccache $CROSS_COMPILE$CC"
        export CCACHE_DIR="../ccache"
        mkdir -p "$CCACHE_DIR"
    fi
    
    make O=../"$OUT_DIR" \
        ARCH=arm64 \
        CROSS_COMPILE=aarch64-linux-android- \
        CROSS_COMPILE_ARM32=arm-linux-androideabi- \
        -j"$JOBS" \
        2>&1 | tee ../build.log
    
    cd ..
}

package_kernel() {
    log "Packaging kernel..."
    mkdir -p "$OUT_DIR/dist"
    
    # Copy Image and dtbs
    find "$OUT_DIR" -name "Image" -o -name "*.dtb" | while read -r file; do
        cp "$file" "$OUT_DIR/dist/"
    done
    
    # Create boot.img header if needed
    if [[ -f "$OUT_DIR/arch/arm64/boot/Image" ]]; then
        cp "$OUT_DIR/arch/arm64/boot/Image" "$OUT_DIR/dist/Image"
    fi
    
    log "Kernel built successfully!"
    log "Output files in: $OUT_DIR/dist/"
    ls -la "$OUT_DIR/dist/"
}

main() {
    log "Starting GKI kernel build for $KERNEL_VERSION with LXC/Docker support"
    
    install_dependencies
    setup_toolchain
    clone_kernel
    apply_gki_config
    build_kernel
    package_kernel
    
    log "Build complete!"
}

main "$@"