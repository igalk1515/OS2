
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8d013103          	ld	sp,-1840(sp) # 800088d0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000052:	00009717          	auipc	a4,0x9
    80000056:	ffe70713          	addi	a4,a4,-2 # 80009050 <timer_scratch>
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
    80000064:	00006797          	auipc	a5,0x6
    80000068:	e4c78793          	addi	a5,a5,-436 # 80005eb0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	68c080e7          	jalr	1676(ra) # 800027b8 <either_copyin>
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
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	00450513          	addi	a0,a0,4 # 80011190 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	ff448493          	addi	s1,s1,-12 # 80011190 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	08290913          	addi	s2,s2,130 # 80011228 <cons+0x98>
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
    800001c8:	ab4080e7          	jalr	-1356(ra) # 80001c78 <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	1ea080e7          	jalr	490(ra) # 800023be <sleep>
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
    80000210:	00002097          	auipc	ra,0x2
    80000214:	552080e7          	jalr	1362(ra) # 80002762 <either_copyout>
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
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f6c50513          	addi	a0,a0,-148 # 80011190 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f5650513          	addi	a0,a0,-170 # 80011190 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
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
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72b23          	sw	a5,-74(a4) # 80011228 <cons+0x98>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ec450513          	addi	a0,a0,-316 # 80011190 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

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
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	51c080e7          	jalr	1308(ra) # 8000280e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e9650513          	addi	a0,a0,-362 # 80011190 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
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
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e7270713          	addi	a4,a4,-398 # 80011190 <cons>
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
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e4878793          	addi	a5,a5,-440 # 80011190 <cons>
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
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	eb27a783          	lw	a5,-334(a5) # 80011228 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e0670713          	addi	a4,a4,-506 # 80011190 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	df648493          	addi	s1,s1,-522 # 80011190 <cons>
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	dba70713          	addi	a4,a4,-582 # 80011190 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72223          	sw	a5,-444(a4) # 80011230 <cons+0xa0>
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
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d7e78793          	addi	a5,a5,-642 # 80011190 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7ab23          	sw	a2,-522(a5) # 8001122c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dea50513          	addi	a0,a0,-534 # 80011228 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	104080e7          	jalr	260(ra) # 8000254a <wakeup>
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
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d3050513          	addi	a0,a0,-720 # 80011190 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	9f878793          	addi	a5,a5,-1544 # 80021e70 <devsw>
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
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
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
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	d007a323          	sw	zero,-762(a5) # 80011250 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
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
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c96dad83          	lw	s11,-874(s11) # 80011250 <pr+0x18>
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
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c4050513          	addi	a0,a0,-960 # 80011238 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
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
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
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
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	adc50513          	addi	a0,a0,-1316 # 80011238 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
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
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ac048493          	addi	s1,s1,-1344 # 80011238 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
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
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a8050513          	addi	a0,a0,-1408 # 80011258 <uart_tx_lock>
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
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
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
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
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
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
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
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9eea0a13          	addi	s4,s4,-1554 # 80011258 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
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
    800008a4:	caa080e7          	jalr	-854(ra) # 8000254a <wakeup>
    
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
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	97c50513          	addi	a0,a0,-1668 # 80011258 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	948a0a13          	addi	s4,s4,-1720 # 80011258 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	a92080e7          	jalr	-1390(ra) # 800023be <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	91648493          	addi	s1,s1,-1770 # 80011258 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
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
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	88e48493          	addi	s1,s1,-1906 # 80011258 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
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
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
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
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	86490913          	addi	s2,s2,-1948 # 80011290 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
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
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7c850513          	addi	a0,a0,1992 # 80011290 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
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
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	79248493          	addi	s1,s1,1938 # 80011290 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	77a50513          	addi	a0,a0,1914 # 80011290 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	74e50513          	addi	a0,a0,1870 # 80011290 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
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
    80000b82:	0d6080e7          	jalr	214(ra) # 80001c54 <mycpu>
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
    80000bb4:	0a4080e7          	jalr	164(ra) # 80001c54 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	098080e7          	jalr	152(ra) # 80001c54 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	080080e7          	jalr	128(ra) # 80001c54 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	040080e7          	jalr	64(ra) # 80001c54 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	014080e7          	jalr	20(ra) # 80001c54 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	dae080e7          	jalr	-594(ra) # 80001c44 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	d92080e7          	jalr	-622(ra) # 80001c44 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	a7a080e7          	jalr	-1414(ra) # 8000294e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	014080e7          	jalr	20(ra) # 80005ef0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	2c8080e7          	jalr	712(ra) # 800021ac <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	c50080e7          	jalr	-944(ra) # 80001b94 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	9da080e7          	jalr	-1574(ra) # 80002926 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	9fa080e7          	jalr	-1542(ra) # 8000294e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	f7e080e7          	jalr	-130(ra) # 80005eda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f8c080e7          	jalr	-116(ra) # 80005ef0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	16e080e7          	jalr	366(ra) # 800030da <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	7fe080e7          	jalr	2046(ra) # 80003772 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	7a8080e7          	jalr	1960(ra) # 80004724 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	08e080e7          	jalr	142(ra) # 80006012 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	fda080e7          	jalr	-38(ra) # 80001f66 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00001097          	auipc	ra,0x1
    80001244:	8be080e7          	jalr	-1858(ra) # 80001afe <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <acquire_list>:
 * 2 = zombie 
 * 3 = sleeping 
 * 4 = unused  
 */
void
acquire_list(int number, int cpu_id){ // TODO: change name of function
    8000183e:	1141                	addi	sp,sp,-16
    80001840:	e406                	sd	ra,8(sp)
    80001842:	e022                	sd	s0,0(sp)
    80001844:	0800                	addi	s0,sp,16
int a =0;
a=a+1;
if(a==0){
  panic("a not zero ");
}
  number == 1 ?  acquire(&readyLock[cpu_id]): 
    80001846:	4785                	li	a5,1
    80001848:	02f50763          	beq	a0,a5,80001876 <acquire_list+0x38>
    number == 2 ? acquire(&zombieLock): 
    8000184c:	4789                	li	a5,2
    8000184e:	04f50263          	beq	a0,a5,80001892 <acquire_list+0x54>
      number == 3 ? acquire(&sleepLock): 
    80001852:	478d                	li	a5,3
    80001854:	04f50863          	beq	a0,a5,800018a4 <acquire_list+0x66>
        number == 4 ? acquire(&unusedLock):  
    80001858:	4791                	li	a5,4
    8000185a:	04f51e63          	bne	a0,a5,800018b6 <acquire_list+0x78>
    8000185e:	00010517          	auipc	a0,0x10
    80001862:	b4250513          	addi	a0,a0,-1214 # 800113a0 <unusedLock>
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	37e080e7          	jalr	894(ra) # 80000be4 <acquire>
          panic("wrong call in acquire_list");
}
    8000186e:	60a2                	ld	ra,8(sp)
    80001870:	6402                	ld	s0,0(sp)
    80001872:	0141                	addi	sp,sp,16
    80001874:	8082                	ret
  number == 1 ?  acquire(&readyLock[cpu_id]): 
    80001876:	00159513          	slli	a0,a1,0x1
    8000187a:	95aa                	add	a1,a1,a0
    8000187c:	058e                	slli	a1,a1,0x3
    8000187e:	00010517          	auipc	a0,0x10
    80001882:	a3250513          	addi	a0,a0,-1486 # 800112b0 <readyLock>
    80001886:	952e                	add	a0,a0,a1
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	35c080e7          	jalr	860(ra) # 80000be4 <acquire>
    80001890:	bff9                	j	8000186e <acquire_list+0x30>
    number == 2 ? acquire(&zombieLock): 
    80001892:	00010517          	auipc	a0,0x10
    80001896:	ade50513          	addi	a0,a0,-1314 # 80011370 <zombieLock>
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	34a080e7          	jalr	842(ra) # 80000be4 <acquire>
    800018a2:	b7f1                	j	8000186e <acquire_list+0x30>
      number == 3 ? acquire(&sleepLock): 
    800018a4:	00010517          	auipc	a0,0x10
    800018a8:	ae450513          	addi	a0,a0,-1308 # 80011388 <sleepLock>
    800018ac:	fffff097          	auipc	ra,0xfffff
    800018b0:	338080e7          	jalr	824(ra) # 80000be4 <acquire>
    800018b4:	bf6d                	j	8000186e <acquire_list+0x30>
          panic("wrong call in acquire_list");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	92250513          	addi	a0,a0,-1758 # 800081d8 <digits+0x198>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c80080e7          	jalr	-896(ra) # 8000053e <panic>

00000000800018c6 <get_first>:

struct proc* get_first(int number, int cpu_id){
  struct proc* p;
  number == 1 ? p = cpus[cpu_id].first :
    800018c6:	4785                	li	a5,1
    800018c8:	02f50063          	beq	a0,a5,800018e8 <get_first+0x22>
    number == 2 ? p = zombieList  :
    800018cc:	4789                	li	a5,2
    800018ce:	02f50963          	beq	a0,a5,80001900 <get_first+0x3a>
      number == 3 ? p = sleepingList :
    800018d2:	478d                	li	a5,3
    800018d4:	02f50b63          	beq	a0,a5,8000190a <get_first+0x44>
        number == 4 ? p = unusedList:
    800018d8:	4791                	li	a5,4
    800018da:	02f51d63          	bne	a0,a5,80001914 <get_first+0x4e>
    800018de:	00007517          	auipc	a0,0x7
    800018e2:	74a53503          	ld	a0,1866(a0) # 80009028 <unusedList>
          panic("wrong call in get_first");
  return p;
}
    800018e6:	8082                	ret
  number == 1 ? p = cpus[cpu_id].first :
    800018e8:	00459793          	slli	a5,a1,0x4
    800018ec:	95be                	add	a1,a1,a5
    800018ee:	058e                	slli	a1,a1,0x3
    800018f0:	00010797          	auipc	a5,0x10
    800018f4:	9c078793          	addi	a5,a5,-1600 # 800112b0 <readyLock>
    800018f8:	95be                	add	a1,a1,a5
    800018fa:	1885b503          	ld	a0,392(a1) # 4000188 <_entry-0x7bfffe78>
    800018fe:	8082                	ret
    number == 2 ? p = zombieList  :
    80001900:	00007517          	auipc	a0,0x7
    80001904:	73853503          	ld	a0,1848(a0) # 80009038 <zombieList>
    80001908:	8082                	ret
      number == 3 ? p = sleepingList :
    8000190a:	00007517          	auipc	a0,0x7
    8000190e:	72653503          	ld	a0,1830(a0) # 80009030 <sleepingList>
    80001912:	8082                	ret
struct proc* get_first(int number, int cpu_id){
    80001914:	1141                	addi	sp,sp,-16
    80001916:	e406                	sd	ra,8(sp)
    80001918:	e022                	sd	s0,0(sp)
    8000191a:	0800                	addi	s0,sp,16
          panic("wrong call in get_first");
    8000191c:	00007517          	auipc	a0,0x7
    80001920:	8dc50513          	addi	a0,a0,-1828 # 800081f8 <digits+0x1b8>
    80001924:	fffff097          	auipc	ra,0xfffff
    80001928:	c1a080e7          	jalr	-998(ra) # 8000053e <panic>

000000008000192c <set_head>:

void
set_head(struct proc* p, int number, int cpu_id)//TODO: change name of function
{
  number == 1 ?  cpus[cpu_id].first = p: 
    8000192c:	4785                	li	a5,1
    8000192e:	00f58c63          	beq	a1,a5,80001946 <set_head+0x1a>
    number == 2 ? zombieList = p: 
    80001932:	4789                	li	a5,2
    80001934:	02f58563          	beq	a1,a5,8000195e <set_head+0x32>
      number == 3 ? sleepingList = p: 
    80001938:	478d                	li	a5,3
    8000193a:	02f58763          	beq	a1,a5,80001968 <set_head+0x3c>
        number == 4 ? unusedList:  
    8000193e:	4791                	li	a5,4
    80001940:	02f59963          	bne	a1,a5,80001972 <set_head+0x46>
    80001944:	8082                	ret
  number == 1 ?  cpus[cpu_id].first = p: 
    80001946:	00461793          	slli	a5,a2,0x4
    8000194a:	963e                	add	a2,a2,a5
    8000194c:	060e                	slli	a2,a2,0x3
    8000194e:	00010797          	auipc	a5,0x10
    80001952:	96278793          	addi	a5,a5,-1694 # 800112b0 <readyLock>
    80001956:	963e                	add	a2,a2,a5
    80001958:	18a63423          	sd	a0,392(a2) # 1188 <_entry-0x7fffee78>
    8000195c:	8082                	ret
    number == 2 ? zombieList = p: 
    8000195e:	00007797          	auipc	a5,0x7
    80001962:	6ca7bd23          	sd	a0,1754(a5) # 80009038 <zombieList>
    80001966:	8082                	ret
      number == 3 ? sleepingList = p: 
    80001968:	00007797          	auipc	a5,0x7
    8000196c:	6ca7b423          	sd	a0,1736(a5) # 80009030 <sleepingList>
    80001970:	8082                	ret
{
    80001972:	1141                	addi	sp,sp,-16
    80001974:	e406                	sd	ra,8(sp)
    80001976:	e022                	sd	s0,0(sp)
    80001978:	0800                	addi	s0,sp,16
          panic("wrong call in acquire_list");
    8000197a:	00007517          	auipc	a0,0x7
    8000197e:	85e50513          	addi	a0,a0,-1954 # 800081d8 <digits+0x198>
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	bbc080e7          	jalr	-1092(ra) # 8000053e <panic>

000000008000198a <release_list>:
}

void
release_list(int number, int cpu_id){
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e406                	sd	ra,8(sp)
    8000198e:	e022                	sd	s0,0(sp)
    80001990:	0800                	addi	s0,sp,16
    number == 1 ?  release(&readyLock[cpu_id]): 
    80001992:	4785                	li	a5,1
    80001994:	02f50763          	beq	a0,a5,800019c2 <release_list+0x38>
      number == 2 ? release(&zombieLock): 
    80001998:	4789                	li	a5,2
    8000199a:	04f50263          	beq	a0,a5,800019de <release_list+0x54>
        number == 3 ? release(&sleepLock): 
    8000199e:	478d                	li	a5,3
    800019a0:	04f50863          	beq	a0,a5,800019f0 <release_list+0x66>
          number == 4 ? release(&unusedLock):  
    800019a4:	4791                	li	a5,4
    800019a6:	04f51e63          	bne	a0,a5,80001a02 <release_list+0x78>
    800019aa:	00010517          	auipc	a0,0x10
    800019ae:	9f650513          	addi	a0,a0,-1546 # 800113a0 <unusedLock>
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	2e6080e7          	jalr	742(ra) # 80000c98 <release>
            panic("wrong call in acquire_list");
}
    800019ba:	60a2                	ld	ra,8(sp)
    800019bc:	6402                	ld	s0,0(sp)
    800019be:	0141                	addi	sp,sp,16
    800019c0:	8082                	ret
    number == 1 ?  release(&readyLock[cpu_id]): 
    800019c2:	00159513          	slli	a0,a1,0x1
    800019c6:	95aa                	add	a1,a1,a0
    800019c8:	058e                	slli	a1,a1,0x3
    800019ca:	00010517          	auipc	a0,0x10
    800019ce:	8e650513          	addi	a0,a0,-1818 # 800112b0 <readyLock>
    800019d2:	952e                	add	a0,a0,a1
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	2c4080e7          	jalr	708(ra) # 80000c98 <release>
    800019dc:	bff9                	j	800019ba <release_list+0x30>
      number == 2 ? release(&zombieLock): 
    800019de:	00010517          	auipc	a0,0x10
    800019e2:	99250513          	addi	a0,a0,-1646 # 80011370 <zombieLock>
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
    800019ee:	b7f1                	j	800019ba <release_list+0x30>
        number == 3 ? release(&sleepLock): 
    800019f0:	00010517          	auipc	a0,0x10
    800019f4:	99850513          	addi	a0,a0,-1640 # 80011388 <sleepLock>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>
    80001a00:	bf6d                	j	800019ba <release_list+0x30>
            panic("wrong call in acquire_list");
    80001a02:	00006517          	auipc	a0,0x6
    80001a06:	7d650513          	addi	a0,a0,2006 # 800081d8 <digits+0x198>
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	b34080e7          	jalr	-1228(ra) # 8000053e <panic>

0000000080001a12 <add_to_list>:


void
add_to_list(struct proc* p, struct proc* head, int type, int cpu_id)//TODO: change name of function
{
    80001a12:	7139                	addi	sp,sp,-64
    80001a14:	fc06                	sd	ra,56(sp)
    80001a16:	f822                	sd	s0,48(sp)
    80001a18:	f426                	sd	s1,40(sp)
    80001a1a:	f04a                	sd	s2,32(sp)
    80001a1c:	ec4e                	sd	s3,24(sp)
    80001a1e:	e852                	sd	s4,16(sp)
    80001a20:	e456                	sd	s5,8(sp)
    80001a22:	e05a                	sd	s6,0(sp)
    80001a24:	0080                	addi	s0,sp,64
  if(!p){
    80001a26:	c505                	beqz	a0,80001a4e <add_to_list+0x3c>
    80001a28:	8b2a                	mv	s6,a0
    80001a2a:	84ae                	mv	s1,a1
    80001a2c:	8a32                	mv	s4,a2
    80001a2e:	8ab6                	mv	s5,a3
  if(!head){
      set_head(p, type, cpu_id);
      release_list(type, cpu_id);
  }
  else{
    struct proc* prev = 0;
    80001a30:	4901                	li	s2,0
  if(!head){
    80001a32:	e1a1                	bnez	a1,80001a72 <add_to_list+0x60>
      set_head(p, type, cpu_id);
    80001a34:	8636                	mv	a2,a3
    80001a36:	85d2                	mv	a1,s4
    80001a38:	00000097          	auipc	ra,0x0
    80001a3c:	ef4080e7          	jalr	-268(ra) # 8000192c <set_head>
      release_list(type, cpu_id);
    80001a40:	85d6                	mv	a1,s5
    80001a42:	8552                	mv	a0,s4
    80001a44:	00000097          	auipc	ra,0x0
    80001a48:	f46080e7          	jalr	-186(ra) # 8000198a <release_list>
    80001a4c:	a891                	j	80001aa0 <add_to_list+0x8e>
    panic("can't add null to list");
    80001a4e:	00006517          	auipc	a0,0x6
    80001a52:	7c250513          	addi	a0,a0,1986 # 80008210 <digits+0x1d0>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	ae8080e7          	jalr	-1304(ra) # 8000053e <panic>

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list(type, cpu_id);
    80001a5e:	85d6                	mv	a1,s5
    80001a60:	8552                	mv	a0,s4
    80001a62:	00000097          	auipc	ra,0x0
    80001a66:	f28080e7          	jalr	-216(ra) # 8000198a <release_list>
      }
      prev = head;
      head = head->next;
    80001a6a:	68bc                	ld	a5,80(s1)
    while(head){
    80001a6c:	8926                	mv	s2,s1
    80001a6e:	c395                	beqz	a5,80001a92 <add_to_list+0x80>
      head = head->next;
    80001a70:	84be                	mv	s1,a5
      acquire(&head->list_lock);
    80001a72:	01848993          	addi	s3,s1,24
    80001a76:	854e                	mv	a0,s3
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	16c080e7          	jalr	364(ra) # 80000be4 <acquire>
      if(prev){
    80001a80:	fc090fe3          	beqz	s2,80001a5e <add_to_list+0x4c>
        release(&prev->list_lock);
    80001a84:	01890513          	addi	a0,s2,24 # 1018 <_entry-0x7fffefe8>
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	210080e7          	jalr	528(ra) # 80000c98 <release>
    80001a90:	bfe9                	j	80001a6a <add_to_list+0x58>
    }
    prev->next = p;
    80001a92:	0564b823          	sd	s6,80(s1)
    release(&prev->list_lock);
    80001a96:	854e                	mv	a0,s3
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	200080e7          	jalr	512(ra) # 80000c98 <release>
  }
}
    80001aa0:	70e2                	ld	ra,56(sp)
    80001aa2:	7442                	ld	s0,48(sp)
    80001aa4:	74a2                	ld	s1,40(sp)
    80001aa6:	7902                	ld	s2,32(sp)
    80001aa8:	69e2                	ld	s3,24(sp)
    80001aaa:	6a42                	ld	s4,16(sp)
    80001aac:	6aa2                	ld	s5,8(sp)
    80001aae:	6b02                	ld	s6,0(sp)
    80001ab0:	6121                	addi	sp,sp,64
    80001ab2:	8082                	ret

0000000080001ab4 <add_proc>:

void //TODO: cahnge 
add_proc(struct proc* p, int number, int cpu_id)
{
    80001ab4:	7179                	addi	sp,sp,-48
    80001ab6:	f406                	sd	ra,40(sp)
    80001ab8:	f022                	sd	s0,32(sp)
    80001aba:	ec26                	sd	s1,24(sp)
    80001abc:	e84a                	sd	s2,16(sp)
    80001abe:	e44e                	sd	s3,8(sp)
    80001ac0:	1800                	addi	s0,sp,48
    80001ac2:	89aa                	mv	s3,a0
    80001ac4:	84ae                	mv	s1,a1
    80001ac6:	8932                	mv	s2,a2
  struct proc* first;
  acquire_list(number, cpu_id);
    80001ac8:	85b2                	mv	a1,a2
    80001aca:	8526                	mv	a0,s1
    80001acc:	00000097          	auipc	ra,0x0
    80001ad0:	d72080e7          	jalr	-654(ra) # 8000183e <acquire_list>
  first = get_first(number, cpu_id);
    80001ad4:	85ca                	mv	a1,s2
    80001ad6:	8526                	mv	a0,s1
    80001ad8:	00000097          	auipc	ra,0x0
    80001adc:	dee080e7          	jalr	-530(ra) # 800018c6 <get_first>
    80001ae0:	85aa                	mv	a1,a0
  add_to_list(p, first, number, cpu_id);//TODO change name
    80001ae2:	86ca                	mv	a3,s2
    80001ae4:	8626                	mv	a2,s1
    80001ae6:	854e                	mv	a0,s3
    80001ae8:	00000097          	auipc	ra,0x0
    80001aec:	f2a080e7          	jalr	-214(ra) # 80001a12 <add_to_list>
}
    80001af0:	70a2                	ld	ra,40(sp)
    80001af2:	7402                	ld	s0,32(sp)
    80001af4:	64e2                	ld	s1,24(sp)
    80001af6:	6942                	ld	s2,16(sp)
    80001af8:	69a2                	ld	s3,8(sp)
    80001afa:	6145                	addi	sp,sp,48
    80001afc:	8082                	ret

0000000080001afe <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001afe:	7139                	addi	sp,sp,-64
    80001b00:	fc06                	sd	ra,56(sp)
    80001b02:	f822                	sd	s0,48(sp)
    80001b04:	f426                	sd	s1,40(sp)
    80001b06:	f04a                	sd	s2,32(sp)
    80001b08:	ec4e                	sd	s3,24(sp)
    80001b0a:	e852                	sd	s4,16(sp)
    80001b0c:	e456                	sd	s5,8(sp)
    80001b0e:	e05a                	sd	s6,0(sp)
    80001b10:	0080                	addi	s0,sp,64
    80001b12:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b14:	00010497          	auipc	s1,0x10
    80001b18:	d1448493          	addi	s1,s1,-748 # 80011828 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001b1c:	8b26                	mv	s6,s1
    80001b1e:	00006a97          	auipc	s5,0x6
    80001b22:	4e2a8a93          	addi	s5,s5,1250 # 80008000 <etext>
    80001b26:	04000937          	lui	s2,0x4000
    80001b2a:	197d                	addi	s2,s2,-1
    80001b2c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b2e:	00016a17          	auipc	s4,0x16
    80001b32:	0faa0a13          	addi	s4,s4,250 # 80017c28 <tickslock>
    char *pa = kalloc();
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	fbe080e7          	jalr	-66(ra) # 80000af4 <kalloc>
    80001b3e:	862a                	mv	a2,a0
    if(pa == 0)
    80001b40:	c131                	beqz	a0,80001b84 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001b42:	416485b3          	sub	a1,s1,s6
    80001b46:	8591                	srai	a1,a1,0x4
    80001b48:	000ab783          	ld	a5,0(s5)
    80001b4c:	02f585b3          	mul	a1,a1,a5
    80001b50:	2585                	addiw	a1,a1,1
    80001b52:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b56:	4719                	li	a4,6
    80001b58:	6685                	lui	a3,0x1
    80001b5a:	40b905b3          	sub	a1,s2,a1
    80001b5e:	854e                	mv	a0,s3
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	5f0080e7          	jalr	1520(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b68:	19048493          	addi	s1,s1,400
    80001b6c:	fd4495e3          	bne	s1,s4,80001b36 <proc_mapstacks+0x38>
  }
}
    80001b70:	70e2                	ld	ra,56(sp)
    80001b72:	7442                	ld	s0,48(sp)
    80001b74:	74a2                	ld	s1,40(sp)
    80001b76:	7902                	ld	s2,32(sp)
    80001b78:	69e2                	ld	s3,24(sp)
    80001b7a:	6a42                	ld	s4,16(sp)
    80001b7c:	6aa2                	ld	s5,8(sp)
    80001b7e:	6b02                	ld	s6,0(sp)
    80001b80:	6121                	addi	sp,sp,64
    80001b82:	8082                	ret
      panic("kalloc");
    80001b84:	00006517          	auipc	a0,0x6
    80001b88:	6a450513          	addi	a0,a0,1700 # 80008228 <digits+0x1e8>
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	9b2080e7          	jalr	-1614(ra) # 8000053e <panic>

0000000080001b94 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b94:	7139                	addi	sp,sp,-64
    80001b96:	fc06                	sd	ra,56(sp)
    80001b98:	f822                	sd	s0,48(sp)
    80001b9a:	f426                	sd	s1,40(sp)
    80001b9c:	f04a                	sd	s2,32(sp)
    80001b9e:	ec4e                	sd	s3,24(sp)
    80001ba0:	e852                	sd	s4,16(sp)
    80001ba2:	e456                	sd	s5,8(sp)
    80001ba4:	e05a                	sd	s6,0(sp)
    80001ba6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001ba8:	00006597          	auipc	a1,0x6
    80001bac:	68858593          	addi	a1,a1,1672 # 80008230 <digits+0x1f0>
    80001bb0:	00010517          	auipc	a0,0x10
    80001bb4:	c4850513          	addi	a0,a0,-952 # 800117f8 <pid_lock>
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	f9c080e7          	jalr	-100(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001bc0:	00006597          	auipc	a1,0x6
    80001bc4:	67858593          	addi	a1,a1,1656 # 80008238 <digits+0x1f8>
    80001bc8:	00010517          	auipc	a0,0x10
    80001bcc:	c4850513          	addi	a0,a0,-952 # 80011810 <wait_lock>
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	f84080e7          	jalr	-124(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd8:	00010497          	auipc	s1,0x10
    80001bdc:	c5048493          	addi	s1,s1,-944 # 80011828 <proc>
      initlock(&p->lock, "proc");
    80001be0:	00006b17          	auipc	s6,0x6
    80001be4:	668b0b13          	addi	s6,s6,1640 # 80008248 <digits+0x208>
      p->kstack = KSTACK((int) (p - proc));
    80001be8:	8aa6                	mv	s5,s1
    80001bea:	00006a17          	auipc	s4,0x6
    80001bee:	416a0a13          	addi	s4,s4,1046 # 80008000 <etext>
    80001bf2:	04000937          	lui	s2,0x4000
    80001bf6:	197d                	addi	s2,s2,-1
    80001bf8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfa:	00016997          	auipc	s3,0x16
    80001bfe:	02e98993          	addi	s3,s3,46 # 80017c28 <tickslock>
      initlock(&p->lock, "proc");
    80001c02:	85da                	mv	a1,s6
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	f4e080e7          	jalr	-178(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c0e:	415487b3          	sub	a5,s1,s5
    80001c12:	8791                	srai	a5,a5,0x4
    80001c14:	000a3703          	ld	a4,0(s4)
    80001c18:	02e787b3          	mul	a5,a5,a4
    80001c1c:	2785                	addiw	a5,a5,1
    80001c1e:	00d7979b          	slliw	a5,a5,0xd
    80001c22:	40f907b3          	sub	a5,s2,a5
    80001c26:	f4bc                	sd	a5,104(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c28:	19048493          	addi	s1,s1,400
    80001c2c:	fd349be3          	bne	s1,s3,80001c02 <procinit+0x6e>
  }
}
    80001c30:	70e2                	ld	ra,56(sp)
    80001c32:	7442                	ld	s0,48(sp)
    80001c34:	74a2                	ld	s1,40(sp)
    80001c36:	7902                	ld	s2,32(sp)
    80001c38:	69e2                	ld	s3,24(sp)
    80001c3a:	6a42                	ld	s4,16(sp)
    80001c3c:	6aa2                	ld	s5,8(sp)
    80001c3e:	6b02                	ld	s6,0(sp)
    80001c40:	6121                	addi	sp,sp,64
    80001c42:	8082                	ret

0000000080001c44 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001c44:	1141                	addi	sp,sp,-16
    80001c46:	e422                	sd	s0,8(sp)
    80001c48:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c4a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001c4c:	2501                	sext.w	a0,a0
    80001c4e:	6422                	ld	s0,8(sp)
    80001c50:	0141                	addi	sp,sp,16
    80001c52:	8082                	ret

0000000080001c54 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001c54:	1141                	addi	sp,sp,-16
    80001c56:	e422                	sd	s0,8(sp)
    80001c58:	0800                	addi	s0,sp,16
    80001c5a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c5c:	0007851b          	sext.w	a0,a5
    80001c60:	00451793          	slli	a5,a0,0x4
    80001c64:	97aa                	add	a5,a5,a0
    80001c66:	078e                	slli	a5,a5,0x3
  return c;
}
    80001c68:	0000f517          	auipc	a0,0xf
    80001c6c:	75050513          	addi	a0,a0,1872 # 800113b8 <cpus>
    80001c70:	953e                	add	a0,a0,a5
    80001c72:	6422                	ld	s0,8(sp)
    80001c74:	0141                	addi	sp,sp,16
    80001c76:	8082                	ret

0000000080001c78 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c78:	1101                	addi	sp,sp,-32
    80001c7a:	ec06                	sd	ra,24(sp)
    80001c7c:	e822                	sd	s0,16(sp)
    80001c7e:	e426                	sd	s1,8(sp)
    80001c80:	1000                	addi	s0,sp,32
  push_off();
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	f16080e7          	jalr	-234(ra) # 80000b98 <push_off>
    80001c8a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c8c:	0007871b          	sext.w	a4,a5
    80001c90:	00471793          	slli	a5,a4,0x4
    80001c94:	97ba                	add	a5,a5,a4
    80001c96:	078e                	slli	a5,a5,0x3
    80001c98:	0000f717          	auipc	a4,0xf
    80001c9c:	61870713          	addi	a4,a4,1560 # 800112b0 <readyLock>
    80001ca0:	97ba                	add	a5,a5,a4
    80001ca2:	1087b483          	ld	s1,264(a5)
  pop_off();
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	f92080e7          	jalr	-110(ra) # 80000c38 <pop_off>
  return p;
}
    80001cae:	8526                	mv	a0,s1
    80001cb0:	60e2                	ld	ra,24(sp)
    80001cb2:	6442                	ld	s0,16(sp)
    80001cb4:	64a2                	ld	s1,8(sp)
    80001cb6:	6105                	addi	sp,sp,32
    80001cb8:	8082                	ret

0000000080001cba <get_cpu>:
{
    80001cba:	1141                	addi	sp,sp,-16
    80001cbc:	e406                	sd	ra,8(sp)
    80001cbe:	e022                	sd	s0,0(sp)
    80001cc0:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    80001cc2:	00000097          	auipc	ra,0x0
    80001cc6:	fb6080e7          	jalr	-74(ra) # 80001c78 <myproc>
}
    80001cca:	4d28                	lw	a0,88(a0)
    80001ccc:	60a2                	ld	ra,8(sp)
    80001cce:	6402                	ld	s0,0(sp)
    80001cd0:	0141                	addi	sp,sp,16
    80001cd2:	8082                	ret

0000000080001cd4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001cd4:	1141                	addi	sp,sp,-16
    80001cd6:	e406                	sd	ra,8(sp)
    80001cd8:	e022                	sd	s0,0(sp)
    80001cda:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	f9c080e7          	jalr	-100(ra) # 80001c78 <myproc>
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	fb4080e7          	jalr	-76(ra) # 80000c98 <release>

  if (first) {
    80001cec:	00007797          	auipc	a5,0x7
    80001cf0:	b947a783          	lw	a5,-1132(a5) # 80008880 <first.1740>
    80001cf4:	eb89                	bnez	a5,80001d06 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001cf6:	00001097          	auipc	ra,0x1
    80001cfa:	c70080e7          	jalr	-912(ra) # 80002966 <usertrapret>
}
    80001cfe:	60a2                	ld	ra,8(sp)
    80001d00:	6402                	ld	s0,0(sp)
    80001d02:	0141                	addi	sp,sp,16
    80001d04:	8082                	ret
    first = 0;
    80001d06:	00007797          	auipc	a5,0x7
    80001d0a:	b607ad23          	sw	zero,-1158(a5) # 80008880 <first.1740>
    fsinit(ROOTDEV);
    80001d0e:	4505                	li	a0,1
    80001d10:	00002097          	auipc	ra,0x2
    80001d14:	9e2080e7          	jalr	-1566(ra) # 800036f2 <fsinit>
    80001d18:	bff9                	j	80001cf6 <forkret+0x22>

0000000080001d1a <allocpid>:
allocpid() {
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001d26:	00007917          	auipc	s2,0x7
    80001d2a:	b5e90913          	addi	s2,s2,-1186 # 80008884 <nextpid>
    80001d2e:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid, pid, pid + 1));
    80001d32:	0014861b          	addiw	a2,s1,1
    80001d36:	85a6                	mv	a1,s1
    80001d38:	854a                	mv	a0,s2
    80001d3a:	00004097          	auipc	ra,0x4
    80001d3e:	7bc080e7          	jalr	1980(ra) # 800064f6 <cas>
    80001d42:	f575                	bnez	a0,80001d2e <allocpid+0x14>
}
    80001d44:	8526                	mv	a0,s1
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6902                	ld	s2,0(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret

0000000080001d52 <proc_pagetable>:
{
    80001d52:	1101                	addi	sp,sp,-32
    80001d54:	ec06                	sd	ra,24(sp)
    80001d56:	e822                	sd	s0,16(sp)
    80001d58:	e426                	sd	s1,8(sp)
    80001d5a:	e04a                	sd	s2,0(sp)
    80001d5c:	1000                	addi	s0,sp,32
    80001d5e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	5da080e7          	jalr	1498(ra) # 8000133a <uvmcreate>
    80001d68:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d6a:	c121                	beqz	a0,80001daa <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d6c:	4729                	li	a4,10
    80001d6e:	00005697          	auipc	a3,0x5
    80001d72:	29268693          	addi	a3,a3,658 # 80007000 <_trampoline>
    80001d76:	6605                	lui	a2,0x1
    80001d78:	040005b7          	lui	a1,0x4000
    80001d7c:	15fd                	addi	a1,a1,-1
    80001d7e:	05b2                	slli	a1,a1,0xc
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	330080e7          	jalr	816(ra) # 800010b0 <mappages>
    80001d88:	02054863          	bltz	a0,80001db8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d8c:	4719                	li	a4,6
    80001d8e:	08093683          	ld	a3,128(s2)
    80001d92:	6605                	lui	a2,0x1
    80001d94:	020005b7          	lui	a1,0x2000
    80001d98:	15fd                	addi	a1,a1,-1
    80001d9a:	05b6                	slli	a1,a1,0xd
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	312080e7          	jalr	786(ra) # 800010b0 <mappages>
    80001da6:	02054163          	bltz	a0,80001dc8 <proc_pagetable+0x76>
}
    80001daa:	8526                	mv	a0,s1
    80001dac:	60e2                	ld	ra,24(sp)
    80001dae:	6442                	ld	s0,16(sp)
    80001db0:	64a2                	ld	s1,8(sp)
    80001db2:	6902                	ld	s2,0(sp)
    80001db4:	6105                	addi	sp,sp,32
    80001db6:	8082                	ret
    uvmfree(pagetable, 0);
    80001db8:	4581                	li	a1,0
    80001dba:	8526                	mv	a0,s1
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	77a080e7          	jalr	1914(ra) # 80001536 <uvmfree>
    return 0;
    80001dc4:	4481                	li	s1,0
    80001dc6:	b7d5                	j	80001daa <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dc8:	4681                	li	a3,0
    80001dca:	4605                	li	a2,1
    80001dcc:	040005b7          	lui	a1,0x4000
    80001dd0:	15fd                	addi	a1,a1,-1
    80001dd2:	05b2                	slli	a1,a1,0xc
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	4a0080e7          	jalr	1184(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001dde:	4581                	li	a1,0
    80001de0:	8526                	mv	a0,s1
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	754080e7          	jalr	1876(ra) # 80001536 <uvmfree>
    return 0;
    80001dea:	4481                	li	s1,0
    80001dec:	bf7d                	j	80001daa <proc_pagetable+0x58>

0000000080001dee <proc_freepagetable>:
{
    80001dee:	1101                	addi	sp,sp,-32
    80001df0:	ec06                	sd	ra,24(sp)
    80001df2:	e822                	sd	s0,16(sp)
    80001df4:	e426                	sd	s1,8(sp)
    80001df6:	e04a                	sd	s2,0(sp)
    80001df8:	1000                	addi	s0,sp,32
    80001dfa:	84aa                	mv	s1,a0
    80001dfc:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dfe:	4681                	li	a3,0
    80001e00:	4605                	li	a2,1
    80001e02:	040005b7          	lui	a1,0x4000
    80001e06:	15fd                	addi	a1,a1,-1
    80001e08:	05b2                	slli	a1,a1,0xc
    80001e0a:	fffff097          	auipc	ra,0xfffff
    80001e0e:	46c080e7          	jalr	1132(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e12:	4681                	li	a3,0
    80001e14:	4605                	li	a2,1
    80001e16:	020005b7          	lui	a1,0x2000
    80001e1a:	15fd                	addi	a1,a1,-1
    80001e1c:	05b6                	slli	a1,a1,0xd
    80001e1e:	8526                	mv	a0,s1
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	456080e7          	jalr	1110(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e28:	85ca                	mv	a1,s2
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	70a080e7          	jalr	1802(ra) # 80001536 <uvmfree>
}
    80001e34:	60e2                	ld	ra,24(sp)
    80001e36:	6442                	ld	s0,16(sp)
    80001e38:	64a2                	ld	s1,8(sp)
    80001e3a:	6902                	ld	s2,0(sp)
    80001e3c:	6105                	addi	sp,sp,32
    80001e3e:	8082                	ret

0000000080001e40 <freeproc>:
{
    80001e40:	1101                	addi	sp,sp,-32
    80001e42:	ec06                	sd	ra,24(sp)
    80001e44:	e822                	sd	s0,16(sp)
    80001e46:	e426                	sd	s1,8(sp)
    80001e48:	1000                	addi	s0,sp,32
    80001e4a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e4c:	6148                	ld	a0,128(a0)
    80001e4e:	c509                	beqz	a0,80001e58 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	ba8080e7          	jalr	-1112(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001e58:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    80001e5c:	7ca8                	ld	a0,120(s1)
    80001e5e:	c511                	beqz	a0,80001e6a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e60:	78ac                	ld	a1,112(s1)
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	f8c080e7          	jalr	-116(ra) # 80001dee <proc_freepagetable>
  p->pagetable = 0;
    80001e6a:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    80001e6e:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    80001e72:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    80001e76:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    80001e7a:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    80001e7e:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    80001e82:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80001e86:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    80001e8a:	0204a823          	sw	zero,48(s1)
}
    80001e8e:	60e2                	ld	ra,24(sp)
    80001e90:	6442                	ld	s0,16(sp)
    80001e92:	64a2                	ld	s1,8(sp)
    80001e94:	6105                	addi	sp,sp,32
    80001e96:	8082                	ret

0000000080001e98 <allocproc>:
{
    80001e98:	1101                	addi	sp,sp,-32
    80001e9a:	ec06                	sd	ra,24(sp)
    80001e9c:	e822                	sd	s0,16(sp)
    80001e9e:	e426                	sd	s1,8(sp)
    80001ea0:	e04a                	sd	s2,0(sp)
    80001ea2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ea4:	00010497          	auipc	s1,0x10
    80001ea8:	98448493          	addi	s1,s1,-1660 # 80011828 <proc>
    80001eac:	00016917          	auipc	s2,0x16
    80001eb0:	d7c90913          	addi	s2,s2,-644 # 80017c28 <tickslock>
    acquire(&p->lock);
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	d2e080e7          	jalr	-722(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001ebe:	589c                	lw	a5,48(s1)
    80001ec0:	cf81                	beqz	a5,80001ed8 <allocproc+0x40>
      release(&p->lock);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	dd4080e7          	jalr	-556(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ecc:	19048493          	addi	s1,s1,400
    80001ed0:	ff2492e3          	bne	s1,s2,80001eb4 <allocproc+0x1c>
  return 0;
    80001ed4:	4481                	li	s1,0
    80001ed6:	a889                	j	80001f28 <allocproc+0x90>
  p->pid = allocpid();
    80001ed8:	00000097          	auipc	ra,0x0
    80001edc:	e42080e7          	jalr	-446(ra) # 80001d1a <allocpid>
    80001ee0:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80001ee2:	4785                	li	a5,1
    80001ee4:	d89c                	sw	a5,48(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	c0e080e7          	jalr	-1010(ra) # 80000af4 <kalloc>
    80001eee:	892a                	mv	s2,a0
    80001ef0:	e0c8                	sd	a0,128(s1)
    80001ef2:	c131                	beqz	a0,80001f36 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	00000097          	auipc	ra,0x0
    80001efa:	e5c080e7          	jalr	-420(ra) # 80001d52 <proc_pagetable>
    80001efe:	892a                	mv	s2,a0
    80001f00:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    80001f02:	c531                	beqz	a0,80001f4e <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001f04:	07000613          	li	a2,112
    80001f08:	4581                	li	a1,0
    80001f0a:	08848513          	addi	a0,s1,136
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	dd2080e7          	jalr	-558(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001f16:	00000797          	auipc	a5,0x0
    80001f1a:	dbe78793          	addi	a5,a5,-578 # 80001cd4 <forkret>
    80001f1e:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f20:	74bc                	ld	a5,104(s1)
    80001f22:	6705                	lui	a4,0x1
    80001f24:	97ba                	add	a5,a5,a4
    80001f26:	e8dc                	sd	a5,144(s1)
}
    80001f28:	8526                	mv	a0,s1
    80001f2a:	60e2                	ld	ra,24(sp)
    80001f2c:	6442                	ld	s0,16(sp)
    80001f2e:	64a2                	ld	s1,8(sp)
    80001f30:	6902                	ld	s2,0(sp)
    80001f32:	6105                	addi	sp,sp,32
    80001f34:	8082                	ret
    freeproc(p);
    80001f36:	8526                	mv	a0,s1
    80001f38:	00000097          	auipc	ra,0x0
    80001f3c:	f08080e7          	jalr	-248(ra) # 80001e40 <freeproc>
    release(&p->lock);
    80001f40:	8526                	mv	a0,s1
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d56080e7          	jalr	-682(ra) # 80000c98 <release>
    return 0;
    80001f4a:	84ca                	mv	s1,s2
    80001f4c:	bff1                	j	80001f28 <allocproc+0x90>
    freeproc(p);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	ef0080e7          	jalr	-272(ra) # 80001e40 <freeproc>
    release(&p->lock);
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	d3e080e7          	jalr	-706(ra) # 80000c98 <release>
    return 0;
    80001f62:	84ca                	mv	s1,s2
    80001f64:	b7d1                	j	80001f28 <allocproc+0x90>

0000000080001f66 <userinit>:
{
    80001f66:	1101                	addi	sp,sp,-32
    80001f68:	ec06                	sd	ra,24(sp)
    80001f6a:	e822                	sd	s0,16(sp)
    80001f6c:	e426                	sd	s1,8(sp)
    80001f6e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	f28080e7          	jalr	-216(ra) # 80001e98 <allocproc>
    80001f78:	84aa                	mv	s1,a0
  initproc = p;
    80001f7a:	00007797          	auipc	a5,0x7
    80001f7e:	0ca7b323          	sd	a0,198(a5) # 80009040 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f82:	03400613          	li	a2,52
    80001f86:	00007597          	auipc	a1,0x7
    80001f8a:	90a58593          	addi	a1,a1,-1782 # 80008890 <initcode>
    80001f8e:	7d28                	ld	a0,120(a0)
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	3d8080e7          	jalr	984(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001f98:	6785                	lui	a5,0x1
    80001f9a:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f9c:	60d8                	ld	a4,128(s1)
    80001f9e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001fa2:	60d8                	ld	a4,128(s1)
    80001fa4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fa6:	4641                	li	a2,16
    80001fa8:	00006597          	auipc	a1,0x6
    80001fac:	2a858593          	addi	a1,a1,680 # 80008250 <digits+0x210>
    80001fb0:	18048513          	addi	a0,s1,384
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	e7e080e7          	jalr	-386(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001fbc:	00006517          	auipc	a0,0x6
    80001fc0:	2a450513          	addi	a0,a0,676 # 80008260 <digits+0x220>
    80001fc4:	00002097          	auipc	ra,0x2
    80001fc8:	15c080e7          	jalr	348(ra) # 80004120 <namei>
    80001fcc:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    80001fd0:	478d                	li	a5,3
    80001fd2:	d89c                	sw	a5,48(s1)
  release(&p->lock);
    80001fd4:	8526                	mv	a0,s1
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	cc2080e7          	jalr	-830(ra) # 80000c98 <release>
}
    80001fde:	60e2                	ld	ra,24(sp)
    80001fe0:	6442                	ld	s0,16(sp)
    80001fe2:	64a2                	ld	s1,8(sp)
    80001fe4:	6105                	addi	sp,sp,32
    80001fe6:	8082                	ret

0000000080001fe8 <growproc>:
{
    80001fe8:	1101                	addi	sp,sp,-32
    80001fea:	ec06                	sd	ra,24(sp)
    80001fec:	e822                	sd	s0,16(sp)
    80001fee:	e426                	sd	s1,8(sp)
    80001ff0:	e04a                	sd	s2,0(sp)
    80001ff2:	1000                	addi	s0,sp,32
    80001ff4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	c82080e7          	jalr	-894(ra) # 80001c78 <myproc>
    80001ffe:	892a                	mv	s2,a0
  sz = p->sz;
    80002000:	792c                	ld	a1,112(a0)
    80002002:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002006:	00904f63          	bgtz	s1,80002024 <growproc+0x3c>
  } else if(n < 0){
    8000200a:	0204cc63          	bltz	s1,80002042 <growproc+0x5a>
  p->sz = sz;
    8000200e:	1602                	slli	a2,a2,0x20
    80002010:	9201                	srli	a2,a2,0x20
    80002012:	06c93823          	sd	a2,112(s2)
  return 0;
    80002016:	4501                	li	a0,0
}
    80002018:	60e2                	ld	ra,24(sp)
    8000201a:	6442                	ld	s0,16(sp)
    8000201c:	64a2                	ld	s1,8(sp)
    8000201e:	6902                	ld	s2,0(sp)
    80002020:	6105                	addi	sp,sp,32
    80002022:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002024:	9e25                	addw	a2,a2,s1
    80002026:	1602                	slli	a2,a2,0x20
    80002028:	9201                	srli	a2,a2,0x20
    8000202a:	1582                	slli	a1,a1,0x20
    8000202c:	9181                	srli	a1,a1,0x20
    8000202e:	7d28                	ld	a0,120(a0)
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	3f2080e7          	jalr	1010(ra) # 80001422 <uvmalloc>
    80002038:	0005061b          	sext.w	a2,a0
    8000203c:	fa69                	bnez	a2,8000200e <growproc+0x26>
      return -1;
    8000203e:	557d                	li	a0,-1
    80002040:	bfe1                	j	80002018 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002042:	9e25                	addw	a2,a2,s1
    80002044:	1602                	slli	a2,a2,0x20
    80002046:	9201                	srli	a2,a2,0x20
    80002048:	1582                	slli	a1,a1,0x20
    8000204a:	9181                	srli	a1,a1,0x20
    8000204c:	7d28                	ld	a0,120(a0)
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	38c080e7          	jalr	908(ra) # 800013da <uvmdealloc>
    80002056:	0005061b          	sext.w	a2,a0
    8000205a:	bf55                	j	8000200e <growproc+0x26>

000000008000205c <fork>:
{
    8000205c:	7179                	addi	sp,sp,-48
    8000205e:	f406                	sd	ra,40(sp)
    80002060:	f022                	sd	s0,32(sp)
    80002062:	ec26                	sd	s1,24(sp)
    80002064:	e84a                	sd	s2,16(sp)
    80002066:	e44e                	sd	s3,8(sp)
    80002068:	e052                	sd	s4,0(sp)
    8000206a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000206c:	00000097          	auipc	ra,0x0
    80002070:	c0c080e7          	jalr	-1012(ra) # 80001c78 <myproc>
    80002074:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002076:	00000097          	auipc	ra,0x0
    8000207a:	e22080e7          	jalr	-478(ra) # 80001e98 <allocproc>
    8000207e:	12050563          	beqz	a0,800021a8 <fork+0x14c>
    80002082:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002084:	07093603          	ld	a2,112(s2)
    80002088:	7d2c                	ld	a1,120(a0)
    8000208a:	07893503          	ld	a0,120(s2)
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	4e0080e7          	jalr	1248(ra) # 8000156e <uvmcopy>
    80002096:	04054663          	bltz	a0,800020e2 <fork+0x86>
  np->sz = p->sz;
    8000209a:	07093783          	ld	a5,112(s2)
    8000209e:	06f9b823          	sd	a5,112(s3)
  *(np->trapframe) = *(p->trapframe);
    800020a2:	08093683          	ld	a3,128(s2)
    800020a6:	87b6                	mv	a5,a3
    800020a8:	0809b703          	ld	a4,128(s3)
    800020ac:	12068693          	addi	a3,a3,288
    800020b0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800020b4:	6788                	ld	a0,8(a5)
    800020b6:	6b8c                	ld	a1,16(a5)
    800020b8:	6f90                	ld	a2,24(a5)
    800020ba:	01073023          	sd	a6,0(a4)
    800020be:	e708                	sd	a0,8(a4)
    800020c0:	eb0c                	sd	a1,16(a4)
    800020c2:	ef10                	sd	a2,24(a4)
    800020c4:	02078793          	addi	a5,a5,32
    800020c8:	02070713          	addi	a4,a4,32
    800020cc:	fed792e3          	bne	a5,a3,800020b0 <fork+0x54>
  np->trapframe->a0 = 0;
    800020d0:	0809b783          	ld	a5,128(s3)
    800020d4:	0607b823          	sd	zero,112(a5)
    800020d8:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    800020dc:	17800a13          	li	s4,376
    800020e0:	a03d                	j	8000210e <fork+0xb2>
    freeproc(np);
    800020e2:	854e                	mv	a0,s3
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	d5c080e7          	jalr	-676(ra) # 80001e40 <freeproc>
    release(&np->lock);
    800020ec:	854e                	mv	a0,s3
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	baa080e7          	jalr	-1110(ra) # 80000c98 <release>
    return -1;
    800020f6:	5a7d                	li	s4,-1
    800020f8:	a879                	j	80002196 <fork+0x13a>
      np->ofile[i] = filedup(p->ofile[i]);
    800020fa:	00002097          	auipc	ra,0x2
    800020fe:	6bc080e7          	jalr	1724(ra) # 800047b6 <filedup>
    80002102:	009987b3          	add	a5,s3,s1
    80002106:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002108:	04a1                	addi	s1,s1,8
    8000210a:	01448763          	beq	s1,s4,80002118 <fork+0xbc>
    if(p->ofile[i])
    8000210e:	009907b3          	add	a5,s2,s1
    80002112:	6388                	ld	a0,0(a5)
    80002114:	f17d                	bnez	a0,800020fa <fork+0x9e>
    80002116:	bfcd                	j	80002108 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002118:	17893503          	ld	a0,376(s2)
    8000211c:	00002097          	auipc	ra,0x2
    80002120:	810080e7          	jalr	-2032(ra) # 8000392c <idup>
    80002124:	16a9bc23          	sd	a0,376(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002128:	4641                	li	a2,16
    8000212a:	18090593          	addi	a1,s2,384
    8000212e:	18098513          	addi	a0,s3,384
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	d00080e7          	jalr	-768(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    8000213a:	0489aa03          	lw	s4,72(s3)
  release(&np->lock);
    8000213e:	854e                	mv	a0,s3
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b58080e7          	jalr	-1192(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002148:	0000f497          	auipc	s1,0xf
    8000214c:	6c848493          	addi	s1,s1,1736 # 80011810 <wait_lock>
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	a92080e7          	jalr	-1390(ra) # 80000be4 <acquire>
  np->parent = p;
    8000215a:	0729b023          	sd	s2,96(s3)
  release(&wait_lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b38080e7          	jalr	-1224(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002168:	854e                	mv	a0,s3
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	a7a080e7          	jalr	-1414(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002172:	478d                	li	a5,3
    80002174:	02f9a823          	sw	a5,48(s3)
  np->parent_cpu = p->parent_cpu; // give the proces cpu id of padrant  
    80002178:	05892603          	lw	a2,88(s2)
    8000217c:	04c9ac23          	sw	a2,88(s3)
  add_proc(np, 1, p->parent_cpu); // add new proces to the list of ready 
    80002180:	4585                	li	a1,1
    80002182:	854e                	mv	a0,s3
    80002184:	00000097          	auipc	ra,0x0
    80002188:	930080e7          	jalr	-1744(ra) # 80001ab4 <add_proc>
  release(&np->lock);
    8000218c:	854e                	mv	a0,s3
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	b0a080e7          	jalr	-1270(ra) # 80000c98 <release>
}
    80002196:	8552                	mv	a0,s4
    80002198:	70a2                	ld	ra,40(sp)
    8000219a:	7402                	ld	s0,32(sp)
    8000219c:	64e2                	ld	s1,24(sp)
    8000219e:	6942                	ld	s2,16(sp)
    800021a0:	69a2                	ld	s3,8(sp)
    800021a2:	6a02                	ld	s4,0(sp)
    800021a4:	6145                	addi	sp,sp,48
    800021a6:	8082                	ret
    return -1;
    800021a8:	5a7d                	li	s4,-1
    800021aa:	b7f5                	j	80002196 <fork+0x13a>

00000000800021ac <scheduler>:
{
    800021ac:	7139                	addi	sp,sp,-64
    800021ae:	fc06                	sd	ra,56(sp)
    800021b0:	f822                	sd	s0,48(sp)
    800021b2:	f426                	sd	s1,40(sp)
    800021b4:	f04a                	sd	s2,32(sp)
    800021b6:	ec4e                	sd	s3,24(sp)
    800021b8:	e852                	sd	s4,16(sp)
    800021ba:	e456                	sd	s5,8(sp)
    800021bc:	e05a                	sd	s6,0(sp)
    800021be:	0080                	addi	s0,sp,64
    800021c0:	8792                	mv	a5,tp
  int id = r_tp();
    800021c2:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021c4:	00479713          	slli	a4,a5,0x4
    800021c8:	00f706b3          	add	a3,a4,a5
    800021cc:	00369613          	slli	a2,a3,0x3
    800021d0:	0000f697          	auipc	a3,0xf
    800021d4:	0e068693          	addi	a3,a3,224 # 800112b0 <readyLock>
    800021d8:	96b2                	add	a3,a3,a2
    800021da:	1006b423          	sd	zero,264(a3)
        swtch(&c->context, &p->context);
    800021de:	0000f717          	auipc	a4,0xf
    800021e2:	1e270713          	addi	a4,a4,482 # 800113c0 <cpus+0x8>
    800021e6:	00e60b33          	add	s6,a2,a4
      if(p->state == RUNNABLE) {
    800021ea:	498d                	li	s3,3
        c->proc = p;
    800021ec:	8a36                	mv	s4,a3
    for(p = proc; p < &proc[NPROC]; p++) {
    800021ee:	00016917          	auipc	s2,0x16
    800021f2:	a3a90913          	addi	s2,s2,-1478 # 80017c28 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021f6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021fa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021fe:	10079073          	csrw	sstatus,a5
    80002202:	0000f497          	auipc	s1,0xf
    80002206:	62648493          	addi	s1,s1,1574 # 80011828 <proc>
        p->state = RUNNING;
    8000220a:	4a91                	li	s5,4
    8000220c:	a03d                	j	8000223a <scheduler+0x8e>
    8000220e:	0354a823          	sw	s5,48(s1)
        c->proc = p;
    80002212:	109a3423          	sd	s1,264(s4)
        swtch(&c->context, &p->context);
    80002216:	08848593          	addi	a1,s1,136
    8000221a:	855a                	mv	a0,s6
    8000221c:	00000097          	auipc	ra,0x0
    80002220:	6a0080e7          	jalr	1696(ra) # 800028bc <swtch>
        c->proc = 0;
    80002224:	100a3423          	sd	zero,264(s4)
      release(&p->lock);
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	a6e080e7          	jalr	-1426(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002232:	19048493          	addi	s1,s1,400
    80002236:	fd2480e3          	beq	s1,s2,800021f6 <scheduler+0x4a>
      acquire(&p->lock);
    8000223a:	8526                	mv	a0,s1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	9a8080e7          	jalr	-1624(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002244:	589c                	lw	a5,48(s1)
    80002246:	ff3791e3          	bne	a5,s3,80002228 <scheduler+0x7c>
    8000224a:	b7d1                	j	8000220e <scheduler+0x62>

000000008000224c <sched>:
{
    8000224c:	7179                	addi	sp,sp,-48
    8000224e:	f406                	sd	ra,40(sp)
    80002250:	f022                	sd	s0,32(sp)
    80002252:	ec26                	sd	s1,24(sp)
    80002254:	e84a                	sd	s2,16(sp)
    80002256:	e44e                	sd	s3,8(sp)
    80002258:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000225a:	00000097          	auipc	ra,0x0
    8000225e:	a1e080e7          	jalr	-1506(ra) # 80001c78 <myproc>
    80002262:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	906080e7          	jalr	-1786(ra) # 80000b6a <holding>
    8000226c:	c959                	beqz	a0,80002302 <sched+0xb6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000226e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002270:	0007871b          	sext.w	a4,a5
    80002274:	00471793          	slli	a5,a4,0x4
    80002278:	97ba                	add	a5,a5,a4
    8000227a:	078e                	slli	a5,a5,0x3
    8000227c:	0000f717          	auipc	a4,0xf
    80002280:	03470713          	addi	a4,a4,52 # 800112b0 <readyLock>
    80002284:	97ba                	add	a5,a5,a4
    80002286:	1807a703          	lw	a4,384(a5)
    8000228a:	4785                	li	a5,1
    8000228c:	08f71363          	bne	a4,a5,80002312 <sched+0xc6>
  if(p->state == RUNNING)
    80002290:	5898                	lw	a4,48(s1)
    80002292:	4791                	li	a5,4
    80002294:	08f70763          	beq	a4,a5,80002322 <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002298:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000229c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000229e:	ebd1                	bnez	a5,80002332 <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022a0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022a2:	0000f917          	auipc	s2,0xf
    800022a6:	00e90913          	addi	s2,s2,14 # 800112b0 <readyLock>
    800022aa:	0007871b          	sext.w	a4,a5
    800022ae:	00471793          	slli	a5,a4,0x4
    800022b2:	97ba                	add	a5,a5,a4
    800022b4:	078e                	slli	a5,a5,0x3
    800022b6:	97ca                	add	a5,a5,s2
    800022b8:	1847a983          	lw	s3,388(a5)
    800022bc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022be:	0007859b          	sext.w	a1,a5
    800022c2:	00459793          	slli	a5,a1,0x4
    800022c6:	97ae                	add	a5,a5,a1
    800022c8:	078e                	slli	a5,a5,0x3
    800022ca:	0000f597          	auipc	a1,0xf
    800022ce:	0f658593          	addi	a1,a1,246 # 800113c0 <cpus+0x8>
    800022d2:	95be                	add	a1,a1,a5
    800022d4:	08848513          	addi	a0,s1,136
    800022d8:	00000097          	auipc	ra,0x0
    800022dc:	5e4080e7          	jalr	1508(ra) # 800028bc <swtch>
    800022e0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022e2:	0007871b          	sext.w	a4,a5
    800022e6:	00471793          	slli	a5,a4,0x4
    800022ea:	97ba                	add	a5,a5,a4
    800022ec:	078e                	slli	a5,a5,0x3
    800022ee:	97ca                	add	a5,a5,s2
    800022f0:	1937a223          	sw	s3,388(a5)
}
    800022f4:	70a2                	ld	ra,40(sp)
    800022f6:	7402                	ld	s0,32(sp)
    800022f8:	64e2                	ld	s1,24(sp)
    800022fa:	6942                	ld	s2,16(sp)
    800022fc:	69a2                	ld	s3,8(sp)
    800022fe:	6145                	addi	sp,sp,48
    80002300:	8082                	ret
    panic("sched p->lock");
    80002302:	00006517          	auipc	a0,0x6
    80002306:	f6650513          	addi	a0,a0,-154 # 80008268 <digits+0x228>
    8000230a:	ffffe097          	auipc	ra,0xffffe
    8000230e:	234080e7          	jalr	564(ra) # 8000053e <panic>
    panic("sched locks");
    80002312:	00006517          	auipc	a0,0x6
    80002316:	f6650513          	addi	a0,a0,-154 # 80008278 <digits+0x238>
    8000231a:	ffffe097          	auipc	ra,0xffffe
    8000231e:	224080e7          	jalr	548(ra) # 8000053e <panic>
    panic("sched running");
    80002322:	00006517          	auipc	a0,0x6
    80002326:	f6650513          	addi	a0,a0,-154 # 80008288 <digits+0x248>
    8000232a:	ffffe097          	auipc	ra,0xffffe
    8000232e:	214080e7          	jalr	532(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002332:	00006517          	auipc	a0,0x6
    80002336:	f6650513          	addi	a0,a0,-154 # 80008298 <digits+0x258>
    8000233a:	ffffe097          	auipc	ra,0xffffe
    8000233e:	204080e7          	jalr	516(ra) # 8000053e <panic>

0000000080002342 <yield>:
{
    80002342:	1101                	addi	sp,sp,-32
    80002344:	ec06                	sd	ra,24(sp)
    80002346:	e822                	sd	s0,16(sp)
    80002348:	e426                	sd	s1,8(sp)
    8000234a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	92c080e7          	jalr	-1748(ra) # 80001c78 <myproc>
    80002354:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	88e080e7          	jalr	-1906(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000235e:	478d                	li	a5,3
    80002360:	d89c                	sw	a5,48(s1)
  sched();
    80002362:	00000097          	auipc	ra,0x0
    80002366:	eea080e7          	jalr	-278(ra) # 8000224c <sched>
  release(&p->lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	92c080e7          	jalr	-1748(ra) # 80000c98 <release>
}
    80002374:	60e2                	ld	ra,24(sp)
    80002376:	6442                	ld	s0,16(sp)
    80002378:	64a2                	ld	s1,8(sp)
    8000237a:	6105                	addi	sp,sp,32
    8000237c:	8082                	ret

000000008000237e <set_cpu>:
{
    8000237e:	1101                	addi	sp,sp,-32
    80002380:	ec06                	sd	ra,24(sp)
    80002382:	e822                	sd	s0,16(sp)
    80002384:	e426                	sd	s1,8(sp)
    80002386:	1000                	addi	s0,sp,32
  if(number_of_cpu<0 || number_of_cpu>NCPU){
    80002388:	47a1                	li	a5,8
    8000238a:	02a7e263          	bltu	a5,a0,800023ae <set_cpu+0x30>
    8000238e:	84aa                	mv	s1,a0
  struct proc* p = myproc();
    80002390:	00000097          	auipc	ra,0x0
    80002394:	8e8080e7          	jalr	-1816(ra) # 80001c78 <myproc>
  p->parent_cpu=number_of_cpu;
    80002398:	cd24                	sw	s1,88(a0)
  yield();
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	fa8080e7          	jalr	-88(ra) # 80002342 <yield>
}
    800023a2:	8526                	mv	a0,s1
    800023a4:	60e2                	ld	ra,24(sp)
    800023a6:	6442                	ld	s0,16(sp)
    800023a8:	64a2                	ld	s1,8(sp)
    800023aa:	6105                	addi	sp,sp,32
    800023ac:	8082                	ret
    panic("cpu number");
    800023ae:	00006517          	auipc	a0,0x6
    800023b2:	f0250513          	addi	a0,a0,-254 # 800082b0 <digits+0x270>
    800023b6:	ffffe097          	auipc	ra,0xffffe
    800023ba:	188080e7          	jalr	392(ra) # 8000053e <panic>

00000000800023be <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800023be:	7179                	addi	sp,sp,-48
    800023c0:	f406                	sd	ra,40(sp)
    800023c2:	f022                	sd	s0,32(sp)
    800023c4:	ec26                	sd	s1,24(sp)
    800023c6:	e84a                	sd	s2,16(sp)
    800023c8:	e44e                	sd	s3,8(sp)
    800023ca:	1800                	addi	s0,sp,48
    800023cc:	89aa                	mv	s3,a0
    800023ce:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023d0:	00000097          	auipc	ra,0x0
    800023d4:	8a8080e7          	jalr	-1880(ra) # 80001c78 <myproc>
    800023d8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	80a080e7          	jalr	-2038(ra) # 80000be4 <acquire>
  release(lk);
    800023e2:	854a                	mv	a0,s2
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8b4080e7          	jalr	-1868(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800023ec:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    800023f0:	4789                	li	a5,2
    800023f2:	d89c                	sw	a5,48(s1)

  sched();
    800023f4:	00000097          	auipc	ra,0x0
    800023f8:	e58080e7          	jalr	-424(ra) # 8000224c <sched>

  // Tidy up.
  p->chan = 0;
    800023fc:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	896080e7          	jalr	-1898(ra) # 80000c98 <release>
  acquire(lk);
    8000240a:	854a                	mv	a0,s2
    8000240c:	ffffe097          	auipc	ra,0xffffe
    80002410:	7d8080e7          	jalr	2008(ra) # 80000be4 <acquire>
}
    80002414:	70a2                	ld	ra,40(sp)
    80002416:	7402                	ld	s0,32(sp)
    80002418:	64e2                	ld	s1,24(sp)
    8000241a:	6942                	ld	s2,16(sp)
    8000241c:	69a2                	ld	s3,8(sp)
    8000241e:	6145                	addi	sp,sp,48
    80002420:	8082                	ret

0000000080002422 <wait>:
{
    80002422:	715d                	addi	sp,sp,-80
    80002424:	e486                	sd	ra,72(sp)
    80002426:	e0a2                	sd	s0,64(sp)
    80002428:	fc26                	sd	s1,56(sp)
    8000242a:	f84a                	sd	s2,48(sp)
    8000242c:	f44e                	sd	s3,40(sp)
    8000242e:	f052                	sd	s4,32(sp)
    80002430:	ec56                	sd	s5,24(sp)
    80002432:	e85a                	sd	s6,16(sp)
    80002434:	e45e                	sd	s7,8(sp)
    80002436:	e062                	sd	s8,0(sp)
    80002438:	0880                	addi	s0,sp,80
    8000243a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000243c:	00000097          	auipc	ra,0x0
    80002440:	83c080e7          	jalr	-1988(ra) # 80001c78 <myproc>
    80002444:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002446:	0000f517          	auipc	a0,0xf
    8000244a:	3ca50513          	addi	a0,a0,970 # 80011810 <wait_lock>
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	796080e7          	jalr	1942(ra) # 80000be4 <acquire>
    havekids = 0;
    80002456:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002458:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000245a:	00015997          	auipc	s3,0x15
    8000245e:	7ce98993          	addi	s3,s3,1998 # 80017c28 <tickslock>
        havekids = 1;
    80002462:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002464:	0000fc17          	auipc	s8,0xf
    80002468:	3acc0c13          	addi	s8,s8,940 # 80011810 <wait_lock>
    havekids = 0;
    8000246c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000246e:	0000f497          	auipc	s1,0xf
    80002472:	3ba48493          	addi	s1,s1,954 # 80011828 <proc>
    80002476:	a0bd                	j	800024e4 <wait+0xc2>
          pid = np->pid;
    80002478:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000247c:	000b0e63          	beqz	s6,80002498 <wait+0x76>
    80002480:	4691                	li	a3,4
    80002482:	04448613          	addi	a2,s1,68
    80002486:	85da                	mv	a1,s6
    80002488:	07893503          	ld	a0,120(s2)
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	1e6080e7          	jalr	486(ra) # 80001672 <copyout>
    80002494:	02054563          	bltz	a0,800024be <wait+0x9c>
          freeproc(np);
    80002498:	8526                	mv	a0,s1
    8000249a:	00000097          	auipc	ra,0x0
    8000249e:	9a6080e7          	jalr	-1626(ra) # 80001e40 <freeproc>
          release(&np->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	7f4080e7          	jalr	2036(ra) # 80000c98 <release>
          release(&wait_lock);
    800024ac:	0000f517          	auipc	a0,0xf
    800024b0:	36450513          	addi	a0,a0,868 # 80011810 <wait_lock>
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	7e4080e7          	jalr	2020(ra) # 80000c98 <release>
          return pid;
    800024bc:	a09d                	j	80002522 <wait+0x100>
            release(&np->lock);
    800024be:	8526                	mv	a0,s1
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	7d8080e7          	jalr	2008(ra) # 80000c98 <release>
            release(&wait_lock);
    800024c8:	0000f517          	auipc	a0,0xf
    800024cc:	34850513          	addi	a0,a0,840 # 80011810 <wait_lock>
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	7c8080e7          	jalr	1992(ra) # 80000c98 <release>
            return -1;
    800024d8:	59fd                	li	s3,-1
    800024da:	a0a1                	j	80002522 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800024dc:	19048493          	addi	s1,s1,400
    800024e0:	03348463          	beq	s1,s3,80002508 <wait+0xe6>
      if(np->parent == p){
    800024e4:	70bc                	ld	a5,96(s1)
    800024e6:	ff279be3          	bne	a5,s2,800024dc <wait+0xba>
        acquire(&np->lock);
    800024ea:	8526                	mv	a0,s1
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	6f8080e7          	jalr	1784(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800024f4:	589c                	lw	a5,48(s1)
    800024f6:	f94781e3          	beq	a5,s4,80002478 <wait+0x56>
        release(&np->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	79c080e7          	jalr	1948(ra) # 80000c98 <release>
        havekids = 1;
    80002504:	8756                	mv	a4,s5
    80002506:	bfd9                	j	800024dc <wait+0xba>
    if(!havekids || p->killed){
    80002508:	c701                	beqz	a4,80002510 <wait+0xee>
    8000250a:	04092783          	lw	a5,64(s2)
    8000250e:	c79d                	beqz	a5,8000253c <wait+0x11a>
      release(&wait_lock);
    80002510:	0000f517          	auipc	a0,0xf
    80002514:	30050513          	addi	a0,a0,768 # 80011810 <wait_lock>
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	780080e7          	jalr	1920(ra) # 80000c98 <release>
      return -1;
    80002520:	59fd                	li	s3,-1
}
    80002522:	854e                	mv	a0,s3
    80002524:	60a6                	ld	ra,72(sp)
    80002526:	6406                	ld	s0,64(sp)
    80002528:	74e2                	ld	s1,56(sp)
    8000252a:	7942                	ld	s2,48(sp)
    8000252c:	79a2                	ld	s3,40(sp)
    8000252e:	7a02                	ld	s4,32(sp)
    80002530:	6ae2                	ld	s5,24(sp)
    80002532:	6b42                	ld	s6,16(sp)
    80002534:	6ba2                	ld	s7,8(sp)
    80002536:	6c02                	ld	s8,0(sp)
    80002538:	6161                	addi	sp,sp,80
    8000253a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000253c:	85e2                	mv	a1,s8
    8000253e:	854a                	mv	a0,s2
    80002540:	00000097          	auipc	ra,0x0
    80002544:	e7e080e7          	jalr	-386(ra) # 800023be <sleep>
    havekids = 0;
    80002548:	b715                	j	8000246c <wait+0x4a>

000000008000254a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000254a:	7139                	addi	sp,sp,-64
    8000254c:	fc06                	sd	ra,56(sp)
    8000254e:	f822                	sd	s0,48(sp)
    80002550:	f426                	sd	s1,40(sp)
    80002552:	f04a                	sd	s2,32(sp)
    80002554:	ec4e                	sd	s3,24(sp)
    80002556:	e852                	sd	s4,16(sp)
    80002558:	e456                	sd	s5,8(sp)
    8000255a:	0080                	addi	s0,sp,64
    8000255c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000255e:	0000f497          	auipc	s1,0xf
    80002562:	2ca48493          	addi	s1,s1,714 # 80011828 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002566:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002568:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000256a:	00015917          	auipc	s2,0x15
    8000256e:	6be90913          	addi	s2,s2,1726 # 80017c28 <tickslock>
    80002572:	a821                	j	8000258a <wakeup+0x40>
        p->state = RUNNABLE;
    80002574:	0354a823          	sw	s5,48(s1)
      }
      release(&p->lock);
    80002578:	8526                	mv	a0,s1
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	71e080e7          	jalr	1822(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002582:	19048493          	addi	s1,s1,400
    80002586:	03248463          	beq	s1,s2,800025ae <wakeup+0x64>
    if(p != myproc()){
    8000258a:	fffff097          	auipc	ra,0xfffff
    8000258e:	6ee080e7          	jalr	1774(ra) # 80001c78 <myproc>
    80002592:	fea488e3          	beq	s1,a0,80002582 <wakeup+0x38>
      acquire(&p->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	64c080e7          	jalr	1612(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800025a0:	589c                	lw	a5,48(s1)
    800025a2:	fd379be3          	bne	a5,s3,80002578 <wakeup+0x2e>
    800025a6:	7c9c                	ld	a5,56(s1)
    800025a8:	fd4798e3          	bne	a5,s4,80002578 <wakeup+0x2e>
    800025ac:	b7e1                	j	80002574 <wakeup+0x2a>
    }
  }
}
    800025ae:	70e2                	ld	ra,56(sp)
    800025b0:	7442                	ld	s0,48(sp)
    800025b2:	74a2                	ld	s1,40(sp)
    800025b4:	7902                	ld	s2,32(sp)
    800025b6:	69e2                	ld	s3,24(sp)
    800025b8:	6a42                	ld	s4,16(sp)
    800025ba:	6aa2                	ld	s5,8(sp)
    800025bc:	6121                	addi	sp,sp,64
    800025be:	8082                	ret

00000000800025c0 <reparent>:
{
    800025c0:	7179                	addi	sp,sp,-48
    800025c2:	f406                	sd	ra,40(sp)
    800025c4:	f022                	sd	s0,32(sp)
    800025c6:	ec26                	sd	s1,24(sp)
    800025c8:	e84a                	sd	s2,16(sp)
    800025ca:	e44e                	sd	s3,8(sp)
    800025cc:	e052                	sd	s4,0(sp)
    800025ce:	1800                	addi	s0,sp,48
    800025d0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025d2:	0000f497          	auipc	s1,0xf
    800025d6:	25648493          	addi	s1,s1,598 # 80011828 <proc>
      pp->parent = initproc;
    800025da:	00007a17          	auipc	s4,0x7
    800025de:	a66a0a13          	addi	s4,s4,-1434 # 80009040 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025e2:	00015997          	auipc	s3,0x15
    800025e6:	64698993          	addi	s3,s3,1606 # 80017c28 <tickslock>
    800025ea:	a029                	j	800025f4 <reparent+0x34>
    800025ec:	19048493          	addi	s1,s1,400
    800025f0:	01348d63          	beq	s1,s3,8000260a <reparent+0x4a>
    if(pp->parent == p){
    800025f4:	70bc                	ld	a5,96(s1)
    800025f6:	ff279be3          	bne	a5,s2,800025ec <reparent+0x2c>
      pp->parent = initproc;
    800025fa:	000a3503          	ld	a0,0(s4)
    800025fe:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80002600:	00000097          	auipc	ra,0x0
    80002604:	f4a080e7          	jalr	-182(ra) # 8000254a <wakeup>
    80002608:	b7d5                	j	800025ec <reparent+0x2c>
}
    8000260a:	70a2                	ld	ra,40(sp)
    8000260c:	7402                	ld	s0,32(sp)
    8000260e:	64e2                	ld	s1,24(sp)
    80002610:	6942                	ld	s2,16(sp)
    80002612:	69a2                	ld	s3,8(sp)
    80002614:	6a02                	ld	s4,0(sp)
    80002616:	6145                	addi	sp,sp,48
    80002618:	8082                	ret

000000008000261a <exit>:
{
    8000261a:	7179                	addi	sp,sp,-48
    8000261c:	f406                	sd	ra,40(sp)
    8000261e:	f022                	sd	s0,32(sp)
    80002620:	ec26                	sd	s1,24(sp)
    80002622:	e84a                	sd	s2,16(sp)
    80002624:	e44e                	sd	s3,8(sp)
    80002626:	e052                	sd	s4,0(sp)
    80002628:	1800                	addi	s0,sp,48
    8000262a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	64c080e7          	jalr	1612(ra) # 80001c78 <myproc>
    80002634:	89aa                	mv	s3,a0
  if(p == initproc)
    80002636:	00007797          	auipc	a5,0x7
    8000263a:	a0a7b783          	ld	a5,-1526(a5) # 80009040 <initproc>
    8000263e:	0f850493          	addi	s1,a0,248
    80002642:	17850913          	addi	s2,a0,376
    80002646:	02a79363          	bne	a5,a0,8000266c <exit+0x52>
    panic("init exiting");
    8000264a:	00006517          	auipc	a0,0x6
    8000264e:	c7650513          	addi	a0,a0,-906 # 800082c0 <digits+0x280>
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	eec080e7          	jalr	-276(ra) # 8000053e <panic>
      fileclose(f);
    8000265a:	00002097          	auipc	ra,0x2
    8000265e:	1ae080e7          	jalr	430(ra) # 80004808 <fileclose>
      p->ofile[fd] = 0;
    80002662:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002666:	04a1                	addi	s1,s1,8
    80002668:	01248563          	beq	s1,s2,80002672 <exit+0x58>
    if(p->ofile[fd]){
    8000266c:	6088                	ld	a0,0(s1)
    8000266e:	f575                	bnez	a0,8000265a <exit+0x40>
    80002670:	bfdd                	j	80002666 <exit+0x4c>
  begin_op();
    80002672:	00002097          	auipc	ra,0x2
    80002676:	cca080e7          	jalr	-822(ra) # 8000433c <begin_op>
  iput(p->cwd);
    8000267a:	1789b503          	ld	a0,376(s3)
    8000267e:	00001097          	auipc	ra,0x1
    80002682:	4a6080e7          	jalr	1190(ra) # 80003b24 <iput>
  end_op();
    80002686:	00002097          	auipc	ra,0x2
    8000268a:	d36080e7          	jalr	-714(ra) # 800043bc <end_op>
  p->cwd = 0;
    8000268e:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    80002692:	0000f497          	auipc	s1,0xf
    80002696:	17e48493          	addi	s1,s1,382 # 80011810 <wait_lock>
    8000269a:	8526                	mv	a0,s1
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	548080e7          	jalr	1352(ra) # 80000be4 <acquire>
  reparent(p);
    800026a4:	854e                	mv	a0,s3
    800026a6:	00000097          	auipc	ra,0x0
    800026aa:	f1a080e7          	jalr	-230(ra) # 800025c0 <reparent>
  wakeup(p->parent);
    800026ae:	0609b503          	ld	a0,96(s3)
    800026b2:	00000097          	auipc	ra,0x0
    800026b6:	e98080e7          	jalr	-360(ra) # 8000254a <wakeup>
  acquire(&p->lock);
    800026ba:	854e                	mv	a0,s3
    800026bc:	ffffe097          	auipc	ra,0xffffe
    800026c0:	528080e7          	jalr	1320(ra) # 80000be4 <acquire>
  p->xstate = status;
    800026c4:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    800026c8:	4795                	li	a5,5
    800026ca:	02f9a823          	sw	a5,48(s3)
  release(&wait_lock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	5c8080e7          	jalr	1480(ra) # 80000c98 <release>
  sched();
    800026d8:	00000097          	auipc	ra,0x0
    800026dc:	b74080e7          	jalr	-1164(ra) # 8000224c <sched>
  panic("zombie exit");
    800026e0:	00006517          	auipc	a0,0x6
    800026e4:	bf050513          	addi	a0,a0,-1040 # 800082d0 <digits+0x290>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	e56080e7          	jalr	-426(ra) # 8000053e <panic>

00000000800026f0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800026f0:	7179                	addi	sp,sp,-48
    800026f2:	f406                	sd	ra,40(sp)
    800026f4:	f022                	sd	s0,32(sp)
    800026f6:	ec26                	sd	s1,24(sp)
    800026f8:	e84a                	sd	s2,16(sp)
    800026fa:	e44e                	sd	s3,8(sp)
    800026fc:	1800                	addi	s0,sp,48
    800026fe:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002700:	0000f497          	auipc	s1,0xf
    80002704:	12848493          	addi	s1,s1,296 # 80011828 <proc>
    80002708:	00015997          	auipc	s3,0x15
    8000270c:	52098993          	addi	s3,s3,1312 # 80017c28 <tickslock>
    acquire(&p->lock);
    80002710:	8526                	mv	a0,s1
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	4d2080e7          	jalr	1234(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000271a:	44bc                	lw	a5,72(s1)
    8000271c:	01278d63          	beq	a5,s2,80002736 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002720:	8526                	mv	a0,s1
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	576080e7          	jalr	1398(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000272a:	19048493          	addi	s1,s1,400
    8000272e:	ff3491e3          	bne	s1,s3,80002710 <kill+0x20>
  }
  return -1;
    80002732:	557d                	li	a0,-1
    80002734:	a829                	j	8000274e <kill+0x5e>
      p->killed = 1;
    80002736:	4785                	li	a5,1
    80002738:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    8000273a:	5898                	lw	a4,48(s1)
    8000273c:	4789                	li	a5,2
    8000273e:	00f70f63          	beq	a4,a5,8000275c <kill+0x6c>
      release(&p->lock);
    80002742:	8526                	mv	a0,s1
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	554080e7          	jalr	1364(ra) # 80000c98 <release>
      return 0;
    8000274c:	4501                	li	a0,0
}
    8000274e:	70a2                	ld	ra,40(sp)
    80002750:	7402                	ld	s0,32(sp)
    80002752:	64e2                	ld	s1,24(sp)
    80002754:	6942                	ld	s2,16(sp)
    80002756:	69a2                	ld	s3,8(sp)
    80002758:	6145                	addi	sp,sp,48
    8000275a:	8082                	ret
        p->state = RUNNABLE;
    8000275c:	478d                	li	a5,3
    8000275e:	d89c                	sw	a5,48(s1)
    80002760:	b7cd                	j	80002742 <kill+0x52>

0000000080002762 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002762:	7179                	addi	sp,sp,-48
    80002764:	f406                	sd	ra,40(sp)
    80002766:	f022                	sd	s0,32(sp)
    80002768:	ec26                	sd	s1,24(sp)
    8000276a:	e84a                	sd	s2,16(sp)
    8000276c:	e44e                	sd	s3,8(sp)
    8000276e:	e052                	sd	s4,0(sp)
    80002770:	1800                	addi	s0,sp,48
    80002772:	84aa                	mv	s1,a0
    80002774:	892e                	mv	s2,a1
    80002776:	89b2                	mv	s3,a2
    80002778:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000277a:	fffff097          	auipc	ra,0xfffff
    8000277e:	4fe080e7          	jalr	1278(ra) # 80001c78 <myproc>
  if(user_dst){
    80002782:	c08d                	beqz	s1,800027a4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002784:	86d2                	mv	a3,s4
    80002786:	864e                	mv	a2,s3
    80002788:	85ca                	mv	a1,s2
    8000278a:	7d28                	ld	a0,120(a0)
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	ee6080e7          	jalr	-282(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002794:	70a2                	ld	ra,40(sp)
    80002796:	7402                	ld	s0,32(sp)
    80002798:	64e2                	ld	s1,24(sp)
    8000279a:	6942                	ld	s2,16(sp)
    8000279c:	69a2                	ld	s3,8(sp)
    8000279e:	6a02                	ld	s4,0(sp)
    800027a0:	6145                	addi	sp,sp,48
    800027a2:	8082                	ret
    memmove((char *)dst, src, len);
    800027a4:	000a061b          	sext.w	a2,s4
    800027a8:	85ce                	mv	a1,s3
    800027aa:	854a                	mv	a0,s2
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	594080e7          	jalr	1428(ra) # 80000d40 <memmove>
    return 0;
    800027b4:	8526                	mv	a0,s1
    800027b6:	bff9                	j	80002794 <either_copyout+0x32>

00000000800027b8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027b8:	7179                	addi	sp,sp,-48
    800027ba:	f406                	sd	ra,40(sp)
    800027bc:	f022                	sd	s0,32(sp)
    800027be:	ec26                	sd	s1,24(sp)
    800027c0:	e84a                	sd	s2,16(sp)
    800027c2:	e44e                	sd	s3,8(sp)
    800027c4:	e052                	sd	s4,0(sp)
    800027c6:	1800                	addi	s0,sp,48
    800027c8:	892a                	mv	s2,a0
    800027ca:	84ae                	mv	s1,a1
    800027cc:	89b2                	mv	s3,a2
    800027ce:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027d0:	fffff097          	auipc	ra,0xfffff
    800027d4:	4a8080e7          	jalr	1192(ra) # 80001c78 <myproc>
  if(user_src){
    800027d8:	c08d                	beqz	s1,800027fa <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027da:	86d2                	mv	a3,s4
    800027dc:	864e                	mv	a2,s3
    800027de:	85ca                	mv	a1,s2
    800027e0:	7d28                	ld	a0,120(a0)
    800027e2:	fffff097          	auipc	ra,0xfffff
    800027e6:	f1c080e7          	jalr	-228(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027ea:	70a2                	ld	ra,40(sp)
    800027ec:	7402                	ld	s0,32(sp)
    800027ee:	64e2                	ld	s1,24(sp)
    800027f0:	6942                	ld	s2,16(sp)
    800027f2:	69a2                	ld	s3,8(sp)
    800027f4:	6a02                	ld	s4,0(sp)
    800027f6:	6145                	addi	sp,sp,48
    800027f8:	8082                	ret
    memmove(dst, (char*)src, len);
    800027fa:	000a061b          	sext.w	a2,s4
    800027fe:	85ce                	mv	a1,s3
    80002800:	854a                	mv	a0,s2
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	53e080e7          	jalr	1342(ra) # 80000d40 <memmove>
    return 0;
    8000280a:	8526                	mv	a0,s1
    8000280c:	bff9                	j	800027ea <either_copyin+0x32>

000000008000280e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000280e:	715d                	addi	sp,sp,-80
    80002810:	e486                	sd	ra,72(sp)
    80002812:	e0a2                	sd	s0,64(sp)
    80002814:	fc26                	sd	s1,56(sp)
    80002816:	f84a                	sd	s2,48(sp)
    80002818:	f44e                	sd	s3,40(sp)
    8000281a:	f052                	sd	s4,32(sp)
    8000281c:	ec56                	sd	s5,24(sp)
    8000281e:	e85a                	sd	s6,16(sp)
    80002820:	e45e                	sd	s7,8(sp)
    80002822:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002824:	00006517          	auipc	a0,0x6
    80002828:	8a450513          	addi	a0,a0,-1884 # 800080c8 <digits+0x88>
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	d5c080e7          	jalr	-676(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002834:	0000f497          	auipc	s1,0xf
    80002838:	17448493          	addi	s1,s1,372 # 800119a8 <proc+0x180>
    8000283c:	00015917          	auipc	s2,0x15
    80002840:	56c90913          	addi	s2,s2,1388 # 80017da8 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002844:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002846:	00006997          	auipc	s3,0x6
    8000284a:	a9a98993          	addi	s3,s3,-1382 # 800082e0 <digits+0x2a0>
    printf("%d %s %s", p->pid, state, p->name);
    8000284e:	00006a97          	auipc	s5,0x6
    80002852:	a9aa8a93          	addi	s5,s5,-1382 # 800082e8 <digits+0x2a8>
    printf("\n");
    80002856:	00006a17          	auipc	s4,0x6
    8000285a:	872a0a13          	addi	s4,s4,-1934 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000285e:	00006b97          	auipc	s7,0x6
    80002862:	ac2b8b93          	addi	s7,s7,-1342 # 80008320 <states.1777>
    80002866:	a00d                	j	80002888 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002868:	ec86a583          	lw	a1,-312(a3)
    8000286c:	8556                	mv	a0,s5
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	d1a080e7          	jalr	-742(ra) # 80000588 <printf>
    printf("\n");
    80002876:	8552                	mv	a0,s4
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	d10080e7          	jalr	-752(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002880:	19048493          	addi	s1,s1,400
    80002884:	03248163          	beq	s1,s2,800028a6 <procdump+0x98>
    if(p->state == UNUSED)
    80002888:	86a6                	mv	a3,s1
    8000288a:	eb04a783          	lw	a5,-336(s1)
    8000288e:	dbed                	beqz	a5,80002880 <procdump+0x72>
      state = "???";
    80002890:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002892:	fcfb6be3          	bltu	s6,a5,80002868 <procdump+0x5a>
    80002896:	1782                	slli	a5,a5,0x20
    80002898:	9381                	srli	a5,a5,0x20
    8000289a:	078e                	slli	a5,a5,0x3
    8000289c:	97de                	add	a5,a5,s7
    8000289e:	6390                	ld	a2,0(a5)
    800028a0:	f661                	bnez	a2,80002868 <procdump+0x5a>
      state = "???";
    800028a2:	864e                	mv	a2,s3
    800028a4:	b7d1                	j	80002868 <procdump+0x5a>
  }
}
    800028a6:	60a6                	ld	ra,72(sp)
    800028a8:	6406                	ld	s0,64(sp)
    800028aa:	74e2                	ld	s1,56(sp)
    800028ac:	7942                	ld	s2,48(sp)
    800028ae:	79a2                	ld	s3,40(sp)
    800028b0:	7a02                	ld	s4,32(sp)
    800028b2:	6ae2                	ld	s5,24(sp)
    800028b4:	6b42                	ld	s6,16(sp)
    800028b6:	6ba2                	ld	s7,8(sp)
    800028b8:	6161                	addi	sp,sp,80
    800028ba:	8082                	ret

00000000800028bc <swtch>:
    800028bc:	00153023          	sd	ra,0(a0)
    800028c0:	00253423          	sd	sp,8(a0)
    800028c4:	e900                	sd	s0,16(a0)
    800028c6:	ed04                	sd	s1,24(a0)
    800028c8:	03253023          	sd	s2,32(a0)
    800028cc:	03353423          	sd	s3,40(a0)
    800028d0:	03453823          	sd	s4,48(a0)
    800028d4:	03553c23          	sd	s5,56(a0)
    800028d8:	05653023          	sd	s6,64(a0)
    800028dc:	05753423          	sd	s7,72(a0)
    800028e0:	05853823          	sd	s8,80(a0)
    800028e4:	05953c23          	sd	s9,88(a0)
    800028e8:	07a53023          	sd	s10,96(a0)
    800028ec:	07b53423          	sd	s11,104(a0)
    800028f0:	0005b083          	ld	ra,0(a1)
    800028f4:	0085b103          	ld	sp,8(a1)
    800028f8:	6980                	ld	s0,16(a1)
    800028fa:	6d84                	ld	s1,24(a1)
    800028fc:	0205b903          	ld	s2,32(a1)
    80002900:	0285b983          	ld	s3,40(a1)
    80002904:	0305ba03          	ld	s4,48(a1)
    80002908:	0385ba83          	ld	s5,56(a1)
    8000290c:	0405bb03          	ld	s6,64(a1)
    80002910:	0485bb83          	ld	s7,72(a1)
    80002914:	0505bc03          	ld	s8,80(a1)
    80002918:	0585bc83          	ld	s9,88(a1)
    8000291c:	0605bd03          	ld	s10,96(a1)
    80002920:	0685bd83          	ld	s11,104(a1)
    80002924:	8082                	ret

0000000080002926 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002926:	1141                	addi	sp,sp,-16
    80002928:	e406                	sd	ra,8(sp)
    8000292a:	e022                	sd	s0,0(sp)
    8000292c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000292e:	00006597          	auipc	a1,0x6
    80002932:	a2258593          	addi	a1,a1,-1502 # 80008350 <states.1777+0x30>
    80002936:	00015517          	auipc	a0,0x15
    8000293a:	2f250513          	addi	a0,a0,754 # 80017c28 <tickslock>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	216080e7          	jalr	534(ra) # 80000b54 <initlock>
}
    80002946:	60a2                	ld	ra,8(sp)
    80002948:	6402                	ld	s0,0(sp)
    8000294a:	0141                	addi	sp,sp,16
    8000294c:	8082                	ret

000000008000294e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000294e:	1141                	addi	sp,sp,-16
    80002950:	e422                	sd	s0,8(sp)
    80002952:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002954:	00003797          	auipc	a5,0x3
    80002958:	4cc78793          	addi	a5,a5,1228 # 80005e20 <kernelvec>
    8000295c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002960:	6422                	ld	s0,8(sp)
    80002962:	0141                	addi	sp,sp,16
    80002964:	8082                	ret

0000000080002966 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002966:	1141                	addi	sp,sp,-16
    80002968:	e406                	sd	ra,8(sp)
    8000296a:	e022                	sd	s0,0(sp)
    8000296c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000296e:	fffff097          	auipc	ra,0xfffff
    80002972:	30a080e7          	jalr	778(ra) # 80001c78 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002976:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000297a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000297c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002980:	00004617          	auipc	a2,0x4
    80002984:	68060613          	addi	a2,a2,1664 # 80007000 <_trampoline>
    80002988:	00004697          	auipc	a3,0x4
    8000298c:	67868693          	addi	a3,a3,1656 # 80007000 <_trampoline>
    80002990:	8e91                	sub	a3,a3,a2
    80002992:	040007b7          	lui	a5,0x4000
    80002996:	17fd                	addi	a5,a5,-1
    80002998:	07b2                	slli	a5,a5,0xc
    8000299a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000299c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029a0:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029a2:	180026f3          	csrr	a3,satp
    800029a6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029a8:	6158                	ld	a4,128(a0)
    800029aa:	7534                	ld	a3,104(a0)
    800029ac:	6585                	lui	a1,0x1
    800029ae:	96ae                	add	a3,a3,a1
    800029b0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029b2:	6158                	ld	a4,128(a0)
    800029b4:	00000697          	auipc	a3,0x0
    800029b8:	13868693          	addi	a3,a3,312 # 80002aec <usertrap>
    800029bc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029be:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029c0:	8692                	mv	a3,tp
    800029c2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029c8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029cc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029d4:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d6:	6f18                	ld	a4,24(a4)
    800029d8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029dc:	7d2c                	ld	a1,120(a0)
    800029de:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029e0:	00004717          	auipc	a4,0x4
    800029e4:	6b070713          	addi	a4,a4,1712 # 80007090 <userret>
    800029e8:	8f11                	sub	a4,a4,a2
    800029ea:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029ec:	577d                	li	a4,-1
    800029ee:	177e                	slli	a4,a4,0x3f
    800029f0:	8dd9                	or	a1,a1,a4
    800029f2:	02000537          	lui	a0,0x2000
    800029f6:	157d                	addi	a0,a0,-1
    800029f8:	0536                	slli	a0,a0,0xd
    800029fa:	9782                	jalr	a5
}
    800029fc:	60a2                	ld	ra,8(sp)
    800029fe:	6402                	ld	s0,0(sp)
    80002a00:	0141                	addi	sp,sp,16
    80002a02:	8082                	ret

0000000080002a04 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a04:	1101                	addi	sp,sp,-32
    80002a06:	ec06                	sd	ra,24(sp)
    80002a08:	e822                	sd	s0,16(sp)
    80002a0a:	e426                	sd	s1,8(sp)
    80002a0c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a0e:	00015497          	auipc	s1,0x15
    80002a12:	21a48493          	addi	s1,s1,538 # 80017c28 <tickslock>
    80002a16:	8526                	mv	a0,s1
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	1cc080e7          	jalr	460(ra) # 80000be4 <acquire>
  ticks++;
    80002a20:	00006517          	auipc	a0,0x6
    80002a24:	62850513          	addi	a0,a0,1576 # 80009048 <ticks>
    80002a28:	411c                	lw	a5,0(a0)
    80002a2a:	2785                	addiw	a5,a5,1
    80002a2c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	b1c080e7          	jalr	-1252(ra) # 8000254a <wakeup>
  release(&tickslock);
    80002a36:	8526                	mv	a0,s1
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	260080e7          	jalr	608(ra) # 80000c98 <release>
}
    80002a40:	60e2                	ld	ra,24(sp)
    80002a42:	6442                	ld	s0,16(sp)
    80002a44:	64a2                	ld	s1,8(sp)
    80002a46:	6105                	addi	sp,sp,32
    80002a48:	8082                	ret

0000000080002a4a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a4a:	1101                	addi	sp,sp,-32
    80002a4c:	ec06                	sd	ra,24(sp)
    80002a4e:	e822                	sd	s0,16(sp)
    80002a50:	e426                	sd	s1,8(sp)
    80002a52:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a54:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a58:	00074d63          	bltz	a4,80002a72 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a5c:	57fd                	li	a5,-1
    80002a5e:	17fe                	slli	a5,a5,0x3f
    80002a60:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a62:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a64:	06f70363          	beq	a4,a5,80002aca <devintr+0x80>
  }
}
    80002a68:	60e2                	ld	ra,24(sp)
    80002a6a:	6442                	ld	s0,16(sp)
    80002a6c:	64a2                	ld	s1,8(sp)
    80002a6e:	6105                	addi	sp,sp,32
    80002a70:	8082                	ret
     (scause & 0xff) == 9){
    80002a72:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a76:	46a5                	li	a3,9
    80002a78:	fed792e3          	bne	a5,a3,80002a5c <devintr+0x12>
    int irq = plic_claim();
    80002a7c:	00003097          	auipc	ra,0x3
    80002a80:	4ac080e7          	jalr	1196(ra) # 80005f28 <plic_claim>
    80002a84:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a86:	47a9                	li	a5,10
    80002a88:	02f50763          	beq	a0,a5,80002ab6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a8c:	4785                	li	a5,1
    80002a8e:	02f50963          	beq	a0,a5,80002ac0 <devintr+0x76>
    return 1;
    80002a92:	4505                	li	a0,1
    } else if(irq){
    80002a94:	d8f1                	beqz	s1,80002a68 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a96:	85a6                	mv	a1,s1
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	8c050513          	addi	a0,a0,-1856 # 80008358 <states.1777+0x38>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	ae8080e7          	jalr	-1304(ra) # 80000588 <printf>
      plic_complete(irq);
    80002aa8:	8526                	mv	a0,s1
    80002aaa:	00003097          	auipc	ra,0x3
    80002aae:	4a2080e7          	jalr	1186(ra) # 80005f4c <plic_complete>
    return 1;
    80002ab2:	4505                	li	a0,1
    80002ab4:	bf55                	j	80002a68 <devintr+0x1e>
      uartintr();
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	ef2080e7          	jalr	-270(ra) # 800009a8 <uartintr>
    80002abe:	b7ed                	j	80002aa8 <devintr+0x5e>
      virtio_disk_intr();
    80002ac0:	00004097          	auipc	ra,0x4
    80002ac4:	96c080e7          	jalr	-1684(ra) # 8000642c <virtio_disk_intr>
    80002ac8:	b7c5                	j	80002aa8 <devintr+0x5e>
    if(cpuid() == 0){
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	17a080e7          	jalr	378(ra) # 80001c44 <cpuid>
    80002ad2:	c901                	beqz	a0,80002ae2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ad4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ad8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ada:	14479073          	csrw	sip,a5
    return 2;
    80002ade:	4509                	li	a0,2
    80002ae0:	b761                	j	80002a68 <devintr+0x1e>
      clockintr();
    80002ae2:	00000097          	auipc	ra,0x0
    80002ae6:	f22080e7          	jalr	-222(ra) # 80002a04 <clockintr>
    80002aea:	b7ed                	j	80002ad4 <devintr+0x8a>

0000000080002aec <usertrap>:
{
    80002aec:	1101                	addi	sp,sp,-32
    80002aee:	ec06                	sd	ra,24(sp)
    80002af0:	e822                	sd	s0,16(sp)
    80002af2:	e426                	sd	s1,8(sp)
    80002af4:	e04a                	sd	s2,0(sp)
    80002af6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002afc:	1007f793          	andi	a5,a5,256
    80002b00:	e3ad                	bnez	a5,80002b62 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b02:	00003797          	auipc	a5,0x3
    80002b06:	31e78793          	addi	a5,a5,798 # 80005e20 <kernelvec>
    80002b0a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	16a080e7          	jalr	362(ra) # 80001c78 <myproc>
    80002b16:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b18:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1a:	14102773          	csrr	a4,sepc
    80002b1e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b20:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b24:	47a1                	li	a5,8
    80002b26:	04f71c63          	bne	a4,a5,80002b7e <usertrap+0x92>
    if(p->killed)
    80002b2a:	413c                	lw	a5,64(a0)
    80002b2c:	e3b9                	bnez	a5,80002b72 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b2e:	60d8                	ld	a4,128(s1)
    80002b30:	6f1c                	ld	a5,24(a4)
    80002b32:	0791                	addi	a5,a5,4
    80002b34:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b36:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b3a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b3e:	10079073          	csrw	sstatus,a5
    syscall();
    80002b42:	00000097          	auipc	ra,0x0
    80002b46:	2e0080e7          	jalr	736(ra) # 80002e22 <syscall>
  if(p->killed)
    80002b4a:	40bc                	lw	a5,64(s1)
    80002b4c:	ebc1                	bnez	a5,80002bdc <usertrap+0xf0>
  usertrapret();
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	e18080e7          	jalr	-488(ra) # 80002966 <usertrapret>
}
    80002b56:	60e2                	ld	ra,24(sp)
    80002b58:	6442                	ld	s0,16(sp)
    80002b5a:	64a2                	ld	s1,8(sp)
    80002b5c:	6902                	ld	s2,0(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret
    panic("usertrap: not from user mode");
    80002b62:	00006517          	auipc	a0,0x6
    80002b66:	81650513          	addi	a0,a0,-2026 # 80008378 <states.1777+0x58>
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	9d4080e7          	jalr	-1580(ra) # 8000053e <panic>
      exit(-1);
    80002b72:	557d                	li	a0,-1
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	aa6080e7          	jalr	-1370(ra) # 8000261a <exit>
    80002b7c:	bf4d                	j	80002b2e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	ecc080e7          	jalr	-308(ra) # 80002a4a <devintr>
    80002b86:	892a                	mv	s2,a0
    80002b88:	c501                	beqz	a0,80002b90 <usertrap+0xa4>
  if(p->killed)
    80002b8a:	40bc                	lw	a5,64(s1)
    80002b8c:	c3a1                	beqz	a5,80002bcc <usertrap+0xe0>
    80002b8e:	a815                	j	80002bc2 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b90:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b94:	44b0                	lw	a2,72(s1)
    80002b96:	00006517          	auipc	a0,0x6
    80002b9a:	80250513          	addi	a0,a0,-2046 # 80008398 <states.1777+0x78>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	9ea080e7          	jalr	-1558(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002baa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bae:	00006517          	auipc	a0,0x6
    80002bb2:	81a50513          	addi	a0,a0,-2022 # 800083c8 <states.1777+0xa8>
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	9d2080e7          	jalr	-1582(ra) # 80000588 <printf>
    p->killed = 1;
    80002bbe:	4785                	li	a5,1
    80002bc0:	c0bc                	sw	a5,64(s1)
    exit(-1);
    80002bc2:	557d                	li	a0,-1
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	a56080e7          	jalr	-1450(ra) # 8000261a <exit>
  if(which_dev == 2)
    80002bcc:	4789                	li	a5,2
    80002bce:	f8f910e3          	bne	s2,a5,80002b4e <usertrap+0x62>
    yield();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	770080e7          	jalr	1904(ra) # 80002342 <yield>
    80002bda:	bf95                	j	80002b4e <usertrap+0x62>
  int which_dev = 0;
    80002bdc:	4901                	li	s2,0
    80002bde:	b7d5                	j	80002bc2 <usertrap+0xd6>

0000000080002be0 <kerneltrap>:
{
    80002be0:	7179                	addi	sp,sp,-48
    80002be2:	f406                	sd	ra,40(sp)
    80002be4:	f022                	sd	s0,32(sp)
    80002be6:	ec26                	sd	s1,24(sp)
    80002be8:	e84a                	sd	s2,16(sp)
    80002bea:	e44e                	sd	s3,8(sp)
    80002bec:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bee:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bf2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bfa:	1004f793          	andi	a5,s1,256
    80002bfe:	cb85                	beqz	a5,80002c2e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c00:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c04:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c06:	ef85                	bnez	a5,80002c3e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c08:	00000097          	auipc	ra,0x0
    80002c0c:	e42080e7          	jalr	-446(ra) # 80002a4a <devintr>
    80002c10:	cd1d                	beqz	a0,80002c4e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c12:	4789                	li	a5,2
    80002c14:	06f50a63          	beq	a0,a5,80002c88 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c18:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c1c:	10049073          	csrw	sstatus,s1
}
    80002c20:	70a2                	ld	ra,40(sp)
    80002c22:	7402                	ld	s0,32(sp)
    80002c24:	64e2                	ld	s1,24(sp)
    80002c26:	6942                	ld	s2,16(sp)
    80002c28:	69a2                	ld	s3,8(sp)
    80002c2a:	6145                	addi	sp,sp,48
    80002c2c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c2e:	00005517          	auipc	a0,0x5
    80002c32:	7ba50513          	addi	a0,a0,1978 # 800083e8 <states.1777+0xc8>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	908080e7          	jalr	-1784(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c3e:	00005517          	auipc	a0,0x5
    80002c42:	7d250513          	addi	a0,a0,2002 # 80008410 <states.1777+0xf0>
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	8f8080e7          	jalr	-1800(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c4e:	85ce                	mv	a1,s3
    80002c50:	00005517          	auipc	a0,0x5
    80002c54:	7e050513          	addi	a0,a0,2016 # 80008430 <states.1777+0x110>
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	930080e7          	jalr	-1744(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c60:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c64:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c68:	00005517          	auipc	a0,0x5
    80002c6c:	7d850513          	addi	a0,a0,2008 # 80008440 <states.1777+0x120>
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	918080e7          	jalr	-1768(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c78:	00005517          	auipc	a0,0x5
    80002c7c:	7e050513          	addi	a0,a0,2016 # 80008458 <states.1777+0x138>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	ff0080e7          	jalr	-16(ra) # 80001c78 <myproc>
    80002c90:	d541                	beqz	a0,80002c18 <kerneltrap+0x38>
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	fe6080e7          	jalr	-26(ra) # 80001c78 <myproc>
    80002c9a:	5918                	lw	a4,48(a0)
    80002c9c:	4791                	li	a5,4
    80002c9e:	f6f71de3          	bne	a4,a5,80002c18 <kerneltrap+0x38>
    yield();
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	6a0080e7          	jalr	1696(ra) # 80002342 <yield>
    80002caa:	b7bd                	j	80002c18 <kerneltrap+0x38>

0000000080002cac <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cac:	1101                	addi	sp,sp,-32
    80002cae:	ec06                	sd	ra,24(sp)
    80002cb0:	e822                	sd	s0,16(sp)
    80002cb2:	e426                	sd	s1,8(sp)
    80002cb4:	1000                	addi	s0,sp,32
    80002cb6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	fc0080e7          	jalr	-64(ra) # 80001c78 <myproc>
  switch (n) {
    80002cc0:	4795                	li	a5,5
    80002cc2:	0497e163          	bltu	a5,s1,80002d04 <argraw+0x58>
    80002cc6:	048a                	slli	s1,s1,0x2
    80002cc8:	00005717          	auipc	a4,0x5
    80002ccc:	7c870713          	addi	a4,a4,1992 # 80008490 <states.1777+0x170>
    80002cd0:	94ba                	add	s1,s1,a4
    80002cd2:	409c                	lw	a5,0(s1)
    80002cd4:	97ba                	add	a5,a5,a4
    80002cd6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cd8:	615c                	ld	a5,128(a0)
    80002cda:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cdc:	60e2                	ld	ra,24(sp)
    80002cde:	6442                	ld	s0,16(sp)
    80002ce0:	64a2                	ld	s1,8(sp)
    80002ce2:	6105                	addi	sp,sp,32
    80002ce4:	8082                	ret
    return p->trapframe->a1;
    80002ce6:	615c                	ld	a5,128(a0)
    80002ce8:	7fa8                	ld	a0,120(a5)
    80002cea:	bfcd                	j	80002cdc <argraw+0x30>
    return p->trapframe->a2;
    80002cec:	615c                	ld	a5,128(a0)
    80002cee:	63c8                	ld	a0,128(a5)
    80002cf0:	b7f5                	j	80002cdc <argraw+0x30>
    return p->trapframe->a3;
    80002cf2:	615c                	ld	a5,128(a0)
    80002cf4:	67c8                	ld	a0,136(a5)
    80002cf6:	b7dd                	j	80002cdc <argraw+0x30>
    return p->trapframe->a4;
    80002cf8:	615c                	ld	a5,128(a0)
    80002cfa:	6bc8                	ld	a0,144(a5)
    80002cfc:	b7c5                	j	80002cdc <argraw+0x30>
    return p->trapframe->a5;
    80002cfe:	615c                	ld	a5,128(a0)
    80002d00:	6fc8                	ld	a0,152(a5)
    80002d02:	bfe9                	j	80002cdc <argraw+0x30>
  panic("argraw");
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	76450513          	addi	a0,a0,1892 # 80008468 <states.1777+0x148>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	832080e7          	jalr	-1998(ra) # 8000053e <panic>

0000000080002d14 <fetchaddr>:
{
    80002d14:	1101                	addi	sp,sp,-32
    80002d16:	ec06                	sd	ra,24(sp)
    80002d18:	e822                	sd	s0,16(sp)
    80002d1a:	e426                	sd	s1,8(sp)
    80002d1c:	e04a                	sd	s2,0(sp)
    80002d1e:	1000                	addi	s0,sp,32
    80002d20:	84aa                	mv	s1,a0
    80002d22:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	f54080e7          	jalr	-172(ra) # 80001c78 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d2c:	793c                	ld	a5,112(a0)
    80002d2e:	02f4f863          	bgeu	s1,a5,80002d5e <fetchaddr+0x4a>
    80002d32:	00848713          	addi	a4,s1,8
    80002d36:	02e7e663          	bltu	a5,a4,80002d62 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d3a:	46a1                	li	a3,8
    80002d3c:	8626                	mv	a2,s1
    80002d3e:	85ca                	mv	a1,s2
    80002d40:	7d28                	ld	a0,120(a0)
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	9bc080e7          	jalr	-1604(ra) # 800016fe <copyin>
    80002d4a:	00a03533          	snez	a0,a0
    80002d4e:	40a00533          	neg	a0,a0
}
    80002d52:	60e2                	ld	ra,24(sp)
    80002d54:	6442                	ld	s0,16(sp)
    80002d56:	64a2                	ld	s1,8(sp)
    80002d58:	6902                	ld	s2,0(sp)
    80002d5a:	6105                	addi	sp,sp,32
    80002d5c:	8082                	ret
    return -1;
    80002d5e:	557d                	li	a0,-1
    80002d60:	bfcd                	j	80002d52 <fetchaddr+0x3e>
    80002d62:	557d                	li	a0,-1
    80002d64:	b7fd                	j	80002d52 <fetchaddr+0x3e>

0000000080002d66 <fetchstr>:
{
    80002d66:	7179                	addi	sp,sp,-48
    80002d68:	f406                	sd	ra,40(sp)
    80002d6a:	f022                	sd	s0,32(sp)
    80002d6c:	ec26                	sd	s1,24(sp)
    80002d6e:	e84a                	sd	s2,16(sp)
    80002d70:	e44e                	sd	s3,8(sp)
    80002d72:	1800                	addi	s0,sp,48
    80002d74:	892a                	mv	s2,a0
    80002d76:	84ae                	mv	s1,a1
    80002d78:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	efe080e7          	jalr	-258(ra) # 80001c78 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d82:	86ce                	mv	a3,s3
    80002d84:	864a                	mv	a2,s2
    80002d86:	85a6                	mv	a1,s1
    80002d88:	7d28                	ld	a0,120(a0)
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	a00080e7          	jalr	-1536(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002d92:	00054763          	bltz	a0,80002da0 <fetchstr+0x3a>
  return strlen(buf);
    80002d96:	8526                	mv	a0,s1
    80002d98:	ffffe097          	auipc	ra,0xffffe
    80002d9c:	0cc080e7          	jalr	204(ra) # 80000e64 <strlen>
}
    80002da0:	70a2                	ld	ra,40(sp)
    80002da2:	7402                	ld	s0,32(sp)
    80002da4:	64e2                	ld	s1,24(sp)
    80002da6:	6942                	ld	s2,16(sp)
    80002da8:	69a2                	ld	s3,8(sp)
    80002daa:	6145                	addi	sp,sp,48
    80002dac:	8082                	ret

0000000080002dae <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	e426                	sd	s1,8(sp)
    80002db6:	1000                	addi	s0,sp,32
    80002db8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dba:	00000097          	auipc	ra,0x0
    80002dbe:	ef2080e7          	jalr	-270(ra) # 80002cac <argraw>
    80002dc2:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dc4:	4501                	li	a0,0
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	64a2                	ld	s1,8(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret

0000000080002dd0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dd0:	1101                	addi	sp,sp,-32
    80002dd2:	ec06                	sd	ra,24(sp)
    80002dd4:	e822                	sd	s0,16(sp)
    80002dd6:	e426                	sd	s1,8(sp)
    80002dd8:	1000                	addi	s0,sp,32
    80002dda:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	ed0080e7          	jalr	-304(ra) # 80002cac <argraw>
    80002de4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002de6:	4501                	li	a0,0
    80002de8:	60e2                	ld	ra,24(sp)
    80002dea:	6442                	ld	s0,16(sp)
    80002dec:	64a2                	ld	s1,8(sp)
    80002dee:	6105                	addi	sp,sp,32
    80002df0:	8082                	ret

0000000080002df2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002df2:	1101                	addi	sp,sp,-32
    80002df4:	ec06                	sd	ra,24(sp)
    80002df6:	e822                	sd	s0,16(sp)
    80002df8:	e426                	sd	s1,8(sp)
    80002dfa:	e04a                	sd	s2,0(sp)
    80002dfc:	1000                	addi	s0,sp,32
    80002dfe:	84ae                	mv	s1,a1
    80002e00:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	eaa080e7          	jalr	-342(ra) # 80002cac <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e0a:	864a                	mv	a2,s2
    80002e0c:	85a6                	mv	a1,s1
    80002e0e:	00000097          	auipc	ra,0x0
    80002e12:	f58080e7          	jalr	-168(ra) # 80002d66 <fetchstr>
}
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	64a2                	ld	s1,8(sp)
    80002e1c:	6902                	ld	s2,0(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret

0000000080002e22 <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    80002e22:	1101                	addi	sp,sp,-32
    80002e24:	ec06                	sd	ra,24(sp)
    80002e26:	e822                	sd	s0,16(sp)
    80002e28:	e426                	sd	s1,8(sp)
    80002e2a:	e04a                	sd	s2,0(sp)
    80002e2c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	e4a080e7          	jalr	-438(ra) # 80001c78 <myproc>
    80002e36:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e38:	08053903          	ld	s2,128(a0)
    80002e3c:	0a893783          	ld	a5,168(s2)
    80002e40:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e44:	37fd                	addiw	a5,a5,-1
    80002e46:	4759                	li	a4,22
    80002e48:	00f76f63          	bltu	a4,a5,80002e66 <syscall+0x44>
    80002e4c:	00369713          	slli	a4,a3,0x3
    80002e50:	00005797          	auipc	a5,0x5
    80002e54:	65878793          	addi	a5,a5,1624 # 800084a8 <syscalls>
    80002e58:	97ba                	add	a5,a5,a4
    80002e5a:	639c                	ld	a5,0(a5)
    80002e5c:	c789                	beqz	a5,80002e66 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e5e:	9782                	jalr	a5
    80002e60:	06a93823          	sd	a0,112(s2)
    80002e64:	a839                	j	80002e82 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e66:	18048613          	addi	a2,s1,384
    80002e6a:	44ac                	lw	a1,72(s1)
    80002e6c:	00005517          	auipc	a0,0x5
    80002e70:	60450513          	addi	a0,a0,1540 # 80008470 <states.1777+0x150>
    80002e74:	ffffd097          	auipc	ra,0xffffd
    80002e78:	714080e7          	jalr	1812(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e7c:	60dc                	ld	a5,128(s1)
    80002e7e:	577d                	li	a4,-1
    80002e80:	fbb8                	sd	a4,112(a5)
  }
}
    80002e82:	60e2                	ld	ra,24(sp)
    80002e84:	6442                	ld	s0,16(sp)
    80002e86:	64a2                	ld	s1,8(sp)
    80002e88:	6902                	ld	s2,0(sp)
    80002e8a:	6105                	addi	sp,sp,32
    80002e8c:	8082                	ret

0000000080002e8e <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    80002e8e:	1101                	addi	sp,sp,-32
    80002e90:	ec06                	sd	ra,24(sp)
    80002e92:	e822                	sd	s0,16(sp)
    80002e94:	1000                	addi	s0,sp,32
  int a;

  if(argint(0, &a) < 0)
    80002e96:	fec40593          	addi	a1,s0,-20
    80002e9a:	4501                	li	a0,0
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	f12080e7          	jalr	-238(ra) # 80002dae <argint>
    80002ea4:	87aa                	mv	a5,a0
    return -1;
    80002ea6:	557d                	li	a0,-1
  if(argint(0, &a) < 0)
    80002ea8:	0007c863          	bltz	a5,80002eb8 <sys_set_cpu+0x2a>
  return set_cpu(a);
    80002eac:	fec42503          	lw	a0,-20(s0)
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	4ce080e7          	jalr	1230(ra) # 8000237e <set_cpu>
}
    80002eb8:	60e2                	ld	ra,24(sp)
    80002eba:	6442                	ld	s0,16(sp)
    80002ebc:	6105                	addi	sp,sp,32
    80002ebe:	8082                	ret

0000000080002ec0 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80002ec0:	1141                	addi	sp,sp,-16
    80002ec2:	e406                	sd	ra,8(sp)
    80002ec4:	e022                	sd	s0,0(sp)
    80002ec6:	0800                	addi	s0,sp,16
  return get_cpu();
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	df2080e7          	jalr	-526(ra) # 80001cba <get_cpu>
}
    80002ed0:	60a2                	ld	ra,8(sp)
    80002ed2:	6402                	ld	s0,0(sp)
    80002ed4:	0141                	addi	sp,sp,16
    80002ed6:	8082                	ret

0000000080002ed8 <sys_exit>:

uint64
sys_exit(void)
{
    80002ed8:	1101                	addi	sp,sp,-32
    80002eda:	ec06                	sd	ra,24(sp)
    80002edc:	e822                	sd	s0,16(sp)
    80002ede:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ee0:	fec40593          	addi	a1,s0,-20
    80002ee4:	4501                	li	a0,0
    80002ee6:	00000097          	auipc	ra,0x0
    80002eea:	ec8080e7          	jalr	-312(ra) # 80002dae <argint>
    return -1;
    80002eee:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ef0:	00054963          	bltz	a0,80002f02 <sys_exit+0x2a>
  exit(n);
    80002ef4:	fec42503          	lw	a0,-20(s0)
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	722080e7          	jalr	1826(ra) # 8000261a <exit>
  return 0;  // not reached
    80002f00:	4781                	li	a5,0
}
    80002f02:	853e                	mv	a0,a5
    80002f04:	60e2                	ld	ra,24(sp)
    80002f06:	6442                	ld	s0,16(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret

0000000080002f0c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f0c:	1141                	addi	sp,sp,-16
    80002f0e:	e406                	sd	ra,8(sp)
    80002f10:	e022                	sd	s0,0(sp)
    80002f12:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	d64080e7          	jalr	-668(ra) # 80001c78 <myproc>
}
    80002f1c:	4528                	lw	a0,72(a0)
    80002f1e:	60a2                	ld	ra,8(sp)
    80002f20:	6402                	ld	s0,0(sp)
    80002f22:	0141                	addi	sp,sp,16
    80002f24:	8082                	ret

0000000080002f26 <sys_fork>:

uint64
sys_fork(void)
{
    80002f26:	1141                	addi	sp,sp,-16
    80002f28:	e406                	sd	ra,8(sp)
    80002f2a:	e022                	sd	s0,0(sp)
    80002f2c:	0800                	addi	s0,sp,16
  return fork();
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	12e080e7          	jalr	302(ra) # 8000205c <fork>
}
    80002f36:	60a2                	ld	ra,8(sp)
    80002f38:	6402                	ld	s0,0(sp)
    80002f3a:	0141                	addi	sp,sp,16
    80002f3c:	8082                	ret

0000000080002f3e <sys_wait>:

uint64
sys_wait(void)
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f46:	fe840593          	addi	a1,s0,-24
    80002f4a:	4501                	li	a0,0
    80002f4c:	00000097          	auipc	ra,0x0
    80002f50:	e84080e7          	jalr	-380(ra) # 80002dd0 <argaddr>
    80002f54:	87aa                	mv	a5,a0
    return -1;
    80002f56:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f58:	0007c863          	bltz	a5,80002f68 <sys_wait+0x2a>
  return wait(p);
    80002f5c:	fe843503          	ld	a0,-24(s0)
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	4c2080e7          	jalr	1218(ra) # 80002422 <wait>
}
    80002f68:	60e2                	ld	ra,24(sp)
    80002f6a:	6442                	ld	s0,16(sp)
    80002f6c:	6105                	addi	sp,sp,32
    80002f6e:	8082                	ret

0000000080002f70 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f70:	7179                	addi	sp,sp,-48
    80002f72:	f406                	sd	ra,40(sp)
    80002f74:	f022                	sd	s0,32(sp)
    80002f76:	ec26                	sd	s1,24(sp)
    80002f78:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f7a:	fdc40593          	addi	a1,s0,-36
    80002f7e:	4501                	li	a0,0
    80002f80:	00000097          	auipc	ra,0x0
    80002f84:	e2e080e7          	jalr	-466(ra) # 80002dae <argint>
    80002f88:	87aa                	mv	a5,a0
    return -1;
    80002f8a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f8c:	0207c063          	bltz	a5,80002fac <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	ce8080e7          	jalr	-792(ra) # 80001c78 <myproc>
    80002f98:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    80002f9a:	fdc42503          	lw	a0,-36(s0)
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	04a080e7          	jalr	74(ra) # 80001fe8 <growproc>
    80002fa6:	00054863          	bltz	a0,80002fb6 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002faa:	8526                	mv	a0,s1
}
    80002fac:	70a2                	ld	ra,40(sp)
    80002fae:	7402                	ld	s0,32(sp)
    80002fb0:	64e2                	ld	s1,24(sp)
    80002fb2:	6145                	addi	sp,sp,48
    80002fb4:	8082                	ret
    return -1;
    80002fb6:	557d                	li	a0,-1
    80002fb8:	bfd5                	j	80002fac <sys_sbrk+0x3c>

0000000080002fba <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fba:	7139                	addi	sp,sp,-64
    80002fbc:	fc06                	sd	ra,56(sp)
    80002fbe:	f822                	sd	s0,48(sp)
    80002fc0:	f426                	sd	s1,40(sp)
    80002fc2:	f04a                	sd	s2,32(sp)
    80002fc4:	ec4e                	sd	s3,24(sp)
    80002fc6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fc8:	fcc40593          	addi	a1,s0,-52
    80002fcc:	4501                	li	a0,0
    80002fce:	00000097          	auipc	ra,0x0
    80002fd2:	de0080e7          	jalr	-544(ra) # 80002dae <argint>
    return -1;
    80002fd6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fd8:	06054563          	bltz	a0,80003042 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fdc:	00015517          	auipc	a0,0x15
    80002fe0:	c4c50513          	addi	a0,a0,-948 # 80017c28 <tickslock>
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	c00080e7          	jalr	-1024(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002fec:	00006917          	auipc	s2,0x6
    80002ff0:	05c92903          	lw	s2,92(s2) # 80009048 <ticks>
  while(ticks - ticks0 < n){
    80002ff4:	fcc42783          	lw	a5,-52(s0)
    80002ff8:	cf85                	beqz	a5,80003030 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ffa:	00015997          	auipc	s3,0x15
    80002ffe:	c2e98993          	addi	s3,s3,-978 # 80017c28 <tickslock>
    80003002:	00006497          	auipc	s1,0x6
    80003006:	04648493          	addi	s1,s1,70 # 80009048 <ticks>
    if(myproc()->killed){
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	c6e080e7          	jalr	-914(ra) # 80001c78 <myproc>
    80003012:	413c                	lw	a5,64(a0)
    80003014:	ef9d                	bnez	a5,80003052 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003016:	85ce                	mv	a1,s3
    80003018:	8526                	mv	a0,s1
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	3a4080e7          	jalr	932(ra) # 800023be <sleep>
  while(ticks - ticks0 < n){
    80003022:	409c                	lw	a5,0(s1)
    80003024:	412787bb          	subw	a5,a5,s2
    80003028:	fcc42703          	lw	a4,-52(s0)
    8000302c:	fce7efe3          	bltu	a5,a4,8000300a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003030:	00015517          	auipc	a0,0x15
    80003034:	bf850513          	addi	a0,a0,-1032 # 80017c28 <tickslock>
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	c60080e7          	jalr	-928(ra) # 80000c98 <release>
  return 0;
    80003040:	4781                	li	a5,0
}
    80003042:	853e                	mv	a0,a5
    80003044:	70e2                	ld	ra,56(sp)
    80003046:	7442                	ld	s0,48(sp)
    80003048:	74a2                	ld	s1,40(sp)
    8000304a:	7902                	ld	s2,32(sp)
    8000304c:	69e2                	ld	s3,24(sp)
    8000304e:	6121                	addi	sp,sp,64
    80003050:	8082                	ret
      release(&tickslock);
    80003052:	00015517          	auipc	a0,0x15
    80003056:	bd650513          	addi	a0,a0,-1066 # 80017c28 <tickslock>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	c3e080e7          	jalr	-962(ra) # 80000c98 <release>
      return -1;
    80003062:	57fd                	li	a5,-1
    80003064:	bff9                	j	80003042 <sys_sleep+0x88>

0000000080003066 <sys_kill>:

uint64
sys_kill(void)
{
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000306e:	fec40593          	addi	a1,s0,-20
    80003072:	4501                	li	a0,0
    80003074:	00000097          	auipc	ra,0x0
    80003078:	d3a080e7          	jalr	-710(ra) # 80002dae <argint>
    8000307c:	87aa                	mv	a5,a0
    return -1;
    8000307e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003080:	0007c863          	bltz	a5,80003090 <sys_kill+0x2a>
  return kill(pid);
    80003084:	fec42503          	lw	a0,-20(s0)
    80003088:	fffff097          	auipc	ra,0xfffff
    8000308c:	668080e7          	jalr	1640(ra) # 800026f0 <kill>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	6105                	addi	sp,sp,32
    80003096:	8082                	ret

0000000080003098 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003098:	1101                	addi	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	e426                	sd	s1,8(sp)
    800030a0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030a2:	00015517          	auipc	a0,0x15
    800030a6:	b8650513          	addi	a0,a0,-1146 # 80017c28 <tickslock>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	b3a080e7          	jalr	-1222(ra) # 80000be4 <acquire>
  xticks = ticks;
    800030b2:	00006497          	auipc	s1,0x6
    800030b6:	f964a483          	lw	s1,-106(s1) # 80009048 <ticks>
  release(&tickslock);
    800030ba:	00015517          	auipc	a0,0x15
    800030be:	b6e50513          	addi	a0,a0,-1170 # 80017c28 <tickslock>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	bd6080e7          	jalr	-1066(ra) # 80000c98 <release>
  return xticks;
}
    800030ca:	02049513          	slli	a0,s1,0x20
    800030ce:	9101                	srli	a0,a0,0x20
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret

00000000800030da <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030da:	7179                	addi	sp,sp,-48
    800030dc:	f406                	sd	ra,40(sp)
    800030de:	f022                	sd	s0,32(sp)
    800030e0:	ec26                	sd	s1,24(sp)
    800030e2:	e84a                	sd	s2,16(sp)
    800030e4:	e44e                	sd	s3,8(sp)
    800030e6:	e052                	sd	s4,0(sp)
    800030e8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030ea:	00005597          	auipc	a1,0x5
    800030ee:	47e58593          	addi	a1,a1,1150 # 80008568 <syscalls+0xc0>
    800030f2:	00015517          	auipc	a0,0x15
    800030f6:	b4e50513          	addi	a0,a0,-1202 # 80017c40 <bcache>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	a5a080e7          	jalr	-1446(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003102:	0001d797          	auipc	a5,0x1d
    80003106:	b3e78793          	addi	a5,a5,-1218 # 8001fc40 <bcache+0x8000>
    8000310a:	0001d717          	auipc	a4,0x1d
    8000310e:	d9e70713          	addi	a4,a4,-610 # 8001fea8 <bcache+0x8268>
    80003112:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003116:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000311a:	00015497          	auipc	s1,0x15
    8000311e:	b3e48493          	addi	s1,s1,-1218 # 80017c58 <bcache+0x18>
    b->next = bcache.head.next;
    80003122:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003124:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003126:	00005a17          	auipc	s4,0x5
    8000312a:	44aa0a13          	addi	s4,s4,1098 # 80008570 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000312e:	2b893783          	ld	a5,696(s2)
    80003132:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003134:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003138:	85d2                	mv	a1,s4
    8000313a:	01048513          	addi	a0,s1,16
    8000313e:	00001097          	auipc	ra,0x1
    80003142:	4bc080e7          	jalr	1212(ra) # 800045fa <initsleeplock>
    bcache.head.next->prev = b;
    80003146:	2b893783          	ld	a5,696(s2)
    8000314a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000314c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003150:	45848493          	addi	s1,s1,1112
    80003154:	fd349de3          	bne	s1,s3,8000312e <binit+0x54>
  }
}
    80003158:	70a2                	ld	ra,40(sp)
    8000315a:	7402                	ld	s0,32(sp)
    8000315c:	64e2                	ld	s1,24(sp)
    8000315e:	6942                	ld	s2,16(sp)
    80003160:	69a2                	ld	s3,8(sp)
    80003162:	6a02                	ld	s4,0(sp)
    80003164:	6145                	addi	sp,sp,48
    80003166:	8082                	ret

0000000080003168 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003168:	7179                	addi	sp,sp,-48
    8000316a:	f406                	sd	ra,40(sp)
    8000316c:	f022                	sd	s0,32(sp)
    8000316e:	ec26                	sd	s1,24(sp)
    80003170:	e84a                	sd	s2,16(sp)
    80003172:	e44e                	sd	s3,8(sp)
    80003174:	1800                	addi	s0,sp,48
    80003176:	89aa                	mv	s3,a0
    80003178:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000317a:	00015517          	auipc	a0,0x15
    8000317e:	ac650513          	addi	a0,a0,-1338 # 80017c40 <bcache>
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	a62080e7          	jalr	-1438(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000318a:	0001d497          	auipc	s1,0x1d
    8000318e:	d6e4b483          	ld	s1,-658(s1) # 8001fef8 <bcache+0x82b8>
    80003192:	0001d797          	auipc	a5,0x1d
    80003196:	d1678793          	addi	a5,a5,-746 # 8001fea8 <bcache+0x8268>
    8000319a:	02f48f63          	beq	s1,a5,800031d8 <bread+0x70>
    8000319e:	873e                	mv	a4,a5
    800031a0:	a021                	j	800031a8 <bread+0x40>
    800031a2:	68a4                	ld	s1,80(s1)
    800031a4:	02e48a63          	beq	s1,a4,800031d8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031a8:	449c                	lw	a5,8(s1)
    800031aa:	ff379ce3          	bne	a5,s3,800031a2 <bread+0x3a>
    800031ae:	44dc                	lw	a5,12(s1)
    800031b0:	ff2799e3          	bne	a5,s2,800031a2 <bread+0x3a>
      b->refcnt++;
    800031b4:	40bc                	lw	a5,64(s1)
    800031b6:	2785                	addiw	a5,a5,1
    800031b8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ba:	00015517          	auipc	a0,0x15
    800031be:	a8650513          	addi	a0,a0,-1402 # 80017c40 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	ad6080e7          	jalr	-1322(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031ca:	01048513          	addi	a0,s1,16
    800031ce:	00001097          	auipc	ra,0x1
    800031d2:	466080e7          	jalr	1126(ra) # 80004634 <acquiresleep>
      return b;
    800031d6:	a8b9                	j	80003234 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031d8:	0001d497          	auipc	s1,0x1d
    800031dc:	d184b483          	ld	s1,-744(s1) # 8001fef0 <bcache+0x82b0>
    800031e0:	0001d797          	auipc	a5,0x1d
    800031e4:	cc878793          	addi	a5,a5,-824 # 8001fea8 <bcache+0x8268>
    800031e8:	00f48863          	beq	s1,a5,800031f8 <bread+0x90>
    800031ec:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031ee:	40bc                	lw	a5,64(s1)
    800031f0:	cf81                	beqz	a5,80003208 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f2:	64a4                	ld	s1,72(s1)
    800031f4:	fee49de3          	bne	s1,a4,800031ee <bread+0x86>
  panic("bget: no buffers");
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	38050513          	addi	a0,a0,896 # 80008578 <syscalls+0xd0>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	33e080e7          	jalr	830(ra) # 8000053e <panic>
      b->dev = dev;
    80003208:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000320c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003210:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003214:	4785                	li	a5,1
    80003216:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003218:	00015517          	auipc	a0,0x15
    8000321c:	a2850513          	addi	a0,a0,-1496 # 80017c40 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	a78080e7          	jalr	-1416(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003228:	01048513          	addi	a0,s1,16
    8000322c:	00001097          	auipc	ra,0x1
    80003230:	408080e7          	jalr	1032(ra) # 80004634 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003234:	409c                	lw	a5,0(s1)
    80003236:	cb89                	beqz	a5,80003248 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003238:	8526                	mv	a0,s1
    8000323a:	70a2                	ld	ra,40(sp)
    8000323c:	7402                	ld	s0,32(sp)
    8000323e:	64e2                	ld	s1,24(sp)
    80003240:	6942                	ld	s2,16(sp)
    80003242:	69a2                	ld	s3,8(sp)
    80003244:	6145                	addi	sp,sp,48
    80003246:	8082                	ret
    virtio_disk_rw(b, 0);
    80003248:	4581                	li	a1,0
    8000324a:	8526                	mv	a0,s1
    8000324c:	00003097          	auipc	ra,0x3
    80003250:	f0a080e7          	jalr	-246(ra) # 80006156 <virtio_disk_rw>
    b->valid = 1;
    80003254:	4785                	li	a5,1
    80003256:	c09c                	sw	a5,0(s1)
  return b;
    80003258:	b7c5                	j	80003238 <bread+0xd0>

000000008000325a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000325a:	1101                	addi	sp,sp,-32
    8000325c:	ec06                	sd	ra,24(sp)
    8000325e:	e822                	sd	s0,16(sp)
    80003260:	e426                	sd	s1,8(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003266:	0541                	addi	a0,a0,16
    80003268:	00001097          	auipc	ra,0x1
    8000326c:	466080e7          	jalr	1126(ra) # 800046ce <holdingsleep>
    80003270:	cd01                	beqz	a0,80003288 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003272:	4585                	li	a1,1
    80003274:	8526                	mv	a0,s1
    80003276:	00003097          	auipc	ra,0x3
    8000327a:	ee0080e7          	jalr	-288(ra) # 80006156 <virtio_disk_rw>
}
    8000327e:	60e2                	ld	ra,24(sp)
    80003280:	6442                	ld	s0,16(sp)
    80003282:	64a2                	ld	s1,8(sp)
    80003284:	6105                	addi	sp,sp,32
    80003286:	8082                	ret
    panic("bwrite");
    80003288:	00005517          	auipc	a0,0x5
    8000328c:	30850513          	addi	a0,a0,776 # 80008590 <syscalls+0xe8>
    80003290:	ffffd097          	auipc	ra,0xffffd
    80003294:	2ae080e7          	jalr	686(ra) # 8000053e <panic>

0000000080003298 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003298:	1101                	addi	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	e426                	sd	s1,8(sp)
    800032a0:	e04a                	sd	s2,0(sp)
    800032a2:	1000                	addi	s0,sp,32
    800032a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032a6:	01050913          	addi	s2,a0,16
    800032aa:	854a                	mv	a0,s2
    800032ac:	00001097          	auipc	ra,0x1
    800032b0:	422080e7          	jalr	1058(ra) # 800046ce <holdingsleep>
    800032b4:	c92d                	beqz	a0,80003326 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032b6:	854a                	mv	a0,s2
    800032b8:	00001097          	auipc	ra,0x1
    800032bc:	3d2080e7          	jalr	978(ra) # 8000468a <releasesleep>

  acquire(&bcache.lock);
    800032c0:	00015517          	auipc	a0,0x15
    800032c4:	98050513          	addi	a0,a0,-1664 # 80017c40 <bcache>
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	91c080e7          	jalr	-1764(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032d0:	40bc                	lw	a5,64(s1)
    800032d2:	37fd                	addiw	a5,a5,-1
    800032d4:	0007871b          	sext.w	a4,a5
    800032d8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032da:	eb05                	bnez	a4,8000330a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032dc:	68bc                	ld	a5,80(s1)
    800032de:	64b8                	ld	a4,72(s1)
    800032e0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032e2:	64bc                	ld	a5,72(s1)
    800032e4:	68b8                	ld	a4,80(s1)
    800032e6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032e8:	0001d797          	auipc	a5,0x1d
    800032ec:	95878793          	addi	a5,a5,-1704 # 8001fc40 <bcache+0x8000>
    800032f0:	2b87b703          	ld	a4,696(a5)
    800032f4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032f6:	0001d717          	auipc	a4,0x1d
    800032fa:	bb270713          	addi	a4,a4,-1102 # 8001fea8 <bcache+0x8268>
    800032fe:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003300:	2b87b703          	ld	a4,696(a5)
    80003304:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003306:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000330a:	00015517          	auipc	a0,0x15
    8000330e:	93650513          	addi	a0,a0,-1738 # 80017c40 <bcache>
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	986080e7          	jalr	-1658(ra) # 80000c98 <release>
}
    8000331a:	60e2                	ld	ra,24(sp)
    8000331c:	6442                	ld	s0,16(sp)
    8000331e:	64a2                	ld	s1,8(sp)
    80003320:	6902                	ld	s2,0(sp)
    80003322:	6105                	addi	sp,sp,32
    80003324:	8082                	ret
    panic("brelse");
    80003326:	00005517          	auipc	a0,0x5
    8000332a:	27250513          	addi	a0,a0,626 # 80008598 <syscalls+0xf0>
    8000332e:	ffffd097          	auipc	ra,0xffffd
    80003332:	210080e7          	jalr	528(ra) # 8000053e <panic>

0000000080003336 <bpin>:

void
bpin(struct buf *b) {
    80003336:	1101                	addi	sp,sp,-32
    80003338:	ec06                	sd	ra,24(sp)
    8000333a:	e822                	sd	s0,16(sp)
    8000333c:	e426                	sd	s1,8(sp)
    8000333e:	1000                	addi	s0,sp,32
    80003340:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003342:	00015517          	auipc	a0,0x15
    80003346:	8fe50513          	addi	a0,a0,-1794 # 80017c40 <bcache>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	89a080e7          	jalr	-1894(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003352:	40bc                	lw	a5,64(s1)
    80003354:	2785                	addiw	a5,a5,1
    80003356:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003358:	00015517          	auipc	a0,0x15
    8000335c:	8e850513          	addi	a0,a0,-1816 # 80017c40 <bcache>
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	938080e7          	jalr	-1736(ra) # 80000c98 <release>
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	64a2                	ld	s1,8(sp)
    8000336e:	6105                	addi	sp,sp,32
    80003370:	8082                	ret

0000000080003372 <bunpin>:

void
bunpin(struct buf *b) {
    80003372:	1101                	addi	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	e426                	sd	s1,8(sp)
    8000337a:	1000                	addi	s0,sp,32
    8000337c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000337e:	00015517          	auipc	a0,0x15
    80003382:	8c250513          	addi	a0,a0,-1854 # 80017c40 <bcache>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	85e080e7          	jalr	-1954(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000338e:	40bc                	lw	a5,64(s1)
    80003390:	37fd                	addiw	a5,a5,-1
    80003392:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003394:	00015517          	auipc	a0,0x15
    80003398:	8ac50513          	addi	a0,a0,-1876 # 80017c40 <bcache>
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	8fc080e7          	jalr	-1796(ra) # 80000c98 <release>
}
    800033a4:	60e2                	ld	ra,24(sp)
    800033a6:	6442                	ld	s0,16(sp)
    800033a8:	64a2                	ld	s1,8(sp)
    800033aa:	6105                	addi	sp,sp,32
    800033ac:	8082                	ret

00000000800033ae <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033ae:	1101                	addi	sp,sp,-32
    800033b0:	ec06                	sd	ra,24(sp)
    800033b2:	e822                	sd	s0,16(sp)
    800033b4:	e426                	sd	s1,8(sp)
    800033b6:	e04a                	sd	s2,0(sp)
    800033b8:	1000                	addi	s0,sp,32
    800033ba:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033bc:	00d5d59b          	srliw	a1,a1,0xd
    800033c0:	0001d797          	auipc	a5,0x1d
    800033c4:	f5c7a783          	lw	a5,-164(a5) # 8002031c <sb+0x1c>
    800033c8:	9dbd                	addw	a1,a1,a5
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	d9e080e7          	jalr	-610(ra) # 80003168 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033d2:	0074f713          	andi	a4,s1,7
    800033d6:	4785                	li	a5,1
    800033d8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033dc:	14ce                	slli	s1,s1,0x33
    800033de:	90d9                	srli	s1,s1,0x36
    800033e0:	00950733          	add	a4,a0,s1
    800033e4:	05874703          	lbu	a4,88(a4)
    800033e8:	00e7f6b3          	and	a3,a5,a4
    800033ec:	c69d                	beqz	a3,8000341a <bfree+0x6c>
    800033ee:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033f0:	94aa                	add	s1,s1,a0
    800033f2:	fff7c793          	not	a5,a5
    800033f6:	8ff9                	and	a5,a5,a4
    800033f8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033fc:	00001097          	auipc	ra,0x1
    80003400:	118080e7          	jalr	280(ra) # 80004514 <log_write>
  brelse(bp);
    80003404:	854a                	mv	a0,s2
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	e92080e7          	jalr	-366(ra) # 80003298 <brelse>
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6902                	ld	s2,0(sp)
    80003416:	6105                	addi	sp,sp,32
    80003418:	8082                	ret
    panic("freeing free block");
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	18650513          	addi	a0,a0,390 # 800085a0 <syscalls+0xf8>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	11c080e7          	jalr	284(ra) # 8000053e <panic>

000000008000342a <balloc>:
{
    8000342a:	711d                	addi	sp,sp,-96
    8000342c:	ec86                	sd	ra,88(sp)
    8000342e:	e8a2                	sd	s0,80(sp)
    80003430:	e4a6                	sd	s1,72(sp)
    80003432:	e0ca                	sd	s2,64(sp)
    80003434:	fc4e                	sd	s3,56(sp)
    80003436:	f852                	sd	s4,48(sp)
    80003438:	f456                	sd	s5,40(sp)
    8000343a:	f05a                	sd	s6,32(sp)
    8000343c:	ec5e                	sd	s7,24(sp)
    8000343e:	e862                	sd	s8,16(sp)
    80003440:	e466                	sd	s9,8(sp)
    80003442:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003444:	0001d797          	auipc	a5,0x1d
    80003448:	ec07a783          	lw	a5,-320(a5) # 80020304 <sb+0x4>
    8000344c:	cbd1                	beqz	a5,800034e0 <balloc+0xb6>
    8000344e:	8baa                	mv	s7,a0
    80003450:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003452:	0001db17          	auipc	s6,0x1d
    80003456:	eaeb0b13          	addi	s6,s6,-338 # 80020300 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000345c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003460:	6c89                	lui	s9,0x2
    80003462:	a831                	j	8000347e <balloc+0x54>
    brelse(bp);
    80003464:	854a                	mv	a0,s2
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	e32080e7          	jalr	-462(ra) # 80003298 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000346e:	015c87bb          	addw	a5,s9,s5
    80003472:	00078a9b          	sext.w	s5,a5
    80003476:	004b2703          	lw	a4,4(s6)
    8000347a:	06eaf363          	bgeu	s5,a4,800034e0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000347e:	41fad79b          	sraiw	a5,s5,0x1f
    80003482:	0137d79b          	srliw	a5,a5,0x13
    80003486:	015787bb          	addw	a5,a5,s5
    8000348a:	40d7d79b          	sraiw	a5,a5,0xd
    8000348e:	01cb2583          	lw	a1,28(s6)
    80003492:	9dbd                	addw	a1,a1,a5
    80003494:	855e                	mv	a0,s7
    80003496:	00000097          	auipc	ra,0x0
    8000349a:	cd2080e7          	jalr	-814(ra) # 80003168 <bread>
    8000349e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a0:	004b2503          	lw	a0,4(s6)
    800034a4:	000a849b          	sext.w	s1,s5
    800034a8:	8662                	mv	a2,s8
    800034aa:	faa4fde3          	bgeu	s1,a0,80003464 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034ae:	41f6579b          	sraiw	a5,a2,0x1f
    800034b2:	01d7d69b          	srliw	a3,a5,0x1d
    800034b6:	00c6873b          	addw	a4,a3,a2
    800034ba:	00777793          	andi	a5,a4,7
    800034be:	9f95                	subw	a5,a5,a3
    800034c0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034c4:	4037571b          	sraiw	a4,a4,0x3
    800034c8:	00e906b3          	add	a3,s2,a4
    800034cc:	0586c683          	lbu	a3,88(a3)
    800034d0:	00d7f5b3          	and	a1,a5,a3
    800034d4:	cd91                	beqz	a1,800034f0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d6:	2605                	addiw	a2,a2,1
    800034d8:	2485                	addiw	s1,s1,1
    800034da:	fd4618e3          	bne	a2,s4,800034aa <balloc+0x80>
    800034de:	b759                	j	80003464 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034e0:	00005517          	auipc	a0,0x5
    800034e4:	0d850513          	addi	a0,a0,216 # 800085b8 <syscalls+0x110>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	056080e7          	jalr	86(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034f0:	974a                	add	a4,a4,s2
    800034f2:	8fd5                	or	a5,a5,a3
    800034f4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034f8:	854a                	mv	a0,s2
    800034fa:	00001097          	auipc	ra,0x1
    800034fe:	01a080e7          	jalr	26(ra) # 80004514 <log_write>
        brelse(bp);
    80003502:	854a                	mv	a0,s2
    80003504:	00000097          	auipc	ra,0x0
    80003508:	d94080e7          	jalr	-620(ra) # 80003298 <brelse>
  bp = bread(dev, bno);
    8000350c:	85a6                	mv	a1,s1
    8000350e:	855e                	mv	a0,s7
    80003510:	00000097          	auipc	ra,0x0
    80003514:	c58080e7          	jalr	-936(ra) # 80003168 <bread>
    80003518:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000351a:	40000613          	li	a2,1024
    8000351e:	4581                	li	a1,0
    80003520:	05850513          	addi	a0,a0,88
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	7bc080e7          	jalr	1980(ra) # 80000ce0 <memset>
  log_write(bp);
    8000352c:	854a                	mv	a0,s2
    8000352e:	00001097          	auipc	ra,0x1
    80003532:	fe6080e7          	jalr	-26(ra) # 80004514 <log_write>
  brelse(bp);
    80003536:	854a                	mv	a0,s2
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	d60080e7          	jalr	-672(ra) # 80003298 <brelse>
}
    80003540:	8526                	mv	a0,s1
    80003542:	60e6                	ld	ra,88(sp)
    80003544:	6446                	ld	s0,80(sp)
    80003546:	64a6                	ld	s1,72(sp)
    80003548:	6906                	ld	s2,64(sp)
    8000354a:	79e2                	ld	s3,56(sp)
    8000354c:	7a42                	ld	s4,48(sp)
    8000354e:	7aa2                	ld	s5,40(sp)
    80003550:	7b02                	ld	s6,32(sp)
    80003552:	6be2                	ld	s7,24(sp)
    80003554:	6c42                	ld	s8,16(sp)
    80003556:	6ca2                	ld	s9,8(sp)
    80003558:	6125                	addi	sp,sp,96
    8000355a:	8082                	ret

000000008000355c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000355c:	7179                	addi	sp,sp,-48
    8000355e:	f406                	sd	ra,40(sp)
    80003560:	f022                	sd	s0,32(sp)
    80003562:	ec26                	sd	s1,24(sp)
    80003564:	e84a                	sd	s2,16(sp)
    80003566:	e44e                	sd	s3,8(sp)
    80003568:	e052                	sd	s4,0(sp)
    8000356a:	1800                	addi	s0,sp,48
    8000356c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000356e:	47ad                	li	a5,11
    80003570:	04b7fe63          	bgeu	a5,a1,800035cc <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003574:	ff45849b          	addiw	s1,a1,-12
    80003578:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000357c:	0ff00793          	li	a5,255
    80003580:	0ae7e363          	bltu	a5,a4,80003626 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003584:	08052583          	lw	a1,128(a0)
    80003588:	c5ad                	beqz	a1,800035f2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000358a:	00092503          	lw	a0,0(s2)
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	bda080e7          	jalr	-1062(ra) # 80003168 <bread>
    80003596:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003598:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000359c:	02049593          	slli	a1,s1,0x20
    800035a0:	9181                	srli	a1,a1,0x20
    800035a2:	058a                	slli	a1,a1,0x2
    800035a4:	00b784b3          	add	s1,a5,a1
    800035a8:	0004a983          	lw	s3,0(s1)
    800035ac:	04098d63          	beqz	s3,80003606 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035b0:	8552                	mv	a0,s4
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	ce6080e7          	jalr	-794(ra) # 80003298 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035ba:	854e                	mv	a0,s3
    800035bc:	70a2                	ld	ra,40(sp)
    800035be:	7402                	ld	s0,32(sp)
    800035c0:	64e2                	ld	s1,24(sp)
    800035c2:	6942                	ld	s2,16(sp)
    800035c4:	69a2                	ld	s3,8(sp)
    800035c6:	6a02                	ld	s4,0(sp)
    800035c8:	6145                	addi	sp,sp,48
    800035ca:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035cc:	02059493          	slli	s1,a1,0x20
    800035d0:	9081                	srli	s1,s1,0x20
    800035d2:	048a                	slli	s1,s1,0x2
    800035d4:	94aa                	add	s1,s1,a0
    800035d6:	0504a983          	lw	s3,80(s1)
    800035da:	fe0990e3          	bnez	s3,800035ba <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035de:	4108                	lw	a0,0(a0)
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	e4a080e7          	jalr	-438(ra) # 8000342a <balloc>
    800035e8:	0005099b          	sext.w	s3,a0
    800035ec:	0534a823          	sw	s3,80(s1)
    800035f0:	b7e9                	j	800035ba <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035f2:	4108                	lw	a0,0(a0)
    800035f4:	00000097          	auipc	ra,0x0
    800035f8:	e36080e7          	jalr	-458(ra) # 8000342a <balloc>
    800035fc:	0005059b          	sext.w	a1,a0
    80003600:	08b92023          	sw	a1,128(s2)
    80003604:	b759                	j	8000358a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003606:	00092503          	lw	a0,0(s2)
    8000360a:	00000097          	auipc	ra,0x0
    8000360e:	e20080e7          	jalr	-480(ra) # 8000342a <balloc>
    80003612:	0005099b          	sext.w	s3,a0
    80003616:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000361a:	8552                	mv	a0,s4
    8000361c:	00001097          	auipc	ra,0x1
    80003620:	ef8080e7          	jalr	-264(ra) # 80004514 <log_write>
    80003624:	b771                	j	800035b0 <bmap+0x54>
  panic("bmap: out of range");
    80003626:	00005517          	auipc	a0,0x5
    8000362a:	faa50513          	addi	a0,a0,-86 # 800085d0 <syscalls+0x128>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>

0000000080003636 <iget>:
{
    80003636:	7179                	addi	sp,sp,-48
    80003638:	f406                	sd	ra,40(sp)
    8000363a:	f022                	sd	s0,32(sp)
    8000363c:	ec26                	sd	s1,24(sp)
    8000363e:	e84a                	sd	s2,16(sp)
    80003640:	e44e                	sd	s3,8(sp)
    80003642:	e052                	sd	s4,0(sp)
    80003644:	1800                	addi	s0,sp,48
    80003646:	89aa                	mv	s3,a0
    80003648:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000364a:	0001d517          	auipc	a0,0x1d
    8000364e:	cd650513          	addi	a0,a0,-810 # 80020320 <itable>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	592080e7          	jalr	1426(ra) # 80000be4 <acquire>
  empty = 0;
    8000365a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000365c:	0001d497          	auipc	s1,0x1d
    80003660:	cdc48493          	addi	s1,s1,-804 # 80020338 <itable+0x18>
    80003664:	0001e697          	auipc	a3,0x1e
    80003668:	76468693          	addi	a3,a3,1892 # 80021dc8 <log>
    8000366c:	a039                	j	8000367a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000366e:	02090b63          	beqz	s2,800036a4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003672:	08848493          	addi	s1,s1,136
    80003676:	02d48a63          	beq	s1,a3,800036aa <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000367a:	449c                	lw	a5,8(s1)
    8000367c:	fef059e3          	blez	a5,8000366e <iget+0x38>
    80003680:	4098                	lw	a4,0(s1)
    80003682:	ff3716e3          	bne	a4,s3,8000366e <iget+0x38>
    80003686:	40d8                	lw	a4,4(s1)
    80003688:	ff4713e3          	bne	a4,s4,8000366e <iget+0x38>
      ip->ref++;
    8000368c:	2785                	addiw	a5,a5,1
    8000368e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003690:	0001d517          	auipc	a0,0x1d
    80003694:	c9050513          	addi	a0,a0,-880 # 80020320 <itable>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	600080e7          	jalr	1536(ra) # 80000c98 <release>
      return ip;
    800036a0:	8926                	mv	s2,s1
    800036a2:	a03d                	j	800036d0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036a4:	f7f9                	bnez	a5,80003672 <iget+0x3c>
    800036a6:	8926                	mv	s2,s1
    800036a8:	b7e9                	j	80003672 <iget+0x3c>
  if(empty == 0)
    800036aa:	02090c63          	beqz	s2,800036e2 <iget+0xac>
  ip->dev = dev;
    800036ae:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036b2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036b6:	4785                	li	a5,1
    800036b8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036bc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036c0:	0001d517          	auipc	a0,0x1d
    800036c4:	c6050513          	addi	a0,a0,-928 # 80020320 <itable>
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	5d0080e7          	jalr	1488(ra) # 80000c98 <release>
}
    800036d0:	854a                	mv	a0,s2
    800036d2:	70a2                	ld	ra,40(sp)
    800036d4:	7402                	ld	s0,32(sp)
    800036d6:	64e2                	ld	s1,24(sp)
    800036d8:	6942                	ld	s2,16(sp)
    800036da:	69a2                	ld	s3,8(sp)
    800036dc:	6a02                	ld	s4,0(sp)
    800036de:	6145                	addi	sp,sp,48
    800036e0:	8082                	ret
    panic("iget: no inodes");
    800036e2:	00005517          	auipc	a0,0x5
    800036e6:	f0650513          	addi	a0,a0,-250 # 800085e8 <syscalls+0x140>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	e54080e7          	jalr	-428(ra) # 8000053e <panic>

00000000800036f2 <fsinit>:
fsinit(int dev) {
    800036f2:	7179                	addi	sp,sp,-48
    800036f4:	f406                	sd	ra,40(sp)
    800036f6:	f022                	sd	s0,32(sp)
    800036f8:	ec26                	sd	s1,24(sp)
    800036fa:	e84a                	sd	s2,16(sp)
    800036fc:	e44e                	sd	s3,8(sp)
    800036fe:	1800                	addi	s0,sp,48
    80003700:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003702:	4585                	li	a1,1
    80003704:	00000097          	auipc	ra,0x0
    80003708:	a64080e7          	jalr	-1436(ra) # 80003168 <bread>
    8000370c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000370e:	0001d997          	auipc	s3,0x1d
    80003712:	bf298993          	addi	s3,s3,-1038 # 80020300 <sb>
    80003716:	02000613          	li	a2,32
    8000371a:	05850593          	addi	a1,a0,88
    8000371e:	854e                	mv	a0,s3
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	620080e7          	jalr	1568(ra) # 80000d40 <memmove>
  brelse(bp);
    80003728:	8526                	mv	a0,s1
    8000372a:	00000097          	auipc	ra,0x0
    8000372e:	b6e080e7          	jalr	-1170(ra) # 80003298 <brelse>
  if(sb.magic != FSMAGIC)
    80003732:	0009a703          	lw	a4,0(s3)
    80003736:	102037b7          	lui	a5,0x10203
    8000373a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000373e:	02f71263          	bne	a4,a5,80003762 <fsinit+0x70>
  initlog(dev, &sb);
    80003742:	0001d597          	auipc	a1,0x1d
    80003746:	bbe58593          	addi	a1,a1,-1090 # 80020300 <sb>
    8000374a:	854a                	mv	a0,s2
    8000374c:	00001097          	auipc	ra,0x1
    80003750:	b4c080e7          	jalr	-1204(ra) # 80004298 <initlog>
}
    80003754:	70a2                	ld	ra,40(sp)
    80003756:	7402                	ld	s0,32(sp)
    80003758:	64e2                	ld	s1,24(sp)
    8000375a:	6942                	ld	s2,16(sp)
    8000375c:	69a2                	ld	s3,8(sp)
    8000375e:	6145                	addi	sp,sp,48
    80003760:	8082                	ret
    panic("invalid file system");
    80003762:	00005517          	auipc	a0,0x5
    80003766:	e9650513          	addi	a0,a0,-362 # 800085f8 <syscalls+0x150>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	dd4080e7          	jalr	-556(ra) # 8000053e <panic>

0000000080003772 <iinit>:
{
    80003772:	7179                	addi	sp,sp,-48
    80003774:	f406                	sd	ra,40(sp)
    80003776:	f022                	sd	s0,32(sp)
    80003778:	ec26                	sd	s1,24(sp)
    8000377a:	e84a                	sd	s2,16(sp)
    8000377c:	e44e                	sd	s3,8(sp)
    8000377e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003780:	00005597          	auipc	a1,0x5
    80003784:	e9058593          	addi	a1,a1,-368 # 80008610 <syscalls+0x168>
    80003788:	0001d517          	auipc	a0,0x1d
    8000378c:	b9850513          	addi	a0,a0,-1128 # 80020320 <itable>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	3c4080e7          	jalr	964(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003798:	0001d497          	auipc	s1,0x1d
    8000379c:	bb048493          	addi	s1,s1,-1104 # 80020348 <itable+0x28>
    800037a0:	0001e997          	auipc	s3,0x1e
    800037a4:	63898993          	addi	s3,s3,1592 # 80021dd8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037a8:	00005917          	auipc	s2,0x5
    800037ac:	e7090913          	addi	s2,s2,-400 # 80008618 <syscalls+0x170>
    800037b0:	85ca                	mv	a1,s2
    800037b2:	8526                	mv	a0,s1
    800037b4:	00001097          	auipc	ra,0x1
    800037b8:	e46080e7          	jalr	-442(ra) # 800045fa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037bc:	08848493          	addi	s1,s1,136
    800037c0:	ff3498e3          	bne	s1,s3,800037b0 <iinit+0x3e>
}
    800037c4:	70a2                	ld	ra,40(sp)
    800037c6:	7402                	ld	s0,32(sp)
    800037c8:	64e2                	ld	s1,24(sp)
    800037ca:	6942                	ld	s2,16(sp)
    800037cc:	69a2                	ld	s3,8(sp)
    800037ce:	6145                	addi	sp,sp,48
    800037d0:	8082                	ret

00000000800037d2 <ialloc>:
{
    800037d2:	715d                	addi	sp,sp,-80
    800037d4:	e486                	sd	ra,72(sp)
    800037d6:	e0a2                	sd	s0,64(sp)
    800037d8:	fc26                	sd	s1,56(sp)
    800037da:	f84a                	sd	s2,48(sp)
    800037dc:	f44e                	sd	s3,40(sp)
    800037de:	f052                	sd	s4,32(sp)
    800037e0:	ec56                	sd	s5,24(sp)
    800037e2:	e85a                	sd	s6,16(sp)
    800037e4:	e45e                	sd	s7,8(sp)
    800037e6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037e8:	0001d717          	auipc	a4,0x1d
    800037ec:	b2472703          	lw	a4,-1244(a4) # 8002030c <sb+0xc>
    800037f0:	4785                	li	a5,1
    800037f2:	04e7fa63          	bgeu	a5,a4,80003846 <ialloc+0x74>
    800037f6:	8aaa                	mv	s5,a0
    800037f8:	8bae                	mv	s7,a1
    800037fa:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037fc:	0001da17          	auipc	s4,0x1d
    80003800:	b04a0a13          	addi	s4,s4,-1276 # 80020300 <sb>
    80003804:	00048b1b          	sext.w	s6,s1
    80003808:	0044d593          	srli	a1,s1,0x4
    8000380c:	018a2783          	lw	a5,24(s4)
    80003810:	9dbd                	addw	a1,a1,a5
    80003812:	8556                	mv	a0,s5
    80003814:	00000097          	auipc	ra,0x0
    80003818:	954080e7          	jalr	-1708(ra) # 80003168 <bread>
    8000381c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000381e:	05850993          	addi	s3,a0,88
    80003822:	00f4f793          	andi	a5,s1,15
    80003826:	079a                	slli	a5,a5,0x6
    80003828:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000382a:	00099783          	lh	a5,0(s3)
    8000382e:	c785                	beqz	a5,80003856 <ialloc+0x84>
    brelse(bp);
    80003830:	00000097          	auipc	ra,0x0
    80003834:	a68080e7          	jalr	-1432(ra) # 80003298 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003838:	0485                	addi	s1,s1,1
    8000383a:	00ca2703          	lw	a4,12(s4)
    8000383e:	0004879b          	sext.w	a5,s1
    80003842:	fce7e1e3          	bltu	a5,a4,80003804 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003846:	00005517          	auipc	a0,0x5
    8000384a:	dda50513          	addi	a0,a0,-550 # 80008620 <syscalls+0x178>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	cf0080e7          	jalr	-784(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003856:	04000613          	li	a2,64
    8000385a:	4581                	li	a1,0
    8000385c:	854e                	mv	a0,s3
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	482080e7          	jalr	1154(ra) # 80000ce0 <memset>
      dip->type = type;
    80003866:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000386a:	854a                	mv	a0,s2
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	ca8080e7          	jalr	-856(ra) # 80004514 <log_write>
      brelse(bp);
    80003874:	854a                	mv	a0,s2
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	a22080e7          	jalr	-1502(ra) # 80003298 <brelse>
      return iget(dev, inum);
    8000387e:	85da                	mv	a1,s6
    80003880:	8556                	mv	a0,s5
    80003882:	00000097          	auipc	ra,0x0
    80003886:	db4080e7          	jalr	-588(ra) # 80003636 <iget>
}
    8000388a:	60a6                	ld	ra,72(sp)
    8000388c:	6406                	ld	s0,64(sp)
    8000388e:	74e2                	ld	s1,56(sp)
    80003890:	7942                	ld	s2,48(sp)
    80003892:	79a2                	ld	s3,40(sp)
    80003894:	7a02                	ld	s4,32(sp)
    80003896:	6ae2                	ld	s5,24(sp)
    80003898:	6b42                	ld	s6,16(sp)
    8000389a:	6ba2                	ld	s7,8(sp)
    8000389c:	6161                	addi	sp,sp,80
    8000389e:	8082                	ret

00000000800038a0 <iupdate>:
{
    800038a0:	1101                	addi	sp,sp,-32
    800038a2:	ec06                	sd	ra,24(sp)
    800038a4:	e822                	sd	s0,16(sp)
    800038a6:	e426                	sd	s1,8(sp)
    800038a8:	e04a                	sd	s2,0(sp)
    800038aa:	1000                	addi	s0,sp,32
    800038ac:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ae:	415c                	lw	a5,4(a0)
    800038b0:	0047d79b          	srliw	a5,a5,0x4
    800038b4:	0001d597          	auipc	a1,0x1d
    800038b8:	a645a583          	lw	a1,-1436(a1) # 80020318 <sb+0x18>
    800038bc:	9dbd                	addw	a1,a1,a5
    800038be:	4108                	lw	a0,0(a0)
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	8a8080e7          	jalr	-1880(ra) # 80003168 <bread>
    800038c8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ca:	05850793          	addi	a5,a0,88
    800038ce:	40c8                	lw	a0,4(s1)
    800038d0:	893d                	andi	a0,a0,15
    800038d2:	051a                	slli	a0,a0,0x6
    800038d4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038d6:	04449703          	lh	a4,68(s1)
    800038da:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038de:	04649703          	lh	a4,70(s1)
    800038e2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038e6:	04849703          	lh	a4,72(s1)
    800038ea:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038ee:	04a49703          	lh	a4,74(s1)
    800038f2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038f6:	44f8                	lw	a4,76(s1)
    800038f8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038fa:	03400613          	li	a2,52
    800038fe:	05048593          	addi	a1,s1,80
    80003902:	0531                	addi	a0,a0,12
    80003904:	ffffd097          	auipc	ra,0xffffd
    80003908:	43c080e7          	jalr	1084(ra) # 80000d40 <memmove>
  log_write(bp);
    8000390c:	854a                	mv	a0,s2
    8000390e:	00001097          	auipc	ra,0x1
    80003912:	c06080e7          	jalr	-1018(ra) # 80004514 <log_write>
  brelse(bp);
    80003916:	854a                	mv	a0,s2
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	980080e7          	jalr	-1664(ra) # 80003298 <brelse>
}
    80003920:	60e2                	ld	ra,24(sp)
    80003922:	6442                	ld	s0,16(sp)
    80003924:	64a2                	ld	s1,8(sp)
    80003926:	6902                	ld	s2,0(sp)
    80003928:	6105                	addi	sp,sp,32
    8000392a:	8082                	ret

000000008000392c <idup>:
{
    8000392c:	1101                	addi	sp,sp,-32
    8000392e:	ec06                	sd	ra,24(sp)
    80003930:	e822                	sd	s0,16(sp)
    80003932:	e426                	sd	s1,8(sp)
    80003934:	1000                	addi	s0,sp,32
    80003936:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003938:	0001d517          	auipc	a0,0x1d
    8000393c:	9e850513          	addi	a0,a0,-1560 # 80020320 <itable>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	2a4080e7          	jalr	676(ra) # 80000be4 <acquire>
  ip->ref++;
    80003948:	449c                	lw	a5,8(s1)
    8000394a:	2785                	addiw	a5,a5,1
    8000394c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000394e:	0001d517          	auipc	a0,0x1d
    80003952:	9d250513          	addi	a0,a0,-1582 # 80020320 <itable>
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	342080e7          	jalr	834(ra) # 80000c98 <release>
}
    8000395e:	8526                	mv	a0,s1
    80003960:	60e2                	ld	ra,24(sp)
    80003962:	6442                	ld	s0,16(sp)
    80003964:	64a2                	ld	s1,8(sp)
    80003966:	6105                	addi	sp,sp,32
    80003968:	8082                	ret

000000008000396a <ilock>:
{
    8000396a:	1101                	addi	sp,sp,-32
    8000396c:	ec06                	sd	ra,24(sp)
    8000396e:	e822                	sd	s0,16(sp)
    80003970:	e426                	sd	s1,8(sp)
    80003972:	e04a                	sd	s2,0(sp)
    80003974:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003976:	c115                	beqz	a0,8000399a <ilock+0x30>
    80003978:	84aa                	mv	s1,a0
    8000397a:	451c                	lw	a5,8(a0)
    8000397c:	00f05f63          	blez	a5,8000399a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003980:	0541                	addi	a0,a0,16
    80003982:	00001097          	auipc	ra,0x1
    80003986:	cb2080e7          	jalr	-846(ra) # 80004634 <acquiresleep>
  if(ip->valid == 0){
    8000398a:	40bc                	lw	a5,64(s1)
    8000398c:	cf99                	beqz	a5,800039aa <ilock+0x40>
}
    8000398e:	60e2                	ld	ra,24(sp)
    80003990:	6442                	ld	s0,16(sp)
    80003992:	64a2                	ld	s1,8(sp)
    80003994:	6902                	ld	s2,0(sp)
    80003996:	6105                	addi	sp,sp,32
    80003998:	8082                	ret
    panic("ilock");
    8000399a:	00005517          	auipc	a0,0x5
    8000399e:	c9e50513          	addi	a0,a0,-866 # 80008638 <syscalls+0x190>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	b9c080e7          	jalr	-1124(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039aa:	40dc                	lw	a5,4(s1)
    800039ac:	0047d79b          	srliw	a5,a5,0x4
    800039b0:	0001d597          	auipc	a1,0x1d
    800039b4:	9685a583          	lw	a1,-1688(a1) # 80020318 <sb+0x18>
    800039b8:	9dbd                	addw	a1,a1,a5
    800039ba:	4088                	lw	a0,0(s1)
    800039bc:	fffff097          	auipc	ra,0xfffff
    800039c0:	7ac080e7          	jalr	1964(ra) # 80003168 <bread>
    800039c4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039c6:	05850593          	addi	a1,a0,88
    800039ca:	40dc                	lw	a5,4(s1)
    800039cc:	8bbd                	andi	a5,a5,15
    800039ce:	079a                	slli	a5,a5,0x6
    800039d0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039d2:	00059783          	lh	a5,0(a1)
    800039d6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039da:	00259783          	lh	a5,2(a1)
    800039de:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039e2:	00459783          	lh	a5,4(a1)
    800039e6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039ea:	00659783          	lh	a5,6(a1)
    800039ee:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039f2:	459c                	lw	a5,8(a1)
    800039f4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039f6:	03400613          	li	a2,52
    800039fa:	05b1                	addi	a1,a1,12
    800039fc:	05048513          	addi	a0,s1,80
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	340080e7          	jalr	832(ra) # 80000d40 <memmove>
    brelse(bp);
    80003a08:	854a                	mv	a0,s2
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	88e080e7          	jalr	-1906(ra) # 80003298 <brelse>
    ip->valid = 1;
    80003a12:	4785                	li	a5,1
    80003a14:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a16:	04449783          	lh	a5,68(s1)
    80003a1a:	fbb5                	bnez	a5,8000398e <ilock+0x24>
      panic("ilock: no type");
    80003a1c:	00005517          	auipc	a0,0x5
    80003a20:	c2450513          	addi	a0,a0,-988 # 80008640 <syscalls+0x198>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	b1a080e7          	jalr	-1254(ra) # 8000053e <panic>

0000000080003a2c <iunlock>:
{
    80003a2c:	1101                	addi	sp,sp,-32
    80003a2e:	ec06                	sd	ra,24(sp)
    80003a30:	e822                	sd	s0,16(sp)
    80003a32:	e426                	sd	s1,8(sp)
    80003a34:	e04a                	sd	s2,0(sp)
    80003a36:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a38:	c905                	beqz	a0,80003a68 <iunlock+0x3c>
    80003a3a:	84aa                	mv	s1,a0
    80003a3c:	01050913          	addi	s2,a0,16
    80003a40:	854a                	mv	a0,s2
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	c8c080e7          	jalr	-884(ra) # 800046ce <holdingsleep>
    80003a4a:	cd19                	beqz	a0,80003a68 <iunlock+0x3c>
    80003a4c:	449c                	lw	a5,8(s1)
    80003a4e:	00f05d63          	blez	a5,80003a68 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a52:	854a                	mv	a0,s2
    80003a54:	00001097          	auipc	ra,0x1
    80003a58:	c36080e7          	jalr	-970(ra) # 8000468a <releasesleep>
}
    80003a5c:	60e2                	ld	ra,24(sp)
    80003a5e:	6442                	ld	s0,16(sp)
    80003a60:	64a2                	ld	s1,8(sp)
    80003a62:	6902                	ld	s2,0(sp)
    80003a64:	6105                	addi	sp,sp,32
    80003a66:	8082                	ret
    panic("iunlock");
    80003a68:	00005517          	auipc	a0,0x5
    80003a6c:	be850513          	addi	a0,a0,-1048 # 80008650 <syscalls+0x1a8>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	ace080e7          	jalr	-1330(ra) # 8000053e <panic>

0000000080003a78 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a78:	7179                	addi	sp,sp,-48
    80003a7a:	f406                	sd	ra,40(sp)
    80003a7c:	f022                	sd	s0,32(sp)
    80003a7e:	ec26                	sd	s1,24(sp)
    80003a80:	e84a                	sd	s2,16(sp)
    80003a82:	e44e                	sd	s3,8(sp)
    80003a84:	e052                	sd	s4,0(sp)
    80003a86:	1800                	addi	s0,sp,48
    80003a88:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a8a:	05050493          	addi	s1,a0,80
    80003a8e:	08050913          	addi	s2,a0,128
    80003a92:	a021                	j	80003a9a <itrunc+0x22>
    80003a94:	0491                	addi	s1,s1,4
    80003a96:	01248d63          	beq	s1,s2,80003ab0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a9a:	408c                	lw	a1,0(s1)
    80003a9c:	dde5                	beqz	a1,80003a94 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a9e:	0009a503          	lw	a0,0(s3)
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	90c080e7          	jalr	-1780(ra) # 800033ae <bfree>
      ip->addrs[i] = 0;
    80003aaa:	0004a023          	sw	zero,0(s1)
    80003aae:	b7dd                	j	80003a94 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ab0:	0809a583          	lw	a1,128(s3)
    80003ab4:	e185                	bnez	a1,80003ad4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ab6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003aba:	854e                	mv	a0,s3
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	de4080e7          	jalr	-540(ra) # 800038a0 <iupdate>
}
    80003ac4:	70a2                	ld	ra,40(sp)
    80003ac6:	7402                	ld	s0,32(sp)
    80003ac8:	64e2                	ld	s1,24(sp)
    80003aca:	6942                	ld	s2,16(sp)
    80003acc:	69a2                	ld	s3,8(sp)
    80003ace:	6a02                	ld	s4,0(sp)
    80003ad0:	6145                	addi	sp,sp,48
    80003ad2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ad4:	0009a503          	lw	a0,0(s3)
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	690080e7          	jalr	1680(ra) # 80003168 <bread>
    80003ae0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ae2:	05850493          	addi	s1,a0,88
    80003ae6:	45850913          	addi	s2,a0,1112
    80003aea:	a811                	j	80003afe <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003aec:	0009a503          	lw	a0,0(s3)
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	8be080e7          	jalr	-1858(ra) # 800033ae <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003af8:	0491                	addi	s1,s1,4
    80003afa:	01248563          	beq	s1,s2,80003b04 <itrunc+0x8c>
      if(a[j])
    80003afe:	408c                	lw	a1,0(s1)
    80003b00:	dde5                	beqz	a1,80003af8 <itrunc+0x80>
    80003b02:	b7ed                	j	80003aec <itrunc+0x74>
    brelse(bp);
    80003b04:	8552                	mv	a0,s4
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	792080e7          	jalr	1938(ra) # 80003298 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b0e:	0809a583          	lw	a1,128(s3)
    80003b12:	0009a503          	lw	a0,0(s3)
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	898080e7          	jalr	-1896(ra) # 800033ae <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b1e:	0809a023          	sw	zero,128(s3)
    80003b22:	bf51                	j	80003ab6 <itrunc+0x3e>

0000000080003b24 <iput>:
{
    80003b24:	1101                	addi	sp,sp,-32
    80003b26:	ec06                	sd	ra,24(sp)
    80003b28:	e822                	sd	s0,16(sp)
    80003b2a:	e426                	sd	s1,8(sp)
    80003b2c:	e04a                	sd	s2,0(sp)
    80003b2e:	1000                	addi	s0,sp,32
    80003b30:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b32:	0001c517          	auipc	a0,0x1c
    80003b36:	7ee50513          	addi	a0,a0,2030 # 80020320 <itable>
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	0aa080e7          	jalr	170(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b42:	4498                	lw	a4,8(s1)
    80003b44:	4785                	li	a5,1
    80003b46:	02f70363          	beq	a4,a5,80003b6c <iput+0x48>
  ip->ref--;
    80003b4a:	449c                	lw	a5,8(s1)
    80003b4c:	37fd                	addiw	a5,a5,-1
    80003b4e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b50:	0001c517          	auipc	a0,0x1c
    80003b54:	7d050513          	addi	a0,a0,2000 # 80020320 <itable>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	140080e7          	jalr	320(ra) # 80000c98 <release>
}
    80003b60:	60e2                	ld	ra,24(sp)
    80003b62:	6442                	ld	s0,16(sp)
    80003b64:	64a2                	ld	s1,8(sp)
    80003b66:	6902                	ld	s2,0(sp)
    80003b68:	6105                	addi	sp,sp,32
    80003b6a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b6c:	40bc                	lw	a5,64(s1)
    80003b6e:	dff1                	beqz	a5,80003b4a <iput+0x26>
    80003b70:	04a49783          	lh	a5,74(s1)
    80003b74:	fbf9                	bnez	a5,80003b4a <iput+0x26>
    acquiresleep(&ip->lock);
    80003b76:	01048913          	addi	s2,s1,16
    80003b7a:	854a                	mv	a0,s2
    80003b7c:	00001097          	auipc	ra,0x1
    80003b80:	ab8080e7          	jalr	-1352(ra) # 80004634 <acquiresleep>
    release(&itable.lock);
    80003b84:	0001c517          	auipc	a0,0x1c
    80003b88:	79c50513          	addi	a0,a0,1948 # 80020320 <itable>
    80003b8c:	ffffd097          	auipc	ra,0xffffd
    80003b90:	10c080e7          	jalr	268(ra) # 80000c98 <release>
    itrunc(ip);
    80003b94:	8526                	mv	a0,s1
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	ee2080e7          	jalr	-286(ra) # 80003a78 <itrunc>
    ip->type = 0;
    80003b9e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ba2:	8526                	mv	a0,s1
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	cfc080e7          	jalr	-772(ra) # 800038a0 <iupdate>
    ip->valid = 0;
    80003bac:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bb0:	854a                	mv	a0,s2
    80003bb2:	00001097          	auipc	ra,0x1
    80003bb6:	ad8080e7          	jalr	-1320(ra) # 8000468a <releasesleep>
    acquire(&itable.lock);
    80003bba:	0001c517          	auipc	a0,0x1c
    80003bbe:	76650513          	addi	a0,a0,1894 # 80020320 <itable>
    80003bc2:	ffffd097          	auipc	ra,0xffffd
    80003bc6:	022080e7          	jalr	34(ra) # 80000be4 <acquire>
    80003bca:	b741                	j	80003b4a <iput+0x26>

0000000080003bcc <iunlockput>:
{
    80003bcc:	1101                	addi	sp,sp,-32
    80003bce:	ec06                	sd	ra,24(sp)
    80003bd0:	e822                	sd	s0,16(sp)
    80003bd2:	e426                	sd	s1,8(sp)
    80003bd4:	1000                	addi	s0,sp,32
    80003bd6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	e54080e7          	jalr	-428(ra) # 80003a2c <iunlock>
  iput(ip);
    80003be0:	8526                	mv	a0,s1
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	f42080e7          	jalr	-190(ra) # 80003b24 <iput>
}
    80003bea:	60e2                	ld	ra,24(sp)
    80003bec:	6442                	ld	s0,16(sp)
    80003bee:	64a2                	ld	s1,8(sp)
    80003bf0:	6105                	addi	sp,sp,32
    80003bf2:	8082                	ret

0000000080003bf4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bf4:	1141                	addi	sp,sp,-16
    80003bf6:	e422                	sd	s0,8(sp)
    80003bf8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bfa:	411c                	lw	a5,0(a0)
    80003bfc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bfe:	415c                	lw	a5,4(a0)
    80003c00:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c02:	04451783          	lh	a5,68(a0)
    80003c06:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c0a:	04a51783          	lh	a5,74(a0)
    80003c0e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c12:	04c56783          	lwu	a5,76(a0)
    80003c16:	e99c                	sd	a5,16(a1)
}
    80003c18:	6422                	ld	s0,8(sp)
    80003c1a:	0141                	addi	sp,sp,16
    80003c1c:	8082                	ret

0000000080003c1e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c1e:	457c                	lw	a5,76(a0)
    80003c20:	0ed7e963          	bltu	a5,a3,80003d12 <readi+0xf4>
{
    80003c24:	7159                	addi	sp,sp,-112
    80003c26:	f486                	sd	ra,104(sp)
    80003c28:	f0a2                	sd	s0,96(sp)
    80003c2a:	eca6                	sd	s1,88(sp)
    80003c2c:	e8ca                	sd	s2,80(sp)
    80003c2e:	e4ce                	sd	s3,72(sp)
    80003c30:	e0d2                	sd	s4,64(sp)
    80003c32:	fc56                	sd	s5,56(sp)
    80003c34:	f85a                	sd	s6,48(sp)
    80003c36:	f45e                	sd	s7,40(sp)
    80003c38:	f062                	sd	s8,32(sp)
    80003c3a:	ec66                	sd	s9,24(sp)
    80003c3c:	e86a                	sd	s10,16(sp)
    80003c3e:	e46e                	sd	s11,8(sp)
    80003c40:	1880                	addi	s0,sp,112
    80003c42:	8baa                	mv	s7,a0
    80003c44:	8c2e                	mv	s8,a1
    80003c46:	8ab2                	mv	s5,a2
    80003c48:	84b6                	mv	s1,a3
    80003c4a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c4c:	9f35                	addw	a4,a4,a3
    return 0;
    80003c4e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c50:	0ad76063          	bltu	a4,a3,80003cf0 <readi+0xd2>
  if(off + n > ip->size)
    80003c54:	00e7f463          	bgeu	a5,a4,80003c5c <readi+0x3e>
    n = ip->size - off;
    80003c58:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c5c:	0a0b0963          	beqz	s6,80003d0e <readi+0xf0>
    80003c60:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c62:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c66:	5cfd                	li	s9,-1
    80003c68:	a82d                	j	80003ca2 <readi+0x84>
    80003c6a:	020a1d93          	slli	s11,s4,0x20
    80003c6e:	020ddd93          	srli	s11,s11,0x20
    80003c72:	05890613          	addi	a2,s2,88
    80003c76:	86ee                	mv	a3,s11
    80003c78:	963a                	add	a2,a2,a4
    80003c7a:	85d6                	mv	a1,s5
    80003c7c:	8562                	mv	a0,s8
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	ae4080e7          	jalr	-1308(ra) # 80002762 <either_copyout>
    80003c86:	05950d63          	beq	a0,s9,80003ce0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c8a:	854a                	mv	a0,s2
    80003c8c:	fffff097          	auipc	ra,0xfffff
    80003c90:	60c080e7          	jalr	1548(ra) # 80003298 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c94:	013a09bb          	addw	s3,s4,s3
    80003c98:	009a04bb          	addw	s1,s4,s1
    80003c9c:	9aee                	add	s5,s5,s11
    80003c9e:	0569f763          	bgeu	s3,s6,80003cec <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ca2:	000ba903          	lw	s2,0(s7)
    80003ca6:	00a4d59b          	srliw	a1,s1,0xa
    80003caa:	855e                	mv	a0,s7
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	8b0080e7          	jalr	-1872(ra) # 8000355c <bmap>
    80003cb4:	0005059b          	sext.w	a1,a0
    80003cb8:	854a                	mv	a0,s2
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	4ae080e7          	jalr	1198(ra) # 80003168 <bread>
    80003cc2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc4:	3ff4f713          	andi	a4,s1,1023
    80003cc8:	40ed07bb          	subw	a5,s10,a4
    80003ccc:	413b06bb          	subw	a3,s6,s3
    80003cd0:	8a3e                	mv	s4,a5
    80003cd2:	2781                	sext.w	a5,a5
    80003cd4:	0006861b          	sext.w	a2,a3
    80003cd8:	f8f679e3          	bgeu	a2,a5,80003c6a <readi+0x4c>
    80003cdc:	8a36                	mv	s4,a3
    80003cde:	b771                	j	80003c6a <readi+0x4c>
      brelse(bp);
    80003ce0:	854a                	mv	a0,s2
    80003ce2:	fffff097          	auipc	ra,0xfffff
    80003ce6:	5b6080e7          	jalr	1462(ra) # 80003298 <brelse>
      tot = -1;
    80003cea:	59fd                	li	s3,-1
  }
  return tot;
    80003cec:	0009851b          	sext.w	a0,s3
}
    80003cf0:	70a6                	ld	ra,104(sp)
    80003cf2:	7406                	ld	s0,96(sp)
    80003cf4:	64e6                	ld	s1,88(sp)
    80003cf6:	6946                	ld	s2,80(sp)
    80003cf8:	69a6                	ld	s3,72(sp)
    80003cfa:	6a06                	ld	s4,64(sp)
    80003cfc:	7ae2                	ld	s5,56(sp)
    80003cfe:	7b42                	ld	s6,48(sp)
    80003d00:	7ba2                	ld	s7,40(sp)
    80003d02:	7c02                	ld	s8,32(sp)
    80003d04:	6ce2                	ld	s9,24(sp)
    80003d06:	6d42                	ld	s10,16(sp)
    80003d08:	6da2                	ld	s11,8(sp)
    80003d0a:	6165                	addi	sp,sp,112
    80003d0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d0e:	89da                	mv	s3,s6
    80003d10:	bff1                	j	80003cec <readi+0xce>
    return 0;
    80003d12:	4501                	li	a0,0
}
    80003d14:	8082                	ret

0000000080003d16 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d16:	457c                	lw	a5,76(a0)
    80003d18:	10d7e863          	bltu	a5,a3,80003e28 <writei+0x112>
{
    80003d1c:	7159                	addi	sp,sp,-112
    80003d1e:	f486                	sd	ra,104(sp)
    80003d20:	f0a2                	sd	s0,96(sp)
    80003d22:	eca6                	sd	s1,88(sp)
    80003d24:	e8ca                	sd	s2,80(sp)
    80003d26:	e4ce                	sd	s3,72(sp)
    80003d28:	e0d2                	sd	s4,64(sp)
    80003d2a:	fc56                	sd	s5,56(sp)
    80003d2c:	f85a                	sd	s6,48(sp)
    80003d2e:	f45e                	sd	s7,40(sp)
    80003d30:	f062                	sd	s8,32(sp)
    80003d32:	ec66                	sd	s9,24(sp)
    80003d34:	e86a                	sd	s10,16(sp)
    80003d36:	e46e                	sd	s11,8(sp)
    80003d38:	1880                	addi	s0,sp,112
    80003d3a:	8b2a                	mv	s6,a0
    80003d3c:	8c2e                	mv	s8,a1
    80003d3e:	8ab2                	mv	s5,a2
    80003d40:	8936                	mv	s2,a3
    80003d42:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d44:	00e687bb          	addw	a5,a3,a4
    80003d48:	0ed7e263          	bltu	a5,a3,80003e2c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d4c:	00043737          	lui	a4,0x43
    80003d50:	0ef76063          	bltu	a4,a5,80003e30 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d54:	0c0b8863          	beqz	s7,80003e24 <writei+0x10e>
    80003d58:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d5a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d5e:	5cfd                	li	s9,-1
    80003d60:	a091                	j	80003da4 <writei+0x8e>
    80003d62:	02099d93          	slli	s11,s3,0x20
    80003d66:	020ddd93          	srli	s11,s11,0x20
    80003d6a:	05848513          	addi	a0,s1,88
    80003d6e:	86ee                	mv	a3,s11
    80003d70:	8656                	mv	a2,s5
    80003d72:	85e2                	mv	a1,s8
    80003d74:	953a                	add	a0,a0,a4
    80003d76:	fffff097          	auipc	ra,0xfffff
    80003d7a:	a42080e7          	jalr	-1470(ra) # 800027b8 <either_copyin>
    80003d7e:	07950263          	beq	a0,s9,80003de2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d82:	8526                	mv	a0,s1
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	790080e7          	jalr	1936(ra) # 80004514 <log_write>
    brelse(bp);
    80003d8c:	8526                	mv	a0,s1
    80003d8e:	fffff097          	auipc	ra,0xfffff
    80003d92:	50a080e7          	jalr	1290(ra) # 80003298 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d96:	01498a3b          	addw	s4,s3,s4
    80003d9a:	0129893b          	addw	s2,s3,s2
    80003d9e:	9aee                	add	s5,s5,s11
    80003da0:	057a7663          	bgeu	s4,s7,80003dec <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003da4:	000b2483          	lw	s1,0(s6)
    80003da8:	00a9559b          	srliw	a1,s2,0xa
    80003dac:	855a                	mv	a0,s6
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	7ae080e7          	jalr	1966(ra) # 8000355c <bmap>
    80003db6:	0005059b          	sext.w	a1,a0
    80003dba:	8526                	mv	a0,s1
    80003dbc:	fffff097          	auipc	ra,0xfffff
    80003dc0:	3ac080e7          	jalr	940(ra) # 80003168 <bread>
    80003dc4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dc6:	3ff97713          	andi	a4,s2,1023
    80003dca:	40ed07bb          	subw	a5,s10,a4
    80003dce:	414b86bb          	subw	a3,s7,s4
    80003dd2:	89be                	mv	s3,a5
    80003dd4:	2781                	sext.w	a5,a5
    80003dd6:	0006861b          	sext.w	a2,a3
    80003dda:	f8f674e3          	bgeu	a2,a5,80003d62 <writei+0x4c>
    80003dde:	89b6                	mv	s3,a3
    80003de0:	b749                	j	80003d62 <writei+0x4c>
      brelse(bp);
    80003de2:	8526                	mv	a0,s1
    80003de4:	fffff097          	auipc	ra,0xfffff
    80003de8:	4b4080e7          	jalr	1204(ra) # 80003298 <brelse>
  }

  if(off > ip->size)
    80003dec:	04cb2783          	lw	a5,76(s6)
    80003df0:	0127f463          	bgeu	a5,s2,80003df8 <writei+0xe2>
    ip->size = off;
    80003df4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003df8:	855a                	mv	a0,s6
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	aa6080e7          	jalr	-1370(ra) # 800038a0 <iupdate>

  return tot;
    80003e02:	000a051b          	sext.w	a0,s4
}
    80003e06:	70a6                	ld	ra,104(sp)
    80003e08:	7406                	ld	s0,96(sp)
    80003e0a:	64e6                	ld	s1,88(sp)
    80003e0c:	6946                	ld	s2,80(sp)
    80003e0e:	69a6                	ld	s3,72(sp)
    80003e10:	6a06                	ld	s4,64(sp)
    80003e12:	7ae2                	ld	s5,56(sp)
    80003e14:	7b42                	ld	s6,48(sp)
    80003e16:	7ba2                	ld	s7,40(sp)
    80003e18:	7c02                	ld	s8,32(sp)
    80003e1a:	6ce2                	ld	s9,24(sp)
    80003e1c:	6d42                	ld	s10,16(sp)
    80003e1e:	6da2                	ld	s11,8(sp)
    80003e20:	6165                	addi	sp,sp,112
    80003e22:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e24:	8a5e                	mv	s4,s7
    80003e26:	bfc9                	j	80003df8 <writei+0xe2>
    return -1;
    80003e28:	557d                	li	a0,-1
}
    80003e2a:	8082                	ret
    return -1;
    80003e2c:	557d                	li	a0,-1
    80003e2e:	bfe1                	j	80003e06 <writei+0xf0>
    return -1;
    80003e30:	557d                	li	a0,-1
    80003e32:	bfd1                	j	80003e06 <writei+0xf0>

0000000080003e34 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e34:	1141                	addi	sp,sp,-16
    80003e36:	e406                	sd	ra,8(sp)
    80003e38:	e022                	sd	s0,0(sp)
    80003e3a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e3c:	4639                	li	a2,14
    80003e3e:	ffffd097          	auipc	ra,0xffffd
    80003e42:	f7a080e7          	jalr	-134(ra) # 80000db8 <strncmp>
}
    80003e46:	60a2                	ld	ra,8(sp)
    80003e48:	6402                	ld	s0,0(sp)
    80003e4a:	0141                	addi	sp,sp,16
    80003e4c:	8082                	ret

0000000080003e4e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e4e:	7139                	addi	sp,sp,-64
    80003e50:	fc06                	sd	ra,56(sp)
    80003e52:	f822                	sd	s0,48(sp)
    80003e54:	f426                	sd	s1,40(sp)
    80003e56:	f04a                	sd	s2,32(sp)
    80003e58:	ec4e                	sd	s3,24(sp)
    80003e5a:	e852                	sd	s4,16(sp)
    80003e5c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e5e:	04451703          	lh	a4,68(a0)
    80003e62:	4785                	li	a5,1
    80003e64:	00f71a63          	bne	a4,a5,80003e78 <dirlookup+0x2a>
    80003e68:	892a                	mv	s2,a0
    80003e6a:	89ae                	mv	s3,a1
    80003e6c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6e:	457c                	lw	a5,76(a0)
    80003e70:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e72:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e74:	e79d                	bnez	a5,80003ea2 <dirlookup+0x54>
    80003e76:	a8a5                	j	80003eee <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e78:	00004517          	auipc	a0,0x4
    80003e7c:	7e050513          	addi	a0,a0,2016 # 80008658 <syscalls+0x1b0>
    80003e80:	ffffc097          	auipc	ra,0xffffc
    80003e84:	6be080e7          	jalr	1726(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e88:	00004517          	auipc	a0,0x4
    80003e8c:	7e850513          	addi	a0,a0,2024 # 80008670 <syscalls+0x1c8>
    80003e90:	ffffc097          	auipc	ra,0xffffc
    80003e94:	6ae080e7          	jalr	1710(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e98:	24c1                	addiw	s1,s1,16
    80003e9a:	04c92783          	lw	a5,76(s2)
    80003e9e:	04f4f763          	bgeu	s1,a5,80003eec <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea2:	4741                	li	a4,16
    80003ea4:	86a6                	mv	a3,s1
    80003ea6:	fc040613          	addi	a2,s0,-64
    80003eaa:	4581                	li	a1,0
    80003eac:	854a                	mv	a0,s2
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	d70080e7          	jalr	-656(ra) # 80003c1e <readi>
    80003eb6:	47c1                	li	a5,16
    80003eb8:	fcf518e3          	bne	a0,a5,80003e88 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ebc:	fc045783          	lhu	a5,-64(s0)
    80003ec0:	dfe1                	beqz	a5,80003e98 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ec2:	fc240593          	addi	a1,s0,-62
    80003ec6:	854e                	mv	a0,s3
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	f6c080e7          	jalr	-148(ra) # 80003e34 <namecmp>
    80003ed0:	f561                	bnez	a0,80003e98 <dirlookup+0x4a>
      if(poff)
    80003ed2:	000a0463          	beqz	s4,80003eda <dirlookup+0x8c>
        *poff = off;
    80003ed6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003eda:	fc045583          	lhu	a1,-64(s0)
    80003ede:	00092503          	lw	a0,0(s2)
    80003ee2:	fffff097          	auipc	ra,0xfffff
    80003ee6:	754080e7          	jalr	1876(ra) # 80003636 <iget>
    80003eea:	a011                	j	80003eee <dirlookup+0xa0>
  return 0;
    80003eec:	4501                	li	a0,0
}
    80003eee:	70e2                	ld	ra,56(sp)
    80003ef0:	7442                	ld	s0,48(sp)
    80003ef2:	74a2                	ld	s1,40(sp)
    80003ef4:	7902                	ld	s2,32(sp)
    80003ef6:	69e2                	ld	s3,24(sp)
    80003ef8:	6a42                	ld	s4,16(sp)
    80003efa:	6121                	addi	sp,sp,64
    80003efc:	8082                	ret

0000000080003efe <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003efe:	711d                	addi	sp,sp,-96
    80003f00:	ec86                	sd	ra,88(sp)
    80003f02:	e8a2                	sd	s0,80(sp)
    80003f04:	e4a6                	sd	s1,72(sp)
    80003f06:	e0ca                	sd	s2,64(sp)
    80003f08:	fc4e                	sd	s3,56(sp)
    80003f0a:	f852                	sd	s4,48(sp)
    80003f0c:	f456                	sd	s5,40(sp)
    80003f0e:	f05a                	sd	s6,32(sp)
    80003f10:	ec5e                	sd	s7,24(sp)
    80003f12:	e862                	sd	s8,16(sp)
    80003f14:	e466                	sd	s9,8(sp)
    80003f16:	1080                	addi	s0,sp,96
    80003f18:	84aa                	mv	s1,a0
    80003f1a:	8b2e                	mv	s6,a1
    80003f1c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f1e:	00054703          	lbu	a4,0(a0)
    80003f22:	02f00793          	li	a5,47
    80003f26:	02f70363          	beq	a4,a5,80003f4c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f2a:	ffffe097          	auipc	ra,0xffffe
    80003f2e:	d4e080e7          	jalr	-690(ra) # 80001c78 <myproc>
    80003f32:	17853503          	ld	a0,376(a0)
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	9f6080e7          	jalr	-1546(ra) # 8000392c <idup>
    80003f3e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f40:	02f00913          	li	s2,47
  len = path - s;
    80003f44:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f46:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f48:	4c05                	li	s8,1
    80003f4a:	a865                	j	80004002 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f4c:	4585                	li	a1,1
    80003f4e:	4505                	li	a0,1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	6e6080e7          	jalr	1766(ra) # 80003636 <iget>
    80003f58:	89aa                	mv	s3,a0
    80003f5a:	b7dd                	j	80003f40 <namex+0x42>
      iunlockput(ip);
    80003f5c:	854e                	mv	a0,s3
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	c6e080e7          	jalr	-914(ra) # 80003bcc <iunlockput>
      return 0;
    80003f66:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f68:	854e                	mv	a0,s3
    80003f6a:	60e6                	ld	ra,88(sp)
    80003f6c:	6446                	ld	s0,80(sp)
    80003f6e:	64a6                	ld	s1,72(sp)
    80003f70:	6906                	ld	s2,64(sp)
    80003f72:	79e2                	ld	s3,56(sp)
    80003f74:	7a42                	ld	s4,48(sp)
    80003f76:	7aa2                	ld	s5,40(sp)
    80003f78:	7b02                	ld	s6,32(sp)
    80003f7a:	6be2                	ld	s7,24(sp)
    80003f7c:	6c42                	ld	s8,16(sp)
    80003f7e:	6ca2                	ld	s9,8(sp)
    80003f80:	6125                	addi	sp,sp,96
    80003f82:	8082                	ret
      iunlock(ip);
    80003f84:	854e                	mv	a0,s3
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	aa6080e7          	jalr	-1370(ra) # 80003a2c <iunlock>
      return ip;
    80003f8e:	bfe9                	j	80003f68 <namex+0x6a>
      iunlockput(ip);
    80003f90:	854e                	mv	a0,s3
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	c3a080e7          	jalr	-966(ra) # 80003bcc <iunlockput>
      return 0;
    80003f9a:	89d2                	mv	s3,s4
    80003f9c:	b7f1                	j	80003f68 <namex+0x6a>
  len = path - s;
    80003f9e:	40b48633          	sub	a2,s1,a1
    80003fa2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fa6:	094cd463          	bge	s9,s4,8000402e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003faa:	4639                	li	a2,14
    80003fac:	8556                	mv	a0,s5
    80003fae:	ffffd097          	auipc	ra,0xffffd
    80003fb2:	d92080e7          	jalr	-622(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003fb6:	0004c783          	lbu	a5,0(s1)
    80003fba:	01279763          	bne	a5,s2,80003fc8 <namex+0xca>
    path++;
    80003fbe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fc0:	0004c783          	lbu	a5,0(s1)
    80003fc4:	ff278de3          	beq	a5,s2,80003fbe <namex+0xc0>
    ilock(ip);
    80003fc8:	854e                	mv	a0,s3
    80003fca:	00000097          	auipc	ra,0x0
    80003fce:	9a0080e7          	jalr	-1632(ra) # 8000396a <ilock>
    if(ip->type != T_DIR){
    80003fd2:	04499783          	lh	a5,68(s3)
    80003fd6:	f98793e3          	bne	a5,s8,80003f5c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fda:	000b0563          	beqz	s6,80003fe4 <namex+0xe6>
    80003fde:	0004c783          	lbu	a5,0(s1)
    80003fe2:	d3cd                	beqz	a5,80003f84 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fe4:	865e                	mv	a2,s7
    80003fe6:	85d6                	mv	a1,s5
    80003fe8:	854e                	mv	a0,s3
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	e64080e7          	jalr	-412(ra) # 80003e4e <dirlookup>
    80003ff2:	8a2a                	mv	s4,a0
    80003ff4:	dd51                	beqz	a0,80003f90 <namex+0x92>
    iunlockput(ip);
    80003ff6:	854e                	mv	a0,s3
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	bd4080e7          	jalr	-1068(ra) # 80003bcc <iunlockput>
    ip = next;
    80004000:	89d2                	mv	s3,s4
  while(*path == '/')
    80004002:	0004c783          	lbu	a5,0(s1)
    80004006:	05279763          	bne	a5,s2,80004054 <namex+0x156>
    path++;
    8000400a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000400c:	0004c783          	lbu	a5,0(s1)
    80004010:	ff278de3          	beq	a5,s2,8000400a <namex+0x10c>
  if(*path == 0)
    80004014:	c79d                	beqz	a5,80004042 <namex+0x144>
    path++;
    80004016:	85a6                	mv	a1,s1
  len = path - s;
    80004018:	8a5e                	mv	s4,s7
    8000401a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000401c:	01278963          	beq	a5,s2,8000402e <namex+0x130>
    80004020:	dfbd                	beqz	a5,80003f9e <namex+0xa0>
    path++;
    80004022:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004024:	0004c783          	lbu	a5,0(s1)
    80004028:	ff279ce3          	bne	a5,s2,80004020 <namex+0x122>
    8000402c:	bf8d                	j	80003f9e <namex+0xa0>
    memmove(name, s, len);
    8000402e:	2601                	sext.w	a2,a2
    80004030:	8556                	mv	a0,s5
    80004032:	ffffd097          	auipc	ra,0xffffd
    80004036:	d0e080e7          	jalr	-754(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000403a:	9a56                	add	s4,s4,s5
    8000403c:	000a0023          	sb	zero,0(s4)
    80004040:	bf9d                	j	80003fb6 <namex+0xb8>
  if(nameiparent){
    80004042:	f20b03e3          	beqz	s6,80003f68 <namex+0x6a>
    iput(ip);
    80004046:	854e                	mv	a0,s3
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	adc080e7          	jalr	-1316(ra) # 80003b24 <iput>
    return 0;
    80004050:	4981                	li	s3,0
    80004052:	bf19                	j	80003f68 <namex+0x6a>
  if(*path == 0)
    80004054:	d7fd                	beqz	a5,80004042 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004056:	0004c783          	lbu	a5,0(s1)
    8000405a:	85a6                	mv	a1,s1
    8000405c:	b7d1                	j	80004020 <namex+0x122>

000000008000405e <dirlink>:
{
    8000405e:	7139                	addi	sp,sp,-64
    80004060:	fc06                	sd	ra,56(sp)
    80004062:	f822                	sd	s0,48(sp)
    80004064:	f426                	sd	s1,40(sp)
    80004066:	f04a                	sd	s2,32(sp)
    80004068:	ec4e                	sd	s3,24(sp)
    8000406a:	e852                	sd	s4,16(sp)
    8000406c:	0080                	addi	s0,sp,64
    8000406e:	892a                	mv	s2,a0
    80004070:	8a2e                	mv	s4,a1
    80004072:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004074:	4601                	li	a2,0
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	dd8080e7          	jalr	-552(ra) # 80003e4e <dirlookup>
    8000407e:	e93d                	bnez	a0,800040f4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004080:	04c92483          	lw	s1,76(s2)
    80004084:	c49d                	beqz	s1,800040b2 <dirlink+0x54>
    80004086:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004088:	4741                	li	a4,16
    8000408a:	86a6                	mv	a3,s1
    8000408c:	fc040613          	addi	a2,s0,-64
    80004090:	4581                	li	a1,0
    80004092:	854a                	mv	a0,s2
    80004094:	00000097          	auipc	ra,0x0
    80004098:	b8a080e7          	jalr	-1142(ra) # 80003c1e <readi>
    8000409c:	47c1                	li	a5,16
    8000409e:	06f51163          	bne	a0,a5,80004100 <dirlink+0xa2>
    if(de.inum == 0)
    800040a2:	fc045783          	lhu	a5,-64(s0)
    800040a6:	c791                	beqz	a5,800040b2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a8:	24c1                	addiw	s1,s1,16
    800040aa:	04c92783          	lw	a5,76(s2)
    800040ae:	fcf4ede3          	bltu	s1,a5,80004088 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040b2:	4639                	li	a2,14
    800040b4:	85d2                	mv	a1,s4
    800040b6:	fc240513          	addi	a0,s0,-62
    800040ba:	ffffd097          	auipc	ra,0xffffd
    800040be:	d3a080e7          	jalr	-710(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800040c2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c6:	4741                	li	a4,16
    800040c8:	86a6                	mv	a3,s1
    800040ca:	fc040613          	addi	a2,s0,-64
    800040ce:	4581                	li	a1,0
    800040d0:	854a                	mv	a0,s2
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	c44080e7          	jalr	-956(ra) # 80003d16 <writei>
    800040da:	872a                	mv	a4,a0
    800040dc:	47c1                	li	a5,16
  return 0;
    800040de:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e0:	02f71863          	bne	a4,a5,80004110 <dirlink+0xb2>
}
    800040e4:	70e2                	ld	ra,56(sp)
    800040e6:	7442                	ld	s0,48(sp)
    800040e8:	74a2                	ld	s1,40(sp)
    800040ea:	7902                	ld	s2,32(sp)
    800040ec:	69e2                	ld	s3,24(sp)
    800040ee:	6a42                	ld	s4,16(sp)
    800040f0:	6121                	addi	sp,sp,64
    800040f2:	8082                	ret
    iput(ip);
    800040f4:	00000097          	auipc	ra,0x0
    800040f8:	a30080e7          	jalr	-1488(ra) # 80003b24 <iput>
    return -1;
    800040fc:	557d                	li	a0,-1
    800040fe:	b7dd                	j	800040e4 <dirlink+0x86>
      panic("dirlink read");
    80004100:	00004517          	auipc	a0,0x4
    80004104:	58050513          	addi	a0,a0,1408 # 80008680 <syscalls+0x1d8>
    80004108:	ffffc097          	auipc	ra,0xffffc
    8000410c:	436080e7          	jalr	1078(ra) # 8000053e <panic>
    panic("dirlink");
    80004110:	00004517          	auipc	a0,0x4
    80004114:	68050513          	addi	a0,a0,1664 # 80008790 <syscalls+0x2e8>
    80004118:	ffffc097          	auipc	ra,0xffffc
    8000411c:	426080e7          	jalr	1062(ra) # 8000053e <panic>

0000000080004120 <namei>:

struct inode*
namei(char *path)
{
    80004120:	1101                	addi	sp,sp,-32
    80004122:	ec06                	sd	ra,24(sp)
    80004124:	e822                	sd	s0,16(sp)
    80004126:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004128:	fe040613          	addi	a2,s0,-32
    8000412c:	4581                	li	a1,0
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	dd0080e7          	jalr	-560(ra) # 80003efe <namex>
}
    80004136:	60e2                	ld	ra,24(sp)
    80004138:	6442                	ld	s0,16(sp)
    8000413a:	6105                	addi	sp,sp,32
    8000413c:	8082                	ret

000000008000413e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000413e:	1141                	addi	sp,sp,-16
    80004140:	e406                	sd	ra,8(sp)
    80004142:	e022                	sd	s0,0(sp)
    80004144:	0800                	addi	s0,sp,16
    80004146:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004148:	4585                	li	a1,1
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	db4080e7          	jalr	-588(ra) # 80003efe <namex>
}
    80004152:	60a2                	ld	ra,8(sp)
    80004154:	6402                	ld	s0,0(sp)
    80004156:	0141                	addi	sp,sp,16
    80004158:	8082                	ret

000000008000415a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000415a:	1101                	addi	sp,sp,-32
    8000415c:	ec06                	sd	ra,24(sp)
    8000415e:	e822                	sd	s0,16(sp)
    80004160:	e426                	sd	s1,8(sp)
    80004162:	e04a                	sd	s2,0(sp)
    80004164:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004166:	0001e917          	auipc	s2,0x1e
    8000416a:	c6290913          	addi	s2,s2,-926 # 80021dc8 <log>
    8000416e:	01892583          	lw	a1,24(s2)
    80004172:	02892503          	lw	a0,40(s2)
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	ff2080e7          	jalr	-14(ra) # 80003168 <bread>
    8000417e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004180:	02c92683          	lw	a3,44(s2)
    80004184:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004186:	02d05763          	blez	a3,800041b4 <write_head+0x5a>
    8000418a:	0001e797          	auipc	a5,0x1e
    8000418e:	c6e78793          	addi	a5,a5,-914 # 80021df8 <log+0x30>
    80004192:	05c50713          	addi	a4,a0,92
    80004196:	36fd                	addiw	a3,a3,-1
    80004198:	1682                	slli	a3,a3,0x20
    8000419a:	9281                	srli	a3,a3,0x20
    8000419c:	068a                	slli	a3,a3,0x2
    8000419e:	0001e617          	auipc	a2,0x1e
    800041a2:	c5e60613          	addi	a2,a2,-930 # 80021dfc <log+0x34>
    800041a6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041a8:	4390                	lw	a2,0(a5)
    800041aa:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041ac:	0791                	addi	a5,a5,4
    800041ae:	0711                	addi	a4,a4,4
    800041b0:	fed79ce3          	bne	a5,a3,800041a8 <write_head+0x4e>
  }
  bwrite(buf);
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	0a4080e7          	jalr	164(ra) # 8000325a <bwrite>
  brelse(buf);
    800041be:	8526                	mv	a0,s1
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	0d8080e7          	jalr	216(ra) # 80003298 <brelse>
}
    800041c8:	60e2                	ld	ra,24(sp)
    800041ca:	6442                	ld	s0,16(sp)
    800041cc:	64a2                	ld	s1,8(sp)
    800041ce:	6902                	ld	s2,0(sp)
    800041d0:	6105                	addi	sp,sp,32
    800041d2:	8082                	ret

00000000800041d4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d4:	0001e797          	auipc	a5,0x1e
    800041d8:	c207a783          	lw	a5,-992(a5) # 80021df4 <log+0x2c>
    800041dc:	0af05d63          	blez	a5,80004296 <install_trans+0xc2>
{
    800041e0:	7139                	addi	sp,sp,-64
    800041e2:	fc06                	sd	ra,56(sp)
    800041e4:	f822                	sd	s0,48(sp)
    800041e6:	f426                	sd	s1,40(sp)
    800041e8:	f04a                	sd	s2,32(sp)
    800041ea:	ec4e                	sd	s3,24(sp)
    800041ec:	e852                	sd	s4,16(sp)
    800041ee:	e456                	sd	s5,8(sp)
    800041f0:	e05a                	sd	s6,0(sp)
    800041f2:	0080                	addi	s0,sp,64
    800041f4:	8b2a                	mv	s6,a0
    800041f6:	0001ea97          	auipc	s5,0x1e
    800041fa:	c02a8a93          	addi	s5,s5,-1022 # 80021df8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041fe:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004200:	0001e997          	auipc	s3,0x1e
    80004204:	bc898993          	addi	s3,s3,-1080 # 80021dc8 <log>
    80004208:	a035                	j	80004234 <install_trans+0x60>
      bunpin(dbuf);
    8000420a:	8526                	mv	a0,s1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	166080e7          	jalr	358(ra) # 80003372 <bunpin>
    brelse(lbuf);
    80004214:	854a                	mv	a0,s2
    80004216:	fffff097          	auipc	ra,0xfffff
    8000421a:	082080e7          	jalr	130(ra) # 80003298 <brelse>
    brelse(dbuf);
    8000421e:	8526                	mv	a0,s1
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	078080e7          	jalr	120(ra) # 80003298 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004228:	2a05                	addiw	s4,s4,1
    8000422a:	0a91                	addi	s5,s5,4
    8000422c:	02c9a783          	lw	a5,44(s3)
    80004230:	04fa5963          	bge	s4,a5,80004282 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004234:	0189a583          	lw	a1,24(s3)
    80004238:	014585bb          	addw	a1,a1,s4
    8000423c:	2585                	addiw	a1,a1,1
    8000423e:	0289a503          	lw	a0,40(s3)
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	f26080e7          	jalr	-218(ra) # 80003168 <bread>
    8000424a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000424c:	000aa583          	lw	a1,0(s5)
    80004250:	0289a503          	lw	a0,40(s3)
    80004254:	fffff097          	auipc	ra,0xfffff
    80004258:	f14080e7          	jalr	-236(ra) # 80003168 <bread>
    8000425c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000425e:	40000613          	li	a2,1024
    80004262:	05890593          	addi	a1,s2,88
    80004266:	05850513          	addi	a0,a0,88
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	ad6080e7          	jalr	-1322(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004272:	8526                	mv	a0,s1
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	fe6080e7          	jalr	-26(ra) # 8000325a <bwrite>
    if(recovering == 0)
    8000427c:	f80b1ce3          	bnez	s6,80004214 <install_trans+0x40>
    80004280:	b769                	j	8000420a <install_trans+0x36>
}
    80004282:	70e2                	ld	ra,56(sp)
    80004284:	7442                	ld	s0,48(sp)
    80004286:	74a2                	ld	s1,40(sp)
    80004288:	7902                	ld	s2,32(sp)
    8000428a:	69e2                	ld	s3,24(sp)
    8000428c:	6a42                	ld	s4,16(sp)
    8000428e:	6aa2                	ld	s5,8(sp)
    80004290:	6b02                	ld	s6,0(sp)
    80004292:	6121                	addi	sp,sp,64
    80004294:	8082                	ret
    80004296:	8082                	ret

0000000080004298 <initlog>:
{
    80004298:	7179                	addi	sp,sp,-48
    8000429a:	f406                	sd	ra,40(sp)
    8000429c:	f022                	sd	s0,32(sp)
    8000429e:	ec26                	sd	s1,24(sp)
    800042a0:	e84a                	sd	s2,16(sp)
    800042a2:	e44e                	sd	s3,8(sp)
    800042a4:	1800                	addi	s0,sp,48
    800042a6:	892a                	mv	s2,a0
    800042a8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042aa:	0001e497          	auipc	s1,0x1e
    800042ae:	b1e48493          	addi	s1,s1,-1250 # 80021dc8 <log>
    800042b2:	00004597          	auipc	a1,0x4
    800042b6:	3de58593          	addi	a1,a1,990 # 80008690 <syscalls+0x1e8>
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	898080e7          	jalr	-1896(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800042c4:	0149a583          	lw	a1,20(s3)
    800042c8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042ca:	0109a783          	lw	a5,16(s3)
    800042ce:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042d0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042d4:	854a                	mv	a0,s2
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	e92080e7          	jalr	-366(ra) # 80003168 <bread>
  log.lh.n = lh->n;
    800042de:	4d3c                	lw	a5,88(a0)
    800042e0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042e2:	02f05563          	blez	a5,8000430c <initlog+0x74>
    800042e6:	05c50713          	addi	a4,a0,92
    800042ea:	0001e697          	auipc	a3,0x1e
    800042ee:	b0e68693          	addi	a3,a3,-1266 # 80021df8 <log+0x30>
    800042f2:	37fd                	addiw	a5,a5,-1
    800042f4:	1782                	slli	a5,a5,0x20
    800042f6:	9381                	srli	a5,a5,0x20
    800042f8:	078a                	slli	a5,a5,0x2
    800042fa:	06050613          	addi	a2,a0,96
    800042fe:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004300:	4310                	lw	a2,0(a4)
    80004302:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004304:	0711                	addi	a4,a4,4
    80004306:	0691                	addi	a3,a3,4
    80004308:	fef71ce3          	bne	a4,a5,80004300 <initlog+0x68>
  brelse(buf);
    8000430c:	fffff097          	auipc	ra,0xfffff
    80004310:	f8c080e7          	jalr	-116(ra) # 80003298 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004314:	4505                	li	a0,1
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	ebe080e7          	jalr	-322(ra) # 800041d4 <install_trans>
  log.lh.n = 0;
    8000431e:	0001e797          	auipc	a5,0x1e
    80004322:	ac07ab23          	sw	zero,-1322(a5) # 80021df4 <log+0x2c>
  write_head(); // clear the log
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	e34080e7          	jalr	-460(ra) # 8000415a <write_head>
}
    8000432e:	70a2                	ld	ra,40(sp)
    80004330:	7402                	ld	s0,32(sp)
    80004332:	64e2                	ld	s1,24(sp)
    80004334:	6942                	ld	s2,16(sp)
    80004336:	69a2                	ld	s3,8(sp)
    80004338:	6145                	addi	sp,sp,48
    8000433a:	8082                	ret

000000008000433c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000433c:	1101                	addi	sp,sp,-32
    8000433e:	ec06                	sd	ra,24(sp)
    80004340:	e822                	sd	s0,16(sp)
    80004342:	e426                	sd	s1,8(sp)
    80004344:	e04a                	sd	s2,0(sp)
    80004346:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004348:	0001e517          	auipc	a0,0x1e
    8000434c:	a8050513          	addi	a0,a0,-1408 # 80021dc8 <log>
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	894080e7          	jalr	-1900(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004358:	0001e497          	auipc	s1,0x1e
    8000435c:	a7048493          	addi	s1,s1,-1424 # 80021dc8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004360:	4979                	li	s2,30
    80004362:	a039                	j	80004370 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004364:	85a6                	mv	a1,s1
    80004366:	8526                	mv	a0,s1
    80004368:	ffffe097          	auipc	ra,0xffffe
    8000436c:	056080e7          	jalr	86(ra) # 800023be <sleep>
    if(log.committing){
    80004370:	50dc                	lw	a5,36(s1)
    80004372:	fbed                	bnez	a5,80004364 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004374:	509c                	lw	a5,32(s1)
    80004376:	0017871b          	addiw	a4,a5,1
    8000437a:	0007069b          	sext.w	a3,a4
    8000437e:	0027179b          	slliw	a5,a4,0x2
    80004382:	9fb9                	addw	a5,a5,a4
    80004384:	0017979b          	slliw	a5,a5,0x1
    80004388:	54d8                	lw	a4,44(s1)
    8000438a:	9fb9                	addw	a5,a5,a4
    8000438c:	00f95963          	bge	s2,a5,8000439e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004390:	85a6                	mv	a1,s1
    80004392:	8526                	mv	a0,s1
    80004394:	ffffe097          	auipc	ra,0xffffe
    80004398:	02a080e7          	jalr	42(ra) # 800023be <sleep>
    8000439c:	bfd1                	j	80004370 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000439e:	0001e517          	auipc	a0,0x1e
    800043a2:	a2a50513          	addi	a0,a0,-1494 # 80021dc8 <log>
    800043a6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	8f0080e7          	jalr	-1808(ra) # 80000c98 <release>
      break;
    }
  }
}
    800043b0:	60e2                	ld	ra,24(sp)
    800043b2:	6442                	ld	s0,16(sp)
    800043b4:	64a2                	ld	s1,8(sp)
    800043b6:	6902                	ld	s2,0(sp)
    800043b8:	6105                	addi	sp,sp,32
    800043ba:	8082                	ret

00000000800043bc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043bc:	7139                	addi	sp,sp,-64
    800043be:	fc06                	sd	ra,56(sp)
    800043c0:	f822                	sd	s0,48(sp)
    800043c2:	f426                	sd	s1,40(sp)
    800043c4:	f04a                	sd	s2,32(sp)
    800043c6:	ec4e                	sd	s3,24(sp)
    800043c8:	e852                	sd	s4,16(sp)
    800043ca:	e456                	sd	s5,8(sp)
    800043cc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043ce:	0001e497          	auipc	s1,0x1e
    800043d2:	9fa48493          	addi	s1,s1,-1542 # 80021dc8 <log>
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	80c080e7          	jalr	-2036(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800043e0:	509c                	lw	a5,32(s1)
    800043e2:	37fd                	addiw	a5,a5,-1
    800043e4:	0007891b          	sext.w	s2,a5
    800043e8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043ea:	50dc                	lw	a5,36(s1)
    800043ec:	efb9                	bnez	a5,8000444a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043ee:	06091663          	bnez	s2,8000445a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043f2:	0001e497          	auipc	s1,0x1e
    800043f6:	9d648493          	addi	s1,s1,-1578 # 80021dc8 <log>
    800043fa:	4785                	li	a5,1
    800043fc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043fe:	8526                	mv	a0,s1
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	898080e7          	jalr	-1896(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004408:	54dc                	lw	a5,44(s1)
    8000440a:	06f04763          	bgtz	a5,80004478 <end_op+0xbc>
    acquire(&log.lock);
    8000440e:	0001e497          	auipc	s1,0x1e
    80004412:	9ba48493          	addi	s1,s1,-1606 # 80021dc8 <log>
    80004416:	8526                	mv	a0,s1
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	7cc080e7          	jalr	1996(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004420:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004424:	8526                	mv	a0,s1
    80004426:	ffffe097          	auipc	ra,0xffffe
    8000442a:	124080e7          	jalr	292(ra) # 8000254a <wakeup>
    release(&log.lock);
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffd097          	auipc	ra,0xffffd
    80004434:	868080e7          	jalr	-1944(ra) # 80000c98 <release>
}
    80004438:	70e2                	ld	ra,56(sp)
    8000443a:	7442                	ld	s0,48(sp)
    8000443c:	74a2                	ld	s1,40(sp)
    8000443e:	7902                	ld	s2,32(sp)
    80004440:	69e2                	ld	s3,24(sp)
    80004442:	6a42                	ld	s4,16(sp)
    80004444:	6aa2                	ld	s5,8(sp)
    80004446:	6121                	addi	sp,sp,64
    80004448:	8082                	ret
    panic("log.committing");
    8000444a:	00004517          	auipc	a0,0x4
    8000444e:	24e50513          	addi	a0,a0,590 # 80008698 <syscalls+0x1f0>
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	0ec080e7          	jalr	236(ra) # 8000053e <panic>
    wakeup(&log);
    8000445a:	0001e497          	auipc	s1,0x1e
    8000445e:	96e48493          	addi	s1,s1,-1682 # 80021dc8 <log>
    80004462:	8526                	mv	a0,s1
    80004464:	ffffe097          	auipc	ra,0xffffe
    80004468:	0e6080e7          	jalr	230(ra) # 8000254a <wakeup>
  release(&log.lock);
    8000446c:	8526                	mv	a0,s1
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	82a080e7          	jalr	-2006(ra) # 80000c98 <release>
  if(do_commit){
    80004476:	b7c9                	j	80004438 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004478:	0001ea97          	auipc	s5,0x1e
    8000447c:	980a8a93          	addi	s5,s5,-1664 # 80021df8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004480:	0001ea17          	auipc	s4,0x1e
    80004484:	948a0a13          	addi	s4,s4,-1720 # 80021dc8 <log>
    80004488:	018a2583          	lw	a1,24(s4)
    8000448c:	012585bb          	addw	a1,a1,s2
    80004490:	2585                	addiw	a1,a1,1
    80004492:	028a2503          	lw	a0,40(s4)
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	cd2080e7          	jalr	-814(ra) # 80003168 <bread>
    8000449e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044a0:	000aa583          	lw	a1,0(s5)
    800044a4:	028a2503          	lw	a0,40(s4)
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	cc0080e7          	jalr	-832(ra) # 80003168 <bread>
    800044b0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044b2:	40000613          	li	a2,1024
    800044b6:	05850593          	addi	a1,a0,88
    800044ba:	05848513          	addi	a0,s1,88
    800044be:	ffffd097          	auipc	ra,0xffffd
    800044c2:	882080e7          	jalr	-1918(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800044c6:	8526                	mv	a0,s1
    800044c8:	fffff097          	auipc	ra,0xfffff
    800044cc:	d92080e7          	jalr	-622(ra) # 8000325a <bwrite>
    brelse(from);
    800044d0:	854e                	mv	a0,s3
    800044d2:	fffff097          	auipc	ra,0xfffff
    800044d6:	dc6080e7          	jalr	-570(ra) # 80003298 <brelse>
    brelse(to);
    800044da:	8526                	mv	a0,s1
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	dbc080e7          	jalr	-580(ra) # 80003298 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e4:	2905                	addiw	s2,s2,1
    800044e6:	0a91                	addi	s5,s5,4
    800044e8:	02ca2783          	lw	a5,44(s4)
    800044ec:	f8f94ee3          	blt	s2,a5,80004488 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044f0:	00000097          	auipc	ra,0x0
    800044f4:	c6a080e7          	jalr	-918(ra) # 8000415a <write_head>
    install_trans(0); // Now install writes to home locations
    800044f8:	4501                	li	a0,0
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	cda080e7          	jalr	-806(ra) # 800041d4 <install_trans>
    log.lh.n = 0;
    80004502:	0001e797          	auipc	a5,0x1e
    80004506:	8e07a923          	sw	zero,-1806(a5) # 80021df4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000450a:	00000097          	auipc	ra,0x0
    8000450e:	c50080e7          	jalr	-944(ra) # 8000415a <write_head>
    80004512:	bdf5                	j	8000440e <end_op+0x52>

0000000080004514 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004514:	1101                	addi	sp,sp,-32
    80004516:	ec06                	sd	ra,24(sp)
    80004518:	e822                	sd	s0,16(sp)
    8000451a:	e426                	sd	s1,8(sp)
    8000451c:	e04a                	sd	s2,0(sp)
    8000451e:	1000                	addi	s0,sp,32
    80004520:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004522:	0001e917          	auipc	s2,0x1e
    80004526:	8a690913          	addi	s2,s2,-1882 # 80021dc8 <log>
    8000452a:	854a                	mv	a0,s2
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	6b8080e7          	jalr	1720(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004534:	02c92603          	lw	a2,44(s2)
    80004538:	47f5                	li	a5,29
    8000453a:	06c7c563          	blt	a5,a2,800045a4 <log_write+0x90>
    8000453e:	0001e797          	auipc	a5,0x1e
    80004542:	8a67a783          	lw	a5,-1882(a5) # 80021de4 <log+0x1c>
    80004546:	37fd                	addiw	a5,a5,-1
    80004548:	04f65e63          	bge	a2,a5,800045a4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000454c:	0001e797          	auipc	a5,0x1e
    80004550:	89c7a783          	lw	a5,-1892(a5) # 80021de8 <log+0x20>
    80004554:	06f05063          	blez	a5,800045b4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004558:	4781                	li	a5,0
    8000455a:	06c05563          	blez	a2,800045c4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000455e:	44cc                	lw	a1,12(s1)
    80004560:	0001e717          	auipc	a4,0x1e
    80004564:	89870713          	addi	a4,a4,-1896 # 80021df8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004568:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000456a:	4314                	lw	a3,0(a4)
    8000456c:	04b68c63          	beq	a3,a1,800045c4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004570:	2785                	addiw	a5,a5,1
    80004572:	0711                	addi	a4,a4,4
    80004574:	fef61be3          	bne	a2,a5,8000456a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004578:	0621                	addi	a2,a2,8
    8000457a:	060a                	slli	a2,a2,0x2
    8000457c:	0001e797          	auipc	a5,0x1e
    80004580:	84c78793          	addi	a5,a5,-1972 # 80021dc8 <log>
    80004584:	963e                	add	a2,a2,a5
    80004586:	44dc                	lw	a5,12(s1)
    80004588:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000458a:	8526                	mv	a0,s1
    8000458c:	fffff097          	auipc	ra,0xfffff
    80004590:	daa080e7          	jalr	-598(ra) # 80003336 <bpin>
    log.lh.n++;
    80004594:	0001e717          	auipc	a4,0x1e
    80004598:	83470713          	addi	a4,a4,-1996 # 80021dc8 <log>
    8000459c:	575c                	lw	a5,44(a4)
    8000459e:	2785                	addiw	a5,a5,1
    800045a0:	d75c                	sw	a5,44(a4)
    800045a2:	a835                	j	800045de <log_write+0xca>
    panic("too big a transaction");
    800045a4:	00004517          	auipc	a0,0x4
    800045a8:	10450513          	addi	a0,a0,260 # 800086a8 <syscalls+0x200>
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	f92080e7          	jalr	-110(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800045b4:	00004517          	auipc	a0,0x4
    800045b8:	10c50513          	addi	a0,a0,268 # 800086c0 <syscalls+0x218>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	f82080e7          	jalr	-126(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045c4:	00878713          	addi	a4,a5,8
    800045c8:	00271693          	slli	a3,a4,0x2
    800045cc:	0001d717          	auipc	a4,0x1d
    800045d0:	7fc70713          	addi	a4,a4,2044 # 80021dc8 <log>
    800045d4:	9736                	add	a4,a4,a3
    800045d6:	44d4                	lw	a3,12(s1)
    800045d8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045da:	faf608e3          	beq	a2,a5,8000458a <log_write+0x76>
  }
  release(&log.lock);
    800045de:	0001d517          	auipc	a0,0x1d
    800045e2:	7ea50513          	addi	a0,a0,2026 # 80021dc8 <log>
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	6b2080e7          	jalr	1714(ra) # 80000c98 <release>
}
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6902                	ld	s2,0(sp)
    800045f6:	6105                	addi	sp,sp,32
    800045f8:	8082                	ret

00000000800045fa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045fa:	1101                	addi	sp,sp,-32
    800045fc:	ec06                	sd	ra,24(sp)
    800045fe:	e822                	sd	s0,16(sp)
    80004600:	e426                	sd	s1,8(sp)
    80004602:	e04a                	sd	s2,0(sp)
    80004604:	1000                	addi	s0,sp,32
    80004606:	84aa                	mv	s1,a0
    80004608:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000460a:	00004597          	auipc	a1,0x4
    8000460e:	0d658593          	addi	a1,a1,214 # 800086e0 <syscalls+0x238>
    80004612:	0521                	addi	a0,a0,8
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	540080e7          	jalr	1344(ra) # 80000b54 <initlock>
  lk->name = name;
    8000461c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004620:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004624:	0204a423          	sw	zero,40(s1)
}
    80004628:	60e2                	ld	ra,24(sp)
    8000462a:	6442                	ld	s0,16(sp)
    8000462c:	64a2                	ld	s1,8(sp)
    8000462e:	6902                	ld	s2,0(sp)
    80004630:	6105                	addi	sp,sp,32
    80004632:	8082                	ret

0000000080004634 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004634:	1101                	addi	sp,sp,-32
    80004636:	ec06                	sd	ra,24(sp)
    80004638:	e822                	sd	s0,16(sp)
    8000463a:	e426                	sd	s1,8(sp)
    8000463c:	e04a                	sd	s2,0(sp)
    8000463e:	1000                	addi	s0,sp,32
    80004640:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004642:	00850913          	addi	s2,a0,8
    80004646:	854a                	mv	a0,s2
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	59c080e7          	jalr	1436(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004650:	409c                	lw	a5,0(s1)
    80004652:	cb89                	beqz	a5,80004664 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004654:	85ca                	mv	a1,s2
    80004656:	8526                	mv	a0,s1
    80004658:	ffffe097          	auipc	ra,0xffffe
    8000465c:	d66080e7          	jalr	-666(ra) # 800023be <sleep>
  while (lk->locked) {
    80004660:	409c                	lw	a5,0(s1)
    80004662:	fbed                	bnez	a5,80004654 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004664:	4785                	li	a5,1
    80004666:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004668:	ffffd097          	auipc	ra,0xffffd
    8000466c:	610080e7          	jalr	1552(ra) # 80001c78 <myproc>
    80004670:	453c                	lw	a5,72(a0)
    80004672:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004674:	854a                	mv	a0,s2
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	622080e7          	jalr	1570(ra) # 80000c98 <release>
}
    8000467e:	60e2                	ld	ra,24(sp)
    80004680:	6442                	ld	s0,16(sp)
    80004682:	64a2                	ld	s1,8(sp)
    80004684:	6902                	ld	s2,0(sp)
    80004686:	6105                	addi	sp,sp,32
    80004688:	8082                	ret

000000008000468a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000468a:	1101                	addi	sp,sp,-32
    8000468c:	ec06                	sd	ra,24(sp)
    8000468e:	e822                	sd	s0,16(sp)
    80004690:	e426                	sd	s1,8(sp)
    80004692:	e04a                	sd	s2,0(sp)
    80004694:	1000                	addi	s0,sp,32
    80004696:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004698:	00850913          	addi	s2,a0,8
    8000469c:	854a                	mv	a0,s2
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	546080e7          	jalr	1350(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800046a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046aa:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046ae:	8526                	mv	a0,s1
    800046b0:	ffffe097          	auipc	ra,0xffffe
    800046b4:	e9a080e7          	jalr	-358(ra) # 8000254a <wakeup>
  release(&lk->lk);
    800046b8:	854a                	mv	a0,s2
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	5de080e7          	jalr	1502(ra) # 80000c98 <release>
}
    800046c2:	60e2                	ld	ra,24(sp)
    800046c4:	6442                	ld	s0,16(sp)
    800046c6:	64a2                	ld	s1,8(sp)
    800046c8:	6902                	ld	s2,0(sp)
    800046ca:	6105                	addi	sp,sp,32
    800046cc:	8082                	ret

00000000800046ce <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046ce:	7179                	addi	sp,sp,-48
    800046d0:	f406                	sd	ra,40(sp)
    800046d2:	f022                	sd	s0,32(sp)
    800046d4:	ec26                	sd	s1,24(sp)
    800046d6:	e84a                	sd	s2,16(sp)
    800046d8:	e44e                	sd	s3,8(sp)
    800046da:	1800                	addi	s0,sp,48
    800046dc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046de:	00850913          	addi	s2,a0,8
    800046e2:	854a                	mv	a0,s2
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	500080e7          	jalr	1280(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046ec:	409c                	lw	a5,0(s1)
    800046ee:	ef99                	bnez	a5,8000470c <holdingsleep+0x3e>
    800046f0:	4481                	li	s1,0
  release(&lk->lk);
    800046f2:	854a                	mv	a0,s2
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	5a4080e7          	jalr	1444(ra) # 80000c98 <release>
  return r;
}
    800046fc:	8526                	mv	a0,s1
    800046fe:	70a2                	ld	ra,40(sp)
    80004700:	7402                	ld	s0,32(sp)
    80004702:	64e2                	ld	s1,24(sp)
    80004704:	6942                	ld	s2,16(sp)
    80004706:	69a2                	ld	s3,8(sp)
    80004708:	6145                	addi	sp,sp,48
    8000470a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000470c:	0284a983          	lw	s3,40(s1)
    80004710:	ffffd097          	auipc	ra,0xffffd
    80004714:	568080e7          	jalr	1384(ra) # 80001c78 <myproc>
    80004718:	4524                	lw	s1,72(a0)
    8000471a:	413484b3          	sub	s1,s1,s3
    8000471e:	0014b493          	seqz	s1,s1
    80004722:	bfc1                	j	800046f2 <holdingsleep+0x24>

0000000080004724 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004724:	1141                	addi	sp,sp,-16
    80004726:	e406                	sd	ra,8(sp)
    80004728:	e022                	sd	s0,0(sp)
    8000472a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000472c:	00004597          	auipc	a1,0x4
    80004730:	fc458593          	addi	a1,a1,-60 # 800086f0 <syscalls+0x248>
    80004734:	0001d517          	auipc	a0,0x1d
    80004738:	7dc50513          	addi	a0,a0,2012 # 80021f10 <ftable>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	418080e7          	jalr	1048(ra) # 80000b54 <initlock>
}
    80004744:	60a2                	ld	ra,8(sp)
    80004746:	6402                	ld	s0,0(sp)
    80004748:	0141                	addi	sp,sp,16
    8000474a:	8082                	ret

000000008000474c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000474c:	1101                	addi	sp,sp,-32
    8000474e:	ec06                	sd	ra,24(sp)
    80004750:	e822                	sd	s0,16(sp)
    80004752:	e426                	sd	s1,8(sp)
    80004754:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004756:	0001d517          	auipc	a0,0x1d
    8000475a:	7ba50513          	addi	a0,a0,1978 # 80021f10 <ftable>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	486080e7          	jalr	1158(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004766:	0001d497          	auipc	s1,0x1d
    8000476a:	7c248493          	addi	s1,s1,1986 # 80021f28 <ftable+0x18>
    8000476e:	0001e717          	auipc	a4,0x1e
    80004772:	75a70713          	addi	a4,a4,1882 # 80022ec8 <ftable+0xfb8>
    if(f->ref == 0){
    80004776:	40dc                	lw	a5,4(s1)
    80004778:	cf99                	beqz	a5,80004796 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000477a:	02848493          	addi	s1,s1,40
    8000477e:	fee49ce3          	bne	s1,a4,80004776 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004782:	0001d517          	auipc	a0,0x1d
    80004786:	78e50513          	addi	a0,a0,1934 # 80021f10 <ftable>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	50e080e7          	jalr	1294(ra) # 80000c98 <release>
  return 0;
    80004792:	4481                	li	s1,0
    80004794:	a819                	j	800047aa <filealloc+0x5e>
      f->ref = 1;
    80004796:	4785                	li	a5,1
    80004798:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000479a:	0001d517          	auipc	a0,0x1d
    8000479e:	77650513          	addi	a0,a0,1910 # 80021f10 <ftable>
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	4f6080e7          	jalr	1270(ra) # 80000c98 <release>
}
    800047aa:	8526                	mv	a0,s1
    800047ac:	60e2                	ld	ra,24(sp)
    800047ae:	6442                	ld	s0,16(sp)
    800047b0:	64a2                	ld	s1,8(sp)
    800047b2:	6105                	addi	sp,sp,32
    800047b4:	8082                	ret

00000000800047b6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047b6:	1101                	addi	sp,sp,-32
    800047b8:	ec06                	sd	ra,24(sp)
    800047ba:	e822                	sd	s0,16(sp)
    800047bc:	e426                	sd	s1,8(sp)
    800047be:	1000                	addi	s0,sp,32
    800047c0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047c2:	0001d517          	auipc	a0,0x1d
    800047c6:	74e50513          	addi	a0,a0,1870 # 80021f10 <ftable>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	41a080e7          	jalr	1050(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047d2:	40dc                	lw	a5,4(s1)
    800047d4:	02f05263          	blez	a5,800047f8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047d8:	2785                	addiw	a5,a5,1
    800047da:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047dc:	0001d517          	auipc	a0,0x1d
    800047e0:	73450513          	addi	a0,a0,1844 # 80021f10 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4b4080e7          	jalr	1204(ra) # 80000c98 <release>
  return f;
}
    800047ec:	8526                	mv	a0,s1
    800047ee:	60e2                	ld	ra,24(sp)
    800047f0:	6442                	ld	s0,16(sp)
    800047f2:	64a2                	ld	s1,8(sp)
    800047f4:	6105                	addi	sp,sp,32
    800047f6:	8082                	ret
    panic("filedup");
    800047f8:	00004517          	auipc	a0,0x4
    800047fc:	f0050513          	addi	a0,a0,-256 # 800086f8 <syscalls+0x250>
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	d3e080e7          	jalr	-706(ra) # 8000053e <panic>

0000000080004808 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004808:	7139                	addi	sp,sp,-64
    8000480a:	fc06                	sd	ra,56(sp)
    8000480c:	f822                	sd	s0,48(sp)
    8000480e:	f426                	sd	s1,40(sp)
    80004810:	f04a                	sd	s2,32(sp)
    80004812:	ec4e                	sd	s3,24(sp)
    80004814:	e852                	sd	s4,16(sp)
    80004816:	e456                	sd	s5,8(sp)
    80004818:	0080                	addi	s0,sp,64
    8000481a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000481c:	0001d517          	auipc	a0,0x1d
    80004820:	6f450513          	addi	a0,a0,1780 # 80021f10 <ftable>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	3c0080e7          	jalr	960(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000482c:	40dc                	lw	a5,4(s1)
    8000482e:	06f05163          	blez	a5,80004890 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004832:	37fd                	addiw	a5,a5,-1
    80004834:	0007871b          	sext.w	a4,a5
    80004838:	c0dc                	sw	a5,4(s1)
    8000483a:	06e04363          	bgtz	a4,800048a0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000483e:	0004a903          	lw	s2,0(s1)
    80004842:	0094ca83          	lbu	s5,9(s1)
    80004846:	0104ba03          	ld	s4,16(s1)
    8000484a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000484e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004852:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004856:	0001d517          	auipc	a0,0x1d
    8000485a:	6ba50513          	addi	a0,a0,1722 # 80021f10 <ftable>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	43a080e7          	jalr	1082(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004866:	4785                	li	a5,1
    80004868:	04f90d63          	beq	s2,a5,800048c2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000486c:	3979                	addiw	s2,s2,-2
    8000486e:	4785                	li	a5,1
    80004870:	0527e063          	bltu	a5,s2,800048b0 <fileclose+0xa8>
    begin_op();
    80004874:	00000097          	auipc	ra,0x0
    80004878:	ac8080e7          	jalr	-1336(ra) # 8000433c <begin_op>
    iput(ff.ip);
    8000487c:	854e                	mv	a0,s3
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	2a6080e7          	jalr	678(ra) # 80003b24 <iput>
    end_op();
    80004886:	00000097          	auipc	ra,0x0
    8000488a:	b36080e7          	jalr	-1226(ra) # 800043bc <end_op>
    8000488e:	a00d                	j	800048b0 <fileclose+0xa8>
    panic("fileclose");
    80004890:	00004517          	auipc	a0,0x4
    80004894:	e7050513          	addi	a0,a0,-400 # 80008700 <syscalls+0x258>
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	ca6080e7          	jalr	-858(ra) # 8000053e <panic>
    release(&ftable.lock);
    800048a0:	0001d517          	auipc	a0,0x1d
    800048a4:	67050513          	addi	a0,a0,1648 # 80021f10 <ftable>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	3f0080e7          	jalr	1008(ra) # 80000c98 <release>
  }
}
    800048b0:	70e2                	ld	ra,56(sp)
    800048b2:	7442                	ld	s0,48(sp)
    800048b4:	74a2                	ld	s1,40(sp)
    800048b6:	7902                	ld	s2,32(sp)
    800048b8:	69e2                	ld	s3,24(sp)
    800048ba:	6a42                	ld	s4,16(sp)
    800048bc:	6aa2                	ld	s5,8(sp)
    800048be:	6121                	addi	sp,sp,64
    800048c0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048c2:	85d6                	mv	a1,s5
    800048c4:	8552                	mv	a0,s4
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	34c080e7          	jalr	844(ra) # 80004c12 <pipeclose>
    800048ce:	b7cd                	j	800048b0 <fileclose+0xa8>

00000000800048d0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048d0:	715d                	addi	sp,sp,-80
    800048d2:	e486                	sd	ra,72(sp)
    800048d4:	e0a2                	sd	s0,64(sp)
    800048d6:	fc26                	sd	s1,56(sp)
    800048d8:	f84a                	sd	s2,48(sp)
    800048da:	f44e                	sd	s3,40(sp)
    800048dc:	0880                	addi	s0,sp,80
    800048de:	84aa                	mv	s1,a0
    800048e0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048e2:	ffffd097          	auipc	ra,0xffffd
    800048e6:	396080e7          	jalr	918(ra) # 80001c78 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048ea:	409c                	lw	a5,0(s1)
    800048ec:	37f9                	addiw	a5,a5,-2
    800048ee:	4705                	li	a4,1
    800048f0:	04f76763          	bltu	a4,a5,8000493e <filestat+0x6e>
    800048f4:	892a                	mv	s2,a0
    ilock(f->ip);
    800048f6:	6c88                	ld	a0,24(s1)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	072080e7          	jalr	114(ra) # 8000396a <ilock>
    stati(f->ip, &st);
    80004900:	fb840593          	addi	a1,s0,-72
    80004904:	6c88                	ld	a0,24(s1)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	2ee080e7          	jalr	750(ra) # 80003bf4 <stati>
    iunlock(f->ip);
    8000490e:	6c88                	ld	a0,24(s1)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	11c080e7          	jalr	284(ra) # 80003a2c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004918:	46e1                	li	a3,24
    8000491a:	fb840613          	addi	a2,s0,-72
    8000491e:	85ce                	mv	a1,s3
    80004920:	07893503          	ld	a0,120(s2)
    80004924:	ffffd097          	auipc	ra,0xffffd
    80004928:	d4e080e7          	jalr	-690(ra) # 80001672 <copyout>
    8000492c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004930:	60a6                	ld	ra,72(sp)
    80004932:	6406                	ld	s0,64(sp)
    80004934:	74e2                	ld	s1,56(sp)
    80004936:	7942                	ld	s2,48(sp)
    80004938:	79a2                	ld	s3,40(sp)
    8000493a:	6161                	addi	sp,sp,80
    8000493c:	8082                	ret
  return -1;
    8000493e:	557d                	li	a0,-1
    80004940:	bfc5                	j	80004930 <filestat+0x60>

0000000080004942 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004942:	7179                	addi	sp,sp,-48
    80004944:	f406                	sd	ra,40(sp)
    80004946:	f022                	sd	s0,32(sp)
    80004948:	ec26                	sd	s1,24(sp)
    8000494a:	e84a                	sd	s2,16(sp)
    8000494c:	e44e                	sd	s3,8(sp)
    8000494e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004950:	00854783          	lbu	a5,8(a0)
    80004954:	c3d5                	beqz	a5,800049f8 <fileread+0xb6>
    80004956:	84aa                	mv	s1,a0
    80004958:	89ae                	mv	s3,a1
    8000495a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000495c:	411c                	lw	a5,0(a0)
    8000495e:	4705                	li	a4,1
    80004960:	04e78963          	beq	a5,a4,800049b2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004964:	470d                	li	a4,3
    80004966:	04e78d63          	beq	a5,a4,800049c0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000496a:	4709                	li	a4,2
    8000496c:	06e79e63          	bne	a5,a4,800049e8 <fileread+0xa6>
    ilock(f->ip);
    80004970:	6d08                	ld	a0,24(a0)
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	ff8080e7          	jalr	-8(ra) # 8000396a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000497a:	874a                	mv	a4,s2
    8000497c:	5094                	lw	a3,32(s1)
    8000497e:	864e                	mv	a2,s3
    80004980:	4585                	li	a1,1
    80004982:	6c88                	ld	a0,24(s1)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	29a080e7          	jalr	666(ra) # 80003c1e <readi>
    8000498c:	892a                	mv	s2,a0
    8000498e:	00a05563          	blez	a0,80004998 <fileread+0x56>
      f->off += r;
    80004992:	509c                	lw	a5,32(s1)
    80004994:	9fa9                	addw	a5,a5,a0
    80004996:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004998:	6c88                	ld	a0,24(s1)
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	092080e7          	jalr	146(ra) # 80003a2c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049a2:	854a                	mv	a0,s2
    800049a4:	70a2                	ld	ra,40(sp)
    800049a6:	7402                	ld	s0,32(sp)
    800049a8:	64e2                	ld	s1,24(sp)
    800049aa:	6942                	ld	s2,16(sp)
    800049ac:	69a2                	ld	s3,8(sp)
    800049ae:	6145                	addi	sp,sp,48
    800049b0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049b2:	6908                	ld	a0,16(a0)
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	3c8080e7          	jalr	968(ra) # 80004d7c <piperead>
    800049bc:	892a                	mv	s2,a0
    800049be:	b7d5                	j	800049a2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049c0:	02451783          	lh	a5,36(a0)
    800049c4:	03079693          	slli	a3,a5,0x30
    800049c8:	92c1                	srli	a3,a3,0x30
    800049ca:	4725                	li	a4,9
    800049cc:	02d76863          	bltu	a4,a3,800049fc <fileread+0xba>
    800049d0:	0792                	slli	a5,a5,0x4
    800049d2:	0001d717          	auipc	a4,0x1d
    800049d6:	49e70713          	addi	a4,a4,1182 # 80021e70 <devsw>
    800049da:	97ba                	add	a5,a5,a4
    800049dc:	639c                	ld	a5,0(a5)
    800049de:	c38d                	beqz	a5,80004a00 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049e0:	4505                	li	a0,1
    800049e2:	9782                	jalr	a5
    800049e4:	892a                	mv	s2,a0
    800049e6:	bf75                	j	800049a2 <fileread+0x60>
    panic("fileread");
    800049e8:	00004517          	auipc	a0,0x4
    800049ec:	d2850513          	addi	a0,a0,-728 # 80008710 <syscalls+0x268>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	b4e080e7          	jalr	-1202(ra) # 8000053e <panic>
    return -1;
    800049f8:	597d                	li	s2,-1
    800049fa:	b765                	j	800049a2 <fileread+0x60>
      return -1;
    800049fc:	597d                	li	s2,-1
    800049fe:	b755                	j	800049a2 <fileread+0x60>
    80004a00:	597d                	li	s2,-1
    80004a02:	b745                	j	800049a2 <fileread+0x60>

0000000080004a04 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a04:	715d                	addi	sp,sp,-80
    80004a06:	e486                	sd	ra,72(sp)
    80004a08:	e0a2                	sd	s0,64(sp)
    80004a0a:	fc26                	sd	s1,56(sp)
    80004a0c:	f84a                	sd	s2,48(sp)
    80004a0e:	f44e                	sd	s3,40(sp)
    80004a10:	f052                	sd	s4,32(sp)
    80004a12:	ec56                	sd	s5,24(sp)
    80004a14:	e85a                	sd	s6,16(sp)
    80004a16:	e45e                	sd	s7,8(sp)
    80004a18:	e062                	sd	s8,0(sp)
    80004a1a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a1c:	00954783          	lbu	a5,9(a0)
    80004a20:	10078663          	beqz	a5,80004b2c <filewrite+0x128>
    80004a24:	892a                	mv	s2,a0
    80004a26:	8aae                	mv	s5,a1
    80004a28:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a2a:	411c                	lw	a5,0(a0)
    80004a2c:	4705                	li	a4,1
    80004a2e:	02e78263          	beq	a5,a4,80004a52 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a32:	470d                	li	a4,3
    80004a34:	02e78663          	beq	a5,a4,80004a60 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a38:	4709                	li	a4,2
    80004a3a:	0ee79163          	bne	a5,a4,80004b1c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a3e:	0ac05d63          	blez	a2,80004af8 <filewrite+0xf4>
    int i = 0;
    80004a42:	4981                	li	s3,0
    80004a44:	6b05                	lui	s6,0x1
    80004a46:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a4a:	6b85                	lui	s7,0x1
    80004a4c:	c00b8b9b          	addiw	s7,s7,-1024
    80004a50:	a861                	j	80004ae8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a52:	6908                	ld	a0,16(a0)
    80004a54:	00000097          	auipc	ra,0x0
    80004a58:	22e080e7          	jalr	558(ra) # 80004c82 <pipewrite>
    80004a5c:	8a2a                	mv	s4,a0
    80004a5e:	a045                	j	80004afe <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a60:	02451783          	lh	a5,36(a0)
    80004a64:	03079693          	slli	a3,a5,0x30
    80004a68:	92c1                	srli	a3,a3,0x30
    80004a6a:	4725                	li	a4,9
    80004a6c:	0cd76263          	bltu	a4,a3,80004b30 <filewrite+0x12c>
    80004a70:	0792                	slli	a5,a5,0x4
    80004a72:	0001d717          	auipc	a4,0x1d
    80004a76:	3fe70713          	addi	a4,a4,1022 # 80021e70 <devsw>
    80004a7a:	97ba                	add	a5,a5,a4
    80004a7c:	679c                	ld	a5,8(a5)
    80004a7e:	cbdd                	beqz	a5,80004b34 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a80:	4505                	li	a0,1
    80004a82:	9782                	jalr	a5
    80004a84:	8a2a                	mv	s4,a0
    80004a86:	a8a5                	j	80004afe <filewrite+0xfa>
    80004a88:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	8b0080e7          	jalr	-1872(ra) # 8000433c <begin_op>
      ilock(f->ip);
    80004a94:	01893503          	ld	a0,24(s2)
    80004a98:	fffff097          	auipc	ra,0xfffff
    80004a9c:	ed2080e7          	jalr	-302(ra) # 8000396a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aa0:	8762                	mv	a4,s8
    80004aa2:	02092683          	lw	a3,32(s2)
    80004aa6:	01598633          	add	a2,s3,s5
    80004aaa:	4585                	li	a1,1
    80004aac:	01893503          	ld	a0,24(s2)
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	266080e7          	jalr	614(ra) # 80003d16 <writei>
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	00a05763          	blez	a0,80004ac8 <filewrite+0xc4>
        f->off += r;
    80004abe:	02092783          	lw	a5,32(s2)
    80004ac2:	9fa9                	addw	a5,a5,a0
    80004ac4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ac8:	01893503          	ld	a0,24(s2)
    80004acc:	fffff097          	auipc	ra,0xfffff
    80004ad0:	f60080e7          	jalr	-160(ra) # 80003a2c <iunlock>
      end_op();
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	8e8080e7          	jalr	-1816(ra) # 800043bc <end_op>

      if(r != n1){
    80004adc:	009c1f63          	bne	s8,s1,80004afa <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ae0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ae4:	0149db63          	bge	s3,s4,80004afa <filewrite+0xf6>
      int n1 = n - i;
    80004ae8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aec:	84be                	mv	s1,a5
    80004aee:	2781                	sext.w	a5,a5
    80004af0:	f8fb5ce3          	bge	s6,a5,80004a88 <filewrite+0x84>
    80004af4:	84de                	mv	s1,s7
    80004af6:	bf49                	j	80004a88 <filewrite+0x84>
    int i = 0;
    80004af8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004afa:	013a1f63          	bne	s4,s3,80004b18 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004afe:	8552                	mv	a0,s4
    80004b00:	60a6                	ld	ra,72(sp)
    80004b02:	6406                	ld	s0,64(sp)
    80004b04:	74e2                	ld	s1,56(sp)
    80004b06:	7942                	ld	s2,48(sp)
    80004b08:	79a2                	ld	s3,40(sp)
    80004b0a:	7a02                	ld	s4,32(sp)
    80004b0c:	6ae2                	ld	s5,24(sp)
    80004b0e:	6b42                	ld	s6,16(sp)
    80004b10:	6ba2                	ld	s7,8(sp)
    80004b12:	6c02                	ld	s8,0(sp)
    80004b14:	6161                	addi	sp,sp,80
    80004b16:	8082                	ret
    ret = (i == n ? n : -1);
    80004b18:	5a7d                	li	s4,-1
    80004b1a:	b7d5                	j	80004afe <filewrite+0xfa>
    panic("filewrite");
    80004b1c:	00004517          	auipc	a0,0x4
    80004b20:	c0450513          	addi	a0,a0,-1020 # 80008720 <syscalls+0x278>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	a1a080e7          	jalr	-1510(ra) # 8000053e <panic>
    return -1;
    80004b2c:	5a7d                	li	s4,-1
    80004b2e:	bfc1                	j	80004afe <filewrite+0xfa>
      return -1;
    80004b30:	5a7d                	li	s4,-1
    80004b32:	b7f1                	j	80004afe <filewrite+0xfa>
    80004b34:	5a7d                	li	s4,-1
    80004b36:	b7e1                	j	80004afe <filewrite+0xfa>

0000000080004b38 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b38:	7179                	addi	sp,sp,-48
    80004b3a:	f406                	sd	ra,40(sp)
    80004b3c:	f022                	sd	s0,32(sp)
    80004b3e:	ec26                	sd	s1,24(sp)
    80004b40:	e84a                	sd	s2,16(sp)
    80004b42:	e44e                	sd	s3,8(sp)
    80004b44:	e052                	sd	s4,0(sp)
    80004b46:	1800                	addi	s0,sp,48
    80004b48:	84aa                	mv	s1,a0
    80004b4a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b4c:	0005b023          	sd	zero,0(a1)
    80004b50:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b54:	00000097          	auipc	ra,0x0
    80004b58:	bf8080e7          	jalr	-1032(ra) # 8000474c <filealloc>
    80004b5c:	e088                	sd	a0,0(s1)
    80004b5e:	c551                	beqz	a0,80004bea <pipealloc+0xb2>
    80004b60:	00000097          	auipc	ra,0x0
    80004b64:	bec080e7          	jalr	-1044(ra) # 8000474c <filealloc>
    80004b68:	00aa3023          	sd	a0,0(s4)
    80004b6c:	c92d                	beqz	a0,80004bde <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	f86080e7          	jalr	-122(ra) # 80000af4 <kalloc>
    80004b76:	892a                	mv	s2,a0
    80004b78:	c125                	beqz	a0,80004bd8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b7a:	4985                	li	s3,1
    80004b7c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b80:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b84:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b88:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b8c:	00004597          	auipc	a1,0x4
    80004b90:	ba458593          	addi	a1,a1,-1116 # 80008730 <syscalls+0x288>
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	fc0080e7          	jalr	-64(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b9c:	609c                	ld	a5,0(s1)
    80004b9e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ba2:	609c                	ld	a5,0(s1)
    80004ba4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ba8:	609c                	ld	a5,0(s1)
    80004baa:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bae:	609c                	ld	a5,0(s1)
    80004bb0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bb4:	000a3783          	ld	a5,0(s4)
    80004bb8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bbc:	000a3783          	ld	a5,0(s4)
    80004bc0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bc4:	000a3783          	ld	a5,0(s4)
    80004bc8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bcc:	000a3783          	ld	a5,0(s4)
    80004bd0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bd4:	4501                	li	a0,0
    80004bd6:	a025                	j	80004bfe <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bd8:	6088                	ld	a0,0(s1)
    80004bda:	e501                	bnez	a0,80004be2 <pipealloc+0xaa>
    80004bdc:	a039                	j	80004bea <pipealloc+0xb2>
    80004bde:	6088                	ld	a0,0(s1)
    80004be0:	c51d                	beqz	a0,80004c0e <pipealloc+0xd6>
    fileclose(*f0);
    80004be2:	00000097          	auipc	ra,0x0
    80004be6:	c26080e7          	jalr	-986(ra) # 80004808 <fileclose>
  if(*f1)
    80004bea:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bee:	557d                	li	a0,-1
  if(*f1)
    80004bf0:	c799                	beqz	a5,80004bfe <pipealloc+0xc6>
    fileclose(*f1);
    80004bf2:	853e                	mv	a0,a5
    80004bf4:	00000097          	auipc	ra,0x0
    80004bf8:	c14080e7          	jalr	-1004(ra) # 80004808 <fileclose>
  return -1;
    80004bfc:	557d                	li	a0,-1
}
    80004bfe:	70a2                	ld	ra,40(sp)
    80004c00:	7402                	ld	s0,32(sp)
    80004c02:	64e2                	ld	s1,24(sp)
    80004c04:	6942                	ld	s2,16(sp)
    80004c06:	69a2                	ld	s3,8(sp)
    80004c08:	6a02                	ld	s4,0(sp)
    80004c0a:	6145                	addi	sp,sp,48
    80004c0c:	8082                	ret
  return -1;
    80004c0e:	557d                	li	a0,-1
    80004c10:	b7fd                	j	80004bfe <pipealloc+0xc6>

0000000080004c12 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c12:	1101                	addi	sp,sp,-32
    80004c14:	ec06                	sd	ra,24(sp)
    80004c16:	e822                	sd	s0,16(sp)
    80004c18:	e426                	sd	s1,8(sp)
    80004c1a:	e04a                	sd	s2,0(sp)
    80004c1c:	1000                	addi	s0,sp,32
    80004c1e:	84aa                	mv	s1,a0
    80004c20:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	fc2080e7          	jalr	-62(ra) # 80000be4 <acquire>
  if(writable){
    80004c2a:	02090d63          	beqz	s2,80004c64 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c2e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c32:	21848513          	addi	a0,s1,536
    80004c36:	ffffe097          	auipc	ra,0xffffe
    80004c3a:	914080e7          	jalr	-1772(ra) # 8000254a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c3e:	2204b783          	ld	a5,544(s1)
    80004c42:	eb95                	bnez	a5,80004c76 <pipeclose+0x64>
    release(&pi->lock);
    80004c44:	8526                	mv	a0,s1
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	052080e7          	jalr	82(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c4e:	8526                	mv	a0,s1
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	da8080e7          	jalr	-600(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c58:	60e2                	ld	ra,24(sp)
    80004c5a:	6442                	ld	s0,16(sp)
    80004c5c:	64a2                	ld	s1,8(sp)
    80004c5e:	6902                	ld	s2,0(sp)
    80004c60:	6105                	addi	sp,sp,32
    80004c62:	8082                	ret
    pi->readopen = 0;
    80004c64:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c68:	21c48513          	addi	a0,s1,540
    80004c6c:	ffffe097          	auipc	ra,0xffffe
    80004c70:	8de080e7          	jalr	-1826(ra) # 8000254a <wakeup>
    80004c74:	b7e9                	j	80004c3e <pipeclose+0x2c>
    release(&pi->lock);
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	020080e7          	jalr	32(ra) # 80000c98 <release>
}
    80004c80:	bfe1                	j	80004c58 <pipeclose+0x46>

0000000080004c82 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c82:	7159                	addi	sp,sp,-112
    80004c84:	f486                	sd	ra,104(sp)
    80004c86:	f0a2                	sd	s0,96(sp)
    80004c88:	eca6                	sd	s1,88(sp)
    80004c8a:	e8ca                	sd	s2,80(sp)
    80004c8c:	e4ce                	sd	s3,72(sp)
    80004c8e:	e0d2                	sd	s4,64(sp)
    80004c90:	fc56                	sd	s5,56(sp)
    80004c92:	f85a                	sd	s6,48(sp)
    80004c94:	f45e                	sd	s7,40(sp)
    80004c96:	f062                	sd	s8,32(sp)
    80004c98:	ec66                	sd	s9,24(sp)
    80004c9a:	1880                	addi	s0,sp,112
    80004c9c:	84aa                	mv	s1,a0
    80004c9e:	8aae                	mv	s5,a1
    80004ca0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	fd6080e7          	jalr	-42(ra) # 80001c78 <myproc>
    80004caa:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	f36080e7          	jalr	-202(ra) # 80000be4 <acquire>
  while(i < n){
    80004cb6:	0d405163          	blez	s4,80004d78 <pipewrite+0xf6>
    80004cba:	8ba6                	mv	s7,s1
  int i = 0;
    80004cbc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cbe:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cc0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cc4:	21c48c13          	addi	s8,s1,540
    80004cc8:	a08d                	j	80004d2a <pipewrite+0xa8>
      release(&pi->lock);
    80004cca:	8526                	mv	a0,s1
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	fcc080e7          	jalr	-52(ra) # 80000c98 <release>
      return -1;
    80004cd4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cd6:	854a                	mv	a0,s2
    80004cd8:	70a6                	ld	ra,104(sp)
    80004cda:	7406                	ld	s0,96(sp)
    80004cdc:	64e6                	ld	s1,88(sp)
    80004cde:	6946                	ld	s2,80(sp)
    80004ce0:	69a6                	ld	s3,72(sp)
    80004ce2:	6a06                	ld	s4,64(sp)
    80004ce4:	7ae2                	ld	s5,56(sp)
    80004ce6:	7b42                	ld	s6,48(sp)
    80004ce8:	7ba2                	ld	s7,40(sp)
    80004cea:	7c02                	ld	s8,32(sp)
    80004cec:	6ce2                	ld	s9,24(sp)
    80004cee:	6165                	addi	sp,sp,112
    80004cf0:	8082                	ret
      wakeup(&pi->nread);
    80004cf2:	8566                	mv	a0,s9
    80004cf4:	ffffe097          	auipc	ra,0xffffe
    80004cf8:	856080e7          	jalr	-1962(ra) # 8000254a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cfc:	85de                	mv	a1,s7
    80004cfe:	8562                	mv	a0,s8
    80004d00:	ffffd097          	auipc	ra,0xffffd
    80004d04:	6be080e7          	jalr	1726(ra) # 800023be <sleep>
    80004d08:	a839                	j	80004d26 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d0a:	21c4a783          	lw	a5,540(s1)
    80004d0e:	0017871b          	addiw	a4,a5,1
    80004d12:	20e4ae23          	sw	a4,540(s1)
    80004d16:	1ff7f793          	andi	a5,a5,511
    80004d1a:	97a6                	add	a5,a5,s1
    80004d1c:	f9f44703          	lbu	a4,-97(s0)
    80004d20:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d24:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d26:	03495d63          	bge	s2,s4,80004d60 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d2a:	2204a783          	lw	a5,544(s1)
    80004d2e:	dfd1                	beqz	a5,80004cca <pipewrite+0x48>
    80004d30:	0409a783          	lw	a5,64(s3)
    80004d34:	fbd9                	bnez	a5,80004cca <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d36:	2184a783          	lw	a5,536(s1)
    80004d3a:	21c4a703          	lw	a4,540(s1)
    80004d3e:	2007879b          	addiw	a5,a5,512
    80004d42:	faf708e3          	beq	a4,a5,80004cf2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d46:	4685                	li	a3,1
    80004d48:	01590633          	add	a2,s2,s5
    80004d4c:	f9f40593          	addi	a1,s0,-97
    80004d50:	0789b503          	ld	a0,120(s3)
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	9aa080e7          	jalr	-1622(ra) # 800016fe <copyin>
    80004d5c:	fb6517e3          	bne	a0,s6,80004d0a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d60:	21848513          	addi	a0,s1,536
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	7e6080e7          	jalr	2022(ra) # 8000254a <wakeup>
  release(&pi->lock);
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	ffffc097          	auipc	ra,0xffffc
    80004d72:	f2a080e7          	jalr	-214(ra) # 80000c98 <release>
  return i;
    80004d76:	b785                	j	80004cd6 <pipewrite+0x54>
  int i = 0;
    80004d78:	4901                	li	s2,0
    80004d7a:	b7dd                	j	80004d60 <pipewrite+0xde>

0000000080004d7c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d7c:	715d                	addi	sp,sp,-80
    80004d7e:	e486                	sd	ra,72(sp)
    80004d80:	e0a2                	sd	s0,64(sp)
    80004d82:	fc26                	sd	s1,56(sp)
    80004d84:	f84a                	sd	s2,48(sp)
    80004d86:	f44e                	sd	s3,40(sp)
    80004d88:	f052                	sd	s4,32(sp)
    80004d8a:	ec56                	sd	s5,24(sp)
    80004d8c:	e85a                	sd	s6,16(sp)
    80004d8e:	0880                	addi	s0,sp,80
    80004d90:	84aa                	mv	s1,a0
    80004d92:	892e                	mv	s2,a1
    80004d94:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d96:	ffffd097          	auipc	ra,0xffffd
    80004d9a:	ee2080e7          	jalr	-286(ra) # 80001c78 <myproc>
    80004d9e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004da0:	8b26                	mv	s6,s1
    80004da2:	8526                	mv	a0,s1
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	e40080e7          	jalr	-448(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dac:	2184a703          	lw	a4,536(s1)
    80004db0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004db4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004db8:	02f71463          	bne	a4,a5,80004de0 <piperead+0x64>
    80004dbc:	2244a783          	lw	a5,548(s1)
    80004dc0:	c385                	beqz	a5,80004de0 <piperead+0x64>
    if(pr->killed){
    80004dc2:	040a2783          	lw	a5,64(s4)
    80004dc6:	ebc1                	bnez	a5,80004e56 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dc8:	85da                	mv	a1,s6
    80004dca:	854e                	mv	a0,s3
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	5f2080e7          	jalr	1522(ra) # 800023be <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dd4:	2184a703          	lw	a4,536(s1)
    80004dd8:	21c4a783          	lw	a5,540(s1)
    80004ddc:	fef700e3          	beq	a4,a5,80004dbc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004de0:	09505263          	blez	s5,80004e64 <piperead+0xe8>
    80004de4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004de6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004de8:	2184a783          	lw	a5,536(s1)
    80004dec:	21c4a703          	lw	a4,540(s1)
    80004df0:	02f70d63          	beq	a4,a5,80004e2a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004df4:	0017871b          	addiw	a4,a5,1
    80004df8:	20e4ac23          	sw	a4,536(s1)
    80004dfc:	1ff7f793          	andi	a5,a5,511
    80004e00:	97a6                	add	a5,a5,s1
    80004e02:	0187c783          	lbu	a5,24(a5)
    80004e06:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e0a:	4685                	li	a3,1
    80004e0c:	fbf40613          	addi	a2,s0,-65
    80004e10:	85ca                	mv	a1,s2
    80004e12:	078a3503          	ld	a0,120(s4)
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	85c080e7          	jalr	-1956(ra) # 80001672 <copyout>
    80004e1e:	01650663          	beq	a0,s6,80004e2a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e22:	2985                	addiw	s3,s3,1
    80004e24:	0905                	addi	s2,s2,1
    80004e26:	fd3a91e3          	bne	s5,s3,80004de8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e2a:	21c48513          	addi	a0,s1,540
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	71c080e7          	jalr	1820(ra) # 8000254a <wakeup>
  release(&pi->lock);
    80004e36:	8526                	mv	a0,s1
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	e60080e7          	jalr	-416(ra) # 80000c98 <release>
  return i;
}
    80004e40:	854e                	mv	a0,s3
    80004e42:	60a6                	ld	ra,72(sp)
    80004e44:	6406                	ld	s0,64(sp)
    80004e46:	74e2                	ld	s1,56(sp)
    80004e48:	7942                	ld	s2,48(sp)
    80004e4a:	79a2                	ld	s3,40(sp)
    80004e4c:	7a02                	ld	s4,32(sp)
    80004e4e:	6ae2                	ld	s5,24(sp)
    80004e50:	6b42                	ld	s6,16(sp)
    80004e52:	6161                	addi	sp,sp,80
    80004e54:	8082                	ret
      release(&pi->lock);
    80004e56:	8526                	mv	a0,s1
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	e40080e7          	jalr	-448(ra) # 80000c98 <release>
      return -1;
    80004e60:	59fd                	li	s3,-1
    80004e62:	bff9                	j	80004e40 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e64:	4981                	li	s3,0
    80004e66:	b7d1                	j	80004e2a <piperead+0xae>

0000000080004e68 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e68:	df010113          	addi	sp,sp,-528
    80004e6c:	20113423          	sd	ra,520(sp)
    80004e70:	20813023          	sd	s0,512(sp)
    80004e74:	ffa6                	sd	s1,504(sp)
    80004e76:	fbca                	sd	s2,496(sp)
    80004e78:	f7ce                	sd	s3,488(sp)
    80004e7a:	f3d2                	sd	s4,480(sp)
    80004e7c:	efd6                	sd	s5,472(sp)
    80004e7e:	ebda                	sd	s6,464(sp)
    80004e80:	e7de                	sd	s7,456(sp)
    80004e82:	e3e2                	sd	s8,448(sp)
    80004e84:	ff66                	sd	s9,440(sp)
    80004e86:	fb6a                	sd	s10,432(sp)
    80004e88:	f76e                	sd	s11,424(sp)
    80004e8a:	0c00                	addi	s0,sp,528
    80004e8c:	84aa                	mv	s1,a0
    80004e8e:	dea43c23          	sd	a0,-520(s0)
    80004e92:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e96:	ffffd097          	auipc	ra,0xffffd
    80004e9a:	de2080e7          	jalr	-542(ra) # 80001c78 <myproc>
    80004e9e:	892a                	mv	s2,a0

  begin_op();
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	49c080e7          	jalr	1180(ra) # 8000433c <begin_op>

  if((ip = namei(path)) == 0){
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	fffff097          	auipc	ra,0xfffff
    80004eae:	276080e7          	jalr	630(ra) # 80004120 <namei>
    80004eb2:	c92d                	beqz	a0,80004f24 <exec+0xbc>
    80004eb4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004eb6:	fffff097          	auipc	ra,0xfffff
    80004eba:	ab4080e7          	jalr	-1356(ra) # 8000396a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ebe:	04000713          	li	a4,64
    80004ec2:	4681                	li	a3,0
    80004ec4:	e5040613          	addi	a2,s0,-432
    80004ec8:	4581                	li	a1,0
    80004eca:	8526                	mv	a0,s1
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	d52080e7          	jalr	-686(ra) # 80003c1e <readi>
    80004ed4:	04000793          	li	a5,64
    80004ed8:	00f51a63          	bne	a0,a5,80004eec <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004edc:	e5042703          	lw	a4,-432(s0)
    80004ee0:	464c47b7          	lui	a5,0x464c4
    80004ee4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ee8:	04f70463          	beq	a4,a5,80004f30 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004eec:	8526                	mv	a0,s1
    80004eee:	fffff097          	auipc	ra,0xfffff
    80004ef2:	cde080e7          	jalr	-802(ra) # 80003bcc <iunlockput>
    end_op();
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	4c6080e7          	jalr	1222(ra) # 800043bc <end_op>
  }
  return -1;
    80004efe:	557d                	li	a0,-1
}
    80004f00:	20813083          	ld	ra,520(sp)
    80004f04:	20013403          	ld	s0,512(sp)
    80004f08:	74fe                	ld	s1,504(sp)
    80004f0a:	795e                	ld	s2,496(sp)
    80004f0c:	79be                	ld	s3,488(sp)
    80004f0e:	7a1e                	ld	s4,480(sp)
    80004f10:	6afe                	ld	s5,472(sp)
    80004f12:	6b5e                	ld	s6,464(sp)
    80004f14:	6bbe                	ld	s7,456(sp)
    80004f16:	6c1e                	ld	s8,448(sp)
    80004f18:	7cfa                	ld	s9,440(sp)
    80004f1a:	7d5a                	ld	s10,432(sp)
    80004f1c:	7dba                	ld	s11,424(sp)
    80004f1e:	21010113          	addi	sp,sp,528
    80004f22:	8082                	ret
    end_op();
    80004f24:	fffff097          	auipc	ra,0xfffff
    80004f28:	498080e7          	jalr	1176(ra) # 800043bc <end_op>
    return -1;
    80004f2c:	557d                	li	a0,-1
    80004f2e:	bfc9                	j	80004f00 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f30:	854a                	mv	a0,s2
    80004f32:	ffffd097          	auipc	ra,0xffffd
    80004f36:	e20080e7          	jalr	-480(ra) # 80001d52 <proc_pagetable>
    80004f3a:	8baa                	mv	s7,a0
    80004f3c:	d945                	beqz	a0,80004eec <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f3e:	e7042983          	lw	s3,-400(s0)
    80004f42:	e8845783          	lhu	a5,-376(s0)
    80004f46:	c7ad                	beqz	a5,80004fb0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f48:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f4a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f4c:	6c85                	lui	s9,0x1
    80004f4e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f52:	def43823          	sd	a5,-528(s0)
    80004f56:	a42d                	j	80005180 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f58:	00003517          	auipc	a0,0x3
    80004f5c:	7e050513          	addi	a0,a0,2016 # 80008738 <syscalls+0x290>
    80004f60:	ffffb097          	auipc	ra,0xffffb
    80004f64:	5de080e7          	jalr	1502(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f68:	8756                	mv	a4,s5
    80004f6a:	012d86bb          	addw	a3,s11,s2
    80004f6e:	4581                	li	a1,0
    80004f70:	8526                	mv	a0,s1
    80004f72:	fffff097          	auipc	ra,0xfffff
    80004f76:	cac080e7          	jalr	-852(ra) # 80003c1e <readi>
    80004f7a:	2501                	sext.w	a0,a0
    80004f7c:	1aaa9963          	bne	s5,a0,8000512e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f80:	6785                	lui	a5,0x1
    80004f82:	0127893b          	addw	s2,a5,s2
    80004f86:	77fd                	lui	a5,0xfffff
    80004f88:	01478a3b          	addw	s4,a5,s4
    80004f8c:	1f897163          	bgeu	s2,s8,8000516e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f90:	02091593          	slli	a1,s2,0x20
    80004f94:	9181                	srli	a1,a1,0x20
    80004f96:	95ea                	add	a1,a1,s10
    80004f98:	855e                	mv	a0,s7
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	0d4080e7          	jalr	212(ra) # 8000106e <walkaddr>
    80004fa2:	862a                	mv	a2,a0
    if(pa == 0)
    80004fa4:	d955                	beqz	a0,80004f58 <exec+0xf0>
      n = PGSIZE;
    80004fa6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fa8:	fd9a70e3          	bgeu	s4,s9,80004f68 <exec+0x100>
      n = sz - i;
    80004fac:	8ad2                	mv	s5,s4
    80004fae:	bf6d                	j	80004f68 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fb0:	4901                	li	s2,0
  iunlockput(ip);
    80004fb2:	8526                	mv	a0,s1
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	c18080e7          	jalr	-1000(ra) # 80003bcc <iunlockput>
  end_op();
    80004fbc:	fffff097          	auipc	ra,0xfffff
    80004fc0:	400080e7          	jalr	1024(ra) # 800043bc <end_op>
  p = myproc();
    80004fc4:	ffffd097          	auipc	ra,0xffffd
    80004fc8:	cb4080e7          	jalr	-844(ra) # 80001c78 <myproc>
    80004fcc:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fce:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80004fd2:	6785                	lui	a5,0x1
    80004fd4:	17fd                	addi	a5,a5,-1
    80004fd6:	993e                	add	s2,s2,a5
    80004fd8:	757d                	lui	a0,0xfffff
    80004fda:	00a977b3          	and	a5,s2,a0
    80004fde:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fe2:	6609                	lui	a2,0x2
    80004fe4:	963e                	add	a2,a2,a5
    80004fe6:	85be                	mv	a1,a5
    80004fe8:	855e                	mv	a0,s7
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	438080e7          	jalr	1080(ra) # 80001422 <uvmalloc>
    80004ff2:	8b2a                	mv	s6,a0
  ip = 0;
    80004ff4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ff6:	12050c63          	beqz	a0,8000512e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ffa:	75f9                	lui	a1,0xffffe
    80004ffc:	95aa                	add	a1,a1,a0
    80004ffe:	855e                	mv	a0,s7
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	640080e7          	jalr	1600(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005008:	7c7d                	lui	s8,0xfffff
    8000500a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000500c:	e0043783          	ld	a5,-512(s0)
    80005010:	6388                	ld	a0,0(a5)
    80005012:	c535                	beqz	a0,8000507e <exec+0x216>
    80005014:	e9040993          	addi	s3,s0,-368
    80005018:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000501c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	e46080e7          	jalr	-442(ra) # 80000e64 <strlen>
    80005026:	2505                	addiw	a0,a0,1
    80005028:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000502c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005030:	13896363          	bltu	s2,s8,80005156 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005034:	e0043d83          	ld	s11,-512(s0)
    80005038:	000dba03          	ld	s4,0(s11)
    8000503c:	8552                	mv	a0,s4
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	e26080e7          	jalr	-474(ra) # 80000e64 <strlen>
    80005046:	0015069b          	addiw	a3,a0,1
    8000504a:	8652                	mv	a2,s4
    8000504c:	85ca                	mv	a1,s2
    8000504e:	855e                	mv	a0,s7
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	622080e7          	jalr	1570(ra) # 80001672 <copyout>
    80005058:	10054363          	bltz	a0,8000515e <exec+0x2f6>
    ustack[argc] = sp;
    8000505c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005060:	0485                	addi	s1,s1,1
    80005062:	008d8793          	addi	a5,s11,8
    80005066:	e0f43023          	sd	a5,-512(s0)
    8000506a:	008db503          	ld	a0,8(s11)
    8000506e:	c911                	beqz	a0,80005082 <exec+0x21a>
    if(argc >= MAXARG)
    80005070:	09a1                	addi	s3,s3,8
    80005072:	fb3c96e3          	bne	s9,s3,8000501e <exec+0x1b6>
  sz = sz1;
    80005076:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000507a:	4481                	li	s1,0
    8000507c:	a84d                	j	8000512e <exec+0x2c6>
  sp = sz;
    8000507e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005080:	4481                	li	s1,0
  ustack[argc] = 0;
    80005082:	00349793          	slli	a5,s1,0x3
    80005086:	f9040713          	addi	a4,s0,-112
    8000508a:	97ba                	add	a5,a5,a4
    8000508c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005090:	00148693          	addi	a3,s1,1
    80005094:	068e                	slli	a3,a3,0x3
    80005096:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000509a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000509e:	01897663          	bgeu	s2,s8,800050aa <exec+0x242>
  sz = sz1;
    800050a2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050a6:	4481                	li	s1,0
    800050a8:	a059                	j	8000512e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050aa:	e9040613          	addi	a2,s0,-368
    800050ae:	85ca                	mv	a1,s2
    800050b0:	855e                	mv	a0,s7
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	5c0080e7          	jalr	1472(ra) # 80001672 <copyout>
    800050ba:	0a054663          	bltz	a0,80005166 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050be:	080ab783          	ld	a5,128(s5)
    800050c2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050c6:	df843783          	ld	a5,-520(s0)
    800050ca:	0007c703          	lbu	a4,0(a5)
    800050ce:	cf11                	beqz	a4,800050ea <exec+0x282>
    800050d0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050d2:	02f00693          	li	a3,47
    800050d6:	a039                	j	800050e4 <exec+0x27c>
      last = s+1;
    800050d8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050dc:	0785                	addi	a5,a5,1
    800050de:	fff7c703          	lbu	a4,-1(a5)
    800050e2:	c701                	beqz	a4,800050ea <exec+0x282>
    if(*s == '/')
    800050e4:	fed71ce3          	bne	a4,a3,800050dc <exec+0x274>
    800050e8:	bfc5                	j	800050d8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050ea:	4641                	li	a2,16
    800050ec:	df843583          	ld	a1,-520(s0)
    800050f0:	180a8513          	addi	a0,s5,384
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	d3e080e7          	jalr	-706(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800050fc:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    80005100:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    80005104:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005108:	080ab783          	ld	a5,128(s5)
    8000510c:	e6843703          	ld	a4,-408(s0)
    80005110:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005112:	080ab783          	ld	a5,128(s5)
    80005116:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000511a:	85ea                	mv	a1,s10
    8000511c:	ffffd097          	auipc	ra,0xffffd
    80005120:	cd2080e7          	jalr	-814(ra) # 80001dee <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005124:	0004851b          	sext.w	a0,s1
    80005128:	bbe1                	j	80004f00 <exec+0x98>
    8000512a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000512e:	e0843583          	ld	a1,-504(s0)
    80005132:	855e                	mv	a0,s7
    80005134:	ffffd097          	auipc	ra,0xffffd
    80005138:	cba080e7          	jalr	-838(ra) # 80001dee <proc_freepagetable>
  if(ip){
    8000513c:	da0498e3          	bnez	s1,80004eec <exec+0x84>
  return -1;
    80005140:	557d                	li	a0,-1
    80005142:	bb7d                	j	80004f00 <exec+0x98>
    80005144:	e1243423          	sd	s2,-504(s0)
    80005148:	b7dd                	j	8000512e <exec+0x2c6>
    8000514a:	e1243423          	sd	s2,-504(s0)
    8000514e:	b7c5                	j	8000512e <exec+0x2c6>
    80005150:	e1243423          	sd	s2,-504(s0)
    80005154:	bfe9                	j	8000512e <exec+0x2c6>
  sz = sz1;
    80005156:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000515a:	4481                	li	s1,0
    8000515c:	bfc9                	j	8000512e <exec+0x2c6>
  sz = sz1;
    8000515e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005162:	4481                	li	s1,0
    80005164:	b7e9                	j	8000512e <exec+0x2c6>
  sz = sz1;
    80005166:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000516a:	4481                	li	s1,0
    8000516c:	b7c9                	j	8000512e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000516e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005172:	2b05                	addiw	s6,s6,1
    80005174:	0389899b          	addiw	s3,s3,56
    80005178:	e8845783          	lhu	a5,-376(s0)
    8000517c:	e2fb5be3          	bge	s6,a5,80004fb2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005180:	2981                	sext.w	s3,s3
    80005182:	03800713          	li	a4,56
    80005186:	86ce                	mv	a3,s3
    80005188:	e1840613          	addi	a2,s0,-488
    8000518c:	4581                	li	a1,0
    8000518e:	8526                	mv	a0,s1
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	a8e080e7          	jalr	-1394(ra) # 80003c1e <readi>
    80005198:	03800793          	li	a5,56
    8000519c:	f8f517e3          	bne	a0,a5,8000512a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051a0:	e1842783          	lw	a5,-488(s0)
    800051a4:	4705                	li	a4,1
    800051a6:	fce796e3          	bne	a5,a4,80005172 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800051aa:	e4043603          	ld	a2,-448(s0)
    800051ae:	e3843783          	ld	a5,-456(s0)
    800051b2:	f8f669e3          	bltu	a2,a5,80005144 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051b6:	e2843783          	ld	a5,-472(s0)
    800051ba:	963e                	add	a2,a2,a5
    800051bc:	f8f667e3          	bltu	a2,a5,8000514a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051c0:	85ca                	mv	a1,s2
    800051c2:	855e                	mv	a0,s7
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	25e080e7          	jalr	606(ra) # 80001422 <uvmalloc>
    800051cc:	e0a43423          	sd	a0,-504(s0)
    800051d0:	d141                	beqz	a0,80005150 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800051d2:	e2843d03          	ld	s10,-472(s0)
    800051d6:	df043783          	ld	a5,-528(s0)
    800051da:	00fd77b3          	and	a5,s10,a5
    800051de:	fba1                	bnez	a5,8000512e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051e0:	e2042d83          	lw	s11,-480(s0)
    800051e4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051e8:	f80c03e3          	beqz	s8,8000516e <exec+0x306>
    800051ec:	8a62                	mv	s4,s8
    800051ee:	4901                	li	s2,0
    800051f0:	b345                	j	80004f90 <exec+0x128>

00000000800051f2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051f2:	7179                	addi	sp,sp,-48
    800051f4:	f406                	sd	ra,40(sp)
    800051f6:	f022                	sd	s0,32(sp)
    800051f8:	ec26                	sd	s1,24(sp)
    800051fa:	e84a                	sd	s2,16(sp)
    800051fc:	1800                	addi	s0,sp,48
    800051fe:	892e                	mv	s2,a1
    80005200:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005202:	fdc40593          	addi	a1,s0,-36
    80005206:	ffffe097          	auipc	ra,0xffffe
    8000520a:	ba8080e7          	jalr	-1112(ra) # 80002dae <argint>
    8000520e:	04054063          	bltz	a0,8000524e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005212:	fdc42703          	lw	a4,-36(s0)
    80005216:	47bd                	li	a5,15
    80005218:	02e7ed63          	bltu	a5,a4,80005252 <argfd+0x60>
    8000521c:	ffffd097          	auipc	ra,0xffffd
    80005220:	a5c080e7          	jalr	-1444(ra) # 80001c78 <myproc>
    80005224:	fdc42703          	lw	a4,-36(s0)
    80005228:	01e70793          	addi	a5,a4,30
    8000522c:	078e                	slli	a5,a5,0x3
    8000522e:	953e                	add	a0,a0,a5
    80005230:	651c                	ld	a5,8(a0)
    80005232:	c395                	beqz	a5,80005256 <argfd+0x64>
    return -1;
  if(pfd)
    80005234:	00090463          	beqz	s2,8000523c <argfd+0x4a>
    *pfd = fd;
    80005238:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000523c:	4501                	li	a0,0
  if(pf)
    8000523e:	c091                	beqz	s1,80005242 <argfd+0x50>
    *pf = f;
    80005240:	e09c                	sd	a5,0(s1)
}
    80005242:	70a2                	ld	ra,40(sp)
    80005244:	7402                	ld	s0,32(sp)
    80005246:	64e2                	ld	s1,24(sp)
    80005248:	6942                	ld	s2,16(sp)
    8000524a:	6145                	addi	sp,sp,48
    8000524c:	8082                	ret
    return -1;
    8000524e:	557d                	li	a0,-1
    80005250:	bfcd                	j	80005242 <argfd+0x50>
    return -1;
    80005252:	557d                	li	a0,-1
    80005254:	b7fd                	j	80005242 <argfd+0x50>
    80005256:	557d                	li	a0,-1
    80005258:	b7ed                	j	80005242 <argfd+0x50>

000000008000525a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000525a:	1101                	addi	sp,sp,-32
    8000525c:	ec06                	sd	ra,24(sp)
    8000525e:	e822                	sd	s0,16(sp)
    80005260:	e426                	sd	s1,8(sp)
    80005262:	1000                	addi	s0,sp,32
    80005264:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005266:	ffffd097          	auipc	ra,0xffffd
    8000526a:	a12080e7          	jalr	-1518(ra) # 80001c78 <myproc>
    8000526e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005270:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    80005274:	4501                	li	a0,0
    80005276:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005278:	6398                	ld	a4,0(a5)
    8000527a:	cb19                	beqz	a4,80005290 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000527c:	2505                	addiw	a0,a0,1
    8000527e:	07a1                	addi	a5,a5,8
    80005280:	fed51ce3          	bne	a0,a3,80005278 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005284:	557d                	li	a0,-1
}
    80005286:	60e2                	ld	ra,24(sp)
    80005288:	6442                	ld	s0,16(sp)
    8000528a:	64a2                	ld	s1,8(sp)
    8000528c:	6105                	addi	sp,sp,32
    8000528e:	8082                	ret
      p->ofile[fd] = f;
    80005290:	01e50793          	addi	a5,a0,30
    80005294:	078e                	slli	a5,a5,0x3
    80005296:	963e                	add	a2,a2,a5
    80005298:	e604                	sd	s1,8(a2)
      return fd;
    8000529a:	b7f5                	j	80005286 <fdalloc+0x2c>

000000008000529c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000529c:	715d                	addi	sp,sp,-80
    8000529e:	e486                	sd	ra,72(sp)
    800052a0:	e0a2                	sd	s0,64(sp)
    800052a2:	fc26                	sd	s1,56(sp)
    800052a4:	f84a                	sd	s2,48(sp)
    800052a6:	f44e                	sd	s3,40(sp)
    800052a8:	f052                	sd	s4,32(sp)
    800052aa:	ec56                	sd	s5,24(sp)
    800052ac:	0880                	addi	s0,sp,80
    800052ae:	89ae                	mv	s3,a1
    800052b0:	8ab2                	mv	s5,a2
    800052b2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052b4:	fb040593          	addi	a1,s0,-80
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	e86080e7          	jalr	-378(ra) # 8000413e <nameiparent>
    800052c0:	892a                	mv	s2,a0
    800052c2:	12050f63          	beqz	a0,80005400 <create+0x164>
    return 0;

  ilock(dp);
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	6a4080e7          	jalr	1700(ra) # 8000396a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052ce:	4601                	li	a2,0
    800052d0:	fb040593          	addi	a1,s0,-80
    800052d4:	854a                	mv	a0,s2
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	b78080e7          	jalr	-1160(ra) # 80003e4e <dirlookup>
    800052de:	84aa                	mv	s1,a0
    800052e0:	c921                	beqz	a0,80005330 <create+0x94>
    iunlockput(dp);
    800052e2:	854a                	mv	a0,s2
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	8e8080e7          	jalr	-1816(ra) # 80003bcc <iunlockput>
    ilock(ip);
    800052ec:	8526                	mv	a0,s1
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	67c080e7          	jalr	1660(ra) # 8000396a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052f6:	2981                	sext.w	s3,s3
    800052f8:	4789                	li	a5,2
    800052fa:	02f99463          	bne	s3,a5,80005322 <create+0x86>
    800052fe:	0444d783          	lhu	a5,68(s1)
    80005302:	37f9                	addiw	a5,a5,-2
    80005304:	17c2                	slli	a5,a5,0x30
    80005306:	93c1                	srli	a5,a5,0x30
    80005308:	4705                	li	a4,1
    8000530a:	00f76c63          	bltu	a4,a5,80005322 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000530e:	8526                	mv	a0,s1
    80005310:	60a6                	ld	ra,72(sp)
    80005312:	6406                	ld	s0,64(sp)
    80005314:	74e2                	ld	s1,56(sp)
    80005316:	7942                	ld	s2,48(sp)
    80005318:	79a2                	ld	s3,40(sp)
    8000531a:	7a02                	ld	s4,32(sp)
    8000531c:	6ae2                	ld	s5,24(sp)
    8000531e:	6161                	addi	sp,sp,80
    80005320:	8082                	ret
    iunlockput(ip);
    80005322:	8526                	mv	a0,s1
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	8a8080e7          	jalr	-1880(ra) # 80003bcc <iunlockput>
    return 0;
    8000532c:	4481                	li	s1,0
    8000532e:	b7c5                	j	8000530e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005330:	85ce                	mv	a1,s3
    80005332:	00092503          	lw	a0,0(s2)
    80005336:	ffffe097          	auipc	ra,0xffffe
    8000533a:	49c080e7          	jalr	1180(ra) # 800037d2 <ialloc>
    8000533e:	84aa                	mv	s1,a0
    80005340:	c529                	beqz	a0,8000538a <create+0xee>
  ilock(ip);
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	628080e7          	jalr	1576(ra) # 8000396a <ilock>
  ip->major = major;
    8000534a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000534e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005352:	4785                	li	a5,1
    80005354:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005358:	8526                	mv	a0,s1
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	546080e7          	jalr	1350(ra) # 800038a0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005362:	2981                	sext.w	s3,s3
    80005364:	4785                	li	a5,1
    80005366:	02f98a63          	beq	s3,a5,8000539a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000536a:	40d0                	lw	a2,4(s1)
    8000536c:	fb040593          	addi	a1,s0,-80
    80005370:	854a                	mv	a0,s2
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	cec080e7          	jalr	-788(ra) # 8000405e <dirlink>
    8000537a:	06054b63          	bltz	a0,800053f0 <create+0x154>
  iunlockput(dp);
    8000537e:	854a                	mv	a0,s2
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	84c080e7          	jalr	-1972(ra) # 80003bcc <iunlockput>
  return ip;
    80005388:	b759                	j	8000530e <create+0x72>
    panic("create: ialloc");
    8000538a:	00003517          	auipc	a0,0x3
    8000538e:	3ce50513          	addi	a0,a0,974 # 80008758 <syscalls+0x2b0>
    80005392:	ffffb097          	auipc	ra,0xffffb
    80005396:	1ac080e7          	jalr	428(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000539a:	04a95783          	lhu	a5,74(s2)
    8000539e:	2785                	addiw	a5,a5,1
    800053a0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053a4:	854a                	mv	a0,s2
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	4fa080e7          	jalr	1274(ra) # 800038a0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053ae:	40d0                	lw	a2,4(s1)
    800053b0:	00003597          	auipc	a1,0x3
    800053b4:	3b858593          	addi	a1,a1,952 # 80008768 <syscalls+0x2c0>
    800053b8:	8526                	mv	a0,s1
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	ca4080e7          	jalr	-860(ra) # 8000405e <dirlink>
    800053c2:	00054f63          	bltz	a0,800053e0 <create+0x144>
    800053c6:	00492603          	lw	a2,4(s2)
    800053ca:	00003597          	auipc	a1,0x3
    800053ce:	3a658593          	addi	a1,a1,934 # 80008770 <syscalls+0x2c8>
    800053d2:	8526                	mv	a0,s1
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	c8a080e7          	jalr	-886(ra) # 8000405e <dirlink>
    800053dc:	f80557e3          	bgez	a0,8000536a <create+0xce>
      panic("create dots");
    800053e0:	00003517          	auipc	a0,0x3
    800053e4:	39850513          	addi	a0,a0,920 # 80008778 <syscalls+0x2d0>
    800053e8:	ffffb097          	auipc	ra,0xffffb
    800053ec:	156080e7          	jalr	342(ra) # 8000053e <panic>
    panic("create: dirlink");
    800053f0:	00003517          	auipc	a0,0x3
    800053f4:	39850513          	addi	a0,a0,920 # 80008788 <syscalls+0x2e0>
    800053f8:	ffffb097          	auipc	ra,0xffffb
    800053fc:	146080e7          	jalr	326(ra) # 8000053e <panic>
    return 0;
    80005400:	84aa                	mv	s1,a0
    80005402:	b731                	j	8000530e <create+0x72>

0000000080005404 <sys_dup>:
{
    80005404:	7179                	addi	sp,sp,-48
    80005406:	f406                	sd	ra,40(sp)
    80005408:	f022                	sd	s0,32(sp)
    8000540a:	ec26                	sd	s1,24(sp)
    8000540c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000540e:	fd840613          	addi	a2,s0,-40
    80005412:	4581                	li	a1,0
    80005414:	4501                	li	a0,0
    80005416:	00000097          	auipc	ra,0x0
    8000541a:	ddc080e7          	jalr	-548(ra) # 800051f2 <argfd>
    return -1;
    8000541e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005420:	02054363          	bltz	a0,80005446 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005424:	fd843503          	ld	a0,-40(s0)
    80005428:	00000097          	auipc	ra,0x0
    8000542c:	e32080e7          	jalr	-462(ra) # 8000525a <fdalloc>
    80005430:	84aa                	mv	s1,a0
    return -1;
    80005432:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005434:	00054963          	bltz	a0,80005446 <sys_dup+0x42>
  filedup(f);
    80005438:	fd843503          	ld	a0,-40(s0)
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	37a080e7          	jalr	890(ra) # 800047b6 <filedup>
  return fd;
    80005444:	87a6                	mv	a5,s1
}
    80005446:	853e                	mv	a0,a5
    80005448:	70a2                	ld	ra,40(sp)
    8000544a:	7402                	ld	s0,32(sp)
    8000544c:	64e2                	ld	s1,24(sp)
    8000544e:	6145                	addi	sp,sp,48
    80005450:	8082                	ret

0000000080005452 <sys_read>:
{
    80005452:	7179                	addi	sp,sp,-48
    80005454:	f406                	sd	ra,40(sp)
    80005456:	f022                	sd	s0,32(sp)
    80005458:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545a:	fe840613          	addi	a2,s0,-24
    8000545e:	4581                	li	a1,0
    80005460:	4501                	li	a0,0
    80005462:	00000097          	auipc	ra,0x0
    80005466:	d90080e7          	jalr	-624(ra) # 800051f2 <argfd>
    return -1;
    8000546a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546c:	04054163          	bltz	a0,800054ae <sys_read+0x5c>
    80005470:	fe440593          	addi	a1,s0,-28
    80005474:	4509                	li	a0,2
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	938080e7          	jalr	-1736(ra) # 80002dae <argint>
    return -1;
    8000547e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005480:	02054763          	bltz	a0,800054ae <sys_read+0x5c>
    80005484:	fd840593          	addi	a1,s0,-40
    80005488:	4505                	li	a0,1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	946080e7          	jalr	-1722(ra) # 80002dd0 <argaddr>
    return -1;
    80005492:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005494:	00054d63          	bltz	a0,800054ae <sys_read+0x5c>
  return fileread(f, p, n);
    80005498:	fe442603          	lw	a2,-28(s0)
    8000549c:	fd843583          	ld	a1,-40(s0)
    800054a0:	fe843503          	ld	a0,-24(s0)
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	49e080e7          	jalr	1182(ra) # 80004942 <fileread>
    800054ac:	87aa                	mv	a5,a0
}
    800054ae:	853e                	mv	a0,a5
    800054b0:	70a2                	ld	ra,40(sp)
    800054b2:	7402                	ld	s0,32(sp)
    800054b4:	6145                	addi	sp,sp,48
    800054b6:	8082                	ret

00000000800054b8 <sys_write>:
{
    800054b8:	7179                	addi	sp,sp,-48
    800054ba:	f406                	sd	ra,40(sp)
    800054bc:	f022                	sd	s0,32(sp)
    800054be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c0:	fe840613          	addi	a2,s0,-24
    800054c4:	4581                	li	a1,0
    800054c6:	4501                	li	a0,0
    800054c8:	00000097          	auipc	ra,0x0
    800054cc:	d2a080e7          	jalr	-726(ra) # 800051f2 <argfd>
    return -1;
    800054d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d2:	04054163          	bltz	a0,80005514 <sys_write+0x5c>
    800054d6:	fe440593          	addi	a1,s0,-28
    800054da:	4509                	li	a0,2
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	8d2080e7          	jalr	-1838(ra) # 80002dae <argint>
    return -1;
    800054e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e6:	02054763          	bltz	a0,80005514 <sys_write+0x5c>
    800054ea:	fd840593          	addi	a1,s0,-40
    800054ee:	4505                	li	a0,1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	8e0080e7          	jalr	-1824(ra) # 80002dd0 <argaddr>
    return -1;
    800054f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054fa:	00054d63          	bltz	a0,80005514 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054fe:	fe442603          	lw	a2,-28(s0)
    80005502:	fd843583          	ld	a1,-40(s0)
    80005506:	fe843503          	ld	a0,-24(s0)
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	4fa080e7          	jalr	1274(ra) # 80004a04 <filewrite>
    80005512:	87aa                	mv	a5,a0
}
    80005514:	853e                	mv	a0,a5
    80005516:	70a2                	ld	ra,40(sp)
    80005518:	7402                	ld	s0,32(sp)
    8000551a:	6145                	addi	sp,sp,48
    8000551c:	8082                	ret

000000008000551e <sys_close>:
{
    8000551e:	1101                	addi	sp,sp,-32
    80005520:	ec06                	sd	ra,24(sp)
    80005522:	e822                	sd	s0,16(sp)
    80005524:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005526:	fe040613          	addi	a2,s0,-32
    8000552a:	fec40593          	addi	a1,s0,-20
    8000552e:	4501                	li	a0,0
    80005530:	00000097          	auipc	ra,0x0
    80005534:	cc2080e7          	jalr	-830(ra) # 800051f2 <argfd>
    return -1;
    80005538:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000553a:	02054463          	bltz	a0,80005562 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000553e:	ffffc097          	auipc	ra,0xffffc
    80005542:	73a080e7          	jalr	1850(ra) # 80001c78 <myproc>
    80005546:	fec42783          	lw	a5,-20(s0)
    8000554a:	07f9                	addi	a5,a5,30
    8000554c:	078e                	slli	a5,a5,0x3
    8000554e:	97aa                	add	a5,a5,a0
    80005550:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005554:	fe043503          	ld	a0,-32(s0)
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	2b0080e7          	jalr	688(ra) # 80004808 <fileclose>
  return 0;
    80005560:	4781                	li	a5,0
}
    80005562:	853e                	mv	a0,a5
    80005564:	60e2                	ld	ra,24(sp)
    80005566:	6442                	ld	s0,16(sp)
    80005568:	6105                	addi	sp,sp,32
    8000556a:	8082                	ret

000000008000556c <sys_fstat>:
{
    8000556c:	1101                	addi	sp,sp,-32
    8000556e:	ec06                	sd	ra,24(sp)
    80005570:	e822                	sd	s0,16(sp)
    80005572:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005574:	fe840613          	addi	a2,s0,-24
    80005578:	4581                	li	a1,0
    8000557a:	4501                	li	a0,0
    8000557c:	00000097          	auipc	ra,0x0
    80005580:	c76080e7          	jalr	-906(ra) # 800051f2 <argfd>
    return -1;
    80005584:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005586:	02054563          	bltz	a0,800055b0 <sys_fstat+0x44>
    8000558a:	fe040593          	addi	a1,s0,-32
    8000558e:	4505                	li	a0,1
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	840080e7          	jalr	-1984(ra) # 80002dd0 <argaddr>
    return -1;
    80005598:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000559a:	00054b63          	bltz	a0,800055b0 <sys_fstat+0x44>
  return filestat(f, st);
    8000559e:	fe043583          	ld	a1,-32(s0)
    800055a2:	fe843503          	ld	a0,-24(s0)
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	32a080e7          	jalr	810(ra) # 800048d0 <filestat>
    800055ae:	87aa                	mv	a5,a0
}
    800055b0:	853e                	mv	a0,a5
    800055b2:	60e2                	ld	ra,24(sp)
    800055b4:	6442                	ld	s0,16(sp)
    800055b6:	6105                	addi	sp,sp,32
    800055b8:	8082                	ret

00000000800055ba <sys_link>:
{
    800055ba:	7169                	addi	sp,sp,-304
    800055bc:	f606                	sd	ra,296(sp)
    800055be:	f222                	sd	s0,288(sp)
    800055c0:	ee26                	sd	s1,280(sp)
    800055c2:	ea4a                	sd	s2,272(sp)
    800055c4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c6:	08000613          	li	a2,128
    800055ca:	ed040593          	addi	a1,s0,-304
    800055ce:	4501                	li	a0,0
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	822080e7          	jalr	-2014(ra) # 80002df2 <argstr>
    return -1;
    800055d8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055da:	10054e63          	bltz	a0,800056f6 <sys_link+0x13c>
    800055de:	08000613          	li	a2,128
    800055e2:	f5040593          	addi	a1,s0,-176
    800055e6:	4505                	li	a0,1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	80a080e7          	jalr	-2038(ra) # 80002df2 <argstr>
    return -1;
    800055f0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055f2:	10054263          	bltz	a0,800056f6 <sys_link+0x13c>
  begin_op();
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	d46080e7          	jalr	-698(ra) # 8000433c <begin_op>
  if((ip = namei(old)) == 0){
    800055fe:	ed040513          	addi	a0,s0,-304
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	b1e080e7          	jalr	-1250(ra) # 80004120 <namei>
    8000560a:	84aa                	mv	s1,a0
    8000560c:	c551                	beqz	a0,80005698 <sys_link+0xde>
  ilock(ip);
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	35c080e7          	jalr	860(ra) # 8000396a <ilock>
  if(ip->type == T_DIR){
    80005616:	04449703          	lh	a4,68(s1)
    8000561a:	4785                	li	a5,1
    8000561c:	08f70463          	beq	a4,a5,800056a4 <sys_link+0xea>
  ip->nlink++;
    80005620:	04a4d783          	lhu	a5,74(s1)
    80005624:	2785                	addiw	a5,a5,1
    80005626:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	274080e7          	jalr	628(ra) # 800038a0 <iupdate>
  iunlock(ip);
    80005634:	8526                	mv	a0,s1
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	3f6080e7          	jalr	1014(ra) # 80003a2c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000563e:	fd040593          	addi	a1,s0,-48
    80005642:	f5040513          	addi	a0,s0,-176
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	af8080e7          	jalr	-1288(ra) # 8000413e <nameiparent>
    8000564e:	892a                	mv	s2,a0
    80005650:	c935                	beqz	a0,800056c4 <sys_link+0x10a>
  ilock(dp);
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	318080e7          	jalr	792(ra) # 8000396a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000565a:	00092703          	lw	a4,0(s2)
    8000565e:	409c                	lw	a5,0(s1)
    80005660:	04f71d63          	bne	a4,a5,800056ba <sys_link+0x100>
    80005664:	40d0                	lw	a2,4(s1)
    80005666:	fd040593          	addi	a1,s0,-48
    8000566a:	854a                	mv	a0,s2
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	9f2080e7          	jalr	-1550(ra) # 8000405e <dirlink>
    80005674:	04054363          	bltz	a0,800056ba <sys_link+0x100>
  iunlockput(dp);
    80005678:	854a                	mv	a0,s2
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	552080e7          	jalr	1362(ra) # 80003bcc <iunlockput>
  iput(ip);
    80005682:	8526                	mv	a0,s1
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	4a0080e7          	jalr	1184(ra) # 80003b24 <iput>
  end_op();
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	d30080e7          	jalr	-720(ra) # 800043bc <end_op>
  return 0;
    80005694:	4781                	li	a5,0
    80005696:	a085                	j	800056f6 <sys_link+0x13c>
    end_op();
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	d24080e7          	jalr	-732(ra) # 800043bc <end_op>
    return -1;
    800056a0:	57fd                	li	a5,-1
    800056a2:	a891                	j	800056f6 <sys_link+0x13c>
    iunlockput(ip);
    800056a4:	8526                	mv	a0,s1
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	526080e7          	jalr	1318(ra) # 80003bcc <iunlockput>
    end_op();
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	d0e080e7          	jalr	-754(ra) # 800043bc <end_op>
    return -1;
    800056b6:	57fd                	li	a5,-1
    800056b8:	a83d                	j	800056f6 <sys_link+0x13c>
    iunlockput(dp);
    800056ba:	854a                	mv	a0,s2
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	510080e7          	jalr	1296(ra) # 80003bcc <iunlockput>
  ilock(ip);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	2a4080e7          	jalr	676(ra) # 8000396a <ilock>
  ip->nlink--;
    800056ce:	04a4d783          	lhu	a5,74(s1)
    800056d2:	37fd                	addiw	a5,a5,-1
    800056d4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	1c6080e7          	jalr	454(ra) # 800038a0 <iupdate>
  iunlockput(ip);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	4e8080e7          	jalr	1256(ra) # 80003bcc <iunlockput>
  end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	cd0080e7          	jalr	-816(ra) # 800043bc <end_op>
  return -1;
    800056f4:	57fd                	li	a5,-1
}
    800056f6:	853e                	mv	a0,a5
    800056f8:	70b2                	ld	ra,296(sp)
    800056fa:	7412                	ld	s0,288(sp)
    800056fc:	64f2                	ld	s1,280(sp)
    800056fe:	6952                	ld	s2,272(sp)
    80005700:	6155                	addi	sp,sp,304
    80005702:	8082                	ret

0000000080005704 <sys_unlink>:
{
    80005704:	7151                	addi	sp,sp,-240
    80005706:	f586                	sd	ra,232(sp)
    80005708:	f1a2                	sd	s0,224(sp)
    8000570a:	eda6                	sd	s1,216(sp)
    8000570c:	e9ca                	sd	s2,208(sp)
    8000570e:	e5ce                	sd	s3,200(sp)
    80005710:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005712:	08000613          	li	a2,128
    80005716:	f3040593          	addi	a1,s0,-208
    8000571a:	4501                	li	a0,0
    8000571c:	ffffd097          	auipc	ra,0xffffd
    80005720:	6d6080e7          	jalr	1750(ra) # 80002df2 <argstr>
    80005724:	18054163          	bltz	a0,800058a6 <sys_unlink+0x1a2>
  begin_op();
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	c14080e7          	jalr	-1004(ra) # 8000433c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005730:	fb040593          	addi	a1,s0,-80
    80005734:	f3040513          	addi	a0,s0,-208
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	a06080e7          	jalr	-1530(ra) # 8000413e <nameiparent>
    80005740:	84aa                	mv	s1,a0
    80005742:	c979                	beqz	a0,80005818 <sys_unlink+0x114>
  ilock(dp);
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	226080e7          	jalr	550(ra) # 8000396a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000574c:	00003597          	auipc	a1,0x3
    80005750:	01c58593          	addi	a1,a1,28 # 80008768 <syscalls+0x2c0>
    80005754:	fb040513          	addi	a0,s0,-80
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	6dc080e7          	jalr	1756(ra) # 80003e34 <namecmp>
    80005760:	14050a63          	beqz	a0,800058b4 <sys_unlink+0x1b0>
    80005764:	00003597          	auipc	a1,0x3
    80005768:	00c58593          	addi	a1,a1,12 # 80008770 <syscalls+0x2c8>
    8000576c:	fb040513          	addi	a0,s0,-80
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	6c4080e7          	jalr	1732(ra) # 80003e34 <namecmp>
    80005778:	12050e63          	beqz	a0,800058b4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000577c:	f2c40613          	addi	a2,s0,-212
    80005780:	fb040593          	addi	a1,s0,-80
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	6c8080e7          	jalr	1736(ra) # 80003e4e <dirlookup>
    8000578e:	892a                	mv	s2,a0
    80005790:	12050263          	beqz	a0,800058b4 <sys_unlink+0x1b0>
  ilock(ip);
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	1d6080e7          	jalr	470(ra) # 8000396a <ilock>
  if(ip->nlink < 1)
    8000579c:	04a91783          	lh	a5,74(s2)
    800057a0:	08f05263          	blez	a5,80005824 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057a4:	04491703          	lh	a4,68(s2)
    800057a8:	4785                	li	a5,1
    800057aa:	08f70563          	beq	a4,a5,80005834 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057ae:	4641                	li	a2,16
    800057b0:	4581                	li	a1,0
    800057b2:	fc040513          	addi	a0,s0,-64
    800057b6:	ffffb097          	auipc	ra,0xffffb
    800057ba:	52a080e7          	jalr	1322(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057be:	4741                	li	a4,16
    800057c0:	f2c42683          	lw	a3,-212(s0)
    800057c4:	fc040613          	addi	a2,s0,-64
    800057c8:	4581                	li	a1,0
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	54a080e7          	jalr	1354(ra) # 80003d16 <writei>
    800057d4:	47c1                	li	a5,16
    800057d6:	0af51563          	bne	a0,a5,80005880 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057da:	04491703          	lh	a4,68(s2)
    800057de:	4785                	li	a5,1
    800057e0:	0af70863          	beq	a4,a5,80005890 <sys_unlink+0x18c>
  iunlockput(dp);
    800057e4:	8526                	mv	a0,s1
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	3e6080e7          	jalr	998(ra) # 80003bcc <iunlockput>
  ip->nlink--;
    800057ee:	04a95783          	lhu	a5,74(s2)
    800057f2:	37fd                	addiw	a5,a5,-1
    800057f4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057f8:	854a                	mv	a0,s2
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	0a6080e7          	jalr	166(ra) # 800038a0 <iupdate>
  iunlockput(ip);
    80005802:	854a                	mv	a0,s2
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	3c8080e7          	jalr	968(ra) # 80003bcc <iunlockput>
  end_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	bb0080e7          	jalr	-1104(ra) # 800043bc <end_op>
  return 0;
    80005814:	4501                	li	a0,0
    80005816:	a84d                	j	800058c8 <sys_unlink+0x1c4>
    end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	ba4080e7          	jalr	-1116(ra) # 800043bc <end_op>
    return -1;
    80005820:	557d                	li	a0,-1
    80005822:	a05d                	j	800058c8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005824:	00003517          	auipc	a0,0x3
    80005828:	f7450513          	addi	a0,a0,-140 # 80008798 <syscalls+0x2f0>
    8000582c:	ffffb097          	auipc	ra,0xffffb
    80005830:	d12080e7          	jalr	-750(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005834:	04c92703          	lw	a4,76(s2)
    80005838:	02000793          	li	a5,32
    8000583c:	f6e7f9e3          	bgeu	a5,a4,800057ae <sys_unlink+0xaa>
    80005840:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005844:	4741                	li	a4,16
    80005846:	86ce                	mv	a3,s3
    80005848:	f1840613          	addi	a2,s0,-232
    8000584c:	4581                	li	a1,0
    8000584e:	854a                	mv	a0,s2
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	3ce080e7          	jalr	974(ra) # 80003c1e <readi>
    80005858:	47c1                	li	a5,16
    8000585a:	00f51b63          	bne	a0,a5,80005870 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000585e:	f1845783          	lhu	a5,-232(s0)
    80005862:	e7a1                	bnez	a5,800058aa <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005864:	29c1                	addiw	s3,s3,16
    80005866:	04c92783          	lw	a5,76(s2)
    8000586a:	fcf9ede3          	bltu	s3,a5,80005844 <sys_unlink+0x140>
    8000586e:	b781                	j	800057ae <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005870:	00003517          	auipc	a0,0x3
    80005874:	f4050513          	addi	a0,a0,-192 # 800087b0 <syscalls+0x308>
    80005878:	ffffb097          	auipc	ra,0xffffb
    8000587c:	cc6080e7          	jalr	-826(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005880:	00003517          	auipc	a0,0x3
    80005884:	f4850513          	addi	a0,a0,-184 # 800087c8 <syscalls+0x320>
    80005888:	ffffb097          	auipc	ra,0xffffb
    8000588c:	cb6080e7          	jalr	-842(ra) # 8000053e <panic>
    dp->nlink--;
    80005890:	04a4d783          	lhu	a5,74(s1)
    80005894:	37fd                	addiw	a5,a5,-1
    80005896:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	004080e7          	jalr	4(ra) # 800038a0 <iupdate>
    800058a4:	b781                	j	800057e4 <sys_unlink+0xe0>
    return -1;
    800058a6:	557d                	li	a0,-1
    800058a8:	a005                	j	800058c8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058aa:	854a                	mv	a0,s2
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	320080e7          	jalr	800(ra) # 80003bcc <iunlockput>
  iunlockput(dp);
    800058b4:	8526                	mv	a0,s1
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	316080e7          	jalr	790(ra) # 80003bcc <iunlockput>
  end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	afe080e7          	jalr	-1282(ra) # 800043bc <end_op>
  return -1;
    800058c6:	557d                	li	a0,-1
}
    800058c8:	70ae                	ld	ra,232(sp)
    800058ca:	740e                	ld	s0,224(sp)
    800058cc:	64ee                	ld	s1,216(sp)
    800058ce:	694e                	ld	s2,208(sp)
    800058d0:	69ae                	ld	s3,200(sp)
    800058d2:	616d                	addi	sp,sp,240
    800058d4:	8082                	ret

00000000800058d6 <sys_open>:

uint64
sys_open(void)
{
    800058d6:	7131                	addi	sp,sp,-192
    800058d8:	fd06                	sd	ra,184(sp)
    800058da:	f922                	sd	s0,176(sp)
    800058dc:	f526                	sd	s1,168(sp)
    800058de:	f14a                	sd	s2,160(sp)
    800058e0:	ed4e                	sd	s3,152(sp)
    800058e2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058e4:	08000613          	li	a2,128
    800058e8:	f5040593          	addi	a1,s0,-176
    800058ec:	4501                	li	a0,0
    800058ee:	ffffd097          	auipc	ra,0xffffd
    800058f2:	504080e7          	jalr	1284(ra) # 80002df2 <argstr>
    return -1;
    800058f6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058f8:	0c054163          	bltz	a0,800059ba <sys_open+0xe4>
    800058fc:	f4c40593          	addi	a1,s0,-180
    80005900:	4505                	li	a0,1
    80005902:	ffffd097          	auipc	ra,0xffffd
    80005906:	4ac080e7          	jalr	1196(ra) # 80002dae <argint>
    8000590a:	0a054863          	bltz	a0,800059ba <sys_open+0xe4>

  begin_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	a2e080e7          	jalr	-1490(ra) # 8000433c <begin_op>

  if(omode & O_CREATE){
    80005916:	f4c42783          	lw	a5,-180(s0)
    8000591a:	2007f793          	andi	a5,a5,512
    8000591e:	cbdd                	beqz	a5,800059d4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005920:	4681                	li	a3,0
    80005922:	4601                	li	a2,0
    80005924:	4589                	li	a1,2
    80005926:	f5040513          	addi	a0,s0,-176
    8000592a:	00000097          	auipc	ra,0x0
    8000592e:	972080e7          	jalr	-1678(ra) # 8000529c <create>
    80005932:	892a                	mv	s2,a0
    if(ip == 0){
    80005934:	c959                	beqz	a0,800059ca <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005936:	04491703          	lh	a4,68(s2)
    8000593a:	478d                	li	a5,3
    8000593c:	00f71763          	bne	a4,a5,8000594a <sys_open+0x74>
    80005940:	04695703          	lhu	a4,70(s2)
    80005944:	47a5                	li	a5,9
    80005946:	0ce7ec63          	bltu	a5,a4,80005a1e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	e02080e7          	jalr	-510(ra) # 8000474c <filealloc>
    80005952:	89aa                	mv	s3,a0
    80005954:	10050263          	beqz	a0,80005a58 <sys_open+0x182>
    80005958:	00000097          	auipc	ra,0x0
    8000595c:	902080e7          	jalr	-1790(ra) # 8000525a <fdalloc>
    80005960:	84aa                	mv	s1,a0
    80005962:	0e054663          	bltz	a0,80005a4e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005966:	04491703          	lh	a4,68(s2)
    8000596a:	478d                	li	a5,3
    8000596c:	0cf70463          	beq	a4,a5,80005a34 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005970:	4789                	li	a5,2
    80005972:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005976:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000597a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000597e:	f4c42783          	lw	a5,-180(s0)
    80005982:	0017c713          	xori	a4,a5,1
    80005986:	8b05                	andi	a4,a4,1
    80005988:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000598c:	0037f713          	andi	a4,a5,3
    80005990:	00e03733          	snez	a4,a4
    80005994:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005998:	4007f793          	andi	a5,a5,1024
    8000599c:	c791                	beqz	a5,800059a8 <sys_open+0xd2>
    8000599e:	04491703          	lh	a4,68(s2)
    800059a2:	4789                	li	a5,2
    800059a4:	08f70f63          	beq	a4,a5,80005a42 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	082080e7          	jalr	130(ra) # 80003a2c <iunlock>
  end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	a0a080e7          	jalr	-1526(ra) # 800043bc <end_op>

  return fd;
}
    800059ba:	8526                	mv	a0,s1
    800059bc:	70ea                	ld	ra,184(sp)
    800059be:	744a                	ld	s0,176(sp)
    800059c0:	74aa                	ld	s1,168(sp)
    800059c2:	790a                	ld	s2,160(sp)
    800059c4:	69ea                	ld	s3,152(sp)
    800059c6:	6129                	addi	sp,sp,192
    800059c8:	8082                	ret
      end_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	9f2080e7          	jalr	-1550(ra) # 800043bc <end_op>
      return -1;
    800059d2:	b7e5                	j	800059ba <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059d4:	f5040513          	addi	a0,s0,-176
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	748080e7          	jalr	1864(ra) # 80004120 <namei>
    800059e0:	892a                	mv	s2,a0
    800059e2:	c905                	beqz	a0,80005a12 <sys_open+0x13c>
    ilock(ip);
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	f86080e7          	jalr	-122(ra) # 8000396a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059ec:	04491703          	lh	a4,68(s2)
    800059f0:	4785                	li	a5,1
    800059f2:	f4f712e3          	bne	a4,a5,80005936 <sys_open+0x60>
    800059f6:	f4c42783          	lw	a5,-180(s0)
    800059fa:	dba1                	beqz	a5,8000594a <sys_open+0x74>
      iunlockput(ip);
    800059fc:	854a                	mv	a0,s2
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	1ce080e7          	jalr	462(ra) # 80003bcc <iunlockput>
      end_op();
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	9b6080e7          	jalr	-1610(ra) # 800043bc <end_op>
      return -1;
    80005a0e:	54fd                	li	s1,-1
    80005a10:	b76d                	j	800059ba <sys_open+0xe4>
      end_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	9aa080e7          	jalr	-1622(ra) # 800043bc <end_op>
      return -1;
    80005a1a:	54fd                	li	s1,-1
    80005a1c:	bf79                	j	800059ba <sys_open+0xe4>
    iunlockput(ip);
    80005a1e:	854a                	mv	a0,s2
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	1ac080e7          	jalr	428(ra) # 80003bcc <iunlockput>
    end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	994080e7          	jalr	-1644(ra) # 800043bc <end_op>
    return -1;
    80005a30:	54fd                	li	s1,-1
    80005a32:	b761                	j	800059ba <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a34:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a38:	04691783          	lh	a5,70(s2)
    80005a3c:	02f99223          	sh	a5,36(s3)
    80005a40:	bf2d                	j	8000597a <sys_open+0xa4>
    itrunc(ip);
    80005a42:	854a                	mv	a0,s2
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	034080e7          	jalr	52(ra) # 80003a78 <itrunc>
    80005a4c:	bfb1                	j	800059a8 <sys_open+0xd2>
      fileclose(f);
    80005a4e:	854e                	mv	a0,s3
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	db8080e7          	jalr	-584(ra) # 80004808 <fileclose>
    iunlockput(ip);
    80005a58:	854a                	mv	a0,s2
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	172080e7          	jalr	370(ra) # 80003bcc <iunlockput>
    end_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	95a080e7          	jalr	-1702(ra) # 800043bc <end_op>
    return -1;
    80005a6a:	54fd                	li	s1,-1
    80005a6c:	b7b9                	j	800059ba <sys_open+0xe4>

0000000080005a6e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a6e:	7175                	addi	sp,sp,-144
    80005a70:	e506                	sd	ra,136(sp)
    80005a72:	e122                	sd	s0,128(sp)
    80005a74:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	8c6080e7          	jalr	-1850(ra) # 8000433c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a7e:	08000613          	li	a2,128
    80005a82:	f7040593          	addi	a1,s0,-144
    80005a86:	4501                	li	a0,0
    80005a88:	ffffd097          	auipc	ra,0xffffd
    80005a8c:	36a080e7          	jalr	874(ra) # 80002df2 <argstr>
    80005a90:	02054963          	bltz	a0,80005ac2 <sys_mkdir+0x54>
    80005a94:	4681                	li	a3,0
    80005a96:	4601                	li	a2,0
    80005a98:	4585                	li	a1,1
    80005a9a:	f7040513          	addi	a0,s0,-144
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	7fe080e7          	jalr	2046(ra) # 8000529c <create>
    80005aa6:	cd11                	beqz	a0,80005ac2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	124080e7          	jalr	292(ra) # 80003bcc <iunlockput>
  end_op();
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	90c080e7          	jalr	-1780(ra) # 800043bc <end_op>
  return 0;
    80005ab8:	4501                	li	a0,0
}
    80005aba:	60aa                	ld	ra,136(sp)
    80005abc:	640a                	ld	s0,128(sp)
    80005abe:	6149                	addi	sp,sp,144
    80005ac0:	8082                	ret
    end_op();
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	8fa080e7          	jalr	-1798(ra) # 800043bc <end_op>
    return -1;
    80005aca:	557d                	li	a0,-1
    80005acc:	b7fd                	j	80005aba <sys_mkdir+0x4c>

0000000080005ace <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ace:	7135                	addi	sp,sp,-160
    80005ad0:	ed06                	sd	ra,152(sp)
    80005ad2:	e922                	sd	s0,144(sp)
    80005ad4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	866080e7          	jalr	-1946(ra) # 8000433c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ade:	08000613          	li	a2,128
    80005ae2:	f7040593          	addi	a1,s0,-144
    80005ae6:	4501                	li	a0,0
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	30a080e7          	jalr	778(ra) # 80002df2 <argstr>
    80005af0:	04054a63          	bltz	a0,80005b44 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005af4:	f6c40593          	addi	a1,s0,-148
    80005af8:	4505                	li	a0,1
    80005afa:	ffffd097          	auipc	ra,0xffffd
    80005afe:	2b4080e7          	jalr	692(ra) # 80002dae <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b02:	04054163          	bltz	a0,80005b44 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b06:	f6840593          	addi	a1,s0,-152
    80005b0a:	4509                	li	a0,2
    80005b0c:	ffffd097          	auipc	ra,0xffffd
    80005b10:	2a2080e7          	jalr	674(ra) # 80002dae <argint>
     argint(1, &major) < 0 ||
    80005b14:	02054863          	bltz	a0,80005b44 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b18:	f6841683          	lh	a3,-152(s0)
    80005b1c:	f6c41603          	lh	a2,-148(s0)
    80005b20:	458d                	li	a1,3
    80005b22:	f7040513          	addi	a0,s0,-144
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	776080e7          	jalr	1910(ra) # 8000529c <create>
     argint(2, &minor) < 0 ||
    80005b2e:	c919                	beqz	a0,80005b44 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	09c080e7          	jalr	156(ra) # 80003bcc <iunlockput>
  end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	884080e7          	jalr	-1916(ra) # 800043bc <end_op>
  return 0;
    80005b40:	4501                	li	a0,0
    80005b42:	a031                	j	80005b4e <sys_mknod+0x80>
    end_op();
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	878080e7          	jalr	-1928(ra) # 800043bc <end_op>
    return -1;
    80005b4c:	557d                	li	a0,-1
}
    80005b4e:	60ea                	ld	ra,152(sp)
    80005b50:	644a                	ld	s0,144(sp)
    80005b52:	610d                	addi	sp,sp,160
    80005b54:	8082                	ret

0000000080005b56 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b56:	7135                	addi	sp,sp,-160
    80005b58:	ed06                	sd	ra,152(sp)
    80005b5a:	e922                	sd	s0,144(sp)
    80005b5c:	e526                	sd	s1,136(sp)
    80005b5e:	e14a                	sd	s2,128(sp)
    80005b60:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b62:	ffffc097          	auipc	ra,0xffffc
    80005b66:	116080e7          	jalr	278(ra) # 80001c78 <myproc>
    80005b6a:	892a                	mv	s2,a0
  
  begin_op();
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	7d0080e7          	jalr	2000(ra) # 8000433c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b74:	08000613          	li	a2,128
    80005b78:	f6040593          	addi	a1,s0,-160
    80005b7c:	4501                	li	a0,0
    80005b7e:	ffffd097          	auipc	ra,0xffffd
    80005b82:	274080e7          	jalr	628(ra) # 80002df2 <argstr>
    80005b86:	04054b63          	bltz	a0,80005bdc <sys_chdir+0x86>
    80005b8a:	f6040513          	addi	a0,s0,-160
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	592080e7          	jalr	1426(ra) # 80004120 <namei>
    80005b96:	84aa                	mv	s1,a0
    80005b98:	c131                	beqz	a0,80005bdc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	dd0080e7          	jalr	-560(ra) # 8000396a <ilock>
  if(ip->type != T_DIR){
    80005ba2:	04449703          	lh	a4,68(s1)
    80005ba6:	4785                	li	a5,1
    80005ba8:	04f71063          	bne	a4,a5,80005be8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bac:	8526                	mv	a0,s1
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	e7e080e7          	jalr	-386(ra) # 80003a2c <iunlock>
  iput(p->cwd);
    80005bb6:	17893503          	ld	a0,376(s2)
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	f6a080e7          	jalr	-150(ra) # 80003b24 <iput>
  end_op();
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	7fa080e7          	jalr	2042(ra) # 800043bc <end_op>
  p->cwd = ip;
    80005bca:	16993c23          	sd	s1,376(s2)
  return 0;
    80005bce:	4501                	li	a0,0
}
    80005bd0:	60ea                	ld	ra,152(sp)
    80005bd2:	644a                	ld	s0,144(sp)
    80005bd4:	64aa                	ld	s1,136(sp)
    80005bd6:	690a                	ld	s2,128(sp)
    80005bd8:	610d                	addi	sp,sp,160
    80005bda:	8082                	ret
    end_op();
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	7e0080e7          	jalr	2016(ra) # 800043bc <end_op>
    return -1;
    80005be4:	557d                	li	a0,-1
    80005be6:	b7ed                	j	80005bd0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005be8:	8526                	mv	a0,s1
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	fe2080e7          	jalr	-30(ra) # 80003bcc <iunlockput>
    end_op();
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	7ca080e7          	jalr	1994(ra) # 800043bc <end_op>
    return -1;
    80005bfa:	557d                	li	a0,-1
    80005bfc:	bfd1                	j	80005bd0 <sys_chdir+0x7a>

0000000080005bfe <sys_exec>:

uint64
sys_exec(void)
{
    80005bfe:	7145                	addi	sp,sp,-464
    80005c00:	e786                	sd	ra,456(sp)
    80005c02:	e3a2                	sd	s0,448(sp)
    80005c04:	ff26                	sd	s1,440(sp)
    80005c06:	fb4a                	sd	s2,432(sp)
    80005c08:	f74e                	sd	s3,424(sp)
    80005c0a:	f352                	sd	s4,416(sp)
    80005c0c:	ef56                	sd	s5,408(sp)
    80005c0e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c10:	08000613          	li	a2,128
    80005c14:	f4040593          	addi	a1,s0,-192
    80005c18:	4501                	li	a0,0
    80005c1a:	ffffd097          	auipc	ra,0xffffd
    80005c1e:	1d8080e7          	jalr	472(ra) # 80002df2 <argstr>
    return -1;
    80005c22:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c24:	0c054a63          	bltz	a0,80005cf8 <sys_exec+0xfa>
    80005c28:	e3840593          	addi	a1,s0,-456
    80005c2c:	4505                	li	a0,1
    80005c2e:	ffffd097          	auipc	ra,0xffffd
    80005c32:	1a2080e7          	jalr	418(ra) # 80002dd0 <argaddr>
    80005c36:	0c054163          	bltz	a0,80005cf8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c3a:	10000613          	li	a2,256
    80005c3e:	4581                	li	a1,0
    80005c40:	e4040513          	addi	a0,s0,-448
    80005c44:	ffffb097          	auipc	ra,0xffffb
    80005c48:	09c080e7          	jalr	156(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c4c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c50:	89a6                	mv	s3,s1
    80005c52:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c54:	02000a13          	li	s4,32
    80005c58:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c5c:	00391513          	slli	a0,s2,0x3
    80005c60:	e3040593          	addi	a1,s0,-464
    80005c64:	e3843783          	ld	a5,-456(s0)
    80005c68:	953e                	add	a0,a0,a5
    80005c6a:	ffffd097          	auipc	ra,0xffffd
    80005c6e:	0aa080e7          	jalr	170(ra) # 80002d14 <fetchaddr>
    80005c72:	02054a63          	bltz	a0,80005ca6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c76:	e3043783          	ld	a5,-464(s0)
    80005c7a:	c3b9                	beqz	a5,80005cc0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c7c:	ffffb097          	auipc	ra,0xffffb
    80005c80:	e78080e7          	jalr	-392(ra) # 80000af4 <kalloc>
    80005c84:	85aa                	mv	a1,a0
    80005c86:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c8a:	cd11                	beqz	a0,80005ca6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c8c:	6605                	lui	a2,0x1
    80005c8e:	e3043503          	ld	a0,-464(s0)
    80005c92:	ffffd097          	auipc	ra,0xffffd
    80005c96:	0d4080e7          	jalr	212(ra) # 80002d66 <fetchstr>
    80005c9a:	00054663          	bltz	a0,80005ca6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c9e:	0905                	addi	s2,s2,1
    80005ca0:	09a1                	addi	s3,s3,8
    80005ca2:	fb491be3          	bne	s2,s4,80005c58 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca6:	10048913          	addi	s2,s1,256
    80005caa:	6088                	ld	a0,0(s1)
    80005cac:	c529                	beqz	a0,80005cf6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cae:	ffffb097          	auipc	ra,0xffffb
    80005cb2:	d4a080e7          	jalr	-694(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb6:	04a1                	addi	s1,s1,8
    80005cb8:	ff2499e3          	bne	s1,s2,80005caa <sys_exec+0xac>
  return -1;
    80005cbc:	597d                	li	s2,-1
    80005cbe:	a82d                	j	80005cf8 <sys_exec+0xfa>
      argv[i] = 0;
    80005cc0:	0a8e                	slli	s5,s5,0x3
    80005cc2:	fc040793          	addi	a5,s0,-64
    80005cc6:	9abe                	add	s5,s5,a5
    80005cc8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ccc:	e4040593          	addi	a1,s0,-448
    80005cd0:	f4040513          	addi	a0,s0,-192
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	194080e7          	jalr	404(ra) # 80004e68 <exec>
    80005cdc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cde:	10048993          	addi	s3,s1,256
    80005ce2:	6088                	ld	a0,0(s1)
    80005ce4:	c911                	beqz	a0,80005cf8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ce6:	ffffb097          	auipc	ra,0xffffb
    80005cea:	d12080e7          	jalr	-750(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cee:	04a1                	addi	s1,s1,8
    80005cf0:	ff3499e3          	bne	s1,s3,80005ce2 <sys_exec+0xe4>
    80005cf4:	a011                	j	80005cf8 <sys_exec+0xfa>
  return -1;
    80005cf6:	597d                	li	s2,-1
}
    80005cf8:	854a                	mv	a0,s2
    80005cfa:	60be                	ld	ra,456(sp)
    80005cfc:	641e                	ld	s0,448(sp)
    80005cfe:	74fa                	ld	s1,440(sp)
    80005d00:	795a                	ld	s2,432(sp)
    80005d02:	79ba                	ld	s3,424(sp)
    80005d04:	7a1a                	ld	s4,416(sp)
    80005d06:	6afa                	ld	s5,408(sp)
    80005d08:	6179                	addi	sp,sp,464
    80005d0a:	8082                	ret

0000000080005d0c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d0c:	7139                	addi	sp,sp,-64
    80005d0e:	fc06                	sd	ra,56(sp)
    80005d10:	f822                	sd	s0,48(sp)
    80005d12:	f426                	sd	s1,40(sp)
    80005d14:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d16:	ffffc097          	auipc	ra,0xffffc
    80005d1a:	f62080e7          	jalr	-158(ra) # 80001c78 <myproc>
    80005d1e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d20:	fd840593          	addi	a1,s0,-40
    80005d24:	4501                	li	a0,0
    80005d26:	ffffd097          	auipc	ra,0xffffd
    80005d2a:	0aa080e7          	jalr	170(ra) # 80002dd0 <argaddr>
    return -1;
    80005d2e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d30:	0e054063          	bltz	a0,80005e10 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d34:	fc840593          	addi	a1,s0,-56
    80005d38:	fd040513          	addi	a0,s0,-48
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	dfc080e7          	jalr	-516(ra) # 80004b38 <pipealloc>
    return -1;
    80005d44:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d46:	0c054563          	bltz	a0,80005e10 <sys_pipe+0x104>
  fd0 = -1;
    80005d4a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d4e:	fd043503          	ld	a0,-48(s0)
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	508080e7          	jalr	1288(ra) # 8000525a <fdalloc>
    80005d5a:	fca42223          	sw	a0,-60(s0)
    80005d5e:	08054c63          	bltz	a0,80005df6 <sys_pipe+0xea>
    80005d62:	fc843503          	ld	a0,-56(s0)
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	4f4080e7          	jalr	1268(ra) # 8000525a <fdalloc>
    80005d6e:	fca42023          	sw	a0,-64(s0)
    80005d72:	06054863          	bltz	a0,80005de2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d76:	4691                	li	a3,4
    80005d78:	fc440613          	addi	a2,s0,-60
    80005d7c:	fd843583          	ld	a1,-40(s0)
    80005d80:	7ca8                	ld	a0,120(s1)
    80005d82:	ffffc097          	auipc	ra,0xffffc
    80005d86:	8f0080e7          	jalr	-1808(ra) # 80001672 <copyout>
    80005d8a:	02054063          	bltz	a0,80005daa <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d8e:	4691                	li	a3,4
    80005d90:	fc040613          	addi	a2,s0,-64
    80005d94:	fd843583          	ld	a1,-40(s0)
    80005d98:	0591                	addi	a1,a1,4
    80005d9a:	7ca8                	ld	a0,120(s1)
    80005d9c:	ffffc097          	auipc	ra,0xffffc
    80005da0:	8d6080e7          	jalr	-1834(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005da4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005da6:	06055563          	bgez	a0,80005e10 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005daa:	fc442783          	lw	a5,-60(s0)
    80005dae:	07f9                	addi	a5,a5,30
    80005db0:	078e                	slli	a5,a5,0x3
    80005db2:	97a6                	add	a5,a5,s1
    80005db4:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005db8:	fc042503          	lw	a0,-64(s0)
    80005dbc:	0579                	addi	a0,a0,30
    80005dbe:	050e                	slli	a0,a0,0x3
    80005dc0:	9526                	add	a0,a0,s1
    80005dc2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005dc6:	fd043503          	ld	a0,-48(s0)
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	a3e080e7          	jalr	-1474(ra) # 80004808 <fileclose>
    fileclose(wf);
    80005dd2:	fc843503          	ld	a0,-56(s0)
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	a32080e7          	jalr	-1486(ra) # 80004808 <fileclose>
    return -1;
    80005dde:	57fd                	li	a5,-1
    80005de0:	a805                	j	80005e10 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005de2:	fc442783          	lw	a5,-60(s0)
    80005de6:	0007c863          	bltz	a5,80005df6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005dea:	01e78513          	addi	a0,a5,30
    80005dee:	050e                	slli	a0,a0,0x3
    80005df0:	9526                	add	a0,a0,s1
    80005df2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005df6:	fd043503          	ld	a0,-48(s0)
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	a0e080e7          	jalr	-1522(ra) # 80004808 <fileclose>
    fileclose(wf);
    80005e02:	fc843503          	ld	a0,-56(s0)
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	a02080e7          	jalr	-1534(ra) # 80004808 <fileclose>
    return -1;
    80005e0e:	57fd                	li	a5,-1
}
    80005e10:	853e                	mv	a0,a5
    80005e12:	70e2                	ld	ra,56(sp)
    80005e14:	7442                	ld	s0,48(sp)
    80005e16:	74a2                	ld	s1,40(sp)
    80005e18:	6121                	addi	sp,sp,64
    80005e1a:	8082                	ret
    80005e1c:	0000                	unimp
	...

0000000080005e20 <kernelvec>:
    80005e20:	7111                	addi	sp,sp,-256
    80005e22:	e006                	sd	ra,0(sp)
    80005e24:	e40a                	sd	sp,8(sp)
    80005e26:	e80e                	sd	gp,16(sp)
    80005e28:	ec12                	sd	tp,24(sp)
    80005e2a:	f016                	sd	t0,32(sp)
    80005e2c:	f41a                	sd	t1,40(sp)
    80005e2e:	f81e                	sd	t2,48(sp)
    80005e30:	fc22                	sd	s0,56(sp)
    80005e32:	e0a6                	sd	s1,64(sp)
    80005e34:	e4aa                	sd	a0,72(sp)
    80005e36:	e8ae                	sd	a1,80(sp)
    80005e38:	ecb2                	sd	a2,88(sp)
    80005e3a:	f0b6                	sd	a3,96(sp)
    80005e3c:	f4ba                	sd	a4,104(sp)
    80005e3e:	f8be                	sd	a5,112(sp)
    80005e40:	fcc2                	sd	a6,120(sp)
    80005e42:	e146                	sd	a7,128(sp)
    80005e44:	e54a                	sd	s2,136(sp)
    80005e46:	e94e                	sd	s3,144(sp)
    80005e48:	ed52                	sd	s4,152(sp)
    80005e4a:	f156                	sd	s5,160(sp)
    80005e4c:	f55a                	sd	s6,168(sp)
    80005e4e:	f95e                	sd	s7,176(sp)
    80005e50:	fd62                	sd	s8,184(sp)
    80005e52:	e1e6                	sd	s9,192(sp)
    80005e54:	e5ea                	sd	s10,200(sp)
    80005e56:	e9ee                	sd	s11,208(sp)
    80005e58:	edf2                	sd	t3,216(sp)
    80005e5a:	f1f6                	sd	t4,224(sp)
    80005e5c:	f5fa                	sd	t5,232(sp)
    80005e5e:	f9fe                	sd	t6,240(sp)
    80005e60:	d81fc0ef          	jal	ra,80002be0 <kerneltrap>
    80005e64:	6082                	ld	ra,0(sp)
    80005e66:	6122                	ld	sp,8(sp)
    80005e68:	61c2                	ld	gp,16(sp)
    80005e6a:	7282                	ld	t0,32(sp)
    80005e6c:	7322                	ld	t1,40(sp)
    80005e6e:	73c2                	ld	t2,48(sp)
    80005e70:	7462                	ld	s0,56(sp)
    80005e72:	6486                	ld	s1,64(sp)
    80005e74:	6526                	ld	a0,72(sp)
    80005e76:	65c6                	ld	a1,80(sp)
    80005e78:	6666                	ld	a2,88(sp)
    80005e7a:	7686                	ld	a3,96(sp)
    80005e7c:	7726                	ld	a4,104(sp)
    80005e7e:	77c6                	ld	a5,112(sp)
    80005e80:	7866                	ld	a6,120(sp)
    80005e82:	688a                	ld	a7,128(sp)
    80005e84:	692a                	ld	s2,136(sp)
    80005e86:	69ca                	ld	s3,144(sp)
    80005e88:	6a6a                	ld	s4,152(sp)
    80005e8a:	7a8a                	ld	s5,160(sp)
    80005e8c:	7b2a                	ld	s6,168(sp)
    80005e8e:	7bca                	ld	s7,176(sp)
    80005e90:	7c6a                	ld	s8,184(sp)
    80005e92:	6c8e                	ld	s9,192(sp)
    80005e94:	6d2e                	ld	s10,200(sp)
    80005e96:	6dce                	ld	s11,208(sp)
    80005e98:	6e6e                	ld	t3,216(sp)
    80005e9a:	7e8e                	ld	t4,224(sp)
    80005e9c:	7f2e                	ld	t5,232(sp)
    80005e9e:	7fce                	ld	t6,240(sp)
    80005ea0:	6111                	addi	sp,sp,256
    80005ea2:	10200073          	sret
    80005ea6:	00000013          	nop
    80005eaa:	00000013          	nop
    80005eae:	0001                	nop

0000000080005eb0 <timervec>:
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	e10c                	sd	a1,0(a0)
    80005eb6:	e510                	sd	a2,8(a0)
    80005eb8:	e914                	sd	a3,16(a0)
    80005eba:	6d0c                	ld	a1,24(a0)
    80005ebc:	7110                	ld	a2,32(a0)
    80005ebe:	6194                	ld	a3,0(a1)
    80005ec0:	96b2                	add	a3,a3,a2
    80005ec2:	e194                	sd	a3,0(a1)
    80005ec4:	4589                	li	a1,2
    80005ec6:	14459073          	csrw	sip,a1
    80005eca:	6914                	ld	a3,16(a0)
    80005ecc:	6510                	ld	a2,8(a0)
    80005ece:	610c                	ld	a1,0(a0)
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	30200073          	mret
	...

0000000080005eda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eda:	1141                	addi	sp,sp,-16
    80005edc:	e422                	sd	s0,8(sp)
    80005ede:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ee0:	0c0007b7          	lui	a5,0xc000
    80005ee4:	4705                	li	a4,1
    80005ee6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ee8:	c3d8                	sw	a4,4(a5)
}
    80005eea:	6422                	ld	s0,8(sp)
    80005eec:	0141                	addi	sp,sp,16
    80005eee:	8082                	ret

0000000080005ef0 <plicinithart>:

void
plicinithart(void)
{
    80005ef0:	1141                	addi	sp,sp,-16
    80005ef2:	e406                	sd	ra,8(sp)
    80005ef4:	e022                	sd	s0,0(sp)
    80005ef6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	d4c080e7          	jalr	-692(ra) # 80001c44 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f00:	0085171b          	slliw	a4,a0,0x8
    80005f04:	0c0027b7          	lui	a5,0xc002
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	40200713          	li	a4,1026
    80005f0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f12:	00d5151b          	slliw	a0,a0,0xd
    80005f16:	0c2017b7          	lui	a5,0xc201
    80005f1a:	953e                	add	a0,a0,a5
    80005f1c:	00052023          	sw	zero,0(a0)
}
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f28:	1141                	addi	sp,sp,-16
    80005f2a:	e406                	sd	ra,8(sp)
    80005f2c:	e022                	sd	s0,0(sp)
    80005f2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	d14080e7          	jalr	-748(ra) # 80001c44 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f38:	00d5179b          	slliw	a5,a0,0xd
    80005f3c:	0c201537          	lui	a0,0xc201
    80005f40:	953e                	add	a0,a0,a5
  return irq;
}
    80005f42:	4148                	lw	a0,4(a0)
    80005f44:	60a2                	ld	ra,8(sp)
    80005f46:	6402                	ld	s0,0(sp)
    80005f48:	0141                	addi	sp,sp,16
    80005f4a:	8082                	ret

0000000080005f4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f4c:	1101                	addi	sp,sp,-32
    80005f4e:	ec06                	sd	ra,24(sp)
    80005f50:	e822                	sd	s0,16(sp)
    80005f52:	e426                	sd	s1,8(sp)
    80005f54:	1000                	addi	s0,sp,32
    80005f56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	cec080e7          	jalr	-788(ra) # 80001c44 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f60:	00d5151b          	slliw	a0,a0,0xd
    80005f64:	0c2017b7          	lui	a5,0xc201
    80005f68:	97aa                	add	a5,a5,a0
    80005f6a:	c3c4                	sw	s1,4(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret

0000000080005f76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f76:	1141                	addi	sp,sp,-16
    80005f78:	e406                	sd	ra,8(sp)
    80005f7a:	e022                	sd	s0,0(sp)
    80005f7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f7e:	479d                	li	a5,7
    80005f80:	06a7c963          	blt	a5,a0,80005ff2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f84:	0001d797          	auipc	a5,0x1d
    80005f88:	07c78793          	addi	a5,a5,124 # 80023000 <disk>
    80005f8c:	00a78733          	add	a4,a5,a0
    80005f90:	6789                	lui	a5,0x2
    80005f92:	97ba                	add	a5,a5,a4
    80005f94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f98:	e7ad                	bnez	a5,80006002 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f9a:	00451793          	slli	a5,a0,0x4
    80005f9e:	0001f717          	auipc	a4,0x1f
    80005fa2:	06270713          	addi	a4,a4,98 # 80025000 <disk+0x2000>
    80005fa6:	6314                	ld	a3,0(a4)
    80005fa8:	96be                	add	a3,a3,a5
    80005faa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fae:	6314                	ld	a3,0(a4)
    80005fb0:	96be                	add	a3,a3,a5
    80005fb2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005fb6:	6314                	ld	a3,0(a4)
    80005fb8:	96be                	add	a3,a3,a5
    80005fba:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005fbe:	6318                	ld	a4,0(a4)
    80005fc0:	97ba                	add	a5,a5,a4
    80005fc2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005fc6:	0001d797          	auipc	a5,0x1d
    80005fca:	03a78793          	addi	a5,a5,58 # 80023000 <disk>
    80005fce:	97aa                	add	a5,a5,a0
    80005fd0:	6509                	lui	a0,0x2
    80005fd2:	953e                	add	a0,a0,a5
    80005fd4:	4785                	li	a5,1
    80005fd6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fda:	0001f517          	auipc	a0,0x1f
    80005fde:	03e50513          	addi	a0,a0,62 # 80025018 <disk+0x2018>
    80005fe2:	ffffc097          	auipc	ra,0xffffc
    80005fe6:	568080e7          	jalr	1384(ra) # 8000254a <wakeup>
}
    80005fea:	60a2                	ld	ra,8(sp)
    80005fec:	6402                	ld	s0,0(sp)
    80005fee:	0141                	addi	sp,sp,16
    80005ff0:	8082                	ret
    panic("free_desc 1");
    80005ff2:	00002517          	auipc	a0,0x2
    80005ff6:	7e650513          	addi	a0,a0,2022 # 800087d8 <syscalls+0x330>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	544080e7          	jalr	1348(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006002:	00002517          	auipc	a0,0x2
    80006006:	7e650513          	addi	a0,a0,2022 # 800087e8 <syscalls+0x340>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	534080e7          	jalr	1332(ra) # 8000053e <panic>

0000000080006012 <virtio_disk_init>:
{
    80006012:	1101                	addi	sp,sp,-32
    80006014:	ec06                	sd	ra,24(sp)
    80006016:	e822                	sd	s0,16(sp)
    80006018:	e426                	sd	s1,8(sp)
    8000601a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000601c:	00002597          	auipc	a1,0x2
    80006020:	7dc58593          	addi	a1,a1,2012 # 800087f8 <syscalls+0x350>
    80006024:	0001f517          	auipc	a0,0x1f
    80006028:	10450513          	addi	a0,a0,260 # 80025128 <disk+0x2128>
    8000602c:	ffffb097          	auipc	ra,0xffffb
    80006030:	b28080e7          	jalr	-1240(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006034:	100017b7          	lui	a5,0x10001
    80006038:	4398                	lw	a4,0(a5)
    8000603a:	2701                	sext.w	a4,a4
    8000603c:	747277b7          	lui	a5,0x74727
    80006040:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006044:	0ef71163          	bne	a4,a5,80006126 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006048:	100017b7          	lui	a5,0x10001
    8000604c:	43dc                	lw	a5,4(a5)
    8000604e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006050:	4705                	li	a4,1
    80006052:	0ce79a63          	bne	a5,a4,80006126 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006056:	100017b7          	lui	a5,0x10001
    8000605a:	479c                	lw	a5,8(a5)
    8000605c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000605e:	4709                	li	a4,2
    80006060:	0ce79363          	bne	a5,a4,80006126 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006064:	100017b7          	lui	a5,0x10001
    80006068:	47d8                	lw	a4,12(a5)
    8000606a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000606c:	554d47b7          	lui	a5,0x554d4
    80006070:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006074:	0af71963          	bne	a4,a5,80006126 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006078:	100017b7          	lui	a5,0x10001
    8000607c:	4705                	li	a4,1
    8000607e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006080:	470d                	li	a4,3
    80006082:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006084:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006086:	c7ffe737          	lui	a4,0xc7ffe
    8000608a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000608e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006090:	2701                	sext.w	a4,a4
    80006092:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006094:	472d                	li	a4,11
    80006096:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006098:	473d                	li	a4,15
    8000609a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000609c:	6705                	lui	a4,0x1
    8000609e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060a4:	5bdc                	lw	a5,52(a5)
    800060a6:	2781                	sext.w	a5,a5
  if(max == 0)
    800060a8:	c7d9                	beqz	a5,80006136 <virtio_disk_init+0x124>
  if(max < NUM)
    800060aa:	471d                	li	a4,7
    800060ac:	08f77d63          	bgeu	a4,a5,80006146 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060b0:	100014b7          	lui	s1,0x10001
    800060b4:	47a1                	li	a5,8
    800060b6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060b8:	6609                	lui	a2,0x2
    800060ba:	4581                	li	a1,0
    800060bc:	0001d517          	auipc	a0,0x1d
    800060c0:	f4450513          	addi	a0,a0,-188 # 80023000 <disk>
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	c1c080e7          	jalr	-996(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060cc:	0001d717          	auipc	a4,0x1d
    800060d0:	f3470713          	addi	a4,a4,-204 # 80023000 <disk>
    800060d4:	00c75793          	srli	a5,a4,0xc
    800060d8:	2781                	sext.w	a5,a5
    800060da:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060dc:	0001f797          	auipc	a5,0x1f
    800060e0:	f2478793          	addi	a5,a5,-220 # 80025000 <disk+0x2000>
    800060e4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060e6:	0001d717          	auipc	a4,0x1d
    800060ea:	f9a70713          	addi	a4,a4,-102 # 80023080 <disk+0x80>
    800060ee:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800060f0:	0001e717          	auipc	a4,0x1e
    800060f4:	f1070713          	addi	a4,a4,-240 # 80024000 <disk+0x1000>
    800060f8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060fa:	4705                	li	a4,1
    800060fc:	00e78c23          	sb	a4,24(a5)
    80006100:	00e78ca3          	sb	a4,25(a5)
    80006104:	00e78d23          	sb	a4,26(a5)
    80006108:	00e78da3          	sb	a4,27(a5)
    8000610c:	00e78e23          	sb	a4,28(a5)
    80006110:	00e78ea3          	sb	a4,29(a5)
    80006114:	00e78f23          	sb	a4,30(a5)
    80006118:	00e78fa3          	sb	a4,31(a5)
}
    8000611c:	60e2                	ld	ra,24(sp)
    8000611e:	6442                	ld	s0,16(sp)
    80006120:	64a2                	ld	s1,8(sp)
    80006122:	6105                	addi	sp,sp,32
    80006124:	8082                	ret
    panic("could not find virtio disk");
    80006126:	00002517          	auipc	a0,0x2
    8000612a:	6e250513          	addi	a0,a0,1762 # 80008808 <syscalls+0x360>
    8000612e:	ffffa097          	auipc	ra,0xffffa
    80006132:	410080e7          	jalr	1040(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006136:	00002517          	auipc	a0,0x2
    8000613a:	6f250513          	addi	a0,a0,1778 # 80008828 <syscalls+0x380>
    8000613e:	ffffa097          	auipc	ra,0xffffa
    80006142:	400080e7          	jalr	1024(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006146:	00002517          	auipc	a0,0x2
    8000614a:	70250513          	addi	a0,a0,1794 # 80008848 <syscalls+0x3a0>
    8000614e:	ffffa097          	auipc	ra,0xffffa
    80006152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>

0000000080006156 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006156:	7159                	addi	sp,sp,-112
    80006158:	f486                	sd	ra,104(sp)
    8000615a:	f0a2                	sd	s0,96(sp)
    8000615c:	eca6                	sd	s1,88(sp)
    8000615e:	e8ca                	sd	s2,80(sp)
    80006160:	e4ce                	sd	s3,72(sp)
    80006162:	e0d2                	sd	s4,64(sp)
    80006164:	fc56                	sd	s5,56(sp)
    80006166:	f85a                	sd	s6,48(sp)
    80006168:	f45e                	sd	s7,40(sp)
    8000616a:	f062                	sd	s8,32(sp)
    8000616c:	ec66                	sd	s9,24(sp)
    8000616e:	e86a                	sd	s10,16(sp)
    80006170:	1880                	addi	s0,sp,112
    80006172:	892a                	mv	s2,a0
    80006174:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006176:	00c52c83          	lw	s9,12(a0)
    8000617a:	001c9c9b          	slliw	s9,s9,0x1
    8000617e:	1c82                	slli	s9,s9,0x20
    80006180:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006184:	0001f517          	auipc	a0,0x1f
    80006188:	fa450513          	addi	a0,a0,-92 # 80025128 <disk+0x2128>
    8000618c:	ffffb097          	auipc	ra,0xffffb
    80006190:	a58080e7          	jalr	-1448(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006194:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006196:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006198:	0001db97          	auipc	s7,0x1d
    8000619c:	e68b8b93          	addi	s7,s7,-408 # 80023000 <disk>
    800061a0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800061a2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061a4:	8a4e                	mv	s4,s3
    800061a6:	a051                	j	8000622a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800061a8:	00fb86b3          	add	a3,s7,a5
    800061ac:	96da                	add	a3,a3,s6
    800061ae:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061b2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061b4:	0207c563          	bltz	a5,800061de <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061b8:	2485                	addiw	s1,s1,1
    800061ba:	0711                	addi	a4,a4,4
    800061bc:	25548063          	beq	s1,s5,800063fc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800061c0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061c2:	0001f697          	auipc	a3,0x1f
    800061c6:	e5668693          	addi	a3,a3,-426 # 80025018 <disk+0x2018>
    800061ca:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061cc:	0006c583          	lbu	a1,0(a3)
    800061d0:	fde1                	bnez	a1,800061a8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061d2:	2785                	addiw	a5,a5,1
    800061d4:	0685                	addi	a3,a3,1
    800061d6:	ff879be3          	bne	a5,s8,800061cc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061da:	57fd                	li	a5,-1
    800061dc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061de:	02905a63          	blez	s1,80006212 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061e2:	f9042503          	lw	a0,-112(s0)
    800061e6:	00000097          	auipc	ra,0x0
    800061ea:	d90080e7          	jalr	-624(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    800061ee:	4785                	li	a5,1
    800061f0:	0297d163          	bge	a5,s1,80006212 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061f4:	f9442503          	lw	a0,-108(s0)
    800061f8:	00000097          	auipc	ra,0x0
    800061fc:	d7e080e7          	jalr	-642(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    80006200:	4789                	li	a5,2
    80006202:	0097d863          	bge	a5,s1,80006212 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006206:	f9842503          	lw	a0,-104(s0)
    8000620a:	00000097          	auipc	ra,0x0
    8000620e:	d6c080e7          	jalr	-660(ra) # 80005f76 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006212:	0001f597          	auipc	a1,0x1f
    80006216:	f1658593          	addi	a1,a1,-234 # 80025128 <disk+0x2128>
    8000621a:	0001f517          	auipc	a0,0x1f
    8000621e:	dfe50513          	addi	a0,a0,-514 # 80025018 <disk+0x2018>
    80006222:	ffffc097          	auipc	ra,0xffffc
    80006226:	19c080e7          	jalr	412(ra) # 800023be <sleep>
  for(int i = 0; i < 3; i++){
    8000622a:	f9040713          	addi	a4,s0,-112
    8000622e:	84ce                	mv	s1,s3
    80006230:	bf41                	j	800061c0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006232:	20058713          	addi	a4,a1,512
    80006236:	00471693          	slli	a3,a4,0x4
    8000623a:	0001d717          	auipc	a4,0x1d
    8000623e:	dc670713          	addi	a4,a4,-570 # 80023000 <disk>
    80006242:	9736                	add	a4,a4,a3
    80006244:	4685                	li	a3,1
    80006246:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000624a:	20058713          	addi	a4,a1,512
    8000624e:	00471693          	slli	a3,a4,0x4
    80006252:	0001d717          	auipc	a4,0x1d
    80006256:	dae70713          	addi	a4,a4,-594 # 80023000 <disk>
    8000625a:	9736                	add	a4,a4,a3
    8000625c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006260:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006264:	7679                	lui	a2,0xffffe
    80006266:	963e                	add	a2,a2,a5
    80006268:	0001f697          	auipc	a3,0x1f
    8000626c:	d9868693          	addi	a3,a3,-616 # 80025000 <disk+0x2000>
    80006270:	6298                	ld	a4,0(a3)
    80006272:	9732                	add	a4,a4,a2
    80006274:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006276:	6298                	ld	a4,0(a3)
    80006278:	9732                	add	a4,a4,a2
    8000627a:	4541                	li	a0,16
    8000627c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000627e:	6298                	ld	a4,0(a3)
    80006280:	9732                	add	a4,a4,a2
    80006282:	4505                	li	a0,1
    80006284:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006288:	f9442703          	lw	a4,-108(s0)
    8000628c:	6288                	ld	a0,0(a3)
    8000628e:	962a                	add	a2,a2,a0
    80006290:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006294:	0712                	slli	a4,a4,0x4
    80006296:	6290                	ld	a2,0(a3)
    80006298:	963a                	add	a2,a2,a4
    8000629a:	05890513          	addi	a0,s2,88
    8000629e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800062a0:	6294                	ld	a3,0(a3)
    800062a2:	96ba                	add	a3,a3,a4
    800062a4:	40000613          	li	a2,1024
    800062a8:	c690                	sw	a2,8(a3)
  if(write)
    800062aa:	140d0063          	beqz	s10,800063ea <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062ae:	0001f697          	auipc	a3,0x1f
    800062b2:	d526b683          	ld	a3,-686(a3) # 80025000 <disk+0x2000>
    800062b6:	96ba                	add	a3,a3,a4
    800062b8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062bc:	0001d817          	auipc	a6,0x1d
    800062c0:	d4480813          	addi	a6,a6,-700 # 80023000 <disk>
    800062c4:	0001f517          	auipc	a0,0x1f
    800062c8:	d3c50513          	addi	a0,a0,-708 # 80025000 <disk+0x2000>
    800062cc:	6114                	ld	a3,0(a0)
    800062ce:	96ba                	add	a3,a3,a4
    800062d0:	00c6d603          	lhu	a2,12(a3)
    800062d4:	00166613          	ori	a2,a2,1
    800062d8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062dc:	f9842683          	lw	a3,-104(s0)
    800062e0:	6110                	ld	a2,0(a0)
    800062e2:	9732                	add	a4,a4,a2
    800062e4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062e8:	20058613          	addi	a2,a1,512
    800062ec:	0612                	slli	a2,a2,0x4
    800062ee:	9642                	add	a2,a2,a6
    800062f0:	577d                	li	a4,-1
    800062f2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062f6:	00469713          	slli	a4,a3,0x4
    800062fa:	6114                	ld	a3,0(a0)
    800062fc:	96ba                	add	a3,a3,a4
    800062fe:	03078793          	addi	a5,a5,48
    80006302:	97c2                	add	a5,a5,a6
    80006304:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006306:	611c                	ld	a5,0(a0)
    80006308:	97ba                	add	a5,a5,a4
    8000630a:	4685                	li	a3,1
    8000630c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000630e:	611c                	ld	a5,0(a0)
    80006310:	97ba                	add	a5,a5,a4
    80006312:	4809                	li	a6,2
    80006314:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006318:	611c                	ld	a5,0(a0)
    8000631a:	973e                	add	a4,a4,a5
    8000631c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006320:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006324:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006328:	6518                	ld	a4,8(a0)
    8000632a:	00275783          	lhu	a5,2(a4)
    8000632e:	8b9d                	andi	a5,a5,7
    80006330:	0786                	slli	a5,a5,0x1
    80006332:	97ba                	add	a5,a5,a4
    80006334:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006338:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000633c:	6518                	ld	a4,8(a0)
    8000633e:	00275783          	lhu	a5,2(a4)
    80006342:	2785                	addiw	a5,a5,1
    80006344:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006348:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000634c:	100017b7          	lui	a5,0x10001
    80006350:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006354:	00492703          	lw	a4,4(s2)
    80006358:	4785                	li	a5,1
    8000635a:	02f71163          	bne	a4,a5,8000637c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000635e:	0001f997          	auipc	s3,0x1f
    80006362:	dca98993          	addi	s3,s3,-566 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006366:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006368:	85ce                	mv	a1,s3
    8000636a:	854a                	mv	a0,s2
    8000636c:	ffffc097          	auipc	ra,0xffffc
    80006370:	052080e7          	jalr	82(ra) # 800023be <sleep>
  while(b->disk == 1) {
    80006374:	00492783          	lw	a5,4(s2)
    80006378:	fe9788e3          	beq	a5,s1,80006368 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000637c:	f9042903          	lw	s2,-112(s0)
    80006380:	20090793          	addi	a5,s2,512
    80006384:	00479713          	slli	a4,a5,0x4
    80006388:	0001d797          	auipc	a5,0x1d
    8000638c:	c7878793          	addi	a5,a5,-904 # 80023000 <disk>
    80006390:	97ba                	add	a5,a5,a4
    80006392:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006396:	0001f997          	auipc	s3,0x1f
    8000639a:	c6a98993          	addi	s3,s3,-918 # 80025000 <disk+0x2000>
    8000639e:	00491713          	slli	a4,s2,0x4
    800063a2:	0009b783          	ld	a5,0(s3)
    800063a6:	97ba                	add	a5,a5,a4
    800063a8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063ac:	854a                	mv	a0,s2
    800063ae:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063b2:	00000097          	auipc	ra,0x0
    800063b6:	bc4080e7          	jalr	-1084(ra) # 80005f76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063ba:	8885                	andi	s1,s1,1
    800063bc:	f0ed                	bnez	s1,8000639e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063be:	0001f517          	auipc	a0,0x1f
    800063c2:	d6a50513          	addi	a0,a0,-662 # 80025128 <disk+0x2128>
    800063c6:	ffffb097          	auipc	ra,0xffffb
    800063ca:	8d2080e7          	jalr	-1838(ra) # 80000c98 <release>
}
    800063ce:	70a6                	ld	ra,104(sp)
    800063d0:	7406                	ld	s0,96(sp)
    800063d2:	64e6                	ld	s1,88(sp)
    800063d4:	6946                	ld	s2,80(sp)
    800063d6:	69a6                	ld	s3,72(sp)
    800063d8:	6a06                	ld	s4,64(sp)
    800063da:	7ae2                	ld	s5,56(sp)
    800063dc:	7b42                	ld	s6,48(sp)
    800063de:	7ba2                	ld	s7,40(sp)
    800063e0:	7c02                	ld	s8,32(sp)
    800063e2:	6ce2                	ld	s9,24(sp)
    800063e4:	6d42                	ld	s10,16(sp)
    800063e6:	6165                	addi	sp,sp,112
    800063e8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063ea:	0001f697          	auipc	a3,0x1f
    800063ee:	c166b683          	ld	a3,-1002(a3) # 80025000 <disk+0x2000>
    800063f2:	96ba                	add	a3,a3,a4
    800063f4:	4609                	li	a2,2
    800063f6:	00c69623          	sh	a2,12(a3)
    800063fa:	b5c9                	j	800062bc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063fc:	f9042583          	lw	a1,-112(s0)
    80006400:	20058793          	addi	a5,a1,512
    80006404:	0792                	slli	a5,a5,0x4
    80006406:	0001d517          	auipc	a0,0x1d
    8000640a:	ca250513          	addi	a0,a0,-862 # 800230a8 <disk+0xa8>
    8000640e:	953e                	add	a0,a0,a5
  if(write)
    80006410:	e20d11e3          	bnez	s10,80006232 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006414:	20058713          	addi	a4,a1,512
    80006418:	00471693          	slli	a3,a4,0x4
    8000641c:	0001d717          	auipc	a4,0x1d
    80006420:	be470713          	addi	a4,a4,-1052 # 80023000 <disk>
    80006424:	9736                	add	a4,a4,a3
    80006426:	0a072423          	sw	zero,168(a4)
    8000642a:	b505                	j	8000624a <virtio_disk_rw+0xf4>

000000008000642c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000642c:	1101                	addi	sp,sp,-32
    8000642e:	ec06                	sd	ra,24(sp)
    80006430:	e822                	sd	s0,16(sp)
    80006432:	e426                	sd	s1,8(sp)
    80006434:	e04a                	sd	s2,0(sp)
    80006436:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006438:	0001f517          	auipc	a0,0x1f
    8000643c:	cf050513          	addi	a0,a0,-784 # 80025128 <disk+0x2128>
    80006440:	ffffa097          	auipc	ra,0xffffa
    80006444:	7a4080e7          	jalr	1956(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006448:	10001737          	lui	a4,0x10001
    8000644c:	533c                	lw	a5,96(a4)
    8000644e:	8b8d                	andi	a5,a5,3
    80006450:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006452:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006456:	0001f797          	auipc	a5,0x1f
    8000645a:	baa78793          	addi	a5,a5,-1110 # 80025000 <disk+0x2000>
    8000645e:	6b94                	ld	a3,16(a5)
    80006460:	0207d703          	lhu	a4,32(a5)
    80006464:	0026d783          	lhu	a5,2(a3)
    80006468:	06f70163          	beq	a4,a5,800064ca <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000646c:	0001d917          	auipc	s2,0x1d
    80006470:	b9490913          	addi	s2,s2,-1132 # 80023000 <disk>
    80006474:	0001f497          	auipc	s1,0x1f
    80006478:	b8c48493          	addi	s1,s1,-1140 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000647c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006480:	6898                	ld	a4,16(s1)
    80006482:	0204d783          	lhu	a5,32(s1)
    80006486:	8b9d                	andi	a5,a5,7
    80006488:	078e                	slli	a5,a5,0x3
    8000648a:	97ba                	add	a5,a5,a4
    8000648c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000648e:	20078713          	addi	a4,a5,512
    80006492:	0712                	slli	a4,a4,0x4
    80006494:	974a                	add	a4,a4,s2
    80006496:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000649a:	e731                	bnez	a4,800064e6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000649c:	20078793          	addi	a5,a5,512
    800064a0:	0792                	slli	a5,a5,0x4
    800064a2:	97ca                	add	a5,a5,s2
    800064a4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064a6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064aa:	ffffc097          	auipc	ra,0xffffc
    800064ae:	0a0080e7          	jalr	160(ra) # 8000254a <wakeup>

    disk.used_idx += 1;
    800064b2:	0204d783          	lhu	a5,32(s1)
    800064b6:	2785                	addiw	a5,a5,1
    800064b8:	17c2                	slli	a5,a5,0x30
    800064ba:	93c1                	srli	a5,a5,0x30
    800064bc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064c0:	6898                	ld	a4,16(s1)
    800064c2:	00275703          	lhu	a4,2(a4)
    800064c6:	faf71be3          	bne	a4,a5,8000647c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064ca:	0001f517          	auipc	a0,0x1f
    800064ce:	c5e50513          	addi	a0,a0,-930 # 80025128 <disk+0x2128>
    800064d2:	ffffa097          	auipc	ra,0xffffa
    800064d6:	7c6080e7          	jalr	1990(ra) # 80000c98 <release>
}
    800064da:	60e2                	ld	ra,24(sp)
    800064dc:	6442                	ld	s0,16(sp)
    800064de:	64a2                	ld	s1,8(sp)
    800064e0:	6902                	ld	s2,0(sp)
    800064e2:	6105                	addi	sp,sp,32
    800064e4:	8082                	ret
      panic("virtio_disk_intr status");
    800064e6:	00002517          	auipc	a0,0x2
    800064ea:	38250513          	addi	a0,a0,898 # 80008868 <syscalls+0x3c0>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	050080e7          	jalr	80(ra) # 8000053e <panic>

00000000800064f6 <cas>:
    800064f6:	100522af          	lr.w	t0,(a0)
    800064fa:	00b29563          	bne	t0,a1,80006504 <fail>
    800064fe:	18c5252f          	sc.w	a0,a2,(a0)
    80006502:	8082                	ret

0000000080006504 <fail>:
    80006504:	4505                	li	a0,1
    80006506:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
