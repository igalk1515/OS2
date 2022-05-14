#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[CPUS];

int print_flag = 0;
int counter_blance = 0;

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

extern uint64 cas(volatile void *addr , int expected , int newval);
struct spinlock readyLock[CPUS];
struct proc *zombieList,*sleepingList,*unusedList =0;
struct spinlock zombieLock,unusedLock,sleepLock;







// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;
/**
 * 1 = ready 
 * 2 = zombie 
 * 3 = sleeping 
 * 4 = unused  
 */
void
getList2(int number, int parent_cpu){ // TODO: change name of function
int a =0;
a=a+1;
if(a==0){
  panic("a not zero ");
}
  number == 1 ?  acquire(&readyLock[parent_cpu]): 
    number == 2 ? acquire(&zombieLock): 
      number == 3 ? acquire(&sleepLock): 
        number == 4 ? acquire(&unusedLock):  
          panic("wrong call in getList2");
}

struct proc* get_first2(int number, int parent_cpu){
  struct proc* p;
  number == 1 ? p = cpus[parent_cpu].first :
    number == 2 ? p = zombieList  :
      number == 3 ? p = sleepingList :
        number == 4 ? p = unusedList:
          panic("wrong call in get_first2");
  return p;
}

void
set_first2(struct proc* p, int number, int parent_cpu)//TODO: change name of function
{
  number == 1 ?  cpus[parent_cpu].first = p: 
    number == 2 ? zombieList = p: 
      number == 3 ? sleepingList = p: 
        number == 4 ? unusedList:  
          panic("wrong call in set_first2");
}

void
release_list2(int number, int parent_cpu){
    number == 1 ?  release(&readyLock[parent_cpu]): 
      number == 2 ? release(&zombieLock): 
        number == 3 ? release(&sleepLock): 
          number == 4 ? release(&unusedLock):  
            panic("wrong call in release_list2");
}


void
add_to_list2(struct proc* p, struct proc* first, int type, int parent_cpu)//TODO: change name of function
{

    struct proc* prev = 0;
    while(first){
      acquire(&first->list_lock);

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list2(type, parent_cpu);
      }
      prev = first;
      first = first->next;
    }
}

void //TODO: cahnge 
add_proc2(struct proc* p, int number, int parent_cpu)
{
  struct proc* first;
  getList2(number, parent_cpu);
  first = get_first2(number, parent_cpu);
  add_to_list2(p, first, number, parent_cpu);//TODO change name
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
int flag_init = 0;

int
pick_cpu(){
  int min = 0;
  int cpuNumber=0;
  for(int i=1; i<CPUS; i++){
    if(min==-1 || min > cpus[i].queue_size){
      cpuNumber = i;
      min = cpus[i].queue_size;
    }
    if(BLNCFLG){
      continue;
    }
  }
  if(min==-31 || cpuNumber==-31){
    panic("pick_cpu");
  }
  return cpuNumber;
}

void
cahnge_number_of_proc(int cpu_id,int number){
  struct cpu* c = &cpus[cpu_id];
  uint64 old;
  do{
    old = c->queue_size;
  } while(cas(&c->queue_size, old, old+number));
}

int //TODO
set_cpu(int number)
{
  if(number<0 || number>NCPU){
    return -1;
  }
  struct proc* p = myproc();
  int b=-1;
  cahnge_number_of_proc(p->parent_cpu,b);
  p->parent_cpu=number;
  int positive=1;
  cahnge_number_of_proc(number,positive);
  yield();
  return number;
}
//  * 1 = ready 
//  * 2 = zombie 
//  * 3 = sleeping 
//  * 4 = unused  

enum list_type {readyList, zombeList, sleepLeast, unuseList};

struct proc *zombie_list,*unused_list,*sleeping_list = 0;

struct spinlock ready_lock[CPUS];
struct spinlock zombie_lock;
struct spinlock sleeping_lock;
struct spinlock unused_lock;

void
getList(int type, int cpu_id){
  if(type>3){
  printf("type is %d\n",type);
  }

  if(type==readyList || type==11){
    acquire(&ready_lock[cpu_id]);
  }
  else if(type==zombeList || type==21){
    acquire(&zombie_lock);
  }
  else if(type==sleepLeast || type==31){
  acquire(&sleeping_lock);
  }
  else if(type==unuseList || type==41){
  acquire(&unused_lock);
  }
  else if(type == 51){
    set_cpu(cpu_id);
    printf("getList type ==5");
  }
  else if(type == 61){
    print_flag++;
  }
  else{
    panic("getList");
  }
}


struct proc* getFirst(int type, int cpu_id){
  struct proc* p;

  if(type>3){
  printf("type is %d\n",type);
  }

  if(type==readyList || type==11){
    p = cpus[cpu_id].first;
  }
  else if(type==zombeList || type==21){
   p = zombie_list;  }
  else if(type==sleepLeast || type==31){
  p = sleeping_list;
  }
  else if(type==unuseList || type==41){
  p = unused_list;
  }
  else{
    panic("getFirst");
  }
  return p;
}


void
setFirst(struct proc* p, int type, int cpu_id)
{
  if(type>3){
  printf("type is %d\n",type);
  }

  if(type==readyList || type==11){
    cpus[cpu_id].first = p;
  }
  else if(type==zombeList || type==21){
    zombie_list = p;
  }
  else if(type==sleepLeast || type==31){
    sleeping_list = p;
  }
  else if(type==unuseList || type==41){
  unused_list = p;
  }
  else if(type == 51){
    set_cpu(cpu_id);
    printf("getList type ==5");
  }
  else if(type == 61){
    print_flag++;
  }
  else{
    panic("getList");
  }
}


void
release_list3(int number, int parent_cpu){
    number == 1 ?  release(&ready_lock[parent_cpu]): 
      number == 2 ? release(&zombie_lock): 
        number == 3 ? release(&sleeping_lock): 
          number == 4 ? release(&unused_lock):  
            panic("wrong call in release_list3");
}

void
release_list(int type, int parent_cpu){
  type==readyList ? release_list3(1,parent_cpu): 
    type==zombeList ? release_list3(2,parent_cpu):
      type==sleepLeast ? release_list3(3,parent_cpu):
        type==unuseList ? release_list3(4,parent_cpu):
          panic("wrong type list");
}

void 
add_proc_to_specific_list(struct proc* p, int type, int cpu_id)
{
  // bad argument
  if(!p){
    panic("add_proc_to_specific_list");
  }
  struct proc* prev = 0;
  struct proc* current;
  getList(type, cpu_id);//get the corect list for proc state
  current = getFirst(type, cpu_id);
  if(!current){// set first in list
    setFirst(p, type, cpu_id);
    release_list(type, cpu_id);
  }
  else{
    while(current){
      acquire(&current->list_lock);

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list(type, cpu_id);
      }
      prev = current;
      current = current->next;
    }
    prev->next = p;
    release(&prev->list_lock);
  }
}





struct proc* 
remove_first(int type, int cpu_id)
{
  getList(type, cpu_id);//acquire lock
  struct proc* head = getFirst(type, cpu_id);//aquire list after we have loock 
  if(!head){
    release_list(type, cpu_id);//realese loock 
  }
  else{
    acquire(&head->list_lock);

    setFirst(head->next, type, cpu_id);
    head->next = 0;
    release(&head->list_lock);

    release_list(type, cpu_id);//realese loock 

  }
  return head;
}

int
remove_proc(struct proc* p, int type){
  getList(type, p->parent_cpu);
  struct proc* head = getFirst(type, p->parent_cpu);
  if(!head){
    release_list(type, p->parent_cpu);
    return 0;
  }
  else{
    struct proc* prev = 0;
    if(p == head){
      // remove node, p is the first link
      acquire(&p->list_lock);
      setFirst(p->next, type, p->parent_cpu);
      p->next = 0;
      release(&p->list_lock);
      release_list(type, p->parent_cpu);
    }
    else{
      while(head){
        acquire(&head->list_lock);

        if(p == head){
          // remove node, head is the first link
          prev->next = head->next;
          p->next = 0;
          release(&head->list_lock);
          release(&prev->list_lock);
          return 1;
        }

        if(!prev)
          release_list(type,p->parent_cpu);
        else{
          release(&prev->list_lock);
        }
          
        
        prev = head;
        head = head->next;
      }
    }
    return 0;
  }
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


int 
get_cpu()
{
  struct proc* p = myproc();
  int cpuid = p->parent_cpu;
  return cpuid;
}

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table at boot time.
void
procinit(void)
{
  struct proc *p;
  //----------------------------------------------------------
  if(CPUS > NCPU){
    panic("recieved more CPUS than what is allowed");
  }
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  initlock(&zombie_lock, "zombie lock");
  initlock(&sleeping_lock, "sleeping lock");
  initlock(&unused_lock, "unused lock");

  struct spinlock* s;
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    initlock(s, "ready lock");
  }
  //--------------------------------------------------
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
      //--------------------------------------------------
      initlock(&p->list_lock, "list lock");
      //--------------------------------------------------
      p->kstack = KSTACK((int) (p - proc));
      //--------------------------------------------------
       p->parent_cpu = -1;
       add_proc_to_specific_list(p, unuseList, -1);
      
      //--------------------------------------------------
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid() {
  int pid;

  do {
    pid = nextpid;
  }
  while(cas(&nextpid, pid, pid + 1));

  // acquire(&pid_lock);
  // pid = nextpid;
  // nextpid = nextpid + 1;
  // release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;
//----------------------------------------------------
  p = remove_first(unuseList, -1);
  if(!p){
    return 0;
  }
//----------------------------------------------------

  acquire(&p->lock);

  p->pid = allocpid();
  p->state = USED;
//----------------------------------------------------
  p->next = 0;
//----------------------------------------------------
  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
  //------------------------------------------
  remove_proc(p, zombeList);
  add_proc_to_specific_list(p, unuseList, -1);
  //------------------------------------------
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  //---------------------------------------------------------------
  if(!flag_init){
    struct cpu* c;
    for(c = cpus; c < &cpus[CPUS]; c++){
      c->first = 0;
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    }
    flag_init = 1;
  }
  //---------------------------------------------------------------
  struct proc *p;

  p = allocproc();
  initproc = p;
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;
//------------------------------------------------
  p->parent_cpu = 0;
//------------------------------------------------PART 4 ------------------------------------------------
  // increase_size(p->parent_cpu);
  int a=1;
  cahnge_number_of_proc(p->parent_cpu,a);
//------------------------------------------------PART 4 ------------------------------------------------
  cpus[p->parent_cpu].first = p;
//------------------------------------------------


  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;

  
  // np->parent_cpu = p->parent_cpu; // give the proces cpu id of padrant  
  // add_proc(np, 1, p->parent_cpu); // add new proces to the list of ready 


 
//------------------------------------------------PART 4 ------------------------------------------------
    int cpu_id = (BLNCFLG) ? pick_cpu() : p->parent_cpu;
//------------------------------------------------PART 4 ------------------------------------------------
  np->parent_cpu = cpu_id;
  add_proc_to_specific_list(np, readyList, cpu_id);

  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  // decrease_size(p->parent_cpu);
  int b=-1;
  cahnge_number_of_proc(p->parent_cpu,b);
  //-----------------------------------------------------
  add_proc_to_specific_list(p, zombeList, -1);
  //-----------------------------------------------------

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  if(!BLNCFLG){
    if(!print_flag){
      print_flag++;
      printf("BLNCFLG is OFF\n");
    }
    blncflag_off();
  }
  else{
      if(!print_flag){
      print_flag++;
      printf("BLNCFLG is ON\n");
      }
    blncflag_on();
  }

}

void
blncflag_on(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  int cpu_id = cpuid();
  
  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    p = remove_first(readyList, cpu_id);

    //if empty list
    if(!p){
      if(!BLNCFLG){
        continue;
      }
      if(!p){ 
        continue;
      }
      // decrease_size(p->parent_cpu);
      int b=-1;
      cahnge_number_of_proc(p->parent_cpu,b);
      p->parent_cpu = cpu_id;
      // increase_size(cpu_id);
      int a=1;
      cahnge_number_of_proc(cpu_id,a);
    }
    acquire(&p->lock);

    if(p->state!=RUNNABLE)
      panic("bad proc was selected");
  
    p->state = RUNNING;
    c->proc = p;
    
    swtch(&c->context, &p->context);
  
    c->proc = 0;
    release(&p->lock);
  }
}

void
blncflag_off(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  int cpu_id = cpuid();

  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    //-------------------------------------------------------------------------------------------------------
    p = remove_first(readyList, cpu_id);
    if(!p){ // no proces ready 
      continue;
    }
    //-------------------------------------------------------------------------------------------------------=
      acquire(&p->lock);
    //-------------------------------------------------------------------------------------------------------=
      if(p->state != RUNNABLE)
        panic("bad proc was selected");
    //-------------------------------------------------------------------------------------------------------=
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.

        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      release(&p->lock);
  }

}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  //-------------------------------------------------------------------
  add_proc_to_specific_list(p, readyList, p->parent_cpu);
  //-------------------------------------------------------------------
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;
  // decrease_size(p->parent_cpu);
  int b=-1;
  cahnge_number_of_proc(p->parent_cpu,b);
  //--------------------------------------------------------------------
    add_proc_to_specific_list(p, sleepLeast,-1);
  //--------------------------------------------------------------------

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);

}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
//--------------------------------------------------------------------
void
wakeup(void *chan)
{
  int released_list = 0;
  struct proc *p;
  struct proc* prev = 0;
  struct proc* tmp;
  getList(sleepLeast, -1);
  p = getFirst(sleepLeast, -1);
  while(p){
    acquire(&p->lock);
    acquire(&p->list_lock);
    if(p->chan == chan){
      if(p == getFirst(sleepLeast, -1)){
        setFirst(p->next, sleepLeast, -1);
        
        tmp = p;
        p = p->next;
        tmp->next = 0;

        //add to runnable
        tmp->state = RUNNABLE;
        int cpu_id = (BLNCFLG) ? pick_cpu() : tmp->parent_cpu;
        tmp->parent_cpu = cpu_id;
        // increase_size(cpu_id);
        int a=1;
        cahnge_number_of_proc(cpu_id,a);
        add_proc_to_specific_list(tmp, readyList, cpu_id);
        release(&tmp->list_lock);
        release(&tmp->lock);
      }
      //we are not on the beginning of the list.
      else{
        prev->next = p->next;
        p->next = 0;
        p->state = RUNNABLE;
        int cpu_id = (BLNCFLG) ? pick_cpu() : p->parent_cpu;
        p->parent_cpu = cpu_id;
        // increase_size(cpu_id);
        int a=1;
        cahnge_number_of_proc(cpu_id,a);
        add_proc_to_specific_list(p, readyList, cpu_id);
        release(&p->list_lock);
        release(&p->lock);
        p = prev->next;
      }
    } 
    else{
      //we are not on the chan
      if(p == getFirst(sleepLeast, -1)){
        release_list(sleepLeast,-1);
        released_list = 1;
      }
      else{
        release(&prev->list_lock);
      }
      release(&p->lock);  //because we dont need to change his fields
      prev = p;
      p = p->next;
    }
  }
  if(!released_list){
    release_list(sleepLeast, -1);
  }
  if(prev){
    release(&prev->list_lock);
  }
}
//--------------------------------------------------------------------

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
        remove_proc(p, sleepLeast);
        add_proc_to_specific_list(p, readyList, p->parent_cpu);
        // increase_size(p->parent_cpu);
        int a=1;
        cahnge_number_of_proc(p->parent_cpu,a);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}
