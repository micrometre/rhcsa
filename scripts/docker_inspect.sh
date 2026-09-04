#!/bin/bash
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_execve
/comm == "curl"/
{
    printf("\n[CURL DETECTED]\n");
    printf("  PID:    %d\n", pid);
    printf("  PPID:   %d (%s)\n", curtask->parent->pid, curtask->parent->comm);
    printf("  UID:    %d\n", uid);
    printf("  Args:   ");
    join(args->argv);
}
'