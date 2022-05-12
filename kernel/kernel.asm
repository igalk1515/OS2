
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9c013103          	ld	sp,-1600(sp) # 800089c0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	01e70713          	addi	a4,a4,30 # 80009070 <timer_scratch>
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
    80000068:	51c78793          	addi	a5,a5,1308 # 80006580 <timervec>
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
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	d56080e7          	jalr	-682(ra) # 80002e82 <either_copyin>
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
    80000190:	02450513          	addi	a0,a0,36 # 800111b0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	01448493          	addi	s1,s1,20 # 800111b0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	0a290913          	addi	s2,s2,162 # 80011248 <cons+0x98>
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
    800001c8:	01c080e7          	jalr	28(ra) # 800021e0 <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	790080e7          	jalr	1936(ra) # 80002964 <sleep>
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
    80000214:	c1c080e7          	jalr	-996(ra) # 80002e2c <either_copyout>
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
    80000228:	f8c50513          	addi	a0,a0,-116 # 800111b0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f7650513          	addi	a0,a0,-138 # 800111b0 <cons>
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
    80000276:	fcf72b23          	sw	a5,-42(a4) # 80011248 <cons+0x98>
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
    800002d0:	ee450513          	addi	a0,a0,-284 # 800111b0 <cons>
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
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	be6080e7          	jalr	-1050(ra) # 80002ed8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	eb650513          	addi	a0,a0,-330 # 800111b0 <cons>
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
    80000322:	e9270713          	addi	a4,a4,-366 # 800111b0 <cons>
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
    8000034c:	e6878793          	addi	a5,a5,-408 # 800111b0 <cons>
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
    8000037a:	ed27a783          	lw	a5,-302(a5) # 80011248 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e2670713          	addi	a4,a4,-474 # 800111b0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e1648493          	addi	s1,s1,-490 # 800111b0 <cons>
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
    800003da:	dda70713          	addi	a4,a4,-550 # 800111b0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e6f72223          	sw	a5,-412(a4) # 80011250 <cons+0xa0>
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
    80000416:	d9e78793          	addi	a5,a5,-610 # 800111b0 <cons>
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
    8000043a:	e0c7ab23          	sw	a2,-490(a5) # 8001124c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	e0a50513          	addi	a0,a0,-502 # 80011248 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	6b8080e7          	jalr	1720(ra) # 80002afe <wakeup>
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
    80000464:	d5050513          	addi	a0,a0,-688 # 800111b0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	61878793          	addi	a5,a5,1560 # 80021a90 <devsw>
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
    8000054e:	d207a323          	sw	zero,-730(a5) # 80011270 <pr+0x18>
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
    800005be:	cb6dad83          	lw	s11,-842(s11) # 80011270 <pr+0x18>
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
    800005fc:	c6050513          	addi	a0,a0,-928 # 80011258 <pr>
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
    80000760:	afc50513          	addi	a0,a0,-1284 # 80011258 <pr>
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
    8000077c:	ae048493          	addi	s1,s1,-1312 # 80011258 <pr>
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
    800007dc:	aa050513          	addi	a0,a0,-1376 # 80011278 <uart_tx_lock>
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
    8000086e:	a0ea0a13          	addi	s4,s4,-1522 # 80011278 <uart_tx_lock>
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
    800008a4:	25e080e7          	jalr	606(ra) # 80002afe <wakeup>
    
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
    800008e0:	99c50513          	addi	a0,a0,-1636 # 80011278 <uart_tx_lock>
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
    80000914:	968a0a13          	addi	s4,s4,-1688 # 80011278 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	038080e7          	jalr	56(ra) # 80002964 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	93648493          	addi	s1,s1,-1738 # 80011278 <uart_tx_lock>
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
    800009ce:	8ae48493          	addi	s1,s1,-1874 # 80011278 <uart_tx_lock>
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
    80000a30:	88490913          	addi	s2,s2,-1916 # 800112b0 <kmem>
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
    80000acc:	7e850513          	addi	a0,a0,2024 # 800112b0 <kmem>
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
    80000b02:	7b248493          	addi	s1,s1,1970 # 800112b0 <kmem>
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
    80000b1a:	79a50513          	addi	a0,a0,1946 # 800112b0 <kmem>
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
    80000b46:	76e50513          	addi	a0,a0,1902 # 800112b0 <kmem>
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
    80000b82:	63e080e7          	jalr	1598(ra) # 800021bc <mycpu>
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
    80000bb4:	60c080e7          	jalr	1548(ra) # 800021bc <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	600080e7          	jalr	1536(ra) # 800021bc <mycpu>
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
    80000bd8:	5e8080e7          	jalr	1512(ra) # 800021bc <mycpu>
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
    80000c18:	5a8080e7          	jalr	1448(ra) # 800021bc <mycpu>
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
    80000c44:	57c080e7          	jalr	1404(ra) # 800021bc <mycpu>
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
    80000e9a:	316080e7          	jalr	790(ra) # 800021ac <cpuid>
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
    80000eb6:	2fa080e7          	jalr	762(ra) # 800021ac <cpuid>
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
    80000ed8:	144080e7          	jalr	324(ra) # 80003018 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	6e4080e7          	jalr	1764(ra) # 800065c0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	85c080e7          	jalr	-1956(ra) # 80002740 <scheduler>
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
    80000f48:	126080e7          	jalr	294(ra) # 8000206a <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	0a4080e7          	jalr	164(ra) # 80002ff0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	0c4080e7          	jalr	196(ra) # 80003018 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	64e080e7          	jalr	1614(ra) # 800065aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	65c080e7          	jalr	1628(ra) # 800065c0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00003097          	auipc	ra,0x3
    80000f70:	838080e7          	jalr	-1992(ra) # 800037a4 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	ec8080e7          	jalr	-312(ra) # 80003e3c <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	e72080e7          	jalr	-398(ra) # 80004dee <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	75e080e7          	jalr	1886(ra) # 800066e2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	546080e7          	jalr	1350(ra) # 800024d2 <userinit>
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
    80001244:	d94080e7          	jalr	-620(ra) # 80001fd4 <proc_mapstacks>
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

000000008000183e <acquire_list2>:
 * 2 = zombie 
 * 3 = sleeping 
 * 4 = unused  
 */
void
acquire_list2(int number, int parent_cpu){ // TODO: change name of function
    8000183e:	1141                	addi	sp,sp,-16
    80001840:	e406                	sd	ra,8(sp)
    80001842:	e022                	sd	s0,0(sp)
    80001844:	0800                	addi	s0,sp,16
int a =0;
a=a+1;
if(a==0){
  panic("a not zero ");
}
  number == 1 ?  acquire(&readyLock[parent_cpu]): 
    80001846:	4785                	li	a5,1
    80001848:	02f50763          	beq	a0,a5,80001876 <acquire_list2+0x38>
    number == 2 ? acquire(&zombieLock): 
    8000184c:	4789                	li	a5,2
    8000184e:	04f50263          	beq	a0,a5,80001892 <acquire_list2+0x54>
      number == 3 ? acquire(&sleepLock): 
    80001852:	478d                	li	a5,3
    80001854:	04f50863          	beq	a0,a5,800018a4 <acquire_list2+0x66>
        number == 4 ? acquire(&unusedLock):  
    80001858:	4791                	li	a5,4
    8000185a:	04f51e63          	bne	a0,a5,800018b6 <acquire_list2+0x78>
    8000185e:	00010517          	auipc	a0,0x10
    80001862:	aba50513          	addi	a0,a0,-1350 # 80011318 <unusedLock>
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	37e080e7          	jalr	894(ra) # 80000be4 <acquire>
          panic("wrong call in acquire_list2");
}
    8000186e:	60a2                	ld	ra,8(sp)
    80001870:	6402                	ld	s0,0(sp)
    80001872:	0141                	addi	sp,sp,16
    80001874:	8082                	ret
  number == 1 ?  acquire(&readyLock[parent_cpu]): 
    80001876:	00159513          	slli	a0,a1,0x1
    8000187a:	95aa                	add	a1,a1,a0
    8000187c:	058e                	slli	a1,a1,0x3
    8000187e:	00010517          	auipc	a0,0x10
    80001882:	a5250513          	addi	a0,a0,-1454 # 800112d0 <readyLock>
    80001886:	952e                	add	a0,a0,a1
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	35c080e7          	jalr	860(ra) # 80000be4 <acquire>
    80001890:	bff9                	j	8000186e <acquire_list2+0x30>
    number == 2 ? acquire(&zombieLock): 
    80001892:	00010517          	auipc	a0,0x10
    80001896:	a5650513          	addi	a0,a0,-1450 # 800112e8 <zombieLock>
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	34a080e7          	jalr	842(ra) # 80000be4 <acquire>
    800018a2:	b7f1                	j	8000186e <acquire_list2+0x30>
      number == 3 ? acquire(&sleepLock): 
    800018a4:	00010517          	auipc	a0,0x10
    800018a8:	a5c50513          	addi	a0,a0,-1444 # 80011300 <sleepLock>
    800018ac:	fffff097          	auipc	ra,0xfffff
    800018b0:	338080e7          	jalr	824(ra) # 80000be4 <acquire>
    800018b4:	bf6d                	j	8000186e <acquire_list2+0x30>
          panic("wrong call in acquire_list2");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	92250513          	addi	a0,a0,-1758 # 800081d8 <digits+0x198>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c80080e7          	jalr	-896(ra) # 8000053e <panic>

00000000800018c6 <get_first2>:

struct proc* get_first2(int number, int parent_cpu){
  struct proc* p;
  number == 1 ? p = cpus[parent_cpu].first :
    800018c6:	4785                	li	a5,1
    800018c8:	02f50063          	beq	a0,a5,800018e8 <get_first2+0x22>
    number == 2 ? p = zombieList  :
    800018cc:	4789                	li	a5,2
    800018ce:	02f50863          	beq	a0,a5,800018fe <get_first2+0x38>
      number == 3 ? p = sleepingList :
    800018d2:	478d                	li	a5,3
    800018d4:	02f50a63          	beq	a0,a5,80001908 <get_first2+0x42>
        number == 4 ? p = unusedList:
    800018d8:	4791                	li	a5,4
    800018da:	02f51c63          	bne	a0,a5,80001912 <get_first2+0x4c>
    800018de:	00007517          	auipc	a0,0x7
    800018e2:	76a53503          	ld	a0,1898(a0) # 80009048 <unusedList>
          panic("wrong call in get_first2");
  return p;
}
    800018e6:	8082                	ret
  number == 1 ? p = cpus[parent_cpu].first :
    800018e8:	00459793          	slli	a5,a1,0x4
    800018ec:	95be                	add	a1,a1,a5
    800018ee:	058e                	slli	a1,a1,0x3
    800018f0:	00010797          	auipc	a5,0x10
    800018f4:	9e078793          	addi	a5,a5,-1568 # 800112d0 <readyLock>
    800018f8:	95be                	add	a1,a1,a5
    800018fa:	71e8                	ld	a0,224(a1)
    800018fc:	8082                	ret
    number == 2 ? p = zombieList  :
    800018fe:	00007517          	auipc	a0,0x7
    80001902:	75a53503          	ld	a0,1882(a0) # 80009058 <zombieList>
    80001906:	8082                	ret
      number == 3 ? p = sleepingList :
    80001908:	00007517          	auipc	a0,0x7
    8000190c:	74853503          	ld	a0,1864(a0) # 80009050 <sleepingList>
    80001910:	8082                	ret
struct proc* get_first2(int number, int parent_cpu){
    80001912:	1141                	addi	sp,sp,-16
    80001914:	e406                	sd	ra,8(sp)
    80001916:	e022                	sd	s0,0(sp)
    80001918:	0800                	addi	s0,sp,16
          panic("wrong call in get_first2");
    8000191a:	00007517          	auipc	a0,0x7
    8000191e:	8de50513          	addi	a0,a0,-1826 # 800081f8 <digits+0x1b8>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	c1c080e7          	jalr	-996(ra) # 8000053e <panic>

000000008000192a <set_first2>:

void
set_first2(struct proc* p, int number, int parent_cpu)//TODO: change name of function
{
  number == 1 ?  cpus[parent_cpu].first = p: 
    8000192a:	4785                	li	a5,1
    8000192c:	00f58c63          	beq	a1,a5,80001944 <set_first2+0x1a>
    number == 2 ? zombieList = p: 
    80001930:	4789                	li	a5,2
    80001932:	02f58463          	beq	a1,a5,8000195a <set_first2+0x30>
      number == 3 ? sleepingList = p: 
    80001936:	478d                	li	a5,3
    80001938:	02f58663          	beq	a1,a5,80001964 <set_first2+0x3a>
        number == 4 ? unusedList:  
    8000193c:	4791                	li	a5,4
    8000193e:	02f59863          	bne	a1,a5,8000196e <set_first2+0x44>
    80001942:	8082                	ret
  number == 1 ?  cpus[parent_cpu].first = p: 
    80001944:	00461793          	slli	a5,a2,0x4
    80001948:	963e                	add	a2,a2,a5
    8000194a:	060e                	slli	a2,a2,0x3
    8000194c:	00010797          	auipc	a5,0x10
    80001950:	98478793          	addi	a5,a5,-1660 # 800112d0 <readyLock>
    80001954:	963e                	add	a2,a2,a5
    80001956:	f268                	sd	a0,224(a2)
    80001958:	8082                	ret
    number == 2 ? zombieList = p: 
    8000195a:	00007797          	auipc	a5,0x7
    8000195e:	6ea7bf23          	sd	a0,1790(a5) # 80009058 <zombieList>
    80001962:	8082                	ret
      number == 3 ? sleepingList = p: 
    80001964:	00007797          	auipc	a5,0x7
    80001968:	6ea7b623          	sd	a0,1772(a5) # 80009050 <sleepingList>
    8000196c:	8082                	ret
{
    8000196e:	1141                	addi	sp,sp,-16
    80001970:	e406                	sd	ra,8(sp)
    80001972:	e022                	sd	s0,0(sp)
    80001974:	0800                	addi	s0,sp,16
          panic("wrong call in set_first2");
    80001976:	00007517          	auipc	a0,0x7
    8000197a:	8a250513          	addi	a0,a0,-1886 # 80008218 <digits+0x1d8>
    8000197e:	fffff097          	auipc	ra,0xfffff
    80001982:	bc0080e7          	jalr	-1088(ra) # 8000053e <panic>

0000000080001986 <release_list2>:
}

void
release_list2(int number, int parent_cpu){
    80001986:	1141                	addi	sp,sp,-16
    80001988:	e406                	sd	ra,8(sp)
    8000198a:	e022                	sd	s0,0(sp)
    8000198c:	0800                	addi	s0,sp,16
    number == 1 ?  release(&readyLock[parent_cpu]): 
    8000198e:	4785                	li	a5,1
    80001990:	02f50763          	beq	a0,a5,800019be <release_list2+0x38>
      number == 2 ? release(&zombieLock): 
    80001994:	4789                	li	a5,2
    80001996:	04f50263          	beq	a0,a5,800019da <release_list2+0x54>
        number == 3 ? release(&sleepLock): 
    8000199a:	478d                	li	a5,3
    8000199c:	04f50863          	beq	a0,a5,800019ec <release_list2+0x66>
          number == 4 ? release(&unusedLock):  
    800019a0:	4791                	li	a5,4
    800019a2:	04f51e63          	bne	a0,a5,800019fe <release_list2+0x78>
    800019a6:	00010517          	auipc	a0,0x10
    800019aa:	97250513          	addi	a0,a0,-1678 # 80011318 <unusedLock>
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	2ea080e7          	jalr	746(ra) # 80000c98 <release>
            panic("wrong call in release_list2");
}
    800019b6:	60a2                	ld	ra,8(sp)
    800019b8:	6402                	ld	s0,0(sp)
    800019ba:	0141                	addi	sp,sp,16
    800019bc:	8082                	ret
    number == 1 ?  release(&readyLock[parent_cpu]): 
    800019be:	00159513          	slli	a0,a1,0x1
    800019c2:	95aa                	add	a1,a1,a0
    800019c4:	058e                	slli	a1,a1,0x3
    800019c6:	00010517          	auipc	a0,0x10
    800019ca:	90a50513          	addi	a0,a0,-1782 # 800112d0 <readyLock>
    800019ce:	952e                	add	a0,a0,a1
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	2c8080e7          	jalr	712(ra) # 80000c98 <release>
    800019d8:	bff9                	j	800019b6 <release_list2+0x30>
      number == 2 ? release(&zombieLock): 
    800019da:	00010517          	auipc	a0,0x10
    800019de:	90e50513          	addi	a0,a0,-1778 # 800112e8 <zombieLock>
    800019e2:	fffff097          	auipc	ra,0xfffff
    800019e6:	2b6080e7          	jalr	694(ra) # 80000c98 <release>
    800019ea:	b7f1                	j	800019b6 <release_list2+0x30>
        number == 3 ? release(&sleepLock): 
    800019ec:	00010517          	auipc	a0,0x10
    800019f0:	91450513          	addi	a0,a0,-1772 # 80011300 <sleepLock>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	2a4080e7          	jalr	676(ra) # 80000c98 <release>
    800019fc:	bf6d                	j	800019b6 <release_list2+0x30>
            panic("wrong call in release_list2");
    800019fe:	00007517          	auipc	a0,0x7
    80001a02:	83a50513          	addi	a0,a0,-1990 # 80008238 <digits+0x1f8>
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	b38080e7          	jalr	-1224(ra) # 8000053e <panic>

0000000080001a0e <add_to_list2>:


void
add_to_list2(struct proc* p, struct proc* first, int type, int parent_cpu)//TODO: change name of function
{
    80001a0e:	7139                	addi	sp,sp,-64
    80001a10:	fc06                	sd	ra,56(sp)
    80001a12:	f822                	sd	s0,48(sp)
    80001a14:	f426                	sd	s1,40(sp)
    80001a16:	f04a                	sd	s2,32(sp)
    80001a18:	ec4e                	sd	s3,24(sp)
    80001a1a:	e852                	sd	s4,16(sp)
    80001a1c:	e456                	sd	s5,8(sp)
    80001a1e:	e05a                	sd	s6,0(sp)
    80001a20:	0080                	addi	s0,sp,64
  if(!p){
    80001a22:	c505                	beqz	a0,80001a4a <add_to_list2+0x3c>
    80001a24:	8b2a                	mv	s6,a0
    80001a26:	84ae                	mv	s1,a1
    80001a28:	8a32                	mv	s4,a2
    80001a2a:	8ab6                	mv	s5,a3
  if(!first){
      set_first2(p, type, parent_cpu);
      release_list2(type, parent_cpu);
  }
  else{
    struct proc* prev = 0;
    80001a2c:	4901                	li	s2,0
  if(!first){
    80001a2e:	e1a1                	bnez	a1,80001a6e <add_to_list2+0x60>
      set_first2(p, type, parent_cpu);
    80001a30:	8636                	mv	a2,a3
    80001a32:	85d2                	mv	a1,s4
    80001a34:	00000097          	auipc	ra,0x0
    80001a38:	ef6080e7          	jalr	-266(ra) # 8000192a <set_first2>
      release_list2(type, parent_cpu);
    80001a3c:	85d6                	mv	a1,s5
    80001a3e:	8552                	mv	a0,s4
    80001a40:	00000097          	auipc	ra,0x0
    80001a44:	f46080e7          	jalr	-186(ra) # 80001986 <release_list2>
    80001a48:	a891                	j	80001a9c <add_to_list2+0x8e>
    panic("can't add null to list");
    80001a4a:	00007517          	auipc	a0,0x7
    80001a4e:	80e50513          	addi	a0,a0,-2034 # 80008258 <digits+0x218>
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	aec080e7          	jalr	-1300(ra) # 8000053e <panic>

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list2(type, parent_cpu);
    80001a5a:	85d6                	mv	a1,s5
    80001a5c:	8552                	mv	a0,s4
    80001a5e:	00000097          	auipc	ra,0x0
    80001a62:	f28080e7          	jalr	-216(ra) # 80001986 <release_list2>
      }
      prev = first;
      first = first->next;
    80001a66:	68bc                	ld	a5,80(s1)
    while(first){
    80001a68:	8926                	mv	s2,s1
    80001a6a:	c395                	beqz	a5,80001a8e <add_to_list2+0x80>
      first = first->next;
    80001a6c:	84be                	mv	s1,a5
      acquire(&first->list_lock);
    80001a6e:	01848993          	addi	s3,s1,24
    80001a72:	854e                	mv	a0,s3
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	170080e7          	jalr	368(ra) # 80000be4 <acquire>
      if(prev){
    80001a7c:	fc090fe3          	beqz	s2,80001a5a <add_to_list2+0x4c>
        release(&prev->list_lock);
    80001a80:	01890513          	addi	a0,s2,24 # 1018 <_entry-0x7fffefe8>
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	214080e7          	jalr	532(ra) # 80000c98 <release>
    80001a8c:	bfe9                	j	80001a66 <add_to_list2+0x58>
    }
    prev->next = p;
    80001a8e:	0564b823          	sd	s6,80(s1)
    release(&prev->list_lock);
    80001a92:	854e                	mv	a0,s3
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	204080e7          	jalr	516(ra) # 80000c98 <release>
  }
}
    80001a9c:	70e2                	ld	ra,56(sp)
    80001a9e:	7442                	ld	s0,48(sp)
    80001aa0:	74a2                	ld	s1,40(sp)
    80001aa2:	7902                	ld	s2,32(sp)
    80001aa4:	69e2                	ld	s3,24(sp)
    80001aa6:	6a42                	ld	s4,16(sp)
    80001aa8:	6aa2                	ld	s5,8(sp)
    80001aaa:	6b02                	ld	s6,0(sp)
    80001aac:	6121                	addi	sp,sp,64
    80001aae:	8082                	ret

0000000080001ab0 <add_proc2>:

void //TODO: cahnge 
add_proc2(struct proc* p, int number, int parent_cpu)
{
    80001ab0:	7179                	addi	sp,sp,-48
    80001ab2:	f406                	sd	ra,40(sp)
    80001ab4:	f022                	sd	s0,32(sp)
    80001ab6:	ec26                	sd	s1,24(sp)
    80001ab8:	e84a                	sd	s2,16(sp)
    80001aba:	e44e                	sd	s3,8(sp)
    80001abc:	1800                	addi	s0,sp,48
    80001abe:	89aa                	mv	s3,a0
    80001ac0:	84ae                	mv	s1,a1
    80001ac2:	8932                	mv	s2,a2
  struct proc* first;
  acquire_list2(number, parent_cpu);
    80001ac4:	85b2                	mv	a1,a2
    80001ac6:	8526                	mv	a0,s1
    80001ac8:	00000097          	auipc	ra,0x0
    80001acc:	d76080e7          	jalr	-650(ra) # 8000183e <acquire_list2>
  first = get_first2(number, parent_cpu);
    80001ad0:	85ca                	mv	a1,s2
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	df2080e7          	jalr	-526(ra) # 800018c6 <get_first2>
    80001adc:	85aa                	mv	a1,a0
  add_to_list2(p, first, number, parent_cpu);//TODO change name
    80001ade:	86ca                	mv	a3,s2
    80001ae0:	8626                	mv	a2,s1
    80001ae2:	854e                	mv	a0,s3
    80001ae4:	00000097          	auipc	ra,0x0
    80001ae8:	f2a080e7          	jalr	-214(ra) # 80001a0e <add_to_list2>
}
    80001aec:	70a2                	ld	ra,40(sp)
    80001aee:	7402                	ld	s0,32(sp)
    80001af0:	64e2                	ld	s1,24(sp)
    80001af2:	6942                	ld	s2,16(sp)
    80001af4:	69a2                	ld	s3,8(sp)
    80001af6:	6145                	addi	sp,sp,48
    80001af8:	8082                	ret

0000000080001afa <acquire_list>:
struct spinlock zombie_lock;
struct spinlock sleeping_lock;
struct spinlock unused_lock;

void
acquire_list(int type, int cpu_id){
    80001afa:	1141                	addi	sp,sp,-16
    80001afc:	e406                	sd	ra,8(sp)
    80001afe:	e022                	sd	s0,0(sp)
    80001b00:	0800                	addi	s0,sp,16
  switch (type)
    80001b02:	4789                	li	a5,2
    80001b04:	04f50e63          	beq	a0,a5,80001b60 <acquire_list+0x66>
    80001b08:	00a7cf63          	blt	a5,a0,80001b26 <acquire_list+0x2c>
    80001b0c:	c90d                	beqz	a0,80001b3e <acquire_list+0x44>
    80001b0e:	4785                	li	a5,1
    80001b10:	06f51163          	bne	a0,a5,80001b72 <acquire_list+0x78>
  {
  case READYL:
    acquire(&ready_lock[cpu_id]);
    break;
  case ZOMBIEL:
    acquire(&zombie_lock);
    80001b14:	00010517          	auipc	a0,0x10
    80001b18:	8bc50513          	addi	a0,a0,-1860 # 800113d0 <zombie_lock>
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	0c8080e7          	jalr	200(ra) # 80000be4 <acquire>
    break;
    80001b24:	a815                	j	80001b58 <acquire_list+0x5e>
  switch (type)
    80001b26:	478d                	li	a5,3
    80001b28:	04f51563          	bne	a0,a5,80001b72 <acquire_list+0x78>
  case SLEEPINGL:
    acquire(&sleeping_lock);
    break;
  case UNUSEDL:
    acquire(&unused_lock);
    80001b2c:	00010517          	auipc	a0,0x10
    80001b30:	8d450513          	addi	a0,a0,-1836 # 80011400 <unused_lock>
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	0b0080e7          	jalr	176(ra) # 80000be4 <acquire>
    break;
    80001b3c:	a831                	j	80001b58 <acquire_list+0x5e>
    acquire(&ready_lock[cpu_id]);
    80001b3e:	00159513          	slli	a0,a1,0x1
    80001b42:	95aa                	add	a1,a1,a0
    80001b44:	058e                	slli	a1,a1,0x3
    80001b46:	00010517          	auipc	a0,0x10
    80001b4a:	87250513          	addi	a0,a0,-1934 # 800113b8 <ready_lock>
    80001b4e:	952e                	add	a0,a0,a1
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	094080e7          	jalr	148(ra) # 80000be4 <acquire>
  
  default:
    panic("wrong type list");
  }
}
    80001b58:	60a2                	ld	ra,8(sp)
    80001b5a:	6402                	ld	s0,0(sp)
    80001b5c:	0141                	addi	sp,sp,16
    80001b5e:	8082                	ret
    acquire(&sleeping_lock);
    80001b60:	00010517          	auipc	a0,0x10
    80001b64:	88850513          	addi	a0,a0,-1912 # 800113e8 <sleeping_lock>
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	07c080e7          	jalr	124(ra) # 80000be4 <acquire>
    break;
    80001b70:	b7e5                	j	80001b58 <acquire_list+0x5e>
    panic("wrong type list");
    80001b72:	00006517          	auipc	a0,0x6
    80001b76:	6fe50513          	addi	a0,a0,1790 # 80008270 <digits+0x230>
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	9c4080e7          	jalr	-1596(ra) # 8000053e <panic>

0000000080001b82 <get_head>:

struct proc* get_head(int type, int cpu_id){
  struct proc* p;

  switch (type)
    80001b82:	4789                	li	a5,2
    80001b84:	04f50063          	beq	a0,a5,80001bc4 <get_head+0x42>
    80001b88:	00a7cb63          	blt	a5,a0,80001b9e <get_head+0x1c>
    80001b8c:	c10d                	beqz	a0,80001bae <get_head+0x2c>
    80001b8e:	4785                	li	a5,1
    80001b90:	02f51f63          	bne	a0,a5,80001bce <get_head+0x4c>
  {
  case READYL:
    p = cpus[cpu_id].first;
    break;
  case ZOMBIEL:
    p = zombie_list;
    80001b94:	00007517          	auipc	a0,0x7
    80001b98:	4a453503          	ld	a0,1188(a0) # 80009038 <zombie_list>
    break;
    80001b9c:	8082                	ret
  switch (type)
    80001b9e:	478d                	li	a5,3
    80001ba0:	02f51763          	bne	a0,a5,80001bce <get_head+0x4c>
  case SLEEPINGL:
    p = sleeping_list;
    break;
  case UNUSEDL:
    p = unused_list;
    80001ba4:	00007517          	auipc	a0,0x7
    80001ba8:	48453503          	ld	a0,1156(a0) # 80009028 <unused_list>
  
  default:
    panic("wrong type list");
  }
  return p;
}
    80001bac:	8082                	ret
    p = cpus[cpu_id].first;
    80001bae:	00459793          	slli	a5,a1,0x4
    80001bb2:	95be                	add	a1,a1,a5
    80001bb4:	058e                	slli	a1,a1,0x3
    80001bb6:	0000f797          	auipc	a5,0xf
    80001bba:	71a78793          	addi	a5,a5,1818 # 800112d0 <readyLock>
    80001bbe:	95be                	add	a1,a1,a5
    80001bc0:	71e8                	ld	a0,224(a1)
    break;
    80001bc2:	8082                	ret
    p = sleeping_list;
    80001bc4:	00007517          	auipc	a0,0x7
    80001bc8:	46c53503          	ld	a0,1132(a0) # 80009030 <sleeping_list>
    break;
    80001bcc:	8082                	ret
struct proc* get_head(int type, int cpu_id){
    80001bce:	1141                	addi	sp,sp,-16
    80001bd0:	e406                	sd	ra,8(sp)
    80001bd2:	e022                	sd	s0,0(sp)
    80001bd4:	0800                	addi	s0,sp,16
    panic("wrong type list");
    80001bd6:	00006517          	auipc	a0,0x6
    80001bda:	69a50513          	addi	a0,a0,1690 # 80008270 <digits+0x230>
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	960080e7          	jalr	-1696(ra) # 8000053e <panic>

0000000080001be6 <set_head>:


void
set_head(struct proc* p, int type, int cpu_id)
{
  switch (type)
    80001be6:	4789                	li	a5,2
    80001be8:	04f58063          	beq	a1,a5,80001c28 <set_head+0x42>
    80001bec:	00b7cb63          	blt	a5,a1,80001c02 <set_head+0x1c>
    80001bf0:	c18d                	beqz	a1,80001c12 <set_head+0x2c>
    80001bf2:	4785                	li	a5,1
    80001bf4:	02f59f63          	bne	a1,a5,80001c32 <set_head+0x4c>
  {
  case READYL:
    cpus[cpu_id].first = p;
    break;
  case ZOMBIEL:
    zombie_list = p;
    80001bf8:	00007797          	auipc	a5,0x7
    80001bfc:	44a7b023          	sd	a0,1088(a5) # 80009038 <zombie_list>
    break;
    80001c00:	8082                	ret
  switch (type)
    80001c02:	478d                	li	a5,3
    80001c04:	02f59763          	bne	a1,a5,80001c32 <set_head+0x4c>
  case SLEEPINGL:
    sleeping_list = p;
    break;
  case UNUSEDL:
    unused_list = p;
    80001c08:	00007797          	auipc	a5,0x7
    80001c0c:	42a7b023          	sd	a0,1056(a5) # 80009028 <unused_list>
    break;
    80001c10:	8082                	ret
    cpus[cpu_id].first = p;
    80001c12:	00461793          	slli	a5,a2,0x4
    80001c16:	963e                	add	a2,a2,a5
    80001c18:	060e                	slli	a2,a2,0x3
    80001c1a:	0000f797          	auipc	a5,0xf
    80001c1e:	6b678793          	addi	a5,a5,1718 # 800112d0 <readyLock>
    80001c22:	963e                	add	a2,a2,a5
    80001c24:	f268                	sd	a0,224(a2)
    break;
    80001c26:	8082                	ret
    sleeping_list = p;
    80001c28:	00007797          	auipc	a5,0x7
    80001c2c:	40a7b423          	sd	a0,1032(a5) # 80009030 <sleeping_list>
    break;
    80001c30:	8082                	ret
{
    80001c32:	1141                	addi	sp,sp,-16
    80001c34:	e406                	sd	ra,8(sp)
    80001c36:	e022                	sd	s0,0(sp)
    80001c38:	0800                	addi	s0,sp,16

  
  default:
    panic("wrong type list");
    80001c3a:	00006517          	auipc	a0,0x6
    80001c3e:	63650513          	addi	a0,a0,1590 # 80008270 <digits+0x230>
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	8fc080e7          	jalr	-1796(ra) # 8000053e <panic>

0000000080001c4a <release_list3>:
  }
}

void
release_list3(int number, int parent_cpu){
    80001c4a:	1141                	addi	sp,sp,-16
    80001c4c:	e406                	sd	ra,8(sp)
    80001c4e:	e022                	sd	s0,0(sp)
    80001c50:	0800                	addi	s0,sp,16
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001c52:	4785                	li	a5,1
    80001c54:	02f50763          	beq	a0,a5,80001c82 <release_list3+0x38>
      number == 2 ? release(&zombie_lock): 
    80001c58:	4789                	li	a5,2
    80001c5a:	04f50263          	beq	a0,a5,80001c9e <release_list3+0x54>
        number == 3 ? release(&sleeping_lock): 
    80001c5e:	478d                	li	a5,3
    80001c60:	04f50863          	beq	a0,a5,80001cb0 <release_list3+0x66>
          number == 4 ? release(&unused_lock):  
    80001c64:	4791                	li	a5,4
    80001c66:	04f51e63          	bne	a0,a5,80001cc2 <release_list3+0x78>
    80001c6a:	0000f517          	auipc	a0,0xf
    80001c6e:	79650513          	addi	a0,a0,1942 # 80011400 <unused_lock>
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	026080e7          	jalr	38(ra) # 80000c98 <release>
            panic("wrong call in release_list3");
}
    80001c7a:	60a2                	ld	ra,8(sp)
    80001c7c:	6402                	ld	s0,0(sp)
    80001c7e:	0141                	addi	sp,sp,16
    80001c80:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001c82:	00159513          	slli	a0,a1,0x1
    80001c86:	95aa                	add	a1,a1,a0
    80001c88:	058e                	slli	a1,a1,0x3
    80001c8a:	0000f517          	auipc	a0,0xf
    80001c8e:	72e50513          	addi	a0,a0,1838 # 800113b8 <ready_lock>
    80001c92:	952e                	add	a0,a0,a1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	004080e7          	jalr	4(ra) # 80000c98 <release>
    80001c9c:	bff9                	j	80001c7a <release_list3+0x30>
      number == 2 ? release(&zombie_lock): 
    80001c9e:	0000f517          	auipc	a0,0xf
    80001ca2:	73250513          	addi	a0,a0,1842 # 800113d0 <zombie_lock>
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	ff2080e7          	jalr	-14(ra) # 80000c98 <release>
    80001cae:	b7f1                	j	80001c7a <release_list3+0x30>
        number == 3 ? release(&sleeping_lock): 
    80001cb0:	0000f517          	auipc	a0,0xf
    80001cb4:	73850513          	addi	a0,a0,1848 # 800113e8 <sleeping_lock>
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	fe0080e7          	jalr	-32(ra) # 80000c98 <release>
    80001cc0:	bf6d                	j	80001c7a <release_list3+0x30>
            panic("wrong call in release_list3");
    80001cc2:	00006517          	auipc	a0,0x6
    80001cc6:	5be50513          	addi	a0,a0,1470 # 80008280 <digits+0x240>
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080001cd2 <release_list>:

void
release_list(int type, int parent_cpu){
    80001cd2:	1141                	addi	sp,sp,-16
    80001cd4:	e406                	sd	ra,8(sp)
    80001cd6:	e022                	sd	s0,0(sp)
    80001cd8:	0800                	addi	s0,sp,16
  type==READYL ? release_list3(1,parent_cpu): 
    80001cda:	c515                	beqz	a0,80001d06 <release_list+0x34>
    type==ZOMBIEL ? release_list3(2,parent_cpu):
    80001cdc:	4785                	li	a5,1
    80001cde:	04f50263          	beq	a0,a5,80001d22 <release_list+0x50>
      type==SLEEPINGL ? release_list3(3,parent_cpu):
    80001ce2:	4789                	li	a5,2
    80001ce4:	04f50863          	beq	a0,a5,80001d34 <release_list+0x62>
        type==UNUSEDL ? release_list3(4,parent_cpu):
    80001ce8:	478d                	li	a5,3
    80001cea:	04f51e63          	bne	a0,a5,80001d46 <release_list+0x74>
          number == 4 ? release(&unused_lock):  
    80001cee:	0000f517          	auipc	a0,0xf
    80001cf2:	71250513          	addi	a0,a0,1810 # 80011400 <unused_lock>
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	fa2080e7          	jalr	-94(ra) # 80000c98 <release>
          panic("wrong type list");
}
    80001cfe:	60a2                	ld	ra,8(sp)
    80001d00:	6402                	ld	s0,0(sp)
    80001d02:	0141                	addi	sp,sp,16
    80001d04:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001d06:	00159513          	slli	a0,a1,0x1
    80001d0a:	95aa                	add	a1,a1,a0
    80001d0c:	058e                	slli	a1,a1,0x3
    80001d0e:	0000f517          	auipc	a0,0xf
    80001d12:	6aa50513          	addi	a0,a0,1706 # 800113b8 <ready_lock>
    80001d16:	952e                	add	a0,a0,a1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	f80080e7          	jalr	-128(ra) # 80000c98 <release>
}
    80001d20:	bff9                	j	80001cfe <release_list+0x2c>
      number == 2 ? release(&zombie_lock): 
    80001d22:	0000f517          	auipc	a0,0xf
    80001d26:	6ae50513          	addi	a0,a0,1710 # 800113d0 <zombie_lock>
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	f6e080e7          	jalr	-146(ra) # 80000c98 <release>
}
    80001d32:	b7f1                	j	80001cfe <release_list+0x2c>
        number == 3 ? release(&sleeping_lock): 
    80001d34:	0000f517          	auipc	a0,0xf
    80001d38:	6b450513          	addi	a0,a0,1716 # 800113e8 <sleeping_lock>
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	f5c080e7          	jalr	-164(ra) # 80000c98 <release>
}
    80001d44:	bf6d                	j	80001cfe <release_list+0x2c>
          panic("wrong type list");
    80001d46:	00006517          	auipc	a0,0x6
    80001d4a:	52a50513          	addi	a0,a0,1322 # 80008270 <digits+0x230>
    80001d4e:	ffffe097          	auipc	ra,0xffffe
    80001d52:	7f0080e7          	jalr	2032(ra) # 8000053e <panic>

0000000080001d56 <add_to_list>:



void
add_to_list(struct proc* p, struct proc* head, int type, int cpu_id)
{
    80001d56:	7139                	addi	sp,sp,-64
    80001d58:	fc06                	sd	ra,56(sp)
    80001d5a:	f822                	sd	s0,48(sp)
    80001d5c:	f426                	sd	s1,40(sp)
    80001d5e:	f04a                	sd	s2,32(sp)
    80001d60:	ec4e                	sd	s3,24(sp)
    80001d62:	e852                	sd	s4,16(sp)
    80001d64:	e456                	sd	s5,8(sp)
    80001d66:	e05a                	sd	s6,0(sp)
    80001d68:	0080                	addi	s0,sp,64
  if(!p){
    80001d6a:	c505                	beqz	a0,80001d92 <add_to_list+0x3c>
    80001d6c:	8b2a                	mv	s6,a0
    80001d6e:	84ae                	mv	s1,a1
    80001d70:	8a32                	mv	s4,a2
    80001d72:	8ab6                	mv	s5,a3
  if(!head){
      set_head(p, type, cpu_id);
      release_list(type, cpu_id);
  }
  else{
    struct proc* prev = 0;
    80001d74:	4901                	li	s2,0
  if(!head){
    80001d76:	e1a1                	bnez	a1,80001db6 <add_to_list+0x60>
      set_head(p, type, cpu_id);
    80001d78:	8636                	mv	a2,a3
    80001d7a:	85d2                	mv	a1,s4
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	e6a080e7          	jalr	-406(ra) # 80001be6 <set_head>
      release_list(type, cpu_id);
    80001d84:	85d6                	mv	a1,s5
    80001d86:	8552                	mv	a0,s4
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	f4a080e7          	jalr	-182(ra) # 80001cd2 <release_list>
    80001d90:	a891                	j	80001de4 <add_to_list+0x8e>
    panic("can't add null to list");
    80001d92:	00006517          	auipc	a0,0x6
    80001d96:	4c650513          	addi	a0,a0,1222 # 80008258 <digits+0x218>
    80001d9a:	ffffe097          	auipc	ra,0xffffe
    80001d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list(type, cpu_id);
    80001da2:	85d6                	mv	a1,s5
    80001da4:	8552                	mv	a0,s4
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	f2c080e7          	jalr	-212(ra) # 80001cd2 <release_list>
      }
      prev = head;
      head = head->next;
    80001dae:	68bc                	ld	a5,80(s1)
    while(head){
    80001db0:	8926                	mv	s2,s1
    80001db2:	c395                	beqz	a5,80001dd6 <add_to_list+0x80>
      head = head->next;
    80001db4:	84be                	mv	s1,a5
      acquire(&head->list_lock);
    80001db6:	01848993          	addi	s3,s1,24
    80001dba:	854e                	mv	a0,s3
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	e28080e7          	jalr	-472(ra) # 80000be4 <acquire>
      if(prev){
    80001dc4:	fc090fe3          	beqz	s2,80001da2 <add_to_list+0x4c>
        release(&prev->list_lock);
    80001dc8:	01890513          	addi	a0,s2,24
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
    80001dd4:	bfe9                	j	80001dae <add_to_list+0x58>
    }
    prev->next = p;
    80001dd6:	0564b823          	sd	s6,80(s1)
    release(&prev->list_lock);
    80001dda:	854e                	mv	a0,s3
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	ebc080e7          	jalr	-324(ra) # 80000c98 <release>
  }
}
    80001de4:	70e2                	ld	ra,56(sp)
    80001de6:	7442                	ld	s0,48(sp)
    80001de8:	74a2                	ld	s1,40(sp)
    80001dea:	7902                	ld	s2,32(sp)
    80001dec:	69e2                	ld	s3,24(sp)
    80001dee:	6a42                	ld	s4,16(sp)
    80001df0:	6aa2                	ld	s5,8(sp)
    80001df2:	6b02                	ld	s6,0(sp)
    80001df4:	6121                	addi	sp,sp,64
    80001df6:	8082                	ret

0000000080001df8 <add_proc_to_list>:


void 
add_proc_to_list(struct proc* p, int type, int cpu_id)
{
    80001df8:	7179                	addi	sp,sp,-48
    80001dfa:	f406                	sd	ra,40(sp)
    80001dfc:	f022                	sd	s0,32(sp)
    80001dfe:	ec26                	sd	s1,24(sp)
    80001e00:	e84a                	sd	s2,16(sp)
    80001e02:	e44e                	sd	s3,8(sp)
    80001e04:	1800                	addi	s0,sp,48
  // bad argument
  if(!p){
    80001e06:	cd1d                	beqz	a0,80001e44 <add_proc_to_list+0x4c>
    80001e08:	89aa                	mv	s3,a0
    80001e0a:	84ae                	mv	s1,a1
    80001e0c:	8932                	mv	s2,a2
    panic("Add proc to list");
  }
  struct proc* head;
  acquire_list(type, cpu_id);
    80001e0e:	85b2                	mv	a1,a2
    80001e10:	8526                	mv	a0,s1
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	ce8080e7          	jalr	-792(ra) # 80001afa <acquire_list>
  head = get_head(type, cpu_id);
    80001e1a:	85ca                	mv	a1,s2
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	d64080e7          	jalr	-668(ra) # 80001b82 <get_head>
    80001e26:	85aa                	mv	a1,a0
  add_to_list(p, head, type, cpu_id);
    80001e28:	86ca                	mv	a3,s2
    80001e2a:	8626                	mv	a2,s1
    80001e2c:	854e                	mv	a0,s3
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	f28080e7          	jalr	-216(ra) # 80001d56 <add_to_list>
}
    80001e36:	70a2                	ld	ra,40(sp)
    80001e38:	7402                	ld	s0,32(sp)
    80001e3a:	64e2                	ld	s1,24(sp)
    80001e3c:	6942                	ld	s2,16(sp)
    80001e3e:	69a2                	ld	s3,8(sp)
    80001e40:	6145                	addi	sp,sp,48
    80001e42:	8082                	ret
    panic("Add proc to list");
    80001e44:	00006517          	auipc	a0,0x6
    80001e48:	45c50513          	addi	a0,a0,1116 # 800082a0 <digits+0x260>
    80001e4c:	ffffe097          	auipc	ra,0xffffe
    80001e50:	6f2080e7          	jalr	1778(ra) # 8000053e <panic>

0000000080001e54 <remove_first>:



struct proc* 
remove_first(int type, int cpu_id)
{
    80001e54:	7179                	addi	sp,sp,-48
    80001e56:	f406                	sd	ra,40(sp)
    80001e58:	f022                	sd	s0,32(sp)
    80001e5a:	ec26                	sd	s1,24(sp)
    80001e5c:	e84a                	sd	s2,16(sp)
    80001e5e:	e44e                	sd	s3,8(sp)
    80001e60:	e052                	sd	s4,0(sp)
    80001e62:	1800                	addi	s0,sp,48
    80001e64:	892a                	mv	s2,a0
    80001e66:	89ae                	mv	s3,a1
  acquire_list(type, cpu_id);
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	c92080e7          	jalr	-878(ra) # 80001afa <acquire_list>
  struct proc* head = get_head(type, cpu_id);
    80001e70:	85ce                	mv	a1,s3
    80001e72:	854a                	mv	a0,s2
    80001e74:	00000097          	auipc	ra,0x0
    80001e78:	d0e080e7          	jalr	-754(ra) # 80001b82 <get_head>
    80001e7c:	84aa                	mv	s1,a0
  if(!head){
    80001e7e:	c529                	beqz	a0,80001ec8 <remove_first+0x74>
    release_list(type, cpu_id);
  }
  else{
    acquire(&head->list_lock);
    80001e80:	01850a13          	addi	s4,a0,24
    80001e84:	8552                	mv	a0,s4
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d5e080e7          	jalr	-674(ra) # 80000be4 <acquire>

    set_head(head->next, type, cpu_id);
    80001e8e:	864e                	mv	a2,s3
    80001e90:	85ca                	mv	a1,s2
    80001e92:	68a8                	ld	a0,80(s1)
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	d52080e7          	jalr	-686(ra) # 80001be6 <set_head>
    head->next = 0;
    80001e9c:	0404b823          	sd	zero,80(s1)
    release(&head->list_lock);
    80001ea0:	8552                	mv	a0,s4
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	df6080e7          	jalr	-522(ra) # 80000c98 <release>

    release_list(type, cpu_id);
    80001eaa:	85ce                	mv	a1,s3
    80001eac:	854a                	mv	a0,s2
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	e24080e7          	jalr	-476(ra) # 80001cd2 <release_list>

  }
  return head;
}
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	70a2                	ld	ra,40(sp)
    80001eba:	7402                	ld	s0,32(sp)
    80001ebc:	64e2                	ld	s1,24(sp)
    80001ebe:	6942                	ld	s2,16(sp)
    80001ec0:	69a2                	ld	s3,8(sp)
    80001ec2:	6a02                	ld	s4,0(sp)
    80001ec4:	6145                	addi	sp,sp,48
    80001ec6:	8082                	ret
    release_list(type, cpu_id);
    80001ec8:	85ce                	mv	a1,s3
    80001eca:	854a                	mv	a0,s2
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	e06080e7          	jalr	-506(ra) # 80001cd2 <release_list>
    80001ed4:	b7cd                	j	80001eb6 <remove_first+0x62>

0000000080001ed6 <remove_proc>:

int
remove_proc(struct proc* p, int type){
    80001ed6:	7179                	addi	sp,sp,-48
    80001ed8:	f406                	sd	ra,40(sp)
    80001eda:	f022                	sd	s0,32(sp)
    80001edc:	ec26                	sd	s1,24(sp)
    80001ede:	e84a                	sd	s2,16(sp)
    80001ee0:	e44e                	sd	s3,8(sp)
    80001ee2:	e052                	sd	s4,0(sp)
    80001ee4:	1800                	addi	s0,sp,48
    80001ee6:	8a2a                	mv	s4,a0
    80001ee8:	84ae                	mv	s1,a1
  acquire_list(type, p->parent_cpu);
    80001eea:	4d2c                	lw	a1,88(a0)
    80001eec:	8526                	mv	a0,s1
    80001eee:	00000097          	auipc	ra,0x0
    80001ef2:	c0c080e7          	jalr	-1012(ra) # 80001afa <acquire_list>
  struct proc* head = get_head(type, p->parent_cpu);
    80001ef6:	058a2983          	lw	s3,88(s4) # fffffffffffff058 <end+0xffffffff7ffd9058>
    80001efa:	85ce                	mv	a1,s3
    80001efc:	8526                	mv	a0,s1
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	c84080e7          	jalr	-892(ra) # 80001b82 <get_head>
  if(!head){
    80001f06:	c521                	beqz	a0,80001f4e <remove_proc+0x78>
    80001f08:	892a                	mv	s2,a0
    release_list(type, p->parent_cpu);
    return 0;
  }
  else{
    struct proc* prev = 0;
    if(p == head){
    80001f0a:	04aa0a63          	beq	s4,a0,80001f5e <remove_proc+0x88>
      release(&p->list_lock);
      release_list(type, p->parent_cpu);
    }
    else{
      while(head){
        acquire(&head->list_lock);
    80001f0e:	0561                	addi	a0,a0,24
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	cd4080e7          	jalr	-812(ra) # 80000be4 <acquire>
          release(&prev->list_lock);
          return 1;
        }

        if(!prev)
          release_list(type,p->parent_cpu);
    80001f18:	058a2583          	lw	a1,88(s4)
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	00000097          	auipc	ra,0x0
    80001f22:	db4080e7          	jalr	-588(ra) # 80001cd2 <release_list>
          release(&prev->list_lock);
        }
          
        
        prev = head;
        head = head->next;
    80001f26:	05093483          	ld	s1,80(s2)
      while(head){
    80001f2a:	c0dd                	beqz	s1,80001fd0 <remove_proc+0xfa>
        acquire(&head->list_lock);
    80001f2c:	01848993          	addi	s3,s1,24
    80001f30:	854e                	mv	a0,s3
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	cb2080e7          	jalr	-846(ra) # 80000be4 <acquire>
        if(p == head){
    80001f3a:	069a0263          	beq	s4,s1,80001f9e <remove_proc+0xc8>
          release(&prev->list_lock);
    80001f3e:	01890513          	addi	a0,s2,24
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d56080e7          	jalr	-682(ra) # 80000c98 <release>
        head = head->next;
    80001f4a:	8926                	mv	s2,s1
    80001f4c:	bfe9                	j	80001f26 <remove_proc+0x50>
    release_list(type, p->parent_cpu);
    80001f4e:	85ce                	mv	a1,s3
    80001f50:	8526                	mv	a0,s1
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	d80080e7          	jalr	-640(ra) # 80001cd2 <release_list>
    return 0;
    80001f5a:	4501                	li	a0,0
    80001f5c:	a095                	j	80001fc0 <remove_proc+0xea>
      acquire(&p->list_lock);
    80001f5e:	01850993          	addi	s3,a0,24
    80001f62:	854e                	mv	a0,s3
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	c80080e7          	jalr	-896(ra) # 80000be4 <acquire>
      set_head(p->next, type, p->parent_cpu);
    80001f6c:	05892603          	lw	a2,88(s2)
    80001f70:	85a6                	mv	a1,s1
    80001f72:	05093503          	ld	a0,80(s2)
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	c70080e7          	jalr	-912(ra) # 80001be6 <set_head>
      p->next = 0;
    80001f7e:	04093823          	sd	zero,80(s2)
      release(&p->list_lock);
    80001f82:	854e                	mv	a0,s3
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	d14080e7          	jalr	-748(ra) # 80000c98 <release>
      release_list(type, p->parent_cpu);
    80001f8c:	05892583          	lw	a1,88(s2)
    80001f90:	8526                	mv	a0,s1
    80001f92:	00000097          	auipc	ra,0x0
    80001f96:	d40080e7          	jalr	-704(ra) # 80001cd2 <release_list>
      }
    }
    return 0;
    80001f9a:	4501                	li	a0,0
    80001f9c:	a015                	j	80001fc0 <remove_proc+0xea>
          prev->next = head->next;
    80001f9e:	68bc                	ld	a5,80(s1)
    80001fa0:	04f93823          	sd	a5,80(s2)
          p->next = 0;
    80001fa4:	0404b823          	sd	zero,80(s1)
          release(&head->list_lock);
    80001fa8:	854e                	mv	a0,s3
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	cee080e7          	jalr	-786(ra) # 80000c98 <release>
          release(&prev->list_lock);
    80001fb2:	01890513          	addi	a0,s2,24
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	ce2080e7          	jalr	-798(ra) # 80000c98 <release>
          return 1;
    80001fbe:	4505                	li	a0,1
  }
}
    80001fc0:	70a2                	ld	ra,40(sp)
    80001fc2:	7402                	ld	s0,32(sp)
    80001fc4:	64e2                	ld	s1,24(sp)
    80001fc6:	6942                	ld	s2,16(sp)
    80001fc8:	69a2                	ld	s3,8(sp)
    80001fca:	6a02                	ld	s4,0(sp)
    80001fcc:	6145                	addi	sp,sp,48
    80001fce:	8082                	ret
    return 0;
    80001fd0:	4501                	li	a0,0
    80001fd2:	b7fd                	j	80001fc0 <remove_proc+0xea>

0000000080001fd4 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001fd4:	7139                	addi	sp,sp,-64
    80001fd6:	fc06                	sd	ra,56(sp)
    80001fd8:	f822                	sd	s0,48(sp)
    80001fda:	f426                	sd	s1,40(sp)
    80001fdc:	f04a                	sd	s2,32(sp)
    80001fde:	ec4e                	sd	s3,24(sp)
    80001fe0:	e852                	sd	s4,16(sp)
    80001fe2:	e456                	sd	s5,8(sp)
    80001fe4:	e05a                	sd	s6,0(sp)
    80001fe6:	0080                	addi	s0,sp,64
    80001fe8:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fea:	0000f497          	auipc	s1,0xf
    80001fee:	45e48493          	addi	s1,s1,1118 # 80011448 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001ff2:	8b26                	mv	s6,s1
    80001ff4:	00006a97          	auipc	s5,0x6
    80001ff8:	00ca8a93          	addi	s5,s5,12 # 80008000 <etext>
    80001ffc:	04000937          	lui	s2,0x4000
    80002000:	197d                	addi	s2,s2,-1
    80002002:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80002004:	00016a17          	auipc	s4,0x16
    80002008:	844a0a13          	addi	s4,s4,-1980 # 80017848 <tickslock>
    char *pa = kalloc();
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	ae8080e7          	jalr	-1304(ra) # 80000af4 <kalloc>
    80002014:	862a                	mv	a2,a0
    if(pa == 0)
    80002016:	c131                	beqz	a0,8000205a <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80002018:	416485b3          	sub	a1,s1,s6
    8000201c:	8591                	srai	a1,a1,0x4
    8000201e:	000ab783          	ld	a5,0(s5)
    80002022:	02f585b3          	mul	a1,a1,a5
    80002026:	2585                	addiw	a1,a1,1
    80002028:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000202c:	4719                	li	a4,6
    8000202e:	6685                	lui	a3,0x1
    80002030:	40b905b3          	sub	a1,s2,a1
    80002034:	854e                	mv	a0,s3
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	11a080e7          	jalr	282(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000203e:	19048493          	addi	s1,s1,400
    80002042:	fd4495e3          	bne	s1,s4,8000200c <proc_mapstacks+0x38>
  }
}
    80002046:	70e2                	ld	ra,56(sp)
    80002048:	7442                	ld	s0,48(sp)
    8000204a:	74a2                	ld	s1,40(sp)
    8000204c:	7902                	ld	s2,32(sp)
    8000204e:	69e2                	ld	s3,24(sp)
    80002050:	6a42                	ld	s4,16(sp)
    80002052:	6aa2                	ld	s5,8(sp)
    80002054:	6b02                	ld	s6,0(sp)
    80002056:	6121                	addi	sp,sp,64
    80002058:	8082                	ret
      panic("kalloc");
    8000205a:	00006517          	auipc	a0,0x6
    8000205e:	25e50513          	addi	a0,a0,606 # 800082b8 <digits+0x278>
    80002062:	ffffe097          	auipc	ra,0xffffe
    80002066:	4dc080e7          	jalr	1244(ra) # 8000053e <panic>

000000008000206a <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    8000206a:	715d                	addi	sp,sp,-80
    8000206c:	e486                	sd	ra,72(sp)
    8000206e:	e0a2                	sd	s0,64(sp)
    80002070:	fc26                	sd	s1,56(sp)
    80002072:	f84a                	sd	s2,48(sp)
    80002074:	f44e                	sd	s3,40(sp)
    80002076:	f052                	sd	s4,32(sp)
    80002078:	ec56                	sd	s5,24(sp)
    8000207a:	e85a                	sd	s6,16(sp)
    8000207c:	e45e                	sd	s7,8(sp)
    8000207e:	e062                	sd	s8,0(sp)
    80002080:	0880                	addi	s0,sp,80
  struct proc *p;
  //----------------------------------------------------------
  if(CPUS > NCPU){
    panic("recieved more CPUS than what is allowed");
  }
  initlock(&pid_lock, "nextpid");
    80002082:	00006597          	auipc	a1,0x6
    80002086:	23e58593          	addi	a1,a1,574 # 800082c0 <digits+0x280>
    8000208a:	0000f517          	auipc	a0,0xf
    8000208e:	38e50513          	addi	a0,a0,910 # 80011418 <pid_lock>
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	ac2080e7          	jalr	-1342(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000209a:	00006597          	auipc	a1,0x6
    8000209e:	22e58593          	addi	a1,a1,558 # 800082c8 <digits+0x288>
    800020a2:	0000f517          	auipc	a0,0xf
    800020a6:	38e50513          	addi	a0,a0,910 # 80011430 <wait_lock>
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	aaa080e7          	jalr	-1366(ra) # 80000b54 <initlock>
  initlock(&zombie_lock, "zombie lock");
    800020b2:	00006597          	auipc	a1,0x6
    800020b6:	22658593          	addi	a1,a1,550 # 800082d8 <digits+0x298>
    800020ba:	0000f517          	auipc	a0,0xf
    800020be:	31650513          	addi	a0,a0,790 # 800113d0 <zombie_lock>
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	a92080e7          	jalr	-1390(ra) # 80000b54 <initlock>
  initlock(&sleeping_lock, "sleeping lock");
    800020ca:	00006597          	auipc	a1,0x6
    800020ce:	21e58593          	addi	a1,a1,542 # 800082e8 <digits+0x2a8>
    800020d2:	0000f517          	auipc	a0,0xf
    800020d6:	31650513          	addi	a0,a0,790 # 800113e8 <sleeping_lock>
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	a7a080e7          	jalr	-1414(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused lock");
    800020e2:	00006597          	auipc	a1,0x6
    800020e6:	21658593          	addi	a1,a1,534 # 800082f8 <digits+0x2b8>
    800020ea:	0000f517          	auipc	a0,0xf
    800020ee:	31650513          	addi	a0,a0,790 # 80011400 <unused_lock>
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	a62080e7          	jalr	-1438(ra) # 80000b54 <initlock>

  struct spinlock* s;
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    initlock(s, "ready lock");
    800020fa:	00006597          	auipc	a1,0x6
    800020fe:	20e58593          	addi	a1,a1,526 # 80008308 <digits+0x2c8>
    80002102:	0000f517          	auipc	a0,0xf
    80002106:	2b650513          	addi	a0,a0,694 # 800113b8 <ready_lock>
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	a4a080e7          	jalr	-1462(ra) # 80000b54 <initlock>
  }
  //--------------------------------------------------
  for(p = proc; p < &proc[NPROC]; p++) {
    80002112:	0000f497          	auipc	s1,0xf
    80002116:	33648493          	addi	s1,s1,822 # 80011448 <proc>
      initlock(&p->lock, "proc");
    8000211a:	00006c17          	auipc	s8,0x6
    8000211e:	1fec0c13          	addi	s8,s8,510 # 80008318 <digits+0x2d8>
      //--------------------------------------------------
      initlock(&p->list_lock, "list lock");
    80002122:	00006b97          	auipc	s7,0x6
    80002126:	1feb8b93          	addi	s7,s7,510 # 80008320 <digits+0x2e0>
      //--------------------------------------------------
      p->kstack = KSTACK((int) (p - proc));
    8000212a:	8b26                	mv	s6,s1
    8000212c:	00006a97          	auipc	s5,0x6
    80002130:	ed4a8a93          	addi	s5,s5,-300 # 80008000 <etext>
    80002134:	04000937          	lui	s2,0x4000
    80002138:	197d                	addi	s2,s2,-1
    8000213a:	0932                	slli	s2,s2,0xc
      //--------------------------------------------------
       p->parent_cpu = -1;
    8000213c:	5a7d                	li	s4,-1
  for(p = proc; p < &proc[NPROC]; p++) {
    8000213e:	00015997          	auipc	s3,0x15
    80002142:	70a98993          	addi	s3,s3,1802 # 80017848 <tickslock>
      initlock(&p->lock, "proc");
    80002146:	85e2                	mv	a1,s8
    80002148:	8526                	mv	a0,s1
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	a0a080e7          	jalr	-1526(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list lock");
    80002152:	85de                	mv	a1,s7
    80002154:	01848513          	addi	a0,s1,24
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	9fc080e7          	jalr	-1540(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80002160:	416487b3          	sub	a5,s1,s6
    80002164:	8791                	srai	a5,a5,0x4
    80002166:	000ab703          	ld	a4,0(s5)
    8000216a:	02e787b3          	mul	a5,a5,a4
    8000216e:	2785                	addiw	a5,a5,1
    80002170:	00d7979b          	slliw	a5,a5,0xd
    80002174:	40f907b3          	sub	a5,s2,a5
    80002178:	f4bc                	sd	a5,104(s1)
       p->parent_cpu = -1;
    8000217a:	0544ac23          	sw	s4,88(s1)
       add_proc_to_list(p, UNUSEDL, -1);
    8000217e:	567d                	li	a2,-1
    80002180:	458d                	li	a1,3
    80002182:	8526                	mv	a0,s1
    80002184:	00000097          	auipc	ra,0x0
    80002188:	c74080e7          	jalr	-908(ra) # 80001df8 <add_proc_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218c:	19048493          	addi	s1,s1,400
    80002190:	fb349be3          	bne	s1,s3,80002146 <procinit+0xdc>
      
      //--------------------------------------------------
  }
}
    80002194:	60a6                	ld	ra,72(sp)
    80002196:	6406                	ld	s0,64(sp)
    80002198:	74e2                	ld	s1,56(sp)
    8000219a:	7942                	ld	s2,48(sp)
    8000219c:	79a2                	ld	s3,40(sp)
    8000219e:	7a02                	ld	s4,32(sp)
    800021a0:	6ae2                	ld	s5,24(sp)
    800021a2:	6b42                	ld	s6,16(sp)
    800021a4:	6ba2                	ld	s7,8(sp)
    800021a6:	6c02                	ld	s8,0(sp)
    800021a8:	6161                	addi	sp,sp,80
    800021aa:	8082                	ret

00000000800021ac <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800021ac:	1141                	addi	sp,sp,-16
    800021ae:	e422                	sd	s0,8(sp)
    800021b0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800021b2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800021b4:	2501                	sext.w	a0,a0
    800021b6:	6422                	ld	s0,8(sp)
    800021b8:	0141                	addi	sp,sp,16
    800021ba:	8082                	ret

00000000800021bc <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800021bc:	1141                	addi	sp,sp,-16
    800021be:	e422                	sd	s0,8(sp)
    800021c0:	0800                	addi	s0,sp,16
    800021c2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800021c4:	0007851b          	sext.w	a0,a5
    800021c8:	00451793          	slli	a5,a0,0x4
    800021cc:	97aa                	add	a5,a5,a0
    800021ce:	078e                	slli	a5,a5,0x3
  return c;
}
    800021d0:	0000f517          	auipc	a0,0xf
    800021d4:	16050513          	addi	a0,a0,352 # 80011330 <cpus>
    800021d8:	953e                	add	a0,a0,a5
    800021da:	6422                	ld	s0,8(sp)
    800021dc:	0141                	addi	sp,sp,16
    800021de:	8082                	ret

00000000800021e0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800021e0:	1101                	addi	sp,sp,-32
    800021e2:	ec06                	sd	ra,24(sp)
    800021e4:	e822                	sd	s0,16(sp)
    800021e6:	e426                	sd	s1,8(sp)
    800021e8:	1000                	addi	s0,sp,32
  push_off();
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	9ae080e7          	jalr	-1618(ra) # 80000b98 <push_off>
    800021f2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800021f4:	0007871b          	sext.w	a4,a5
    800021f8:	00471793          	slli	a5,a4,0x4
    800021fc:	97ba                	add	a5,a5,a4
    800021fe:	078e                	slli	a5,a5,0x3
    80002200:	0000f717          	auipc	a4,0xf
    80002204:	0d070713          	addi	a4,a4,208 # 800112d0 <readyLock>
    80002208:	97ba                	add	a5,a5,a4
    8000220a:	73a4                	ld	s1,96(a5)
  pop_off();
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a2c080e7          	jalr	-1492(ra) # 80000c38 <pop_off>
  return p;
}
    80002214:	8526                	mv	a0,s1
    80002216:	60e2                	ld	ra,24(sp)
    80002218:	6442                	ld	s0,16(sp)
    8000221a:	64a2                	ld	s1,8(sp)
    8000221c:	6105                	addi	sp,sp,32
    8000221e:	8082                	ret

0000000080002220 <get_cpu>:
{
    80002220:	1141                	addi	sp,sp,-16
    80002222:	e406                	sd	ra,8(sp)
    80002224:	e022                	sd	s0,0(sp)
    80002226:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	fb8080e7          	jalr	-72(ra) # 800021e0 <myproc>
}
    80002230:	4d28                	lw	a0,88(a0)
    80002232:	60a2                	ld	ra,8(sp)
    80002234:	6402                	ld	s0,0(sp)
    80002236:	0141                	addi	sp,sp,16
    80002238:	8082                	ret

000000008000223a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    8000223a:	1141                	addi	sp,sp,-16
    8000223c:	e406                	sd	ra,8(sp)
    8000223e:	e022                	sd	s0,0(sp)
    80002240:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80002242:	00000097          	auipc	ra,0x0
    80002246:	f9e080e7          	jalr	-98(ra) # 800021e0 <myproc>
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	a4e080e7          	jalr	-1458(ra) # 80000c98 <release>

  if (first) {
    80002252:	00006797          	auipc	a5,0x6
    80002256:	71e7a783          	lw	a5,1822(a5) # 80008970 <first.1827>
    8000225a:	eb89                	bnez	a5,8000226c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    8000225c:	00001097          	auipc	ra,0x1
    80002260:	dd4080e7          	jalr	-556(ra) # 80003030 <usertrapret>
}
    80002264:	60a2                	ld	ra,8(sp)
    80002266:	6402                	ld	s0,0(sp)
    80002268:	0141                	addi	sp,sp,16
    8000226a:	8082                	ret
    first = 0;
    8000226c:	00006797          	auipc	a5,0x6
    80002270:	7007a223          	sw	zero,1796(a5) # 80008970 <first.1827>
    fsinit(ROOTDEV);
    80002274:	4505                	li	a0,1
    80002276:	00002097          	auipc	ra,0x2
    8000227a:	b46080e7          	jalr	-1210(ra) # 80003dbc <fsinit>
    8000227e:	bff9                	j	8000225c <forkret+0x22>

0000000080002280 <allocpid>:
allocpid() {
    80002280:	1101                	addi	sp,sp,-32
    80002282:	ec06                	sd	ra,24(sp)
    80002284:	e822                	sd	s0,16(sp)
    80002286:	e426                	sd	s1,8(sp)
    80002288:	e04a                	sd	s2,0(sp)
    8000228a:	1000                	addi	s0,sp,32
    pid = nextpid;
    8000228c:	00006917          	auipc	s2,0x6
    80002290:	6e890913          	addi	s2,s2,1768 # 80008974 <nextpid>
    80002294:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid, pid, pid + 1));
    80002298:	0014861b          	addiw	a2,s1,1
    8000229c:	85a6                	mv	a1,s1
    8000229e:	854a                	mv	a0,s2
    800022a0:	00005097          	auipc	ra,0x5
    800022a4:	926080e7          	jalr	-1754(ra) # 80006bc6 <cas>
    800022a8:	f575                	bnez	a0,80002294 <allocpid+0x14>
}
    800022aa:	8526                	mv	a0,s1
    800022ac:	60e2                	ld	ra,24(sp)
    800022ae:	6442                	ld	s0,16(sp)
    800022b0:	64a2                	ld	s1,8(sp)
    800022b2:	6902                	ld	s2,0(sp)
    800022b4:	6105                	addi	sp,sp,32
    800022b6:	8082                	ret

00000000800022b8 <proc_pagetable>:
{
    800022b8:	1101                	addi	sp,sp,-32
    800022ba:	ec06                	sd	ra,24(sp)
    800022bc:	e822                	sd	s0,16(sp)
    800022be:	e426                	sd	s1,8(sp)
    800022c0:	e04a                	sd	s2,0(sp)
    800022c2:	1000                	addi	s0,sp,32
    800022c4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	074080e7          	jalr	116(ra) # 8000133a <uvmcreate>
    800022ce:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800022d0:	c121                	beqz	a0,80002310 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800022d2:	4729                	li	a4,10
    800022d4:	00005697          	auipc	a3,0x5
    800022d8:	d2c68693          	addi	a3,a3,-724 # 80007000 <_trampoline>
    800022dc:	6605                	lui	a2,0x1
    800022de:	040005b7          	lui	a1,0x4000
    800022e2:	15fd                	addi	a1,a1,-1
    800022e4:	05b2                	slli	a1,a1,0xc
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	dca080e7          	jalr	-566(ra) # 800010b0 <mappages>
    800022ee:	02054863          	bltz	a0,8000231e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800022f2:	4719                	li	a4,6
    800022f4:	08093683          	ld	a3,128(s2)
    800022f8:	6605                	lui	a2,0x1
    800022fa:	020005b7          	lui	a1,0x2000
    800022fe:	15fd                	addi	a1,a1,-1
    80002300:	05b6                	slli	a1,a1,0xd
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	dac080e7          	jalr	-596(ra) # 800010b0 <mappages>
    8000230c:	02054163          	bltz	a0,8000232e <proc_pagetable+0x76>
}
    80002310:	8526                	mv	a0,s1
    80002312:	60e2                	ld	ra,24(sp)
    80002314:	6442                	ld	s0,16(sp)
    80002316:	64a2                	ld	s1,8(sp)
    80002318:	6902                	ld	s2,0(sp)
    8000231a:	6105                	addi	sp,sp,32
    8000231c:	8082                	ret
    uvmfree(pagetable, 0);
    8000231e:	4581                	li	a1,0
    80002320:	8526                	mv	a0,s1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	214080e7          	jalr	532(ra) # 80001536 <uvmfree>
    return 0;
    8000232a:	4481                	li	s1,0
    8000232c:	b7d5                	j	80002310 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000232e:	4681                	li	a3,0
    80002330:	4605                	li	a2,1
    80002332:	040005b7          	lui	a1,0x4000
    80002336:	15fd                	addi	a1,a1,-1
    80002338:	05b2                	slli	a1,a1,0xc
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	f3a080e7          	jalr	-198(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80002344:	4581                	li	a1,0
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	1ee080e7          	jalr	494(ra) # 80001536 <uvmfree>
    return 0;
    80002350:	4481                	li	s1,0
    80002352:	bf7d                	j	80002310 <proc_pagetable+0x58>

0000000080002354 <proc_freepagetable>:
{
    80002354:	1101                	addi	sp,sp,-32
    80002356:	ec06                	sd	ra,24(sp)
    80002358:	e822                	sd	s0,16(sp)
    8000235a:	e426                	sd	s1,8(sp)
    8000235c:	e04a                	sd	s2,0(sp)
    8000235e:	1000                	addi	s0,sp,32
    80002360:	84aa                	mv	s1,a0
    80002362:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002364:	4681                	li	a3,0
    80002366:	4605                	li	a2,1
    80002368:	040005b7          	lui	a1,0x4000
    8000236c:	15fd                	addi	a1,a1,-1
    8000236e:	05b2                	slli	a1,a1,0xc
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	f06080e7          	jalr	-250(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002378:	4681                	li	a3,0
    8000237a:	4605                	li	a2,1
    8000237c:	020005b7          	lui	a1,0x2000
    80002380:	15fd                	addi	a1,a1,-1
    80002382:	05b6                	slli	a1,a1,0xd
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	ef0080e7          	jalr	-272(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    8000238e:	85ca                	mv	a1,s2
    80002390:	8526                	mv	a0,s1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	1a4080e7          	jalr	420(ra) # 80001536 <uvmfree>
}
    8000239a:	60e2                	ld	ra,24(sp)
    8000239c:	6442                	ld	s0,16(sp)
    8000239e:	64a2                	ld	s1,8(sp)
    800023a0:	6902                	ld	s2,0(sp)
    800023a2:	6105                	addi	sp,sp,32
    800023a4:	8082                	ret

00000000800023a6 <freeproc>:
{
    800023a6:	1101                	addi	sp,sp,-32
    800023a8:	ec06                	sd	ra,24(sp)
    800023aa:	e822                	sd	s0,16(sp)
    800023ac:	e426                	sd	s1,8(sp)
    800023ae:	1000                	addi	s0,sp,32
    800023b0:	84aa                	mv	s1,a0
  if(p->trapframe)
    800023b2:	6148                	ld	a0,128(a0)
    800023b4:	c509                	beqz	a0,800023be <freeproc+0x18>
    kfree((void*)p->trapframe);
    800023b6:	ffffe097          	auipc	ra,0xffffe
    800023ba:	642080e7          	jalr	1602(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    800023be:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    800023c2:	7ca8                	ld	a0,120(s1)
    800023c4:	c511                	beqz	a0,800023d0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800023c6:	78ac                	ld	a1,112(s1)
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	f8c080e7          	jalr	-116(ra) # 80002354 <proc_freepagetable>
  p->pagetable = 0;
    800023d0:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    800023d4:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    800023d8:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    800023dc:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    800023e0:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    800023e4:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    800023e8:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    800023ec:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    800023f0:	0204a823          	sw	zero,48(s1)
  remove_proc(p, ZOMBIEL);
    800023f4:	4585                	li	a1,1
    800023f6:	8526                	mv	a0,s1
    800023f8:	00000097          	auipc	ra,0x0
    800023fc:	ade080e7          	jalr	-1314(ra) # 80001ed6 <remove_proc>
  add_proc_to_list(p, UNUSEDL, -1);
    80002400:	567d                	li	a2,-1
    80002402:	458d                	li	a1,3
    80002404:	8526                	mv	a0,s1
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	9f2080e7          	jalr	-1550(ra) # 80001df8 <add_proc_to_list>
}
    8000240e:	60e2                	ld	ra,24(sp)
    80002410:	6442                	ld	s0,16(sp)
    80002412:	64a2                	ld	s1,8(sp)
    80002414:	6105                	addi	sp,sp,32
    80002416:	8082                	ret

0000000080002418 <allocproc>:
{
    80002418:	7179                	addi	sp,sp,-48
    8000241a:	f406                	sd	ra,40(sp)
    8000241c:	f022                	sd	s0,32(sp)
    8000241e:	ec26                	sd	s1,24(sp)
    80002420:	e84a                	sd	s2,16(sp)
    80002422:	e44e                	sd	s3,8(sp)
    80002424:	1800                	addi	s0,sp,48
  p = remove_first(UNUSEDL, -1);
    80002426:	55fd                	li	a1,-1
    80002428:	450d                	li	a0,3
    8000242a:	00000097          	auipc	ra,0x0
    8000242e:	a2a080e7          	jalr	-1494(ra) # 80001e54 <remove_first>
    80002432:	84aa                	mv	s1,a0
  if(!p){
    80002434:	cd39                	beqz	a0,80002492 <allocproc+0x7a>
  acquire(&p->lock);
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	7ae080e7          	jalr	1966(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    8000243e:	00000097          	auipc	ra,0x0
    80002442:	e42080e7          	jalr	-446(ra) # 80002280 <allocpid>
    80002446:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80002448:	4785                	li	a5,1
    8000244a:	d89c                	sw	a5,48(s1)
  p->next = 0;
    8000244c:	0404b823          	sd	zero,80(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	6a4080e7          	jalr	1700(ra) # 80000af4 <kalloc>
    80002458:	892a                	mv	s2,a0
    8000245a:	e0c8                	sd	a0,128(s1)
    8000245c:	c139                	beqz	a0,800024a2 <allocproc+0x8a>
  p->pagetable = proc_pagetable(p);
    8000245e:	8526                	mv	a0,s1
    80002460:	00000097          	auipc	ra,0x0
    80002464:	e58080e7          	jalr	-424(ra) # 800022b8 <proc_pagetable>
    80002468:	892a                	mv	s2,a0
    8000246a:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    8000246c:	c539                	beqz	a0,800024ba <allocproc+0xa2>
  memset(&p->context, 0, sizeof(p->context));
    8000246e:	07000613          	li	a2,112
    80002472:	4581                	li	a1,0
    80002474:	08848513          	addi	a0,s1,136
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	868080e7          	jalr	-1944(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002480:	00000797          	auipc	a5,0x0
    80002484:	dba78793          	addi	a5,a5,-582 # 8000223a <forkret>
    80002488:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    8000248a:	74bc                	ld	a5,104(s1)
    8000248c:	6705                	lui	a4,0x1
    8000248e:	97ba                	add	a5,a5,a4
    80002490:	e8dc                	sd	a5,144(s1)
}
    80002492:	8526                	mv	a0,s1
    80002494:	70a2                	ld	ra,40(sp)
    80002496:	7402                	ld	s0,32(sp)
    80002498:	64e2                	ld	s1,24(sp)
    8000249a:	6942                	ld	s2,16(sp)
    8000249c:	69a2                	ld	s3,8(sp)
    8000249e:	6145                	addi	sp,sp,48
    800024a0:	8082                	ret
    freeproc(p);
    800024a2:	8526                	mv	a0,s1
    800024a4:	00000097          	auipc	ra,0x0
    800024a8:	f02080e7          	jalr	-254(ra) # 800023a6 <freeproc>
    release(&p->lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	7ea080e7          	jalr	2026(ra) # 80000c98 <release>
    return 0;
    800024b6:	84ca                	mv	s1,s2
    800024b8:	bfe9                	j	80002492 <allocproc+0x7a>
    freeproc(p);
    800024ba:	8526                	mv	a0,s1
    800024bc:	00000097          	auipc	ra,0x0
    800024c0:	eea080e7          	jalr	-278(ra) # 800023a6 <freeproc>
    release(&p->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	7d2080e7          	jalr	2002(ra) # 80000c98 <release>
    return 0;
    800024ce:	84ca                	mv	s1,s2
    800024d0:	b7c9                	j	80002492 <allocproc+0x7a>

00000000800024d2 <userinit>:
{
    800024d2:	1101                	addi	sp,sp,-32
    800024d4:	ec06                	sd	ra,24(sp)
    800024d6:	e822                	sd	s0,16(sp)
    800024d8:	e426                	sd	s1,8(sp)
    800024da:	1000                	addi	s0,sp,32
  if(!init){
    800024dc:	00007797          	auipc	a5,0x7
    800024e0:	b647a783          	lw	a5,-1180(a5) # 80009040 <init>
    800024e4:	eb91                	bnez	a5,800024f8 <userinit+0x26>
      c->first = 0;
    800024e6:	0000f797          	auipc	a5,0xf
    800024ea:	ec07b523          	sd	zero,-310(a5) # 800113b0 <cpus+0x80>
    init = 1;
    800024ee:	4785                	li	a5,1
    800024f0:	00007717          	auipc	a4,0x7
    800024f4:	b4f72823          	sw	a5,-1200(a4) # 80009040 <init>
  p = allocproc();
    800024f8:	00000097          	auipc	ra,0x0
    800024fc:	f20080e7          	jalr	-224(ra) # 80002418 <allocproc>
    80002500:	84aa                	mv	s1,a0
  initproc = p;
    80002502:	00007797          	auipc	a5,0x7
    80002506:	b4a7bf23          	sd	a0,-1186(a5) # 80009060 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000250a:	03400613          	li	a2,52
    8000250e:	00006597          	auipc	a1,0x6
    80002512:	47258593          	addi	a1,a1,1138 # 80008980 <initcode>
    80002516:	7d28                	ld	a0,120(a0)
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	e50080e7          	jalr	-432(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002520:	6785                	lui	a5,0x1
    80002522:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    80002524:	60d8                	ld	a4,128(s1)
    80002526:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000252a:	60d8                	ld	a4,128(s1)
    8000252c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000252e:	4641                	li	a2,16
    80002530:	00006597          	auipc	a1,0x6
    80002534:	e0058593          	addi	a1,a1,-512 # 80008330 <digits+0x2f0>
    80002538:	18048513          	addi	a0,s1,384
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	8f6080e7          	jalr	-1802(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002544:	00006517          	auipc	a0,0x6
    80002548:	dfc50513          	addi	a0,a0,-516 # 80008340 <digits+0x300>
    8000254c:	00002097          	auipc	ra,0x2
    80002550:	29e080e7          	jalr	670(ra) # 800047ea <namei>
    80002554:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    80002558:	478d                	li	a5,3
    8000255a:	d89c                	sw	a5,48(s1)
  p->parent_cpu = 0;
    8000255c:	0404ac23          	sw	zero,88(s1)
  cpus[p->parent_cpu].first = p;
    80002560:	0000f797          	auipc	a5,0xf
    80002564:	e497b823          	sd	s1,-432(a5) # 800113b0 <cpus+0x80>
  release(&p->lock);
    80002568:	8526                	mv	a0,s1
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	72e080e7          	jalr	1838(ra) # 80000c98 <release>
}
    80002572:	60e2                	ld	ra,24(sp)
    80002574:	6442                	ld	s0,16(sp)
    80002576:	64a2                	ld	s1,8(sp)
    80002578:	6105                	addi	sp,sp,32
    8000257a:	8082                	ret

000000008000257c <growproc>:
{
    8000257c:	1101                	addi	sp,sp,-32
    8000257e:	ec06                	sd	ra,24(sp)
    80002580:	e822                	sd	s0,16(sp)
    80002582:	e426                	sd	s1,8(sp)
    80002584:	e04a                	sd	s2,0(sp)
    80002586:	1000                	addi	s0,sp,32
    80002588:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	c56080e7          	jalr	-938(ra) # 800021e0 <myproc>
    80002592:	892a                	mv	s2,a0
  sz = p->sz;
    80002594:	792c                	ld	a1,112(a0)
    80002596:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000259a:	00904f63          	bgtz	s1,800025b8 <growproc+0x3c>
  } else if(n < 0){
    8000259e:	0204cc63          	bltz	s1,800025d6 <growproc+0x5a>
  p->sz = sz;
    800025a2:	1602                	slli	a2,a2,0x20
    800025a4:	9201                	srli	a2,a2,0x20
    800025a6:	06c93823          	sd	a2,112(s2)
  return 0;
    800025aa:	4501                	li	a0,0
}
    800025ac:	60e2                	ld	ra,24(sp)
    800025ae:	6442                	ld	s0,16(sp)
    800025b0:	64a2                	ld	s1,8(sp)
    800025b2:	6902                	ld	s2,0(sp)
    800025b4:	6105                	addi	sp,sp,32
    800025b6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800025b8:	9e25                	addw	a2,a2,s1
    800025ba:	1602                	slli	a2,a2,0x20
    800025bc:	9201                	srli	a2,a2,0x20
    800025be:	1582                	slli	a1,a1,0x20
    800025c0:	9181                	srli	a1,a1,0x20
    800025c2:	7d28                	ld	a0,120(a0)
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	e5e080e7          	jalr	-418(ra) # 80001422 <uvmalloc>
    800025cc:	0005061b          	sext.w	a2,a0
    800025d0:	fa69                	bnez	a2,800025a2 <growproc+0x26>
      return -1;
    800025d2:	557d                	li	a0,-1
    800025d4:	bfe1                	j	800025ac <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800025d6:	9e25                	addw	a2,a2,s1
    800025d8:	1602                	slli	a2,a2,0x20
    800025da:	9201                	srli	a2,a2,0x20
    800025dc:	1582                	slli	a1,a1,0x20
    800025de:	9181                	srli	a1,a1,0x20
    800025e0:	7d28                	ld	a0,120(a0)
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	df8080e7          	jalr	-520(ra) # 800013da <uvmdealloc>
    800025ea:	0005061b          	sext.w	a2,a0
    800025ee:	bf55                	j	800025a2 <growproc+0x26>

00000000800025f0 <fork>:
{
    800025f0:	7179                	addi	sp,sp,-48
    800025f2:	f406                	sd	ra,40(sp)
    800025f4:	f022                	sd	s0,32(sp)
    800025f6:	ec26                	sd	s1,24(sp)
    800025f8:	e84a                	sd	s2,16(sp)
    800025fa:	e44e                	sd	s3,8(sp)
    800025fc:	e052                	sd	s4,0(sp)
    800025fe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002600:	00000097          	auipc	ra,0x0
    80002604:	be0080e7          	jalr	-1056(ra) # 800021e0 <myproc>
    80002608:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    8000260a:	00000097          	auipc	ra,0x0
    8000260e:	e0e080e7          	jalr	-498(ra) # 80002418 <allocproc>
    80002612:	12050563          	beqz	a0,8000273c <fork+0x14c>
    80002616:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002618:	07093603          	ld	a2,112(s2)
    8000261c:	7d2c                	ld	a1,120(a0)
    8000261e:	07893503          	ld	a0,120(s2)
    80002622:	fffff097          	auipc	ra,0xfffff
    80002626:	f4c080e7          	jalr	-180(ra) # 8000156e <uvmcopy>
    8000262a:	04054663          	bltz	a0,80002676 <fork+0x86>
  np->sz = p->sz;
    8000262e:	07093783          	ld	a5,112(s2)
    80002632:	06f9b823          	sd	a5,112(s3)
  *(np->trapframe) = *(p->trapframe);
    80002636:	08093683          	ld	a3,128(s2)
    8000263a:	87b6                	mv	a5,a3
    8000263c:	0809b703          	ld	a4,128(s3)
    80002640:	12068693          	addi	a3,a3,288
    80002644:	0007b803          	ld	a6,0(a5)
    80002648:	6788                	ld	a0,8(a5)
    8000264a:	6b8c                	ld	a1,16(a5)
    8000264c:	6f90                	ld	a2,24(a5)
    8000264e:	01073023          	sd	a6,0(a4)
    80002652:	e708                	sd	a0,8(a4)
    80002654:	eb0c                	sd	a1,16(a4)
    80002656:	ef10                	sd	a2,24(a4)
    80002658:	02078793          	addi	a5,a5,32
    8000265c:	02070713          	addi	a4,a4,32
    80002660:	fed792e3          	bne	a5,a3,80002644 <fork+0x54>
  np->trapframe->a0 = 0;
    80002664:	0809b783          	ld	a5,128(s3)
    80002668:	0607b823          	sd	zero,112(a5)
    8000266c:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80002670:	17800a13          	li	s4,376
    80002674:	a03d                	j	800026a2 <fork+0xb2>
    freeproc(np);
    80002676:	854e                	mv	a0,s3
    80002678:	00000097          	auipc	ra,0x0
    8000267c:	d2e080e7          	jalr	-722(ra) # 800023a6 <freeproc>
    release(&np->lock);
    80002680:	854e                	mv	a0,s3
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	616080e7          	jalr	1558(ra) # 80000c98 <release>
    return -1;
    8000268a:	5a7d                	li	s4,-1
    8000268c:	a879                	j	8000272a <fork+0x13a>
      np->ofile[i] = filedup(p->ofile[i]);
    8000268e:	00002097          	auipc	ra,0x2
    80002692:	7f2080e7          	jalr	2034(ra) # 80004e80 <filedup>
    80002696:	009987b3          	add	a5,s3,s1
    8000269a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000269c:	04a1                	addi	s1,s1,8
    8000269e:	01448763          	beq	s1,s4,800026ac <fork+0xbc>
    if(p->ofile[i])
    800026a2:	009907b3          	add	a5,s2,s1
    800026a6:	6388                	ld	a0,0(a5)
    800026a8:	f17d                	bnez	a0,8000268e <fork+0x9e>
    800026aa:	bfcd                	j	8000269c <fork+0xac>
  np->cwd = idup(p->cwd);
    800026ac:	17893503          	ld	a0,376(s2)
    800026b0:	00002097          	auipc	ra,0x2
    800026b4:	946080e7          	jalr	-1722(ra) # 80003ff6 <idup>
    800026b8:	16a9bc23          	sd	a0,376(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800026bc:	4641                	li	a2,16
    800026be:	18090593          	addi	a1,s2,384
    800026c2:	18098513          	addi	a0,s3,384
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	76c080e7          	jalr	1900(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800026ce:	0489aa03          	lw	s4,72(s3)
  release(&np->lock);
    800026d2:	854e                	mv	a0,s3
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	5c4080e7          	jalr	1476(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800026dc:	0000f497          	auipc	s1,0xf
    800026e0:	d5448493          	addi	s1,s1,-684 # 80011430 <wait_lock>
    800026e4:	8526                	mv	a0,s1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	4fe080e7          	jalr	1278(ra) # 80000be4 <acquire>
  np->parent = p;
    800026ee:	0729b023          	sd	s2,96(s3)
  release(&wait_lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	5a4080e7          	jalr	1444(ra) # 80000c98 <release>
  acquire(&np->lock);
    800026fc:	854e                	mv	a0,s3
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	4e6080e7          	jalr	1254(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002706:	478d                	li	a5,3
    80002708:	02f9a823          	sw	a5,48(s3)
  int parent_cpu =  p->parent_cpu;
    8000270c:	05892603          	lw	a2,88(s2)
  np->parent_cpu = parent_cpu;
    80002710:	04c9ac23          	sw	a2,88(s3)
  add_proc_to_list(np, READYL, parent_cpu);
    80002714:	4581                	li	a1,0
    80002716:	854e                	mv	a0,s3
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	6e0080e7          	jalr	1760(ra) # 80001df8 <add_proc_to_list>
  release(&np->lock);
    80002720:	854e                	mv	a0,s3
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	576080e7          	jalr	1398(ra) # 80000c98 <release>
}
    8000272a:	8552                	mv	a0,s4
    8000272c:	70a2                	ld	ra,40(sp)
    8000272e:	7402                	ld	s0,32(sp)
    80002730:	64e2                	ld	s1,24(sp)
    80002732:	6942                	ld	s2,16(sp)
    80002734:	69a2                	ld	s3,8(sp)
    80002736:	6a02                	ld	s4,0(sp)
    80002738:	6145                	addi	sp,sp,48
    8000273a:	8082                	ret
    return -1;
    8000273c:	5a7d                	li	s4,-1
    8000273e:	b7f5                	j	8000272a <fork+0x13a>

0000000080002740 <scheduler>:
{
    80002740:	7139                	addi	sp,sp,-64
    80002742:	fc06                	sd	ra,56(sp)
    80002744:	f822                	sd	s0,48(sp)
    80002746:	f426                	sd	s1,40(sp)
    80002748:	f04a                	sd	s2,32(sp)
    8000274a:	ec4e                	sd	s3,24(sp)
    8000274c:	e852                	sd	s4,16(sp)
    8000274e:	e456                	sd	s5,8(sp)
    80002750:	e05a                	sd	s6,0(sp)
    80002752:	0080                	addi	s0,sp,64
    80002754:	8792                	mv	a5,tp
  int id = r_tp();
    80002756:	2781                	sext.w	a5,a5
    80002758:	8a12                	mv	s4,tp
    8000275a:	2a01                	sext.w	s4,s4
  c->proc = 0;
    8000275c:	00479993          	slli	s3,a5,0x4
    80002760:	00f98733          	add	a4,s3,a5
    80002764:	00371693          	slli	a3,a4,0x3
    80002768:	0000f717          	auipc	a4,0xf
    8000276c:	b6870713          	addi	a4,a4,-1176 # 800112d0 <readyLock>
    80002770:	9736                	add	a4,a4,a3
    80002772:	06073023          	sd	zero,96(a4)
        swtch(&c->context, &p->context);
    80002776:	0000f717          	auipc	a4,0xf
    8000277a:	bc270713          	addi	a4,a4,-1086 # 80011338 <cpus+0x8>
    8000277e:	00e689b3          	add	s3,a3,a4
      if(p->state != RUNNABLE)
    80002782:	4a8d                	li	s5,3
        p->state = RUNNING;
    80002784:	4b11                	li	s6,4
        c->proc = p;
    80002786:	0000f917          	auipc	s2,0xf
    8000278a:	b4a90913          	addi	s2,s2,-1206 # 800112d0 <readyLock>
    8000278e:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002790:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002794:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002798:	10079073          	csrw	sstatus,a5
    p = remove_first(READYL, cpu_id);
    8000279c:	85d2                	mv	a1,s4
    8000279e:	4501                	li	a0,0
    800027a0:	fffff097          	auipc	ra,0xfffff
    800027a4:	6b4080e7          	jalr	1716(ra) # 80001e54 <remove_first>
    800027a8:	84aa                	mv	s1,a0
    if(!p){ // no proces ready 
    800027aa:	d17d                	beqz	a0,80002790 <scheduler+0x50>
      acquire(&p->lock);
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	438080e7          	jalr	1080(ra) # 80000be4 <acquire>
      if(p->state != RUNNABLE)
    800027b4:	589c                	lw	a5,48(s1)
    800027b6:	03579563          	bne	a5,s5,800027e0 <scheduler+0xa0>
        p->state = RUNNING;
    800027ba:	0364a823          	sw	s6,48(s1)
        c->proc = p;
    800027be:	06993023          	sd	s1,96(s2)
        swtch(&c->context, &p->context);
    800027c2:	08848593          	addi	a1,s1,136
    800027c6:	854e                	mv	a0,s3
    800027c8:	00000097          	auipc	ra,0x0
    800027cc:	7be080e7          	jalr	1982(ra) # 80002f86 <swtch>
        c->proc = 0;
    800027d0:	06093023          	sd	zero,96(s2)
      release(&p->lock);
    800027d4:	8526                	mv	a0,s1
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	4c2080e7          	jalr	1218(ra) # 80000c98 <release>
    800027de:	bf4d                	j	80002790 <scheduler+0x50>
        panic("bad proc was selected");
    800027e0:	00006517          	auipc	a0,0x6
    800027e4:	b6850513          	addi	a0,a0,-1176 # 80008348 <digits+0x308>
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	d56080e7          	jalr	-682(ra) # 8000053e <panic>

00000000800027f0 <sched>:
{
    800027f0:	7179                	addi	sp,sp,-48
    800027f2:	f406                	sd	ra,40(sp)
    800027f4:	f022                	sd	s0,32(sp)
    800027f6:	ec26                	sd	s1,24(sp)
    800027f8:	e84a                	sd	s2,16(sp)
    800027fa:	e44e                	sd	s3,8(sp)
    800027fc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	9e2080e7          	jalr	-1566(ra) # 800021e0 <myproc>
    80002806:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	362080e7          	jalr	866(ra) # 80000b6a <holding>
    80002810:	c959                	beqz	a0,800028a6 <sched+0xb6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002812:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002814:	0007871b          	sext.w	a4,a5
    80002818:	00471793          	slli	a5,a4,0x4
    8000281c:	97ba                	add	a5,a5,a4
    8000281e:	078e                	slli	a5,a5,0x3
    80002820:	0000f717          	auipc	a4,0xf
    80002824:	ab070713          	addi	a4,a4,-1360 # 800112d0 <readyLock>
    80002828:	97ba                	add	a5,a5,a4
    8000282a:	0d87a703          	lw	a4,216(a5)
    8000282e:	4785                	li	a5,1
    80002830:	08f71363          	bne	a4,a5,800028b6 <sched+0xc6>
  if(p->state == RUNNING)
    80002834:	5898                	lw	a4,48(s1)
    80002836:	4791                	li	a5,4
    80002838:	08f70763          	beq	a4,a5,800028c6 <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002840:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002842:	ebd1                	bnez	a5,800028d6 <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002844:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002846:	0000f917          	auipc	s2,0xf
    8000284a:	a8a90913          	addi	s2,s2,-1398 # 800112d0 <readyLock>
    8000284e:	0007871b          	sext.w	a4,a5
    80002852:	00471793          	slli	a5,a4,0x4
    80002856:	97ba                	add	a5,a5,a4
    80002858:	078e                	slli	a5,a5,0x3
    8000285a:	97ca                	add	a5,a5,s2
    8000285c:	0dc7a983          	lw	s3,220(a5)
    80002860:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002862:	0007859b          	sext.w	a1,a5
    80002866:	00459793          	slli	a5,a1,0x4
    8000286a:	97ae                	add	a5,a5,a1
    8000286c:	078e                	slli	a5,a5,0x3
    8000286e:	0000f597          	auipc	a1,0xf
    80002872:	aca58593          	addi	a1,a1,-1334 # 80011338 <cpus+0x8>
    80002876:	95be                	add	a1,a1,a5
    80002878:	08848513          	addi	a0,s1,136
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	70a080e7          	jalr	1802(ra) # 80002f86 <swtch>
    80002884:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002886:	0007871b          	sext.w	a4,a5
    8000288a:	00471793          	slli	a5,a4,0x4
    8000288e:	97ba                	add	a5,a5,a4
    80002890:	078e                	slli	a5,a5,0x3
    80002892:	97ca                	add	a5,a5,s2
    80002894:	0d37ae23          	sw	s3,220(a5)
}
    80002898:	70a2                	ld	ra,40(sp)
    8000289a:	7402                	ld	s0,32(sp)
    8000289c:	64e2                	ld	s1,24(sp)
    8000289e:	6942                	ld	s2,16(sp)
    800028a0:	69a2                	ld	s3,8(sp)
    800028a2:	6145                	addi	sp,sp,48
    800028a4:	8082                	ret
    panic("sched p->lock");
    800028a6:	00006517          	auipc	a0,0x6
    800028aa:	aba50513          	addi	a0,a0,-1350 # 80008360 <digits+0x320>
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	c90080e7          	jalr	-880(ra) # 8000053e <panic>
    panic("sched locks");
    800028b6:	00006517          	auipc	a0,0x6
    800028ba:	aba50513          	addi	a0,a0,-1350 # 80008370 <digits+0x330>
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	c80080e7          	jalr	-896(ra) # 8000053e <panic>
    panic("sched running");
    800028c6:	00006517          	auipc	a0,0x6
    800028ca:	aba50513          	addi	a0,a0,-1350 # 80008380 <digits+0x340>
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	c70080e7          	jalr	-912(ra) # 8000053e <panic>
    panic("sched interruptible");
    800028d6:	00006517          	auipc	a0,0x6
    800028da:	aba50513          	addi	a0,a0,-1350 # 80008390 <digits+0x350>
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	c60080e7          	jalr	-928(ra) # 8000053e <panic>

00000000800028e6 <yield>:
{
    800028e6:	1101                	addi	sp,sp,-32
    800028e8:	ec06                	sd	ra,24(sp)
    800028ea:	e822                	sd	s0,16(sp)
    800028ec:	e426                	sd	s1,8(sp)
    800028ee:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800028f0:	00000097          	auipc	ra,0x0
    800028f4:	8f0080e7          	jalr	-1808(ra) # 800021e0 <myproc>
    800028f8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	2ea080e7          	jalr	746(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002902:	478d                	li	a5,3
    80002904:	d89c                	sw	a5,48(s1)
  add_proc_to_list(p, READYL, p->parent_cpu);
    80002906:	4cb0                	lw	a2,88(s1)
    80002908:	4581                	li	a1,0
    8000290a:	8526                	mv	a0,s1
    8000290c:	fffff097          	auipc	ra,0xfffff
    80002910:	4ec080e7          	jalr	1260(ra) # 80001df8 <add_proc_to_list>
  sched();
    80002914:	00000097          	auipc	ra,0x0
    80002918:	edc080e7          	jalr	-292(ra) # 800027f0 <sched>
  release(&p->lock);
    8000291c:	8526                	mv	a0,s1
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	37a080e7          	jalr	890(ra) # 80000c98 <release>
}
    80002926:	60e2                	ld	ra,24(sp)
    80002928:	6442                	ld	s0,16(sp)
    8000292a:	64a2                	ld	s1,8(sp)
    8000292c:	6105                	addi	sp,sp,32
    8000292e:	8082                	ret

0000000080002930 <set_cpu>:
  if(cpu_num<0 || cpu_num>NCPU){
    80002930:	47a1                	li	a5,8
    80002932:	02a7e763          	bltu	a5,a0,80002960 <set_cpu+0x30>
{
    80002936:	1101                	addi	sp,sp,-32
    80002938:	ec06                	sd	ra,24(sp)
    8000293a:	e822                	sd	s0,16(sp)
    8000293c:	e426                	sd	s1,8(sp)
    8000293e:	1000                	addi	s0,sp,32
    80002940:	84aa                	mv	s1,a0
  struct proc* p = myproc();
    80002942:	00000097          	auipc	ra,0x0
    80002946:	89e080e7          	jalr	-1890(ra) # 800021e0 <myproc>
  p->parent_cpu=cpu_num;
    8000294a:	cd24                	sw	s1,88(a0)
  yield();
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	f9a080e7          	jalr	-102(ra) # 800028e6 <yield>
  return cpu_num;
    80002954:	8526                	mv	a0,s1
}
    80002956:	60e2                	ld	ra,24(sp)
    80002958:	6442                	ld	s0,16(sp)
    8000295a:	64a2                	ld	s1,8(sp)
    8000295c:	6105                	addi	sp,sp,32
    8000295e:	8082                	ret
    return -1;
    80002960:	557d                	li	a0,-1
}
    80002962:	8082                	ret

0000000080002964 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002964:	7179                	addi	sp,sp,-48
    80002966:	f406                	sd	ra,40(sp)
    80002968:	f022                	sd	s0,32(sp)
    8000296a:	ec26                	sd	s1,24(sp)
    8000296c:	e84a                	sd	s2,16(sp)
    8000296e:	e44e                	sd	s3,8(sp)
    80002970:	1800                	addi	s0,sp,48
    80002972:	89aa                	mv	s3,a0
    80002974:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	86a080e7          	jalr	-1942(ra) # 800021e0 <myproc>
    8000297e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	264080e7          	jalr	612(ra) # 80000be4 <acquire>
  release(lk);
    80002988:	854a                	mv	a0,s2
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	30e080e7          	jalr	782(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002992:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    80002996:	4789                	li	a5,2
    80002998:	d89c                	sw	a5,48(s1)
  //--------------------------------------------------------------------
    add_proc_to_list(p, SLEEPINGL,-1);
    8000299a:	567d                	li	a2,-1
    8000299c:	4589                	li	a1,2
    8000299e:	8526                	mv	a0,s1
    800029a0:	fffff097          	auipc	ra,0xfffff
    800029a4:	458080e7          	jalr	1112(ra) # 80001df8 <add_proc_to_list>
  //--------------------------------------------------------------------

  sched();
    800029a8:	00000097          	auipc	ra,0x0
    800029ac:	e48080e7          	jalr	-440(ra) # 800027f0 <sched>

  // Tidy up.
  p->chan = 0;
    800029b0:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    800029b4:	8526                	mv	a0,s1
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	2e2080e7          	jalr	738(ra) # 80000c98 <release>
  acquire(lk);
    800029be:	854a                	mv	a0,s2
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	224080e7          	jalr	548(ra) # 80000be4 <acquire>

}
    800029c8:	70a2                	ld	ra,40(sp)
    800029ca:	7402                	ld	s0,32(sp)
    800029cc:	64e2                	ld	s1,24(sp)
    800029ce:	6942                	ld	s2,16(sp)
    800029d0:	69a2                	ld	s3,8(sp)
    800029d2:	6145                	addi	sp,sp,48
    800029d4:	8082                	ret

00000000800029d6 <wait>:
{
    800029d6:	715d                	addi	sp,sp,-80
    800029d8:	e486                	sd	ra,72(sp)
    800029da:	e0a2                	sd	s0,64(sp)
    800029dc:	fc26                	sd	s1,56(sp)
    800029de:	f84a                	sd	s2,48(sp)
    800029e0:	f44e                	sd	s3,40(sp)
    800029e2:	f052                	sd	s4,32(sp)
    800029e4:	ec56                	sd	s5,24(sp)
    800029e6:	e85a                	sd	s6,16(sp)
    800029e8:	e45e                	sd	s7,8(sp)
    800029ea:	e062                	sd	s8,0(sp)
    800029ec:	0880                	addi	s0,sp,80
    800029ee:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	7f0080e7          	jalr	2032(ra) # 800021e0 <myproc>
    800029f8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800029fa:	0000f517          	auipc	a0,0xf
    800029fe:	a3650513          	addi	a0,a0,-1482 # 80011430 <wait_lock>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	1e2080e7          	jalr	482(ra) # 80000be4 <acquire>
    havekids = 0;
    80002a0a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002a0c:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002a0e:	00015997          	auipc	s3,0x15
    80002a12:	e3a98993          	addi	s3,s3,-454 # 80017848 <tickslock>
        havekids = 1;
    80002a16:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002a18:	0000fc17          	auipc	s8,0xf
    80002a1c:	a18c0c13          	addi	s8,s8,-1512 # 80011430 <wait_lock>
    havekids = 0;
    80002a20:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002a22:	0000f497          	auipc	s1,0xf
    80002a26:	a2648493          	addi	s1,s1,-1498 # 80011448 <proc>
    80002a2a:	a0bd                	j	80002a98 <wait+0xc2>
          pid = np->pid;
    80002a2c:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002a30:	000b0e63          	beqz	s6,80002a4c <wait+0x76>
    80002a34:	4691                	li	a3,4
    80002a36:	04448613          	addi	a2,s1,68
    80002a3a:	85da                	mv	a1,s6
    80002a3c:	07893503          	ld	a0,120(s2)
    80002a40:	fffff097          	auipc	ra,0xfffff
    80002a44:	c32080e7          	jalr	-974(ra) # 80001672 <copyout>
    80002a48:	02054563          	bltz	a0,80002a72 <wait+0x9c>
          freeproc(np);
    80002a4c:	8526                	mv	a0,s1
    80002a4e:	00000097          	auipc	ra,0x0
    80002a52:	958080e7          	jalr	-1704(ra) # 800023a6 <freeproc>
          release(&np->lock);
    80002a56:	8526                	mv	a0,s1
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	240080e7          	jalr	576(ra) # 80000c98 <release>
          release(&wait_lock);
    80002a60:	0000f517          	auipc	a0,0xf
    80002a64:	9d050513          	addi	a0,a0,-1584 # 80011430 <wait_lock>
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	230080e7          	jalr	560(ra) # 80000c98 <release>
          return pid;
    80002a70:	a09d                	j	80002ad6 <wait+0x100>
            release(&np->lock);
    80002a72:	8526                	mv	a0,s1
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	224080e7          	jalr	548(ra) # 80000c98 <release>
            release(&wait_lock);
    80002a7c:	0000f517          	auipc	a0,0xf
    80002a80:	9b450513          	addi	a0,a0,-1612 # 80011430 <wait_lock>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	214080e7          	jalr	532(ra) # 80000c98 <release>
            return -1;
    80002a8c:	59fd                	li	s3,-1
    80002a8e:	a0a1                	j	80002ad6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002a90:	19048493          	addi	s1,s1,400
    80002a94:	03348463          	beq	s1,s3,80002abc <wait+0xe6>
      if(np->parent == p){
    80002a98:	70bc                	ld	a5,96(s1)
    80002a9a:	ff279be3          	bne	a5,s2,80002a90 <wait+0xba>
        acquire(&np->lock);
    80002a9e:	8526                	mv	a0,s1
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	144080e7          	jalr	324(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002aa8:	589c                	lw	a5,48(s1)
    80002aaa:	f94781e3          	beq	a5,s4,80002a2c <wait+0x56>
        release(&np->lock);
    80002aae:	8526                	mv	a0,s1
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	1e8080e7          	jalr	488(ra) # 80000c98 <release>
        havekids = 1;
    80002ab8:	8756                	mv	a4,s5
    80002aba:	bfd9                	j	80002a90 <wait+0xba>
    if(!havekids || p->killed){
    80002abc:	c701                	beqz	a4,80002ac4 <wait+0xee>
    80002abe:	04092783          	lw	a5,64(s2)
    80002ac2:	c79d                	beqz	a5,80002af0 <wait+0x11a>
      release(&wait_lock);
    80002ac4:	0000f517          	auipc	a0,0xf
    80002ac8:	96c50513          	addi	a0,a0,-1684 # 80011430 <wait_lock>
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	1cc080e7          	jalr	460(ra) # 80000c98 <release>
      return -1;
    80002ad4:	59fd                	li	s3,-1
}
    80002ad6:	854e                	mv	a0,s3
    80002ad8:	60a6                	ld	ra,72(sp)
    80002ada:	6406                	ld	s0,64(sp)
    80002adc:	74e2                	ld	s1,56(sp)
    80002ade:	7942                	ld	s2,48(sp)
    80002ae0:	79a2                	ld	s3,40(sp)
    80002ae2:	7a02                	ld	s4,32(sp)
    80002ae4:	6ae2                	ld	s5,24(sp)
    80002ae6:	6b42                	ld	s6,16(sp)
    80002ae8:	6ba2                	ld	s7,8(sp)
    80002aea:	6c02                	ld	s8,0(sp)
    80002aec:	6161                	addi	sp,sp,80
    80002aee:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002af0:	85e2                	mv	a1,s8
    80002af2:	854a                	mv	a0,s2
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	e70080e7          	jalr	-400(ra) # 80002964 <sleep>
    havekids = 0;
    80002afc:	b715                	j	80002a20 <wait+0x4a>

0000000080002afe <wakeup>:
// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
//--------------------------------------------------------------------
void
wakeup(void *chan)
{
    80002afe:	711d                	addi	sp,sp,-96
    80002b00:	ec86                	sd	ra,88(sp)
    80002b02:	e8a2                	sd	s0,80(sp)
    80002b04:	e4a6                	sd	s1,72(sp)
    80002b06:	e0ca                	sd	s2,64(sp)
    80002b08:	fc4e                	sd	s3,56(sp)
    80002b0a:	f852                	sd	s4,48(sp)
    80002b0c:	f456                	sd	s5,40(sp)
    80002b0e:	f05a                	sd	s6,32(sp)
    80002b10:	ec5e                	sd	s7,24(sp)
    80002b12:	e862                	sd	s8,16(sp)
    80002b14:	e466                	sd	s9,8(sp)
    80002b16:	1080                	addi	s0,sp,96
    80002b18:	8aaa                	mv	s5,a0
  int released_list = 0;
  struct proc *p;
  struct proc* prev = 0;
  struct proc* tmp;
  acquire_list(SLEEPINGL, -1);
    80002b1a:	55fd                	li	a1,-1
    80002b1c:	4509                	li	a0,2
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	fdc080e7          	jalr	-36(ra) # 80001afa <acquire_list>
  p = get_head(SLEEPINGL, -1);
    80002b26:	55fd                	li	a1,-1
    80002b28:	4509                	li	a0,2
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	058080e7          	jalr	88(ra) # 80001b82 <get_head>
    80002b32:	84aa                	mv	s1,a0
  while(p){
    80002b34:	10050f63          	beqz	a0,80002c52 <wakeup+0x154>
  struct proc* prev = 0;
    80002b38:	4a01                	li	s4,0
  int released_list = 0;
    80002b3a:	4b01                	li	s6,0
    } 
    else{
      //we are not on the chan
      if(p == get_head(SLEEPINGL, -1)){
        release_list(SLEEPINGL,-1);
        released_list = 1;
    80002b3c:	4c05                	li	s8,1
        p->state = RUNNABLE;
    80002b3e:	4b8d                	li	s7,3
    80002b40:	a05d                	j	80002be6 <wakeup+0xe8>
      if(p == get_head(SLEEPINGL, -1)){
    80002b42:	55fd                	li	a1,-1
    80002b44:	4509                	li	a0,2
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	03c080e7          	jalr	60(ra) # 80001b82 <get_head>
    80002b4e:	02a48d63          	beq	s1,a0,80002b88 <wakeup+0x8a>
        prev->next = p->next;
    80002b52:	68bc                	ld	a5,80(s1)
    80002b54:	04fa3823          	sd	a5,80(s4)
        p->next = 0;
    80002b58:	0404b823          	sd	zero,80(s1)
        p->state = RUNNABLE;
    80002b5c:	0374a823          	sw	s7,48(s1)
        add_proc_to_list(p, READYL, cpu_id);
    80002b60:	4cb0                	lw	a2,88(s1)
    80002b62:	4581                	li	a1,0
    80002b64:	8526                	mv	a0,s1
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	292080e7          	jalr	658(ra) # 80001df8 <add_proc_to_list>
        release(&p->list_lock);
    80002b6e:	854a                	mv	a0,s2
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	128080e7          	jalr	296(ra) # 80000c98 <release>
        release(&p->lock);
    80002b78:	8526                	mv	a0,s1
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	11e080e7          	jalr	286(ra) # 80000c98 <release>
        p = prev->next;
    80002b82:	050a3483          	ld	s1,80(s4)
    80002b86:	a8b9                	j	80002be4 <wakeup+0xe6>
        set_head(p->next, SLEEPINGL, -1);
    80002b88:	567d                	li	a2,-1
    80002b8a:	4589                	li	a1,2
    80002b8c:	68a8                	ld	a0,80(s1)
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	058080e7          	jalr	88(ra) # 80001be6 <set_head>
        p = p->next;
    80002b96:	0504bc83          	ld	s9,80(s1)
        tmp->next = 0;
    80002b9a:	0404b823          	sd	zero,80(s1)
        tmp->state = RUNNABLE;
    80002b9e:	0374a823          	sw	s7,48(s1)
        add_proc_to_list(tmp, READYL, cpu_id);
    80002ba2:	4cb0                	lw	a2,88(s1)
    80002ba4:	4581                	li	a1,0
    80002ba6:	8526                	mv	a0,s1
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	250080e7          	jalr	592(ra) # 80001df8 <add_proc_to_list>
        release(&tmp->list_lock);
    80002bb0:	854a                	mv	a0,s2
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	0e6080e7          	jalr	230(ra) # 80000c98 <release>
        release(&tmp->lock);
    80002bba:	8526                	mv	a0,s1
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	0dc080e7          	jalr	220(ra) # 80000c98 <release>
        p = p->next;
    80002bc4:	84e6                	mv	s1,s9
    80002bc6:	a839                	j	80002be4 <wakeup+0xe6>
        release_list(SLEEPINGL,-1);
    80002bc8:	55fd                	li	a1,-1
    80002bca:	4509                	li	a0,2
    80002bcc:	fffff097          	auipc	ra,0xfffff
    80002bd0:	106080e7          	jalr	262(ra) # 80001cd2 <release_list>
        released_list = 1;
    80002bd4:	8b62                	mv	s6,s8
      }
      else{
        release(&prev->list_lock);
      }
      release(&p->lock);  //because we dont need to change his fields
    80002bd6:	854e                	mv	a0,s3
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	0c0080e7          	jalr	192(ra) # 80000c98 <release>
      prev = p;
      p = p->next;
    80002be0:	8a26                	mv	s4,s1
    80002be2:	68a4                	ld	s1,80(s1)
  while(p){
    80002be4:	c0a1                	beqz	s1,80002c24 <wakeup+0x126>
    acquire(&p->lock);
    80002be6:	89a6                	mv	s3,s1
    80002be8:	8526                	mv	a0,s1
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	ffa080e7          	jalr	-6(ra) # 80000be4 <acquire>
    acquire(&p->list_lock);
    80002bf2:	01848913          	addi	s2,s1,24
    80002bf6:	854a                	mv	a0,s2
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	fec080e7          	jalr	-20(ra) # 80000be4 <acquire>
    if(p->chan == chan){
    80002c00:	7c9c                	ld	a5,56(s1)
    80002c02:	f55780e3          	beq	a5,s5,80002b42 <wakeup+0x44>
      if(p == get_head(SLEEPINGL, -1)){
    80002c06:	55fd                	li	a1,-1
    80002c08:	4509                	li	a0,2
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	f78080e7          	jalr	-136(ra) # 80001b82 <get_head>
    80002c12:	faa48be3          	beq	s1,a0,80002bc8 <wakeup+0xca>
        release(&prev->list_lock);
    80002c16:	018a0513          	addi	a0,s4,24
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	07e080e7          	jalr	126(ra) # 80000c98 <release>
    80002c22:	bf55                	j	80002bd6 <wakeup+0xd8>
    }
  }
  if(!released_list){
    80002c24:	020b0863          	beqz	s6,80002c54 <wakeup+0x156>
    release_list(SLEEPINGL, -1);
  }
  if(prev){
    80002c28:	000a0863          	beqz	s4,80002c38 <wakeup+0x13a>
    release(&prev->list_lock);
    80002c2c:	018a0513          	addi	a0,s4,24
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	068080e7          	jalr	104(ra) # 80000c98 <release>
  }
}
    80002c38:	60e6                	ld	ra,88(sp)
    80002c3a:	6446                	ld	s0,80(sp)
    80002c3c:	64a6                	ld	s1,72(sp)
    80002c3e:	6906                	ld	s2,64(sp)
    80002c40:	79e2                	ld	s3,56(sp)
    80002c42:	7a42                	ld	s4,48(sp)
    80002c44:	7aa2                	ld	s5,40(sp)
    80002c46:	7b02                	ld	s6,32(sp)
    80002c48:	6be2                	ld	s7,24(sp)
    80002c4a:	6c42                	ld	s8,16(sp)
    80002c4c:	6ca2                	ld	s9,8(sp)
    80002c4e:	6125                	addi	sp,sp,96
    80002c50:	8082                	ret
  struct proc* prev = 0;
    80002c52:	8a2a                	mv	s4,a0
    release_list(SLEEPINGL, -1);
    80002c54:	55fd                	li	a1,-1
    80002c56:	4509                	li	a0,2
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	07a080e7          	jalr	122(ra) # 80001cd2 <release_list>
    80002c60:	b7e1                	j	80002c28 <wakeup+0x12a>

0000000080002c62 <reparent>:
{
    80002c62:	7179                	addi	sp,sp,-48
    80002c64:	f406                	sd	ra,40(sp)
    80002c66:	f022                	sd	s0,32(sp)
    80002c68:	ec26                	sd	s1,24(sp)
    80002c6a:	e84a                	sd	s2,16(sp)
    80002c6c:	e44e                	sd	s3,8(sp)
    80002c6e:	e052                	sd	s4,0(sp)
    80002c70:	1800                	addi	s0,sp,48
    80002c72:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002c74:	0000e497          	auipc	s1,0xe
    80002c78:	7d448493          	addi	s1,s1,2004 # 80011448 <proc>
      pp->parent = initproc;
    80002c7c:	00006a17          	auipc	s4,0x6
    80002c80:	3e4a0a13          	addi	s4,s4,996 # 80009060 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002c84:	00015997          	auipc	s3,0x15
    80002c88:	bc498993          	addi	s3,s3,-1084 # 80017848 <tickslock>
    80002c8c:	a029                	j	80002c96 <reparent+0x34>
    80002c8e:	19048493          	addi	s1,s1,400
    80002c92:	01348d63          	beq	s1,s3,80002cac <reparent+0x4a>
    if(pp->parent == p){
    80002c96:	70bc                	ld	a5,96(s1)
    80002c98:	ff279be3          	bne	a5,s2,80002c8e <reparent+0x2c>
      pp->parent = initproc;
    80002c9c:	000a3503          	ld	a0,0(s4)
    80002ca0:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	e5c080e7          	jalr	-420(ra) # 80002afe <wakeup>
    80002caa:	b7d5                	j	80002c8e <reparent+0x2c>
}
    80002cac:	70a2                	ld	ra,40(sp)
    80002cae:	7402                	ld	s0,32(sp)
    80002cb0:	64e2                	ld	s1,24(sp)
    80002cb2:	6942                	ld	s2,16(sp)
    80002cb4:	69a2                	ld	s3,8(sp)
    80002cb6:	6a02                	ld	s4,0(sp)
    80002cb8:	6145                	addi	sp,sp,48
    80002cba:	8082                	ret

0000000080002cbc <exit>:
{
    80002cbc:	7179                	addi	sp,sp,-48
    80002cbe:	f406                	sd	ra,40(sp)
    80002cc0:	f022                	sd	s0,32(sp)
    80002cc2:	ec26                	sd	s1,24(sp)
    80002cc4:	e84a                	sd	s2,16(sp)
    80002cc6:	e44e                	sd	s3,8(sp)
    80002cc8:	e052                	sd	s4,0(sp)
    80002cca:	1800                	addi	s0,sp,48
    80002ccc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	512080e7          	jalr	1298(ra) # 800021e0 <myproc>
    80002cd6:	89aa                	mv	s3,a0
  if(p == initproc)
    80002cd8:	00006797          	auipc	a5,0x6
    80002cdc:	3887b783          	ld	a5,904(a5) # 80009060 <initproc>
    80002ce0:	0f850493          	addi	s1,a0,248
    80002ce4:	17850913          	addi	s2,a0,376
    80002ce8:	02a79363          	bne	a5,a0,80002d0e <exit+0x52>
    panic("init exiting");
    80002cec:	00005517          	auipc	a0,0x5
    80002cf0:	6bc50513          	addi	a0,a0,1724 # 800083a8 <digits+0x368>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	84a080e7          	jalr	-1974(ra) # 8000053e <panic>
      fileclose(f);
    80002cfc:	00002097          	auipc	ra,0x2
    80002d00:	1d6080e7          	jalr	470(ra) # 80004ed2 <fileclose>
      p->ofile[fd] = 0;
    80002d04:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002d08:	04a1                	addi	s1,s1,8
    80002d0a:	01248563          	beq	s1,s2,80002d14 <exit+0x58>
    if(p->ofile[fd]){
    80002d0e:	6088                	ld	a0,0(s1)
    80002d10:	f575                	bnez	a0,80002cfc <exit+0x40>
    80002d12:	bfdd                	j	80002d08 <exit+0x4c>
  begin_op();
    80002d14:	00002097          	auipc	ra,0x2
    80002d18:	cf2080e7          	jalr	-782(ra) # 80004a06 <begin_op>
  iput(p->cwd);
    80002d1c:	1789b503          	ld	a0,376(s3)
    80002d20:	00001097          	auipc	ra,0x1
    80002d24:	4ce080e7          	jalr	1230(ra) # 800041ee <iput>
  end_op();
    80002d28:	00002097          	auipc	ra,0x2
    80002d2c:	d5e080e7          	jalr	-674(ra) # 80004a86 <end_op>
  p->cwd = 0;
    80002d30:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    80002d34:	0000e497          	auipc	s1,0xe
    80002d38:	6fc48493          	addi	s1,s1,1788 # 80011430 <wait_lock>
    80002d3c:	8526                	mv	a0,s1
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	ea6080e7          	jalr	-346(ra) # 80000be4 <acquire>
  reparent(p);
    80002d46:	854e                	mv	a0,s3
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	f1a080e7          	jalr	-230(ra) # 80002c62 <reparent>
  wakeup(p->parent);
    80002d50:	0609b503          	ld	a0,96(s3)
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	daa080e7          	jalr	-598(ra) # 80002afe <wakeup>
  acquire(&p->lock);
    80002d5c:	854e                	mv	a0,s3
    80002d5e:	ffffe097          	auipc	ra,0xffffe
    80002d62:	e86080e7          	jalr	-378(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002d66:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    80002d6a:	4795                	li	a5,5
    80002d6c:	02f9a823          	sw	a5,48(s3)
  add_proc_to_list(p, ZOMBIEL, -1);
    80002d70:	567d                	li	a2,-1
    80002d72:	4585                	li	a1,1
    80002d74:	854e                	mv	a0,s3
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	082080e7          	jalr	130(ra) # 80001df8 <add_proc_to_list>
  release(&wait_lock);
    80002d7e:	8526                	mv	a0,s1
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	f18080e7          	jalr	-232(ra) # 80000c98 <release>
  sched();
    80002d88:	00000097          	auipc	ra,0x0
    80002d8c:	a68080e7          	jalr	-1432(ra) # 800027f0 <sched>
  panic("zombie exit");
    80002d90:	00005517          	auipc	a0,0x5
    80002d94:	62850513          	addi	a0,a0,1576 # 800083b8 <digits+0x378>
    80002d98:	ffffd097          	auipc	ra,0xffffd
    80002d9c:	7a6080e7          	jalr	1958(ra) # 8000053e <panic>

0000000080002da0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002da0:	7179                	addi	sp,sp,-48
    80002da2:	f406                	sd	ra,40(sp)
    80002da4:	f022                	sd	s0,32(sp)
    80002da6:	ec26                	sd	s1,24(sp)
    80002da8:	e84a                	sd	s2,16(sp)
    80002daa:	e44e                	sd	s3,8(sp)
    80002dac:	1800                	addi	s0,sp,48
    80002dae:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002db0:	0000e497          	auipc	s1,0xe
    80002db4:	69848493          	addi	s1,s1,1688 # 80011448 <proc>
    80002db8:	00015997          	auipc	s3,0x15
    80002dbc:	a9098993          	addi	s3,s3,-1392 # 80017848 <tickslock>
    acquire(&p->lock);
    80002dc0:	8526                	mv	a0,s1
    80002dc2:	ffffe097          	auipc	ra,0xffffe
    80002dc6:	e22080e7          	jalr	-478(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002dca:	44bc                	lw	a5,72(s1)
    80002dcc:	01278d63          	beq	a5,s2,80002de6 <kill+0x46>
        add_proc_to_list(p, READYL, p->parent_cpu);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	ec6080e7          	jalr	-314(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002dda:	19048493          	addi	s1,s1,400
    80002dde:	ff3491e3          	bne	s1,s3,80002dc0 <kill+0x20>
  }
  return -1;
    80002de2:	557d                	li	a0,-1
    80002de4:	a829                	j	80002dfe <kill+0x5e>
      p->killed = 1;
    80002de6:	4785                	li	a5,1
    80002de8:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    80002dea:	5898                	lw	a4,48(s1)
    80002dec:	4789                	li	a5,2
    80002dee:	00f70f63          	beq	a4,a5,80002e0c <kill+0x6c>
      release(&p->lock);
    80002df2:	8526                	mv	a0,s1
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	ea4080e7          	jalr	-348(ra) # 80000c98 <release>
      return 0;
    80002dfc:	4501                	li	a0,0
}
    80002dfe:	70a2                	ld	ra,40(sp)
    80002e00:	7402                	ld	s0,32(sp)
    80002e02:	64e2                	ld	s1,24(sp)
    80002e04:	6942                	ld	s2,16(sp)
    80002e06:	69a2                	ld	s3,8(sp)
    80002e08:	6145                	addi	sp,sp,48
    80002e0a:	8082                	ret
        p->state = RUNNABLE;
    80002e0c:	478d                	li	a5,3
    80002e0e:	d89c                	sw	a5,48(s1)
        remove_proc(p, SLEEPINGL);
    80002e10:	4589                	li	a1,2
    80002e12:	8526                	mv	a0,s1
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	0c2080e7          	jalr	194(ra) # 80001ed6 <remove_proc>
        add_proc_to_list(p, READYL, p->parent_cpu);
    80002e1c:	4cb0                	lw	a2,88(s1)
    80002e1e:	4581                	li	a1,0
    80002e20:	8526                	mv	a0,s1
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	fd6080e7          	jalr	-42(ra) # 80001df8 <add_proc_to_list>
    80002e2a:	b7e1                	j	80002df2 <kill+0x52>

0000000080002e2c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002e2c:	7179                	addi	sp,sp,-48
    80002e2e:	f406                	sd	ra,40(sp)
    80002e30:	f022                	sd	s0,32(sp)
    80002e32:	ec26                	sd	s1,24(sp)
    80002e34:	e84a                	sd	s2,16(sp)
    80002e36:	e44e                	sd	s3,8(sp)
    80002e38:	e052                	sd	s4,0(sp)
    80002e3a:	1800                	addi	s0,sp,48
    80002e3c:	84aa                	mv	s1,a0
    80002e3e:	892e                	mv	s2,a1
    80002e40:	89b2                	mv	s3,a2
    80002e42:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	39c080e7          	jalr	924(ra) # 800021e0 <myproc>
  if(user_dst){
    80002e4c:	c08d                	beqz	s1,80002e6e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002e4e:	86d2                	mv	a3,s4
    80002e50:	864e                	mv	a2,s3
    80002e52:	85ca                	mv	a1,s2
    80002e54:	7d28                	ld	a0,120(a0)
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	81c080e7          	jalr	-2020(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002e5e:	70a2                	ld	ra,40(sp)
    80002e60:	7402                	ld	s0,32(sp)
    80002e62:	64e2                	ld	s1,24(sp)
    80002e64:	6942                	ld	s2,16(sp)
    80002e66:	69a2                	ld	s3,8(sp)
    80002e68:	6a02                	ld	s4,0(sp)
    80002e6a:	6145                	addi	sp,sp,48
    80002e6c:	8082                	ret
    memmove((char *)dst, src, len);
    80002e6e:	000a061b          	sext.w	a2,s4
    80002e72:	85ce                	mv	a1,s3
    80002e74:	854a                	mv	a0,s2
    80002e76:	ffffe097          	auipc	ra,0xffffe
    80002e7a:	eca080e7          	jalr	-310(ra) # 80000d40 <memmove>
    return 0;
    80002e7e:	8526                	mv	a0,s1
    80002e80:	bff9                	j	80002e5e <either_copyout+0x32>

0000000080002e82 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002e82:	7179                	addi	sp,sp,-48
    80002e84:	f406                	sd	ra,40(sp)
    80002e86:	f022                	sd	s0,32(sp)
    80002e88:	ec26                	sd	s1,24(sp)
    80002e8a:	e84a                	sd	s2,16(sp)
    80002e8c:	e44e                	sd	s3,8(sp)
    80002e8e:	e052                	sd	s4,0(sp)
    80002e90:	1800                	addi	s0,sp,48
    80002e92:	892a                	mv	s2,a0
    80002e94:	84ae                	mv	s1,a1
    80002e96:	89b2                	mv	s3,a2
    80002e98:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002e9a:	fffff097          	auipc	ra,0xfffff
    80002e9e:	346080e7          	jalr	838(ra) # 800021e0 <myproc>
  if(user_src){
    80002ea2:	c08d                	beqz	s1,80002ec4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002ea4:	86d2                	mv	a3,s4
    80002ea6:	864e                	mv	a2,s3
    80002ea8:	85ca                	mv	a1,s2
    80002eaa:	7d28                	ld	a0,120(a0)
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	852080e7          	jalr	-1966(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002eb4:	70a2                	ld	ra,40(sp)
    80002eb6:	7402                	ld	s0,32(sp)
    80002eb8:	64e2                	ld	s1,24(sp)
    80002eba:	6942                	ld	s2,16(sp)
    80002ebc:	69a2                	ld	s3,8(sp)
    80002ebe:	6a02                	ld	s4,0(sp)
    80002ec0:	6145                	addi	sp,sp,48
    80002ec2:	8082                	ret
    memmove(dst, (char*)src, len);
    80002ec4:	000a061b          	sext.w	a2,s4
    80002ec8:	85ce                	mv	a1,s3
    80002eca:	854a                	mv	a0,s2
    80002ecc:	ffffe097          	auipc	ra,0xffffe
    80002ed0:	e74080e7          	jalr	-396(ra) # 80000d40 <memmove>
    return 0;
    80002ed4:	8526                	mv	a0,s1
    80002ed6:	bff9                	j	80002eb4 <either_copyin+0x32>

0000000080002ed8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002ed8:	715d                	addi	sp,sp,-80
    80002eda:	e486                	sd	ra,72(sp)
    80002edc:	e0a2                	sd	s0,64(sp)
    80002ede:	fc26                	sd	s1,56(sp)
    80002ee0:	f84a                	sd	s2,48(sp)
    80002ee2:	f44e                	sd	s3,40(sp)
    80002ee4:	f052                	sd	s4,32(sp)
    80002ee6:	ec56                	sd	s5,24(sp)
    80002ee8:	e85a                	sd	s6,16(sp)
    80002eea:	e45e                	sd	s7,8(sp)
    80002eec:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002eee:	00005517          	auipc	a0,0x5
    80002ef2:	1da50513          	addi	a0,a0,474 # 800080c8 <digits+0x88>
    80002ef6:	ffffd097          	auipc	ra,0xffffd
    80002efa:	692080e7          	jalr	1682(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002efe:	0000e497          	auipc	s1,0xe
    80002f02:	6ca48493          	addi	s1,s1,1738 # 800115c8 <proc+0x180>
    80002f06:	00015917          	auipc	s2,0x15
    80002f0a:	ac290913          	addi	s2,s2,-1342 # 800179c8 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002f0e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002f10:	00005997          	auipc	s3,0x5
    80002f14:	4b898993          	addi	s3,s3,1208 # 800083c8 <digits+0x388>
    printf("%d %s %s", p->pid, state, p->name);
    80002f18:	00005a97          	auipc	s5,0x5
    80002f1c:	4b8a8a93          	addi	s5,s5,1208 # 800083d0 <digits+0x390>
    printf("\n");
    80002f20:	00005a17          	auipc	s4,0x5
    80002f24:	1a8a0a13          	addi	s4,s4,424 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002f28:	00005b97          	auipc	s7,0x5
    80002f2c:	4e0b8b93          	addi	s7,s7,1248 # 80008408 <states.1869>
    80002f30:	a00d                	j	80002f52 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002f32:	ec86a583          	lw	a1,-312(a3)
    80002f36:	8556                	mv	a0,s5
    80002f38:	ffffd097          	auipc	ra,0xffffd
    80002f3c:	650080e7          	jalr	1616(ra) # 80000588 <printf>
    printf("\n");
    80002f40:	8552                	mv	a0,s4
    80002f42:	ffffd097          	auipc	ra,0xffffd
    80002f46:	646080e7          	jalr	1606(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002f4a:	19048493          	addi	s1,s1,400
    80002f4e:	03248163          	beq	s1,s2,80002f70 <procdump+0x98>
    if(p->state == UNUSED)
    80002f52:	86a6                	mv	a3,s1
    80002f54:	eb04a783          	lw	a5,-336(s1)
    80002f58:	dbed                	beqz	a5,80002f4a <procdump+0x72>
      state = "???";
    80002f5a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002f5c:	fcfb6be3          	bltu	s6,a5,80002f32 <procdump+0x5a>
    80002f60:	1782                	slli	a5,a5,0x20
    80002f62:	9381                	srli	a5,a5,0x20
    80002f64:	078e                	slli	a5,a5,0x3
    80002f66:	97de                	add	a5,a5,s7
    80002f68:	6390                	ld	a2,0(a5)
    80002f6a:	f661                	bnez	a2,80002f32 <procdump+0x5a>
      state = "???";
    80002f6c:	864e                	mv	a2,s3
    80002f6e:	b7d1                	j	80002f32 <procdump+0x5a>
  }
}
    80002f70:	60a6                	ld	ra,72(sp)
    80002f72:	6406                	ld	s0,64(sp)
    80002f74:	74e2                	ld	s1,56(sp)
    80002f76:	7942                	ld	s2,48(sp)
    80002f78:	79a2                	ld	s3,40(sp)
    80002f7a:	7a02                	ld	s4,32(sp)
    80002f7c:	6ae2                	ld	s5,24(sp)
    80002f7e:	6b42                	ld	s6,16(sp)
    80002f80:	6ba2                	ld	s7,8(sp)
    80002f82:	6161                	addi	sp,sp,80
    80002f84:	8082                	ret

0000000080002f86 <swtch>:
    80002f86:	00153023          	sd	ra,0(a0)
    80002f8a:	00253423          	sd	sp,8(a0)
    80002f8e:	e900                	sd	s0,16(a0)
    80002f90:	ed04                	sd	s1,24(a0)
    80002f92:	03253023          	sd	s2,32(a0)
    80002f96:	03353423          	sd	s3,40(a0)
    80002f9a:	03453823          	sd	s4,48(a0)
    80002f9e:	03553c23          	sd	s5,56(a0)
    80002fa2:	05653023          	sd	s6,64(a0)
    80002fa6:	05753423          	sd	s7,72(a0)
    80002faa:	05853823          	sd	s8,80(a0)
    80002fae:	05953c23          	sd	s9,88(a0)
    80002fb2:	07a53023          	sd	s10,96(a0)
    80002fb6:	07b53423          	sd	s11,104(a0)
    80002fba:	0005b083          	ld	ra,0(a1)
    80002fbe:	0085b103          	ld	sp,8(a1)
    80002fc2:	6980                	ld	s0,16(a1)
    80002fc4:	6d84                	ld	s1,24(a1)
    80002fc6:	0205b903          	ld	s2,32(a1)
    80002fca:	0285b983          	ld	s3,40(a1)
    80002fce:	0305ba03          	ld	s4,48(a1)
    80002fd2:	0385ba83          	ld	s5,56(a1)
    80002fd6:	0405bb03          	ld	s6,64(a1)
    80002fda:	0485bb83          	ld	s7,72(a1)
    80002fde:	0505bc03          	ld	s8,80(a1)
    80002fe2:	0585bc83          	ld	s9,88(a1)
    80002fe6:	0605bd03          	ld	s10,96(a1)
    80002fea:	0685bd83          	ld	s11,104(a1)
    80002fee:	8082                	ret

0000000080002ff0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002ff0:	1141                	addi	sp,sp,-16
    80002ff2:	e406                	sd	ra,8(sp)
    80002ff4:	e022                	sd	s0,0(sp)
    80002ff6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ff8:	00005597          	auipc	a1,0x5
    80002ffc:	44058593          	addi	a1,a1,1088 # 80008438 <states.1869+0x30>
    80003000:	00015517          	auipc	a0,0x15
    80003004:	84850513          	addi	a0,a0,-1976 # 80017848 <tickslock>
    80003008:	ffffe097          	auipc	ra,0xffffe
    8000300c:	b4c080e7          	jalr	-1204(ra) # 80000b54 <initlock>
}
    80003010:	60a2                	ld	ra,8(sp)
    80003012:	6402                	ld	s0,0(sp)
    80003014:	0141                	addi	sp,sp,16
    80003016:	8082                	ret

0000000080003018 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003018:	1141                	addi	sp,sp,-16
    8000301a:	e422                	sd	s0,8(sp)
    8000301c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000301e:	00003797          	auipc	a5,0x3
    80003022:	4d278793          	addi	a5,a5,1234 # 800064f0 <kernelvec>
    80003026:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000302a:	6422                	ld	s0,8(sp)
    8000302c:	0141                	addi	sp,sp,16
    8000302e:	8082                	ret

0000000080003030 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003030:	1141                	addi	sp,sp,-16
    80003032:	e406                	sd	ra,8(sp)
    80003034:	e022                	sd	s0,0(sp)
    80003036:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003038:	fffff097          	auipc	ra,0xfffff
    8000303c:	1a8080e7          	jalr	424(ra) # 800021e0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003040:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003044:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003046:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000304a:	00004617          	auipc	a2,0x4
    8000304e:	fb660613          	addi	a2,a2,-74 # 80007000 <_trampoline>
    80003052:	00004697          	auipc	a3,0x4
    80003056:	fae68693          	addi	a3,a3,-82 # 80007000 <_trampoline>
    8000305a:	8e91                	sub	a3,a3,a2
    8000305c:	040007b7          	lui	a5,0x4000
    80003060:	17fd                	addi	a5,a5,-1
    80003062:	07b2                	slli	a5,a5,0xc
    80003064:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003066:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000306a:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000306c:	180026f3          	csrr	a3,satp
    80003070:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003072:	6158                	ld	a4,128(a0)
    80003074:	7534                	ld	a3,104(a0)
    80003076:	6585                	lui	a1,0x1
    80003078:	96ae                	add	a3,a3,a1
    8000307a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000307c:	6158                	ld	a4,128(a0)
    8000307e:	00000697          	auipc	a3,0x0
    80003082:	13868693          	addi	a3,a3,312 # 800031b6 <usertrap>
    80003086:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003088:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000308a:	8692                	mv	a3,tp
    8000308c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000308e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003092:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003096:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000309a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000309e:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030a0:	6f18                	ld	a4,24(a4)
    800030a2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800030a6:	7d2c                	ld	a1,120(a0)
    800030a8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800030aa:	00004717          	auipc	a4,0x4
    800030ae:	fe670713          	addi	a4,a4,-26 # 80007090 <userret>
    800030b2:	8f11                	sub	a4,a4,a2
    800030b4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800030b6:	577d                	li	a4,-1
    800030b8:	177e                	slli	a4,a4,0x3f
    800030ba:	8dd9                	or	a1,a1,a4
    800030bc:	02000537          	lui	a0,0x2000
    800030c0:	157d                	addi	a0,a0,-1
    800030c2:	0536                	slli	a0,a0,0xd
    800030c4:	9782                	jalr	a5
}
    800030c6:	60a2                	ld	ra,8(sp)
    800030c8:	6402                	ld	s0,0(sp)
    800030ca:	0141                	addi	sp,sp,16
    800030cc:	8082                	ret

00000000800030ce <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800030ce:	1101                	addi	sp,sp,-32
    800030d0:	ec06                	sd	ra,24(sp)
    800030d2:	e822                	sd	s0,16(sp)
    800030d4:	e426                	sd	s1,8(sp)
    800030d6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800030d8:	00014497          	auipc	s1,0x14
    800030dc:	77048493          	addi	s1,s1,1904 # 80017848 <tickslock>
    800030e0:	8526                	mv	a0,s1
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	b02080e7          	jalr	-1278(ra) # 80000be4 <acquire>
  ticks++;
    800030ea:	00006517          	auipc	a0,0x6
    800030ee:	f7e50513          	addi	a0,a0,-130 # 80009068 <ticks>
    800030f2:	411c                	lw	a5,0(a0)
    800030f4:	2785                	addiw	a5,a5,1
    800030f6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	a06080e7          	jalr	-1530(ra) # 80002afe <wakeup>
  release(&tickslock);
    80003100:	8526                	mv	a0,s1
    80003102:	ffffe097          	auipc	ra,0xffffe
    80003106:	b96080e7          	jalr	-1130(ra) # 80000c98 <release>
}
    8000310a:	60e2                	ld	ra,24(sp)
    8000310c:	6442                	ld	s0,16(sp)
    8000310e:	64a2                	ld	s1,8(sp)
    80003110:	6105                	addi	sp,sp,32
    80003112:	8082                	ret

0000000080003114 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003114:	1101                	addi	sp,sp,-32
    80003116:	ec06                	sd	ra,24(sp)
    80003118:	e822                	sd	s0,16(sp)
    8000311a:	e426                	sd	s1,8(sp)
    8000311c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000311e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003122:	00074d63          	bltz	a4,8000313c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003126:	57fd                	li	a5,-1
    80003128:	17fe                	slli	a5,a5,0x3f
    8000312a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000312c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000312e:	06f70363          	beq	a4,a5,80003194 <devintr+0x80>
  }
}
    80003132:	60e2                	ld	ra,24(sp)
    80003134:	6442                	ld	s0,16(sp)
    80003136:	64a2                	ld	s1,8(sp)
    80003138:	6105                	addi	sp,sp,32
    8000313a:	8082                	ret
     (scause & 0xff) == 9){
    8000313c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003140:	46a5                	li	a3,9
    80003142:	fed792e3          	bne	a5,a3,80003126 <devintr+0x12>
    int irq = plic_claim();
    80003146:	00003097          	auipc	ra,0x3
    8000314a:	4b2080e7          	jalr	1202(ra) # 800065f8 <plic_claim>
    8000314e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003150:	47a9                	li	a5,10
    80003152:	02f50763          	beq	a0,a5,80003180 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003156:	4785                	li	a5,1
    80003158:	02f50963          	beq	a0,a5,8000318a <devintr+0x76>
    return 1;
    8000315c:	4505                	li	a0,1
    } else if(irq){
    8000315e:	d8f1                	beqz	s1,80003132 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003160:	85a6                	mv	a1,s1
    80003162:	00005517          	auipc	a0,0x5
    80003166:	2de50513          	addi	a0,a0,734 # 80008440 <states.1869+0x38>
    8000316a:	ffffd097          	auipc	ra,0xffffd
    8000316e:	41e080e7          	jalr	1054(ra) # 80000588 <printf>
      plic_complete(irq);
    80003172:	8526                	mv	a0,s1
    80003174:	00003097          	auipc	ra,0x3
    80003178:	4a8080e7          	jalr	1192(ra) # 8000661c <plic_complete>
    return 1;
    8000317c:	4505                	li	a0,1
    8000317e:	bf55                	j	80003132 <devintr+0x1e>
      uartintr();
    80003180:	ffffe097          	auipc	ra,0xffffe
    80003184:	828080e7          	jalr	-2008(ra) # 800009a8 <uartintr>
    80003188:	b7ed                	j	80003172 <devintr+0x5e>
      virtio_disk_intr();
    8000318a:	00004097          	auipc	ra,0x4
    8000318e:	972080e7          	jalr	-1678(ra) # 80006afc <virtio_disk_intr>
    80003192:	b7c5                	j	80003172 <devintr+0x5e>
    if(cpuid() == 0){
    80003194:	fffff097          	auipc	ra,0xfffff
    80003198:	018080e7          	jalr	24(ra) # 800021ac <cpuid>
    8000319c:	c901                	beqz	a0,800031ac <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000319e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800031a2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800031a4:	14479073          	csrw	sip,a5
    return 2;
    800031a8:	4509                	li	a0,2
    800031aa:	b761                	j	80003132 <devintr+0x1e>
      clockintr();
    800031ac:	00000097          	auipc	ra,0x0
    800031b0:	f22080e7          	jalr	-222(ra) # 800030ce <clockintr>
    800031b4:	b7ed                	j	8000319e <devintr+0x8a>

00000000800031b6 <usertrap>:
{
    800031b6:	1101                	addi	sp,sp,-32
    800031b8:	ec06                	sd	ra,24(sp)
    800031ba:	e822                	sd	s0,16(sp)
    800031bc:	e426                	sd	s1,8(sp)
    800031be:	e04a                	sd	s2,0(sp)
    800031c0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031c2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800031c6:	1007f793          	andi	a5,a5,256
    800031ca:	e3ad                	bnez	a5,8000322c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800031cc:	00003797          	auipc	a5,0x3
    800031d0:	32478793          	addi	a5,a5,804 # 800064f0 <kernelvec>
    800031d4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800031d8:	fffff097          	auipc	ra,0xfffff
    800031dc:	008080e7          	jalr	8(ra) # 800021e0 <myproc>
    800031e0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800031e2:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031e4:	14102773          	csrr	a4,sepc
    800031e8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031ea:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800031ee:	47a1                	li	a5,8
    800031f0:	04f71c63          	bne	a4,a5,80003248 <usertrap+0x92>
    if(p->killed)
    800031f4:	413c                	lw	a5,64(a0)
    800031f6:	e3b9                	bnez	a5,8000323c <usertrap+0x86>
    p->trapframe->epc += 4;
    800031f8:	60d8                	ld	a4,128(s1)
    800031fa:	6f1c                	ld	a5,24(a4)
    800031fc:	0791                	addi	a5,a5,4
    800031fe:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003200:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003204:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003208:	10079073          	csrw	sstatus,a5
    syscall();
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	2e0080e7          	jalr	736(ra) # 800034ec <syscall>
  if(p->killed)
    80003214:	40bc                	lw	a5,64(s1)
    80003216:	ebc1                	bnez	a5,800032a6 <usertrap+0xf0>
  usertrapret();
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	e18080e7          	jalr	-488(ra) # 80003030 <usertrapret>
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6902                	ld	s2,0(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret
    panic("usertrap: not from user mode");
    8000322c:	00005517          	auipc	a0,0x5
    80003230:	23450513          	addi	a0,a0,564 # 80008460 <states.1869+0x58>
    80003234:	ffffd097          	auipc	ra,0xffffd
    80003238:	30a080e7          	jalr	778(ra) # 8000053e <panic>
      exit(-1);
    8000323c:	557d                	li	a0,-1
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	a7e080e7          	jalr	-1410(ra) # 80002cbc <exit>
    80003246:	bf4d                	j	800031f8 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003248:	00000097          	auipc	ra,0x0
    8000324c:	ecc080e7          	jalr	-308(ra) # 80003114 <devintr>
    80003250:	892a                	mv	s2,a0
    80003252:	c501                	beqz	a0,8000325a <usertrap+0xa4>
  if(p->killed)
    80003254:	40bc                	lw	a5,64(s1)
    80003256:	c3a1                	beqz	a5,80003296 <usertrap+0xe0>
    80003258:	a815                	j	8000328c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000325a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000325e:	44b0                	lw	a2,72(s1)
    80003260:	00005517          	auipc	a0,0x5
    80003264:	22050513          	addi	a0,a0,544 # 80008480 <states.1869+0x78>
    80003268:	ffffd097          	auipc	ra,0xffffd
    8000326c:	320080e7          	jalr	800(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003270:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003274:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003278:	00005517          	auipc	a0,0x5
    8000327c:	23850513          	addi	a0,a0,568 # 800084b0 <states.1869+0xa8>
    80003280:	ffffd097          	auipc	ra,0xffffd
    80003284:	308080e7          	jalr	776(ra) # 80000588 <printf>
    p->killed = 1;
    80003288:	4785                	li	a5,1
    8000328a:	c0bc                	sw	a5,64(s1)
    exit(-1);
    8000328c:	557d                	li	a0,-1
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	a2e080e7          	jalr	-1490(ra) # 80002cbc <exit>
  if(which_dev == 2)
    80003296:	4789                	li	a5,2
    80003298:	f8f910e3          	bne	s2,a5,80003218 <usertrap+0x62>
    yield();
    8000329c:	fffff097          	auipc	ra,0xfffff
    800032a0:	64a080e7          	jalr	1610(ra) # 800028e6 <yield>
    800032a4:	bf95                	j	80003218 <usertrap+0x62>
  int which_dev = 0;
    800032a6:	4901                	li	s2,0
    800032a8:	b7d5                	j	8000328c <usertrap+0xd6>

00000000800032aa <kerneltrap>:
{
    800032aa:	7179                	addi	sp,sp,-48
    800032ac:	f406                	sd	ra,40(sp)
    800032ae:	f022                	sd	s0,32(sp)
    800032b0:	ec26                	sd	s1,24(sp)
    800032b2:	e84a                	sd	s2,16(sp)
    800032b4:	e44e                	sd	s3,8(sp)
    800032b6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032b8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032bc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800032c0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800032c4:	1004f793          	andi	a5,s1,256
    800032c8:	cb85                	beqz	a5,800032f8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032ca:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800032ce:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800032d0:	ef85                	bnez	a5,80003308 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	e42080e7          	jalr	-446(ra) # 80003114 <devintr>
    800032da:	cd1d                	beqz	a0,80003318 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032dc:	4789                	li	a5,2
    800032de:	06f50a63          	beq	a0,a5,80003352 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032e2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032e6:	10049073          	csrw	sstatus,s1
}
    800032ea:	70a2                	ld	ra,40(sp)
    800032ec:	7402                	ld	s0,32(sp)
    800032ee:	64e2                	ld	s1,24(sp)
    800032f0:	6942                	ld	s2,16(sp)
    800032f2:	69a2                	ld	s3,8(sp)
    800032f4:	6145                	addi	sp,sp,48
    800032f6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800032f8:	00005517          	auipc	a0,0x5
    800032fc:	1d850513          	addi	a0,a0,472 # 800084d0 <states.1869+0xc8>
    80003300:	ffffd097          	auipc	ra,0xffffd
    80003304:	23e080e7          	jalr	574(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003308:	00005517          	auipc	a0,0x5
    8000330c:	1f050513          	addi	a0,a0,496 # 800084f8 <states.1869+0xf0>
    80003310:	ffffd097          	auipc	ra,0xffffd
    80003314:	22e080e7          	jalr	558(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003318:	85ce                	mv	a1,s3
    8000331a:	00005517          	auipc	a0,0x5
    8000331e:	1fe50513          	addi	a0,a0,510 # 80008518 <states.1869+0x110>
    80003322:	ffffd097          	auipc	ra,0xffffd
    80003326:	266080e7          	jalr	614(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000332a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000332e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003332:	00005517          	auipc	a0,0x5
    80003336:	1f650513          	addi	a0,a0,502 # 80008528 <states.1869+0x120>
    8000333a:	ffffd097          	auipc	ra,0xffffd
    8000333e:	24e080e7          	jalr	590(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003342:	00005517          	auipc	a0,0x5
    80003346:	1fe50513          	addi	a0,a0,510 # 80008540 <states.1869+0x138>
    8000334a:	ffffd097          	auipc	ra,0xffffd
    8000334e:	1f4080e7          	jalr	500(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003352:	fffff097          	auipc	ra,0xfffff
    80003356:	e8e080e7          	jalr	-370(ra) # 800021e0 <myproc>
    8000335a:	d541                	beqz	a0,800032e2 <kerneltrap+0x38>
    8000335c:	fffff097          	auipc	ra,0xfffff
    80003360:	e84080e7          	jalr	-380(ra) # 800021e0 <myproc>
    80003364:	5918                	lw	a4,48(a0)
    80003366:	4791                	li	a5,4
    80003368:	f6f71de3          	bne	a4,a5,800032e2 <kerneltrap+0x38>
    yield();
    8000336c:	fffff097          	auipc	ra,0xfffff
    80003370:	57a080e7          	jalr	1402(ra) # 800028e6 <yield>
    80003374:	b7bd                	j	800032e2 <kerneltrap+0x38>

0000000080003376 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003376:	1101                	addi	sp,sp,-32
    80003378:	ec06                	sd	ra,24(sp)
    8000337a:	e822                	sd	s0,16(sp)
    8000337c:	e426                	sd	s1,8(sp)
    8000337e:	1000                	addi	s0,sp,32
    80003380:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003382:	fffff097          	auipc	ra,0xfffff
    80003386:	e5e080e7          	jalr	-418(ra) # 800021e0 <myproc>
  switch (n) {
    8000338a:	4795                	li	a5,5
    8000338c:	0497e163          	bltu	a5,s1,800033ce <argraw+0x58>
    80003390:	048a                	slli	s1,s1,0x2
    80003392:	00005717          	auipc	a4,0x5
    80003396:	1e670713          	addi	a4,a4,486 # 80008578 <states.1869+0x170>
    8000339a:	94ba                	add	s1,s1,a4
    8000339c:	409c                	lw	a5,0(s1)
    8000339e:	97ba                	add	a5,a5,a4
    800033a0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800033a2:	615c                	ld	a5,128(a0)
    800033a4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800033a6:	60e2                	ld	ra,24(sp)
    800033a8:	6442                	ld	s0,16(sp)
    800033aa:	64a2                	ld	s1,8(sp)
    800033ac:	6105                	addi	sp,sp,32
    800033ae:	8082                	ret
    return p->trapframe->a1;
    800033b0:	615c                	ld	a5,128(a0)
    800033b2:	7fa8                	ld	a0,120(a5)
    800033b4:	bfcd                	j	800033a6 <argraw+0x30>
    return p->trapframe->a2;
    800033b6:	615c                	ld	a5,128(a0)
    800033b8:	63c8                	ld	a0,128(a5)
    800033ba:	b7f5                	j	800033a6 <argraw+0x30>
    return p->trapframe->a3;
    800033bc:	615c                	ld	a5,128(a0)
    800033be:	67c8                	ld	a0,136(a5)
    800033c0:	b7dd                	j	800033a6 <argraw+0x30>
    return p->trapframe->a4;
    800033c2:	615c                	ld	a5,128(a0)
    800033c4:	6bc8                	ld	a0,144(a5)
    800033c6:	b7c5                	j	800033a6 <argraw+0x30>
    return p->trapframe->a5;
    800033c8:	615c                	ld	a5,128(a0)
    800033ca:	6fc8                	ld	a0,152(a5)
    800033cc:	bfe9                	j	800033a6 <argraw+0x30>
  panic("argraw");
    800033ce:	00005517          	auipc	a0,0x5
    800033d2:	18250513          	addi	a0,a0,386 # 80008550 <states.1869+0x148>
    800033d6:	ffffd097          	auipc	ra,0xffffd
    800033da:	168080e7          	jalr	360(ra) # 8000053e <panic>

00000000800033de <fetchaddr>:
{
    800033de:	1101                	addi	sp,sp,-32
    800033e0:	ec06                	sd	ra,24(sp)
    800033e2:	e822                	sd	s0,16(sp)
    800033e4:	e426                	sd	s1,8(sp)
    800033e6:	e04a                	sd	s2,0(sp)
    800033e8:	1000                	addi	s0,sp,32
    800033ea:	84aa                	mv	s1,a0
    800033ec:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033ee:	fffff097          	auipc	ra,0xfffff
    800033f2:	df2080e7          	jalr	-526(ra) # 800021e0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800033f6:	793c                	ld	a5,112(a0)
    800033f8:	02f4f863          	bgeu	s1,a5,80003428 <fetchaddr+0x4a>
    800033fc:	00848713          	addi	a4,s1,8
    80003400:	02e7e663          	bltu	a5,a4,8000342c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003404:	46a1                	li	a3,8
    80003406:	8626                	mv	a2,s1
    80003408:	85ca                	mv	a1,s2
    8000340a:	7d28                	ld	a0,120(a0)
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	2f2080e7          	jalr	754(ra) # 800016fe <copyin>
    80003414:	00a03533          	snez	a0,a0
    80003418:	40a00533          	neg	a0,a0
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	64a2                	ld	s1,8(sp)
    80003422:	6902                	ld	s2,0(sp)
    80003424:	6105                	addi	sp,sp,32
    80003426:	8082                	ret
    return -1;
    80003428:	557d                	li	a0,-1
    8000342a:	bfcd                	j	8000341c <fetchaddr+0x3e>
    8000342c:	557d                	li	a0,-1
    8000342e:	b7fd                	j	8000341c <fetchaddr+0x3e>

0000000080003430 <fetchstr>:
{
    80003430:	7179                	addi	sp,sp,-48
    80003432:	f406                	sd	ra,40(sp)
    80003434:	f022                	sd	s0,32(sp)
    80003436:	ec26                	sd	s1,24(sp)
    80003438:	e84a                	sd	s2,16(sp)
    8000343a:	e44e                	sd	s3,8(sp)
    8000343c:	1800                	addi	s0,sp,48
    8000343e:	892a                	mv	s2,a0
    80003440:	84ae                	mv	s1,a1
    80003442:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003444:	fffff097          	auipc	ra,0xfffff
    80003448:	d9c080e7          	jalr	-612(ra) # 800021e0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000344c:	86ce                	mv	a3,s3
    8000344e:	864a                	mv	a2,s2
    80003450:	85a6                	mv	a1,s1
    80003452:	7d28                	ld	a0,120(a0)
    80003454:	ffffe097          	auipc	ra,0xffffe
    80003458:	336080e7          	jalr	822(ra) # 8000178a <copyinstr>
  if(err < 0)
    8000345c:	00054763          	bltz	a0,8000346a <fetchstr+0x3a>
  return strlen(buf);
    80003460:	8526                	mv	a0,s1
    80003462:	ffffe097          	auipc	ra,0xffffe
    80003466:	a02080e7          	jalr	-1534(ra) # 80000e64 <strlen>
}
    8000346a:	70a2                	ld	ra,40(sp)
    8000346c:	7402                	ld	s0,32(sp)
    8000346e:	64e2                	ld	s1,24(sp)
    80003470:	6942                	ld	s2,16(sp)
    80003472:	69a2                	ld	s3,8(sp)
    80003474:	6145                	addi	sp,sp,48
    80003476:	8082                	ret

0000000080003478 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003478:	1101                	addi	sp,sp,-32
    8000347a:	ec06                	sd	ra,24(sp)
    8000347c:	e822                	sd	s0,16(sp)
    8000347e:	e426                	sd	s1,8(sp)
    80003480:	1000                	addi	s0,sp,32
    80003482:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003484:	00000097          	auipc	ra,0x0
    80003488:	ef2080e7          	jalr	-270(ra) # 80003376 <argraw>
    8000348c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000348e:	4501                	li	a0,0
    80003490:	60e2                	ld	ra,24(sp)
    80003492:	6442                	ld	s0,16(sp)
    80003494:	64a2                	ld	s1,8(sp)
    80003496:	6105                	addi	sp,sp,32
    80003498:	8082                	ret

000000008000349a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000349a:	1101                	addi	sp,sp,-32
    8000349c:	ec06                	sd	ra,24(sp)
    8000349e:	e822                	sd	s0,16(sp)
    800034a0:	e426                	sd	s1,8(sp)
    800034a2:	1000                	addi	s0,sp,32
    800034a4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	ed0080e7          	jalr	-304(ra) # 80003376 <argraw>
    800034ae:	e088                	sd	a0,0(s1)
  return 0;
}
    800034b0:	4501                	li	a0,0
    800034b2:	60e2                	ld	ra,24(sp)
    800034b4:	6442                	ld	s0,16(sp)
    800034b6:	64a2                	ld	s1,8(sp)
    800034b8:	6105                	addi	sp,sp,32
    800034ba:	8082                	ret

00000000800034bc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800034bc:	1101                	addi	sp,sp,-32
    800034be:	ec06                	sd	ra,24(sp)
    800034c0:	e822                	sd	s0,16(sp)
    800034c2:	e426                	sd	s1,8(sp)
    800034c4:	e04a                	sd	s2,0(sp)
    800034c6:	1000                	addi	s0,sp,32
    800034c8:	84ae                	mv	s1,a1
    800034ca:	8932                	mv	s2,a2
  *ip = argraw(n);
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	eaa080e7          	jalr	-342(ra) # 80003376 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800034d4:	864a                	mv	a2,s2
    800034d6:	85a6                	mv	a1,s1
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	f58080e7          	jalr	-168(ra) # 80003430 <fetchstr>
}
    800034e0:	60e2                	ld	ra,24(sp)
    800034e2:	6442                	ld	s0,16(sp)
    800034e4:	64a2                	ld	s1,8(sp)
    800034e6:	6902                	ld	s2,0(sp)
    800034e8:	6105                	addi	sp,sp,32
    800034ea:	8082                	ret

00000000800034ec <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    800034ec:	1101                	addi	sp,sp,-32
    800034ee:	ec06                	sd	ra,24(sp)
    800034f0:	e822                	sd	s0,16(sp)
    800034f2:	e426                	sd	s1,8(sp)
    800034f4:	e04a                	sd	s2,0(sp)
    800034f6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800034f8:	fffff097          	auipc	ra,0xfffff
    800034fc:	ce8080e7          	jalr	-792(ra) # 800021e0 <myproc>
    80003500:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003502:	08053903          	ld	s2,128(a0)
    80003506:	0a893783          	ld	a5,168(s2)
    8000350a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000350e:	37fd                	addiw	a5,a5,-1
    80003510:	4759                	li	a4,22
    80003512:	00f76f63          	bltu	a4,a5,80003530 <syscall+0x44>
    80003516:	00369713          	slli	a4,a3,0x3
    8000351a:	00005797          	auipc	a5,0x5
    8000351e:	07678793          	addi	a5,a5,118 # 80008590 <syscalls>
    80003522:	97ba                	add	a5,a5,a4
    80003524:	639c                	ld	a5,0(a5)
    80003526:	c789                	beqz	a5,80003530 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003528:	9782                	jalr	a5
    8000352a:	06a93823          	sd	a0,112(s2)
    8000352e:	a839                	j	8000354c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003530:	18048613          	addi	a2,s1,384
    80003534:	44ac                	lw	a1,72(s1)
    80003536:	00005517          	auipc	a0,0x5
    8000353a:	02250513          	addi	a0,a0,34 # 80008558 <states.1869+0x150>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	04a080e7          	jalr	74(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003546:	60dc                	ld	a5,128(s1)
    80003548:	577d                	li	a4,-1
    8000354a:	fbb8                	sd	a4,112(a5)
  }
}
    8000354c:	60e2                	ld	ra,24(sp)
    8000354e:	6442                	ld	s0,16(sp)
    80003550:	64a2                	ld	s1,8(sp)
    80003552:	6902                	ld	s2,0(sp)
    80003554:	6105                	addi	sp,sp,32
    80003556:	8082                	ret

0000000080003558 <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    80003558:	1101                	addi	sp,sp,-32
    8000355a:	ec06                	sd	ra,24(sp)
    8000355c:	e822                	sd	s0,16(sp)
    8000355e:	1000                	addi	s0,sp,32
  int a;

  if(argint(0, &a) < 0)
    80003560:	fec40593          	addi	a1,s0,-20
    80003564:	4501                	li	a0,0
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	f12080e7          	jalr	-238(ra) # 80003478 <argint>
    8000356e:	87aa                	mv	a5,a0
    return -1;
    80003570:	557d                	li	a0,-1
  if(argint(0, &a) < 0)
    80003572:	0007c863          	bltz	a5,80003582 <sys_set_cpu+0x2a>
  return set_cpu(a);
    80003576:	fec42503          	lw	a0,-20(s0)
    8000357a:	fffff097          	auipc	ra,0xfffff
    8000357e:	3b6080e7          	jalr	950(ra) # 80002930 <set_cpu>
}
    80003582:	60e2                	ld	ra,24(sp)
    80003584:	6442                	ld	s0,16(sp)
    80003586:	6105                	addi	sp,sp,32
    80003588:	8082                	ret

000000008000358a <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    8000358a:	1141                	addi	sp,sp,-16
    8000358c:	e406                	sd	ra,8(sp)
    8000358e:	e022                	sd	s0,0(sp)
    80003590:	0800                	addi	s0,sp,16
  return get_cpu();
    80003592:	fffff097          	auipc	ra,0xfffff
    80003596:	c8e080e7          	jalr	-882(ra) # 80002220 <get_cpu>
}
    8000359a:	60a2                	ld	ra,8(sp)
    8000359c:	6402                	ld	s0,0(sp)
    8000359e:	0141                	addi	sp,sp,16
    800035a0:	8082                	ret

00000000800035a2 <sys_exit>:

uint64
sys_exit(void)
{
    800035a2:	1101                	addi	sp,sp,-32
    800035a4:	ec06                	sd	ra,24(sp)
    800035a6:	e822                	sd	s0,16(sp)
    800035a8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800035aa:	fec40593          	addi	a1,s0,-20
    800035ae:	4501                	li	a0,0
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	ec8080e7          	jalr	-312(ra) # 80003478 <argint>
    return -1;
    800035b8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800035ba:	00054963          	bltz	a0,800035cc <sys_exit+0x2a>
  exit(n);
    800035be:	fec42503          	lw	a0,-20(s0)
    800035c2:	fffff097          	auipc	ra,0xfffff
    800035c6:	6fa080e7          	jalr	1786(ra) # 80002cbc <exit>
  return 0;  // not reached
    800035ca:	4781                	li	a5,0
}
    800035cc:	853e                	mv	a0,a5
    800035ce:	60e2                	ld	ra,24(sp)
    800035d0:	6442                	ld	s0,16(sp)
    800035d2:	6105                	addi	sp,sp,32
    800035d4:	8082                	ret

00000000800035d6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800035d6:	1141                	addi	sp,sp,-16
    800035d8:	e406                	sd	ra,8(sp)
    800035da:	e022                	sd	s0,0(sp)
    800035dc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800035de:	fffff097          	auipc	ra,0xfffff
    800035e2:	c02080e7          	jalr	-1022(ra) # 800021e0 <myproc>
}
    800035e6:	4528                	lw	a0,72(a0)
    800035e8:	60a2                	ld	ra,8(sp)
    800035ea:	6402                	ld	s0,0(sp)
    800035ec:	0141                	addi	sp,sp,16
    800035ee:	8082                	ret

00000000800035f0 <sys_fork>:

uint64
sys_fork(void)
{
    800035f0:	1141                	addi	sp,sp,-16
    800035f2:	e406                	sd	ra,8(sp)
    800035f4:	e022                	sd	s0,0(sp)
    800035f6:	0800                	addi	s0,sp,16
  return fork();
    800035f8:	fffff097          	auipc	ra,0xfffff
    800035fc:	ff8080e7          	jalr	-8(ra) # 800025f0 <fork>
}
    80003600:	60a2                	ld	ra,8(sp)
    80003602:	6402                	ld	s0,0(sp)
    80003604:	0141                	addi	sp,sp,16
    80003606:	8082                	ret

0000000080003608 <sys_wait>:

uint64
sys_wait(void)
{
    80003608:	1101                	addi	sp,sp,-32
    8000360a:	ec06                	sd	ra,24(sp)
    8000360c:	e822                	sd	s0,16(sp)
    8000360e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003610:	fe840593          	addi	a1,s0,-24
    80003614:	4501                	li	a0,0
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	e84080e7          	jalr	-380(ra) # 8000349a <argaddr>
    8000361e:	87aa                	mv	a5,a0
    return -1;
    80003620:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003622:	0007c863          	bltz	a5,80003632 <sys_wait+0x2a>
  return wait(p);
    80003626:	fe843503          	ld	a0,-24(s0)
    8000362a:	fffff097          	auipc	ra,0xfffff
    8000362e:	3ac080e7          	jalr	940(ra) # 800029d6 <wait>
}
    80003632:	60e2                	ld	ra,24(sp)
    80003634:	6442                	ld	s0,16(sp)
    80003636:	6105                	addi	sp,sp,32
    80003638:	8082                	ret

000000008000363a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000363a:	7179                	addi	sp,sp,-48
    8000363c:	f406                	sd	ra,40(sp)
    8000363e:	f022                	sd	s0,32(sp)
    80003640:	ec26                	sd	s1,24(sp)
    80003642:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003644:	fdc40593          	addi	a1,s0,-36
    80003648:	4501                	li	a0,0
    8000364a:	00000097          	auipc	ra,0x0
    8000364e:	e2e080e7          	jalr	-466(ra) # 80003478 <argint>
    80003652:	87aa                	mv	a5,a0
    return -1;
    80003654:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003656:	0207c063          	bltz	a5,80003676 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000365a:	fffff097          	auipc	ra,0xfffff
    8000365e:	b86080e7          	jalr	-1146(ra) # 800021e0 <myproc>
    80003662:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    80003664:	fdc42503          	lw	a0,-36(s0)
    80003668:	fffff097          	auipc	ra,0xfffff
    8000366c:	f14080e7          	jalr	-236(ra) # 8000257c <growproc>
    80003670:	00054863          	bltz	a0,80003680 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003674:	8526                	mv	a0,s1
}
    80003676:	70a2                	ld	ra,40(sp)
    80003678:	7402                	ld	s0,32(sp)
    8000367a:	64e2                	ld	s1,24(sp)
    8000367c:	6145                	addi	sp,sp,48
    8000367e:	8082                	ret
    return -1;
    80003680:	557d                	li	a0,-1
    80003682:	bfd5                	j	80003676 <sys_sbrk+0x3c>

0000000080003684 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003684:	7139                	addi	sp,sp,-64
    80003686:	fc06                	sd	ra,56(sp)
    80003688:	f822                	sd	s0,48(sp)
    8000368a:	f426                	sd	s1,40(sp)
    8000368c:	f04a                	sd	s2,32(sp)
    8000368e:	ec4e                	sd	s3,24(sp)
    80003690:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003692:	fcc40593          	addi	a1,s0,-52
    80003696:	4501                	li	a0,0
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	de0080e7          	jalr	-544(ra) # 80003478 <argint>
    return -1;
    800036a0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800036a2:	06054563          	bltz	a0,8000370c <sys_sleep+0x88>
  acquire(&tickslock);
    800036a6:	00014517          	auipc	a0,0x14
    800036aa:	1a250513          	addi	a0,a0,418 # 80017848 <tickslock>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	536080e7          	jalr	1334(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800036b6:	00006917          	auipc	s2,0x6
    800036ba:	9b292903          	lw	s2,-1614(s2) # 80009068 <ticks>
  while(ticks - ticks0 < n){
    800036be:	fcc42783          	lw	a5,-52(s0)
    800036c2:	cf85                	beqz	a5,800036fa <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800036c4:	00014997          	auipc	s3,0x14
    800036c8:	18498993          	addi	s3,s3,388 # 80017848 <tickslock>
    800036cc:	00006497          	auipc	s1,0x6
    800036d0:	99c48493          	addi	s1,s1,-1636 # 80009068 <ticks>
    if(myproc()->killed){
    800036d4:	fffff097          	auipc	ra,0xfffff
    800036d8:	b0c080e7          	jalr	-1268(ra) # 800021e0 <myproc>
    800036dc:	413c                	lw	a5,64(a0)
    800036de:	ef9d                	bnez	a5,8000371c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800036e0:	85ce                	mv	a1,s3
    800036e2:	8526                	mv	a0,s1
    800036e4:	fffff097          	auipc	ra,0xfffff
    800036e8:	280080e7          	jalr	640(ra) # 80002964 <sleep>
  while(ticks - ticks0 < n){
    800036ec:	409c                	lw	a5,0(s1)
    800036ee:	412787bb          	subw	a5,a5,s2
    800036f2:	fcc42703          	lw	a4,-52(s0)
    800036f6:	fce7efe3          	bltu	a5,a4,800036d4 <sys_sleep+0x50>
  }
  release(&tickslock);
    800036fa:	00014517          	auipc	a0,0x14
    800036fe:	14e50513          	addi	a0,a0,334 # 80017848 <tickslock>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	596080e7          	jalr	1430(ra) # 80000c98 <release>
  return 0;
    8000370a:	4781                	li	a5,0
}
    8000370c:	853e                	mv	a0,a5
    8000370e:	70e2                	ld	ra,56(sp)
    80003710:	7442                	ld	s0,48(sp)
    80003712:	74a2                	ld	s1,40(sp)
    80003714:	7902                	ld	s2,32(sp)
    80003716:	69e2                	ld	s3,24(sp)
    80003718:	6121                	addi	sp,sp,64
    8000371a:	8082                	ret
      release(&tickslock);
    8000371c:	00014517          	auipc	a0,0x14
    80003720:	12c50513          	addi	a0,a0,300 # 80017848 <tickslock>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	574080e7          	jalr	1396(ra) # 80000c98 <release>
      return -1;
    8000372c:	57fd                	li	a5,-1
    8000372e:	bff9                	j	8000370c <sys_sleep+0x88>

0000000080003730 <sys_kill>:

uint64
sys_kill(void)
{
    80003730:	1101                	addi	sp,sp,-32
    80003732:	ec06                	sd	ra,24(sp)
    80003734:	e822                	sd	s0,16(sp)
    80003736:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003738:	fec40593          	addi	a1,s0,-20
    8000373c:	4501                	li	a0,0
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	d3a080e7          	jalr	-710(ra) # 80003478 <argint>
    80003746:	87aa                	mv	a5,a0
    return -1;
    80003748:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000374a:	0007c863          	bltz	a5,8000375a <sys_kill+0x2a>
  return kill(pid);
    8000374e:	fec42503          	lw	a0,-20(s0)
    80003752:	fffff097          	auipc	ra,0xfffff
    80003756:	64e080e7          	jalr	1614(ra) # 80002da0 <kill>
}
    8000375a:	60e2                	ld	ra,24(sp)
    8000375c:	6442                	ld	s0,16(sp)
    8000375e:	6105                	addi	sp,sp,32
    80003760:	8082                	ret

0000000080003762 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003762:	1101                	addi	sp,sp,-32
    80003764:	ec06                	sd	ra,24(sp)
    80003766:	e822                	sd	s0,16(sp)
    80003768:	e426                	sd	s1,8(sp)
    8000376a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000376c:	00014517          	auipc	a0,0x14
    80003770:	0dc50513          	addi	a0,a0,220 # 80017848 <tickslock>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	470080e7          	jalr	1136(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000377c:	00006497          	auipc	s1,0x6
    80003780:	8ec4a483          	lw	s1,-1812(s1) # 80009068 <ticks>
  release(&tickslock);
    80003784:	00014517          	auipc	a0,0x14
    80003788:	0c450513          	addi	a0,a0,196 # 80017848 <tickslock>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	50c080e7          	jalr	1292(ra) # 80000c98 <release>
  return xticks;
}
    80003794:	02049513          	slli	a0,s1,0x20
    80003798:	9101                	srli	a0,a0,0x20
    8000379a:	60e2                	ld	ra,24(sp)
    8000379c:	6442                	ld	s0,16(sp)
    8000379e:	64a2                	ld	s1,8(sp)
    800037a0:	6105                	addi	sp,sp,32
    800037a2:	8082                	ret

00000000800037a4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800037a4:	7179                	addi	sp,sp,-48
    800037a6:	f406                	sd	ra,40(sp)
    800037a8:	f022                	sd	s0,32(sp)
    800037aa:	ec26                	sd	s1,24(sp)
    800037ac:	e84a                	sd	s2,16(sp)
    800037ae:	e44e                	sd	s3,8(sp)
    800037b0:	e052                	sd	s4,0(sp)
    800037b2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800037b4:	00005597          	auipc	a1,0x5
    800037b8:	e9c58593          	addi	a1,a1,-356 # 80008650 <syscalls+0xc0>
    800037bc:	00014517          	auipc	a0,0x14
    800037c0:	0a450513          	addi	a0,a0,164 # 80017860 <bcache>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	390080e7          	jalr	912(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800037cc:	0001c797          	auipc	a5,0x1c
    800037d0:	09478793          	addi	a5,a5,148 # 8001f860 <bcache+0x8000>
    800037d4:	0001c717          	auipc	a4,0x1c
    800037d8:	2f470713          	addi	a4,a4,756 # 8001fac8 <bcache+0x8268>
    800037dc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800037e0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037e4:	00014497          	auipc	s1,0x14
    800037e8:	09448493          	addi	s1,s1,148 # 80017878 <bcache+0x18>
    b->next = bcache.head.next;
    800037ec:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800037ee:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800037f0:	00005a17          	auipc	s4,0x5
    800037f4:	e68a0a13          	addi	s4,s4,-408 # 80008658 <syscalls+0xc8>
    b->next = bcache.head.next;
    800037f8:	2b893783          	ld	a5,696(s2)
    800037fc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800037fe:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003802:	85d2                	mv	a1,s4
    80003804:	01048513          	addi	a0,s1,16
    80003808:	00001097          	auipc	ra,0x1
    8000380c:	4bc080e7          	jalr	1212(ra) # 80004cc4 <initsleeplock>
    bcache.head.next->prev = b;
    80003810:	2b893783          	ld	a5,696(s2)
    80003814:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003816:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000381a:	45848493          	addi	s1,s1,1112
    8000381e:	fd349de3          	bne	s1,s3,800037f8 <binit+0x54>
  }
}
    80003822:	70a2                	ld	ra,40(sp)
    80003824:	7402                	ld	s0,32(sp)
    80003826:	64e2                	ld	s1,24(sp)
    80003828:	6942                	ld	s2,16(sp)
    8000382a:	69a2                	ld	s3,8(sp)
    8000382c:	6a02                	ld	s4,0(sp)
    8000382e:	6145                	addi	sp,sp,48
    80003830:	8082                	ret

0000000080003832 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003832:	7179                	addi	sp,sp,-48
    80003834:	f406                	sd	ra,40(sp)
    80003836:	f022                	sd	s0,32(sp)
    80003838:	ec26                	sd	s1,24(sp)
    8000383a:	e84a                	sd	s2,16(sp)
    8000383c:	e44e                	sd	s3,8(sp)
    8000383e:	1800                	addi	s0,sp,48
    80003840:	89aa                	mv	s3,a0
    80003842:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003844:	00014517          	auipc	a0,0x14
    80003848:	01c50513          	addi	a0,a0,28 # 80017860 <bcache>
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	398080e7          	jalr	920(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003854:	0001c497          	auipc	s1,0x1c
    80003858:	2c44b483          	ld	s1,708(s1) # 8001fb18 <bcache+0x82b8>
    8000385c:	0001c797          	auipc	a5,0x1c
    80003860:	26c78793          	addi	a5,a5,620 # 8001fac8 <bcache+0x8268>
    80003864:	02f48f63          	beq	s1,a5,800038a2 <bread+0x70>
    80003868:	873e                	mv	a4,a5
    8000386a:	a021                	j	80003872 <bread+0x40>
    8000386c:	68a4                	ld	s1,80(s1)
    8000386e:	02e48a63          	beq	s1,a4,800038a2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003872:	449c                	lw	a5,8(s1)
    80003874:	ff379ce3          	bne	a5,s3,8000386c <bread+0x3a>
    80003878:	44dc                	lw	a5,12(s1)
    8000387a:	ff2799e3          	bne	a5,s2,8000386c <bread+0x3a>
      b->refcnt++;
    8000387e:	40bc                	lw	a5,64(s1)
    80003880:	2785                	addiw	a5,a5,1
    80003882:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003884:	00014517          	auipc	a0,0x14
    80003888:	fdc50513          	addi	a0,a0,-36 # 80017860 <bcache>
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	40c080e7          	jalr	1036(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003894:	01048513          	addi	a0,s1,16
    80003898:	00001097          	auipc	ra,0x1
    8000389c:	466080e7          	jalr	1126(ra) # 80004cfe <acquiresleep>
      return b;
    800038a0:	a8b9                	j	800038fe <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038a2:	0001c497          	auipc	s1,0x1c
    800038a6:	26e4b483          	ld	s1,622(s1) # 8001fb10 <bcache+0x82b0>
    800038aa:	0001c797          	auipc	a5,0x1c
    800038ae:	21e78793          	addi	a5,a5,542 # 8001fac8 <bcache+0x8268>
    800038b2:	00f48863          	beq	s1,a5,800038c2 <bread+0x90>
    800038b6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800038b8:	40bc                	lw	a5,64(s1)
    800038ba:	cf81                	beqz	a5,800038d2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038bc:	64a4                	ld	s1,72(s1)
    800038be:	fee49de3          	bne	s1,a4,800038b8 <bread+0x86>
  panic("bget: no buffers");
    800038c2:	00005517          	auipc	a0,0x5
    800038c6:	d9e50513          	addi	a0,a0,-610 # 80008660 <syscalls+0xd0>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	c74080e7          	jalr	-908(ra) # 8000053e <panic>
      b->dev = dev;
    800038d2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800038d6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800038da:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800038de:	4785                	li	a5,1
    800038e0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800038e2:	00014517          	auipc	a0,0x14
    800038e6:	f7e50513          	addi	a0,a0,-130 # 80017860 <bcache>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800038f2:	01048513          	addi	a0,s1,16
    800038f6:	00001097          	auipc	ra,0x1
    800038fa:	408080e7          	jalr	1032(ra) # 80004cfe <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800038fe:	409c                	lw	a5,0(s1)
    80003900:	cb89                	beqz	a5,80003912 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003902:	8526                	mv	a0,s1
    80003904:	70a2                	ld	ra,40(sp)
    80003906:	7402                	ld	s0,32(sp)
    80003908:	64e2                	ld	s1,24(sp)
    8000390a:	6942                	ld	s2,16(sp)
    8000390c:	69a2                	ld	s3,8(sp)
    8000390e:	6145                	addi	sp,sp,48
    80003910:	8082                	ret
    virtio_disk_rw(b, 0);
    80003912:	4581                	li	a1,0
    80003914:	8526                	mv	a0,s1
    80003916:	00003097          	auipc	ra,0x3
    8000391a:	f10080e7          	jalr	-240(ra) # 80006826 <virtio_disk_rw>
    b->valid = 1;
    8000391e:	4785                	li	a5,1
    80003920:	c09c                	sw	a5,0(s1)
  return b;
    80003922:	b7c5                	j	80003902 <bread+0xd0>

0000000080003924 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003924:	1101                	addi	sp,sp,-32
    80003926:	ec06                	sd	ra,24(sp)
    80003928:	e822                	sd	s0,16(sp)
    8000392a:	e426                	sd	s1,8(sp)
    8000392c:	1000                	addi	s0,sp,32
    8000392e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003930:	0541                	addi	a0,a0,16
    80003932:	00001097          	auipc	ra,0x1
    80003936:	466080e7          	jalr	1126(ra) # 80004d98 <holdingsleep>
    8000393a:	cd01                	beqz	a0,80003952 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000393c:	4585                	li	a1,1
    8000393e:	8526                	mv	a0,s1
    80003940:	00003097          	auipc	ra,0x3
    80003944:	ee6080e7          	jalr	-282(ra) # 80006826 <virtio_disk_rw>
}
    80003948:	60e2                	ld	ra,24(sp)
    8000394a:	6442                	ld	s0,16(sp)
    8000394c:	64a2                	ld	s1,8(sp)
    8000394e:	6105                	addi	sp,sp,32
    80003950:	8082                	ret
    panic("bwrite");
    80003952:	00005517          	auipc	a0,0x5
    80003956:	d2650513          	addi	a0,a0,-730 # 80008678 <syscalls+0xe8>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	be4080e7          	jalr	-1052(ra) # 8000053e <panic>

0000000080003962 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003962:	1101                	addi	sp,sp,-32
    80003964:	ec06                	sd	ra,24(sp)
    80003966:	e822                	sd	s0,16(sp)
    80003968:	e426                	sd	s1,8(sp)
    8000396a:	e04a                	sd	s2,0(sp)
    8000396c:	1000                	addi	s0,sp,32
    8000396e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003970:	01050913          	addi	s2,a0,16
    80003974:	854a                	mv	a0,s2
    80003976:	00001097          	auipc	ra,0x1
    8000397a:	422080e7          	jalr	1058(ra) # 80004d98 <holdingsleep>
    8000397e:	c92d                	beqz	a0,800039f0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003980:	854a                	mv	a0,s2
    80003982:	00001097          	auipc	ra,0x1
    80003986:	3d2080e7          	jalr	978(ra) # 80004d54 <releasesleep>

  acquire(&bcache.lock);
    8000398a:	00014517          	auipc	a0,0x14
    8000398e:	ed650513          	addi	a0,a0,-298 # 80017860 <bcache>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	252080e7          	jalr	594(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000399a:	40bc                	lw	a5,64(s1)
    8000399c:	37fd                	addiw	a5,a5,-1
    8000399e:	0007871b          	sext.w	a4,a5
    800039a2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800039a4:	eb05                	bnez	a4,800039d4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800039a6:	68bc                	ld	a5,80(s1)
    800039a8:	64b8                	ld	a4,72(s1)
    800039aa:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800039ac:	64bc                	ld	a5,72(s1)
    800039ae:	68b8                	ld	a4,80(s1)
    800039b0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800039b2:	0001c797          	auipc	a5,0x1c
    800039b6:	eae78793          	addi	a5,a5,-338 # 8001f860 <bcache+0x8000>
    800039ba:	2b87b703          	ld	a4,696(a5)
    800039be:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800039c0:	0001c717          	auipc	a4,0x1c
    800039c4:	10870713          	addi	a4,a4,264 # 8001fac8 <bcache+0x8268>
    800039c8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800039ca:	2b87b703          	ld	a4,696(a5)
    800039ce:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800039d0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800039d4:	00014517          	auipc	a0,0x14
    800039d8:	e8c50513          	addi	a0,a0,-372 # 80017860 <bcache>
    800039dc:	ffffd097          	auipc	ra,0xffffd
    800039e0:	2bc080e7          	jalr	700(ra) # 80000c98 <release>
}
    800039e4:	60e2                	ld	ra,24(sp)
    800039e6:	6442                	ld	s0,16(sp)
    800039e8:	64a2                	ld	s1,8(sp)
    800039ea:	6902                	ld	s2,0(sp)
    800039ec:	6105                	addi	sp,sp,32
    800039ee:	8082                	ret
    panic("brelse");
    800039f0:	00005517          	auipc	a0,0x5
    800039f4:	c9050513          	addi	a0,a0,-880 # 80008680 <syscalls+0xf0>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	b46080e7          	jalr	-1210(ra) # 8000053e <panic>

0000000080003a00 <bpin>:

void
bpin(struct buf *b) {
    80003a00:	1101                	addi	sp,sp,-32
    80003a02:	ec06                	sd	ra,24(sp)
    80003a04:	e822                	sd	s0,16(sp)
    80003a06:	e426                	sd	s1,8(sp)
    80003a08:	1000                	addi	s0,sp,32
    80003a0a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a0c:	00014517          	auipc	a0,0x14
    80003a10:	e5450513          	addi	a0,a0,-428 # 80017860 <bcache>
    80003a14:	ffffd097          	auipc	ra,0xffffd
    80003a18:	1d0080e7          	jalr	464(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003a1c:	40bc                	lw	a5,64(s1)
    80003a1e:	2785                	addiw	a5,a5,1
    80003a20:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a22:	00014517          	auipc	a0,0x14
    80003a26:	e3e50513          	addi	a0,a0,-450 # 80017860 <bcache>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	26e080e7          	jalr	622(ra) # 80000c98 <release>
}
    80003a32:	60e2                	ld	ra,24(sp)
    80003a34:	6442                	ld	s0,16(sp)
    80003a36:	64a2                	ld	s1,8(sp)
    80003a38:	6105                	addi	sp,sp,32
    80003a3a:	8082                	ret

0000000080003a3c <bunpin>:

void
bunpin(struct buf *b) {
    80003a3c:	1101                	addi	sp,sp,-32
    80003a3e:	ec06                	sd	ra,24(sp)
    80003a40:	e822                	sd	s0,16(sp)
    80003a42:	e426                	sd	s1,8(sp)
    80003a44:	1000                	addi	s0,sp,32
    80003a46:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a48:	00014517          	auipc	a0,0x14
    80003a4c:	e1850513          	addi	a0,a0,-488 # 80017860 <bcache>
    80003a50:	ffffd097          	auipc	ra,0xffffd
    80003a54:	194080e7          	jalr	404(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003a58:	40bc                	lw	a5,64(s1)
    80003a5a:	37fd                	addiw	a5,a5,-1
    80003a5c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a5e:	00014517          	auipc	a0,0x14
    80003a62:	e0250513          	addi	a0,a0,-510 # 80017860 <bcache>
    80003a66:	ffffd097          	auipc	ra,0xffffd
    80003a6a:	232080e7          	jalr	562(ra) # 80000c98 <release>
}
    80003a6e:	60e2                	ld	ra,24(sp)
    80003a70:	6442                	ld	s0,16(sp)
    80003a72:	64a2                	ld	s1,8(sp)
    80003a74:	6105                	addi	sp,sp,32
    80003a76:	8082                	ret

0000000080003a78 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003a78:	1101                	addi	sp,sp,-32
    80003a7a:	ec06                	sd	ra,24(sp)
    80003a7c:	e822                	sd	s0,16(sp)
    80003a7e:	e426                	sd	s1,8(sp)
    80003a80:	e04a                	sd	s2,0(sp)
    80003a82:	1000                	addi	s0,sp,32
    80003a84:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a86:	00d5d59b          	srliw	a1,a1,0xd
    80003a8a:	0001c797          	auipc	a5,0x1c
    80003a8e:	4b27a783          	lw	a5,1202(a5) # 8001ff3c <sb+0x1c>
    80003a92:	9dbd                	addw	a1,a1,a5
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	d9e080e7          	jalr	-610(ra) # 80003832 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a9c:	0074f713          	andi	a4,s1,7
    80003aa0:	4785                	li	a5,1
    80003aa2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003aa6:	14ce                	slli	s1,s1,0x33
    80003aa8:	90d9                	srli	s1,s1,0x36
    80003aaa:	00950733          	add	a4,a0,s1
    80003aae:	05874703          	lbu	a4,88(a4)
    80003ab2:	00e7f6b3          	and	a3,a5,a4
    80003ab6:	c69d                	beqz	a3,80003ae4 <bfree+0x6c>
    80003ab8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003aba:	94aa                	add	s1,s1,a0
    80003abc:	fff7c793          	not	a5,a5
    80003ac0:	8ff9                	and	a5,a5,a4
    80003ac2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003ac6:	00001097          	auipc	ra,0x1
    80003aca:	118080e7          	jalr	280(ra) # 80004bde <log_write>
  brelse(bp);
    80003ace:	854a                	mv	a0,s2
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	e92080e7          	jalr	-366(ra) # 80003962 <brelse>
}
    80003ad8:	60e2                	ld	ra,24(sp)
    80003ada:	6442                	ld	s0,16(sp)
    80003adc:	64a2                	ld	s1,8(sp)
    80003ade:	6902                	ld	s2,0(sp)
    80003ae0:	6105                	addi	sp,sp,32
    80003ae2:	8082                	ret
    panic("freeing free block");
    80003ae4:	00005517          	auipc	a0,0x5
    80003ae8:	ba450513          	addi	a0,a0,-1116 # 80008688 <syscalls+0xf8>
    80003aec:	ffffd097          	auipc	ra,0xffffd
    80003af0:	a52080e7          	jalr	-1454(ra) # 8000053e <panic>

0000000080003af4 <balloc>:
{
    80003af4:	711d                	addi	sp,sp,-96
    80003af6:	ec86                	sd	ra,88(sp)
    80003af8:	e8a2                	sd	s0,80(sp)
    80003afa:	e4a6                	sd	s1,72(sp)
    80003afc:	e0ca                	sd	s2,64(sp)
    80003afe:	fc4e                	sd	s3,56(sp)
    80003b00:	f852                	sd	s4,48(sp)
    80003b02:	f456                	sd	s5,40(sp)
    80003b04:	f05a                	sd	s6,32(sp)
    80003b06:	ec5e                	sd	s7,24(sp)
    80003b08:	e862                	sd	s8,16(sp)
    80003b0a:	e466                	sd	s9,8(sp)
    80003b0c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003b0e:	0001c797          	auipc	a5,0x1c
    80003b12:	4167a783          	lw	a5,1046(a5) # 8001ff24 <sb+0x4>
    80003b16:	cbd1                	beqz	a5,80003baa <balloc+0xb6>
    80003b18:	8baa                	mv	s7,a0
    80003b1a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003b1c:	0001cb17          	auipc	s6,0x1c
    80003b20:	404b0b13          	addi	s6,s6,1028 # 8001ff20 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b24:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003b26:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b28:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003b2a:	6c89                	lui	s9,0x2
    80003b2c:	a831                	j	80003b48 <balloc+0x54>
    brelse(bp);
    80003b2e:	854a                	mv	a0,s2
    80003b30:	00000097          	auipc	ra,0x0
    80003b34:	e32080e7          	jalr	-462(ra) # 80003962 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003b38:	015c87bb          	addw	a5,s9,s5
    80003b3c:	00078a9b          	sext.w	s5,a5
    80003b40:	004b2703          	lw	a4,4(s6)
    80003b44:	06eaf363          	bgeu	s5,a4,80003baa <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003b48:	41fad79b          	sraiw	a5,s5,0x1f
    80003b4c:	0137d79b          	srliw	a5,a5,0x13
    80003b50:	015787bb          	addw	a5,a5,s5
    80003b54:	40d7d79b          	sraiw	a5,a5,0xd
    80003b58:	01cb2583          	lw	a1,28(s6)
    80003b5c:	9dbd                	addw	a1,a1,a5
    80003b5e:	855e                	mv	a0,s7
    80003b60:	00000097          	auipc	ra,0x0
    80003b64:	cd2080e7          	jalr	-814(ra) # 80003832 <bread>
    80003b68:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b6a:	004b2503          	lw	a0,4(s6)
    80003b6e:	000a849b          	sext.w	s1,s5
    80003b72:	8662                	mv	a2,s8
    80003b74:	faa4fde3          	bgeu	s1,a0,80003b2e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003b78:	41f6579b          	sraiw	a5,a2,0x1f
    80003b7c:	01d7d69b          	srliw	a3,a5,0x1d
    80003b80:	00c6873b          	addw	a4,a3,a2
    80003b84:	00777793          	andi	a5,a4,7
    80003b88:	9f95                	subw	a5,a5,a3
    80003b8a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003b8e:	4037571b          	sraiw	a4,a4,0x3
    80003b92:	00e906b3          	add	a3,s2,a4
    80003b96:	0586c683          	lbu	a3,88(a3)
    80003b9a:	00d7f5b3          	and	a1,a5,a3
    80003b9e:	cd91                	beqz	a1,80003bba <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ba0:	2605                	addiw	a2,a2,1
    80003ba2:	2485                	addiw	s1,s1,1
    80003ba4:	fd4618e3          	bne	a2,s4,80003b74 <balloc+0x80>
    80003ba8:	b759                	j	80003b2e <balloc+0x3a>
  panic("balloc: out of blocks");
    80003baa:	00005517          	auipc	a0,0x5
    80003bae:	af650513          	addi	a0,a0,-1290 # 800086a0 <syscalls+0x110>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	98c080e7          	jalr	-1652(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003bba:	974a                	add	a4,a4,s2
    80003bbc:	8fd5                	or	a5,a5,a3
    80003bbe:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003bc2:	854a                	mv	a0,s2
    80003bc4:	00001097          	auipc	ra,0x1
    80003bc8:	01a080e7          	jalr	26(ra) # 80004bde <log_write>
        brelse(bp);
    80003bcc:	854a                	mv	a0,s2
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	d94080e7          	jalr	-620(ra) # 80003962 <brelse>
  bp = bread(dev, bno);
    80003bd6:	85a6                	mv	a1,s1
    80003bd8:	855e                	mv	a0,s7
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	c58080e7          	jalr	-936(ra) # 80003832 <bread>
    80003be2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003be4:	40000613          	li	a2,1024
    80003be8:	4581                	li	a1,0
    80003bea:	05850513          	addi	a0,a0,88
    80003bee:	ffffd097          	auipc	ra,0xffffd
    80003bf2:	0f2080e7          	jalr	242(ra) # 80000ce0 <memset>
  log_write(bp);
    80003bf6:	854a                	mv	a0,s2
    80003bf8:	00001097          	auipc	ra,0x1
    80003bfc:	fe6080e7          	jalr	-26(ra) # 80004bde <log_write>
  brelse(bp);
    80003c00:	854a                	mv	a0,s2
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	d60080e7          	jalr	-672(ra) # 80003962 <brelse>
}
    80003c0a:	8526                	mv	a0,s1
    80003c0c:	60e6                	ld	ra,88(sp)
    80003c0e:	6446                	ld	s0,80(sp)
    80003c10:	64a6                	ld	s1,72(sp)
    80003c12:	6906                	ld	s2,64(sp)
    80003c14:	79e2                	ld	s3,56(sp)
    80003c16:	7a42                	ld	s4,48(sp)
    80003c18:	7aa2                	ld	s5,40(sp)
    80003c1a:	7b02                	ld	s6,32(sp)
    80003c1c:	6be2                	ld	s7,24(sp)
    80003c1e:	6c42                	ld	s8,16(sp)
    80003c20:	6ca2                	ld	s9,8(sp)
    80003c22:	6125                	addi	sp,sp,96
    80003c24:	8082                	ret

0000000080003c26 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003c26:	7179                	addi	sp,sp,-48
    80003c28:	f406                	sd	ra,40(sp)
    80003c2a:	f022                	sd	s0,32(sp)
    80003c2c:	ec26                	sd	s1,24(sp)
    80003c2e:	e84a                	sd	s2,16(sp)
    80003c30:	e44e                	sd	s3,8(sp)
    80003c32:	e052                	sd	s4,0(sp)
    80003c34:	1800                	addi	s0,sp,48
    80003c36:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003c38:	47ad                	li	a5,11
    80003c3a:	04b7fe63          	bgeu	a5,a1,80003c96 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003c3e:	ff45849b          	addiw	s1,a1,-12
    80003c42:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003c46:	0ff00793          	li	a5,255
    80003c4a:	0ae7e363          	bltu	a5,a4,80003cf0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003c4e:	08052583          	lw	a1,128(a0)
    80003c52:	c5ad                	beqz	a1,80003cbc <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003c54:	00092503          	lw	a0,0(s2)
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	bda080e7          	jalr	-1062(ra) # 80003832 <bread>
    80003c60:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003c62:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003c66:	02049593          	slli	a1,s1,0x20
    80003c6a:	9181                	srli	a1,a1,0x20
    80003c6c:	058a                	slli	a1,a1,0x2
    80003c6e:	00b784b3          	add	s1,a5,a1
    80003c72:	0004a983          	lw	s3,0(s1)
    80003c76:	04098d63          	beqz	s3,80003cd0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003c7a:	8552                	mv	a0,s4
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	ce6080e7          	jalr	-794(ra) # 80003962 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c84:	854e                	mv	a0,s3
    80003c86:	70a2                	ld	ra,40(sp)
    80003c88:	7402                	ld	s0,32(sp)
    80003c8a:	64e2                	ld	s1,24(sp)
    80003c8c:	6942                	ld	s2,16(sp)
    80003c8e:	69a2                	ld	s3,8(sp)
    80003c90:	6a02                	ld	s4,0(sp)
    80003c92:	6145                	addi	sp,sp,48
    80003c94:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003c96:	02059493          	slli	s1,a1,0x20
    80003c9a:	9081                	srli	s1,s1,0x20
    80003c9c:	048a                	slli	s1,s1,0x2
    80003c9e:	94aa                	add	s1,s1,a0
    80003ca0:	0504a983          	lw	s3,80(s1)
    80003ca4:	fe0990e3          	bnez	s3,80003c84 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003ca8:	4108                	lw	a0,0(a0)
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	e4a080e7          	jalr	-438(ra) # 80003af4 <balloc>
    80003cb2:	0005099b          	sext.w	s3,a0
    80003cb6:	0534a823          	sw	s3,80(s1)
    80003cba:	b7e9                	j	80003c84 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003cbc:	4108                	lw	a0,0(a0)
    80003cbe:	00000097          	auipc	ra,0x0
    80003cc2:	e36080e7          	jalr	-458(ra) # 80003af4 <balloc>
    80003cc6:	0005059b          	sext.w	a1,a0
    80003cca:	08b92023          	sw	a1,128(s2)
    80003cce:	b759                	j	80003c54 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003cd0:	00092503          	lw	a0,0(s2)
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	e20080e7          	jalr	-480(ra) # 80003af4 <balloc>
    80003cdc:	0005099b          	sext.w	s3,a0
    80003ce0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003ce4:	8552                	mv	a0,s4
    80003ce6:	00001097          	auipc	ra,0x1
    80003cea:	ef8080e7          	jalr	-264(ra) # 80004bde <log_write>
    80003cee:	b771                	j	80003c7a <bmap+0x54>
  panic("bmap: out of range");
    80003cf0:	00005517          	auipc	a0,0x5
    80003cf4:	9c850513          	addi	a0,a0,-1592 # 800086b8 <syscalls+0x128>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	846080e7          	jalr	-1978(ra) # 8000053e <panic>

0000000080003d00 <iget>:
{
    80003d00:	7179                	addi	sp,sp,-48
    80003d02:	f406                	sd	ra,40(sp)
    80003d04:	f022                	sd	s0,32(sp)
    80003d06:	ec26                	sd	s1,24(sp)
    80003d08:	e84a                	sd	s2,16(sp)
    80003d0a:	e44e                	sd	s3,8(sp)
    80003d0c:	e052                	sd	s4,0(sp)
    80003d0e:	1800                	addi	s0,sp,48
    80003d10:	89aa                	mv	s3,a0
    80003d12:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003d14:	0001c517          	auipc	a0,0x1c
    80003d18:	22c50513          	addi	a0,a0,556 # 8001ff40 <itable>
    80003d1c:	ffffd097          	auipc	ra,0xffffd
    80003d20:	ec8080e7          	jalr	-312(ra) # 80000be4 <acquire>
  empty = 0;
    80003d24:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d26:	0001c497          	auipc	s1,0x1c
    80003d2a:	23248493          	addi	s1,s1,562 # 8001ff58 <itable+0x18>
    80003d2e:	0001e697          	auipc	a3,0x1e
    80003d32:	cba68693          	addi	a3,a3,-838 # 800219e8 <log>
    80003d36:	a039                	j	80003d44 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d38:	02090b63          	beqz	s2,80003d6e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d3c:	08848493          	addi	s1,s1,136
    80003d40:	02d48a63          	beq	s1,a3,80003d74 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003d44:	449c                	lw	a5,8(s1)
    80003d46:	fef059e3          	blez	a5,80003d38 <iget+0x38>
    80003d4a:	4098                	lw	a4,0(s1)
    80003d4c:	ff3716e3          	bne	a4,s3,80003d38 <iget+0x38>
    80003d50:	40d8                	lw	a4,4(s1)
    80003d52:	ff4713e3          	bne	a4,s4,80003d38 <iget+0x38>
      ip->ref++;
    80003d56:	2785                	addiw	a5,a5,1
    80003d58:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003d5a:	0001c517          	auipc	a0,0x1c
    80003d5e:	1e650513          	addi	a0,a0,486 # 8001ff40 <itable>
    80003d62:	ffffd097          	auipc	ra,0xffffd
    80003d66:	f36080e7          	jalr	-202(ra) # 80000c98 <release>
      return ip;
    80003d6a:	8926                	mv	s2,s1
    80003d6c:	a03d                	j	80003d9a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d6e:	f7f9                	bnez	a5,80003d3c <iget+0x3c>
    80003d70:	8926                	mv	s2,s1
    80003d72:	b7e9                	j	80003d3c <iget+0x3c>
  if(empty == 0)
    80003d74:	02090c63          	beqz	s2,80003dac <iget+0xac>
  ip->dev = dev;
    80003d78:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003d7c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d80:	4785                	li	a5,1
    80003d82:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d86:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d8a:	0001c517          	auipc	a0,0x1c
    80003d8e:	1b650513          	addi	a0,a0,438 # 8001ff40 <itable>
    80003d92:	ffffd097          	auipc	ra,0xffffd
    80003d96:	f06080e7          	jalr	-250(ra) # 80000c98 <release>
}
    80003d9a:	854a                	mv	a0,s2
    80003d9c:	70a2                	ld	ra,40(sp)
    80003d9e:	7402                	ld	s0,32(sp)
    80003da0:	64e2                	ld	s1,24(sp)
    80003da2:	6942                	ld	s2,16(sp)
    80003da4:	69a2                	ld	s3,8(sp)
    80003da6:	6a02                	ld	s4,0(sp)
    80003da8:	6145                	addi	sp,sp,48
    80003daa:	8082                	ret
    panic("iget: no inodes");
    80003dac:	00005517          	auipc	a0,0x5
    80003db0:	92450513          	addi	a0,a0,-1756 # 800086d0 <syscalls+0x140>
    80003db4:	ffffc097          	auipc	ra,0xffffc
    80003db8:	78a080e7          	jalr	1930(ra) # 8000053e <panic>

0000000080003dbc <fsinit>:
fsinit(int dev) {
    80003dbc:	7179                	addi	sp,sp,-48
    80003dbe:	f406                	sd	ra,40(sp)
    80003dc0:	f022                	sd	s0,32(sp)
    80003dc2:	ec26                	sd	s1,24(sp)
    80003dc4:	e84a                	sd	s2,16(sp)
    80003dc6:	e44e                	sd	s3,8(sp)
    80003dc8:	1800                	addi	s0,sp,48
    80003dca:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003dcc:	4585                	li	a1,1
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	a64080e7          	jalr	-1436(ra) # 80003832 <bread>
    80003dd6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003dd8:	0001c997          	auipc	s3,0x1c
    80003ddc:	14898993          	addi	s3,s3,328 # 8001ff20 <sb>
    80003de0:	02000613          	li	a2,32
    80003de4:	05850593          	addi	a1,a0,88
    80003de8:	854e                	mv	a0,s3
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	f56080e7          	jalr	-170(ra) # 80000d40 <memmove>
  brelse(bp);
    80003df2:	8526                	mv	a0,s1
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	b6e080e7          	jalr	-1170(ra) # 80003962 <brelse>
  if(sb.magic != FSMAGIC)
    80003dfc:	0009a703          	lw	a4,0(s3)
    80003e00:	102037b7          	lui	a5,0x10203
    80003e04:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003e08:	02f71263          	bne	a4,a5,80003e2c <fsinit+0x70>
  initlog(dev, &sb);
    80003e0c:	0001c597          	auipc	a1,0x1c
    80003e10:	11458593          	addi	a1,a1,276 # 8001ff20 <sb>
    80003e14:	854a                	mv	a0,s2
    80003e16:	00001097          	auipc	ra,0x1
    80003e1a:	b4c080e7          	jalr	-1204(ra) # 80004962 <initlog>
}
    80003e1e:	70a2                	ld	ra,40(sp)
    80003e20:	7402                	ld	s0,32(sp)
    80003e22:	64e2                	ld	s1,24(sp)
    80003e24:	6942                	ld	s2,16(sp)
    80003e26:	69a2                	ld	s3,8(sp)
    80003e28:	6145                	addi	sp,sp,48
    80003e2a:	8082                	ret
    panic("invalid file system");
    80003e2c:	00005517          	auipc	a0,0x5
    80003e30:	8b450513          	addi	a0,a0,-1868 # 800086e0 <syscalls+0x150>
    80003e34:	ffffc097          	auipc	ra,0xffffc
    80003e38:	70a080e7          	jalr	1802(ra) # 8000053e <panic>

0000000080003e3c <iinit>:
{
    80003e3c:	7179                	addi	sp,sp,-48
    80003e3e:	f406                	sd	ra,40(sp)
    80003e40:	f022                	sd	s0,32(sp)
    80003e42:	ec26                	sd	s1,24(sp)
    80003e44:	e84a                	sd	s2,16(sp)
    80003e46:	e44e                	sd	s3,8(sp)
    80003e48:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003e4a:	00005597          	auipc	a1,0x5
    80003e4e:	8ae58593          	addi	a1,a1,-1874 # 800086f8 <syscalls+0x168>
    80003e52:	0001c517          	auipc	a0,0x1c
    80003e56:	0ee50513          	addi	a0,a0,238 # 8001ff40 <itable>
    80003e5a:	ffffd097          	auipc	ra,0xffffd
    80003e5e:	cfa080e7          	jalr	-774(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003e62:	0001c497          	auipc	s1,0x1c
    80003e66:	10648493          	addi	s1,s1,262 # 8001ff68 <itable+0x28>
    80003e6a:	0001e997          	auipc	s3,0x1e
    80003e6e:	b8e98993          	addi	s3,s3,-1138 # 800219f8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003e72:	00005917          	auipc	s2,0x5
    80003e76:	88e90913          	addi	s2,s2,-1906 # 80008700 <syscalls+0x170>
    80003e7a:	85ca                	mv	a1,s2
    80003e7c:	8526                	mv	a0,s1
    80003e7e:	00001097          	auipc	ra,0x1
    80003e82:	e46080e7          	jalr	-442(ra) # 80004cc4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e86:	08848493          	addi	s1,s1,136
    80003e8a:	ff3498e3          	bne	s1,s3,80003e7a <iinit+0x3e>
}
    80003e8e:	70a2                	ld	ra,40(sp)
    80003e90:	7402                	ld	s0,32(sp)
    80003e92:	64e2                	ld	s1,24(sp)
    80003e94:	6942                	ld	s2,16(sp)
    80003e96:	69a2                	ld	s3,8(sp)
    80003e98:	6145                	addi	sp,sp,48
    80003e9a:	8082                	ret

0000000080003e9c <ialloc>:
{
    80003e9c:	715d                	addi	sp,sp,-80
    80003e9e:	e486                	sd	ra,72(sp)
    80003ea0:	e0a2                	sd	s0,64(sp)
    80003ea2:	fc26                	sd	s1,56(sp)
    80003ea4:	f84a                	sd	s2,48(sp)
    80003ea6:	f44e                	sd	s3,40(sp)
    80003ea8:	f052                	sd	s4,32(sp)
    80003eaa:	ec56                	sd	s5,24(sp)
    80003eac:	e85a                	sd	s6,16(sp)
    80003eae:	e45e                	sd	s7,8(sp)
    80003eb0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003eb2:	0001c717          	auipc	a4,0x1c
    80003eb6:	07a72703          	lw	a4,122(a4) # 8001ff2c <sb+0xc>
    80003eba:	4785                	li	a5,1
    80003ebc:	04e7fa63          	bgeu	a5,a4,80003f10 <ialloc+0x74>
    80003ec0:	8aaa                	mv	s5,a0
    80003ec2:	8bae                	mv	s7,a1
    80003ec4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ec6:	0001ca17          	auipc	s4,0x1c
    80003eca:	05aa0a13          	addi	s4,s4,90 # 8001ff20 <sb>
    80003ece:	00048b1b          	sext.w	s6,s1
    80003ed2:	0044d593          	srli	a1,s1,0x4
    80003ed6:	018a2783          	lw	a5,24(s4)
    80003eda:	9dbd                	addw	a1,a1,a5
    80003edc:	8556                	mv	a0,s5
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	954080e7          	jalr	-1708(ra) # 80003832 <bread>
    80003ee6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ee8:	05850993          	addi	s3,a0,88
    80003eec:	00f4f793          	andi	a5,s1,15
    80003ef0:	079a                	slli	a5,a5,0x6
    80003ef2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ef4:	00099783          	lh	a5,0(s3)
    80003ef8:	c785                	beqz	a5,80003f20 <ialloc+0x84>
    brelse(bp);
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	a68080e7          	jalr	-1432(ra) # 80003962 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f02:	0485                	addi	s1,s1,1
    80003f04:	00ca2703          	lw	a4,12(s4)
    80003f08:	0004879b          	sext.w	a5,s1
    80003f0c:	fce7e1e3          	bltu	a5,a4,80003ece <ialloc+0x32>
  panic("ialloc: no inodes");
    80003f10:	00004517          	auipc	a0,0x4
    80003f14:	7f850513          	addi	a0,a0,2040 # 80008708 <syscalls+0x178>
    80003f18:	ffffc097          	auipc	ra,0xffffc
    80003f1c:	626080e7          	jalr	1574(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003f20:	04000613          	li	a2,64
    80003f24:	4581                	li	a1,0
    80003f26:	854e                	mv	a0,s3
    80003f28:	ffffd097          	auipc	ra,0xffffd
    80003f2c:	db8080e7          	jalr	-584(ra) # 80000ce0 <memset>
      dip->type = type;
    80003f30:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003f34:	854a                	mv	a0,s2
    80003f36:	00001097          	auipc	ra,0x1
    80003f3a:	ca8080e7          	jalr	-856(ra) # 80004bde <log_write>
      brelse(bp);
    80003f3e:	854a                	mv	a0,s2
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	a22080e7          	jalr	-1502(ra) # 80003962 <brelse>
      return iget(dev, inum);
    80003f48:	85da                	mv	a1,s6
    80003f4a:	8556                	mv	a0,s5
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	db4080e7          	jalr	-588(ra) # 80003d00 <iget>
}
    80003f54:	60a6                	ld	ra,72(sp)
    80003f56:	6406                	ld	s0,64(sp)
    80003f58:	74e2                	ld	s1,56(sp)
    80003f5a:	7942                	ld	s2,48(sp)
    80003f5c:	79a2                	ld	s3,40(sp)
    80003f5e:	7a02                	ld	s4,32(sp)
    80003f60:	6ae2                	ld	s5,24(sp)
    80003f62:	6b42                	ld	s6,16(sp)
    80003f64:	6ba2                	ld	s7,8(sp)
    80003f66:	6161                	addi	sp,sp,80
    80003f68:	8082                	ret

0000000080003f6a <iupdate>:
{
    80003f6a:	1101                	addi	sp,sp,-32
    80003f6c:	ec06                	sd	ra,24(sp)
    80003f6e:	e822                	sd	s0,16(sp)
    80003f70:	e426                	sd	s1,8(sp)
    80003f72:	e04a                	sd	s2,0(sp)
    80003f74:	1000                	addi	s0,sp,32
    80003f76:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f78:	415c                	lw	a5,4(a0)
    80003f7a:	0047d79b          	srliw	a5,a5,0x4
    80003f7e:	0001c597          	auipc	a1,0x1c
    80003f82:	fba5a583          	lw	a1,-70(a1) # 8001ff38 <sb+0x18>
    80003f86:	9dbd                	addw	a1,a1,a5
    80003f88:	4108                	lw	a0,0(a0)
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	8a8080e7          	jalr	-1880(ra) # 80003832 <bread>
    80003f92:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f94:	05850793          	addi	a5,a0,88
    80003f98:	40c8                	lw	a0,4(s1)
    80003f9a:	893d                	andi	a0,a0,15
    80003f9c:	051a                	slli	a0,a0,0x6
    80003f9e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003fa0:	04449703          	lh	a4,68(s1)
    80003fa4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003fa8:	04649703          	lh	a4,70(s1)
    80003fac:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003fb0:	04849703          	lh	a4,72(s1)
    80003fb4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003fb8:	04a49703          	lh	a4,74(s1)
    80003fbc:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003fc0:	44f8                	lw	a4,76(s1)
    80003fc2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003fc4:	03400613          	li	a2,52
    80003fc8:	05048593          	addi	a1,s1,80
    80003fcc:	0531                	addi	a0,a0,12
    80003fce:	ffffd097          	auipc	ra,0xffffd
    80003fd2:	d72080e7          	jalr	-654(ra) # 80000d40 <memmove>
  log_write(bp);
    80003fd6:	854a                	mv	a0,s2
    80003fd8:	00001097          	auipc	ra,0x1
    80003fdc:	c06080e7          	jalr	-1018(ra) # 80004bde <log_write>
  brelse(bp);
    80003fe0:	854a                	mv	a0,s2
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	980080e7          	jalr	-1664(ra) # 80003962 <brelse>
}
    80003fea:	60e2                	ld	ra,24(sp)
    80003fec:	6442                	ld	s0,16(sp)
    80003fee:	64a2                	ld	s1,8(sp)
    80003ff0:	6902                	ld	s2,0(sp)
    80003ff2:	6105                	addi	sp,sp,32
    80003ff4:	8082                	ret

0000000080003ff6 <idup>:
{
    80003ff6:	1101                	addi	sp,sp,-32
    80003ff8:	ec06                	sd	ra,24(sp)
    80003ffa:	e822                	sd	s0,16(sp)
    80003ffc:	e426                	sd	s1,8(sp)
    80003ffe:	1000                	addi	s0,sp,32
    80004000:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004002:	0001c517          	auipc	a0,0x1c
    80004006:	f3e50513          	addi	a0,a0,-194 # 8001ff40 <itable>
    8000400a:	ffffd097          	auipc	ra,0xffffd
    8000400e:	bda080e7          	jalr	-1062(ra) # 80000be4 <acquire>
  ip->ref++;
    80004012:	449c                	lw	a5,8(s1)
    80004014:	2785                	addiw	a5,a5,1
    80004016:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004018:	0001c517          	auipc	a0,0x1c
    8000401c:	f2850513          	addi	a0,a0,-216 # 8001ff40 <itable>
    80004020:	ffffd097          	auipc	ra,0xffffd
    80004024:	c78080e7          	jalr	-904(ra) # 80000c98 <release>
}
    80004028:	8526                	mv	a0,s1
    8000402a:	60e2                	ld	ra,24(sp)
    8000402c:	6442                	ld	s0,16(sp)
    8000402e:	64a2                	ld	s1,8(sp)
    80004030:	6105                	addi	sp,sp,32
    80004032:	8082                	ret

0000000080004034 <ilock>:
{
    80004034:	1101                	addi	sp,sp,-32
    80004036:	ec06                	sd	ra,24(sp)
    80004038:	e822                	sd	s0,16(sp)
    8000403a:	e426                	sd	s1,8(sp)
    8000403c:	e04a                	sd	s2,0(sp)
    8000403e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004040:	c115                	beqz	a0,80004064 <ilock+0x30>
    80004042:	84aa                	mv	s1,a0
    80004044:	451c                	lw	a5,8(a0)
    80004046:	00f05f63          	blez	a5,80004064 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000404a:	0541                	addi	a0,a0,16
    8000404c:	00001097          	auipc	ra,0x1
    80004050:	cb2080e7          	jalr	-846(ra) # 80004cfe <acquiresleep>
  if(ip->valid == 0){
    80004054:	40bc                	lw	a5,64(s1)
    80004056:	cf99                	beqz	a5,80004074 <ilock+0x40>
}
    80004058:	60e2                	ld	ra,24(sp)
    8000405a:	6442                	ld	s0,16(sp)
    8000405c:	64a2                	ld	s1,8(sp)
    8000405e:	6902                	ld	s2,0(sp)
    80004060:	6105                	addi	sp,sp,32
    80004062:	8082                	ret
    panic("ilock");
    80004064:	00004517          	auipc	a0,0x4
    80004068:	6bc50513          	addi	a0,a0,1724 # 80008720 <syscalls+0x190>
    8000406c:	ffffc097          	auipc	ra,0xffffc
    80004070:	4d2080e7          	jalr	1234(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004074:	40dc                	lw	a5,4(s1)
    80004076:	0047d79b          	srliw	a5,a5,0x4
    8000407a:	0001c597          	auipc	a1,0x1c
    8000407e:	ebe5a583          	lw	a1,-322(a1) # 8001ff38 <sb+0x18>
    80004082:	9dbd                	addw	a1,a1,a5
    80004084:	4088                	lw	a0,0(s1)
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	7ac080e7          	jalr	1964(ra) # 80003832 <bread>
    8000408e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004090:	05850593          	addi	a1,a0,88
    80004094:	40dc                	lw	a5,4(s1)
    80004096:	8bbd                	andi	a5,a5,15
    80004098:	079a                	slli	a5,a5,0x6
    8000409a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000409c:	00059783          	lh	a5,0(a1)
    800040a0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800040a4:	00259783          	lh	a5,2(a1)
    800040a8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800040ac:	00459783          	lh	a5,4(a1)
    800040b0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800040b4:	00659783          	lh	a5,6(a1)
    800040b8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800040bc:	459c                	lw	a5,8(a1)
    800040be:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800040c0:	03400613          	li	a2,52
    800040c4:	05b1                	addi	a1,a1,12
    800040c6:	05048513          	addi	a0,s1,80
    800040ca:	ffffd097          	auipc	ra,0xffffd
    800040ce:	c76080e7          	jalr	-906(ra) # 80000d40 <memmove>
    brelse(bp);
    800040d2:	854a                	mv	a0,s2
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	88e080e7          	jalr	-1906(ra) # 80003962 <brelse>
    ip->valid = 1;
    800040dc:	4785                	li	a5,1
    800040de:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800040e0:	04449783          	lh	a5,68(s1)
    800040e4:	fbb5                	bnez	a5,80004058 <ilock+0x24>
      panic("ilock: no type");
    800040e6:	00004517          	auipc	a0,0x4
    800040ea:	64250513          	addi	a0,a0,1602 # 80008728 <syscalls+0x198>
    800040ee:	ffffc097          	auipc	ra,0xffffc
    800040f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>

00000000800040f6 <iunlock>:
{
    800040f6:	1101                	addi	sp,sp,-32
    800040f8:	ec06                	sd	ra,24(sp)
    800040fa:	e822                	sd	s0,16(sp)
    800040fc:	e426                	sd	s1,8(sp)
    800040fe:	e04a                	sd	s2,0(sp)
    80004100:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004102:	c905                	beqz	a0,80004132 <iunlock+0x3c>
    80004104:	84aa                	mv	s1,a0
    80004106:	01050913          	addi	s2,a0,16
    8000410a:	854a                	mv	a0,s2
    8000410c:	00001097          	auipc	ra,0x1
    80004110:	c8c080e7          	jalr	-884(ra) # 80004d98 <holdingsleep>
    80004114:	cd19                	beqz	a0,80004132 <iunlock+0x3c>
    80004116:	449c                	lw	a5,8(s1)
    80004118:	00f05d63          	blez	a5,80004132 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000411c:	854a                	mv	a0,s2
    8000411e:	00001097          	auipc	ra,0x1
    80004122:	c36080e7          	jalr	-970(ra) # 80004d54 <releasesleep>
}
    80004126:	60e2                	ld	ra,24(sp)
    80004128:	6442                	ld	s0,16(sp)
    8000412a:	64a2                	ld	s1,8(sp)
    8000412c:	6902                	ld	s2,0(sp)
    8000412e:	6105                	addi	sp,sp,32
    80004130:	8082                	ret
    panic("iunlock");
    80004132:	00004517          	auipc	a0,0x4
    80004136:	60650513          	addi	a0,a0,1542 # 80008738 <syscalls+0x1a8>
    8000413a:	ffffc097          	auipc	ra,0xffffc
    8000413e:	404080e7          	jalr	1028(ra) # 8000053e <panic>

0000000080004142 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004142:	7179                	addi	sp,sp,-48
    80004144:	f406                	sd	ra,40(sp)
    80004146:	f022                	sd	s0,32(sp)
    80004148:	ec26                	sd	s1,24(sp)
    8000414a:	e84a                	sd	s2,16(sp)
    8000414c:	e44e                	sd	s3,8(sp)
    8000414e:	e052                	sd	s4,0(sp)
    80004150:	1800                	addi	s0,sp,48
    80004152:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004154:	05050493          	addi	s1,a0,80
    80004158:	08050913          	addi	s2,a0,128
    8000415c:	a021                	j	80004164 <itrunc+0x22>
    8000415e:	0491                	addi	s1,s1,4
    80004160:	01248d63          	beq	s1,s2,8000417a <itrunc+0x38>
    if(ip->addrs[i]){
    80004164:	408c                	lw	a1,0(s1)
    80004166:	dde5                	beqz	a1,8000415e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004168:	0009a503          	lw	a0,0(s3)
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	90c080e7          	jalr	-1780(ra) # 80003a78 <bfree>
      ip->addrs[i] = 0;
    80004174:	0004a023          	sw	zero,0(s1)
    80004178:	b7dd                	j	8000415e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000417a:	0809a583          	lw	a1,128(s3)
    8000417e:	e185                	bnez	a1,8000419e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004180:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004184:	854e                	mv	a0,s3
    80004186:	00000097          	auipc	ra,0x0
    8000418a:	de4080e7          	jalr	-540(ra) # 80003f6a <iupdate>
}
    8000418e:	70a2                	ld	ra,40(sp)
    80004190:	7402                	ld	s0,32(sp)
    80004192:	64e2                	ld	s1,24(sp)
    80004194:	6942                	ld	s2,16(sp)
    80004196:	69a2                	ld	s3,8(sp)
    80004198:	6a02                	ld	s4,0(sp)
    8000419a:	6145                	addi	sp,sp,48
    8000419c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000419e:	0009a503          	lw	a0,0(s3)
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	690080e7          	jalr	1680(ra) # 80003832 <bread>
    800041aa:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800041ac:	05850493          	addi	s1,a0,88
    800041b0:	45850913          	addi	s2,a0,1112
    800041b4:	a811                	j	800041c8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800041b6:	0009a503          	lw	a0,0(s3)
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	8be080e7          	jalr	-1858(ra) # 80003a78 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800041c2:	0491                	addi	s1,s1,4
    800041c4:	01248563          	beq	s1,s2,800041ce <itrunc+0x8c>
      if(a[j])
    800041c8:	408c                	lw	a1,0(s1)
    800041ca:	dde5                	beqz	a1,800041c2 <itrunc+0x80>
    800041cc:	b7ed                	j	800041b6 <itrunc+0x74>
    brelse(bp);
    800041ce:	8552                	mv	a0,s4
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	792080e7          	jalr	1938(ra) # 80003962 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800041d8:	0809a583          	lw	a1,128(s3)
    800041dc:	0009a503          	lw	a0,0(s3)
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	898080e7          	jalr	-1896(ra) # 80003a78 <bfree>
    ip->addrs[NDIRECT] = 0;
    800041e8:	0809a023          	sw	zero,128(s3)
    800041ec:	bf51                	j	80004180 <itrunc+0x3e>

00000000800041ee <iput>:
{
    800041ee:	1101                	addi	sp,sp,-32
    800041f0:	ec06                	sd	ra,24(sp)
    800041f2:	e822                	sd	s0,16(sp)
    800041f4:	e426                	sd	s1,8(sp)
    800041f6:	e04a                	sd	s2,0(sp)
    800041f8:	1000                	addi	s0,sp,32
    800041fa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800041fc:	0001c517          	auipc	a0,0x1c
    80004200:	d4450513          	addi	a0,a0,-700 # 8001ff40 <itable>
    80004204:	ffffd097          	auipc	ra,0xffffd
    80004208:	9e0080e7          	jalr	-1568(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000420c:	4498                	lw	a4,8(s1)
    8000420e:	4785                	li	a5,1
    80004210:	02f70363          	beq	a4,a5,80004236 <iput+0x48>
  ip->ref--;
    80004214:	449c                	lw	a5,8(s1)
    80004216:	37fd                	addiw	a5,a5,-1
    80004218:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000421a:	0001c517          	auipc	a0,0x1c
    8000421e:	d2650513          	addi	a0,a0,-730 # 8001ff40 <itable>
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	a76080e7          	jalr	-1418(ra) # 80000c98 <release>
}
    8000422a:	60e2                	ld	ra,24(sp)
    8000422c:	6442                	ld	s0,16(sp)
    8000422e:	64a2                	ld	s1,8(sp)
    80004230:	6902                	ld	s2,0(sp)
    80004232:	6105                	addi	sp,sp,32
    80004234:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004236:	40bc                	lw	a5,64(s1)
    80004238:	dff1                	beqz	a5,80004214 <iput+0x26>
    8000423a:	04a49783          	lh	a5,74(s1)
    8000423e:	fbf9                	bnez	a5,80004214 <iput+0x26>
    acquiresleep(&ip->lock);
    80004240:	01048913          	addi	s2,s1,16
    80004244:	854a                	mv	a0,s2
    80004246:	00001097          	auipc	ra,0x1
    8000424a:	ab8080e7          	jalr	-1352(ra) # 80004cfe <acquiresleep>
    release(&itable.lock);
    8000424e:	0001c517          	auipc	a0,0x1c
    80004252:	cf250513          	addi	a0,a0,-782 # 8001ff40 <itable>
    80004256:	ffffd097          	auipc	ra,0xffffd
    8000425a:	a42080e7          	jalr	-1470(ra) # 80000c98 <release>
    itrunc(ip);
    8000425e:	8526                	mv	a0,s1
    80004260:	00000097          	auipc	ra,0x0
    80004264:	ee2080e7          	jalr	-286(ra) # 80004142 <itrunc>
    ip->type = 0;
    80004268:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000426c:	8526                	mv	a0,s1
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	cfc080e7          	jalr	-772(ra) # 80003f6a <iupdate>
    ip->valid = 0;
    80004276:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000427a:	854a                	mv	a0,s2
    8000427c:	00001097          	auipc	ra,0x1
    80004280:	ad8080e7          	jalr	-1320(ra) # 80004d54 <releasesleep>
    acquire(&itable.lock);
    80004284:	0001c517          	auipc	a0,0x1c
    80004288:	cbc50513          	addi	a0,a0,-836 # 8001ff40 <itable>
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	958080e7          	jalr	-1704(ra) # 80000be4 <acquire>
    80004294:	b741                	j	80004214 <iput+0x26>

0000000080004296 <iunlockput>:
{
    80004296:	1101                	addi	sp,sp,-32
    80004298:	ec06                	sd	ra,24(sp)
    8000429a:	e822                	sd	s0,16(sp)
    8000429c:	e426                	sd	s1,8(sp)
    8000429e:	1000                	addi	s0,sp,32
    800042a0:	84aa                	mv	s1,a0
  iunlock(ip);
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	e54080e7          	jalr	-428(ra) # 800040f6 <iunlock>
  iput(ip);
    800042aa:	8526                	mv	a0,s1
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	f42080e7          	jalr	-190(ra) # 800041ee <iput>
}
    800042b4:	60e2                	ld	ra,24(sp)
    800042b6:	6442                	ld	s0,16(sp)
    800042b8:	64a2                	ld	s1,8(sp)
    800042ba:	6105                	addi	sp,sp,32
    800042bc:	8082                	ret

00000000800042be <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800042be:	1141                	addi	sp,sp,-16
    800042c0:	e422                	sd	s0,8(sp)
    800042c2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800042c4:	411c                	lw	a5,0(a0)
    800042c6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800042c8:	415c                	lw	a5,4(a0)
    800042ca:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800042cc:	04451783          	lh	a5,68(a0)
    800042d0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800042d4:	04a51783          	lh	a5,74(a0)
    800042d8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800042dc:	04c56783          	lwu	a5,76(a0)
    800042e0:	e99c                	sd	a5,16(a1)
}
    800042e2:	6422                	ld	s0,8(sp)
    800042e4:	0141                	addi	sp,sp,16
    800042e6:	8082                	ret

00000000800042e8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042e8:	457c                	lw	a5,76(a0)
    800042ea:	0ed7e963          	bltu	a5,a3,800043dc <readi+0xf4>
{
    800042ee:	7159                	addi	sp,sp,-112
    800042f0:	f486                	sd	ra,104(sp)
    800042f2:	f0a2                	sd	s0,96(sp)
    800042f4:	eca6                	sd	s1,88(sp)
    800042f6:	e8ca                	sd	s2,80(sp)
    800042f8:	e4ce                	sd	s3,72(sp)
    800042fa:	e0d2                	sd	s4,64(sp)
    800042fc:	fc56                	sd	s5,56(sp)
    800042fe:	f85a                	sd	s6,48(sp)
    80004300:	f45e                	sd	s7,40(sp)
    80004302:	f062                	sd	s8,32(sp)
    80004304:	ec66                	sd	s9,24(sp)
    80004306:	e86a                	sd	s10,16(sp)
    80004308:	e46e                	sd	s11,8(sp)
    8000430a:	1880                	addi	s0,sp,112
    8000430c:	8baa                	mv	s7,a0
    8000430e:	8c2e                	mv	s8,a1
    80004310:	8ab2                	mv	s5,a2
    80004312:	84b6                	mv	s1,a3
    80004314:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004316:	9f35                	addw	a4,a4,a3
    return 0;
    80004318:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000431a:	0ad76063          	bltu	a4,a3,800043ba <readi+0xd2>
  if(off + n > ip->size)
    8000431e:	00e7f463          	bgeu	a5,a4,80004326 <readi+0x3e>
    n = ip->size - off;
    80004322:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004326:	0a0b0963          	beqz	s6,800043d8 <readi+0xf0>
    8000432a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000432c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004330:	5cfd                	li	s9,-1
    80004332:	a82d                	j	8000436c <readi+0x84>
    80004334:	020a1d93          	slli	s11,s4,0x20
    80004338:	020ddd93          	srli	s11,s11,0x20
    8000433c:	05890613          	addi	a2,s2,88
    80004340:	86ee                	mv	a3,s11
    80004342:	963a                	add	a2,a2,a4
    80004344:	85d6                	mv	a1,s5
    80004346:	8562                	mv	a0,s8
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	ae4080e7          	jalr	-1308(ra) # 80002e2c <either_copyout>
    80004350:	05950d63          	beq	a0,s9,800043aa <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004354:	854a                	mv	a0,s2
    80004356:	fffff097          	auipc	ra,0xfffff
    8000435a:	60c080e7          	jalr	1548(ra) # 80003962 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000435e:	013a09bb          	addw	s3,s4,s3
    80004362:	009a04bb          	addw	s1,s4,s1
    80004366:	9aee                	add	s5,s5,s11
    80004368:	0569f763          	bgeu	s3,s6,800043b6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000436c:	000ba903          	lw	s2,0(s7)
    80004370:	00a4d59b          	srliw	a1,s1,0xa
    80004374:	855e                	mv	a0,s7
    80004376:	00000097          	auipc	ra,0x0
    8000437a:	8b0080e7          	jalr	-1872(ra) # 80003c26 <bmap>
    8000437e:	0005059b          	sext.w	a1,a0
    80004382:	854a                	mv	a0,s2
    80004384:	fffff097          	auipc	ra,0xfffff
    80004388:	4ae080e7          	jalr	1198(ra) # 80003832 <bread>
    8000438c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000438e:	3ff4f713          	andi	a4,s1,1023
    80004392:	40ed07bb          	subw	a5,s10,a4
    80004396:	413b06bb          	subw	a3,s6,s3
    8000439a:	8a3e                	mv	s4,a5
    8000439c:	2781                	sext.w	a5,a5
    8000439e:	0006861b          	sext.w	a2,a3
    800043a2:	f8f679e3          	bgeu	a2,a5,80004334 <readi+0x4c>
    800043a6:	8a36                	mv	s4,a3
    800043a8:	b771                	j	80004334 <readi+0x4c>
      brelse(bp);
    800043aa:	854a                	mv	a0,s2
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	5b6080e7          	jalr	1462(ra) # 80003962 <brelse>
      tot = -1;
    800043b4:	59fd                	li	s3,-1
  }
  return tot;
    800043b6:	0009851b          	sext.w	a0,s3
}
    800043ba:	70a6                	ld	ra,104(sp)
    800043bc:	7406                	ld	s0,96(sp)
    800043be:	64e6                	ld	s1,88(sp)
    800043c0:	6946                	ld	s2,80(sp)
    800043c2:	69a6                	ld	s3,72(sp)
    800043c4:	6a06                	ld	s4,64(sp)
    800043c6:	7ae2                	ld	s5,56(sp)
    800043c8:	7b42                	ld	s6,48(sp)
    800043ca:	7ba2                	ld	s7,40(sp)
    800043cc:	7c02                	ld	s8,32(sp)
    800043ce:	6ce2                	ld	s9,24(sp)
    800043d0:	6d42                	ld	s10,16(sp)
    800043d2:	6da2                	ld	s11,8(sp)
    800043d4:	6165                	addi	sp,sp,112
    800043d6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043d8:	89da                	mv	s3,s6
    800043da:	bff1                	j	800043b6 <readi+0xce>
    return 0;
    800043dc:	4501                	li	a0,0
}
    800043de:	8082                	ret

00000000800043e0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800043e0:	457c                	lw	a5,76(a0)
    800043e2:	10d7e863          	bltu	a5,a3,800044f2 <writei+0x112>
{
    800043e6:	7159                	addi	sp,sp,-112
    800043e8:	f486                	sd	ra,104(sp)
    800043ea:	f0a2                	sd	s0,96(sp)
    800043ec:	eca6                	sd	s1,88(sp)
    800043ee:	e8ca                	sd	s2,80(sp)
    800043f0:	e4ce                	sd	s3,72(sp)
    800043f2:	e0d2                	sd	s4,64(sp)
    800043f4:	fc56                	sd	s5,56(sp)
    800043f6:	f85a                	sd	s6,48(sp)
    800043f8:	f45e                	sd	s7,40(sp)
    800043fa:	f062                	sd	s8,32(sp)
    800043fc:	ec66                	sd	s9,24(sp)
    800043fe:	e86a                	sd	s10,16(sp)
    80004400:	e46e                	sd	s11,8(sp)
    80004402:	1880                	addi	s0,sp,112
    80004404:	8b2a                	mv	s6,a0
    80004406:	8c2e                	mv	s8,a1
    80004408:	8ab2                	mv	s5,a2
    8000440a:	8936                	mv	s2,a3
    8000440c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000440e:	00e687bb          	addw	a5,a3,a4
    80004412:	0ed7e263          	bltu	a5,a3,800044f6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004416:	00043737          	lui	a4,0x43
    8000441a:	0ef76063          	bltu	a4,a5,800044fa <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000441e:	0c0b8863          	beqz	s7,800044ee <writei+0x10e>
    80004422:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004424:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004428:	5cfd                	li	s9,-1
    8000442a:	a091                	j	8000446e <writei+0x8e>
    8000442c:	02099d93          	slli	s11,s3,0x20
    80004430:	020ddd93          	srli	s11,s11,0x20
    80004434:	05848513          	addi	a0,s1,88
    80004438:	86ee                	mv	a3,s11
    8000443a:	8656                	mv	a2,s5
    8000443c:	85e2                	mv	a1,s8
    8000443e:	953a                	add	a0,a0,a4
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	a42080e7          	jalr	-1470(ra) # 80002e82 <either_copyin>
    80004448:	07950263          	beq	a0,s9,800044ac <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000444c:	8526                	mv	a0,s1
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	790080e7          	jalr	1936(ra) # 80004bde <log_write>
    brelse(bp);
    80004456:	8526                	mv	a0,s1
    80004458:	fffff097          	auipc	ra,0xfffff
    8000445c:	50a080e7          	jalr	1290(ra) # 80003962 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004460:	01498a3b          	addw	s4,s3,s4
    80004464:	0129893b          	addw	s2,s3,s2
    80004468:	9aee                	add	s5,s5,s11
    8000446a:	057a7663          	bgeu	s4,s7,800044b6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000446e:	000b2483          	lw	s1,0(s6)
    80004472:	00a9559b          	srliw	a1,s2,0xa
    80004476:	855a                	mv	a0,s6
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	7ae080e7          	jalr	1966(ra) # 80003c26 <bmap>
    80004480:	0005059b          	sext.w	a1,a0
    80004484:	8526                	mv	a0,s1
    80004486:	fffff097          	auipc	ra,0xfffff
    8000448a:	3ac080e7          	jalr	940(ra) # 80003832 <bread>
    8000448e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004490:	3ff97713          	andi	a4,s2,1023
    80004494:	40ed07bb          	subw	a5,s10,a4
    80004498:	414b86bb          	subw	a3,s7,s4
    8000449c:	89be                	mv	s3,a5
    8000449e:	2781                	sext.w	a5,a5
    800044a0:	0006861b          	sext.w	a2,a3
    800044a4:	f8f674e3          	bgeu	a2,a5,8000442c <writei+0x4c>
    800044a8:	89b6                	mv	s3,a3
    800044aa:	b749                	j	8000442c <writei+0x4c>
      brelse(bp);
    800044ac:	8526                	mv	a0,s1
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	4b4080e7          	jalr	1204(ra) # 80003962 <brelse>
  }

  if(off > ip->size)
    800044b6:	04cb2783          	lw	a5,76(s6)
    800044ba:	0127f463          	bgeu	a5,s2,800044c2 <writei+0xe2>
    ip->size = off;
    800044be:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800044c2:	855a                	mv	a0,s6
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	aa6080e7          	jalr	-1370(ra) # 80003f6a <iupdate>

  return tot;
    800044cc:	000a051b          	sext.w	a0,s4
}
    800044d0:	70a6                	ld	ra,104(sp)
    800044d2:	7406                	ld	s0,96(sp)
    800044d4:	64e6                	ld	s1,88(sp)
    800044d6:	6946                	ld	s2,80(sp)
    800044d8:	69a6                	ld	s3,72(sp)
    800044da:	6a06                	ld	s4,64(sp)
    800044dc:	7ae2                	ld	s5,56(sp)
    800044de:	7b42                	ld	s6,48(sp)
    800044e0:	7ba2                	ld	s7,40(sp)
    800044e2:	7c02                	ld	s8,32(sp)
    800044e4:	6ce2                	ld	s9,24(sp)
    800044e6:	6d42                	ld	s10,16(sp)
    800044e8:	6da2                	ld	s11,8(sp)
    800044ea:	6165                	addi	sp,sp,112
    800044ec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800044ee:	8a5e                	mv	s4,s7
    800044f0:	bfc9                	j	800044c2 <writei+0xe2>
    return -1;
    800044f2:	557d                	li	a0,-1
}
    800044f4:	8082                	ret
    return -1;
    800044f6:	557d                	li	a0,-1
    800044f8:	bfe1                	j	800044d0 <writei+0xf0>
    return -1;
    800044fa:	557d                	li	a0,-1
    800044fc:	bfd1                	j	800044d0 <writei+0xf0>

00000000800044fe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800044fe:	1141                	addi	sp,sp,-16
    80004500:	e406                	sd	ra,8(sp)
    80004502:	e022                	sd	s0,0(sp)
    80004504:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004506:	4639                	li	a2,14
    80004508:	ffffd097          	auipc	ra,0xffffd
    8000450c:	8b0080e7          	jalr	-1872(ra) # 80000db8 <strncmp>
}
    80004510:	60a2                	ld	ra,8(sp)
    80004512:	6402                	ld	s0,0(sp)
    80004514:	0141                	addi	sp,sp,16
    80004516:	8082                	ret

0000000080004518 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004518:	7139                	addi	sp,sp,-64
    8000451a:	fc06                	sd	ra,56(sp)
    8000451c:	f822                	sd	s0,48(sp)
    8000451e:	f426                	sd	s1,40(sp)
    80004520:	f04a                	sd	s2,32(sp)
    80004522:	ec4e                	sd	s3,24(sp)
    80004524:	e852                	sd	s4,16(sp)
    80004526:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004528:	04451703          	lh	a4,68(a0)
    8000452c:	4785                	li	a5,1
    8000452e:	00f71a63          	bne	a4,a5,80004542 <dirlookup+0x2a>
    80004532:	892a                	mv	s2,a0
    80004534:	89ae                	mv	s3,a1
    80004536:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004538:	457c                	lw	a5,76(a0)
    8000453a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000453c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000453e:	e79d                	bnez	a5,8000456c <dirlookup+0x54>
    80004540:	a8a5                	j	800045b8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004542:	00004517          	auipc	a0,0x4
    80004546:	1fe50513          	addi	a0,a0,510 # 80008740 <syscalls+0x1b0>
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	ff4080e7          	jalr	-12(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004552:	00004517          	auipc	a0,0x4
    80004556:	20650513          	addi	a0,a0,518 # 80008758 <syscalls+0x1c8>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	fe4080e7          	jalr	-28(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004562:	24c1                	addiw	s1,s1,16
    80004564:	04c92783          	lw	a5,76(s2)
    80004568:	04f4f763          	bgeu	s1,a5,800045b6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000456c:	4741                	li	a4,16
    8000456e:	86a6                	mv	a3,s1
    80004570:	fc040613          	addi	a2,s0,-64
    80004574:	4581                	li	a1,0
    80004576:	854a                	mv	a0,s2
    80004578:	00000097          	auipc	ra,0x0
    8000457c:	d70080e7          	jalr	-656(ra) # 800042e8 <readi>
    80004580:	47c1                	li	a5,16
    80004582:	fcf518e3          	bne	a0,a5,80004552 <dirlookup+0x3a>
    if(de.inum == 0)
    80004586:	fc045783          	lhu	a5,-64(s0)
    8000458a:	dfe1                	beqz	a5,80004562 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000458c:	fc240593          	addi	a1,s0,-62
    80004590:	854e                	mv	a0,s3
    80004592:	00000097          	auipc	ra,0x0
    80004596:	f6c080e7          	jalr	-148(ra) # 800044fe <namecmp>
    8000459a:	f561                	bnez	a0,80004562 <dirlookup+0x4a>
      if(poff)
    8000459c:	000a0463          	beqz	s4,800045a4 <dirlookup+0x8c>
        *poff = off;
    800045a0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800045a4:	fc045583          	lhu	a1,-64(s0)
    800045a8:	00092503          	lw	a0,0(s2)
    800045ac:	fffff097          	auipc	ra,0xfffff
    800045b0:	754080e7          	jalr	1876(ra) # 80003d00 <iget>
    800045b4:	a011                	j	800045b8 <dirlookup+0xa0>
  return 0;
    800045b6:	4501                	li	a0,0
}
    800045b8:	70e2                	ld	ra,56(sp)
    800045ba:	7442                	ld	s0,48(sp)
    800045bc:	74a2                	ld	s1,40(sp)
    800045be:	7902                	ld	s2,32(sp)
    800045c0:	69e2                	ld	s3,24(sp)
    800045c2:	6a42                	ld	s4,16(sp)
    800045c4:	6121                	addi	sp,sp,64
    800045c6:	8082                	ret

00000000800045c8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800045c8:	711d                	addi	sp,sp,-96
    800045ca:	ec86                	sd	ra,88(sp)
    800045cc:	e8a2                	sd	s0,80(sp)
    800045ce:	e4a6                	sd	s1,72(sp)
    800045d0:	e0ca                	sd	s2,64(sp)
    800045d2:	fc4e                	sd	s3,56(sp)
    800045d4:	f852                	sd	s4,48(sp)
    800045d6:	f456                	sd	s5,40(sp)
    800045d8:	f05a                	sd	s6,32(sp)
    800045da:	ec5e                	sd	s7,24(sp)
    800045dc:	e862                	sd	s8,16(sp)
    800045de:	e466                	sd	s9,8(sp)
    800045e0:	1080                	addi	s0,sp,96
    800045e2:	84aa                	mv	s1,a0
    800045e4:	8b2e                	mv	s6,a1
    800045e6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800045e8:	00054703          	lbu	a4,0(a0)
    800045ec:	02f00793          	li	a5,47
    800045f0:	02f70363          	beq	a4,a5,80004616 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800045f4:	ffffe097          	auipc	ra,0xffffe
    800045f8:	bec080e7          	jalr	-1044(ra) # 800021e0 <myproc>
    800045fc:	17853503          	ld	a0,376(a0)
    80004600:	00000097          	auipc	ra,0x0
    80004604:	9f6080e7          	jalr	-1546(ra) # 80003ff6 <idup>
    80004608:	89aa                	mv	s3,a0
  while(*path == '/')
    8000460a:	02f00913          	li	s2,47
  len = path - s;
    8000460e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004610:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004612:	4c05                	li	s8,1
    80004614:	a865                	j	800046cc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004616:	4585                	li	a1,1
    80004618:	4505                	li	a0,1
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	6e6080e7          	jalr	1766(ra) # 80003d00 <iget>
    80004622:	89aa                	mv	s3,a0
    80004624:	b7dd                	j	8000460a <namex+0x42>
      iunlockput(ip);
    80004626:	854e                	mv	a0,s3
    80004628:	00000097          	auipc	ra,0x0
    8000462c:	c6e080e7          	jalr	-914(ra) # 80004296 <iunlockput>
      return 0;
    80004630:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004632:	854e                	mv	a0,s3
    80004634:	60e6                	ld	ra,88(sp)
    80004636:	6446                	ld	s0,80(sp)
    80004638:	64a6                	ld	s1,72(sp)
    8000463a:	6906                	ld	s2,64(sp)
    8000463c:	79e2                	ld	s3,56(sp)
    8000463e:	7a42                	ld	s4,48(sp)
    80004640:	7aa2                	ld	s5,40(sp)
    80004642:	7b02                	ld	s6,32(sp)
    80004644:	6be2                	ld	s7,24(sp)
    80004646:	6c42                	ld	s8,16(sp)
    80004648:	6ca2                	ld	s9,8(sp)
    8000464a:	6125                	addi	sp,sp,96
    8000464c:	8082                	ret
      iunlock(ip);
    8000464e:	854e                	mv	a0,s3
    80004650:	00000097          	auipc	ra,0x0
    80004654:	aa6080e7          	jalr	-1370(ra) # 800040f6 <iunlock>
      return ip;
    80004658:	bfe9                	j	80004632 <namex+0x6a>
      iunlockput(ip);
    8000465a:	854e                	mv	a0,s3
    8000465c:	00000097          	auipc	ra,0x0
    80004660:	c3a080e7          	jalr	-966(ra) # 80004296 <iunlockput>
      return 0;
    80004664:	89d2                	mv	s3,s4
    80004666:	b7f1                	j	80004632 <namex+0x6a>
  len = path - s;
    80004668:	40b48633          	sub	a2,s1,a1
    8000466c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004670:	094cd463          	bge	s9,s4,800046f8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004674:	4639                	li	a2,14
    80004676:	8556                	mv	a0,s5
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	6c8080e7          	jalr	1736(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004680:	0004c783          	lbu	a5,0(s1)
    80004684:	01279763          	bne	a5,s2,80004692 <namex+0xca>
    path++;
    80004688:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000468a:	0004c783          	lbu	a5,0(s1)
    8000468e:	ff278de3          	beq	a5,s2,80004688 <namex+0xc0>
    ilock(ip);
    80004692:	854e                	mv	a0,s3
    80004694:	00000097          	auipc	ra,0x0
    80004698:	9a0080e7          	jalr	-1632(ra) # 80004034 <ilock>
    if(ip->type != T_DIR){
    8000469c:	04499783          	lh	a5,68(s3)
    800046a0:	f98793e3          	bne	a5,s8,80004626 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800046a4:	000b0563          	beqz	s6,800046ae <namex+0xe6>
    800046a8:	0004c783          	lbu	a5,0(s1)
    800046ac:	d3cd                	beqz	a5,8000464e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800046ae:	865e                	mv	a2,s7
    800046b0:	85d6                	mv	a1,s5
    800046b2:	854e                	mv	a0,s3
    800046b4:	00000097          	auipc	ra,0x0
    800046b8:	e64080e7          	jalr	-412(ra) # 80004518 <dirlookup>
    800046bc:	8a2a                	mv	s4,a0
    800046be:	dd51                	beqz	a0,8000465a <namex+0x92>
    iunlockput(ip);
    800046c0:	854e                	mv	a0,s3
    800046c2:	00000097          	auipc	ra,0x0
    800046c6:	bd4080e7          	jalr	-1068(ra) # 80004296 <iunlockput>
    ip = next;
    800046ca:	89d2                	mv	s3,s4
  while(*path == '/')
    800046cc:	0004c783          	lbu	a5,0(s1)
    800046d0:	05279763          	bne	a5,s2,8000471e <namex+0x156>
    path++;
    800046d4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800046d6:	0004c783          	lbu	a5,0(s1)
    800046da:	ff278de3          	beq	a5,s2,800046d4 <namex+0x10c>
  if(*path == 0)
    800046de:	c79d                	beqz	a5,8000470c <namex+0x144>
    path++;
    800046e0:	85a6                	mv	a1,s1
  len = path - s;
    800046e2:	8a5e                	mv	s4,s7
    800046e4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800046e6:	01278963          	beq	a5,s2,800046f8 <namex+0x130>
    800046ea:	dfbd                	beqz	a5,80004668 <namex+0xa0>
    path++;
    800046ec:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800046ee:	0004c783          	lbu	a5,0(s1)
    800046f2:	ff279ce3          	bne	a5,s2,800046ea <namex+0x122>
    800046f6:	bf8d                	j	80004668 <namex+0xa0>
    memmove(name, s, len);
    800046f8:	2601                	sext.w	a2,a2
    800046fa:	8556                	mv	a0,s5
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	644080e7          	jalr	1604(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004704:	9a56                	add	s4,s4,s5
    80004706:	000a0023          	sb	zero,0(s4)
    8000470a:	bf9d                	j	80004680 <namex+0xb8>
  if(nameiparent){
    8000470c:	f20b03e3          	beqz	s6,80004632 <namex+0x6a>
    iput(ip);
    80004710:	854e                	mv	a0,s3
    80004712:	00000097          	auipc	ra,0x0
    80004716:	adc080e7          	jalr	-1316(ra) # 800041ee <iput>
    return 0;
    8000471a:	4981                	li	s3,0
    8000471c:	bf19                	j	80004632 <namex+0x6a>
  if(*path == 0)
    8000471e:	d7fd                	beqz	a5,8000470c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004720:	0004c783          	lbu	a5,0(s1)
    80004724:	85a6                	mv	a1,s1
    80004726:	b7d1                	j	800046ea <namex+0x122>

0000000080004728 <dirlink>:
{
    80004728:	7139                	addi	sp,sp,-64
    8000472a:	fc06                	sd	ra,56(sp)
    8000472c:	f822                	sd	s0,48(sp)
    8000472e:	f426                	sd	s1,40(sp)
    80004730:	f04a                	sd	s2,32(sp)
    80004732:	ec4e                	sd	s3,24(sp)
    80004734:	e852                	sd	s4,16(sp)
    80004736:	0080                	addi	s0,sp,64
    80004738:	892a                	mv	s2,a0
    8000473a:	8a2e                	mv	s4,a1
    8000473c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000473e:	4601                	li	a2,0
    80004740:	00000097          	auipc	ra,0x0
    80004744:	dd8080e7          	jalr	-552(ra) # 80004518 <dirlookup>
    80004748:	e93d                	bnez	a0,800047be <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000474a:	04c92483          	lw	s1,76(s2)
    8000474e:	c49d                	beqz	s1,8000477c <dirlink+0x54>
    80004750:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004752:	4741                	li	a4,16
    80004754:	86a6                	mv	a3,s1
    80004756:	fc040613          	addi	a2,s0,-64
    8000475a:	4581                	li	a1,0
    8000475c:	854a                	mv	a0,s2
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	b8a080e7          	jalr	-1142(ra) # 800042e8 <readi>
    80004766:	47c1                	li	a5,16
    80004768:	06f51163          	bne	a0,a5,800047ca <dirlink+0xa2>
    if(de.inum == 0)
    8000476c:	fc045783          	lhu	a5,-64(s0)
    80004770:	c791                	beqz	a5,8000477c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004772:	24c1                	addiw	s1,s1,16
    80004774:	04c92783          	lw	a5,76(s2)
    80004778:	fcf4ede3          	bltu	s1,a5,80004752 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000477c:	4639                	li	a2,14
    8000477e:	85d2                	mv	a1,s4
    80004780:	fc240513          	addi	a0,s0,-62
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	670080e7          	jalr	1648(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000478c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004790:	4741                	li	a4,16
    80004792:	86a6                	mv	a3,s1
    80004794:	fc040613          	addi	a2,s0,-64
    80004798:	4581                	li	a1,0
    8000479a:	854a                	mv	a0,s2
    8000479c:	00000097          	auipc	ra,0x0
    800047a0:	c44080e7          	jalr	-956(ra) # 800043e0 <writei>
    800047a4:	872a                	mv	a4,a0
    800047a6:	47c1                	li	a5,16
  return 0;
    800047a8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047aa:	02f71863          	bne	a4,a5,800047da <dirlink+0xb2>
}
    800047ae:	70e2                	ld	ra,56(sp)
    800047b0:	7442                	ld	s0,48(sp)
    800047b2:	74a2                	ld	s1,40(sp)
    800047b4:	7902                	ld	s2,32(sp)
    800047b6:	69e2                	ld	s3,24(sp)
    800047b8:	6a42                	ld	s4,16(sp)
    800047ba:	6121                	addi	sp,sp,64
    800047bc:	8082                	ret
    iput(ip);
    800047be:	00000097          	auipc	ra,0x0
    800047c2:	a30080e7          	jalr	-1488(ra) # 800041ee <iput>
    return -1;
    800047c6:	557d                	li	a0,-1
    800047c8:	b7dd                	j	800047ae <dirlink+0x86>
      panic("dirlink read");
    800047ca:	00004517          	auipc	a0,0x4
    800047ce:	f9e50513          	addi	a0,a0,-98 # 80008768 <syscalls+0x1d8>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	d6c080e7          	jalr	-660(ra) # 8000053e <panic>
    panic("dirlink");
    800047da:	00004517          	auipc	a0,0x4
    800047de:	09e50513          	addi	a0,a0,158 # 80008878 <syscalls+0x2e8>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	d5c080e7          	jalr	-676(ra) # 8000053e <panic>

00000000800047ea <namei>:

struct inode*
namei(char *path)
{
    800047ea:	1101                	addi	sp,sp,-32
    800047ec:	ec06                	sd	ra,24(sp)
    800047ee:	e822                	sd	s0,16(sp)
    800047f0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800047f2:	fe040613          	addi	a2,s0,-32
    800047f6:	4581                	li	a1,0
    800047f8:	00000097          	auipc	ra,0x0
    800047fc:	dd0080e7          	jalr	-560(ra) # 800045c8 <namex>
}
    80004800:	60e2                	ld	ra,24(sp)
    80004802:	6442                	ld	s0,16(sp)
    80004804:	6105                	addi	sp,sp,32
    80004806:	8082                	ret

0000000080004808 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004808:	1141                	addi	sp,sp,-16
    8000480a:	e406                	sd	ra,8(sp)
    8000480c:	e022                	sd	s0,0(sp)
    8000480e:	0800                	addi	s0,sp,16
    80004810:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004812:	4585                	li	a1,1
    80004814:	00000097          	auipc	ra,0x0
    80004818:	db4080e7          	jalr	-588(ra) # 800045c8 <namex>
}
    8000481c:	60a2                	ld	ra,8(sp)
    8000481e:	6402                	ld	s0,0(sp)
    80004820:	0141                	addi	sp,sp,16
    80004822:	8082                	ret

0000000080004824 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004824:	1101                	addi	sp,sp,-32
    80004826:	ec06                	sd	ra,24(sp)
    80004828:	e822                	sd	s0,16(sp)
    8000482a:	e426                	sd	s1,8(sp)
    8000482c:	e04a                	sd	s2,0(sp)
    8000482e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004830:	0001d917          	auipc	s2,0x1d
    80004834:	1b890913          	addi	s2,s2,440 # 800219e8 <log>
    80004838:	01892583          	lw	a1,24(s2)
    8000483c:	02892503          	lw	a0,40(s2)
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	ff2080e7          	jalr	-14(ra) # 80003832 <bread>
    80004848:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000484a:	02c92683          	lw	a3,44(s2)
    8000484e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004850:	02d05763          	blez	a3,8000487e <write_head+0x5a>
    80004854:	0001d797          	auipc	a5,0x1d
    80004858:	1c478793          	addi	a5,a5,452 # 80021a18 <log+0x30>
    8000485c:	05c50713          	addi	a4,a0,92
    80004860:	36fd                	addiw	a3,a3,-1
    80004862:	1682                	slli	a3,a3,0x20
    80004864:	9281                	srli	a3,a3,0x20
    80004866:	068a                	slli	a3,a3,0x2
    80004868:	0001d617          	auipc	a2,0x1d
    8000486c:	1b460613          	addi	a2,a2,436 # 80021a1c <log+0x34>
    80004870:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004872:	4390                	lw	a2,0(a5)
    80004874:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004876:	0791                	addi	a5,a5,4
    80004878:	0711                	addi	a4,a4,4
    8000487a:	fed79ce3          	bne	a5,a3,80004872 <write_head+0x4e>
  }
  bwrite(buf);
    8000487e:	8526                	mv	a0,s1
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	0a4080e7          	jalr	164(ra) # 80003924 <bwrite>
  brelse(buf);
    80004888:	8526                	mv	a0,s1
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	0d8080e7          	jalr	216(ra) # 80003962 <brelse>
}
    80004892:	60e2                	ld	ra,24(sp)
    80004894:	6442                	ld	s0,16(sp)
    80004896:	64a2                	ld	s1,8(sp)
    80004898:	6902                	ld	s2,0(sp)
    8000489a:	6105                	addi	sp,sp,32
    8000489c:	8082                	ret

000000008000489e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000489e:	0001d797          	auipc	a5,0x1d
    800048a2:	1767a783          	lw	a5,374(a5) # 80021a14 <log+0x2c>
    800048a6:	0af05d63          	blez	a5,80004960 <install_trans+0xc2>
{
    800048aa:	7139                	addi	sp,sp,-64
    800048ac:	fc06                	sd	ra,56(sp)
    800048ae:	f822                	sd	s0,48(sp)
    800048b0:	f426                	sd	s1,40(sp)
    800048b2:	f04a                	sd	s2,32(sp)
    800048b4:	ec4e                	sd	s3,24(sp)
    800048b6:	e852                	sd	s4,16(sp)
    800048b8:	e456                	sd	s5,8(sp)
    800048ba:	e05a                	sd	s6,0(sp)
    800048bc:	0080                	addi	s0,sp,64
    800048be:	8b2a                	mv	s6,a0
    800048c0:	0001da97          	auipc	s5,0x1d
    800048c4:	158a8a93          	addi	s5,s5,344 # 80021a18 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048c8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048ca:	0001d997          	auipc	s3,0x1d
    800048ce:	11e98993          	addi	s3,s3,286 # 800219e8 <log>
    800048d2:	a035                	j	800048fe <install_trans+0x60>
      bunpin(dbuf);
    800048d4:	8526                	mv	a0,s1
    800048d6:	fffff097          	auipc	ra,0xfffff
    800048da:	166080e7          	jalr	358(ra) # 80003a3c <bunpin>
    brelse(lbuf);
    800048de:	854a                	mv	a0,s2
    800048e0:	fffff097          	auipc	ra,0xfffff
    800048e4:	082080e7          	jalr	130(ra) # 80003962 <brelse>
    brelse(dbuf);
    800048e8:	8526                	mv	a0,s1
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	078080e7          	jalr	120(ra) # 80003962 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048f2:	2a05                	addiw	s4,s4,1
    800048f4:	0a91                	addi	s5,s5,4
    800048f6:	02c9a783          	lw	a5,44(s3)
    800048fa:	04fa5963          	bge	s4,a5,8000494c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048fe:	0189a583          	lw	a1,24(s3)
    80004902:	014585bb          	addw	a1,a1,s4
    80004906:	2585                	addiw	a1,a1,1
    80004908:	0289a503          	lw	a0,40(s3)
    8000490c:	fffff097          	auipc	ra,0xfffff
    80004910:	f26080e7          	jalr	-218(ra) # 80003832 <bread>
    80004914:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004916:	000aa583          	lw	a1,0(s5)
    8000491a:	0289a503          	lw	a0,40(s3)
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	f14080e7          	jalr	-236(ra) # 80003832 <bread>
    80004926:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004928:	40000613          	li	a2,1024
    8000492c:	05890593          	addi	a1,s2,88
    80004930:	05850513          	addi	a0,a0,88
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	40c080e7          	jalr	1036(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000493c:	8526                	mv	a0,s1
    8000493e:	fffff097          	auipc	ra,0xfffff
    80004942:	fe6080e7          	jalr	-26(ra) # 80003924 <bwrite>
    if(recovering == 0)
    80004946:	f80b1ce3          	bnez	s6,800048de <install_trans+0x40>
    8000494a:	b769                	j	800048d4 <install_trans+0x36>
}
    8000494c:	70e2                	ld	ra,56(sp)
    8000494e:	7442                	ld	s0,48(sp)
    80004950:	74a2                	ld	s1,40(sp)
    80004952:	7902                	ld	s2,32(sp)
    80004954:	69e2                	ld	s3,24(sp)
    80004956:	6a42                	ld	s4,16(sp)
    80004958:	6aa2                	ld	s5,8(sp)
    8000495a:	6b02                	ld	s6,0(sp)
    8000495c:	6121                	addi	sp,sp,64
    8000495e:	8082                	ret
    80004960:	8082                	ret

0000000080004962 <initlog>:
{
    80004962:	7179                	addi	sp,sp,-48
    80004964:	f406                	sd	ra,40(sp)
    80004966:	f022                	sd	s0,32(sp)
    80004968:	ec26                	sd	s1,24(sp)
    8000496a:	e84a                	sd	s2,16(sp)
    8000496c:	e44e                	sd	s3,8(sp)
    8000496e:	1800                	addi	s0,sp,48
    80004970:	892a                	mv	s2,a0
    80004972:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004974:	0001d497          	auipc	s1,0x1d
    80004978:	07448493          	addi	s1,s1,116 # 800219e8 <log>
    8000497c:	00004597          	auipc	a1,0x4
    80004980:	dfc58593          	addi	a1,a1,-516 # 80008778 <syscalls+0x1e8>
    80004984:	8526                	mv	a0,s1
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	1ce080e7          	jalr	462(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000498e:	0149a583          	lw	a1,20(s3)
    80004992:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004994:	0109a783          	lw	a5,16(s3)
    80004998:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000499a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000499e:	854a                	mv	a0,s2
    800049a0:	fffff097          	auipc	ra,0xfffff
    800049a4:	e92080e7          	jalr	-366(ra) # 80003832 <bread>
  log.lh.n = lh->n;
    800049a8:	4d3c                	lw	a5,88(a0)
    800049aa:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800049ac:	02f05563          	blez	a5,800049d6 <initlog+0x74>
    800049b0:	05c50713          	addi	a4,a0,92
    800049b4:	0001d697          	auipc	a3,0x1d
    800049b8:	06468693          	addi	a3,a3,100 # 80021a18 <log+0x30>
    800049bc:	37fd                	addiw	a5,a5,-1
    800049be:	1782                	slli	a5,a5,0x20
    800049c0:	9381                	srli	a5,a5,0x20
    800049c2:	078a                	slli	a5,a5,0x2
    800049c4:	06050613          	addi	a2,a0,96
    800049c8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800049ca:	4310                	lw	a2,0(a4)
    800049cc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800049ce:	0711                	addi	a4,a4,4
    800049d0:	0691                	addi	a3,a3,4
    800049d2:	fef71ce3          	bne	a4,a5,800049ca <initlog+0x68>
  brelse(buf);
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	f8c080e7          	jalr	-116(ra) # 80003962 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800049de:	4505                	li	a0,1
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	ebe080e7          	jalr	-322(ra) # 8000489e <install_trans>
  log.lh.n = 0;
    800049e8:	0001d797          	auipc	a5,0x1d
    800049ec:	0207a623          	sw	zero,44(a5) # 80021a14 <log+0x2c>
  write_head(); // clear the log
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	e34080e7          	jalr	-460(ra) # 80004824 <write_head>
}
    800049f8:	70a2                	ld	ra,40(sp)
    800049fa:	7402                	ld	s0,32(sp)
    800049fc:	64e2                	ld	s1,24(sp)
    800049fe:	6942                	ld	s2,16(sp)
    80004a00:	69a2                	ld	s3,8(sp)
    80004a02:	6145                	addi	sp,sp,48
    80004a04:	8082                	ret

0000000080004a06 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004a06:	1101                	addi	sp,sp,-32
    80004a08:	ec06                	sd	ra,24(sp)
    80004a0a:	e822                	sd	s0,16(sp)
    80004a0c:	e426                	sd	s1,8(sp)
    80004a0e:	e04a                	sd	s2,0(sp)
    80004a10:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004a12:	0001d517          	auipc	a0,0x1d
    80004a16:	fd650513          	addi	a0,a0,-42 # 800219e8 <log>
    80004a1a:	ffffc097          	auipc	ra,0xffffc
    80004a1e:	1ca080e7          	jalr	458(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004a22:	0001d497          	auipc	s1,0x1d
    80004a26:	fc648493          	addi	s1,s1,-58 # 800219e8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a2a:	4979                	li	s2,30
    80004a2c:	a039                	j	80004a3a <begin_op+0x34>
      sleep(&log, &log.lock);
    80004a2e:	85a6                	mv	a1,s1
    80004a30:	8526                	mv	a0,s1
    80004a32:	ffffe097          	auipc	ra,0xffffe
    80004a36:	f32080e7          	jalr	-206(ra) # 80002964 <sleep>
    if(log.committing){
    80004a3a:	50dc                	lw	a5,36(s1)
    80004a3c:	fbed                	bnez	a5,80004a2e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a3e:	509c                	lw	a5,32(s1)
    80004a40:	0017871b          	addiw	a4,a5,1
    80004a44:	0007069b          	sext.w	a3,a4
    80004a48:	0027179b          	slliw	a5,a4,0x2
    80004a4c:	9fb9                	addw	a5,a5,a4
    80004a4e:	0017979b          	slliw	a5,a5,0x1
    80004a52:	54d8                	lw	a4,44(s1)
    80004a54:	9fb9                	addw	a5,a5,a4
    80004a56:	00f95963          	bge	s2,a5,80004a68 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004a5a:	85a6                	mv	a1,s1
    80004a5c:	8526                	mv	a0,s1
    80004a5e:	ffffe097          	auipc	ra,0xffffe
    80004a62:	f06080e7          	jalr	-250(ra) # 80002964 <sleep>
    80004a66:	bfd1                	j	80004a3a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004a68:	0001d517          	auipc	a0,0x1d
    80004a6c:	f8050513          	addi	a0,a0,-128 # 800219e8 <log>
    80004a70:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	226080e7          	jalr	550(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004a7a:	60e2                	ld	ra,24(sp)
    80004a7c:	6442                	ld	s0,16(sp)
    80004a7e:	64a2                	ld	s1,8(sp)
    80004a80:	6902                	ld	s2,0(sp)
    80004a82:	6105                	addi	sp,sp,32
    80004a84:	8082                	ret

0000000080004a86 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a86:	7139                	addi	sp,sp,-64
    80004a88:	fc06                	sd	ra,56(sp)
    80004a8a:	f822                	sd	s0,48(sp)
    80004a8c:	f426                	sd	s1,40(sp)
    80004a8e:	f04a                	sd	s2,32(sp)
    80004a90:	ec4e                	sd	s3,24(sp)
    80004a92:	e852                	sd	s4,16(sp)
    80004a94:	e456                	sd	s5,8(sp)
    80004a96:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a98:	0001d497          	auipc	s1,0x1d
    80004a9c:	f5048493          	addi	s1,s1,-176 # 800219e8 <log>
    80004aa0:	8526                	mv	a0,s1
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	142080e7          	jalr	322(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004aaa:	509c                	lw	a5,32(s1)
    80004aac:	37fd                	addiw	a5,a5,-1
    80004aae:	0007891b          	sext.w	s2,a5
    80004ab2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004ab4:	50dc                	lw	a5,36(s1)
    80004ab6:	efb9                	bnez	a5,80004b14 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004ab8:	06091663          	bnez	s2,80004b24 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004abc:	0001d497          	auipc	s1,0x1d
    80004ac0:	f2c48493          	addi	s1,s1,-212 # 800219e8 <log>
    80004ac4:	4785                	li	a5,1
    80004ac6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	1ce080e7          	jalr	462(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004ad2:	54dc                	lw	a5,44(s1)
    80004ad4:	06f04763          	bgtz	a5,80004b42 <end_op+0xbc>
    acquire(&log.lock);
    80004ad8:	0001d497          	auipc	s1,0x1d
    80004adc:	f1048493          	addi	s1,s1,-240 # 800219e8 <log>
    80004ae0:	8526                	mv	a0,s1
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	102080e7          	jalr	258(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004aea:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004aee:	8526                	mv	a0,s1
    80004af0:	ffffe097          	auipc	ra,0xffffe
    80004af4:	00e080e7          	jalr	14(ra) # 80002afe <wakeup>
    release(&log.lock);
    80004af8:	8526                	mv	a0,s1
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	19e080e7          	jalr	414(ra) # 80000c98 <release>
}
    80004b02:	70e2                	ld	ra,56(sp)
    80004b04:	7442                	ld	s0,48(sp)
    80004b06:	74a2                	ld	s1,40(sp)
    80004b08:	7902                	ld	s2,32(sp)
    80004b0a:	69e2                	ld	s3,24(sp)
    80004b0c:	6a42                	ld	s4,16(sp)
    80004b0e:	6aa2                	ld	s5,8(sp)
    80004b10:	6121                	addi	sp,sp,64
    80004b12:	8082                	ret
    panic("log.committing");
    80004b14:	00004517          	auipc	a0,0x4
    80004b18:	c6c50513          	addi	a0,a0,-916 # 80008780 <syscalls+0x1f0>
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	a22080e7          	jalr	-1502(ra) # 8000053e <panic>
    wakeup(&log);
    80004b24:	0001d497          	auipc	s1,0x1d
    80004b28:	ec448493          	addi	s1,s1,-316 # 800219e8 <log>
    80004b2c:	8526                	mv	a0,s1
    80004b2e:	ffffe097          	auipc	ra,0xffffe
    80004b32:	fd0080e7          	jalr	-48(ra) # 80002afe <wakeup>
  release(&log.lock);
    80004b36:	8526                	mv	a0,s1
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	160080e7          	jalr	352(ra) # 80000c98 <release>
  if(do_commit){
    80004b40:	b7c9                	j	80004b02 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b42:	0001da97          	auipc	s5,0x1d
    80004b46:	ed6a8a93          	addi	s5,s5,-298 # 80021a18 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004b4a:	0001da17          	auipc	s4,0x1d
    80004b4e:	e9ea0a13          	addi	s4,s4,-354 # 800219e8 <log>
    80004b52:	018a2583          	lw	a1,24(s4)
    80004b56:	012585bb          	addw	a1,a1,s2
    80004b5a:	2585                	addiw	a1,a1,1
    80004b5c:	028a2503          	lw	a0,40(s4)
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	cd2080e7          	jalr	-814(ra) # 80003832 <bread>
    80004b68:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004b6a:	000aa583          	lw	a1,0(s5)
    80004b6e:	028a2503          	lw	a0,40(s4)
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	cc0080e7          	jalr	-832(ra) # 80003832 <bread>
    80004b7a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b7c:	40000613          	li	a2,1024
    80004b80:	05850593          	addi	a1,a0,88
    80004b84:	05848513          	addi	a0,s1,88
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	1b8080e7          	jalr	440(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004b90:	8526                	mv	a0,s1
    80004b92:	fffff097          	auipc	ra,0xfffff
    80004b96:	d92080e7          	jalr	-622(ra) # 80003924 <bwrite>
    brelse(from);
    80004b9a:	854e                	mv	a0,s3
    80004b9c:	fffff097          	auipc	ra,0xfffff
    80004ba0:	dc6080e7          	jalr	-570(ra) # 80003962 <brelse>
    brelse(to);
    80004ba4:	8526                	mv	a0,s1
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	dbc080e7          	jalr	-580(ra) # 80003962 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bae:	2905                	addiw	s2,s2,1
    80004bb0:	0a91                	addi	s5,s5,4
    80004bb2:	02ca2783          	lw	a5,44(s4)
    80004bb6:	f8f94ee3          	blt	s2,a5,80004b52 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004bba:	00000097          	auipc	ra,0x0
    80004bbe:	c6a080e7          	jalr	-918(ra) # 80004824 <write_head>
    install_trans(0); // Now install writes to home locations
    80004bc2:	4501                	li	a0,0
    80004bc4:	00000097          	auipc	ra,0x0
    80004bc8:	cda080e7          	jalr	-806(ra) # 8000489e <install_trans>
    log.lh.n = 0;
    80004bcc:	0001d797          	auipc	a5,0x1d
    80004bd0:	e407a423          	sw	zero,-440(a5) # 80021a14 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004bd4:	00000097          	auipc	ra,0x0
    80004bd8:	c50080e7          	jalr	-944(ra) # 80004824 <write_head>
    80004bdc:	bdf5                	j	80004ad8 <end_op+0x52>

0000000080004bde <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004bde:	1101                	addi	sp,sp,-32
    80004be0:	ec06                	sd	ra,24(sp)
    80004be2:	e822                	sd	s0,16(sp)
    80004be4:	e426                	sd	s1,8(sp)
    80004be6:	e04a                	sd	s2,0(sp)
    80004be8:	1000                	addi	s0,sp,32
    80004bea:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004bec:	0001d917          	auipc	s2,0x1d
    80004bf0:	dfc90913          	addi	s2,s2,-516 # 800219e8 <log>
    80004bf4:	854a                	mv	a0,s2
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	fee080e7          	jalr	-18(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004bfe:	02c92603          	lw	a2,44(s2)
    80004c02:	47f5                	li	a5,29
    80004c04:	06c7c563          	blt	a5,a2,80004c6e <log_write+0x90>
    80004c08:	0001d797          	auipc	a5,0x1d
    80004c0c:	dfc7a783          	lw	a5,-516(a5) # 80021a04 <log+0x1c>
    80004c10:	37fd                	addiw	a5,a5,-1
    80004c12:	04f65e63          	bge	a2,a5,80004c6e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004c16:	0001d797          	auipc	a5,0x1d
    80004c1a:	df27a783          	lw	a5,-526(a5) # 80021a08 <log+0x20>
    80004c1e:	06f05063          	blez	a5,80004c7e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004c22:	4781                	li	a5,0
    80004c24:	06c05563          	blez	a2,80004c8e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c28:	44cc                	lw	a1,12(s1)
    80004c2a:	0001d717          	auipc	a4,0x1d
    80004c2e:	dee70713          	addi	a4,a4,-530 # 80021a18 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004c32:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c34:	4314                	lw	a3,0(a4)
    80004c36:	04b68c63          	beq	a3,a1,80004c8e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004c3a:	2785                	addiw	a5,a5,1
    80004c3c:	0711                	addi	a4,a4,4
    80004c3e:	fef61be3          	bne	a2,a5,80004c34 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004c42:	0621                	addi	a2,a2,8
    80004c44:	060a                	slli	a2,a2,0x2
    80004c46:	0001d797          	auipc	a5,0x1d
    80004c4a:	da278793          	addi	a5,a5,-606 # 800219e8 <log>
    80004c4e:	963e                	add	a2,a2,a5
    80004c50:	44dc                	lw	a5,12(s1)
    80004c52:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004c54:	8526                	mv	a0,s1
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	daa080e7          	jalr	-598(ra) # 80003a00 <bpin>
    log.lh.n++;
    80004c5e:	0001d717          	auipc	a4,0x1d
    80004c62:	d8a70713          	addi	a4,a4,-630 # 800219e8 <log>
    80004c66:	575c                	lw	a5,44(a4)
    80004c68:	2785                	addiw	a5,a5,1
    80004c6a:	d75c                	sw	a5,44(a4)
    80004c6c:	a835                	j	80004ca8 <log_write+0xca>
    panic("too big a transaction");
    80004c6e:	00004517          	auipc	a0,0x4
    80004c72:	b2250513          	addi	a0,a0,-1246 # 80008790 <syscalls+0x200>
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	8c8080e7          	jalr	-1848(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004c7e:	00004517          	auipc	a0,0x4
    80004c82:	b2a50513          	addi	a0,a0,-1238 # 800087a8 <syscalls+0x218>
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	8b8080e7          	jalr	-1864(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004c8e:	00878713          	addi	a4,a5,8
    80004c92:	00271693          	slli	a3,a4,0x2
    80004c96:	0001d717          	auipc	a4,0x1d
    80004c9a:	d5270713          	addi	a4,a4,-686 # 800219e8 <log>
    80004c9e:	9736                	add	a4,a4,a3
    80004ca0:	44d4                	lw	a3,12(s1)
    80004ca2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004ca4:	faf608e3          	beq	a2,a5,80004c54 <log_write+0x76>
  }
  release(&log.lock);
    80004ca8:	0001d517          	auipc	a0,0x1d
    80004cac:	d4050513          	addi	a0,a0,-704 # 800219e8 <log>
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	fe8080e7          	jalr	-24(ra) # 80000c98 <release>
}
    80004cb8:	60e2                	ld	ra,24(sp)
    80004cba:	6442                	ld	s0,16(sp)
    80004cbc:	64a2                	ld	s1,8(sp)
    80004cbe:	6902                	ld	s2,0(sp)
    80004cc0:	6105                	addi	sp,sp,32
    80004cc2:	8082                	ret

0000000080004cc4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004cc4:	1101                	addi	sp,sp,-32
    80004cc6:	ec06                	sd	ra,24(sp)
    80004cc8:	e822                	sd	s0,16(sp)
    80004cca:	e426                	sd	s1,8(sp)
    80004ccc:	e04a                	sd	s2,0(sp)
    80004cce:	1000                	addi	s0,sp,32
    80004cd0:	84aa                	mv	s1,a0
    80004cd2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004cd4:	00004597          	auipc	a1,0x4
    80004cd8:	af458593          	addi	a1,a1,-1292 # 800087c8 <syscalls+0x238>
    80004cdc:	0521                	addi	a0,a0,8
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	e76080e7          	jalr	-394(ra) # 80000b54 <initlock>
  lk->name = name;
    80004ce6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004cea:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004cee:	0204a423          	sw	zero,40(s1)
}
    80004cf2:	60e2                	ld	ra,24(sp)
    80004cf4:	6442                	ld	s0,16(sp)
    80004cf6:	64a2                	ld	s1,8(sp)
    80004cf8:	6902                	ld	s2,0(sp)
    80004cfa:	6105                	addi	sp,sp,32
    80004cfc:	8082                	ret

0000000080004cfe <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004cfe:	1101                	addi	sp,sp,-32
    80004d00:	ec06                	sd	ra,24(sp)
    80004d02:	e822                	sd	s0,16(sp)
    80004d04:	e426                	sd	s1,8(sp)
    80004d06:	e04a                	sd	s2,0(sp)
    80004d08:	1000                	addi	s0,sp,32
    80004d0a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d0c:	00850913          	addi	s2,a0,8
    80004d10:	854a                	mv	a0,s2
    80004d12:	ffffc097          	auipc	ra,0xffffc
    80004d16:	ed2080e7          	jalr	-302(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004d1a:	409c                	lw	a5,0(s1)
    80004d1c:	cb89                	beqz	a5,80004d2e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004d1e:	85ca                	mv	a1,s2
    80004d20:	8526                	mv	a0,s1
    80004d22:	ffffe097          	auipc	ra,0xffffe
    80004d26:	c42080e7          	jalr	-958(ra) # 80002964 <sleep>
  while (lk->locked) {
    80004d2a:	409c                	lw	a5,0(s1)
    80004d2c:	fbed                	bnez	a5,80004d1e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004d2e:	4785                	li	a5,1
    80004d30:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	4ae080e7          	jalr	1198(ra) # 800021e0 <myproc>
    80004d3a:	453c                	lw	a5,72(a0)
    80004d3c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004d3e:	854a                	mv	a0,s2
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	f58080e7          	jalr	-168(ra) # 80000c98 <release>
}
    80004d48:	60e2                	ld	ra,24(sp)
    80004d4a:	6442                	ld	s0,16(sp)
    80004d4c:	64a2                	ld	s1,8(sp)
    80004d4e:	6902                	ld	s2,0(sp)
    80004d50:	6105                	addi	sp,sp,32
    80004d52:	8082                	ret

0000000080004d54 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004d54:	1101                	addi	sp,sp,-32
    80004d56:	ec06                	sd	ra,24(sp)
    80004d58:	e822                	sd	s0,16(sp)
    80004d5a:	e426                	sd	s1,8(sp)
    80004d5c:	e04a                	sd	s2,0(sp)
    80004d5e:	1000                	addi	s0,sp,32
    80004d60:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d62:	00850913          	addi	s2,a0,8
    80004d66:	854a                	mv	a0,s2
    80004d68:	ffffc097          	auipc	ra,0xffffc
    80004d6c:	e7c080e7          	jalr	-388(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004d70:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d74:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	ffffe097          	auipc	ra,0xffffe
    80004d7e:	d84080e7          	jalr	-636(ra) # 80002afe <wakeup>
  release(&lk->lk);
    80004d82:	854a                	mv	a0,s2
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	f14080e7          	jalr	-236(ra) # 80000c98 <release>
}
    80004d8c:	60e2                	ld	ra,24(sp)
    80004d8e:	6442                	ld	s0,16(sp)
    80004d90:	64a2                	ld	s1,8(sp)
    80004d92:	6902                	ld	s2,0(sp)
    80004d94:	6105                	addi	sp,sp,32
    80004d96:	8082                	ret

0000000080004d98 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d98:	7179                	addi	sp,sp,-48
    80004d9a:	f406                	sd	ra,40(sp)
    80004d9c:	f022                	sd	s0,32(sp)
    80004d9e:	ec26                	sd	s1,24(sp)
    80004da0:	e84a                	sd	s2,16(sp)
    80004da2:	e44e                	sd	s3,8(sp)
    80004da4:	1800                	addi	s0,sp,48
    80004da6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004da8:	00850913          	addi	s2,a0,8
    80004dac:	854a                	mv	a0,s2
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	e36080e7          	jalr	-458(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004db6:	409c                	lw	a5,0(s1)
    80004db8:	ef99                	bnez	a5,80004dd6 <holdingsleep+0x3e>
    80004dba:	4481                	li	s1,0
  release(&lk->lk);
    80004dbc:	854a                	mv	a0,s2
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	eda080e7          	jalr	-294(ra) # 80000c98 <release>
  return r;
}
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	70a2                	ld	ra,40(sp)
    80004dca:	7402                	ld	s0,32(sp)
    80004dcc:	64e2                	ld	s1,24(sp)
    80004dce:	6942                	ld	s2,16(sp)
    80004dd0:	69a2                	ld	s3,8(sp)
    80004dd2:	6145                	addi	sp,sp,48
    80004dd4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dd6:	0284a983          	lw	s3,40(s1)
    80004dda:	ffffd097          	auipc	ra,0xffffd
    80004dde:	406080e7          	jalr	1030(ra) # 800021e0 <myproc>
    80004de2:	4524                	lw	s1,72(a0)
    80004de4:	413484b3          	sub	s1,s1,s3
    80004de8:	0014b493          	seqz	s1,s1
    80004dec:	bfc1                	j	80004dbc <holdingsleep+0x24>

0000000080004dee <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004dee:	1141                	addi	sp,sp,-16
    80004df0:	e406                	sd	ra,8(sp)
    80004df2:	e022                	sd	s0,0(sp)
    80004df4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004df6:	00004597          	auipc	a1,0x4
    80004dfa:	9e258593          	addi	a1,a1,-1566 # 800087d8 <syscalls+0x248>
    80004dfe:	0001d517          	auipc	a0,0x1d
    80004e02:	d3250513          	addi	a0,a0,-718 # 80021b30 <ftable>
    80004e06:	ffffc097          	auipc	ra,0xffffc
    80004e0a:	d4e080e7          	jalr	-690(ra) # 80000b54 <initlock>
}
    80004e0e:	60a2                	ld	ra,8(sp)
    80004e10:	6402                	ld	s0,0(sp)
    80004e12:	0141                	addi	sp,sp,16
    80004e14:	8082                	ret

0000000080004e16 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004e16:	1101                	addi	sp,sp,-32
    80004e18:	ec06                	sd	ra,24(sp)
    80004e1a:	e822                	sd	s0,16(sp)
    80004e1c:	e426                	sd	s1,8(sp)
    80004e1e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004e20:	0001d517          	auipc	a0,0x1d
    80004e24:	d1050513          	addi	a0,a0,-752 # 80021b30 <ftable>
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	dbc080e7          	jalr	-580(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e30:	0001d497          	auipc	s1,0x1d
    80004e34:	d1848493          	addi	s1,s1,-744 # 80021b48 <ftable+0x18>
    80004e38:	0001e717          	auipc	a4,0x1e
    80004e3c:	cb070713          	addi	a4,a4,-848 # 80022ae8 <ftable+0xfb8>
    if(f->ref == 0){
    80004e40:	40dc                	lw	a5,4(s1)
    80004e42:	cf99                	beqz	a5,80004e60 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e44:	02848493          	addi	s1,s1,40
    80004e48:	fee49ce3          	bne	s1,a4,80004e40 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004e4c:	0001d517          	auipc	a0,0x1d
    80004e50:	ce450513          	addi	a0,a0,-796 # 80021b30 <ftable>
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	e44080e7          	jalr	-444(ra) # 80000c98 <release>
  return 0;
    80004e5c:	4481                	li	s1,0
    80004e5e:	a819                	j	80004e74 <filealloc+0x5e>
      f->ref = 1;
    80004e60:	4785                	li	a5,1
    80004e62:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004e64:	0001d517          	auipc	a0,0x1d
    80004e68:	ccc50513          	addi	a0,a0,-820 # 80021b30 <ftable>
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	e2c080e7          	jalr	-468(ra) # 80000c98 <release>
}
    80004e74:	8526                	mv	a0,s1
    80004e76:	60e2                	ld	ra,24(sp)
    80004e78:	6442                	ld	s0,16(sp)
    80004e7a:	64a2                	ld	s1,8(sp)
    80004e7c:	6105                	addi	sp,sp,32
    80004e7e:	8082                	ret

0000000080004e80 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e80:	1101                	addi	sp,sp,-32
    80004e82:	ec06                	sd	ra,24(sp)
    80004e84:	e822                	sd	s0,16(sp)
    80004e86:	e426                	sd	s1,8(sp)
    80004e88:	1000                	addi	s0,sp,32
    80004e8a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e8c:	0001d517          	auipc	a0,0x1d
    80004e90:	ca450513          	addi	a0,a0,-860 # 80021b30 <ftable>
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	d50080e7          	jalr	-688(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004e9c:	40dc                	lw	a5,4(s1)
    80004e9e:	02f05263          	blez	a5,80004ec2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ea2:	2785                	addiw	a5,a5,1
    80004ea4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ea6:	0001d517          	auipc	a0,0x1d
    80004eaa:	c8a50513          	addi	a0,a0,-886 # 80021b30 <ftable>
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	dea080e7          	jalr	-534(ra) # 80000c98 <release>
  return f;
}
    80004eb6:	8526                	mv	a0,s1
    80004eb8:	60e2                	ld	ra,24(sp)
    80004eba:	6442                	ld	s0,16(sp)
    80004ebc:	64a2                	ld	s1,8(sp)
    80004ebe:	6105                	addi	sp,sp,32
    80004ec0:	8082                	ret
    panic("filedup");
    80004ec2:	00004517          	auipc	a0,0x4
    80004ec6:	91e50513          	addi	a0,a0,-1762 # 800087e0 <syscalls+0x250>
    80004eca:	ffffb097          	auipc	ra,0xffffb
    80004ece:	674080e7          	jalr	1652(ra) # 8000053e <panic>

0000000080004ed2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ed2:	7139                	addi	sp,sp,-64
    80004ed4:	fc06                	sd	ra,56(sp)
    80004ed6:	f822                	sd	s0,48(sp)
    80004ed8:	f426                	sd	s1,40(sp)
    80004eda:	f04a                	sd	s2,32(sp)
    80004edc:	ec4e                	sd	s3,24(sp)
    80004ede:	e852                	sd	s4,16(sp)
    80004ee0:	e456                	sd	s5,8(sp)
    80004ee2:	0080                	addi	s0,sp,64
    80004ee4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ee6:	0001d517          	auipc	a0,0x1d
    80004eea:	c4a50513          	addi	a0,a0,-950 # 80021b30 <ftable>
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	cf6080e7          	jalr	-778(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ef6:	40dc                	lw	a5,4(s1)
    80004ef8:	06f05163          	blez	a5,80004f5a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004efc:	37fd                	addiw	a5,a5,-1
    80004efe:	0007871b          	sext.w	a4,a5
    80004f02:	c0dc                	sw	a5,4(s1)
    80004f04:	06e04363          	bgtz	a4,80004f6a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004f08:	0004a903          	lw	s2,0(s1)
    80004f0c:	0094ca83          	lbu	s5,9(s1)
    80004f10:	0104ba03          	ld	s4,16(s1)
    80004f14:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004f18:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004f1c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004f20:	0001d517          	auipc	a0,0x1d
    80004f24:	c1050513          	addi	a0,a0,-1008 # 80021b30 <ftable>
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	d70080e7          	jalr	-656(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004f30:	4785                	li	a5,1
    80004f32:	04f90d63          	beq	s2,a5,80004f8c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004f36:	3979                	addiw	s2,s2,-2
    80004f38:	4785                	li	a5,1
    80004f3a:	0527e063          	bltu	a5,s2,80004f7a <fileclose+0xa8>
    begin_op();
    80004f3e:	00000097          	auipc	ra,0x0
    80004f42:	ac8080e7          	jalr	-1336(ra) # 80004a06 <begin_op>
    iput(ff.ip);
    80004f46:	854e                	mv	a0,s3
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	2a6080e7          	jalr	678(ra) # 800041ee <iput>
    end_op();
    80004f50:	00000097          	auipc	ra,0x0
    80004f54:	b36080e7          	jalr	-1226(ra) # 80004a86 <end_op>
    80004f58:	a00d                	j	80004f7a <fileclose+0xa8>
    panic("fileclose");
    80004f5a:	00004517          	auipc	a0,0x4
    80004f5e:	88e50513          	addi	a0,a0,-1906 # 800087e8 <syscalls+0x258>
    80004f62:	ffffb097          	auipc	ra,0xffffb
    80004f66:	5dc080e7          	jalr	1500(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004f6a:	0001d517          	auipc	a0,0x1d
    80004f6e:	bc650513          	addi	a0,a0,-1082 # 80021b30 <ftable>
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	d26080e7          	jalr	-730(ra) # 80000c98 <release>
  }
}
    80004f7a:	70e2                	ld	ra,56(sp)
    80004f7c:	7442                	ld	s0,48(sp)
    80004f7e:	74a2                	ld	s1,40(sp)
    80004f80:	7902                	ld	s2,32(sp)
    80004f82:	69e2                	ld	s3,24(sp)
    80004f84:	6a42                	ld	s4,16(sp)
    80004f86:	6aa2                	ld	s5,8(sp)
    80004f88:	6121                	addi	sp,sp,64
    80004f8a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f8c:	85d6                	mv	a1,s5
    80004f8e:	8552                	mv	a0,s4
    80004f90:	00000097          	auipc	ra,0x0
    80004f94:	34c080e7          	jalr	844(ra) # 800052dc <pipeclose>
    80004f98:	b7cd                	j	80004f7a <fileclose+0xa8>

0000000080004f9a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f9a:	715d                	addi	sp,sp,-80
    80004f9c:	e486                	sd	ra,72(sp)
    80004f9e:	e0a2                	sd	s0,64(sp)
    80004fa0:	fc26                	sd	s1,56(sp)
    80004fa2:	f84a                	sd	s2,48(sp)
    80004fa4:	f44e                	sd	s3,40(sp)
    80004fa6:	0880                	addi	s0,sp,80
    80004fa8:	84aa                	mv	s1,a0
    80004faa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	234080e7          	jalr	564(ra) # 800021e0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004fb4:	409c                	lw	a5,0(s1)
    80004fb6:	37f9                	addiw	a5,a5,-2
    80004fb8:	4705                	li	a4,1
    80004fba:	04f76763          	bltu	a4,a5,80005008 <filestat+0x6e>
    80004fbe:	892a                	mv	s2,a0
    ilock(f->ip);
    80004fc0:	6c88                	ld	a0,24(s1)
    80004fc2:	fffff097          	auipc	ra,0xfffff
    80004fc6:	072080e7          	jalr	114(ra) # 80004034 <ilock>
    stati(f->ip, &st);
    80004fca:	fb840593          	addi	a1,s0,-72
    80004fce:	6c88                	ld	a0,24(s1)
    80004fd0:	fffff097          	auipc	ra,0xfffff
    80004fd4:	2ee080e7          	jalr	750(ra) # 800042be <stati>
    iunlock(f->ip);
    80004fd8:	6c88                	ld	a0,24(s1)
    80004fda:	fffff097          	auipc	ra,0xfffff
    80004fde:	11c080e7          	jalr	284(ra) # 800040f6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004fe2:	46e1                	li	a3,24
    80004fe4:	fb840613          	addi	a2,s0,-72
    80004fe8:	85ce                	mv	a1,s3
    80004fea:	07893503          	ld	a0,120(s2)
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	684080e7          	jalr	1668(ra) # 80001672 <copyout>
    80004ff6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ffa:	60a6                	ld	ra,72(sp)
    80004ffc:	6406                	ld	s0,64(sp)
    80004ffe:	74e2                	ld	s1,56(sp)
    80005000:	7942                	ld	s2,48(sp)
    80005002:	79a2                	ld	s3,40(sp)
    80005004:	6161                	addi	sp,sp,80
    80005006:	8082                	ret
  return -1;
    80005008:	557d                	li	a0,-1
    8000500a:	bfc5                	j	80004ffa <filestat+0x60>

000000008000500c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000500c:	7179                	addi	sp,sp,-48
    8000500e:	f406                	sd	ra,40(sp)
    80005010:	f022                	sd	s0,32(sp)
    80005012:	ec26                	sd	s1,24(sp)
    80005014:	e84a                	sd	s2,16(sp)
    80005016:	e44e                	sd	s3,8(sp)
    80005018:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000501a:	00854783          	lbu	a5,8(a0)
    8000501e:	c3d5                	beqz	a5,800050c2 <fileread+0xb6>
    80005020:	84aa                	mv	s1,a0
    80005022:	89ae                	mv	s3,a1
    80005024:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005026:	411c                	lw	a5,0(a0)
    80005028:	4705                	li	a4,1
    8000502a:	04e78963          	beq	a5,a4,8000507c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000502e:	470d                	li	a4,3
    80005030:	04e78d63          	beq	a5,a4,8000508a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005034:	4709                	li	a4,2
    80005036:	06e79e63          	bne	a5,a4,800050b2 <fileread+0xa6>
    ilock(f->ip);
    8000503a:	6d08                	ld	a0,24(a0)
    8000503c:	fffff097          	auipc	ra,0xfffff
    80005040:	ff8080e7          	jalr	-8(ra) # 80004034 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005044:	874a                	mv	a4,s2
    80005046:	5094                	lw	a3,32(s1)
    80005048:	864e                	mv	a2,s3
    8000504a:	4585                	li	a1,1
    8000504c:	6c88                	ld	a0,24(s1)
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	29a080e7          	jalr	666(ra) # 800042e8 <readi>
    80005056:	892a                	mv	s2,a0
    80005058:	00a05563          	blez	a0,80005062 <fileread+0x56>
      f->off += r;
    8000505c:	509c                	lw	a5,32(s1)
    8000505e:	9fa9                	addw	a5,a5,a0
    80005060:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005062:	6c88                	ld	a0,24(s1)
    80005064:	fffff097          	auipc	ra,0xfffff
    80005068:	092080e7          	jalr	146(ra) # 800040f6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000506c:	854a                	mv	a0,s2
    8000506e:	70a2                	ld	ra,40(sp)
    80005070:	7402                	ld	s0,32(sp)
    80005072:	64e2                	ld	s1,24(sp)
    80005074:	6942                	ld	s2,16(sp)
    80005076:	69a2                	ld	s3,8(sp)
    80005078:	6145                	addi	sp,sp,48
    8000507a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000507c:	6908                	ld	a0,16(a0)
    8000507e:	00000097          	auipc	ra,0x0
    80005082:	3c8080e7          	jalr	968(ra) # 80005446 <piperead>
    80005086:	892a                	mv	s2,a0
    80005088:	b7d5                	j	8000506c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000508a:	02451783          	lh	a5,36(a0)
    8000508e:	03079693          	slli	a3,a5,0x30
    80005092:	92c1                	srli	a3,a3,0x30
    80005094:	4725                	li	a4,9
    80005096:	02d76863          	bltu	a4,a3,800050c6 <fileread+0xba>
    8000509a:	0792                	slli	a5,a5,0x4
    8000509c:	0001d717          	auipc	a4,0x1d
    800050a0:	9f470713          	addi	a4,a4,-1548 # 80021a90 <devsw>
    800050a4:	97ba                	add	a5,a5,a4
    800050a6:	639c                	ld	a5,0(a5)
    800050a8:	c38d                	beqz	a5,800050ca <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800050aa:	4505                	li	a0,1
    800050ac:	9782                	jalr	a5
    800050ae:	892a                	mv	s2,a0
    800050b0:	bf75                	j	8000506c <fileread+0x60>
    panic("fileread");
    800050b2:	00003517          	auipc	a0,0x3
    800050b6:	74650513          	addi	a0,a0,1862 # 800087f8 <syscalls+0x268>
    800050ba:	ffffb097          	auipc	ra,0xffffb
    800050be:	484080e7          	jalr	1156(ra) # 8000053e <panic>
    return -1;
    800050c2:	597d                	li	s2,-1
    800050c4:	b765                	j	8000506c <fileread+0x60>
      return -1;
    800050c6:	597d                	li	s2,-1
    800050c8:	b755                	j	8000506c <fileread+0x60>
    800050ca:	597d                	li	s2,-1
    800050cc:	b745                	j	8000506c <fileread+0x60>

00000000800050ce <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800050ce:	715d                	addi	sp,sp,-80
    800050d0:	e486                	sd	ra,72(sp)
    800050d2:	e0a2                	sd	s0,64(sp)
    800050d4:	fc26                	sd	s1,56(sp)
    800050d6:	f84a                	sd	s2,48(sp)
    800050d8:	f44e                	sd	s3,40(sp)
    800050da:	f052                	sd	s4,32(sp)
    800050dc:	ec56                	sd	s5,24(sp)
    800050de:	e85a                	sd	s6,16(sp)
    800050e0:	e45e                	sd	s7,8(sp)
    800050e2:	e062                	sd	s8,0(sp)
    800050e4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800050e6:	00954783          	lbu	a5,9(a0)
    800050ea:	10078663          	beqz	a5,800051f6 <filewrite+0x128>
    800050ee:	892a                	mv	s2,a0
    800050f0:	8aae                	mv	s5,a1
    800050f2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800050f4:	411c                	lw	a5,0(a0)
    800050f6:	4705                	li	a4,1
    800050f8:	02e78263          	beq	a5,a4,8000511c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050fc:	470d                	li	a4,3
    800050fe:	02e78663          	beq	a5,a4,8000512a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005102:	4709                	li	a4,2
    80005104:	0ee79163          	bne	a5,a4,800051e6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005108:	0ac05d63          	blez	a2,800051c2 <filewrite+0xf4>
    int i = 0;
    8000510c:	4981                	li	s3,0
    8000510e:	6b05                	lui	s6,0x1
    80005110:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005114:	6b85                	lui	s7,0x1
    80005116:	c00b8b9b          	addiw	s7,s7,-1024
    8000511a:	a861                	j	800051b2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000511c:	6908                	ld	a0,16(a0)
    8000511e:	00000097          	auipc	ra,0x0
    80005122:	22e080e7          	jalr	558(ra) # 8000534c <pipewrite>
    80005126:	8a2a                	mv	s4,a0
    80005128:	a045                	j	800051c8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000512a:	02451783          	lh	a5,36(a0)
    8000512e:	03079693          	slli	a3,a5,0x30
    80005132:	92c1                	srli	a3,a3,0x30
    80005134:	4725                	li	a4,9
    80005136:	0cd76263          	bltu	a4,a3,800051fa <filewrite+0x12c>
    8000513a:	0792                	slli	a5,a5,0x4
    8000513c:	0001d717          	auipc	a4,0x1d
    80005140:	95470713          	addi	a4,a4,-1708 # 80021a90 <devsw>
    80005144:	97ba                	add	a5,a5,a4
    80005146:	679c                	ld	a5,8(a5)
    80005148:	cbdd                	beqz	a5,800051fe <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000514a:	4505                	li	a0,1
    8000514c:	9782                	jalr	a5
    8000514e:	8a2a                	mv	s4,a0
    80005150:	a8a5                	j	800051c8 <filewrite+0xfa>
    80005152:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005156:	00000097          	auipc	ra,0x0
    8000515a:	8b0080e7          	jalr	-1872(ra) # 80004a06 <begin_op>
      ilock(f->ip);
    8000515e:	01893503          	ld	a0,24(s2)
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	ed2080e7          	jalr	-302(ra) # 80004034 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000516a:	8762                	mv	a4,s8
    8000516c:	02092683          	lw	a3,32(s2)
    80005170:	01598633          	add	a2,s3,s5
    80005174:	4585                	li	a1,1
    80005176:	01893503          	ld	a0,24(s2)
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	266080e7          	jalr	614(ra) # 800043e0 <writei>
    80005182:	84aa                	mv	s1,a0
    80005184:	00a05763          	blez	a0,80005192 <filewrite+0xc4>
        f->off += r;
    80005188:	02092783          	lw	a5,32(s2)
    8000518c:	9fa9                	addw	a5,a5,a0
    8000518e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005192:	01893503          	ld	a0,24(s2)
    80005196:	fffff097          	auipc	ra,0xfffff
    8000519a:	f60080e7          	jalr	-160(ra) # 800040f6 <iunlock>
      end_op();
    8000519e:	00000097          	auipc	ra,0x0
    800051a2:	8e8080e7          	jalr	-1816(ra) # 80004a86 <end_op>

      if(r != n1){
    800051a6:	009c1f63          	bne	s8,s1,800051c4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800051aa:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800051ae:	0149db63          	bge	s3,s4,800051c4 <filewrite+0xf6>
      int n1 = n - i;
    800051b2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800051b6:	84be                	mv	s1,a5
    800051b8:	2781                	sext.w	a5,a5
    800051ba:	f8fb5ce3          	bge	s6,a5,80005152 <filewrite+0x84>
    800051be:	84de                	mv	s1,s7
    800051c0:	bf49                	j	80005152 <filewrite+0x84>
    int i = 0;
    800051c2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800051c4:	013a1f63          	bne	s4,s3,800051e2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800051c8:	8552                	mv	a0,s4
    800051ca:	60a6                	ld	ra,72(sp)
    800051cc:	6406                	ld	s0,64(sp)
    800051ce:	74e2                	ld	s1,56(sp)
    800051d0:	7942                	ld	s2,48(sp)
    800051d2:	79a2                	ld	s3,40(sp)
    800051d4:	7a02                	ld	s4,32(sp)
    800051d6:	6ae2                	ld	s5,24(sp)
    800051d8:	6b42                	ld	s6,16(sp)
    800051da:	6ba2                	ld	s7,8(sp)
    800051dc:	6c02                	ld	s8,0(sp)
    800051de:	6161                	addi	sp,sp,80
    800051e0:	8082                	ret
    ret = (i == n ? n : -1);
    800051e2:	5a7d                	li	s4,-1
    800051e4:	b7d5                	j	800051c8 <filewrite+0xfa>
    panic("filewrite");
    800051e6:	00003517          	auipc	a0,0x3
    800051ea:	62250513          	addi	a0,a0,1570 # 80008808 <syscalls+0x278>
    800051ee:	ffffb097          	auipc	ra,0xffffb
    800051f2:	350080e7          	jalr	848(ra) # 8000053e <panic>
    return -1;
    800051f6:	5a7d                	li	s4,-1
    800051f8:	bfc1                	j	800051c8 <filewrite+0xfa>
      return -1;
    800051fa:	5a7d                	li	s4,-1
    800051fc:	b7f1                	j	800051c8 <filewrite+0xfa>
    800051fe:	5a7d                	li	s4,-1
    80005200:	b7e1                	j	800051c8 <filewrite+0xfa>

0000000080005202 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005202:	7179                	addi	sp,sp,-48
    80005204:	f406                	sd	ra,40(sp)
    80005206:	f022                	sd	s0,32(sp)
    80005208:	ec26                	sd	s1,24(sp)
    8000520a:	e84a                	sd	s2,16(sp)
    8000520c:	e44e                	sd	s3,8(sp)
    8000520e:	e052                	sd	s4,0(sp)
    80005210:	1800                	addi	s0,sp,48
    80005212:	84aa                	mv	s1,a0
    80005214:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005216:	0005b023          	sd	zero,0(a1)
    8000521a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000521e:	00000097          	auipc	ra,0x0
    80005222:	bf8080e7          	jalr	-1032(ra) # 80004e16 <filealloc>
    80005226:	e088                	sd	a0,0(s1)
    80005228:	c551                	beqz	a0,800052b4 <pipealloc+0xb2>
    8000522a:	00000097          	auipc	ra,0x0
    8000522e:	bec080e7          	jalr	-1044(ra) # 80004e16 <filealloc>
    80005232:	00aa3023          	sd	a0,0(s4)
    80005236:	c92d                	beqz	a0,800052a8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005238:	ffffc097          	auipc	ra,0xffffc
    8000523c:	8bc080e7          	jalr	-1860(ra) # 80000af4 <kalloc>
    80005240:	892a                	mv	s2,a0
    80005242:	c125                	beqz	a0,800052a2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005244:	4985                	li	s3,1
    80005246:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000524a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000524e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005252:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005256:	00003597          	auipc	a1,0x3
    8000525a:	5c258593          	addi	a1,a1,1474 # 80008818 <syscalls+0x288>
    8000525e:	ffffc097          	auipc	ra,0xffffc
    80005262:	8f6080e7          	jalr	-1802(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005266:	609c                	ld	a5,0(s1)
    80005268:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000526c:	609c                	ld	a5,0(s1)
    8000526e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005272:	609c                	ld	a5,0(s1)
    80005274:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005278:	609c                	ld	a5,0(s1)
    8000527a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000527e:	000a3783          	ld	a5,0(s4)
    80005282:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005286:	000a3783          	ld	a5,0(s4)
    8000528a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000528e:	000a3783          	ld	a5,0(s4)
    80005292:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005296:	000a3783          	ld	a5,0(s4)
    8000529a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000529e:	4501                	li	a0,0
    800052a0:	a025                	j	800052c8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800052a2:	6088                	ld	a0,0(s1)
    800052a4:	e501                	bnez	a0,800052ac <pipealloc+0xaa>
    800052a6:	a039                	j	800052b4 <pipealloc+0xb2>
    800052a8:	6088                	ld	a0,0(s1)
    800052aa:	c51d                	beqz	a0,800052d8 <pipealloc+0xd6>
    fileclose(*f0);
    800052ac:	00000097          	auipc	ra,0x0
    800052b0:	c26080e7          	jalr	-986(ra) # 80004ed2 <fileclose>
  if(*f1)
    800052b4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800052b8:	557d                	li	a0,-1
  if(*f1)
    800052ba:	c799                	beqz	a5,800052c8 <pipealloc+0xc6>
    fileclose(*f1);
    800052bc:	853e                	mv	a0,a5
    800052be:	00000097          	auipc	ra,0x0
    800052c2:	c14080e7          	jalr	-1004(ra) # 80004ed2 <fileclose>
  return -1;
    800052c6:	557d                	li	a0,-1
}
    800052c8:	70a2                	ld	ra,40(sp)
    800052ca:	7402                	ld	s0,32(sp)
    800052cc:	64e2                	ld	s1,24(sp)
    800052ce:	6942                	ld	s2,16(sp)
    800052d0:	69a2                	ld	s3,8(sp)
    800052d2:	6a02                	ld	s4,0(sp)
    800052d4:	6145                	addi	sp,sp,48
    800052d6:	8082                	ret
  return -1;
    800052d8:	557d                	li	a0,-1
    800052da:	b7fd                	j	800052c8 <pipealloc+0xc6>

00000000800052dc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800052dc:	1101                	addi	sp,sp,-32
    800052de:	ec06                	sd	ra,24(sp)
    800052e0:	e822                	sd	s0,16(sp)
    800052e2:	e426                	sd	s1,8(sp)
    800052e4:	e04a                	sd	s2,0(sp)
    800052e6:	1000                	addi	s0,sp,32
    800052e8:	84aa                	mv	s1,a0
    800052ea:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800052ec:	ffffc097          	auipc	ra,0xffffc
    800052f0:	8f8080e7          	jalr	-1800(ra) # 80000be4 <acquire>
  if(writable){
    800052f4:	02090d63          	beqz	s2,8000532e <pipeclose+0x52>
    pi->writeopen = 0;
    800052f8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800052fc:	21848513          	addi	a0,s1,536
    80005300:	ffffd097          	auipc	ra,0xffffd
    80005304:	7fe080e7          	jalr	2046(ra) # 80002afe <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005308:	2204b783          	ld	a5,544(s1)
    8000530c:	eb95                	bnez	a5,80005340 <pipeclose+0x64>
    release(&pi->lock);
    8000530e:	8526                	mv	a0,s1
    80005310:	ffffc097          	auipc	ra,0xffffc
    80005314:	988080e7          	jalr	-1656(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005318:	8526                	mv	a0,s1
    8000531a:	ffffb097          	auipc	ra,0xffffb
    8000531e:	6de080e7          	jalr	1758(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005322:	60e2                	ld	ra,24(sp)
    80005324:	6442                	ld	s0,16(sp)
    80005326:	64a2                	ld	s1,8(sp)
    80005328:	6902                	ld	s2,0(sp)
    8000532a:	6105                	addi	sp,sp,32
    8000532c:	8082                	ret
    pi->readopen = 0;
    8000532e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005332:	21c48513          	addi	a0,s1,540
    80005336:	ffffd097          	auipc	ra,0xffffd
    8000533a:	7c8080e7          	jalr	1992(ra) # 80002afe <wakeup>
    8000533e:	b7e9                	j	80005308 <pipeclose+0x2c>
    release(&pi->lock);
    80005340:	8526                	mv	a0,s1
    80005342:	ffffc097          	auipc	ra,0xffffc
    80005346:	956080e7          	jalr	-1706(ra) # 80000c98 <release>
}
    8000534a:	bfe1                	j	80005322 <pipeclose+0x46>

000000008000534c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000534c:	7159                	addi	sp,sp,-112
    8000534e:	f486                	sd	ra,104(sp)
    80005350:	f0a2                	sd	s0,96(sp)
    80005352:	eca6                	sd	s1,88(sp)
    80005354:	e8ca                	sd	s2,80(sp)
    80005356:	e4ce                	sd	s3,72(sp)
    80005358:	e0d2                	sd	s4,64(sp)
    8000535a:	fc56                	sd	s5,56(sp)
    8000535c:	f85a                	sd	s6,48(sp)
    8000535e:	f45e                	sd	s7,40(sp)
    80005360:	f062                	sd	s8,32(sp)
    80005362:	ec66                	sd	s9,24(sp)
    80005364:	1880                	addi	s0,sp,112
    80005366:	84aa                	mv	s1,a0
    80005368:	8aae                	mv	s5,a1
    8000536a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000536c:	ffffd097          	auipc	ra,0xffffd
    80005370:	e74080e7          	jalr	-396(ra) # 800021e0 <myproc>
    80005374:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005376:	8526                	mv	a0,s1
    80005378:	ffffc097          	auipc	ra,0xffffc
    8000537c:	86c080e7          	jalr	-1940(ra) # 80000be4 <acquire>
  while(i < n){
    80005380:	0d405163          	blez	s4,80005442 <pipewrite+0xf6>
    80005384:	8ba6                	mv	s7,s1
  int i = 0;
    80005386:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005388:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000538a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000538e:	21c48c13          	addi	s8,s1,540
    80005392:	a08d                	j	800053f4 <pipewrite+0xa8>
      release(&pi->lock);
    80005394:	8526                	mv	a0,s1
    80005396:	ffffc097          	auipc	ra,0xffffc
    8000539a:	902080e7          	jalr	-1790(ra) # 80000c98 <release>
      return -1;
    8000539e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800053a0:	854a                	mv	a0,s2
    800053a2:	70a6                	ld	ra,104(sp)
    800053a4:	7406                	ld	s0,96(sp)
    800053a6:	64e6                	ld	s1,88(sp)
    800053a8:	6946                	ld	s2,80(sp)
    800053aa:	69a6                	ld	s3,72(sp)
    800053ac:	6a06                	ld	s4,64(sp)
    800053ae:	7ae2                	ld	s5,56(sp)
    800053b0:	7b42                	ld	s6,48(sp)
    800053b2:	7ba2                	ld	s7,40(sp)
    800053b4:	7c02                	ld	s8,32(sp)
    800053b6:	6ce2                	ld	s9,24(sp)
    800053b8:	6165                	addi	sp,sp,112
    800053ba:	8082                	ret
      wakeup(&pi->nread);
    800053bc:	8566                	mv	a0,s9
    800053be:	ffffd097          	auipc	ra,0xffffd
    800053c2:	740080e7          	jalr	1856(ra) # 80002afe <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800053c6:	85de                	mv	a1,s7
    800053c8:	8562                	mv	a0,s8
    800053ca:	ffffd097          	auipc	ra,0xffffd
    800053ce:	59a080e7          	jalr	1434(ra) # 80002964 <sleep>
    800053d2:	a839                	j	800053f0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800053d4:	21c4a783          	lw	a5,540(s1)
    800053d8:	0017871b          	addiw	a4,a5,1
    800053dc:	20e4ae23          	sw	a4,540(s1)
    800053e0:	1ff7f793          	andi	a5,a5,511
    800053e4:	97a6                	add	a5,a5,s1
    800053e6:	f9f44703          	lbu	a4,-97(s0)
    800053ea:	00e78c23          	sb	a4,24(a5)
      i++;
    800053ee:	2905                	addiw	s2,s2,1
  while(i < n){
    800053f0:	03495d63          	bge	s2,s4,8000542a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800053f4:	2204a783          	lw	a5,544(s1)
    800053f8:	dfd1                	beqz	a5,80005394 <pipewrite+0x48>
    800053fa:	0409a783          	lw	a5,64(s3)
    800053fe:	fbd9                	bnez	a5,80005394 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005400:	2184a783          	lw	a5,536(s1)
    80005404:	21c4a703          	lw	a4,540(s1)
    80005408:	2007879b          	addiw	a5,a5,512
    8000540c:	faf708e3          	beq	a4,a5,800053bc <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005410:	4685                	li	a3,1
    80005412:	01590633          	add	a2,s2,s5
    80005416:	f9f40593          	addi	a1,s0,-97
    8000541a:	0789b503          	ld	a0,120(s3)
    8000541e:	ffffc097          	auipc	ra,0xffffc
    80005422:	2e0080e7          	jalr	736(ra) # 800016fe <copyin>
    80005426:	fb6517e3          	bne	a0,s6,800053d4 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000542a:	21848513          	addi	a0,s1,536
    8000542e:	ffffd097          	auipc	ra,0xffffd
    80005432:	6d0080e7          	jalr	1744(ra) # 80002afe <wakeup>
  release(&pi->lock);
    80005436:	8526                	mv	a0,s1
    80005438:	ffffc097          	auipc	ra,0xffffc
    8000543c:	860080e7          	jalr	-1952(ra) # 80000c98 <release>
  return i;
    80005440:	b785                	j	800053a0 <pipewrite+0x54>
  int i = 0;
    80005442:	4901                	li	s2,0
    80005444:	b7dd                	j	8000542a <pipewrite+0xde>

0000000080005446 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005446:	715d                	addi	sp,sp,-80
    80005448:	e486                	sd	ra,72(sp)
    8000544a:	e0a2                	sd	s0,64(sp)
    8000544c:	fc26                	sd	s1,56(sp)
    8000544e:	f84a                	sd	s2,48(sp)
    80005450:	f44e                	sd	s3,40(sp)
    80005452:	f052                	sd	s4,32(sp)
    80005454:	ec56                	sd	s5,24(sp)
    80005456:	e85a                	sd	s6,16(sp)
    80005458:	0880                	addi	s0,sp,80
    8000545a:	84aa                	mv	s1,a0
    8000545c:	892e                	mv	s2,a1
    8000545e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005460:	ffffd097          	auipc	ra,0xffffd
    80005464:	d80080e7          	jalr	-640(ra) # 800021e0 <myproc>
    80005468:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000546a:	8b26                	mv	s6,s1
    8000546c:	8526                	mv	a0,s1
    8000546e:	ffffb097          	auipc	ra,0xffffb
    80005472:	776080e7          	jalr	1910(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005476:	2184a703          	lw	a4,536(s1)
    8000547a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000547e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005482:	02f71463          	bne	a4,a5,800054aa <piperead+0x64>
    80005486:	2244a783          	lw	a5,548(s1)
    8000548a:	c385                	beqz	a5,800054aa <piperead+0x64>
    if(pr->killed){
    8000548c:	040a2783          	lw	a5,64(s4)
    80005490:	ebc1                	bnez	a5,80005520 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005492:	85da                	mv	a1,s6
    80005494:	854e                	mv	a0,s3
    80005496:	ffffd097          	auipc	ra,0xffffd
    8000549a:	4ce080e7          	jalr	1230(ra) # 80002964 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000549e:	2184a703          	lw	a4,536(s1)
    800054a2:	21c4a783          	lw	a5,540(s1)
    800054a6:	fef700e3          	beq	a4,a5,80005486 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054aa:	09505263          	blez	s5,8000552e <piperead+0xe8>
    800054ae:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054b0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800054b2:	2184a783          	lw	a5,536(s1)
    800054b6:	21c4a703          	lw	a4,540(s1)
    800054ba:	02f70d63          	beq	a4,a5,800054f4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800054be:	0017871b          	addiw	a4,a5,1
    800054c2:	20e4ac23          	sw	a4,536(s1)
    800054c6:	1ff7f793          	andi	a5,a5,511
    800054ca:	97a6                	add	a5,a5,s1
    800054cc:	0187c783          	lbu	a5,24(a5)
    800054d0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054d4:	4685                	li	a3,1
    800054d6:	fbf40613          	addi	a2,s0,-65
    800054da:	85ca                	mv	a1,s2
    800054dc:	078a3503          	ld	a0,120(s4)
    800054e0:	ffffc097          	auipc	ra,0xffffc
    800054e4:	192080e7          	jalr	402(ra) # 80001672 <copyout>
    800054e8:	01650663          	beq	a0,s6,800054f4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054ec:	2985                	addiw	s3,s3,1
    800054ee:	0905                	addi	s2,s2,1
    800054f0:	fd3a91e3          	bne	s5,s3,800054b2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800054f4:	21c48513          	addi	a0,s1,540
    800054f8:	ffffd097          	auipc	ra,0xffffd
    800054fc:	606080e7          	jalr	1542(ra) # 80002afe <wakeup>
  release(&pi->lock);
    80005500:	8526                	mv	a0,s1
    80005502:	ffffb097          	auipc	ra,0xffffb
    80005506:	796080e7          	jalr	1942(ra) # 80000c98 <release>
  return i;
}
    8000550a:	854e                	mv	a0,s3
    8000550c:	60a6                	ld	ra,72(sp)
    8000550e:	6406                	ld	s0,64(sp)
    80005510:	74e2                	ld	s1,56(sp)
    80005512:	7942                	ld	s2,48(sp)
    80005514:	79a2                	ld	s3,40(sp)
    80005516:	7a02                	ld	s4,32(sp)
    80005518:	6ae2                	ld	s5,24(sp)
    8000551a:	6b42                	ld	s6,16(sp)
    8000551c:	6161                	addi	sp,sp,80
    8000551e:	8082                	ret
      release(&pi->lock);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffb097          	auipc	ra,0xffffb
    80005526:	776080e7          	jalr	1910(ra) # 80000c98 <release>
      return -1;
    8000552a:	59fd                	li	s3,-1
    8000552c:	bff9                	j	8000550a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000552e:	4981                	li	s3,0
    80005530:	b7d1                	j	800054f4 <piperead+0xae>

0000000080005532 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005532:	df010113          	addi	sp,sp,-528
    80005536:	20113423          	sd	ra,520(sp)
    8000553a:	20813023          	sd	s0,512(sp)
    8000553e:	ffa6                	sd	s1,504(sp)
    80005540:	fbca                	sd	s2,496(sp)
    80005542:	f7ce                	sd	s3,488(sp)
    80005544:	f3d2                	sd	s4,480(sp)
    80005546:	efd6                	sd	s5,472(sp)
    80005548:	ebda                	sd	s6,464(sp)
    8000554a:	e7de                	sd	s7,456(sp)
    8000554c:	e3e2                	sd	s8,448(sp)
    8000554e:	ff66                	sd	s9,440(sp)
    80005550:	fb6a                	sd	s10,432(sp)
    80005552:	f76e                	sd	s11,424(sp)
    80005554:	0c00                	addi	s0,sp,528
    80005556:	84aa                	mv	s1,a0
    80005558:	dea43c23          	sd	a0,-520(s0)
    8000555c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005560:	ffffd097          	auipc	ra,0xffffd
    80005564:	c80080e7          	jalr	-896(ra) # 800021e0 <myproc>
    80005568:	892a                	mv	s2,a0

  begin_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	49c080e7          	jalr	1180(ra) # 80004a06 <begin_op>

  if((ip = namei(path)) == 0){
    80005572:	8526                	mv	a0,s1
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	276080e7          	jalr	630(ra) # 800047ea <namei>
    8000557c:	c92d                	beqz	a0,800055ee <exec+0xbc>
    8000557e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	ab4080e7          	jalr	-1356(ra) # 80004034 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005588:	04000713          	li	a4,64
    8000558c:	4681                	li	a3,0
    8000558e:	e5040613          	addi	a2,s0,-432
    80005592:	4581                	li	a1,0
    80005594:	8526                	mv	a0,s1
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	d52080e7          	jalr	-686(ra) # 800042e8 <readi>
    8000559e:	04000793          	li	a5,64
    800055a2:	00f51a63          	bne	a0,a5,800055b6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800055a6:	e5042703          	lw	a4,-432(s0)
    800055aa:	464c47b7          	lui	a5,0x464c4
    800055ae:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800055b2:	04f70463          	beq	a4,a5,800055fa <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800055b6:	8526                	mv	a0,s1
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	cde080e7          	jalr	-802(ra) # 80004296 <iunlockput>
    end_op();
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	4c6080e7          	jalr	1222(ra) # 80004a86 <end_op>
  }
  return -1;
    800055c8:	557d                	li	a0,-1
}
    800055ca:	20813083          	ld	ra,520(sp)
    800055ce:	20013403          	ld	s0,512(sp)
    800055d2:	74fe                	ld	s1,504(sp)
    800055d4:	795e                	ld	s2,496(sp)
    800055d6:	79be                	ld	s3,488(sp)
    800055d8:	7a1e                	ld	s4,480(sp)
    800055da:	6afe                	ld	s5,472(sp)
    800055dc:	6b5e                	ld	s6,464(sp)
    800055de:	6bbe                	ld	s7,456(sp)
    800055e0:	6c1e                	ld	s8,448(sp)
    800055e2:	7cfa                	ld	s9,440(sp)
    800055e4:	7d5a                	ld	s10,432(sp)
    800055e6:	7dba                	ld	s11,424(sp)
    800055e8:	21010113          	addi	sp,sp,528
    800055ec:	8082                	ret
    end_op();
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	498080e7          	jalr	1176(ra) # 80004a86 <end_op>
    return -1;
    800055f6:	557d                	li	a0,-1
    800055f8:	bfc9                	j	800055ca <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800055fa:	854a                	mv	a0,s2
    800055fc:	ffffd097          	auipc	ra,0xffffd
    80005600:	cbc080e7          	jalr	-836(ra) # 800022b8 <proc_pagetable>
    80005604:	8baa                	mv	s7,a0
    80005606:	d945                	beqz	a0,800055b6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005608:	e7042983          	lw	s3,-400(s0)
    8000560c:	e8845783          	lhu	a5,-376(s0)
    80005610:	c7ad                	beqz	a5,8000567a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005612:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005614:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005616:	6c85                	lui	s9,0x1
    80005618:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000561c:	def43823          	sd	a5,-528(s0)
    80005620:	a42d                	j	8000584a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005622:	00003517          	auipc	a0,0x3
    80005626:	1fe50513          	addi	a0,a0,510 # 80008820 <syscalls+0x290>
    8000562a:	ffffb097          	auipc	ra,0xffffb
    8000562e:	f14080e7          	jalr	-236(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005632:	8756                	mv	a4,s5
    80005634:	012d86bb          	addw	a3,s11,s2
    80005638:	4581                	li	a1,0
    8000563a:	8526                	mv	a0,s1
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	cac080e7          	jalr	-852(ra) # 800042e8 <readi>
    80005644:	2501                	sext.w	a0,a0
    80005646:	1aaa9963          	bne	s5,a0,800057f8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000564a:	6785                	lui	a5,0x1
    8000564c:	0127893b          	addw	s2,a5,s2
    80005650:	77fd                	lui	a5,0xfffff
    80005652:	01478a3b          	addw	s4,a5,s4
    80005656:	1f897163          	bgeu	s2,s8,80005838 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000565a:	02091593          	slli	a1,s2,0x20
    8000565e:	9181                	srli	a1,a1,0x20
    80005660:	95ea                	add	a1,a1,s10
    80005662:	855e                	mv	a0,s7
    80005664:	ffffc097          	auipc	ra,0xffffc
    80005668:	a0a080e7          	jalr	-1526(ra) # 8000106e <walkaddr>
    8000566c:	862a                	mv	a2,a0
    if(pa == 0)
    8000566e:	d955                	beqz	a0,80005622 <exec+0xf0>
      n = PGSIZE;
    80005670:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005672:	fd9a70e3          	bgeu	s4,s9,80005632 <exec+0x100>
      n = sz - i;
    80005676:	8ad2                	mv	s5,s4
    80005678:	bf6d                	j	80005632 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000567a:	4901                	li	s2,0
  iunlockput(ip);
    8000567c:	8526                	mv	a0,s1
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	c18080e7          	jalr	-1000(ra) # 80004296 <iunlockput>
  end_op();
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	400080e7          	jalr	1024(ra) # 80004a86 <end_op>
  p = myproc();
    8000568e:	ffffd097          	auipc	ra,0xffffd
    80005692:	b52080e7          	jalr	-1198(ra) # 800021e0 <myproc>
    80005696:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005698:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    8000569c:	6785                	lui	a5,0x1
    8000569e:	17fd                	addi	a5,a5,-1
    800056a0:	993e                	add	s2,s2,a5
    800056a2:	757d                	lui	a0,0xfffff
    800056a4:	00a977b3          	and	a5,s2,a0
    800056a8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800056ac:	6609                	lui	a2,0x2
    800056ae:	963e                	add	a2,a2,a5
    800056b0:	85be                	mv	a1,a5
    800056b2:	855e                	mv	a0,s7
    800056b4:	ffffc097          	auipc	ra,0xffffc
    800056b8:	d6e080e7          	jalr	-658(ra) # 80001422 <uvmalloc>
    800056bc:	8b2a                	mv	s6,a0
  ip = 0;
    800056be:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800056c0:	12050c63          	beqz	a0,800057f8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800056c4:	75f9                	lui	a1,0xffffe
    800056c6:	95aa                	add	a1,a1,a0
    800056c8:	855e                	mv	a0,s7
    800056ca:	ffffc097          	auipc	ra,0xffffc
    800056ce:	f76080e7          	jalr	-138(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800056d2:	7c7d                	lui	s8,0xfffff
    800056d4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800056d6:	e0043783          	ld	a5,-512(s0)
    800056da:	6388                	ld	a0,0(a5)
    800056dc:	c535                	beqz	a0,80005748 <exec+0x216>
    800056de:	e9040993          	addi	s3,s0,-368
    800056e2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800056e6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800056e8:	ffffb097          	auipc	ra,0xffffb
    800056ec:	77c080e7          	jalr	1916(ra) # 80000e64 <strlen>
    800056f0:	2505                	addiw	a0,a0,1
    800056f2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800056f6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800056fa:	13896363          	bltu	s2,s8,80005820 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800056fe:	e0043d83          	ld	s11,-512(s0)
    80005702:	000dba03          	ld	s4,0(s11)
    80005706:	8552                	mv	a0,s4
    80005708:	ffffb097          	auipc	ra,0xffffb
    8000570c:	75c080e7          	jalr	1884(ra) # 80000e64 <strlen>
    80005710:	0015069b          	addiw	a3,a0,1
    80005714:	8652                	mv	a2,s4
    80005716:	85ca                	mv	a1,s2
    80005718:	855e                	mv	a0,s7
    8000571a:	ffffc097          	auipc	ra,0xffffc
    8000571e:	f58080e7          	jalr	-168(ra) # 80001672 <copyout>
    80005722:	10054363          	bltz	a0,80005828 <exec+0x2f6>
    ustack[argc] = sp;
    80005726:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000572a:	0485                	addi	s1,s1,1
    8000572c:	008d8793          	addi	a5,s11,8
    80005730:	e0f43023          	sd	a5,-512(s0)
    80005734:	008db503          	ld	a0,8(s11)
    80005738:	c911                	beqz	a0,8000574c <exec+0x21a>
    if(argc >= MAXARG)
    8000573a:	09a1                	addi	s3,s3,8
    8000573c:	fb3c96e3          	bne	s9,s3,800056e8 <exec+0x1b6>
  sz = sz1;
    80005740:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005744:	4481                	li	s1,0
    80005746:	a84d                	j	800057f8 <exec+0x2c6>
  sp = sz;
    80005748:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000574a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000574c:	00349793          	slli	a5,s1,0x3
    80005750:	f9040713          	addi	a4,s0,-112
    80005754:	97ba                	add	a5,a5,a4
    80005756:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000575a:	00148693          	addi	a3,s1,1
    8000575e:	068e                	slli	a3,a3,0x3
    80005760:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005764:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005768:	01897663          	bgeu	s2,s8,80005774 <exec+0x242>
  sz = sz1;
    8000576c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005770:	4481                	li	s1,0
    80005772:	a059                	j	800057f8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005774:	e9040613          	addi	a2,s0,-368
    80005778:	85ca                	mv	a1,s2
    8000577a:	855e                	mv	a0,s7
    8000577c:	ffffc097          	auipc	ra,0xffffc
    80005780:	ef6080e7          	jalr	-266(ra) # 80001672 <copyout>
    80005784:	0a054663          	bltz	a0,80005830 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005788:	080ab783          	ld	a5,128(s5)
    8000578c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005790:	df843783          	ld	a5,-520(s0)
    80005794:	0007c703          	lbu	a4,0(a5)
    80005798:	cf11                	beqz	a4,800057b4 <exec+0x282>
    8000579a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000579c:	02f00693          	li	a3,47
    800057a0:	a039                	j	800057ae <exec+0x27c>
      last = s+1;
    800057a2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800057a6:	0785                	addi	a5,a5,1
    800057a8:	fff7c703          	lbu	a4,-1(a5)
    800057ac:	c701                	beqz	a4,800057b4 <exec+0x282>
    if(*s == '/')
    800057ae:	fed71ce3          	bne	a4,a3,800057a6 <exec+0x274>
    800057b2:	bfc5                	j	800057a2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800057b4:	4641                	li	a2,16
    800057b6:	df843583          	ld	a1,-520(s0)
    800057ba:	180a8513          	addi	a0,s5,384
    800057be:	ffffb097          	auipc	ra,0xffffb
    800057c2:	674080e7          	jalr	1652(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800057c6:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    800057ca:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    800057ce:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800057d2:	080ab783          	ld	a5,128(s5)
    800057d6:	e6843703          	ld	a4,-408(s0)
    800057da:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800057dc:	080ab783          	ld	a5,128(s5)
    800057e0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800057e4:	85ea                	mv	a1,s10
    800057e6:	ffffd097          	auipc	ra,0xffffd
    800057ea:	b6e080e7          	jalr	-1170(ra) # 80002354 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800057ee:	0004851b          	sext.w	a0,s1
    800057f2:	bbe1                	j	800055ca <exec+0x98>
    800057f4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800057f8:	e0843583          	ld	a1,-504(s0)
    800057fc:	855e                	mv	a0,s7
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	b56080e7          	jalr	-1194(ra) # 80002354 <proc_freepagetable>
  if(ip){
    80005806:	da0498e3          	bnez	s1,800055b6 <exec+0x84>
  return -1;
    8000580a:	557d                	li	a0,-1
    8000580c:	bb7d                	j	800055ca <exec+0x98>
    8000580e:	e1243423          	sd	s2,-504(s0)
    80005812:	b7dd                	j	800057f8 <exec+0x2c6>
    80005814:	e1243423          	sd	s2,-504(s0)
    80005818:	b7c5                	j	800057f8 <exec+0x2c6>
    8000581a:	e1243423          	sd	s2,-504(s0)
    8000581e:	bfe9                	j	800057f8 <exec+0x2c6>
  sz = sz1;
    80005820:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005824:	4481                	li	s1,0
    80005826:	bfc9                	j	800057f8 <exec+0x2c6>
  sz = sz1;
    80005828:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000582c:	4481                	li	s1,0
    8000582e:	b7e9                	j	800057f8 <exec+0x2c6>
  sz = sz1;
    80005830:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005834:	4481                	li	s1,0
    80005836:	b7c9                	j	800057f8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005838:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000583c:	2b05                	addiw	s6,s6,1
    8000583e:	0389899b          	addiw	s3,s3,56
    80005842:	e8845783          	lhu	a5,-376(s0)
    80005846:	e2fb5be3          	bge	s6,a5,8000567c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000584a:	2981                	sext.w	s3,s3
    8000584c:	03800713          	li	a4,56
    80005850:	86ce                	mv	a3,s3
    80005852:	e1840613          	addi	a2,s0,-488
    80005856:	4581                	li	a1,0
    80005858:	8526                	mv	a0,s1
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	a8e080e7          	jalr	-1394(ra) # 800042e8 <readi>
    80005862:	03800793          	li	a5,56
    80005866:	f8f517e3          	bne	a0,a5,800057f4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000586a:	e1842783          	lw	a5,-488(s0)
    8000586e:	4705                	li	a4,1
    80005870:	fce796e3          	bne	a5,a4,8000583c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005874:	e4043603          	ld	a2,-448(s0)
    80005878:	e3843783          	ld	a5,-456(s0)
    8000587c:	f8f669e3          	bltu	a2,a5,8000580e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005880:	e2843783          	ld	a5,-472(s0)
    80005884:	963e                	add	a2,a2,a5
    80005886:	f8f667e3          	bltu	a2,a5,80005814 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000588a:	85ca                	mv	a1,s2
    8000588c:	855e                	mv	a0,s7
    8000588e:	ffffc097          	auipc	ra,0xffffc
    80005892:	b94080e7          	jalr	-1132(ra) # 80001422 <uvmalloc>
    80005896:	e0a43423          	sd	a0,-504(s0)
    8000589a:	d141                	beqz	a0,8000581a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000589c:	e2843d03          	ld	s10,-472(s0)
    800058a0:	df043783          	ld	a5,-528(s0)
    800058a4:	00fd77b3          	and	a5,s10,a5
    800058a8:	fba1                	bnez	a5,800057f8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800058aa:	e2042d83          	lw	s11,-480(s0)
    800058ae:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800058b2:	f80c03e3          	beqz	s8,80005838 <exec+0x306>
    800058b6:	8a62                	mv	s4,s8
    800058b8:	4901                	li	s2,0
    800058ba:	b345                	j	8000565a <exec+0x128>

00000000800058bc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800058bc:	7179                	addi	sp,sp,-48
    800058be:	f406                	sd	ra,40(sp)
    800058c0:	f022                	sd	s0,32(sp)
    800058c2:	ec26                	sd	s1,24(sp)
    800058c4:	e84a                	sd	s2,16(sp)
    800058c6:	1800                	addi	s0,sp,48
    800058c8:	892e                	mv	s2,a1
    800058ca:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800058cc:	fdc40593          	addi	a1,s0,-36
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	ba8080e7          	jalr	-1112(ra) # 80003478 <argint>
    800058d8:	04054063          	bltz	a0,80005918 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800058dc:	fdc42703          	lw	a4,-36(s0)
    800058e0:	47bd                	li	a5,15
    800058e2:	02e7ed63          	bltu	a5,a4,8000591c <argfd+0x60>
    800058e6:	ffffd097          	auipc	ra,0xffffd
    800058ea:	8fa080e7          	jalr	-1798(ra) # 800021e0 <myproc>
    800058ee:	fdc42703          	lw	a4,-36(s0)
    800058f2:	01e70793          	addi	a5,a4,30
    800058f6:	078e                	slli	a5,a5,0x3
    800058f8:	953e                	add	a0,a0,a5
    800058fa:	651c                	ld	a5,8(a0)
    800058fc:	c395                	beqz	a5,80005920 <argfd+0x64>
    return -1;
  if(pfd)
    800058fe:	00090463          	beqz	s2,80005906 <argfd+0x4a>
    *pfd = fd;
    80005902:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005906:	4501                	li	a0,0
  if(pf)
    80005908:	c091                	beqz	s1,8000590c <argfd+0x50>
    *pf = f;
    8000590a:	e09c                	sd	a5,0(s1)
}
    8000590c:	70a2                	ld	ra,40(sp)
    8000590e:	7402                	ld	s0,32(sp)
    80005910:	64e2                	ld	s1,24(sp)
    80005912:	6942                	ld	s2,16(sp)
    80005914:	6145                	addi	sp,sp,48
    80005916:	8082                	ret
    return -1;
    80005918:	557d                	li	a0,-1
    8000591a:	bfcd                	j	8000590c <argfd+0x50>
    return -1;
    8000591c:	557d                	li	a0,-1
    8000591e:	b7fd                	j	8000590c <argfd+0x50>
    80005920:	557d                	li	a0,-1
    80005922:	b7ed                	j	8000590c <argfd+0x50>

0000000080005924 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005924:	1101                	addi	sp,sp,-32
    80005926:	ec06                	sd	ra,24(sp)
    80005928:	e822                	sd	s0,16(sp)
    8000592a:	e426                	sd	s1,8(sp)
    8000592c:	1000                	addi	s0,sp,32
    8000592e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005930:	ffffd097          	auipc	ra,0xffffd
    80005934:	8b0080e7          	jalr	-1872(ra) # 800021e0 <myproc>
    80005938:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000593a:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    8000593e:	4501                	li	a0,0
    80005940:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005942:	6398                	ld	a4,0(a5)
    80005944:	cb19                	beqz	a4,8000595a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005946:	2505                	addiw	a0,a0,1
    80005948:	07a1                	addi	a5,a5,8
    8000594a:	fed51ce3          	bne	a0,a3,80005942 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000594e:	557d                	li	a0,-1
}
    80005950:	60e2                	ld	ra,24(sp)
    80005952:	6442                	ld	s0,16(sp)
    80005954:	64a2                	ld	s1,8(sp)
    80005956:	6105                	addi	sp,sp,32
    80005958:	8082                	ret
      p->ofile[fd] = f;
    8000595a:	01e50793          	addi	a5,a0,30
    8000595e:	078e                	slli	a5,a5,0x3
    80005960:	963e                	add	a2,a2,a5
    80005962:	e604                	sd	s1,8(a2)
      return fd;
    80005964:	b7f5                	j	80005950 <fdalloc+0x2c>

0000000080005966 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005966:	715d                	addi	sp,sp,-80
    80005968:	e486                	sd	ra,72(sp)
    8000596a:	e0a2                	sd	s0,64(sp)
    8000596c:	fc26                	sd	s1,56(sp)
    8000596e:	f84a                	sd	s2,48(sp)
    80005970:	f44e                	sd	s3,40(sp)
    80005972:	f052                	sd	s4,32(sp)
    80005974:	ec56                	sd	s5,24(sp)
    80005976:	0880                	addi	s0,sp,80
    80005978:	89ae                	mv	s3,a1
    8000597a:	8ab2                	mv	s5,a2
    8000597c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000597e:	fb040593          	addi	a1,s0,-80
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	e86080e7          	jalr	-378(ra) # 80004808 <nameiparent>
    8000598a:	892a                	mv	s2,a0
    8000598c:	12050f63          	beqz	a0,80005aca <create+0x164>
    return 0;

  ilock(dp);
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	6a4080e7          	jalr	1700(ra) # 80004034 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005998:	4601                	li	a2,0
    8000599a:	fb040593          	addi	a1,s0,-80
    8000599e:	854a                	mv	a0,s2
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	b78080e7          	jalr	-1160(ra) # 80004518 <dirlookup>
    800059a8:	84aa                	mv	s1,a0
    800059aa:	c921                	beqz	a0,800059fa <create+0x94>
    iunlockput(dp);
    800059ac:	854a                	mv	a0,s2
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	8e8080e7          	jalr	-1816(ra) # 80004296 <iunlockput>
    ilock(ip);
    800059b6:	8526                	mv	a0,s1
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	67c080e7          	jalr	1660(ra) # 80004034 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800059c0:	2981                	sext.w	s3,s3
    800059c2:	4789                	li	a5,2
    800059c4:	02f99463          	bne	s3,a5,800059ec <create+0x86>
    800059c8:	0444d783          	lhu	a5,68(s1)
    800059cc:	37f9                	addiw	a5,a5,-2
    800059ce:	17c2                	slli	a5,a5,0x30
    800059d0:	93c1                	srli	a5,a5,0x30
    800059d2:	4705                	li	a4,1
    800059d4:	00f76c63          	bltu	a4,a5,800059ec <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800059d8:	8526                	mv	a0,s1
    800059da:	60a6                	ld	ra,72(sp)
    800059dc:	6406                	ld	s0,64(sp)
    800059de:	74e2                	ld	s1,56(sp)
    800059e0:	7942                	ld	s2,48(sp)
    800059e2:	79a2                	ld	s3,40(sp)
    800059e4:	7a02                	ld	s4,32(sp)
    800059e6:	6ae2                	ld	s5,24(sp)
    800059e8:	6161                	addi	sp,sp,80
    800059ea:	8082                	ret
    iunlockput(ip);
    800059ec:	8526                	mv	a0,s1
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	8a8080e7          	jalr	-1880(ra) # 80004296 <iunlockput>
    return 0;
    800059f6:	4481                	li	s1,0
    800059f8:	b7c5                	j	800059d8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800059fa:	85ce                	mv	a1,s3
    800059fc:	00092503          	lw	a0,0(s2)
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	49c080e7          	jalr	1180(ra) # 80003e9c <ialloc>
    80005a08:	84aa                	mv	s1,a0
    80005a0a:	c529                	beqz	a0,80005a54 <create+0xee>
  ilock(ip);
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	628080e7          	jalr	1576(ra) # 80004034 <ilock>
  ip->major = major;
    80005a14:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005a18:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005a1c:	4785                	li	a5,1
    80005a1e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a22:	8526                	mv	a0,s1
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	546080e7          	jalr	1350(ra) # 80003f6a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005a2c:	2981                	sext.w	s3,s3
    80005a2e:	4785                	li	a5,1
    80005a30:	02f98a63          	beq	s3,a5,80005a64 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a34:	40d0                	lw	a2,4(s1)
    80005a36:	fb040593          	addi	a1,s0,-80
    80005a3a:	854a                	mv	a0,s2
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	cec080e7          	jalr	-788(ra) # 80004728 <dirlink>
    80005a44:	06054b63          	bltz	a0,80005aba <create+0x154>
  iunlockput(dp);
    80005a48:	854a                	mv	a0,s2
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	84c080e7          	jalr	-1972(ra) # 80004296 <iunlockput>
  return ip;
    80005a52:	b759                	j	800059d8 <create+0x72>
    panic("create: ialloc");
    80005a54:	00003517          	auipc	a0,0x3
    80005a58:	dec50513          	addi	a0,a0,-532 # 80008840 <syscalls+0x2b0>
    80005a5c:	ffffb097          	auipc	ra,0xffffb
    80005a60:	ae2080e7          	jalr	-1310(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005a64:	04a95783          	lhu	a5,74(s2)
    80005a68:	2785                	addiw	a5,a5,1
    80005a6a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005a6e:	854a                	mv	a0,s2
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	4fa080e7          	jalr	1274(ra) # 80003f6a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a78:	40d0                	lw	a2,4(s1)
    80005a7a:	00003597          	auipc	a1,0x3
    80005a7e:	dd658593          	addi	a1,a1,-554 # 80008850 <syscalls+0x2c0>
    80005a82:	8526                	mv	a0,s1
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	ca4080e7          	jalr	-860(ra) # 80004728 <dirlink>
    80005a8c:	00054f63          	bltz	a0,80005aaa <create+0x144>
    80005a90:	00492603          	lw	a2,4(s2)
    80005a94:	00003597          	auipc	a1,0x3
    80005a98:	dc458593          	addi	a1,a1,-572 # 80008858 <syscalls+0x2c8>
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	c8a080e7          	jalr	-886(ra) # 80004728 <dirlink>
    80005aa6:	f80557e3          	bgez	a0,80005a34 <create+0xce>
      panic("create dots");
    80005aaa:	00003517          	auipc	a0,0x3
    80005aae:	db650513          	addi	a0,a0,-586 # 80008860 <syscalls+0x2d0>
    80005ab2:	ffffb097          	auipc	ra,0xffffb
    80005ab6:	a8c080e7          	jalr	-1396(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005aba:	00003517          	auipc	a0,0x3
    80005abe:	db650513          	addi	a0,a0,-586 # 80008870 <syscalls+0x2e0>
    80005ac2:	ffffb097          	auipc	ra,0xffffb
    80005ac6:	a7c080e7          	jalr	-1412(ra) # 8000053e <panic>
    return 0;
    80005aca:	84aa                	mv	s1,a0
    80005acc:	b731                	j	800059d8 <create+0x72>

0000000080005ace <sys_dup>:
{
    80005ace:	7179                	addi	sp,sp,-48
    80005ad0:	f406                	sd	ra,40(sp)
    80005ad2:	f022                	sd	s0,32(sp)
    80005ad4:	ec26                	sd	s1,24(sp)
    80005ad6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005ad8:	fd840613          	addi	a2,s0,-40
    80005adc:	4581                	li	a1,0
    80005ade:	4501                	li	a0,0
    80005ae0:	00000097          	auipc	ra,0x0
    80005ae4:	ddc080e7          	jalr	-548(ra) # 800058bc <argfd>
    return -1;
    80005ae8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005aea:	02054363          	bltz	a0,80005b10 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005aee:	fd843503          	ld	a0,-40(s0)
    80005af2:	00000097          	auipc	ra,0x0
    80005af6:	e32080e7          	jalr	-462(ra) # 80005924 <fdalloc>
    80005afa:	84aa                	mv	s1,a0
    return -1;
    80005afc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005afe:	00054963          	bltz	a0,80005b10 <sys_dup+0x42>
  filedup(f);
    80005b02:	fd843503          	ld	a0,-40(s0)
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	37a080e7          	jalr	890(ra) # 80004e80 <filedup>
  return fd;
    80005b0e:	87a6                	mv	a5,s1
}
    80005b10:	853e                	mv	a0,a5
    80005b12:	70a2                	ld	ra,40(sp)
    80005b14:	7402                	ld	s0,32(sp)
    80005b16:	64e2                	ld	s1,24(sp)
    80005b18:	6145                	addi	sp,sp,48
    80005b1a:	8082                	ret

0000000080005b1c <sys_read>:
{
    80005b1c:	7179                	addi	sp,sp,-48
    80005b1e:	f406                	sd	ra,40(sp)
    80005b20:	f022                	sd	s0,32(sp)
    80005b22:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b24:	fe840613          	addi	a2,s0,-24
    80005b28:	4581                	li	a1,0
    80005b2a:	4501                	li	a0,0
    80005b2c:	00000097          	auipc	ra,0x0
    80005b30:	d90080e7          	jalr	-624(ra) # 800058bc <argfd>
    return -1;
    80005b34:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b36:	04054163          	bltz	a0,80005b78 <sys_read+0x5c>
    80005b3a:	fe440593          	addi	a1,s0,-28
    80005b3e:	4509                	li	a0,2
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	938080e7          	jalr	-1736(ra) # 80003478 <argint>
    return -1;
    80005b48:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b4a:	02054763          	bltz	a0,80005b78 <sys_read+0x5c>
    80005b4e:	fd840593          	addi	a1,s0,-40
    80005b52:	4505                	li	a0,1
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	946080e7          	jalr	-1722(ra) # 8000349a <argaddr>
    return -1;
    80005b5c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b5e:	00054d63          	bltz	a0,80005b78 <sys_read+0x5c>
  return fileread(f, p, n);
    80005b62:	fe442603          	lw	a2,-28(s0)
    80005b66:	fd843583          	ld	a1,-40(s0)
    80005b6a:	fe843503          	ld	a0,-24(s0)
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	49e080e7          	jalr	1182(ra) # 8000500c <fileread>
    80005b76:	87aa                	mv	a5,a0
}
    80005b78:	853e                	mv	a0,a5
    80005b7a:	70a2                	ld	ra,40(sp)
    80005b7c:	7402                	ld	s0,32(sp)
    80005b7e:	6145                	addi	sp,sp,48
    80005b80:	8082                	ret

0000000080005b82 <sys_write>:
{
    80005b82:	7179                	addi	sp,sp,-48
    80005b84:	f406                	sd	ra,40(sp)
    80005b86:	f022                	sd	s0,32(sp)
    80005b88:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b8a:	fe840613          	addi	a2,s0,-24
    80005b8e:	4581                	li	a1,0
    80005b90:	4501                	li	a0,0
    80005b92:	00000097          	auipc	ra,0x0
    80005b96:	d2a080e7          	jalr	-726(ra) # 800058bc <argfd>
    return -1;
    80005b9a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b9c:	04054163          	bltz	a0,80005bde <sys_write+0x5c>
    80005ba0:	fe440593          	addi	a1,s0,-28
    80005ba4:	4509                	li	a0,2
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	8d2080e7          	jalr	-1838(ra) # 80003478 <argint>
    return -1;
    80005bae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bb0:	02054763          	bltz	a0,80005bde <sys_write+0x5c>
    80005bb4:	fd840593          	addi	a1,s0,-40
    80005bb8:	4505                	li	a0,1
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	8e0080e7          	jalr	-1824(ra) # 8000349a <argaddr>
    return -1;
    80005bc2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bc4:	00054d63          	bltz	a0,80005bde <sys_write+0x5c>
  return filewrite(f, p, n);
    80005bc8:	fe442603          	lw	a2,-28(s0)
    80005bcc:	fd843583          	ld	a1,-40(s0)
    80005bd0:	fe843503          	ld	a0,-24(s0)
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	4fa080e7          	jalr	1274(ra) # 800050ce <filewrite>
    80005bdc:	87aa                	mv	a5,a0
}
    80005bde:	853e                	mv	a0,a5
    80005be0:	70a2                	ld	ra,40(sp)
    80005be2:	7402                	ld	s0,32(sp)
    80005be4:	6145                	addi	sp,sp,48
    80005be6:	8082                	ret

0000000080005be8 <sys_close>:
{
    80005be8:	1101                	addi	sp,sp,-32
    80005bea:	ec06                	sd	ra,24(sp)
    80005bec:	e822                	sd	s0,16(sp)
    80005bee:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005bf0:	fe040613          	addi	a2,s0,-32
    80005bf4:	fec40593          	addi	a1,s0,-20
    80005bf8:	4501                	li	a0,0
    80005bfa:	00000097          	auipc	ra,0x0
    80005bfe:	cc2080e7          	jalr	-830(ra) # 800058bc <argfd>
    return -1;
    80005c02:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c04:	02054463          	bltz	a0,80005c2c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c08:	ffffc097          	auipc	ra,0xffffc
    80005c0c:	5d8080e7          	jalr	1496(ra) # 800021e0 <myproc>
    80005c10:	fec42783          	lw	a5,-20(s0)
    80005c14:	07f9                	addi	a5,a5,30
    80005c16:	078e                	slli	a5,a5,0x3
    80005c18:	97aa                	add	a5,a5,a0
    80005c1a:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005c1e:	fe043503          	ld	a0,-32(s0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	2b0080e7          	jalr	688(ra) # 80004ed2 <fileclose>
  return 0;
    80005c2a:	4781                	li	a5,0
}
    80005c2c:	853e                	mv	a0,a5
    80005c2e:	60e2                	ld	ra,24(sp)
    80005c30:	6442                	ld	s0,16(sp)
    80005c32:	6105                	addi	sp,sp,32
    80005c34:	8082                	ret

0000000080005c36 <sys_fstat>:
{
    80005c36:	1101                	addi	sp,sp,-32
    80005c38:	ec06                	sd	ra,24(sp)
    80005c3a:	e822                	sd	s0,16(sp)
    80005c3c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c3e:	fe840613          	addi	a2,s0,-24
    80005c42:	4581                	li	a1,0
    80005c44:	4501                	li	a0,0
    80005c46:	00000097          	auipc	ra,0x0
    80005c4a:	c76080e7          	jalr	-906(ra) # 800058bc <argfd>
    return -1;
    80005c4e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c50:	02054563          	bltz	a0,80005c7a <sys_fstat+0x44>
    80005c54:	fe040593          	addi	a1,s0,-32
    80005c58:	4505                	li	a0,1
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	840080e7          	jalr	-1984(ra) # 8000349a <argaddr>
    return -1;
    80005c62:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c64:	00054b63          	bltz	a0,80005c7a <sys_fstat+0x44>
  return filestat(f, st);
    80005c68:	fe043583          	ld	a1,-32(s0)
    80005c6c:	fe843503          	ld	a0,-24(s0)
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	32a080e7          	jalr	810(ra) # 80004f9a <filestat>
    80005c78:	87aa                	mv	a5,a0
}
    80005c7a:	853e                	mv	a0,a5
    80005c7c:	60e2                	ld	ra,24(sp)
    80005c7e:	6442                	ld	s0,16(sp)
    80005c80:	6105                	addi	sp,sp,32
    80005c82:	8082                	ret

0000000080005c84 <sys_link>:
{
    80005c84:	7169                	addi	sp,sp,-304
    80005c86:	f606                	sd	ra,296(sp)
    80005c88:	f222                	sd	s0,288(sp)
    80005c8a:	ee26                	sd	s1,280(sp)
    80005c8c:	ea4a                	sd	s2,272(sp)
    80005c8e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c90:	08000613          	li	a2,128
    80005c94:	ed040593          	addi	a1,s0,-304
    80005c98:	4501                	li	a0,0
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	822080e7          	jalr	-2014(ra) # 800034bc <argstr>
    return -1;
    80005ca2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ca4:	10054e63          	bltz	a0,80005dc0 <sys_link+0x13c>
    80005ca8:	08000613          	li	a2,128
    80005cac:	f5040593          	addi	a1,s0,-176
    80005cb0:	4505                	li	a0,1
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	80a080e7          	jalr	-2038(ra) # 800034bc <argstr>
    return -1;
    80005cba:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cbc:	10054263          	bltz	a0,80005dc0 <sys_link+0x13c>
  begin_op();
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	d46080e7          	jalr	-698(ra) # 80004a06 <begin_op>
  if((ip = namei(old)) == 0){
    80005cc8:	ed040513          	addi	a0,s0,-304
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	b1e080e7          	jalr	-1250(ra) # 800047ea <namei>
    80005cd4:	84aa                	mv	s1,a0
    80005cd6:	c551                	beqz	a0,80005d62 <sys_link+0xde>
  ilock(ip);
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	35c080e7          	jalr	860(ra) # 80004034 <ilock>
  if(ip->type == T_DIR){
    80005ce0:	04449703          	lh	a4,68(s1)
    80005ce4:	4785                	li	a5,1
    80005ce6:	08f70463          	beq	a4,a5,80005d6e <sys_link+0xea>
  ip->nlink++;
    80005cea:	04a4d783          	lhu	a5,74(s1)
    80005cee:	2785                	addiw	a5,a5,1
    80005cf0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005cf4:	8526                	mv	a0,s1
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	274080e7          	jalr	628(ra) # 80003f6a <iupdate>
  iunlock(ip);
    80005cfe:	8526                	mv	a0,s1
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	3f6080e7          	jalr	1014(ra) # 800040f6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005d08:	fd040593          	addi	a1,s0,-48
    80005d0c:	f5040513          	addi	a0,s0,-176
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	af8080e7          	jalr	-1288(ra) # 80004808 <nameiparent>
    80005d18:	892a                	mv	s2,a0
    80005d1a:	c935                	beqz	a0,80005d8e <sys_link+0x10a>
  ilock(dp);
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	318080e7          	jalr	792(ra) # 80004034 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005d24:	00092703          	lw	a4,0(s2)
    80005d28:	409c                	lw	a5,0(s1)
    80005d2a:	04f71d63          	bne	a4,a5,80005d84 <sys_link+0x100>
    80005d2e:	40d0                	lw	a2,4(s1)
    80005d30:	fd040593          	addi	a1,s0,-48
    80005d34:	854a                	mv	a0,s2
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	9f2080e7          	jalr	-1550(ra) # 80004728 <dirlink>
    80005d3e:	04054363          	bltz	a0,80005d84 <sys_link+0x100>
  iunlockput(dp);
    80005d42:	854a                	mv	a0,s2
    80005d44:	ffffe097          	auipc	ra,0xffffe
    80005d48:	552080e7          	jalr	1362(ra) # 80004296 <iunlockput>
  iput(ip);
    80005d4c:	8526                	mv	a0,s1
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	4a0080e7          	jalr	1184(ra) # 800041ee <iput>
  end_op();
    80005d56:	fffff097          	auipc	ra,0xfffff
    80005d5a:	d30080e7          	jalr	-720(ra) # 80004a86 <end_op>
  return 0;
    80005d5e:	4781                	li	a5,0
    80005d60:	a085                	j	80005dc0 <sys_link+0x13c>
    end_op();
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	d24080e7          	jalr	-732(ra) # 80004a86 <end_op>
    return -1;
    80005d6a:	57fd                	li	a5,-1
    80005d6c:	a891                	j	80005dc0 <sys_link+0x13c>
    iunlockput(ip);
    80005d6e:	8526                	mv	a0,s1
    80005d70:	ffffe097          	auipc	ra,0xffffe
    80005d74:	526080e7          	jalr	1318(ra) # 80004296 <iunlockput>
    end_op();
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	d0e080e7          	jalr	-754(ra) # 80004a86 <end_op>
    return -1;
    80005d80:	57fd                	li	a5,-1
    80005d82:	a83d                	j	80005dc0 <sys_link+0x13c>
    iunlockput(dp);
    80005d84:	854a                	mv	a0,s2
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	510080e7          	jalr	1296(ra) # 80004296 <iunlockput>
  ilock(ip);
    80005d8e:	8526                	mv	a0,s1
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	2a4080e7          	jalr	676(ra) # 80004034 <ilock>
  ip->nlink--;
    80005d98:	04a4d783          	lhu	a5,74(s1)
    80005d9c:	37fd                	addiw	a5,a5,-1
    80005d9e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005da2:	8526                	mv	a0,s1
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	1c6080e7          	jalr	454(ra) # 80003f6a <iupdate>
  iunlockput(ip);
    80005dac:	8526                	mv	a0,s1
    80005dae:	ffffe097          	auipc	ra,0xffffe
    80005db2:	4e8080e7          	jalr	1256(ra) # 80004296 <iunlockput>
  end_op();
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	cd0080e7          	jalr	-816(ra) # 80004a86 <end_op>
  return -1;
    80005dbe:	57fd                	li	a5,-1
}
    80005dc0:	853e                	mv	a0,a5
    80005dc2:	70b2                	ld	ra,296(sp)
    80005dc4:	7412                	ld	s0,288(sp)
    80005dc6:	64f2                	ld	s1,280(sp)
    80005dc8:	6952                	ld	s2,272(sp)
    80005dca:	6155                	addi	sp,sp,304
    80005dcc:	8082                	ret

0000000080005dce <sys_unlink>:
{
    80005dce:	7151                	addi	sp,sp,-240
    80005dd0:	f586                	sd	ra,232(sp)
    80005dd2:	f1a2                	sd	s0,224(sp)
    80005dd4:	eda6                	sd	s1,216(sp)
    80005dd6:	e9ca                	sd	s2,208(sp)
    80005dd8:	e5ce                	sd	s3,200(sp)
    80005dda:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ddc:	08000613          	li	a2,128
    80005de0:	f3040593          	addi	a1,s0,-208
    80005de4:	4501                	li	a0,0
    80005de6:	ffffd097          	auipc	ra,0xffffd
    80005dea:	6d6080e7          	jalr	1750(ra) # 800034bc <argstr>
    80005dee:	18054163          	bltz	a0,80005f70 <sys_unlink+0x1a2>
  begin_op();
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	c14080e7          	jalr	-1004(ra) # 80004a06 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005dfa:	fb040593          	addi	a1,s0,-80
    80005dfe:	f3040513          	addi	a0,s0,-208
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	a06080e7          	jalr	-1530(ra) # 80004808 <nameiparent>
    80005e0a:	84aa                	mv	s1,a0
    80005e0c:	c979                	beqz	a0,80005ee2 <sys_unlink+0x114>
  ilock(dp);
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	226080e7          	jalr	550(ra) # 80004034 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005e16:	00003597          	auipc	a1,0x3
    80005e1a:	a3a58593          	addi	a1,a1,-1478 # 80008850 <syscalls+0x2c0>
    80005e1e:	fb040513          	addi	a0,s0,-80
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	6dc080e7          	jalr	1756(ra) # 800044fe <namecmp>
    80005e2a:	14050a63          	beqz	a0,80005f7e <sys_unlink+0x1b0>
    80005e2e:	00003597          	auipc	a1,0x3
    80005e32:	a2a58593          	addi	a1,a1,-1494 # 80008858 <syscalls+0x2c8>
    80005e36:	fb040513          	addi	a0,s0,-80
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	6c4080e7          	jalr	1732(ra) # 800044fe <namecmp>
    80005e42:	12050e63          	beqz	a0,80005f7e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005e46:	f2c40613          	addi	a2,s0,-212
    80005e4a:	fb040593          	addi	a1,s0,-80
    80005e4e:	8526                	mv	a0,s1
    80005e50:	ffffe097          	auipc	ra,0xffffe
    80005e54:	6c8080e7          	jalr	1736(ra) # 80004518 <dirlookup>
    80005e58:	892a                	mv	s2,a0
    80005e5a:	12050263          	beqz	a0,80005f7e <sys_unlink+0x1b0>
  ilock(ip);
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	1d6080e7          	jalr	470(ra) # 80004034 <ilock>
  if(ip->nlink < 1)
    80005e66:	04a91783          	lh	a5,74(s2)
    80005e6a:	08f05263          	blez	a5,80005eee <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005e6e:	04491703          	lh	a4,68(s2)
    80005e72:	4785                	li	a5,1
    80005e74:	08f70563          	beq	a4,a5,80005efe <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005e78:	4641                	li	a2,16
    80005e7a:	4581                	li	a1,0
    80005e7c:	fc040513          	addi	a0,s0,-64
    80005e80:	ffffb097          	auipc	ra,0xffffb
    80005e84:	e60080e7          	jalr	-416(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e88:	4741                	li	a4,16
    80005e8a:	f2c42683          	lw	a3,-212(s0)
    80005e8e:	fc040613          	addi	a2,s0,-64
    80005e92:	4581                	li	a1,0
    80005e94:	8526                	mv	a0,s1
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	54a080e7          	jalr	1354(ra) # 800043e0 <writei>
    80005e9e:	47c1                	li	a5,16
    80005ea0:	0af51563          	bne	a0,a5,80005f4a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ea4:	04491703          	lh	a4,68(s2)
    80005ea8:	4785                	li	a5,1
    80005eaa:	0af70863          	beq	a4,a5,80005f5a <sys_unlink+0x18c>
  iunlockput(dp);
    80005eae:	8526                	mv	a0,s1
    80005eb0:	ffffe097          	auipc	ra,0xffffe
    80005eb4:	3e6080e7          	jalr	998(ra) # 80004296 <iunlockput>
  ip->nlink--;
    80005eb8:	04a95783          	lhu	a5,74(s2)
    80005ebc:	37fd                	addiw	a5,a5,-1
    80005ebe:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ec2:	854a                	mv	a0,s2
    80005ec4:	ffffe097          	auipc	ra,0xffffe
    80005ec8:	0a6080e7          	jalr	166(ra) # 80003f6a <iupdate>
  iunlockput(ip);
    80005ecc:	854a                	mv	a0,s2
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	3c8080e7          	jalr	968(ra) # 80004296 <iunlockput>
  end_op();
    80005ed6:	fffff097          	auipc	ra,0xfffff
    80005eda:	bb0080e7          	jalr	-1104(ra) # 80004a86 <end_op>
  return 0;
    80005ede:	4501                	li	a0,0
    80005ee0:	a84d                	j	80005f92 <sys_unlink+0x1c4>
    end_op();
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	ba4080e7          	jalr	-1116(ra) # 80004a86 <end_op>
    return -1;
    80005eea:	557d                	li	a0,-1
    80005eec:	a05d                	j	80005f92 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005eee:	00003517          	auipc	a0,0x3
    80005ef2:	99250513          	addi	a0,a0,-1646 # 80008880 <syscalls+0x2f0>
    80005ef6:	ffffa097          	auipc	ra,0xffffa
    80005efa:	648080e7          	jalr	1608(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005efe:	04c92703          	lw	a4,76(s2)
    80005f02:	02000793          	li	a5,32
    80005f06:	f6e7f9e3          	bgeu	a5,a4,80005e78 <sys_unlink+0xaa>
    80005f0a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f0e:	4741                	li	a4,16
    80005f10:	86ce                	mv	a3,s3
    80005f12:	f1840613          	addi	a2,s0,-232
    80005f16:	4581                	li	a1,0
    80005f18:	854a                	mv	a0,s2
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	3ce080e7          	jalr	974(ra) # 800042e8 <readi>
    80005f22:	47c1                	li	a5,16
    80005f24:	00f51b63          	bne	a0,a5,80005f3a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005f28:	f1845783          	lhu	a5,-232(s0)
    80005f2c:	e7a1                	bnez	a5,80005f74 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f2e:	29c1                	addiw	s3,s3,16
    80005f30:	04c92783          	lw	a5,76(s2)
    80005f34:	fcf9ede3          	bltu	s3,a5,80005f0e <sys_unlink+0x140>
    80005f38:	b781                	j	80005e78 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005f3a:	00003517          	auipc	a0,0x3
    80005f3e:	95e50513          	addi	a0,a0,-1698 # 80008898 <syscalls+0x308>
    80005f42:	ffffa097          	auipc	ra,0xffffa
    80005f46:	5fc080e7          	jalr	1532(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005f4a:	00003517          	auipc	a0,0x3
    80005f4e:	96650513          	addi	a0,a0,-1690 # 800088b0 <syscalls+0x320>
    80005f52:	ffffa097          	auipc	ra,0xffffa
    80005f56:	5ec080e7          	jalr	1516(ra) # 8000053e <panic>
    dp->nlink--;
    80005f5a:	04a4d783          	lhu	a5,74(s1)
    80005f5e:	37fd                	addiw	a5,a5,-1
    80005f60:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f64:	8526                	mv	a0,s1
    80005f66:	ffffe097          	auipc	ra,0xffffe
    80005f6a:	004080e7          	jalr	4(ra) # 80003f6a <iupdate>
    80005f6e:	b781                	j	80005eae <sys_unlink+0xe0>
    return -1;
    80005f70:	557d                	li	a0,-1
    80005f72:	a005                	j	80005f92 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005f74:	854a                	mv	a0,s2
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	320080e7          	jalr	800(ra) # 80004296 <iunlockput>
  iunlockput(dp);
    80005f7e:	8526                	mv	a0,s1
    80005f80:	ffffe097          	auipc	ra,0xffffe
    80005f84:	316080e7          	jalr	790(ra) # 80004296 <iunlockput>
  end_op();
    80005f88:	fffff097          	auipc	ra,0xfffff
    80005f8c:	afe080e7          	jalr	-1282(ra) # 80004a86 <end_op>
  return -1;
    80005f90:	557d                	li	a0,-1
}
    80005f92:	70ae                	ld	ra,232(sp)
    80005f94:	740e                	ld	s0,224(sp)
    80005f96:	64ee                	ld	s1,216(sp)
    80005f98:	694e                	ld	s2,208(sp)
    80005f9a:	69ae                	ld	s3,200(sp)
    80005f9c:	616d                	addi	sp,sp,240
    80005f9e:	8082                	ret

0000000080005fa0 <sys_open>:

uint64
sys_open(void)
{
    80005fa0:	7131                	addi	sp,sp,-192
    80005fa2:	fd06                	sd	ra,184(sp)
    80005fa4:	f922                	sd	s0,176(sp)
    80005fa6:	f526                	sd	s1,168(sp)
    80005fa8:	f14a                	sd	s2,160(sp)
    80005faa:	ed4e                	sd	s3,152(sp)
    80005fac:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005fae:	08000613          	li	a2,128
    80005fb2:	f5040593          	addi	a1,s0,-176
    80005fb6:	4501                	li	a0,0
    80005fb8:	ffffd097          	auipc	ra,0xffffd
    80005fbc:	504080e7          	jalr	1284(ra) # 800034bc <argstr>
    return -1;
    80005fc0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005fc2:	0c054163          	bltz	a0,80006084 <sys_open+0xe4>
    80005fc6:	f4c40593          	addi	a1,s0,-180
    80005fca:	4505                	li	a0,1
    80005fcc:	ffffd097          	auipc	ra,0xffffd
    80005fd0:	4ac080e7          	jalr	1196(ra) # 80003478 <argint>
    80005fd4:	0a054863          	bltz	a0,80006084 <sys_open+0xe4>

  begin_op();
    80005fd8:	fffff097          	auipc	ra,0xfffff
    80005fdc:	a2e080e7          	jalr	-1490(ra) # 80004a06 <begin_op>

  if(omode & O_CREATE){
    80005fe0:	f4c42783          	lw	a5,-180(s0)
    80005fe4:	2007f793          	andi	a5,a5,512
    80005fe8:	cbdd                	beqz	a5,8000609e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005fea:	4681                	li	a3,0
    80005fec:	4601                	li	a2,0
    80005fee:	4589                	li	a1,2
    80005ff0:	f5040513          	addi	a0,s0,-176
    80005ff4:	00000097          	auipc	ra,0x0
    80005ff8:	972080e7          	jalr	-1678(ra) # 80005966 <create>
    80005ffc:	892a                	mv	s2,a0
    if(ip == 0){
    80005ffe:	c959                	beqz	a0,80006094 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006000:	04491703          	lh	a4,68(s2)
    80006004:	478d                	li	a5,3
    80006006:	00f71763          	bne	a4,a5,80006014 <sys_open+0x74>
    8000600a:	04695703          	lhu	a4,70(s2)
    8000600e:	47a5                	li	a5,9
    80006010:	0ce7ec63          	bltu	a5,a4,800060e8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006014:	fffff097          	auipc	ra,0xfffff
    80006018:	e02080e7          	jalr	-510(ra) # 80004e16 <filealloc>
    8000601c:	89aa                	mv	s3,a0
    8000601e:	10050263          	beqz	a0,80006122 <sys_open+0x182>
    80006022:	00000097          	auipc	ra,0x0
    80006026:	902080e7          	jalr	-1790(ra) # 80005924 <fdalloc>
    8000602a:	84aa                	mv	s1,a0
    8000602c:	0e054663          	bltz	a0,80006118 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006030:	04491703          	lh	a4,68(s2)
    80006034:	478d                	li	a5,3
    80006036:	0cf70463          	beq	a4,a5,800060fe <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000603a:	4789                	li	a5,2
    8000603c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006040:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006044:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006048:	f4c42783          	lw	a5,-180(s0)
    8000604c:	0017c713          	xori	a4,a5,1
    80006050:	8b05                	andi	a4,a4,1
    80006052:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006056:	0037f713          	andi	a4,a5,3
    8000605a:	00e03733          	snez	a4,a4
    8000605e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006062:	4007f793          	andi	a5,a5,1024
    80006066:	c791                	beqz	a5,80006072 <sys_open+0xd2>
    80006068:	04491703          	lh	a4,68(s2)
    8000606c:	4789                	li	a5,2
    8000606e:	08f70f63          	beq	a4,a5,8000610c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006072:	854a                	mv	a0,s2
    80006074:	ffffe097          	auipc	ra,0xffffe
    80006078:	082080e7          	jalr	130(ra) # 800040f6 <iunlock>
  end_op();
    8000607c:	fffff097          	auipc	ra,0xfffff
    80006080:	a0a080e7          	jalr	-1526(ra) # 80004a86 <end_op>

  return fd;
}
    80006084:	8526                	mv	a0,s1
    80006086:	70ea                	ld	ra,184(sp)
    80006088:	744a                	ld	s0,176(sp)
    8000608a:	74aa                	ld	s1,168(sp)
    8000608c:	790a                	ld	s2,160(sp)
    8000608e:	69ea                	ld	s3,152(sp)
    80006090:	6129                	addi	sp,sp,192
    80006092:	8082                	ret
      end_op();
    80006094:	fffff097          	auipc	ra,0xfffff
    80006098:	9f2080e7          	jalr	-1550(ra) # 80004a86 <end_op>
      return -1;
    8000609c:	b7e5                	j	80006084 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000609e:	f5040513          	addi	a0,s0,-176
    800060a2:	ffffe097          	auipc	ra,0xffffe
    800060a6:	748080e7          	jalr	1864(ra) # 800047ea <namei>
    800060aa:	892a                	mv	s2,a0
    800060ac:	c905                	beqz	a0,800060dc <sys_open+0x13c>
    ilock(ip);
    800060ae:	ffffe097          	auipc	ra,0xffffe
    800060b2:	f86080e7          	jalr	-122(ra) # 80004034 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800060b6:	04491703          	lh	a4,68(s2)
    800060ba:	4785                	li	a5,1
    800060bc:	f4f712e3          	bne	a4,a5,80006000 <sys_open+0x60>
    800060c0:	f4c42783          	lw	a5,-180(s0)
    800060c4:	dba1                	beqz	a5,80006014 <sys_open+0x74>
      iunlockput(ip);
    800060c6:	854a                	mv	a0,s2
    800060c8:	ffffe097          	auipc	ra,0xffffe
    800060cc:	1ce080e7          	jalr	462(ra) # 80004296 <iunlockput>
      end_op();
    800060d0:	fffff097          	auipc	ra,0xfffff
    800060d4:	9b6080e7          	jalr	-1610(ra) # 80004a86 <end_op>
      return -1;
    800060d8:	54fd                	li	s1,-1
    800060da:	b76d                	j	80006084 <sys_open+0xe4>
      end_op();
    800060dc:	fffff097          	auipc	ra,0xfffff
    800060e0:	9aa080e7          	jalr	-1622(ra) # 80004a86 <end_op>
      return -1;
    800060e4:	54fd                	li	s1,-1
    800060e6:	bf79                	j	80006084 <sys_open+0xe4>
    iunlockput(ip);
    800060e8:	854a                	mv	a0,s2
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	1ac080e7          	jalr	428(ra) # 80004296 <iunlockput>
    end_op();
    800060f2:	fffff097          	auipc	ra,0xfffff
    800060f6:	994080e7          	jalr	-1644(ra) # 80004a86 <end_op>
    return -1;
    800060fa:	54fd                	li	s1,-1
    800060fc:	b761                	j	80006084 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800060fe:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006102:	04691783          	lh	a5,70(s2)
    80006106:	02f99223          	sh	a5,36(s3)
    8000610a:	bf2d                	j	80006044 <sys_open+0xa4>
    itrunc(ip);
    8000610c:	854a                	mv	a0,s2
    8000610e:	ffffe097          	auipc	ra,0xffffe
    80006112:	034080e7          	jalr	52(ra) # 80004142 <itrunc>
    80006116:	bfb1                	j	80006072 <sys_open+0xd2>
      fileclose(f);
    80006118:	854e                	mv	a0,s3
    8000611a:	fffff097          	auipc	ra,0xfffff
    8000611e:	db8080e7          	jalr	-584(ra) # 80004ed2 <fileclose>
    iunlockput(ip);
    80006122:	854a                	mv	a0,s2
    80006124:	ffffe097          	auipc	ra,0xffffe
    80006128:	172080e7          	jalr	370(ra) # 80004296 <iunlockput>
    end_op();
    8000612c:	fffff097          	auipc	ra,0xfffff
    80006130:	95a080e7          	jalr	-1702(ra) # 80004a86 <end_op>
    return -1;
    80006134:	54fd                	li	s1,-1
    80006136:	b7b9                	j	80006084 <sys_open+0xe4>

0000000080006138 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006138:	7175                	addi	sp,sp,-144
    8000613a:	e506                	sd	ra,136(sp)
    8000613c:	e122                	sd	s0,128(sp)
    8000613e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006140:	fffff097          	auipc	ra,0xfffff
    80006144:	8c6080e7          	jalr	-1850(ra) # 80004a06 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006148:	08000613          	li	a2,128
    8000614c:	f7040593          	addi	a1,s0,-144
    80006150:	4501                	li	a0,0
    80006152:	ffffd097          	auipc	ra,0xffffd
    80006156:	36a080e7          	jalr	874(ra) # 800034bc <argstr>
    8000615a:	02054963          	bltz	a0,8000618c <sys_mkdir+0x54>
    8000615e:	4681                	li	a3,0
    80006160:	4601                	li	a2,0
    80006162:	4585                	li	a1,1
    80006164:	f7040513          	addi	a0,s0,-144
    80006168:	fffff097          	auipc	ra,0xfffff
    8000616c:	7fe080e7          	jalr	2046(ra) # 80005966 <create>
    80006170:	cd11                	beqz	a0,8000618c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006172:	ffffe097          	auipc	ra,0xffffe
    80006176:	124080e7          	jalr	292(ra) # 80004296 <iunlockput>
  end_op();
    8000617a:	fffff097          	auipc	ra,0xfffff
    8000617e:	90c080e7          	jalr	-1780(ra) # 80004a86 <end_op>
  return 0;
    80006182:	4501                	li	a0,0
}
    80006184:	60aa                	ld	ra,136(sp)
    80006186:	640a                	ld	s0,128(sp)
    80006188:	6149                	addi	sp,sp,144
    8000618a:	8082                	ret
    end_op();
    8000618c:	fffff097          	auipc	ra,0xfffff
    80006190:	8fa080e7          	jalr	-1798(ra) # 80004a86 <end_op>
    return -1;
    80006194:	557d                	li	a0,-1
    80006196:	b7fd                	j	80006184 <sys_mkdir+0x4c>

0000000080006198 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006198:	7135                	addi	sp,sp,-160
    8000619a:	ed06                	sd	ra,152(sp)
    8000619c:	e922                	sd	s0,144(sp)
    8000619e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	866080e7          	jalr	-1946(ra) # 80004a06 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061a8:	08000613          	li	a2,128
    800061ac:	f7040593          	addi	a1,s0,-144
    800061b0:	4501                	li	a0,0
    800061b2:	ffffd097          	auipc	ra,0xffffd
    800061b6:	30a080e7          	jalr	778(ra) # 800034bc <argstr>
    800061ba:	04054a63          	bltz	a0,8000620e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800061be:	f6c40593          	addi	a1,s0,-148
    800061c2:	4505                	li	a0,1
    800061c4:	ffffd097          	auipc	ra,0xffffd
    800061c8:	2b4080e7          	jalr	692(ra) # 80003478 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061cc:	04054163          	bltz	a0,8000620e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800061d0:	f6840593          	addi	a1,s0,-152
    800061d4:	4509                	li	a0,2
    800061d6:	ffffd097          	auipc	ra,0xffffd
    800061da:	2a2080e7          	jalr	674(ra) # 80003478 <argint>
     argint(1, &major) < 0 ||
    800061de:	02054863          	bltz	a0,8000620e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800061e2:	f6841683          	lh	a3,-152(s0)
    800061e6:	f6c41603          	lh	a2,-148(s0)
    800061ea:	458d                	li	a1,3
    800061ec:	f7040513          	addi	a0,s0,-144
    800061f0:	fffff097          	auipc	ra,0xfffff
    800061f4:	776080e7          	jalr	1910(ra) # 80005966 <create>
     argint(2, &minor) < 0 ||
    800061f8:	c919                	beqz	a0,8000620e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800061fa:	ffffe097          	auipc	ra,0xffffe
    800061fe:	09c080e7          	jalr	156(ra) # 80004296 <iunlockput>
  end_op();
    80006202:	fffff097          	auipc	ra,0xfffff
    80006206:	884080e7          	jalr	-1916(ra) # 80004a86 <end_op>
  return 0;
    8000620a:	4501                	li	a0,0
    8000620c:	a031                	j	80006218 <sys_mknod+0x80>
    end_op();
    8000620e:	fffff097          	auipc	ra,0xfffff
    80006212:	878080e7          	jalr	-1928(ra) # 80004a86 <end_op>
    return -1;
    80006216:	557d                	li	a0,-1
}
    80006218:	60ea                	ld	ra,152(sp)
    8000621a:	644a                	ld	s0,144(sp)
    8000621c:	610d                	addi	sp,sp,160
    8000621e:	8082                	ret

0000000080006220 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006220:	7135                	addi	sp,sp,-160
    80006222:	ed06                	sd	ra,152(sp)
    80006224:	e922                	sd	s0,144(sp)
    80006226:	e526                	sd	s1,136(sp)
    80006228:	e14a                	sd	s2,128(sp)
    8000622a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000622c:	ffffc097          	auipc	ra,0xffffc
    80006230:	fb4080e7          	jalr	-76(ra) # 800021e0 <myproc>
    80006234:	892a                	mv	s2,a0
  
  begin_op();
    80006236:	ffffe097          	auipc	ra,0xffffe
    8000623a:	7d0080e7          	jalr	2000(ra) # 80004a06 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000623e:	08000613          	li	a2,128
    80006242:	f6040593          	addi	a1,s0,-160
    80006246:	4501                	li	a0,0
    80006248:	ffffd097          	auipc	ra,0xffffd
    8000624c:	274080e7          	jalr	628(ra) # 800034bc <argstr>
    80006250:	04054b63          	bltz	a0,800062a6 <sys_chdir+0x86>
    80006254:	f6040513          	addi	a0,s0,-160
    80006258:	ffffe097          	auipc	ra,0xffffe
    8000625c:	592080e7          	jalr	1426(ra) # 800047ea <namei>
    80006260:	84aa                	mv	s1,a0
    80006262:	c131                	beqz	a0,800062a6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006264:	ffffe097          	auipc	ra,0xffffe
    80006268:	dd0080e7          	jalr	-560(ra) # 80004034 <ilock>
  if(ip->type != T_DIR){
    8000626c:	04449703          	lh	a4,68(s1)
    80006270:	4785                	li	a5,1
    80006272:	04f71063          	bne	a4,a5,800062b2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006276:	8526                	mv	a0,s1
    80006278:	ffffe097          	auipc	ra,0xffffe
    8000627c:	e7e080e7          	jalr	-386(ra) # 800040f6 <iunlock>
  iput(p->cwd);
    80006280:	17893503          	ld	a0,376(s2)
    80006284:	ffffe097          	auipc	ra,0xffffe
    80006288:	f6a080e7          	jalr	-150(ra) # 800041ee <iput>
  end_op();
    8000628c:	ffffe097          	auipc	ra,0xffffe
    80006290:	7fa080e7          	jalr	2042(ra) # 80004a86 <end_op>
  p->cwd = ip;
    80006294:	16993c23          	sd	s1,376(s2)
  return 0;
    80006298:	4501                	li	a0,0
}
    8000629a:	60ea                	ld	ra,152(sp)
    8000629c:	644a                	ld	s0,144(sp)
    8000629e:	64aa                	ld	s1,136(sp)
    800062a0:	690a                	ld	s2,128(sp)
    800062a2:	610d                	addi	sp,sp,160
    800062a4:	8082                	ret
    end_op();
    800062a6:	ffffe097          	auipc	ra,0xffffe
    800062aa:	7e0080e7          	jalr	2016(ra) # 80004a86 <end_op>
    return -1;
    800062ae:	557d                	li	a0,-1
    800062b0:	b7ed                	j	8000629a <sys_chdir+0x7a>
    iunlockput(ip);
    800062b2:	8526                	mv	a0,s1
    800062b4:	ffffe097          	auipc	ra,0xffffe
    800062b8:	fe2080e7          	jalr	-30(ra) # 80004296 <iunlockput>
    end_op();
    800062bc:	ffffe097          	auipc	ra,0xffffe
    800062c0:	7ca080e7          	jalr	1994(ra) # 80004a86 <end_op>
    return -1;
    800062c4:	557d                	li	a0,-1
    800062c6:	bfd1                	j	8000629a <sys_chdir+0x7a>

00000000800062c8 <sys_exec>:

uint64
sys_exec(void)
{
    800062c8:	7145                	addi	sp,sp,-464
    800062ca:	e786                	sd	ra,456(sp)
    800062cc:	e3a2                	sd	s0,448(sp)
    800062ce:	ff26                	sd	s1,440(sp)
    800062d0:	fb4a                	sd	s2,432(sp)
    800062d2:	f74e                	sd	s3,424(sp)
    800062d4:	f352                	sd	s4,416(sp)
    800062d6:	ef56                	sd	s5,408(sp)
    800062d8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800062da:	08000613          	li	a2,128
    800062de:	f4040593          	addi	a1,s0,-192
    800062e2:	4501                	li	a0,0
    800062e4:	ffffd097          	auipc	ra,0xffffd
    800062e8:	1d8080e7          	jalr	472(ra) # 800034bc <argstr>
    return -1;
    800062ec:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800062ee:	0c054a63          	bltz	a0,800063c2 <sys_exec+0xfa>
    800062f2:	e3840593          	addi	a1,s0,-456
    800062f6:	4505                	li	a0,1
    800062f8:	ffffd097          	auipc	ra,0xffffd
    800062fc:	1a2080e7          	jalr	418(ra) # 8000349a <argaddr>
    80006300:	0c054163          	bltz	a0,800063c2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006304:	10000613          	li	a2,256
    80006308:	4581                	li	a1,0
    8000630a:	e4040513          	addi	a0,s0,-448
    8000630e:	ffffb097          	auipc	ra,0xffffb
    80006312:	9d2080e7          	jalr	-1582(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006316:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000631a:	89a6                	mv	s3,s1
    8000631c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000631e:	02000a13          	li	s4,32
    80006322:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006326:	00391513          	slli	a0,s2,0x3
    8000632a:	e3040593          	addi	a1,s0,-464
    8000632e:	e3843783          	ld	a5,-456(s0)
    80006332:	953e                	add	a0,a0,a5
    80006334:	ffffd097          	auipc	ra,0xffffd
    80006338:	0aa080e7          	jalr	170(ra) # 800033de <fetchaddr>
    8000633c:	02054a63          	bltz	a0,80006370 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006340:	e3043783          	ld	a5,-464(s0)
    80006344:	c3b9                	beqz	a5,8000638a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006346:	ffffa097          	auipc	ra,0xffffa
    8000634a:	7ae080e7          	jalr	1966(ra) # 80000af4 <kalloc>
    8000634e:	85aa                	mv	a1,a0
    80006350:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006354:	cd11                	beqz	a0,80006370 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006356:	6605                	lui	a2,0x1
    80006358:	e3043503          	ld	a0,-464(s0)
    8000635c:	ffffd097          	auipc	ra,0xffffd
    80006360:	0d4080e7          	jalr	212(ra) # 80003430 <fetchstr>
    80006364:	00054663          	bltz	a0,80006370 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006368:	0905                	addi	s2,s2,1
    8000636a:	09a1                	addi	s3,s3,8
    8000636c:	fb491be3          	bne	s2,s4,80006322 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006370:	10048913          	addi	s2,s1,256
    80006374:	6088                	ld	a0,0(s1)
    80006376:	c529                	beqz	a0,800063c0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006378:	ffffa097          	auipc	ra,0xffffa
    8000637c:	680080e7          	jalr	1664(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006380:	04a1                	addi	s1,s1,8
    80006382:	ff2499e3          	bne	s1,s2,80006374 <sys_exec+0xac>
  return -1;
    80006386:	597d                	li	s2,-1
    80006388:	a82d                	j	800063c2 <sys_exec+0xfa>
      argv[i] = 0;
    8000638a:	0a8e                	slli	s5,s5,0x3
    8000638c:	fc040793          	addi	a5,s0,-64
    80006390:	9abe                	add	s5,s5,a5
    80006392:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006396:	e4040593          	addi	a1,s0,-448
    8000639a:	f4040513          	addi	a0,s0,-192
    8000639e:	fffff097          	auipc	ra,0xfffff
    800063a2:	194080e7          	jalr	404(ra) # 80005532 <exec>
    800063a6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063a8:	10048993          	addi	s3,s1,256
    800063ac:	6088                	ld	a0,0(s1)
    800063ae:	c911                	beqz	a0,800063c2 <sys_exec+0xfa>
    kfree(argv[i]);
    800063b0:	ffffa097          	auipc	ra,0xffffa
    800063b4:	648080e7          	jalr	1608(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063b8:	04a1                	addi	s1,s1,8
    800063ba:	ff3499e3          	bne	s1,s3,800063ac <sys_exec+0xe4>
    800063be:	a011                	j	800063c2 <sys_exec+0xfa>
  return -1;
    800063c0:	597d                	li	s2,-1
}
    800063c2:	854a                	mv	a0,s2
    800063c4:	60be                	ld	ra,456(sp)
    800063c6:	641e                	ld	s0,448(sp)
    800063c8:	74fa                	ld	s1,440(sp)
    800063ca:	795a                	ld	s2,432(sp)
    800063cc:	79ba                	ld	s3,424(sp)
    800063ce:	7a1a                	ld	s4,416(sp)
    800063d0:	6afa                	ld	s5,408(sp)
    800063d2:	6179                	addi	sp,sp,464
    800063d4:	8082                	ret

00000000800063d6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800063d6:	7139                	addi	sp,sp,-64
    800063d8:	fc06                	sd	ra,56(sp)
    800063da:	f822                	sd	s0,48(sp)
    800063dc:	f426                	sd	s1,40(sp)
    800063de:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800063e0:	ffffc097          	auipc	ra,0xffffc
    800063e4:	e00080e7          	jalr	-512(ra) # 800021e0 <myproc>
    800063e8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800063ea:	fd840593          	addi	a1,s0,-40
    800063ee:	4501                	li	a0,0
    800063f0:	ffffd097          	auipc	ra,0xffffd
    800063f4:	0aa080e7          	jalr	170(ra) # 8000349a <argaddr>
    return -1;
    800063f8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800063fa:	0e054063          	bltz	a0,800064da <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800063fe:	fc840593          	addi	a1,s0,-56
    80006402:	fd040513          	addi	a0,s0,-48
    80006406:	fffff097          	auipc	ra,0xfffff
    8000640a:	dfc080e7          	jalr	-516(ra) # 80005202 <pipealloc>
    return -1;
    8000640e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006410:	0c054563          	bltz	a0,800064da <sys_pipe+0x104>
  fd0 = -1;
    80006414:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006418:	fd043503          	ld	a0,-48(s0)
    8000641c:	fffff097          	auipc	ra,0xfffff
    80006420:	508080e7          	jalr	1288(ra) # 80005924 <fdalloc>
    80006424:	fca42223          	sw	a0,-60(s0)
    80006428:	08054c63          	bltz	a0,800064c0 <sys_pipe+0xea>
    8000642c:	fc843503          	ld	a0,-56(s0)
    80006430:	fffff097          	auipc	ra,0xfffff
    80006434:	4f4080e7          	jalr	1268(ra) # 80005924 <fdalloc>
    80006438:	fca42023          	sw	a0,-64(s0)
    8000643c:	06054863          	bltz	a0,800064ac <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006440:	4691                	li	a3,4
    80006442:	fc440613          	addi	a2,s0,-60
    80006446:	fd843583          	ld	a1,-40(s0)
    8000644a:	7ca8                	ld	a0,120(s1)
    8000644c:	ffffb097          	auipc	ra,0xffffb
    80006450:	226080e7          	jalr	550(ra) # 80001672 <copyout>
    80006454:	02054063          	bltz	a0,80006474 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006458:	4691                	li	a3,4
    8000645a:	fc040613          	addi	a2,s0,-64
    8000645e:	fd843583          	ld	a1,-40(s0)
    80006462:	0591                	addi	a1,a1,4
    80006464:	7ca8                	ld	a0,120(s1)
    80006466:	ffffb097          	auipc	ra,0xffffb
    8000646a:	20c080e7          	jalr	524(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000646e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006470:	06055563          	bgez	a0,800064da <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006474:	fc442783          	lw	a5,-60(s0)
    80006478:	07f9                	addi	a5,a5,30
    8000647a:	078e                	slli	a5,a5,0x3
    8000647c:	97a6                	add	a5,a5,s1
    8000647e:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006482:	fc042503          	lw	a0,-64(s0)
    80006486:	0579                	addi	a0,a0,30
    80006488:	050e                	slli	a0,a0,0x3
    8000648a:	9526                	add	a0,a0,s1
    8000648c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006490:	fd043503          	ld	a0,-48(s0)
    80006494:	fffff097          	auipc	ra,0xfffff
    80006498:	a3e080e7          	jalr	-1474(ra) # 80004ed2 <fileclose>
    fileclose(wf);
    8000649c:	fc843503          	ld	a0,-56(s0)
    800064a0:	fffff097          	auipc	ra,0xfffff
    800064a4:	a32080e7          	jalr	-1486(ra) # 80004ed2 <fileclose>
    return -1;
    800064a8:	57fd                	li	a5,-1
    800064aa:	a805                	j	800064da <sys_pipe+0x104>
    if(fd0 >= 0)
    800064ac:	fc442783          	lw	a5,-60(s0)
    800064b0:	0007c863          	bltz	a5,800064c0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800064b4:	01e78513          	addi	a0,a5,30
    800064b8:	050e                	slli	a0,a0,0x3
    800064ba:	9526                	add	a0,a0,s1
    800064bc:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800064c0:	fd043503          	ld	a0,-48(s0)
    800064c4:	fffff097          	auipc	ra,0xfffff
    800064c8:	a0e080e7          	jalr	-1522(ra) # 80004ed2 <fileclose>
    fileclose(wf);
    800064cc:	fc843503          	ld	a0,-56(s0)
    800064d0:	fffff097          	auipc	ra,0xfffff
    800064d4:	a02080e7          	jalr	-1534(ra) # 80004ed2 <fileclose>
    return -1;
    800064d8:	57fd                	li	a5,-1
}
    800064da:	853e                	mv	a0,a5
    800064dc:	70e2                	ld	ra,56(sp)
    800064de:	7442                	ld	s0,48(sp)
    800064e0:	74a2                	ld	s1,40(sp)
    800064e2:	6121                	addi	sp,sp,64
    800064e4:	8082                	ret
	...

00000000800064f0 <kernelvec>:
    800064f0:	7111                	addi	sp,sp,-256
    800064f2:	e006                	sd	ra,0(sp)
    800064f4:	e40a                	sd	sp,8(sp)
    800064f6:	e80e                	sd	gp,16(sp)
    800064f8:	ec12                	sd	tp,24(sp)
    800064fa:	f016                	sd	t0,32(sp)
    800064fc:	f41a                	sd	t1,40(sp)
    800064fe:	f81e                	sd	t2,48(sp)
    80006500:	fc22                	sd	s0,56(sp)
    80006502:	e0a6                	sd	s1,64(sp)
    80006504:	e4aa                	sd	a0,72(sp)
    80006506:	e8ae                	sd	a1,80(sp)
    80006508:	ecb2                	sd	a2,88(sp)
    8000650a:	f0b6                	sd	a3,96(sp)
    8000650c:	f4ba                	sd	a4,104(sp)
    8000650e:	f8be                	sd	a5,112(sp)
    80006510:	fcc2                	sd	a6,120(sp)
    80006512:	e146                	sd	a7,128(sp)
    80006514:	e54a                	sd	s2,136(sp)
    80006516:	e94e                	sd	s3,144(sp)
    80006518:	ed52                	sd	s4,152(sp)
    8000651a:	f156                	sd	s5,160(sp)
    8000651c:	f55a                	sd	s6,168(sp)
    8000651e:	f95e                	sd	s7,176(sp)
    80006520:	fd62                	sd	s8,184(sp)
    80006522:	e1e6                	sd	s9,192(sp)
    80006524:	e5ea                	sd	s10,200(sp)
    80006526:	e9ee                	sd	s11,208(sp)
    80006528:	edf2                	sd	t3,216(sp)
    8000652a:	f1f6                	sd	t4,224(sp)
    8000652c:	f5fa                	sd	t5,232(sp)
    8000652e:	f9fe                	sd	t6,240(sp)
    80006530:	d7bfc0ef          	jal	ra,800032aa <kerneltrap>
    80006534:	6082                	ld	ra,0(sp)
    80006536:	6122                	ld	sp,8(sp)
    80006538:	61c2                	ld	gp,16(sp)
    8000653a:	7282                	ld	t0,32(sp)
    8000653c:	7322                	ld	t1,40(sp)
    8000653e:	73c2                	ld	t2,48(sp)
    80006540:	7462                	ld	s0,56(sp)
    80006542:	6486                	ld	s1,64(sp)
    80006544:	6526                	ld	a0,72(sp)
    80006546:	65c6                	ld	a1,80(sp)
    80006548:	6666                	ld	a2,88(sp)
    8000654a:	7686                	ld	a3,96(sp)
    8000654c:	7726                	ld	a4,104(sp)
    8000654e:	77c6                	ld	a5,112(sp)
    80006550:	7866                	ld	a6,120(sp)
    80006552:	688a                	ld	a7,128(sp)
    80006554:	692a                	ld	s2,136(sp)
    80006556:	69ca                	ld	s3,144(sp)
    80006558:	6a6a                	ld	s4,152(sp)
    8000655a:	7a8a                	ld	s5,160(sp)
    8000655c:	7b2a                	ld	s6,168(sp)
    8000655e:	7bca                	ld	s7,176(sp)
    80006560:	7c6a                	ld	s8,184(sp)
    80006562:	6c8e                	ld	s9,192(sp)
    80006564:	6d2e                	ld	s10,200(sp)
    80006566:	6dce                	ld	s11,208(sp)
    80006568:	6e6e                	ld	t3,216(sp)
    8000656a:	7e8e                	ld	t4,224(sp)
    8000656c:	7f2e                	ld	t5,232(sp)
    8000656e:	7fce                	ld	t6,240(sp)
    80006570:	6111                	addi	sp,sp,256
    80006572:	10200073          	sret
    80006576:	00000013          	nop
    8000657a:	00000013          	nop
    8000657e:	0001                	nop

0000000080006580 <timervec>:
    80006580:	34051573          	csrrw	a0,mscratch,a0
    80006584:	e10c                	sd	a1,0(a0)
    80006586:	e510                	sd	a2,8(a0)
    80006588:	e914                	sd	a3,16(a0)
    8000658a:	6d0c                	ld	a1,24(a0)
    8000658c:	7110                	ld	a2,32(a0)
    8000658e:	6194                	ld	a3,0(a1)
    80006590:	96b2                	add	a3,a3,a2
    80006592:	e194                	sd	a3,0(a1)
    80006594:	4589                	li	a1,2
    80006596:	14459073          	csrw	sip,a1
    8000659a:	6914                	ld	a3,16(a0)
    8000659c:	6510                	ld	a2,8(a0)
    8000659e:	610c                	ld	a1,0(a0)
    800065a0:	34051573          	csrrw	a0,mscratch,a0
    800065a4:	30200073          	mret
	...

00000000800065aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800065aa:	1141                	addi	sp,sp,-16
    800065ac:	e422                	sd	s0,8(sp)
    800065ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800065b0:	0c0007b7          	lui	a5,0xc000
    800065b4:	4705                	li	a4,1
    800065b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800065b8:	c3d8                	sw	a4,4(a5)
}
    800065ba:	6422                	ld	s0,8(sp)
    800065bc:	0141                	addi	sp,sp,16
    800065be:	8082                	ret

00000000800065c0 <plicinithart>:

void
plicinithart(void)
{
    800065c0:	1141                	addi	sp,sp,-16
    800065c2:	e406                	sd	ra,8(sp)
    800065c4:	e022                	sd	s0,0(sp)
    800065c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800065c8:	ffffc097          	auipc	ra,0xffffc
    800065cc:	be4080e7          	jalr	-1052(ra) # 800021ac <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800065d0:	0085171b          	slliw	a4,a0,0x8
    800065d4:	0c0027b7          	lui	a5,0xc002
    800065d8:	97ba                	add	a5,a5,a4
    800065da:	40200713          	li	a4,1026
    800065de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800065e2:	00d5151b          	slliw	a0,a0,0xd
    800065e6:	0c2017b7          	lui	a5,0xc201
    800065ea:	953e                	add	a0,a0,a5
    800065ec:	00052023          	sw	zero,0(a0)
}
    800065f0:	60a2                	ld	ra,8(sp)
    800065f2:	6402                	ld	s0,0(sp)
    800065f4:	0141                	addi	sp,sp,16
    800065f6:	8082                	ret

00000000800065f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800065f8:	1141                	addi	sp,sp,-16
    800065fa:	e406                	sd	ra,8(sp)
    800065fc:	e022                	sd	s0,0(sp)
    800065fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006600:	ffffc097          	auipc	ra,0xffffc
    80006604:	bac080e7          	jalr	-1108(ra) # 800021ac <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006608:	00d5179b          	slliw	a5,a0,0xd
    8000660c:	0c201537          	lui	a0,0xc201
    80006610:	953e                	add	a0,a0,a5
  return irq;
}
    80006612:	4148                	lw	a0,4(a0)
    80006614:	60a2                	ld	ra,8(sp)
    80006616:	6402                	ld	s0,0(sp)
    80006618:	0141                	addi	sp,sp,16
    8000661a:	8082                	ret

000000008000661c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000661c:	1101                	addi	sp,sp,-32
    8000661e:	ec06                	sd	ra,24(sp)
    80006620:	e822                	sd	s0,16(sp)
    80006622:	e426                	sd	s1,8(sp)
    80006624:	1000                	addi	s0,sp,32
    80006626:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006628:	ffffc097          	auipc	ra,0xffffc
    8000662c:	b84080e7          	jalr	-1148(ra) # 800021ac <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006630:	00d5151b          	slliw	a0,a0,0xd
    80006634:	0c2017b7          	lui	a5,0xc201
    80006638:	97aa                	add	a5,a5,a0
    8000663a:	c3c4                	sw	s1,4(a5)
}
    8000663c:	60e2                	ld	ra,24(sp)
    8000663e:	6442                	ld	s0,16(sp)
    80006640:	64a2                	ld	s1,8(sp)
    80006642:	6105                	addi	sp,sp,32
    80006644:	8082                	ret

0000000080006646 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006646:	1141                	addi	sp,sp,-16
    80006648:	e406                	sd	ra,8(sp)
    8000664a:	e022                	sd	s0,0(sp)
    8000664c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000664e:	479d                	li	a5,7
    80006650:	06a7c963          	blt	a5,a0,800066c2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006654:	0001d797          	auipc	a5,0x1d
    80006658:	9ac78793          	addi	a5,a5,-1620 # 80023000 <disk>
    8000665c:	00a78733          	add	a4,a5,a0
    80006660:	6789                	lui	a5,0x2
    80006662:	97ba                	add	a5,a5,a4
    80006664:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006668:	e7ad                	bnez	a5,800066d2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000666a:	00451793          	slli	a5,a0,0x4
    8000666e:	0001f717          	auipc	a4,0x1f
    80006672:	99270713          	addi	a4,a4,-1646 # 80025000 <disk+0x2000>
    80006676:	6314                	ld	a3,0(a4)
    80006678:	96be                	add	a3,a3,a5
    8000667a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000667e:	6314                	ld	a3,0(a4)
    80006680:	96be                	add	a3,a3,a5
    80006682:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006686:	6314                	ld	a3,0(a4)
    80006688:	96be                	add	a3,a3,a5
    8000668a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000668e:	6318                	ld	a4,0(a4)
    80006690:	97ba                	add	a5,a5,a4
    80006692:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006696:	0001d797          	auipc	a5,0x1d
    8000669a:	96a78793          	addi	a5,a5,-1686 # 80023000 <disk>
    8000669e:	97aa                	add	a5,a5,a0
    800066a0:	6509                	lui	a0,0x2
    800066a2:	953e                	add	a0,a0,a5
    800066a4:	4785                	li	a5,1
    800066a6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800066aa:	0001f517          	auipc	a0,0x1f
    800066ae:	96e50513          	addi	a0,a0,-1682 # 80025018 <disk+0x2018>
    800066b2:	ffffc097          	auipc	ra,0xffffc
    800066b6:	44c080e7          	jalr	1100(ra) # 80002afe <wakeup>
}
    800066ba:	60a2                	ld	ra,8(sp)
    800066bc:	6402                	ld	s0,0(sp)
    800066be:	0141                	addi	sp,sp,16
    800066c0:	8082                	ret
    panic("free_desc 1");
    800066c2:	00002517          	auipc	a0,0x2
    800066c6:	1fe50513          	addi	a0,a0,510 # 800088c0 <syscalls+0x330>
    800066ca:	ffffa097          	auipc	ra,0xffffa
    800066ce:	e74080e7          	jalr	-396(ra) # 8000053e <panic>
    panic("free_desc 2");
    800066d2:	00002517          	auipc	a0,0x2
    800066d6:	1fe50513          	addi	a0,a0,510 # 800088d0 <syscalls+0x340>
    800066da:	ffffa097          	auipc	ra,0xffffa
    800066de:	e64080e7          	jalr	-412(ra) # 8000053e <panic>

00000000800066e2 <virtio_disk_init>:
{
    800066e2:	1101                	addi	sp,sp,-32
    800066e4:	ec06                	sd	ra,24(sp)
    800066e6:	e822                	sd	s0,16(sp)
    800066e8:	e426                	sd	s1,8(sp)
    800066ea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800066ec:	00002597          	auipc	a1,0x2
    800066f0:	1f458593          	addi	a1,a1,500 # 800088e0 <syscalls+0x350>
    800066f4:	0001f517          	auipc	a0,0x1f
    800066f8:	a3450513          	addi	a0,a0,-1484 # 80025128 <disk+0x2128>
    800066fc:	ffffa097          	auipc	ra,0xffffa
    80006700:	458080e7          	jalr	1112(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006704:	100017b7          	lui	a5,0x10001
    80006708:	4398                	lw	a4,0(a5)
    8000670a:	2701                	sext.w	a4,a4
    8000670c:	747277b7          	lui	a5,0x74727
    80006710:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006714:	0ef71163          	bne	a4,a5,800067f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006718:	100017b7          	lui	a5,0x10001
    8000671c:	43dc                	lw	a5,4(a5)
    8000671e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006720:	4705                	li	a4,1
    80006722:	0ce79a63          	bne	a5,a4,800067f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006726:	100017b7          	lui	a5,0x10001
    8000672a:	479c                	lw	a5,8(a5)
    8000672c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000672e:	4709                	li	a4,2
    80006730:	0ce79363          	bne	a5,a4,800067f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006734:	100017b7          	lui	a5,0x10001
    80006738:	47d8                	lw	a4,12(a5)
    8000673a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000673c:	554d47b7          	lui	a5,0x554d4
    80006740:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006744:	0af71963          	bne	a4,a5,800067f6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006748:	100017b7          	lui	a5,0x10001
    8000674c:	4705                	li	a4,1
    8000674e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006750:	470d                	li	a4,3
    80006752:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006754:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006756:	c7ffe737          	lui	a4,0xc7ffe
    8000675a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000675e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006760:	2701                	sext.w	a4,a4
    80006762:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006764:	472d                	li	a4,11
    80006766:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006768:	473d                	li	a4,15
    8000676a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000676c:	6705                	lui	a4,0x1
    8000676e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006770:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006774:	5bdc                	lw	a5,52(a5)
    80006776:	2781                	sext.w	a5,a5
  if(max == 0)
    80006778:	c7d9                	beqz	a5,80006806 <virtio_disk_init+0x124>
  if(max < NUM)
    8000677a:	471d                	li	a4,7
    8000677c:	08f77d63          	bgeu	a4,a5,80006816 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006780:	100014b7          	lui	s1,0x10001
    80006784:	47a1                	li	a5,8
    80006786:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006788:	6609                	lui	a2,0x2
    8000678a:	4581                	li	a1,0
    8000678c:	0001d517          	auipc	a0,0x1d
    80006790:	87450513          	addi	a0,a0,-1932 # 80023000 <disk>
    80006794:	ffffa097          	auipc	ra,0xffffa
    80006798:	54c080e7          	jalr	1356(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000679c:	0001d717          	auipc	a4,0x1d
    800067a0:	86470713          	addi	a4,a4,-1948 # 80023000 <disk>
    800067a4:	00c75793          	srli	a5,a4,0xc
    800067a8:	2781                	sext.w	a5,a5
    800067aa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800067ac:	0001f797          	auipc	a5,0x1f
    800067b0:	85478793          	addi	a5,a5,-1964 # 80025000 <disk+0x2000>
    800067b4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800067b6:	0001d717          	auipc	a4,0x1d
    800067ba:	8ca70713          	addi	a4,a4,-1846 # 80023080 <disk+0x80>
    800067be:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800067c0:	0001e717          	auipc	a4,0x1e
    800067c4:	84070713          	addi	a4,a4,-1984 # 80024000 <disk+0x1000>
    800067c8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800067ca:	4705                	li	a4,1
    800067cc:	00e78c23          	sb	a4,24(a5)
    800067d0:	00e78ca3          	sb	a4,25(a5)
    800067d4:	00e78d23          	sb	a4,26(a5)
    800067d8:	00e78da3          	sb	a4,27(a5)
    800067dc:	00e78e23          	sb	a4,28(a5)
    800067e0:	00e78ea3          	sb	a4,29(a5)
    800067e4:	00e78f23          	sb	a4,30(a5)
    800067e8:	00e78fa3          	sb	a4,31(a5)
}
    800067ec:	60e2                	ld	ra,24(sp)
    800067ee:	6442                	ld	s0,16(sp)
    800067f0:	64a2                	ld	s1,8(sp)
    800067f2:	6105                	addi	sp,sp,32
    800067f4:	8082                	ret
    panic("could not find virtio disk");
    800067f6:	00002517          	auipc	a0,0x2
    800067fa:	0fa50513          	addi	a0,a0,250 # 800088f0 <syscalls+0x360>
    800067fe:	ffffa097          	auipc	ra,0xffffa
    80006802:	d40080e7          	jalr	-704(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006806:	00002517          	auipc	a0,0x2
    8000680a:	10a50513          	addi	a0,a0,266 # 80008910 <syscalls+0x380>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006816:	00002517          	auipc	a0,0x2
    8000681a:	11a50513          	addi	a0,a0,282 # 80008930 <syscalls+0x3a0>
    8000681e:	ffffa097          	auipc	ra,0xffffa
    80006822:	d20080e7          	jalr	-736(ra) # 8000053e <panic>

0000000080006826 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006826:	7159                	addi	sp,sp,-112
    80006828:	f486                	sd	ra,104(sp)
    8000682a:	f0a2                	sd	s0,96(sp)
    8000682c:	eca6                	sd	s1,88(sp)
    8000682e:	e8ca                	sd	s2,80(sp)
    80006830:	e4ce                	sd	s3,72(sp)
    80006832:	e0d2                	sd	s4,64(sp)
    80006834:	fc56                	sd	s5,56(sp)
    80006836:	f85a                	sd	s6,48(sp)
    80006838:	f45e                	sd	s7,40(sp)
    8000683a:	f062                	sd	s8,32(sp)
    8000683c:	ec66                	sd	s9,24(sp)
    8000683e:	e86a                	sd	s10,16(sp)
    80006840:	1880                	addi	s0,sp,112
    80006842:	892a                	mv	s2,a0
    80006844:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006846:	00c52c83          	lw	s9,12(a0)
    8000684a:	001c9c9b          	slliw	s9,s9,0x1
    8000684e:	1c82                	slli	s9,s9,0x20
    80006850:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006854:	0001f517          	auipc	a0,0x1f
    80006858:	8d450513          	addi	a0,a0,-1836 # 80025128 <disk+0x2128>
    8000685c:	ffffa097          	auipc	ra,0xffffa
    80006860:	388080e7          	jalr	904(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006864:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006866:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006868:	0001cb97          	auipc	s7,0x1c
    8000686c:	798b8b93          	addi	s7,s7,1944 # 80023000 <disk>
    80006870:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006872:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006874:	8a4e                	mv	s4,s3
    80006876:	a051                	j	800068fa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006878:	00fb86b3          	add	a3,s7,a5
    8000687c:	96da                	add	a3,a3,s6
    8000687e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006882:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006884:	0207c563          	bltz	a5,800068ae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006888:	2485                	addiw	s1,s1,1
    8000688a:	0711                	addi	a4,a4,4
    8000688c:	25548063          	beq	s1,s5,80006acc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006890:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006892:	0001e697          	auipc	a3,0x1e
    80006896:	78668693          	addi	a3,a3,1926 # 80025018 <disk+0x2018>
    8000689a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000689c:	0006c583          	lbu	a1,0(a3)
    800068a0:	fde1                	bnez	a1,80006878 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800068a2:	2785                	addiw	a5,a5,1
    800068a4:	0685                	addi	a3,a3,1
    800068a6:	ff879be3          	bne	a5,s8,8000689c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800068aa:	57fd                	li	a5,-1
    800068ac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800068ae:	02905a63          	blez	s1,800068e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068b2:	f9042503          	lw	a0,-112(s0)
    800068b6:	00000097          	auipc	ra,0x0
    800068ba:	d90080e7          	jalr	-624(ra) # 80006646 <free_desc>
      for(int j = 0; j < i; j++)
    800068be:	4785                	li	a5,1
    800068c0:	0297d163          	bge	a5,s1,800068e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068c4:	f9442503          	lw	a0,-108(s0)
    800068c8:	00000097          	auipc	ra,0x0
    800068cc:	d7e080e7          	jalr	-642(ra) # 80006646 <free_desc>
      for(int j = 0; j < i; j++)
    800068d0:	4789                	li	a5,2
    800068d2:	0097d863          	bge	a5,s1,800068e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068d6:	f9842503          	lw	a0,-104(s0)
    800068da:	00000097          	auipc	ra,0x0
    800068de:	d6c080e7          	jalr	-660(ra) # 80006646 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800068e2:	0001f597          	auipc	a1,0x1f
    800068e6:	84658593          	addi	a1,a1,-1978 # 80025128 <disk+0x2128>
    800068ea:	0001e517          	auipc	a0,0x1e
    800068ee:	72e50513          	addi	a0,a0,1838 # 80025018 <disk+0x2018>
    800068f2:	ffffc097          	auipc	ra,0xffffc
    800068f6:	072080e7          	jalr	114(ra) # 80002964 <sleep>
  for(int i = 0; i < 3; i++){
    800068fa:	f9040713          	addi	a4,s0,-112
    800068fe:	84ce                	mv	s1,s3
    80006900:	bf41                	j	80006890 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006902:	20058713          	addi	a4,a1,512
    80006906:	00471693          	slli	a3,a4,0x4
    8000690a:	0001c717          	auipc	a4,0x1c
    8000690e:	6f670713          	addi	a4,a4,1782 # 80023000 <disk>
    80006912:	9736                	add	a4,a4,a3
    80006914:	4685                	li	a3,1
    80006916:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000691a:	20058713          	addi	a4,a1,512
    8000691e:	00471693          	slli	a3,a4,0x4
    80006922:	0001c717          	auipc	a4,0x1c
    80006926:	6de70713          	addi	a4,a4,1758 # 80023000 <disk>
    8000692a:	9736                	add	a4,a4,a3
    8000692c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006930:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006934:	7679                	lui	a2,0xffffe
    80006936:	963e                	add	a2,a2,a5
    80006938:	0001e697          	auipc	a3,0x1e
    8000693c:	6c868693          	addi	a3,a3,1736 # 80025000 <disk+0x2000>
    80006940:	6298                	ld	a4,0(a3)
    80006942:	9732                	add	a4,a4,a2
    80006944:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006946:	6298                	ld	a4,0(a3)
    80006948:	9732                	add	a4,a4,a2
    8000694a:	4541                	li	a0,16
    8000694c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000694e:	6298                	ld	a4,0(a3)
    80006950:	9732                	add	a4,a4,a2
    80006952:	4505                	li	a0,1
    80006954:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006958:	f9442703          	lw	a4,-108(s0)
    8000695c:	6288                	ld	a0,0(a3)
    8000695e:	962a                	add	a2,a2,a0
    80006960:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006964:	0712                	slli	a4,a4,0x4
    80006966:	6290                	ld	a2,0(a3)
    80006968:	963a                	add	a2,a2,a4
    8000696a:	05890513          	addi	a0,s2,88
    8000696e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006970:	6294                	ld	a3,0(a3)
    80006972:	96ba                	add	a3,a3,a4
    80006974:	40000613          	li	a2,1024
    80006978:	c690                	sw	a2,8(a3)
  if(write)
    8000697a:	140d0063          	beqz	s10,80006aba <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000697e:	0001e697          	auipc	a3,0x1e
    80006982:	6826b683          	ld	a3,1666(a3) # 80025000 <disk+0x2000>
    80006986:	96ba                	add	a3,a3,a4
    80006988:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000698c:	0001c817          	auipc	a6,0x1c
    80006990:	67480813          	addi	a6,a6,1652 # 80023000 <disk>
    80006994:	0001e517          	auipc	a0,0x1e
    80006998:	66c50513          	addi	a0,a0,1644 # 80025000 <disk+0x2000>
    8000699c:	6114                	ld	a3,0(a0)
    8000699e:	96ba                	add	a3,a3,a4
    800069a0:	00c6d603          	lhu	a2,12(a3)
    800069a4:	00166613          	ori	a2,a2,1
    800069a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800069ac:	f9842683          	lw	a3,-104(s0)
    800069b0:	6110                	ld	a2,0(a0)
    800069b2:	9732                	add	a4,a4,a2
    800069b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800069b8:	20058613          	addi	a2,a1,512
    800069bc:	0612                	slli	a2,a2,0x4
    800069be:	9642                	add	a2,a2,a6
    800069c0:	577d                	li	a4,-1
    800069c2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800069c6:	00469713          	slli	a4,a3,0x4
    800069ca:	6114                	ld	a3,0(a0)
    800069cc:	96ba                	add	a3,a3,a4
    800069ce:	03078793          	addi	a5,a5,48
    800069d2:	97c2                	add	a5,a5,a6
    800069d4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800069d6:	611c                	ld	a5,0(a0)
    800069d8:	97ba                	add	a5,a5,a4
    800069da:	4685                	li	a3,1
    800069dc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800069de:	611c                	ld	a5,0(a0)
    800069e0:	97ba                	add	a5,a5,a4
    800069e2:	4809                	li	a6,2
    800069e4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800069e8:	611c                	ld	a5,0(a0)
    800069ea:	973e                	add	a4,a4,a5
    800069ec:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800069f0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800069f4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800069f8:	6518                	ld	a4,8(a0)
    800069fa:	00275783          	lhu	a5,2(a4)
    800069fe:	8b9d                	andi	a5,a5,7
    80006a00:	0786                	slli	a5,a5,0x1
    80006a02:	97ba                	add	a5,a5,a4
    80006a04:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006a08:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006a0c:	6518                	ld	a4,8(a0)
    80006a0e:	00275783          	lhu	a5,2(a4)
    80006a12:	2785                	addiw	a5,a5,1
    80006a14:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006a18:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006a1c:	100017b7          	lui	a5,0x10001
    80006a20:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006a24:	00492703          	lw	a4,4(s2)
    80006a28:	4785                	li	a5,1
    80006a2a:	02f71163          	bne	a4,a5,80006a4c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006a2e:	0001e997          	auipc	s3,0x1e
    80006a32:	6fa98993          	addi	s3,s3,1786 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006a36:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006a38:	85ce                	mv	a1,s3
    80006a3a:	854a                	mv	a0,s2
    80006a3c:	ffffc097          	auipc	ra,0xffffc
    80006a40:	f28080e7          	jalr	-216(ra) # 80002964 <sleep>
  while(b->disk == 1) {
    80006a44:	00492783          	lw	a5,4(s2)
    80006a48:	fe9788e3          	beq	a5,s1,80006a38 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006a4c:	f9042903          	lw	s2,-112(s0)
    80006a50:	20090793          	addi	a5,s2,512
    80006a54:	00479713          	slli	a4,a5,0x4
    80006a58:	0001c797          	auipc	a5,0x1c
    80006a5c:	5a878793          	addi	a5,a5,1448 # 80023000 <disk>
    80006a60:	97ba                	add	a5,a5,a4
    80006a62:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006a66:	0001e997          	auipc	s3,0x1e
    80006a6a:	59a98993          	addi	s3,s3,1434 # 80025000 <disk+0x2000>
    80006a6e:	00491713          	slli	a4,s2,0x4
    80006a72:	0009b783          	ld	a5,0(s3)
    80006a76:	97ba                	add	a5,a5,a4
    80006a78:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a7c:	854a                	mv	a0,s2
    80006a7e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a82:	00000097          	auipc	ra,0x0
    80006a86:	bc4080e7          	jalr	-1084(ra) # 80006646 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a8a:	8885                	andi	s1,s1,1
    80006a8c:	f0ed                	bnez	s1,80006a6e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a8e:	0001e517          	auipc	a0,0x1e
    80006a92:	69a50513          	addi	a0,a0,1690 # 80025128 <disk+0x2128>
    80006a96:	ffffa097          	auipc	ra,0xffffa
    80006a9a:	202080e7          	jalr	514(ra) # 80000c98 <release>
}
    80006a9e:	70a6                	ld	ra,104(sp)
    80006aa0:	7406                	ld	s0,96(sp)
    80006aa2:	64e6                	ld	s1,88(sp)
    80006aa4:	6946                	ld	s2,80(sp)
    80006aa6:	69a6                	ld	s3,72(sp)
    80006aa8:	6a06                	ld	s4,64(sp)
    80006aaa:	7ae2                	ld	s5,56(sp)
    80006aac:	7b42                	ld	s6,48(sp)
    80006aae:	7ba2                	ld	s7,40(sp)
    80006ab0:	7c02                	ld	s8,32(sp)
    80006ab2:	6ce2                	ld	s9,24(sp)
    80006ab4:	6d42                	ld	s10,16(sp)
    80006ab6:	6165                	addi	sp,sp,112
    80006ab8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006aba:	0001e697          	auipc	a3,0x1e
    80006abe:	5466b683          	ld	a3,1350(a3) # 80025000 <disk+0x2000>
    80006ac2:	96ba                	add	a3,a3,a4
    80006ac4:	4609                	li	a2,2
    80006ac6:	00c69623          	sh	a2,12(a3)
    80006aca:	b5c9                	j	8000698c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006acc:	f9042583          	lw	a1,-112(s0)
    80006ad0:	20058793          	addi	a5,a1,512
    80006ad4:	0792                	slli	a5,a5,0x4
    80006ad6:	0001c517          	auipc	a0,0x1c
    80006ada:	5d250513          	addi	a0,a0,1490 # 800230a8 <disk+0xa8>
    80006ade:	953e                	add	a0,a0,a5
  if(write)
    80006ae0:	e20d11e3          	bnez	s10,80006902 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006ae4:	20058713          	addi	a4,a1,512
    80006ae8:	00471693          	slli	a3,a4,0x4
    80006aec:	0001c717          	auipc	a4,0x1c
    80006af0:	51470713          	addi	a4,a4,1300 # 80023000 <disk>
    80006af4:	9736                	add	a4,a4,a3
    80006af6:	0a072423          	sw	zero,168(a4)
    80006afa:	b505                	j	8000691a <virtio_disk_rw+0xf4>

0000000080006afc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006afc:	1101                	addi	sp,sp,-32
    80006afe:	ec06                	sd	ra,24(sp)
    80006b00:	e822                	sd	s0,16(sp)
    80006b02:	e426                	sd	s1,8(sp)
    80006b04:	e04a                	sd	s2,0(sp)
    80006b06:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006b08:	0001e517          	auipc	a0,0x1e
    80006b0c:	62050513          	addi	a0,a0,1568 # 80025128 <disk+0x2128>
    80006b10:	ffffa097          	auipc	ra,0xffffa
    80006b14:	0d4080e7          	jalr	212(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006b18:	10001737          	lui	a4,0x10001
    80006b1c:	533c                	lw	a5,96(a4)
    80006b1e:	8b8d                	andi	a5,a5,3
    80006b20:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006b22:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006b26:	0001e797          	auipc	a5,0x1e
    80006b2a:	4da78793          	addi	a5,a5,1242 # 80025000 <disk+0x2000>
    80006b2e:	6b94                	ld	a3,16(a5)
    80006b30:	0207d703          	lhu	a4,32(a5)
    80006b34:	0026d783          	lhu	a5,2(a3)
    80006b38:	06f70163          	beq	a4,a5,80006b9a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b3c:	0001c917          	auipc	s2,0x1c
    80006b40:	4c490913          	addi	s2,s2,1220 # 80023000 <disk>
    80006b44:	0001e497          	auipc	s1,0x1e
    80006b48:	4bc48493          	addi	s1,s1,1212 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006b4c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b50:	6898                	ld	a4,16(s1)
    80006b52:	0204d783          	lhu	a5,32(s1)
    80006b56:	8b9d                	andi	a5,a5,7
    80006b58:	078e                	slli	a5,a5,0x3
    80006b5a:	97ba                	add	a5,a5,a4
    80006b5c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006b5e:	20078713          	addi	a4,a5,512
    80006b62:	0712                	slli	a4,a4,0x4
    80006b64:	974a                	add	a4,a4,s2
    80006b66:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006b6a:	e731                	bnez	a4,80006bb6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006b6c:	20078793          	addi	a5,a5,512
    80006b70:	0792                	slli	a5,a5,0x4
    80006b72:	97ca                	add	a5,a5,s2
    80006b74:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006b76:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b7a:	ffffc097          	auipc	ra,0xffffc
    80006b7e:	f84080e7          	jalr	-124(ra) # 80002afe <wakeup>

    disk.used_idx += 1;
    80006b82:	0204d783          	lhu	a5,32(s1)
    80006b86:	2785                	addiw	a5,a5,1
    80006b88:	17c2                	slli	a5,a5,0x30
    80006b8a:	93c1                	srli	a5,a5,0x30
    80006b8c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b90:	6898                	ld	a4,16(s1)
    80006b92:	00275703          	lhu	a4,2(a4)
    80006b96:	faf71be3          	bne	a4,a5,80006b4c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006b9a:	0001e517          	auipc	a0,0x1e
    80006b9e:	58e50513          	addi	a0,a0,1422 # 80025128 <disk+0x2128>
    80006ba2:	ffffa097          	auipc	ra,0xffffa
    80006ba6:	0f6080e7          	jalr	246(ra) # 80000c98 <release>
}
    80006baa:	60e2                	ld	ra,24(sp)
    80006bac:	6442                	ld	s0,16(sp)
    80006bae:	64a2                	ld	s1,8(sp)
    80006bb0:	6902                	ld	s2,0(sp)
    80006bb2:	6105                	addi	sp,sp,32
    80006bb4:	8082                	ret
      panic("virtio_disk_intr status");
    80006bb6:	00002517          	auipc	a0,0x2
    80006bba:	d9a50513          	addi	a0,a0,-614 # 80008950 <syscalls+0x3c0>
    80006bbe:	ffffa097          	auipc	ra,0xffffa
    80006bc2:	980080e7          	jalr	-1664(ra) # 8000053e <panic>

0000000080006bc6 <cas>:
    80006bc6:	100522af          	lr.w	t0,(a0)
    80006bca:	00b29563          	bne	t0,a1,80006bd4 <fail>
    80006bce:	18c5252f          	sc.w	a0,a2,(a0)
    80006bd2:	8082                	ret

0000000080006bd4 <fail>:
    80006bd4:	4505                	li	a0,1
    80006bd6:	8082                	ret
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
