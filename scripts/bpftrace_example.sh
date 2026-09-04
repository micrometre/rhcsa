#!/usr/bin/bpftrace

BEGIN
{
    printf("Tracing VFS read latency... Hit Ctrl-C to end.\n");
}

kprobe:vfs_read
{
    @start[tid] = nsecs;
}

kretprobe:vfs_read
/@start[tid]/
{
    $lat = (nsecs - @start[tid]) / 1000; // Convert to microseconds
    @lat_us = hist($lat);
    @bytes[comm] = sum(retval);
    delete(@start[tid]);
}

END
{
    clear(@start);
}