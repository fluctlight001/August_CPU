#include "kernel/interrupt.h"
#include "kernel/register.h"
#include "kernel/scheduler.h"
#include "kernel/self_test.h"
#include "kernel/memory/kernel_stack.h"
#include "lib/stl/string.h"
#include "kernel/fs/IFS.h"
#include "kernel/fs/VFS.h"
#include "kernel/Test.h"
#include "lib/stl/vector.h"
#include "kernel/memory/memory.h"
#include "kernel/memory/Heap.h"
#include "kernel/fs/file_describer.h"
#include "lib/stl/Trie.h"
#include "lib/stl/PathUtil.h"
#include "lib/stl/RefCountPtr.h"
#include "lib/stl/UniquePtr.h"
#include "lib/stl/PageTableUtil.h"
#include "kernel/time/time.h"

void vfs_init();
void fix_kernel_page_table();

extern "C" {
#include "driver/interface.h"
#include "driver/fatfs/ff.h"
#include "driver/sysctl.h"
#include "driver/sleep/sleep.h"
#include "driver/rtc/rtc.h"
#include "driver/plic/plic.h"
}

extern "C" void __cxa_pure_virtual() {
    // Do nothing or print an error message.
}

void test_lib() {
    TestString t = TestString();
    t.test();

    TestTrie testTrie;
    TestPathUtil testPathUtil;
    TestFile testFile;
}

void simple_test(){
//    add_test("/yield");
//    add_test("/fork");
//    add_test("/clone");
//    add_test("/write");
//    add_test("/uname");
//    add_test("/times");
//    add_test("/getpid");
//    add_test("/getppid");
//    add_test("/open");
//    add_test("/read");
//    add_test("/close");
//    add_test("/openat");
//    add_test("/getcwd");
//    add_test("/dup");
//    add_test("/getdents");
//    add_test("/dup2");
//    add_test("/wait");
//    add_test("/exit");
//    add_test("/execve");
//    add_test("/gettimeofday");
//    add_test("/mkdir_");
//    add_test("/chdir");
//    add_test("/waitpid");
//    add_test("/sleep");
//    add_test("/unlink");
//    add_test("/mount");
//    add_test("/umount");
//    add_test("/fstat");
//    add_test("/pipe");
}

void busybox_test(){

    // tested
//    add_test("busybox_new ash -c exit");
//    add_test("busybox_new sh -c exit");
//    add_test("busybox_new du");
//    add_test("busybox_new expr 1 + 1");
//    add_test("busybox_new false");
//    add_test("busybox_new true");
//    add_test("busybox_new clear");
//    add_test("busybox_new uname");
//    add_test("busybox_new printf abc\n");
//    add_test("busybox_new basename /aaa/bbb");
//    add_test("busybox_new dirname /aaa/bbb");
//    add_test("busybox_new echo 123");
//    add_test("busybox_new printf \"abc\n\"");
//    add_test("busybox_new echo \"#### independent command test\"");
//    add_test("busybox_new sleep 1");
//    add_test("busybox_new cal");
//    add_test("busybox_new date");
//    add_test("busybox_new kill 10");
//    add_test("busybox_new pwd");

    // TODO: misc tests
//    add_test("busybox_new df");         // too complex, skip
//    add_test("busybox_new dmesg");      // too complex, skip
//    add_test("busybox_new uptime");     // too complex, skip
//    add_test("busybox_new free");       // need /proc/meminfo
//    add_test("busybox_new ps");         // need /proc
//    add_test("busybox_new hwclock");    // need /etc/localtime

    // passed fs tests
//    add_test("busybox_new sh -c \"echo ccccccc > test.txt \"");
//    add_test("busybox_new touch test.txt");
//    add_test("busybox_new cat test.txt");
//    add_test("busybox_new cut -c 3 test.txt");

    // TODO: file system tests
//    add_test("busybox_new which ls");
//    add_test("busybox_new ls");
//    add_test("busybox_new sh -c \"echo ccccccc > test.txt \"");
//    add_test("busybox_new cat test.txt");
//    add_test("busybox_new cut -c 3 test.txt");
//    add_test("busybox_new od test.txt");
//    add_test("busybox_new head test.txt");
//    add_test("busybox_new tail test.txt");
//    add_test("busybox_new hexdump -C test.txt");
//    add_test("busybox_new md5sum test.txt");
//    add_test("busybox_new sort test.txt | ./busybox uniq");
//    add_test("busybox_new stat test.txt");
//    add_test("busybox_new strings test.txt");
//    add_test("busybox_new wc test.txt");
//    add_test("busybox_new [ -f test.txt ]");
//    add_test("busybox_new more test.txt");
//    add_test("busybox_new rm test.txt");
//    add_test("busybox_new mkdir test_dir");
//    add_test("busybox_new mv test_dir test");
//    add_test("busybox_new rmdir test");
//    add_test("busybox_new grep hello busybox_cmd.txt");
//    add_test("busybox_new cp busybox_cmd.txt busybox_cmd.bak");
//    add_test("busybox_new rm busybox_cmd.bak");
//    add_test("busybox_new find -name \"busybox_cmd.txt\"");
}

/**
 * ?????????????????? sret ??????u-mode
 * ???????????????????????????????????????
 * ???????????????pc????????????sepc???;pc????????????stvec;
 * scause????????????????????????;stval???????????????????????????????????????;
 * sie?????????????????????;?????????sie????????????spie;
 * ?????????????????????????????????spp???;
 *
 * ??????????????????????????????????????????????????????;????????????????????????;????????????;
 *
 * ??????????????????????????????+???????????????????????????????????????
 */
void init_thread() {
    printf("[OS] test library\n");
    test_lib();
//    printf("[OS] rtc init.\n");
//    init_rtc();
//    printf("[OS] fix page table before driver\n");
//    fix_kernel_page_table();
    printf("[OS] bsp init.\n");
    driver_init();
    printf("[FS] fs init.\n");
    vfs_init();
    printf("[OS] Interrupt & Timer Interrupt Open.\n");
    interrupt_timer_init();
    printf("[OS] init scheduler.\n");
    init_scheduler();
    FD::InitializeFileDescriber();
    init_self_tests();

    simple_test();
//    busybox_test();

    add_test("/lmbench_new bw_pipe -P 1");

    schedule();
}

void fix_kernel_page_table(){
    size_t table_base = register_read_satp() << 12;
    size_t virtual_address = 0x38001000;
    size_t physical_address = virtual_address;

    PageTableUtil::CreateMapping(table_base,
                                 virtual_address,
                                 physical_address,
                                 PAGE_TABLE_LEVEL::SMALL,
                                 PRIVILEGE_LEVEL::SUPERVISOR);

}

void vfs_init() {
    File::init();
    auto *ifs = new FS;
    ifs->init();
    fs = new VFS(ifs);

    auto *stdout = new StdoutFs;

    /** /dev/console **/
    fs->root->appendChild(new File("dev", ifs));
    fs->mkdir("/dev", O_DIRECTORY | O_RDWR);

    auto *dev = fs->root->first_child->search("/dev");
    assert(dev != nullptr);
    dev->appendChild(new File("console", stdout));

    /** /sys/pipe **/
    fs->root->appendChild(new File("sys", ifs));
    fs->mkdir("/sys", O_DIRECTORY | O_RDWR);

    auto* sys = fs->root->first_child->search("/sys");
    assert(sys != nullptr);

    sys->appendChild(new File("pipe", new PipeFs));
    fs->mkdir("/pipe", O_DIRECTORY | O_RDWR);

    auto* sys_pipe = fs->root->first_child->search("/sys/pipe");
    assert(sys_pipe != nullptr);


    /** /proc/self/exe **/
    fs->root->appendChild(new File("proc", ifs));
    fs->mkdir("/proc", O_DIRECTORY | O_RDWR);

    auto* proc = fs->root->first_child->search("/proc");
    assert(proc != nullptr);

    proc->appendChild(new File("self", ifs));
    fs->mkdir("/proc/self", O_DIRECTORY | O_RDWR);

    auto* self = fs->root->first_child->search("/proc/self");
    assert(self != nullptr);

    self->appendChild(new File("exe", nullptr));

    auto* exe = fs->root->first_child->search("/proc/self/exe");
    assert(exe != nullptr);
}
#define CLINT_BASE_ADDR     (0x02000000U)

volatile clint_t *const clint = (volatile clint_t *)CLINT_BASE_ADDR;
int main() {
    printf("   _____            _____               \n"
           "  / ____|          / ____|              \n"
           " | (___  _   _ ___| |     ___  _ __ ___ \n"
           "  \\___ \\| | | / __| |    / _ \\| '__/ _ \\\n"
           "  ____) | |_| \\__ \\ |___| (_) | | |  __/\n"
           " |_____/ \\__, |___/\\_____\\___/|_|  \\___|\n"
           "          __/ |                         \n"
           "         |___/                          \n");

    lty(__kernel_stack_base);

    printf("[OS] Memory Init.\n");
    init_memory();
//    init_kernel_heap();
    init_heap();
    kernelContext.kernel_satp = register_read_satp() | (8LL << 60);lty(kernelContext.kernel_satp);
    kernelContext.kernel_handle_interrupt = (size_t) handle_interrupt;
    kernelContext.kernel_restore = (size_t) __restore;

    // init_thread();
    // unreachable
    init_rtc();
    // tm timep;
    // uint64 ans;
    // timep.tm_year=2020;
    // timep.tm_mon = 1;
    // timep.tm_mday = 1;
    // timep.tm_hour = 0;
    // timep.tm_min = 0;
    // timep.tm_sec = 0;
    // ans = mktime(&timep);
    // printf("%d\n",ans);
    // ans = mktime_set(2020,1,1,0,0,0);
    // printf("%d\n",ans);
    timespec ts;
    // rtc_timer_set(2021,8,12,8,51,0);
    // uint64 start = clint_get_time();
    // uint64 end = clint_get_time();
    // uint64 start1 = timer();
    // uint64 end1 = timer();
    // start = clint_get_time();
    // start1 = timer();
    uint64 a,b;
    while(1){
        // current_timespec(&ts);
        sys_clock_gettime(CLOCK_REALTIME,&ts);
        // end = clint_get_time();
        // printf("clint_time:%d\t",end-start);
        // end1 = timer();
        // printf("r_time:%d\n",end1-start1);
        printf("%d %d\t",ts.tv_sec,ts.tv_nsec);
        sys_clock_gettime(CLOCK_MONOTONIC,&ts);
        printf("%d %d\n",ts.tv_sec,ts.tv_nsec);
        
        // uint64_t clint_usec =
        // clint->mtime * 1000 /
        // (sysctl_clock_get_freq(SYSCTL_CLOCK_CPU) / 50 / 1000000UL );

        // a = clint_usec / 1000000000UL;
        // b = clint_usec % 1000000000UL;
        // printf("%d %d\n", a, b);
        sleep(1);
    }
 
    // seconds = time(NULL);
    // printf("??? 1970-01-01 ??????????????? = %d\n", seconds/3600);
    panic("Unreachable code!");
    return 0;
}
