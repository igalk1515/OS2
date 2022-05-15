
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	a5013103          	ld	sp,-1456(sp) # 80009a50 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	02e70713          	addi	a4,a4,46 # 8000a080 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	9bc78793          	addi	a5,a5,-1604 # 80006a20 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dee78793          	addi	a5,a5,-530 # 80000e9c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	1fa080e7          	jalr	506(ra) # 80003326 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	03450513          	addi	a0,a0,52 # 800121c0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a58080e7          	jalr	-1448(ra) # 80000bec <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00012497          	auipc	s1,0x12
    800001a0:	02448493          	addi	s1,s1,36 # 800121c0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00012917          	auipc	s2,0x12
    800001aa:	0b290913          	addi	s2,s2,178 # 80012258 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	cde080e7          	jalr	-802(ra) # 80001ea2 <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	bba080e7          	jalr	-1094(ra) # 80002d8e <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00003097          	auipc	ra,0x3
    80000214:	0c0080e7          	jalr	192(ra) # 800032d0 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00012517          	auipc	a0,0x12
    80000228:	f9c50513          	addi	a0,a0,-100 # 800121c0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a7a080e7          	jalr	-1414(ra) # 80000ca6 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00012517          	auipc	a0,0x12
    8000023e:	f8650513          	addi	a0,a0,-122 # 800121c0 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a64080e7          	jalr	-1436(ra) # 80000ca6 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00012717          	auipc	a4,0x12
    80000276:	fef72323          	sw	a5,-26(a4) # 80012258 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00012517          	auipc	a0,0x12
    800002d0:	ef450513          	addi	a0,a0,-268 # 800121c0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	918080e7          	jalr	-1768(ra) # 80000bec <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	08a080e7          	jalr	138(ra) # 8000337c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00012517          	auipc	a0,0x12
    800002fe:	ec650513          	addi	a0,a0,-314 # 800121c0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9a4080e7          	jalr	-1628(ra) # 80000ca6 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00012717          	auipc	a4,0x12
    80000322:	ea270713          	addi	a4,a4,-350 # 800121c0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00012797          	auipc	a5,0x12
    8000034c:	e7878793          	addi	a5,a5,-392 # 800121c0 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00012797          	auipc	a5,0x12
    8000037a:	ee27a783          	lw	a5,-286(a5) # 80012258 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00012717          	auipc	a4,0x12
    8000038e:	e3670713          	addi	a4,a4,-458 # 800121c0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00012497          	auipc	s1,0x12
    8000039e:	e2648493          	addi	s1,s1,-474 # 800121c0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00012717          	auipc	a4,0x12
    800003da:	dea70713          	addi	a4,a4,-534 # 800121c0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00012717          	auipc	a4,0x12
    800003f0:	e6f72a23          	sw	a5,-396(a4) # 80012260 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00012797          	auipc	a5,0x12
    80000416:	dae78793          	addi	a5,a5,-594 # 800121c0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00012797          	auipc	a5,0x12
    8000043a:	e2c7a323          	sw	a2,-474(a5) # 8001225c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00012517          	auipc	a0,0x12
    80000442:	e1a50513          	addi	a0,a0,-486 # 80012258 <cons+0x98>
    80000446:	00003097          	auipc	ra,0x3
    8000044a:	af0080e7          	jalr	-1296(ra) # 80002f36 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00009597          	auipc	a1,0x9
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80009010 <etext+0x10>
    80000460:	00012517          	auipc	a0,0x12
    80000464:	d6050513          	addi	a0,a0,-672 # 800121c0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	7b078793          	addi	a5,a5,1968 # 80022c28 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00009617          	auipc	a2,0x9
    800004be:	b8660613          	addi	a2,a2,-1146 # 80009040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00012797          	auipc	a5,0x12
    8000054e:	d207ab23          	sw	zero,-714(a5) # 80012280 <pr+0x18>
  printf("panic: ");
    80000552:	00009517          	auipc	a0,0x9
    80000556:	ac650513          	addi	a0,a0,-1338 # 80009018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00009517          	auipc	a0,0x9
    80000570:	ddc50513          	addi	a0,a0,-548 # 80009348 <digits+0x308>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	0000a717          	auipc	a4,0xa
    80000582:	a8f72123          	sw	a5,-1406(a4) # 8000a000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00012d97          	auipc	s11,0x12
    800005be:	cc6dad83          	lw	s11,-826(s11) # 80012280 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00009b97          	auipc	s7,0x9
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80009040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00012517          	auipc	a0,0x12
    800005fc:	c7050513          	addi	a0,a0,-912 # 80012268 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5ec080e7          	jalr	1516(ra) # 80000bec <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00009517          	auipc	a0,0x9
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80009028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00009917          	auipc	s2,0x9
    8000070e:	91690913          	addi	s2,s2,-1770 # 80009020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00012517          	auipc	a0,0x12
    80000760:	b0c50513          	addi	a0,a0,-1268 # 80012268 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	542080e7          	jalr	1346(ra) # 80000ca6 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00012497          	auipc	s1,0x12
    8000077c:	af048493          	addi	s1,s1,-1296 # 80012268 <pr>
    80000780:	00009597          	auipc	a1,0x9
    80000784:	8b858593          	addi	a1,a1,-1864 # 80009038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00009597          	auipc	a1,0x9
    800007d4:	88858593          	addi	a1,a1,-1912 # 80009058 <digits+0x18>
    800007d8:	00012517          	auipc	a0,0x12
    800007dc:	ab050513          	addi	a0,a0,-1360 # 80012288 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00009797          	auipc	a5,0x9
    80000808:	7fc7a783          	lw	a5,2044(a5) # 8000a000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	412080e7          	jalr	1042(ra) # 80000c40 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00009717          	auipc	a4,0x9
    80000844:	7c873703          	ld	a4,1992(a4) # 8000a008 <uart_tx_r>
    80000848:	00009797          	auipc	a5,0x9
    8000084c:	7c87b783          	ld	a5,1992(a5) # 8000a010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00012a17          	auipc	s4,0x12
    8000086e:	a1ea0a13          	addi	s4,s4,-1506 # 80012288 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00009497          	auipc	s1,0x9
    80000876:	79648493          	addi	s1,s1,1942 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00009997          	auipc	s3,0x9
    8000087e:	79698993          	addi	s3,s3,1942 # 8000a010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	696080e7          	jalr	1686(ra) # 80002f36 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00012517          	auipc	a0,0x12
    800008e0:	9ac50513          	addi	a0,a0,-1620 # 80012288 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	308080e7          	jalr	776(ra) # 80000bec <acquire>
  if(panicked){
    800008ec:	00009797          	auipc	a5,0x9
    800008f0:	7147a783          	lw	a5,1812(a5) # 8000a000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00009797          	auipc	a5,0x9
    800008fc:	7187b783          	ld	a5,1816(a5) # 8000a010 <uart_tx_w>
    80000900:	00009717          	auipc	a4,0x9
    80000904:	70873703          	ld	a4,1800(a4) # 8000a008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00012a17          	auipc	s4,0x12
    80000914:	978a0a13          	addi	s4,s4,-1672 # 80012288 <uart_tx_lock>
    80000918:	00009497          	auipc	s1,0x9
    8000091c:	6f048493          	addi	s1,s1,1776 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00009917          	auipc	s2,0x9
    80000924:	6f090913          	addi	s2,s2,1776 # 8000a010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	462080e7          	jalr	1122(ra) # 80002d8e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00012497          	auipc	s1,0x12
    80000946:	94648493          	addi	s1,s1,-1722 # 80012288 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00009717          	auipc	a4,0x9
    8000095a:	6af73d23          	sd	a5,1722(a4) # 8000a010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	33e080e7          	jalr	830(ra) # 80000ca6 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00012497          	auipc	s1,0x12
    800009ce:	8be48493          	addi	s1,s1,-1858 # 80012288 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	218080e7          	jalr	536(ra) # 80000bec <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2c0080e7          	jalr	704(ra) # 80000ca6 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00026797          	auipc	a5,0x26
    80000a10:	5f478793          	addi	a5,a5,1524 # 80027000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2ca080e7          	jalr	714(ra) # 80000cee <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00012917          	auipc	s2,0x12
    80000a30:	89490913          	addi	s2,s2,-1900 # 800122c0 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1b6080e7          	jalr	438(ra) # 80000bec <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	25c080e7          	jalr	604(ra) # 80000ca6 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00008517          	auipc	a0,0x8
    80000a62:	60250513          	addi	a0,a0,1538 # 80009060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00008597          	auipc	a1,0x8
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80009068 <digits+0x28>
    80000ac8:	00011517          	auipc	a0,0x11
    80000acc:	7f850513          	addi	a0,a0,2040 # 800122c0 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00026517          	auipc	a0,0x26
    80000ae0:	52450513          	addi	a0,a0,1316 # 80027000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00011497          	auipc	s1,0x11
    80000b02:	7c248493          	addi	s1,s1,1986 # 800122c0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0e4080e7          	jalr	228(ra) # 80000bec <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00011517          	auipc	a0,0x11
    80000b1a:	7aa50513          	addi	a0,a0,1962 # 800122c0 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	186080e7          	jalr	390(ra) # 80000ca6 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1c0080e7          	jalr	448(ra) # 80000cee <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	77e50513          	addi	a0,a0,1918 # 800122c0 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	15c080e7          	jalr	348(ra) # 80000ca6 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	300080e7          	jalr	768(ra) # 80001e7e <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	2ce080e7          	jalr	718(ra) # 80001e7e <mycpu>
    80000bb8:	08052783          	lw	a5,128(a0)
    80000bbc:	cf99                	beqz	a5,80000bda <push_off+0x42>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	2c0080e7          	jalr	704(ra) # 80001e7e <mycpu>
    80000bc6:	08052783          	lw	a5,128(a0)
    80000bca:	2785                	addiw	a5,a5,1
    80000bcc:	08f52023          	sw	a5,128(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	2a4080e7          	jalr	676(ra) # 80001e7e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	08952223          	sw	s1,132(a0)
    80000bea:	bfd1                	j	80000bbe <push_off+0x26>

0000000080000bec <acquire>:
{
    80000bec:	1101                	addi	sp,sp,-32
    80000bee:	ec06                	sd	ra,24(sp)
    80000bf0:	e822                	sd	s0,16(sp)
    80000bf2:	e426                	sd	s1,8(sp)
    80000bf4:	1000                	addi	s0,sp,32
    80000bf6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf8:	00000097          	auipc	ra,0x0
    80000bfc:	fa0080e7          	jalr	-96(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000c00:	8526                	mv	a0,s1
    80000c02:	00000097          	auipc	ra,0x0
    80000c06:	f68080e7          	jalr	-152(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0a:	4705                	li	a4,1
  if(holding(lk))
    80000c0c:	e115                	bnez	a0,80000c30 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0e:	87ba                	mv	a5,a4
    80000c10:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c14:	2781                	sext.w	a5,a5
    80000c16:	ffe5                	bnez	a5,80000c0e <acquire+0x22>
  __sync_synchronize();
    80000c18:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1c:	00001097          	auipc	ra,0x1
    80000c20:	262080e7          	jalr	610(ra) # 80001e7e <mycpu>
    80000c24:	e888                	sd	a0,16(s1)
}
    80000c26:	60e2                	ld	ra,24(sp)
    80000c28:	6442                	ld	s0,16(sp)
    80000c2a:	64a2                	ld	s1,8(sp)
    80000c2c:	6105                	addi	sp,sp,32
    80000c2e:	8082                	ret
    panic("acquire");
    80000c30:	00008517          	auipc	a0,0x8
    80000c34:	44050513          	addi	a0,a0,1088 # 80009070 <digits+0x30>
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	906080e7          	jalr	-1786(ra) # 8000053e <panic>

0000000080000c40 <pop_off>:

void
pop_off(void)
{
    80000c40:	1141                	addi	sp,sp,-16
    80000c42:	e406                	sd	ra,8(sp)
    80000c44:	e022                	sd	s0,0(sp)
    80000c46:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c48:	00001097          	auipc	ra,0x1
    80000c4c:	236080e7          	jalr	566(ra) # 80001e7e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c54:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c56:	eb85                	bnez	a5,80000c86 <pop_off+0x46>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c58:	08052783          	lw	a5,128(a0)
    80000c5c:	02f05d63          	blez	a5,80000c96 <pop_off+0x56>
    panic("pop_off");
  c->noff -= 1;
    80000c60:	37fd                	addiw	a5,a5,-1
    80000c62:	0007871b          	sext.w	a4,a5
    80000c66:	08f52023          	sw	a5,128(a0)
  if(c->noff == 0 && c->intena)
    80000c6a:	eb11                	bnez	a4,80000c7e <pop_off+0x3e>
    80000c6c:	08452783          	lw	a5,132(a0)
    80000c70:	c799                	beqz	a5,80000c7e <pop_off+0x3e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c72:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c76:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c7a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c7e:	60a2                	ld	ra,8(sp)
    80000c80:	6402                	ld	s0,0(sp)
    80000c82:	0141                	addi	sp,sp,16
    80000c84:	8082                	ret
    panic("pop_off - interruptible");
    80000c86:	00008517          	auipc	a0,0x8
    80000c8a:	3f250513          	addi	a0,a0,1010 # 80009078 <digits+0x38>
    80000c8e:	00000097          	auipc	ra,0x0
    80000c92:	8b0080e7          	jalr	-1872(ra) # 8000053e <panic>
    panic("pop_off");
    80000c96:	00008517          	auipc	a0,0x8
    80000c9a:	3fa50513          	addi	a0,a0,1018 # 80009090 <digits+0x50>
    80000c9e:	00000097          	auipc	ra,0x0
    80000ca2:	8a0080e7          	jalr	-1888(ra) # 8000053e <panic>

0000000080000ca6 <release>:
{
    80000ca6:	1101                	addi	sp,sp,-32
    80000ca8:	ec06                	sd	ra,24(sp)
    80000caa:	e822                	sd	s0,16(sp)
    80000cac:	e426                	sd	s1,8(sp)
    80000cae:	1000                	addi	s0,sp,32
    80000cb0:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cb2:	00000097          	auipc	ra,0x0
    80000cb6:	eb8080e7          	jalr	-328(ra) # 80000b6a <holding>
    80000cba:	c115                	beqz	a0,80000cde <release+0x38>
  lk->cpu = 0;
    80000cbc:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cc0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cc4:	0f50000f          	fence	iorw,ow
    80000cc8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000ccc:	00000097          	auipc	ra,0x0
    80000cd0:	f74080e7          	jalr	-140(ra) # 80000c40 <pop_off>
}
    80000cd4:	60e2                	ld	ra,24(sp)
    80000cd6:	6442                	ld	s0,16(sp)
    80000cd8:	64a2                	ld	s1,8(sp)
    80000cda:	6105                	addi	sp,sp,32
    80000cdc:	8082                	ret
    panic("release");
    80000cde:	00008517          	auipc	a0,0x8
    80000ce2:	3ba50513          	addi	a0,a0,954 # 80009098 <digits+0x58>
    80000ce6:	00000097          	auipc	ra,0x0
    80000cea:	858080e7          	jalr	-1960(ra) # 8000053e <panic>

0000000080000cee <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cf4:	ce09                	beqz	a2,80000d0e <memset+0x20>
    80000cf6:	87aa                	mv	a5,a0
    80000cf8:	fff6071b          	addiw	a4,a2,-1
    80000cfc:	1702                	slli	a4,a4,0x20
    80000cfe:	9301                	srli	a4,a4,0x20
    80000d00:	0705                	addi	a4,a4,1
    80000d02:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d04:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d08:	0785                	addi	a5,a5,1
    80000d0a:	fee79de3          	bne	a5,a4,80000d04 <memset+0x16>
  }
  return dst;
}
    80000d0e:	6422                	ld	s0,8(sp)
    80000d10:	0141                	addi	sp,sp,16
    80000d12:	8082                	ret

0000000080000d14 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d14:	1141                	addi	sp,sp,-16
    80000d16:	e422                	sd	s0,8(sp)
    80000d18:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d1a:	ca05                	beqz	a2,80000d4a <memcmp+0x36>
    80000d1c:	fff6069b          	addiw	a3,a2,-1
    80000d20:	1682                	slli	a3,a3,0x20
    80000d22:	9281                	srli	a3,a3,0x20
    80000d24:	0685                	addi	a3,a3,1
    80000d26:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d28:	00054783          	lbu	a5,0(a0)
    80000d2c:	0005c703          	lbu	a4,0(a1)
    80000d30:	00e79863          	bne	a5,a4,80000d40 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d34:	0505                	addi	a0,a0,1
    80000d36:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d38:	fed518e3          	bne	a0,a3,80000d28 <memcmp+0x14>
  }

  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	a019                	j	80000d44 <memcmp+0x30>
      return *s1 - *s2;
    80000d40:	40e7853b          	subw	a0,a5,a4
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  return 0;
    80000d4a:	4501                	li	a0,0
    80000d4c:	bfe5                	j	80000d44 <memcmp+0x30>

0000000080000d4e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d4e:	1141                	addi	sp,sp,-16
    80000d50:	e422                	sd	s0,8(sp)
    80000d52:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d54:	ca0d                	beqz	a2,80000d86 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d56:	00a5f963          	bgeu	a1,a0,80000d68 <memmove+0x1a>
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	02e56463          	bltu	a0,a4,80000d8c <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d68:	fff6079b          	addiw	a5,a2,-1
    80000d6c:	1782                	slli	a5,a5,0x20
    80000d6e:	9381                	srli	a5,a5,0x20
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	97ae                	add	a5,a5,a1
    80000d74:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d76:	0585                	addi	a1,a1,1
    80000d78:	0705                	addi	a4,a4,1
    80000d7a:	fff5c683          	lbu	a3,-1(a1)
    80000d7e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d82:	fef59ae3          	bne	a1,a5,80000d76 <memmove+0x28>

  return dst;
}
    80000d86:	6422                	ld	s0,8(sp)
    80000d88:	0141                	addi	sp,sp,16
    80000d8a:	8082                	ret
    d += n;
    80000d8c:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d8e:	fff6079b          	addiw	a5,a2,-1
    80000d92:	1782                	slli	a5,a5,0x20
    80000d94:	9381                	srli	a5,a5,0x20
    80000d96:	fff7c793          	not	a5,a5
    80000d9a:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d9c:	177d                	addi	a4,a4,-1
    80000d9e:	16fd                	addi	a3,a3,-1
    80000da0:	00074603          	lbu	a2,0(a4)
    80000da4:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da8:	fef71ae3          	bne	a4,a5,80000d9c <memmove+0x4e>
    80000dac:	bfe9                	j	80000d86 <memmove+0x38>

0000000080000dae <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e406                	sd	ra,8(sp)
    80000db2:	e022                	sd	s0,0(sp)
    80000db4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000db6:	00000097          	auipc	ra,0x0
    80000dba:	f98080e7          	jalr	-104(ra) # 80000d4e <memmove>
}
    80000dbe:	60a2                	ld	ra,8(sp)
    80000dc0:	6402                	ld	s0,0(sp)
    80000dc2:	0141                	addi	sp,sp,16
    80000dc4:	8082                	ret

0000000080000dc6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dc6:	1141                	addi	sp,sp,-16
    80000dc8:	e422                	sd	s0,8(sp)
    80000dca:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dcc:	ce11                	beqz	a2,80000de8 <strncmp+0x22>
    80000dce:	00054783          	lbu	a5,0(a0)
    80000dd2:	cf89                	beqz	a5,80000dec <strncmp+0x26>
    80000dd4:	0005c703          	lbu	a4,0(a1)
    80000dd8:	00f71a63          	bne	a4,a5,80000dec <strncmp+0x26>
    n--, p++, q++;
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	0505                	addi	a0,a0,1
    80000de0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000de2:	f675                	bnez	a2,80000dce <strncmp+0x8>
  if(n == 0)
    return 0;
    80000de4:	4501                	li	a0,0
    80000de6:	a809                	j	80000df8 <strncmp+0x32>
    80000de8:	4501                	li	a0,0
    80000dea:	a039                	j	80000df8 <strncmp+0x32>
  if(n == 0)
    80000dec:	ca09                	beqz	a2,80000dfe <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dee:	00054503          	lbu	a0,0(a0)
    80000df2:	0005c783          	lbu	a5,0(a1)
    80000df6:	9d1d                	subw	a0,a0,a5
}
    80000df8:	6422                	ld	s0,8(sp)
    80000dfa:	0141                	addi	sp,sp,16
    80000dfc:	8082                	ret
    return 0;
    80000dfe:	4501                	li	a0,0
    80000e00:	bfe5                	j	80000df8 <strncmp+0x32>

0000000080000e02 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e02:	1141                	addi	sp,sp,-16
    80000e04:	e422                	sd	s0,8(sp)
    80000e06:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e08:	872a                	mv	a4,a0
    80000e0a:	8832                	mv	a6,a2
    80000e0c:	367d                	addiw	a2,a2,-1
    80000e0e:	01005963          	blez	a6,80000e20 <strncpy+0x1e>
    80000e12:	0705                	addi	a4,a4,1
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	fef70fa3          	sb	a5,-1(a4)
    80000e1c:	0585                	addi	a1,a1,1
    80000e1e:	f7f5                	bnez	a5,80000e0a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e20:	00c05d63          	blez	a2,80000e3a <strncpy+0x38>
    80000e24:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e26:	0685                	addi	a3,a3,1
    80000e28:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e2c:	fff6c793          	not	a5,a3
    80000e30:	9fb9                	addw	a5,a5,a4
    80000e32:	010787bb          	addw	a5,a5,a6
    80000e36:	fef048e3          	bgtz	a5,80000e26 <strncpy+0x24>
  return os;
}
    80000e3a:	6422                	ld	s0,8(sp)
    80000e3c:	0141                	addi	sp,sp,16
    80000e3e:	8082                	ret

0000000080000e40 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e40:	1141                	addi	sp,sp,-16
    80000e42:	e422                	sd	s0,8(sp)
    80000e44:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e46:	02c05363          	blez	a2,80000e6c <safestrcpy+0x2c>
    80000e4a:	fff6069b          	addiw	a3,a2,-1
    80000e4e:	1682                	slli	a3,a3,0x20
    80000e50:	9281                	srli	a3,a3,0x20
    80000e52:	96ae                	add	a3,a3,a1
    80000e54:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e56:	00d58963          	beq	a1,a3,80000e68 <safestrcpy+0x28>
    80000e5a:	0585                	addi	a1,a1,1
    80000e5c:	0785                	addi	a5,a5,1
    80000e5e:	fff5c703          	lbu	a4,-1(a1)
    80000e62:	fee78fa3          	sb	a4,-1(a5)
    80000e66:	fb65                	bnez	a4,80000e56 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e68:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e6c:	6422                	ld	s0,8(sp)
    80000e6e:	0141                	addi	sp,sp,16
    80000e70:	8082                	ret

0000000080000e72 <strlen>:

int
strlen(const char *s)
{
    80000e72:	1141                	addi	sp,sp,-16
    80000e74:	e422                	sd	s0,8(sp)
    80000e76:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e78:	00054783          	lbu	a5,0(a0)
    80000e7c:	cf91                	beqz	a5,80000e98 <strlen+0x26>
    80000e7e:	0505                	addi	a0,a0,1
    80000e80:	87aa                	mv	a5,a0
    80000e82:	4685                	li	a3,1
    80000e84:	9e89                	subw	a3,a3,a0
    80000e86:	00f6853b          	addw	a0,a3,a5
    80000e8a:	0785                	addi	a5,a5,1
    80000e8c:	fff7c703          	lbu	a4,-1(a5)
    80000e90:	fb7d                	bnez	a4,80000e86 <strlen+0x14>
    ;
  return n;
}
    80000e92:	6422                	ld	s0,8(sp)
    80000e94:	0141                	addi	sp,sp,16
    80000e96:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e98:	4501                	li	a0,0
    80000e9a:	bfe5                	j	80000e92 <strlen+0x20>

0000000080000e9c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e9c:	1141                	addi	sp,sp,-16
    80000e9e:	e406                	sd	ra,8(sp)
    80000ea0:	e022                	sd	s0,0(sp)
    80000ea2:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ea4:	00001097          	auipc	ra,0x1
    80000ea8:	fca080e7          	jalr	-54(ra) # 80001e6e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eac:	00009717          	auipc	a4,0x9
    80000eb0:	16c70713          	addi	a4,a4,364 # 8000a018 <started>
  if(cpuid() == 0){
    80000eb4:	c139                	beqz	a0,80000efa <main+0x5e>
    while(started == 0)
    80000eb6:	431c                	lw	a5,0(a4)
    80000eb8:	2781                	sext.w	a5,a5
    80000eba:	dff5                	beqz	a5,80000eb6 <main+0x1a>
      ;
    __sync_synchronize();
    80000ebc:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ec0:	00001097          	auipc	ra,0x1
    80000ec4:	fae080e7          	jalr	-82(ra) # 80001e6e <cpuid>
    80000ec8:	85aa                	mv	a1,a0
    80000eca:	00008517          	auipc	a0,0x8
    80000ece:	1ee50513          	addi	a0,a0,494 # 800090b8 <digits+0x78>
    80000ed2:	fffff097          	auipc	ra,0xfffff
    80000ed6:	6b6080e7          	jalr	1718(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eda:	00000097          	auipc	ra,0x0
    80000ede:	0d8080e7          	jalr	216(ra) # 80000fb2 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ee2:	00002097          	auipc	ra,0x2
    80000ee6:	5da080e7          	jalr	1498(ra) # 800034bc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eea:	00006097          	auipc	ra,0x6
    80000eee:	b76080e7          	jalr	-1162(ra) # 80006a60 <plicinithart>
  }

  scheduler();        
    80000ef2:	00002097          	auipc	ra,0x2
    80000ef6:	954080e7          	jalr	-1708(ra) # 80002846 <scheduler>
    consoleinit();
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	556080e7          	jalr	1366(ra) # 80000450 <consoleinit>
    printfinit();
    80000f02:	00000097          	auipc	ra,0x0
    80000f06:	86c080e7          	jalr	-1940(ra) # 8000076e <printfinit>
    printf("\n");
    80000f0a:	00008517          	auipc	a0,0x8
    80000f0e:	43e50513          	addi	a0,a0,1086 # 80009348 <digits+0x308>
    80000f12:	fffff097          	auipc	ra,0xfffff
    80000f16:	676080e7          	jalr	1654(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f1a:	00008517          	auipc	a0,0x8
    80000f1e:	18650513          	addi	a0,a0,390 # 800090a0 <digits+0x60>
    80000f22:	fffff097          	auipc	ra,0xfffff
    80000f26:	666080e7          	jalr	1638(ra) # 80000588 <printf>
    printf("\n");
    80000f2a:	00008517          	auipc	a0,0x8
    80000f2e:	41e50513          	addi	a0,a0,1054 # 80009348 <digits+0x308>
    80000f32:	fffff097          	auipc	ra,0xfffff
    80000f36:	656080e7          	jalr	1622(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	b7e080e7          	jalr	-1154(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	322080e7          	jalr	802(ra) # 80001264 <kvminit>
    kvminithart();   // turn on paging
    80000f4a:	00000097          	auipc	ra,0x0
    80000f4e:	068080e7          	jalr	104(ra) # 80000fb2 <kvminithart>
    procinit();      // process table
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	656080e7          	jalr	1622(ra) # 800025a8 <procinit>
    trapinit();      // trap vectors
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	53a080e7          	jalr	1338(ra) # 80003494 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	55a080e7          	jalr	1370(ra) # 800034bc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f6a:	00006097          	auipc	ra,0x6
    80000f6e:	ae0080e7          	jalr	-1312(ra) # 80006a4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f72:	00006097          	auipc	ra,0x6
    80000f76:	aee080e7          	jalr	-1298(ra) # 80006a60 <plicinithart>
    binit();         // buffer cache
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	cce080e7          	jalr	-818(ra) # 80003c48 <binit>
    iinit();         // inode table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	35e080e7          	jalr	862(ra) # 800042e0 <iinit>
    fileinit();      // file table
    80000f8a:	00004097          	auipc	ra,0x4
    80000f8e:	308080e7          	jalr	776(ra) # 80005292 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f92:	00006097          	auipc	ra,0x6
    80000f96:	bf0080e7          	jalr	-1040(ra) # 80006b82 <virtio_disk_init>
    userinit();      // first user process
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	bbe080e7          	jalr	-1090(ra) # 80002b58 <userinit>
    __sync_synchronize();
    80000fa2:	0ff0000f          	fence
    started = 1;
    80000fa6:	4785                	li	a5,1
    80000fa8:	00009717          	auipc	a4,0x9
    80000fac:	06f72823          	sw	a5,112(a4) # 8000a018 <started>
    80000fb0:	b789                	j	80000ef2 <main+0x56>

0000000080000fb2 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fb2:	1141                	addi	sp,sp,-16
    80000fb4:	e422                	sd	s0,8(sp)
    80000fb6:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb8:	00009797          	auipc	a5,0x9
    80000fbc:	0687b783          	ld	a5,104(a5) # 8000a020 <kernel_pagetable>
    80000fc0:	83b1                	srli	a5,a5,0xc
    80000fc2:	577d                	li	a4,-1
    80000fc4:	177e                	slli	a4,a4,0x3f
    80000fc6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc8:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fcc:	12000073          	sfence.vma
  sfence_vma();
}
    80000fd0:	6422                	ld	s0,8(sp)
    80000fd2:	0141                	addi	sp,sp,16
    80000fd4:	8082                	ret

0000000080000fd6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd6:	7139                	addi	sp,sp,-64
    80000fd8:	fc06                	sd	ra,56(sp)
    80000fda:	f822                	sd	s0,48(sp)
    80000fdc:	f426                	sd	s1,40(sp)
    80000fde:	f04a                	sd	s2,32(sp)
    80000fe0:	ec4e                	sd	s3,24(sp)
    80000fe2:	e852                	sd	s4,16(sp)
    80000fe4:	e456                	sd	s5,8(sp)
    80000fe6:	e05a                	sd	s6,0(sp)
    80000fe8:	0080                	addi	s0,sp,64
    80000fea:	84aa                	mv	s1,a0
    80000fec:	89ae                	mv	s3,a1
    80000fee:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ff0:	57fd                	li	a5,-1
    80000ff2:	83e9                	srli	a5,a5,0x1a
    80000ff4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff8:	04b7f263          	bgeu	a5,a1,8000103c <walk+0x66>
    panic("walk");
    80000ffc:	00008517          	auipc	a0,0x8
    80001000:	0d450513          	addi	a0,a0,212 # 800090d0 <digits+0x90>
    80001004:	fffff097          	auipc	ra,0xfffff
    80001008:	53a080e7          	jalr	1338(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000100c:	060a8663          	beqz	s5,80001078 <walk+0xa2>
    80001010:	00000097          	auipc	ra,0x0
    80001014:	ae4080e7          	jalr	-1308(ra) # 80000af4 <kalloc>
    80001018:	84aa                	mv	s1,a0
    8000101a:	c529                	beqz	a0,80001064 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000101c:	6605                	lui	a2,0x1
    8000101e:	4581                	li	a1,0
    80001020:	00000097          	auipc	ra,0x0
    80001024:	cce080e7          	jalr	-818(ra) # 80000cee <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001028:	00c4d793          	srli	a5,s1,0xc
    8000102c:	07aa                	slli	a5,a5,0xa
    8000102e:	0017e793          	ori	a5,a5,1
    80001032:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001036:	3a5d                	addiw	s4,s4,-9
    80001038:	036a0063          	beq	s4,s6,80001058 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000103c:	0149d933          	srl	s2,s3,s4
    80001040:	1ff97913          	andi	s2,s2,511
    80001044:	090e                	slli	s2,s2,0x3
    80001046:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001048:	00093483          	ld	s1,0(s2)
    8000104c:	0014f793          	andi	a5,s1,1
    80001050:	dfd5                	beqz	a5,8000100c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001052:	80a9                	srli	s1,s1,0xa
    80001054:	04b2                	slli	s1,s1,0xc
    80001056:	b7c5                	j	80001036 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001058:	00c9d513          	srli	a0,s3,0xc
    8000105c:	1ff57513          	andi	a0,a0,511
    80001060:	050e                	slli	a0,a0,0x3
    80001062:	9526                	add	a0,a0,s1
}
    80001064:	70e2                	ld	ra,56(sp)
    80001066:	7442                	ld	s0,48(sp)
    80001068:	74a2                	ld	s1,40(sp)
    8000106a:	7902                	ld	s2,32(sp)
    8000106c:	69e2                	ld	s3,24(sp)
    8000106e:	6a42                	ld	s4,16(sp)
    80001070:	6aa2                	ld	s5,8(sp)
    80001072:	6b02                	ld	s6,0(sp)
    80001074:	6121                	addi	sp,sp,64
    80001076:	8082                	ret
        return 0;
    80001078:	4501                	li	a0,0
    8000107a:	b7ed                	j	80001064 <walk+0x8e>

000000008000107c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000107c:	57fd                	li	a5,-1
    8000107e:	83e9                	srli	a5,a5,0x1a
    80001080:	00b7f463          	bgeu	a5,a1,80001088 <walkaddr+0xc>
    return 0;
    80001084:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001086:	8082                	ret
{
    80001088:	1141                	addi	sp,sp,-16
    8000108a:	e406                	sd	ra,8(sp)
    8000108c:	e022                	sd	s0,0(sp)
    8000108e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001090:	4601                	li	a2,0
    80001092:	00000097          	auipc	ra,0x0
    80001096:	f44080e7          	jalr	-188(ra) # 80000fd6 <walk>
  if(pte == 0)
    8000109a:	c105                	beqz	a0,800010ba <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000109c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109e:	0117f693          	andi	a3,a5,17
    800010a2:	4745                	li	a4,17
    return 0;
    800010a4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a6:	00e68663          	beq	a3,a4,800010b2 <walkaddr+0x36>
}
    800010aa:	60a2                	ld	ra,8(sp)
    800010ac:	6402                	ld	s0,0(sp)
    800010ae:	0141                	addi	sp,sp,16
    800010b0:	8082                	ret
  pa = PTE2PA(*pte);
    800010b2:	00a7d513          	srli	a0,a5,0xa
    800010b6:	0532                	slli	a0,a0,0xc
  return pa;
    800010b8:	bfcd                	j	800010aa <walkaddr+0x2e>
    return 0;
    800010ba:	4501                	li	a0,0
    800010bc:	b7fd                	j	800010aa <walkaddr+0x2e>

00000000800010be <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010be:	715d                	addi	sp,sp,-80
    800010c0:	e486                	sd	ra,72(sp)
    800010c2:	e0a2                	sd	s0,64(sp)
    800010c4:	fc26                	sd	s1,56(sp)
    800010c6:	f84a                	sd	s2,48(sp)
    800010c8:	f44e                	sd	s3,40(sp)
    800010ca:	f052                	sd	s4,32(sp)
    800010cc:	ec56                	sd	s5,24(sp)
    800010ce:	e85a                	sd	s6,16(sp)
    800010d0:	e45e                	sd	s7,8(sp)
    800010d2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d4:	c205                	beqz	a2,800010f4 <mappages+0x36>
    800010d6:	8aaa                	mv	s5,a0
    800010d8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010da:	77fd                	lui	a5,0xfffff
    800010dc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010e0:	15fd                	addi	a1,a1,-1
    800010e2:	00c589b3          	add	s3,a1,a2
    800010e6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ea:	8952                	mv	s2,s4
    800010ec:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010f0:	6b85                	lui	s7,0x1
    800010f2:	a015                	j	80001116 <mappages+0x58>
    panic("mappages: size");
    800010f4:	00008517          	auipc	a0,0x8
    800010f8:	fe450513          	addi	a0,a0,-28 # 800090d8 <digits+0x98>
    800010fc:	fffff097          	auipc	ra,0xfffff
    80001100:	442080e7          	jalr	1090(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001104:	00008517          	auipc	a0,0x8
    80001108:	fe450513          	addi	a0,a0,-28 # 800090e8 <digits+0xa8>
    8000110c:	fffff097          	auipc	ra,0xfffff
    80001110:	432080e7          	jalr	1074(ra) # 8000053e <panic>
    a += PGSIZE;
    80001114:	995e                	add	s2,s2,s7
  for(;;){
    80001116:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000111a:	4605                	li	a2,1
    8000111c:	85ca                	mv	a1,s2
    8000111e:	8556                	mv	a0,s5
    80001120:	00000097          	auipc	ra,0x0
    80001124:	eb6080e7          	jalr	-330(ra) # 80000fd6 <walk>
    80001128:	cd19                	beqz	a0,80001146 <mappages+0x88>
    if(*pte & PTE_V)
    8000112a:	611c                	ld	a5,0(a0)
    8000112c:	8b85                	andi	a5,a5,1
    8000112e:	fbf9                	bnez	a5,80001104 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001130:	80b1                	srli	s1,s1,0xc
    80001132:	04aa                	slli	s1,s1,0xa
    80001134:	0164e4b3          	or	s1,s1,s6
    80001138:	0014e493          	ori	s1,s1,1
    8000113c:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113e:	fd391be3          	bne	s2,s3,80001114 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001142:	4501                	li	a0,0
    80001144:	a011                	j	80001148 <mappages+0x8a>
      return -1;
    80001146:	557d                	li	a0,-1
}
    80001148:	60a6                	ld	ra,72(sp)
    8000114a:	6406                	ld	s0,64(sp)
    8000114c:	74e2                	ld	s1,56(sp)
    8000114e:	7942                	ld	s2,48(sp)
    80001150:	79a2                	ld	s3,40(sp)
    80001152:	7a02                	ld	s4,32(sp)
    80001154:	6ae2                	ld	s5,24(sp)
    80001156:	6b42                	ld	s6,16(sp)
    80001158:	6ba2                	ld	s7,8(sp)
    8000115a:	6161                	addi	sp,sp,80
    8000115c:	8082                	ret

000000008000115e <kvmmap>:
{
    8000115e:	1141                	addi	sp,sp,-16
    80001160:	e406                	sd	ra,8(sp)
    80001162:	e022                	sd	s0,0(sp)
    80001164:	0800                	addi	s0,sp,16
    80001166:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001168:	86b2                	mv	a3,a2
    8000116a:	863e                	mv	a2,a5
    8000116c:	00000097          	auipc	ra,0x0
    80001170:	f52080e7          	jalr	-174(ra) # 800010be <mappages>
    80001174:	e509                	bnez	a0,8000117e <kvmmap+0x20>
}
    80001176:	60a2                	ld	ra,8(sp)
    80001178:	6402                	ld	s0,0(sp)
    8000117a:	0141                	addi	sp,sp,16
    8000117c:	8082                	ret
    panic("kvmmap");
    8000117e:	00008517          	auipc	a0,0x8
    80001182:	f7a50513          	addi	a0,a0,-134 # 800090f8 <digits+0xb8>
    80001186:	fffff097          	auipc	ra,0xfffff
    8000118a:	3b8080e7          	jalr	952(ra) # 8000053e <panic>

000000008000118e <kvmmake>:
{
    8000118e:	1101                	addi	sp,sp,-32
    80001190:	ec06                	sd	ra,24(sp)
    80001192:	e822                	sd	s0,16(sp)
    80001194:	e426                	sd	s1,8(sp)
    80001196:	e04a                	sd	s2,0(sp)
    80001198:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	95a080e7          	jalr	-1702(ra) # 80000af4 <kalloc>
    800011a2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a4:	6605                	lui	a2,0x1
    800011a6:	4581                	li	a1,0
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	b46080e7          	jalr	-1210(ra) # 80000cee <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b0:	4719                	li	a4,6
    800011b2:	6685                	lui	a3,0x1
    800011b4:	10000637          	lui	a2,0x10000
    800011b8:	100005b7          	lui	a1,0x10000
    800011bc:	8526                	mv	a0,s1
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	fa0080e7          	jalr	-96(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c6:	4719                	li	a4,6
    800011c8:	6685                	lui	a3,0x1
    800011ca:	10001637          	lui	a2,0x10001
    800011ce:	100015b7          	lui	a1,0x10001
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	f8a080e7          	jalr	-118(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	004006b7          	lui	a3,0x400
    800011e2:	0c000637          	lui	a2,0xc000
    800011e6:	0c0005b7          	lui	a1,0xc000
    800011ea:	8526                	mv	a0,s1
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	f72080e7          	jalr	-142(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f4:	00008917          	auipc	s2,0x8
    800011f8:	e0c90913          	addi	s2,s2,-500 # 80009000 <etext>
    800011fc:	4729                	li	a4,10
    800011fe:	80008697          	auipc	a3,0x80008
    80001202:	e0268693          	addi	a3,a3,-510 # 9000 <_entry-0x7fff7000>
    80001206:	4605                	li	a2,1
    80001208:	067e                	slli	a2,a2,0x1f
    8000120a:	85b2                	mv	a1,a2
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f50080e7          	jalr	-176(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001216:	4719                	li	a4,6
    80001218:	46c5                	li	a3,17
    8000121a:	06ee                	slli	a3,a3,0x1b
    8000121c:	412686b3          	sub	a3,a3,s2
    80001220:	864a                	mv	a2,s2
    80001222:	85ca                	mv	a1,s2
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f38080e7          	jalr	-200(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122e:	4729                	li	a4,10
    80001230:	6685                	lui	a3,0x1
    80001232:	00007617          	auipc	a2,0x7
    80001236:	dce60613          	addi	a2,a2,-562 # 80008000 <_trampoline>
    8000123a:	040005b7          	lui	a1,0x4000
    8000123e:	15fd                	addi	a1,a1,-1
    80001240:	05b2                	slli	a1,a1,0xc
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f1a080e7          	jalr	-230(ra) # 8000115e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000124c:	8526                	mv	a0,s1
    8000124e:	00001097          	auipc	ra,0x1
    80001252:	b8a080e7          	jalr	-1142(ra) # 80001dd8 <proc_mapstacks>
}
    80001256:	8526                	mv	a0,s1
    80001258:	60e2                	ld	ra,24(sp)
    8000125a:	6442                	ld	s0,16(sp)
    8000125c:	64a2                	ld	s1,8(sp)
    8000125e:	6902                	ld	s2,0(sp)
    80001260:	6105                	addi	sp,sp,32
    80001262:	8082                	ret

0000000080001264 <kvminit>:
{
    80001264:	1141                	addi	sp,sp,-16
    80001266:	e406                	sd	ra,8(sp)
    80001268:	e022                	sd	s0,0(sp)
    8000126a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f22080e7          	jalr	-222(ra) # 8000118e <kvmmake>
    80001274:	00009797          	auipc	a5,0x9
    80001278:	daa7b623          	sd	a0,-596(a5) # 8000a020 <kernel_pagetable>
}
    8000127c:	60a2                	ld	ra,8(sp)
    8000127e:	6402                	ld	s0,0(sp)
    80001280:	0141                	addi	sp,sp,16
    80001282:	8082                	ret

0000000080001284 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001284:	715d                	addi	sp,sp,-80
    80001286:	e486                	sd	ra,72(sp)
    80001288:	e0a2                	sd	s0,64(sp)
    8000128a:	fc26                	sd	s1,56(sp)
    8000128c:	f84a                	sd	s2,48(sp)
    8000128e:	f44e                	sd	s3,40(sp)
    80001290:	f052                	sd	s4,32(sp)
    80001292:	ec56                	sd	s5,24(sp)
    80001294:	e85a                	sd	s6,16(sp)
    80001296:	e45e                	sd	s7,8(sp)
    80001298:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129a:	03459793          	slli	a5,a1,0x34
    8000129e:	e795                	bnez	a5,800012ca <uvmunmap+0x46>
    800012a0:	8a2a                	mv	s4,a0
    800012a2:	892e                	mv	s2,a1
    800012a4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a6:	0632                	slli	a2,a2,0xc
    800012a8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ac:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ae:	6b05                	lui	s6,0x1
    800012b0:	0735e863          	bltu	a1,s3,80001320 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b4:	60a6                	ld	ra,72(sp)
    800012b6:	6406                	ld	s0,64(sp)
    800012b8:	74e2                	ld	s1,56(sp)
    800012ba:	7942                	ld	s2,48(sp)
    800012bc:	79a2                	ld	s3,40(sp)
    800012be:	7a02                	ld	s4,32(sp)
    800012c0:	6ae2                	ld	s5,24(sp)
    800012c2:	6b42                	ld	s6,16(sp)
    800012c4:	6ba2                	ld	s7,8(sp)
    800012c6:	6161                	addi	sp,sp,80
    800012c8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ca:	00008517          	auipc	a0,0x8
    800012ce:	e3650513          	addi	a0,a0,-458 # 80009100 <digits+0xc0>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012da:	00008517          	auipc	a0,0x8
    800012de:	e3e50513          	addi	a0,a0,-450 # 80009118 <digits+0xd8>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ea:	00008517          	auipc	a0,0x8
    800012ee:	e3e50513          	addi	a0,a0,-450 # 80009128 <digits+0xe8>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012fa:	00008517          	auipc	a0,0x8
    800012fe:	e4650513          	addi	a0,a0,-442 # 80009140 <digits+0x100>
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	23c080e7          	jalr	572(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    8000130a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000130c:	0532                	slli	a0,a0,0xc
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	6ea080e7          	jalr	1770(ra) # 800009f8 <kfree>
    *pte = 0;
    80001316:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000131a:	995a                	add	s2,s2,s6
    8000131c:	f9397ce3          	bgeu	s2,s3,800012b4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001320:	4601                	li	a2,0
    80001322:	85ca                	mv	a1,s2
    80001324:	8552                	mv	a0,s4
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	cb0080e7          	jalr	-848(ra) # 80000fd6 <walk>
    8000132e:	84aa                	mv	s1,a0
    80001330:	d54d                	beqz	a0,800012da <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001332:	6108                	ld	a0,0(a0)
    80001334:	00157793          	andi	a5,a0,1
    80001338:	dbcd                	beqz	a5,800012ea <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000133a:	3ff57793          	andi	a5,a0,1023
    8000133e:	fb778ee3          	beq	a5,s7,800012fa <uvmunmap+0x76>
    if(do_free){
    80001342:	fc0a8ae3          	beqz	s5,80001316 <uvmunmap+0x92>
    80001346:	b7d1                	j	8000130a <uvmunmap+0x86>

0000000080001348 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001348:	1101                	addi	sp,sp,-32
    8000134a:	ec06                	sd	ra,24(sp)
    8000134c:	e822                	sd	s0,16(sp)
    8000134e:	e426                	sd	s1,8(sp)
    80001350:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	7a2080e7          	jalr	1954(ra) # 80000af4 <kalloc>
    8000135a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000135c:	c519                	beqz	a0,8000136a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135e:	6605                	lui	a2,0x1
    80001360:	4581                	li	a1,0
    80001362:	00000097          	auipc	ra,0x0
    80001366:	98c080e7          	jalr	-1652(ra) # 80000cee <memset>
  return pagetable;
}
    8000136a:	8526                	mv	a0,s1
    8000136c:	60e2                	ld	ra,24(sp)
    8000136e:	6442                	ld	s0,16(sp)
    80001370:	64a2                	ld	s1,8(sp)
    80001372:	6105                	addi	sp,sp,32
    80001374:	8082                	ret

0000000080001376 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001376:	7179                	addi	sp,sp,-48
    80001378:	f406                	sd	ra,40(sp)
    8000137a:	f022                	sd	s0,32(sp)
    8000137c:	ec26                	sd	s1,24(sp)
    8000137e:	e84a                	sd	s2,16(sp)
    80001380:	e44e                	sd	s3,8(sp)
    80001382:	e052                	sd	s4,0(sp)
    80001384:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001386:	6785                	lui	a5,0x1
    80001388:	04f67863          	bgeu	a2,a5,800013d8 <uvminit+0x62>
    8000138c:	8a2a                	mv	s4,a0
    8000138e:	89ae                	mv	s3,a1
    80001390:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	762080e7          	jalr	1890(ra) # 80000af4 <kalloc>
    8000139a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000139c:	6605                	lui	a2,0x1
    8000139e:	4581                	li	a1,0
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	94e080e7          	jalr	-1714(ra) # 80000cee <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a8:	4779                	li	a4,30
    800013aa:	86ca                	mv	a3,s2
    800013ac:	6605                	lui	a2,0x1
    800013ae:	4581                	li	a1,0
    800013b0:	8552                	mv	a0,s4
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	d0c080e7          	jalr	-756(ra) # 800010be <mappages>
  memmove(mem, src, sz);
    800013ba:	8626                	mv	a2,s1
    800013bc:	85ce                	mv	a1,s3
    800013be:	854a                	mv	a0,s2
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	98e080e7          	jalr	-1650(ra) # 80000d4e <memmove>
}
    800013c8:	70a2                	ld	ra,40(sp)
    800013ca:	7402                	ld	s0,32(sp)
    800013cc:	64e2                	ld	s1,24(sp)
    800013ce:	6942                	ld	s2,16(sp)
    800013d0:	69a2                	ld	s3,8(sp)
    800013d2:	6a02                	ld	s4,0(sp)
    800013d4:	6145                	addi	sp,sp,48
    800013d6:	8082                	ret
    panic("inituvm: more than a page");
    800013d8:	00008517          	auipc	a0,0x8
    800013dc:	d8050513          	addi	a0,a0,-640 # 80009158 <digits+0x118>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	15e080e7          	jalr	350(ra) # 8000053e <panic>

00000000800013e8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e8:	1101                	addi	sp,sp,-32
    800013ea:	ec06                	sd	ra,24(sp)
    800013ec:	e822                	sd	s0,16(sp)
    800013ee:	e426                	sd	s1,8(sp)
    800013f0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f4:	00b67d63          	bgeu	a2,a1,8000140e <uvmdealloc+0x26>
    800013f8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fa:	6785                	lui	a5,0x1
    800013fc:	17fd                	addi	a5,a5,-1
    800013fe:	00f60733          	add	a4,a2,a5
    80001402:	767d                	lui	a2,0xfffff
    80001404:	8f71                	and	a4,a4,a2
    80001406:	97ae                	add	a5,a5,a1
    80001408:	8ff1                	and	a5,a5,a2
    8000140a:	00f76863          	bltu	a4,a5,8000141a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140e:	8526                	mv	a0,s1
    80001410:	60e2                	ld	ra,24(sp)
    80001412:	6442                	ld	s0,16(sp)
    80001414:	64a2                	ld	s1,8(sp)
    80001416:	6105                	addi	sp,sp,32
    80001418:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141a:	8f99                	sub	a5,a5,a4
    8000141c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141e:	4685                	li	a3,1
    80001420:	0007861b          	sext.w	a2,a5
    80001424:	85ba                	mv	a1,a4
    80001426:	00000097          	auipc	ra,0x0
    8000142a:	e5e080e7          	jalr	-418(ra) # 80001284 <uvmunmap>
    8000142e:	b7c5                	j	8000140e <uvmdealloc+0x26>

0000000080001430 <uvmalloc>:
  if(newsz < oldsz)
    80001430:	0ab66163          	bltu	a2,a1,800014d2 <uvmalloc+0xa2>
{
    80001434:	7139                	addi	sp,sp,-64
    80001436:	fc06                	sd	ra,56(sp)
    80001438:	f822                	sd	s0,48(sp)
    8000143a:	f426                	sd	s1,40(sp)
    8000143c:	f04a                	sd	s2,32(sp)
    8000143e:	ec4e                	sd	s3,24(sp)
    80001440:	e852                	sd	s4,16(sp)
    80001442:	e456                	sd	s5,8(sp)
    80001444:	0080                	addi	s0,sp,64
    80001446:	8aaa                	mv	s5,a0
    80001448:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144a:	6985                	lui	s3,0x1
    8000144c:	19fd                	addi	s3,s3,-1
    8000144e:	95ce                	add	a1,a1,s3
    80001450:	79fd                	lui	s3,0xfffff
    80001452:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001456:	08c9f063          	bgeu	s3,a2,800014d6 <uvmalloc+0xa6>
    8000145a:	894e                	mv	s2,s3
    mem = kalloc();
    8000145c:	fffff097          	auipc	ra,0xfffff
    80001460:	698080e7          	jalr	1688(ra) # 80000af4 <kalloc>
    80001464:	84aa                	mv	s1,a0
    if(mem == 0){
    80001466:	c51d                	beqz	a0,80001494 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001468:	6605                	lui	a2,0x1
    8000146a:	4581                	li	a1,0
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	882080e7          	jalr	-1918(ra) # 80000cee <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001474:	4779                	li	a4,30
    80001476:	86a6                	mv	a3,s1
    80001478:	6605                	lui	a2,0x1
    8000147a:	85ca                	mv	a1,s2
    8000147c:	8556                	mv	a0,s5
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	c40080e7          	jalr	-960(ra) # 800010be <mappages>
    80001486:	e905                	bnez	a0,800014b6 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001488:	6785                	lui	a5,0x1
    8000148a:	993e                	add	s2,s2,a5
    8000148c:	fd4968e3          	bltu	s2,s4,8000145c <uvmalloc+0x2c>
  return newsz;
    80001490:	8552                	mv	a0,s4
    80001492:	a809                	j	800014a4 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001494:	864e                	mv	a2,s3
    80001496:	85ca                	mv	a1,s2
    80001498:	8556                	mv	a0,s5
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	f4e080e7          	jalr	-178(ra) # 800013e8 <uvmdealloc>
      return 0;
    800014a2:	4501                	li	a0,0
}
    800014a4:	70e2                	ld	ra,56(sp)
    800014a6:	7442                	ld	s0,48(sp)
    800014a8:	74a2                	ld	s1,40(sp)
    800014aa:	7902                	ld	s2,32(sp)
    800014ac:	69e2                	ld	s3,24(sp)
    800014ae:	6a42                	ld	s4,16(sp)
    800014b0:	6aa2                	ld	s5,8(sp)
    800014b2:	6121                	addi	sp,sp,64
    800014b4:	8082                	ret
      kfree(mem);
    800014b6:	8526                	mv	a0,s1
    800014b8:	fffff097          	auipc	ra,0xfffff
    800014bc:	540080e7          	jalr	1344(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c0:	864e                	mv	a2,s3
    800014c2:	85ca                	mv	a1,s2
    800014c4:	8556                	mv	a0,s5
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	f22080e7          	jalr	-222(ra) # 800013e8 <uvmdealloc>
      return 0;
    800014ce:	4501                	li	a0,0
    800014d0:	bfd1                	j	800014a4 <uvmalloc+0x74>
    return oldsz;
    800014d2:	852e                	mv	a0,a1
}
    800014d4:	8082                	ret
  return newsz;
    800014d6:	8532                	mv	a0,a2
    800014d8:	b7f1                	j	800014a4 <uvmalloc+0x74>

00000000800014da <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014da:	7179                	addi	sp,sp,-48
    800014dc:	f406                	sd	ra,40(sp)
    800014de:	f022                	sd	s0,32(sp)
    800014e0:	ec26                	sd	s1,24(sp)
    800014e2:	e84a                	sd	s2,16(sp)
    800014e4:	e44e                	sd	s3,8(sp)
    800014e6:	e052                	sd	s4,0(sp)
    800014e8:	1800                	addi	s0,sp,48
    800014ea:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ec:	84aa                	mv	s1,a0
    800014ee:	6905                	lui	s2,0x1
    800014f0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	4985                	li	s3,1
    800014f4:	a821                	j	8000150c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f8:	0532                	slli	a0,a0,0xc
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	fe0080e7          	jalr	-32(ra) # 800014da <freewalk>
      pagetable[i] = 0;
    80001502:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001506:	04a1                	addi	s1,s1,8
    80001508:	03248163          	beq	s1,s2,8000152a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000150c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000150e:	00f57793          	andi	a5,a0,15
    80001512:	ff3782e3          	beq	a5,s3,800014f6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001516:	8905                	andi	a0,a0,1
    80001518:	d57d                	beqz	a0,80001506 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151a:	00008517          	auipc	a0,0x8
    8000151e:	c5e50513          	addi	a0,a0,-930 # 80009178 <digits+0x138>
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	01c080e7          	jalr	28(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000152a:	8552                	mv	a0,s4
    8000152c:	fffff097          	auipc	ra,0xfffff
    80001530:	4cc080e7          	jalr	1228(ra) # 800009f8 <kfree>
}
    80001534:	70a2                	ld	ra,40(sp)
    80001536:	7402                	ld	s0,32(sp)
    80001538:	64e2                	ld	s1,24(sp)
    8000153a:	6942                	ld	s2,16(sp)
    8000153c:	69a2                	ld	s3,8(sp)
    8000153e:	6a02                	ld	s4,0(sp)
    80001540:	6145                	addi	sp,sp,48
    80001542:	8082                	ret

0000000080001544 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001544:	1101                	addi	sp,sp,-32
    80001546:	ec06                	sd	ra,24(sp)
    80001548:	e822                	sd	s0,16(sp)
    8000154a:	e426                	sd	s1,8(sp)
    8000154c:	1000                	addi	s0,sp,32
    8000154e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001550:	e999                	bnez	a1,80001566 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001552:	8526                	mv	a0,s1
    80001554:	00000097          	auipc	ra,0x0
    80001558:	f86080e7          	jalr	-122(ra) # 800014da <freewalk>
}
    8000155c:	60e2                	ld	ra,24(sp)
    8000155e:	6442                	ld	s0,16(sp)
    80001560:	64a2                	ld	s1,8(sp)
    80001562:	6105                	addi	sp,sp,32
    80001564:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001566:	6605                	lui	a2,0x1
    80001568:	167d                	addi	a2,a2,-1
    8000156a:	962e                	add	a2,a2,a1
    8000156c:	4685                	li	a3,1
    8000156e:	8231                	srli	a2,a2,0xc
    80001570:	4581                	li	a1,0
    80001572:	00000097          	auipc	ra,0x0
    80001576:	d12080e7          	jalr	-750(ra) # 80001284 <uvmunmap>
    8000157a:	bfe1                	j	80001552 <uvmfree+0xe>

000000008000157c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000157c:	c679                	beqz	a2,8000164a <uvmcopy+0xce>
{
    8000157e:	715d                	addi	sp,sp,-80
    80001580:	e486                	sd	ra,72(sp)
    80001582:	e0a2                	sd	s0,64(sp)
    80001584:	fc26                	sd	s1,56(sp)
    80001586:	f84a                	sd	s2,48(sp)
    80001588:	f44e                	sd	s3,40(sp)
    8000158a:	f052                	sd	s4,32(sp)
    8000158c:	ec56                	sd	s5,24(sp)
    8000158e:	e85a                	sd	s6,16(sp)
    80001590:	e45e                	sd	s7,8(sp)
    80001592:	0880                	addi	s0,sp,80
    80001594:	8b2a                	mv	s6,a0
    80001596:	8aae                	mv	s5,a1
    80001598:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000159c:	4601                	li	a2,0
    8000159e:	85ce                	mv	a1,s3
    800015a0:	855a                	mv	a0,s6
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	a34080e7          	jalr	-1484(ra) # 80000fd6 <walk>
    800015aa:	c531                	beqz	a0,800015f6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015ac:	6118                	ld	a4,0(a0)
    800015ae:	00177793          	andi	a5,a4,1
    800015b2:	cbb1                	beqz	a5,80001606 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b4:	00a75593          	srli	a1,a4,0xa
    800015b8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015bc:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	534080e7          	jalr	1332(ra) # 80000af4 <kalloc>
    800015c8:	892a                	mv	s2,a0
    800015ca:	c939                	beqz	a0,80001620 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015cc:	6605                	lui	a2,0x1
    800015ce:	85de                	mv	a1,s7
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	77e080e7          	jalr	1918(ra) # 80000d4e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d8:	8726                	mv	a4,s1
    800015da:	86ca                	mv	a3,s2
    800015dc:	6605                	lui	a2,0x1
    800015de:	85ce                	mv	a1,s3
    800015e0:	8556                	mv	a0,s5
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	adc080e7          	jalr	-1316(ra) # 800010be <mappages>
    800015ea:	e515                	bnez	a0,80001616 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015ec:	6785                	lui	a5,0x1
    800015ee:	99be                	add	s3,s3,a5
    800015f0:	fb49e6e3          	bltu	s3,s4,8000159c <uvmcopy+0x20>
    800015f4:	a081                	j	80001634 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f6:	00008517          	auipc	a0,0x8
    800015fa:	b9250513          	addi	a0,a0,-1134 # 80009188 <digits+0x148>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001606:	00008517          	auipc	a0,0x8
    8000160a:	ba250513          	addi	a0,a0,-1118 # 800091a8 <digits+0x168>
    8000160e:	fffff097          	auipc	ra,0xfffff
    80001612:	f30080e7          	jalr	-208(ra) # 8000053e <panic>
      kfree(mem);
    80001616:	854a                	mv	a0,s2
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	3e0080e7          	jalr	992(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001620:	4685                	li	a3,1
    80001622:	00c9d613          	srli	a2,s3,0xc
    80001626:	4581                	li	a1,0
    80001628:	8556                	mv	a0,s5
    8000162a:	00000097          	auipc	ra,0x0
    8000162e:	c5a080e7          	jalr	-934(ra) # 80001284 <uvmunmap>
  return -1;
    80001632:	557d                	li	a0,-1
}
    80001634:	60a6                	ld	ra,72(sp)
    80001636:	6406                	ld	s0,64(sp)
    80001638:	74e2                	ld	s1,56(sp)
    8000163a:	7942                	ld	s2,48(sp)
    8000163c:	79a2                	ld	s3,40(sp)
    8000163e:	7a02                	ld	s4,32(sp)
    80001640:	6ae2                	ld	s5,24(sp)
    80001642:	6b42                	ld	s6,16(sp)
    80001644:	6ba2                	ld	s7,8(sp)
    80001646:	6161                	addi	sp,sp,80
    80001648:	8082                	ret
  return 0;
    8000164a:	4501                	li	a0,0
}
    8000164c:	8082                	ret

000000008000164e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000164e:	1141                	addi	sp,sp,-16
    80001650:	e406                	sd	ra,8(sp)
    80001652:	e022                	sd	s0,0(sp)
    80001654:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001656:	4601                	li	a2,0
    80001658:	00000097          	auipc	ra,0x0
    8000165c:	97e080e7          	jalr	-1666(ra) # 80000fd6 <walk>
  if(pte == 0)
    80001660:	c901                	beqz	a0,80001670 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001662:	611c                	ld	a5,0(a0)
    80001664:	9bbd                	andi	a5,a5,-17
    80001666:	e11c                	sd	a5,0(a0)
}
    80001668:	60a2                	ld	ra,8(sp)
    8000166a:	6402                	ld	s0,0(sp)
    8000166c:	0141                	addi	sp,sp,16
    8000166e:	8082                	ret
    panic("uvmclear");
    80001670:	00008517          	auipc	a0,0x8
    80001674:	b5850513          	addi	a0,a0,-1192 # 800091c8 <digits+0x188>
    80001678:	fffff097          	auipc	ra,0xfffff
    8000167c:	ec6080e7          	jalr	-314(ra) # 8000053e <panic>

0000000080001680 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001680:	c6bd                	beqz	a3,800016ee <copyout+0x6e>
{
    80001682:	715d                	addi	sp,sp,-80
    80001684:	e486                	sd	ra,72(sp)
    80001686:	e0a2                	sd	s0,64(sp)
    80001688:	fc26                	sd	s1,56(sp)
    8000168a:	f84a                	sd	s2,48(sp)
    8000168c:	f44e                	sd	s3,40(sp)
    8000168e:	f052                	sd	s4,32(sp)
    80001690:	ec56                	sd	s5,24(sp)
    80001692:	e85a                	sd	s6,16(sp)
    80001694:	e45e                	sd	s7,8(sp)
    80001696:	e062                	sd	s8,0(sp)
    80001698:	0880                	addi	s0,sp,80
    8000169a:	8b2a                	mv	s6,a0
    8000169c:	8c2e                	mv	s8,a1
    8000169e:	8a32                	mv	s4,a2
    800016a0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a4:	6a85                	lui	s5,0x1
    800016a6:	a015                	j	800016ca <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a8:	9562                	add	a0,a0,s8
    800016aa:	0004861b          	sext.w	a2,s1
    800016ae:	85d2                	mv	a1,s4
    800016b0:	41250533          	sub	a0,a0,s2
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	69a080e7          	jalr	1690(ra) # 80000d4e <memmove>

    len -= n;
    800016bc:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c6:	02098263          	beqz	s3,800016ea <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ca:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ce:	85ca                	mv	a1,s2
    800016d0:	855a                	mv	a0,s6
    800016d2:	00000097          	auipc	ra,0x0
    800016d6:	9aa080e7          	jalr	-1622(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    800016da:	cd01                	beqz	a0,800016f2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016dc:	418904b3          	sub	s1,s2,s8
    800016e0:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e2:	fc99f3e3          	bgeu	s3,s1,800016a8 <copyout+0x28>
    800016e6:	84ce                	mv	s1,s3
    800016e8:	b7c1                	j	800016a8 <copyout+0x28>
  }
  return 0;
    800016ea:	4501                	li	a0,0
    800016ec:	a021                	j	800016f4 <copyout+0x74>
    800016ee:	4501                	li	a0,0
}
    800016f0:	8082                	ret
      return -1;
    800016f2:	557d                	li	a0,-1
}
    800016f4:	60a6                	ld	ra,72(sp)
    800016f6:	6406                	ld	s0,64(sp)
    800016f8:	74e2                	ld	s1,56(sp)
    800016fa:	7942                	ld	s2,48(sp)
    800016fc:	79a2                	ld	s3,40(sp)
    800016fe:	7a02                	ld	s4,32(sp)
    80001700:	6ae2                	ld	s5,24(sp)
    80001702:	6b42                	ld	s6,16(sp)
    80001704:	6ba2                	ld	s7,8(sp)
    80001706:	6c02                	ld	s8,0(sp)
    80001708:	6161                	addi	sp,sp,80
    8000170a:	8082                	ret

000000008000170c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000170c:	c6bd                	beqz	a3,8000177a <copyin+0x6e>
{
    8000170e:	715d                	addi	sp,sp,-80
    80001710:	e486                	sd	ra,72(sp)
    80001712:	e0a2                	sd	s0,64(sp)
    80001714:	fc26                	sd	s1,56(sp)
    80001716:	f84a                	sd	s2,48(sp)
    80001718:	f44e                	sd	s3,40(sp)
    8000171a:	f052                	sd	s4,32(sp)
    8000171c:	ec56                	sd	s5,24(sp)
    8000171e:	e85a                	sd	s6,16(sp)
    80001720:	e45e                	sd	s7,8(sp)
    80001722:	e062                	sd	s8,0(sp)
    80001724:	0880                	addi	s0,sp,80
    80001726:	8b2a                	mv	s6,a0
    80001728:	8a2e                	mv	s4,a1
    8000172a:	8c32                	mv	s8,a2
    8000172c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000172e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001730:	6a85                	lui	s5,0x1
    80001732:	a015                	j	80001756 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001734:	9562                	add	a0,a0,s8
    80001736:	0004861b          	sext.w	a2,s1
    8000173a:	412505b3          	sub	a1,a0,s2
    8000173e:	8552                	mv	a0,s4
    80001740:	fffff097          	auipc	ra,0xfffff
    80001744:	60e080e7          	jalr	1550(ra) # 80000d4e <memmove>

    len -= n;
    80001748:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000174c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000174e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001752:	02098263          	beqz	s3,80001776 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001756:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175a:	85ca                	mv	a1,s2
    8000175c:	855a                	mv	a0,s6
    8000175e:	00000097          	auipc	ra,0x0
    80001762:	91e080e7          	jalr	-1762(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    80001766:	cd01                	beqz	a0,8000177e <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001768:	418904b3          	sub	s1,s2,s8
    8000176c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000176e:	fc99f3e3          	bgeu	s3,s1,80001734 <copyin+0x28>
    80001772:	84ce                	mv	s1,s3
    80001774:	b7c1                	j	80001734 <copyin+0x28>
  }
  return 0;
    80001776:	4501                	li	a0,0
    80001778:	a021                	j	80001780 <copyin+0x74>
    8000177a:	4501                	li	a0,0
}
    8000177c:	8082                	ret
      return -1;
    8000177e:	557d                	li	a0,-1
}
    80001780:	60a6                	ld	ra,72(sp)
    80001782:	6406                	ld	s0,64(sp)
    80001784:	74e2                	ld	s1,56(sp)
    80001786:	7942                	ld	s2,48(sp)
    80001788:	79a2                	ld	s3,40(sp)
    8000178a:	7a02                	ld	s4,32(sp)
    8000178c:	6ae2                	ld	s5,24(sp)
    8000178e:	6b42                	ld	s6,16(sp)
    80001790:	6ba2                	ld	s7,8(sp)
    80001792:	6c02                	ld	s8,0(sp)
    80001794:	6161                	addi	sp,sp,80
    80001796:	8082                	ret

0000000080001798 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001798:	c6c5                	beqz	a3,80001840 <copyinstr+0xa8>
{
    8000179a:	715d                	addi	sp,sp,-80
    8000179c:	e486                	sd	ra,72(sp)
    8000179e:	e0a2                	sd	s0,64(sp)
    800017a0:	fc26                	sd	s1,56(sp)
    800017a2:	f84a                	sd	s2,48(sp)
    800017a4:	f44e                	sd	s3,40(sp)
    800017a6:	f052                	sd	s4,32(sp)
    800017a8:	ec56                	sd	s5,24(sp)
    800017aa:	e85a                	sd	s6,16(sp)
    800017ac:	e45e                	sd	s7,8(sp)
    800017ae:	0880                	addi	s0,sp,80
    800017b0:	8a2a                	mv	s4,a0
    800017b2:	8b2e                	mv	s6,a1
    800017b4:	8bb2                	mv	s7,a2
    800017b6:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ba:	6985                	lui	s3,0x1
    800017bc:	a035                	j	800017e8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017be:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c4:	0017b793          	seqz	a5,a5
    800017c8:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017cc:	60a6                	ld	ra,72(sp)
    800017ce:	6406                	ld	s0,64(sp)
    800017d0:	74e2                	ld	s1,56(sp)
    800017d2:	7942                	ld	s2,48(sp)
    800017d4:	79a2                	ld	s3,40(sp)
    800017d6:	7a02                	ld	s4,32(sp)
    800017d8:	6ae2                	ld	s5,24(sp)
    800017da:	6b42                	ld	s6,16(sp)
    800017dc:	6ba2                	ld	s7,8(sp)
    800017de:	6161                	addi	sp,sp,80
    800017e0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e6:	c8a9                	beqz	s1,80001838 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ec:	85ca                	mv	a1,s2
    800017ee:	8552                	mv	a0,s4
    800017f0:	00000097          	auipc	ra,0x0
    800017f4:	88c080e7          	jalr	-1908(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    800017f8:	c131                	beqz	a0,8000183c <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fa:	41790833          	sub	a6,s2,s7
    800017fe:	984e                	add	a6,a6,s3
    if(n > max)
    80001800:	0104f363          	bgeu	s1,a6,80001806 <copyinstr+0x6e>
    80001804:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001806:	955e                	add	a0,a0,s7
    80001808:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000180c:	fc080be3          	beqz	a6,800017e2 <copyinstr+0x4a>
    80001810:	985a                	add	a6,a6,s6
    80001812:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001814:	41650633          	sub	a2,a0,s6
    80001818:	14fd                	addi	s1,s1,-1
    8000181a:	9b26                	add	s6,s6,s1
    8000181c:	00f60733          	add	a4,a2,a5
    80001820:	00074703          	lbu	a4,0(a4)
    80001824:	df49                	beqz	a4,800017be <copyinstr+0x26>
        *dst = *p;
    80001826:	00e78023          	sb	a4,0(a5)
      --max;
    8000182a:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000182e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001830:	ff0796e3          	bne	a5,a6,8000181c <copyinstr+0x84>
      dst++;
    80001834:	8b42                	mv	s6,a6
    80001836:	b775                	j	800017e2 <copyinstr+0x4a>
    80001838:	4781                	li	a5,0
    8000183a:	b769                	j	800017c4 <copyinstr+0x2c>
      return -1;
    8000183c:	557d                	li	a0,-1
    8000183e:	b779                	j	800017cc <copyinstr+0x34>
  int got_null = 0;
    80001840:	4781                	li	a5,0
  if(got_null){
    80001842:	0017b793          	seqz	a5,a5
    80001846:	40f00533          	neg	a0,a5
}
    8000184a:	8082                	ret

000000008000184c <getList2>:
 * 2 = zombie 
 * 3 = sleeping 
 * 4 = unused  
 */
void
getList2(int number, int parent_cpu){ // TODO: change name of function
    8000184c:	1141                	addi	sp,sp,-16
    8000184e:	e406                	sd	ra,8(sp)
    80001850:	e022                	sd	s0,0(sp)
    80001852:	0800                	addi	s0,sp,16
int a =0;
a=a+1;
if(a==0){
  panic("a not zero ");
}
  number == 1 ?  acquire(&readyLock[parent_cpu]): 
    80001854:	4785                	li	a5,1
    80001856:	02f50763          	beq	a0,a5,80001884 <getList2+0x38>
    number == 2 ? acquire(&zombieLock): 
    8000185a:	4789                	li	a5,2
    8000185c:	04f50263          	beq	a0,a5,800018a0 <getList2+0x54>
      number == 3 ? acquire(&sleepLock): 
    80001860:	478d                	li	a5,3
    80001862:	04f50863          	beq	a0,a5,800018b2 <getList2+0x66>
        number == 4 ? acquire(&unusedLock):  
    80001866:	4791                	li	a5,4
    80001868:	04f51e63          	bne	a0,a5,800018c4 <getList2+0x78>
    8000186c:	00011517          	auipc	a0,0x11
    80001870:	aec50513          	addi	a0,a0,-1300 # 80012358 <unusedLock>
    80001874:	fffff097          	auipc	ra,0xfffff
    80001878:	378080e7          	jalr	888(ra) # 80000bec <acquire>
          panic("wrong call in getList2");
}
    8000187c:	60a2                	ld	ra,8(sp)
    8000187e:	6402                	ld	s0,0(sp)
    80001880:	0141                	addi	sp,sp,16
    80001882:	8082                	ret
  number == 1 ?  acquire(&readyLock[parent_cpu]): 
    80001884:	00159513          	slli	a0,a1,0x1
    80001888:	95aa                	add	a1,a1,a0
    8000188a:	058e                	slli	a1,a1,0x3
    8000188c:	00011517          	auipc	a0,0x11
    80001890:	a5450513          	addi	a0,a0,-1452 # 800122e0 <readyLock>
    80001894:	952e                	add	a0,a0,a1
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	356080e7          	jalr	854(ra) # 80000bec <acquire>
    8000189e:	bff9                	j	8000187c <getList2+0x30>
    number == 2 ? acquire(&zombieLock): 
    800018a0:	00011517          	auipc	a0,0x11
    800018a4:	a8850513          	addi	a0,a0,-1400 # 80012328 <zombieLock>
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	344080e7          	jalr	836(ra) # 80000bec <acquire>
    800018b0:	b7f1                	j	8000187c <getList2+0x30>
      number == 3 ? acquire(&sleepLock): 
    800018b2:	00011517          	auipc	a0,0x11
    800018b6:	a8e50513          	addi	a0,a0,-1394 # 80012340 <sleepLock>
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	332080e7          	jalr	818(ra) # 80000bec <acquire>
    800018c2:	bf6d                	j	8000187c <getList2+0x30>
          panic("wrong call in getList2");
    800018c4:	00008517          	auipc	a0,0x8
    800018c8:	91450513          	addi	a0,a0,-1772 # 800091d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <get_first2>:

struct proc* get_first2(int number, int parent_cpu){
  struct proc* p;
  number == 1 ? p = cpus[parent_cpu].first :
    800018d4:	4785                	li	a5,1
    800018d6:	02f50063          	beq	a0,a5,800018f6 <get_first2+0x22>
    number == 2 ? p = zombieList  :
    800018da:	4789                	li	a5,2
    800018dc:	02f50963          	beq	a0,a5,8000190e <get_first2+0x3a>
      number == 3 ? p = sleepingList :
    800018e0:	478d                	li	a5,3
    800018e2:	02f50b63          	beq	a0,a5,80001918 <get_first2+0x44>
        number == 4 ? p = unusedList:
    800018e6:	4791                	li	a5,4
    800018e8:	02f51d63          	bne	a0,a5,80001922 <get_first2+0x4e>
    800018ec:	00008517          	auipc	a0,0x8
    800018f0:	75c53503          	ld	a0,1884(a0) # 8000a048 <unusedList>
          panic("wrong call in get_first2");
  return p;
}
    800018f4:	8082                	ret
  number == 1 ? p = cpus[parent_cpu].first :
    800018f6:	00359793          	slli	a5,a1,0x3
    800018fa:	95be                	add	a1,a1,a5
    800018fc:	0592                	slli	a1,a1,0x4
    800018fe:	00011797          	auipc	a5,0x11
    80001902:	9e278793          	addi	a5,a5,-1566 # 800122e0 <readyLock>
    80001906:	95be                	add	a1,a1,a5
    80001908:	1185b503          	ld	a0,280(a1) # 4000118 <_entry-0x7bfffee8>
    8000190c:	8082                	ret
    number == 2 ? p = zombieList  :
    8000190e:	00008517          	auipc	a0,0x8
    80001912:	74a53503          	ld	a0,1866(a0) # 8000a058 <zombieList>
    80001916:	8082                	ret
      number == 3 ? p = sleepingList :
    80001918:	00008517          	auipc	a0,0x8
    8000191c:	73853503          	ld	a0,1848(a0) # 8000a050 <sleepingList>
    80001920:	8082                	ret
struct proc* get_first2(int number, int parent_cpu){
    80001922:	1141                	addi	sp,sp,-16
    80001924:	e406                	sd	ra,8(sp)
    80001926:	e022                	sd	s0,0(sp)
    80001928:	0800                	addi	s0,sp,16
          panic("wrong call in get_first2");
    8000192a:	00008517          	auipc	a0,0x8
    8000192e:	8c650513          	addi	a0,a0,-1850 # 800091f0 <digits+0x1b0>
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	c0c080e7          	jalr	-1012(ra) # 8000053e <panic>

000000008000193a <set_first2>:

void
set_first2(struct proc* p, int number, int parent_cpu)//TODO: change name of function
{
  number == 1 ?  cpus[parent_cpu].first = p: 
    8000193a:	4785                	li	a5,1
    8000193c:	00f58c63          	beq	a1,a5,80001954 <set_first2+0x1a>
    number == 2 ? zombieList = p: 
    80001940:	4789                	li	a5,2
    80001942:	02f58563          	beq	a1,a5,8000196c <set_first2+0x32>
      number == 3 ? sleepingList = p: 
    80001946:	478d                	li	a5,3
    80001948:	02f58763          	beq	a1,a5,80001976 <set_first2+0x3c>
        number == 4 ? unusedList:  
    8000194c:	4791                	li	a5,4
    8000194e:	02f59963          	bne	a1,a5,80001980 <set_first2+0x46>
    80001952:	8082                	ret
  number == 1 ?  cpus[parent_cpu].first = p: 
    80001954:	00361793          	slli	a5,a2,0x3
    80001958:	963e                	add	a2,a2,a5
    8000195a:	0612                	slli	a2,a2,0x4
    8000195c:	00011797          	auipc	a5,0x11
    80001960:	98478793          	addi	a5,a5,-1660 # 800122e0 <readyLock>
    80001964:	963e                	add	a2,a2,a5
    80001966:	10a63c23          	sd	a0,280(a2) # 1118 <_entry-0x7fffeee8>
    8000196a:	8082                	ret
    number == 2 ? zombieList = p: 
    8000196c:	00008797          	auipc	a5,0x8
    80001970:	6ea7b623          	sd	a0,1772(a5) # 8000a058 <zombieList>
    80001974:	8082                	ret
      number == 3 ? sleepingList = p: 
    80001976:	00008797          	auipc	a5,0x8
    8000197a:	6ca7bd23          	sd	a0,1754(a5) # 8000a050 <sleepingList>
    8000197e:	8082                	ret
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e406                	sd	ra,8(sp)
    80001984:	e022                	sd	s0,0(sp)
    80001986:	0800                	addi	s0,sp,16
          panic("wrong call in set_first2");
    80001988:	00008517          	auipc	a0,0x8
    8000198c:	88850513          	addi	a0,a0,-1912 # 80009210 <digits+0x1d0>
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	bae080e7          	jalr	-1106(ra) # 8000053e <panic>

0000000080001998 <release_list2>:
}

void
release_list2(int number, int parent_cpu){
    80001998:	1141                	addi	sp,sp,-16
    8000199a:	e406                	sd	ra,8(sp)
    8000199c:	e022                	sd	s0,0(sp)
    8000199e:	0800                	addi	s0,sp,16
    number == 1 ?  release(&readyLock[parent_cpu]): 
    800019a0:	4785                	li	a5,1
    800019a2:	02f50763          	beq	a0,a5,800019d0 <release_list2+0x38>
      number == 2 ? release(&zombieLock): 
    800019a6:	4789                	li	a5,2
    800019a8:	04f50263          	beq	a0,a5,800019ec <release_list2+0x54>
        number == 3 ? release(&sleepLock): 
    800019ac:	478d                	li	a5,3
    800019ae:	04f50863          	beq	a0,a5,800019fe <release_list2+0x66>
          number == 4 ? release(&unusedLock):  
    800019b2:	4791                	li	a5,4
    800019b4:	04f51e63          	bne	a0,a5,80001a10 <release_list2+0x78>
    800019b8:	00011517          	auipc	a0,0x11
    800019bc:	9a050513          	addi	a0,a0,-1632 # 80012358 <unusedLock>
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	2e6080e7          	jalr	742(ra) # 80000ca6 <release>
            panic("wrong call in release_list2");
}
    800019c8:	60a2                	ld	ra,8(sp)
    800019ca:	6402                	ld	s0,0(sp)
    800019cc:	0141                	addi	sp,sp,16
    800019ce:	8082                	ret
    number == 1 ?  release(&readyLock[parent_cpu]): 
    800019d0:	00159513          	slli	a0,a1,0x1
    800019d4:	95aa                	add	a1,a1,a0
    800019d6:	058e                	slli	a1,a1,0x3
    800019d8:	00011517          	auipc	a0,0x11
    800019dc:	90850513          	addi	a0,a0,-1784 # 800122e0 <readyLock>
    800019e0:	952e                	add	a0,a0,a1
    800019e2:	fffff097          	auipc	ra,0xfffff
    800019e6:	2c4080e7          	jalr	708(ra) # 80000ca6 <release>
    800019ea:	bff9                	j	800019c8 <release_list2+0x30>
      number == 2 ? release(&zombieLock): 
    800019ec:	00011517          	auipc	a0,0x11
    800019f0:	93c50513          	addi	a0,a0,-1732 # 80012328 <zombieLock>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	2b2080e7          	jalr	690(ra) # 80000ca6 <release>
    800019fc:	b7f1                	j	800019c8 <release_list2+0x30>
        number == 3 ? release(&sleepLock): 
    800019fe:	00011517          	auipc	a0,0x11
    80001a02:	94250513          	addi	a0,a0,-1726 # 80012340 <sleepLock>
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	2a0080e7          	jalr	672(ra) # 80000ca6 <release>
    80001a0e:	bf6d                	j	800019c8 <release_list2+0x30>
            panic("wrong call in release_list2");
    80001a10:	00008517          	auipc	a0,0x8
    80001a14:	82050513          	addi	a0,a0,-2016 # 80009230 <digits+0x1f0>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>

0000000080001a20 <add_to_list2>:
void
add_to_list2(struct proc* p, struct proc* first, int type, int parent_cpu)//TODO: change name of function
{

    struct proc* prev = 0;
    while(first){
    80001a20:	cdb9                	beqz	a1,80001a7e <add_to_list2+0x5e>
{
    80001a22:	7179                	addi	sp,sp,-48
    80001a24:	f406                	sd	ra,40(sp)
    80001a26:	f022                	sd	s0,32(sp)
    80001a28:	ec26                	sd	s1,24(sp)
    80001a2a:	e84a                	sd	s2,16(sp)
    80001a2c:	e44e                	sd	s3,8(sp)
    80001a2e:	e052                	sd	s4,0(sp)
    80001a30:	1800                	addi	s0,sp,48
    80001a32:	84ae                	mv	s1,a1
    80001a34:	89b2                	mv	s3,a2
    80001a36:	8a36                	mv	s4,a3
    struct proc* prev = 0;
    80001a38:	4901                	li	s2,0
    80001a3a:	a819                	j	80001a50 <add_to_list2+0x30>

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list2(type, parent_cpu);
    80001a3c:	85d2                	mv	a1,s4
    80001a3e:	854e                	mv	a0,s3
    80001a40:	00000097          	auipc	ra,0x0
    80001a44:	f58080e7          	jalr	-168(ra) # 80001998 <release_list2>
      }
      prev = first;
      first = first->next;
    80001a48:	68bc                	ld	a5,80(s1)
    while(first){
    80001a4a:	8926                	mv	s2,s1
    80001a4c:	c38d                	beqz	a5,80001a6e <add_to_list2+0x4e>
      first = first->next;
    80001a4e:	84be                	mv	s1,a5
      acquire(&first->list_lock);
    80001a50:	01848513          	addi	a0,s1,24
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	198080e7          	jalr	408(ra) # 80000bec <acquire>
      if(prev){
    80001a5c:	fe0900e3          	beqz	s2,80001a3c <add_to_list2+0x1c>
        release(&prev->list_lock);
    80001a60:	01890513          	addi	a0,s2,24 # 1018 <_entry-0x7fffefe8>
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	242080e7          	jalr	578(ra) # 80000ca6 <release>
    80001a6c:	bff1                	j	80001a48 <add_to_list2+0x28>
    }
}
    80001a6e:	70a2                	ld	ra,40(sp)
    80001a70:	7402                	ld	s0,32(sp)
    80001a72:	64e2                	ld	s1,24(sp)
    80001a74:	6942                	ld	s2,16(sp)
    80001a76:	69a2                	ld	s3,8(sp)
    80001a78:	6a02                	ld	s4,0(sp)
    80001a7a:	6145                	addi	sp,sp,48
    80001a7c:	8082                	ret
    80001a7e:	8082                	ret

0000000080001a80 <add_proc2>:

void //TODO: cahnge 
add_proc2(struct proc* p, int number, int parent_cpu)
{
    80001a80:	7179                	addi	sp,sp,-48
    80001a82:	f406                	sd	ra,40(sp)
    80001a84:	f022                	sd	s0,32(sp)
    80001a86:	ec26                	sd	s1,24(sp)
    80001a88:	e84a                	sd	s2,16(sp)
    80001a8a:	e44e                	sd	s3,8(sp)
    80001a8c:	1800                	addi	s0,sp,48
    80001a8e:	89aa                	mv	s3,a0
    80001a90:	84ae                	mv	s1,a1
    80001a92:	8932                	mv	s2,a2
  struct proc* first;
  getList2(number, parent_cpu);
    80001a94:	85b2                	mv	a1,a2
    80001a96:	8526                	mv	a0,s1
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	db4080e7          	jalr	-588(ra) # 8000184c <getList2>
  first = get_first2(number, parent_cpu);
    80001aa0:	85ca                	mv	a1,s2
    80001aa2:	8526                	mv	a0,s1
    80001aa4:	00000097          	auipc	ra,0x0
    80001aa8:	e30080e7          	jalr	-464(ra) # 800018d4 <get_first2>
    80001aac:	85aa                	mv	a1,a0
  add_to_list2(p, first, number, parent_cpu);//TODO change name
    80001aae:	86ca                	mv	a3,s2
    80001ab0:	8626                	mv	a2,s1
    80001ab2:	854e                	mv	a0,s3
    80001ab4:	00000097          	auipc	ra,0x0
    80001ab8:	f6c080e7          	jalr	-148(ra) # 80001a20 <add_to_list2>
}
    80001abc:	70a2                	ld	ra,40(sp)
    80001abe:	7402                	ld	s0,32(sp)
    80001ac0:	64e2                	ld	s1,24(sp)
    80001ac2:	6942                	ld	s2,16(sp)
    80001ac4:	69a2                	ld	s3,8(sp)
    80001ac6:	6145                	addi	sp,sp,48
    80001ac8:	8082                	ret

0000000080001aca <pick_cpu>:
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
int flag_init = 0;

int
pick_cpu(){
    80001aca:	1141                	addi	sp,sp,-16
    80001acc:	e422                	sd	s0,8(sp)
    80001ace:	0800                	addi	s0,sp,16
  }
  if(min==-31 || cpuNumber==-31){
    panic("pick_cpu");
  }
  return cpuNumber;
}
    80001ad0:	4501                	li	a0,0
    80001ad2:	6422                	ld	s0,8(sp)
    80001ad4:	0141                	addi	sp,sp,16
    80001ad6:	8082                	ret

0000000080001ad8 <cahnge_number_of_proc>:

void
cahnge_number_of_proc(int cpu_id,int number){
    80001ad8:	7179                	addi	sp,sp,-48
    80001ada:	f406                	sd	ra,40(sp)
    80001adc:	f022                	sd	s0,32(sp)
    80001ade:	ec26                	sd	s1,24(sp)
    80001ae0:	e84a                	sd	s2,16(sp)
    80001ae2:	e44e                	sd	s3,8(sp)
    80001ae4:	1800                	addi	s0,sp,48
    80001ae6:	89ae                	mv	s3,a1
  struct cpu* c = &cpus[cpu_id];
  uint64 old;
  do{
    old = c->queue_size;
  } while(cas(&c->queue_size, old, old+number));
    80001ae8:	00351913          	slli	s2,a0,0x3
    80001aec:	992a                	add	s2,s2,a0
    80001aee:	00491793          	slli	a5,s2,0x4
    80001af2:	00011917          	auipc	s2,0x11
    80001af6:	87e90913          	addi	s2,s2,-1922 # 80012370 <cpus>
    80001afa:	993e                	add	s2,s2,a5
    old = c->queue_size;
    80001afc:	00010497          	auipc	s1,0x10
    80001b00:	7e448493          	addi	s1,s1,2020 # 800122e0 <readyLock>
    80001b04:	94be                	add	s1,s1,a5
    80001b06:	68cc                	ld	a1,144(s1)
  } while(cas(&c->queue_size, old, old+number));
    80001b08:	0135863b          	addw	a2,a1,s3
    80001b0c:	2581                	sext.w	a1,a1
    80001b0e:	854a                	mv	a0,s2
    80001b10:	00005097          	auipc	ra,0x5
    80001b14:	556080e7          	jalr	1366(ra) # 80007066 <cas>
    80001b18:	f57d                	bnez	a0,80001b06 <cahnge_number_of_proc+0x2e>
}
    80001b1a:	70a2                	ld	ra,40(sp)
    80001b1c:	7402                	ld	s0,32(sp)
    80001b1e:	64e2                	ld	s1,24(sp)
    80001b20:	6942                	ld	s2,16(sp)
    80001b22:	69a2                	ld	s3,8(sp)
    80001b24:	6145                	addi	sp,sp,48
    80001b26:	8082                	ret

0000000080001b28 <getFirst>:
    panic("getList");
  }
}


struct proc* getFirst(int type, int cpu_id){
    80001b28:	1101                	addi	sp,sp,-32
    80001b2a:	ec06                	sd	ra,24(sp)
    80001b2c:	e822                	sd	s0,16(sp)
    80001b2e:	e426                	sd	s1,8(sp)
    80001b30:	e04a                	sd	s2,0(sp)
    80001b32:	1000                	addi	s0,sp,32
    80001b34:	84aa                	mv	s1,a0
    80001b36:	892e                	mv	s2,a1
  struct proc* p;

  if(type>3){
    80001b38:	478d                	li	a5,3
    80001b3a:	02a7c463          	blt	a5,a0,80001b62 <getFirst+0x3a>
  printf("type is %d\n",type);
  }

  if(type==readyList || type==11){
    80001b3e:	e141                	bnez	a0,80001bbe <getFirst+0x96>
    p = cpus[cpu_id].first;
    80001b40:	00391593          	slli	a1,s2,0x3
    80001b44:	992e                	add	s2,s2,a1
    80001b46:	0912                	slli	s2,s2,0x4
    80001b48:	00010797          	auipc	a5,0x10
    80001b4c:	79878793          	addi	a5,a5,1944 # 800122e0 <readyLock>
    80001b50:	993e                	add	s2,s2,a5
    80001b52:	11893503          	ld	a0,280(s2)
  }
  else{
    panic("getFirst");
  }
  return p;
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret
  printf("type is %d\n",type);
    80001b62:	85aa                	mv	a1,a0
    80001b64:	00007517          	auipc	a0,0x7
    80001b68:	6ec50513          	addi	a0,a0,1772 # 80009250 <digits+0x210>
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	a1c080e7          	jalr	-1508(ra) # 80000588 <printf>
  if(type==readyList || type==11){
    80001b74:	47ad                	li	a5,11
    80001b76:	fcf485e3          	beq	s1,a5,80001b40 <getFirst+0x18>
  else if(type==zombeList || type==21){
    80001b7a:	47d5                	li	a5,21
    80001b7c:	04f48463          	beq	s1,a5,80001bc4 <getFirst+0x9c>
  else if(type==sleepLeast || type==31){
    80001b80:	4789                	li	a5,2
    80001b82:	02f48163          	beq	s1,a5,80001ba4 <getFirst+0x7c>
    80001b86:	47fd                	li	a5,31
    80001b88:	00f48e63          	beq	s1,a5,80001ba4 <getFirst+0x7c>
  else if(type==unuseList || type==41){
    80001b8c:	478d                	li	a5,3
    80001b8e:	00f48663          	beq	s1,a5,80001b9a <getFirst+0x72>
    80001b92:	02900793          	li	a5,41
    80001b96:	00f49c63          	bne	s1,a5,80001bae <getFirst+0x86>
  p = unused_list;
    80001b9a:	00008517          	auipc	a0,0x8
    80001b9e:	49653503          	ld	a0,1174(a0) # 8000a030 <unused_list>
    80001ba2:	bf55                	j	80001b56 <getFirst+0x2e>
  p = sleeping_list;
    80001ba4:	00008517          	auipc	a0,0x8
    80001ba8:	48453503          	ld	a0,1156(a0) # 8000a028 <sleeping_list>
    80001bac:	b76d                	j	80001b56 <getFirst+0x2e>
    panic("getFirst");
    80001bae:	00007517          	auipc	a0,0x7
    80001bb2:	6b250513          	addi	a0,a0,1714 # 80009260 <digits+0x220>
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	988080e7          	jalr	-1656(ra) # 8000053e <panic>
  else if(type==zombeList || type==21){
    80001bbe:	4785                	li	a5,1
    80001bc0:	faf51de3          	bne	a0,a5,80001b7a <getFirst+0x52>
   p = zombie_list;  }
    80001bc4:	00008517          	auipc	a0,0x8
    80001bc8:	47453503          	ld	a0,1140(a0) # 8000a038 <zombie_list>
    80001bcc:	b769                	j	80001b56 <getFirst+0x2e>

0000000080001bce <release_list3>:
  }
}


void
release_list3(int number, int parent_cpu){
    80001bce:	1141                	addi	sp,sp,-16
    80001bd0:	e406                	sd	ra,8(sp)
    80001bd2:	e022                	sd	s0,0(sp)
    80001bd4:	0800                	addi	s0,sp,16
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001bd6:	4785                	li	a5,1
    80001bd8:	02f50763          	beq	a0,a5,80001c06 <release_list3+0x38>
      number == 2 ? release(&zombie_lock): 
    80001bdc:	4789                	li	a5,2
    80001bde:	04f50263          	beq	a0,a5,80001c22 <release_list3+0x54>
        number == 3 ? release(&sleeping_lock): 
    80001be2:	478d                	li	a5,3
    80001be4:	04f50863          	beq	a0,a5,80001c34 <release_list3+0x66>
          number == 4 ? release(&unused_lock):  
    80001be8:	4791                	li	a5,4
    80001bea:	04f51e63          	bne	a0,a5,80001c46 <release_list3+0x78>
    80001bee:	00011517          	auipc	a0,0x11
    80001bf2:	9aa50513          	addi	a0,a0,-1622 # 80012598 <unused_lock>
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	0b0080e7          	jalr	176(ra) # 80000ca6 <release>
            panic("wrong call in release_list3");
}
    80001bfe:	60a2                	ld	ra,8(sp)
    80001c00:	6402                	ld	s0,0(sp)
    80001c02:	0141                	addi	sp,sp,16
    80001c04:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001c06:	00159513          	slli	a0,a1,0x1
    80001c0a:	95aa                	add	a1,a1,a0
    80001c0c:	058e                	slli	a1,a1,0x3
    80001c0e:	00011517          	auipc	a0,0x11
    80001c12:	91250513          	addi	a0,a0,-1774 # 80012520 <ready_lock>
    80001c16:	952e                	add	a0,a0,a1
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	08e080e7          	jalr	142(ra) # 80000ca6 <release>
    80001c20:	bff9                	j	80001bfe <release_list3+0x30>
      number == 2 ? release(&zombie_lock): 
    80001c22:	00011517          	auipc	a0,0x11
    80001c26:	94650513          	addi	a0,a0,-1722 # 80012568 <zombie_lock>
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	07c080e7          	jalr	124(ra) # 80000ca6 <release>
    80001c32:	b7f1                	j	80001bfe <release_list3+0x30>
        number == 3 ? release(&sleeping_lock): 
    80001c34:	00011517          	auipc	a0,0x11
    80001c38:	94c50513          	addi	a0,a0,-1716 # 80012580 <sleeping_lock>
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	06a080e7          	jalr	106(ra) # 80000ca6 <release>
    80001c44:	bf6d                	j	80001bfe <release_list3+0x30>
            panic("wrong call in release_list3");
    80001c46:	00007517          	auipc	a0,0x7
    80001c4a:	62a50513          	addi	a0,a0,1578 # 80009270 <digits+0x230>
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	8f0080e7          	jalr	-1808(ra) # 8000053e <panic>

0000000080001c56 <release_list>:

void
release_list(int type, int parent_cpu){
    80001c56:	1141                	addi	sp,sp,-16
    80001c58:	e406                	sd	ra,8(sp)
    80001c5a:	e022                	sd	s0,0(sp)
    80001c5c:	0800                	addi	s0,sp,16
  type==readyList ? release_list3(1,parent_cpu): 
    80001c5e:	c515                	beqz	a0,80001c8a <release_list+0x34>
    type==zombeList ? release_list3(2,parent_cpu):
    80001c60:	4785                	li	a5,1
    80001c62:	04f50263          	beq	a0,a5,80001ca6 <release_list+0x50>
      type==sleepLeast ? release_list3(3,parent_cpu):
    80001c66:	4789                	li	a5,2
    80001c68:	04f50863          	beq	a0,a5,80001cb8 <release_list+0x62>
        type==unuseList ? release_list3(4,parent_cpu):
    80001c6c:	478d                	li	a5,3
    80001c6e:	04f51e63          	bne	a0,a5,80001cca <release_list+0x74>
          number == 4 ? release(&unused_lock):  
    80001c72:	00011517          	auipc	a0,0x11
    80001c76:	92650513          	addi	a0,a0,-1754 # 80012598 <unused_lock>
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	02c080e7          	jalr	44(ra) # 80000ca6 <release>
          panic("wrong type list");
}
    80001c82:	60a2                	ld	ra,8(sp)
    80001c84:	6402                	ld	s0,0(sp)
    80001c86:	0141                	addi	sp,sp,16
    80001c88:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001c8a:	00159513          	slli	a0,a1,0x1
    80001c8e:	95aa                	add	a1,a1,a0
    80001c90:	058e                	slli	a1,a1,0x3
    80001c92:	00011517          	auipc	a0,0x11
    80001c96:	88e50513          	addi	a0,a0,-1906 # 80012520 <ready_lock>
    80001c9a:	952e                	add	a0,a0,a1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	00a080e7          	jalr	10(ra) # 80000ca6 <release>
}
    80001ca4:	bff9                	j	80001c82 <release_list+0x2c>
      number == 2 ? release(&zombie_lock): 
    80001ca6:	00011517          	auipc	a0,0x11
    80001caa:	8c250513          	addi	a0,a0,-1854 # 80012568 <zombie_lock>
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	ff8080e7          	jalr	-8(ra) # 80000ca6 <release>
}
    80001cb6:	b7f1                	j	80001c82 <release_list+0x2c>
        number == 3 ? release(&sleeping_lock): 
    80001cb8:	00011517          	auipc	a0,0x11
    80001cbc:	8c850513          	addi	a0,a0,-1848 # 80012580 <sleeping_lock>
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	fe6080e7          	jalr	-26(ra) # 80000ca6 <release>
}
    80001cc8:	bf6d                	j	80001c82 <release_list+0x2c>
          panic("wrong type list");
    80001cca:	00007517          	auipc	a0,0x7
    80001cce:	5c650513          	addi	a0,a0,1478 # 80009290 <digits+0x250>
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	86c080e7          	jalr	-1940(ra) # 8000053e <panic>

0000000080001cda <delet_the_first>:
  // }
  return first;
}

int
delet_the_first(int number,int cpuId){
    80001cda:	1141                	addi	sp,sp,-16
    80001cdc:	e406                	sd	ra,8(sp)
    80001cde:	e022                	sd	s0,0(sp)
    80001ce0:	0800                	addi	s0,sp,16
  release_list(number, proc->parent_cpu);
    80001ce2:	00011597          	auipc	a1,0x11
    80001ce6:	9565a583          	lw	a1,-1706(a1) # 80012638 <proc+0x58>
    80001cea:	00000097          	auipc	ra,0x0
    80001cee:	f6c080e7          	jalr	-148(ra) # 80001c56 <release_list>
  number++;
  return 0;
}
    80001cf2:	4501                	li	a0,0
    80001cf4:	60a2                	ld	ra,8(sp)
    80001cf6:	6402                	ld	s0,0(sp)
    80001cf8:	0141                	addi	sp,sp,16
    80001cfa:	8082                	ret

0000000080001cfc <delete_the_first_not_empty_list>:

int 
delete_the_first_not_empty_list(struct proc* proc,struct proc* first,int number,int debug_flag){
  struct proc* prev = 0;
  while(first){
    80001cfc:	cde1                	beqz	a1,80001dd4 <delete_the_first_not_empty_list+0xd8>
delete_the_first_not_empty_list(struct proc* proc,struct proc* first,int number,int debug_flag){
    80001cfe:	715d                	addi	sp,sp,-80
    80001d00:	e486                	sd	ra,72(sp)
    80001d02:	e0a2                	sd	s0,64(sp)
    80001d04:	fc26                	sd	s1,56(sp)
    80001d06:	f84a                	sd	s2,48(sp)
    80001d08:	f44e                	sd	s3,40(sp)
    80001d0a:	f052                	sd	s4,32(sp)
    80001d0c:	ec56                	sd	s5,24(sp)
    80001d0e:	e85a                	sd	s6,16(sp)
    80001d10:	e45e                	sd	s7,8(sp)
    80001d12:	e062                	sd	s8,0(sp)
    80001d14:	0880                	addi	s0,sp,80
    80001d16:	8a2a                	mv	s4,a0
    80001d18:	84ae                	mv	s1,a1
    80001d1a:	8bb2                	mv	s7,a2
    80001d1c:	8ab6                	mv	s5,a3
  struct proc* prev = 0;
    80001d1e:	4981                	li	s3,0
    else{
      release(&prev->list_lock);
    }
    prev = first;
    first = first->next;
    if(debug_flag==debugFlag){
    80001d20:	4b11                	li	s6,4
      printf("first is %d",first);
    80001d22:	00007c17          	auipc	s8,0x7
    80001d26:	57ec0c13          	addi	s8,s8,1406 # 800092a0 <digits+0x260>
    80001d2a:	a895                	j	80001d9e <delete_the_first_not_empty_list+0xa2>
      if(debug_flag==debugFlag){
    80001d2c:	4791                	li	a5,4
    80001d2e:	02fa8f63          	beq	s5,a5,80001d6c <delete_the_first_not_empty_list+0x70>
      prev->next = first->next;
    80001d32:	68bc                	ld	a5,80(s1)
    80001d34:	04f9b823          	sd	a5,80(s3) # 1050 <_entry-0x7fffefb0>
      proc->next = 0;
    80001d38:	040a3823          	sd	zero,80(s4) # fffffffffffff050 <end+0xffffffff7ffd8050>
      release(&first->list_lock);
    80001d3c:	854a                	mv	a0,s2
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	f68080e7          	jalr	-152(ra) # 80000ca6 <release>
      release(&prev->list_lock);
    80001d46:	01898513          	addi	a0,s3,24
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	f5c080e7          	jalr	-164(ra) # 80000ca6 <release>
      return 1;
    80001d52:	4505                	li	a0,1
    }
  }
  return 0;
}
    80001d54:	60a6                	ld	ra,72(sp)
    80001d56:	6406                	ld	s0,64(sp)
    80001d58:	74e2                	ld	s1,56(sp)
    80001d5a:	7942                	ld	s2,48(sp)
    80001d5c:	79a2                	ld	s3,40(sp)
    80001d5e:	7a02                	ld	s4,32(sp)
    80001d60:	6ae2                	ld	s5,24(sp)
    80001d62:	6b42                	ld	s6,16(sp)
    80001d64:	6ba2                	ld	s7,8(sp)
    80001d66:	6c02                	ld	s8,0(sp)
    80001d68:	6161                	addi	sp,sp,80
    80001d6a:	8082                	ret
        printf("first is %d",first);
    80001d6c:	85a6                	mv	a1,s1
    80001d6e:	00007517          	auipc	a0,0x7
    80001d72:	53250513          	addi	a0,a0,1330 # 800092a0 <digits+0x260>
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	812080e7          	jalr	-2030(ra) # 80000588 <printf>
    80001d7e:	bf55                	j	80001d32 <delete_the_first_not_empty_list+0x36>
      release_list(number,proc->parent_cpu);
    80001d80:	058a2583          	lw	a1,88(s4)
    80001d84:	855e                	mv	a0,s7
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	ed0080e7          	jalr	-304(ra) # 80001c56 <release_list>
    first = first->next;
    80001d8e:	0504b903          	ld	s2,80(s1)
    if(debug_flag==debugFlag){
    80001d92:	036a8863          	beq	s5,s6,80001dc2 <delete_the_first_not_empty_list+0xc6>
  while(first){
    80001d96:	89a6                	mv	s3,s1
    80001d98:	02090c63          	beqz	s2,80001dd0 <delete_the_first_not_empty_list+0xd4>
    80001d9c:	84ca                	mv	s1,s2
    acquire(&first->list_lock);
    80001d9e:	01848913          	addi	s2,s1,24
    80001da2:	854a                	mv	a0,s2
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	e48080e7          	jalr	-440(ra) # 80000bec <acquire>
    if(proc == first){
    80001dac:	f89a00e3          	beq	s4,s1,80001d2c <delete_the_first_not_empty_list+0x30>
    if(!prev)
    80001db0:	fc0988e3          	beqz	s3,80001d80 <delete_the_first_not_empty_list+0x84>
      release(&prev->list_lock);
    80001db4:	01898513          	addi	a0,s3,24
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	eee080e7          	jalr	-274(ra) # 80000ca6 <release>
    80001dc0:	b7f9                	j	80001d8e <delete_the_first_not_empty_list+0x92>
      printf("first is %d",first);
    80001dc2:	85ca                	mv	a1,s2
    80001dc4:	8562                	mv	a0,s8
    80001dc6:	ffffe097          	auipc	ra,0xffffe
    80001dca:	7c2080e7          	jalr	1986(ra) # 80000588 <printf>
    80001dce:	b7e1                	j	80001d96 <delete_the_first_not_empty_list+0x9a>
  return 0;
    80001dd0:	4501                	li	a0,0
    80001dd2:	b749                	j	80001d54 <delete_the_first_not_empty_list+0x58>
    80001dd4:	4501                	li	a0,0
}
    80001dd6:	8082                	ret

0000000080001dd8 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001dd8:	7139                	addi	sp,sp,-64
    80001dda:	fc06                	sd	ra,56(sp)
    80001ddc:	f822                	sd	s0,48(sp)
    80001dde:	f426                	sd	s1,40(sp)
    80001de0:	f04a                	sd	s2,32(sp)
    80001de2:	ec4e                	sd	s3,24(sp)
    80001de4:	e852                	sd	s4,16(sp)
    80001de6:	e456                	sd	s5,8(sp)
    80001de8:	e05a                	sd	s6,0(sp)
    80001dea:	0080                	addi	s0,sp,64
    80001dec:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dee:	00010497          	auipc	s1,0x10
    80001df2:	7f248493          	addi	s1,s1,2034 # 800125e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001df6:	8b26                	mv	s6,s1
    80001df8:	00007a97          	auipc	s5,0x7
    80001dfc:	208a8a93          	addi	s5,s5,520 # 80009000 <etext>
    80001e00:	04000937          	lui	s2,0x4000
    80001e04:	197d                	addi	s2,s2,-1
    80001e06:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e08:	00017a17          	auipc	s4,0x17
    80001e0c:	bd8a0a13          	addi	s4,s4,-1064 # 800189e0 <tickslock>
    char *pa = kalloc();
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	ce4080e7          	jalr	-796(ra) # 80000af4 <kalloc>
    80001e18:	862a                	mv	a2,a0
    if(pa == 0)
    80001e1a:	c131                	beqz	a0,80001e5e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001e1c:	416485b3          	sub	a1,s1,s6
    80001e20:	8591                	srai	a1,a1,0x4
    80001e22:	000ab783          	ld	a5,0(s5)
    80001e26:	02f585b3          	mul	a1,a1,a5
    80001e2a:	2585                	addiw	a1,a1,1
    80001e2c:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001e30:	4719                	li	a4,6
    80001e32:	6685                	lui	a3,0x1
    80001e34:	40b905b3          	sub	a1,s2,a1
    80001e38:	854e                	mv	a0,s3
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	324080e7          	jalr	804(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e42:	19048493          	addi	s1,s1,400
    80001e46:	fd4495e3          	bne	s1,s4,80001e10 <proc_mapstacks+0x38>
  }
}
    80001e4a:	70e2                	ld	ra,56(sp)
    80001e4c:	7442                	ld	s0,48(sp)
    80001e4e:	74a2                	ld	s1,40(sp)
    80001e50:	7902                	ld	s2,32(sp)
    80001e52:	69e2                	ld	s3,24(sp)
    80001e54:	6a42                	ld	s4,16(sp)
    80001e56:	6aa2                	ld	s5,8(sp)
    80001e58:	6b02                	ld	s6,0(sp)
    80001e5a:	6121                	addi	sp,sp,64
    80001e5c:	8082                	ret
      panic("kalloc");
    80001e5e:	00007517          	auipc	a0,0x7
    80001e62:	45250513          	addi	a0,a0,1106 # 800092b0 <digits+0x270>
    80001e66:	ffffe097          	auipc	ra,0xffffe
    80001e6a:	6d8080e7          	jalr	1752(ra) # 8000053e <panic>

0000000080001e6e <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001e6e:	1141                	addi	sp,sp,-16
    80001e70:	e422                	sd	s0,8(sp)
    80001e72:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e74:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001e76:	2501                	sext.w	a0,a0
    80001e78:	6422                	ld	s0,8(sp)
    80001e7a:	0141                	addi	sp,sp,16
    80001e7c:	8082                	ret

0000000080001e7e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001e7e:	1141                	addi	sp,sp,-16
    80001e80:	e422                	sd	s0,8(sp)
    80001e82:	0800                	addi	s0,sp,16
    80001e84:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001e86:	0007851b          	sext.w	a0,a5
    80001e8a:	00351793          	slli	a5,a0,0x3
    80001e8e:	97aa                	add	a5,a5,a0
    80001e90:	0792                	slli	a5,a5,0x4
  return c;
}
    80001e92:	00010517          	auipc	a0,0x10
    80001e96:	4de50513          	addi	a0,a0,1246 # 80012370 <cpus>
    80001e9a:	953e                	add	a0,a0,a5
    80001e9c:	6422                	ld	s0,8(sp)
    80001e9e:	0141                	addi	sp,sp,16
    80001ea0:	8082                	ret

0000000080001ea2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ea2:	1101                	addi	sp,sp,-32
    80001ea4:	ec06                	sd	ra,24(sp)
    80001ea6:	e822                	sd	s0,16(sp)
    80001ea8:	e426                	sd	s1,8(sp)
    80001eaa:	1000                	addi	s0,sp,32
  push_off();
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	cec080e7          	jalr	-788(ra) # 80000b98 <push_off>
    80001eb4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001eb6:	0007871b          	sext.w	a4,a5
    80001eba:	00371793          	slli	a5,a4,0x3
    80001ebe:	97ba                	add	a5,a5,a4
    80001ec0:	0792                	slli	a5,a5,0x4
    80001ec2:	00010717          	auipc	a4,0x10
    80001ec6:	41e70713          	addi	a4,a4,1054 # 800122e0 <readyLock>
    80001eca:	97ba                	add	a5,a5,a4
    80001ecc:	6fc4                	ld	s1,152(a5)
  pop_off();
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	d72080e7          	jalr	-654(ra) # 80000c40 <pop_off>
  return p;
}
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	60e2                	ld	ra,24(sp)
    80001eda:	6442                	ld	s0,16(sp)
    80001edc:	64a2                	ld	s1,8(sp)
    80001ede:	6105                	addi	sp,sp,32
    80001ee0:	8082                	ret

0000000080001ee2 <get_cpu>:
{
    80001ee2:	1141                	addi	sp,sp,-16
    80001ee4:	e406                	sd	ra,8(sp)
    80001ee6:	e022                	sd	s0,0(sp)
    80001ee8:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    80001eea:	00000097          	auipc	ra,0x0
    80001eee:	fb8080e7          	jalr	-72(ra) # 80001ea2 <myproc>
}
    80001ef2:	4d28                	lw	a0,88(a0)
    80001ef4:	60a2                	ld	ra,8(sp)
    80001ef6:	6402                	ld	s0,0(sp)
    80001ef8:	0141                	addi	sp,sp,16
    80001efa:	8082                	ret

0000000080001efc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001efc:	1141                	addi	sp,sp,-16
    80001efe:	e406                	sd	ra,8(sp)
    80001f00:	e022                	sd	s0,0(sp)
    80001f02:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001f04:	00000097          	auipc	ra,0x0
    80001f08:	f9e080e7          	jalr	-98(ra) # 80001ea2 <myproc>
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	d9a080e7          	jalr	-614(ra) # 80000ca6 <release>

  if (first) {
    80001f14:	00008797          	auipc	a5,0x8
    80001f18:	aec7a783          	lw	a5,-1300(a5) # 80009a00 <first.1858>
    80001f1c:	eb89                	bnez	a5,80001f2e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001f1e:	00001097          	auipc	ra,0x1
    80001f22:	5b6080e7          	jalr	1462(ra) # 800034d4 <usertrapret>
}
    80001f26:	60a2                	ld	ra,8(sp)
    80001f28:	6402                	ld	s0,0(sp)
    80001f2a:	0141                	addi	sp,sp,16
    80001f2c:	8082                	ret
    first = 0;
    80001f2e:	00008797          	auipc	a5,0x8
    80001f32:	ac07a923          	sw	zero,-1326(a5) # 80009a00 <first.1858>
    fsinit(ROOTDEV);
    80001f36:	4505                	li	a0,1
    80001f38:	00002097          	auipc	ra,0x2
    80001f3c:	328080e7          	jalr	808(ra) # 80004260 <fsinit>
    80001f40:	bff9                	j	80001f1e <forkret+0x22>

0000000080001f42 <allocpid>:
allocpid() {
    80001f42:	1101                	addi	sp,sp,-32
    80001f44:	ec06                	sd	ra,24(sp)
    80001f46:	e822                	sd	s0,16(sp)
    80001f48:	e426                	sd	s1,8(sp)
    80001f4a:	e04a                	sd	s2,0(sp)
    80001f4c:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001f4e:	00008917          	auipc	s2,0x8
    80001f52:	ab690913          	addi	s2,s2,-1354 # 80009a04 <nextpid>
    80001f56:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid, pid, pid + 1));
    80001f5a:	0014861b          	addiw	a2,s1,1
    80001f5e:	85a6                	mv	a1,s1
    80001f60:	854a                	mv	a0,s2
    80001f62:	00005097          	auipc	ra,0x5
    80001f66:	104080e7          	jalr	260(ra) # 80007066 <cas>
    80001f6a:	f575                	bnez	a0,80001f56 <allocpid+0x14>
}
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	60e2                	ld	ra,24(sp)
    80001f70:	6442                	ld	s0,16(sp)
    80001f72:	64a2                	ld	s1,8(sp)
    80001f74:	6902                	ld	s2,0(sp)
    80001f76:	6105                	addi	sp,sp,32
    80001f78:	8082                	ret

0000000080001f7a <proc_pagetable>:
{
    80001f7a:	1101                	addi	sp,sp,-32
    80001f7c:	ec06                	sd	ra,24(sp)
    80001f7e:	e822                	sd	s0,16(sp)
    80001f80:	e426                	sd	s1,8(sp)
    80001f82:	e04a                	sd	s2,0(sp)
    80001f84:	1000                	addi	s0,sp,32
    80001f86:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	3c0080e7          	jalr	960(ra) # 80001348 <uvmcreate>
    80001f90:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001f92:	c121                	beqz	a0,80001fd2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f94:	4729                	li	a4,10
    80001f96:	00006697          	auipc	a3,0x6
    80001f9a:	06a68693          	addi	a3,a3,106 # 80008000 <_trampoline>
    80001f9e:	6605                	lui	a2,0x1
    80001fa0:	040005b7          	lui	a1,0x4000
    80001fa4:	15fd                	addi	a1,a1,-1
    80001fa6:	05b2                	slli	a1,a1,0xc
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	116080e7          	jalr	278(ra) # 800010be <mappages>
    80001fb0:	02054863          	bltz	a0,80001fe0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001fb4:	4719                	li	a4,6
    80001fb6:	08093683          	ld	a3,128(s2)
    80001fba:	6605                	lui	a2,0x1
    80001fbc:	020005b7          	lui	a1,0x2000
    80001fc0:	15fd                	addi	a1,a1,-1
    80001fc2:	05b6                	slli	a1,a1,0xd
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	0f8080e7          	jalr	248(ra) # 800010be <mappages>
    80001fce:	02054163          	bltz	a0,80001ff0 <proc_pagetable+0x76>
}
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	60e2                	ld	ra,24(sp)
    80001fd6:	6442                	ld	s0,16(sp)
    80001fd8:	64a2                	ld	s1,8(sp)
    80001fda:	6902                	ld	s2,0(sp)
    80001fdc:	6105                	addi	sp,sp,32
    80001fde:	8082                	ret
    uvmfree(pagetable, 0);
    80001fe0:	4581                	li	a1,0
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	560080e7          	jalr	1376(ra) # 80001544 <uvmfree>
    return 0;
    80001fec:	4481                	li	s1,0
    80001fee:	b7d5                	j	80001fd2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ff0:	4681                	li	a3,0
    80001ff2:	4605                	li	a2,1
    80001ff4:	040005b7          	lui	a1,0x4000
    80001ff8:	15fd                	addi	a1,a1,-1
    80001ffa:	05b2                	slli	a1,a1,0xc
    80001ffc:	8526                	mv	a0,s1
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	286080e7          	jalr	646(ra) # 80001284 <uvmunmap>
    uvmfree(pagetable, 0);
    80002006:	4581                	li	a1,0
    80002008:	8526                	mv	a0,s1
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	53a080e7          	jalr	1338(ra) # 80001544 <uvmfree>
    return 0;
    80002012:	4481                	li	s1,0
    80002014:	bf7d                	j	80001fd2 <proc_pagetable+0x58>

0000000080002016 <proc_freepagetable>:
{
    80002016:	1101                	addi	sp,sp,-32
    80002018:	ec06                	sd	ra,24(sp)
    8000201a:	e822                	sd	s0,16(sp)
    8000201c:	e426                	sd	s1,8(sp)
    8000201e:	e04a                	sd	s2,0(sp)
    80002020:	1000                	addi	s0,sp,32
    80002022:	84aa                	mv	s1,a0
    80002024:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002026:	4681                	li	a3,0
    80002028:	4605                	li	a2,1
    8000202a:	040005b7          	lui	a1,0x4000
    8000202e:	15fd                	addi	a1,a1,-1
    80002030:	05b2                	slli	a1,a1,0xc
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	252080e7          	jalr	594(ra) # 80001284 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    8000203a:	4681                	li	a3,0
    8000203c:	4605                	li	a2,1
    8000203e:	020005b7          	lui	a1,0x2000
    80002042:	15fd                	addi	a1,a1,-1
    80002044:	05b6                	slli	a1,a1,0xd
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	23c080e7          	jalr	572(ra) # 80001284 <uvmunmap>
  uvmfree(pagetable, sz);
    80002050:	85ca                	mv	a1,s2
    80002052:	8526                	mv	a0,s1
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	4f0080e7          	jalr	1264(ra) # 80001544 <uvmfree>
}
    8000205c:	60e2                	ld	ra,24(sp)
    8000205e:	6442                	ld	s0,16(sp)
    80002060:	64a2                	ld	s1,8(sp)
    80002062:	6902                	ld	s2,0(sp)
    80002064:	6105                	addi	sp,sp,32
    80002066:	8082                	ret

0000000080002068 <growproc>:
{
    80002068:	1101                	addi	sp,sp,-32
    8000206a:	ec06                	sd	ra,24(sp)
    8000206c:	e822                	sd	s0,16(sp)
    8000206e:	e426                	sd	s1,8(sp)
    80002070:	e04a                	sd	s2,0(sp)
    80002072:	1000                	addi	s0,sp,32
    80002074:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002076:	00000097          	auipc	ra,0x0
    8000207a:	e2c080e7          	jalr	-468(ra) # 80001ea2 <myproc>
    8000207e:	892a                	mv	s2,a0
  sz = p->sz;
    80002080:	792c                	ld	a1,112(a0)
    80002082:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002086:	00904f63          	bgtz	s1,800020a4 <growproc+0x3c>
  } else if(n < 0){
    8000208a:	0204cc63          	bltz	s1,800020c2 <growproc+0x5a>
  p->sz = sz;
    8000208e:	1602                	slli	a2,a2,0x20
    80002090:	9201                	srli	a2,a2,0x20
    80002092:	06c93823          	sd	a2,112(s2)
  return 0;
    80002096:	4501                	li	a0,0
}
    80002098:	60e2                	ld	ra,24(sp)
    8000209a:	6442                	ld	s0,16(sp)
    8000209c:	64a2                	ld	s1,8(sp)
    8000209e:	6902                	ld	s2,0(sp)
    800020a0:	6105                	addi	sp,sp,32
    800020a2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020a4:	9e25                	addw	a2,a2,s1
    800020a6:	1602                	slli	a2,a2,0x20
    800020a8:	9201                	srli	a2,a2,0x20
    800020aa:	1582                	slli	a1,a1,0x20
    800020ac:	9181                	srli	a1,a1,0x20
    800020ae:	7d28                	ld	a0,120(a0)
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	380080e7          	jalr	896(ra) # 80001430 <uvmalloc>
    800020b8:	0005061b          	sext.w	a2,a0
    800020bc:	fa69                	bnez	a2,8000208e <growproc+0x26>
      return -1;
    800020be:	557d                	li	a0,-1
    800020c0:	bfe1                	j	80002098 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020c2:	9e25                	addw	a2,a2,s1
    800020c4:	1602                	slli	a2,a2,0x20
    800020c6:	9201                	srli	a2,a2,0x20
    800020c8:	1582                	slli	a1,a1,0x20
    800020ca:	9181                	srli	a1,a1,0x20
    800020cc:	7d28                	ld	a0,120(a0)
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	31a080e7          	jalr	794(ra) # 800013e8 <uvmdealloc>
    800020d6:	0005061b          	sext.w	a2,a0
    800020da:	bf55                	j	8000208e <growproc+0x26>

00000000800020dc <sched>:
{
    800020dc:	7179                	addi	sp,sp,-48
    800020de:	f406                	sd	ra,40(sp)
    800020e0:	f022                	sd	s0,32(sp)
    800020e2:	ec26                	sd	s1,24(sp)
    800020e4:	e84a                	sd	s2,16(sp)
    800020e6:	e44e                	sd	s3,8(sp)
    800020e8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	db8080e7          	jalr	-584(ra) # 80001ea2 <myproc>
    800020f2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	a76080e7          	jalr	-1418(ra) # 80000b6a <holding>
    800020fc:	c959                	beqz	a0,80002192 <sched+0xb6>
    800020fe:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002100:	0007871b          	sext.w	a4,a5
    80002104:	00371793          	slli	a5,a4,0x3
    80002108:	97ba                	add	a5,a5,a4
    8000210a:	0792                	slli	a5,a5,0x4
    8000210c:	00010717          	auipc	a4,0x10
    80002110:	1d470713          	addi	a4,a4,468 # 800122e0 <readyLock>
    80002114:	97ba                	add	a5,a5,a4
    80002116:	1107a703          	lw	a4,272(a5)
    8000211a:	4785                	li	a5,1
    8000211c:	08f71363          	bne	a4,a5,800021a2 <sched+0xc6>
  if(p->state == RUNNING)
    80002120:	5898                	lw	a4,48(s1)
    80002122:	4791                	li	a5,4
    80002124:	08f70763          	beq	a4,a5,800021b2 <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002128:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000212c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000212e:	ebd1                	bnez	a5,800021c2 <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002130:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002132:	00010917          	auipc	s2,0x10
    80002136:	1ae90913          	addi	s2,s2,430 # 800122e0 <readyLock>
    8000213a:	0007871b          	sext.w	a4,a5
    8000213e:	00371793          	slli	a5,a4,0x3
    80002142:	97ba                	add	a5,a5,a4
    80002144:	0792                	slli	a5,a5,0x4
    80002146:	97ca                	add	a5,a5,s2
    80002148:	1147a983          	lw	s3,276(a5)
    8000214c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000214e:	0007859b          	sext.w	a1,a5
    80002152:	00359793          	slli	a5,a1,0x3
    80002156:	97ae                	add	a5,a5,a1
    80002158:	0792                	slli	a5,a5,0x4
    8000215a:	00010597          	auipc	a1,0x10
    8000215e:	22658593          	addi	a1,a1,550 # 80012380 <cpus+0x10>
    80002162:	95be                	add	a1,a1,a5
    80002164:	08848513          	addi	a0,s1,136
    80002168:	00001097          	auipc	ra,0x1
    8000216c:	2c2080e7          	jalr	706(ra) # 8000342a <swtch>
    80002170:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002172:	0007871b          	sext.w	a4,a5
    80002176:	00371793          	slli	a5,a4,0x3
    8000217a:	97ba                	add	a5,a5,a4
    8000217c:	0792                	slli	a5,a5,0x4
    8000217e:	97ca                	add	a5,a5,s2
    80002180:	1137aa23          	sw	s3,276(a5)
}
    80002184:	70a2                	ld	ra,40(sp)
    80002186:	7402                	ld	s0,32(sp)
    80002188:	64e2                	ld	s1,24(sp)
    8000218a:	6942                	ld	s2,16(sp)
    8000218c:	69a2                	ld	s3,8(sp)
    8000218e:	6145                	addi	sp,sp,48
    80002190:	8082                	ret
    panic("sched p->lock");
    80002192:	00007517          	auipc	a0,0x7
    80002196:	12650513          	addi	a0,a0,294 # 800092b8 <digits+0x278>
    8000219a:	ffffe097          	auipc	ra,0xffffe
    8000219e:	3a4080e7          	jalr	932(ra) # 8000053e <panic>
    panic("sched locks");
    800021a2:	00007517          	auipc	a0,0x7
    800021a6:	12650513          	addi	a0,a0,294 # 800092c8 <digits+0x288>
    800021aa:	ffffe097          	auipc	ra,0xffffe
    800021ae:	394080e7          	jalr	916(ra) # 8000053e <panic>
    panic("sched running");
    800021b2:	00007517          	auipc	a0,0x7
    800021b6:	12650513          	addi	a0,a0,294 # 800092d8 <digits+0x298>
    800021ba:	ffffe097          	auipc	ra,0xffffe
    800021be:	384080e7          	jalr	900(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021c2:	00007517          	auipc	a0,0x7
    800021c6:	12650513          	addi	a0,a0,294 # 800092e8 <digits+0x2a8>
    800021ca:	ffffe097          	auipc	ra,0xffffe
    800021ce:	374080e7          	jalr	884(ra) # 8000053e <panic>

00000000800021d2 <yield>:
{
    800021d2:	1101                	addi	sp,sp,-32
    800021d4:	ec06                	sd	ra,24(sp)
    800021d6:	e822                	sd	s0,16(sp)
    800021d8:	e426                	sd	s1,8(sp)
    800021da:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021dc:	00000097          	auipc	ra,0x0
    800021e0:	cc6080e7          	jalr	-826(ra) # 80001ea2 <myproc>
    800021e4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	a06080e7          	jalr	-1530(ra) # 80000bec <acquire>
  p->state = RUNNABLE;
    800021ee:	478d                	li	a5,3
    800021f0:	d89c                	sw	a5,48(s1)
  add_proc_to_specific_list(p, readyList, p->parent_cpu,0);
    800021f2:	4681                	li	a3,0
    800021f4:	4cb0                	lw	a2,88(s1)
    800021f6:	4581                	li	a1,0
    800021f8:	8526                	mv	a0,s1
    800021fa:	00000097          	auipc	ra,0x0
    800021fe:	260080e7          	jalr	608(ra) # 8000245a <add_proc_to_specific_list>
  sched();
    80002202:	00000097          	auipc	ra,0x0
    80002206:	eda080e7          	jalr	-294(ra) # 800020dc <sched>
  release(&p->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a9a080e7          	jalr	-1382(ra) # 80000ca6 <release>
}
    80002214:	60e2                	ld	ra,24(sp)
    80002216:	6442                	ld	s0,16(sp)
    80002218:	64a2                	ld	s1,8(sp)
    8000221a:	6105                	addi	sp,sp,32
    8000221c:	8082                	ret

000000008000221e <set_cpu>:
  if(number<0 || number>NCPU){
    8000221e:	47a1                	li	a5,8
    80002220:	04a7e763          	bltu	a5,a0,8000226e <set_cpu+0x50>
{
    80002224:	1101                	addi	sp,sp,-32
    80002226:	ec06                	sd	ra,24(sp)
    80002228:	e822                	sd	s0,16(sp)
    8000222a:	e426                	sd	s1,8(sp)
    8000222c:	e04a                	sd	s2,0(sp)
    8000222e:	1000                	addi	s0,sp,32
    80002230:	84aa                	mv	s1,a0
  struct proc* p = myproc();
    80002232:	00000097          	auipc	ra,0x0
    80002236:	c70080e7          	jalr	-912(ra) # 80001ea2 <myproc>
    8000223a:	892a                	mv	s2,a0
  BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,b): counter_blance++;
    8000223c:	55fd                	li	a1,-1
    8000223e:	4d28                	lw	a0,88(a0)
    80002240:	00000097          	auipc	ra,0x0
    80002244:	898080e7          	jalr	-1896(ra) # 80001ad8 <cahnge_number_of_proc>
  p->parent_cpu=number;
    80002248:	04992c23          	sw	s1,88(s2)
  BLNCFLG ?cahnge_number_of_proc(number,positive): counter_blance++;
    8000224c:	4585                	li	a1,1
    8000224e:	8526                	mv	a0,s1
    80002250:	00000097          	auipc	ra,0x0
    80002254:	888080e7          	jalr	-1912(ra) # 80001ad8 <cahnge_number_of_proc>
  yield();
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	f7a080e7          	jalr	-134(ra) # 800021d2 <yield>
  return number;
    80002260:	8526                	mv	a0,s1
}
    80002262:	60e2                	ld	ra,24(sp)
    80002264:	6442                	ld	s0,16(sp)
    80002266:	64a2                	ld	s1,8(sp)
    80002268:	6902                	ld	s2,0(sp)
    8000226a:	6105                	addi	sp,sp,32
    8000226c:	8082                	ret
    return -1;
    8000226e:	557d                	li	a0,-1
}
    80002270:	8082                	ret

0000000080002272 <getList>:
getList(int type, int cpu_id){ //grab the loock of list 
    80002272:	1101                	addi	sp,sp,-32
    80002274:	ec06                	sd	ra,24(sp)
    80002276:	e822                	sd	s0,16(sp)
    80002278:	e426                	sd	s1,8(sp)
    8000227a:	e04a                	sd	s2,0(sp)
    8000227c:	1000                	addi	s0,sp,32
    8000227e:	84aa                	mv	s1,a0
    80002280:	892e                	mv	s2,a1
  if(type>3){
    80002282:	478d                	li	a5,3
    80002284:	04a7c663          	blt	a5,a0,800022d0 <getList+0x5e>
  if(type==readyList || type==11){
    80002288:	c125                	beqz	a0,800022e8 <getList+0x76>
  else if(type==zombeList || type==21){
    8000228a:	4785                	li	a5,1
    8000228c:	08f50263          	beq	a0,a5,80002310 <getList+0x9e>
    80002290:	47d5                	li	a5,21
    80002292:	06f48f63          	beq	s1,a5,80002310 <getList+0x9e>
  else if(type==sleepLeast || type==31){
    80002296:	4789                	li	a5,2
    80002298:	08f48563          	beq	s1,a5,80002322 <getList+0xb0>
    8000229c:	47fd                	li	a5,31
    8000229e:	08f48263          	beq	s1,a5,80002322 <getList+0xb0>
  else if(type==unuseList || type==41){
    800022a2:	478d                	li	a5,3
    800022a4:	08f48863          	beq	s1,a5,80002334 <getList+0xc2>
    800022a8:	02900793          	li	a5,41
    800022ac:	08f48463          	beq	s1,a5,80002334 <getList+0xc2>
  else if(type == 51){
    800022b0:	03300793          	li	a5,51
    800022b4:	08f48963          	beq	s1,a5,80002346 <getList+0xd4>
  else if(type == 61){
    800022b8:	03d00793          	li	a5,61
    800022bc:	0af49363          	bne	s1,a5,80002362 <getList+0xf0>
    print_flag++;
    800022c0:	00008717          	auipc	a4,0x8
    800022c4:	dac70713          	addi	a4,a4,-596 # 8000a06c <print_flag>
    800022c8:	431c                	lw	a5,0(a4)
    800022ca:	2785                	addiw	a5,a5,1
    800022cc:	c31c                	sw	a5,0(a4)
    800022ce:	a81d                	j	80002304 <getList+0x92>
  printf("type is %d\n",type);
    800022d0:	85aa                	mv	a1,a0
    800022d2:	00007517          	auipc	a0,0x7
    800022d6:	f7e50513          	addi	a0,a0,-130 # 80009250 <digits+0x210>
    800022da:	ffffe097          	auipc	ra,0xffffe
    800022de:	2ae080e7          	jalr	686(ra) # 80000588 <printf>
  if(type==readyList || type==11){
    800022e2:	47ad                	li	a5,11
    800022e4:	faf496e3          	bne	s1,a5,80002290 <getList+0x1e>
    acquire(&ready_lock[cpu_id]);
    800022e8:	00191513          	slli	a0,s2,0x1
    800022ec:	012505b3          	add	a1,a0,s2
    800022f0:	058e                	slli	a1,a1,0x3
    800022f2:	00010517          	auipc	a0,0x10
    800022f6:	22e50513          	addi	a0,a0,558 # 80012520 <ready_lock>
    800022fa:	952e                	add	a0,a0,a1
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	8f0080e7          	jalr	-1808(ra) # 80000bec <acquire>
}
    80002304:	60e2                	ld	ra,24(sp)
    80002306:	6442                	ld	s0,16(sp)
    80002308:	64a2                	ld	s1,8(sp)
    8000230a:	6902                	ld	s2,0(sp)
    8000230c:	6105                	addi	sp,sp,32
    8000230e:	8082                	ret
    acquire(&zombie_lock);
    80002310:	00010517          	auipc	a0,0x10
    80002314:	25850513          	addi	a0,a0,600 # 80012568 <zombie_lock>
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	8d4080e7          	jalr	-1836(ra) # 80000bec <acquire>
    80002320:	b7d5                	j	80002304 <getList+0x92>
  acquire(&sleeping_lock);
    80002322:	00010517          	auipc	a0,0x10
    80002326:	25e50513          	addi	a0,a0,606 # 80012580 <sleeping_lock>
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	8c2080e7          	jalr	-1854(ra) # 80000bec <acquire>
    80002332:	bfc9                	j	80002304 <getList+0x92>
  acquire(&unused_lock);
    80002334:	00010517          	auipc	a0,0x10
    80002338:	26450513          	addi	a0,a0,612 # 80012598 <unused_lock>
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	8b0080e7          	jalr	-1872(ra) # 80000bec <acquire>
    80002344:	b7c1                	j	80002304 <getList+0x92>
    set_cpu(cpu_id);
    80002346:	854a                	mv	a0,s2
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	ed6080e7          	jalr	-298(ra) # 8000221e <set_cpu>
    printf("getList type ==5");
    80002350:	00007517          	auipc	a0,0x7
    80002354:	fb050513          	addi	a0,a0,-80 # 80009300 <digits+0x2c0>
    80002358:	ffffe097          	auipc	ra,0xffffe
    8000235c:	230080e7          	jalr	560(ra) # 80000588 <printf>
    80002360:	b755                	j	80002304 <getList+0x92>
    panic("getList");
    80002362:	00007517          	auipc	a0,0x7
    80002366:	fb650513          	addi	a0,a0,-74 # 80009318 <digits+0x2d8>
    8000236a:	ffffe097          	auipc	ra,0xffffe
    8000236e:	1d4080e7          	jalr	468(ra) # 8000053e <panic>

0000000080002372 <setFirst>:
{
    80002372:	7179                	addi	sp,sp,-48
    80002374:	f406                	sd	ra,40(sp)
    80002376:	f022                	sd	s0,32(sp)
    80002378:	ec26                	sd	s1,24(sp)
    8000237a:	e84a                	sd	s2,16(sp)
    8000237c:	e44e                	sd	s3,8(sp)
    8000237e:	1800                	addi	s0,sp,48
    80002380:	89aa                	mv	s3,a0
    80002382:	84ae                	mv	s1,a1
    80002384:	8932                	mv	s2,a2
  if(type>3){
    80002386:	478d                	li	a5,3
    80002388:	02b7c663          	blt	a5,a1,800023b4 <setFirst+0x42>
  if(type==readyList || type==11){
    8000238c:	eddd                	bnez	a1,8000244a <setFirst+0xd8>
    cpus[cpu_id].first = p;
    8000238e:	00391793          	slli	a5,s2,0x3
    80002392:	01278633          	add	a2,a5,s2
    80002396:	0612                	slli	a2,a2,0x4
    80002398:	00010797          	auipc	a5,0x10
    8000239c:	f4878793          	addi	a5,a5,-184 # 800122e0 <readyLock>
    800023a0:	963e                	add	a2,a2,a5
    800023a2:	11363c23          	sd	s3,280(a2) # 1118 <_entry-0x7fffeee8>
}
    800023a6:	70a2                	ld	ra,40(sp)
    800023a8:	7402                	ld	s0,32(sp)
    800023aa:	64e2                	ld	s1,24(sp)
    800023ac:	6942                	ld	s2,16(sp)
    800023ae:	69a2                	ld	s3,8(sp)
    800023b0:	6145                	addi	sp,sp,48
    800023b2:	8082                	ret
  printf("type is %d\n",type);
    800023b4:	00007517          	auipc	a0,0x7
    800023b8:	e9c50513          	addi	a0,a0,-356 # 80009250 <digits+0x210>
    800023bc:	ffffe097          	auipc	ra,0xffffe
    800023c0:	1cc080e7          	jalr	460(ra) # 80000588 <printf>
  if(type==readyList || type==11){
    800023c4:	47ad                	li	a5,11
    800023c6:	fcf484e3          	beq	s1,a5,8000238e <setFirst+0x1c>
  else if(type==zombeList || type==21){
    800023ca:	47d5                	li	a5,21
    800023cc:	08f48263          	beq	s1,a5,80002450 <setFirst+0xde>
  else if(type==sleepLeast || type==31){
    800023d0:	4789                	li	a5,2
    800023d2:	02f48c63          	beq	s1,a5,8000240a <setFirst+0x98>
    800023d6:	47fd                	li	a5,31
    800023d8:	02f48963          	beq	s1,a5,8000240a <setFirst+0x98>
  else if(type==unuseList || type==41){
    800023dc:	478d                	li	a5,3
    800023de:	02f48b63          	beq	s1,a5,80002414 <setFirst+0xa2>
    800023e2:	02900793          	li	a5,41
    800023e6:	02f48763          	beq	s1,a5,80002414 <setFirst+0xa2>
  else if(type == 51){
    800023ea:	03300793          	li	a5,51
    800023ee:	02f48863          	beq	s1,a5,8000241e <setFirst+0xac>
  else if(type == 61){
    800023f2:	03d00793          	li	a5,61
    800023f6:	04f49263          	bne	s1,a5,8000243a <setFirst+0xc8>
    print_flag++;
    800023fa:	00008717          	auipc	a4,0x8
    800023fe:	c7270713          	addi	a4,a4,-910 # 8000a06c <print_flag>
    80002402:	431c                	lw	a5,0(a4)
    80002404:	2785                	addiw	a5,a5,1
    80002406:	c31c                	sw	a5,0(a4)
    80002408:	bf79                	j	800023a6 <setFirst+0x34>
    sleeping_list = p;
    8000240a:	00008797          	auipc	a5,0x8
    8000240e:	c137bf23          	sd	s3,-994(a5) # 8000a028 <sleeping_list>
    80002412:	bf51                	j	800023a6 <setFirst+0x34>
  unused_list = p;
    80002414:	00008797          	auipc	a5,0x8
    80002418:	c137be23          	sd	s3,-996(a5) # 8000a030 <unused_list>
    8000241c:	b769                	j	800023a6 <setFirst+0x34>
    set_cpu(cpu_id);
    8000241e:	854a                	mv	a0,s2
    80002420:	00000097          	auipc	ra,0x0
    80002424:	dfe080e7          	jalr	-514(ra) # 8000221e <set_cpu>
    printf("getList type ==5");
    80002428:	00007517          	auipc	a0,0x7
    8000242c:	ed850513          	addi	a0,a0,-296 # 80009300 <digits+0x2c0>
    80002430:	ffffe097          	auipc	ra,0xffffe
    80002434:	158080e7          	jalr	344(ra) # 80000588 <printf>
    80002438:	b7bd                	j	800023a6 <setFirst+0x34>
    panic("getList");
    8000243a:	00007517          	auipc	a0,0x7
    8000243e:	ede50513          	addi	a0,a0,-290 # 80009318 <digits+0x2d8>
    80002442:	ffffe097          	auipc	ra,0xffffe
    80002446:	0fc080e7          	jalr	252(ra) # 8000053e <panic>
  else if(type==zombeList || type==21){
    8000244a:	4785                	li	a5,1
    8000244c:	f6f59fe3          	bne	a1,a5,800023ca <setFirst+0x58>
    zombie_list = p;
    80002450:	00008797          	auipc	a5,0x8
    80002454:	bf37b423          	sd	s3,-1048(a5) # 8000a038 <zombie_list>
    80002458:	b7b9                	j	800023a6 <setFirst+0x34>

000000008000245a <add_proc_to_specific_list>:
{
    8000245a:	711d                	addi	sp,sp,-96
    8000245c:	ec86                	sd	ra,88(sp)
    8000245e:	e8a2                	sd	s0,80(sp)
    80002460:	e4a6                	sd	s1,72(sp)
    80002462:	e0ca                	sd	s2,64(sp)
    80002464:	fc4e                	sd	s3,56(sp)
    80002466:	f852                	sd	s4,48(sp)
    80002468:	f456                	sd	s5,40(sp)
    8000246a:	f05a                	sd	s6,32(sp)
    8000246c:	ec5e                	sd	s7,24(sp)
    8000246e:	e862                	sd	s8,16(sp)
    80002470:	e466                	sd	s9,8(sp)
    80002472:	e06a                	sd	s10,0(sp)
    80002474:	1080                	addi	s0,sp,96
  if(!p){
    80002476:	c129                	beqz	a0,800024b8 <add_proc_to_specific_list+0x5e>
    80002478:	8c2a                	mv	s8,a0
    8000247a:	8b2e                	mv	s6,a1
    8000247c:	8bb2                	mv	s7,a2
    8000247e:	89b6                	mv	s3,a3
  if(debug_flag==debugFlag){
    80002480:	4791                	li	a5,4
    80002482:	04f68363          	beq	a3,a5,800024c8 <add_proc_to_specific_list+0x6e>
  getList(type, cpu_id);//get the corect list for proc state
    80002486:	85b2                	mv	a1,a2
    80002488:	855a                	mv	a0,s6
    8000248a:	00000097          	auipc	ra,0x0
    8000248e:	de8080e7          	jalr	-536(ra) # 80002272 <getList>
  current = getFirst(type, cpu_id);
    80002492:	85de                	mv	a1,s7
    80002494:	855a                	mv	a0,s6
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	692080e7          	jalr	1682(ra) # 80001b28 <getFirst>
    8000249e:	84aa                	mv	s1,a0
  struct proc* prev = 0;
    800024a0:	4901                	li	s2,0
  if(!current){// if the list empty so current is first 
    800024a2:	c4a5                	beqz	s1,8000250a <add_proc_to_specific_list+0xb0>
        if(debug_flag==debugFlag){
    800024a4:	4a91                	li	s5,4
          printf("prev is %d\n",prev);
    800024a6:	00007d17          	auipc	s10,0x7
    800024aa:	ebad0d13          	addi	s10,s10,-326 # 80009360 <digits+0x320>
          printf("type is %d\n",type);
    800024ae:	00007c97          	auipc	s9,0x7
    800024b2:	da2c8c93          	addi	s9,s9,-606 # 80009250 <digits+0x210>
    800024b6:	a061                	j	8000253e <add_proc_to_specific_list+0xe4>
    panic("add_proc_to_specific_list");
    800024b8:	00007517          	auipc	a0,0x7
    800024bc:	e6850513          	addi	a0,a0,-408 # 80009320 <digits+0x2e0>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	07e080e7          	jalr	126(ra) # 8000053e <panic>
    printf("id is %d\n",prev->parent_cpu);
    800024c8:	05802583          	lw	a1,88(zero) # 58 <_entry-0x7fffffa8>
    800024cc:	00007517          	auipc	a0,0x7
    800024d0:	e7450513          	addi	a0,a0,-396 # 80009340 <digits+0x300>
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	0b4080e7          	jalr	180(ra) # 80000588 <printf>
  getList(type, cpu_id);//get the corect list for proc state
    800024dc:	85de                	mv	a1,s7
    800024de:	855a                	mv	a0,s6
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	d92080e7          	jalr	-622(ra) # 80002272 <getList>
  current = getFirst(type, cpu_id);
    800024e8:	85de                	mv	a1,s7
    800024ea:	855a                	mv	a0,s6
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	63c080e7          	jalr	1596(ra) # 80001b28 <getFirst>
    800024f4:	84aa                	mv	s1,a0
    printf("current is %d\n",current);
    800024f6:	85aa                	mv	a1,a0
    800024f8:	00007517          	auipc	a0,0x7
    800024fc:	e5850513          	addi	a0,a0,-424 # 80009350 <digits+0x310>
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	088080e7          	jalr	136(ra) # 80000588 <printf>
    80002508:	bf61                	j	800024a0 <add_proc_to_specific_list+0x46>
    setFirst(p, type, cpu_id);
    8000250a:	865e                	mv	a2,s7
    8000250c:	85da                	mv	a1,s6
    8000250e:	8562                	mv	a0,s8
    80002510:	00000097          	auipc	ra,0x0
    80002514:	e62080e7          	jalr	-414(ra) # 80002372 <setFirst>
    release_list(type, cpu_id);
    80002518:	85de                	mv	a1,s7
    8000251a:	855a                	mv	a0,s6
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	73a080e7          	jalr	1850(ra) # 80001c56 <release_list>
    80002524:	a0a5                	j	8000258c <add_proc_to_specific_list+0x132>
        release(&prev->list_lock);
    80002526:	01890513          	addi	a0,s2,24
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	77c080e7          	jalr	1916(ra) # 80000ca6 <release>
        if(debug_flag==debugFlag){
    80002532:	03598f63          	beq	s3,s5,80002570 <add_proc_to_specific_list+0x116>
      current = current->next;
    80002536:	68bc                	ld	a5,80(s1)
    while(current){
    80002538:	8926                	mv	s2,s1
    8000253a:	c3b1                	beqz	a5,8000257e <add_proc_to_specific_list+0x124>
      current = current->next;
    8000253c:	84be                	mv	s1,a5
      acquire(&current->list_lock);
    8000253e:	01848a13          	addi	s4,s1,24
    80002542:	8552                	mv	a0,s4
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	6a8080e7          	jalr	1704(ra) # 80000bec <acquire>
      if(prev){
    8000254c:	00090b63          	beqz	s2,80002562 <add_proc_to_specific_list+0x108>
        if(debug_flag==debugFlag){
    80002550:	fd599be3          	bne	s3,s5,80002526 <add_proc_to_specific_list+0xcc>
          printf("prev is %d\n",prev);
    80002554:	85ca                	mv	a1,s2
    80002556:	856a                	mv	a0,s10
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	030080e7          	jalr	48(ra) # 80000588 <printf>
    80002560:	b7d9                	j	80002526 <add_proc_to_specific_list+0xcc>
        release_list(type, cpu_id);
    80002562:	85de                	mv	a1,s7
    80002564:	855a                	mv	a0,s6
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	6f0080e7          	jalr	1776(ra) # 80001c56 <release_list>
    8000256e:	b7d1                	j	80002532 <add_proc_to_specific_list+0xd8>
          printf("type is %d\n",type);
    80002570:	85da                	mv	a1,s6
    80002572:	8566                	mv	a0,s9
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	014080e7          	jalr	20(ra) # 80000588 <printf>
    8000257c:	bf6d                	j	80002536 <add_proc_to_specific_list+0xdc>
    prev->next = p;
    8000257e:	0584b823          	sd	s8,80(s1)
    release(&prev->list_lock);
    80002582:	8552                	mv	a0,s4
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	722080e7          	jalr	1826(ra) # 80000ca6 <release>
}
    8000258c:	60e6                	ld	ra,88(sp)
    8000258e:	6446                	ld	s0,80(sp)
    80002590:	64a6                	ld	s1,72(sp)
    80002592:	6906                	ld	s2,64(sp)
    80002594:	79e2                	ld	s3,56(sp)
    80002596:	7a42                	ld	s4,48(sp)
    80002598:	7aa2                	ld	s5,40(sp)
    8000259a:	7b02                	ld	s6,32(sp)
    8000259c:	6be2                	ld	s7,24(sp)
    8000259e:	6c42                	ld	s8,16(sp)
    800025a0:	6ca2                	ld	s9,8(sp)
    800025a2:	6d02                	ld	s10,0(sp)
    800025a4:	6125                	addi	sp,sp,96
    800025a6:	8082                	ret

00000000800025a8 <procinit>:
{
    800025a8:	715d                	addi	sp,sp,-80
    800025aa:	e486                	sd	ra,72(sp)
    800025ac:	e0a2                	sd	s0,64(sp)
    800025ae:	fc26                	sd	s1,56(sp)
    800025b0:	f84a                	sd	s2,48(sp)
    800025b2:	f44e                	sd	s3,40(sp)
    800025b4:	f052                	sd	s4,32(sp)
    800025b6:	ec56                	sd	s5,24(sp)
    800025b8:	e85a                	sd	s6,16(sp)
    800025ba:	e45e                	sd	s7,8(sp)
    800025bc:	e062                	sd	s8,0(sp)
    800025be:	0880                	addi	s0,sp,80
  initlock(&sleeping_lock, "sleeping lock");
    800025c0:	00007597          	auipc	a1,0x7
    800025c4:	db058593          	addi	a1,a1,-592 # 80009370 <digits+0x330>
    800025c8:	00010517          	auipc	a0,0x10
    800025cc:	fb850513          	addi	a0,a0,-72 # 80012580 <sleeping_lock>
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	584080e7          	jalr	1412(ra) # 80000b54 <initlock>
  initlock(&pid_lock, "nextpid");
    800025d8:	00007597          	auipc	a1,0x7
    800025dc:	da858593          	addi	a1,a1,-600 # 80009380 <digits+0x340>
    800025e0:	00010517          	auipc	a0,0x10
    800025e4:	fd050513          	addi	a0,a0,-48 # 800125b0 <pid_lock>
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	56c080e7          	jalr	1388(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused lock");
    800025f0:	00007597          	auipc	a1,0x7
    800025f4:	d9858593          	addi	a1,a1,-616 # 80009388 <digits+0x348>
    800025f8:	00010517          	auipc	a0,0x10
    800025fc:	fa050513          	addi	a0,a0,-96 # 80012598 <unused_lock>
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	554080e7          	jalr	1364(ra) # 80000b54 <initlock>
  initlock(&zombie_lock, "zombie lock");
    80002608:	00007597          	auipc	a1,0x7
    8000260c:	d9058593          	addi	a1,a1,-624 # 80009398 <digits+0x358>
    80002610:	00010517          	auipc	a0,0x10
    80002614:	f5850513          	addi	a0,a0,-168 # 80012568 <zombie_lock>
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	53c080e7          	jalr	1340(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait lock");
    80002620:	00007597          	auipc	a1,0x7
    80002624:	d8858593          	addi	a1,a1,-632 # 800093a8 <digits+0x368>
    80002628:	00010517          	auipc	a0,0x10
    8000262c:	fa050513          	addi	a0,a0,-96 # 800125c8 <wait_lock>
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	524080e7          	jalr	1316(ra) # 80000b54 <initlock>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    80002638:	00010497          	auipc	s1,0x10
    8000263c:	ee848493          	addi	s1,s1,-280 # 80012520 <ready_lock>
    initlock(s, "ready lock");
    80002640:	00007997          	auipc	s3,0x7
    80002644:	d7898993          	addi	s3,s3,-648 # 800093b8 <digits+0x378>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    80002648:	00010917          	auipc	s2,0x10
    8000264c:	f2090913          	addi	s2,s2,-224 # 80012568 <zombie_lock>
    initlock(s, "ready lock");
    80002650:	85ce                	mv	a1,s3
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	500080e7          	jalr	1280(ra) # 80000b54 <initlock>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    8000265c:	04e1                	addi	s1,s1,24
    8000265e:	ff2499e3          	bne	s1,s2,80002650 <procinit+0xa8>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002662:	00010497          	auipc	s1,0x10
    80002666:	f7e48493          	addi	s1,s1,-130 # 800125e0 <proc>
      initlock(&p->lock, "proc");
    8000266a:	00007c17          	auipc	s8,0x7
    8000266e:	d5ec0c13          	addi	s8,s8,-674 # 800093c8 <digits+0x388>
      initlock(&p->list_lock, "list lock");
    80002672:	00007b97          	auipc	s7,0x7
    80002676:	d5eb8b93          	addi	s7,s7,-674 # 800093d0 <digits+0x390>
      p->kstack = KSTACK((int) (p - proc));
    8000267a:	8b26                	mv	s6,s1
    8000267c:	00007a97          	auipc	s5,0x7
    80002680:	984a8a93          	addi	s5,s5,-1660 # 80009000 <etext>
    80002684:	04000937          	lui	s2,0x4000
    80002688:	197d                	addi	s2,s2,-1
    8000268a:	0932                	slli	s2,s2,0xc
       p->parent_cpu = -11;
    8000268c:	5a55                	li	s4,-11
  for(p = proc; p < &proc[NPROC]; p++) {
    8000268e:	00016997          	auipc	s3,0x16
    80002692:	35298993          	addi	s3,s3,850 # 800189e0 <tickslock>
      initlock(&p->lock, "proc");
    80002696:	85e2                	mv	a1,s8
    80002698:	8526                	mv	a0,s1
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	4ba080e7          	jalr	1210(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list lock");
    800026a2:	85de                	mv	a1,s7
    800026a4:	01848513          	addi	a0,s1,24
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	4ac080e7          	jalr	1196(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800026b0:	416487b3          	sub	a5,s1,s6
    800026b4:	8791                	srai	a5,a5,0x4
    800026b6:	000ab703          	ld	a4,0(s5)
    800026ba:	02e787b3          	mul	a5,a5,a4
    800026be:	2785                	addiw	a5,a5,1
    800026c0:	00d7979b          	slliw	a5,a5,0xd
    800026c4:	40f907b3          	sub	a5,s2,a5
    800026c8:	f4bc                	sd	a5,104(s1)
       p->parent_cpu = -11;
    800026ca:	0544ac23          	sw	s4,88(s1)
       add_proc_to_specific_list(p, unuseList, -1,0);
    800026ce:	4681                	li	a3,0
    800026d0:	567d                	li	a2,-1
    800026d2:	458d                	li	a1,3
    800026d4:	8526                	mv	a0,s1
    800026d6:	00000097          	auipc	ra,0x0
    800026da:	d84080e7          	jalr	-636(ra) # 8000245a <add_proc_to_specific_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026de:	19048493          	addi	s1,s1,400
    800026e2:	fb349ae3          	bne	s1,s3,80002696 <procinit+0xee>
}
    800026e6:	60a6                	ld	ra,72(sp)
    800026e8:	6406                	ld	s0,64(sp)
    800026ea:	74e2                	ld	s1,56(sp)
    800026ec:	7942                	ld	s2,48(sp)
    800026ee:	79a2                	ld	s3,40(sp)
    800026f0:	7a02                	ld	s4,32(sp)
    800026f2:	6ae2                	ld	s5,24(sp)
    800026f4:	6b42                	ld	s6,16(sp)
    800026f6:	6ba2                	ld	s7,8(sp)
    800026f8:	6c02                	ld	s8,0(sp)
    800026fa:	6161                	addi	sp,sp,80
    800026fc:	8082                	ret

00000000800026fe <get_first>:
{   
    800026fe:	7179                	addi	sp,sp,-48
    80002700:	f406                	sd	ra,40(sp)
    80002702:	f022                	sd	s0,32(sp)
    80002704:	ec26                	sd	s1,24(sp)
    80002706:	e84a                	sd	s2,16(sp)
    80002708:	e44e                	sd	s3,8(sp)
    8000270a:	e052                	sd	s4,0(sp)
    8000270c:	1800                	addi	s0,sp,48
    8000270e:	892a                	mv	s2,a0
    80002710:	89ae                	mv	s3,a1
  getList(number, parent_cpu);                      //acquire lock for the list 
    80002712:	00000097          	auipc	ra,0x0
    80002716:	b60080e7          	jalr	-1184(ra) # 80002272 <getList>
  struct proc* first = getFirst(number, parent_cpu);//aquire first proc in the list after we have loock 
    8000271a:	85ce                	mv	a1,s3
    8000271c:	854a                	mv	a0,s2
    8000271e:	fffff097          	auipc	ra,0xfffff
    80002722:	40a080e7          	jalr	1034(ra) # 80001b28 <getFirst>
    80002726:	84aa                	mv	s1,a0
  if(!first){                                 // there only one in the list and we return him
    80002728:	c921                	beqz	a0,80002778 <get_first+0x7a>
    else if(number==debugFlag){ 
    8000272a:	4791                	li	a5,4
    8000272c:	04f90d63          	beq	s2,a5,80002786 <get_first+0x88>
    acquire(&first->list_lock);               //grab the loock of proc in list
    80002730:	01850a13          	addi	s4,a0,24
    80002734:	8552                	mv	a0,s4
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	4b6080e7          	jalr	1206(ra) # 80000bec <acquire>
    setFirst(first->next, number, parent_cpu);
    8000273e:	864e                	mv	a2,s3
    80002740:	85ca                	mv	a1,s2
    80002742:	68a8                	ld	a0,80(s1)
    80002744:	00000097          	auipc	ra,0x0
    80002748:	c2e080e7          	jalr	-978(ra) # 80002372 <setFirst>
    first->next = 0;
    8000274c:	0404b823          	sd	zero,80(s1)
    release(&first->list_lock);
    80002750:	8552                	mv	a0,s4
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	554080e7          	jalr	1364(ra) # 80000ca6 <release>
    release_list(number, parent_cpu);//realese loock 
    8000275a:	85ce                	mv	a1,s3
    8000275c:	854a                	mv	a0,s2
    8000275e:	fffff097          	auipc	ra,0xfffff
    80002762:	4f8080e7          	jalr	1272(ra) # 80001c56 <release_list>
}
    80002766:	8526                	mv	a0,s1
    80002768:	70a2                	ld	ra,40(sp)
    8000276a:	7402                	ld	s0,32(sp)
    8000276c:	64e2                	ld	s1,24(sp)
    8000276e:	6942                	ld	s2,16(sp)
    80002770:	69a2                	ld	s3,8(sp)
    80002772:	6a02                	ld	s4,0(sp)
    80002774:	6145                	addi	sp,sp,48
    80002776:	8082                	ret
    release_list(number, parent_cpu);               //realese loock of the list
    80002778:	85ce                	mv	a1,s3
    8000277a:	854a                	mv	a0,s2
    8000277c:	fffff097          	auipc	ra,0xfffff
    80002780:	4da080e7          	jalr	1242(ra) # 80001c56 <release_list>
    80002784:	b7cd                	j	80002766 <get_first+0x68>
      panic("debugFlag");
    80002786:	00007517          	auipc	a0,0x7
    8000278a:	c5a50513          	addi	a0,a0,-934 # 800093e0 <digits+0x3a0>
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	db0080e7          	jalr	-592(ra) # 8000053e <panic>

0000000080002796 <blncflag_on>:
{
    80002796:	7139                	addi	sp,sp,-64
    80002798:	fc06                	sd	ra,56(sp)
    8000279a:	f822                	sd	s0,48(sp)
    8000279c:	f426                	sd	s1,40(sp)
    8000279e:	f04a                	sd	s2,32(sp)
    800027a0:	ec4e                	sd	s3,24(sp)
    800027a2:	e852                	sd	s4,16(sp)
    800027a4:	e456                	sd	s5,8(sp)
    800027a6:	e05a                	sd	s6,0(sp)
    800027a8:	0080                	addi	s0,sp,64
    800027aa:	8792                	mv	a5,tp
  int id = r_tp();
    800027ac:	2781                	sext.w	a5,a5
    800027ae:	8a12                	mv	s4,tp
    800027b0:	2a01                	sext.w	s4,s4
  c->proc = 0;
    800027b2:	00379993          	slli	s3,a5,0x3
    800027b6:	00f98733          	add	a4,s3,a5
    800027ba:	00471693          	slli	a3,a4,0x4
    800027be:	00010717          	auipc	a4,0x10
    800027c2:	b2270713          	addi	a4,a4,-1246 # 800122e0 <readyLock>
    800027c6:	9736                	add	a4,a4,a3
    800027c8:	08073c23          	sd	zero,152(a4)
    swtch(&c->context, &p->context);
    800027cc:	00010717          	auipc	a4,0x10
    800027d0:	bb470713          	addi	a4,a4,-1100 # 80012380 <cpus+0x10>
    800027d4:	00e689b3          	add	s3,a3,a4
    if(p->state!=RUNNABLE)
    800027d8:	4a8d                	li	s5,3
    p->state = RUNNING;
    800027da:	4b11                	li	s6,4
    c->proc = p;
    800027dc:	00010917          	auipc	s2,0x10
    800027e0:	b0490913          	addi	s2,s2,-1276 # 800122e0 <readyLock>
    800027e4:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ee:	10079073          	csrw	sstatus,a5
    p = get_first(readyList, cpu_id);
    800027f2:	85d2                	mv	a1,s4
    800027f4:	4501                	li	a0,0
    800027f6:	00000097          	auipc	ra,0x0
    800027fa:	f08080e7          	jalr	-248(ra) # 800026fe <get_first>
    800027fe:	84aa                	mv	s1,a0
    if(!p){
    80002800:	d17d                	beqz	a0,800027e6 <blncflag_on+0x50>
    acquire(&p->lock);
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	3ea080e7          	jalr	1002(ra) # 80000bec <acquire>
    if(p->state!=RUNNABLE)
    8000280a:	589c                	lw	a5,48(s1)
    8000280c:	03579563          	bne	a5,s5,80002836 <blncflag_on+0xa0>
    p->state = RUNNING;
    80002810:	0364a823          	sw	s6,48(s1)
    c->proc = p;
    80002814:	08993c23          	sd	s1,152(s2)
    swtch(&c->context, &p->context);
    80002818:	08848593          	addi	a1,s1,136
    8000281c:	854e                	mv	a0,s3
    8000281e:	00001097          	auipc	ra,0x1
    80002822:	c0c080e7          	jalr	-1012(ra) # 8000342a <swtch>
    c->proc = 0;
    80002826:	08093c23          	sd	zero,152(s2)
    release(&p->lock);
    8000282a:	8526                	mv	a0,s1
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	47a080e7          	jalr	1146(ra) # 80000ca6 <release>
    80002834:	bf4d                	j	800027e6 <blncflag_on+0x50>
      panic("bad proc was selected");
    80002836:	00007517          	auipc	a0,0x7
    8000283a:	bba50513          	addi	a0,a0,-1094 # 800093f0 <digits+0x3b0>
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	d00080e7          	jalr	-768(ra) # 8000053e <panic>

0000000080002846 <scheduler>:
{
    80002846:	1141                	addi	sp,sp,-16
    80002848:	e406                	sd	ra,8(sp)
    8000284a:	e022                	sd	s0,0(sp)
    8000284c:	0800                	addi	s0,sp,16
      if(!print_flag){
    8000284e:	00008797          	auipc	a5,0x8
    80002852:	81e7a783          	lw	a5,-2018(a5) # 8000a06c <print_flag>
    80002856:	c789                	beqz	a5,80002860 <scheduler+0x1a>
    blncflag_on();
    80002858:	00000097          	auipc	ra,0x0
    8000285c:	f3e080e7          	jalr	-194(ra) # 80002796 <blncflag_on>
      print_flag++;
    80002860:	4785                	li	a5,1
    80002862:	00008717          	auipc	a4,0x8
    80002866:	80f72523          	sw	a5,-2038(a4) # 8000a06c <print_flag>
      printf("BLNCFLG is ON\n");
    8000286a:	00007517          	auipc	a0,0x7
    8000286e:	b9e50513          	addi	a0,a0,-1122 # 80009408 <digits+0x3c8>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	d16080e7          	jalr	-746(ra) # 80000588 <printf>
    8000287a:	bff9                	j	80002858 <scheduler+0x12>

000000008000287c <blncflag_off>:
{
    8000287c:	7139                	addi	sp,sp,-64
    8000287e:	fc06                	sd	ra,56(sp)
    80002880:	f822                	sd	s0,48(sp)
    80002882:	f426                	sd	s1,40(sp)
    80002884:	f04a                	sd	s2,32(sp)
    80002886:	ec4e                	sd	s3,24(sp)
    80002888:	e852                	sd	s4,16(sp)
    8000288a:	e456                	sd	s5,8(sp)
    8000288c:	e05a                	sd	s6,0(sp)
    8000288e:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80002890:	8792                	mv	a5,tp
  int id = r_tp();
    80002892:	2781                	sext.w	a5,a5
    80002894:	8a12                	mv	s4,tp
    80002896:	2a01                	sext.w	s4,s4
  c->proc = 0;
    80002898:	00379993          	slli	s3,a5,0x3
    8000289c:	00f98733          	add	a4,s3,a5
    800028a0:	00471693          	slli	a3,a4,0x4
    800028a4:	00010717          	auipc	a4,0x10
    800028a8:	a3c70713          	addi	a4,a4,-1476 # 800122e0 <readyLock>
    800028ac:	9736                	add	a4,a4,a3
    800028ae:	08073c23          	sd	zero,152(a4)
        swtch(&c->context, &p->context);
    800028b2:	00010717          	auipc	a4,0x10
    800028b6:	ace70713          	addi	a4,a4,-1330 # 80012380 <cpus+0x10>
    800028ba:	00e689b3          	add	s3,a3,a4
      if(p->state != RUNNABLE)
    800028be:	4a8d                	li	s5,3
        p->state = RUNNING;
    800028c0:	4b11                	li	s6,4
        c->proc = p;
    800028c2:	00010917          	auipc	s2,0x10
    800028c6:	a1e90913          	addi	s2,s2,-1506 # 800122e0 <readyLock>
    800028ca:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028d0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d4:	10079073          	csrw	sstatus,a5
    p = get_first(readyList, cpu_id);
    800028d8:	85d2                	mv	a1,s4
    800028da:	4501                	li	a0,0
    800028dc:	00000097          	auipc	ra,0x0
    800028e0:	e22080e7          	jalr	-478(ra) # 800026fe <get_first>
    800028e4:	84aa                	mv	s1,a0
    if(!p){ // no proces ready 
    800028e6:	d17d                	beqz	a0,800028cc <blncflag_off+0x50>
      acquire(&p->lock);
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	304080e7          	jalr	772(ra) # 80000bec <acquire>
      if(p->state != RUNNABLE)
    800028f0:	589c                	lw	a5,48(s1)
    800028f2:	03579563          	bne	a5,s5,8000291c <blncflag_off+0xa0>
        p->state = RUNNING;
    800028f6:	0364a823          	sw	s6,48(s1)
        c->proc = p;
    800028fa:	08993c23          	sd	s1,152(s2)
        swtch(&c->context, &p->context);
    800028fe:	08848593          	addi	a1,s1,136
    80002902:	854e                	mv	a0,s3
    80002904:	00001097          	auipc	ra,0x1
    80002908:	b26080e7          	jalr	-1242(ra) # 8000342a <swtch>
        c->proc = 0;
    8000290c:	08093c23          	sd	zero,152(s2)
      release(&p->lock);
    80002910:	8526                	mv	a0,s1
    80002912:	ffffe097          	auipc	ra,0xffffe
    80002916:	394080e7          	jalr	916(ra) # 80000ca6 <release>
    8000291a:	bf4d                	j	800028cc <blncflag_off+0x50>
        panic("bad proc was selected");
    8000291c:	00007517          	auipc	a0,0x7
    80002920:	ad450513          	addi	a0,a0,-1324 # 800093f0 <digits+0x3b0>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c1a080e7          	jalr	-998(ra) # 8000053e <panic>

000000008000292c <delete_proc_from_list>:
delete_proc_from_list(struct proc* first,struct proc* proc, int number, int debug_flag){
    8000292c:	7179                	addi	sp,sp,-48
    8000292e:	f406                	sd	ra,40(sp)
    80002930:	f022                	sd	s0,32(sp)
    80002932:	ec26                	sd	s1,24(sp)
    80002934:	e84a                	sd	s2,16(sp)
    80002936:	e44e                	sd	s3,8(sp)
    80002938:	e052                	sd	s4,0(sp)
    8000293a:	1800                	addi	s0,sp,48
    8000293c:	892a                	mv	s2,a0
    8000293e:	84ae                	mv	s1,a1
    80002940:	8a32                	mv	s4,a2
    80002942:	89b6                	mv	s3,a3
  if(debug_flag==debugFlag){
    80002944:	4791                	li	a5,4
    80002946:	02f68963          	beq	a3,a5,80002978 <delete_proc_from_list+0x4c>
  if(!first){
    8000294a:	04090163          	beqz	s2,8000298c <delete_proc_from_list+0x60>
  else if(proc == first){
    8000294e:	04990a63          	beq	s2,s1,800029a2 <delete_proc_from_list+0x76>
    if(debug_flag==debugFlag){
    80002952:	4791                	li	a5,4
    80002954:	0af98163          	beq	s3,a5,800029f6 <delete_proc_from_list+0xca>
    return delete_the_first_not_empty_list(proc,first,number,0);
    80002958:	4681                	li	a3,0
    8000295a:	8652                	mv	a2,s4
    8000295c:	85ca                	mv	a1,s2
    8000295e:	8526                	mv	a0,s1
    80002960:	fffff097          	auipc	ra,0xfffff
    80002964:	39c080e7          	jalr	924(ra) # 80001cfc <delete_the_first_not_empty_list>
}
    80002968:	70a2                	ld	ra,40(sp)
    8000296a:	7402                	ld	s0,32(sp)
    8000296c:	64e2                	ld	s1,24(sp)
    8000296e:	6942                	ld	s2,16(sp)
    80002970:	69a2                	ld	s3,8(sp)
    80002972:	6a02                	ld	s4,0(sp)
    80002974:	6145                	addi	sp,sp,48
    80002976:	8082                	ret
    printf("first is %d",first);
    80002978:	85aa                	mv	a1,a0
    8000297a:	00007517          	auipc	a0,0x7
    8000297e:	92650513          	addi	a0,a0,-1754 # 800092a0 <digits+0x260>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	c06080e7          	jalr	-1018(ra) # 80000588 <printf>
    8000298a:	b7c1                	j	8000294a <delete_proc_from_list+0x1e>
  release_list(number, proc->parent_cpu);
    8000298c:	00010597          	auipc	a1,0x10
    80002990:	cac5a583          	lw	a1,-852(a1) # 80012638 <proc+0x58>
    80002994:	8552                	mv	a0,s4
    80002996:	fffff097          	auipc	ra,0xfffff
    8000299a:	2c0080e7          	jalr	704(ra) # 80001c56 <release_list>
    return delet_the_first(number, proc->parent_cpu);
    8000299e:	4501                	li	a0,0
    800029a0:	b7e1                	j	80002968 <delete_proc_from_list+0x3c>
      acquire(&proc->list_lock);
    800029a2:	01848913          	addi	s2,s1,24
    800029a6:	854a                	mv	a0,s2
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	244080e7          	jalr	580(ra) # 80000bec <acquire>
      setFirst(proc->next, number, proc->parent_cpu);
    800029b0:	4cb0                	lw	a2,88(s1)
    800029b2:	85d2                	mv	a1,s4
    800029b4:	68a8                	ld	a0,80(s1)
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	9bc080e7          	jalr	-1604(ra) # 80002372 <setFirst>
      if(debug_flag==debugFlag){
    800029be:	4791                	li	a5,4
    800029c0:	02f98163          	beq	s3,a5,800029e2 <delete_proc_from_list+0xb6>
      proc->next = 0;
    800029c4:	0404b823          	sd	zero,80(s1)
      release(&proc->list_lock);
    800029c8:	854a                	mv	a0,s2
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	2dc080e7          	jalr	732(ra) # 80000ca6 <release>
      release_list(number, proc->parent_cpu);
    800029d2:	4cac                	lw	a1,88(s1)
    800029d4:	8552                	mv	a0,s4
    800029d6:	fffff097          	auipc	ra,0xfffff
    800029da:	280080e7          	jalr	640(ra) # 80001c56 <release_list>
    return 0;
    800029de:	4501                	li	a0,0
    800029e0:	b761                	j	80002968 <delete_proc_from_list+0x3c>
        printf("nest is %d",proc->parent_cpu);
    800029e2:	4cac                	lw	a1,88(s1)
    800029e4:	00007517          	auipc	a0,0x7
    800029e8:	a3450513          	addi	a0,a0,-1484 # 80009418 <digits+0x3d8>
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	b9c080e7          	jalr	-1124(ra) # 80000588 <printf>
    800029f4:	bfc1                	j	800029c4 <delete_proc_from_list+0x98>
      printf("first is %d",first);
    800029f6:	85ca                	mv	a1,s2
    800029f8:	00007517          	auipc	a0,0x7
    800029fc:	8a850513          	addi	a0,a0,-1880 # 800092a0 <digits+0x260>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	b88080e7          	jalr	-1144(ra) # 80000588 <printf>
    80002a08:	bf81                	j	80002958 <delete_proc_from_list+0x2c>

0000000080002a0a <freeproc>:
{
    80002a0a:	1101                	addi	sp,sp,-32
    80002a0c:	ec06                	sd	ra,24(sp)
    80002a0e:	e822                	sd	s0,16(sp)
    80002a10:	e426                	sd	s1,8(sp)
    80002a12:	1000                	addi	s0,sp,32
    80002a14:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002a16:	6148                	ld	a0,128(a0)
    80002a18:	c509                	beqz	a0,80002a22 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	fde080e7          	jalr	-34(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002a22:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    80002a26:	7ca8                	ld	a0,120(s1)
    80002a28:	c511                	beqz	a0,80002a34 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002a2a:	78ac                	ld	a1,112(s1)
    80002a2c:	fffff097          	auipc	ra,0xfffff
    80002a30:	5ea080e7          	jalr	1514(ra) # 80002016 <proc_freepagetable>
  p->pagetable = 0;
    80002a34:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    80002a38:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    80002a3c:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    80002a40:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    80002a44:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    80002a48:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    80002a4c:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80002a50:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    80002a54:	0204a823          	sw	zero,48(s1)
  getList(zombeList, proc->parent_cpu); // get list is grabing the loock of relevnt list
    80002a58:	00010597          	auipc	a1,0x10
    80002a5c:	be05a583          	lw	a1,-1056(a1) # 80012638 <proc+0x58>
    80002a60:	4505                	li	a0,1
    80002a62:	00000097          	auipc	ra,0x0
    80002a66:	810080e7          	jalr	-2032(ra) # 80002272 <getList>
  struct proc* first = getFirst(zombeList, p->parent_cpu);//aquire first proc in the list after we have loock 
    80002a6a:	4cac                	lw	a1,88(s1)
    80002a6c:	4505                	li	a0,1
    80002a6e:	fffff097          	auipc	ra,0xfffff
    80002a72:	0ba080e7          	jalr	186(ra) # 80001b28 <getFirst>
  delete_proc_from_list(first,p, zombeList,0 );
    80002a76:	4681                	li	a3,0
    80002a78:	4605                	li	a2,1
    80002a7a:	85a6                	mv	a1,s1
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	eb0080e7          	jalr	-336(ra) # 8000292c <delete_proc_from_list>
  add_proc_to_specific_list(p, unuseList, -1,0);
    80002a84:	4681                	li	a3,0
    80002a86:	567d                	li	a2,-1
    80002a88:	458d                	li	a1,3
    80002a8a:	8526                	mv	a0,s1
    80002a8c:	00000097          	auipc	ra,0x0
    80002a90:	9ce080e7          	jalr	-1586(ra) # 8000245a <add_proc_to_specific_list>
}
    80002a94:	60e2                	ld	ra,24(sp)
    80002a96:	6442                	ld	s0,16(sp)
    80002a98:	64a2                	ld	s1,8(sp)
    80002a9a:	6105                	addi	sp,sp,32
    80002a9c:	8082                	ret

0000000080002a9e <allocproc>:
{
    80002a9e:	7179                	addi	sp,sp,-48
    80002aa0:	f406                	sd	ra,40(sp)
    80002aa2:	f022                	sd	s0,32(sp)
    80002aa4:	ec26                	sd	s1,24(sp)
    80002aa6:	e84a                	sd	s2,16(sp)
    80002aa8:	e44e                	sd	s3,8(sp)
    80002aaa:	1800                	addi	s0,sp,48
  p = get_first(unuseList, -1);
    80002aac:	55fd                	li	a1,-1
    80002aae:	450d                	li	a0,3
    80002ab0:	00000097          	auipc	ra,0x0
    80002ab4:	c4e080e7          	jalr	-946(ra) # 800026fe <get_first>
    80002ab8:	84aa                	mv	s1,a0
  if(!p){
    80002aba:	cd39                	beqz	a0,80002b18 <allocproc+0x7a>
  acquire(&p->lock);
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	130080e7          	jalr	304(ra) # 80000bec <acquire>
  p->pid = allocpid();
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	47e080e7          	jalr	1150(ra) # 80001f42 <allocpid>
    80002acc:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80002ace:	4785                	li	a5,1
    80002ad0:	d89c                	sw	a5,48(s1)
  p->next = 0;
    80002ad2:	0404b823          	sd	zero,80(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	01e080e7          	jalr	30(ra) # 80000af4 <kalloc>
    80002ade:	892a                	mv	s2,a0
    80002ae0:	e0c8                	sd	a0,128(s1)
    80002ae2:	c139                	beqz	a0,80002b28 <allocproc+0x8a>
  p->pagetable = proc_pagetable(p);
    80002ae4:	8526                	mv	a0,s1
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	494080e7          	jalr	1172(ra) # 80001f7a <proc_pagetable>
    80002aee:	892a                	mv	s2,a0
    80002af0:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    80002af2:	c539                	beqz	a0,80002b40 <allocproc+0xa2>
  memset(&p->context, 0, sizeof(p->context));
    80002af4:	07000613          	li	a2,112
    80002af8:	4581                	li	a1,0
    80002afa:	08848513          	addi	a0,s1,136
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	1f0080e7          	jalr	496(ra) # 80000cee <memset>
  p->context.ra = (uint64)forkret;
    80002b06:	fffff797          	auipc	a5,0xfffff
    80002b0a:	3f678793          	addi	a5,a5,1014 # 80001efc <forkret>
    80002b0e:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002b10:	74bc                	ld	a5,104(s1)
    80002b12:	6705                	lui	a4,0x1
    80002b14:	97ba                	add	a5,a5,a4
    80002b16:	e8dc                	sd	a5,144(s1)
}
    80002b18:	8526                	mv	a0,s1
    80002b1a:	70a2                	ld	ra,40(sp)
    80002b1c:	7402                	ld	s0,32(sp)
    80002b1e:	64e2                	ld	s1,24(sp)
    80002b20:	6942                	ld	s2,16(sp)
    80002b22:	69a2                	ld	s3,8(sp)
    80002b24:	6145                	addi	sp,sp,48
    80002b26:	8082                	ret
    freeproc(p);
    80002b28:	8526                	mv	a0,s1
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	ee0080e7          	jalr	-288(ra) # 80002a0a <freeproc>
    release(&p->lock);
    80002b32:	8526                	mv	a0,s1
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	172080e7          	jalr	370(ra) # 80000ca6 <release>
    return 0;
    80002b3c:	84ca                	mv	s1,s2
    80002b3e:	bfe9                	j	80002b18 <allocproc+0x7a>
    freeproc(p);
    80002b40:	8526                	mv	a0,s1
    80002b42:	00000097          	auipc	ra,0x0
    80002b46:	ec8080e7          	jalr	-312(ra) # 80002a0a <freeproc>
    release(&p->lock);
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	15a080e7          	jalr	346(ra) # 80000ca6 <release>
    return 0;
    80002b54:	84ca                	mv	s1,s2
    80002b56:	b7c9                	j	80002b18 <allocproc+0x7a>

0000000080002b58 <userinit>:
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	1000                	addi	s0,sp,32
  if(!flag_init){
    80002b62:	00007797          	auipc	a5,0x7
    80002b66:	4de7a783          	lw	a5,1246(a5) # 8000a040 <flag_init>
    80002b6a:	e795                	bnez	a5,80002b96 <userinit+0x3e>
      c->first = 0;
    80002b6c:	0000f797          	auipc	a5,0xf
    80002b70:	77478793          	addi	a5,a5,1908 # 800122e0 <readyLock>
    80002b74:	1007bc23          	sd	zero,280(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    80002b78:	0807b823          	sd	zero,144(a5)
      c->first = 0;
    80002b7c:	1a07b423          	sd	zero,424(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    80002b80:	1207b023          	sd	zero,288(a5)
      c->first = 0;
    80002b84:	2207bc23          	sd	zero,568(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    80002b88:	1a07b823          	sd	zero,432(a5)
    flag_init = 1;
    80002b8c:	4785                	li	a5,1
    80002b8e:	00007717          	auipc	a4,0x7
    80002b92:	4af72923          	sw	a5,1202(a4) # 8000a040 <flag_init>
  p = allocproc();
    80002b96:	00000097          	auipc	ra,0x0
    80002b9a:	f08080e7          	jalr	-248(ra) # 80002a9e <allocproc>
    80002b9e:	84aa                	mv	s1,a0
  initproc = p;
    80002ba0:	00007797          	auipc	a5,0x7
    80002ba4:	4ca7b023          	sd	a0,1216(a5) # 8000a060 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002ba8:	03400613          	li	a2,52
    80002bac:	00007597          	auipc	a1,0x7
    80002bb0:	e6458593          	addi	a1,a1,-412 # 80009a10 <initcode>
    80002bb4:	7d28                	ld	a0,120(a0)
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	7c0080e7          	jalr	1984(ra) # 80001376 <uvminit>
  p->sz = PGSIZE;
    80002bbe:	6785                	lui	a5,0x1
    80002bc0:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    80002bc2:	60d8                	ld	a4,128(s1)
    80002bc4:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002bc8:	60d8                	ld	a4,128(s1)
    80002bca:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002bcc:	4641                	li	a2,16
    80002bce:	00007597          	auipc	a1,0x7
    80002bd2:	85a58593          	addi	a1,a1,-1958 # 80009428 <digits+0x3e8>
    80002bd6:	18048513          	addi	a0,s1,384
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	266080e7          	jalr	614(ra) # 80000e40 <safestrcpy>
  p->cwd = namei("/");
    80002be2:	00007517          	auipc	a0,0x7
    80002be6:	85650513          	addi	a0,a0,-1962 # 80009438 <digits+0x3f8>
    80002bea:	00002097          	auipc	ra,0x2
    80002bee:	0a4080e7          	jalr	164(ra) # 80004c8e <namei>
    80002bf2:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    80002bf6:	478d                	li	a5,3
    80002bf8:	d89c                	sw	a5,48(s1)
  p->parent_cpu = 0;
    80002bfa:	0404ac23          	sw	zero,88(s1)
  BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,a):counter_blance++;
    80002bfe:	4585                	li	a1,1
    80002c00:	4501                	li	a0,0
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	ed6080e7          	jalr	-298(ra) # 80001ad8 <cahnge_number_of_proc>
  cpus[p->parent_cpu].first = p;
    80002c0a:	4cb8                	lw	a4,88(s1)
    80002c0c:	00371793          	slli	a5,a4,0x3
    80002c10:	97ba                	add	a5,a5,a4
    80002c12:	0792                	slli	a5,a5,0x4
    80002c14:	0000f717          	auipc	a4,0xf
    80002c18:	6cc70713          	addi	a4,a4,1740 # 800122e0 <readyLock>
    80002c1c:	97ba                	add	a5,a5,a4
    80002c1e:	1097bc23          	sd	s1,280(a5) # 1118 <_entry-0x7fffeee8>
  release(&p->lock);
    80002c22:	8526                	mv	a0,s1
    80002c24:	ffffe097          	auipc	ra,0xffffe
    80002c28:	082080e7          	jalr	130(ra) # 80000ca6 <release>
}
    80002c2c:	60e2                	ld	ra,24(sp)
    80002c2e:	6442                	ld	s0,16(sp)
    80002c30:	64a2                	ld	s1,8(sp)
    80002c32:	6105                	addi	sp,sp,32
    80002c34:	8082                	ret

0000000080002c36 <fork>:
{
    80002c36:	7179                	addi	sp,sp,-48
    80002c38:	f406                	sd	ra,40(sp)
    80002c3a:	f022                	sd	s0,32(sp)
    80002c3c:	ec26                	sd	s1,24(sp)
    80002c3e:	e84a                	sd	s2,16(sp)
    80002c40:	e44e                	sd	s3,8(sp)
    80002c42:	e052                	sd	s4,0(sp)
    80002c44:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	25c080e7          	jalr	604(ra) # 80001ea2 <myproc>
    80002c4e:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	e4e080e7          	jalr	-434(ra) # 80002a9e <allocproc>
    80002c58:	12050963          	beqz	a0,80002d8a <fork+0x154>
    80002c5c:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002c5e:	0709b603          	ld	a2,112(s3)
    80002c62:	7d2c                	ld	a1,120(a0)
    80002c64:	0789b503          	ld	a0,120(s3)
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	914080e7          	jalr	-1772(ra) # 8000157c <uvmcopy>
    80002c70:	04054663          	bltz	a0,80002cbc <fork+0x86>
  np->sz = p->sz;
    80002c74:	0709b783          	ld	a5,112(s3)
    80002c78:	06f93823          	sd	a5,112(s2)
  *(np->trapframe) = *(p->trapframe);
    80002c7c:	0809b683          	ld	a3,128(s3)
    80002c80:	87b6                	mv	a5,a3
    80002c82:	08093703          	ld	a4,128(s2)
    80002c86:	12068693          	addi	a3,a3,288
    80002c8a:	0007b803          	ld	a6,0(a5)
    80002c8e:	6788                	ld	a0,8(a5)
    80002c90:	6b8c                	ld	a1,16(a5)
    80002c92:	6f90                	ld	a2,24(a5)
    80002c94:	01073023          	sd	a6,0(a4)
    80002c98:	e708                	sd	a0,8(a4)
    80002c9a:	eb0c                	sd	a1,16(a4)
    80002c9c:	ef10                	sd	a2,24(a4)
    80002c9e:	02078793          	addi	a5,a5,32
    80002ca2:	02070713          	addi	a4,a4,32
    80002ca6:	fed792e3          	bne	a5,a3,80002c8a <fork+0x54>
  np->trapframe->a0 = 0;
    80002caa:	08093783          	ld	a5,128(s2)
    80002cae:	0607b823          	sd	zero,112(a5)
    80002cb2:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80002cb6:	17800a13          	li	s4,376
    80002cba:	a03d                	j	80002ce8 <fork+0xb2>
    freeproc(np);
    80002cbc:	854a                	mv	a0,s2
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	d4c080e7          	jalr	-692(ra) # 80002a0a <freeproc>
    release(&np->lock);
    80002cc6:	854a                	mv	a0,s2
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	fde080e7          	jalr	-34(ra) # 80000ca6 <release>
    return -1;
    80002cd0:	5a7d                	li	s4,-1
    80002cd2:	a05d                	j	80002d78 <fork+0x142>
      np->ofile[i] = filedup(p->ofile[i]);
    80002cd4:	00002097          	auipc	ra,0x2
    80002cd8:	650080e7          	jalr	1616(ra) # 80005324 <filedup>
    80002cdc:	009907b3          	add	a5,s2,s1
    80002ce0:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002ce2:	04a1                	addi	s1,s1,8
    80002ce4:	01448763          	beq	s1,s4,80002cf2 <fork+0xbc>
    if(p->ofile[i])
    80002ce8:	009987b3          	add	a5,s3,s1
    80002cec:	6388                	ld	a0,0(a5)
    80002cee:	f17d                	bnez	a0,80002cd4 <fork+0x9e>
    80002cf0:	bfcd                	j	80002ce2 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002cf2:	1789b503          	ld	a0,376(s3)
    80002cf6:	00001097          	auipc	ra,0x1
    80002cfa:	7a4080e7          	jalr	1956(ra) # 8000449a <idup>
    80002cfe:	16a93c23          	sd	a0,376(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002d02:	4641                	li	a2,16
    80002d04:	18098593          	addi	a1,s3,384
    80002d08:	18090513          	addi	a0,s2,384
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	134080e7          	jalr	308(ra) # 80000e40 <safestrcpy>
  pid = np->pid;
    80002d14:	04892a03          	lw	s4,72(s2)
  release(&np->lock);
    80002d18:	854a                	mv	a0,s2
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	f8c080e7          	jalr	-116(ra) # 80000ca6 <release>
  acquire(&wait_lock);
    80002d22:	00010497          	auipc	s1,0x10
    80002d26:	8a648493          	addi	s1,s1,-1882 # 800125c8 <wait_lock>
    80002d2a:	8526                	mv	a0,s1
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	ec0080e7          	jalr	-320(ra) # 80000bec <acquire>
  np->parent = p;
    80002d34:	07393023          	sd	s3,96(s2)
  release(&wait_lock);
    80002d38:	8526                	mv	a0,s1
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	f6c080e7          	jalr	-148(ra) # 80000ca6 <release>
  acquire(&np->lock);
    80002d42:	854a                	mv	a0,s2
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	ea8080e7          	jalr	-344(ra) # 80000bec <acquire>
  np->state = RUNNABLE;
    80002d4c:	478d                	li	a5,3
    80002d4e:	02f92823          	sw	a5,48(s2)
    int cpu_id = (BLNCFLG) ? pick_cpu() : p->parent_cpu;
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	d78080e7          	jalr	-648(ra) # 80001aca <pick_cpu>
    80002d5a:	862a                	mv	a2,a0
  np->parent_cpu = cpu_id;
    80002d5c:	04a92c23          	sw	a0,88(s2)
  add_proc_to_specific_list(np, readyList, cpu_id,0);
    80002d60:	4681                	li	a3,0
    80002d62:	4581                	li	a1,0
    80002d64:	854a                	mv	a0,s2
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	6f4080e7          	jalr	1780(ra) # 8000245a <add_proc_to_specific_list>
  release(&np->lock);
    80002d6e:	854a                	mv	a0,s2
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	f36080e7          	jalr	-202(ra) # 80000ca6 <release>
}
    80002d78:	8552                	mv	a0,s4
    80002d7a:	70a2                	ld	ra,40(sp)
    80002d7c:	7402                	ld	s0,32(sp)
    80002d7e:	64e2                	ld	s1,24(sp)
    80002d80:	6942                	ld	s2,16(sp)
    80002d82:	69a2                	ld	s3,8(sp)
    80002d84:	6a02                	ld	s4,0(sp)
    80002d86:	6145                	addi	sp,sp,48
    80002d88:	8082                	ret
    return -1;
    80002d8a:	5a7d                	li	s4,-1
    80002d8c:	b7f5                	j	80002d78 <fork+0x142>

0000000080002d8e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002d8e:	7179                	addi	sp,sp,-48
    80002d90:	f406                	sd	ra,40(sp)
    80002d92:	f022                	sd	s0,32(sp)
    80002d94:	ec26                	sd	s1,24(sp)
    80002d96:	e84a                	sd	s2,16(sp)
    80002d98:	e44e                	sd	s3,8(sp)
    80002d9a:	1800                	addi	s0,sp,48
    80002d9c:	89aa                	mv	s3,a0
    80002d9e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	102080e7          	jalr	258(ra) # 80001ea2 <myproc>
    80002da8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002daa:	ffffe097          	auipc	ra,0xffffe
    80002dae:	e42080e7          	jalr	-446(ra) # 80000bec <acquire>
  release(lk);
    80002db2:	854a                	mv	a0,s2
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	ef2080e7          	jalr	-270(ra) # 80000ca6 <release>

  // Go to sleep.
  p->chan = chan;
    80002dbc:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    80002dc0:	4789                	li	a5,2
    80002dc2:	d89c                	sw	a5,48(s1)
  // decrease_size(p->parent_cpu);
  int b=-1;
  BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,b):counter_blance++;
    80002dc4:	55fd                	li	a1,-1
    80002dc6:	4ca8                	lw	a0,88(s1)
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	d10080e7          	jalr	-752(ra) # 80001ad8 <cahnge_number_of_proc>
  //--------------------------------------------------------------------
    add_proc_to_specific_list(p, sleepLeast,-1,0);
    80002dd0:	4681                	li	a3,0
    80002dd2:	567d                	li	a2,-1
    80002dd4:	4589                	li	a1,2
    80002dd6:	8526                	mv	a0,s1
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	682080e7          	jalr	1666(ra) # 8000245a <add_proc_to_specific_list>
  //--------------------------------------------------------------------

  sched();
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	2fc080e7          	jalr	764(ra) # 800020dc <sched>

  // Tidy up.
  p->chan = 0;
    80002de8:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002dec:	8526                	mv	a0,s1
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	eb8080e7          	jalr	-328(ra) # 80000ca6 <release>
  acquire(lk);
    80002df6:	854a                	mv	a0,s2
    80002df8:	ffffe097          	auipc	ra,0xffffe
    80002dfc:	df4080e7          	jalr	-524(ra) # 80000bec <acquire>

}
    80002e00:	70a2                	ld	ra,40(sp)
    80002e02:	7402                	ld	s0,32(sp)
    80002e04:	64e2                	ld	s1,24(sp)
    80002e06:	6942                	ld	s2,16(sp)
    80002e08:	69a2                	ld	s3,8(sp)
    80002e0a:	6145                	addi	sp,sp,48
    80002e0c:	8082                	ret

0000000080002e0e <wait>:
{
    80002e0e:	715d                	addi	sp,sp,-80
    80002e10:	e486                	sd	ra,72(sp)
    80002e12:	e0a2                	sd	s0,64(sp)
    80002e14:	fc26                	sd	s1,56(sp)
    80002e16:	f84a                	sd	s2,48(sp)
    80002e18:	f44e                	sd	s3,40(sp)
    80002e1a:	f052                	sd	s4,32(sp)
    80002e1c:	ec56                	sd	s5,24(sp)
    80002e1e:	e85a                	sd	s6,16(sp)
    80002e20:	e45e                	sd	s7,8(sp)
    80002e22:	e062                	sd	s8,0(sp)
    80002e24:	0880                	addi	s0,sp,80
    80002e26:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	07a080e7          	jalr	122(ra) # 80001ea2 <myproc>
    80002e30:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002e32:	0000f517          	auipc	a0,0xf
    80002e36:	79650513          	addi	a0,a0,1942 # 800125c8 <wait_lock>
    80002e3a:	ffffe097          	auipc	ra,0xffffe
    80002e3e:	db2080e7          	jalr	-590(ra) # 80000bec <acquire>
    havekids = 0;
    80002e42:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002e44:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002e46:	00016997          	auipc	s3,0x16
    80002e4a:	b9a98993          	addi	s3,s3,-1126 # 800189e0 <tickslock>
        havekids = 1;
    80002e4e:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002e50:	0000fc17          	auipc	s8,0xf
    80002e54:	778c0c13          	addi	s8,s8,1912 # 800125c8 <wait_lock>
    havekids = 0;
    80002e58:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002e5a:	0000f497          	auipc	s1,0xf
    80002e5e:	78648493          	addi	s1,s1,1926 # 800125e0 <proc>
    80002e62:	a0bd                	j	80002ed0 <wait+0xc2>
          pid = np->pid;
    80002e64:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002e68:	000b0e63          	beqz	s6,80002e84 <wait+0x76>
    80002e6c:	4691                	li	a3,4
    80002e6e:	04448613          	addi	a2,s1,68
    80002e72:	85da                	mv	a1,s6
    80002e74:	07893503          	ld	a0,120(s2)
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	808080e7          	jalr	-2040(ra) # 80001680 <copyout>
    80002e80:	02054563          	bltz	a0,80002eaa <wait+0x9c>
          freeproc(np);
    80002e84:	8526                	mv	a0,s1
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	b84080e7          	jalr	-1148(ra) # 80002a0a <freeproc>
          release(&np->lock);
    80002e8e:	8526                	mv	a0,s1
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	e16080e7          	jalr	-490(ra) # 80000ca6 <release>
          release(&wait_lock);
    80002e98:	0000f517          	auipc	a0,0xf
    80002e9c:	73050513          	addi	a0,a0,1840 # 800125c8 <wait_lock>
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	e06080e7          	jalr	-506(ra) # 80000ca6 <release>
          return pid;
    80002ea8:	a09d                	j	80002f0e <wait+0x100>
            release(&np->lock);
    80002eaa:	8526                	mv	a0,s1
    80002eac:	ffffe097          	auipc	ra,0xffffe
    80002eb0:	dfa080e7          	jalr	-518(ra) # 80000ca6 <release>
            release(&wait_lock);
    80002eb4:	0000f517          	auipc	a0,0xf
    80002eb8:	71450513          	addi	a0,a0,1812 # 800125c8 <wait_lock>
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	dea080e7          	jalr	-534(ra) # 80000ca6 <release>
            return -1;
    80002ec4:	59fd                	li	s3,-1
    80002ec6:	a0a1                	j	80002f0e <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002ec8:	19048493          	addi	s1,s1,400
    80002ecc:	03348463          	beq	s1,s3,80002ef4 <wait+0xe6>
      if(np->parent == p){
    80002ed0:	70bc                	ld	a5,96(s1)
    80002ed2:	ff279be3          	bne	a5,s2,80002ec8 <wait+0xba>
        acquire(&np->lock);
    80002ed6:	8526                	mv	a0,s1
    80002ed8:	ffffe097          	auipc	ra,0xffffe
    80002edc:	d14080e7          	jalr	-748(ra) # 80000bec <acquire>
        if(np->state == ZOMBIE){
    80002ee0:	589c                	lw	a5,48(s1)
    80002ee2:	f94781e3          	beq	a5,s4,80002e64 <wait+0x56>
        release(&np->lock);
    80002ee6:	8526                	mv	a0,s1
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	dbe080e7          	jalr	-578(ra) # 80000ca6 <release>
        havekids = 1;
    80002ef0:	8756                	mv	a4,s5
    80002ef2:	bfd9                	j	80002ec8 <wait+0xba>
    if(!havekids || p->killed){
    80002ef4:	c701                	beqz	a4,80002efc <wait+0xee>
    80002ef6:	04092783          	lw	a5,64(s2)
    80002efa:	c79d                	beqz	a5,80002f28 <wait+0x11a>
      release(&wait_lock);
    80002efc:	0000f517          	auipc	a0,0xf
    80002f00:	6cc50513          	addi	a0,a0,1740 # 800125c8 <wait_lock>
    80002f04:	ffffe097          	auipc	ra,0xffffe
    80002f08:	da2080e7          	jalr	-606(ra) # 80000ca6 <release>
      return -1;
    80002f0c:	59fd                	li	s3,-1
}
    80002f0e:	854e                	mv	a0,s3
    80002f10:	60a6                	ld	ra,72(sp)
    80002f12:	6406                	ld	s0,64(sp)
    80002f14:	74e2                	ld	s1,56(sp)
    80002f16:	7942                	ld	s2,48(sp)
    80002f18:	79a2                	ld	s3,40(sp)
    80002f1a:	7a02                	ld	s4,32(sp)
    80002f1c:	6ae2                	ld	s5,24(sp)
    80002f1e:	6b42                	ld	s6,16(sp)
    80002f20:	6ba2                	ld	s7,8(sp)
    80002f22:	6c02                	ld	s8,0(sp)
    80002f24:	6161                	addi	sp,sp,80
    80002f26:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002f28:	85e2                	mv	a1,s8
    80002f2a:	854a                	mv	a0,s2
    80002f2c:	00000097          	auipc	ra,0x0
    80002f30:	e62080e7          	jalr	-414(ra) # 80002d8e <sleep>
    havekids = 0;
    80002f34:	b715                	j	80002e58 <wait+0x4a>

0000000080002f36 <wakeup>:
// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
//--------------------------------------------------------------------
void
wakeup(void *chan)
{
    80002f36:	711d                	addi	sp,sp,-96
    80002f38:	ec86                	sd	ra,88(sp)
    80002f3a:	e8a2                	sd	s0,80(sp)
    80002f3c:	e4a6                	sd	s1,72(sp)
    80002f3e:	e0ca                	sd	s2,64(sp)
    80002f40:	fc4e                	sd	s3,56(sp)
    80002f42:	f852                	sd	s4,48(sp)
    80002f44:	f456                	sd	s5,40(sp)
    80002f46:	f05a                	sd	s6,32(sp)
    80002f48:	ec5e                	sd	s7,24(sp)
    80002f4a:	e862                	sd	s8,16(sp)
    80002f4c:	e466                	sd	s9,8(sp)
    80002f4e:	e06a                	sd	s10,0(sp)
    80002f50:	1080                	addi	s0,sp,96
    80002f52:	8aaa                	mv	s5,a0
  int released_list = 0;
  struct proc *p;
  struct proc* prev = 0;
  struct proc* tmp;
  getList(sleepLeast, -1);
    80002f54:	55fd                	li	a1,-1
    80002f56:	4509                	li	a0,2
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	31a080e7          	jalr	794(ra) # 80002272 <getList>
  p = getFirst(sleepLeast, -1);
    80002f60:	55fd                	li	a1,-1
    80002f62:	4509                	li	a0,2
    80002f64:	fffff097          	auipc	ra,0xfffff
    80002f68:	bc4080e7          	jalr	-1084(ra) # 80001b28 <getFirst>
    80002f6c:	84aa                	mv	s1,a0
  while(p){
    80002f6e:	14050863          	beqz	a0,800030be <wakeup+0x188>
  struct proc* prev = 0;
    80002f72:	4a01                	li	s4,0
  int released_list = 0;
    80002f74:	4c01                	li	s8,0
    } 
    else{
      //we are not on the chan
      if(p == getFirst(sleepLeast, -1)){
        release_list(sleepLeast,-1);
        released_list = 1;
    80002f76:	4b85                	li	s7,1
        p->state = RUNNABLE;
    80002f78:	4c8d                	li	s9,3
    80002f7a:	a8d9                	j	80003050 <wakeup+0x11a>
      if(p == getFirst(sleepLeast, -1)){
    80002f7c:	55fd                	li	a1,-1
    80002f7e:	4509                	li	a0,2
    80002f80:	fffff097          	auipc	ra,0xfffff
    80002f84:	ba8080e7          	jalr	-1112(ra) # 80001b28 <getFirst>
    80002f88:	04a48963          	beq	s1,a0,80002fda <wakeup+0xa4>
        prev->next = p->next;
    80002f8c:	68bc                	ld	a5,80(s1)
    80002f8e:	04fa3823          	sd	a5,80(s4)
        p->next = 0;
    80002f92:	0404b823          	sd	zero,80(s1)
        p->state = RUNNABLE;
    80002f96:	0394a823          	sw	s9,48(s1)
        int cpu_id = (BLNCFLG) ? pick_cpu() : p->parent_cpu;
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	b30080e7          	jalr	-1232(ra) # 80001aca <pick_cpu>
    80002fa2:	8b2a                	mv	s6,a0
        p->parent_cpu = cpu_id;
    80002fa4:	cca8                	sw	a0,88(s1)
        BLNCFLG ?cahnge_number_of_proc(cpu_id,a):counter_blance++;
    80002fa6:	85de                	mv	a1,s7
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	b30080e7          	jalr	-1232(ra) # 80001ad8 <cahnge_number_of_proc>
        add_proc_to_specific_list(p, readyList, cpu_id,0);
    80002fb0:	4681                	li	a3,0
    80002fb2:	865a                	mv	a2,s6
    80002fb4:	4581                	li	a1,0
    80002fb6:	8526                	mv	a0,s1
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	4a2080e7          	jalr	1186(ra) # 8000245a <add_proc_to_specific_list>
        release(&p->list_lock);
    80002fc0:	854a                	mv	a0,s2
    80002fc2:	ffffe097          	auipc	ra,0xffffe
    80002fc6:	ce4080e7          	jalr	-796(ra) # 80000ca6 <release>
        release(&p->lock);
    80002fca:	8526                	mv	a0,s1
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	cda080e7          	jalr	-806(ra) # 80000ca6 <release>
        p = prev->next;
    80002fd4:	050a3483          	ld	s1,80(s4)
    80002fd8:	a89d                	j	8000304e <wakeup+0x118>
        setFirst(p->next, sleepLeast, -1);
    80002fda:	567d                	li	a2,-1
    80002fdc:	4589                	li	a1,2
    80002fde:	68a8                	ld	a0,80(s1)
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	392080e7          	jalr	914(ra) # 80002372 <setFirst>
        p = p->next;
    80002fe8:	0504bd03          	ld	s10,80(s1)
        tmp->next = 0;
    80002fec:	0404b823          	sd	zero,80(s1)
        tmp->state = RUNNABLE;
    80002ff0:	0394a823          	sw	s9,48(s1)
        int cpu_id = (BLNCFLG) ? pick_cpu() : tmp->parent_cpu;
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	ad6080e7          	jalr	-1322(ra) # 80001aca <pick_cpu>
    80002ffc:	8b2a                	mv	s6,a0
        tmp->parent_cpu = cpu_id;
    80002ffe:	cca8                	sw	a0,88(s1)
        BLNCFLG ?cahnge_number_of_proc(cpu_id,a):counter_blance++;
    80003000:	85de                	mv	a1,s7
    80003002:	fffff097          	auipc	ra,0xfffff
    80003006:	ad6080e7          	jalr	-1322(ra) # 80001ad8 <cahnge_number_of_proc>
        add_proc_to_specific_list(tmp, readyList, cpu_id,0);
    8000300a:	4681                	li	a3,0
    8000300c:	865a                	mv	a2,s6
    8000300e:	4581                	li	a1,0
    80003010:	8526                	mv	a0,s1
    80003012:	fffff097          	auipc	ra,0xfffff
    80003016:	448080e7          	jalr	1096(ra) # 8000245a <add_proc_to_specific_list>
        release(&tmp->list_lock);
    8000301a:	854a                	mv	a0,s2
    8000301c:	ffffe097          	auipc	ra,0xffffe
    80003020:	c8a080e7          	jalr	-886(ra) # 80000ca6 <release>
        release(&tmp->lock);
    80003024:	8526                	mv	a0,s1
    80003026:	ffffe097          	auipc	ra,0xffffe
    8000302a:	c80080e7          	jalr	-896(ra) # 80000ca6 <release>
        p = p->next;
    8000302e:	84ea                	mv	s1,s10
    80003030:	a839                	j	8000304e <wakeup+0x118>
        release_list(sleepLeast,-1);
    80003032:	55fd                	li	a1,-1
    80003034:	4509                	li	a0,2
    80003036:	fffff097          	auipc	ra,0xfffff
    8000303a:	c20080e7          	jalr	-992(ra) # 80001c56 <release_list>
        released_list = 1;
    8000303e:	8c5e                	mv	s8,s7
      }
      else{
        release(&prev->list_lock);
      }
      release(&p->lock);  //because we dont need to change his fields
    80003040:	854e                	mv	a0,s3
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	c64080e7          	jalr	-924(ra) # 80000ca6 <release>
      prev = p;
      p = p->next;
    8000304a:	8a26                	mv	s4,s1
    8000304c:	68a4                	ld	s1,80(s1)
  while(p){
    8000304e:	c0a1                	beqz	s1,8000308e <wakeup+0x158>
    acquire(&p->lock);
    80003050:	89a6                	mv	s3,s1
    80003052:	8526                	mv	a0,s1
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	b98080e7          	jalr	-1128(ra) # 80000bec <acquire>
    acquire(&p->list_lock);
    8000305c:	01848913          	addi	s2,s1,24
    80003060:	854a                	mv	a0,s2
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	b8a080e7          	jalr	-1142(ra) # 80000bec <acquire>
    if(p->chan == chan){
    8000306a:	7c9c                	ld	a5,56(s1)
    8000306c:	f15788e3          	beq	a5,s5,80002f7c <wakeup+0x46>
      if(p == getFirst(sleepLeast, -1)){
    80003070:	55fd                	li	a1,-1
    80003072:	4509                	li	a0,2
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	ab4080e7          	jalr	-1356(ra) # 80001b28 <getFirst>
    8000307c:	faa48be3          	beq	s1,a0,80003032 <wakeup+0xfc>
        release(&prev->list_lock);
    80003080:	018a0513          	addi	a0,s4,24
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	c22080e7          	jalr	-990(ra) # 80000ca6 <release>
    8000308c:	bf55                	j	80003040 <wakeup+0x10a>
    }
  }
  if(!released_list){
    8000308e:	020c0963          	beqz	s8,800030c0 <wakeup+0x18a>
    release_list(sleepLeast, -1);
  }
  if(prev){
    80003092:	000a0863          	beqz	s4,800030a2 <wakeup+0x16c>
    release(&prev->list_lock);
    80003096:	018a0513          	addi	a0,s4,24
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	c0c080e7          	jalr	-1012(ra) # 80000ca6 <release>
  }
}
    800030a2:	60e6                	ld	ra,88(sp)
    800030a4:	6446                	ld	s0,80(sp)
    800030a6:	64a6                	ld	s1,72(sp)
    800030a8:	6906                	ld	s2,64(sp)
    800030aa:	79e2                	ld	s3,56(sp)
    800030ac:	7a42                	ld	s4,48(sp)
    800030ae:	7aa2                	ld	s5,40(sp)
    800030b0:	7b02                	ld	s6,32(sp)
    800030b2:	6be2                	ld	s7,24(sp)
    800030b4:	6c42                	ld	s8,16(sp)
    800030b6:	6ca2                	ld	s9,8(sp)
    800030b8:	6d02                	ld	s10,0(sp)
    800030ba:	6125                	addi	sp,sp,96
    800030bc:	8082                	ret
  struct proc* prev = 0;
    800030be:	8a2a                	mv	s4,a0
    release_list(sleepLeast, -1);
    800030c0:	55fd                	li	a1,-1
    800030c2:	4509                	li	a0,2
    800030c4:	fffff097          	auipc	ra,0xfffff
    800030c8:	b92080e7          	jalr	-1134(ra) # 80001c56 <release_list>
    800030cc:	b7d9                	j	80003092 <wakeup+0x15c>

00000000800030ce <reparent>:
{
    800030ce:	7179                	addi	sp,sp,-48
    800030d0:	f406                	sd	ra,40(sp)
    800030d2:	f022                	sd	s0,32(sp)
    800030d4:	ec26                	sd	s1,24(sp)
    800030d6:	e84a                	sd	s2,16(sp)
    800030d8:	e44e                	sd	s3,8(sp)
    800030da:	e052                	sd	s4,0(sp)
    800030dc:	1800                	addi	s0,sp,48
    800030de:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800030e0:	0000f497          	auipc	s1,0xf
    800030e4:	50048493          	addi	s1,s1,1280 # 800125e0 <proc>
      pp->parent = initproc;
    800030e8:	00007a17          	auipc	s4,0x7
    800030ec:	f78a0a13          	addi	s4,s4,-136 # 8000a060 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800030f0:	00016997          	auipc	s3,0x16
    800030f4:	8f098993          	addi	s3,s3,-1808 # 800189e0 <tickslock>
    800030f8:	a029                	j	80003102 <reparent+0x34>
    800030fa:	19048493          	addi	s1,s1,400
    800030fe:	01348d63          	beq	s1,s3,80003118 <reparent+0x4a>
    if(pp->parent == p){
    80003102:	70bc                	ld	a5,96(s1)
    80003104:	ff279be3          	bne	a5,s2,800030fa <reparent+0x2c>
      pp->parent = initproc;
    80003108:	000a3503          	ld	a0,0(s4)
    8000310c:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    8000310e:	00000097          	auipc	ra,0x0
    80003112:	e28080e7          	jalr	-472(ra) # 80002f36 <wakeup>
    80003116:	b7d5                	j	800030fa <reparent+0x2c>
}
    80003118:	70a2                	ld	ra,40(sp)
    8000311a:	7402                	ld	s0,32(sp)
    8000311c:	64e2                	ld	s1,24(sp)
    8000311e:	6942                	ld	s2,16(sp)
    80003120:	69a2                	ld	s3,8(sp)
    80003122:	6a02                	ld	s4,0(sp)
    80003124:	6145                	addi	sp,sp,48
    80003126:	8082                	ret

0000000080003128 <exit>:
{
    80003128:	7179                	addi	sp,sp,-48
    8000312a:	f406                	sd	ra,40(sp)
    8000312c:	f022                	sd	s0,32(sp)
    8000312e:	ec26                	sd	s1,24(sp)
    80003130:	e84a                	sd	s2,16(sp)
    80003132:	e44e                	sd	s3,8(sp)
    80003134:	e052                	sd	s4,0(sp)
    80003136:	1800                	addi	s0,sp,48
    80003138:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	d68080e7          	jalr	-664(ra) # 80001ea2 <myproc>
    80003142:	89aa                	mv	s3,a0
  if(p == initproc)
    80003144:	00007797          	auipc	a5,0x7
    80003148:	f1c7b783          	ld	a5,-228(a5) # 8000a060 <initproc>
    8000314c:	0f850493          	addi	s1,a0,248
    80003150:	17850913          	addi	s2,a0,376
    80003154:	02a79363          	bne	a5,a0,8000317a <exit+0x52>
    panic("init exiting");
    80003158:	00006517          	auipc	a0,0x6
    8000315c:	2e850513          	addi	a0,a0,744 # 80009440 <digits+0x400>
    80003160:	ffffd097          	auipc	ra,0xffffd
    80003164:	3de080e7          	jalr	990(ra) # 8000053e <panic>
      fileclose(f);
    80003168:	00002097          	auipc	ra,0x2
    8000316c:	20e080e7          	jalr	526(ra) # 80005376 <fileclose>
      p->ofile[fd] = 0;
    80003170:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80003174:	04a1                	addi	s1,s1,8
    80003176:	01248563          	beq	s1,s2,80003180 <exit+0x58>
    if(p->ofile[fd]){
    8000317a:	6088                	ld	a0,0(s1)
    8000317c:	f575                	bnez	a0,80003168 <exit+0x40>
    8000317e:	bfdd                	j	80003174 <exit+0x4c>
  begin_op();
    80003180:	00002097          	auipc	ra,0x2
    80003184:	d2a080e7          	jalr	-726(ra) # 80004eaa <begin_op>
  iput(p->cwd);
    80003188:	1789b503          	ld	a0,376(s3)
    8000318c:	00001097          	auipc	ra,0x1
    80003190:	506080e7          	jalr	1286(ra) # 80004692 <iput>
  end_op();
    80003194:	00002097          	auipc	ra,0x2
    80003198:	d96080e7          	jalr	-618(ra) # 80004f2a <end_op>
  p->cwd = 0;
    8000319c:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    800031a0:	0000f497          	auipc	s1,0xf
    800031a4:	42848493          	addi	s1,s1,1064 # 800125c8 <wait_lock>
    800031a8:	8526                	mv	a0,s1
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	a42080e7          	jalr	-1470(ra) # 80000bec <acquire>
  reparent(p);
    800031b2:	854e                	mv	a0,s3
    800031b4:	00000097          	auipc	ra,0x0
    800031b8:	f1a080e7          	jalr	-230(ra) # 800030ce <reparent>
  wakeup(p->parent);
    800031bc:	0609b503          	ld	a0,96(s3)
    800031c0:	00000097          	auipc	ra,0x0
    800031c4:	d76080e7          	jalr	-650(ra) # 80002f36 <wakeup>
  acquire(&p->lock);
    800031c8:	854e                	mv	a0,s3
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	a22080e7          	jalr	-1502(ra) # 80000bec <acquire>
  p->xstate = status;
    800031d2:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    800031d6:	4795                	li	a5,5
    800031d8:	02f9a823          	sw	a5,48(s3)
  BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,b):counter_blance++;
    800031dc:	55fd                	li	a1,-1
    800031de:	0589a503          	lw	a0,88(s3)
    800031e2:	fffff097          	auipc	ra,0xfffff
    800031e6:	8f6080e7          	jalr	-1802(ra) # 80001ad8 <cahnge_number_of_proc>
  add_proc_to_specific_list(p, zombeList, -1,0);
    800031ea:	4681                	li	a3,0
    800031ec:	567d                	li	a2,-1
    800031ee:	4585                	li	a1,1
    800031f0:	854e                	mv	a0,s3
    800031f2:	fffff097          	auipc	ra,0xfffff
    800031f6:	268080e7          	jalr	616(ra) # 8000245a <add_proc_to_specific_list>
  release(&wait_lock);
    800031fa:	8526                	mv	a0,s1
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	aaa080e7          	jalr	-1366(ra) # 80000ca6 <release>
  sched();
    80003204:	fffff097          	auipc	ra,0xfffff
    80003208:	ed8080e7          	jalr	-296(ra) # 800020dc <sched>
  panic("zombie exit");
    8000320c:	00006517          	auipc	a0,0x6
    80003210:	24450513          	addi	a0,a0,580 # 80009450 <digits+0x410>
    80003214:	ffffd097          	auipc	ra,0xffffd
    80003218:	32a080e7          	jalr	810(ra) # 8000053e <panic>

000000008000321c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000321c:	7179                	addi	sp,sp,-48
    8000321e:	f406                	sd	ra,40(sp)
    80003220:	f022                	sd	s0,32(sp)
    80003222:	ec26                	sd	s1,24(sp)
    80003224:	e84a                	sd	s2,16(sp)
    80003226:	e44e                	sd	s3,8(sp)
    80003228:	1800                	addi	s0,sp,48
    8000322a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000322c:	0000f497          	auipc	s1,0xf
    80003230:	3b448493          	addi	s1,s1,948 # 800125e0 <proc>
    80003234:	00015997          	auipc	s3,0x15
    80003238:	7ac98993          	addi	s3,s3,1964 # 800189e0 <tickslock>
    acquire(&p->lock);
    8000323c:	8526                	mv	a0,s1
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	9ae080e7          	jalr	-1618(ra) # 80000bec <acquire>
    if(p->pid == pid){
    80003246:	44bc                	lw	a5,72(s1)
    80003248:	01278d63          	beq	a5,s2,80003262 <kill+0x46>
        BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,a):counter_blance++;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000324c:	8526                	mv	a0,s1
    8000324e:	ffffe097          	auipc	ra,0xffffe
    80003252:	a58080e7          	jalr	-1448(ra) # 80000ca6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80003256:	19048493          	addi	s1,s1,400
    8000325a:	ff3491e3          	bne	s1,s3,8000323c <kill+0x20>
  }
  return -1;
    8000325e:	557d                	li	a0,-1
    80003260:	a829                	j	8000327a <kill+0x5e>
      p->killed = 1;
    80003262:	4785                	li	a5,1
    80003264:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    80003266:	5898                	lw	a4,48(s1)
    80003268:	4789                	li	a5,2
    8000326a:	00f70f63          	beq	a4,a5,80003288 <kill+0x6c>
      release(&p->lock);
    8000326e:	8526                	mv	a0,s1
    80003270:	ffffe097          	auipc	ra,0xffffe
    80003274:	a36080e7          	jalr	-1482(ra) # 80000ca6 <release>
      return 0;
    80003278:	4501                	li	a0,0
}
    8000327a:	70a2                	ld	ra,40(sp)
    8000327c:	7402                	ld	s0,32(sp)
    8000327e:	64e2                	ld	s1,24(sp)
    80003280:	6942                	ld	s2,16(sp)
    80003282:	69a2                	ld	s3,8(sp)
    80003284:	6145                	addi	sp,sp,48
    80003286:	8082                	ret
        p->state = RUNNABLE;
    80003288:	478d                	li	a5,3
    8000328a:	d89c                	sw	a5,48(s1)
        getList(sleepLeast, p->parent_cpu); // get list is grabing the loock of relevnt list
    8000328c:	4cac                	lw	a1,88(s1)
    8000328e:	4509                	li	a0,2
    80003290:	fffff097          	auipc	ra,0xfffff
    80003294:	fe2080e7          	jalr	-30(ra) # 80002272 <getList>
        struct proc* first = getFirst(sleepLeast, p->parent_cpu);//aquire first proc in the list after we have loock 
    80003298:	4cac                	lw	a1,88(s1)
    8000329a:	4509                	li	a0,2
    8000329c:	fffff097          	auipc	ra,0xfffff
    800032a0:	88c080e7          	jalr	-1908(ra) # 80001b28 <getFirst>
        delete_proc_from_list(first,p, sleepLeast,0);
    800032a4:	4681                	li	a3,0
    800032a6:	4609                	li	a2,2
    800032a8:	85a6                	mv	a1,s1
    800032aa:	fffff097          	auipc	ra,0xfffff
    800032ae:	682080e7          	jalr	1666(ra) # 8000292c <delete_proc_from_list>
        add_proc_to_specific_list(p, readyList, p->parent_cpu,0);
    800032b2:	4681                	li	a3,0
    800032b4:	4cb0                	lw	a2,88(s1)
    800032b6:	4581                	li	a1,0
    800032b8:	8526                	mv	a0,s1
    800032ba:	fffff097          	auipc	ra,0xfffff
    800032be:	1a0080e7          	jalr	416(ra) # 8000245a <add_proc_to_specific_list>
        BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,a):counter_blance++;
    800032c2:	4585                	li	a1,1
    800032c4:	4ca8                	lw	a0,88(s1)
    800032c6:	fffff097          	auipc	ra,0xfffff
    800032ca:	812080e7          	jalr	-2030(ra) # 80001ad8 <cahnge_number_of_proc>
    800032ce:	b745                	j	8000326e <kill+0x52>

00000000800032d0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800032d0:	7179                	addi	sp,sp,-48
    800032d2:	f406                	sd	ra,40(sp)
    800032d4:	f022                	sd	s0,32(sp)
    800032d6:	ec26                	sd	s1,24(sp)
    800032d8:	e84a                	sd	s2,16(sp)
    800032da:	e44e                	sd	s3,8(sp)
    800032dc:	e052                	sd	s4,0(sp)
    800032de:	1800                	addi	s0,sp,48
    800032e0:	84aa                	mv	s1,a0
    800032e2:	892e                	mv	s2,a1
    800032e4:	89b2                	mv	s3,a2
    800032e6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800032e8:	fffff097          	auipc	ra,0xfffff
    800032ec:	bba080e7          	jalr	-1094(ra) # 80001ea2 <myproc>
  if(user_dst){
    800032f0:	c08d                	beqz	s1,80003312 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800032f2:	86d2                	mv	a3,s4
    800032f4:	864e                	mv	a2,s3
    800032f6:	85ca                	mv	a1,s2
    800032f8:	7d28                	ld	a0,120(a0)
    800032fa:	ffffe097          	auipc	ra,0xffffe
    800032fe:	386080e7          	jalr	902(ra) # 80001680 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80003302:	70a2                	ld	ra,40(sp)
    80003304:	7402                	ld	s0,32(sp)
    80003306:	64e2                	ld	s1,24(sp)
    80003308:	6942                	ld	s2,16(sp)
    8000330a:	69a2                	ld	s3,8(sp)
    8000330c:	6a02                	ld	s4,0(sp)
    8000330e:	6145                	addi	sp,sp,48
    80003310:	8082                	ret
    memmove((char *)dst, src, len);
    80003312:	000a061b          	sext.w	a2,s4
    80003316:	85ce                	mv	a1,s3
    80003318:	854a                	mv	a0,s2
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	a34080e7          	jalr	-1484(ra) # 80000d4e <memmove>
    return 0;
    80003322:	8526                	mv	a0,s1
    80003324:	bff9                	j	80003302 <either_copyout+0x32>

0000000080003326 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80003326:	7179                	addi	sp,sp,-48
    80003328:	f406                	sd	ra,40(sp)
    8000332a:	f022                	sd	s0,32(sp)
    8000332c:	ec26                	sd	s1,24(sp)
    8000332e:	e84a                	sd	s2,16(sp)
    80003330:	e44e                	sd	s3,8(sp)
    80003332:	e052                	sd	s4,0(sp)
    80003334:	1800                	addi	s0,sp,48
    80003336:	892a                	mv	s2,a0
    80003338:	84ae                	mv	s1,a1
    8000333a:	89b2                	mv	s3,a2
    8000333c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000333e:	fffff097          	auipc	ra,0xfffff
    80003342:	b64080e7          	jalr	-1180(ra) # 80001ea2 <myproc>
  if(user_src){
    80003346:	c08d                	beqz	s1,80003368 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80003348:	86d2                	mv	a3,s4
    8000334a:	864e                	mv	a2,s3
    8000334c:	85ca                	mv	a1,s2
    8000334e:	7d28                	ld	a0,120(a0)
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	3bc080e7          	jalr	956(ra) # 8000170c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80003358:	70a2                	ld	ra,40(sp)
    8000335a:	7402                	ld	s0,32(sp)
    8000335c:	64e2                	ld	s1,24(sp)
    8000335e:	6942                	ld	s2,16(sp)
    80003360:	69a2                	ld	s3,8(sp)
    80003362:	6a02                	ld	s4,0(sp)
    80003364:	6145                	addi	sp,sp,48
    80003366:	8082                	ret
    memmove(dst, (char*)src, len);
    80003368:	000a061b          	sext.w	a2,s4
    8000336c:	85ce                	mv	a1,s3
    8000336e:	854a                	mv	a0,s2
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	9de080e7          	jalr	-1570(ra) # 80000d4e <memmove>
    return 0;
    80003378:	8526                	mv	a0,s1
    8000337a:	bff9                	j	80003358 <either_copyin+0x32>

000000008000337c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000337c:	715d                	addi	sp,sp,-80
    8000337e:	e486                	sd	ra,72(sp)
    80003380:	e0a2                	sd	s0,64(sp)
    80003382:	fc26                	sd	s1,56(sp)
    80003384:	f84a                	sd	s2,48(sp)
    80003386:	f44e                	sd	s3,40(sp)
    80003388:	f052                	sd	s4,32(sp)
    8000338a:	ec56                	sd	s5,24(sp)
    8000338c:	e85a                	sd	s6,16(sp)
    8000338e:	e45e                	sd	s7,8(sp)
    80003390:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80003392:	00006517          	auipc	a0,0x6
    80003396:	fb650513          	addi	a0,a0,-74 # 80009348 <digits+0x308>
    8000339a:	ffffd097          	auipc	ra,0xffffd
    8000339e:	1ee080e7          	jalr	494(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800033a2:	0000f497          	auipc	s1,0xf
    800033a6:	3be48493          	addi	s1,s1,958 # 80012760 <proc+0x180>
    800033aa:	00015917          	auipc	s2,0x15
    800033ae:	7b690913          	addi	s2,s2,1974 # 80018b60 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800033b2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800033b4:	00006997          	auipc	s3,0x6
    800033b8:	0ac98993          	addi	s3,s3,172 # 80009460 <digits+0x420>
    printf("%d %s %s", p->pid, state, p->name);
    800033bc:	00006a97          	auipc	s5,0x6
    800033c0:	0aca8a93          	addi	s5,s5,172 # 80009468 <digits+0x428>
    printf("\n");
    800033c4:	00006a17          	auipc	s4,0x6
    800033c8:	f84a0a13          	addi	s4,s4,-124 # 80009348 <digits+0x308>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800033cc:	00006b97          	auipc	s7,0x6
    800033d0:	0d4b8b93          	addi	s7,s7,212 # 800094a0 <states.1905>
    800033d4:	a00d                	j	800033f6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800033d6:	ec86a583          	lw	a1,-312(a3)
    800033da:	8556                	mv	a0,s5
    800033dc:	ffffd097          	auipc	ra,0xffffd
    800033e0:	1ac080e7          	jalr	428(ra) # 80000588 <printf>
    printf("\n");
    800033e4:	8552                	mv	a0,s4
    800033e6:	ffffd097          	auipc	ra,0xffffd
    800033ea:	1a2080e7          	jalr	418(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800033ee:	19048493          	addi	s1,s1,400
    800033f2:	03248163          	beq	s1,s2,80003414 <procdump+0x98>
    if(p->state == UNUSED)
    800033f6:	86a6                	mv	a3,s1
    800033f8:	eb04a783          	lw	a5,-336(s1)
    800033fc:	dbed                	beqz	a5,800033ee <procdump+0x72>
      state = "???";
    800033fe:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003400:	fcfb6be3          	bltu	s6,a5,800033d6 <procdump+0x5a>
    80003404:	1782                	slli	a5,a5,0x20
    80003406:	9381                	srli	a5,a5,0x20
    80003408:	078e                	slli	a5,a5,0x3
    8000340a:	97de                	add	a5,a5,s7
    8000340c:	6390                	ld	a2,0(a5)
    8000340e:	f661                	bnez	a2,800033d6 <procdump+0x5a>
      state = "???";
    80003410:	864e                	mv	a2,s3
    80003412:	b7d1                	j	800033d6 <procdump+0x5a>
  }
}
    80003414:	60a6                	ld	ra,72(sp)
    80003416:	6406                	ld	s0,64(sp)
    80003418:	74e2                	ld	s1,56(sp)
    8000341a:	7942                	ld	s2,48(sp)
    8000341c:	79a2                	ld	s3,40(sp)
    8000341e:	7a02                	ld	s4,32(sp)
    80003420:	6ae2                	ld	s5,24(sp)
    80003422:	6b42                	ld	s6,16(sp)
    80003424:	6ba2                	ld	s7,8(sp)
    80003426:	6161                	addi	sp,sp,80
    80003428:	8082                	ret

000000008000342a <swtch>:
    8000342a:	00153023          	sd	ra,0(a0)
    8000342e:	00253423          	sd	sp,8(a0)
    80003432:	e900                	sd	s0,16(a0)
    80003434:	ed04                	sd	s1,24(a0)
    80003436:	03253023          	sd	s2,32(a0)
    8000343a:	03353423          	sd	s3,40(a0)
    8000343e:	03453823          	sd	s4,48(a0)
    80003442:	03553c23          	sd	s5,56(a0)
    80003446:	05653023          	sd	s6,64(a0)
    8000344a:	05753423          	sd	s7,72(a0)
    8000344e:	05853823          	sd	s8,80(a0)
    80003452:	05953c23          	sd	s9,88(a0)
    80003456:	07a53023          	sd	s10,96(a0)
    8000345a:	07b53423          	sd	s11,104(a0)
    8000345e:	0005b083          	ld	ra,0(a1)
    80003462:	0085b103          	ld	sp,8(a1)
    80003466:	6980                	ld	s0,16(a1)
    80003468:	6d84                	ld	s1,24(a1)
    8000346a:	0205b903          	ld	s2,32(a1)
    8000346e:	0285b983          	ld	s3,40(a1)
    80003472:	0305ba03          	ld	s4,48(a1)
    80003476:	0385ba83          	ld	s5,56(a1)
    8000347a:	0405bb03          	ld	s6,64(a1)
    8000347e:	0485bb83          	ld	s7,72(a1)
    80003482:	0505bc03          	ld	s8,80(a1)
    80003486:	0585bc83          	ld	s9,88(a1)
    8000348a:	0605bd03          	ld	s10,96(a1)
    8000348e:	0685bd83          	ld	s11,104(a1)
    80003492:	8082                	ret

0000000080003494 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003494:	1141                	addi	sp,sp,-16
    80003496:	e406                	sd	ra,8(sp)
    80003498:	e022                	sd	s0,0(sp)
    8000349a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000349c:	00006597          	auipc	a1,0x6
    800034a0:	03458593          	addi	a1,a1,52 # 800094d0 <states.1905+0x30>
    800034a4:	00015517          	auipc	a0,0x15
    800034a8:	53c50513          	addi	a0,a0,1340 # 800189e0 <tickslock>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	6a8080e7          	jalr	1704(ra) # 80000b54 <initlock>
}
    800034b4:	60a2                	ld	ra,8(sp)
    800034b6:	6402                	ld	s0,0(sp)
    800034b8:	0141                	addi	sp,sp,16
    800034ba:	8082                	ret

00000000800034bc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800034bc:	1141                	addi	sp,sp,-16
    800034be:	e422                	sd	s0,8(sp)
    800034c0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800034c2:	00003797          	auipc	a5,0x3
    800034c6:	4ce78793          	addi	a5,a5,1230 # 80006990 <kernelvec>
    800034ca:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800034ce:	6422                	ld	s0,8(sp)
    800034d0:	0141                	addi	sp,sp,16
    800034d2:	8082                	ret

00000000800034d4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800034d4:	1141                	addi	sp,sp,-16
    800034d6:	e406                	sd	ra,8(sp)
    800034d8:	e022                	sd	s0,0(sp)
    800034da:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800034dc:	fffff097          	auipc	ra,0xfffff
    800034e0:	9c6080e7          	jalr	-1594(ra) # 80001ea2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800034e8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034ea:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800034ee:	00005617          	auipc	a2,0x5
    800034f2:	b1260613          	addi	a2,a2,-1262 # 80008000 <_trampoline>
    800034f6:	00005697          	auipc	a3,0x5
    800034fa:	b0a68693          	addi	a3,a3,-1270 # 80008000 <_trampoline>
    800034fe:	8e91                	sub	a3,a3,a2
    80003500:	040007b7          	lui	a5,0x4000
    80003504:	17fd                	addi	a5,a5,-1
    80003506:	07b2                	slli	a5,a5,0xc
    80003508:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000350a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000350e:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003510:	180026f3          	csrr	a3,satp
    80003514:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003516:	6158                	ld	a4,128(a0)
    80003518:	7534                	ld	a3,104(a0)
    8000351a:	6585                	lui	a1,0x1
    8000351c:	96ae                	add	a3,a3,a1
    8000351e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003520:	6158                	ld	a4,128(a0)
    80003522:	00000697          	auipc	a3,0x0
    80003526:	13868693          	addi	a3,a3,312 # 8000365a <usertrap>
    8000352a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000352c:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000352e:	8692                	mv	a3,tp
    80003530:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003532:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003536:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000353a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000353e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003542:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003544:	6f18                	ld	a4,24(a4)
    80003546:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000354a:	7d2c                	ld	a1,120(a0)
    8000354c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000354e:	00005717          	auipc	a4,0x5
    80003552:	b4270713          	addi	a4,a4,-1214 # 80008090 <userret>
    80003556:	8f11                	sub	a4,a4,a2
    80003558:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000355a:	577d                	li	a4,-1
    8000355c:	177e                	slli	a4,a4,0x3f
    8000355e:	8dd9                	or	a1,a1,a4
    80003560:	02000537          	lui	a0,0x2000
    80003564:	157d                	addi	a0,a0,-1
    80003566:	0536                	slli	a0,a0,0xd
    80003568:	9782                	jalr	a5
}
    8000356a:	60a2                	ld	ra,8(sp)
    8000356c:	6402                	ld	s0,0(sp)
    8000356e:	0141                	addi	sp,sp,16
    80003570:	8082                	ret

0000000080003572 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003572:	1101                	addi	sp,sp,-32
    80003574:	ec06                	sd	ra,24(sp)
    80003576:	e822                	sd	s0,16(sp)
    80003578:	e426                	sd	s1,8(sp)
    8000357a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000357c:	00015497          	auipc	s1,0x15
    80003580:	46448493          	addi	s1,s1,1124 # 800189e0 <tickslock>
    80003584:	8526                	mv	a0,s1
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	666080e7          	jalr	1638(ra) # 80000bec <acquire>
  ticks++;
    8000358e:	00007517          	auipc	a0,0x7
    80003592:	ae250513          	addi	a0,a0,-1310 # 8000a070 <ticks>
    80003596:	411c                	lw	a5,0(a0)
    80003598:	2785                	addiw	a5,a5,1
    8000359a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000359c:	00000097          	auipc	ra,0x0
    800035a0:	99a080e7          	jalr	-1638(ra) # 80002f36 <wakeup>
  release(&tickslock);
    800035a4:	8526                	mv	a0,s1
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	700080e7          	jalr	1792(ra) # 80000ca6 <release>
}
    800035ae:	60e2                	ld	ra,24(sp)
    800035b0:	6442                	ld	s0,16(sp)
    800035b2:	64a2                	ld	s1,8(sp)
    800035b4:	6105                	addi	sp,sp,32
    800035b6:	8082                	ret

00000000800035b8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800035b8:	1101                	addi	sp,sp,-32
    800035ba:	ec06                	sd	ra,24(sp)
    800035bc:	e822                	sd	s0,16(sp)
    800035be:	e426                	sd	s1,8(sp)
    800035c0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800035c2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800035c6:	00074d63          	bltz	a4,800035e0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800035ca:	57fd                	li	a5,-1
    800035cc:	17fe                	slli	a5,a5,0x3f
    800035ce:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800035d0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800035d2:	06f70363          	beq	a4,a5,80003638 <devintr+0x80>
  }
}
    800035d6:	60e2                	ld	ra,24(sp)
    800035d8:	6442                	ld	s0,16(sp)
    800035da:	64a2                	ld	s1,8(sp)
    800035dc:	6105                	addi	sp,sp,32
    800035de:	8082                	ret
     (scause & 0xff) == 9){
    800035e0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800035e4:	46a5                	li	a3,9
    800035e6:	fed792e3          	bne	a5,a3,800035ca <devintr+0x12>
    int irq = plic_claim();
    800035ea:	00003097          	auipc	ra,0x3
    800035ee:	4ae080e7          	jalr	1198(ra) # 80006a98 <plic_claim>
    800035f2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800035f4:	47a9                	li	a5,10
    800035f6:	02f50763          	beq	a0,a5,80003624 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800035fa:	4785                	li	a5,1
    800035fc:	02f50963          	beq	a0,a5,8000362e <devintr+0x76>
    return 1;
    80003600:	4505                	li	a0,1
    } else if(irq){
    80003602:	d8f1                	beqz	s1,800035d6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003604:	85a6                	mv	a1,s1
    80003606:	00006517          	auipc	a0,0x6
    8000360a:	ed250513          	addi	a0,a0,-302 # 800094d8 <states.1905+0x38>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	f7a080e7          	jalr	-134(ra) # 80000588 <printf>
      plic_complete(irq);
    80003616:	8526                	mv	a0,s1
    80003618:	00003097          	auipc	ra,0x3
    8000361c:	4a4080e7          	jalr	1188(ra) # 80006abc <plic_complete>
    return 1;
    80003620:	4505                	li	a0,1
    80003622:	bf55                	j	800035d6 <devintr+0x1e>
      uartintr();
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	384080e7          	jalr	900(ra) # 800009a8 <uartintr>
    8000362c:	b7ed                	j	80003616 <devintr+0x5e>
      virtio_disk_intr();
    8000362e:	00004097          	auipc	ra,0x4
    80003632:	96e080e7          	jalr	-1682(ra) # 80006f9c <virtio_disk_intr>
    80003636:	b7c5                	j	80003616 <devintr+0x5e>
    if(cpuid() == 0){
    80003638:	fffff097          	auipc	ra,0xfffff
    8000363c:	836080e7          	jalr	-1994(ra) # 80001e6e <cpuid>
    80003640:	c901                	beqz	a0,80003650 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003642:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003646:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003648:	14479073          	csrw	sip,a5
    return 2;
    8000364c:	4509                	li	a0,2
    8000364e:	b761                	j	800035d6 <devintr+0x1e>
      clockintr();
    80003650:	00000097          	auipc	ra,0x0
    80003654:	f22080e7          	jalr	-222(ra) # 80003572 <clockintr>
    80003658:	b7ed                	j	80003642 <devintr+0x8a>

000000008000365a <usertrap>:
{
    8000365a:	1101                	addi	sp,sp,-32
    8000365c:	ec06                	sd	ra,24(sp)
    8000365e:	e822                	sd	s0,16(sp)
    80003660:	e426                	sd	s1,8(sp)
    80003662:	e04a                	sd	s2,0(sp)
    80003664:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003666:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000366a:	1007f793          	andi	a5,a5,256
    8000366e:	e3ad                	bnez	a5,800036d0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003670:	00003797          	auipc	a5,0x3
    80003674:	32078793          	addi	a5,a5,800 # 80006990 <kernelvec>
    80003678:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000367c:	fffff097          	auipc	ra,0xfffff
    80003680:	826080e7          	jalr	-2010(ra) # 80001ea2 <myproc>
    80003684:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003686:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003688:	14102773          	csrr	a4,sepc
    8000368c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000368e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003692:	47a1                	li	a5,8
    80003694:	04f71c63          	bne	a4,a5,800036ec <usertrap+0x92>
    if(p->killed)
    80003698:	413c                	lw	a5,64(a0)
    8000369a:	e3b9                	bnez	a5,800036e0 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000369c:	60d8                	ld	a4,128(s1)
    8000369e:	6f1c                	ld	a5,24(a4)
    800036a0:	0791                	addi	a5,a5,4
    800036a2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800036a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800036a8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800036ac:	10079073          	csrw	sstatus,a5
    syscall();
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	2e0080e7          	jalr	736(ra) # 80003990 <syscall>
  if(p->killed)
    800036b8:	40bc                	lw	a5,64(s1)
    800036ba:	ebc1                	bnez	a5,8000374a <usertrap+0xf0>
  usertrapret();
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	e18080e7          	jalr	-488(ra) # 800034d4 <usertrapret>
}
    800036c4:	60e2                	ld	ra,24(sp)
    800036c6:	6442                	ld	s0,16(sp)
    800036c8:	64a2                	ld	s1,8(sp)
    800036ca:	6902                	ld	s2,0(sp)
    800036cc:	6105                	addi	sp,sp,32
    800036ce:	8082                	ret
    panic("usertrap: not from user mode");
    800036d0:	00006517          	auipc	a0,0x6
    800036d4:	e2850513          	addi	a0,a0,-472 # 800094f8 <states.1905+0x58>
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	e66080e7          	jalr	-410(ra) # 8000053e <panic>
      exit(-1);
    800036e0:	557d                	li	a0,-1
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	a46080e7          	jalr	-1466(ra) # 80003128 <exit>
    800036ea:	bf4d                	j	8000369c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	ecc080e7          	jalr	-308(ra) # 800035b8 <devintr>
    800036f4:	892a                	mv	s2,a0
    800036f6:	c501                	beqz	a0,800036fe <usertrap+0xa4>
  if(p->killed)
    800036f8:	40bc                	lw	a5,64(s1)
    800036fa:	c3a1                	beqz	a5,8000373a <usertrap+0xe0>
    800036fc:	a815                	j	80003730 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800036fe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003702:	44b0                	lw	a2,72(s1)
    80003704:	00006517          	auipc	a0,0x6
    80003708:	e1450513          	addi	a0,a0,-492 # 80009518 <states.1905+0x78>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	e7c080e7          	jalr	-388(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003714:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003718:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000371c:	00006517          	auipc	a0,0x6
    80003720:	e2c50513          	addi	a0,a0,-468 # 80009548 <states.1905+0xa8>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	e64080e7          	jalr	-412(ra) # 80000588 <printf>
    p->killed = 1;
    8000372c:	4785                	li	a5,1
    8000372e:	c0bc                	sw	a5,64(s1)
    exit(-1);
    80003730:	557d                	li	a0,-1
    80003732:	00000097          	auipc	ra,0x0
    80003736:	9f6080e7          	jalr	-1546(ra) # 80003128 <exit>
  if(which_dev == 2)
    8000373a:	4789                	li	a5,2
    8000373c:	f8f910e3          	bne	s2,a5,800036bc <usertrap+0x62>
    yield();
    80003740:	fffff097          	auipc	ra,0xfffff
    80003744:	a92080e7          	jalr	-1390(ra) # 800021d2 <yield>
    80003748:	bf95                	j	800036bc <usertrap+0x62>
  int which_dev = 0;
    8000374a:	4901                	li	s2,0
    8000374c:	b7d5                	j	80003730 <usertrap+0xd6>

000000008000374e <kerneltrap>:
{
    8000374e:	7179                	addi	sp,sp,-48
    80003750:	f406                	sd	ra,40(sp)
    80003752:	f022                	sd	s0,32(sp)
    80003754:	ec26                	sd	s1,24(sp)
    80003756:	e84a                	sd	s2,16(sp)
    80003758:	e44e                	sd	s3,8(sp)
    8000375a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000375c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003760:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003764:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003768:	1004f793          	andi	a5,s1,256
    8000376c:	cb85                	beqz	a5,8000379c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000376e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003772:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003774:	ef85                	bnez	a5,800037ac <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	e42080e7          	jalr	-446(ra) # 800035b8 <devintr>
    8000377e:	cd1d                	beqz	a0,800037bc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003780:	4789                	li	a5,2
    80003782:	06f50a63          	beq	a0,a5,800037f6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003786:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000378a:	10049073          	csrw	sstatus,s1
}
    8000378e:	70a2                	ld	ra,40(sp)
    80003790:	7402                	ld	s0,32(sp)
    80003792:	64e2                	ld	s1,24(sp)
    80003794:	6942                	ld	s2,16(sp)
    80003796:	69a2                	ld	s3,8(sp)
    80003798:	6145                	addi	sp,sp,48
    8000379a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000379c:	00006517          	auipc	a0,0x6
    800037a0:	dcc50513          	addi	a0,a0,-564 # 80009568 <states.1905+0xc8>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	d9a080e7          	jalr	-614(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800037ac:	00006517          	auipc	a0,0x6
    800037b0:	de450513          	addi	a0,a0,-540 # 80009590 <states.1905+0xf0>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800037bc:	85ce                	mv	a1,s3
    800037be:	00006517          	auipc	a0,0x6
    800037c2:	df250513          	addi	a0,a0,-526 # 800095b0 <states.1905+0x110>
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	dc2080e7          	jalr	-574(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800037ce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800037d2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800037d6:	00006517          	auipc	a0,0x6
    800037da:	dea50513          	addi	a0,a0,-534 # 800095c0 <states.1905+0x120>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	daa080e7          	jalr	-598(ra) # 80000588 <printf>
    panic("kerneltrap");
    800037e6:	00006517          	auipc	a0,0x6
    800037ea:	df250513          	addi	a0,a0,-526 # 800095d8 <states.1905+0x138>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	d50080e7          	jalr	-688(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800037f6:	ffffe097          	auipc	ra,0xffffe
    800037fa:	6ac080e7          	jalr	1708(ra) # 80001ea2 <myproc>
    800037fe:	d541                	beqz	a0,80003786 <kerneltrap+0x38>
    80003800:	ffffe097          	auipc	ra,0xffffe
    80003804:	6a2080e7          	jalr	1698(ra) # 80001ea2 <myproc>
    80003808:	5918                	lw	a4,48(a0)
    8000380a:	4791                	li	a5,4
    8000380c:	f6f71de3          	bne	a4,a5,80003786 <kerneltrap+0x38>
    yield();
    80003810:	fffff097          	auipc	ra,0xfffff
    80003814:	9c2080e7          	jalr	-1598(ra) # 800021d2 <yield>
    80003818:	b7bd                	j	80003786 <kerneltrap+0x38>

000000008000381a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000381a:	1101                	addi	sp,sp,-32
    8000381c:	ec06                	sd	ra,24(sp)
    8000381e:	e822                	sd	s0,16(sp)
    80003820:	e426                	sd	s1,8(sp)
    80003822:	1000                	addi	s0,sp,32
    80003824:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003826:	ffffe097          	auipc	ra,0xffffe
    8000382a:	67c080e7          	jalr	1660(ra) # 80001ea2 <myproc>
  switch (n) {
    8000382e:	4795                	li	a5,5
    80003830:	0497e163          	bltu	a5,s1,80003872 <argraw+0x58>
    80003834:	048a                	slli	s1,s1,0x2
    80003836:	00006717          	auipc	a4,0x6
    8000383a:	dda70713          	addi	a4,a4,-550 # 80009610 <states.1905+0x170>
    8000383e:	94ba                	add	s1,s1,a4
    80003840:	409c                	lw	a5,0(s1)
    80003842:	97ba                	add	a5,a5,a4
    80003844:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003846:	615c                	ld	a5,128(a0)
    80003848:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000384a:	60e2                	ld	ra,24(sp)
    8000384c:	6442                	ld	s0,16(sp)
    8000384e:	64a2                	ld	s1,8(sp)
    80003850:	6105                	addi	sp,sp,32
    80003852:	8082                	ret
    return p->trapframe->a1;
    80003854:	615c                	ld	a5,128(a0)
    80003856:	7fa8                	ld	a0,120(a5)
    80003858:	bfcd                	j	8000384a <argraw+0x30>
    return p->trapframe->a2;
    8000385a:	615c                	ld	a5,128(a0)
    8000385c:	63c8                	ld	a0,128(a5)
    8000385e:	b7f5                	j	8000384a <argraw+0x30>
    return p->trapframe->a3;
    80003860:	615c                	ld	a5,128(a0)
    80003862:	67c8                	ld	a0,136(a5)
    80003864:	b7dd                	j	8000384a <argraw+0x30>
    return p->trapframe->a4;
    80003866:	615c                	ld	a5,128(a0)
    80003868:	6bc8                	ld	a0,144(a5)
    8000386a:	b7c5                	j	8000384a <argraw+0x30>
    return p->trapframe->a5;
    8000386c:	615c                	ld	a5,128(a0)
    8000386e:	6fc8                	ld	a0,152(a5)
    80003870:	bfe9                	j	8000384a <argraw+0x30>
  panic("argraw");
    80003872:	00006517          	auipc	a0,0x6
    80003876:	d7650513          	addi	a0,a0,-650 # 800095e8 <states.1905+0x148>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	cc4080e7          	jalr	-828(ra) # 8000053e <panic>

0000000080003882 <fetchaddr>:
{
    80003882:	1101                	addi	sp,sp,-32
    80003884:	ec06                	sd	ra,24(sp)
    80003886:	e822                	sd	s0,16(sp)
    80003888:	e426                	sd	s1,8(sp)
    8000388a:	e04a                	sd	s2,0(sp)
    8000388c:	1000                	addi	s0,sp,32
    8000388e:	84aa                	mv	s1,a0
    80003890:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003892:	ffffe097          	auipc	ra,0xffffe
    80003896:	610080e7          	jalr	1552(ra) # 80001ea2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000389a:	793c                	ld	a5,112(a0)
    8000389c:	02f4f863          	bgeu	s1,a5,800038cc <fetchaddr+0x4a>
    800038a0:	00848713          	addi	a4,s1,8
    800038a4:	02e7e663          	bltu	a5,a4,800038d0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800038a8:	46a1                	li	a3,8
    800038aa:	8626                	mv	a2,s1
    800038ac:	85ca                	mv	a1,s2
    800038ae:	7d28                	ld	a0,120(a0)
    800038b0:	ffffe097          	auipc	ra,0xffffe
    800038b4:	e5c080e7          	jalr	-420(ra) # 8000170c <copyin>
    800038b8:	00a03533          	snez	a0,a0
    800038bc:	40a00533          	neg	a0,a0
}
    800038c0:	60e2                	ld	ra,24(sp)
    800038c2:	6442                	ld	s0,16(sp)
    800038c4:	64a2                	ld	s1,8(sp)
    800038c6:	6902                	ld	s2,0(sp)
    800038c8:	6105                	addi	sp,sp,32
    800038ca:	8082                	ret
    return -1;
    800038cc:	557d                	li	a0,-1
    800038ce:	bfcd                	j	800038c0 <fetchaddr+0x3e>
    800038d0:	557d                	li	a0,-1
    800038d2:	b7fd                	j	800038c0 <fetchaddr+0x3e>

00000000800038d4 <fetchstr>:
{
    800038d4:	7179                	addi	sp,sp,-48
    800038d6:	f406                	sd	ra,40(sp)
    800038d8:	f022                	sd	s0,32(sp)
    800038da:	ec26                	sd	s1,24(sp)
    800038dc:	e84a                	sd	s2,16(sp)
    800038de:	e44e                	sd	s3,8(sp)
    800038e0:	1800                	addi	s0,sp,48
    800038e2:	892a                	mv	s2,a0
    800038e4:	84ae                	mv	s1,a1
    800038e6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800038e8:	ffffe097          	auipc	ra,0xffffe
    800038ec:	5ba080e7          	jalr	1466(ra) # 80001ea2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800038f0:	86ce                	mv	a3,s3
    800038f2:	864a                	mv	a2,s2
    800038f4:	85a6                	mv	a1,s1
    800038f6:	7d28                	ld	a0,120(a0)
    800038f8:	ffffe097          	auipc	ra,0xffffe
    800038fc:	ea0080e7          	jalr	-352(ra) # 80001798 <copyinstr>
  if(err < 0)
    80003900:	00054763          	bltz	a0,8000390e <fetchstr+0x3a>
  return strlen(buf);
    80003904:	8526                	mv	a0,s1
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	56c080e7          	jalr	1388(ra) # 80000e72 <strlen>
}
    8000390e:	70a2                	ld	ra,40(sp)
    80003910:	7402                	ld	s0,32(sp)
    80003912:	64e2                	ld	s1,24(sp)
    80003914:	6942                	ld	s2,16(sp)
    80003916:	69a2                	ld	s3,8(sp)
    80003918:	6145                	addi	sp,sp,48
    8000391a:	8082                	ret

000000008000391c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000391c:	1101                	addi	sp,sp,-32
    8000391e:	ec06                	sd	ra,24(sp)
    80003920:	e822                	sd	s0,16(sp)
    80003922:	e426                	sd	s1,8(sp)
    80003924:	1000                	addi	s0,sp,32
    80003926:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	ef2080e7          	jalr	-270(ra) # 8000381a <argraw>
    80003930:	c088                	sw	a0,0(s1)
  return 0;
}
    80003932:	4501                	li	a0,0
    80003934:	60e2                	ld	ra,24(sp)
    80003936:	6442                	ld	s0,16(sp)
    80003938:	64a2                	ld	s1,8(sp)
    8000393a:	6105                	addi	sp,sp,32
    8000393c:	8082                	ret

000000008000393e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000393e:	1101                	addi	sp,sp,-32
    80003940:	ec06                	sd	ra,24(sp)
    80003942:	e822                	sd	s0,16(sp)
    80003944:	e426                	sd	s1,8(sp)
    80003946:	1000                	addi	s0,sp,32
    80003948:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000394a:	00000097          	auipc	ra,0x0
    8000394e:	ed0080e7          	jalr	-304(ra) # 8000381a <argraw>
    80003952:	e088                	sd	a0,0(s1)
  return 0;
}
    80003954:	4501                	li	a0,0
    80003956:	60e2                	ld	ra,24(sp)
    80003958:	6442                	ld	s0,16(sp)
    8000395a:	64a2                	ld	s1,8(sp)
    8000395c:	6105                	addi	sp,sp,32
    8000395e:	8082                	ret

0000000080003960 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003960:	1101                	addi	sp,sp,-32
    80003962:	ec06                	sd	ra,24(sp)
    80003964:	e822                	sd	s0,16(sp)
    80003966:	e426                	sd	s1,8(sp)
    80003968:	e04a                	sd	s2,0(sp)
    8000396a:	1000                	addi	s0,sp,32
    8000396c:	84ae                	mv	s1,a1
    8000396e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003970:	00000097          	auipc	ra,0x0
    80003974:	eaa080e7          	jalr	-342(ra) # 8000381a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003978:	864a                	mv	a2,s2
    8000397a:	85a6                	mv	a1,s1
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	f58080e7          	jalr	-168(ra) # 800038d4 <fetchstr>
}
    80003984:	60e2                	ld	ra,24(sp)
    80003986:	6442                	ld	s0,16(sp)
    80003988:	64a2                	ld	s1,8(sp)
    8000398a:	6902                	ld	s2,0(sp)
    8000398c:	6105                	addi	sp,sp,32
    8000398e:	8082                	ret

0000000080003990 <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    80003990:	1101                	addi	sp,sp,-32
    80003992:	ec06                	sd	ra,24(sp)
    80003994:	e822                	sd	s0,16(sp)
    80003996:	e426                	sd	s1,8(sp)
    80003998:	e04a                	sd	s2,0(sp)
    8000399a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000399c:	ffffe097          	auipc	ra,0xffffe
    800039a0:	506080e7          	jalr	1286(ra) # 80001ea2 <myproc>
    800039a4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800039a6:	08053903          	ld	s2,128(a0)
    800039aa:	0a893783          	ld	a5,168(s2)
    800039ae:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800039b2:	37fd                	addiw	a5,a5,-1
    800039b4:	4759                	li	a4,22
    800039b6:	00f76f63          	bltu	a4,a5,800039d4 <syscall+0x44>
    800039ba:	00369713          	slli	a4,a3,0x3
    800039be:	00006797          	auipc	a5,0x6
    800039c2:	c6a78793          	addi	a5,a5,-918 # 80009628 <syscalls>
    800039c6:	97ba                	add	a5,a5,a4
    800039c8:	639c                	ld	a5,0(a5)
    800039ca:	c789                	beqz	a5,800039d4 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800039cc:	9782                	jalr	a5
    800039ce:	06a93823          	sd	a0,112(s2)
    800039d2:	a839                	j	800039f0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800039d4:	18048613          	addi	a2,s1,384
    800039d8:	44ac                	lw	a1,72(s1)
    800039da:	00006517          	auipc	a0,0x6
    800039de:	c1650513          	addi	a0,a0,-1002 # 800095f0 <states.1905+0x150>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	ba6080e7          	jalr	-1114(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800039ea:	60dc                	ld	a5,128(s1)
    800039ec:	577d                	li	a4,-1
    800039ee:	fbb8                	sd	a4,112(a5)
  }
}
    800039f0:	60e2                	ld	ra,24(sp)
    800039f2:	6442                	ld	s0,16(sp)
    800039f4:	64a2                	ld	s1,8(sp)
    800039f6:	6902                	ld	s2,0(sp)
    800039f8:	6105                	addi	sp,sp,32
    800039fa:	8082                	ret

00000000800039fc <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    800039fc:	1101                	addi	sp,sp,-32
    800039fe:	ec06                	sd	ra,24(sp)
    80003a00:	e822                	sd	s0,16(sp)
    80003a02:	1000                	addi	s0,sp,32
  int a;

  if(argint(0, &a) < 0)
    80003a04:	fec40593          	addi	a1,s0,-20
    80003a08:	4501                	li	a0,0
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	f12080e7          	jalr	-238(ra) # 8000391c <argint>
    80003a12:	87aa                	mv	a5,a0
    return -1;
    80003a14:	557d                	li	a0,-1
  if(argint(0, &a) < 0)
    80003a16:	0007c863          	bltz	a5,80003a26 <sys_set_cpu+0x2a>
  return set_cpu(a);
    80003a1a:	fec42503          	lw	a0,-20(s0)
    80003a1e:	fffff097          	auipc	ra,0xfffff
    80003a22:	800080e7          	jalr	-2048(ra) # 8000221e <set_cpu>
}
    80003a26:	60e2                	ld	ra,24(sp)
    80003a28:	6442                	ld	s0,16(sp)
    80003a2a:	6105                	addi	sp,sp,32
    80003a2c:	8082                	ret

0000000080003a2e <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003a2e:	1141                	addi	sp,sp,-16
    80003a30:	e406                	sd	ra,8(sp)
    80003a32:	e022                	sd	s0,0(sp)
    80003a34:	0800                	addi	s0,sp,16
  return get_cpu();
    80003a36:	ffffe097          	auipc	ra,0xffffe
    80003a3a:	4ac080e7          	jalr	1196(ra) # 80001ee2 <get_cpu>
}
    80003a3e:	60a2                	ld	ra,8(sp)
    80003a40:	6402                	ld	s0,0(sp)
    80003a42:	0141                	addi	sp,sp,16
    80003a44:	8082                	ret

0000000080003a46 <sys_exit>:

uint64
sys_exit(void)
{
    80003a46:	1101                	addi	sp,sp,-32
    80003a48:	ec06                	sd	ra,24(sp)
    80003a4a:	e822                	sd	s0,16(sp)
    80003a4c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003a4e:	fec40593          	addi	a1,s0,-20
    80003a52:	4501                	li	a0,0
    80003a54:	00000097          	auipc	ra,0x0
    80003a58:	ec8080e7          	jalr	-312(ra) # 8000391c <argint>
    return -1;
    80003a5c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003a5e:	00054963          	bltz	a0,80003a70 <sys_exit+0x2a>
  exit(n);
    80003a62:	fec42503          	lw	a0,-20(s0)
    80003a66:	fffff097          	auipc	ra,0xfffff
    80003a6a:	6c2080e7          	jalr	1730(ra) # 80003128 <exit>
  return 0;  // not reached
    80003a6e:	4781                	li	a5,0
}
    80003a70:	853e                	mv	a0,a5
    80003a72:	60e2                	ld	ra,24(sp)
    80003a74:	6442                	ld	s0,16(sp)
    80003a76:	6105                	addi	sp,sp,32
    80003a78:	8082                	ret

0000000080003a7a <sys_getpid>:

uint64
sys_getpid(void)
{
    80003a7a:	1141                	addi	sp,sp,-16
    80003a7c:	e406                	sd	ra,8(sp)
    80003a7e:	e022                	sd	s0,0(sp)
    80003a80:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003a82:	ffffe097          	auipc	ra,0xffffe
    80003a86:	420080e7          	jalr	1056(ra) # 80001ea2 <myproc>
}
    80003a8a:	4528                	lw	a0,72(a0)
    80003a8c:	60a2                	ld	ra,8(sp)
    80003a8e:	6402                	ld	s0,0(sp)
    80003a90:	0141                	addi	sp,sp,16
    80003a92:	8082                	ret

0000000080003a94 <sys_fork>:

uint64
sys_fork(void)
{
    80003a94:	1141                	addi	sp,sp,-16
    80003a96:	e406                	sd	ra,8(sp)
    80003a98:	e022                	sd	s0,0(sp)
    80003a9a:	0800                	addi	s0,sp,16
  return fork();
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	19a080e7          	jalr	410(ra) # 80002c36 <fork>
}
    80003aa4:	60a2                	ld	ra,8(sp)
    80003aa6:	6402                	ld	s0,0(sp)
    80003aa8:	0141                	addi	sp,sp,16
    80003aaa:	8082                	ret

0000000080003aac <sys_wait>:

uint64
sys_wait(void)
{
    80003aac:	1101                	addi	sp,sp,-32
    80003aae:	ec06                	sd	ra,24(sp)
    80003ab0:	e822                	sd	s0,16(sp)
    80003ab2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003ab4:	fe840593          	addi	a1,s0,-24
    80003ab8:	4501                	li	a0,0
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	e84080e7          	jalr	-380(ra) # 8000393e <argaddr>
    80003ac2:	87aa                	mv	a5,a0
    return -1;
    80003ac4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003ac6:	0007c863          	bltz	a5,80003ad6 <sys_wait+0x2a>
  return wait(p);
    80003aca:	fe843503          	ld	a0,-24(s0)
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	340080e7          	jalr	832(ra) # 80002e0e <wait>
}
    80003ad6:	60e2                	ld	ra,24(sp)
    80003ad8:	6442                	ld	s0,16(sp)
    80003ada:	6105                	addi	sp,sp,32
    80003adc:	8082                	ret

0000000080003ade <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003ade:	7179                	addi	sp,sp,-48
    80003ae0:	f406                	sd	ra,40(sp)
    80003ae2:	f022                	sd	s0,32(sp)
    80003ae4:	ec26                	sd	s1,24(sp)
    80003ae6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003ae8:	fdc40593          	addi	a1,s0,-36
    80003aec:	4501                	li	a0,0
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	e2e080e7          	jalr	-466(ra) # 8000391c <argint>
    80003af6:	87aa                	mv	a5,a0
    return -1;
    80003af8:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003afa:	0207c063          	bltz	a5,80003b1a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003afe:	ffffe097          	auipc	ra,0xffffe
    80003b02:	3a4080e7          	jalr	932(ra) # 80001ea2 <myproc>
    80003b06:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    80003b08:	fdc42503          	lw	a0,-36(s0)
    80003b0c:	ffffe097          	auipc	ra,0xffffe
    80003b10:	55c080e7          	jalr	1372(ra) # 80002068 <growproc>
    80003b14:	00054863          	bltz	a0,80003b24 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003b18:	8526                	mv	a0,s1
}
    80003b1a:	70a2                	ld	ra,40(sp)
    80003b1c:	7402                	ld	s0,32(sp)
    80003b1e:	64e2                	ld	s1,24(sp)
    80003b20:	6145                	addi	sp,sp,48
    80003b22:	8082                	ret
    return -1;
    80003b24:	557d                	li	a0,-1
    80003b26:	bfd5                	j	80003b1a <sys_sbrk+0x3c>

0000000080003b28 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003b28:	7139                	addi	sp,sp,-64
    80003b2a:	fc06                	sd	ra,56(sp)
    80003b2c:	f822                	sd	s0,48(sp)
    80003b2e:	f426                	sd	s1,40(sp)
    80003b30:	f04a                	sd	s2,32(sp)
    80003b32:	ec4e                	sd	s3,24(sp)
    80003b34:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003b36:	fcc40593          	addi	a1,s0,-52
    80003b3a:	4501                	li	a0,0
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	de0080e7          	jalr	-544(ra) # 8000391c <argint>
    return -1;
    80003b44:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003b46:	06054563          	bltz	a0,80003bb0 <sys_sleep+0x88>
  acquire(&tickslock);
    80003b4a:	00015517          	auipc	a0,0x15
    80003b4e:	e9650513          	addi	a0,a0,-362 # 800189e0 <tickslock>
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	09a080e7          	jalr	154(ra) # 80000bec <acquire>
  ticks0 = ticks;
    80003b5a:	00006917          	auipc	s2,0x6
    80003b5e:	51692903          	lw	s2,1302(s2) # 8000a070 <ticks>
  while(ticks - ticks0 < n){
    80003b62:	fcc42783          	lw	a5,-52(s0)
    80003b66:	cf85                	beqz	a5,80003b9e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003b68:	00015997          	auipc	s3,0x15
    80003b6c:	e7898993          	addi	s3,s3,-392 # 800189e0 <tickslock>
    80003b70:	00006497          	auipc	s1,0x6
    80003b74:	50048493          	addi	s1,s1,1280 # 8000a070 <ticks>
    if(myproc()->killed){
    80003b78:	ffffe097          	auipc	ra,0xffffe
    80003b7c:	32a080e7          	jalr	810(ra) # 80001ea2 <myproc>
    80003b80:	413c                	lw	a5,64(a0)
    80003b82:	ef9d                	bnez	a5,80003bc0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003b84:	85ce                	mv	a1,s3
    80003b86:	8526                	mv	a0,s1
    80003b88:	fffff097          	auipc	ra,0xfffff
    80003b8c:	206080e7          	jalr	518(ra) # 80002d8e <sleep>
  while(ticks - ticks0 < n){
    80003b90:	409c                	lw	a5,0(s1)
    80003b92:	412787bb          	subw	a5,a5,s2
    80003b96:	fcc42703          	lw	a4,-52(s0)
    80003b9a:	fce7efe3          	bltu	a5,a4,80003b78 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003b9e:	00015517          	auipc	a0,0x15
    80003ba2:	e4250513          	addi	a0,a0,-446 # 800189e0 <tickslock>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	100080e7          	jalr	256(ra) # 80000ca6 <release>
  return 0;
    80003bae:	4781                	li	a5,0
}
    80003bb0:	853e                	mv	a0,a5
    80003bb2:	70e2                	ld	ra,56(sp)
    80003bb4:	7442                	ld	s0,48(sp)
    80003bb6:	74a2                	ld	s1,40(sp)
    80003bb8:	7902                	ld	s2,32(sp)
    80003bba:	69e2                	ld	s3,24(sp)
    80003bbc:	6121                	addi	sp,sp,64
    80003bbe:	8082                	ret
      release(&tickslock);
    80003bc0:	00015517          	auipc	a0,0x15
    80003bc4:	e2050513          	addi	a0,a0,-480 # 800189e0 <tickslock>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	0de080e7          	jalr	222(ra) # 80000ca6 <release>
      return -1;
    80003bd0:	57fd                	li	a5,-1
    80003bd2:	bff9                	j	80003bb0 <sys_sleep+0x88>

0000000080003bd4 <sys_kill>:

uint64
sys_kill(void)
{
    80003bd4:	1101                	addi	sp,sp,-32
    80003bd6:	ec06                	sd	ra,24(sp)
    80003bd8:	e822                	sd	s0,16(sp)
    80003bda:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003bdc:	fec40593          	addi	a1,s0,-20
    80003be0:	4501                	li	a0,0
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	d3a080e7          	jalr	-710(ra) # 8000391c <argint>
    80003bea:	87aa                	mv	a5,a0
    return -1;
    80003bec:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003bee:	0007c863          	bltz	a5,80003bfe <sys_kill+0x2a>
  return kill(pid);
    80003bf2:	fec42503          	lw	a0,-20(s0)
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	626080e7          	jalr	1574(ra) # 8000321c <kill>
}
    80003bfe:	60e2                	ld	ra,24(sp)
    80003c00:	6442                	ld	s0,16(sp)
    80003c02:	6105                	addi	sp,sp,32
    80003c04:	8082                	ret

0000000080003c06 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003c06:	1101                	addi	sp,sp,-32
    80003c08:	ec06                	sd	ra,24(sp)
    80003c0a:	e822                	sd	s0,16(sp)
    80003c0c:	e426                	sd	s1,8(sp)
    80003c0e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003c10:	00015517          	auipc	a0,0x15
    80003c14:	dd050513          	addi	a0,a0,-560 # 800189e0 <tickslock>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	fd4080e7          	jalr	-44(ra) # 80000bec <acquire>
  xticks = ticks;
    80003c20:	00006497          	auipc	s1,0x6
    80003c24:	4504a483          	lw	s1,1104(s1) # 8000a070 <ticks>
  release(&tickslock);
    80003c28:	00015517          	auipc	a0,0x15
    80003c2c:	db850513          	addi	a0,a0,-584 # 800189e0 <tickslock>
    80003c30:	ffffd097          	auipc	ra,0xffffd
    80003c34:	076080e7          	jalr	118(ra) # 80000ca6 <release>
  return xticks;
}
    80003c38:	02049513          	slli	a0,s1,0x20
    80003c3c:	9101                	srli	a0,a0,0x20
    80003c3e:	60e2                	ld	ra,24(sp)
    80003c40:	6442                	ld	s0,16(sp)
    80003c42:	64a2                	ld	s1,8(sp)
    80003c44:	6105                	addi	sp,sp,32
    80003c46:	8082                	ret

0000000080003c48 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003c48:	7179                	addi	sp,sp,-48
    80003c4a:	f406                	sd	ra,40(sp)
    80003c4c:	f022                	sd	s0,32(sp)
    80003c4e:	ec26                	sd	s1,24(sp)
    80003c50:	e84a                	sd	s2,16(sp)
    80003c52:	e44e                	sd	s3,8(sp)
    80003c54:	e052                	sd	s4,0(sp)
    80003c56:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003c58:	00006597          	auipc	a1,0x6
    80003c5c:	a9058593          	addi	a1,a1,-1392 # 800096e8 <syscalls+0xc0>
    80003c60:	00015517          	auipc	a0,0x15
    80003c64:	d9850513          	addi	a0,a0,-616 # 800189f8 <bcache>
    80003c68:	ffffd097          	auipc	ra,0xffffd
    80003c6c:	eec080e7          	jalr	-276(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003c70:	0001d797          	auipc	a5,0x1d
    80003c74:	d8878793          	addi	a5,a5,-632 # 800209f8 <bcache+0x8000>
    80003c78:	0001d717          	auipc	a4,0x1d
    80003c7c:	fe870713          	addi	a4,a4,-24 # 80020c60 <bcache+0x8268>
    80003c80:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003c84:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003c88:	00015497          	auipc	s1,0x15
    80003c8c:	d8848493          	addi	s1,s1,-632 # 80018a10 <bcache+0x18>
    b->next = bcache.head.next;
    80003c90:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003c92:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003c94:	00006a17          	auipc	s4,0x6
    80003c98:	a5ca0a13          	addi	s4,s4,-1444 # 800096f0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003c9c:	2b893783          	ld	a5,696(s2)
    80003ca0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003ca2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003ca6:	85d2                	mv	a1,s4
    80003ca8:	01048513          	addi	a0,s1,16
    80003cac:	00001097          	auipc	ra,0x1
    80003cb0:	4bc080e7          	jalr	1212(ra) # 80005168 <initsleeplock>
    bcache.head.next->prev = b;
    80003cb4:	2b893783          	ld	a5,696(s2)
    80003cb8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003cba:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003cbe:	45848493          	addi	s1,s1,1112
    80003cc2:	fd349de3          	bne	s1,s3,80003c9c <binit+0x54>
  }
}
    80003cc6:	70a2                	ld	ra,40(sp)
    80003cc8:	7402                	ld	s0,32(sp)
    80003cca:	64e2                	ld	s1,24(sp)
    80003ccc:	6942                	ld	s2,16(sp)
    80003cce:	69a2                	ld	s3,8(sp)
    80003cd0:	6a02                	ld	s4,0(sp)
    80003cd2:	6145                	addi	sp,sp,48
    80003cd4:	8082                	ret

0000000080003cd6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003cd6:	7179                	addi	sp,sp,-48
    80003cd8:	f406                	sd	ra,40(sp)
    80003cda:	f022                	sd	s0,32(sp)
    80003cdc:	ec26                	sd	s1,24(sp)
    80003cde:	e84a                	sd	s2,16(sp)
    80003ce0:	e44e                	sd	s3,8(sp)
    80003ce2:	1800                	addi	s0,sp,48
    80003ce4:	89aa                	mv	s3,a0
    80003ce6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003ce8:	00015517          	auipc	a0,0x15
    80003cec:	d1050513          	addi	a0,a0,-752 # 800189f8 <bcache>
    80003cf0:	ffffd097          	auipc	ra,0xffffd
    80003cf4:	efc080e7          	jalr	-260(ra) # 80000bec <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003cf8:	0001d497          	auipc	s1,0x1d
    80003cfc:	fb84b483          	ld	s1,-72(s1) # 80020cb0 <bcache+0x82b8>
    80003d00:	0001d797          	auipc	a5,0x1d
    80003d04:	f6078793          	addi	a5,a5,-160 # 80020c60 <bcache+0x8268>
    80003d08:	02f48f63          	beq	s1,a5,80003d46 <bread+0x70>
    80003d0c:	873e                	mv	a4,a5
    80003d0e:	a021                	j	80003d16 <bread+0x40>
    80003d10:	68a4                	ld	s1,80(s1)
    80003d12:	02e48a63          	beq	s1,a4,80003d46 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003d16:	449c                	lw	a5,8(s1)
    80003d18:	ff379ce3          	bne	a5,s3,80003d10 <bread+0x3a>
    80003d1c:	44dc                	lw	a5,12(s1)
    80003d1e:	ff2799e3          	bne	a5,s2,80003d10 <bread+0x3a>
      b->refcnt++;
    80003d22:	40bc                	lw	a5,64(s1)
    80003d24:	2785                	addiw	a5,a5,1
    80003d26:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003d28:	00015517          	auipc	a0,0x15
    80003d2c:	cd050513          	addi	a0,a0,-816 # 800189f8 <bcache>
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	f76080e7          	jalr	-138(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003d38:	01048513          	addi	a0,s1,16
    80003d3c:	00001097          	auipc	ra,0x1
    80003d40:	466080e7          	jalr	1126(ra) # 800051a2 <acquiresleep>
      return b;
    80003d44:	a8b9                	j	80003da2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003d46:	0001d497          	auipc	s1,0x1d
    80003d4a:	f624b483          	ld	s1,-158(s1) # 80020ca8 <bcache+0x82b0>
    80003d4e:	0001d797          	auipc	a5,0x1d
    80003d52:	f1278793          	addi	a5,a5,-238 # 80020c60 <bcache+0x8268>
    80003d56:	00f48863          	beq	s1,a5,80003d66 <bread+0x90>
    80003d5a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003d5c:	40bc                	lw	a5,64(s1)
    80003d5e:	cf81                	beqz	a5,80003d76 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003d60:	64a4                	ld	s1,72(s1)
    80003d62:	fee49de3          	bne	s1,a4,80003d5c <bread+0x86>
  panic("bget: no buffers");
    80003d66:	00006517          	auipc	a0,0x6
    80003d6a:	99250513          	addi	a0,a0,-1646 # 800096f8 <syscalls+0xd0>
    80003d6e:	ffffc097          	auipc	ra,0xffffc
    80003d72:	7d0080e7          	jalr	2000(ra) # 8000053e <panic>
      b->dev = dev;
    80003d76:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003d7a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003d7e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003d82:	4785                	li	a5,1
    80003d84:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003d86:	00015517          	auipc	a0,0x15
    80003d8a:	c7250513          	addi	a0,a0,-910 # 800189f8 <bcache>
    80003d8e:	ffffd097          	auipc	ra,0xffffd
    80003d92:	f18080e7          	jalr	-232(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003d96:	01048513          	addi	a0,s1,16
    80003d9a:	00001097          	auipc	ra,0x1
    80003d9e:	408080e7          	jalr	1032(ra) # 800051a2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003da2:	409c                	lw	a5,0(s1)
    80003da4:	cb89                	beqz	a5,80003db6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003da6:	8526                	mv	a0,s1
    80003da8:	70a2                	ld	ra,40(sp)
    80003daa:	7402                	ld	s0,32(sp)
    80003dac:	64e2                	ld	s1,24(sp)
    80003dae:	6942                	ld	s2,16(sp)
    80003db0:	69a2                	ld	s3,8(sp)
    80003db2:	6145                	addi	sp,sp,48
    80003db4:	8082                	ret
    virtio_disk_rw(b, 0);
    80003db6:	4581                	li	a1,0
    80003db8:	8526                	mv	a0,s1
    80003dba:	00003097          	auipc	ra,0x3
    80003dbe:	f0c080e7          	jalr	-244(ra) # 80006cc6 <virtio_disk_rw>
    b->valid = 1;
    80003dc2:	4785                	li	a5,1
    80003dc4:	c09c                	sw	a5,0(s1)
  return b;
    80003dc6:	b7c5                	j	80003da6 <bread+0xd0>

0000000080003dc8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003dc8:	1101                	addi	sp,sp,-32
    80003dca:	ec06                	sd	ra,24(sp)
    80003dcc:	e822                	sd	s0,16(sp)
    80003dce:	e426                	sd	s1,8(sp)
    80003dd0:	1000                	addi	s0,sp,32
    80003dd2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003dd4:	0541                	addi	a0,a0,16
    80003dd6:	00001097          	auipc	ra,0x1
    80003dda:	466080e7          	jalr	1126(ra) # 8000523c <holdingsleep>
    80003dde:	cd01                	beqz	a0,80003df6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003de0:	4585                	li	a1,1
    80003de2:	8526                	mv	a0,s1
    80003de4:	00003097          	auipc	ra,0x3
    80003de8:	ee2080e7          	jalr	-286(ra) # 80006cc6 <virtio_disk_rw>
}
    80003dec:	60e2                	ld	ra,24(sp)
    80003dee:	6442                	ld	s0,16(sp)
    80003df0:	64a2                	ld	s1,8(sp)
    80003df2:	6105                	addi	sp,sp,32
    80003df4:	8082                	ret
    panic("bwrite");
    80003df6:	00006517          	auipc	a0,0x6
    80003dfa:	91a50513          	addi	a0,a0,-1766 # 80009710 <syscalls+0xe8>
    80003dfe:	ffffc097          	auipc	ra,0xffffc
    80003e02:	740080e7          	jalr	1856(ra) # 8000053e <panic>

0000000080003e06 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003e06:	1101                	addi	sp,sp,-32
    80003e08:	ec06                	sd	ra,24(sp)
    80003e0a:	e822                	sd	s0,16(sp)
    80003e0c:	e426                	sd	s1,8(sp)
    80003e0e:	e04a                	sd	s2,0(sp)
    80003e10:	1000                	addi	s0,sp,32
    80003e12:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003e14:	01050913          	addi	s2,a0,16
    80003e18:	854a                	mv	a0,s2
    80003e1a:	00001097          	auipc	ra,0x1
    80003e1e:	422080e7          	jalr	1058(ra) # 8000523c <holdingsleep>
    80003e22:	c92d                	beqz	a0,80003e94 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003e24:	854a                	mv	a0,s2
    80003e26:	00001097          	auipc	ra,0x1
    80003e2a:	3d2080e7          	jalr	978(ra) # 800051f8 <releasesleep>

  acquire(&bcache.lock);
    80003e2e:	00015517          	auipc	a0,0x15
    80003e32:	bca50513          	addi	a0,a0,-1078 # 800189f8 <bcache>
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	db6080e7          	jalr	-586(ra) # 80000bec <acquire>
  b->refcnt--;
    80003e3e:	40bc                	lw	a5,64(s1)
    80003e40:	37fd                	addiw	a5,a5,-1
    80003e42:	0007871b          	sext.w	a4,a5
    80003e46:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003e48:	eb05                	bnez	a4,80003e78 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003e4a:	68bc                	ld	a5,80(s1)
    80003e4c:	64b8                	ld	a4,72(s1)
    80003e4e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003e50:	64bc                	ld	a5,72(s1)
    80003e52:	68b8                	ld	a4,80(s1)
    80003e54:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003e56:	0001d797          	auipc	a5,0x1d
    80003e5a:	ba278793          	addi	a5,a5,-1118 # 800209f8 <bcache+0x8000>
    80003e5e:	2b87b703          	ld	a4,696(a5)
    80003e62:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003e64:	0001d717          	auipc	a4,0x1d
    80003e68:	dfc70713          	addi	a4,a4,-516 # 80020c60 <bcache+0x8268>
    80003e6c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003e6e:	2b87b703          	ld	a4,696(a5)
    80003e72:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003e74:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003e78:	00015517          	auipc	a0,0x15
    80003e7c:	b8050513          	addi	a0,a0,-1152 # 800189f8 <bcache>
    80003e80:	ffffd097          	auipc	ra,0xffffd
    80003e84:	e26080e7          	jalr	-474(ra) # 80000ca6 <release>
}
    80003e88:	60e2                	ld	ra,24(sp)
    80003e8a:	6442                	ld	s0,16(sp)
    80003e8c:	64a2                	ld	s1,8(sp)
    80003e8e:	6902                	ld	s2,0(sp)
    80003e90:	6105                	addi	sp,sp,32
    80003e92:	8082                	ret
    panic("brelse");
    80003e94:	00006517          	auipc	a0,0x6
    80003e98:	88450513          	addi	a0,a0,-1916 # 80009718 <syscalls+0xf0>
    80003e9c:	ffffc097          	auipc	ra,0xffffc
    80003ea0:	6a2080e7          	jalr	1698(ra) # 8000053e <panic>

0000000080003ea4 <bpin>:

void
bpin(struct buf *b) {
    80003ea4:	1101                	addi	sp,sp,-32
    80003ea6:	ec06                	sd	ra,24(sp)
    80003ea8:	e822                	sd	s0,16(sp)
    80003eaa:	e426                	sd	s1,8(sp)
    80003eac:	1000                	addi	s0,sp,32
    80003eae:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003eb0:	00015517          	auipc	a0,0x15
    80003eb4:	b4850513          	addi	a0,a0,-1208 # 800189f8 <bcache>
    80003eb8:	ffffd097          	auipc	ra,0xffffd
    80003ebc:	d34080e7          	jalr	-716(ra) # 80000bec <acquire>
  b->refcnt++;
    80003ec0:	40bc                	lw	a5,64(s1)
    80003ec2:	2785                	addiw	a5,a5,1
    80003ec4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ec6:	00015517          	auipc	a0,0x15
    80003eca:	b3250513          	addi	a0,a0,-1230 # 800189f8 <bcache>
    80003ece:	ffffd097          	auipc	ra,0xffffd
    80003ed2:	dd8080e7          	jalr	-552(ra) # 80000ca6 <release>
}
    80003ed6:	60e2                	ld	ra,24(sp)
    80003ed8:	6442                	ld	s0,16(sp)
    80003eda:	64a2                	ld	s1,8(sp)
    80003edc:	6105                	addi	sp,sp,32
    80003ede:	8082                	ret

0000000080003ee0 <bunpin>:

void
bunpin(struct buf *b) {
    80003ee0:	1101                	addi	sp,sp,-32
    80003ee2:	ec06                	sd	ra,24(sp)
    80003ee4:	e822                	sd	s0,16(sp)
    80003ee6:	e426                	sd	s1,8(sp)
    80003ee8:	1000                	addi	s0,sp,32
    80003eea:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003eec:	00015517          	auipc	a0,0x15
    80003ef0:	b0c50513          	addi	a0,a0,-1268 # 800189f8 <bcache>
    80003ef4:	ffffd097          	auipc	ra,0xffffd
    80003ef8:	cf8080e7          	jalr	-776(ra) # 80000bec <acquire>
  b->refcnt--;
    80003efc:	40bc                	lw	a5,64(s1)
    80003efe:	37fd                	addiw	a5,a5,-1
    80003f00:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003f02:	00015517          	auipc	a0,0x15
    80003f06:	af650513          	addi	a0,a0,-1290 # 800189f8 <bcache>
    80003f0a:	ffffd097          	auipc	ra,0xffffd
    80003f0e:	d9c080e7          	jalr	-612(ra) # 80000ca6 <release>
}
    80003f12:	60e2                	ld	ra,24(sp)
    80003f14:	6442                	ld	s0,16(sp)
    80003f16:	64a2                	ld	s1,8(sp)
    80003f18:	6105                	addi	sp,sp,32
    80003f1a:	8082                	ret

0000000080003f1c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003f1c:	1101                	addi	sp,sp,-32
    80003f1e:	ec06                	sd	ra,24(sp)
    80003f20:	e822                	sd	s0,16(sp)
    80003f22:	e426                	sd	s1,8(sp)
    80003f24:	e04a                	sd	s2,0(sp)
    80003f26:	1000                	addi	s0,sp,32
    80003f28:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003f2a:	00d5d59b          	srliw	a1,a1,0xd
    80003f2e:	0001d797          	auipc	a5,0x1d
    80003f32:	1a67a783          	lw	a5,422(a5) # 800210d4 <sb+0x1c>
    80003f36:	9dbd                	addw	a1,a1,a5
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	d9e080e7          	jalr	-610(ra) # 80003cd6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003f40:	0074f713          	andi	a4,s1,7
    80003f44:	4785                	li	a5,1
    80003f46:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003f4a:	14ce                	slli	s1,s1,0x33
    80003f4c:	90d9                	srli	s1,s1,0x36
    80003f4e:	00950733          	add	a4,a0,s1
    80003f52:	05874703          	lbu	a4,88(a4)
    80003f56:	00e7f6b3          	and	a3,a5,a4
    80003f5a:	c69d                	beqz	a3,80003f88 <bfree+0x6c>
    80003f5c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003f5e:	94aa                	add	s1,s1,a0
    80003f60:	fff7c793          	not	a5,a5
    80003f64:	8ff9                	and	a5,a5,a4
    80003f66:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003f6a:	00001097          	auipc	ra,0x1
    80003f6e:	118080e7          	jalr	280(ra) # 80005082 <log_write>
  brelse(bp);
    80003f72:	854a                	mv	a0,s2
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	e92080e7          	jalr	-366(ra) # 80003e06 <brelse>
}
    80003f7c:	60e2                	ld	ra,24(sp)
    80003f7e:	6442                	ld	s0,16(sp)
    80003f80:	64a2                	ld	s1,8(sp)
    80003f82:	6902                	ld	s2,0(sp)
    80003f84:	6105                	addi	sp,sp,32
    80003f86:	8082                	ret
    panic("freeing free block");
    80003f88:	00005517          	auipc	a0,0x5
    80003f8c:	79850513          	addi	a0,a0,1944 # 80009720 <syscalls+0xf8>
    80003f90:	ffffc097          	auipc	ra,0xffffc
    80003f94:	5ae080e7          	jalr	1454(ra) # 8000053e <panic>

0000000080003f98 <balloc>:
{
    80003f98:	711d                	addi	sp,sp,-96
    80003f9a:	ec86                	sd	ra,88(sp)
    80003f9c:	e8a2                	sd	s0,80(sp)
    80003f9e:	e4a6                	sd	s1,72(sp)
    80003fa0:	e0ca                	sd	s2,64(sp)
    80003fa2:	fc4e                	sd	s3,56(sp)
    80003fa4:	f852                	sd	s4,48(sp)
    80003fa6:	f456                	sd	s5,40(sp)
    80003fa8:	f05a                	sd	s6,32(sp)
    80003faa:	ec5e                	sd	s7,24(sp)
    80003fac:	e862                	sd	s8,16(sp)
    80003fae:	e466                	sd	s9,8(sp)
    80003fb0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003fb2:	0001d797          	auipc	a5,0x1d
    80003fb6:	10a7a783          	lw	a5,266(a5) # 800210bc <sb+0x4>
    80003fba:	cbd1                	beqz	a5,8000404e <balloc+0xb6>
    80003fbc:	8baa                	mv	s7,a0
    80003fbe:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003fc0:	0001db17          	auipc	s6,0x1d
    80003fc4:	0f8b0b13          	addi	s6,s6,248 # 800210b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003fc8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003fca:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003fcc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003fce:	6c89                	lui	s9,0x2
    80003fd0:	a831                	j	80003fec <balloc+0x54>
    brelse(bp);
    80003fd2:	854a                	mv	a0,s2
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	e32080e7          	jalr	-462(ra) # 80003e06 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003fdc:	015c87bb          	addw	a5,s9,s5
    80003fe0:	00078a9b          	sext.w	s5,a5
    80003fe4:	004b2703          	lw	a4,4(s6)
    80003fe8:	06eaf363          	bgeu	s5,a4,8000404e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003fec:	41fad79b          	sraiw	a5,s5,0x1f
    80003ff0:	0137d79b          	srliw	a5,a5,0x13
    80003ff4:	015787bb          	addw	a5,a5,s5
    80003ff8:	40d7d79b          	sraiw	a5,a5,0xd
    80003ffc:	01cb2583          	lw	a1,28(s6)
    80004000:	9dbd                	addw	a1,a1,a5
    80004002:	855e                	mv	a0,s7
    80004004:	00000097          	auipc	ra,0x0
    80004008:	cd2080e7          	jalr	-814(ra) # 80003cd6 <bread>
    8000400c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000400e:	004b2503          	lw	a0,4(s6)
    80004012:	000a849b          	sext.w	s1,s5
    80004016:	8662                	mv	a2,s8
    80004018:	faa4fde3          	bgeu	s1,a0,80003fd2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000401c:	41f6579b          	sraiw	a5,a2,0x1f
    80004020:	01d7d69b          	srliw	a3,a5,0x1d
    80004024:	00c6873b          	addw	a4,a3,a2
    80004028:	00777793          	andi	a5,a4,7
    8000402c:	9f95                	subw	a5,a5,a3
    8000402e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004032:	4037571b          	sraiw	a4,a4,0x3
    80004036:	00e906b3          	add	a3,s2,a4
    8000403a:	0586c683          	lbu	a3,88(a3)
    8000403e:	00d7f5b3          	and	a1,a5,a3
    80004042:	cd91                	beqz	a1,8000405e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004044:	2605                	addiw	a2,a2,1
    80004046:	2485                	addiw	s1,s1,1
    80004048:	fd4618e3          	bne	a2,s4,80004018 <balloc+0x80>
    8000404c:	b759                	j	80003fd2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000404e:	00005517          	auipc	a0,0x5
    80004052:	6ea50513          	addi	a0,a0,1770 # 80009738 <syscalls+0x110>
    80004056:	ffffc097          	auipc	ra,0xffffc
    8000405a:	4e8080e7          	jalr	1256(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000405e:	974a                	add	a4,a4,s2
    80004060:	8fd5                	or	a5,a5,a3
    80004062:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80004066:	854a                	mv	a0,s2
    80004068:	00001097          	auipc	ra,0x1
    8000406c:	01a080e7          	jalr	26(ra) # 80005082 <log_write>
        brelse(bp);
    80004070:	854a                	mv	a0,s2
    80004072:	00000097          	auipc	ra,0x0
    80004076:	d94080e7          	jalr	-620(ra) # 80003e06 <brelse>
  bp = bread(dev, bno);
    8000407a:	85a6                	mv	a1,s1
    8000407c:	855e                	mv	a0,s7
    8000407e:	00000097          	auipc	ra,0x0
    80004082:	c58080e7          	jalr	-936(ra) # 80003cd6 <bread>
    80004086:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80004088:	40000613          	li	a2,1024
    8000408c:	4581                	li	a1,0
    8000408e:	05850513          	addi	a0,a0,88
    80004092:	ffffd097          	auipc	ra,0xffffd
    80004096:	c5c080e7          	jalr	-932(ra) # 80000cee <memset>
  log_write(bp);
    8000409a:	854a                	mv	a0,s2
    8000409c:	00001097          	auipc	ra,0x1
    800040a0:	fe6080e7          	jalr	-26(ra) # 80005082 <log_write>
  brelse(bp);
    800040a4:	854a                	mv	a0,s2
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	d60080e7          	jalr	-672(ra) # 80003e06 <brelse>
}
    800040ae:	8526                	mv	a0,s1
    800040b0:	60e6                	ld	ra,88(sp)
    800040b2:	6446                	ld	s0,80(sp)
    800040b4:	64a6                	ld	s1,72(sp)
    800040b6:	6906                	ld	s2,64(sp)
    800040b8:	79e2                	ld	s3,56(sp)
    800040ba:	7a42                	ld	s4,48(sp)
    800040bc:	7aa2                	ld	s5,40(sp)
    800040be:	7b02                	ld	s6,32(sp)
    800040c0:	6be2                	ld	s7,24(sp)
    800040c2:	6c42                	ld	s8,16(sp)
    800040c4:	6ca2                	ld	s9,8(sp)
    800040c6:	6125                	addi	sp,sp,96
    800040c8:	8082                	ret

00000000800040ca <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800040ca:	7179                	addi	sp,sp,-48
    800040cc:	f406                	sd	ra,40(sp)
    800040ce:	f022                	sd	s0,32(sp)
    800040d0:	ec26                	sd	s1,24(sp)
    800040d2:	e84a                	sd	s2,16(sp)
    800040d4:	e44e                	sd	s3,8(sp)
    800040d6:	e052                	sd	s4,0(sp)
    800040d8:	1800                	addi	s0,sp,48
    800040da:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800040dc:	47ad                	li	a5,11
    800040de:	04b7fe63          	bgeu	a5,a1,8000413a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800040e2:	ff45849b          	addiw	s1,a1,-12
    800040e6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800040ea:	0ff00793          	li	a5,255
    800040ee:	0ae7e363          	bltu	a5,a4,80004194 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800040f2:	08052583          	lw	a1,128(a0)
    800040f6:	c5ad                	beqz	a1,80004160 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800040f8:	00092503          	lw	a0,0(s2)
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	bda080e7          	jalr	-1062(ra) # 80003cd6 <bread>
    80004104:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80004106:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000410a:	02049593          	slli	a1,s1,0x20
    8000410e:	9181                	srli	a1,a1,0x20
    80004110:	058a                	slli	a1,a1,0x2
    80004112:	00b784b3          	add	s1,a5,a1
    80004116:	0004a983          	lw	s3,0(s1)
    8000411a:	04098d63          	beqz	s3,80004174 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000411e:	8552                	mv	a0,s4
    80004120:	00000097          	auipc	ra,0x0
    80004124:	ce6080e7          	jalr	-794(ra) # 80003e06 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004128:	854e                	mv	a0,s3
    8000412a:	70a2                	ld	ra,40(sp)
    8000412c:	7402                	ld	s0,32(sp)
    8000412e:	64e2                	ld	s1,24(sp)
    80004130:	6942                	ld	s2,16(sp)
    80004132:	69a2                	ld	s3,8(sp)
    80004134:	6a02                	ld	s4,0(sp)
    80004136:	6145                	addi	sp,sp,48
    80004138:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000413a:	02059493          	slli	s1,a1,0x20
    8000413e:	9081                	srli	s1,s1,0x20
    80004140:	048a                	slli	s1,s1,0x2
    80004142:	94aa                	add	s1,s1,a0
    80004144:	0504a983          	lw	s3,80(s1)
    80004148:	fe0990e3          	bnez	s3,80004128 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000414c:	4108                	lw	a0,0(a0)
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	e4a080e7          	jalr	-438(ra) # 80003f98 <balloc>
    80004156:	0005099b          	sext.w	s3,a0
    8000415a:	0534a823          	sw	s3,80(s1)
    8000415e:	b7e9                	j	80004128 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80004160:	4108                	lw	a0,0(a0)
    80004162:	00000097          	auipc	ra,0x0
    80004166:	e36080e7          	jalr	-458(ra) # 80003f98 <balloc>
    8000416a:	0005059b          	sext.w	a1,a0
    8000416e:	08b92023          	sw	a1,128(s2)
    80004172:	b759                	j	800040f8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80004174:	00092503          	lw	a0,0(s2)
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	e20080e7          	jalr	-480(ra) # 80003f98 <balloc>
    80004180:	0005099b          	sext.w	s3,a0
    80004184:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80004188:	8552                	mv	a0,s4
    8000418a:	00001097          	auipc	ra,0x1
    8000418e:	ef8080e7          	jalr	-264(ra) # 80005082 <log_write>
    80004192:	b771                	j	8000411e <bmap+0x54>
  panic("bmap: out of range");
    80004194:	00005517          	auipc	a0,0x5
    80004198:	5bc50513          	addi	a0,a0,1468 # 80009750 <syscalls+0x128>
    8000419c:	ffffc097          	auipc	ra,0xffffc
    800041a0:	3a2080e7          	jalr	930(ra) # 8000053e <panic>

00000000800041a4 <iget>:
{
    800041a4:	7179                	addi	sp,sp,-48
    800041a6:	f406                	sd	ra,40(sp)
    800041a8:	f022                	sd	s0,32(sp)
    800041aa:	ec26                	sd	s1,24(sp)
    800041ac:	e84a                	sd	s2,16(sp)
    800041ae:	e44e                	sd	s3,8(sp)
    800041b0:	e052                	sd	s4,0(sp)
    800041b2:	1800                	addi	s0,sp,48
    800041b4:	89aa                	mv	s3,a0
    800041b6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800041b8:	0001d517          	auipc	a0,0x1d
    800041bc:	f2050513          	addi	a0,a0,-224 # 800210d8 <itable>
    800041c0:	ffffd097          	auipc	ra,0xffffd
    800041c4:	a2c080e7          	jalr	-1492(ra) # 80000bec <acquire>
  empty = 0;
    800041c8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800041ca:	0001d497          	auipc	s1,0x1d
    800041ce:	f2648493          	addi	s1,s1,-218 # 800210f0 <itable+0x18>
    800041d2:	0001f697          	auipc	a3,0x1f
    800041d6:	9ae68693          	addi	a3,a3,-1618 # 80022b80 <log>
    800041da:	a039                	j	800041e8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800041dc:	02090b63          	beqz	s2,80004212 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800041e0:	08848493          	addi	s1,s1,136
    800041e4:	02d48a63          	beq	s1,a3,80004218 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800041e8:	449c                	lw	a5,8(s1)
    800041ea:	fef059e3          	blez	a5,800041dc <iget+0x38>
    800041ee:	4098                	lw	a4,0(s1)
    800041f0:	ff3716e3          	bne	a4,s3,800041dc <iget+0x38>
    800041f4:	40d8                	lw	a4,4(s1)
    800041f6:	ff4713e3          	bne	a4,s4,800041dc <iget+0x38>
      ip->ref++;
    800041fa:	2785                	addiw	a5,a5,1
    800041fc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800041fe:	0001d517          	auipc	a0,0x1d
    80004202:	eda50513          	addi	a0,a0,-294 # 800210d8 <itable>
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	aa0080e7          	jalr	-1376(ra) # 80000ca6 <release>
      return ip;
    8000420e:	8926                	mv	s2,s1
    80004210:	a03d                	j	8000423e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004212:	f7f9                	bnez	a5,800041e0 <iget+0x3c>
    80004214:	8926                	mv	s2,s1
    80004216:	b7e9                	j	800041e0 <iget+0x3c>
  if(empty == 0)
    80004218:	02090c63          	beqz	s2,80004250 <iget+0xac>
  ip->dev = dev;
    8000421c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004220:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004224:	4785                	li	a5,1
    80004226:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000422a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000422e:	0001d517          	auipc	a0,0x1d
    80004232:	eaa50513          	addi	a0,a0,-342 # 800210d8 <itable>
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	a70080e7          	jalr	-1424(ra) # 80000ca6 <release>
}
    8000423e:	854a                	mv	a0,s2
    80004240:	70a2                	ld	ra,40(sp)
    80004242:	7402                	ld	s0,32(sp)
    80004244:	64e2                	ld	s1,24(sp)
    80004246:	6942                	ld	s2,16(sp)
    80004248:	69a2                	ld	s3,8(sp)
    8000424a:	6a02                	ld	s4,0(sp)
    8000424c:	6145                	addi	sp,sp,48
    8000424e:	8082                	ret
    panic("iget: no inodes");
    80004250:	00005517          	auipc	a0,0x5
    80004254:	51850513          	addi	a0,a0,1304 # 80009768 <syscalls+0x140>
    80004258:	ffffc097          	auipc	ra,0xffffc
    8000425c:	2e6080e7          	jalr	742(ra) # 8000053e <panic>

0000000080004260 <fsinit>:
fsinit(int dev) {
    80004260:	7179                	addi	sp,sp,-48
    80004262:	f406                	sd	ra,40(sp)
    80004264:	f022                	sd	s0,32(sp)
    80004266:	ec26                	sd	s1,24(sp)
    80004268:	e84a                	sd	s2,16(sp)
    8000426a:	e44e                	sd	s3,8(sp)
    8000426c:	1800                	addi	s0,sp,48
    8000426e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004270:	4585                	li	a1,1
    80004272:	00000097          	auipc	ra,0x0
    80004276:	a64080e7          	jalr	-1436(ra) # 80003cd6 <bread>
    8000427a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000427c:	0001d997          	auipc	s3,0x1d
    80004280:	e3c98993          	addi	s3,s3,-452 # 800210b8 <sb>
    80004284:	02000613          	li	a2,32
    80004288:	05850593          	addi	a1,a0,88
    8000428c:	854e                	mv	a0,s3
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	ac0080e7          	jalr	-1344(ra) # 80000d4e <memmove>
  brelse(bp);
    80004296:	8526                	mv	a0,s1
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	b6e080e7          	jalr	-1170(ra) # 80003e06 <brelse>
  if(sb.magic != FSMAGIC)
    800042a0:	0009a703          	lw	a4,0(s3)
    800042a4:	102037b7          	lui	a5,0x10203
    800042a8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800042ac:	02f71263          	bne	a4,a5,800042d0 <fsinit+0x70>
  initlog(dev, &sb);
    800042b0:	0001d597          	auipc	a1,0x1d
    800042b4:	e0858593          	addi	a1,a1,-504 # 800210b8 <sb>
    800042b8:	854a                	mv	a0,s2
    800042ba:	00001097          	auipc	ra,0x1
    800042be:	b4c080e7          	jalr	-1204(ra) # 80004e06 <initlog>
}
    800042c2:	70a2                	ld	ra,40(sp)
    800042c4:	7402                	ld	s0,32(sp)
    800042c6:	64e2                	ld	s1,24(sp)
    800042c8:	6942                	ld	s2,16(sp)
    800042ca:	69a2                	ld	s3,8(sp)
    800042cc:	6145                	addi	sp,sp,48
    800042ce:	8082                	ret
    panic("invalid file system");
    800042d0:	00005517          	auipc	a0,0x5
    800042d4:	4a850513          	addi	a0,a0,1192 # 80009778 <syscalls+0x150>
    800042d8:	ffffc097          	auipc	ra,0xffffc
    800042dc:	266080e7          	jalr	614(ra) # 8000053e <panic>

00000000800042e0 <iinit>:
{
    800042e0:	7179                	addi	sp,sp,-48
    800042e2:	f406                	sd	ra,40(sp)
    800042e4:	f022                	sd	s0,32(sp)
    800042e6:	ec26                	sd	s1,24(sp)
    800042e8:	e84a                	sd	s2,16(sp)
    800042ea:	e44e                	sd	s3,8(sp)
    800042ec:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800042ee:	00005597          	auipc	a1,0x5
    800042f2:	4a258593          	addi	a1,a1,1186 # 80009790 <syscalls+0x168>
    800042f6:	0001d517          	auipc	a0,0x1d
    800042fa:	de250513          	addi	a0,a0,-542 # 800210d8 <itable>
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	856080e7          	jalr	-1962(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004306:	0001d497          	auipc	s1,0x1d
    8000430a:	dfa48493          	addi	s1,s1,-518 # 80021100 <itable+0x28>
    8000430e:	0001f997          	auipc	s3,0x1f
    80004312:	88298993          	addi	s3,s3,-1918 # 80022b90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004316:	00005917          	auipc	s2,0x5
    8000431a:	48290913          	addi	s2,s2,1154 # 80009798 <syscalls+0x170>
    8000431e:	85ca                	mv	a1,s2
    80004320:	8526                	mv	a0,s1
    80004322:	00001097          	auipc	ra,0x1
    80004326:	e46080e7          	jalr	-442(ra) # 80005168 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000432a:	08848493          	addi	s1,s1,136
    8000432e:	ff3498e3          	bne	s1,s3,8000431e <iinit+0x3e>
}
    80004332:	70a2                	ld	ra,40(sp)
    80004334:	7402                	ld	s0,32(sp)
    80004336:	64e2                	ld	s1,24(sp)
    80004338:	6942                	ld	s2,16(sp)
    8000433a:	69a2                	ld	s3,8(sp)
    8000433c:	6145                	addi	sp,sp,48
    8000433e:	8082                	ret

0000000080004340 <ialloc>:
{
    80004340:	715d                	addi	sp,sp,-80
    80004342:	e486                	sd	ra,72(sp)
    80004344:	e0a2                	sd	s0,64(sp)
    80004346:	fc26                	sd	s1,56(sp)
    80004348:	f84a                	sd	s2,48(sp)
    8000434a:	f44e                	sd	s3,40(sp)
    8000434c:	f052                	sd	s4,32(sp)
    8000434e:	ec56                	sd	s5,24(sp)
    80004350:	e85a                	sd	s6,16(sp)
    80004352:	e45e                	sd	s7,8(sp)
    80004354:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004356:	0001d717          	auipc	a4,0x1d
    8000435a:	d6e72703          	lw	a4,-658(a4) # 800210c4 <sb+0xc>
    8000435e:	4785                	li	a5,1
    80004360:	04e7fa63          	bgeu	a5,a4,800043b4 <ialloc+0x74>
    80004364:	8aaa                	mv	s5,a0
    80004366:	8bae                	mv	s7,a1
    80004368:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000436a:	0001da17          	auipc	s4,0x1d
    8000436e:	d4ea0a13          	addi	s4,s4,-690 # 800210b8 <sb>
    80004372:	00048b1b          	sext.w	s6,s1
    80004376:	0044d593          	srli	a1,s1,0x4
    8000437a:	018a2783          	lw	a5,24(s4)
    8000437e:	9dbd                	addw	a1,a1,a5
    80004380:	8556                	mv	a0,s5
    80004382:	00000097          	auipc	ra,0x0
    80004386:	954080e7          	jalr	-1708(ra) # 80003cd6 <bread>
    8000438a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000438c:	05850993          	addi	s3,a0,88
    80004390:	00f4f793          	andi	a5,s1,15
    80004394:	079a                	slli	a5,a5,0x6
    80004396:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004398:	00099783          	lh	a5,0(s3)
    8000439c:	c785                	beqz	a5,800043c4 <ialloc+0x84>
    brelse(bp);
    8000439e:	00000097          	auipc	ra,0x0
    800043a2:	a68080e7          	jalr	-1432(ra) # 80003e06 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800043a6:	0485                	addi	s1,s1,1
    800043a8:	00ca2703          	lw	a4,12(s4)
    800043ac:	0004879b          	sext.w	a5,s1
    800043b0:	fce7e1e3          	bltu	a5,a4,80004372 <ialloc+0x32>
  panic("ialloc: no inodes");
    800043b4:	00005517          	auipc	a0,0x5
    800043b8:	3ec50513          	addi	a0,a0,1004 # 800097a0 <syscalls+0x178>
    800043bc:	ffffc097          	auipc	ra,0xffffc
    800043c0:	182080e7          	jalr	386(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800043c4:	04000613          	li	a2,64
    800043c8:	4581                	li	a1,0
    800043ca:	854e                	mv	a0,s3
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	922080e7          	jalr	-1758(ra) # 80000cee <memset>
      dip->type = type;
    800043d4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800043d8:	854a                	mv	a0,s2
    800043da:	00001097          	auipc	ra,0x1
    800043de:	ca8080e7          	jalr	-856(ra) # 80005082 <log_write>
      brelse(bp);
    800043e2:	854a                	mv	a0,s2
    800043e4:	00000097          	auipc	ra,0x0
    800043e8:	a22080e7          	jalr	-1502(ra) # 80003e06 <brelse>
      return iget(dev, inum);
    800043ec:	85da                	mv	a1,s6
    800043ee:	8556                	mv	a0,s5
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	db4080e7          	jalr	-588(ra) # 800041a4 <iget>
}
    800043f8:	60a6                	ld	ra,72(sp)
    800043fa:	6406                	ld	s0,64(sp)
    800043fc:	74e2                	ld	s1,56(sp)
    800043fe:	7942                	ld	s2,48(sp)
    80004400:	79a2                	ld	s3,40(sp)
    80004402:	7a02                	ld	s4,32(sp)
    80004404:	6ae2                	ld	s5,24(sp)
    80004406:	6b42                	ld	s6,16(sp)
    80004408:	6ba2                	ld	s7,8(sp)
    8000440a:	6161                	addi	sp,sp,80
    8000440c:	8082                	ret

000000008000440e <iupdate>:
{
    8000440e:	1101                	addi	sp,sp,-32
    80004410:	ec06                	sd	ra,24(sp)
    80004412:	e822                	sd	s0,16(sp)
    80004414:	e426                	sd	s1,8(sp)
    80004416:	e04a                	sd	s2,0(sp)
    80004418:	1000                	addi	s0,sp,32
    8000441a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000441c:	415c                	lw	a5,4(a0)
    8000441e:	0047d79b          	srliw	a5,a5,0x4
    80004422:	0001d597          	auipc	a1,0x1d
    80004426:	cae5a583          	lw	a1,-850(a1) # 800210d0 <sb+0x18>
    8000442a:	9dbd                	addw	a1,a1,a5
    8000442c:	4108                	lw	a0,0(a0)
    8000442e:	00000097          	auipc	ra,0x0
    80004432:	8a8080e7          	jalr	-1880(ra) # 80003cd6 <bread>
    80004436:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004438:	05850793          	addi	a5,a0,88
    8000443c:	40c8                	lw	a0,4(s1)
    8000443e:	893d                	andi	a0,a0,15
    80004440:	051a                	slli	a0,a0,0x6
    80004442:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004444:	04449703          	lh	a4,68(s1)
    80004448:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000444c:	04649703          	lh	a4,70(s1)
    80004450:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004454:	04849703          	lh	a4,72(s1)
    80004458:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000445c:	04a49703          	lh	a4,74(s1)
    80004460:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004464:	44f8                	lw	a4,76(s1)
    80004466:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004468:	03400613          	li	a2,52
    8000446c:	05048593          	addi	a1,s1,80
    80004470:	0531                	addi	a0,a0,12
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	8dc080e7          	jalr	-1828(ra) # 80000d4e <memmove>
  log_write(bp);
    8000447a:	854a                	mv	a0,s2
    8000447c:	00001097          	auipc	ra,0x1
    80004480:	c06080e7          	jalr	-1018(ra) # 80005082 <log_write>
  brelse(bp);
    80004484:	854a                	mv	a0,s2
    80004486:	00000097          	auipc	ra,0x0
    8000448a:	980080e7          	jalr	-1664(ra) # 80003e06 <brelse>
}
    8000448e:	60e2                	ld	ra,24(sp)
    80004490:	6442                	ld	s0,16(sp)
    80004492:	64a2                	ld	s1,8(sp)
    80004494:	6902                	ld	s2,0(sp)
    80004496:	6105                	addi	sp,sp,32
    80004498:	8082                	ret

000000008000449a <idup>:
{
    8000449a:	1101                	addi	sp,sp,-32
    8000449c:	ec06                	sd	ra,24(sp)
    8000449e:	e822                	sd	s0,16(sp)
    800044a0:	e426                	sd	s1,8(sp)
    800044a2:	1000                	addi	s0,sp,32
    800044a4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800044a6:	0001d517          	auipc	a0,0x1d
    800044aa:	c3250513          	addi	a0,a0,-974 # 800210d8 <itable>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	73e080e7          	jalr	1854(ra) # 80000bec <acquire>
  ip->ref++;
    800044b6:	449c                	lw	a5,8(s1)
    800044b8:	2785                	addiw	a5,a5,1
    800044ba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800044bc:	0001d517          	auipc	a0,0x1d
    800044c0:	c1c50513          	addi	a0,a0,-996 # 800210d8 <itable>
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	7e2080e7          	jalr	2018(ra) # 80000ca6 <release>
}
    800044cc:	8526                	mv	a0,s1
    800044ce:	60e2                	ld	ra,24(sp)
    800044d0:	6442                	ld	s0,16(sp)
    800044d2:	64a2                	ld	s1,8(sp)
    800044d4:	6105                	addi	sp,sp,32
    800044d6:	8082                	ret

00000000800044d8 <ilock>:
{
    800044d8:	1101                	addi	sp,sp,-32
    800044da:	ec06                	sd	ra,24(sp)
    800044dc:	e822                	sd	s0,16(sp)
    800044de:	e426                	sd	s1,8(sp)
    800044e0:	e04a                	sd	s2,0(sp)
    800044e2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800044e4:	c115                	beqz	a0,80004508 <ilock+0x30>
    800044e6:	84aa                	mv	s1,a0
    800044e8:	451c                	lw	a5,8(a0)
    800044ea:	00f05f63          	blez	a5,80004508 <ilock+0x30>
  acquiresleep(&ip->lock);
    800044ee:	0541                	addi	a0,a0,16
    800044f0:	00001097          	auipc	ra,0x1
    800044f4:	cb2080e7          	jalr	-846(ra) # 800051a2 <acquiresleep>
  if(ip->valid == 0){
    800044f8:	40bc                	lw	a5,64(s1)
    800044fa:	cf99                	beqz	a5,80004518 <ilock+0x40>
}
    800044fc:	60e2                	ld	ra,24(sp)
    800044fe:	6442                	ld	s0,16(sp)
    80004500:	64a2                	ld	s1,8(sp)
    80004502:	6902                	ld	s2,0(sp)
    80004504:	6105                	addi	sp,sp,32
    80004506:	8082                	ret
    panic("ilock");
    80004508:	00005517          	auipc	a0,0x5
    8000450c:	2b050513          	addi	a0,a0,688 # 800097b8 <syscalls+0x190>
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	02e080e7          	jalr	46(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004518:	40dc                	lw	a5,4(s1)
    8000451a:	0047d79b          	srliw	a5,a5,0x4
    8000451e:	0001d597          	auipc	a1,0x1d
    80004522:	bb25a583          	lw	a1,-1102(a1) # 800210d0 <sb+0x18>
    80004526:	9dbd                	addw	a1,a1,a5
    80004528:	4088                	lw	a0,0(s1)
    8000452a:	fffff097          	auipc	ra,0xfffff
    8000452e:	7ac080e7          	jalr	1964(ra) # 80003cd6 <bread>
    80004532:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004534:	05850593          	addi	a1,a0,88
    80004538:	40dc                	lw	a5,4(s1)
    8000453a:	8bbd                	andi	a5,a5,15
    8000453c:	079a                	slli	a5,a5,0x6
    8000453e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004540:	00059783          	lh	a5,0(a1)
    80004544:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004548:	00259783          	lh	a5,2(a1)
    8000454c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004550:	00459783          	lh	a5,4(a1)
    80004554:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004558:	00659783          	lh	a5,6(a1)
    8000455c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004560:	459c                	lw	a5,8(a1)
    80004562:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004564:	03400613          	li	a2,52
    80004568:	05b1                	addi	a1,a1,12
    8000456a:	05048513          	addi	a0,s1,80
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	7e0080e7          	jalr	2016(ra) # 80000d4e <memmove>
    brelse(bp);
    80004576:	854a                	mv	a0,s2
    80004578:	00000097          	auipc	ra,0x0
    8000457c:	88e080e7          	jalr	-1906(ra) # 80003e06 <brelse>
    ip->valid = 1;
    80004580:	4785                	li	a5,1
    80004582:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004584:	04449783          	lh	a5,68(s1)
    80004588:	fbb5                	bnez	a5,800044fc <ilock+0x24>
      panic("ilock: no type");
    8000458a:	00005517          	auipc	a0,0x5
    8000458e:	23650513          	addi	a0,a0,566 # 800097c0 <syscalls+0x198>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	fac080e7          	jalr	-84(ra) # 8000053e <panic>

000000008000459a <iunlock>:
{
    8000459a:	1101                	addi	sp,sp,-32
    8000459c:	ec06                	sd	ra,24(sp)
    8000459e:	e822                	sd	s0,16(sp)
    800045a0:	e426                	sd	s1,8(sp)
    800045a2:	e04a                	sd	s2,0(sp)
    800045a4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800045a6:	c905                	beqz	a0,800045d6 <iunlock+0x3c>
    800045a8:	84aa                	mv	s1,a0
    800045aa:	01050913          	addi	s2,a0,16
    800045ae:	854a                	mv	a0,s2
    800045b0:	00001097          	auipc	ra,0x1
    800045b4:	c8c080e7          	jalr	-884(ra) # 8000523c <holdingsleep>
    800045b8:	cd19                	beqz	a0,800045d6 <iunlock+0x3c>
    800045ba:	449c                	lw	a5,8(s1)
    800045bc:	00f05d63          	blez	a5,800045d6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800045c0:	854a                	mv	a0,s2
    800045c2:	00001097          	auipc	ra,0x1
    800045c6:	c36080e7          	jalr	-970(ra) # 800051f8 <releasesleep>
}
    800045ca:	60e2                	ld	ra,24(sp)
    800045cc:	6442                	ld	s0,16(sp)
    800045ce:	64a2                	ld	s1,8(sp)
    800045d0:	6902                	ld	s2,0(sp)
    800045d2:	6105                	addi	sp,sp,32
    800045d4:	8082                	ret
    panic("iunlock");
    800045d6:	00005517          	auipc	a0,0x5
    800045da:	1fa50513          	addi	a0,a0,506 # 800097d0 <syscalls+0x1a8>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	f60080e7          	jalr	-160(ra) # 8000053e <panic>

00000000800045e6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800045e6:	7179                	addi	sp,sp,-48
    800045e8:	f406                	sd	ra,40(sp)
    800045ea:	f022                	sd	s0,32(sp)
    800045ec:	ec26                	sd	s1,24(sp)
    800045ee:	e84a                	sd	s2,16(sp)
    800045f0:	e44e                	sd	s3,8(sp)
    800045f2:	e052                	sd	s4,0(sp)
    800045f4:	1800                	addi	s0,sp,48
    800045f6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800045f8:	05050493          	addi	s1,a0,80
    800045fc:	08050913          	addi	s2,a0,128
    80004600:	a021                	j	80004608 <itrunc+0x22>
    80004602:	0491                	addi	s1,s1,4
    80004604:	01248d63          	beq	s1,s2,8000461e <itrunc+0x38>
    if(ip->addrs[i]){
    80004608:	408c                	lw	a1,0(s1)
    8000460a:	dde5                	beqz	a1,80004602 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000460c:	0009a503          	lw	a0,0(s3)
    80004610:	00000097          	auipc	ra,0x0
    80004614:	90c080e7          	jalr	-1780(ra) # 80003f1c <bfree>
      ip->addrs[i] = 0;
    80004618:	0004a023          	sw	zero,0(s1)
    8000461c:	b7dd                	j	80004602 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000461e:	0809a583          	lw	a1,128(s3)
    80004622:	e185                	bnez	a1,80004642 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004624:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004628:	854e                	mv	a0,s3
    8000462a:	00000097          	auipc	ra,0x0
    8000462e:	de4080e7          	jalr	-540(ra) # 8000440e <iupdate>
}
    80004632:	70a2                	ld	ra,40(sp)
    80004634:	7402                	ld	s0,32(sp)
    80004636:	64e2                	ld	s1,24(sp)
    80004638:	6942                	ld	s2,16(sp)
    8000463a:	69a2                	ld	s3,8(sp)
    8000463c:	6a02                	ld	s4,0(sp)
    8000463e:	6145                	addi	sp,sp,48
    80004640:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004642:	0009a503          	lw	a0,0(s3)
    80004646:	fffff097          	auipc	ra,0xfffff
    8000464a:	690080e7          	jalr	1680(ra) # 80003cd6 <bread>
    8000464e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004650:	05850493          	addi	s1,a0,88
    80004654:	45850913          	addi	s2,a0,1112
    80004658:	a811                	j	8000466c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000465a:	0009a503          	lw	a0,0(s3)
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	8be080e7          	jalr	-1858(ra) # 80003f1c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004666:	0491                	addi	s1,s1,4
    80004668:	01248563          	beq	s1,s2,80004672 <itrunc+0x8c>
      if(a[j])
    8000466c:	408c                	lw	a1,0(s1)
    8000466e:	dde5                	beqz	a1,80004666 <itrunc+0x80>
    80004670:	b7ed                	j	8000465a <itrunc+0x74>
    brelse(bp);
    80004672:	8552                	mv	a0,s4
    80004674:	fffff097          	auipc	ra,0xfffff
    80004678:	792080e7          	jalr	1938(ra) # 80003e06 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000467c:	0809a583          	lw	a1,128(s3)
    80004680:	0009a503          	lw	a0,0(s3)
    80004684:	00000097          	auipc	ra,0x0
    80004688:	898080e7          	jalr	-1896(ra) # 80003f1c <bfree>
    ip->addrs[NDIRECT] = 0;
    8000468c:	0809a023          	sw	zero,128(s3)
    80004690:	bf51                	j	80004624 <itrunc+0x3e>

0000000080004692 <iput>:
{
    80004692:	1101                	addi	sp,sp,-32
    80004694:	ec06                	sd	ra,24(sp)
    80004696:	e822                	sd	s0,16(sp)
    80004698:	e426                	sd	s1,8(sp)
    8000469a:	e04a                	sd	s2,0(sp)
    8000469c:	1000                	addi	s0,sp,32
    8000469e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800046a0:	0001d517          	auipc	a0,0x1d
    800046a4:	a3850513          	addi	a0,a0,-1480 # 800210d8 <itable>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	544080e7          	jalr	1348(ra) # 80000bec <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800046b0:	4498                	lw	a4,8(s1)
    800046b2:	4785                	li	a5,1
    800046b4:	02f70363          	beq	a4,a5,800046da <iput+0x48>
  ip->ref--;
    800046b8:	449c                	lw	a5,8(s1)
    800046ba:	37fd                	addiw	a5,a5,-1
    800046bc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800046be:	0001d517          	auipc	a0,0x1d
    800046c2:	a1a50513          	addi	a0,a0,-1510 # 800210d8 <itable>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	5e0080e7          	jalr	1504(ra) # 80000ca6 <release>
}
    800046ce:	60e2                	ld	ra,24(sp)
    800046d0:	6442                	ld	s0,16(sp)
    800046d2:	64a2                	ld	s1,8(sp)
    800046d4:	6902                	ld	s2,0(sp)
    800046d6:	6105                	addi	sp,sp,32
    800046d8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800046da:	40bc                	lw	a5,64(s1)
    800046dc:	dff1                	beqz	a5,800046b8 <iput+0x26>
    800046de:	04a49783          	lh	a5,74(s1)
    800046e2:	fbf9                	bnez	a5,800046b8 <iput+0x26>
    acquiresleep(&ip->lock);
    800046e4:	01048913          	addi	s2,s1,16
    800046e8:	854a                	mv	a0,s2
    800046ea:	00001097          	auipc	ra,0x1
    800046ee:	ab8080e7          	jalr	-1352(ra) # 800051a2 <acquiresleep>
    release(&itable.lock);
    800046f2:	0001d517          	auipc	a0,0x1d
    800046f6:	9e650513          	addi	a0,a0,-1562 # 800210d8 <itable>
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	5ac080e7          	jalr	1452(ra) # 80000ca6 <release>
    itrunc(ip);
    80004702:	8526                	mv	a0,s1
    80004704:	00000097          	auipc	ra,0x0
    80004708:	ee2080e7          	jalr	-286(ra) # 800045e6 <itrunc>
    ip->type = 0;
    8000470c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004710:	8526                	mv	a0,s1
    80004712:	00000097          	auipc	ra,0x0
    80004716:	cfc080e7          	jalr	-772(ra) # 8000440e <iupdate>
    ip->valid = 0;
    8000471a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000471e:	854a                	mv	a0,s2
    80004720:	00001097          	auipc	ra,0x1
    80004724:	ad8080e7          	jalr	-1320(ra) # 800051f8 <releasesleep>
    acquire(&itable.lock);
    80004728:	0001d517          	auipc	a0,0x1d
    8000472c:	9b050513          	addi	a0,a0,-1616 # 800210d8 <itable>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	4bc080e7          	jalr	1212(ra) # 80000bec <acquire>
    80004738:	b741                	j	800046b8 <iput+0x26>

000000008000473a <iunlockput>:
{
    8000473a:	1101                	addi	sp,sp,-32
    8000473c:	ec06                	sd	ra,24(sp)
    8000473e:	e822                	sd	s0,16(sp)
    80004740:	e426                	sd	s1,8(sp)
    80004742:	1000                	addi	s0,sp,32
    80004744:	84aa                	mv	s1,a0
  iunlock(ip);
    80004746:	00000097          	auipc	ra,0x0
    8000474a:	e54080e7          	jalr	-428(ra) # 8000459a <iunlock>
  iput(ip);
    8000474e:	8526                	mv	a0,s1
    80004750:	00000097          	auipc	ra,0x0
    80004754:	f42080e7          	jalr	-190(ra) # 80004692 <iput>
}
    80004758:	60e2                	ld	ra,24(sp)
    8000475a:	6442                	ld	s0,16(sp)
    8000475c:	64a2                	ld	s1,8(sp)
    8000475e:	6105                	addi	sp,sp,32
    80004760:	8082                	ret

0000000080004762 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004762:	1141                	addi	sp,sp,-16
    80004764:	e422                	sd	s0,8(sp)
    80004766:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004768:	411c                	lw	a5,0(a0)
    8000476a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000476c:	415c                	lw	a5,4(a0)
    8000476e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004770:	04451783          	lh	a5,68(a0)
    80004774:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004778:	04a51783          	lh	a5,74(a0)
    8000477c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004780:	04c56783          	lwu	a5,76(a0)
    80004784:	e99c                	sd	a5,16(a1)
}
    80004786:	6422                	ld	s0,8(sp)
    80004788:	0141                	addi	sp,sp,16
    8000478a:	8082                	ret

000000008000478c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000478c:	457c                	lw	a5,76(a0)
    8000478e:	0ed7e963          	bltu	a5,a3,80004880 <readi+0xf4>
{
    80004792:	7159                	addi	sp,sp,-112
    80004794:	f486                	sd	ra,104(sp)
    80004796:	f0a2                	sd	s0,96(sp)
    80004798:	eca6                	sd	s1,88(sp)
    8000479a:	e8ca                	sd	s2,80(sp)
    8000479c:	e4ce                	sd	s3,72(sp)
    8000479e:	e0d2                	sd	s4,64(sp)
    800047a0:	fc56                	sd	s5,56(sp)
    800047a2:	f85a                	sd	s6,48(sp)
    800047a4:	f45e                	sd	s7,40(sp)
    800047a6:	f062                	sd	s8,32(sp)
    800047a8:	ec66                	sd	s9,24(sp)
    800047aa:	e86a                	sd	s10,16(sp)
    800047ac:	e46e                	sd	s11,8(sp)
    800047ae:	1880                	addi	s0,sp,112
    800047b0:	8baa                	mv	s7,a0
    800047b2:	8c2e                	mv	s8,a1
    800047b4:	8ab2                	mv	s5,a2
    800047b6:	84b6                	mv	s1,a3
    800047b8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800047ba:	9f35                	addw	a4,a4,a3
    return 0;
    800047bc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800047be:	0ad76063          	bltu	a4,a3,8000485e <readi+0xd2>
  if(off + n > ip->size)
    800047c2:	00e7f463          	bgeu	a5,a4,800047ca <readi+0x3e>
    n = ip->size - off;
    800047c6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800047ca:	0a0b0963          	beqz	s6,8000487c <readi+0xf0>
    800047ce:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800047d0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800047d4:	5cfd                	li	s9,-1
    800047d6:	a82d                	j	80004810 <readi+0x84>
    800047d8:	020a1d93          	slli	s11,s4,0x20
    800047dc:	020ddd93          	srli	s11,s11,0x20
    800047e0:	05890613          	addi	a2,s2,88
    800047e4:	86ee                	mv	a3,s11
    800047e6:	963a                	add	a2,a2,a4
    800047e8:	85d6                	mv	a1,s5
    800047ea:	8562                	mv	a0,s8
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	ae4080e7          	jalr	-1308(ra) # 800032d0 <either_copyout>
    800047f4:	05950d63          	beq	a0,s9,8000484e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800047f8:	854a                	mv	a0,s2
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	60c080e7          	jalr	1548(ra) # 80003e06 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004802:	013a09bb          	addw	s3,s4,s3
    80004806:	009a04bb          	addw	s1,s4,s1
    8000480a:	9aee                	add	s5,s5,s11
    8000480c:	0569f763          	bgeu	s3,s6,8000485a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004810:	000ba903          	lw	s2,0(s7)
    80004814:	00a4d59b          	srliw	a1,s1,0xa
    80004818:	855e                	mv	a0,s7
    8000481a:	00000097          	auipc	ra,0x0
    8000481e:	8b0080e7          	jalr	-1872(ra) # 800040ca <bmap>
    80004822:	0005059b          	sext.w	a1,a0
    80004826:	854a                	mv	a0,s2
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	4ae080e7          	jalr	1198(ra) # 80003cd6 <bread>
    80004830:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004832:	3ff4f713          	andi	a4,s1,1023
    80004836:	40ed07bb          	subw	a5,s10,a4
    8000483a:	413b06bb          	subw	a3,s6,s3
    8000483e:	8a3e                	mv	s4,a5
    80004840:	2781                	sext.w	a5,a5
    80004842:	0006861b          	sext.w	a2,a3
    80004846:	f8f679e3          	bgeu	a2,a5,800047d8 <readi+0x4c>
    8000484a:	8a36                	mv	s4,a3
    8000484c:	b771                	j	800047d8 <readi+0x4c>
      brelse(bp);
    8000484e:	854a                	mv	a0,s2
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	5b6080e7          	jalr	1462(ra) # 80003e06 <brelse>
      tot = -1;
    80004858:	59fd                	li	s3,-1
  }
  return tot;
    8000485a:	0009851b          	sext.w	a0,s3
}
    8000485e:	70a6                	ld	ra,104(sp)
    80004860:	7406                	ld	s0,96(sp)
    80004862:	64e6                	ld	s1,88(sp)
    80004864:	6946                	ld	s2,80(sp)
    80004866:	69a6                	ld	s3,72(sp)
    80004868:	6a06                	ld	s4,64(sp)
    8000486a:	7ae2                	ld	s5,56(sp)
    8000486c:	7b42                	ld	s6,48(sp)
    8000486e:	7ba2                	ld	s7,40(sp)
    80004870:	7c02                	ld	s8,32(sp)
    80004872:	6ce2                	ld	s9,24(sp)
    80004874:	6d42                	ld	s10,16(sp)
    80004876:	6da2                	ld	s11,8(sp)
    80004878:	6165                	addi	sp,sp,112
    8000487a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000487c:	89da                	mv	s3,s6
    8000487e:	bff1                	j	8000485a <readi+0xce>
    return 0;
    80004880:	4501                	li	a0,0
}
    80004882:	8082                	ret

0000000080004884 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004884:	457c                	lw	a5,76(a0)
    80004886:	10d7e863          	bltu	a5,a3,80004996 <writei+0x112>
{
    8000488a:	7159                	addi	sp,sp,-112
    8000488c:	f486                	sd	ra,104(sp)
    8000488e:	f0a2                	sd	s0,96(sp)
    80004890:	eca6                	sd	s1,88(sp)
    80004892:	e8ca                	sd	s2,80(sp)
    80004894:	e4ce                	sd	s3,72(sp)
    80004896:	e0d2                	sd	s4,64(sp)
    80004898:	fc56                	sd	s5,56(sp)
    8000489a:	f85a                	sd	s6,48(sp)
    8000489c:	f45e                	sd	s7,40(sp)
    8000489e:	f062                	sd	s8,32(sp)
    800048a0:	ec66                	sd	s9,24(sp)
    800048a2:	e86a                	sd	s10,16(sp)
    800048a4:	e46e                	sd	s11,8(sp)
    800048a6:	1880                	addi	s0,sp,112
    800048a8:	8b2a                	mv	s6,a0
    800048aa:	8c2e                	mv	s8,a1
    800048ac:	8ab2                	mv	s5,a2
    800048ae:	8936                	mv	s2,a3
    800048b0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800048b2:	00e687bb          	addw	a5,a3,a4
    800048b6:	0ed7e263          	bltu	a5,a3,8000499a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800048ba:	00043737          	lui	a4,0x43
    800048be:	0ef76063          	bltu	a4,a5,8000499e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800048c2:	0c0b8863          	beqz	s7,80004992 <writei+0x10e>
    800048c6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800048c8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800048cc:	5cfd                	li	s9,-1
    800048ce:	a091                	j	80004912 <writei+0x8e>
    800048d0:	02099d93          	slli	s11,s3,0x20
    800048d4:	020ddd93          	srli	s11,s11,0x20
    800048d8:	05848513          	addi	a0,s1,88
    800048dc:	86ee                	mv	a3,s11
    800048de:	8656                	mv	a2,s5
    800048e0:	85e2                	mv	a1,s8
    800048e2:	953a                	add	a0,a0,a4
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	a42080e7          	jalr	-1470(ra) # 80003326 <either_copyin>
    800048ec:	07950263          	beq	a0,s9,80004950 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800048f0:	8526                	mv	a0,s1
    800048f2:	00000097          	auipc	ra,0x0
    800048f6:	790080e7          	jalr	1936(ra) # 80005082 <log_write>
    brelse(bp);
    800048fa:	8526                	mv	a0,s1
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	50a080e7          	jalr	1290(ra) # 80003e06 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004904:	01498a3b          	addw	s4,s3,s4
    80004908:	0129893b          	addw	s2,s3,s2
    8000490c:	9aee                	add	s5,s5,s11
    8000490e:	057a7663          	bgeu	s4,s7,8000495a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004912:	000b2483          	lw	s1,0(s6)
    80004916:	00a9559b          	srliw	a1,s2,0xa
    8000491a:	855a                	mv	a0,s6
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	7ae080e7          	jalr	1966(ra) # 800040ca <bmap>
    80004924:	0005059b          	sext.w	a1,a0
    80004928:	8526                	mv	a0,s1
    8000492a:	fffff097          	auipc	ra,0xfffff
    8000492e:	3ac080e7          	jalr	940(ra) # 80003cd6 <bread>
    80004932:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004934:	3ff97713          	andi	a4,s2,1023
    80004938:	40ed07bb          	subw	a5,s10,a4
    8000493c:	414b86bb          	subw	a3,s7,s4
    80004940:	89be                	mv	s3,a5
    80004942:	2781                	sext.w	a5,a5
    80004944:	0006861b          	sext.w	a2,a3
    80004948:	f8f674e3          	bgeu	a2,a5,800048d0 <writei+0x4c>
    8000494c:	89b6                	mv	s3,a3
    8000494e:	b749                	j	800048d0 <writei+0x4c>
      brelse(bp);
    80004950:	8526                	mv	a0,s1
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	4b4080e7          	jalr	1204(ra) # 80003e06 <brelse>
  }

  if(off > ip->size)
    8000495a:	04cb2783          	lw	a5,76(s6)
    8000495e:	0127f463          	bgeu	a5,s2,80004966 <writei+0xe2>
    ip->size = off;
    80004962:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004966:	855a                	mv	a0,s6
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	aa6080e7          	jalr	-1370(ra) # 8000440e <iupdate>

  return tot;
    80004970:	000a051b          	sext.w	a0,s4
}
    80004974:	70a6                	ld	ra,104(sp)
    80004976:	7406                	ld	s0,96(sp)
    80004978:	64e6                	ld	s1,88(sp)
    8000497a:	6946                	ld	s2,80(sp)
    8000497c:	69a6                	ld	s3,72(sp)
    8000497e:	6a06                	ld	s4,64(sp)
    80004980:	7ae2                	ld	s5,56(sp)
    80004982:	7b42                	ld	s6,48(sp)
    80004984:	7ba2                	ld	s7,40(sp)
    80004986:	7c02                	ld	s8,32(sp)
    80004988:	6ce2                	ld	s9,24(sp)
    8000498a:	6d42                	ld	s10,16(sp)
    8000498c:	6da2                	ld	s11,8(sp)
    8000498e:	6165                	addi	sp,sp,112
    80004990:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004992:	8a5e                	mv	s4,s7
    80004994:	bfc9                	j	80004966 <writei+0xe2>
    return -1;
    80004996:	557d                	li	a0,-1
}
    80004998:	8082                	ret
    return -1;
    8000499a:	557d                	li	a0,-1
    8000499c:	bfe1                	j	80004974 <writei+0xf0>
    return -1;
    8000499e:	557d                	li	a0,-1
    800049a0:	bfd1                	j	80004974 <writei+0xf0>

00000000800049a2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800049a2:	1141                	addi	sp,sp,-16
    800049a4:	e406                	sd	ra,8(sp)
    800049a6:	e022                	sd	s0,0(sp)
    800049a8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800049aa:	4639                	li	a2,14
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	41a080e7          	jalr	1050(ra) # 80000dc6 <strncmp>
}
    800049b4:	60a2                	ld	ra,8(sp)
    800049b6:	6402                	ld	s0,0(sp)
    800049b8:	0141                	addi	sp,sp,16
    800049ba:	8082                	ret

00000000800049bc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800049bc:	7139                	addi	sp,sp,-64
    800049be:	fc06                	sd	ra,56(sp)
    800049c0:	f822                	sd	s0,48(sp)
    800049c2:	f426                	sd	s1,40(sp)
    800049c4:	f04a                	sd	s2,32(sp)
    800049c6:	ec4e                	sd	s3,24(sp)
    800049c8:	e852                	sd	s4,16(sp)
    800049ca:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800049cc:	04451703          	lh	a4,68(a0)
    800049d0:	4785                	li	a5,1
    800049d2:	00f71a63          	bne	a4,a5,800049e6 <dirlookup+0x2a>
    800049d6:	892a                	mv	s2,a0
    800049d8:	89ae                	mv	s3,a1
    800049da:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800049dc:	457c                	lw	a5,76(a0)
    800049de:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800049e0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049e2:	e79d                	bnez	a5,80004a10 <dirlookup+0x54>
    800049e4:	a8a5                	j	80004a5c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800049e6:	00005517          	auipc	a0,0x5
    800049ea:	df250513          	addi	a0,a0,-526 # 800097d8 <syscalls+0x1b0>
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	b50080e7          	jalr	-1200(ra) # 8000053e <panic>
      panic("dirlookup read");
    800049f6:	00005517          	auipc	a0,0x5
    800049fa:	dfa50513          	addi	a0,a0,-518 # 800097f0 <syscalls+0x1c8>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	b40080e7          	jalr	-1216(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a06:	24c1                	addiw	s1,s1,16
    80004a08:	04c92783          	lw	a5,76(s2)
    80004a0c:	04f4f763          	bgeu	s1,a5,80004a5a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a10:	4741                	li	a4,16
    80004a12:	86a6                	mv	a3,s1
    80004a14:	fc040613          	addi	a2,s0,-64
    80004a18:	4581                	li	a1,0
    80004a1a:	854a                	mv	a0,s2
    80004a1c:	00000097          	auipc	ra,0x0
    80004a20:	d70080e7          	jalr	-656(ra) # 8000478c <readi>
    80004a24:	47c1                	li	a5,16
    80004a26:	fcf518e3          	bne	a0,a5,800049f6 <dirlookup+0x3a>
    if(de.inum == 0)
    80004a2a:	fc045783          	lhu	a5,-64(s0)
    80004a2e:	dfe1                	beqz	a5,80004a06 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004a30:	fc240593          	addi	a1,s0,-62
    80004a34:	854e                	mv	a0,s3
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	f6c080e7          	jalr	-148(ra) # 800049a2 <namecmp>
    80004a3e:	f561                	bnez	a0,80004a06 <dirlookup+0x4a>
      if(poff)
    80004a40:	000a0463          	beqz	s4,80004a48 <dirlookup+0x8c>
        *poff = off;
    80004a44:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004a48:	fc045583          	lhu	a1,-64(s0)
    80004a4c:	00092503          	lw	a0,0(s2)
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	754080e7          	jalr	1876(ra) # 800041a4 <iget>
    80004a58:	a011                	j	80004a5c <dirlookup+0xa0>
  return 0;
    80004a5a:	4501                	li	a0,0
}
    80004a5c:	70e2                	ld	ra,56(sp)
    80004a5e:	7442                	ld	s0,48(sp)
    80004a60:	74a2                	ld	s1,40(sp)
    80004a62:	7902                	ld	s2,32(sp)
    80004a64:	69e2                	ld	s3,24(sp)
    80004a66:	6a42                	ld	s4,16(sp)
    80004a68:	6121                	addi	sp,sp,64
    80004a6a:	8082                	ret

0000000080004a6c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004a6c:	711d                	addi	sp,sp,-96
    80004a6e:	ec86                	sd	ra,88(sp)
    80004a70:	e8a2                	sd	s0,80(sp)
    80004a72:	e4a6                	sd	s1,72(sp)
    80004a74:	e0ca                	sd	s2,64(sp)
    80004a76:	fc4e                	sd	s3,56(sp)
    80004a78:	f852                	sd	s4,48(sp)
    80004a7a:	f456                	sd	s5,40(sp)
    80004a7c:	f05a                	sd	s6,32(sp)
    80004a7e:	ec5e                	sd	s7,24(sp)
    80004a80:	e862                	sd	s8,16(sp)
    80004a82:	e466                	sd	s9,8(sp)
    80004a84:	1080                	addi	s0,sp,96
    80004a86:	84aa                	mv	s1,a0
    80004a88:	8b2e                	mv	s6,a1
    80004a8a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004a8c:	00054703          	lbu	a4,0(a0)
    80004a90:	02f00793          	li	a5,47
    80004a94:	02f70363          	beq	a4,a5,80004aba <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004a98:	ffffd097          	auipc	ra,0xffffd
    80004a9c:	40a080e7          	jalr	1034(ra) # 80001ea2 <myproc>
    80004aa0:	17853503          	ld	a0,376(a0)
    80004aa4:	00000097          	auipc	ra,0x0
    80004aa8:	9f6080e7          	jalr	-1546(ra) # 8000449a <idup>
    80004aac:	89aa                	mv	s3,a0
  while(*path == '/')
    80004aae:	02f00913          	li	s2,47
  len = path - s;
    80004ab2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004ab4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004ab6:	4c05                	li	s8,1
    80004ab8:	a865                	j	80004b70 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004aba:	4585                	li	a1,1
    80004abc:	4505                	li	a0,1
    80004abe:	fffff097          	auipc	ra,0xfffff
    80004ac2:	6e6080e7          	jalr	1766(ra) # 800041a4 <iget>
    80004ac6:	89aa                	mv	s3,a0
    80004ac8:	b7dd                	j	80004aae <namex+0x42>
      iunlockput(ip);
    80004aca:	854e                	mv	a0,s3
    80004acc:	00000097          	auipc	ra,0x0
    80004ad0:	c6e080e7          	jalr	-914(ra) # 8000473a <iunlockput>
      return 0;
    80004ad4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004ad6:	854e                	mv	a0,s3
    80004ad8:	60e6                	ld	ra,88(sp)
    80004ada:	6446                	ld	s0,80(sp)
    80004adc:	64a6                	ld	s1,72(sp)
    80004ade:	6906                	ld	s2,64(sp)
    80004ae0:	79e2                	ld	s3,56(sp)
    80004ae2:	7a42                	ld	s4,48(sp)
    80004ae4:	7aa2                	ld	s5,40(sp)
    80004ae6:	7b02                	ld	s6,32(sp)
    80004ae8:	6be2                	ld	s7,24(sp)
    80004aea:	6c42                	ld	s8,16(sp)
    80004aec:	6ca2                	ld	s9,8(sp)
    80004aee:	6125                	addi	sp,sp,96
    80004af0:	8082                	ret
      iunlock(ip);
    80004af2:	854e                	mv	a0,s3
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	aa6080e7          	jalr	-1370(ra) # 8000459a <iunlock>
      return ip;
    80004afc:	bfe9                	j	80004ad6 <namex+0x6a>
      iunlockput(ip);
    80004afe:	854e                	mv	a0,s3
    80004b00:	00000097          	auipc	ra,0x0
    80004b04:	c3a080e7          	jalr	-966(ra) # 8000473a <iunlockput>
      return 0;
    80004b08:	89d2                	mv	s3,s4
    80004b0a:	b7f1                	j	80004ad6 <namex+0x6a>
  len = path - s;
    80004b0c:	40b48633          	sub	a2,s1,a1
    80004b10:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004b14:	094cd463          	bge	s9,s4,80004b9c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004b18:	4639                	li	a2,14
    80004b1a:	8556                	mv	a0,s5
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	232080e7          	jalr	562(ra) # 80000d4e <memmove>
  while(*path == '/')
    80004b24:	0004c783          	lbu	a5,0(s1)
    80004b28:	01279763          	bne	a5,s2,80004b36 <namex+0xca>
    path++;
    80004b2c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004b2e:	0004c783          	lbu	a5,0(s1)
    80004b32:	ff278de3          	beq	a5,s2,80004b2c <namex+0xc0>
    ilock(ip);
    80004b36:	854e                	mv	a0,s3
    80004b38:	00000097          	auipc	ra,0x0
    80004b3c:	9a0080e7          	jalr	-1632(ra) # 800044d8 <ilock>
    if(ip->type != T_DIR){
    80004b40:	04499783          	lh	a5,68(s3)
    80004b44:	f98793e3          	bne	a5,s8,80004aca <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004b48:	000b0563          	beqz	s6,80004b52 <namex+0xe6>
    80004b4c:	0004c783          	lbu	a5,0(s1)
    80004b50:	d3cd                	beqz	a5,80004af2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004b52:	865e                	mv	a2,s7
    80004b54:	85d6                	mv	a1,s5
    80004b56:	854e                	mv	a0,s3
    80004b58:	00000097          	auipc	ra,0x0
    80004b5c:	e64080e7          	jalr	-412(ra) # 800049bc <dirlookup>
    80004b60:	8a2a                	mv	s4,a0
    80004b62:	dd51                	beqz	a0,80004afe <namex+0x92>
    iunlockput(ip);
    80004b64:	854e                	mv	a0,s3
    80004b66:	00000097          	auipc	ra,0x0
    80004b6a:	bd4080e7          	jalr	-1068(ra) # 8000473a <iunlockput>
    ip = next;
    80004b6e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004b70:	0004c783          	lbu	a5,0(s1)
    80004b74:	05279763          	bne	a5,s2,80004bc2 <namex+0x156>
    path++;
    80004b78:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004b7a:	0004c783          	lbu	a5,0(s1)
    80004b7e:	ff278de3          	beq	a5,s2,80004b78 <namex+0x10c>
  if(*path == 0)
    80004b82:	c79d                	beqz	a5,80004bb0 <namex+0x144>
    path++;
    80004b84:	85a6                	mv	a1,s1
  len = path - s;
    80004b86:	8a5e                	mv	s4,s7
    80004b88:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004b8a:	01278963          	beq	a5,s2,80004b9c <namex+0x130>
    80004b8e:	dfbd                	beqz	a5,80004b0c <namex+0xa0>
    path++;
    80004b90:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004b92:	0004c783          	lbu	a5,0(s1)
    80004b96:	ff279ce3          	bne	a5,s2,80004b8e <namex+0x122>
    80004b9a:	bf8d                	j	80004b0c <namex+0xa0>
    memmove(name, s, len);
    80004b9c:	2601                	sext.w	a2,a2
    80004b9e:	8556                	mv	a0,s5
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	1ae080e7          	jalr	430(ra) # 80000d4e <memmove>
    name[len] = 0;
    80004ba8:	9a56                	add	s4,s4,s5
    80004baa:	000a0023          	sb	zero,0(s4)
    80004bae:	bf9d                	j	80004b24 <namex+0xb8>
  if(nameiparent){
    80004bb0:	f20b03e3          	beqz	s6,80004ad6 <namex+0x6a>
    iput(ip);
    80004bb4:	854e                	mv	a0,s3
    80004bb6:	00000097          	auipc	ra,0x0
    80004bba:	adc080e7          	jalr	-1316(ra) # 80004692 <iput>
    return 0;
    80004bbe:	4981                	li	s3,0
    80004bc0:	bf19                	j	80004ad6 <namex+0x6a>
  if(*path == 0)
    80004bc2:	d7fd                	beqz	a5,80004bb0 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004bc4:	0004c783          	lbu	a5,0(s1)
    80004bc8:	85a6                	mv	a1,s1
    80004bca:	b7d1                	j	80004b8e <namex+0x122>

0000000080004bcc <dirlink>:
{
    80004bcc:	7139                	addi	sp,sp,-64
    80004bce:	fc06                	sd	ra,56(sp)
    80004bd0:	f822                	sd	s0,48(sp)
    80004bd2:	f426                	sd	s1,40(sp)
    80004bd4:	f04a                	sd	s2,32(sp)
    80004bd6:	ec4e                	sd	s3,24(sp)
    80004bd8:	e852                	sd	s4,16(sp)
    80004bda:	0080                	addi	s0,sp,64
    80004bdc:	892a                	mv	s2,a0
    80004bde:	8a2e                	mv	s4,a1
    80004be0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004be2:	4601                	li	a2,0
    80004be4:	00000097          	auipc	ra,0x0
    80004be8:	dd8080e7          	jalr	-552(ra) # 800049bc <dirlookup>
    80004bec:	e93d                	bnez	a0,80004c62 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004bee:	04c92483          	lw	s1,76(s2)
    80004bf2:	c49d                	beqz	s1,80004c20 <dirlink+0x54>
    80004bf4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004bf6:	4741                	li	a4,16
    80004bf8:	86a6                	mv	a3,s1
    80004bfa:	fc040613          	addi	a2,s0,-64
    80004bfe:	4581                	li	a1,0
    80004c00:	854a                	mv	a0,s2
    80004c02:	00000097          	auipc	ra,0x0
    80004c06:	b8a080e7          	jalr	-1142(ra) # 8000478c <readi>
    80004c0a:	47c1                	li	a5,16
    80004c0c:	06f51163          	bne	a0,a5,80004c6e <dirlink+0xa2>
    if(de.inum == 0)
    80004c10:	fc045783          	lhu	a5,-64(s0)
    80004c14:	c791                	beqz	a5,80004c20 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004c16:	24c1                	addiw	s1,s1,16
    80004c18:	04c92783          	lw	a5,76(s2)
    80004c1c:	fcf4ede3          	bltu	s1,a5,80004bf6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004c20:	4639                	li	a2,14
    80004c22:	85d2                	mv	a1,s4
    80004c24:	fc240513          	addi	a0,s0,-62
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	1da080e7          	jalr	474(ra) # 80000e02 <strncpy>
  de.inum = inum;
    80004c30:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004c34:	4741                	li	a4,16
    80004c36:	86a6                	mv	a3,s1
    80004c38:	fc040613          	addi	a2,s0,-64
    80004c3c:	4581                	li	a1,0
    80004c3e:	854a                	mv	a0,s2
    80004c40:	00000097          	auipc	ra,0x0
    80004c44:	c44080e7          	jalr	-956(ra) # 80004884 <writei>
    80004c48:	872a                	mv	a4,a0
    80004c4a:	47c1                	li	a5,16
  return 0;
    80004c4c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004c4e:	02f71863          	bne	a4,a5,80004c7e <dirlink+0xb2>
}
    80004c52:	70e2                	ld	ra,56(sp)
    80004c54:	7442                	ld	s0,48(sp)
    80004c56:	74a2                	ld	s1,40(sp)
    80004c58:	7902                	ld	s2,32(sp)
    80004c5a:	69e2                	ld	s3,24(sp)
    80004c5c:	6a42                	ld	s4,16(sp)
    80004c5e:	6121                	addi	sp,sp,64
    80004c60:	8082                	ret
    iput(ip);
    80004c62:	00000097          	auipc	ra,0x0
    80004c66:	a30080e7          	jalr	-1488(ra) # 80004692 <iput>
    return -1;
    80004c6a:	557d                	li	a0,-1
    80004c6c:	b7dd                	j	80004c52 <dirlink+0x86>
      panic("dirlink read");
    80004c6e:	00005517          	auipc	a0,0x5
    80004c72:	b9250513          	addi	a0,a0,-1134 # 80009800 <syscalls+0x1d8>
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	8c8080e7          	jalr	-1848(ra) # 8000053e <panic>
    panic("dirlink");
    80004c7e:	00005517          	auipc	a0,0x5
    80004c82:	c9250513          	addi	a0,a0,-878 # 80009910 <syscalls+0x2e8>
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	8b8080e7          	jalr	-1864(ra) # 8000053e <panic>

0000000080004c8e <namei>:

struct inode*
namei(char *path)
{
    80004c8e:	1101                	addi	sp,sp,-32
    80004c90:	ec06                	sd	ra,24(sp)
    80004c92:	e822                	sd	s0,16(sp)
    80004c94:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004c96:	fe040613          	addi	a2,s0,-32
    80004c9a:	4581                	li	a1,0
    80004c9c:	00000097          	auipc	ra,0x0
    80004ca0:	dd0080e7          	jalr	-560(ra) # 80004a6c <namex>
}
    80004ca4:	60e2                	ld	ra,24(sp)
    80004ca6:	6442                	ld	s0,16(sp)
    80004ca8:	6105                	addi	sp,sp,32
    80004caa:	8082                	ret

0000000080004cac <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004cac:	1141                	addi	sp,sp,-16
    80004cae:	e406                	sd	ra,8(sp)
    80004cb0:	e022                	sd	s0,0(sp)
    80004cb2:	0800                	addi	s0,sp,16
    80004cb4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004cb6:	4585                	li	a1,1
    80004cb8:	00000097          	auipc	ra,0x0
    80004cbc:	db4080e7          	jalr	-588(ra) # 80004a6c <namex>
}
    80004cc0:	60a2                	ld	ra,8(sp)
    80004cc2:	6402                	ld	s0,0(sp)
    80004cc4:	0141                	addi	sp,sp,16
    80004cc6:	8082                	ret

0000000080004cc8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004cc8:	1101                	addi	sp,sp,-32
    80004cca:	ec06                	sd	ra,24(sp)
    80004ccc:	e822                	sd	s0,16(sp)
    80004cce:	e426                	sd	s1,8(sp)
    80004cd0:	e04a                	sd	s2,0(sp)
    80004cd2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004cd4:	0001e917          	auipc	s2,0x1e
    80004cd8:	eac90913          	addi	s2,s2,-340 # 80022b80 <log>
    80004cdc:	01892583          	lw	a1,24(s2)
    80004ce0:	02892503          	lw	a0,40(s2)
    80004ce4:	fffff097          	auipc	ra,0xfffff
    80004ce8:	ff2080e7          	jalr	-14(ra) # 80003cd6 <bread>
    80004cec:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004cee:	02c92683          	lw	a3,44(s2)
    80004cf2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004cf4:	02d05763          	blez	a3,80004d22 <write_head+0x5a>
    80004cf8:	0001e797          	auipc	a5,0x1e
    80004cfc:	eb878793          	addi	a5,a5,-328 # 80022bb0 <log+0x30>
    80004d00:	05c50713          	addi	a4,a0,92
    80004d04:	36fd                	addiw	a3,a3,-1
    80004d06:	1682                	slli	a3,a3,0x20
    80004d08:	9281                	srli	a3,a3,0x20
    80004d0a:	068a                	slli	a3,a3,0x2
    80004d0c:	0001e617          	auipc	a2,0x1e
    80004d10:	ea860613          	addi	a2,a2,-344 # 80022bb4 <log+0x34>
    80004d14:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004d16:	4390                	lw	a2,0(a5)
    80004d18:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004d1a:	0791                	addi	a5,a5,4
    80004d1c:	0711                	addi	a4,a4,4
    80004d1e:	fed79ce3          	bne	a5,a3,80004d16 <write_head+0x4e>
  }
  bwrite(buf);
    80004d22:	8526                	mv	a0,s1
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	0a4080e7          	jalr	164(ra) # 80003dc8 <bwrite>
  brelse(buf);
    80004d2c:	8526                	mv	a0,s1
    80004d2e:	fffff097          	auipc	ra,0xfffff
    80004d32:	0d8080e7          	jalr	216(ra) # 80003e06 <brelse>
}
    80004d36:	60e2                	ld	ra,24(sp)
    80004d38:	6442                	ld	s0,16(sp)
    80004d3a:	64a2                	ld	s1,8(sp)
    80004d3c:	6902                	ld	s2,0(sp)
    80004d3e:	6105                	addi	sp,sp,32
    80004d40:	8082                	ret

0000000080004d42 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d42:	0001e797          	auipc	a5,0x1e
    80004d46:	e6a7a783          	lw	a5,-406(a5) # 80022bac <log+0x2c>
    80004d4a:	0af05d63          	blez	a5,80004e04 <install_trans+0xc2>
{
    80004d4e:	7139                	addi	sp,sp,-64
    80004d50:	fc06                	sd	ra,56(sp)
    80004d52:	f822                	sd	s0,48(sp)
    80004d54:	f426                	sd	s1,40(sp)
    80004d56:	f04a                	sd	s2,32(sp)
    80004d58:	ec4e                	sd	s3,24(sp)
    80004d5a:	e852                	sd	s4,16(sp)
    80004d5c:	e456                	sd	s5,8(sp)
    80004d5e:	e05a                	sd	s6,0(sp)
    80004d60:	0080                	addi	s0,sp,64
    80004d62:	8b2a                	mv	s6,a0
    80004d64:	0001ea97          	auipc	s5,0x1e
    80004d68:	e4ca8a93          	addi	s5,s5,-436 # 80022bb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d6c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004d6e:	0001e997          	auipc	s3,0x1e
    80004d72:	e1298993          	addi	s3,s3,-494 # 80022b80 <log>
    80004d76:	a035                	j	80004da2 <install_trans+0x60>
      bunpin(dbuf);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	fffff097          	auipc	ra,0xfffff
    80004d7e:	166080e7          	jalr	358(ra) # 80003ee0 <bunpin>
    brelse(lbuf);
    80004d82:	854a                	mv	a0,s2
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	082080e7          	jalr	130(ra) # 80003e06 <brelse>
    brelse(dbuf);
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	078080e7          	jalr	120(ra) # 80003e06 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d96:	2a05                	addiw	s4,s4,1
    80004d98:	0a91                	addi	s5,s5,4
    80004d9a:	02c9a783          	lw	a5,44(s3)
    80004d9e:	04fa5963          	bge	s4,a5,80004df0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004da2:	0189a583          	lw	a1,24(s3)
    80004da6:	014585bb          	addw	a1,a1,s4
    80004daa:	2585                	addiw	a1,a1,1
    80004dac:	0289a503          	lw	a0,40(s3)
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	f26080e7          	jalr	-218(ra) # 80003cd6 <bread>
    80004db8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004dba:	000aa583          	lw	a1,0(s5)
    80004dbe:	0289a503          	lw	a0,40(s3)
    80004dc2:	fffff097          	auipc	ra,0xfffff
    80004dc6:	f14080e7          	jalr	-236(ra) # 80003cd6 <bread>
    80004dca:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004dcc:	40000613          	li	a2,1024
    80004dd0:	05890593          	addi	a1,s2,88
    80004dd4:	05850513          	addi	a0,a0,88
    80004dd8:	ffffc097          	auipc	ra,0xffffc
    80004ddc:	f76080e7          	jalr	-138(ra) # 80000d4e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004de0:	8526                	mv	a0,s1
    80004de2:	fffff097          	auipc	ra,0xfffff
    80004de6:	fe6080e7          	jalr	-26(ra) # 80003dc8 <bwrite>
    if(recovering == 0)
    80004dea:	f80b1ce3          	bnez	s6,80004d82 <install_trans+0x40>
    80004dee:	b769                	j	80004d78 <install_trans+0x36>
}
    80004df0:	70e2                	ld	ra,56(sp)
    80004df2:	7442                	ld	s0,48(sp)
    80004df4:	74a2                	ld	s1,40(sp)
    80004df6:	7902                	ld	s2,32(sp)
    80004df8:	69e2                	ld	s3,24(sp)
    80004dfa:	6a42                	ld	s4,16(sp)
    80004dfc:	6aa2                	ld	s5,8(sp)
    80004dfe:	6b02                	ld	s6,0(sp)
    80004e00:	6121                	addi	sp,sp,64
    80004e02:	8082                	ret
    80004e04:	8082                	ret

0000000080004e06 <initlog>:
{
    80004e06:	7179                	addi	sp,sp,-48
    80004e08:	f406                	sd	ra,40(sp)
    80004e0a:	f022                	sd	s0,32(sp)
    80004e0c:	ec26                	sd	s1,24(sp)
    80004e0e:	e84a                	sd	s2,16(sp)
    80004e10:	e44e                	sd	s3,8(sp)
    80004e12:	1800                	addi	s0,sp,48
    80004e14:	892a                	mv	s2,a0
    80004e16:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004e18:	0001e497          	auipc	s1,0x1e
    80004e1c:	d6848493          	addi	s1,s1,-664 # 80022b80 <log>
    80004e20:	00005597          	auipc	a1,0x5
    80004e24:	9f058593          	addi	a1,a1,-1552 # 80009810 <syscalls+0x1e8>
    80004e28:	8526                	mv	a0,s1
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	d2a080e7          	jalr	-726(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004e32:	0149a583          	lw	a1,20(s3)
    80004e36:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004e38:	0109a783          	lw	a5,16(s3)
    80004e3c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004e3e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004e42:	854a                	mv	a0,s2
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	e92080e7          	jalr	-366(ra) # 80003cd6 <bread>
  log.lh.n = lh->n;
    80004e4c:	4d3c                	lw	a5,88(a0)
    80004e4e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004e50:	02f05563          	blez	a5,80004e7a <initlog+0x74>
    80004e54:	05c50713          	addi	a4,a0,92
    80004e58:	0001e697          	auipc	a3,0x1e
    80004e5c:	d5868693          	addi	a3,a3,-680 # 80022bb0 <log+0x30>
    80004e60:	37fd                	addiw	a5,a5,-1
    80004e62:	1782                	slli	a5,a5,0x20
    80004e64:	9381                	srli	a5,a5,0x20
    80004e66:	078a                	slli	a5,a5,0x2
    80004e68:	06050613          	addi	a2,a0,96
    80004e6c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004e6e:	4310                	lw	a2,0(a4)
    80004e70:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004e72:	0711                	addi	a4,a4,4
    80004e74:	0691                	addi	a3,a3,4
    80004e76:	fef71ce3          	bne	a4,a5,80004e6e <initlog+0x68>
  brelse(buf);
    80004e7a:	fffff097          	auipc	ra,0xfffff
    80004e7e:	f8c080e7          	jalr	-116(ra) # 80003e06 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004e82:	4505                	li	a0,1
    80004e84:	00000097          	auipc	ra,0x0
    80004e88:	ebe080e7          	jalr	-322(ra) # 80004d42 <install_trans>
  log.lh.n = 0;
    80004e8c:	0001e797          	auipc	a5,0x1e
    80004e90:	d207a023          	sw	zero,-736(a5) # 80022bac <log+0x2c>
  write_head(); // clear the log
    80004e94:	00000097          	auipc	ra,0x0
    80004e98:	e34080e7          	jalr	-460(ra) # 80004cc8 <write_head>
}
    80004e9c:	70a2                	ld	ra,40(sp)
    80004e9e:	7402                	ld	s0,32(sp)
    80004ea0:	64e2                	ld	s1,24(sp)
    80004ea2:	6942                	ld	s2,16(sp)
    80004ea4:	69a2                	ld	s3,8(sp)
    80004ea6:	6145                	addi	sp,sp,48
    80004ea8:	8082                	ret

0000000080004eaa <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004eaa:	1101                	addi	sp,sp,-32
    80004eac:	ec06                	sd	ra,24(sp)
    80004eae:	e822                	sd	s0,16(sp)
    80004eb0:	e426                	sd	s1,8(sp)
    80004eb2:	e04a                	sd	s2,0(sp)
    80004eb4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004eb6:	0001e517          	auipc	a0,0x1e
    80004eba:	cca50513          	addi	a0,a0,-822 # 80022b80 <log>
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	d2e080e7          	jalr	-722(ra) # 80000bec <acquire>
  while(1){
    if(log.committing){
    80004ec6:	0001e497          	auipc	s1,0x1e
    80004eca:	cba48493          	addi	s1,s1,-838 # 80022b80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ece:	4979                	li	s2,30
    80004ed0:	a039                	j	80004ede <begin_op+0x34>
      sleep(&log, &log.lock);
    80004ed2:	85a6                	mv	a1,s1
    80004ed4:	8526                	mv	a0,s1
    80004ed6:	ffffe097          	auipc	ra,0xffffe
    80004eda:	eb8080e7          	jalr	-328(ra) # 80002d8e <sleep>
    if(log.committing){
    80004ede:	50dc                	lw	a5,36(s1)
    80004ee0:	fbed                	bnez	a5,80004ed2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ee2:	509c                	lw	a5,32(s1)
    80004ee4:	0017871b          	addiw	a4,a5,1
    80004ee8:	0007069b          	sext.w	a3,a4
    80004eec:	0027179b          	slliw	a5,a4,0x2
    80004ef0:	9fb9                	addw	a5,a5,a4
    80004ef2:	0017979b          	slliw	a5,a5,0x1
    80004ef6:	54d8                	lw	a4,44(s1)
    80004ef8:	9fb9                	addw	a5,a5,a4
    80004efa:	00f95963          	bge	s2,a5,80004f0c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004efe:	85a6                	mv	a1,s1
    80004f00:	8526                	mv	a0,s1
    80004f02:	ffffe097          	auipc	ra,0xffffe
    80004f06:	e8c080e7          	jalr	-372(ra) # 80002d8e <sleep>
    80004f0a:	bfd1                	j	80004ede <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004f0c:	0001e517          	auipc	a0,0x1e
    80004f10:	c7450513          	addi	a0,a0,-908 # 80022b80 <log>
    80004f14:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	d90080e7          	jalr	-624(ra) # 80000ca6 <release>
      break;
    }
  }
}
    80004f1e:	60e2                	ld	ra,24(sp)
    80004f20:	6442                	ld	s0,16(sp)
    80004f22:	64a2                	ld	s1,8(sp)
    80004f24:	6902                	ld	s2,0(sp)
    80004f26:	6105                	addi	sp,sp,32
    80004f28:	8082                	ret

0000000080004f2a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004f2a:	7139                	addi	sp,sp,-64
    80004f2c:	fc06                	sd	ra,56(sp)
    80004f2e:	f822                	sd	s0,48(sp)
    80004f30:	f426                	sd	s1,40(sp)
    80004f32:	f04a                	sd	s2,32(sp)
    80004f34:	ec4e                	sd	s3,24(sp)
    80004f36:	e852                	sd	s4,16(sp)
    80004f38:	e456                	sd	s5,8(sp)
    80004f3a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004f3c:	0001e497          	auipc	s1,0x1e
    80004f40:	c4448493          	addi	s1,s1,-956 # 80022b80 <log>
    80004f44:	8526                	mv	a0,s1
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	ca6080e7          	jalr	-858(ra) # 80000bec <acquire>
  log.outstanding -= 1;
    80004f4e:	509c                	lw	a5,32(s1)
    80004f50:	37fd                	addiw	a5,a5,-1
    80004f52:	0007891b          	sext.w	s2,a5
    80004f56:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004f58:	50dc                	lw	a5,36(s1)
    80004f5a:	efb9                	bnez	a5,80004fb8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004f5c:	06091663          	bnez	s2,80004fc8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004f60:	0001e497          	auipc	s1,0x1e
    80004f64:	c2048493          	addi	s1,s1,-992 # 80022b80 <log>
    80004f68:	4785                	li	a5,1
    80004f6a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004f6c:	8526                	mv	a0,s1
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	d38080e7          	jalr	-712(ra) # 80000ca6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004f76:	54dc                	lw	a5,44(s1)
    80004f78:	06f04763          	bgtz	a5,80004fe6 <end_op+0xbc>
    acquire(&log.lock);
    80004f7c:	0001e497          	auipc	s1,0x1e
    80004f80:	c0448493          	addi	s1,s1,-1020 # 80022b80 <log>
    80004f84:	8526                	mv	a0,s1
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	c66080e7          	jalr	-922(ra) # 80000bec <acquire>
    log.committing = 0;
    80004f8e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004f92:	8526                	mv	a0,s1
    80004f94:	ffffe097          	auipc	ra,0xffffe
    80004f98:	fa2080e7          	jalr	-94(ra) # 80002f36 <wakeup>
    release(&log.lock);
    80004f9c:	8526                	mv	a0,s1
    80004f9e:	ffffc097          	auipc	ra,0xffffc
    80004fa2:	d08080e7          	jalr	-760(ra) # 80000ca6 <release>
}
    80004fa6:	70e2                	ld	ra,56(sp)
    80004fa8:	7442                	ld	s0,48(sp)
    80004faa:	74a2                	ld	s1,40(sp)
    80004fac:	7902                	ld	s2,32(sp)
    80004fae:	69e2                	ld	s3,24(sp)
    80004fb0:	6a42                	ld	s4,16(sp)
    80004fb2:	6aa2                	ld	s5,8(sp)
    80004fb4:	6121                	addi	sp,sp,64
    80004fb6:	8082                	ret
    panic("log.committing");
    80004fb8:	00005517          	auipc	a0,0x5
    80004fbc:	86050513          	addi	a0,a0,-1952 # 80009818 <syscalls+0x1f0>
    80004fc0:	ffffb097          	auipc	ra,0xffffb
    80004fc4:	57e080e7          	jalr	1406(ra) # 8000053e <panic>
    wakeup(&log);
    80004fc8:	0001e497          	auipc	s1,0x1e
    80004fcc:	bb848493          	addi	s1,s1,-1096 # 80022b80 <log>
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	ffffe097          	auipc	ra,0xffffe
    80004fd6:	f64080e7          	jalr	-156(ra) # 80002f36 <wakeup>
  release(&log.lock);
    80004fda:	8526                	mv	a0,s1
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	cca080e7          	jalr	-822(ra) # 80000ca6 <release>
  if(do_commit){
    80004fe4:	b7c9                	j	80004fa6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004fe6:	0001ea97          	auipc	s5,0x1e
    80004fea:	bcaa8a93          	addi	s5,s5,-1078 # 80022bb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004fee:	0001ea17          	auipc	s4,0x1e
    80004ff2:	b92a0a13          	addi	s4,s4,-1134 # 80022b80 <log>
    80004ff6:	018a2583          	lw	a1,24(s4)
    80004ffa:	012585bb          	addw	a1,a1,s2
    80004ffe:	2585                	addiw	a1,a1,1
    80005000:	028a2503          	lw	a0,40(s4)
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	cd2080e7          	jalr	-814(ra) # 80003cd6 <bread>
    8000500c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000500e:	000aa583          	lw	a1,0(s5)
    80005012:	028a2503          	lw	a0,40(s4)
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	cc0080e7          	jalr	-832(ra) # 80003cd6 <bread>
    8000501e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005020:	40000613          	li	a2,1024
    80005024:	05850593          	addi	a1,a0,88
    80005028:	05848513          	addi	a0,s1,88
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	d22080e7          	jalr	-734(ra) # 80000d4e <memmove>
    bwrite(to);  // write the log
    80005034:	8526                	mv	a0,s1
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	d92080e7          	jalr	-622(ra) # 80003dc8 <bwrite>
    brelse(from);
    8000503e:	854e                	mv	a0,s3
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	dc6080e7          	jalr	-570(ra) # 80003e06 <brelse>
    brelse(to);
    80005048:	8526                	mv	a0,s1
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	dbc080e7          	jalr	-580(ra) # 80003e06 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005052:	2905                	addiw	s2,s2,1
    80005054:	0a91                	addi	s5,s5,4
    80005056:	02ca2783          	lw	a5,44(s4)
    8000505a:	f8f94ee3          	blt	s2,a5,80004ff6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000505e:	00000097          	auipc	ra,0x0
    80005062:	c6a080e7          	jalr	-918(ra) # 80004cc8 <write_head>
    install_trans(0); // Now install writes to home locations
    80005066:	4501                	li	a0,0
    80005068:	00000097          	auipc	ra,0x0
    8000506c:	cda080e7          	jalr	-806(ra) # 80004d42 <install_trans>
    log.lh.n = 0;
    80005070:	0001e797          	auipc	a5,0x1e
    80005074:	b207ae23          	sw	zero,-1220(a5) # 80022bac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80005078:	00000097          	auipc	ra,0x0
    8000507c:	c50080e7          	jalr	-944(ra) # 80004cc8 <write_head>
    80005080:	bdf5                	j	80004f7c <end_op+0x52>

0000000080005082 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80005082:	1101                	addi	sp,sp,-32
    80005084:	ec06                	sd	ra,24(sp)
    80005086:	e822                	sd	s0,16(sp)
    80005088:	e426                	sd	s1,8(sp)
    8000508a:	e04a                	sd	s2,0(sp)
    8000508c:	1000                	addi	s0,sp,32
    8000508e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80005090:	0001e917          	auipc	s2,0x1e
    80005094:	af090913          	addi	s2,s2,-1296 # 80022b80 <log>
    80005098:	854a                	mv	a0,s2
    8000509a:	ffffc097          	auipc	ra,0xffffc
    8000509e:	b52080e7          	jalr	-1198(ra) # 80000bec <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800050a2:	02c92603          	lw	a2,44(s2)
    800050a6:	47f5                	li	a5,29
    800050a8:	06c7c563          	blt	a5,a2,80005112 <log_write+0x90>
    800050ac:	0001e797          	auipc	a5,0x1e
    800050b0:	af07a783          	lw	a5,-1296(a5) # 80022b9c <log+0x1c>
    800050b4:	37fd                	addiw	a5,a5,-1
    800050b6:	04f65e63          	bge	a2,a5,80005112 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800050ba:	0001e797          	auipc	a5,0x1e
    800050be:	ae67a783          	lw	a5,-1306(a5) # 80022ba0 <log+0x20>
    800050c2:	06f05063          	blez	a5,80005122 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800050c6:	4781                	li	a5,0
    800050c8:	06c05563          	blez	a2,80005132 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800050cc:	44cc                	lw	a1,12(s1)
    800050ce:	0001e717          	auipc	a4,0x1e
    800050d2:	ae270713          	addi	a4,a4,-1310 # 80022bb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800050d6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800050d8:	4314                	lw	a3,0(a4)
    800050da:	04b68c63          	beq	a3,a1,80005132 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800050de:	2785                	addiw	a5,a5,1
    800050e0:	0711                	addi	a4,a4,4
    800050e2:	fef61be3          	bne	a2,a5,800050d8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800050e6:	0621                	addi	a2,a2,8
    800050e8:	060a                	slli	a2,a2,0x2
    800050ea:	0001e797          	auipc	a5,0x1e
    800050ee:	a9678793          	addi	a5,a5,-1386 # 80022b80 <log>
    800050f2:	963e                	add	a2,a2,a5
    800050f4:	44dc                	lw	a5,12(s1)
    800050f6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800050f8:	8526                	mv	a0,s1
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	daa080e7          	jalr	-598(ra) # 80003ea4 <bpin>
    log.lh.n++;
    80005102:	0001e717          	auipc	a4,0x1e
    80005106:	a7e70713          	addi	a4,a4,-1410 # 80022b80 <log>
    8000510a:	575c                	lw	a5,44(a4)
    8000510c:	2785                	addiw	a5,a5,1
    8000510e:	d75c                	sw	a5,44(a4)
    80005110:	a835                	j	8000514c <log_write+0xca>
    panic("too big a transaction");
    80005112:	00004517          	auipc	a0,0x4
    80005116:	71650513          	addi	a0,a0,1814 # 80009828 <syscalls+0x200>
    8000511a:	ffffb097          	auipc	ra,0xffffb
    8000511e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80005122:	00004517          	auipc	a0,0x4
    80005126:	71e50513          	addi	a0,a0,1822 # 80009840 <syscalls+0x218>
    8000512a:	ffffb097          	auipc	ra,0xffffb
    8000512e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80005132:	00878713          	addi	a4,a5,8
    80005136:	00271693          	slli	a3,a4,0x2
    8000513a:	0001e717          	auipc	a4,0x1e
    8000513e:	a4670713          	addi	a4,a4,-1466 # 80022b80 <log>
    80005142:	9736                	add	a4,a4,a3
    80005144:	44d4                	lw	a3,12(s1)
    80005146:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80005148:	faf608e3          	beq	a2,a5,800050f8 <log_write+0x76>
  }
  release(&log.lock);
    8000514c:	0001e517          	auipc	a0,0x1e
    80005150:	a3450513          	addi	a0,a0,-1484 # 80022b80 <log>
    80005154:	ffffc097          	auipc	ra,0xffffc
    80005158:	b52080e7          	jalr	-1198(ra) # 80000ca6 <release>
}
    8000515c:	60e2                	ld	ra,24(sp)
    8000515e:	6442                	ld	s0,16(sp)
    80005160:	64a2                	ld	s1,8(sp)
    80005162:	6902                	ld	s2,0(sp)
    80005164:	6105                	addi	sp,sp,32
    80005166:	8082                	ret

0000000080005168 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80005168:	1101                	addi	sp,sp,-32
    8000516a:	ec06                	sd	ra,24(sp)
    8000516c:	e822                	sd	s0,16(sp)
    8000516e:	e426                	sd	s1,8(sp)
    80005170:	e04a                	sd	s2,0(sp)
    80005172:	1000                	addi	s0,sp,32
    80005174:	84aa                	mv	s1,a0
    80005176:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80005178:	00004597          	auipc	a1,0x4
    8000517c:	6e858593          	addi	a1,a1,1768 # 80009860 <syscalls+0x238>
    80005180:	0521                	addi	a0,a0,8
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	9d2080e7          	jalr	-1582(ra) # 80000b54 <initlock>
  lk->name = name;
    8000518a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000518e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005192:	0204a423          	sw	zero,40(s1)
}
    80005196:	60e2                	ld	ra,24(sp)
    80005198:	6442                	ld	s0,16(sp)
    8000519a:	64a2                	ld	s1,8(sp)
    8000519c:	6902                	ld	s2,0(sp)
    8000519e:	6105                	addi	sp,sp,32
    800051a0:	8082                	ret

00000000800051a2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800051a2:	1101                	addi	sp,sp,-32
    800051a4:	ec06                	sd	ra,24(sp)
    800051a6:	e822                	sd	s0,16(sp)
    800051a8:	e426                	sd	s1,8(sp)
    800051aa:	e04a                	sd	s2,0(sp)
    800051ac:	1000                	addi	s0,sp,32
    800051ae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800051b0:	00850913          	addi	s2,a0,8
    800051b4:	854a                	mv	a0,s2
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	a36080e7          	jalr	-1482(ra) # 80000bec <acquire>
  while (lk->locked) {
    800051be:	409c                	lw	a5,0(s1)
    800051c0:	cb89                	beqz	a5,800051d2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800051c2:	85ca                	mv	a1,s2
    800051c4:	8526                	mv	a0,s1
    800051c6:	ffffe097          	auipc	ra,0xffffe
    800051ca:	bc8080e7          	jalr	-1080(ra) # 80002d8e <sleep>
  while (lk->locked) {
    800051ce:	409c                	lw	a5,0(s1)
    800051d0:	fbed                	bnez	a5,800051c2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800051d2:	4785                	li	a5,1
    800051d4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800051d6:	ffffd097          	auipc	ra,0xffffd
    800051da:	ccc080e7          	jalr	-820(ra) # 80001ea2 <myproc>
    800051de:	453c                	lw	a5,72(a0)
    800051e0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800051e2:	854a                	mv	a0,s2
    800051e4:	ffffc097          	auipc	ra,0xffffc
    800051e8:	ac2080e7          	jalr	-1342(ra) # 80000ca6 <release>
}
    800051ec:	60e2                	ld	ra,24(sp)
    800051ee:	6442                	ld	s0,16(sp)
    800051f0:	64a2                	ld	s1,8(sp)
    800051f2:	6902                	ld	s2,0(sp)
    800051f4:	6105                	addi	sp,sp,32
    800051f6:	8082                	ret

00000000800051f8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800051f8:	1101                	addi	sp,sp,-32
    800051fa:	ec06                	sd	ra,24(sp)
    800051fc:	e822                	sd	s0,16(sp)
    800051fe:	e426                	sd	s1,8(sp)
    80005200:	e04a                	sd	s2,0(sp)
    80005202:	1000                	addi	s0,sp,32
    80005204:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005206:	00850913          	addi	s2,a0,8
    8000520a:	854a                	mv	a0,s2
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	9e0080e7          	jalr	-1568(ra) # 80000bec <acquire>
  lk->locked = 0;
    80005214:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005218:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000521c:	8526                	mv	a0,s1
    8000521e:	ffffe097          	auipc	ra,0xffffe
    80005222:	d18080e7          	jalr	-744(ra) # 80002f36 <wakeup>
  release(&lk->lk);
    80005226:	854a                	mv	a0,s2
    80005228:	ffffc097          	auipc	ra,0xffffc
    8000522c:	a7e080e7          	jalr	-1410(ra) # 80000ca6 <release>
}
    80005230:	60e2                	ld	ra,24(sp)
    80005232:	6442                	ld	s0,16(sp)
    80005234:	64a2                	ld	s1,8(sp)
    80005236:	6902                	ld	s2,0(sp)
    80005238:	6105                	addi	sp,sp,32
    8000523a:	8082                	ret

000000008000523c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000523c:	7179                	addi	sp,sp,-48
    8000523e:	f406                	sd	ra,40(sp)
    80005240:	f022                	sd	s0,32(sp)
    80005242:	ec26                	sd	s1,24(sp)
    80005244:	e84a                	sd	s2,16(sp)
    80005246:	e44e                	sd	s3,8(sp)
    80005248:	1800                	addi	s0,sp,48
    8000524a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000524c:	00850913          	addi	s2,a0,8
    80005250:	854a                	mv	a0,s2
    80005252:	ffffc097          	auipc	ra,0xffffc
    80005256:	99a080e7          	jalr	-1638(ra) # 80000bec <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000525a:	409c                	lw	a5,0(s1)
    8000525c:	ef99                	bnez	a5,8000527a <holdingsleep+0x3e>
    8000525e:	4481                	li	s1,0
  release(&lk->lk);
    80005260:	854a                	mv	a0,s2
    80005262:	ffffc097          	auipc	ra,0xffffc
    80005266:	a44080e7          	jalr	-1468(ra) # 80000ca6 <release>
  return r;
}
    8000526a:	8526                	mv	a0,s1
    8000526c:	70a2                	ld	ra,40(sp)
    8000526e:	7402                	ld	s0,32(sp)
    80005270:	64e2                	ld	s1,24(sp)
    80005272:	6942                	ld	s2,16(sp)
    80005274:	69a2                	ld	s3,8(sp)
    80005276:	6145                	addi	sp,sp,48
    80005278:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000527a:	0284a983          	lw	s3,40(s1)
    8000527e:	ffffd097          	auipc	ra,0xffffd
    80005282:	c24080e7          	jalr	-988(ra) # 80001ea2 <myproc>
    80005286:	4524                	lw	s1,72(a0)
    80005288:	413484b3          	sub	s1,s1,s3
    8000528c:	0014b493          	seqz	s1,s1
    80005290:	bfc1                	j	80005260 <holdingsleep+0x24>

0000000080005292 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005292:	1141                	addi	sp,sp,-16
    80005294:	e406                	sd	ra,8(sp)
    80005296:	e022                	sd	s0,0(sp)
    80005298:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000529a:	00004597          	auipc	a1,0x4
    8000529e:	5d658593          	addi	a1,a1,1494 # 80009870 <syscalls+0x248>
    800052a2:	0001e517          	auipc	a0,0x1e
    800052a6:	a2650513          	addi	a0,a0,-1498 # 80022cc8 <ftable>
    800052aa:	ffffc097          	auipc	ra,0xffffc
    800052ae:	8aa080e7          	jalr	-1878(ra) # 80000b54 <initlock>
}
    800052b2:	60a2                	ld	ra,8(sp)
    800052b4:	6402                	ld	s0,0(sp)
    800052b6:	0141                	addi	sp,sp,16
    800052b8:	8082                	ret

00000000800052ba <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800052ba:	1101                	addi	sp,sp,-32
    800052bc:	ec06                	sd	ra,24(sp)
    800052be:	e822                	sd	s0,16(sp)
    800052c0:	e426                	sd	s1,8(sp)
    800052c2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800052c4:	0001e517          	auipc	a0,0x1e
    800052c8:	a0450513          	addi	a0,a0,-1532 # 80022cc8 <ftable>
    800052cc:	ffffc097          	auipc	ra,0xffffc
    800052d0:	920080e7          	jalr	-1760(ra) # 80000bec <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800052d4:	0001e497          	auipc	s1,0x1e
    800052d8:	a0c48493          	addi	s1,s1,-1524 # 80022ce0 <ftable+0x18>
    800052dc:	0001f717          	auipc	a4,0x1f
    800052e0:	9a470713          	addi	a4,a4,-1628 # 80023c80 <ftable+0xfb8>
    if(f->ref == 0){
    800052e4:	40dc                	lw	a5,4(s1)
    800052e6:	cf99                	beqz	a5,80005304 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800052e8:	02848493          	addi	s1,s1,40
    800052ec:	fee49ce3          	bne	s1,a4,800052e4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800052f0:	0001e517          	auipc	a0,0x1e
    800052f4:	9d850513          	addi	a0,a0,-1576 # 80022cc8 <ftable>
    800052f8:	ffffc097          	auipc	ra,0xffffc
    800052fc:	9ae080e7          	jalr	-1618(ra) # 80000ca6 <release>
  return 0;
    80005300:	4481                	li	s1,0
    80005302:	a819                	j	80005318 <filealloc+0x5e>
      f->ref = 1;
    80005304:	4785                	li	a5,1
    80005306:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005308:	0001e517          	auipc	a0,0x1e
    8000530c:	9c050513          	addi	a0,a0,-1600 # 80022cc8 <ftable>
    80005310:	ffffc097          	auipc	ra,0xffffc
    80005314:	996080e7          	jalr	-1642(ra) # 80000ca6 <release>
}
    80005318:	8526                	mv	a0,s1
    8000531a:	60e2                	ld	ra,24(sp)
    8000531c:	6442                	ld	s0,16(sp)
    8000531e:	64a2                	ld	s1,8(sp)
    80005320:	6105                	addi	sp,sp,32
    80005322:	8082                	ret

0000000080005324 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005324:	1101                	addi	sp,sp,-32
    80005326:	ec06                	sd	ra,24(sp)
    80005328:	e822                	sd	s0,16(sp)
    8000532a:	e426                	sd	s1,8(sp)
    8000532c:	1000                	addi	s0,sp,32
    8000532e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005330:	0001e517          	auipc	a0,0x1e
    80005334:	99850513          	addi	a0,a0,-1640 # 80022cc8 <ftable>
    80005338:	ffffc097          	auipc	ra,0xffffc
    8000533c:	8b4080e7          	jalr	-1868(ra) # 80000bec <acquire>
  if(f->ref < 1)
    80005340:	40dc                	lw	a5,4(s1)
    80005342:	02f05263          	blez	a5,80005366 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005346:	2785                	addiw	a5,a5,1
    80005348:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000534a:	0001e517          	auipc	a0,0x1e
    8000534e:	97e50513          	addi	a0,a0,-1666 # 80022cc8 <ftable>
    80005352:	ffffc097          	auipc	ra,0xffffc
    80005356:	954080e7          	jalr	-1708(ra) # 80000ca6 <release>
  return f;
}
    8000535a:	8526                	mv	a0,s1
    8000535c:	60e2                	ld	ra,24(sp)
    8000535e:	6442                	ld	s0,16(sp)
    80005360:	64a2                	ld	s1,8(sp)
    80005362:	6105                	addi	sp,sp,32
    80005364:	8082                	ret
    panic("filedup");
    80005366:	00004517          	auipc	a0,0x4
    8000536a:	51250513          	addi	a0,a0,1298 # 80009878 <syscalls+0x250>
    8000536e:	ffffb097          	auipc	ra,0xffffb
    80005372:	1d0080e7          	jalr	464(ra) # 8000053e <panic>

0000000080005376 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005376:	7139                	addi	sp,sp,-64
    80005378:	fc06                	sd	ra,56(sp)
    8000537a:	f822                	sd	s0,48(sp)
    8000537c:	f426                	sd	s1,40(sp)
    8000537e:	f04a                	sd	s2,32(sp)
    80005380:	ec4e                	sd	s3,24(sp)
    80005382:	e852                	sd	s4,16(sp)
    80005384:	e456                	sd	s5,8(sp)
    80005386:	0080                	addi	s0,sp,64
    80005388:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000538a:	0001e517          	auipc	a0,0x1e
    8000538e:	93e50513          	addi	a0,a0,-1730 # 80022cc8 <ftable>
    80005392:	ffffc097          	auipc	ra,0xffffc
    80005396:	85a080e7          	jalr	-1958(ra) # 80000bec <acquire>
  if(f->ref < 1)
    8000539a:	40dc                	lw	a5,4(s1)
    8000539c:	06f05163          	blez	a5,800053fe <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800053a0:	37fd                	addiw	a5,a5,-1
    800053a2:	0007871b          	sext.w	a4,a5
    800053a6:	c0dc                	sw	a5,4(s1)
    800053a8:	06e04363          	bgtz	a4,8000540e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800053ac:	0004a903          	lw	s2,0(s1)
    800053b0:	0094ca83          	lbu	s5,9(s1)
    800053b4:	0104ba03          	ld	s4,16(s1)
    800053b8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800053bc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800053c0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800053c4:	0001e517          	auipc	a0,0x1e
    800053c8:	90450513          	addi	a0,a0,-1788 # 80022cc8 <ftable>
    800053cc:	ffffc097          	auipc	ra,0xffffc
    800053d0:	8da080e7          	jalr	-1830(ra) # 80000ca6 <release>

  if(ff.type == FD_PIPE){
    800053d4:	4785                	li	a5,1
    800053d6:	04f90d63          	beq	s2,a5,80005430 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800053da:	3979                	addiw	s2,s2,-2
    800053dc:	4785                	li	a5,1
    800053de:	0527e063          	bltu	a5,s2,8000541e <fileclose+0xa8>
    begin_op();
    800053e2:	00000097          	auipc	ra,0x0
    800053e6:	ac8080e7          	jalr	-1336(ra) # 80004eaa <begin_op>
    iput(ff.ip);
    800053ea:	854e                	mv	a0,s3
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	2a6080e7          	jalr	678(ra) # 80004692 <iput>
    end_op();
    800053f4:	00000097          	auipc	ra,0x0
    800053f8:	b36080e7          	jalr	-1226(ra) # 80004f2a <end_op>
    800053fc:	a00d                	j	8000541e <fileclose+0xa8>
    panic("fileclose");
    800053fe:	00004517          	auipc	a0,0x4
    80005402:	48250513          	addi	a0,a0,1154 # 80009880 <syscalls+0x258>
    80005406:	ffffb097          	auipc	ra,0xffffb
    8000540a:	138080e7          	jalr	312(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000540e:	0001e517          	auipc	a0,0x1e
    80005412:	8ba50513          	addi	a0,a0,-1862 # 80022cc8 <ftable>
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	890080e7          	jalr	-1904(ra) # 80000ca6 <release>
  }
}
    8000541e:	70e2                	ld	ra,56(sp)
    80005420:	7442                	ld	s0,48(sp)
    80005422:	74a2                	ld	s1,40(sp)
    80005424:	7902                	ld	s2,32(sp)
    80005426:	69e2                	ld	s3,24(sp)
    80005428:	6a42                	ld	s4,16(sp)
    8000542a:	6aa2                	ld	s5,8(sp)
    8000542c:	6121                	addi	sp,sp,64
    8000542e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005430:	85d6                	mv	a1,s5
    80005432:	8552                	mv	a0,s4
    80005434:	00000097          	auipc	ra,0x0
    80005438:	34c080e7          	jalr	844(ra) # 80005780 <pipeclose>
    8000543c:	b7cd                	j	8000541e <fileclose+0xa8>

000000008000543e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000543e:	715d                	addi	sp,sp,-80
    80005440:	e486                	sd	ra,72(sp)
    80005442:	e0a2                	sd	s0,64(sp)
    80005444:	fc26                	sd	s1,56(sp)
    80005446:	f84a                	sd	s2,48(sp)
    80005448:	f44e                	sd	s3,40(sp)
    8000544a:	0880                	addi	s0,sp,80
    8000544c:	84aa                	mv	s1,a0
    8000544e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005450:	ffffd097          	auipc	ra,0xffffd
    80005454:	a52080e7          	jalr	-1454(ra) # 80001ea2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005458:	409c                	lw	a5,0(s1)
    8000545a:	37f9                	addiw	a5,a5,-2
    8000545c:	4705                	li	a4,1
    8000545e:	04f76763          	bltu	a4,a5,800054ac <filestat+0x6e>
    80005462:	892a                	mv	s2,a0
    ilock(f->ip);
    80005464:	6c88                	ld	a0,24(s1)
    80005466:	fffff097          	auipc	ra,0xfffff
    8000546a:	072080e7          	jalr	114(ra) # 800044d8 <ilock>
    stati(f->ip, &st);
    8000546e:	fb840593          	addi	a1,s0,-72
    80005472:	6c88                	ld	a0,24(s1)
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	2ee080e7          	jalr	750(ra) # 80004762 <stati>
    iunlock(f->ip);
    8000547c:	6c88                	ld	a0,24(s1)
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	11c080e7          	jalr	284(ra) # 8000459a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005486:	46e1                	li	a3,24
    80005488:	fb840613          	addi	a2,s0,-72
    8000548c:	85ce                	mv	a1,s3
    8000548e:	07893503          	ld	a0,120(s2)
    80005492:	ffffc097          	auipc	ra,0xffffc
    80005496:	1ee080e7          	jalr	494(ra) # 80001680 <copyout>
    8000549a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000549e:	60a6                	ld	ra,72(sp)
    800054a0:	6406                	ld	s0,64(sp)
    800054a2:	74e2                	ld	s1,56(sp)
    800054a4:	7942                	ld	s2,48(sp)
    800054a6:	79a2                	ld	s3,40(sp)
    800054a8:	6161                	addi	sp,sp,80
    800054aa:	8082                	ret
  return -1;
    800054ac:	557d                	li	a0,-1
    800054ae:	bfc5                	j	8000549e <filestat+0x60>

00000000800054b0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800054b0:	7179                	addi	sp,sp,-48
    800054b2:	f406                	sd	ra,40(sp)
    800054b4:	f022                	sd	s0,32(sp)
    800054b6:	ec26                	sd	s1,24(sp)
    800054b8:	e84a                	sd	s2,16(sp)
    800054ba:	e44e                	sd	s3,8(sp)
    800054bc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800054be:	00854783          	lbu	a5,8(a0)
    800054c2:	c3d5                	beqz	a5,80005566 <fileread+0xb6>
    800054c4:	84aa                	mv	s1,a0
    800054c6:	89ae                	mv	s3,a1
    800054c8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800054ca:	411c                	lw	a5,0(a0)
    800054cc:	4705                	li	a4,1
    800054ce:	04e78963          	beq	a5,a4,80005520 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054d2:	470d                	li	a4,3
    800054d4:	04e78d63          	beq	a5,a4,8000552e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800054d8:	4709                	li	a4,2
    800054da:	06e79e63          	bne	a5,a4,80005556 <fileread+0xa6>
    ilock(f->ip);
    800054de:	6d08                	ld	a0,24(a0)
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	ff8080e7          	jalr	-8(ra) # 800044d8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800054e8:	874a                	mv	a4,s2
    800054ea:	5094                	lw	a3,32(s1)
    800054ec:	864e                	mv	a2,s3
    800054ee:	4585                	li	a1,1
    800054f0:	6c88                	ld	a0,24(s1)
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	29a080e7          	jalr	666(ra) # 8000478c <readi>
    800054fa:	892a                	mv	s2,a0
    800054fc:	00a05563          	blez	a0,80005506 <fileread+0x56>
      f->off += r;
    80005500:	509c                	lw	a5,32(s1)
    80005502:	9fa9                	addw	a5,a5,a0
    80005504:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005506:	6c88                	ld	a0,24(s1)
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	092080e7          	jalr	146(ra) # 8000459a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005510:	854a                	mv	a0,s2
    80005512:	70a2                	ld	ra,40(sp)
    80005514:	7402                	ld	s0,32(sp)
    80005516:	64e2                	ld	s1,24(sp)
    80005518:	6942                	ld	s2,16(sp)
    8000551a:	69a2                	ld	s3,8(sp)
    8000551c:	6145                	addi	sp,sp,48
    8000551e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005520:	6908                	ld	a0,16(a0)
    80005522:	00000097          	auipc	ra,0x0
    80005526:	3c8080e7          	jalr	968(ra) # 800058ea <piperead>
    8000552a:	892a                	mv	s2,a0
    8000552c:	b7d5                	j	80005510 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000552e:	02451783          	lh	a5,36(a0)
    80005532:	03079693          	slli	a3,a5,0x30
    80005536:	92c1                	srli	a3,a3,0x30
    80005538:	4725                	li	a4,9
    8000553a:	02d76863          	bltu	a4,a3,8000556a <fileread+0xba>
    8000553e:	0792                	slli	a5,a5,0x4
    80005540:	0001d717          	auipc	a4,0x1d
    80005544:	6e870713          	addi	a4,a4,1768 # 80022c28 <devsw>
    80005548:	97ba                	add	a5,a5,a4
    8000554a:	639c                	ld	a5,0(a5)
    8000554c:	c38d                	beqz	a5,8000556e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000554e:	4505                	li	a0,1
    80005550:	9782                	jalr	a5
    80005552:	892a                	mv	s2,a0
    80005554:	bf75                	j	80005510 <fileread+0x60>
    panic("fileread");
    80005556:	00004517          	auipc	a0,0x4
    8000555a:	33a50513          	addi	a0,a0,826 # 80009890 <syscalls+0x268>
    8000555e:	ffffb097          	auipc	ra,0xffffb
    80005562:	fe0080e7          	jalr	-32(ra) # 8000053e <panic>
    return -1;
    80005566:	597d                	li	s2,-1
    80005568:	b765                	j	80005510 <fileread+0x60>
      return -1;
    8000556a:	597d                	li	s2,-1
    8000556c:	b755                	j	80005510 <fileread+0x60>
    8000556e:	597d                	li	s2,-1
    80005570:	b745                	j	80005510 <fileread+0x60>

0000000080005572 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005572:	715d                	addi	sp,sp,-80
    80005574:	e486                	sd	ra,72(sp)
    80005576:	e0a2                	sd	s0,64(sp)
    80005578:	fc26                	sd	s1,56(sp)
    8000557a:	f84a                	sd	s2,48(sp)
    8000557c:	f44e                	sd	s3,40(sp)
    8000557e:	f052                	sd	s4,32(sp)
    80005580:	ec56                	sd	s5,24(sp)
    80005582:	e85a                	sd	s6,16(sp)
    80005584:	e45e                	sd	s7,8(sp)
    80005586:	e062                	sd	s8,0(sp)
    80005588:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000558a:	00954783          	lbu	a5,9(a0)
    8000558e:	10078663          	beqz	a5,8000569a <filewrite+0x128>
    80005592:	892a                	mv	s2,a0
    80005594:	8aae                	mv	s5,a1
    80005596:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005598:	411c                	lw	a5,0(a0)
    8000559a:	4705                	li	a4,1
    8000559c:	02e78263          	beq	a5,a4,800055c0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800055a0:	470d                	li	a4,3
    800055a2:	02e78663          	beq	a5,a4,800055ce <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800055a6:	4709                	li	a4,2
    800055a8:	0ee79163          	bne	a5,a4,8000568a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800055ac:	0ac05d63          	blez	a2,80005666 <filewrite+0xf4>
    int i = 0;
    800055b0:	4981                	li	s3,0
    800055b2:	6b05                	lui	s6,0x1
    800055b4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800055b8:	6b85                	lui	s7,0x1
    800055ba:	c00b8b9b          	addiw	s7,s7,-1024
    800055be:	a861                	j	80005656 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800055c0:	6908                	ld	a0,16(a0)
    800055c2:	00000097          	auipc	ra,0x0
    800055c6:	22e080e7          	jalr	558(ra) # 800057f0 <pipewrite>
    800055ca:	8a2a                	mv	s4,a0
    800055cc:	a045                	j	8000566c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800055ce:	02451783          	lh	a5,36(a0)
    800055d2:	03079693          	slli	a3,a5,0x30
    800055d6:	92c1                	srli	a3,a3,0x30
    800055d8:	4725                	li	a4,9
    800055da:	0cd76263          	bltu	a4,a3,8000569e <filewrite+0x12c>
    800055de:	0792                	slli	a5,a5,0x4
    800055e0:	0001d717          	auipc	a4,0x1d
    800055e4:	64870713          	addi	a4,a4,1608 # 80022c28 <devsw>
    800055e8:	97ba                	add	a5,a5,a4
    800055ea:	679c                	ld	a5,8(a5)
    800055ec:	cbdd                	beqz	a5,800056a2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800055ee:	4505                	li	a0,1
    800055f0:	9782                	jalr	a5
    800055f2:	8a2a                	mv	s4,a0
    800055f4:	a8a5                	j	8000566c <filewrite+0xfa>
    800055f6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800055fa:	00000097          	auipc	ra,0x0
    800055fe:	8b0080e7          	jalr	-1872(ra) # 80004eaa <begin_op>
      ilock(f->ip);
    80005602:	01893503          	ld	a0,24(s2)
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	ed2080e7          	jalr	-302(ra) # 800044d8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000560e:	8762                	mv	a4,s8
    80005610:	02092683          	lw	a3,32(s2)
    80005614:	01598633          	add	a2,s3,s5
    80005618:	4585                	li	a1,1
    8000561a:	01893503          	ld	a0,24(s2)
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	266080e7          	jalr	614(ra) # 80004884 <writei>
    80005626:	84aa                	mv	s1,a0
    80005628:	00a05763          	blez	a0,80005636 <filewrite+0xc4>
        f->off += r;
    8000562c:	02092783          	lw	a5,32(s2)
    80005630:	9fa9                	addw	a5,a5,a0
    80005632:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005636:	01893503          	ld	a0,24(s2)
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	f60080e7          	jalr	-160(ra) # 8000459a <iunlock>
      end_op();
    80005642:	00000097          	auipc	ra,0x0
    80005646:	8e8080e7          	jalr	-1816(ra) # 80004f2a <end_op>

      if(r != n1){
    8000564a:	009c1f63          	bne	s8,s1,80005668 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000564e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005652:	0149db63          	bge	s3,s4,80005668 <filewrite+0xf6>
      int n1 = n - i;
    80005656:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000565a:	84be                	mv	s1,a5
    8000565c:	2781                	sext.w	a5,a5
    8000565e:	f8fb5ce3          	bge	s6,a5,800055f6 <filewrite+0x84>
    80005662:	84de                	mv	s1,s7
    80005664:	bf49                	j	800055f6 <filewrite+0x84>
    int i = 0;
    80005666:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005668:	013a1f63          	bne	s4,s3,80005686 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000566c:	8552                	mv	a0,s4
    8000566e:	60a6                	ld	ra,72(sp)
    80005670:	6406                	ld	s0,64(sp)
    80005672:	74e2                	ld	s1,56(sp)
    80005674:	7942                	ld	s2,48(sp)
    80005676:	79a2                	ld	s3,40(sp)
    80005678:	7a02                	ld	s4,32(sp)
    8000567a:	6ae2                	ld	s5,24(sp)
    8000567c:	6b42                	ld	s6,16(sp)
    8000567e:	6ba2                	ld	s7,8(sp)
    80005680:	6c02                	ld	s8,0(sp)
    80005682:	6161                	addi	sp,sp,80
    80005684:	8082                	ret
    ret = (i == n ? n : -1);
    80005686:	5a7d                	li	s4,-1
    80005688:	b7d5                	j	8000566c <filewrite+0xfa>
    panic("filewrite");
    8000568a:	00004517          	auipc	a0,0x4
    8000568e:	21650513          	addi	a0,a0,534 # 800098a0 <syscalls+0x278>
    80005692:	ffffb097          	auipc	ra,0xffffb
    80005696:	eac080e7          	jalr	-340(ra) # 8000053e <panic>
    return -1;
    8000569a:	5a7d                	li	s4,-1
    8000569c:	bfc1                	j	8000566c <filewrite+0xfa>
      return -1;
    8000569e:	5a7d                	li	s4,-1
    800056a0:	b7f1                	j	8000566c <filewrite+0xfa>
    800056a2:	5a7d                	li	s4,-1
    800056a4:	b7e1                	j	8000566c <filewrite+0xfa>

00000000800056a6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800056a6:	7179                	addi	sp,sp,-48
    800056a8:	f406                	sd	ra,40(sp)
    800056aa:	f022                	sd	s0,32(sp)
    800056ac:	ec26                	sd	s1,24(sp)
    800056ae:	e84a                	sd	s2,16(sp)
    800056b0:	e44e                	sd	s3,8(sp)
    800056b2:	e052                	sd	s4,0(sp)
    800056b4:	1800                	addi	s0,sp,48
    800056b6:	84aa                	mv	s1,a0
    800056b8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800056ba:	0005b023          	sd	zero,0(a1)
    800056be:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800056c2:	00000097          	auipc	ra,0x0
    800056c6:	bf8080e7          	jalr	-1032(ra) # 800052ba <filealloc>
    800056ca:	e088                	sd	a0,0(s1)
    800056cc:	c551                	beqz	a0,80005758 <pipealloc+0xb2>
    800056ce:	00000097          	auipc	ra,0x0
    800056d2:	bec080e7          	jalr	-1044(ra) # 800052ba <filealloc>
    800056d6:	00aa3023          	sd	a0,0(s4)
    800056da:	c92d                	beqz	a0,8000574c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800056dc:	ffffb097          	auipc	ra,0xffffb
    800056e0:	418080e7          	jalr	1048(ra) # 80000af4 <kalloc>
    800056e4:	892a                	mv	s2,a0
    800056e6:	c125                	beqz	a0,80005746 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800056e8:	4985                	li	s3,1
    800056ea:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800056ee:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800056f2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800056f6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800056fa:	00004597          	auipc	a1,0x4
    800056fe:	1b658593          	addi	a1,a1,438 # 800098b0 <syscalls+0x288>
    80005702:	ffffb097          	auipc	ra,0xffffb
    80005706:	452080e7          	jalr	1106(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000570a:	609c                	ld	a5,0(s1)
    8000570c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005710:	609c                	ld	a5,0(s1)
    80005712:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005716:	609c                	ld	a5,0(s1)
    80005718:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000571c:	609c                	ld	a5,0(s1)
    8000571e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005722:	000a3783          	ld	a5,0(s4)
    80005726:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000572a:	000a3783          	ld	a5,0(s4)
    8000572e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005732:	000a3783          	ld	a5,0(s4)
    80005736:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000573a:	000a3783          	ld	a5,0(s4)
    8000573e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005742:	4501                	li	a0,0
    80005744:	a025                	j	8000576c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005746:	6088                	ld	a0,0(s1)
    80005748:	e501                	bnez	a0,80005750 <pipealloc+0xaa>
    8000574a:	a039                	j	80005758 <pipealloc+0xb2>
    8000574c:	6088                	ld	a0,0(s1)
    8000574e:	c51d                	beqz	a0,8000577c <pipealloc+0xd6>
    fileclose(*f0);
    80005750:	00000097          	auipc	ra,0x0
    80005754:	c26080e7          	jalr	-986(ra) # 80005376 <fileclose>
  if(*f1)
    80005758:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000575c:	557d                	li	a0,-1
  if(*f1)
    8000575e:	c799                	beqz	a5,8000576c <pipealloc+0xc6>
    fileclose(*f1);
    80005760:	853e                	mv	a0,a5
    80005762:	00000097          	auipc	ra,0x0
    80005766:	c14080e7          	jalr	-1004(ra) # 80005376 <fileclose>
  return -1;
    8000576a:	557d                	li	a0,-1
}
    8000576c:	70a2                	ld	ra,40(sp)
    8000576e:	7402                	ld	s0,32(sp)
    80005770:	64e2                	ld	s1,24(sp)
    80005772:	6942                	ld	s2,16(sp)
    80005774:	69a2                	ld	s3,8(sp)
    80005776:	6a02                	ld	s4,0(sp)
    80005778:	6145                	addi	sp,sp,48
    8000577a:	8082                	ret
  return -1;
    8000577c:	557d                	li	a0,-1
    8000577e:	b7fd                	j	8000576c <pipealloc+0xc6>

0000000080005780 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005780:	1101                	addi	sp,sp,-32
    80005782:	ec06                	sd	ra,24(sp)
    80005784:	e822                	sd	s0,16(sp)
    80005786:	e426                	sd	s1,8(sp)
    80005788:	e04a                	sd	s2,0(sp)
    8000578a:	1000                	addi	s0,sp,32
    8000578c:	84aa                	mv	s1,a0
    8000578e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005790:	ffffb097          	auipc	ra,0xffffb
    80005794:	45c080e7          	jalr	1116(ra) # 80000bec <acquire>
  if(writable){
    80005798:	02090d63          	beqz	s2,800057d2 <pipeclose+0x52>
    pi->writeopen = 0;
    8000579c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800057a0:	21848513          	addi	a0,s1,536
    800057a4:	ffffd097          	auipc	ra,0xffffd
    800057a8:	792080e7          	jalr	1938(ra) # 80002f36 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800057ac:	2204b783          	ld	a5,544(s1)
    800057b0:	eb95                	bnez	a5,800057e4 <pipeclose+0x64>
    release(&pi->lock);
    800057b2:	8526                	mv	a0,s1
    800057b4:	ffffb097          	auipc	ra,0xffffb
    800057b8:	4f2080e7          	jalr	1266(ra) # 80000ca6 <release>
    kfree((char*)pi);
    800057bc:	8526                	mv	a0,s1
    800057be:	ffffb097          	auipc	ra,0xffffb
    800057c2:	23a080e7          	jalr	570(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800057c6:	60e2                	ld	ra,24(sp)
    800057c8:	6442                	ld	s0,16(sp)
    800057ca:	64a2                	ld	s1,8(sp)
    800057cc:	6902                	ld	s2,0(sp)
    800057ce:	6105                	addi	sp,sp,32
    800057d0:	8082                	ret
    pi->readopen = 0;
    800057d2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800057d6:	21c48513          	addi	a0,s1,540
    800057da:	ffffd097          	auipc	ra,0xffffd
    800057de:	75c080e7          	jalr	1884(ra) # 80002f36 <wakeup>
    800057e2:	b7e9                	j	800057ac <pipeclose+0x2c>
    release(&pi->lock);
    800057e4:	8526                	mv	a0,s1
    800057e6:	ffffb097          	auipc	ra,0xffffb
    800057ea:	4c0080e7          	jalr	1216(ra) # 80000ca6 <release>
}
    800057ee:	bfe1                	j	800057c6 <pipeclose+0x46>

00000000800057f0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800057f0:	7159                	addi	sp,sp,-112
    800057f2:	f486                	sd	ra,104(sp)
    800057f4:	f0a2                	sd	s0,96(sp)
    800057f6:	eca6                	sd	s1,88(sp)
    800057f8:	e8ca                	sd	s2,80(sp)
    800057fa:	e4ce                	sd	s3,72(sp)
    800057fc:	e0d2                	sd	s4,64(sp)
    800057fe:	fc56                	sd	s5,56(sp)
    80005800:	f85a                	sd	s6,48(sp)
    80005802:	f45e                	sd	s7,40(sp)
    80005804:	f062                	sd	s8,32(sp)
    80005806:	ec66                	sd	s9,24(sp)
    80005808:	1880                	addi	s0,sp,112
    8000580a:	84aa                	mv	s1,a0
    8000580c:	8aae                	mv	s5,a1
    8000580e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005810:	ffffc097          	auipc	ra,0xffffc
    80005814:	692080e7          	jalr	1682(ra) # 80001ea2 <myproc>
    80005818:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffb097          	auipc	ra,0xffffb
    80005820:	3d0080e7          	jalr	976(ra) # 80000bec <acquire>
  while(i < n){
    80005824:	0d405163          	blez	s4,800058e6 <pipewrite+0xf6>
    80005828:	8ba6                	mv	s7,s1
  int i = 0;
    8000582a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000582c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000582e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005832:	21c48c13          	addi	s8,s1,540
    80005836:	a08d                	j	80005898 <pipewrite+0xa8>
      release(&pi->lock);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffb097          	auipc	ra,0xffffb
    8000583e:	46c080e7          	jalr	1132(ra) # 80000ca6 <release>
      return -1;
    80005842:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005844:	854a                	mv	a0,s2
    80005846:	70a6                	ld	ra,104(sp)
    80005848:	7406                	ld	s0,96(sp)
    8000584a:	64e6                	ld	s1,88(sp)
    8000584c:	6946                	ld	s2,80(sp)
    8000584e:	69a6                	ld	s3,72(sp)
    80005850:	6a06                	ld	s4,64(sp)
    80005852:	7ae2                	ld	s5,56(sp)
    80005854:	7b42                	ld	s6,48(sp)
    80005856:	7ba2                	ld	s7,40(sp)
    80005858:	7c02                	ld	s8,32(sp)
    8000585a:	6ce2                	ld	s9,24(sp)
    8000585c:	6165                	addi	sp,sp,112
    8000585e:	8082                	ret
      wakeup(&pi->nread);
    80005860:	8566                	mv	a0,s9
    80005862:	ffffd097          	auipc	ra,0xffffd
    80005866:	6d4080e7          	jalr	1748(ra) # 80002f36 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000586a:	85de                	mv	a1,s7
    8000586c:	8562                	mv	a0,s8
    8000586e:	ffffd097          	auipc	ra,0xffffd
    80005872:	520080e7          	jalr	1312(ra) # 80002d8e <sleep>
    80005876:	a839                	j	80005894 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005878:	21c4a783          	lw	a5,540(s1)
    8000587c:	0017871b          	addiw	a4,a5,1
    80005880:	20e4ae23          	sw	a4,540(s1)
    80005884:	1ff7f793          	andi	a5,a5,511
    80005888:	97a6                	add	a5,a5,s1
    8000588a:	f9f44703          	lbu	a4,-97(s0)
    8000588e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005892:	2905                	addiw	s2,s2,1
  while(i < n){
    80005894:	03495d63          	bge	s2,s4,800058ce <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005898:	2204a783          	lw	a5,544(s1)
    8000589c:	dfd1                	beqz	a5,80005838 <pipewrite+0x48>
    8000589e:	0409a783          	lw	a5,64(s3)
    800058a2:	fbd9                	bnez	a5,80005838 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800058a4:	2184a783          	lw	a5,536(s1)
    800058a8:	21c4a703          	lw	a4,540(s1)
    800058ac:	2007879b          	addiw	a5,a5,512
    800058b0:	faf708e3          	beq	a4,a5,80005860 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800058b4:	4685                	li	a3,1
    800058b6:	01590633          	add	a2,s2,s5
    800058ba:	f9f40593          	addi	a1,s0,-97
    800058be:	0789b503          	ld	a0,120(s3)
    800058c2:	ffffc097          	auipc	ra,0xffffc
    800058c6:	e4a080e7          	jalr	-438(ra) # 8000170c <copyin>
    800058ca:	fb6517e3          	bne	a0,s6,80005878 <pipewrite+0x88>
  wakeup(&pi->nread);
    800058ce:	21848513          	addi	a0,s1,536
    800058d2:	ffffd097          	auipc	ra,0xffffd
    800058d6:	664080e7          	jalr	1636(ra) # 80002f36 <wakeup>
  release(&pi->lock);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	3ca080e7          	jalr	970(ra) # 80000ca6 <release>
  return i;
    800058e4:	b785                	j	80005844 <pipewrite+0x54>
  int i = 0;
    800058e6:	4901                	li	s2,0
    800058e8:	b7dd                	j	800058ce <pipewrite+0xde>

00000000800058ea <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800058ea:	715d                	addi	sp,sp,-80
    800058ec:	e486                	sd	ra,72(sp)
    800058ee:	e0a2                	sd	s0,64(sp)
    800058f0:	fc26                	sd	s1,56(sp)
    800058f2:	f84a                	sd	s2,48(sp)
    800058f4:	f44e                	sd	s3,40(sp)
    800058f6:	f052                	sd	s4,32(sp)
    800058f8:	ec56                	sd	s5,24(sp)
    800058fa:	e85a                	sd	s6,16(sp)
    800058fc:	0880                	addi	s0,sp,80
    800058fe:	84aa                	mv	s1,a0
    80005900:	892e                	mv	s2,a1
    80005902:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005904:	ffffc097          	auipc	ra,0xffffc
    80005908:	59e080e7          	jalr	1438(ra) # 80001ea2 <myproc>
    8000590c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000590e:	8b26                	mv	s6,s1
    80005910:	8526                	mv	a0,s1
    80005912:	ffffb097          	auipc	ra,0xffffb
    80005916:	2da080e7          	jalr	730(ra) # 80000bec <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000591a:	2184a703          	lw	a4,536(s1)
    8000591e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005922:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005926:	02f71463          	bne	a4,a5,8000594e <piperead+0x64>
    8000592a:	2244a783          	lw	a5,548(s1)
    8000592e:	c385                	beqz	a5,8000594e <piperead+0x64>
    if(pr->killed){
    80005930:	040a2783          	lw	a5,64(s4)
    80005934:	ebc1                	bnez	a5,800059c4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005936:	85da                	mv	a1,s6
    80005938:	854e                	mv	a0,s3
    8000593a:	ffffd097          	auipc	ra,0xffffd
    8000593e:	454080e7          	jalr	1108(ra) # 80002d8e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005942:	2184a703          	lw	a4,536(s1)
    80005946:	21c4a783          	lw	a5,540(s1)
    8000594a:	fef700e3          	beq	a4,a5,8000592a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000594e:	09505263          	blez	s5,800059d2 <piperead+0xe8>
    80005952:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005954:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005956:	2184a783          	lw	a5,536(s1)
    8000595a:	21c4a703          	lw	a4,540(s1)
    8000595e:	02f70d63          	beq	a4,a5,80005998 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005962:	0017871b          	addiw	a4,a5,1
    80005966:	20e4ac23          	sw	a4,536(s1)
    8000596a:	1ff7f793          	andi	a5,a5,511
    8000596e:	97a6                	add	a5,a5,s1
    80005970:	0187c783          	lbu	a5,24(a5)
    80005974:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005978:	4685                	li	a3,1
    8000597a:	fbf40613          	addi	a2,s0,-65
    8000597e:	85ca                	mv	a1,s2
    80005980:	078a3503          	ld	a0,120(s4)
    80005984:	ffffc097          	auipc	ra,0xffffc
    80005988:	cfc080e7          	jalr	-772(ra) # 80001680 <copyout>
    8000598c:	01650663          	beq	a0,s6,80005998 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005990:	2985                	addiw	s3,s3,1
    80005992:	0905                	addi	s2,s2,1
    80005994:	fd3a91e3          	bne	s5,s3,80005956 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005998:	21c48513          	addi	a0,s1,540
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	59a080e7          	jalr	1434(ra) # 80002f36 <wakeup>
  release(&pi->lock);
    800059a4:	8526                	mv	a0,s1
    800059a6:	ffffb097          	auipc	ra,0xffffb
    800059aa:	300080e7          	jalr	768(ra) # 80000ca6 <release>
  return i;
}
    800059ae:	854e                	mv	a0,s3
    800059b0:	60a6                	ld	ra,72(sp)
    800059b2:	6406                	ld	s0,64(sp)
    800059b4:	74e2                	ld	s1,56(sp)
    800059b6:	7942                	ld	s2,48(sp)
    800059b8:	79a2                	ld	s3,40(sp)
    800059ba:	7a02                	ld	s4,32(sp)
    800059bc:	6ae2                	ld	s5,24(sp)
    800059be:	6b42                	ld	s6,16(sp)
    800059c0:	6161                	addi	sp,sp,80
    800059c2:	8082                	ret
      release(&pi->lock);
    800059c4:	8526                	mv	a0,s1
    800059c6:	ffffb097          	auipc	ra,0xffffb
    800059ca:	2e0080e7          	jalr	736(ra) # 80000ca6 <release>
      return -1;
    800059ce:	59fd                	li	s3,-1
    800059d0:	bff9                	j	800059ae <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800059d2:	4981                	li	s3,0
    800059d4:	b7d1                	j	80005998 <piperead+0xae>

00000000800059d6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800059d6:	df010113          	addi	sp,sp,-528
    800059da:	20113423          	sd	ra,520(sp)
    800059de:	20813023          	sd	s0,512(sp)
    800059e2:	ffa6                	sd	s1,504(sp)
    800059e4:	fbca                	sd	s2,496(sp)
    800059e6:	f7ce                	sd	s3,488(sp)
    800059e8:	f3d2                	sd	s4,480(sp)
    800059ea:	efd6                	sd	s5,472(sp)
    800059ec:	ebda                	sd	s6,464(sp)
    800059ee:	e7de                	sd	s7,456(sp)
    800059f0:	e3e2                	sd	s8,448(sp)
    800059f2:	ff66                	sd	s9,440(sp)
    800059f4:	fb6a                	sd	s10,432(sp)
    800059f6:	f76e                	sd	s11,424(sp)
    800059f8:	0c00                	addi	s0,sp,528
    800059fa:	84aa                	mv	s1,a0
    800059fc:	dea43c23          	sd	a0,-520(s0)
    80005a00:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005a04:	ffffc097          	auipc	ra,0xffffc
    80005a08:	49e080e7          	jalr	1182(ra) # 80001ea2 <myproc>
    80005a0c:	892a                	mv	s2,a0

  begin_op();
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	49c080e7          	jalr	1180(ra) # 80004eaa <begin_op>

  if((ip = namei(path)) == 0){
    80005a16:	8526                	mv	a0,s1
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	276080e7          	jalr	630(ra) # 80004c8e <namei>
    80005a20:	c92d                	beqz	a0,80005a92 <exec+0xbc>
    80005a22:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	ab4080e7          	jalr	-1356(ra) # 800044d8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005a2c:	04000713          	li	a4,64
    80005a30:	4681                	li	a3,0
    80005a32:	e5040613          	addi	a2,s0,-432
    80005a36:	4581                	li	a1,0
    80005a38:	8526                	mv	a0,s1
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	d52080e7          	jalr	-686(ra) # 8000478c <readi>
    80005a42:	04000793          	li	a5,64
    80005a46:	00f51a63          	bne	a0,a5,80005a5a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005a4a:	e5042703          	lw	a4,-432(s0)
    80005a4e:	464c47b7          	lui	a5,0x464c4
    80005a52:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005a56:	04f70463          	beq	a4,a5,80005a9e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005a5a:	8526                	mv	a0,s1
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	cde080e7          	jalr	-802(ra) # 8000473a <iunlockput>
    end_op();
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	4c6080e7          	jalr	1222(ra) # 80004f2a <end_op>
  }
  return -1;
    80005a6c:	557d                	li	a0,-1
}
    80005a6e:	20813083          	ld	ra,520(sp)
    80005a72:	20013403          	ld	s0,512(sp)
    80005a76:	74fe                	ld	s1,504(sp)
    80005a78:	795e                	ld	s2,496(sp)
    80005a7a:	79be                	ld	s3,488(sp)
    80005a7c:	7a1e                	ld	s4,480(sp)
    80005a7e:	6afe                	ld	s5,472(sp)
    80005a80:	6b5e                	ld	s6,464(sp)
    80005a82:	6bbe                	ld	s7,456(sp)
    80005a84:	6c1e                	ld	s8,448(sp)
    80005a86:	7cfa                	ld	s9,440(sp)
    80005a88:	7d5a                	ld	s10,432(sp)
    80005a8a:	7dba                	ld	s11,424(sp)
    80005a8c:	21010113          	addi	sp,sp,528
    80005a90:	8082                	ret
    end_op();
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	498080e7          	jalr	1176(ra) # 80004f2a <end_op>
    return -1;
    80005a9a:	557d                	li	a0,-1
    80005a9c:	bfc9                	j	80005a6e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005a9e:	854a                	mv	a0,s2
    80005aa0:	ffffc097          	auipc	ra,0xffffc
    80005aa4:	4da080e7          	jalr	1242(ra) # 80001f7a <proc_pagetable>
    80005aa8:	8baa                	mv	s7,a0
    80005aaa:	d945                	beqz	a0,80005a5a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005aac:	e7042983          	lw	s3,-400(s0)
    80005ab0:	e8845783          	lhu	a5,-376(s0)
    80005ab4:	c7ad                	beqz	a5,80005b1e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005ab6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005ab8:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005aba:	6c85                	lui	s9,0x1
    80005abc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005ac0:	def43823          	sd	a5,-528(s0)
    80005ac4:	a42d                	j	80005cee <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005ac6:	00004517          	auipc	a0,0x4
    80005aca:	df250513          	addi	a0,a0,-526 # 800098b8 <syscalls+0x290>
    80005ace:	ffffb097          	auipc	ra,0xffffb
    80005ad2:	a70080e7          	jalr	-1424(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005ad6:	8756                	mv	a4,s5
    80005ad8:	012d86bb          	addw	a3,s11,s2
    80005adc:	4581                	li	a1,0
    80005ade:	8526                	mv	a0,s1
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	cac080e7          	jalr	-852(ra) # 8000478c <readi>
    80005ae8:	2501                	sext.w	a0,a0
    80005aea:	1aaa9963          	bne	s5,a0,80005c9c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005aee:	6785                	lui	a5,0x1
    80005af0:	0127893b          	addw	s2,a5,s2
    80005af4:	77fd                	lui	a5,0xfffff
    80005af6:	01478a3b          	addw	s4,a5,s4
    80005afa:	1f897163          	bgeu	s2,s8,80005cdc <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005afe:	02091593          	slli	a1,s2,0x20
    80005b02:	9181                	srli	a1,a1,0x20
    80005b04:	95ea                	add	a1,a1,s10
    80005b06:	855e                	mv	a0,s7
    80005b08:	ffffb097          	auipc	ra,0xffffb
    80005b0c:	574080e7          	jalr	1396(ra) # 8000107c <walkaddr>
    80005b10:	862a                	mv	a2,a0
    if(pa == 0)
    80005b12:	d955                	beqz	a0,80005ac6 <exec+0xf0>
      n = PGSIZE;
    80005b14:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005b16:	fd9a70e3          	bgeu	s4,s9,80005ad6 <exec+0x100>
      n = sz - i;
    80005b1a:	8ad2                	mv	s5,s4
    80005b1c:	bf6d                	j	80005ad6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005b1e:	4901                	li	s2,0
  iunlockput(ip);
    80005b20:	8526                	mv	a0,s1
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	c18080e7          	jalr	-1000(ra) # 8000473a <iunlockput>
  end_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	400080e7          	jalr	1024(ra) # 80004f2a <end_op>
  p = myproc();
    80005b32:	ffffc097          	auipc	ra,0xffffc
    80005b36:	370080e7          	jalr	880(ra) # 80001ea2 <myproc>
    80005b3a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005b3c:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80005b40:	6785                	lui	a5,0x1
    80005b42:	17fd                	addi	a5,a5,-1
    80005b44:	993e                	add	s2,s2,a5
    80005b46:	757d                	lui	a0,0xfffff
    80005b48:	00a977b3          	and	a5,s2,a0
    80005b4c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b50:	6609                	lui	a2,0x2
    80005b52:	963e                	add	a2,a2,a5
    80005b54:	85be                	mv	a1,a5
    80005b56:	855e                	mv	a0,s7
    80005b58:	ffffc097          	auipc	ra,0xffffc
    80005b5c:	8d8080e7          	jalr	-1832(ra) # 80001430 <uvmalloc>
    80005b60:	8b2a                	mv	s6,a0
  ip = 0;
    80005b62:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b64:	12050c63          	beqz	a0,80005c9c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005b68:	75f9                	lui	a1,0xffffe
    80005b6a:	95aa                	add	a1,a1,a0
    80005b6c:	855e                	mv	a0,s7
    80005b6e:	ffffc097          	auipc	ra,0xffffc
    80005b72:	ae0080e7          	jalr	-1312(ra) # 8000164e <uvmclear>
  stackbase = sp - PGSIZE;
    80005b76:	7c7d                	lui	s8,0xfffff
    80005b78:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005b7a:	e0043783          	ld	a5,-512(s0)
    80005b7e:	6388                	ld	a0,0(a5)
    80005b80:	c535                	beqz	a0,80005bec <exec+0x216>
    80005b82:	e9040993          	addi	s3,s0,-368
    80005b86:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005b8a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005b8c:	ffffb097          	auipc	ra,0xffffb
    80005b90:	2e6080e7          	jalr	742(ra) # 80000e72 <strlen>
    80005b94:	2505                	addiw	a0,a0,1
    80005b96:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005b9a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005b9e:	13896363          	bltu	s2,s8,80005cc4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005ba2:	e0043d83          	ld	s11,-512(s0)
    80005ba6:	000dba03          	ld	s4,0(s11)
    80005baa:	8552                	mv	a0,s4
    80005bac:	ffffb097          	auipc	ra,0xffffb
    80005bb0:	2c6080e7          	jalr	710(ra) # 80000e72 <strlen>
    80005bb4:	0015069b          	addiw	a3,a0,1
    80005bb8:	8652                	mv	a2,s4
    80005bba:	85ca                	mv	a1,s2
    80005bbc:	855e                	mv	a0,s7
    80005bbe:	ffffc097          	auipc	ra,0xffffc
    80005bc2:	ac2080e7          	jalr	-1342(ra) # 80001680 <copyout>
    80005bc6:	10054363          	bltz	a0,80005ccc <exec+0x2f6>
    ustack[argc] = sp;
    80005bca:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005bce:	0485                	addi	s1,s1,1
    80005bd0:	008d8793          	addi	a5,s11,8
    80005bd4:	e0f43023          	sd	a5,-512(s0)
    80005bd8:	008db503          	ld	a0,8(s11)
    80005bdc:	c911                	beqz	a0,80005bf0 <exec+0x21a>
    if(argc >= MAXARG)
    80005bde:	09a1                	addi	s3,s3,8
    80005be0:	fb3c96e3          	bne	s9,s3,80005b8c <exec+0x1b6>
  sz = sz1;
    80005be4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005be8:	4481                	li	s1,0
    80005bea:	a84d                	j	80005c9c <exec+0x2c6>
  sp = sz;
    80005bec:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005bee:	4481                	li	s1,0
  ustack[argc] = 0;
    80005bf0:	00349793          	slli	a5,s1,0x3
    80005bf4:	f9040713          	addi	a4,s0,-112
    80005bf8:	97ba                	add	a5,a5,a4
    80005bfa:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005bfe:	00148693          	addi	a3,s1,1
    80005c02:	068e                	slli	a3,a3,0x3
    80005c04:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005c08:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005c0c:	01897663          	bgeu	s2,s8,80005c18 <exec+0x242>
  sz = sz1;
    80005c10:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005c14:	4481                	li	s1,0
    80005c16:	a059                	j	80005c9c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005c18:	e9040613          	addi	a2,s0,-368
    80005c1c:	85ca                	mv	a1,s2
    80005c1e:	855e                	mv	a0,s7
    80005c20:	ffffc097          	auipc	ra,0xffffc
    80005c24:	a60080e7          	jalr	-1440(ra) # 80001680 <copyout>
    80005c28:	0a054663          	bltz	a0,80005cd4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005c2c:	080ab783          	ld	a5,128(s5)
    80005c30:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005c34:	df843783          	ld	a5,-520(s0)
    80005c38:	0007c703          	lbu	a4,0(a5)
    80005c3c:	cf11                	beqz	a4,80005c58 <exec+0x282>
    80005c3e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005c40:	02f00693          	li	a3,47
    80005c44:	a039                	j	80005c52 <exec+0x27c>
      last = s+1;
    80005c46:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005c4a:	0785                	addi	a5,a5,1
    80005c4c:	fff7c703          	lbu	a4,-1(a5)
    80005c50:	c701                	beqz	a4,80005c58 <exec+0x282>
    if(*s == '/')
    80005c52:	fed71ce3          	bne	a4,a3,80005c4a <exec+0x274>
    80005c56:	bfc5                	j	80005c46 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005c58:	4641                	li	a2,16
    80005c5a:	df843583          	ld	a1,-520(s0)
    80005c5e:	180a8513          	addi	a0,s5,384
    80005c62:	ffffb097          	auipc	ra,0xffffb
    80005c66:	1de080e7          	jalr	478(ra) # 80000e40 <safestrcpy>
  oldpagetable = p->pagetable;
    80005c6a:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    80005c6e:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    80005c72:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005c76:	080ab783          	ld	a5,128(s5)
    80005c7a:	e6843703          	ld	a4,-408(s0)
    80005c7e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005c80:	080ab783          	ld	a5,128(s5)
    80005c84:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005c88:	85ea                	mv	a1,s10
    80005c8a:	ffffc097          	auipc	ra,0xffffc
    80005c8e:	38c080e7          	jalr	908(ra) # 80002016 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005c92:	0004851b          	sext.w	a0,s1
    80005c96:	bbe1                	j	80005a6e <exec+0x98>
    80005c98:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005c9c:	e0843583          	ld	a1,-504(s0)
    80005ca0:	855e                	mv	a0,s7
    80005ca2:	ffffc097          	auipc	ra,0xffffc
    80005ca6:	374080e7          	jalr	884(ra) # 80002016 <proc_freepagetable>
  if(ip){
    80005caa:	da0498e3          	bnez	s1,80005a5a <exec+0x84>
  return -1;
    80005cae:	557d                	li	a0,-1
    80005cb0:	bb7d                	j	80005a6e <exec+0x98>
    80005cb2:	e1243423          	sd	s2,-504(s0)
    80005cb6:	b7dd                	j	80005c9c <exec+0x2c6>
    80005cb8:	e1243423          	sd	s2,-504(s0)
    80005cbc:	b7c5                	j	80005c9c <exec+0x2c6>
    80005cbe:	e1243423          	sd	s2,-504(s0)
    80005cc2:	bfe9                	j	80005c9c <exec+0x2c6>
  sz = sz1;
    80005cc4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005cc8:	4481                	li	s1,0
    80005cca:	bfc9                	j	80005c9c <exec+0x2c6>
  sz = sz1;
    80005ccc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005cd0:	4481                	li	s1,0
    80005cd2:	b7e9                	j	80005c9c <exec+0x2c6>
  sz = sz1;
    80005cd4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005cd8:	4481                	li	s1,0
    80005cda:	b7c9                	j	80005c9c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005cdc:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005ce0:	2b05                	addiw	s6,s6,1
    80005ce2:	0389899b          	addiw	s3,s3,56
    80005ce6:	e8845783          	lhu	a5,-376(s0)
    80005cea:	e2fb5be3          	bge	s6,a5,80005b20 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005cee:	2981                	sext.w	s3,s3
    80005cf0:	03800713          	li	a4,56
    80005cf4:	86ce                	mv	a3,s3
    80005cf6:	e1840613          	addi	a2,s0,-488
    80005cfa:	4581                	li	a1,0
    80005cfc:	8526                	mv	a0,s1
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	a8e080e7          	jalr	-1394(ra) # 8000478c <readi>
    80005d06:	03800793          	li	a5,56
    80005d0a:	f8f517e3          	bne	a0,a5,80005c98 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005d0e:	e1842783          	lw	a5,-488(s0)
    80005d12:	4705                	li	a4,1
    80005d14:	fce796e3          	bne	a5,a4,80005ce0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005d18:	e4043603          	ld	a2,-448(s0)
    80005d1c:	e3843783          	ld	a5,-456(s0)
    80005d20:	f8f669e3          	bltu	a2,a5,80005cb2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005d24:	e2843783          	ld	a5,-472(s0)
    80005d28:	963e                	add	a2,a2,a5
    80005d2a:	f8f667e3          	bltu	a2,a5,80005cb8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005d2e:	85ca                	mv	a1,s2
    80005d30:	855e                	mv	a0,s7
    80005d32:	ffffb097          	auipc	ra,0xffffb
    80005d36:	6fe080e7          	jalr	1790(ra) # 80001430 <uvmalloc>
    80005d3a:	e0a43423          	sd	a0,-504(s0)
    80005d3e:	d141                	beqz	a0,80005cbe <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005d40:	e2843d03          	ld	s10,-472(s0)
    80005d44:	df043783          	ld	a5,-528(s0)
    80005d48:	00fd77b3          	and	a5,s10,a5
    80005d4c:	fba1                	bnez	a5,80005c9c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005d4e:	e2042d83          	lw	s11,-480(s0)
    80005d52:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005d56:	f80c03e3          	beqz	s8,80005cdc <exec+0x306>
    80005d5a:	8a62                	mv	s4,s8
    80005d5c:	4901                	li	s2,0
    80005d5e:	b345                	j	80005afe <exec+0x128>

0000000080005d60 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005d60:	7179                	addi	sp,sp,-48
    80005d62:	f406                	sd	ra,40(sp)
    80005d64:	f022                	sd	s0,32(sp)
    80005d66:	ec26                	sd	s1,24(sp)
    80005d68:	e84a                	sd	s2,16(sp)
    80005d6a:	1800                	addi	s0,sp,48
    80005d6c:	892e                	mv	s2,a1
    80005d6e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005d70:	fdc40593          	addi	a1,s0,-36
    80005d74:	ffffe097          	auipc	ra,0xffffe
    80005d78:	ba8080e7          	jalr	-1112(ra) # 8000391c <argint>
    80005d7c:	04054063          	bltz	a0,80005dbc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005d80:	fdc42703          	lw	a4,-36(s0)
    80005d84:	47bd                	li	a5,15
    80005d86:	02e7ed63          	bltu	a5,a4,80005dc0 <argfd+0x60>
    80005d8a:	ffffc097          	auipc	ra,0xffffc
    80005d8e:	118080e7          	jalr	280(ra) # 80001ea2 <myproc>
    80005d92:	fdc42703          	lw	a4,-36(s0)
    80005d96:	01e70793          	addi	a5,a4,30
    80005d9a:	078e                	slli	a5,a5,0x3
    80005d9c:	953e                	add	a0,a0,a5
    80005d9e:	651c                	ld	a5,8(a0)
    80005da0:	c395                	beqz	a5,80005dc4 <argfd+0x64>
    return -1;
  if(pfd)
    80005da2:	00090463          	beqz	s2,80005daa <argfd+0x4a>
    *pfd = fd;
    80005da6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005daa:	4501                	li	a0,0
  if(pf)
    80005dac:	c091                	beqz	s1,80005db0 <argfd+0x50>
    *pf = f;
    80005dae:	e09c                	sd	a5,0(s1)
}
    80005db0:	70a2                	ld	ra,40(sp)
    80005db2:	7402                	ld	s0,32(sp)
    80005db4:	64e2                	ld	s1,24(sp)
    80005db6:	6942                	ld	s2,16(sp)
    80005db8:	6145                	addi	sp,sp,48
    80005dba:	8082                	ret
    return -1;
    80005dbc:	557d                	li	a0,-1
    80005dbe:	bfcd                	j	80005db0 <argfd+0x50>
    return -1;
    80005dc0:	557d                	li	a0,-1
    80005dc2:	b7fd                	j	80005db0 <argfd+0x50>
    80005dc4:	557d                	li	a0,-1
    80005dc6:	b7ed                	j	80005db0 <argfd+0x50>

0000000080005dc8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005dc8:	1101                	addi	sp,sp,-32
    80005dca:	ec06                	sd	ra,24(sp)
    80005dcc:	e822                	sd	s0,16(sp)
    80005dce:	e426                	sd	s1,8(sp)
    80005dd0:	1000                	addi	s0,sp,32
    80005dd2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005dd4:	ffffc097          	auipc	ra,0xffffc
    80005dd8:	0ce080e7          	jalr	206(ra) # 80001ea2 <myproc>
    80005ddc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005dde:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd80f8>
    80005de2:	4501                	li	a0,0
    80005de4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005de6:	6398                	ld	a4,0(a5)
    80005de8:	cb19                	beqz	a4,80005dfe <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005dea:	2505                	addiw	a0,a0,1
    80005dec:	07a1                	addi	a5,a5,8
    80005dee:	fed51ce3          	bne	a0,a3,80005de6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005df2:	557d                	li	a0,-1
}
    80005df4:	60e2                	ld	ra,24(sp)
    80005df6:	6442                	ld	s0,16(sp)
    80005df8:	64a2                	ld	s1,8(sp)
    80005dfa:	6105                	addi	sp,sp,32
    80005dfc:	8082                	ret
      p->ofile[fd] = f;
    80005dfe:	01e50793          	addi	a5,a0,30
    80005e02:	078e                	slli	a5,a5,0x3
    80005e04:	963e                	add	a2,a2,a5
    80005e06:	e604                	sd	s1,8(a2)
      return fd;
    80005e08:	b7f5                	j	80005df4 <fdalloc+0x2c>

0000000080005e0a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005e0a:	715d                	addi	sp,sp,-80
    80005e0c:	e486                	sd	ra,72(sp)
    80005e0e:	e0a2                	sd	s0,64(sp)
    80005e10:	fc26                	sd	s1,56(sp)
    80005e12:	f84a                	sd	s2,48(sp)
    80005e14:	f44e                	sd	s3,40(sp)
    80005e16:	f052                	sd	s4,32(sp)
    80005e18:	ec56                	sd	s5,24(sp)
    80005e1a:	0880                	addi	s0,sp,80
    80005e1c:	89ae                	mv	s3,a1
    80005e1e:	8ab2                	mv	s5,a2
    80005e20:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005e22:	fb040593          	addi	a1,s0,-80
    80005e26:	fffff097          	auipc	ra,0xfffff
    80005e2a:	e86080e7          	jalr	-378(ra) # 80004cac <nameiparent>
    80005e2e:	892a                	mv	s2,a0
    80005e30:	12050f63          	beqz	a0,80005f6e <create+0x164>
    return 0;

  ilock(dp);
    80005e34:	ffffe097          	auipc	ra,0xffffe
    80005e38:	6a4080e7          	jalr	1700(ra) # 800044d8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005e3c:	4601                	li	a2,0
    80005e3e:	fb040593          	addi	a1,s0,-80
    80005e42:	854a                	mv	a0,s2
    80005e44:	fffff097          	auipc	ra,0xfffff
    80005e48:	b78080e7          	jalr	-1160(ra) # 800049bc <dirlookup>
    80005e4c:	84aa                	mv	s1,a0
    80005e4e:	c921                	beqz	a0,80005e9e <create+0x94>
    iunlockput(dp);
    80005e50:	854a                	mv	a0,s2
    80005e52:	fffff097          	auipc	ra,0xfffff
    80005e56:	8e8080e7          	jalr	-1816(ra) # 8000473a <iunlockput>
    ilock(ip);
    80005e5a:	8526                	mv	a0,s1
    80005e5c:	ffffe097          	auipc	ra,0xffffe
    80005e60:	67c080e7          	jalr	1660(ra) # 800044d8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005e64:	2981                	sext.w	s3,s3
    80005e66:	4789                	li	a5,2
    80005e68:	02f99463          	bne	s3,a5,80005e90 <create+0x86>
    80005e6c:	0444d783          	lhu	a5,68(s1)
    80005e70:	37f9                	addiw	a5,a5,-2
    80005e72:	17c2                	slli	a5,a5,0x30
    80005e74:	93c1                	srli	a5,a5,0x30
    80005e76:	4705                	li	a4,1
    80005e78:	00f76c63          	bltu	a4,a5,80005e90 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005e7c:	8526                	mv	a0,s1
    80005e7e:	60a6                	ld	ra,72(sp)
    80005e80:	6406                	ld	s0,64(sp)
    80005e82:	74e2                	ld	s1,56(sp)
    80005e84:	7942                	ld	s2,48(sp)
    80005e86:	79a2                	ld	s3,40(sp)
    80005e88:	7a02                	ld	s4,32(sp)
    80005e8a:	6ae2                	ld	s5,24(sp)
    80005e8c:	6161                	addi	sp,sp,80
    80005e8e:	8082                	ret
    iunlockput(ip);
    80005e90:	8526                	mv	a0,s1
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	8a8080e7          	jalr	-1880(ra) # 8000473a <iunlockput>
    return 0;
    80005e9a:	4481                	li	s1,0
    80005e9c:	b7c5                	j	80005e7c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005e9e:	85ce                	mv	a1,s3
    80005ea0:	00092503          	lw	a0,0(s2)
    80005ea4:	ffffe097          	auipc	ra,0xffffe
    80005ea8:	49c080e7          	jalr	1180(ra) # 80004340 <ialloc>
    80005eac:	84aa                	mv	s1,a0
    80005eae:	c529                	beqz	a0,80005ef8 <create+0xee>
  ilock(ip);
    80005eb0:	ffffe097          	auipc	ra,0xffffe
    80005eb4:	628080e7          	jalr	1576(ra) # 800044d8 <ilock>
  ip->major = major;
    80005eb8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005ebc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005ec0:	4785                	li	a5,1
    80005ec2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ec6:	8526                	mv	a0,s1
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	546080e7          	jalr	1350(ra) # 8000440e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005ed0:	2981                	sext.w	s3,s3
    80005ed2:	4785                	li	a5,1
    80005ed4:	02f98a63          	beq	s3,a5,80005f08 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005ed8:	40d0                	lw	a2,4(s1)
    80005eda:	fb040593          	addi	a1,s0,-80
    80005ede:	854a                	mv	a0,s2
    80005ee0:	fffff097          	auipc	ra,0xfffff
    80005ee4:	cec080e7          	jalr	-788(ra) # 80004bcc <dirlink>
    80005ee8:	06054b63          	bltz	a0,80005f5e <create+0x154>
  iunlockput(dp);
    80005eec:	854a                	mv	a0,s2
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	84c080e7          	jalr	-1972(ra) # 8000473a <iunlockput>
  return ip;
    80005ef6:	b759                	j	80005e7c <create+0x72>
    panic("create: ialloc");
    80005ef8:	00004517          	auipc	a0,0x4
    80005efc:	9e050513          	addi	a0,a0,-1568 # 800098d8 <syscalls+0x2b0>
    80005f00:	ffffa097          	auipc	ra,0xffffa
    80005f04:	63e080e7          	jalr	1598(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005f08:	04a95783          	lhu	a5,74(s2)
    80005f0c:	2785                	addiw	a5,a5,1
    80005f0e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005f12:	854a                	mv	a0,s2
    80005f14:	ffffe097          	auipc	ra,0xffffe
    80005f18:	4fa080e7          	jalr	1274(ra) # 8000440e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005f1c:	40d0                	lw	a2,4(s1)
    80005f1e:	00004597          	auipc	a1,0x4
    80005f22:	9ca58593          	addi	a1,a1,-1590 # 800098e8 <syscalls+0x2c0>
    80005f26:	8526                	mv	a0,s1
    80005f28:	fffff097          	auipc	ra,0xfffff
    80005f2c:	ca4080e7          	jalr	-860(ra) # 80004bcc <dirlink>
    80005f30:	00054f63          	bltz	a0,80005f4e <create+0x144>
    80005f34:	00492603          	lw	a2,4(s2)
    80005f38:	00004597          	auipc	a1,0x4
    80005f3c:	9b858593          	addi	a1,a1,-1608 # 800098f0 <syscalls+0x2c8>
    80005f40:	8526                	mv	a0,s1
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	c8a080e7          	jalr	-886(ra) # 80004bcc <dirlink>
    80005f4a:	f80557e3          	bgez	a0,80005ed8 <create+0xce>
      panic("create dots");
    80005f4e:	00004517          	auipc	a0,0x4
    80005f52:	9aa50513          	addi	a0,a0,-1622 # 800098f8 <syscalls+0x2d0>
    80005f56:	ffffa097          	auipc	ra,0xffffa
    80005f5a:	5e8080e7          	jalr	1512(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005f5e:	00004517          	auipc	a0,0x4
    80005f62:	9aa50513          	addi	a0,a0,-1622 # 80009908 <syscalls+0x2e0>
    80005f66:	ffffa097          	auipc	ra,0xffffa
    80005f6a:	5d8080e7          	jalr	1496(ra) # 8000053e <panic>
    return 0;
    80005f6e:	84aa                	mv	s1,a0
    80005f70:	b731                	j	80005e7c <create+0x72>

0000000080005f72 <sys_dup>:
{
    80005f72:	7179                	addi	sp,sp,-48
    80005f74:	f406                	sd	ra,40(sp)
    80005f76:	f022                	sd	s0,32(sp)
    80005f78:	ec26                	sd	s1,24(sp)
    80005f7a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005f7c:	fd840613          	addi	a2,s0,-40
    80005f80:	4581                	li	a1,0
    80005f82:	4501                	li	a0,0
    80005f84:	00000097          	auipc	ra,0x0
    80005f88:	ddc080e7          	jalr	-548(ra) # 80005d60 <argfd>
    return -1;
    80005f8c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005f8e:	02054363          	bltz	a0,80005fb4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005f92:	fd843503          	ld	a0,-40(s0)
    80005f96:	00000097          	auipc	ra,0x0
    80005f9a:	e32080e7          	jalr	-462(ra) # 80005dc8 <fdalloc>
    80005f9e:	84aa                	mv	s1,a0
    return -1;
    80005fa0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005fa2:	00054963          	bltz	a0,80005fb4 <sys_dup+0x42>
  filedup(f);
    80005fa6:	fd843503          	ld	a0,-40(s0)
    80005faa:	fffff097          	auipc	ra,0xfffff
    80005fae:	37a080e7          	jalr	890(ra) # 80005324 <filedup>
  return fd;
    80005fb2:	87a6                	mv	a5,s1
}
    80005fb4:	853e                	mv	a0,a5
    80005fb6:	70a2                	ld	ra,40(sp)
    80005fb8:	7402                	ld	s0,32(sp)
    80005fba:	64e2                	ld	s1,24(sp)
    80005fbc:	6145                	addi	sp,sp,48
    80005fbe:	8082                	ret

0000000080005fc0 <sys_read>:
{
    80005fc0:	7179                	addi	sp,sp,-48
    80005fc2:	f406                	sd	ra,40(sp)
    80005fc4:	f022                	sd	s0,32(sp)
    80005fc6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fc8:	fe840613          	addi	a2,s0,-24
    80005fcc:	4581                	li	a1,0
    80005fce:	4501                	li	a0,0
    80005fd0:	00000097          	auipc	ra,0x0
    80005fd4:	d90080e7          	jalr	-624(ra) # 80005d60 <argfd>
    return -1;
    80005fd8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fda:	04054163          	bltz	a0,8000601c <sys_read+0x5c>
    80005fde:	fe440593          	addi	a1,s0,-28
    80005fe2:	4509                	li	a0,2
    80005fe4:	ffffe097          	auipc	ra,0xffffe
    80005fe8:	938080e7          	jalr	-1736(ra) # 8000391c <argint>
    return -1;
    80005fec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fee:	02054763          	bltz	a0,8000601c <sys_read+0x5c>
    80005ff2:	fd840593          	addi	a1,s0,-40
    80005ff6:	4505                	li	a0,1
    80005ff8:	ffffe097          	auipc	ra,0xffffe
    80005ffc:	946080e7          	jalr	-1722(ra) # 8000393e <argaddr>
    return -1;
    80006000:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006002:	00054d63          	bltz	a0,8000601c <sys_read+0x5c>
  return fileread(f, p, n);
    80006006:	fe442603          	lw	a2,-28(s0)
    8000600a:	fd843583          	ld	a1,-40(s0)
    8000600e:	fe843503          	ld	a0,-24(s0)
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	49e080e7          	jalr	1182(ra) # 800054b0 <fileread>
    8000601a:	87aa                	mv	a5,a0
}
    8000601c:	853e                	mv	a0,a5
    8000601e:	70a2                	ld	ra,40(sp)
    80006020:	7402                	ld	s0,32(sp)
    80006022:	6145                	addi	sp,sp,48
    80006024:	8082                	ret

0000000080006026 <sys_write>:
{
    80006026:	7179                	addi	sp,sp,-48
    80006028:	f406                	sd	ra,40(sp)
    8000602a:	f022                	sd	s0,32(sp)
    8000602c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000602e:	fe840613          	addi	a2,s0,-24
    80006032:	4581                	li	a1,0
    80006034:	4501                	li	a0,0
    80006036:	00000097          	auipc	ra,0x0
    8000603a:	d2a080e7          	jalr	-726(ra) # 80005d60 <argfd>
    return -1;
    8000603e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006040:	04054163          	bltz	a0,80006082 <sys_write+0x5c>
    80006044:	fe440593          	addi	a1,s0,-28
    80006048:	4509                	li	a0,2
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	8d2080e7          	jalr	-1838(ra) # 8000391c <argint>
    return -1;
    80006052:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006054:	02054763          	bltz	a0,80006082 <sys_write+0x5c>
    80006058:	fd840593          	addi	a1,s0,-40
    8000605c:	4505                	li	a0,1
    8000605e:	ffffe097          	auipc	ra,0xffffe
    80006062:	8e0080e7          	jalr	-1824(ra) # 8000393e <argaddr>
    return -1;
    80006066:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006068:	00054d63          	bltz	a0,80006082 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000606c:	fe442603          	lw	a2,-28(s0)
    80006070:	fd843583          	ld	a1,-40(s0)
    80006074:	fe843503          	ld	a0,-24(s0)
    80006078:	fffff097          	auipc	ra,0xfffff
    8000607c:	4fa080e7          	jalr	1274(ra) # 80005572 <filewrite>
    80006080:	87aa                	mv	a5,a0
}
    80006082:	853e                	mv	a0,a5
    80006084:	70a2                	ld	ra,40(sp)
    80006086:	7402                	ld	s0,32(sp)
    80006088:	6145                	addi	sp,sp,48
    8000608a:	8082                	ret

000000008000608c <sys_close>:
{
    8000608c:	1101                	addi	sp,sp,-32
    8000608e:	ec06                	sd	ra,24(sp)
    80006090:	e822                	sd	s0,16(sp)
    80006092:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80006094:	fe040613          	addi	a2,s0,-32
    80006098:	fec40593          	addi	a1,s0,-20
    8000609c:	4501                	li	a0,0
    8000609e:	00000097          	auipc	ra,0x0
    800060a2:	cc2080e7          	jalr	-830(ra) # 80005d60 <argfd>
    return -1;
    800060a6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800060a8:	02054463          	bltz	a0,800060d0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800060ac:	ffffc097          	auipc	ra,0xffffc
    800060b0:	df6080e7          	jalr	-522(ra) # 80001ea2 <myproc>
    800060b4:	fec42783          	lw	a5,-20(s0)
    800060b8:	07f9                	addi	a5,a5,30
    800060ba:	078e                	slli	a5,a5,0x3
    800060bc:	97aa                	add	a5,a5,a0
    800060be:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800060c2:	fe043503          	ld	a0,-32(s0)
    800060c6:	fffff097          	auipc	ra,0xfffff
    800060ca:	2b0080e7          	jalr	688(ra) # 80005376 <fileclose>
  return 0;
    800060ce:	4781                	li	a5,0
}
    800060d0:	853e                	mv	a0,a5
    800060d2:	60e2                	ld	ra,24(sp)
    800060d4:	6442                	ld	s0,16(sp)
    800060d6:	6105                	addi	sp,sp,32
    800060d8:	8082                	ret

00000000800060da <sys_fstat>:
{
    800060da:	1101                	addi	sp,sp,-32
    800060dc:	ec06                	sd	ra,24(sp)
    800060de:	e822                	sd	s0,16(sp)
    800060e0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800060e2:	fe840613          	addi	a2,s0,-24
    800060e6:	4581                	li	a1,0
    800060e8:	4501                	li	a0,0
    800060ea:	00000097          	auipc	ra,0x0
    800060ee:	c76080e7          	jalr	-906(ra) # 80005d60 <argfd>
    return -1;
    800060f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800060f4:	02054563          	bltz	a0,8000611e <sys_fstat+0x44>
    800060f8:	fe040593          	addi	a1,s0,-32
    800060fc:	4505                	li	a0,1
    800060fe:	ffffe097          	auipc	ra,0xffffe
    80006102:	840080e7          	jalr	-1984(ra) # 8000393e <argaddr>
    return -1;
    80006106:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006108:	00054b63          	bltz	a0,8000611e <sys_fstat+0x44>
  return filestat(f, st);
    8000610c:	fe043583          	ld	a1,-32(s0)
    80006110:	fe843503          	ld	a0,-24(s0)
    80006114:	fffff097          	auipc	ra,0xfffff
    80006118:	32a080e7          	jalr	810(ra) # 8000543e <filestat>
    8000611c:	87aa                	mv	a5,a0
}
    8000611e:	853e                	mv	a0,a5
    80006120:	60e2                	ld	ra,24(sp)
    80006122:	6442                	ld	s0,16(sp)
    80006124:	6105                	addi	sp,sp,32
    80006126:	8082                	ret

0000000080006128 <sys_link>:
{
    80006128:	7169                	addi	sp,sp,-304
    8000612a:	f606                	sd	ra,296(sp)
    8000612c:	f222                	sd	s0,288(sp)
    8000612e:	ee26                	sd	s1,280(sp)
    80006130:	ea4a                	sd	s2,272(sp)
    80006132:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006134:	08000613          	li	a2,128
    80006138:	ed040593          	addi	a1,s0,-304
    8000613c:	4501                	li	a0,0
    8000613e:	ffffe097          	auipc	ra,0xffffe
    80006142:	822080e7          	jalr	-2014(ra) # 80003960 <argstr>
    return -1;
    80006146:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006148:	10054e63          	bltz	a0,80006264 <sys_link+0x13c>
    8000614c:	08000613          	li	a2,128
    80006150:	f5040593          	addi	a1,s0,-176
    80006154:	4505                	li	a0,1
    80006156:	ffffe097          	auipc	ra,0xffffe
    8000615a:	80a080e7          	jalr	-2038(ra) # 80003960 <argstr>
    return -1;
    8000615e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006160:	10054263          	bltz	a0,80006264 <sys_link+0x13c>
  begin_op();
    80006164:	fffff097          	auipc	ra,0xfffff
    80006168:	d46080e7          	jalr	-698(ra) # 80004eaa <begin_op>
  if((ip = namei(old)) == 0){
    8000616c:	ed040513          	addi	a0,s0,-304
    80006170:	fffff097          	auipc	ra,0xfffff
    80006174:	b1e080e7          	jalr	-1250(ra) # 80004c8e <namei>
    80006178:	84aa                	mv	s1,a0
    8000617a:	c551                	beqz	a0,80006206 <sys_link+0xde>
  ilock(ip);
    8000617c:	ffffe097          	auipc	ra,0xffffe
    80006180:	35c080e7          	jalr	860(ra) # 800044d8 <ilock>
  if(ip->type == T_DIR){
    80006184:	04449703          	lh	a4,68(s1)
    80006188:	4785                	li	a5,1
    8000618a:	08f70463          	beq	a4,a5,80006212 <sys_link+0xea>
  ip->nlink++;
    8000618e:	04a4d783          	lhu	a5,74(s1)
    80006192:	2785                	addiw	a5,a5,1
    80006194:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006198:	8526                	mv	a0,s1
    8000619a:	ffffe097          	auipc	ra,0xffffe
    8000619e:	274080e7          	jalr	628(ra) # 8000440e <iupdate>
  iunlock(ip);
    800061a2:	8526                	mv	a0,s1
    800061a4:	ffffe097          	auipc	ra,0xffffe
    800061a8:	3f6080e7          	jalr	1014(ra) # 8000459a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800061ac:	fd040593          	addi	a1,s0,-48
    800061b0:	f5040513          	addi	a0,s0,-176
    800061b4:	fffff097          	auipc	ra,0xfffff
    800061b8:	af8080e7          	jalr	-1288(ra) # 80004cac <nameiparent>
    800061bc:	892a                	mv	s2,a0
    800061be:	c935                	beqz	a0,80006232 <sys_link+0x10a>
  ilock(dp);
    800061c0:	ffffe097          	auipc	ra,0xffffe
    800061c4:	318080e7          	jalr	792(ra) # 800044d8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800061c8:	00092703          	lw	a4,0(s2)
    800061cc:	409c                	lw	a5,0(s1)
    800061ce:	04f71d63          	bne	a4,a5,80006228 <sys_link+0x100>
    800061d2:	40d0                	lw	a2,4(s1)
    800061d4:	fd040593          	addi	a1,s0,-48
    800061d8:	854a                	mv	a0,s2
    800061da:	fffff097          	auipc	ra,0xfffff
    800061de:	9f2080e7          	jalr	-1550(ra) # 80004bcc <dirlink>
    800061e2:	04054363          	bltz	a0,80006228 <sys_link+0x100>
  iunlockput(dp);
    800061e6:	854a                	mv	a0,s2
    800061e8:	ffffe097          	auipc	ra,0xffffe
    800061ec:	552080e7          	jalr	1362(ra) # 8000473a <iunlockput>
  iput(ip);
    800061f0:	8526                	mv	a0,s1
    800061f2:	ffffe097          	auipc	ra,0xffffe
    800061f6:	4a0080e7          	jalr	1184(ra) # 80004692 <iput>
  end_op();
    800061fa:	fffff097          	auipc	ra,0xfffff
    800061fe:	d30080e7          	jalr	-720(ra) # 80004f2a <end_op>
  return 0;
    80006202:	4781                	li	a5,0
    80006204:	a085                	j	80006264 <sys_link+0x13c>
    end_op();
    80006206:	fffff097          	auipc	ra,0xfffff
    8000620a:	d24080e7          	jalr	-732(ra) # 80004f2a <end_op>
    return -1;
    8000620e:	57fd                	li	a5,-1
    80006210:	a891                	j	80006264 <sys_link+0x13c>
    iunlockput(ip);
    80006212:	8526                	mv	a0,s1
    80006214:	ffffe097          	auipc	ra,0xffffe
    80006218:	526080e7          	jalr	1318(ra) # 8000473a <iunlockput>
    end_op();
    8000621c:	fffff097          	auipc	ra,0xfffff
    80006220:	d0e080e7          	jalr	-754(ra) # 80004f2a <end_op>
    return -1;
    80006224:	57fd                	li	a5,-1
    80006226:	a83d                	j	80006264 <sys_link+0x13c>
    iunlockput(dp);
    80006228:	854a                	mv	a0,s2
    8000622a:	ffffe097          	auipc	ra,0xffffe
    8000622e:	510080e7          	jalr	1296(ra) # 8000473a <iunlockput>
  ilock(ip);
    80006232:	8526                	mv	a0,s1
    80006234:	ffffe097          	auipc	ra,0xffffe
    80006238:	2a4080e7          	jalr	676(ra) # 800044d8 <ilock>
  ip->nlink--;
    8000623c:	04a4d783          	lhu	a5,74(s1)
    80006240:	37fd                	addiw	a5,a5,-1
    80006242:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006246:	8526                	mv	a0,s1
    80006248:	ffffe097          	auipc	ra,0xffffe
    8000624c:	1c6080e7          	jalr	454(ra) # 8000440e <iupdate>
  iunlockput(ip);
    80006250:	8526                	mv	a0,s1
    80006252:	ffffe097          	auipc	ra,0xffffe
    80006256:	4e8080e7          	jalr	1256(ra) # 8000473a <iunlockput>
  end_op();
    8000625a:	fffff097          	auipc	ra,0xfffff
    8000625e:	cd0080e7          	jalr	-816(ra) # 80004f2a <end_op>
  return -1;
    80006262:	57fd                	li	a5,-1
}
    80006264:	853e                	mv	a0,a5
    80006266:	70b2                	ld	ra,296(sp)
    80006268:	7412                	ld	s0,288(sp)
    8000626a:	64f2                	ld	s1,280(sp)
    8000626c:	6952                	ld	s2,272(sp)
    8000626e:	6155                	addi	sp,sp,304
    80006270:	8082                	ret

0000000080006272 <sys_unlink>:
{
    80006272:	7151                	addi	sp,sp,-240
    80006274:	f586                	sd	ra,232(sp)
    80006276:	f1a2                	sd	s0,224(sp)
    80006278:	eda6                	sd	s1,216(sp)
    8000627a:	e9ca                	sd	s2,208(sp)
    8000627c:	e5ce                	sd	s3,200(sp)
    8000627e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006280:	08000613          	li	a2,128
    80006284:	f3040593          	addi	a1,s0,-208
    80006288:	4501                	li	a0,0
    8000628a:	ffffd097          	auipc	ra,0xffffd
    8000628e:	6d6080e7          	jalr	1750(ra) # 80003960 <argstr>
    80006292:	18054163          	bltz	a0,80006414 <sys_unlink+0x1a2>
  begin_op();
    80006296:	fffff097          	auipc	ra,0xfffff
    8000629a:	c14080e7          	jalr	-1004(ra) # 80004eaa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000629e:	fb040593          	addi	a1,s0,-80
    800062a2:	f3040513          	addi	a0,s0,-208
    800062a6:	fffff097          	auipc	ra,0xfffff
    800062aa:	a06080e7          	jalr	-1530(ra) # 80004cac <nameiparent>
    800062ae:	84aa                	mv	s1,a0
    800062b0:	c979                	beqz	a0,80006386 <sys_unlink+0x114>
  ilock(dp);
    800062b2:	ffffe097          	auipc	ra,0xffffe
    800062b6:	226080e7          	jalr	550(ra) # 800044d8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800062ba:	00003597          	auipc	a1,0x3
    800062be:	62e58593          	addi	a1,a1,1582 # 800098e8 <syscalls+0x2c0>
    800062c2:	fb040513          	addi	a0,s0,-80
    800062c6:	ffffe097          	auipc	ra,0xffffe
    800062ca:	6dc080e7          	jalr	1756(ra) # 800049a2 <namecmp>
    800062ce:	14050a63          	beqz	a0,80006422 <sys_unlink+0x1b0>
    800062d2:	00003597          	auipc	a1,0x3
    800062d6:	61e58593          	addi	a1,a1,1566 # 800098f0 <syscalls+0x2c8>
    800062da:	fb040513          	addi	a0,s0,-80
    800062de:	ffffe097          	auipc	ra,0xffffe
    800062e2:	6c4080e7          	jalr	1732(ra) # 800049a2 <namecmp>
    800062e6:	12050e63          	beqz	a0,80006422 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800062ea:	f2c40613          	addi	a2,s0,-212
    800062ee:	fb040593          	addi	a1,s0,-80
    800062f2:	8526                	mv	a0,s1
    800062f4:	ffffe097          	auipc	ra,0xffffe
    800062f8:	6c8080e7          	jalr	1736(ra) # 800049bc <dirlookup>
    800062fc:	892a                	mv	s2,a0
    800062fe:	12050263          	beqz	a0,80006422 <sys_unlink+0x1b0>
  ilock(ip);
    80006302:	ffffe097          	auipc	ra,0xffffe
    80006306:	1d6080e7          	jalr	470(ra) # 800044d8 <ilock>
  if(ip->nlink < 1)
    8000630a:	04a91783          	lh	a5,74(s2)
    8000630e:	08f05263          	blez	a5,80006392 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006312:	04491703          	lh	a4,68(s2)
    80006316:	4785                	li	a5,1
    80006318:	08f70563          	beq	a4,a5,800063a2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000631c:	4641                	li	a2,16
    8000631e:	4581                	li	a1,0
    80006320:	fc040513          	addi	a0,s0,-64
    80006324:	ffffb097          	auipc	ra,0xffffb
    80006328:	9ca080e7          	jalr	-1590(ra) # 80000cee <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000632c:	4741                	li	a4,16
    8000632e:	f2c42683          	lw	a3,-212(s0)
    80006332:	fc040613          	addi	a2,s0,-64
    80006336:	4581                	li	a1,0
    80006338:	8526                	mv	a0,s1
    8000633a:	ffffe097          	auipc	ra,0xffffe
    8000633e:	54a080e7          	jalr	1354(ra) # 80004884 <writei>
    80006342:	47c1                	li	a5,16
    80006344:	0af51563          	bne	a0,a5,800063ee <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006348:	04491703          	lh	a4,68(s2)
    8000634c:	4785                	li	a5,1
    8000634e:	0af70863          	beq	a4,a5,800063fe <sys_unlink+0x18c>
  iunlockput(dp);
    80006352:	8526                	mv	a0,s1
    80006354:	ffffe097          	auipc	ra,0xffffe
    80006358:	3e6080e7          	jalr	998(ra) # 8000473a <iunlockput>
  ip->nlink--;
    8000635c:	04a95783          	lhu	a5,74(s2)
    80006360:	37fd                	addiw	a5,a5,-1
    80006362:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006366:	854a                	mv	a0,s2
    80006368:	ffffe097          	auipc	ra,0xffffe
    8000636c:	0a6080e7          	jalr	166(ra) # 8000440e <iupdate>
  iunlockput(ip);
    80006370:	854a                	mv	a0,s2
    80006372:	ffffe097          	auipc	ra,0xffffe
    80006376:	3c8080e7          	jalr	968(ra) # 8000473a <iunlockput>
  end_op();
    8000637a:	fffff097          	auipc	ra,0xfffff
    8000637e:	bb0080e7          	jalr	-1104(ra) # 80004f2a <end_op>
  return 0;
    80006382:	4501                	li	a0,0
    80006384:	a84d                	j	80006436 <sys_unlink+0x1c4>
    end_op();
    80006386:	fffff097          	auipc	ra,0xfffff
    8000638a:	ba4080e7          	jalr	-1116(ra) # 80004f2a <end_op>
    return -1;
    8000638e:	557d                	li	a0,-1
    80006390:	a05d                	j	80006436 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006392:	00003517          	auipc	a0,0x3
    80006396:	58650513          	addi	a0,a0,1414 # 80009918 <syscalls+0x2f0>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a4080e7          	jalr	420(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800063a2:	04c92703          	lw	a4,76(s2)
    800063a6:	02000793          	li	a5,32
    800063aa:	f6e7f9e3          	bgeu	a5,a4,8000631c <sys_unlink+0xaa>
    800063ae:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800063b2:	4741                	li	a4,16
    800063b4:	86ce                	mv	a3,s3
    800063b6:	f1840613          	addi	a2,s0,-232
    800063ba:	4581                	li	a1,0
    800063bc:	854a                	mv	a0,s2
    800063be:	ffffe097          	auipc	ra,0xffffe
    800063c2:	3ce080e7          	jalr	974(ra) # 8000478c <readi>
    800063c6:	47c1                	li	a5,16
    800063c8:	00f51b63          	bne	a0,a5,800063de <sys_unlink+0x16c>
    if(de.inum != 0)
    800063cc:	f1845783          	lhu	a5,-232(s0)
    800063d0:	e7a1                	bnez	a5,80006418 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800063d2:	29c1                	addiw	s3,s3,16
    800063d4:	04c92783          	lw	a5,76(s2)
    800063d8:	fcf9ede3          	bltu	s3,a5,800063b2 <sys_unlink+0x140>
    800063dc:	b781                	j	8000631c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800063de:	00003517          	auipc	a0,0x3
    800063e2:	55250513          	addi	a0,a0,1362 # 80009930 <syscalls+0x308>
    800063e6:	ffffa097          	auipc	ra,0xffffa
    800063ea:	158080e7          	jalr	344(ra) # 8000053e <panic>
    panic("unlink: writei");
    800063ee:	00003517          	auipc	a0,0x3
    800063f2:	55a50513          	addi	a0,a0,1370 # 80009948 <syscalls+0x320>
    800063f6:	ffffa097          	auipc	ra,0xffffa
    800063fa:	148080e7          	jalr	328(ra) # 8000053e <panic>
    dp->nlink--;
    800063fe:	04a4d783          	lhu	a5,74(s1)
    80006402:	37fd                	addiw	a5,a5,-1
    80006404:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006408:	8526                	mv	a0,s1
    8000640a:	ffffe097          	auipc	ra,0xffffe
    8000640e:	004080e7          	jalr	4(ra) # 8000440e <iupdate>
    80006412:	b781                	j	80006352 <sys_unlink+0xe0>
    return -1;
    80006414:	557d                	li	a0,-1
    80006416:	a005                	j	80006436 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006418:	854a                	mv	a0,s2
    8000641a:	ffffe097          	auipc	ra,0xffffe
    8000641e:	320080e7          	jalr	800(ra) # 8000473a <iunlockput>
  iunlockput(dp);
    80006422:	8526                	mv	a0,s1
    80006424:	ffffe097          	auipc	ra,0xffffe
    80006428:	316080e7          	jalr	790(ra) # 8000473a <iunlockput>
  end_op();
    8000642c:	fffff097          	auipc	ra,0xfffff
    80006430:	afe080e7          	jalr	-1282(ra) # 80004f2a <end_op>
  return -1;
    80006434:	557d                	li	a0,-1
}
    80006436:	70ae                	ld	ra,232(sp)
    80006438:	740e                	ld	s0,224(sp)
    8000643a:	64ee                	ld	s1,216(sp)
    8000643c:	694e                	ld	s2,208(sp)
    8000643e:	69ae                	ld	s3,200(sp)
    80006440:	616d                	addi	sp,sp,240
    80006442:	8082                	ret

0000000080006444 <sys_open>:

uint64
sys_open(void)
{
    80006444:	7131                	addi	sp,sp,-192
    80006446:	fd06                	sd	ra,184(sp)
    80006448:	f922                	sd	s0,176(sp)
    8000644a:	f526                	sd	s1,168(sp)
    8000644c:	f14a                	sd	s2,160(sp)
    8000644e:	ed4e                	sd	s3,152(sp)
    80006450:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006452:	08000613          	li	a2,128
    80006456:	f5040593          	addi	a1,s0,-176
    8000645a:	4501                	li	a0,0
    8000645c:	ffffd097          	auipc	ra,0xffffd
    80006460:	504080e7          	jalr	1284(ra) # 80003960 <argstr>
    return -1;
    80006464:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006466:	0c054163          	bltz	a0,80006528 <sys_open+0xe4>
    8000646a:	f4c40593          	addi	a1,s0,-180
    8000646e:	4505                	li	a0,1
    80006470:	ffffd097          	auipc	ra,0xffffd
    80006474:	4ac080e7          	jalr	1196(ra) # 8000391c <argint>
    80006478:	0a054863          	bltz	a0,80006528 <sys_open+0xe4>

  begin_op();
    8000647c:	fffff097          	auipc	ra,0xfffff
    80006480:	a2e080e7          	jalr	-1490(ra) # 80004eaa <begin_op>

  if(omode & O_CREATE){
    80006484:	f4c42783          	lw	a5,-180(s0)
    80006488:	2007f793          	andi	a5,a5,512
    8000648c:	cbdd                	beqz	a5,80006542 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000648e:	4681                	li	a3,0
    80006490:	4601                	li	a2,0
    80006492:	4589                	li	a1,2
    80006494:	f5040513          	addi	a0,s0,-176
    80006498:	00000097          	auipc	ra,0x0
    8000649c:	972080e7          	jalr	-1678(ra) # 80005e0a <create>
    800064a0:	892a                	mv	s2,a0
    if(ip == 0){
    800064a2:	c959                	beqz	a0,80006538 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800064a4:	04491703          	lh	a4,68(s2)
    800064a8:	478d                	li	a5,3
    800064aa:	00f71763          	bne	a4,a5,800064b8 <sys_open+0x74>
    800064ae:	04695703          	lhu	a4,70(s2)
    800064b2:	47a5                	li	a5,9
    800064b4:	0ce7ec63          	bltu	a5,a4,8000658c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800064b8:	fffff097          	auipc	ra,0xfffff
    800064bc:	e02080e7          	jalr	-510(ra) # 800052ba <filealloc>
    800064c0:	89aa                	mv	s3,a0
    800064c2:	10050263          	beqz	a0,800065c6 <sys_open+0x182>
    800064c6:	00000097          	auipc	ra,0x0
    800064ca:	902080e7          	jalr	-1790(ra) # 80005dc8 <fdalloc>
    800064ce:	84aa                	mv	s1,a0
    800064d0:	0e054663          	bltz	a0,800065bc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800064d4:	04491703          	lh	a4,68(s2)
    800064d8:	478d                	li	a5,3
    800064da:	0cf70463          	beq	a4,a5,800065a2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800064de:	4789                	li	a5,2
    800064e0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800064e4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800064e8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800064ec:	f4c42783          	lw	a5,-180(s0)
    800064f0:	0017c713          	xori	a4,a5,1
    800064f4:	8b05                	andi	a4,a4,1
    800064f6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800064fa:	0037f713          	andi	a4,a5,3
    800064fe:	00e03733          	snez	a4,a4
    80006502:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006506:	4007f793          	andi	a5,a5,1024
    8000650a:	c791                	beqz	a5,80006516 <sys_open+0xd2>
    8000650c:	04491703          	lh	a4,68(s2)
    80006510:	4789                	li	a5,2
    80006512:	08f70f63          	beq	a4,a5,800065b0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006516:	854a                	mv	a0,s2
    80006518:	ffffe097          	auipc	ra,0xffffe
    8000651c:	082080e7          	jalr	130(ra) # 8000459a <iunlock>
  end_op();
    80006520:	fffff097          	auipc	ra,0xfffff
    80006524:	a0a080e7          	jalr	-1526(ra) # 80004f2a <end_op>

  return fd;
}
    80006528:	8526                	mv	a0,s1
    8000652a:	70ea                	ld	ra,184(sp)
    8000652c:	744a                	ld	s0,176(sp)
    8000652e:	74aa                	ld	s1,168(sp)
    80006530:	790a                	ld	s2,160(sp)
    80006532:	69ea                	ld	s3,152(sp)
    80006534:	6129                	addi	sp,sp,192
    80006536:	8082                	ret
      end_op();
    80006538:	fffff097          	auipc	ra,0xfffff
    8000653c:	9f2080e7          	jalr	-1550(ra) # 80004f2a <end_op>
      return -1;
    80006540:	b7e5                	j	80006528 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006542:	f5040513          	addi	a0,s0,-176
    80006546:	ffffe097          	auipc	ra,0xffffe
    8000654a:	748080e7          	jalr	1864(ra) # 80004c8e <namei>
    8000654e:	892a                	mv	s2,a0
    80006550:	c905                	beqz	a0,80006580 <sys_open+0x13c>
    ilock(ip);
    80006552:	ffffe097          	auipc	ra,0xffffe
    80006556:	f86080e7          	jalr	-122(ra) # 800044d8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000655a:	04491703          	lh	a4,68(s2)
    8000655e:	4785                	li	a5,1
    80006560:	f4f712e3          	bne	a4,a5,800064a4 <sys_open+0x60>
    80006564:	f4c42783          	lw	a5,-180(s0)
    80006568:	dba1                	beqz	a5,800064b8 <sys_open+0x74>
      iunlockput(ip);
    8000656a:	854a                	mv	a0,s2
    8000656c:	ffffe097          	auipc	ra,0xffffe
    80006570:	1ce080e7          	jalr	462(ra) # 8000473a <iunlockput>
      end_op();
    80006574:	fffff097          	auipc	ra,0xfffff
    80006578:	9b6080e7          	jalr	-1610(ra) # 80004f2a <end_op>
      return -1;
    8000657c:	54fd                	li	s1,-1
    8000657e:	b76d                	j	80006528 <sys_open+0xe4>
      end_op();
    80006580:	fffff097          	auipc	ra,0xfffff
    80006584:	9aa080e7          	jalr	-1622(ra) # 80004f2a <end_op>
      return -1;
    80006588:	54fd                	li	s1,-1
    8000658a:	bf79                	j	80006528 <sys_open+0xe4>
    iunlockput(ip);
    8000658c:	854a                	mv	a0,s2
    8000658e:	ffffe097          	auipc	ra,0xffffe
    80006592:	1ac080e7          	jalr	428(ra) # 8000473a <iunlockput>
    end_op();
    80006596:	fffff097          	auipc	ra,0xfffff
    8000659a:	994080e7          	jalr	-1644(ra) # 80004f2a <end_op>
    return -1;
    8000659e:	54fd                	li	s1,-1
    800065a0:	b761                	j	80006528 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800065a2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800065a6:	04691783          	lh	a5,70(s2)
    800065aa:	02f99223          	sh	a5,36(s3)
    800065ae:	bf2d                	j	800064e8 <sys_open+0xa4>
    itrunc(ip);
    800065b0:	854a                	mv	a0,s2
    800065b2:	ffffe097          	auipc	ra,0xffffe
    800065b6:	034080e7          	jalr	52(ra) # 800045e6 <itrunc>
    800065ba:	bfb1                	j	80006516 <sys_open+0xd2>
      fileclose(f);
    800065bc:	854e                	mv	a0,s3
    800065be:	fffff097          	auipc	ra,0xfffff
    800065c2:	db8080e7          	jalr	-584(ra) # 80005376 <fileclose>
    iunlockput(ip);
    800065c6:	854a                	mv	a0,s2
    800065c8:	ffffe097          	auipc	ra,0xffffe
    800065cc:	172080e7          	jalr	370(ra) # 8000473a <iunlockput>
    end_op();
    800065d0:	fffff097          	auipc	ra,0xfffff
    800065d4:	95a080e7          	jalr	-1702(ra) # 80004f2a <end_op>
    return -1;
    800065d8:	54fd                	li	s1,-1
    800065da:	b7b9                	j	80006528 <sys_open+0xe4>

00000000800065dc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800065dc:	7175                	addi	sp,sp,-144
    800065de:	e506                	sd	ra,136(sp)
    800065e0:	e122                	sd	s0,128(sp)
    800065e2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800065e4:	fffff097          	auipc	ra,0xfffff
    800065e8:	8c6080e7          	jalr	-1850(ra) # 80004eaa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800065ec:	08000613          	li	a2,128
    800065f0:	f7040593          	addi	a1,s0,-144
    800065f4:	4501                	li	a0,0
    800065f6:	ffffd097          	auipc	ra,0xffffd
    800065fa:	36a080e7          	jalr	874(ra) # 80003960 <argstr>
    800065fe:	02054963          	bltz	a0,80006630 <sys_mkdir+0x54>
    80006602:	4681                	li	a3,0
    80006604:	4601                	li	a2,0
    80006606:	4585                	li	a1,1
    80006608:	f7040513          	addi	a0,s0,-144
    8000660c:	fffff097          	auipc	ra,0xfffff
    80006610:	7fe080e7          	jalr	2046(ra) # 80005e0a <create>
    80006614:	cd11                	beqz	a0,80006630 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006616:	ffffe097          	auipc	ra,0xffffe
    8000661a:	124080e7          	jalr	292(ra) # 8000473a <iunlockput>
  end_op();
    8000661e:	fffff097          	auipc	ra,0xfffff
    80006622:	90c080e7          	jalr	-1780(ra) # 80004f2a <end_op>
  return 0;
    80006626:	4501                	li	a0,0
}
    80006628:	60aa                	ld	ra,136(sp)
    8000662a:	640a                	ld	s0,128(sp)
    8000662c:	6149                	addi	sp,sp,144
    8000662e:	8082                	ret
    end_op();
    80006630:	fffff097          	auipc	ra,0xfffff
    80006634:	8fa080e7          	jalr	-1798(ra) # 80004f2a <end_op>
    return -1;
    80006638:	557d                	li	a0,-1
    8000663a:	b7fd                	j	80006628 <sys_mkdir+0x4c>

000000008000663c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000663c:	7135                	addi	sp,sp,-160
    8000663e:	ed06                	sd	ra,152(sp)
    80006640:	e922                	sd	s0,144(sp)
    80006642:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006644:	fffff097          	auipc	ra,0xfffff
    80006648:	866080e7          	jalr	-1946(ra) # 80004eaa <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000664c:	08000613          	li	a2,128
    80006650:	f7040593          	addi	a1,s0,-144
    80006654:	4501                	li	a0,0
    80006656:	ffffd097          	auipc	ra,0xffffd
    8000665a:	30a080e7          	jalr	778(ra) # 80003960 <argstr>
    8000665e:	04054a63          	bltz	a0,800066b2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006662:	f6c40593          	addi	a1,s0,-148
    80006666:	4505                	li	a0,1
    80006668:	ffffd097          	auipc	ra,0xffffd
    8000666c:	2b4080e7          	jalr	692(ra) # 8000391c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006670:	04054163          	bltz	a0,800066b2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006674:	f6840593          	addi	a1,s0,-152
    80006678:	4509                	li	a0,2
    8000667a:	ffffd097          	auipc	ra,0xffffd
    8000667e:	2a2080e7          	jalr	674(ra) # 8000391c <argint>
     argint(1, &major) < 0 ||
    80006682:	02054863          	bltz	a0,800066b2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006686:	f6841683          	lh	a3,-152(s0)
    8000668a:	f6c41603          	lh	a2,-148(s0)
    8000668e:	458d                	li	a1,3
    80006690:	f7040513          	addi	a0,s0,-144
    80006694:	fffff097          	auipc	ra,0xfffff
    80006698:	776080e7          	jalr	1910(ra) # 80005e0a <create>
     argint(2, &minor) < 0 ||
    8000669c:	c919                	beqz	a0,800066b2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000669e:	ffffe097          	auipc	ra,0xffffe
    800066a2:	09c080e7          	jalr	156(ra) # 8000473a <iunlockput>
  end_op();
    800066a6:	fffff097          	auipc	ra,0xfffff
    800066aa:	884080e7          	jalr	-1916(ra) # 80004f2a <end_op>
  return 0;
    800066ae:	4501                	li	a0,0
    800066b0:	a031                	j	800066bc <sys_mknod+0x80>
    end_op();
    800066b2:	fffff097          	auipc	ra,0xfffff
    800066b6:	878080e7          	jalr	-1928(ra) # 80004f2a <end_op>
    return -1;
    800066ba:	557d                	li	a0,-1
}
    800066bc:	60ea                	ld	ra,152(sp)
    800066be:	644a                	ld	s0,144(sp)
    800066c0:	610d                	addi	sp,sp,160
    800066c2:	8082                	ret

00000000800066c4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800066c4:	7135                	addi	sp,sp,-160
    800066c6:	ed06                	sd	ra,152(sp)
    800066c8:	e922                	sd	s0,144(sp)
    800066ca:	e526                	sd	s1,136(sp)
    800066cc:	e14a                	sd	s2,128(sp)
    800066ce:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800066d0:	ffffb097          	auipc	ra,0xffffb
    800066d4:	7d2080e7          	jalr	2002(ra) # 80001ea2 <myproc>
    800066d8:	892a                	mv	s2,a0
  
  begin_op();
    800066da:	ffffe097          	auipc	ra,0xffffe
    800066de:	7d0080e7          	jalr	2000(ra) # 80004eaa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800066e2:	08000613          	li	a2,128
    800066e6:	f6040593          	addi	a1,s0,-160
    800066ea:	4501                	li	a0,0
    800066ec:	ffffd097          	auipc	ra,0xffffd
    800066f0:	274080e7          	jalr	628(ra) # 80003960 <argstr>
    800066f4:	04054b63          	bltz	a0,8000674a <sys_chdir+0x86>
    800066f8:	f6040513          	addi	a0,s0,-160
    800066fc:	ffffe097          	auipc	ra,0xffffe
    80006700:	592080e7          	jalr	1426(ra) # 80004c8e <namei>
    80006704:	84aa                	mv	s1,a0
    80006706:	c131                	beqz	a0,8000674a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006708:	ffffe097          	auipc	ra,0xffffe
    8000670c:	dd0080e7          	jalr	-560(ra) # 800044d8 <ilock>
  if(ip->type != T_DIR){
    80006710:	04449703          	lh	a4,68(s1)
    80006714:	4785                	li	a5,1
    80006716:	04f71063          	bne	a4,a5,80006756 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000671a:	8526                	mv	a0,s1
    8000671c:	ffffe097          	auipc	ra,0xffffe
    80006720:	e7e080e7          	jalr	-386(ra) # 8000459a <iunlock>
  iput(p->cwd);
    80006724:	17893503          	ld	a0,376(s2)
    80006728:	ffffe097          	auipc	ra,0xffffe
    8000672c:	f6a080e7          	jalr	-150(ra) # 80004692 <iput>
  end_op();
    80006730:	ffffe097          	auipc	ra,0xffffe
    80006734:	7fa080e7          	jalr	2042(ra) # 80004f2a <end_op>
  p->cwd = ip;
    80006738:	16993c23          	sd	s1,376(s2)
  return 0;
    8000673c:	4501                	li	a0,0
}
    8000673e:	60ea                	ld	ra,152(sp)
    80006740:	644a                	ld	s0,144(sp)
    80006742:	64aa                	ld	s1,136(sp)
    80006744:	690a                	ld	s2,128(sp)
    80006746:	610d                	addi	sp,sp,160
    80006748:	8082                	ret
    end_op();
    8000674a:	ffffe097          	auipc	ra,0xffffe
    8000674e:	7e0080e7          	jalr	2016(ra) # 80004f2a <end_op>
    return -1;
    80006752:	557d                	li	a0,-1
    80006754:	b7ed                	j	8000673e <sys_chdir+0x7a>
    iunlockput(ip);
    80006756:	8526                	mv	a0,s1
    80006758:	ffffe097          	auipc	ra,0xffffe
    8000675c:	fe2080e7          	jalr	-30(ra) # 8000473a <iunlockput>
    end_op();
    80006760:	ffffe097          	auipc	ra,0xffffe
    80006764:	7ca080e7          	jalr	1994(ra) # 80004f2a <end_op>
    return -1;
    80006768:	557d                	li	a0,-1
    8000676a:	bfd1                	j	8000673e <sys_chdir+0x7a>

000000008000676c <sys_exec>:

uint64
sys_exec(void)
{
    8000676c:	7145                	addi	sp,sp,-464
    8000676e:	e786                	sd	ra,456(sp)
    80006770:	e3a2                	sd	s0,448(sp)
    80006772:	ff26                	sd	s1,440(sp)
    80006774:	fb4a                	sd	s2,432(sp)
    80006776:	f74e                	sd	s3,424(sp)
    80006778:	f352                	sd	s4,416(sp)
    8000677a:	ef56                	sd	s5,408(sp)
    8000677c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000677e:	08000613          	li	a2,128
    80006782:	f4040593          	addi	a1,s0,-192
    80006786:	4501                	li	a0,0
    80006788:	ffffd097          	auipc	ra,0xffffd
    8000678c:	1d8080e7          	jalr	472(ra) # 80003960 <argstr>
    return -1;
    80006790:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006792:	0c054a63          	bltz	a0,80006866 <sys_exec+0xfa>
    80006796:	e3840593          	addi	a1,s0,-456
    8000679a:	4505                	li	a0,1
    8000679c:	ffffd097          	auipc	ra,0xffffd
    800067a0:	1a2080e7          	jalr	418(ra) # 8000393e <argaddr>
    800067a4:	0c054163          	bltz	a0,80006866 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800067a8:	10000613          	li	a2,256
    800067ac:	4581                	li	a1,0
    800067ae:	e4040513          	addi	a0,s0,-448
    800067b2:	ffffa097          	auipc	ra,0xffffa
    800067b6:	53c080e7          	jalr	1340(ra) # 80000cee <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800067ba:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800067be:	89a6                	mv	s3,s1
    800067c0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800067c2:	02000a13          	li	s4,32
    800067c6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800067ca:	00391513          	slli	a0,s2,0x3
    800067ce:	e3040593          	addi	a1,s0,-464
    800067d2:	e3843783          	ld	a5,-456(s0)
    800067d6:	953e                	add	a0,a0,a5
    800067d8:	ffffd097          	auipc	ra,0xffffd
    800067dc:	0aa080e7          	jalr	170(ra) # 80003882 <fetchaddr>
    800067e0:	02054a63          	bltz	a0,80006814 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800067e4:	e3043783          	ld	a5,-464(s0)
    800067e8:	c3b9                	beqz	a5,8000682e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800067ea:	ffffa097          	auipc	ra,0xffffa
    800067ee:	30a080e7          	jalr	778(ra) # 80000af4 <kalloc>
    800067f2:	85aa                	mv	a1,a0
    800067f4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800067f8:	cd11                	beqz	a0,80006814 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800067fa:	6605                	lui	a2,0x1
    800067fc:	e3043503          	ld	a0,-464(s0)
    80006800:	ffffd097          	auipc	ra,0xffffd
    80006804:	0d4080e7          	jalr	212(ra) # 800038d4 <fetchstr>
    80006808:	00054663          	bltz	a0,80006814 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000680c:	0905                	addi	s2,s2,1
    8000680e:	09a1                	addi	s3,s3,8
    80006810:	fb491be3          	bne	s2,s4,800067c6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006814:	10048913          	addi	s2,s1,256
    80006818:	6088                	ld	a0,0(s1)
    8000681a:	c529                	beqz	a0,80006864 <sys_exec+0xf8>
    kfree(argv[i]);
    8000681c:	ffffa097          	auipc	ra,0xffffa
    80006820:	1dc080e7          	jalr	476(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006824:	04a1                	addi	s1,s1,8
    80006826:	ff2499e3          	bne	s1,s2,80006818 <sys_exec+0xac>
  return -1;
    8000682a:	597d                	li	s2,-1
    8000682c:	a82d                	j	80006866 <sys_exec+0xfa>
      argv[i] = 0;
    8000682e:	0a8e                	slli	s5,s5,0x3
    80006830:	fc040793          	addi	a5,s0,-64
    80006834:	9abe                	add	s5,s5,a5
    80006836:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000683a:	e4040593          	addi	a1,s0,-448
    8000683e:	f4040513          	addi	a0,s0,-192
    80006842:	fffff097          	auipc	ra,0xfffff
    80006846:	194080e7          	jalr	404(ra) # 800059d6 <exec>
    8000684a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000684c:	10048993          	addi	s3,s1,256
    80006850:	6088                	ld	a0,0(s1)
    80006852:	c911                	beqz	a0,80006866 <sys_exec+0xfa>
    kfree(argv[i]);
    80006854:	ffffa097          	auipc	ra,0xffffa
    80006858:	1a4080e7          	jalr	420(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000685c:	04a1                	addi	s1,s1,8
    8000685e:	ff3499e3          	bne	s1,s3,80006850 <sys_exec+0xe4>
    80006862:	a011                	j	80006866 <sys_exec+0xfa>
  return -1;
    80006864:	597d                	li	s2,-1
}
    80006866:	854a                	mv	a0,s2
    80006868:	60be                	ld	ra,456(sp)
    8000686a:	641e                	ld	s0,448(sp)
    8000686c:	74fa                	ld	s1,440(sp)
    8000686e:	795a                	ld	s2,432(sp)
    80006870:	79ba                	ld	s3,424(sp)
    80006872:	7a1a                	ld	s4,416(sp)
    80006874:	6afa                	ld	s5,408(sp)
    80006876:	6179                	addi	sp,sp,464
    80006878:	8082                	ret

000000008000687a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000687a:	7139                	addi	sp,sp,-64
    8000687c:	fc06                	sd	ra,56(sp)
    8000687e:	f822                	sd	s0,48(sp)
    80006880:	f426                	sd	s1,40(sp)
    80006882:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006884:	ffffb097          	auipc	ra,0xffffb
    80006888:	61e080e7          	jalr	1566(ra) # 80001ea2 <myproc>
    8000688c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000688e:	fd840593          	addi	a1,s0,-40
    80006892:	4501                	li	a0,0
    80006894:	ffffd097          	auipc	ra,0xffffd
    80006898:	0aa080e7          	jalr	170(ra) # 8000393e <argaddr>
    return -1;
    8000689c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000689e:	0e054063          	bltz	a0,8000697e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800068a2:	fc840593          	addi	a1,s0,-56
    800068a6:	fd040513          	addi	a0,s0,-48
    800068aa:	fffff097          	auipc	ra,0xfffff
    800068ae:	dfc080e7          	jalr	-516(ra) # 800056a6 <pipealloc>
    return -1;
    800068b2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800068b4:	0c054563          	bltz	a0,8000697e <sys_pipe+0x104>
  fd0 = -1;
    800068b8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800068bc:	fd043503          	ld	a0,-48(s0)
    800068c0:	fffff097          	auipc	ra,0xfffff
    800068c4:	508080e7          	jalr	1288(ra) # 80005dc8 <fdalloc>
    800068c8:	fca42223          	sw	a0,-60(s0)
    800068cc:	08054c63          	bltz	a0,80006964 <sys_pipe+0xea>
    800068d0:	fc843503          	ld	a0,-56(s0)
    800068d4:	fffff097          	auipc	ra,0xfffff
    800068d8:	4f4080e7          	jalr	1268(ra) # 80005dc8 <fdalloc>
    800068dc:	fca42023          	sw	a0,-64(s0)
    800068e0:	06054863          	bltz	a0,80006950 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800068e4:	4691                	li	a3,4
    800068e6:	fc440613          	addi	a2,s0,-60
    800068ea:	fd843583          	ld	a1,-40(s0)
    800068ee:	7ca8                	ld	a0,120(s1)
    800068f0:	ffffb097          	auipc	ra,0xffffb
    800068f4:	d90080e7          	jalr	-624(ra) # 80001680 <copyout>
    800068f8:	02054063          	bltz	a0,80006918 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800068fc:	4691                	li	a3,4
    800068fe:	fc040613          	addi	a2,s0,-64
    80006902:	fd843583          	ld	a1,-40(s0)
    80006906:	0591                	addi	a1,a1,4
    80006908:	7ca8                	ld	a0,120(s1)
    8000690a:	ffffb097          	auipc	ra,0xffffb
    8000690e:	d76080e7          	jalr	-650(ra) # 80001680 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006912:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006914:	06055563          	bgez	a0,8000697e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006918:	fc442783          	lw	a5,-60(s0)
    8000691c:	07f9                	addi	a5,a5,30
    8000691e:	078e                	slli	a5,a5,0x3
    80006920:	97a6                	add	a5,a5,s1
    80006922:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006926:	fc042503          	lw	a0,-64(s0)
    8000692a:	0579                	addi	a0,a0,30
    8000692c:	050e                	slli	a0,a0,0x3
    8000692e:	9526                	add	a0,a0,s1
    80006930:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006934:	fd043503          	ld	a0,-48(s0)
    80006938:	fffff097          	auipc	ra,0xfffff
    8000693c:	a3e080e7          	jalr	-1474(ra) # 80005376 <fileclose>
    fileclose(wf);
    80006940:	fc843503          	ld	a0,-56(s0)
    80006944:	fffff097          	auipc	ra,0xfffff
    80006948:	a32080e7          	jalr	-1486(ra) # 80005376 <fileclose>
    return -1;
    8000694c:	57fd                	li	a5,-1
    8000694e:	a805                	j	8000697e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006950:	fc442783          	lw	a5,-60(s0)
    80006954:	0007c863          	bltz	a5,80006964 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006958:	01e78513          	addi	a0,a5,30
    8000695c:	050e                	slli	a0,a0,0x3
    8000695e:	9526                	add	a0,a0,s1
    80006960:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006964:	fd043503          	ld	a0,-48(s0)
    80006968:	fffff097          	auipc	ra,0xfffff
    8000696c:	a0e080e7          	jalr	-1522(ra) # 80005376 <fileclose>
    fileclose(wf);
    80006970:	fc843503          	ld	a0,-56(s0)
    80006974:	fffff097          	auipc	ra,0xfffff
    80006978:	a02080e7          	jalr	-1534(ra) # 80005376 <fileclose>
    return -1;
    8000697c:	57fd                	li	a5,-1
}
    8000697e:	853e                	mv	a0,a5
    80006980:	70e2                	ld	ra,56(sp)
    80006982:	7442                	ld	s0,48(sp)
    80006984:	74a2                	ld	s1,40(sp)
    80006986:	6121                	addi	sp,sp,64
    80006988:	8082                	ret
    8000698a:	0000                	unimp
    8000698c:	0000                	unimp
	...

0000000080006990 <kernelvec>:
    80006990:	7111                	addi	sp,sp,-256
    80006992:	e006                	sd	ra,0(sp)
    80006994:	e40a                	sd	sp,8(sp)
    80006996:	e80e                	sd	gp,16(sp)
    80006998:	ec12                	sd	tp,24(sp)
    8000699a:	f016                	sd	t0,32(sp)
    8000699c:	f41a                	sd	t1,40(sp)
    8000699e:	f81e                	sd	t2,48(sp)
    800069a0:	fc22                	sd	s0,56(sp)
    800069a2:	e0a6                	sd	s1,64(sp)
    800069a4:	e4aa                	sd	a0,72(sp)
    800069a6:	e8ae                	sd	a1,80(sp)
    800069a8:	ecb2                	sd	a2,88(sp)
    800069aa:	f0b6                	sd	a3,96(sp)
    800069ac:	f4ba                	sd	a4,104(sp)
    800069ae:	f8be                	sd	a5,112(sp)
    800069b0:	fcc2                	sd	a6,120(sp)
    800069b2:	e146                	sd	a7,128(sp)
    800069b4:	e54a                	sd	s2,136(sp)
    800069b6:	e94e                	sd	s3,144(sp)
    800069b8:	ed52                	sd	s4,152(sp)
    800069ba:	f156                	sd	s5,160(sp)
    800069bc:	f55a                	sd	s6,168(sp)
    800069be:	f95e                	sd	s7,176(sp)
    800069c0:	fd62                	sd	s8,184(sp)
    800069c2:	e1e6                	sd	s9,192(sp)
    800069c4:	e5ea                	sd	s10,200(sp)
    800069c6:	e9ee                	sd	s11,208(sp)
    800069c8:	edf2                	sd	t3,216(sp)
    800069ca:	f1f6                	sd	t4,224(sp)
    800069cc:	f5fa                	sd	t5,232(sp)
    800069ce:	f9fe                	sd	t6,240(sp)
    800069d0:	d7ffc0ef          	jal	ra,8000374e <kerneltrap>
    800069d4:	6082                	ld	ra,0(sp)
    800069d6:	6122                	ld	sp,8(sp)
    800069d8:	61c2                	ld	gp,16(sp)
    800069da:	7282                	ld	t0,32(sp)
    800069dc:	7322                	ld	t1,40(sp)
    800069de:	73c2                	ld	t2,48(sp)
    800069e0:	7462                	ld	s0,56(sp)
    800069e2:	6486                	ld	s1,64(sp)
    800069e4:	6526                	ld	a0,72(sp)
    800069e6:	65c6                	ld	a1,80(sp)
    800069e8:	6666                	ld	a2,88(sp)
    800069ea:	7686                	ld	a3,96(sp)
    800069ec:	7726                	ld	a4,104(sp)
    800069ee:	77c6                	ld	a5,112(sp)
    800069f0:	7866                	ld	a6,120(sp)
    800069f2:	688a                	ld	a7,128(sp)
    800069f4:	692a                	ld	s2,136(sp)
    800069f6:	69ca                	ld	s3,144(sp)
    800069f8:	6a6a                	ld	s4,152(sp)
    800069fa:	7a8a                	ld	s5,160(sp)
    800069fc:	7b2a                	ld	s6,168(sp)
    800069fe:	7bca                	ld	s7,176(sp)
    80006a00:	7c6a                	ld	s8,184(sp)
    80006a02:	6c8e                	ld	s9,192(sp)
    80006a04:	6d2e                	ld	s10,200(sp)
    80006a06:	6dce                	ld	s11,208(sp)
    80006a08:	6e6e                	ld	t3,216(sp)
    80006a0a:	7e8e                	ld	t4,224(sp)
    80006a0c:	7f2e                	ld	t5,232(sp)
    80006a0e:	7fce                	ld	t6,240(sp)
    80006a10:	6111                	addi	sp,sp,256
    80006a12:	10200073          	sret
    80006a16:	00000013          	nop
    80006a1a:	00000013          	nop
    80006a1e:	0001                	nop

0000000080006a20 <timervec>:
    80006a20:	34051573          	csrrw	a0,mscratch,a0
    80006a24:	e10c                	sd	a1,0(a0)
    80006a26:	e510                	sd	a2,8(a0)
    80006a28:	e914                	sd	a3,16(a0)
    80006a2a:	6d0c                	ld	a1,24(a0)
    80006a2c:	7110                	ld	a2,32(a0)
    80006a2e:	6194                	ld	a3,0(a1)
    80006a30:	96b2                	add	a3,a3,a2
    80006a32:	e194                	sd	a3,0(a1)
    80006a34:	4589                	li	a1,2
    80006a36:	14459073          	csrw	sip,a1
    80006a3a:	6914                	ld	a3,16(a0)
    80006a3c:	6510                	ld	a2,8(a0)
    80006a3e:	610c                	ld	a1,0(a0)
    80006a40:	34051573          	csrrw	a0,mscratch,a0
    80006a44:	30200073          	mret
	...

0000000080006a4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006a4a:	1141                	addi	sp,sp,-16
    80006a4c:	e422                	sd	s0,8(sp)
    80006a4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006a50:	0c0007b7          	lui	a5,0xc000
    80006a54:	4705                	li	a4,1
    80006a56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006a58:	c3d8                	sw	a4,4(a5)
}
    80006a5a:	6422                	ld	s0,8(sp)
    80006a5c:	0141                	addi	sp,sp,16
    80006a5e:	8082                	ret

0000000080006a60 <plicinithart>:

void
plicinithart(void)
{
    80006a60:	1141                	addi	sp,sp,-16
    80006a62:	e406                	sd	ra,8(sp)
    80006a64:	e022                	sd	s0,0(sp)
    80006a66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006a68:	ffffb097          	auipc	ra,0xffffb
    80006a6c:	406080e7          	jalr	1030(ra) # 80001e6e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006a70:	0085171b          	slliw	a4,a0,0x8
    80006a74:	0c0027b7          	lui	a5,0xc002
    80006a78:	97ba                	add	a5,a5,a4
    80006a7a:	40200713          	li	a4,1026
    80006a7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006a82:	00d5151b          	slliw	a0,a0,0xd
    80006a86:	0c2017b7          	lui	a5,0xc201
    80006a8a:	953e                	add	a0,a0,a5
    80006a8c:	00052023          	sw	zero,0(a0)
}
    80006a90:	60a2                	ld	ra,8(sp)
    80006a92:	6402                	ld	s0,0(sp)
    80006a94:	0141                	addi	sp,sp,16
    80006a96:	8082                	ret

0000000080006a98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006a98:	1141                	addi	sp,sp,-16
    80006a9a:	e406                	sd	ra,8(sp)
    80006a9c:	e022                	sd	s0,0(sp)
    80006a9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006aa0:	ffffb097          	auipc	ra,0xffffb
    80006aa4:	3ce080e7          	jalr	974(ra) # 80001e6e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006aa8:	00d5179b          	slliw	a5,a0,0xd
    80006aac:	0c201537          	lui	a0,0xc201
    80006ab0:	953e                	add	a0,a0,a5
  return irq;
}
    80006ab2:	4148                	lw	a0,4(a0)
    80006ab4:	60a2                	ld	ra,8(sp)
    80006ab6:	6402                	ld	s0,0(sp)
    80006ab8:	0141                	addi	sp,sp,16
    80006aba:	8082                	ret

0000000080006abc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006abc:	1101                	addi	sp,sp,-32
    80006abe:	ec06                	sd	ra,24(sp)
    80006ac0:	e822                	sd	s0,16(sp)
    80006ac2:	e426                	sd	s1,8(sp)
    80006ac4:	1000                	addi	s0,sp,32
    80006ac6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006ac8:	ffffb097          	auipc	ra,0xffffb
    80006acc:	3a6080e7          	jalr	934(ra) # 80001e6e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006ad0:	00d5151b          	slliw	a0,a0,0xd
    80006ad4:	0c2017b7          	lui	a5,0xc201
    80006ad8:	97aa                	add	a5,a5,a0
    80006ada:	c3c4                	sw	s1,4(a5)
}
    80006adc:	60e2                	ld	ra,24(sp)
    80006ade:	6442                	ld	s0,16(sp)
    80006ae0:	64a2                	ld	s1,8(sp)
    80006ae2:	6105                	addi	sp,sp,32
    80006ae4:	8082                	ret

0000000080006ae6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006ae6:	1141                	addi	sp,sp,-16
    80006ae8:	e406                	sd	ra,8(sp)
    80006aea:	e022                	sd	s0,0(sp)
    80006aec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006aee:	479d                	li	a5,7
    80006af0:	06a7c963          	blt	a5,a0,80006b62 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006af4:	0001d797          	auipc	a5,0x1d
    80006af8:	50c78793          	addi	a5,a5,1292 # 80024000 <disk>
    80006afc:	00a78733          	add	a4,a5,a0
    80006b00:	6789                	lui	a5,0x2
    80006b02:	97ba                	add	a5,a5,a4
    80006b04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006b08:	e7ad                	bnez	a5,80006b72 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006b0a:	00451793          	slli	a5,a0,0x4
    80006b0e:	0001f717          	auipc	a4,0x1f
    80006b12:	4f270713          	addi	a4,a4,1266 # 80026000 <disk+0x2000>
    80006b16:	6314                	ld	a3,0(a4)
    80006b18:	96be                	add	a3,a3,a5
    80006b1a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006b1e:	6314                	ld	a3,0(a4)
    80006b20:	96be                	add	a3,a3,a5
    80006b22:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006b26:	6314                	ld	a3,0(a4)
    80006b28:	96be                	add	a3,a3,a5
    80006b2a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006b2e:	6318                	ld	a4,0(a4)
    80006b30:	97ba                	add	a5,a5,a4
    80006b32:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006b36:	0001d797          	auipc	a5,0x1d
    80006b3a:	4ca78793          	addi	a5,a5,1226 # 80024000 <disk>
    80006b3e:	97aa                	add	a5,a5,a0
    80006b40:	6509                	lui	a0,0x2
    80006b42:	953e                	add	a0,a0,a5
    80006b44:	4785                	li	a5,1
    80006b46:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006b4a:	0001f517          	auipc	a0,0x1f
    80006b4e:	4ce50513          	addi	a0,a0,1230 # 80026018 <disk+0x2018>
    80006b52:	ffffc097          	auipc	ra,0xffffc
    80006b56:	3e4080e7          	jalr	996(ra) # 80002f36 <wakeup>
}
    80006b5a:	60a2                	ld	ra,8(sp)
    80006b5c:	6402                	ld	s0,0(sp)
    80006b5e:	0141                	addi	sp,sp,16
    80006b60:	8082                	ret
    panic("free_desc 1");
    80006b62:	00003517          	auipc	a0,0x3
    80006b66:	df650513          	addi	a0,a0,-522 # 80009958 <syscalls+0x330>
    80006b6a:	ffffa097          	auipc	ra,0xffffa
    80006b6e:	9d4080e7          	jalr	-1580(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006b72:	00003517          	auipc	a0,0x3
    80006b76:	df650513          	addi	a0,a0,-522 # 80009968 <syscalls+0x340>
    80006b7a:	ffffa097          	auipc	ra,0xffffa
    80006b7e:	9c4080e7          	jalr	-1596(ra) # 8000053e <panic>

0000000080006b82 <virtio_disk_init>:
{
    80006b82:	1101                	addi	sp,sp,-32
    80006b84:	ec06                	sd	ra,24(sp)
    80006b86:	e822                	sd	s0,16(sp)
    80006b88:	e426                	sd	s1,8(sp)
    80006b8a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006b8c:	00003597          	auipc	a1,0x3
    80006b90:	dec58593          	addi	a1,a1,-532 # 80009978 <syscalls+0x350>
    80006b94:	0001f517          	auipc	a0,0x1f
    80006b98:	59450513          	addi	a0,a0,1428 # 80026128 <disk+0x2128>
    80006b9c:	ffffa097          	auipc	ra,0xffffa
    80006ba0:	fb8080e7          	jalr	-72(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006ba4:	100017b7          	lui	a5,0x10001
    80006ba8:	4398                	lw	a4,0(a5)
    80006baa:	2701                	sext.w	a4,a4
    80006bac:	747277b7          	lui	a5,0x74727
    80006bb0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006bb4:	0ef71163          	bne	a4,a5,80006c96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006bb8:	100017b7          	lui	a5,0x10001
    80006bbc:	43dc                	lw	a5,4(a5)
    80006bbe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006bc0:	4705                	li	a4,1
    80006bc2:	0ce79a63          	bne	a5,a4,80006c96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006bc6:	100017b7          	lui	a5,0x10001
    80006bca:	479c                	lw	a5,8(a5)
    80006bcc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006bce:	4709                	li	a4,2
    80006bd0:	0ce79363          	bne	a5,a4,80006c96 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006bd4:	100017b7          	lui	a5,0x10001
    80006bd8:	47d8                	lw	a4,12(a5)
    80006bda:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006bdc:	554d47b7          	lui	a5,0x554d4
    80006be0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006be4:	0af71963          	bne	a4,a5,80006c96 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006be8:	100017b7          	lui	a5,0x10001
    80006bec:	4705                	li	a4,1
    80006bee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006bf0:	470d                	li	a4,3
    80006bf2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006bf4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006bf6:	c7ffe737          	lui	a4,0xc7ffe
    80006bfa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80006bfe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006c00:	2701                	sext.w	a4,a4
    80006c02:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c04:	472d                	li	a4,11
    80006c06:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c08:	473d                	li	a4,15
    80006c0a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006c0c:	6705                	lui	a4,0x1
    80006c0e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006c10:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006c14:	5bdc                	lw	a5,52(a5)
    80006c16:	2781                	sext.w	a5,a5
  if(max == 0)
    80006c18:	c7d9                	beqz	a5,80006ca6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006c1a:	471d                	li	a4,7
    80006c1c:	08f77d63          	bgeu	a4,a5,80006cb6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006c20:	100014b7          	lui	s1,0x10001
    80006c24:	47a1                	li	a5,8
    80006c26:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006c28:	6609                	lui	a2,0x2
    80006c2a:	4581                	li	a1,0
    80006c2c:	0001d517          	auipc	a0,0x1d
    80006c30:	3d450513          	addi	a0,a0,980 # 80024000 <disk>
    80006c34:	ffffa097          	auipc	ra,0xffffa
    80006c38:	0ba080e7          	jalr	186(ra) # 80000cee <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006c3c:	0001d717          	auipc	a4,0x1d
    80006c40:	3c470713          	addi	a4,a4,964 # 80024000 <disk>
    80006c44:	00c75793          	srli	a5,a4,0xc
    80006c48:	2781                	sext.w	a5,a5
    80006c4a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006c4c:	0001f797          	auipc	a5,0x1f
    80006c50:	3b478793          	addi	a5,a5,948 # 80026000 <disk+0x2000>
    80006c54:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006c56:	0001d717          	auipc	a4,0x1d
    80006c5a:	42a70713          	addi	a4,a4,1066 # 80024080 <disk+0x80>
    80006c5e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006c60:	0001e717          	auipc	a4,0x1e
    80006c64:	3a070713          	addi	a4,a4,928 # 80025000 <disk+0x1000>
    80006c68:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006c6a:	4705                	li	a4,1
    80006c6c:	00e78c23          	sb	a4,24(a5)
    80006c70:	00e78ca3          	sb	a4,25(a5)
    80006c74:	00e78d23          	sb	a4,26(a5)
    80006c78:	00e78da3          	sb	a4,27(a5)
    80006c7c:	00e78e23          	sb	a4,28(a5)
    80006c80:	00e78ea3          	sb	a4,29(a5)
    80006c84:	00e78f23          	sb	a4,30(a5)
    80006c88:	00e78fa3          	sb	a4,31(a5)
}
    80006c8c:	60e2                	ld	ra,24(sp)
    80006c8e:	6442                	ld	s0,16(sp)
    80006c90:	64a2                	ld	s1,8(sp)
    80006c92:	6105                	addi	sp,sp,32
    80006c94:	8082                	ret
    panic("could not find virtio disk");
    80006c96:	00003517          	auipc	a0,0x3
    80006c9a:	cf250513          	addi	a0,a0,-782 # 80009988 <syscalls+0x360>
    80006c9e:	ffffa097          	auipc	ra,0xffffa
    80006ca2:	8a0080e7          	jalr	-1888(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006ca6:	00003517          	auipc	a0,0x3
    80006caa:	d0250513          	addi	a0,a0,-766 # 800099a8 <syscalls+0x380>
    80006cae:	ffffa097          	auipc	ra,0xffffa
    80006cb2:	890080e7          	jalr	-1904(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006cb6:	00003517          	auipc	a0,0x3
    80006cba:	d1250513          	addi	a0,a0,-750 # 800099c8 <syscalls+0x3a0>
    80006cbe:	ffffa097          	auipc	ra,0xffffa
    80006cc2:	880080e7          	jalr	-1920(ra) # 8000053e <panic>

0000000080006cc6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006cc6:	7159                	addi	sp,sp,-112
    80006cc8:	f486                	sd	ra,104(sp)
    80006cca:	f0a2                	sd	s0,96(sp)
    80006ccc:	eca6                	sd	s1,88(sp)
    80006cce:	e8ca                	sd	s2,80(sp)
    80006cd0:	e4ce                	sd	s3,72(sp)
    80006cd2:	e0d2                	sd	s4,64(sp)
    80006cd4:	fc56                	sd	s5,56(sp)
    80006cd6:	f85a                	sd	s6,48(sp)
    80006cd8:	f45e                	sd	s7,40(sp)
    80006cda:	f062                	sd	s8,32(sp)
    80006cdc:	ec66                	sd	s9,24(sp)
    80006cde:	e86a                	sd	s10,16(sp)
    80006ce0:	1880                	addi	s0,sp,112
    80006ce2:	892a                	mv	s2,a0
    80006ce4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006ce6:	00c52c83          	lw	s9,12(a0)
    80006cea:	001c9c9b          	slliw	s9,s9,0x1
    80006cee:	1c82                	slli	s9,s9,0x20
    80006cf0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006cf4:	0001f517          	auipc	a0,0x1f
    80006cf8:	43450513          	addi	a0,a0,1076 # 80026128 <disk+0x2128>
    80006cfc:	ffffa097          	auipc	ra,0xffffa
    80006d00:	ef0080e7          	jalr	-272(ra) # 80000bec <acquire>
  for(int i = 0; i < 3; i++){
    80006d04:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006d06:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006d08:	0001db97          	auipc	s7,0x1d
    80006d0c:	2f8b8b93          	addi	s7,s7,760 # 80024000 <disk>
    80006d10:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006d12:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006d14:	8a4e                	mv	s4,s3
    80006d16:	a051                	j	80006d9a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006d18:	00fb86b3          	add	a3,s7,a5
    80006d1c:	96da                	add	a3,a3,s6
    80006d1e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006d22:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006d24:	0207c563          	bltz	a5,80006d4e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006d28:	2485                	addiw	s1,s1,1
    80006d2a:	0711                	addi	a4,a4,4
    80006d2c:	25548063          	beq	s1,s5,80006f6c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006d30:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006d32:	0001f697          	auipc	a3,0x1f
    80006d36:	2e668693          	addi	a3,a3,742 # 80026018 <disk+0x2018>
    80006d3a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006d3c:	0006c583          	lbu	a1,0(a3)
    80006d40:	fde1                	bnez	a1,80006d18 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006d42:	2785                	addiw	a5,a5,1
    80006d44:	0685                	addi	a3,a3,1
    80006d46:	ff879be3          	bne	a5,s8,80006d3c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006d4a:	57fd                	li	a5,-1
    80006d4c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006d4e:	02905a63          	blez	s1,80006d82 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006d52:	f9042503          	lw	a0,-112(s0)
    80006d56:	00000097          	auipc	ra,0x0
    80006d5a:	d90080e7          	jalr	-624(ra) # 80006ae6 <free_desc>
      for(int j = 0; j < i; j++)
    80006d5e:	4785                	li	a5,1
    80006d60:	0297d163          	bge	a5,s1,80006d82 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006d64:	f9442503          	lw	a0,-108(s0)
    80006d68:	00000097          	auipc	ra,0x0
    80006d6c:	d7e080e7          	jalr	-642(ra) # 80006ae6 <free_desc>
      for(int j = 0; j < i; j++)
    80006d70:	4789                	li	a5,2
    80006d72:	0097d863          	bge	a5,s1,80006d82 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006d76:	f9842503          	lw	a0,-104(s0)
    80006d7a:	00000097          	auipc	ra,0x0
    80006d7e:	d6c080e7          	jalr	-660(ra) # 80006ae6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006d82:	0001f597          	auipc	a1,0x1f
    80006d86:	3a658593          	addi	a1,a1,934 # 80026128 <disk+0x2128>
    80006d8a:	0001f517          	auipc	a0,0x1f
    80006d8e:	28e50513          	addi	a0,a0,654 # 80026018 <disk+0x2018>
    80006d92:	ffffc097          	auipc	ra,0xffffc
    80006d96:	ffc080e7          	jalr	-4(ra) # 80002d8e <sleep>
  for(int i = 0; i < 3; i++){
    80006d9a:	f9040713          	addi	a4,s0,-112
    80006d9e:	84ce                	mv	s1,s3
    80006da0:	bf41                	j	80006d30 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006da2:	20058713          	addi	a4,a1,512
    80006da6:	00471693          	slli	a3,a4,0x4
    80006daa:	0001d717          	auipc	a4,0x1d
    80006dae:	25670713          	addi	a4,a4,598 # 80024000 <disk>
    80006db2:	9736                	add	a4,a4,a3
    80006db4:	4685                	li	a3,1
    80006db6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006dba:	20058713          	addi	a4,a1,512
    80006dbe:	00471693          	slli	a3,a4,0x4
    80006dc2:	0001d717          	auipc	a4,0x1d
    80006dc6:	23e70713          	addi	a4,a4,574 # 80024000 <disk>
    80006dca:	9736                	add	a4,a4,a3
    80006dcc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006dd0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006dd4:	7679                	lui	a2,0xffffe
    80006dd6:	963e                	add	a2,a2,a5
    80006dd8:	0001f697          	auipc	a3,0x1f
    80006ddc:	22868693          	addi	a3,a3,552 # 80026000 <disk+0x2000>
    80006de0:	6298                	ld	a4,0(a3)
    80006de2:	9732                	add	a4,a4,a2
    80006de4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006de6:	6298                	ld	a4,0(a3)
    80006de8:	9732                	add	a4,a4,a2
    80006dea:	4541                	li	a0,16
    80006dec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006dee:	6298                	ld	a4,0(a3)
    80006df0:	9732                	add	a4,a4,a2
    80006df2:	4505                	li	a0,1
    80006df4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006df8:	f9442703          	lw	a4,-108(s0)
    80006dfc:	6288                	ld	a0,0(a3)
    80006dfe:	962a                	add	a2,a2,a0
    80006e00:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006e04:	0712                	slli	a4,a4,0x4
    80006e06:	6290                	ld	a2,0(a3)
    80006e08:	963a                	add	a2,a2,a4
    80006e0a:	05890513          	addi	a0,s2,88
    80006e0e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006e10:	6294                	ld	a3,0(a3)
    80006e12:	96ba                	add	a3,a3,a4
    80006e14:	40000613          	li	a2,1024
    80006e18:	c690                	sw	a2,8(a3)
  if(write)
    80006e1a:	140d0063          	beqz	s10,80006f5a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006e1e:	0001f697          	auipc	a3,0x1f
    80006e22:	1e26b683          	ld	a3,482(a3) # 80026000 <disk+0x2000>
    80006e26:	96ba                	add	a3,a3,a4
    80006e28:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006e2c:	0001d817          	auipc	a6,0x1d
    80006e30:	1d480813          	addi	a6,a6,468 # 80024000 <disk>
    80006e34:	0001f517          	auipc	a0,0x1f
    80006e38:	1cc50513          	addi	a0,a0,460 # 80026000 <disk+0x2000>
    80006e3c:	6114                	ld	a3,0(a0)
    80006e3e:	96ba                	add	a3,a3,a4
    80006e40:	00c6d603          	lhu	a2,12(a3)
    80006e44:	00166613          	ori	a2,a2,1
    80006e48:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006e4c:	f9842683          	lw	a3,-104(s0)
    80006e50:	6110                	ld	a2,0(a0)
    80006e52:	9732                	add	a4,a4,a2
    80006e54:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006e58:	20058613          	addi	a2,a1,512
    80006e5c:	0612                	slli	a2,a2,0x4
    80006e5e:	9642                	add	a2,a2,a6
    80006e60:	577d                	li	a4,-1
    80006e62:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006e66:	00469713          	slli	a4,a3,0x4
    80006e6a:	6114                	ld	a3,0(a0)
    80006e6c:	96ba                	add	a3,a3,a4
    80006e6e:	03078793          	addi	a5,a5,48
    80006e72:	97c2                	add	a5,a5,a6
    80006e74:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006e76:	611c                	ld	a5,0(a0)
    80006e78:	97ba                	add	a5,a5,a4
    80006e7a:	4685                	li	a3,1
    80006e7c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006e7e:	611c                	ld	a5,0(a0)
    80006e80:	97ba                	add	a5,a5,a4
    80006e82:	4809                	li	a6,2
    80006e84:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006e88:	611c                	ld	a5,0(a0)
    80006e8a:	973e                	add	a4,a4,a5
    80006e8c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006e90:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006e94:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006e98:	6518                	ld	a4,8(a0)
    80006e9a:	00275783          	lhu	a5,2(a4)
    80006e9e:	8b9d                	andi	a5,a5,7
    80006ea0:	0786                	slli	a5,a5,0x1
    80006ea2:	97ba                	add	a5,a5,a4
    80006ea4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006ea8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006eac:	6518                	ld	a4,8(a0)
    80006eae:	00275783          	lhu	a5,2(a4)
    80006eb2:	2785                	addiw	a5,a5,1
    80006eb4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006eb8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006ebc:	100017b7          	lui	a5,0x10001
    80006ec0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006ec4:	00492703          	lw	a4,4(s2)
    80006ec8:	4785                	li	a5,1
    80006eca:	02f71163          	bne	a4,a5,80006eec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006ece:	0001f997          	auipc	s3,0x1f
    80006ed2:	25a98993          	addi	s3,s3,602 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    80006ed6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006ed8:	85ce                	mv	a1,s3
    80006eda:	854a                	mv	a0,s2
    80006edc:	ffffc097          	auipc	ra,0xffffc
    80006ee0:	eb2080e7          	jalr	-334(ra) # 80002d8e <sleep>
  while(b->disk == 1) {
    80006ee4:	00492783          	lw	a5,4(s2)
    80006ee8:	fe9788e3          	beq	a5,s1,80006ed8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006eec:	f9042903          	lw	s2,-112(s0)
    80006ef0:	20090793          	addi	a5,s2,512
    80006ef4:	00479713          	slli	a4,a5,0x4
    80006ef8:	0001d797          	auipc	a5,0x1d
    80006efc:	10878793          	addi	a5,a5,264 # 80024000 <disk>
    80006f00:	97ba                	add	a5,a5,a4
    80006f02:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006f06:	0001f997          	auipc	s3,0x1f
    80006f0a:	0fa98993          	addi	s3,s3,250 # 80026000 <disk+0x2000>
    80006f0e:	00491713          	slli	a4,s2,0x4
    80006f12:	0009b783          	ld	a5,0(s3)
    80006f16:	97ba                	add	a5,a5,a4
    80006f18:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006f1c:	854a                	mv	a0,s2
    80006f1e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006f22:	00000097          	auipc	ra,0x0
    80006f26:	bc4080e7          	jalr	-1084(ra) # 80006ae6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006f2a:	8885                	andi	s1,s1,1
    80006f2c:	f0ed                	bnez	s1,80006f0e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006f2e:	0001f517          	auipc	a0,0x1f
    80006f32:	1fa50513          	addi	a0,a0,506 # 80026128 <disk+0x2128>
    80006f36:	ffffa097          	auipc	ra,0xffffa
    80006f3a:	d70080e7          	jalr	-656(ra) # 80000ca6 <release>
}
    80006f3e:	70a6                	ld	ra,104(sp)
    80006f40:	7406                	ld	s0,96(sp)
    80006f42:	64e6                	ld	s1,88(sp)
    80006f44:	6946                	ld	s2,80(sp)
    80006f46:	69a6                	ld	s3,72(sp)
    80006f48:	6a06                	ld	s4,64(sp)
    80006f4a:	7ae2                	ld	s5,56(sp)
    80006f4c:	7b42                	ld	s6,48(sp)
    80006f4e:	7ba2                	ld	s7,40(sp)
    80006f50:	7c02                	ld	s8,32(sp)
    80006f52:	6ce2                	ld	s9,24(sp)
    80006f54:	6d42                	ld	s10,16(sp)
    80006f56:	6165                	addi	sp,sp,112
    80006f58:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006f5a:	0001f697          	auipc	a3,0x1f
    80006f5e:	0a66b683          	ld	a3,166(a3) # 80026000 <disk+0x2000>
    80006f62:	96ba                	add	a3,a3,a4
    80006f64:	4609                	li	a2,2
    80006f66:	00c69623          	sh	a2,12(a3)
    80006f6a:	b5c9                	j	80006e2c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f6c:	f9042583          	lw	a1,-112(s0)
    80006f70:	20058793          	addi	a5,a1,512
    80006f74:	0792                	slli	a5,a5,0x4
    80006f76:	0001d517          	auipc	a0,0x1d
    80006f7a:	13250513          	addi	a0,a0,306 # 800240a8 <disk+0xa8>
    80006f7e:	953e                	add	a0,a0,a5
  if(write)
    80006f80:	e20d11e3          	bnez	s10,80006da2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006f84:	20058713          	addi	a4,a1,512
    80006f88:	00471693          	slli	a3,a4,0x4
    80006f8c:	0001d717          	auipc	a4,0x1d
    80006f90:	07470713          	addi	a4,a4,116 # 80024000 <disk>
    80006f94:	9736                	add	a4,a4,a3
    80006f96:	0a072423          	sw	zero,168(a4)
    80006f9a:	b505                	j	80006dba <virtio_disk_rw+0xf4>

0000000080006f9c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006f9c:	1101                	addi	sp,sp,-32
    80006f9e:	ec06                	sd	ra,24(sp)
    80006fa0:	e822                	sd	s0,16(sp)
    80006fa2:	e426                	sd	s1,8(sp)
    80006fa4:	e04a                	sd	s2,0(sp)
    80006fa6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006fa8:	0001f517          	auipc	a0,0x1f
    80006fac:	18050513          	addi	a0,a0,384 # 80026128 <disk+0x2128>
    80006fb0:	ffffa097          	auipc	ra,0xffffa
    80006fb4:	c3c080e7          	jalr	-964(ra) # 80000bec <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006fb8:	10001737          	lui	a4,0x10001
    80006fbc:	533c                	lw	a5,96(a4)
    80006fbe:	8b8d                	andi	a5,a5,3
    80006fc0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006fc2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006fc6:	0001f797          	auipc	a5,0x1f
    80006fca:	03a78793          	addi	a5,a5,58 # 80026000 <disk+0x2000>
    80006fce:	6b94                	ld	a3,16(a5)
    80006fd0:	0207d703          	lhu	a4,32(a5)
    80006fd4:	0026d783          	lhu	a5,2(a3)
    80006fd8:	06f70163          	beq	a4,a5,8000703a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006fdc:	0001d917          	auipc	s2,0x1d
    80006fe0:	02490913          	addi	s2,s2,36 # 80024000 <disk>
    80006fe4:	0001f497          	auipc	s1,0x1f
    80006fe8:	01c48493          	addi	s1,s1,28 # 80026000 <disk+0x2000>
    __sync_synchronize();
    80006fec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ff0:	6898                	ld	a4,16(s1)
    80006ff2:	0204d783          	lhu	a5,32(s1)
    80006ff6:	8b9d                	andi	a5,a5,7
    80006ff8:	078e                	slli	a5,a5,0x3
    80006ffa:	97ba                	add	a5,a5,a4
    80006ffc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006ffe:	20078713          	addi	a4,a5,512
    80007002:	0712                	slli	a4,a4,0x4
    80007004:	974a                	add	a4,a4,s2
    80007006:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000700a:	e731                	bnez	a4,80007056 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000700c:	20078793          	addi	a5,a5,512
    80007010:	0792                	slli	a5,a5,0x4
    80007012:	97ca                	add	a5,a5,s2
    80007014:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007016:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000701a:	ffffc097          	auipc	ra,0xffffc
    8000701e:	f1c080e7          	jalr	-228(ra) # 80002f36 <wakeup>

    disk.used_idx += 1;
    80007022:	0204d783          	lhu	a5,32(s1)
    80007026:	2785                	addiw	a5,a5,1
    80007028:	17c2                	slli	a5,a5,0x30
    8000702a:	93c1                	srli	a5,a5,0x30
    8000702c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007030:	6898                	ld	a4,16(s1)
    80007032:	00275703          	lhu	a4,2(a4)
    80007036:	faf71be3          	bne	a4,a5,80006fec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000703a:	0001f517          	auipc	a0,0x1f
    8000703e:	0ee50513          	addi	a0,a0,238 # 80026128 <disk+0x2128>
    80007042:	ffffa097          	auipc	ra,0xffffa
    80007046:	c64080e7          	jalr	-924(ra) # 80000ca6 <release>
}
    8000704a:	60e2                	ld	ra,24(sp)
    8000704c:	6442                	ld	s0,16(sp)
    8000704e:	64a2                	ld	s1,8(sp)
    80007050:	6902                	ld	s2,0(sp)
    80007052:	6105                	addi	sp,sp,32
    80007054:	8082                	ret
      panic("virtio_disk_intr status");
    80007056:	00003517          	auipc	a0,0x3
    8000705a:	99250513          	addi	a0,a0,-1646 # 800099e8 <syscalls+0x3c0>
    8000705e:	ffff9097          	auipc	ra,0xffff9
    80007062:	4e0080e7          	jalr	1248(ra) # 8000053e <panic>

0000000080007066 <cas>:
    80007066:	100522af          	lr.w	t0,(a0)
    8000706a:	00b29563          	bne	t0,a1,80007074 <fail>
    8000706e:	18c5252f          	sc.w	a0,a2,(a0)
    80007072:	8082                	ret

0000000080007074 <fail>:
    80007074:	4505                	li	a0,1
    80007076:	8082                	ret
	...

0000000080008000 <_trampoline>:
    80008000:	14051573          	csrrw	a0,sscratch,a0
    80008004:	02153423          	sd	ra,40(a0)
    80008008:	02253823          	sd	sp,48(a0)
    8000800c:	02353c23          	sd	gp,56(a0)
    80008010:	04453023          	sd	tp,64(a0)
    80008014:	04553423          	sd	t0,72(a0)
    80008018:	04653823          	sd	t1,80(a0)
    8000801c:	04753c23          	sd	t2,88(a0)
    80008020:	f120                	sd	s0,96(a0)
    80008022:	f524                	sd	s1,104(a0)
    80008024:	fd2c                	sd	a1,120(a0)
    80008026:	e150                	sd	a2,128(a0)
    80008028:	e554                	sd	a3,136(a0)
    8000802a:	e958                	sd	a4,144(a0)
    8000802c:	ed5c                	sd	a5,152(a0)
    8000802e:	0b053023          	sd	a6,160(a0)
    80008032:	0b153423          	sd	a7,168(a0)
    80008036:	0b253823          	sd	s2,176(a0)
    8000803a:	0b353c23          	sd	s3,184(a0)
    8000803e:	0d453023          	sd	s4,192(a0)
    80008042:	0d553423          	sd	s5,200(a0)
    80008046:	0d653823          	sd	s6,208(a0)
    8000804a:	0d753c23          	sd	s7,216(a0)
    8000804e:	0f853023          	sd	s8,224(a0)
    80008052:	0f953423          	sd	s9,232(a0)
    80008056:	0fa53823          	sd	s10,240(a0)
    8000805a:	0fb53c23          	sd	s11,248(a0)
    8000805e:	11c53023          	sd	t3,256(a0)
    80008062:	11d53423          	sd	t4,264(a0)
    80008066:	11e53823          	sd	t5,272(a0)
    8000806a:	11f53c23          	sd	t6,280(a0)
    8000806e:	140022f3          	csrr	t0,sscratch
    80008072:	06553823          	sd	t0,112(a0)
    80008076:	00853103          	ld	sp,8(a0)
    8000807a:	02053203          	ld	tp,32(a0)
    8000807e:	01053283          	ld	t0,16(a0)
    80008082:	00053303          	ld	t1,0(a0)
    80008086:	18031073          	csrw	satp,t1
    8000808a:	12000073          	sfence.vma
    8000808e:	8282                	jr	t0

0000000080008090 <userret>:
    80008090:	18059073          	csrw	satp,a1
    80008094:	12000073          	sfence.vma
    80008098:	07053283          	ld	t0,112(a0)
    8000809c:	14029073          	csrw	sscratch,t0
    800080a0:	02853083          	ld	ra,40(a0)
    800080a4:	03053103          	ld	sp,48(a0)
    800080a8:	03853183          	ld	gp,56(a0)
    800080ac:	04053203          	ld	tp,64(a0)
    800080b0:	04853283          	ld	t0,72(a0)
    800080b4:	05053303          	ld	t1,80(a0)
    800080b8:	05853383          	ld	t2,88(a0)
    800080bc:	7120                	ld	s0,96(a0)
    800080be:	7524                	ld	s1,104(a0)
    800080c0:	7d2c                	ld	a1,120(a0)
    800080c2:	6150                	ld	a2,128(a0)
    800080c4:	6554                	ld	a3,136(a0)
    800080c6:	6958                	ld	a4,144(a0)
    800080c8:	6d5c                	ld	a5,152(a0)
    800080ca:	0a053803          	ld	a6,160(a0)
    800080ce:	0a853883          	ld	a7,168(a0)
    800080d2:	0b053903          	ld	s2,176(a0)
    800080d6:	0b853983          	ld	s3,184(a0)
    800080da:	0c053a03          	ld	s4,192(a0)
    800080de:	0c853a83          	ld	s5,200(a0)
    800080e2:	0d053b03          	ld	s6,208(a0)
    800080e6:	0d853b83          	ld	s7,216(a0)
    800080ea:	0e053c03          	ld	s8,224(a0)
    800080ee:	0e853c83          	ld	s9,232(a0)
    800080f2:	0f053d03          	ld	s10,240(a0)
    800080f6:	0f853d83          	ld	s11,248(a0)
    800080fa:	10053e03          	ld	t3,256(a0)
    800080fe:	10853e83          	ld	t4,264(a0)
    80008102:	11053f03          	ld	t5,272(a0)
    80008106:	11853f83          	ld	t6,280(a0)
    8000810a:	14051573          	csrrw	a0,sscratch,a0
    8000810e:	10200073          	sret
	...
