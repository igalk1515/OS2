
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9d013103          	ld	sp,-1584(sp) # 800089d0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	62c78793          	addi	a5,a5,1580 # 80006690 <timervec>
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
    80000130:	e62080e7          	jalr	-414(ra) # 80002f8e <either_copyin>
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
    800001c8:	036080e7          	jalr	54(ra) # 800021fa <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	89c080e7          	jalr	-1892(ra) # 80002a70 <sleep>
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
    80000214:	d28080e7          	jalr	-728(ra) # 80002f38 <either_copyout>
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
    800002f6:	cf2080e7          	jalr	-782(ra) # 80002fe4 <procdump>
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
    8000044a:	7c4080e7          	jalr	1988(ra) # 80002c0a <wakeup>
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
    8000047c:	78878793          	addi	a5,a5,1928 # 80021c00 <devsw>
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
    800008a4:	36a080e7          	jalr	874(ra) # 80002c0a <wakeup>
    
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
    80000930:	144080e7          	jalr	324(ra) # 80002a70 <sleep>
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
    80000b82:	658080e7          	jalr	1624(ra) # 800021d6 <mycpu>
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
    80000bb4:	626080e7          	jalr	1574(ra) # 800021d6 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	61a080e7          	jalr	1562(ra) # 800021d6 <mycpu>
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
    80000bd8:	602080e7          	jalr	1538(ra) # 800021d6 <mycpu>
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
    80000c18:	5c2080e7          	jalr	1474(ra) # 800021d6 <mycpu>
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
    80000c44:	596080e7          	jalr	1430(ra) # 800021d6 <mycpu>
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
    80000e9a:	330080e7          	jalr	816(ra) # 800021c6 <cpuid>
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
    80000eb6:	314080e7          	jalr	788(ra) # 800021c6 <cpuid>
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
    80000ed8:	250080e7          	jalr	592(ra) # 80003124 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	7f4080e7          	jalr	2036(ra) # 800066d0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	932080e7          	jalr	-1742(ra) # 80002816 <scheduler>
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
    80000f48:	12e080e7          	jalr	302(ra) # 80002072 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	1b0080e7          	jalr	432(ra) # 800030fc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	1d0080e7          	jalr	464(ra) # 80003124 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	75e080e7          	jalr	1886(ra) # 800066ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	76c080e7          	jalr	1900(ra) # 800066d0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00003097          	auipc	ra,0x3
    80000f70:	944080e7          	jalr	-1724(ra) # 800038b0 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	fd4080e7          	jalr	-44(ra) # 80003f48 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	f7e080e7          	jalr	-130(ra) # 80004efa <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00006097          	auipc	ra,0x6
    80000f88:	86e080e7          	jalr	-1938(ra) # 800067f2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	560080e7          	jalr	1376(ra) # 800024ec <userinit>
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
    80001244:	d9c080e7          	jalr	-612(ra) # 80001fdc <proc_mapstacks>
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
    80001862:	aea50513          	addi	a0,a0,-1302 # 80011348 <unusedLock>
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
    80001896:	a8650513          	addi	a0,a0,-1402 # 80011318 <zombieLock>
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	34a080e7          	jalr	842(ra) # 80000be4 <acquire>
    800018a2:	b7f1                	j	8000186e <acquire_list2+0x30>
      number == 3 ? acquire(&sleepLock): 
    800018a4:	00010517          	auipc	a0,0x10
    800018a8:	a8c50513          	addi	a0,a0,-1396 # 80011330 <sleepLock>
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
    800018ce:	02f50963          	beq	a0,a5,80001900 <get_first2+0x3a>
      number == 3 ? p = sleepingList :
    800018d2:	478d                	li	a5,3
    800018d4:	02f50b63          	beq	a0,a5,8000190a <get_first2+0x44>
        number == 4 ? p = unusedList:
    800018d8:	4791                	li	a5,4
    800018da:	02f51d63          	bne	a0,a5,80001914 <get_first2+0x4e>
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
    800018fa:	1105b503          	ld	a0,272(a1) # 4000110 <_entry-0x7bfffef0>
    800018fe:	8082                	ret
    number == 2 ? p = zombieList  :
    80001900:	00007517          	auipc	a0,0x7
    80001904:	75853503          	ld	a0,1880(a0) # 80009058 <zombieList>
    80001908:	8082                	ret
      number == 3 ? p = sleepingList :
    8000190a:	00007517          	auipc	a0,0x7
    8000190e:	74653503          	ld	a0,1862(a0) # 80009050 <sleepingList>
    80001912:	8082                	ret
struct proc* get_first2(int number, int parent_cpu){
    80001914:	1141                	addi	sp,sp,-16
    80001916:	e406                	sd	ra,8(sp)
    80001918:	e022                	sd	s0,0(sp)
    8000191a:	0800                	addi	s0,sp,16
          panic("wrong call in get_first2");
    8000191c:	00007517          	auipc	a0,0x7
    80001920:	8dc50513          	addi	a0,a0,-1828 # 800081f8 <digits+0x1b8>
    80001924:	fffff097          	auipc	ra,0xfffff
    80001928:	c1a080e7          	jalr	-998(ra) # 8000053e <panic>

000000008000192c <set_first2>:

void
set_first2(struct proc* p, int number, int parent_cpu)//TODO: change name of function
{
  number == 1 ?  cpus[parent_cpu].first = p: 
    8000192c:	4785                	li	a5,1
    8000192e:	00f58c63          	beq	a1,a5,80001946 <set_first2+0x1a>
    number == 2 ? zombieList = p: 
    80001932:	4789                	li	a5,2
    80001934:	02f58563          	beq	a1,a5,8000195e <set_first2+0x32>
      number == 3 ? sleepingList = p: 
    80001938:	478d                	li	a5,3
    8000193a:	02f58763          	beq	a1,a5,80001968 <set_first2+0x3c>
        number == 4 ? unusedList:  
    8000193e:	4791                	li	a5,4
    80001940:	02f59963          	bne	a1,a5,80001972 <set_first2+0x46>
    80001944:	8082                	ret
  number == 1 ?  cpus[parent_cpu].first = p: 
    80001946:	00461793          	slli	a5,a2,0x4
    8000194a:	963e                	add	a2,a2,a5
    8000194c:	060e                	slli	a2,a2,0x3
    8000194e:	00010797          	auipc	a5,0x10
    80001952:	98278793          	addi	a5,a5,-1662 # 800112d0 <readyLock>
    80001956:	963e                	add	a2,a2,a5
    80001958:	10a63823          	sd	a0,272(a2) # 1110 <_entry-0x7fffeef0>
    8000195c:	8082                	ret
    number == 2 ? zombieList = p: 
    8000195e:	00007797          	auipc	a5,0x7
    80001962:	6ea7bd23          	sd	a0,1786(a5) # 80009058 <zombieList>
    80001966:	8082                	ret
      number == 3 ? sleepingList = p: 
    80001968:	00007797          	auipc	a5,0x7
    8000196c:	6ea7b423          	sd	a0,1768(a5) # 80009050 <sleepingList>
    80001970:	8082                	ret
{
    80001972:	1141                	addi	sp,sp,-16
    80001974:	e406                	sd	ra,8(sp)
    80001976:	e022                	sd	s0,0(sp)
    80001978:	0800                	addi	s0,sp,16
          panic("wrong call in set_first2");
    8000197a:	00007517          	auipc	a0,0x7
    8000197e:	89e50513          	addi	a0,a0,-1890 # 80008218 <digits+0x1d8>
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	bbc080e7          	jalr	-1092(ra) # 8000053e <panic>

000000008000198a <release_list2>:
}

void
release_list2(int number, int parent_cpu){
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e406                	sd	ra,8(sp)
    8000198e:	e022                	sd	s0,0(sp)
    80001990:	0800                	addi	s0,sp,16
    number == 1 ?  release(&readyLock[parent_cpu]): 
    80001992:	4785                	li	a5,1
    80001994:	02f50763          	beq	a0,a5,800019c2 <release_list2+0x38>
      number == 2 ? release(&zombieLock): 
    80001998:	4789                	li	a5,2
    8000199a:	04f50263          	beq	a0,a5,800019de <release_list2+0x54>
        number == 3 ? release(&sleepLock): 
    8000199e:	478d                	li	a5,3
    800019a0:	04f50863          	beq	a0,a5,800019f0 <release_list2+0x66>
          number == 4 ? release(&unusedLock):  
    800019a4:	4791                	li	a5,4
    800019a6:	04f51e63          	bne	a0,a5,80001a02 <release_list2+0x78>
    800019aa:	00010517          	auipc	a0,0x10
    800019ae:	99e50513          	addi	a0,a0,-1634 # 80011348 <unusedLock>
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	2e6080e7          	jalr	742(ra) # 80000c98 <release>
            panic("wrong call in release_list2");
}
    800019ba:	60a2                	ld	ra,8(sp)
    800019bc:	6402                	ld	s0,0(sp)
    800019be:	0141                	addi	sp,sp,16
    800019c0:	8082                	ret
    number == 1 ?  release(&readyLock[parent_cpu]): 
    800019c2:	00159513          	slli	a0,a1,0x1
    800019c6:	95aa                	add	a1,a1,a0
    800019c8:	058e                	slli	a1,a1,0x3
    800019ca:	00010517          	auipc	a0,0x10
    800019ce:	90650513          	addi	a0,a0,-1786 # 800112d0 <readyLock>
    800019d2:	952e                	add	a0,a0,a1
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	2c4080e7          	jalr	708(ra) # 80000c98 <release>
    800019dc:	bff9                	j	800019ba <release_list2+0x30>
      number == 2 ? release(&zombieLock): 
    800019de:	00010517          	auipc	a0,0x10
    800019e2:	93a50513          	addi	a0,a0,-1734 # 80011318 <zombieLock>
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
    800019ee:	b7f1                	j	800019ba <release_list2+0x30>
        number == 3 ? release(&sleepLock): 
    800019f0:	00010517          	auipc	a0,0x10
    800019f4:	94050513          	addi	a0,a0,-1728 # 80011330 <sleepLock>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>
    80001a00:	bf6d                	j	800019ba <release_list2+0x30>
            panic("wrong call in release_list2");
    80001a02:	00007517          	auipc	a0,0x7
    80001a06:	83650513          	addi	a0,a0,-1994 # 80008238 <digits+0x1f8>
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	b34080e7          	jalr	-1228(ra) # 8000053e <panic>

0000000080001a12 <add_to_list2>:


void
add_to_list2(struct proc* p, struct proc* first, int type, int parent_cpu)//TODO: change name of function
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
    80001a26:	c505                	beqz	a0,80001a4e <add_to_list2+0x3c>
    80001a28:	8b2a                	mv	s6,a0
    80001a2a:	84ae                	mv	s1,a1
    80001a2c:	8a32                	mv	s4,a2
    80001a2e:	8ab6                	mv	s5,a3
  if(!first){
      set_first2(p, type, parent_cpu);
      release_list2(type, parent_cpu);
  }
  else{
    struct proc* prev = 0;
    80001a30:	4901                	li	s2,0
  if(!first){
    80001a32:	e1a1                	bnez	a1,80001a72 <add_to_list2+0x60>
      set_first2(p, type, parent_cpu);
    80001a34:	8636                	mv	a2,a3
    80001a36:	85d2                	mv	a1,s4
    80001a38:	00000097          	auipc	ra,0x0
    80001a3c:	ef4080e7          	jalr	-268(ra) # 8000192c <set_first2>
      release_list2(type, parent_cpu);
    80001a40:	85d6                	mv	a1,s5
    80001a42:	8552                	mv	a0,s4
    80001a44:	00000097          	auipc	ra,0x0
    80001a48:	f46080e7          	jalr	-186(ra) # 8000198a <release_list2>
    80001a4c:	a891                	j	80001aa0 <add_to_list2+0x8e>
    panic("can't add null to list");
    80001a4e:	00007517          	auipc	a0,0x7
    80001a52:	80a50513          	addi	a0,a0,-2038 # 80008258 <digits+0x218>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	ae8080e7          	jalr	-1304(ra) # 8000053e <panic>

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list2(type, parent_cpu);
    80001a5e:	85d6                	mv	a1,s5
    80001a60:	8552                	mv	a0,s4
    80001a62:	00000097          	auipc	ra,0x0
    80001a66:	f28080e7          	jalr	-216(ra) # 8000198a <release_list2>
      }
      prev = first;
      first = first->next;
    80001a6a:	68bc                	ld	a5,80(s1)
    while(first){
    80001a6c:	8926                	mv	s2,s1
    80001a6e:	c395                	beqz	a5,80001a92 <add_to_list2+0x80>
      first = first->next;
    80001a70:	84be                	mv	s1,a5
      acquire(&first->list_lock);
    80001a72:	01848993          	addi	s3,s1,24
    80001a76:	854e                	mv	a0,s3
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	16c080e7          	jalr	364(ra) # 80000be4 <acquire>
      if(prev){
    80001a80:	fc090fe3          	beqz	s2,80001a5e <add_to_list2+0x4c>
        release(&prev->list_lock);
    80001a84:	01890513          	addi	a0,s2,24 # 1018 <_entry-0x7fffefe8>
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	210080e7          	jalr	528(ra) # 80000c98 <release>
    80001a90:	bfe9                	j	80001a6a <add_to_list2+0x58>
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

0000000080001ab4 <add_proc2>:

void //TODO: cahnge 
add_proc2(struct proc* p, int number, int parent_cpu)
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
  acquire_list2(number, parent_cpu);
    80001ac8:	85b2                	mv	a1,a2
    80001aca:	8526                	mv	a0,s1
    80001acc:	00000097          	auipc	ra,0x0
    80001ad0:	d72080e7          	jalr	-654(ra) # 8000183e <acquire_list2>
  first = get_first2(number, parent_cpu);
    80001ad4:	85ca                	mv	a1,s2
    80001ad6:	8526                	mv	a0,s1
    80001ad8:	00000097          	auipc	ra,0x0
    80001adc:	dee080e7          	jalr	-530(ra) # 800018c6 <get_first2>
    80001ae0:	85aa                	mv	a1,a0
  add_to_list2(p, first, number, parent_cpu);//TODO change name
    80001ae2:	86ca                	mv	a3,s2
    80001ae4:	8626                	mv	a2,s1
    80001ae6:	854e                	mv	a0,s3
    80001ae8:	00000097          	auipc	ra,0x0
    80001aec:	f2a080e7          	jalr	-214(ra) # 80001a12 <add_to_list2>
}
    80001af0:	70a2                	ld	ra,40(sp)
    80001af2:	7402                	ld	s0,32(sp)
    80001af4:	64e2                	ld	s1,24(sp)
    80001af6:	6942                	ld	s2,16(sp)
    80001af8:	69a2                	ld	s3,8(sp)
    80001afa:	6145                	addi	sp,sp,48
    80001afc:	8082                	ret

0000000080001afe <acquire_list>:
struct spinlock zombie_lock;
struct spinlock sleeping_lock;
struct spinlock unused_lock;

void
acquire_list(int type, int cpu_id){
    80001afe:	1141                	addi	sp,sp,-16
    80001b00:	e406                	sd	ra,8(sp)
    80001b02:	e022                	sd	s0,0(sp)
    80001b04:	0800                	addi	s0,sp,16
  switch (type)
    80001b06:	4789                	li	a5,2
    80001b08:	04f50e63          	beq	a0,a5,80001b64 <acquire_list+0x66>
    80001b0c:	00a7cf63          	blt	a5,a0,80001b2a <acquire_list+0x2c>
    80001b10:	c90d                	beqz	a0,80001b42 <acquire_list+0x44>
    80001b12:	4785                	li	a5,1
    80001b14:	06f51163          	bne	a0,a5,80001b76 <acquire_list+0x78>
  {
  case READYL:
    acquire(&ready_lock[cpu_id]);
    break;
  case ZOMBIEL:
    acquire(&zombie_lock);
    80001b18:	00010517          	auipc	a0,0x10
    80001b1c:	a2850513          	addi	a0,a0,-1496 # 80011540 <zombie_lock>
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	0c4080e7          	jalr	196(ra) # 80000be4 <acquire>
    break;
    80001b28:	a815                	j	80001b5c <acquire_list+0x5e>
  switch (type)
    80001b2a:	478d                	li	a5,3
    80001b2c:	04f51563          	bne	a0,a5,80001b76 <acquire_list+0x78>
  case SLEEPINGL:
    acquire(&sleeping_lock);
    break;
  case UNUSEDL:
    acquire(&unused_lock);
    80001b30:	00010517          	auipc	a0,0x10
    80001b34:	a4050513          	addi	a0,a0,-1472 # 80011570 <unused_lock>
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	0ac080e7          	jalr	172(ra) # 80000be4 <acquire>
    break;
    80001b40:	a831                	j	80001b5c <acquire_list+0x5e>
    acquire(&ready_lock[cpu_id]);
    80001b42:	00159513          	slli	a0,a1,0x1
    80001b46:	95aa                	add	a1,a1,a0
    80001b48:	058e                	slli	a1,a1,0x3
    80001b4a:	00010517          	auipc	a0,0x10
    80001b4e:	9ae50513          	addi	a0,a0,-1618 # 800114f8 <ready_lock>
    80001b52:	952e                	add	a0,a0,a1
    80001b54:	fffff097          	auipc	ra,0xfffff
    80001b58:	090080e7          	jalr	144(ra) # 80000be4 <acquire>
  
  default:
    panic("wrong type list");
  }
}
    80001b5c:	60a2                	ld	ra,8(sp)
    80001b5e:	6402                	ld	s0,0(sp)
    80001b60:	0141                	addi	sp,sp,16
    80001b62:	8082                	ret
    acquire(&sleeping_lock);
    80001b64:	00010517          	auipc	a0,0x10
    80001b68:	9f450513          	addi	a0,a0,-1548 # 80011558 <sleeping_lock>
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	078080e7          	jalr	120(ra) # 80000be4 <acquire>
    break;
    80001b74:	b7e5                	j	80001b5c <acquire_list+0x5e>
    panic("wrong type list");
    80001b76:	00006517          	auipc	a0,0x6
    80001b7a:	6fa50513          	addi	a0,a0,1786 # 80008270 <digits+0x230>
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	9c0080e7          	jalr	-1600(ra) # 8000053e <panic>

0000000080001b86 <get_head>:

struct proc* get_head(int type, int cpu_id){
  struct proc* p;

  switch (type)
    80001b86:	4789                	li	a5,2
    80001b88:	04f50163          	beq	a0,a5,80001bca <get_head+0x44>
    80001b8c:	00a7cb63          	blt	a5,a0,80001ba2 <get_head+0x1c>
    80001b90:	c10d                	beqz	a0,80001bb2 <get_head+0x2c>
    80001b92:	4785                	li	a5,1
    80001b94:	04f51063          	bne	a0,a5,80001bd4 <get_head+0x4e>
  {
  case READYL:
    p = cpus[cpu_id].first;
    break;
  case ZOMBIEL:
    p = zombie_list;
    80001b98:	00007517          	auipc	a0,0x7
    80001b9c:	4a053503          	ld	a0,1184(a0) # 80009038 <zombie_list>
    break;
    80001ba0:	8082                	ret
  switch (type)
    80001ba2:	478d                	li	a5,3
    80001ba4:	02f51863          	bne	a0,a5,80001bd4 <get_head+0x4e>
  case SLEEPINGL:
    p = sleeping_list;
    break;
  case UNUSEDL:
    p = unused_list;
    80001ba8:	00007517          	auipc	a0,0x7
    80001bac:	48053503          	ld	a0,1152(a0) # 80009028 <unused_list>
  
  default:
    panic("wrong type list");
  }
  return p;
}
    80001bb0:	8082                	ret
    p = cpus[cpu_id].first;
    80001bb2:	00459793          	slli	a5,a1,0x4
    80001bb6:	95be                	add	a1,a1,a5
    80001bb8:	058e                	slli	a1,a1,0x3
    80001bba:	0000f797          	auipc	a5,0xf
    80001bbe:	71678793          	addi	a5,a5,1814 # 800112d0 <readyLock>
    80001bc2:	95be                	add	a1,a1,a5
    80001bc4:	1105b503          	ld	a0,272(a1)
    break;
    80001bc8:	8082                	ret
    p = sleeping_list;
    80001bca:	00007517          	auipc	a0,0x7
    80001bce:	46653503          	ld	a0,1126(a0) # 80009030 <sleeping_list>
    break;
    80001bd2:	8082                	ret
struct proc* get_head(int type, int cpu_id){
    80001bd4:	1141                	addi	sp,sp,-16
    80001bd6:	e406                	sd	ra,8(sp)
    80001bd8:	e022                	sd	s0,0(sp)
    80001bda:	0800                	addi	s0,sp,16
    panic("wrong type list");
    80001bdc:	00006517          	auipc	a0,0x6
    80001be0:	69450513          	addi	a0,a0,1684 # 80008270 <digits+0x230>
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	95a080e7          	jalr	-1702(ra) # 8000053e <panic>

0000000080001bec <set_head>:


void
set_head(struct proc* p, int type, int cpu_id)
{
  switch (type)
    80001bec:	4789                	li	a5,2
    80001bee:	04f58163          	beq	a1,a5,80001c30 <set_head+0x44>
    80001bf2:	00b7cb63          	blt	a5,a1,80001c08 <set_head+0x1c>
    80001bf6:	c18d                	beqz	a1,80001c18 <set_head+0x2c>
    80001bf8:	4785                	li	a5,1
    80001bfa:	04f59063          	bne	a1,a5,80001c3a <set_head+0x4e>
  {
  case READYL:
    cpus[cpu_id].first = p;
    break;
  case ZOMBIEL:
    zombie_list = p;
    80001bfe:	00007797          	auipc	a5,0x7
    80001c02:	42a7bd23          	sd	a0,1082(a5) # 80009038 <zombie_list>
    break;
    80001c06:	8082                	ret
  switch (type)
    80001c08:	478d                	li	a5,3
    80001c0a:	02f59863          	bne	a1,a5,80001c3a <set_head+0x4e>
  case SLEEPINGL:
    sleeping_list = p;
    break;
  case UNUSEDL:
    unused_list = p;
    80001c0e:	00007797          	auipc	a5,0x7
    80001c12:	40a7bd23          	sd	a0,1050(a5) # 80009028 <unused_list>
    break;
    80001c16:	8082                	ret
    cpus[cpu_id].first = p;
    80001c18:	00461793          	slli	a5,a2,0x4
    80001c1c:	963e                	add	a2,a2,a5
    80001c1e:	060e                	slli	a2,a2,0x3
    80001c20:	0000f797          	auipc	a5,0xf
    80001c24:	6b078793          	addi	a5,a5,1712 # 800112d0 <readyLock>
    80001c28:	963e                	add	a2,a2,a5
    80001c2a:	10a63823          	sd	a0,272(a2)
    break;
    80001c2e:	8082                	ret
    sleeping_list = p;
    80001c30:	00007797          	auipc	a5,0x7
    80001c34:	40a7b023          	sd	a0,1024(a5) # 80009030 <sleeping_list>
    break;
    80001c38:	8082                	ret
{
    80001c3a:	1141                	addi	sp,sp,-16
    80001c3c:	e406                	sd	ra,8(sp)
    80001c3e:	e022                	sd	s0,0(sp)
    80001c40:	0800                	addi	s0,sp,16

  
  default:
    panic("wrong type list");
    80001c42:	00006517          	auipc	a0,0x6
    80001c46:	62e50513          	addi	a0,a0,1582 # 80008270 <digits+0x230>
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	8f4080e7          	jalr	-1804(ra) # 8000053e <panic>

0000000080001c52 <release_list3>:
  }
}

void
release_list3(int number, int parent_cpu){
    80001c52:	1141                	addi	sp,sp,-16
    80001c54:	e406                	sd	ra,8(sp)
    80001c56:	e022                	sd	s0,0(sp)
    80001c58:	0800                	addi	s0,sp,16
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001c5a:	4785                	li	a5,1
    80001c5c:	02f50763          	beq	a0,a5,80001c8a <release_list3+0x38>
      number == 2 ? release(&zombie_lock): 
    80001c60:	4789                	li	a5,2
    80001c62:	04f50263          	beq	a0,a5,80001ca6 <release_list3+0x54>
        number == 3 ? release(&sleeping_lock): 
    80001c66:	478d                	li	a5,3
    80001c68:	04f50863          	beq	a0,a5,80001cb8 <release_list3+0x66>
          number == 4 ? release(&unused_lock):  
    80001c6c:	4791                	li	a5,4
    80001c6e:	04f51e63          	bne	a0,a5,80001cca <release_list3+0x78>
    80001c72:	00010517          	auipc	a0,0x10
    80001c76:	8fe50513          	addi	a0,a0,-1794 # 80011570 <unused_lock>
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	01e080e7          	jalr	30(ra) # 80000c98 <release>
            panic("wrong call in release_list3");
}
    80001c82:	60a2                	ld	ra,8(sp)
    80001c84:	6402                	ld	s0,0(sp)
    80001c86:	0141                	addi	sp,sp,16
    80001c88:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001c8a:	00159513          	slli	a0,a1,0x1
    80001c8e:	95aa                	add	a1,a1,a0
    80001c90:	058e                	slli	a1,a1,0x3
    80001c92:	00010517          	auipc	a0,0x10
    80001c96:	86650513          	addi	a0,a0,-1946 # 800114f8 <ready_lock>
    80001c9a:	952e                	add	a0,a0,a1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	ffc080e7          	jalr	-4(ra) # 80000c98 <release>
    80001ca4:	bff9                	j	80001c82 <release_list3+0x30>
      number == 2 ? release(&zombie_lock): 
    80001ca6:	00010517          	auipc	a0,0x10
    80001caa:	89a50513          	addi	a0,a0,-1894 # 80011540 <zombie_lock>
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	fea080e7          	jalr	-22(ra) # 80000c98 <release>
    80001cb6:	b7f1                	j	80001c82 <release_list3+0x30>
        number == 3 ? release(&sleeping_lock): 
    80001cb8:	00010517          	auipc	a0,0x10
    80001cbc:	8a050513          	addi	a0,a0,-1888 # 80011558 <sleeping_lock>
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	fd8080e7          	jalr	-40(ra) # 80000c98 <release>
    80001cc8:	bf6d                	j	80001c82 <release_list3+0x30>
            panic("wrong call in release_list3");
    80001cca:	00006517          	auipc	a0,0x6
    80001cce:	5b650513          	addi	a0,a0,1462 # 80008280 <digits+0x240>
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	86c080e7          	jalr	-1940(ra) # 8000053e <panic>

0000000080001cda <release_list>:

void
release_list(int type, int parent_cpu){
    80001cda:	1141                	addi	sp,sp,-16
    80001cdc:	e406                	sd	ra,8(sp)
    80001cde:	e022                	sd	s0,0(sp)
    80001ce0:	0800                	addi	s0,sp,16
  type==READYL ? release_list3(1,parent_cpu): 
    80001ce2:	c515                	beqz	a0,80001d0e <release_list+0x34>
    type==ZOMBIEL ? release_list3(2,parent_cpu):
    80001ce4:	4785                	li	a5,1
    80001ce6:	04f50263          	beq	a0,a5,80001d2a <release_list+0x50>
      type==SLEEPINGL ? release_list3(3,parent_cpu):
    80001cea:	4789                	li	a5,2
    80001cec:	04f50863          	beq	a0,a5,80001d3c <release_list+0x62>
        type==UNUSEDL ? release_list3(4,parent_cpu):
    80001cf0:	478d                	li	a5,3
    80001cf2:	04f51e63          	bne	a0,a5,80001d4e <release_list+0x74>
          number == 4 ? release(&unused_lock):  
    80001cf6:	00010517          	auipc	a0,0x10
    80001cfa:	87a50513          	addi	a0,a0,-1926 # 80011570 <unused_lock>
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	f9a080e7          	jalr	-102(ra) # 80000c98 <release>
          panic("wrong type list");
}
    80001d06:	60a2                	ld	ra,8(sp)
    80001d08:	6402                	ld	s0,0(sp)
    80001d0a:	0141                	addi	sp,sp,16
    80001d0c:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001d0e:	00159513          	slli	a0,a1,0x1
    80001d12:	95aa                	add	a1,a1,a0
    80001d14:	058e                	slli	a1,a1,0x3
    80001d16:	0000f517          	auipc	a0,0xf
    80001d1a:	7e250513          	addi	a0,a0,2018 # 800114f8 <ready_lock>
    80001d1e:	952e                	add	a0,a0,a1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	f78080e7          	jalr	-136(ra) # 80000c98 <release>
}
    80001d28:	bff9                	j	80001d06 <release_list+0x2c>
      number == 2 ? release(&zombie_lock): 
    80001d2a:	00010517          	auipc	a0,0x10
    80001d2e:	81650513          	addi	a0,a0,-2026 # 80011540 <zombie_lock>
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	f66080e7          	jalr	-154(ra) # 80000c98 <release>
}
    80001d3a:	b7f1                	j	80001d06 <release_list+0x2c>
        number == 3 ? release(&sleeping_lock): 
    80001d3c:	00010517          	auipc	a0,0x10
    80001d40:	81c50513          	addi	a0,a0,-2020 # 80011558 <sleeping_lock>
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	f54080e7          	jalr	-172(ra) # 80000c98 <release>
}
    80001d4c:	bf6d                	j	80001d06 <release_list+0x2c>
          panic("wrong type list");
    80001d4e:	00006517          	auipc	a0,0x6
    80001d52:	52250513          	addi	a0,a0,1314 # 80008270 <digits+0x230>
    80001d56:	ffffe097          	auipc	ra,0xffffe
    80001d5a:	7e8080e7          	jalr	2024(ra) # 8000053e <panic>

0000000080001d5e <add_to_list>:



void
add_to_list(struct proc* p, struct proc* head, int type, int cpu_id)
{
    80001d5e:	7139                	addi	sp,sp,-64
    80001d60:	fc06                	sd	ra,56(sp)
    80001d62:	f822                	sd	s0,48(sp)
    80001d64:	f426                	sd	s1,40(sp)
    80001d66:	f04a                	sd	s2,32(sp)
    80001d68:	ec4e                	sd	s3,24(sp)
    80001d6a:	e852                	sd	s4,16(sp)
    80001d6c:	e456                	sd	s5,8(sp)
    80001d6e:	e05a                	sd	s6,0(sp)
    80001d70:	0080                	addi	s0,sp,64
  if(!p){
    80001d72:	c505                	beqz	a0,80001d9a <add_to_list+0x3c>
    80001d74:	8b2a                	mv	s6,a0
    80001d76:	84ae                	mv	s1,a1
    80001d78:	8a32                	mv	s4,a2
    80001d7a:	8ab6                	mv	s5,a3
  if(!head){
      set_head(p, type, cpu_id);
      release_list(type, cpu_id);
  }
  else{
    struct proc* prev = 0;
    80001d7c:	4901                	li	s2,0
  if(!head){
    80001d7e:	e1a1                	bnez	a1,80001dbe <add_to_list+0x60>
      set_head(p, type, cpu_id);
    80001d80:	8636                	mv	a2,a3
    80001d82:	85d2                	mv	a1,s4
    80001d84:	00000097          	auipc	ra,0x0
    80001d88:	e68080e7          	jalr	-408(ra) # 80001bec <set_head>
      release_list(type, cpu_id);
    80001d8c:	85d6                	mv	a1,s5
    80001d8e:	8552                	mv	a0,s4
    80001d90:	00000097          	auipc	ra,0x0
    80001d94:	f4a080e7          	jalr	-182(ra) # 80001cda <release_list>
    80001d98:	a891                	j	80001dec <add_to_list+0x8e>
    panic("can't add null to list");
    80001d9a:	00006517          	auipc	a0,0x6
    80001d9e:	4be50513          	addi	a0,a0,1214 # 80008258 <digits+0x218>
    80001da2:	ffffe097          	auipc	ra,0xffffe
    80001da6:	79c080e7          	jalr	1948(ra) # 8000053e <panic>

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list(type, cpu_id);
    80001daa:	85d6                	mv	a1,s5
    80001dac:	8552                	mv	a0,s4
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	f2c080e7          	jalr	-212(ra) # 80001cda <release_list>
      }
      prev = head;
      head = head->next;
    80001db6:	68bc                	ld	a5,80(s1)
    while(head){
    80001db8:	8926                	mv	s2,s1
    80001dba:	c395                	beqz	a5,80001dde <add_to_list+0x80>
      head = head->next;
    80001dbc:	84be                	mv	s1,a5
      acquire(&head->list_lock);
    80001dbe:	01848993          	addi	s3,s1,24
    80001dc2:	854e                	mv	a0,s3
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	e20080e7          	jalr	-480(ra) # 80000be4 <acquire>
      if(prev){
    80001dcc:	fc090fe3          	beqz	s2,80001daa <add_to_list+0x4c>
        release(&prev->list_lock);
    80001dd0:	01890513          	addi	a0,s2,24
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	ec4080e7          	jalr	-316(ra) # 80000c98 <release>
    80001ddc:	bfe9                	j	80001db6 <add_to_list+0x58>
    }
    prev->next = p;
    80001dde:	0564b823          	sd	s6,80(s1)
    release(&prev->list_lock);
    80001de2:	854e                	mv	a0,s3
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	eb4080e7          	jalr	-332(ra) # 80000c98 <release>
  }
}
    80001dec:	70e2                	ld	ra,56(sp)
    80001dee:	7442                	ld	s0,48(sp)
    80001df0:	74a2                	ld	s1,40(sp)
    80001df2:	7902                	ld	s2,32(sp)
    80001df4:	69e2                	ld	s3,24(sp)
    80001df6:	6a42                	ld	s4,16(sp)
    80001df8:	6aa2                	ld	s5,8(sp)
    80001dfa:	6b02                	ld	s6,0(sp)
    80001dfc:	6121                	addi	sp,sp,64
    80001dfe:	8082                	ret

0000000080001e00 <add_proc_to_list>:


void 
add_proc_to_list(struct proc* p, int type, int cpu_id)
{
    80001e00:	7179                	addi	sp,sp,-48
    80001e02:	f406                	sd	ra,40(sp)
    80001e04:	f022                	sd	s0,32(sp)
    80001e06:	ec26                	sd	s1,24(sp)
    80001e08:	e84a                	sd	s2,16(sp)
    80001e0a:	e44e                	sd	s3,8(sp)
    80001e0c:	1800                	addi	s0,sp,48
  // bad argument
  if(!p){
    80001e0e:	cd1d                	beqz	a0,80001e4c <add_proc_to_list+0x4c>
    80001e10:	89aa                	mv	s3,a0
    80001e12:	84ae                	mv	s1,a1
    80001e14:	8932                	mv	s2,a2
    panic("Add proc to list");
  }
  struct proc* head;
  acquire_list(type, cpu_id);
    80001e16:	85b2                	mv	a1,a2
    80001e18:	8526                	mv	a0,s1
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	ce4080e7          	jalr	-796(ra) # 80001afe <acquire_list>
  head = get_head(type, cpu_id);
    80001e22:	85ca                	mv	a1,s2
    80001e24:	8526                	mv	a0,s1
    80001e26:	00000097          	auipc	ra,0x0
    80001e2a:	d60080e7          	jalr	-672(ra) # 80001b86 <get_head>
    80001e2e:	85aa                	mv	a1,a0
  add_to_list(p, head, type, cpu_id);
    80001e30:	86ca                	mv	a3,s2
    80001e32:	8626                	mv	a2,s1
    80001e34:	854e                	mv	a0,s3
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	f28080e7          	jalr	-216(ra) # 80001d5e <add_to_list>
}
    80001e3e:	70a2                	ld	ra,40(sp)
    80001e40:	7402                	ld	s0,32(sp)
    80001e42:	64e2                	ld	s1,24(sp)
    80001e44:	6942                	ld	s2,16(sp)
    80001e46:	69a2                	ld	s3,8(sp)
    80001e48:	6145                	addi	sp,sp,48
    80001e4a:	8082                	ret
    panic("Add proc to list");
    80001e4c:	00006517          	auipc	a0,0x6
    80001e50:	45450513          	addi	a0,a0,1108 # 800082a0 <digits+0x260>
    80001e54:	ffffe097          	auipc	ra,0xffffe
    80001e58:	6ea080e7          	jalr	1770(ra) # 8000053e <panic>

0000000080001e5c <remove_first>:



struct proc* 
remove_first(int type, int cpu_id)
{
    80001e5c:	7179                	addi	sp,sp,-48
    80001e5e:	f406                	sd	ra,40(sp)
    80001e60:	f022                	sd	s0,32(sp)
    80001e62:	ec26                	sd	s1,24(sp)
    80001e64:	e84a                	sd	s2,16(sp)
    80001e66:	e44e                	sd	s3,8(sp)
    80001e68:	e052                	sd	s4,0(sp)
    80001e6a:	1800                	addi	s0,sp,48
    80001e6c:	892a                	mv	s2,a0
    80001e6e:	89ae                	mv	s3,a1
  acquire_list(type, cpu_id);//acquire lock
    80001e70:	00000097          	auipc	ra,0x0
    80001e74:	c8e080e7          	jalr	-882(ra) # 80001afe <acquire_list>
  struct proc* head = get_head(type, cpu_id);//aquire list after we have loock 
    80001e78:	85ce                	mv	a1,s3
    80001e7a:	854a                	mv	a0,s2
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	d0a080e7          	jalr	-758(ra) # 80001b86 <get_head>
    80001e84:	84aa                	mv	s1,a0
  if(!head){
    80001e86:	c529                	beqz	a0,80001ed0 <remove_first+0x74>
    release_list(type, cpu_id);//realese loock 
  }
  else{
    acquire(&head->list_lock);
    80001e88:	01850a13          	addi	s4,a0,24
    80001e8c:	8552                	mv	a0,s4
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	d56080e7          	jalr	-682(ra) # 80000be4 <acquire>

    set_head(head->next, type, cpu_id);
    80001e96:	864e                	mv	a2,s3
    80001e98:	85ca                	mv	a1,s2
    80001e9a:	68a8                	ld	a0,80(s1)
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	d50080e7          	jalr	-688(ra) # 80001bec <set_head>
    head->next = 0;
    80001ea4:	0404b823          	sd	zero,80(s1)
    release(&head->list_lock);
    80001ea8:	8552                	mv	a0,s4
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	dee080e7          	jalr	-530(ra) # 80000c98 <release>

    release_list(type, cpu_id);//realese loock 
    80001eb2:	85ce                	mv	a1,s3
    80001eb4:	854a                	mv	a0,s2
    80001eb6:	00000097          	auipc	ra,0x0
    80001eba:	e24080e7          	jalr	-476(ra) # 80001cda <release_list>

  }
  return head;
}
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	70a2                	ld	ra,40(sp)
    80001ec2:	7402                	ld	s0,32(sp)
    80001ec4:	64e2                	ld	s1,24(sp)
    80001ec6:	6942                	ld	s2,16(sp)
    80001ec8:	69a2                	ld	s3,8(sp)
    80001eca:	6a02                	ld	s4,0(sp)
    80001ecc:	6145                	addi	sp,sp,48
    80001ece:	8082                	ret
    release_list(type, cpu_id);//realese loock 
    80001ed0:	85ce                	mv	a1,s3
    80001ed2:	854a                	mv	a0,s2
    80001ed4:	00000097          	auipc	ra,0x0
    80001ed8:	e06080e7          	jalr	-506(ra) # 80001cda <release_list>
    80001edc:	b7cd                	j	80001ebe <remove_first+0x62>

0000000080001ede <remove_proc>:

int
remove_proc(struct proc* p, int type){
    80001ede:	7179                	addi	sp,sp,-48
    80001ee0:	f406                	sd	ra,40(sp)
    80001ee2:	f022                	sd	s0,32(sp)
    80001ee4:	ec26                	sd	s1,24(sp)
    80001ee6:	e84a                	sd	s2,16(sp)
    80001ee8:	e44e                	sd	s3,8(sp)
    80001eea:	e052                	sd	s4,0(sp)
    80001eec:	1800                	addi	s0,sp,48
    80001eee:	8a2a                	mv	s4,a0
    80001ef0:	84ae                	mv	s1,a1
  acquire_list(type, p->parent_cpu);
    80001ef2:	4d2c                	lw	a1,88(a0)
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	00000097          	auipc	ra,0x0
    80001efa:	c08080e7          	jalr	-1016(ra) # 80001afe <acquire_list>
  struct proc* head = get_head(type, p->parent_cpu);
    80001efe:	058a2983          	lw	s3,88(s4) # fffffffffffff058 <end+0xffffffff7ffd9058>
    80001f02:	85ce                	mv	a1,s3
    80001f04:	8526                	mv	a0,s1
    80001f06:	00000097          	auipc	ra,0x0
    80001f0a:	c80080e7          	jalr	-896(ra) # 80001b86 <get_head>
  if(!head){
    80001f0e:	c521                	beqz	a0,80001f56 <remove_proc+0x78>
    80001f10:	892a                	mv	s2,a0
    release_list(type, p->parent_cpu);
    return 0;
  }
  else{
    struct proc* prev = 0;
    if(p == head){
    80001f12:	04aa0a63          	beq	s4,a0,80001f66 <remove_proc+0x88>
      release(&p->list_lock);
      release_list(type, p->parent_cpu);
    }
    else{
      while(head){
        acquire(&head->list_lock);
    80001f16:	0561                	addi	a0,a0,24
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	ccc080e7          	jalr	-820(ra) # 80000be4 <acquire>
          release(&prev->list_lock);
          return 1;
        }

        if(!prev)
          release_list(type,p->parent_cpu);
    80001f20:	058a2583          	lw	a1,88(s4)
    80001f24:	8526                	mv	a0,s1
    80001f26:	00000097          	auipc	ra,0x0
    80001f2a:	db4080e7          	jalr	-588(ra) # 80001cda <release_list>
          release(&prev->list_lock);
        }
          
        
        prev = head;
        head = head->next;
    80001f2e:	05093483          	ld	s1,80(s2)
      while(head){
    80001f32:	c0dd                	beqz	s1,80001fd8 <remove_proc+0xfa>
        acquire(&head->list_lock);
    80001f34:	01848993          	addi	s3,s1,24
    80001f38:	854e                	mv	a0,s3
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	caa080e7          	jalr	-854(ra) # 80000be4 <acquire>
        if(p == head){
    80001f42:	069a0263          	beq	s4,s1,80001fa6 <remove_proc+0xc8>
          release(&prev->list_lock);
    80001f46:	01890513          	addi	a0,s2,24
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	d4e080e7          	jalr	-690(ra) # 80000c98 <release>
        head = head->next;
    80001f52:	8926                	mv	s2,s1
    80001f54:	bfe9                	j	80001f2e <remove_proc+0x50>
    release_list(type, p->parent_cpu);
    80001f56:	85ce                	mv	a1,s3
    80001f58:	8526                	mv	a0,s1
    80001f5a:	00000097          	auipc	ra,0x0
    80001f5e:	d80080e7          	jalr	-640(ra) # 80001cda <release_list>
    return 0;
    80001f62:	4501                	li	a0,0
    80001f64:	a095                	j	80001fc8 <remove_proc+0xea>
      acquire(&p->list_lock);
    80001f66:	01850993          	addi	s3,a0,24
    80001f6a:	854e                	mv	a0,s3
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	c78080e7          	jalr	-904(ra) # 80000be4 <acquire>
      set_head(p->next, type, p->parent_cpu);
    80001f74:	05892603          	lw	a2,88(s2)
    80001f78:	85a6                	mv	a1,s1
    80001f7a:	05093503          	ld	a0,80(s2)
    80001f7e:	00000097          	auipc	ra,0x0
    80001f82:	c6e080e7          	jalr	-914(ra) # 80001bec <set_head>
      p->next = 0;
    80001f86:	04093823          	sd	zero,80(s2)
      release(&p->list_lock);
    80001f8a:	854e                	mv	a0,s3
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	d0c080e7          	jalr	-756(ra) # 80000c98 <release>
      release_list(type, p->parent_cpu);
    80001f94:	05892583          	lw	a1,88(s2)
    80001f98:	8526                	mv	a0,s1
    80001f9a:	00000097          	auipc	ra,0x0
    80001f9e:	d40080e7          	jalr	-704(ra) # 80001cda <release_list>
      }
    }
    return 0;
    80001fa2:	4501                	li	a0,0
    80001fa4:	a015                	j	80001fc8 <remove_proc+0xea>
          prev->next = head->next;
    80001fa6:	68bc                	ld	a5,80(s1)
    80001fa8:	04f93823          	sd	a5,80(s2)
          p->next = 0;
    80001fac:	0404b823          	sd	zero,80(s1)
          release(&head->list_lock);
    80001fb0:	854e                	mv	a0,s3
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	ce6080e7          	jalr	-794(ra) # 80000c98 <release>
          release(&prev->list_lock);
    80001fba:	01890513          	addi	a0,s2,24
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	cda080e7          	jalr	-806(ra) # 80000c98 <release>
          return 1;
    80001fc6:	4505                	li	a0,1
  }
}
    80001fc8:	70a2                	ld	ra,40(sp)
    80001fca:	7402                	ld	s0,32(sp)
    80001fcc:	64e2                	ld	s1,24(sp)
    80001fce:	6942                	ld	s2,16(sp)
    80001fd0:	69a2                	ld	s3,8(sp)
    80001fd2:	6a02                	ld	s4,0(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    return 0;
    80001fd8:	4501                	li	a0,0
    80001fda:	b7fd                	j	80001fc8 <remove_proc+0xea>

0000000080001fdc <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001fdc:	7139                	addi	sp,sp,-64
    80001fde:	fc06                	sd	ra,56(sp)
    80001fe0:	f822                	sd	s0,48(sp)
    80001fe2:	f426                	sd	s1,40(sp)
    80001fe4:	f04a                	sd	s2,32(sp)
    80001fe6:	ec4e                	sd	s3,24(sp)
    80001fe8:	e852                	sd	s4,16(sp)
    80001fea:	e456                	sd	s5,8(sp)
    80001fec:	e05a                	sd	s6,0(sp)
    80001fee:	0080                	addi	s0,sp,64
    80001ff0:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ff2:	0000f497          	auipc	s1,0xf
    80001ff6:	5c648493          	addi	s1,s1,1478 # 800115b8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001ffa:	8b26                	mv	s6,s1
    80001ffc:	00006a97          	auipc	s5,0x6
    80002000:	004a8a93          	addi	s5,s5,4 # 80008000 <etext>
    80002004:	04000937          	lui	s2,0x4000
    80002008:	197d                	addi	s2,s2,-1
    8000200a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000200c:	00016a17          	auipc	s4,0x16
    80002010:	9aca0a13          	addi	s4,s4,-1620 # 800179b8 <tickslock>
    char *pa = kalloc();
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	ae0080e7          	jalr	-1312(ra) # 80000af4 <kalloc>
    8000201c:	862a                	mv	a2,a0
    if(pa == 0)
    8000201e:	c131                	beqz	a0,80002062 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80002020:	416485b3          	sub	a1,s1,s6
    80002024:	8591                	srai	a1,a1,0x4
    80002026:	000ab783          	ld	a5,0(s5)
    8000202a:	02f585b3          	mul	a1,a1,a5
    8000202e:	2585                	addiw	a1,a1,1
    80002030:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80002034:	4719                	li	a4,6
    80002036:	6685                	lui	a3,0x1
    80002038:	40b905b3          	sub	a1,s2,a1
    8000203c:	854e                	mv	a0,s3
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	112080e7          	jalr	274(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002046:	19048493          	addi	s1,s1,400
    8000204a:	fd4495e3          	bne	s1,s4,80002014 <proc_mapstacks+0x38>
  }
}
    8000204e:	70e2                	ld	ra,56(sp)
    80002050:	7442                	ld	s0,48(sp)
    80002052:	74a2                	ld	s1,40(sp)
    80002054:	7902                	ld	s2,32(sp)
    80002056:	69e2                	ld	s3,24(sp)
    80002058:	6a42                	ld	s4,16(sp)
    8000205a:	6aa2                	ld	s5,8(sp)
    8000205c:	6b02                	ld	s6,0(sp)
    8000205e:	6121                	addi	sp,sp,64
    80002060:	8082                	ret
      panic("kalloc");
    80002062:	00006517          	auipc	a0,0x6
    80002066:	25650513          	addi	a0,a0,598 # 800082b8 <digits+0x278>
    8000206a:	ffffe097          	auipc	ra,0xffffe
    8000206e:	4d4080e7          	jalr	1236(ra) # 8000053e <panic>

0000000080002072 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80002072:	715d                	addi	sp,sp,-80
    80002074:	e486                	sd	ra,72(sp)
    80002076:	e0a2                	sd	s0,64(sp)
    80002078:	fc26                	sd	s1,56(sp)
    8000207a:	f84a                	sd	s2,48(sp)
    8000207c:	f44e                	sd	s3,40(sp)
    8000207e:	f052                	sd	s4,32(sp)
    80002080:	ec56                	sd	s5,24(sp)
    80002082:	e85a                	sd	s6,16(sp)
    80002084:	e45e                	sd	s7,8(sp)
    80002086:	e062                	sd	s8,0(sp)
    80002088:	0880                	addi	s0,sp,80
  struct proc *p;
  //----------------------------------------------------------
  if(CPUS > NCPU){
    panic("recieved more CPUS than what is allowed");
  }
  initlock(&pid_lock, "nextpid");
    8000208a:	00006597          	auipc	a1,0x6
    8000208e:	23658593          	addi	a1,a1,566 # 800082c0 <digits+0x280>
    80002092:	0000f517          	auipc	a0,0xf
    80002096:	4f650513          	addi	a0,a0,1270 # 80011588 <pid_lock>
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	aba080e7          	jalr	-1350(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    800020a2:	00006597          	auipc	a1,0x6
    800020a6:	22658593          	addi	a1,a1,550 # 800082c8 <digits+0x288>
    800020aa:	0000f517          	auipc	a0,0xf
    800020ae:	4f650513          	addi	a0,a0,1270 # 800115a0 <wait_lock>
    800020b2:	fffff097          	auipc	ra,0xfffff
    800020b6:	aa2080e7          	jalr	-1374(ra) # 80000b54 <initlock>
  initlock(&zombie_lock, "zombie lock");
    800020ba:	00006597          	auipc	a1,0x6
    800020be:	21e58593          	addi	a1,a1,542 # 800082d8 <digits+0x298>
    800020c2:	0000f517          	auipc	a0,0xf
    800020c6:	47e50513          	addi	a0,a0,1150 # 80011540 <zombie_lock>
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	a8a080e7          	jalr	-1398(ra) # 80000b54 <initlock>
  initlock(&sleeping_lock, "sleeping lock");
    800020d2:	00006597          	auipc	a1,0x6
    800020d6:	21658593          	addi	a1,a1,534 # 800082e8 <digits+0x2a8>
    800020da:	0000f517          	auipc	a0,0xf
    800020de:	47e50513          	addi	a0,a0,1150 # 80011558 <sleeping_lock>
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	a72080e7          	jalr	-1422(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused lock");
    800020ea:	00006597          	auipc	a1,0x6
    800020ee:	20e58593          	addi	a1,a1,526 # 800082f8 <digits+0x2b8>
    800020f2:	0000f517          	auipc	a0,0xf
    800020f6:	47e50513          	addi	a0,a0,1150 # 80011570 <unused_lock>
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	a5a080e7          	jalr	-1446(ra) # 80000b54 <initlock>

  struct spinlock* s;
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    80002102:	0000f497          	auipc	s1,0xf
    80002106:	3f648493          	addi	s1,s1,1014 # 800114f8 <ready_lock>
    initlock(s, "ready lock");
    8000210a:	00006997          	auipc	s3,0x6
    8000210e:	1fe98993          	addi	s3,s3,510 # 80008308 <digits+0x2c8>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    80002112:	0000f917          	auipc	s2,0xf
    80002116:	42e90913          	addi	s2,s2,1070 # 80011540 <zombie_lock>
    initlock(s, "ready lock");
    8000211a:	85ce                	mv	a1,s3
    8000211c:	8526                	mv	a0,s1
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	a36080e7          	jalr	-1482(ra) # 80000b54 <initlock>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    80002126:	04e1                	addi	s1,s1,24
    80002128:	ff2499e3          	bne	s1,s2,8000211a <procinit+0xa8>
  }
  //--------------------------------------------------
  for(p = proc; p < &proc[NPROC]; p++) {
    8000212c:	0000f497          	auipc	s1,0xf
    80002130:	48c48493          	addi	s1,s1,1164 # 800115b8 <proc>
      initlock(&p->lock, "proc");
    80002134:	00006c17          	auipc	s8,0x6
    80002138:	1e4c0c13          	addi	s8,s8,484 # 80008318 <digits+0x2d8>
      //--------------------------------------------------
      initlock(&p->list_lock, "list lock");
    8000213c:	00006b97          	auipc	s7,0x6
    80002140:	1e4b8b93          	addi	s7,s7,484 # 80008320 <digits+0x2e0>
      //--------------------------------------------------
      p->kstack = KSTACK((int) (p - proc));
    80002144:	8b26                	mv	s6,s1
    80002146:	00006a97          	auipc	s5,0x6
    8000214a:	ebaa8a93          	addi	s5,s5,-326 # 80008000 <etext>
    8000214e:	04000937          	lui	s2,0x4000
    80002152:	197d                	addi	s2,s2,-1
    80002154:	0932                	slli	s2,s2,0xc
      //--------------------------------------------------
       p->parent_cpu = -1;
    80002156:	5a7d                	li	s4,-1
  for(p = proc; p < &proc[NPROC]; p++) {
    80002158:	00016997          	auipc	s3,0x16
    8000215c:	86098993          	addi	s3,s3,-1952 # 800179b8 <tickslock>
      initlock(&p->lock, "proc");
    80002160:	85e2                	mv	a1,s8
    80002162:	8526                	mv	a0,s1
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	9f0080e7          	jalr	-1552(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list lock");
    8000216c:	85de                	mv	a1,s7
    8000216e:	01848513          	addi	a0,s1,24
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	9e2080e7          	jalr	-1566(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000217a:	416487b3          	sub	a5,s1,s6
    8000217e:	8791                	srai	a5,a5,0x4
    80002180:	000ab703          	ld	a4,0(s5)
    80002184:	02e787b3          	mul	a5,a5,a4
    80002188:	2785                	addiw	a5,a5,1
    8000218a:	00d7979b          	slliw	a5,a5,0xd
    8000218e:	40f907b3          	sub	a5,s2,a5
    80002192:	f4bc                	sd	a5,104(s1)
       p->parent_cpu = -1;
    80002194:	0544ac23          	sw	s4,88(s1)
       add_proc_to_list(p, UNUSEDL, -1);
    80002198:	567d                	li	a2,-1
    8000219a:	458d                	li	a1,3
    8000219c:	8526                	mv	a0,s1
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	c62080e7          	jalr	-926(ra) # 80001e00 <add_proc_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a6:	19048493          	addi	s1,s1,400
    800021aa:	fb349be3          	bne	s1,s3,80002160 <procinit+0xee>
      
      //--------------------------------------------------
  }
}
    800021ae:	60a6                	ld	ra,72(sp)
    800021b0:	6406                	ld	s0,64(sp)
    800021b2:	74e2                	ld	s1,56(sp)
    800021b4:	7942                	ld	s2,48(sp)
    800021b6:	79a2                	ld	s3,40(sp)
    800021b8:	7a02                	ld	s4,32(sp)
    800021ba:	6ae2                	ld	s5,24(sp)
    800021bc:	6b42                	ld	s6,16(sp)
    800021be:	6ba2                	ld	s7,8(sp)
    800021c0:	6c02                	ld	s8,0(sp)
    800021c2:	6161                	addi	sp,sp,80
    800021c4:	8082                	ret

00000000800021c6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800021c6:	1141                	addi	sp,sp,-16
    800021c8:	e422                	sd	s0,8(sp)
    800021ca:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800021cc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800021ce:	2501                	sext.w	a0,a0
    800021d0:	6422                	ld	s0,8(sp)
    800021d2:	0141                	addi	sp,sp,16
    800021d4:	8082                	ret

00000000800021d6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800021d6:	1141                	addi	sp,sp,-16
    800021d8:	e422                	sd	s0,8(sp)
    800021da:	0800                	addi	s0,sp,16
    800021dc:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800021de:	0007851b          	sext.w	a0,a5
    800021e2:	00451793          	slli	a5,a0,0x4
    800021e6:	97aa                	add	a5,a5,a0
    800021e8:	078e                	slli	a5,a5,0x3
  return c;
}
    800021ea:	0000f517          	auipc	a0,0xf
    800021ee:	17650513          	addi	a0,a0,374 # 80011360 <cpus>
    800021f2:	953e                	add	a0,a0,a5
    800021f4:	6422                	ld	s0,8(sp)
    800021f6:	0141                	addi	sp,sp,16
    800021f8:	8082                	ret

00000000800021fa <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800021fa:	1101                	addi	sp,sp,-32
    800021fc:	ec06                	sd	ra,24(sp)
    800021fe:	e822                	sd	s0,16(sp)
    80002200:	e426                	sd	s1,8(sp)
    80002202:	1000                	addi	s0,sp,32
  push_off();
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	994080e7          	jalr	-1644(ra) # 80000b98 <push_off>
    8000220c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000220e:	0007871b          	sext.w	a4,a5
    80002212:	00471793          	slli	a5,a4,0x4
    80002216:	97ba                	add	a5,a5,a4
    80002218:	078e                	slli	a5,a5,0x3
    8000221a:	0000f717          	auipc	a4,0xf
    8000221e:	0b670713          	addi	a4,a4,182 # 800112d0 <readyLock>
    80002222:	97ba                	add	a5,a5,a4
    80002224:	6bc4                	ld	s1,144(a5)
  pop_off();
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a12080e7          	jalr	-1518(ra) # 80000c38 <pop_off>
  return p;
}
    8000222e:	8526                	mv	a0,s1
    80002230:	60e2                	ld	ra,24(sp)
    80002232:	6442                	ld	s0,16(sp)
    80002234:	64a2                	ld	s1,8(sp)
    80002236:	6105                	addi	sp,sp,32
    80002238:	8082                	ret

000000008000223a <get_cpu>:
{
    8000223a:	1141                	addi	sp,sp,-16
    8000223c:	e406                	sd	ra,8(sp)
    8000223e:	e022                	sd	s0,0(sp)
    80002240:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    80002242:	00000097          	auipc	ra,0x0
    80002246:	fb8080e7          	jalr	-72(ra) # 800021fa <myproc>
}
    8000224a:	4d28                	lw	a0,88(a0)
    8000224c:	60a2                	ld	ra,8(sp)
    8000224e:	6402                	ld	s0,0(sp)
    80002250:	0141                	addi	sp,sp,16
    80002252:	8082                	ret

0000000080002254 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80002254:	1141                	addi	sp,sp,-16
    80002256:	e406                	sd	ra,8(sp)
    80002258:	e022                	sd	s0,0(sp)
    8000225a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	f9e080e7          	jalr	-98(ra) # 800021fa <myproc>
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a34080e7          	jalr	-1484(ra) # 80000c98 <release>

  if (first) {
    8000226c:	00006797          	auipc	a5,0x6
    80002270:	7147a783          	lw	a5,1812(a5) # 80008980 <first.1843>
    80002274:	eb89                	bnez	a5,80002286 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80002276:	00001097          	auipc	ra,0x1
    8000227a:	ec6080e7          	jalr	-314(ra) # 8000313c <usertrapret>
}
    8000227e:	60a2                	ld	ra,8(sp)
    80002280:	6402                	ld	s0,0(sp)
    80002282:	0141                	addi	sp,sp,16
    80002284:	8082                	ret
    first = 0;
    80002286:	00006797          	auipc	a5,0x6
    8000228a:	6e07ad23          	sw	zero,1786(a5) # 80008980 <first.1843>
    fsinit(ROOTDEV);
    8000228e:	4505                	li	a0,1
    80002290:	00002097          	auipc	ra,0x2
    80002294:	c38080e7          	jalr	-968(ra) # 80003ec8 <fsinit>
    80002298:	bff9                	j	80002276 <forkret+0x22>

000000008000229a <allocpid>:
allocpid() {
    8000229a:	1101                	addi	sp,sp,-32
    8000229c:	ec06                	sd	ra,24(sp)
    8000229e:	e822                	sd	s0,16(sp)
    800022a0:	e426                	sd	s1,8(sp)
    800022a2:	e04a                	sd	s2,0(sp)
    800022a4:	1000                	addi	s0,sp,32
    pid = nextpid;
    800022a6:	00006917          	auipc	s2,0x6
    800022aa:	6de90913          	addi	s2,s2,1758 # 80008984 <nextpid>
    800022ae:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid, pid, pid + 1));
    800022b2:	0014861b          	addiw	a2,s1,1
    800022b6:	85a6                	mv	a1,s1
    800022b8:	854a                	mv	a0,s2
    800022ba:	00005097          	auipc	ra,0x5
    800022be:	a1c080e7          	jalr	-1508(ra) # 80006cd6 <cas>
    800022c2:	f575                	bnez	a0,800022ae <allocpid+0x14>
}
    800022c4:	8526                	mv	a0,s1
    800022c6:	60e2                	ld	ra,24(sp)
    800022c8:	6442                	ld	s0,16(sp)
    800022ca:	64a2                	ld	s1,8(sp)
    800022cc:	6902                	ld	s2,0(sp)
    800022ce:	6105                	addi	sp,sp,32
    800022d0:	8082                	ret

00000000800022d2 <proc_pagetable>:
{
    800022d2:	1101                	addi	sp,sp,-32
    800022d4:	ec06                	sd	ra,24(sp)
    800022d6:	e822                	sd	s0,16(sp)
    800022d8:	e426                	sd	s1,8(sp)
    800022da:	e04a                	sd	s2,0(sp)
    800022dc:	1000                	addi	s0,sp,32
    800022de:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	05a080e7          	jalr	90(ra) # 8000133a <uvmcreate>
    800022e8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800022ea:	c121                	beqz	a0,8000232a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800022ec:	4729                	li	a4,10
    800022ee:	00005697          	auipc	a3,0x5
    800022f2:	d1268693          	addi	a3,a3,-750 # 80007000 <_trampoline>
    800022f6:	6605                	lui	a2,0x1
    800022f8:	040005b7          	lui	a1,0x4000
    800022fc:	15fd                	addi	a1,a1,-1
    800022fe:	05b2                	slli	a1,a1,0xc
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	db0080e7          	jalr	-592(ra) # 800010b0 <mappages>
    80002308:	02054863          	bltz	a0,80002338 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    8000230c:	4719                	li	a4,6
    8000230e:	08093683          	ld	a3,128(s2)
    80002312:	6605                	lui	a2,0x1
    80002314:	020005b7          	lui	a1,0x2000
    80002318:	15fd                	addi	a1,a1,-1
    8000231a:	05b6                	slli	a1,a1,0xd
    8000231c:	8526                	mv	a0,s1
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	d92080e7          	jalr	-622(ra) # 800010b0 <mappages>
    80002326:	02054163          	bltz	a0,80002348 <proc_pagetable+0x76>
}
    8000232a:	8526                	mv	a0,s1
    8000232c:	60e2                	ld	ra,24(sp)
    8000232e:	6442                	ld	s0,16(sp)
    80002330:	64a2                	ld	s1,8(sp)
    80002332:	6902                	ld	s2,0(sp)
    80002334:	6105                	addi	sp,sp,32
    80002336:	8082                	ret
    uvmfree(pagetable, 0);
    80002338:	4581                	li	a1,0
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	1fa080e7          	jalr	506(ra) # 80001536 <uvmfree>
    return 0;
    80002344:	4481                	li	s1,0
    80002346:	b7d5                	j	8000232a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002348:	4681                	li	a3,0
    8000234a:	4605                	li	a2,1
    8000234c:	040005b7          	lui	a1,0x4000
    80002350:	15fd                	addi	a1,a1,-1
    80002352:	05b2                	slli	a1,a1,0xc
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	f20080e7          	jalr	-224(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    8000235e:	4581                	li	a1,0
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	1d4080e7          	jalr	468(ra) # 80001536 <uvmfree>
    return 0;
    8000236a:	4481                	li	s1,0
    8000236c:	bf7d                	j	8000232a <proc_pagetable+0x58>

000000008000236e <proc_freepagetable>:
{
    8000236e:	1101                	addi	sp,sp,-32
    80002370:	ec06                	sd	ra,24(sp)
    80002372:	e822                	sd	s0,16(sp)
    80002374:	e426                	sd	s1,8(sp)
    80002376:	e04a                	sd	s2,0(sp)
    80002378:	1000                	addi	s0,sp,32
    8000237a:	84aa                	mv	s1,a0
    8000237c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000237e:	4681                	li	a3,0
    80002380:	4605                	li	a2,1
    80002382:	040005b7          	lui	a1,0x4000
    80002386:	15fd                	addi	a1,a1,-1
    80002388:	05b2                	slli	a1,a1,0xc
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	eec080e7          	jalr	-276(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002392:	4681                	li	a3,0
    80002394:	4605                	li	a2,1
    80002396:	020005b7          	lui	a1,0x2000
    8000239a:	15fd                	addi	a1,a1,-1
    8000239c:	05b6                	slli	a1,a1,0xd
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	ed6080e7          	jalr	-298(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    800023a8:	85ca                	mv	a1,s2
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	18a080e7          	jalr	394(ra) # 80001536 <uvmfree>
}
    800023b4:	60e2                	ld	ra,24(sp)
    800023b6:	6442                	ld	s0,16(sp)
    800023b8:	64a2                	ld	s1,8(sp)
    800023ba:	6902                	ld	s2,0(sp)
    800023bc:	6105                	addi	sp,sp,32
    800023be:	8082                	ret

00000000800023c0 <freeproc>:
{
    800023c0:	1101                	addi	sp,sp,-32
    800023c2:	ec06                	sd	ra,24(sp)
    800023c4:	e822                	sd	s0,16(sp)
    800023c6:	e426                	sd	s1,8(sp)
    800023c8:	1000                	addi	s0,sp,32
    800023ca:	84aa                	mv	s1,a0
  if(p->trapframe)
    800023cc:	6148                	ld	a0,128(a0)
    800023ce:	c509                	beqz	a0,800023d8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    800023d0:	ffffe097          	auipc	ra,0xffffe
    800023d4:	628080e7          	jalr	1576(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    800023d8:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    800023dc:	7ca8                	ld	a0,120(s1)
    800023de:	c511                	beqz	a0,800023ea <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800023e0:	78ac                	ld	a1,112(s1)
    800023e2:	00000097          	auipc	ra,0x0
    800023e6:	f8c080e7          	jalr	-116(ra) # 8000236e <proc_freepagetable>
  p->pagetable = 0;
    800023ea:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    800023ee:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    800023f2:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    800023f6:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    800023fa:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    800023fe:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    80002402:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80002406:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    8000240a:	0204a823          	sw	zero,48(s1)
  remove_proc(p, ZOMBIEL);
    8000240e:	4585                	li	a1,1
    80002410:	8526                	mv	a0,s1
    80002412:	00000097          	auipc	ra,0x0
    80002416:	acc080e7          	jalr	-1332(ra) # 80001ede <remove_proc>
  add_proc_to_list(p, UNUSEDL, -1);
    8000241a:	567d                	li	a2,-1
    8000241c:	458d                	li	a1,3
    8000241e:	8526                	mv	a0,s1
    80002420:	00000097          	auipc	ra,0x0
    80002424:	9e0080e7          	jalr	-1568(ra) # 80001e00 <add_proc_to_list>
}
    80002428:	60e2                	ld	ra,24(sp)
    8000242a:	6442                	ld	s0,16(sp)
    8000242c:	64a2                	ld	s1,8(sp)
    8000242e:	6105                	addi	sp,sp,32
    80002430:	8082                	ret

0000000080002432 <allocproc>:
{
    80002432:	7179                	addi	sp,sp,-48
    80002434:	f406                	sd	ra,40(sp)
    80002436:	f022                	sd	s0,32(sp)
    80002438:	ec26                	sd	s1,24(sp)
    8000243a:	e84a                	sd	s2,16(sp)
    8000243c:	e44e                	sd	s3,8(sp)
    8000243e:	1800                	addi	s0,sp,48
  p = remove_first(UNUSEDL, -1);
    80002440:	55fd                	li	a1,-1
    80002442:	450d                	li	a0,3
    80002444:	00000097          	auipc	ra,0x0
    80002448:	a18080e7          	jalr	-1512(ra) # 80001e5c <remove_first>
    8000244c:	84aa                	mv	s1,a0
  if(!p){
    8000244e:	cd39                	beqz	a0,800024ac <allocproc+0x7a>
  acquire(&p->lock);
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	794080e7          	jalr	1940(ra) # 80000be4 <acquire>
  p->pid = allocpid();
    80002458:	00000097          	auipc	ra,0x0
    8000245c:	e42080e7          	jalr	-446(ra) # 8000229a <allocpid>
    80002460:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80002462:	4785                	li	a5,1
    80002464:	d89c                	sw	a5,48(s1)
  p->next = 0;
    80002466:	0404b823          	sd	zero,80(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000246a:	ffffe097          	auipc	ra,0xffffe
    8000246e:	68a080e7          	jalr	1674(ra) # 80000af4 <kalloc>
    80002472:	892a                	mv	s2,a0
    80002474:	e0c8                	sd	a0,128(s1)
    80002476:	c139                	beqz	a0,800024bc <allocproc+0x8a>
  p->pagetable = proc_pagetable(p);
    80002478:	8526                	mv	a0,s1
    8000247a:	00000097          	auipc	ra,0x0
    8000247e:	e58080e7          	jalr	-424(ra) # 800022d2 <proc_pagetable>
    80002482:	892a                	mv	s2,a0
    80002484:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    80002486:	c539                	beqz	a0,800024d4 <allocproc+0xa2>
  memset(&p->context, 0, sizeof(p->context));
    80002488:	07000613          	li	a2,112
    8000248c:	4581                	li	a1,0
    8000248e:	08848513          	addi	a0,s1,136
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	84e080e7          	jalr	-1970(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000249a:	00000797          	auipc	a5,0x0
    8000249e:	dba78793          	addi	a5,a5,-582 # 80002254 <forkret>
    800024a2:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    800024a4:	74bc                	ld	a5,104(s1)
    800024a6:	6705                	lui	a4,0x1
    800024a8:	97ba                	add	a5,a5,a4
    800024aa:	e8dc                	sd	a5,144(s1)
}
    800024ac:	8526                	mv	a0,s1
    800024ae:	70a2                	ld	ra,40(sp)
    800024b0:	7402                	ld	s0,32(sp)
    800024b2:	64e2                	ld	s1,24(sp)
    800024b4:	6942                	ld	s2,16(sp)
    800024b6:	69a2                	ld	s3,8(sp)
    800024b8:	6145                	addi	sp,sp,48
    800024ba:	8082                	ret
    freeproc(p);
    800024bc:	8526                	mv	a0,s1
    800024be:	00000097          	auipc	ra,0x0
    800024c2:	f02080e7          	jalr	-254(ra) # 800023c0 <freeproc>
    release(&p->lock);
    800024c6:	8526                	mv	a0,s1
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7d0080e7          	jalr	2000(ra) # 80000c98 <release>
    return 0;
    800024d0:	84ca                	mv	s1,s2
    800024d2:	bfe9                	j	800024ac <allocproc+0x7a>
    freeproc(p);
    800024d4:	8526                	mv	a0,s1
    800024d6:	00000097          	auipc	ra,0x0
    800024da:	eea080e7          	jalr	-278(ra) # 800023c0 <freeproc>
    release(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7b8080e7          	jalr	1976(ra) # 80000c98 <release>
    return 0;
    800024e8:	84ca                	mv	s1,s2
    800024ea:	b7c9                	j	800024ac <allocproc+0x7a>

00000000800024ec <userinit>:
{
    800024ec:	1101                	addi	sp,sp,-32
    800024ee:	ec06                	sd	ra,24(sp)
    800024f0:	e822                	sd	s0,16(sp)
    800024f2:	e426                	sd	s1,8(sp)
    800024f4:	1000                	addi	s0,sp,32
  if(!init){
    800024f6:	00007797          	auipc	a5,0x7
    800024fa:	b4a7a783          	lw	a5,-1206(a5) # 80009040 <init>
    800024fe:	e385                	bnez	a5,8000251e <userinit+0x32>
      c->first = 0;
    80002500:	0000f797          	auipc	a5,0xf
    80002504:	dd078793          	addi	a5,a5,-560 # 800112d0 <readyLock>
    80002508:	1007b823          	sd	zero,272(a5)
    8000250c:	1807bc23          	sd	zero,408(a5)
    80002510:	2207b023          	sd	zero,544(a5)
    init = 1;
    80002514:	4785                	li	a5,1
    80002516:	00007717          	auipc	a4,0x7
    8000251a:	b2f72523          	sw	a5,-1238(a4) # 80009040 <init>
  p = allocproc();
    8000251e:	00000097          	auipc	ra,0x0
    80002522:	f14080e7          	jalr	-236(ra) # 80002432 <allocproc>
    80002526:	84aa                	mv	s1,a0
  initproc = p;
    80002528:	00007797          	auipc	a5,0x7
    8000252c:	b2a7bc23          	sd	a0,-1224(a5) # 80009060 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002530:	03400613          	li	a2,52
    80002534:	00006597          	auipc	a1,0x6
    80002538:	45c58593          	addi	a1,a1,1116 # 80008990 <initcode>
    8000253c:	7d28                	ld	a0,120(a0)
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	e2a080e7          	jalr	-470(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002546:	6785                	lui	a5,0x1
    80002548:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    8000254a:	60d8                	ld	a4,128(s1)
    8000254c:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002550:	60d8                	ld	a4,128(s1)
    80002552:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002554:	4641                	li	a2,16
    80002556:	00006597          	auipc	a1,0x6
    8000255a:	dda58593          	addi	a1,a1,-550 # 80008330 <digits+0x2f0>
    8000255e:	18048513          	addi	a0,s1,384
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	8d0080e7          	jalr	-1840(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    8000256a:	00006517          	auipc	a0,0x6
    8000256e:	dd650513          	addi	a0,a0,-554 # 80008340 <digits+0x300>
    80002572:	00002097          	auipc	ra,0x2
    80002576:	384080e7          	jalr	900(ra) # 800048f6 <namei>
    8000257a:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    8000257e:	478d                	li	a5,3
    80002580:	d89c                	sw	a5,48(s1)
  p->parent_cpu = 0;
    80002582:	0404ac23          	sw	zero,88(s1)
  cpus[p->parent_cpu].first = p;
    80002586:	0000f797          	auipc	a5,0xf
    8000258a:	e497bd23          	sd	s1,-422(a5) # 800113e0 <cpus+0x80>
  release(&p->lock);
    8000258e:	8526                	mv	a0,s1
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	708080e7          	jalr	1800(ra) # 80000c98 <release>
}
    80002598:	60e2                	ld	ra,24(sp)
    8000259a:	6442                	ld	s0,16(sp)
    8000259c:	64a2                	ld	s1,8(sp)
    8000259e:	6105                	addi	sp,sp,32
    800025a0:	8082                	ret

00000000800025a2 <growproc>:
{
    800025a2:	1101                	addi	sp,sp,-32
    800025a4:	ec06                	sd	ra,24(sp)
    800025a6:	e822                	sd	s0,16(sp)
    800025a8:	e426                	sd	s1,8(sp)
    800025aa:	e04a                	sd	s2,0(sp)
    800025ac:	1000                	addi	s0,sp,32
    800025ae:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800025b0:	00000097          	auipc	ra,0x0
    800025b4:	c4a080e7          	jalr	-950(ra) # 800021fa <myproc>
    800025b8:	892a                	mv	s2,a0
  sz = p->sz;
    800025ba:	792c                	ld	a1,112(a0)
    800025bc:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800025c0:	00904f63          	bgtz	s1,800025de <growproc+0x3c>
  } else if(n < 0){
    800025c4:	0204cc63          	bltz	s1,800025fc <growproc+0x5a>
  p->sz = sz;
    800025c8:	1602                	slli	a2,a2,0x20
    800025ca:	9201                	srli	a2,a2,0x20
    800025cc:	06c93823          	sd	a2,112(s2)
  return 0;
    800025d0:	4501                	li	a0,0
}
    800025d2:	60e2                	ld	ra,24(sp)
    800025d4:	6442                	ld	s0,16(sp)
    800025d6:	64a2                	ld	s1,8(sp)
    800025d8:	6902                	ld	s2,0(sp)
    800025da:	6105                	addi	sp,sp,32
    800025dc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800025de:	9e25                	addw	a2,a2,s1
    800025e0:	1602                	slli	a2,a2,0x20
    800025e2:	9201                	srli	a2,a2,0x20
    800025e4:	1582                	slli	a1,a1,0x20
    800025e6:	9181                	srli	a1,a1,0x20
    800025e8:	7d28                	ld	a0,120(a0)
    800025ea:	fffff097          	auipc	ra,0xfffff
    800025ee:	e38080e7          	jalr	-456(ra) # 80001422 <uvmalloc>
    800025f2:	0005061b          	sext.w	a2,a0
    800025f6:	fa69                	bnez	a2,800025c8 <growproc+0x26>
      return -1;
    800025f8:	557d                	li	a0,-1
    800025fa:	bfe1                	j	800025d2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800025fc:	9e25                	addw	a2,a2,s1
    800025fe:	1602                	slli	a2,a2,0x20
    80002600:	9201                	srli	a2,a2,0x20
    80002602:	1582                	slli	a1,a1,0x20
    80002604:	9181                	srli	a1,a1,0x20
    80002606:	7d28                	ld	a0,120(a0)
    80002608:	fffff097          	auipc	ra,0xfffff
    8000260c:	dd2080e7          	jalr	-558(ra) # 800013da <uvmdealloc>
    80002610:	0005061b          	sext.w	a2,a0
    80002614:	bf55                	j	800025c8 <growproc+0x26>

0000000080002616 <fork>:
{
    80002616:	7179                	addi	sp,sp,-48
    80002618:	f406                	sd	ra,40(sp)
    8000261a:	f022                	sd	s0,32(sp)
    8000261c:	ec26                	sd	s1,24(sp)
    8000261e:	e84a                	sd	s2,16(sp)
    80002620:	e44e                	sd	s3,8(sp)
    80002622:	e052                	sd	s4,0(sp)
    80002624:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002626:	00000097          	auipc	ra,0x0
    8000262a:	bd4080e7          	jalr	-1068(ra) # 800021fa <myproc>
    8000262e:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002630:	00000097          	auipc	ra,0x0
    80002634:	e02080e7          	jalr	-510(ra) # 80002432 <allocproc>
    80002638:	12050563          	beqz	a0,80002762 <fork+0x14c>
    8000263c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000263e:	07093603          	ld	a2,112(s2)
    80002642:	7d2c                	ld	a1,120(a0)
    80002644:	07893503          	ld	a0,120(s2)
    80002648:	fffff097          	auipc	ra,0xfffff
    8000264c:	f26080e7          	jalr	-218(ra) # 8000156e <uvmcopy>
    80002650:	04054663          	bltz	a0,8000269c <fork+0x86>
  np->sz = p->sz;
    80002654:	07093783          	ld	a5,112(s2)
    80002658:	06f9b823          	sd	a5,112(s3)
  *(np->trapframe) = *(p->trapframe);
    8000265c:	08093683          	ld	a3,128(s2)
    80002660:	87b6                	mv	a5,a3
    80002662:	0809b703          	ld	a4,128(s3)
    80002666:	12068693          	addi	a3,a3,288
    8000266a:	0007b803          	ld	a6,0(a5)
    8000266e:	6788                	ld	a0,8(a5)
    80002670:	6b8c                	ld	a1,16(a5)
    80002672:	6f90                	ld	a2,24(a5)
    80002674:	01073023          	sd	a6,0(a4)
    80002678:	e708                	sd	a0,8(a4)
    8000267a:	eb0c                	sd	a1,16(a4)
    8000267c:	ef10                	sd	a2,24(a4)
    8000267e:	02078793          	addi	a5,a5,32
    80002682:	02070713          	addi	a4,a4,32
    80002686:	fed792e3          	bne	a5,a3,8000266a <fork+0x54>
  np->trapframe->a0 = 0;
    8000268a:	0809b783          	ld	a5,128(s3)
    8000268e:	0607b823          	sd	zero,112(a5)
    80002692:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80002696:	17800a13          	li	s4,376
    8000269a:	a03d                	j	800026c8 <fork+0xb2>
    freeproc(np);
    8000269c:	854e                	mv	a0,s3
    8000269e:	00000097          	auipc	ra,0x0
    800026a2:	d22080e7          	jalr	-734(ra) # 800023c0 <freeproc>
    release(&np->lock);
    800026a6:	854e                	mv	a0,s3
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	5f0080e7          	jalr	1520(ra) # 80000c98 <release>
    return -1;
    800026b0:	5a7d                	li	s4,-1
    800026b2:	a879                	j	80002750 <fork+0x13a>
      np->ofile[i] = filedup(p->ofile[i]);
    800026b4:	00003097          	auipc	ra,0x3
    800026b8:	8d8080e7          	jalr	-1832(ra) # 80004f8c <filedup>
    800026bc:	009987b3          	add	a5,s3,s1
    800026c0:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800026c2:	04a1                	addi	s1,s1,8
    800026c4:	01448763          	beq	s1,s4,800026d2 <fork+0xbc>
    if(p->ofile[i])
    800026c8:	009907b3          	add	a5,s2,s1
    800026cc:	6388                	ld	a0,0(a5)
    800026ce:	f17d                	bnez	a0,800026b4 <fork+0x9e>
    800026d0:	bfcd                	j	800026c2 <fork+0xac>
  np->cwd = idup(p->cwd);
    800026d2:	17893503          	ld	a0,376(s2)
    800026d6:	00002097          	auipc	ra,0x2
    800026da:	a2c080e7          	jalr	-1492(ra) # 80004102 <idup>
    800026de:	16a9bc23          	sd	a0,376(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800026e2:	4641                	li	a2,16
    800026e4:	18090593          	addi	a1,s2,384
    800026e8:	18098513          	addi	a0,s3,384
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	746080e7          	jalr	1862(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800026f4:	0489aa03          	lw	s4,72(s3)
  release(&np->lock);
    800026f8:	854e                	mv	a0,s3
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	59e080e7          	jalr	1438(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002702:	0000f497          	auipc	s1,0xf
    80002706:	e9e48493          	addi	s1,s1,-354 # 800115a0 <wait_lock>
    8000270a:	8526                	mv	a0,s1
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	4d8080e7          	jalr	1240(ra) # 80000be4 <acquire>
  np->parent = p;
    80002714:	0729b023          	sd	s2,96(s3)
  release(&wait_lock);
    80002718:	8526                	mv	a0,s1
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	57e080e7          	jalr	1406(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002722:	854e                	mv	a0,s3
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	4c0080e7          	jalr	1216(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    8000272c:	478d                	li	a5,3
    8000272e:	02f9a823          	sw	a5,48(s3)
  int parent_cpu =  p->parent_cpu;
    80002732:	05892603          	lw	a2,88(s2)
  np->parent_cpu = parent_cpu;
    80002736:	04c9ac23          	sw	a2,88(s3)
  add_proc_to_list(np, READYL, parent_cpu);
    8000273a:	4581                	li	a1,0
    8000273c:	854e                	mv	a0,s3
    8000273e:	fffff097          	auipc	ra,0xfffff
    80002742:	6c2080e7          	jalr	1730(ra) # 80001e00 <add_proc_to_list>
  release(&np->lock);
    80002746:	854e                	mv	a0,s3
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	550080e7          	jalr	1360(ra) # 80000c98 <release>
}
    80002750:	8552                	mv	a0,s4
    80002752:	70a2                	ld	ra,40(sp)
    80002754:	7402                	ld	s0,32(sp)
    80002756:	64e2                	ld	s1,24(sp)
    80002758:	6942                	ld	s2,16(sp)
    8000275a:	69a2                	ld	s3,8(sp)
    8000275c:	6a02                	ld	s4,0(sp)
    8000275e:	6145                	addi	sp,sp,48
    80002760:	8082                	ret
    return -1;
    80002762:	5a7d                	li	s4,-1
    80002764:	b7f5                	j	80002750 <fork+0x13a>

0000000080002766 <blncflag_on>:
{
    80002766:	7139                	addi	sp,sp,-64
    80002768:	fc06                	sd	ra,56(sp)
    8000276a:	f822                	sd	s0,48(sp)
    8000276c:	f426                	sd	s1,40(sp)
    8000276e:	f04a                	sd	s2,32(sp)
    80002770:	ec4e                	sd	s3,24(sp)
    80002772:	e852                	sd	s4,16(sp)
    80002774:	e456                	sd	s5,8(sp)
    80002776:	e05a                	sd	s6,0(sp)
    80002778:	0080                	addi	s0,sp,64
    8000277a:	8792                	mv	a5,tp
  int id = r_tp();
    8000277c:	2781                	sext.w	a5,a5
    8000277e:	8a12                	mv	s4,tp
    80002780:	2a01                	sext.w	s4,s4
  c->proc = 0;
    80002782:	00479993          	slli	s3,a5,0x4
    80002786:	00f98733          	add	a4,s3,a5
    8000278a:	00371693          	slli	a3,a4,0x3
    8000278e:	0000f717          	auipc	a4,0xf
    80002792:	b4270713          	addi	a4,a4,-1214 # 800112d0 <readyLock>
    80002796:	9736                	add	a4,a4,a3
    80002798:	08073823          	sd	zero,144(a4)
        swtch(&c->context, &p->context);
    8000279c:	0000f717          	auipc	a4,0xf
    800027a0:	bcc70713          	addi	a4,a4,-1076 # 80011368 <cpus+0x8>
    800027a4:	00e689b3          	add	s3,a3,a4
      if(p->state != RUNNABLE)
    800027a8:	4a8d                	li	s5,3
        p->state = RUNNING;
    800027aa:	4b11                	li	s6,4
        c->proc = p;
    800027ac:	0000f917          	auipc	s2,0xf
    800027b0:	b2490913          	addi	s2,s2,-1244 # 800112d0 <readyLock>
    800027b4:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027b6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027ba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027be:	10079073          	csrw	sstatus,a5
    p = remove_first(READYL, cpu_id);
    800027c2:	85d2                	mv	a1,s4
    800027c4:	4501                	li	a0,0
    800027c6:	fffff097          	auipc	ra,0xfffff
    800027ca:	696080e7          	jalr	1686(ra) # 80001e5c <remove_first>
    800027ce:	84aa                	mv	s1,a0
    if(!p){ // no proces ready 
    800027d0:	d17d                	beqz	a0,800027b6 <blncflag_on+0x50>
      acquire(&p->lock);
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	412080e7          	jalr	1042(ra) # 80000be4 <acquire>
      if(p->state != RUNNABLE)
    800027da:	589c                	lw	a5,48(s1)
    800027dc:	03579563          	bne	a5,s5,80002806 <blncflag_on+0xa0>
        p->state = RUNNING;
    800027e0:	0364a823          	sw	s6,48(s1)
        c->proc = p;
    800027e4:	08993823          	sd	s1,144(s2)
        swtch(&c->context, &p->context);
    800027e8:	08848593          	addi	a1,s1,136
    800027ec:	854e                	mv	a0,s3
    800027ee:	00001097          	auipc	ra,0x1
    800027f2:	8a4080e7          	jalr	-1884(ra) # 80003092 <swtch>
        c->proc = 0;
    800027f6:	08093823          	sd	zero,144(s2)
      release(&p->lock);
    800027fa:	8526                	mv	a0,s1
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	49c080e7          	jalr	1180(ra) # 80000c98 <release>
    80002804:	bf4d                	j	800027b6 <blncflag_on+0x50>
        panic("bad proc was selected");
    80002806:	00006517          	auipc	a0,0x6
    8000280a:	b4250513          	addi	a0,a0,-1214 # 80008348 <digits+0x308>
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>

0000000080002816 <scheduler>:
{
    80002816:	1141                	addi	sp,sp,-16
    80002818:	e406                	sd	ra,8(sp)
    8000281a:	e022                	sd	s0,0(sp)
    8000281c:	0800                	addi	s0,sp,16
      if(!print_flag){
    8000281e:	00007797          	auipc	a5,0x7
    80002822:	84a7a783          	lw	a5,-1974(a5) # 80009068 <print_flag>
    80002826:	c789                	beqz	a5,80002830 <scheduler+0x1a>
    blncflag_on();
    80002828:	00000097          	auipc	ra,0x0
    8000282c:	f3e080e7          	jalr	-194(ra) # 80002766 <blncflag_on>
      print_flag++;
    80002830:	4785                	li	a5,1
    80002832:	00007717          	auipc	a4,0x7
    80002836:	82f72b23          	sw	a5,-1994(a4) # 80009068 <print_flag>
      printf("BLNCFLG=ON\n");
    8000283a:	00006517          	auipc	a0,0x6
    8000283e:	b2650513          	addi	a0,a0,-1242 # 80008360 <digits+0x320>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	d46080e7          	jalr	-698(ra) # 80000588 <printf>
    8000284a:	bff9                	j	80002828 <scheduler+0x12>

000000008000284c <blncflag_off>:
{
    8000284c:	7139                	addi	sp,sp,-64
    8000284e:	fc06                	sd	ra,56(sp)
    80002850:	f822                	sd	s0,48(sp)
    80002852:	f426                	sd	s1,40(sp)
    80002854:	f04a                	sd	s2,32(sp)
    80002856:	ec4e                	sd	s3,24(sp)
    80002858:	e852                	sd	s4,16(sp)
    8000285a:	e456                	sd	s5,8(sp)
    8000285c:	e05a                	sd	s6,0(sp)
    8000285e:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80002860:	8792                	mv	a5,tp
  int id = r_tp();
    80002862:	2781                	sext.w	a5,a5
    80002864:	8a12                	mv	s4,tp
    80002866:	2a01                	sext.w	s4,s4
  c->proc = 0;
    80002868:	00479993          	slli	s3,a5,0x4
    8000286c:	00f98733          	add	a4,s3,a5
    80002870:	00371693          	slli	a3,a4,0x3
    80002874:	0000f717          	auipc	a4,0xf
    80002878:	a5c70713          	addi	a4,a4,-1444 # 800112d0 <readyLock>
    8000287c:	9736                	add	a4,a4,a3
    8000287e:	08073823          	sd	zero,144(a4)
        swtch(&c->context, &p->context);
    80002882:	0000f717          	auipc	a4,0xf
    80002886:	ae670713          	addi	a4,a4,-1306 # 80011368 <cpus+0x8>
    8000288a:	00e689b3          	add	s3,a3,a4
      if(p->state != RUNNABLE)
    8000288e:	4a8d                	li	s5,3
        p->state = RUNNING;
    80002890:	4b11                	li	s6,4
        c->proc = p;
    80002892:	0000f917          	auipc	s2,0xf
    80002896:	a3e90913          	addi	s2,s2,-1474 # 800112d0 <readyLock>
    8000289a:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028a0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a4:	10079073          	csrw	sstatus,a5
    p = remove_first(READYL, cpu_id);
    800028a8:	85d2                	mv	a1,s4
    800028aa:	4501                	li	a0,0
    800028ac:	fffff097          	auipc	ra,0xfffff
    800028b0:	5b0080e7          	jalr	1456(ra) # 80001e5c <remove_first>
    800028b4:	84aa                	mv	s1,a0
    if(!p){ // no proces ready 
    800028b6:	d17d                	beqz	a0,8000289c <blncflag_off+0x50>
      acquire(&p->lock);
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	32c080e7          	jalr	812(ra) # 80000be4 <acquire>
      if(p->state != RUNNABLE)
    800028c0:	589c                	lw	a5,48(s1)
    800028c2:	03579563          	bne	a5,s5,800028ec <blncflag_off+0xa0>
        p->state = RUNNING;
    800028c6:	0364a823          	sw	s6,48(s1)
        c->proc = p;
    800028ca:	08993823          	sd	s1,144(s2)
        swtch(&c->context, &p->context);
    800028ce:	08848593          	addi	a1,s1,136
    800028d2:	854e                	mv	a0,s3
    800028d4:	00000097          	auipc	ra,0x0
    800028d8:	7be080e7          	jalr	1982(ra) # 80003092 <swtch>
        c->proc = 0;
    800028dc:	08093823          	sd	zero,144(s2)
      release(&p->lock);
    800028e0:	8526                	mv	a0,s1
    800028e2:	ffffe097          	auipc	ra,0xffffe
    800028e6:	3b6080e7          	jalr	950(ra) # 80000c98 <release>
    800028ea:	bf4d                	j	8000289c <blncflag_off+0x50>
        panic("bad proc was selected");
    800028ec:	00006517          	auipc	a0,0x6
    800028f0:	a5c50513          	addi	a0,a0,-1444 # 80008348 <digits+0x308>
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	c4a080e7          	jalr	-950(ra) # 8000053e <panic>

00000000800028fc <sched>:
{
    800028fc:	7179                	addi	sp,sp,-48
    800028fe:	f406                	sd	ra,40(sp)
    80002900:	f022                	sd	s0,32(sp)
    80002902:	ec26                	sd	s1,24(sp)
    80002904:	e84a                	sd	s2,16(sp)
    80002906:	e44e                	sd	s3,8(sp)
    80002908:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	8f0080e7          	jalr	-1808(ra) # 800021fa <myproc>
    80002912:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	256080e7          	jalr	598(ra) # 80000b6a <holding>
    8000291c:	c959                	beqz	a0,800029b2 <sched+0xb6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000291e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002920:	0007871b          	sext.w	a4,a5
    80002924:	00471793          	slli	a5,a4,0x4
    80002928:	97ba                	add	a5,a5,a4
    8000292a:	078e                	slli	a5,a5,0x3
    8000292c:	0000f717          	auipc	a4,0xf
    80002930:	9a470713          	addi	a4,a4,-1628 # 800112d0 <readyLock>
    80002934:	97ba                	add	a5,a5,a4
    80002936:	1087a703          	lw	a4,264(a5)
    8000293a:	4785                	li	a5,1
    8000293c:	08f71363          	bne	a4,a5,800029c2 <sched+0xc6>
  if(p->state == RUNNING)
    80002940:	5898                	lw	a4,48(s1)
    80002942:	4791                	li	a5,4
    80002944:	08f70763          	beq	a4,a5,800029d2 <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002948:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000294c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000294e:	ebd1                	bnez	a5,800029e2 <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002950:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002952:	0000f917          	auipc	s2,0xf
    80002956:	97e90913          	addi	s2,s2,-1666 # 800112d0 <readyLock>
    8000295a:	0007871b          	sext.w	a4,a5
    8000295e:	00471793          	slli	a5,a4,0x4
    80002962:	97ba                	add	a5,a5,a4
    80002964:	078e                	slli	a5,a5,0x3
    80002966:	97ca                	add	a5,a5,s2
    80002968:	10c7a983          	lw	s3,268(a5)
    8000296c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000296e:	0007859b          	sext.w	a1,a5
    80002972:	00459793          	slli	a5,a1,0x4
    80002976:	97ae                	add	a5,a5,a1
    80002978:	078e                	slli	a5,a5,0x3
    8000297a:	0000f597          	auipc	a1,0xf
    8000297e:	9ee58593          	addi	a1,a1,-1554 # 80011368 <cpus+0x8>
    80002982:	95be                	add	a1,a1,a5
    80002984:	08848513          	addi	a0,s1,136
    80002988:	00000097          	auipc	ra,0x0
    8000298c:	70a080e7          	jalr	1802(ra) # 80003092 <swtch>
    80002990:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002992:	0007871b          	sext.w	a4,a5
    80002996:	00471793          	slli	a5,a4,0x4
    8000299a:	97ba                	add	a5,a5,a4
    8000299c:	078e                	slli	a5,a5,0x3
    8000299e:	97ca                	add	a5,a5,s2
    800029a0:	1137a623          	sw	s3,268(a5)
}
    800029a4:	70a2                	ld	ra,40(sp)
    800029a6:	7402                	ld	s0,32(sp)
    800029a8:	64e2                	ld	s1,24(sp)
    800029aa:	6942                	ld	s2,16(sp)
    800029ac:	69a2                	ld	s3,8(sp)
    800029ae:	6145                	addi	sp,sp,48
    800029b0:	8082                	ret
    panic("sched p->lock");
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	9be50513          	addi	a0,a0,-1602 # 80008370 <digits+0x330>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	b84080e7          	jalr	-1148(ra) # 8000053e <panic>
    panic("sched locks");
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	9be50513          	addi	a0,a0,-1602 # 80008380 <digits+0x340>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	b74080e7          	jalr	-1164(ra) # 8000053e <panic>
    panic("sched running");
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	9be50513          	addi	a0,a0,-1602 # 80008390 <digits+0x350>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	b64080e7          	jalr	-1180(ra) # 8000053e <panic>
    panic("sched interruptible");
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	9be50513          	addi	a0,a0,-1602 # 800083a0 <digits+0x360>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	b54080e7          	jalr	-1196(ra) # 8000053e <panic>

00000000800029f2 <yield>:
{
    800029f2:	1101                	addi	sp,sp,-32
    800029f4:	ec06                	sd	ra,24(sp)
    800029f6:	e822                	sd	s0,16(sp)
    800029f8:	e426                	sd	s1,8(sp)
    800029fa:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800029fc:	fffff097          	auipc	ra,0xfffff
    80002a00:	7fe080e7          	jalr	2046(ra) # 800021fa <myproc>
    80002a04:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	1de080e7          	jalr	478(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002a0e:	478d                	li	a5,3
    80002a10:	d89c                	sw	a5,48(s1)
  add_proc_to_list(p, READYL, p->parent_cpu);
    80002a12:	4cb0                	lw	a2,88(s1)
    80002a14:	4581                	li	a1,0
    80002a16:	8526                	mv	a0,s1
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	3e8080e7          	jalr	1000(ra) # 80001e00 <add_proc_to_list>
  sched();
    80002a20:	00000097          	auipc	ra,0x0
    80002a24:	edc080e7          	jalr	-292(ra) # 800028fc <sched>
  release(&p->lock);
    80002a28:	8526                	mv	a0,s1
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	26e080e7          	jalr	622(ra) # 80000c98 <release>
}
    80002a32:	60e2                	ld	ra,24(sp)
    80002a34:	6442                	ld	s0,16(sp)
    80002a36:	64a2                	ld	s1,8(sp)
    80002a38:	6105                	addi	sp,sp,32
    80002a3a:	8082                	ret

0000000080002a3c <set_cpu>:
  if(cpu_num<0 || cpu_num>NCPU){
    80002a3c:	47a1                	li	a5,8
    80002a3e:	02a7e763          	bltu	a5,a0,80002a6c <set_cpu+0x30>
{
    80002a42:	1101                	addi	sp,sp,-32
    80002a44:	ec06                	sd	ra,24(sp)
    80002a46:	e822                	sd	s0,16(sp)
    80002a48:	e426                	sd	s1,8(sp)
    80002a4a:	1000                	addi	s0,sp,32
    80002a4c:	84aa                	mv	s1,a0
  struct proc* p = myproc();
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	7ac080e7          	jalr	1964(ra) # 800021fa <myproc>
  p->parent_cpu=cpu_num;
    80002a56:	cd24                	sw	s1,88(a0)
  yield();
    80002a58:	00000097          	auipc	ra,0x0
    80002a5c:	f9a080e7          	jalr	-102(ra) # 800029f2 <yield>
  return cpu_num;
    80002a60:	8526                	mv	a0,s1
}
    80002a62:	60e2                	ld	ra,24(sp)
    80002a64:	6442                	ld	s0,16(sp)
    80002a66:	64a2                	ld	s1,8(sp)
    80002a68:	6105                	addi	sp,sp,32
    80002a6a:	8082                	ret
    return -1;
    80002a6c:	557d                	li	a0,-1
}
    80002a6e:	8082                	ret

0000000080002a70 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002a70:	7179                	addi	sp,sp,-48
    80002a72:	f406                	sd	ra,40(sp)
    80002a74:	f022                	sd	s0,32(sp)
    80002a76:	ec26                	sd	s1,24(sp)
    80002a78:	e84a                	sd	s2,16(sp)
    80002a7a:	e44e                	sd	s3,8(sp)
    80002a7c:	1800                	addi	s0,sp,48
    80002a7e:	89aa                	mv	s3,a0
    80002a80:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a82:	fffff097          	auipc	ra,0xfffff
    80002a86:	778080e7          	jalr	1912(ra) # 800021fa <myproc>
    80002a8a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	158080e7          	jalr	344(ra) # 80000be4 <acquire>
  release(lk);
    80002a94:	854a                	mv	a0,s2
    80002a96:	ffffe097          	auipc	ra,0xffffe
    80002a9a:	202080e7          	jalr	514(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002a9e:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    80002aa2:	4789                	li	a5,2
    80002aa4:	d89c                	sw	a5,48(s1)
  //--------------------------------------------------------------------
    add_proc_to_list(p, SLEEPINGL,-1);
    80002aa6:	567d                	li	a2,-1
    80002aa8:	4589                	li	a1,2
    80002aaa:	8526                	mv	a0,s1
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	354080e7          	jalr	852(ra) # 80001e00 <add_proc_to_list>
  //--------------------------------------------------------------------

  sched();
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	e48080e7          	jalr	-440(ra) # 800028fc <sched>

  // Tidy up.
  p->chan = 0;
    80002abc:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002ac0:	8526                	mv	a0,s1
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	1d6080e7          	jalr	470(ra) # 80000c98 <release>
  acquire(lk);
    80002aca:	854a                	mv	a0,s2
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	118080e7          	jalr	280(ra) # 80000be4 <acquire>

}
    80002ad4:	70a2                	ld	ra,40(sp)
    80002ad6:	7402                	ld	s0,32(sp)
    80002ad8:	64e2                	ld	s1,24(sp)
    80002ada:	6942                	ld	s2,16(sp)
    80002adc:	69a2                	ld	s3,8(sp)
    80002ade:	6145                	addi	sp,sp,48
    80002ae0:	8082                	ret

0000000080002ae2 <wait>:
{
    80002ae2:	715d                	addi	sp,sp,-80
    80002ae4:	e486                	sd	ra,72(sp)
    80002ae6:	e0a2                	sd	s0,64(sp)
    80002ae8:	fc26                	sd	s1,56(sp)
    80002aea:	f84a                	sd	s2,48(sp)
    80002aec:	f44e                	sd	s3,40(sp)
    80002aee:	f052                	sd	s4,32(sp)
    80002af0:	ec56                	sd	s5,24(sp)
    80002af2:	e85a                	sd	s6,16(sp)
    80002af4:	e45e                	sd	s7,8(sp)
    80002af6:	e062                	sd	s8,0(sp)
    80002af8:	0880                	addi	s0,sp,80
    80002afa:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	6fe080e7          	jalr	1790(ra) # 800021fa <myproc>
    80002b04:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002b06:	0000f517          	auipc	a0,0xf
    80002b0a:	a9a50513          	addi	a0,a0,-1382 # 800115a0 <wait_lock>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	0d6080e7          	jalr	214(ra) # 80000be4 <acquire>
    havekids = 0;
    80002b16:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002b18:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002b1a:	00015997          	auipc	s3,0x15
    80002b1e:	e9e98993          	addi	s3,s3,-354 # 800179b8 <tickslock>
        havekids = 1;
    80002b22:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b24:	0000fc17          	auipc	s8,0xf
    80002b28:	a7cc0c13          	addi	s8,s8,-1412 # 800115a0 <wait_lock>
    havekids = 0;
    80002b2c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002b2e:	0000f497          	auipc	s1,0xf
    80002b32:	a8a48493          	addi	s1,s1,-1398 # 800115b8 <proc>
    80002b36:	a0bd                	j	80002ba4 <wait+0xc2>
          pid = np->pid;
    80002b38:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002b3c:	000b0e63          	beqz	s6,80002b58 <wait+0x76>
    80002b40:	4691                	li	a3,4
    80002b42:	04448613          	addi	a2,s1,68
    80002b46:	85da                	mv	a1,s6
    80002b48:	07893503          	ld	a0,120(s2)
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	b26080e7          	jalr	-1242(ra) # 80001672 <copyout>
    80002b54:	02054563          	bltz	a0,80002b7e <wait+0x9c>
          freeproc(np);
    80002b58:	8526                	mv	a0,s1
    80002b5a:	00000097          	auipc	ra,0x0
    80002b5e:	866080e7          	jalr	-1946(ra) # 800023c0 <freeproc>
          release(&np->lock);
    80002b62:	8526                	mv	a0,s1
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	134080e7          	jalr	308(ra) # 80000c98 <release>
          release(&wait_lock);
    80002b6c:	0000f517          	auipc	a0,0xf
    80002b70:	a3450513          	addi	a0,a0,-1484 # 800115a0 <wait_lock>
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	124080e7          	jalr	292(ra) # 80000c98 <release>
          return pid;
    80002b7c:	a09d                	j	80002be2 <wait+0x100>
            release(&np->lock);
    80002b7e:	8526                	mv	a0,s1
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	118080e7          	jalr	280(ra) # 80000c98 <release>
            release(&wait_lock);
    80002b88:	0000f517          	auipc	a0,0xf
    80002b8c:	a1850513          	addi	a0,a0,-1512 # 800115a0 <wait_lock>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	108080e7          	jalr	264(ra) # 80000c98 <release>
            return -1;
    80002b98:	59fd                	li	s3,-1
    80002b9a:	a0a1                	j	80002be2 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002b9c:	19048493          	addi	s1,s1,400
    80002ba0:	03348463          	beq	s1,s3,80002bc8 <wait+0xe6>
      if(np->parent == p){
    80002ba4:	70bc                	ld	a5,96(s1)
    80002ba6:	ff279be3          	bne	a5,s2,80002b9c <wait+0xba>
        acquire(&np->lock);
    80002baa:	8526                	mv	a0,s1
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	038080e7          	jalr	56(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002bb4:	589c                	lw	a5,48(s1)
    80002bb6:	f94781e3          	beq	a5,s4,80002b38 <wait+0x56>
        release(&np->lock);
    80002bba:	8526                	mv	a0,s1
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	0dc080e7          	jalr	220(ra) # 80000c98 <release>
        havekids = 1;
    80002bc4:	8756                	mv	a4,s5
    80002bc6:	bfd9                	j	80002b9c <wait+0xba>
    if(!havekids || p->killed){
    80002bc8:	c701                	beqz	a4,80002bd0 <wait+0xee>
    80002bca:	04092783          	lw	a5,64(s2)
    80002bce:	c79d                	beqz	a5,80002bfc <wait+0x11a>
      release(&wait_lock);
    80002bd0:	0000f517          	auipc	a0,0xf
    80002bd4:	9d050513          	addi	a0,a0,-1584 # 800115a0 <wait_lock>
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	0c0080e7          	jalr	192(ra) # 80000c98 <release>
      return -1;
    80002be0:	59fd                	li	s3,-1
}
    80002be2:	854e                	mv	a0,s3
    80002be4:	60a6                	ld	ra,72(sp)
    80002be6:	6406                	ld	s0,64(sp)
    80002be8:	74e2                	ld	s1,56(sp)
    80002bea:	7942                	ld	s2,48(sp)
    80002bec:	79a2                	ld	s3,40(sp)
    80002bee:	7a02                	ld	s4,32(sp)
    80002bf0:	6ae2                	ld	s5,24(sp)
    80002bf2:	6b42                	ld	s6,16(sp)
    80002bf4:	6ba2                	ld	s7,8(sp)
    80002bf6:	6c02                	ld	s8,0(sp)
    80002bf8:	6161                	addi	sp,sp,80
    80002bfa:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002bfc:	85e2                	mv	a1,s8
    80002bfe:	854a                	mv	a0,s2
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	e70080e7          	jalr	-400(ra) # 80002a70 <sleep>
    havekids = 0;
    80002c08:	b715                	j	80002b2c <wait+0x4a>

0000000080002c0a <wakeup>:
// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
//--------------------------------------------------------------------
void
wakeup(void *chan)
{
    80002c0a:	711d                	addi	sp,sp,-96
    80002c0c:	ec86                	sd	ra,88(sp)
    80002c0e:	e8a2                	sd	s0,80(sp)
    80002c10:	e4a6                	sd	s1,72(sp)
    80002c12:	e0ca                	sd	s2,64(sp)
    80002c14:	fc4e                	sd	s3,56(sp)
    80002c16:	f852                	sd	s4,48(sp)
    80002c18:	f456                	sd	s5,40(sp)
    80002c1a:	f05a                	sd	s6,32(sp)
    80002c1c:	ec5e                	sd	s7,24(sp)
    80002c1e:	e862                	sd	s8,16(sp)
    80002c20:	e466                	sd	s9,8(sp)
    80002c22:	1080                	addi	s0,sp,96
    80002c24:	8aaa                	mv	s5,a0
  int released_list = 0;
  struct proc *p;
  struct proc* prev = 0;
  struct proc* tmp;
  acquire_list(SLEEPINGL, -1);
    80002c26:	55fd                	li	a1,-1
    80002c28:	4509                	li	a0,2
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	ed4080e7          	jalr	-300(ra) # 80001afe <acquire_list>
  p = get_head(SLEEPINGL, -1);
    80002c32:	55fd                	li	a1,-1
    80002c34:	4509                	li	a0,2
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	f50080e7          	jalr	-176(ra) # 80001b86 <get_head>
    80002c3e:	84aa                	mv	s1,a0
  while(p){
    80002c40:	10050f63          	beqz	a0,80002d5e <wakeup+0x154>
  struct proc* prev = 0;
    80002c44:	4a01                	li	s4,0
  int released_list = 0;
    80002c46:	4b01                	li	s6,0
    } 
    else{
      //we are not on the chan
      if(p == get_head(SLEEPINGL, -1)){
        release_list(SLEEPINGL,-1);
        released_list = 1;
    80002c48:	4c05                	li	s8,1
        p->state = RUNNABLE;
    80002c4a:	4b8d                	li	s7,3
    80002c4c:	a05d                	j	80002cf2 <wakeup+0xe8>
      if(p == get_head(SLEEPINGL, -1)){
    80002c4e:	55fd                	li	a1,-1
    80002c50:	4509                	li	a0,2
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	f34080e7          	jalr	-204(ra) # 80001b86 <get_head>
    80002c5a:	02a48d63          	beq	s1,a0,80002c94 <wakeup+0x8a>
        prev->next = p->next;
    80002c5e:	68bc                	ld	a5,80(s1)
    80002c60:	04fa3823          	sd	a5,80(s4)
        p->next = 0;
    80002c64:	0404b823          	sd	zero,80(s1)
        p->state = RUNNABLE;
    80002c68:	0374a823          	sw	s7,48(s1)
        add_proc_to_list(p, READYL, cpu_id);
    80002c6c:	4cb0                	lw	a2,88(s1)
    80002c6e:	4581                	li	a1,0
    80002c70:	8526                	mv	a0,s1
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	18e080e7          	jalr	398(ra) # 80001e00 <add_proc_to_list>
        release(&p->list_lock);
    80002c7a:	854a                	mv	a0,s2
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	01c080e7          	jalr	28(ra) # 80000c98 <release>
        release(&p->lock);
    80002c84:	8526                	mv	a0,s1
    80002c86:	ffffe097          	auipc	ra,0xffffe
    80002c8a:	012080e7          	jalr	18(ra) # 80000c98 <release>
        p = prev->next;
    80002c8e:	050a3483          	ld	s1,80(s4)
    80002c92:	a8b9                	j	80002cf0 <wakeup+0xe6>
        set_head(p->next, SLEEPINGL, -1);
    80002c94:	567d                	li	a2,-1
    80002c96:	4589                	li	a1,2
    80002c98:	68a8                	ld	a0,80(s1)
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	f52080e7          	jalr	-174(ra) # 80001bec <set_head>
        p = p->next;
    80002ca2:	0504bc83          	ld	s9,80(s1)
        tmp->next = 0;
    80002ca6:	0404b823          	sd	zero,80(s1)
        tmp->state = RUNNABLE;
    80002caa:	0374a823          	sw	s7,48(s1)
        add_proc_to_list(tmp, READYL, cpu_id);
    80002cae:	4cb0                	lw	a2,88(s1)
    80002cb0:	4581                	li	a1,0
    80002cb2:	8526                	mv	a0,s1
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	14c080e7          	jalr	332(ra) # 80001e00 <add_proc_to_list>
        release(&tmp->list_lock);
    80002cbc:	854a                	mv	a0,s2
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	fda080e7          	jalr	-38(ra) # 80000c98 <release>
        release(&tmp->lock);
    80002cc6:	8526                	mv	a0,s1
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	fd0080e7          	jalr	-48(ra) # 80000c98 <release>
        p = p->next;
    80002cd0:	84e6                	mv	s1,s9
    80002cd2:	a839                	j	80002cf0 <wakeup+0xe6>
        release_list(SLEEPINGL,-1);
    80002cd4:	55fd                	li	a1,-1
    80002cd6:	4509                	li	a0,2
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	002080e7          	jalr	2(ra) # 80001cda <release_list>
        released_list = 1;
    80002ce0:	8b62                	mv	s6,s8
      }
      else{
        release(&prev->list_lock);
      }
      release(&p->lock);  //because we dont need to change his fields
    80002ce2:	854e                	mv	a0,s3
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	fb4080e7          	jalr	-76(ra) # 80000c98 <release>
      prev = p;
      p = p->next;
    80002cec:	8a26                	mv	s4,s1
    80002cee:	68a4                	ld	s1,80(s1)
  while(p){
    80002cf0:	c0a1                	beqz	s1,80002d30 <wakeup+0x126>
    acquire(&p->lock);
    80002cf2:	89a6                	mv	s3,s1
    80002cf4:	8526                	mv	a0,s1
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	eee080e7          	jalr	-274(ra) # 80000be4 <acquire>
    acquire(&p->list_lock);
    80002cfe:	01848913          	addi	s2,s1,24
    80002d02:	854a                	mv	a0,s2
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	ee0080e7          	jalr	-288(ra) # 80000be4 <acquire>
    if(p->chan == chan){
    80002d0c:	7c9c                	ld	a5,56(s1)
    80002d0e:	f55780e3          	beq	a5,s5,80002c4e <wakeup+0x44>
      if(p == get_head(SLEEPINGL, -1)){
    80002d12:	55fd                	li	a1,-1
    80002d14:	4509                	li	a0,2
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	e70080e7          	jalr	-400(ra) # 80001b86 <get_head>
    80002d1e:	faa48be3          	beq	s1,a0,80002cd4 <wakeup+0xca>
        release(&prev->list_lock);
    80002d22:	018a0513          	addi	a0,s4,24
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	f72080e7          	jalr	-142(ra) # 80000c98 <release>
    80002d2e:	bf55                	j	80002ce2 <wakeup+0xd8>
    }
  }
  if(!released_list){
    80002d30:	020b0863          	beqz	s6,80002d60 <wakeup+0x156>
    release_list(SLEEPINGL, -1);
  }
  if(prev){
    80002d34:	000a0863          	beqz	s4,80002d44 <wakeup+0x13a>
    release(&prev->list_lock);
    80002d38:	018a0513          	addi	a0,s4,24
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	f5c080e7          	jalr	-164(ra) # 80000c98 <release>
  }
}
    80002d44:	60e6                	ld	ra,88(sp)
    80002d46:	6446                	ld	s0,80(sp)
    80002d48:	64a6                	ld	s1,72(sp)
    80002d4a:	6906                	ld	s2,64(sp)
    80002d4c:	79e2                	ld	s3,56(sp)
    80002d4e:	7a42                	ld	s4,48(sp)
    80002d50:	7aa2                	ld	s5,40(sp)
    80002d52:	7b02                	ld	s6,32(sp)
    80002d54:	6be2                	ld	s7,24(sp)
    80002d56:	6c42                	ld	s8,16(sp)
    80002d58:	6ca2                	ld	s9,8(sp)
    80002d5a:	6125                	addi	sp,sp,96
    80002d5c:	8082                	ret
  struct proc* prev = 0;
    80002d5e:	8a2a                	mv	s4,a0
    release_list(SLEEPINGL, -1);
    80002d60:	55fd                	li	a1,-1
    80002d62:	4509                	li	a0,2
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	f76080e7          	jalr	-138(ra) # 80001cda <release_list>
    80002d6c:	b7e1                	j	80002d34 <wakeup+0x12a>

0000000080002d6e <reparent>:
{
    80002d6e:	7179                	addi	sp,sp,-48
    80002d70:	f406                	sd	ra,40(sp)
    80002d72:	f022                	sd	s0,32(sp)
    80002d74:	ec26                	sd	s1,24(sp)
    80002d76:	e84a                	sd	s2,16(sp)
    80002d78:	e44e                	sd	s3,8(sp)
    80002d7a:	e052                	sd	s4,0(sp)
    80002d7c:	1800                	addi	s0,sp,48
    80002d7e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002d80:	0000f497          	auipc	s1,0xf
    80002d84:	83848493          	addi	s1,s1,-1992 # 800115b8 <proc>
      pp->parent = initproc;
    80002d88:	00006a17          	auipc	s4,0x6
    80002d8c:	2d8a0a13          	addi	s4,s4,728 # 80009060 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002d90:	00015997          	auipc	s3,0x15
    80002d94:	c2898993          	addi	s3,s3,-984 # 800179b8 <tickslock>
    80002d98:	a029                	j	80002da2 <reparent+0x34>
    80002d9a:	19048493          	addi	s1,s1,400
    80002d9e:	01348d63          	beq	s1,s3,80002db8 <reparent+0x4a>
    if(pp->parent == p){
    80002da2:	70bc                	ld	a5,96(s1)
    80002da4:	ff279be3          	bne	a5,s2,80002d9a <reparent+0x2c>
      pp->parent = initproc;
    80002da8:	000a3503          	ld	a0,0(s4)
    80002dac:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	e5c080e7          	jalr	-420(ra) # 80002c0a <wakeup>
    80002db6:	b7d5                	j	80002d9a <reparent+0x2c>
}
    80002db8:	70a2                	ld	ra,40(sp)
    80002dba:	7402                	ld	s0,32(sp)
    80002dbc:	64e2                	ld	s1,24(sp)
    80002dbe:	6942                	ld	s2,16(sp)
    80002dc0:	69a2                	ld	s3,8(sp)
    80002dc2:	6a02                	ld	s4,0(sp)
    80002dc4:	6145                	addi	sp,sp,48
    80002dc6:	8082                	ret

0000000080002dc8 <exit>:
{
    80002dc8:	7179                	addi	sp,sp,-48
    80002dca:	f406                	sd	ra,40(sp)
    80002dcc:	f022                	sd	s0,32(sp)
    80002dce:	ec26                	sd	s1,24(sp)
    80002dd0:	e84a                	sd	s2,16(sp)
    80002dd2:	e44e                	sd	s3,8(sp)
    80002dd4:	e052                	sd	s4,0(sp)
    80002dd6:	1800                	addi	s0,sp,48
    80002dd8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	420080e7          	jalr	1056(ra) # 800021fa <myproc>
    80002de2:	89aa                	mv	s3,a0
  if(p == initproc)
    80002de4:	00006797          	auipc	a5,0x6
    80002de8:	27c7b783          	ld	a5,636(a5) # 80009060 <initproc>
    80002dec:	0f850493          	addi	s1,a0,248
    80002df0:	17850913          	addi	s2,a0,376
    80002df4:	02a79363          	bne	a5,a0,80002e1a <exit+0x52>
    panic("init exiting");
    80002df8:	00005517          	auipc	a0,0x5
    80002dfc:	5c050513          	addi	a0,a0,1472 # 800083b8 <digits+0x378>
    80002e00:	ffffd097          	auipc	ra,0xffffd
    80002e04:	73e080e7          	jalr	1854(ra) # 8000053e <panic>
      fileclose(f);
    80002e08:	00002097          	auipc	ra,0x2
    80002e0c:	1d6080e7          	jalr	470(ra) # 80004fde <fileclose>
      p->ofile[fd] = 0;
    80002e10:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002e14:	04a1                	addi	s1,s1,8
    80002e16:	01248563          	beq	s1,s2,80002e20 <exit+0x58>
    if(p->ofile[fd]){
    80002e1a:	6088                	ld	a0,0(s1)
    80002e1c:	f575                	bnez	a0,80002e08 <exit+0x40>
    80002e1e:	bfdd                	j	80002e14 <exit+0x4c>
  begin_op();
    80002e20:	00002097          	auipc	ra,0x2
    80002e24:	cf2080e7          	jalr	-782(ra) # 80004b12 <begin_op>
  iput(p->cwd);
    80002e28:	1789b503          	ld	a0,376(s3)
    80002e2c:	00001097          	auipc	ra,0x1
    80002e30:	4ce080e7          	jalr	1230(ra) # 800042fa <iput>
  end_op();
    80002e34:	00002097          	auipc	ra,0x2
    80002e38:	d5e080e7          	jalr	-674(ra) # 80004b92 <end_op>
  p->cwd = 0;
    80002e3c:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    80002e40:	0000e497          	auipc	s1,0xe
    80002e44:	76048493          	addi	s1,s1,1888 # 800115a0 <wait_lock>
    80002e48:	8526                	mv	a0,s1
    80002e4a:	ffffe097          	auipc	ra,0xffffe
    80002e4e:	d9a080e7          	jalr	-614(ra) # 80000be4 <acquire>
  reparent(p);
    80002e52:	854e                	mv	a0,s3
    80002e54:	00000097          	auipc	ra,0x0
    80002e58:	f1a080e7          	jalr	-230(ra) # 80002d6e <reparent>
  wakeup(p->parent);
    80002e5c:	0609b503          	ld	a0,96(s3)
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	daa080e7          	jalr	-598(ra) # 80002c0a <wakeup>
  acquire(&p->lock);
    80002e68:	854e                	mv	a0,s3
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	d7a080e7          	jalr	-646(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002e72:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    80002e76:	4795                	li	a5,5
    80002e78:	02f9a823          	sw	a5,48(s3)
  add_proc_to_list(p, ZOMBIEL, -1);
    80002e7c:	567d                	li	a2,-1
    80002e7e:	4585                	li	a1,1
    80002e80:	854e                	mv	a0,s3
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	f7e080e7          	jalr	-130(ra) # 80001e00 <add_proc_to_list>
  release(&wait_lock);
    80002e8a:	8526                	mv	a0,s1
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	e0c080e7          	jalr	-500(ra) # 80000c98 <release>
  sched();
    80002e94:	00000097          	auipc	ra,0x0
    80002e98:	a68080e7          	jalr	-1432(ra) # 800028fc <sched>
  panic("zombie exit");
    80002e9c:	00005517          	auipc	a0,0x5
    80002ea0:	52c50513          	addi	a0,a0,1324 # 800083c8 <digits+0x388>
    80002ea4:	ffffd097          	auipc	ra,0xffffd
    80002ea8:	69a080e7          	jalr	1690(ra) # 8000053e <panic>

0000000080002eac <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002eac:	7179                	addi	sp,sp,-48
    80002eae:	f406                	sd	ra,40(sp)
    80002eb0:	f022                	sd	s0,32(sp)
    80002eb2:	ec26                	sd	s1,24(sp)
    80002eb4:	e84a                	sd	s2,16(sp)
    80002eb6:	e44e                	sd	s3,8(sp)
    80002eb8:	1800                	addi	s0,sp,48
    80002eba:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002ebc:	0000e497          	auipc	s1,0xe
    80002ec0:	6fc48493          	addi	s1,s1,1788 # 800115b8 <proc>
    80002ec4:	00015997          	auipc	s3,0x15
    80002ec8:	af498993          	addi	s3,s3,-1292 # 800179b8 <tickslock>
    acquire(&p->lock);
    80002ecc:	8526                	mv	a0,s1
    80002ece:	ffffe097          	auipc	ra,0xffffe
    80002ed2:	d16080e7          	jalr	-746(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002ed6:	44bc                	lw	a5,72(s1)
    80002ed8:	01278d63          	beq	a5,s2,80002ef2 <kill+0x46>
        add_proc_to_list(p, READYL, p->parent_cpu);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002edc:	8526                	mv	a0,s1
    80002ede:	ffffe097          	auipc	ra,0xffffe
    80002ee2:	dba080e7          	jalr	-582(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ee6:	19048493          	addi	s1,s1,400
    80002eea:	ff3491e3          	bne	s1,s3,80002ecc <kill+0x20>
  }
  return -1;
    80002eee:	557d                	li	a0,-1
    80002ef0:	a829                	j	80002f0a <kill+0x5e>
      p->killed = 1;
    80002ef2:	4785                	li	a5,1
    80002ef4:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    80002ef6:	5898                	lw	a4,48(s1)
    80002ef8:	4789                	li	a5,2
    80002efa:	00f70f63          	beq	a4,a5,80002f18 <kill+0x6c>
      release(&p->lock);
    80002efe:	8526                	mv	a0,s1
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	d98080e7          	jalr	-616(ra) # 80000c98 <release>
      return 0;
    80002f08:	4501                	li	a0,0
}
    80002f0a:	70a2                	ld	ra,40(sp)
    80002f0c:	7402                	ld	s0,32(sp)
    80002f0e:	64e2                	ld	s1,24(sp)
    80002f10:	6942                	ld	s2,16(sp)
    80002f12:	69a2                	ld	s3,8(sp)
    80002f14:	6145                	addi	sp,sp,48
    80002f16:	8082                	ret
        p->state = RUNNABLE;
    80002f18:	478d                	li	a5,3
    80002f1a:	d89c                	sw	a5,48(s1)
        remove_proc(p, SLEEPINGL);
    80002f1c:	4589                	li	a1,2
    80002f1e:	8526                	mv	a0,s1
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	fbe080e7          	jalr	-66(ra) # 80001ede <remove_proc>
        add_proc_to_list(p, READYL, p->parent_cpu);
    80002f28:	4cb0                	lw	a2,88(s1)
    80002f2a:	4581                	li	a1,0
    80002f2c:	8526                	mv	a0,s1
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	ed2080e7          	jalr	-302(ra) # 80001e00 <add_proc_to_list>
    80002f36:	b7e1                	j	80002efe <kill+0x52>

0000000080002f38 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002f38:	7179                	addi	sp,sp,-48
    80002f3a:	f406                	sd	ra,40(sp)
    80002f3c:	f022                	sd	s0,32(sp)
    80002f3e:	ec26                	sd	s1,24(sp)
    80002f40:	e84a                	sd	s2,16(sp)
    80002f42:	e44e                	sd	s3,8(sp)
    80002f44:	e052                	sd	s4,0(sp)
    80002f46:	1800                	addi	s0,sp,48
    80002f48:	84aa                	mv	s1,a0
    80002f4a:	892e                	mv	s2,a1
    80002f4c:	89b2                	mv	s3,a2
    80002f4e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	2aa080e7          	jalr	682(ra) # 800021fa <myproc>
  if(user_dst){
    80002f58:	c08d                	beqz	s1,80002f7a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002f5a:	86d2                	mv	a3,s4
    80002f5c:	864e                	mv	a2,s3
    80002f5e:	85ca                	mv	a1,s2
    80002f60:	7d28                	ld	a0,120(a0)
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	710080e7          	jalr	1808(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002f6a:	70a2                	ld	ra,40(sp)
    80002f6c:	7402                	ld	s0,32(sp)
    80002f6e:	64e2                	ld	s1,24(sp)
    80002f70:	6942                	ld	s2,16(sp)
    80002f72:	69a2                	ld	s3,8(sp)
    80002f74:	6a02                	ld	s4,0(sp)
    80002f76:	6145                	addi	sp,sp,48
    80002f78:	8082                	ret
    memmove((char *)dst, src, len);
    80002f7a:	000a061b          	sext.w	a2,s4
    80002f7e:	85ce                	mv	a1,s3
    80002f80:	854a                	mv	a0,s2
    80002f82:	ffffe097          	auipc	ra,0xffffe
    80002f86:	dbe080e7          	jalr	-578(ra) # 80000d40 <memmove>
    return 0;
    80002f8a:	8526                	mv	a0,s1
    80002f8c:	bff9                	j	80002f6a <either_copyout+0x32>

0000000080002f8e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002f8e:	7179                	addi	sp,sp,-48
    80002f90:	f406                	sd	ra,40(sp)
    80002f92:	f022                	sd	s0,32(sp)
    80002f94:	ec26                	sd	s1,24(sp)
    80002f96:	e84a                	sd	s2,16(sp)
    80002f98:	e44e                	sd	s3,8(sp)
    80002f9a:	e052                	sd	s4,0(sp)
    80002f9c:	1800                	addi	s0,sp,48
    80002f9e:	892a                	mv	s2,a0
    80002fa0:	84ae                	mv	s1,a1
    80002fa2:	89b2                	mv	s3,a2
    80002fa4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	254080e7          	jalr	596(ra) # 800021fa <myproc>
  if(user_src){
    80002fae:	c08d                	beqz	s1,80002fd0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002fb0:	86d2                	mv	a3,s4
    80002fb2:	864e                	mv	a2,s3
    80002fb4:	85ca                	mv	a1,s2
    80002fb6:	7d28                	ld	a0,120(a0)
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	746080e7          	jalr	1862(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002fc0:	70a2                	ld	ra,40(sp)
    80002fc2:	7402                	ld	s0,32(sp)
    80002fc4:	64e2                	ld	s1,24(sp)
    80002fc6:	6942                	ld	s2,16(sp)
    80002fc8:	69a2                	ld	s3,8(sp)
    80002fca:	6a02                	ld	s4,0(sp)
    80002fcc:	6145                	addi	sp,sp,48
    80002fce:	8082                	ret
    memmove(dst, (char*)src, len);
    80002fd0:	000a061b          	sext.w	a2,s4
    80002fd4:	85ce                	mv	a1,s3
    80002fd6:	854a                	mv	a0,s2
    80002fd8:	ffffe097          	auipc	ra,0xffffe
    80002fdc:	d68080e7          	jalr	-664(ra) # 80000d40 <memmove>
    return 0;
    80002fe0:	8526                	mv	a0,s1
    80002fe2:	bff9                	j	80002fc0 <either_copyin+0x32>

0000000080002fe4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002fe4:	715d                	addi	sp,sp,-80
    80002fe6:	e486                	sd	ra,72(sp)
    80002fe8:	e0a2                	sd	s0,64(sp)
    80002fea:	fc26                	sd	s1,56(sp)
    80002fec:	f84a                	sd	s2,48(sp)
    80002fee:	f44e                	sd	s3,40(sp)
    80002ff0:	f052                	sd	s4,32(sp)
    80002ff2:	ec56                	sd	s5,24(sp)
    80002ff4:	e85a                	sd	s6,16(sp)
    80002ff6:	e45e                	sd	s7,8(sp)
    80002ff8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002ffa:	00005517          	auipc	a0,0x5
    80002ffe:	0ce50513          	addi	a0,a0,206 # 800080c8 <digits+0x88>
    80003002:	ffffd097          	auipc	ra,0xffffd
    80003006:	586080e7          	jalr	1414(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000300a:	0000e497          	auipc	s1,0xe
    8000300e:	72e48493          	addi	s1,s1,1838 # 80011738 <proc+0x180>
    80003012:	00015917          	auipc	s2,0x15
    80003016:	b2690913          	addi	s2,s2,-1242 # 80017b38 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000301a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000301c:	00005997          	auipc	s3,0x5
    80003020:	3bc98993          	addi	s3,s3,956 # 800083d8 <digits+0x398>
    printf("%d %s %s", p->pid, state, p->name);
    80003024:	00005a97          	auipc	s5,0x5
    80003028:	3bca8a93          	addi	s5,s5,956 # 800083e0 <digits+0x3a0>
    printf("\n");
    8000302c:	00005a17          	auipc	s4,0x5
    80003030:	09ca0a13          	addi	s4,s4,156 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003034:	00005b97          	auipc	s7,0x5
    80003038:	3e4b8b93          	addi	s7,s7,996 # 80008418 <states.1885>
    8000303c:	a00d                	j	8000305e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000303e:	ec86a583          	lw	a1,-312(a3)
    80003042:	8556                	mv	a0,s5
    80003044:	ffffd097          	auipc	ra,0xffffd
    80003048:	544080e7          	jalr	1348(ra) # 80000588 <printf>
    printf("\n");
    8000304c:	8552                	mv	a0,s4
    8000304e:	ffffd097          	auipc	ra,0xffffd
    80003052:	53a080e7          	jalr	1338(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003056:	19048493          	addi	s1,s1,400
    8000305a:	03248163          	beq	s1,s2,8000307c <procdump+0x98>
    if(p->state == UNUSED)
    8000305e:	86a6                	mv	a3,s1
    80003060:	eb04a783          	lw	a5,-336(s1)
    80003064:	dbed                	beqz	a5,80003056 <procdump+0x72>
      state = "???";
    80003066:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003068:	fcfb6be3          	bltu	s6,a5,8000303e <procdump+0x5a>
    8000306c:	1782                	slli	a5,a5,0x20
    8000306e:	9381                	srli	a5,a5,0x20
    80003070:	078e                	slli	a5,a5,0x3
    80003072:	97de                	add	a5,a5,s7
    80003074:	6390                	ld	a2,0(a5)
    80003076:	f661                	bnez	a2,8000303e <procdump+0x5a>
      state = "???";
    80003078:	864e                	mv	a2,s3
    8000307a:	b7d1                	j	8000303e <procdump+0x5a>
  }
}
    8000307c:	60a6                	ld	ra,72(sp)
    8000307e:	6406                	ld	s0,64(sp)
    80003080:	74e2                	ld	s1,56(sp)
    80003082:	7942                	ld	s2,48(sp)
    80003084:	79a2                	ld	s3,40(sp)
    80003086:	7a02                	ld	s4,32(sp)
    80003088:	6ae2                	ld	s5,24(sp)
    8000308a:	6b42                	ld	s6,16(sp)
    8000308c:	6ba2                	ld	s7,8(sp)
    8000308e:	6161                	addi	sp,sp,80
    80003090:	8082                	ret

0000000080003092 <swtch>:
    80003092:	00153023          	sd	ra,0(a0)
    80003096:	00253423          	sd	sp,8(a0)
    8000309a:	e900                	sd	s0,16(a0)
    8000309c:	ed04                	sd	s1,24(a0)
    8000309e:	03253023          	sd	s2,32(a0)
    800030a2:	03353423          	sd	s3,40(a0)
    800030a6:	03453823          	sd	s4,48(a0)
    800030aa:	03553c23          	sd	s5,56(a0)
    800030ae:	05653023          	sd	s6,64(a0)
    800030b2:	05753423          	sd	s7,72(a0)
    800030b6:	05853823          	sd	s8,80(a0)
    800030ba:	05953c23          	sd	s9,88(a0)
    800030be:	07a53023          	sd	s10,96(a0)
    800030c2:	07b53423          	sd	s11,104(a0)
    800030c6:	0005b083          	ld	ra,0(a1)
    800030ca:	0085b103          	ld	sp,8(a1)
    800030ce:	6980                	ld	s0,16(a1)
    800030d0:	6d84                	ld	s1,24(a1)
    800030d2:	0205b903          	ld	s2,32(a1)
    800030d6:	0285b983          	ld	s3,40(a1)
    800030da:	0305ba03          	ld	s4,48(a1)
    800030de:	0385ba83          	ld	s5,56(a1)
    800030e2:	0405bb03          	ld	s6,64(a1)
    800030e6:	0485bb83          	ld	s7,72(a1)
    800030ea:	0505bc03          	ld	s8,80(a1)
    800030ee:	0585bc83          	ld	s9,88(a1)
    800030f2:	0605bd03          	ld	s10,96(a1)
    800030f6:	0685bd83          	ld	s11,104(a1)
    800030fa:	8082                	ret

00000000800030fc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800030fc:	1141                	addi	sp,sp,-16
    800030fe:	e406                	sd	ra,8(sp)
    80003100:	e022                	sd	s0,0(sp)
    80003102:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003104:	00005597          	auipc	a1,0x5
    80003108:	34458593          	addi	a1,a1,836 # 80008448 <states.1885+0x30>
    8000310c:	00015517          	auipc	a0,0x15
    80003110:	8ac50513          	addi	a0,a0,-1876 # 800179b8 <tickslock>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	a40080e7          	jalr	-1472(ra) # 80000b54 <initlock>
}
    8000311c:	60a2                	ld	ra,8(sp)
    8000311e:	6402                	ld	s0,0(sp)
    80003120:	0141                	addi	sp,sp,16
    80003122:	8082                	ret

0000000080003124 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003124:	1141                	addi	sp,sp,-16
    80003126:	e422                	sd	s0,8(sp)
    80003128:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000312a:	00003797          	auipc	a5,0x3
    8000312e:	4d678793          	addi	a5,a5,1238 # 80006600 <kernelvec>
    80003132:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003136:	6422                	ld	s0,8(sp)
    80003138:	0141                	addi	sp,sp,16
    8000313a:	8082                	ret

000000008000313c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000313c:	1141                	addi	sp,sp,-16
    8000313e:	e406                	sd	ra,8(sp)
    80003140:	e022                	sd	s0,0(sp)
    80003142:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003144:	fffff097          	auipc	ra,0xfffff
    80003148:	0b6080e7          	jalr	182(ra) # 800021fa <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000314c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003150:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003152:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003156:	00004617          	auipc	a2,0x4
    8000315a:	eaa60613          	addi	a2,a2,-342 # 80007000 <_trampoline>
    8000315e:	00004697          	auipc	a3,0x4
    80003162:	ea268693          	addi	a3,a3,-350 # 80007000 <_trampoline>
    80003166:	8e91                	sub	a3,a3,a2
    80003168:	040007b7          	lui	a5,0x4000
    8000316c:	17fd                	addi	a5,a5,-1
    8000316e:	07b2                	slli	a5,a5,0xc
    80003170:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003172:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003176:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003178:	180026f3          	csrr	a3,satp
    8000317c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000317e:	6158                	ld	a4,128(a0)
    80003180:	7534                	ld	a3,104(a0)
    80003182:	6585                	lui	a1,0x1
    80003184:	96ae                	add	a3,a3,a1
    80003186:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003188:	6158                	ld	a4,128(a0)
    8000318a:	00000697          	auipc	a3,0x0
    8000318e:	13868693          	addi	a3,a3,312 # 800032c2 <usertrap>
    80003192:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003194:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003196:	8692                	mv	a3,tp
    80003198:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000319a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000319e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800031a2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031a6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800031aa:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031ac:	6f18                	ld	a4,24(a4)
    800031ae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800031b2:	7d2c                	ld	a1,120(a0)
    800031b4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800031b6:	00004717          	auipc	a4,0x4
    800031ba:	eda70713          	addi	a4,a4,-294 # 80007090 <userret>
    800031be:	8f11                	sub	a4,a4,a2
    800031c0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800031c2:	577d                	li	a4,-1
    800031c4:	177e                	slli	a4,a4,0x3f
    800031c6:	8dd9                	or	a1,a1,a4
    800031c8:	02000537          	lui	a0,0x2000
    800031cc:	157d                	addi	a0,a0,-1
    800031ce:	0536                	slli	a0,a0,0xd
    800031d0:	9782                	jalr	a5
}
    800031d2:	60a2                	ld	ra,8(sp)
    800031d4:	6402                	ld	s0,0(sp)
    800031d6:	0141                	addi	sp,sp,16
    800031d8:	8082                	ret

00000000800031da <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800031da:	1101                	addi	sp,sp,-32
    800031dc:	ec06                	sd	ra,24(sp)
    800031de:	e822                	sd	s0,16(sp)
    800031e0:	e426                	sd	s1,8(sp)
    800031e2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800031e4:	00014497          	auipc	s1,0x14
    800031e8:	7d448493          	addi	s1,s1,2004 # 800179b8 <tickslock>
    800031ec:	8526                	mv	a0,s1
    800031ee:	ffffe097          	auipc	ra,0xffffe
    800031f2:	9f6080e7          	jalr	-1546(ra) # 80000be4 <acquire>
  ticks++;
    800031f6:	00006517          	auipc	a0,0x6
    800031fa:	e7650513          	addi	a0,a0,-394 # 8000906c <ticks>
    800031fe:	411c                	lw	a5,0(a0)
    80003200:	2785                	addiw	a5,a5,1
    80003202:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003204:	00000097          	auipc	ra,0x0
    80003208:	a06080e7          	jalr	-1530(ra) # 80002c0a <wakeup>
  release(&tickslock);
    8000320c:	8526                	mv	a0,s1
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	a8a080e7          	jalr	-1398(ra) # 80000c98 <release>
}
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	64a2                	ld	s1,8(sp)
    8000321c:	6105                	addi	sp,sp,32
    8000321e:	8082                	ret

0000000080003220 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003220:	1101                	addi	sp,sp,-32
    80003222:	ec06                	sd	ra,24(sp)
    80003224:	e822                	sd	s0,16(sp)
    80003226:	e426                	sd	s1,8(sp)
    80003228:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000322a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000322e:	00074d63          	bltz	a4,80003248 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003232:	57fd                	li	a5,-1
    80003234:	17fe                	slli	a5,a5,0x3f
    80003236:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003238:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000323a:	06f70363          	beq	a4,a5,800032a0 <devintr+0x80>
  }
}
    8000323e:	60e2                	ld	ra,24(sp)
    80003240:	6442                	ld	s0,16(sp)
    80003242:	64a2                	ld	s1,8(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret
     (scause & 0xff) == 9){
    80003248:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000324c:	46a5                	li	a3,9
    8000324e:	fed792e3          	bne	a5,a3,80003232 <devintr+0x12>
    int irq = plic_claim();
    80003252:	00003097          	auipc	ra,0x3
    80003256:	4b6080e7          	jalr	1206(ra) # 80006708 <plic_claim>
    8000325a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000325c:	47a9                	li	a5,10
    8000325e:	02f50763          	beq	a0,a5,8000328c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003262:	4785                	li	a5,1
    80003264:	02f50963          	beq	a0,a5,80003296 <devintr+0x76>
    return 1;
    80003268:	4505                	li	a0,1
    } else if(irq){
    8000326a:	d8f1                	beqz	s1,8000323e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000326c:	85a6                	mv	a1,s1
    8000326e:	00005517          	auipc	a0,0x5
    80003272:	1e250513          	addi	a0,a0,482 # 80008450 <states.1885+0x38>
    80003276:	ffffd097          	auipc	ra,0xffffd
    8000327a:	312080e7          	jalr	786(ra) # 80000588 <printf>
      plic_complete(irq);
    8000327e:	8526                	mv	a0,s1
    80003280:	00003097          	auipc	ra,0x3
    80003284:	4ac080e7          	jalr	1196(ra) # 8000672c <plic_complete>
    return 1;
    80003288:	4505                	li	a0,1
    8000328a:	bf55                	j	8000323e <devintr+0x1e>
      uartintr();
    8000328c:	ffffd097          	auipc	ra,0xffffd
    80003290:	71c080e7          	jalr	1820(ra) # 800009a8 <uartintr>
    80003294:	b7ed                	j	8000327e <devintr+0x5e>
      virtio_disk_intr();
    80003296:	00004097          	auipc	ra,0x4
    8000329a:	976080e7          	jalr	-1674(ra) # 80006c0c <virtio_disk_intr>
    8000329e:	b7c5                	j	8000327e <devintr+0x5e>
    if(cpuid() == 0){
    800032a0:	fffff097          	auipc	ra,0xfffff
    800032a4:	f26080e7          	jalr	-218(ra) # 800021c6 <cpuid>
    800032a8:	c901                	beqz	a0,800032b8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800032aa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800032ae:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800032b0:	14479073          	csrw	sip,a5
    return 2;
    800032b4:	4509                	li	a0,2
    800032b6:	b761                	j	8000323e <devintr+0x1e>
      clockintr();
    800032b8:	00000097          	auipc	ra,0x0
    800032bc:	f22080e7          	jalr	-222(ra) # 800031da <clockintr>
    800032c0:	b7ed                	j	800032aa <devintr+0x8a>

00000000800032c2 <usertrap>:
{
    800032c2:	1101                	addi	sp,sp,-32
    800032c4:	ec06                	sd	ra,24(sp)
    800032c6:	e822                	sd	s0,16(sp)
    800032c8:	e426                	sd	s1,8(sp)
    800032ca:	e04a                	sd	s2,0(sp)
    800032cc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032ce:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800032d2:	1007f793          	andi	a5,a5,256
    800032d6:	e3ad                	bnez	a5,80003338 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800032d8:	00003797          	auipc	a5,0x3
    800032dc:	32878793          	addi	a5,a5,808 # 80006600 <kernelvec>
    800032e0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800032e4:	fffff097          	auipc	ra,0xfffff
    800032e8:	f16080e7          	jalr	-234(ra) # 800021fa <myproc>
    800032ec:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800032ee:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032f0:	14102773          	csrr	a4,sepc
    800032f4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800032f6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800032fa:	47a1                	li	a5,8
    800032fc:	04f71c63          	bne	a4,a5,80003354 <usertrap+0x92>
    if(p->killed)
    80003300:	413c                	lw	a5,64(a0)
    80003302:	e3b9                	bnez	a5,80003348 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003304:	60d8                	ld	a4,128(s1)
    80003306:	6f1c                	ld	a5,24(a4)
    80003308:	0791                	addi	a5,a5,4
    8000330a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000330c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003310:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003314:	10079073          	csrw	sstatus,a5
    syscall();
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	2e0080e7          	jalr	736(ra) # 800035f8 <syscall>
  if(p->killed)
    80003320:	40bc                	lw	a5,64(s1)
    80003322:	ebc1                	bnez	a5,800033b2 <usertrap+0xf0>
  usertrapret();
    80003324:	00000097          	auipc	ra,0x0
    80003328:	e18080e7          	jalr	-488(ra) # 8000313c <usertrapret>
}
    8000332c:	60e2                	ld	ra,24(sp)
    8000332e:	6442                	ld	s0,16(sp)
    80003330:	64a2                	ld	s1,8(sp)
    80003332:	6902                	ld	s2,0(sp)
    80003334:	6105                	addi	sp,sp,32
    80003336:	8082                	ret
    panic("usertrap: not from user mode");
    80003338:	00005517          	auipc	a0,0x5
    8000333c:	13850513          	addi	a0,a0,312 # 80008470 <states.1885+0x58>
    80003340:	ffffd097          	auipc	ra,0xffffd
    80003344:	1fe080e7          	jalr	510(ra) # 8000053e <panic>
      exit(-1);
    80003348:	557d                	li	a0,-1
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	a7e080e7          	jalr	-1410(ra) # 80002dc8 <exit>
    80003352:	bf4d                	j	80003304 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003354:	00000097          	auipc	ra,0x0
    80003358:	ecc080e7          	jalr	-308(ra) # 80003220 <devintr>
    8000335c:	892a                	mv	s2,a0
    8000335e:	c501                	beqz	a0,80003366 <usertrap+0xa4>
  if(p->killed)
    80003360:	40bc                	lw	a5,64(s1)
    80003362:	c3a1                	beqz	a5,800033a2 <usertrap+0xe0>
    80003364:	a815                	j	80003398 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003366:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000336a:	44b0                	lw	a2,72(s1)
    8000336c:	00005517          	auipc	a0,0x5
    80003370:	12450513          	addi	a0,a0,292 # 80008490 <states.1885+0x78>
    80003374:	ffffd097          	auipc	ra,0xffffd
    80003378:	214080e7          	jalr	532(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000337c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003380:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003384:	00005517          	auipc	a0,0x5
    80003388:	13c50513          	addi	a0,a0,316 # 800084c0 <states.1885+0xa8>
    8000338c:	ffffd097          	auipc	ra,0xffffd
    80003390:	1fc080e7          	jalr	508(ra) # 80000588 <printf>
    p->killed = 1;
    80003394:	4785                	li	a5,1
    80003396:	c0bc                	sw	a5,64(s1)
    exit(-1);
    80003398:	557d                	li	a0,-1
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	a2e080e7          	jalr	-1490(ra) # 80002dc8 <exit>
  if(which_dev == 2)
    800033a2:	4789                	li	a5,2
    800033a4:	f8f910e3          	bne	s2,a5,80003324 <usertrap+0x62>
    yield();
    800033a8:	fffff097          	auipc	ra,0xfffff
    800033ac:	64a080e7          	jalr	1610(ra) # 800029f2 <yield>
    800033b0:	bf95                	j	80003324 <usertrap+0x62>
  int which_dev = 0;
    800033b2:	4901                	li	s2,0
    800033b4:	b7d5                	j	80003398 <usertrap+0xd6>

00000000800033b6 <kerneltrap>:
{
    800033b6:	7179                	addi	sp,sp,-48
    800033b8:	f406                	sd	ra,40(sp)
    800033ba:	f022                	sd	s0,32(sp)
    800033bc:	ec26                	sd	s1,24(sp)
    800033be:	e84a                	sd	s2,16(sp)
    800033c0:	e44e                	sd	s3,8(sp)
    800033c2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800033c4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033c8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033cc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800033d0:	1004f793          	andi	a5,s1,256
    800033d4:	cb85                	beqz	a5,80003404 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033d6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800033da:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800033dc:	ef85                	bnez	a5,80003414 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	e42080e7          	jalr	-446(ra) # 80003220 <devintr>
    800033e6:	cd1d                	beqz	a0,80003424 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800033e8:	4789                	li	a5,2
    800033ea:	06f50a63          	beq	a0,a5,8000345e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800033ee:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800033f2:	10049073          	csrw	sstatus,s1
}
    800033f6:	70a2                	ld	ra,40(sp)
    800033f8:	7402                	ld	s0,32(sp)
    800033fa:	64e2                	ld	s1,24(sp)
    800033fc:	6942                	ld	s2,16(sp)
    800033fe:	69a2                	ld	s3,8(sp)
    80003400:	6145                	addi	sp,sp,48
    80003402:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003404:	00005517          	auipc	a0,0x5
    80003408:	0dc50513          	addi	a0,a0,220 # 800084e0 <states.1885+0xc8>
    8000340c:	ffffd097          	auipc	ra,0xffffd
    80003410:	132080e7          	jalr	306(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003414:	00005517          	auipc	a0,0x5
    80003418:	0f450513          	addi	a0,a0,244 # 80008508 <states.1885+0xf0>
    8000341c:	ffffd097          	auipc	ra,0xffffd
    80003420:	122080e7          	jalr	290(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003424:	85ce                	mv	a1,s3
    80003426:	00005517          	auipc	a0,0x5
    8000342a:	10250513          	addi	a0,a0,258 # 80008528 <states.1885+0x110>
    8000342e:	ffffd097          	auipc	ra,0xffffd
    80003432:	15a080e7          	jalr	346(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003436:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000343a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000343e:	00005517          	auipc	a0,0x5
    80003442:	0fa50513          	addi	a0,a0,250 # 80008538 <states.1885+0x120>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	142080e7          	jalr	322(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000344e:	00005517          	auipc	a0,0x5
    80003452:	10250513          	addi	a0,a0,258 # 80008550 <states.1885+0x138>
    80003456:	ffffd097          	auipc	ra,0xffffd
    8000345a:	0e8080e7          	jalr	232(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000345e:	fffff097          	auipc	ra,0xfffff
    80003462:	d9c080e7          	jalr	-612(ra) # 800021fa <myproc>
    80003466:	d541                	beqz	a0,800033ee <kerneltrap+0x38>
    80003468:	fffff097          	auipc	ra,0xfffff
    8000346c:	d92080e7          	jalr	-622(ra) # 800021fa <myproc>
    80003470:	5918                	lw	a4,48(a0)
    80003472:	4791                	li	a5,4
    80003474:	f6f71de3          	bne	a4,a5,800033ee <kerneltrap+0x38>
    yield();
    80003478:	fffff097          	auipc	ra,0xfffff
    8000347c:	57a080e7          	jalr	1402(ra) # 800029f2 <yield>
    80003480:	b7bd                	j	800033ee <kerneltrap+0x38>

0000000080003482 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003482:	1101                	addi	sp,sp,-32
    80003484:	ec06                	sd	ra,24(sp)
    80003486:	e822                	sd	s0,16(sp)
    80003488:	e426                	sd	s1,8(sp)
    8000348a:	1000                	addi	s0,sp,32
    8000348c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000348e:	fffff097          	auipc	ra,0xfffff
    80003492:	d6c080e7          	jalr	-660(ra) # 800021fa <myproc>
  switch (n) {
    80003496:	4795                	li	a5,5
    80003498:	0497e163          	bltu	a5,s1,800034da <argraw+0x58>
    8000349c:	048a                	slli	s1,s1,0x2
    8000349e:	00005717          	auipc	a4,0x5
    800034a2:	0ea70713          	addi	a4,a4,234 # 80008588 <states.1885+0x170>
    800034a6:	94ba                	add	s1,s1,a4
    800034a8:	409c                	lw	a5,0(s1)
    800034aa:	97ba                	add	a5,a5,a4
    800034ac:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800034ae:	615c                	ld	a5,128(a0)
    800034b0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800034b2:	60e2                	ld	ra,24(sp)
    800034b4:	6442                	ld	s0,16(sp)
    800034b6:	64a2                	ld	s1,8(sp)
    800034b8:	6105                	addi	sp,sp,32
    800034ba:	8082                	ret
    return p->trapframe->a1;
    800034bc:	615c                	ld	a5,128(a0)
    800034be:	7fa8                	ld	a0,120(a5)
    800034c0:	bfcd                	j	800034b2 <argraw+0x30>
    return p->trapframe->a2;
    800034c2:	615c                	ld	a5,128(a0)
    800034c4:	63c8                	ld	a0,128(a5)
    800034c6:	b7f5                	j	800034b2 <argraw+0x30>
    return p->trapframe->a3;
    800034c8:	615c                	ld	a5,128(a0)
    800034ca:	67c8                	ld	a0,136(a5)
    800034cc:	b7dd                	j	800034b2 <argraw+0x30>
    return p->trapframe->a4;
    800034ce:	615c                	ld	a5,128(a0)
    800034d0:	6bc8                	ld	a0,144(a5)
    800034d2:	b7c5                	j	800034b2 <argraw+0x30>
    return p->trapframe->a5;
    800034d4:	615c                	ld	a5,128(a0)
    800034d6:	6fc8                	ld	a0,152(a5)
    800034d8:	bfe9                	j	800034b2 <argraw+0x30>
  panic("argraw");
    800034da:	00005517          	auipc	a0,0x5
    800034de:	08650513          	addi	a0,a0,134 # 80008560 <states.1885+0x148>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	05c080e7          	jalr	92(ra) # 8000053e <panic>

00000000800034ea <fetchaddr>:
{
    800034ea:	1101                	addi	sp,sp,-32
    800034ec:	ec06                	sd	ra,24(sp)
    800034ee:	e822                	sd	s0,16(sp)
    800034f0:	e426                	sd	s1,8(sp)
    800034f2:	e04a                	sd	s2,0(sp)
    800034f4:	1000                	addi	s0,sp,32
    800034f6:	84aa                	mv	s1,a0
    800034f8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800034fa:	fffff097          	auipc	ra,0xfffff
    800034fe:	d00080e7          	jalr	-768(ra) # 800021fa <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003502:	793c                	ld	a5,112(a0)
    80003504:	02f4f863          	bgeu	s1,a5,80003534 <fetchaddr+0x4a>
    80003508:	00848713          	addi	a4,s1,8
    8000350c:	02e7e663          	bltu	a5,a4,80003538 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003510:	46a1                	li	a3,8
    80003512:	8626                	mv	a2,s1
    80003514:	85ca                	mv	a1,s2
    80003516:	7d28                	ld	a0,120(a0)
    80003518:	ffffe097          	auipc	ra,0xffffe
    8000351c:	1e6080e7          	jalr	486(ra) # 800016fe <copyin>
    80003520:	00a03533          	snez	a0,a0
    80003524:	40a00533          	neg	a0,a0
}
    80003528:	60e2                	ld	ra,24(sp)
    8000352a:	6442                	ld	s0,16(sp)
    8000352c:	64a2                	ld	s1,8(sp)
    8000352e:	6902                	ld	s2,0(sp)
    80003530:	6105                	addi	sp,sp,32
    80003532:	8082                	ret
    return -1;
    80003534:	557d                	li	a0,-1
    80003536:	bfcd                	j	80003528 <fetchaddr+0x3e>
    80003538:	557d                	li	a0,-1
    8000353a:	b7fd                	j	80003528 <fetchaddr+0x3e>

000000008000353c <fetchstr>:
{
    8000353c:	7179                	addi	sp,sp,-48
    8000353e:	f406                	sd	ra,40(sp)
    80003540:	f022                	sd	s0,32(sp)
    80003542:	ec26                	sd	s1,24(sp)
    80003544:	e84a                	sd	s2,16(sp)
    80003546:	e44e                	sd	s3,8(sp)
    80003548:	1800                	addi	s0,sp,48
    8000354a:	892a                	mv	s2,a0
    8000354c:	84ae                	mv	s1,a1
    8000354e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003550:	fffff097          	auipc	ra,0xfffff
    80003554:	caa080e7          	jalr	-854(ra) # 800021fa <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003558:	86ce                	mv	a3,s3
    8000355a:	864a                	mv	a2,s2
    8000355c:	85a6                	mv	a1,s1
    8000355e:	7d28                	ld	a0,120(a0)
    80003560:	ffffe097          	auipc	ra,0xffffe
    80003564:	22a080e7          	jalr	554(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003568:	00054763          	bltz	a0,80003576 <fetchstr+0x3a>
  return strlen(buf);
    8000356c:	8526                	mv	a0,s1
    8000356e:	ffffe097          	auipc	ra,0xffffe
    80003572:	8f6080e7          	jalr	-1802(ra) # 80000e64 <strlen>
}
    80003576:	70a2                	ld	ra,40(sp)
    80003578:	7402                	ld	s0,32(sp)
    8000357a:	64e2                	ld	s1,24(sp)
    8000357c:	6942                	ld	s2,16(sp)
    8000357e:	69a2                	ld	s3,8(sp)
    80003580:	6145                	addi	sp,sp,48
    80003582:	8082                	ret

0000000080003584 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003584:	1101                	addi	sp,sp,-32
    80003586:	ec06                	sd	ra,24(sp)
    80003588:	e822                	sd	s0,16(sp)
    8000358a:	e426                	sd	s1,8(sp)
    8000358c:	1000                	addi	s0,sp,32
    8000358e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003590:	00000097          	auipc	ra,0x0
    80003594:	ef2080e7          	jalr	-270(ra) # 80003482 <argraw>
    80003598:	c088                	sw	a0,0(s1)
  return 0;
}
    8000359a:	4501                	li	a0,0
    8000359c:	60e2                	ld	ra,24(sp)
    8000359e:	6442                	ld	s0,16(sp)
    800035a0:	64a2                	ld	s1,8(sp)
    800035a2:	6105                	addi	sp,sp,32
    800035a4:	8082                	ret

00000000800035a6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800035a6:	1101                	addi	sp,sp,-32
    800035a8:	ec06                	sd	ra,24(sp)
    800035aa:	e822                	sd	s0,16(sp)
    800035ac:	e426                	sd	s1,8(sp)
    800035ae:	1000                	addi	s0,sp,32
    800035b0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	ed0080e7          	jalr	-304(ra) # 80003482 <argraw>
    800035ba:	e088                	sd	a0,0(s1)
  return 0;
}
    800035bc:	4501                	li	a0,0
    800035be:	60e2                	ld	ra,24(sp)
    800035c0:	6442                	ld	s0,16(sp)
    800035c2:	64a2                	ld	s1,8(sp)
    800035c4:	6105                	addi	sp,sp,32
    800035c6:	8082                	ret

00000000800035c8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800035c8:	1101                	addi	sp,sp,-32
    800035ca:	ec06                	sd	ra,24(sp)
    800035cc:	e822                	sd	s0,16(sp)
    800035ce:	e426                	sd	s1,8(sp)
    800035d0:	e04a                	sd	s2,0(sp)
    800035d2:	1000                	addi	s0,sp,32
    800035d4:	84ae                	mv	s1,a1
    800035d6:	8932                	mv	s2,a2
  *ip = argraw(n);
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	eaa080e7          	jalr	-342(ra) # 80003482 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800035e0:	864a                	mv	a2,s2
    800035e2:	85a6                	mv	a1,s1
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	f58080e7          	jalr	-168(ra) # 8000353c <fetchstr>
}
    800035ec:	60e2                	ld	ra,24(sp)
    800035ee:	6442                	ld	s0,16(sp)
    800035f0:	64a2                	ld	s1,8(sp)
    800035f2:	6902                	ld	s2,0(sp)
    800035f4:	6105                	addi	sp,sp,32
    800035f6:	8082                	ret

00000000800035f8 <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    800035f8:	1101                	addi	sp,sp,-32
    800035fa:	ec06                	sd	ra,24(sp)
    800035fc:	e822                	sd	s0,16(sp)
    800035fe:	e426                	sd	s1,8(sp)
    80003600:	e04a                	sd	s2,0(sp)
    80003602:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003604:	fffff097          	auipc	ra,0xfffff
    80003608:	bf6080e7          	jalr	-1034(ra) # 800021fa <myproc>
    8000360c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000360e:	08053903          	ld	s2,128(a0)
    80003612:	0a893783          	ld	a5,168(s2)
    80003616:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000361a:	37fd                	addiw	a5,a5,-1
    8000361c:	4759                	li	a4,22
    8000361e:	00f76f63          	bltu	a4,a5,8000363c <syscall+0x44>
    80003622:	00369713          	slli	a4,a3,0x3
    80003626:	00005797          	auipc	a5,0x5
    8000362a:	f7a78793          	addi	a5,a5,-134 # 800085a0 <syscalls>
    8000362e:	97ba                	add	a5,a5,a4
    80003630:	639c                	ld	a5,0(a5)
    80003632:	c789                	beqz	a5,8000363c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003634:	9782                	jalr	a5
    80003636:	06a93823          	sd	a0,112(s2)
    8000363a:	a839                	j	80003658 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000363c:	18048613          	addi	a2,s1,384
    80003640:	44ac                	lw	a1,72(s1)
    80003642:	00005517          	auipc	a0,0x5
    80003646:	f2650513          	addi	a0,a0,-218 # 80008568 <states.1885+0x150>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	f3e080e7          	jalr	-194(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003652:	60dc                	ld	a5,128(s1)
    80003654:	577d                	li	a4,-1
    80003656:	fbb8                	sd	a4,112(a5)
  }
}
    80003658:	60e2                	ld	ra,24(sp)
    8000365a:	6442                	ld	s0,16(sp)
    8000365c:	64a2                	ld	s1,8(sp)
    8000365e:	6902                	ld	s2,0(sp)
    80003660:	6105                	addi	sp,sp,32
    80003662:	8082                	ret

0000000080003664 <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    80003664:	1101                	addi	sp,sp,-32
    80003666:	ec06                	sd	ra,24(sp)
    80003668:	e822                	sd	s0,16(sp)
    8000366a:	1000                	addi	s0,sp,32
  int a;

  if(argint(0, &a) < 0)
    8000366c:	fec40593          	addi	a1,s0,-20
    80003670:	4501                	li	a0,0
    80003672:	00000097          	auipc	ra,0x0
    80003676:	f12080e7          	jalr	-238(ra) # 80003584 <argint>
    8000367a:	87aa                	mv	a5,a0
    return -1;
    8000367c:	557d                	li	a0,-1
  if(argint(0, &a) < 0)
    8000367e:	0007c863          	bltz	a5,8000368e <sys_set_cpu+0x2a>
  return set_cpu(a);
    80003682:	fec42503          	lw	a0,-20(s0)
    80003686:	fffff097          	auipc	ra,0xfffff
    8000368a:	3b6080e7          	jalr	950(ra) # 80002a3c <set_cpu>
}
    8000368e:	60e2                	ld	ra,24(sp)
    80003690:	6442                	ld	s0,16(sp)
    80003692:	6105                	addi	sp,sp,32
    80003694:	8082                	ret

0000000080003696 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003696:	1141                	addi	sp,sp,-16
    80003698:	e406                	sd	ra,8(sp)
    8000369a:	e022                	sd	s0,0(sp)
    8000369c:	0800                	addi	s0,sp,16
  return get_cpu();
    8000369e:	fffff097          	auipc	ra,0xfffff
    800036a2:	b9c080e7          	jalr	-1124(ra) # 8000223a <get_cpu>
}
    800036a6:	60a2                	ld	ra,8(sp)
    800036a8:	6402                	ld	s0,0(sp)
    800036aa:	0141                	addi	sp,sp,16
    800036ac:	8082                	ret

00000000800036ae <sys_exit>:

uint64
sys_exit(void)
{
    800036ae:	1101                	addi	sp,sp,-32
    800036b0:	ec06                	sd	ra,24(sp)
    800036b2:	e822                	sd	s0,16(sp)
    800036b4:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800036b6:	fec40593          	addi	a1,s0,-20
    800036ba:	4501                	li	a0,0
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	ec8080e7          	jalr	-312(ra) # 80003584 <argint>
    return -1;
    800036c4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800036c6:	00054963          	bltz	a0,800036d8 <sys_exit+0x2a>
  exit(n);
    800036ca:	fec42503          	lw	a0,-20(s0)
    800036ce:	fffff097          	auipc	ra,0xfffff
    800036d2:	6fa080e7          	jalr	1786(ra) # 80002dc8 <exit>
  return 0;  // not reached
    800036d6:	4781                	li	a5,0
}
    800036d8:	853e                	mv	a0,a5
    800036da:	60e2                	ld	ra,24(sp)
    800036dc:	6442                	ld	s0,16(sp)
    800036de:	6105                	addi	sp,sp,32
    800036e0:	8082                	ret

00000000800036e2 <sys_getpid>:

uint64
sys_getpid(void)
{
    800036e2:	1141                	addi	sp,sp,-16
    800036e4:	e406                	sd	ra,8(sp)
    800036e6:	e022                	sd	s0,0(sp)
    800036e8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800036ea:	fffff097          	auipc	ra,0xfffff
    800036ee:	b10080e7          	jalr	-1264(ra) # 800021fa <myproc>
}
    800036f2:	4528                	lw	a0,72(a0)
    800036f4:	60a2                	ld	ra,8(sp)
    800036f6:	6402                	ld	s0,0(sp)
    800036f8:	0141                	addi	sp,sp,16
    800036fa:	8082                	ret

00000000800036fc <sys_fork>:

uint64
sys_fork(void)
{
    800036fc:	1141                	addi	sp,sp,-16
    800036fe:	e406                	sd	ra,8(sp)
    80003700:	e022                	sd	s0,0(sp)
    80003702:	0800                	addi	s0,sp,16
  return fork();
    80003704:	fffff097          	auipc	ra,0xfffff
    80003708:	f12080e7          	jalr	-238(ra) # 80002616 <fork>
}
    8000370c:	60a2                	ld	ra,8(sp)
    8000370e:	6402                	ld	s0,0(sp)
    80003710:	0141                	addi	sp,sp,16
    80003712:	8082                	ret

0000000080003714 <sys_wait>:

uint64
sys_wait(void)
{
    80003714:	1101                	addi	sp,sp,-32
    80003716:	ec06                	sd	ra,24(sp)
    80003718:	e822                	sd	s0,16(sp)
    8000371a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000371c:	fe840593          	addi	a1,s0,-24
    80003720:	4501                	li	a0,0
    80003722:	00000097          	auipc	ra,0x0
    80003726:	e84080e7          	jalr	-380(ra) # 800035a6 <argaddr>
    8000372a:	87aa                	mv	a5,a0
    return -1;
    8000372c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000372e:	0007c863          	bltz	a5,8000373e <sys_wait+0x2a>
  return wait(p);
    80003732:	fe843503          	ld	a0,-24(s0)
    80003736:	fffff097          	auipc	ra,0xfffff
    8000373a:	3ac080e7          	jalr	940(ra) # 80002ae2 <wait>
}
    8000373e:	60e2                	ld	ra,24(sp)
    80003740:	6442                	ld	s0,16(sp)
    80003742:	6105                	addi	sp,sp,32
    80003744:	8082                	ret

0000000080003746 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003746:	7179                	addi	sp,sp,-48
    80003748:	f406                	sd	ra,40(sp)
    8000374a:	f022                	sd	s0,32(sp)
    8000374c:	ec26                	sd	s1,24(sp)
    8000374e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003750:	fdc40593          	addi	a1,s0,-36
    80003754:	4501                	li	a0,0
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	e2e080e7          	jalr	-466(ra) # 80003584 <argint>
    8000375e:	87aa                	mv	a5,a0
    return -1;
    80003760:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003762:	0207c063          	bltz	a5,80003782 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003766:	fffff097          	auipc	ra,0xfffff
    8000376a:	a94080e7          	jalr	-1388(ra) # 800021fa <myproc>
    8000376e:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    80003770:	fdc42503          	lw	a0,-36(s0)
    80003774:	fffff097          	auipc	ra,0xfffff
    80003778:	e2e080e7          	jalr	-466(ra) # 800025a2 <growproc>
    8000377c:	00054863          	bltz	a0,8000378c <sys_sbrk+0x46>
    return -1;
  return addr;
    80003780:	8526                	mv	a0,s1
}
    80003782:	70a2                	ld	ra,40(sp)
    80003784:	7402                	ld	s0,32(sp)
    80003786:	64e2                	ld	s1,24(sp)
    80003788:	6145                	addi	sp,sp,48
    8000378a:	8082                	ret
    return -1;
    8000378c:	557d                	li	a0,-1
    8000378e:	bfd5                	j	80003782 <sys_sbrk+0x3c>

0000000080003790 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003790:	7139                	addi	sp,sp,-64
    80003792:	fc06                	sd	ra,56(sp)
    80003794:	f822                	sd	s0,48(sp)
    80003796:	f426                	sd	s1,40(sp)
    80003798:	f04a                	sd	s2,32(sp)
    8000379a:	ec4e                	sd	s3,24(sp)
    8000379c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000379e:	fcc40593          	addi	a1,s0,-52
    800037a2:	4501                	li	a0,0
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	de0080e7          	jalr	-544(ra) # 80003584 <argint>
    return -1;
    800037ac:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800037ae:	06054563          	bltz	a0,80003818 <sys_sleep+0x88>
  acquire(&tickslock);
    800037b2:	00014517          	auipc	a0,0x14
    800037b6:	20650513          	addi	a0,a0,518 # 800179b8 <tickslock>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	42a080e7          	jalr	1066(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800037c2:	00006917          	auipc	s2,0x6
    800037c6:	8aa92903          	lw	s2,-1878(s2) # 8000906c <ticks>
  while(ticks - ticks0 < n){
    800037ca:	fcc42783          	lw	a5,-52(s0)
    800037ce:	cf85                	beqz	a5,80003806 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800037d0:	00014997          	auipc	s3,0x14
    800037d4:	1e898993          	addi	s3,s3,488 # 800179b8 <tickslock>
    800037d8:	00006497          	auipc	s1,0x6
    800037dc:	89448493          	addi	s1,s1,-1900 # 8000906c <ticks>
    if(myproc()->killed){
    800037e0:	fffff097          	auipc	ra,0xfffff
    800037e4:	a1a080e7          	jalr	-1510(ra) # 800021fa <myproc>
    800037e8:	413c                	lw	a5,64(a0)
    800037ea:	ef9d                	bnez	a5,80003828 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800037ec:	85ce                	mv	a1,s3
    800037ee:	8526                	mv	a0,s1
    800037f0:	fffff097          	auipc	ra,0xfffff
    800037f4:	280080e7          	jalr	640(ra) # 80002a70 <sleep>
  while(ticks - ticks0 < n){
    800037f8:	409c                	lw	a5,0(s1)
    800037fa:	412787bb          	subw	a5,a5,s2
    800037fe:	fcc42703          	lw	a4,-52(s0)
    80003802:	fce7efe3          	bltu	a5,a4,800037e0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003806:	00014517          	auipc	a0,0x14
    8000380a:	1b250513          	addi	a0,a0,434 # 800179b8 <tickslock>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	48a080e7          	jalr	1162(ra) # 80000c98 <release>
  return 0;
    80003816:	4781                	li	a5,0
}
    80003818:	853e                	mv	a0,a5
    8000381a:	70e2                	ld	ra,56(sp)
    8000381c:	7442                	ld	s0,48(sp)
    8000381e:	74a2                	ld	s1,40(sp)
    80003820:	7902                	ld	s2,32(sp)
    80003822:	69e2                	ld	s3,24(sp)
    80003824:	6121                	addi	sp,sp,64
    80003826:	8082                	ret
      release(&tickslock);
    80003828:	00014517          	auipc	a0,0x14
    8000382c:	19050513          	addi	a0,a0,400 # 800179b8 <tickslock>
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	468080e7          	jalr	1128(ra) # 80000c98 <release>
      return -1;
    80003838:	57fd                	li	a5,-1
    8000383a:	bff9                	j	80003818 <sys_sleep+0x88>

000000008000383c <sys_kill>:

uint64
sys_kill(void)
{
    8000383c:	1101                	addi	sp,sp,-32
    8000383e:	ec06                	sd	ra,24(sp)
    80003840:	e822                	sd	s0,16(sp)
    80003842:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003844:	fec40593          	addi	a1,s0,-20
    80003848:	4501                	li	a0,0
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	d3a080e7          	jalr	-710(ra) # 80003584 <argint>
    80003852:	87aa                	mv	a5,a0
    return -1;
    80003854:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003856:	0007c863          	bltz	a5,80003866 <sys_kill+0x2a>
  return kill(pid);
    8000385a:	fec42503          	lw	a0,-20(s0)
    8000385e:	fffff097          	auipc	ra,0xfffff
    80003862:	64e080e7          	jalr	1614(ra) # 80002eac <kill>
}
    80003866:	60e2                	ld	ra,24(sp)
    80003868:	6442                	ld	s0,16(sp)
    8000386a:	6105                	addi	sp,sp,32
    8000386c:	8082                	ret

000000008000386e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000386e:	1101                	addi	sp,sp,-32
    80003870:	ec06                	sd	ra,24(sp)
    80003872:	e822                	sd	s0,16(sp)
    80003874:	e426                	sd	s1,8(sp)
    80003876:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003878:	00014517          	auipc	a0,0x14
    8000387c:	14050513          	addi	a0,a0,320 # 800179b8 <tickslock>
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	364080e7          	jalr	868(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003888:	00005497          	auipc	s1,0x5
    8000388c:	7e44a483          	lw	s1,2020(s1) # 8000906c <ticks>
  release(&tickslock);
    80003890:	00014517          	auipc	a0,0x14
    80003894:	12850513          	addi	a0,a0,296 # 800179b8 <tickslock>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	400080e7          	jalr	1024(ra) # 80000c98 <release>
  return xticks;
}
    800038a0:	02049513          	slli	a0,s1,0x20
    800038a4:	9101                	srli	a0,a0,0x20
    800038a6:	60e2                	ld	ra,24(sp)
    800038a8:	6442                	ld	s0,16(sp)
    800038aa:	64a2                	ld	s1,8(sp)
    800038ac:	6105                	addi	sp,sp,32
    800038ae:	8082                	ret

00000000800038b0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800038b0:	7179                	addi	sp,sp,-48
    800038b2:	f406                	sd	ra,40(sp)
    800038b4:	f022                	sd	s0,32(sp)
    800038b6:	ec26                	sd	s1,24(sp)
    800038b8:	e84a                	sd	s2,16(sp)
    800038ba:	e44e                	sd	s3,8(sp)
    800038bc:	e052                	sd	s4,0(sp)
    800038be:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800038c0:	00005597          	auipc	a1,0x5
    800038c4:	da058593          	addi	a1,a1,-608 # 80008660 <syscalls+0xc0>
    800038c8:	00014517          	auipc	a0,0x14
    800038cc:	10850513          	addi	a0,a0,264 # 800179d0 <bcache>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	284080e7          	jalr	644(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800038d8:	0001c797          	auipc	a5,0x1c
    800038dc:	0f878793          	addi	a5,a5,248 # 8001f9d0 <bcache+0x8000>
    800038e0:	0001c717          	auipc	a4,0x1c
    800038e4:	35870713          	addi	a4,a4,856 # 8001fc38 <bcache+0x8268>
    800038e8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800038ec:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800038f0:	00014497          	auipc	s1,0x14
    800038f4:	0f848493          	addi	s1,s1,248 # 800179e8 <bcache+0x18>
    b->next = bcache.head.next;
    800038f8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800038fa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800038fc:	00005a17          	auipc	s4,0x5
    80003900:	d6ca0a13          	addi	s4,s4,-660 # 80008668 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003904:	2b893783          	ld	a5,696(s2)
    80003908:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000390a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000390e:	85d2                	mv	a1,s4
    80003910:	01048513          	addi	a0,s1,16
    80003914:	00001097          	auipc	ra,0x1
    80003918:	4bc080e7          	jalr	1212(ra) # 80004dd0 <initsleeplock>
    bcache.head.next->prev = b;
    8000391c:	2b893783          	ld	a5,696(s2)
    80003920:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003922:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003926:	45848493          	addi	s1,s1,1112
    8000392a:	fd349de3          	bne	s1,s3,80003904 <binit+0x54>
  }
}
    8000392e:	70a2                	ld	ra,40(sp)
    80003930:	7402                	ld	s0,32(sp)
    80003932:	64e2                	ld	s1,24(sp)
    80003934:	6942                	ld	s2,16(sp)
    80003936:	69a2                	ld	s3,8(sp)
    80003938:	6a02                	ld	s4,0(sp)
    8000393a:	6145                	addi	sp,sp,48
    8000393c:	8082                	ret

000000008000393e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000393e:	7179                	addi	sp,sp,-48
    80003940:	f406                	sd	ra,40(sp)
    80003942:	f022                	sd	s0,32(sp)
    80003944:	ec26                	sd	s1,24(sp)
    80003946:	e84a                	sd	s2,16(sp)
    80003948:	e44e                	sd	s3,8(sp)
    8000394a:	1800                	addi	s0,sp,48
    8000394c:	89aa                	mv	s3,a0
    8000394e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003950:	00014517          	auipc	a0,0x14
    80003954:	08050513          	addi	a0,a0,128 # 800179d0 <bcache>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	28c080e7          	jalr	652(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003960:	0001c497          	auipc	s1,0x1c
    80003964:	3284b483          	ld	s1,808(s1) # 8001fc88 <bcache+0x82b8>
    80003968:	0001c797          	auipc	a5,0x1c
    8000396c:	2d078793          	addi	a5,a5,720 # 8001fc38 <bcache+0x8268>
    80003970:	02f48f63          	beq	s1,a5,800039ae <bread+0x70>
    80003974:	873e                	mv	a4,a5
    80003976:	a021                	j	8000397e <bread+0x40>
    80003978:	68a4                	ld	s1,80(s1)
    8000397a:	02e48a63          	beq	s1,a4,800039ae <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000397e:	449c                	lw	a5,8(s1)
    80003980:	ff379ce3          	bne	a5,s3,80003978 <bread+0x3a>
    80003984:	44dc                	lw	a5,12(s1)
    80003986:	ff2799e3          	bne	a5,s2,80003978 <bread+0x3a>
      b->refcnt++;
    8000398a:	40bc                	lw	a5,64(s1)
    8000398c:	2785                	addiw	a5,a5,1
    8000398e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003990:	00014517          	auipc	a0,0x14
    80003994:	04050513          	addi	a0,a0,64 # 800179d0 <bcache>
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	300080e7          	jalr	768(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800039a0:	01048513          	addi	a0,s1,16
    800039a4:	00001097          	auipc	ra,0x1
    800039a8:	466080e7          	jalr	1126(ra) # 80004e0a <acquiresleep>
      return b;
    800039ac:	a8b9                	j	80003a0a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800039ae:	0001c497          	auipc	s1,0x1c
    800039b2:	2d24b483          	ld	s1,722(s1) # 8001fc80 <bcache+0x82b0>
    800039b6:	0001c797          	auipc	a5,0x1c
    800039ba:	28278793          	addi	a5,a5,642 # 8001fc38 <bcache+0x8268>
    800039be:	00f48863          	beq	s1,a5,800039ce <bread+0x90>
    800039c2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800039c4:	40bc                	lw	a5,64(s1)
    800039c6:	cf81                	beqz	a5,800039de <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800039c8:	64a4                	ld	s1,72(s1)
    800039ca:	fee49de3          	bne	s1,a4,800039c4 <bread+0x86>
  panic("bget: no buffers");
    800039ce:	00005517          	auipc	a0,0x5
    800039d2:	ca250513          	addi	a0,a0,-862 # 80008670 <syscalls+0xd0>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	b68080e7          	jalr	-1176(ra) # 8000053e <panic>
      b->dev = dev;
    800039de:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800039e2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800039e6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800039ea:	4785                	li	a5,1
    800039ec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800039ee:	00014517          	auipc	a0,0x14
    800039f2:	fe250513          	addi	a0,a0,-30 # 800179d0 <bcache>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	2a2080e7          	jalr	674(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800039fe:	01048513          	addi	a0,s1,16
    80003a02:	00001097          	auipc	ra,0x1
    80003a06:	408080e7          	jalr	1032(ra) # 80004e0a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003a0a:	409c                	lw	a5,0(s1)
    80003a0c:	cb89                	beqz	a5,80003a1e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003a0e:	8526                	mv	a0,s1
    80003a10:	70a2                	ld	ra,40(sp)
    80003a12:	7402                	ld	s0,32(sp)
    80003a14:	64e2                	ld	s1,24(sp)
    80003a16:	6942                	ld	s2,16(sp)
    80003a18:	69a2                	ld	s3,8(sp)
    80003a1a:	6145                	addi	sp,sp,48
    80003a1c:	8082                	ret
    virtio_disk_rw(b, 0);
    80003a1e:	4581                	li	a1,0
    80003a20:	8526                	mv	a0,s1
    80003a22:	00003097          	auipc	ra,0x3
    80003a26:	f14080e7          	jalr	-236(ra) # 80006936 <virtio_disk_rw>
    b->valid = 1;
    80003a2a:	4785                	li	a5,1
    80003a2c:	c09c                	sw	a5,0(s1)
  return b;
    80003a2e:	b7c5                	j	80003a0e <bread+0xd0>

0000000080003a30 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003a30:	1101                	addi	sp,sp,-32
    80003a32:	ec06                	sd	ra,24(sp)
    80003a34:	e822                	sd	s0,16(sp)
    80003a36:	e426                	sd	s1,8(sp)
    80003a38:	1000                	addi	s0,sp,32
    80003a3a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a3c:	0541                	addi	a0,a0,16
    80003a3e:	00001097          	auipc	ra,0x1
    80003a42:	466080e7          	jalr	1126(ra) # 80004ea4 <holdingsleep>
    80003a46:	cd01                	beqz	a0,80003a5e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003a48:	4585                	li	a1,1
    80003a4a:	8526                	mv	a0,s1
    80003a4c:	00003097          	auipc	ra,0x3
    80003a50:	eea080e7          	jalr	-278(ra) # 80006936 <virtio_disk_rw>
}
    80003a54:	60e2                	ld	ra,24(sp)
    80003a56:	6442                	ld	s0,16(sp)
    80003a58:	64a2                	ld	s1,8(sp)
    80003a5a:	6105                	addi	sp,sp,32
    80003a5c:	8082                	ret
    panic("bwrite");
    80003a5e:	00005517          	auipc	a0,0x5
    80003a62:	c2a50513          	addi	a0,a0,-982 # 80008688 <syscalls+0xe8>
    80003a66:	ffffd097          	auipc	ra,0xffffd
    80003a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080003a6e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003a6e:	1101                	addi	sp,sp,-32
    80003a70:	ec06                	sd	ra,24(sp)
    80003a72:	e822                	sd	s0,16(sp)
    80003a74:	e426                	sd	s1,8(sp)
    80003a76:	e04a                	sd	s2,0(sp)
    80003a78:	1000                	addi	s0,sp,32
    80003a7a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a7c:	01050913          	addi	s2,a0,16
    80003a80:	854a                	mv	a0,s2
    80003a82:	00001097          	auipc	ra,0x1
    80003a86:	422080e7          	jalr	1058(ra) # 80004ea4 <holdingsleep>
    80003a8a:	c92d                	beqz	a0,80003afc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003a8c:	854a                	mv	a0,s2
    80003a8e:	00001097          	auipc	ra,0x1
    80003a92:	3d2080e7          	jalr	978(ra) # 80004e60 <releasesleep>

  acquire(&bcache.lock);
    80003a96:	00014517          	auipc	a0,0x14
    80003a9a:	f3a50513          	addi	a0,a0,-198 # 800179d0 <bcache>
    80003a9e:	ffffd097          	auipc	ra,0xffffd
    80003aa2:	146080e7          	jalr	326(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003aa6:	40bc                	lw	a5,64(s1)
    80003aa8:	37fd                	addiw	a5,a5,-1
    80003aaa:	0007871b          	sext.w	a4,a5
    80003aae:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003ab0:	eb05                	bnez	a4,80003ae0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003ab2:	68bc                	ld	a5,80(s1)
    80003ab4:	64b8                	ld	a4,72(s1)
    80003ab6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003ab8:	64bc                	ld	a5,72(s1)
    80003aba:	68b8                	ld	a4,80(s1)
    80003abc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003abe:	0001c797          	auipc	a5,0x1c
    80003ac2:	f1278793          	addi	a5,a5,-238 # 8001f9d0 <bcache+0x8000>
    80003ac6:	2b87b703          	ld	a4,696(a5)
    80003aca:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003acc:	0001c717          	auipc	a4,0x1c
    80003ad0:	16c70713          	addi	a4,a4,364 # 8001fc38 <bcache+0x8268>
    80003ad4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003ad6:	2b87b703          	ld	a4,696(a5)
    80003ada:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003adc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003ae0:	00014517          	auipc	a0,0x14
    80003ae4:	ef050513          	addi	a0,a0,-272 # 800179d0 <bcache>
    80003ae8:	ffffd097          	auipc	ra,0xffffd
    80003aec:	1b0080e7          	jalr	432(ra) # 80000c98 <release>
}
    80003af0:	60e2                	ld	ra,24(sp)
    80003af2:	6442                	ld	s0,16(sp)
    80003af4:	64a2                	ld	s1,8(sp)
    80003af6:	6902                	ld	s2,0(sp)
    80003af8:	6105                	addi	sp,sp,32
    80003afa:	8082                	ret
    panic("brelse");
    80003afc:	00005517          	auipc	a0,0x5
    80003b00:	b9450513          	addi	a0,a0,-1132 # 80008690 <syscalls+0xf0>
    80003b04:	ffffd097          	auipc	ra,0xffffd
    80003b08:	a3a080e7          	jalr	-1478(ra) # 8000053e <panic>

0000000080003b0c <bpin>:

void
bpin(struct buf *b) {
    80003b0c:	1101                	addi	sp,sp,-32
    80003b0e:	ec06                	sd	ra,24(sp)
    80003b10:	e822                	sd	s0,16(sp)
    80003b12:	e426                	sd	s1,8(sp)
    80003b14:	1000                	addi	s0,sp,32
    80003b16:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b18:	00014517          	auipc	a0,0x14
    80003b1c:	eb850513          	addi	a0,a0,-328 # 800179d0 <bcache>
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	0c4080e7          	jalr	196(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003b28:	40bc                	lw	a5,64(s1)
    80003b2a:	2785                	addiw	a5,a5,1
    80003b2c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b2e:	00014517          	auipc	a0,0x14
    80003b32:	ea250513          	addi	a0,a0,-350 # 800179d0 <bcache>
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	162080e7          	jalr	354(ra) # 80000c98 <release>
}
    80003b3e:	60e2                	ld	ra,24(sp)
    80003b40:	6442                	ld	s0,16(sp)
    80003b42:	64a2                	ld	s1,8(sp)
    80003b44:	6105                	addi	sp,sp,32
    80003b46:	8082                	ret

0000000080003b48 <bunpin>:

void
bunpin(struct buf *b) {
    80003b48:	1101                	addi	sp,sp,-32
    80003b4a:	ec06                	sd	ra,24(sp)
    80003b4c:	e822                	sd	s0,16(sp)
    80003b4e:	e426                	sd	s1,8(sp)
    80003b50:	1000                	addi	s0,sp,32
    80003b52:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b54:	00014517          	auipc	a0,0x14
    80003b58:	e7c50513          	addi	a0,a0,-388 # 800179d0 <bcache>
    80003b5c:	ffffd097          	auipc	ra,0xffffd
    80003b60:	088080e7          	jalr	136(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003b64:	40bc                	lw	a5,64(s1)
    80003b66:	37fd                	addiw	a5,a5,-1
    80003b68:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b6a:	00014517          	auipc	a0,0x14
    80003b6e:	e6650513          	addi	a0,a0,-410 # 800179d0 <bcache>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	126080e7          	jalr	294(ra) # 80000c98 <release>
}
    80003b7a:	60e2                	ld	ra,24(sp)
    80003b7c:	6442                	ld	s0,16(sp)
    80003b7e:	64a2                	ld	s1,8(sp)
    80003b80:	6105                	addi	sp,sp,32
    80003b82:	8082                	ret

0000000080003b84 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003b84:	1101                	addi	sp,sp,-32
    80003b86:	ec06                	sd	ra,24(sp)
    80003b88:	e822                	sd	s0,16(sp)
    80003b8a:	e426                	sd	s1,8(sp)
    80003b8c:	e04a                	sd	s2,0(sp)
    80003b8e:	1000                	addi	s0,sp,32
    80003b90:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003b92:	00d5d59b          	srliw	a1,a1,0xd
    80003b96:	0001c797          	auipc	a5,0x1c
    80003b9a:	5167a783          	lw	a5,1302(a5) # 800200ac <sb+0x1c>
    80003b9e:	9dbd                	addw	a1,a1,a5
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	d9e080e7          	jalr	-610(ra) # 8000393e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003ba8:	0074f713          	andi	a4,s1,7
    80003bac:	4785                	li	a5,1
    80003bae:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003bb2:	14ce                	slli	s1,s1,0x33
    80003bb4:	90d9                	srli	s1,s1,0x36
    80003bb6:	00950733          	add	a4,a0,s1
    80003bba:	05874703          	lbu	a4,88(a4)
    80003bbe:	00e7f6b3          	and	a3,a5,a4
    80003bc2:	c69d                	beqz	a3,80003bf0 <bfree+0x6c>
    80003bc4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003bc6:	94aa                	add	s1,s1,a0
    80003bc8:	fff7c793          	not	a5,a5
    80003bcc:	8ff9                	and	a5,a5,a4
    80003bce:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003bd2:	00001097          	auipc	ra,0x1
    80003bd6:	118080e7          	jalr	280(ra) # 80004cea <log_write>
  brelse(bp);
    80003bda:	854a                	mv	a0,s2
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	e92080e7          	jalr	-366(ra) # 80003a6e <brelse>
}
    80003be4:	60e2                	ld	ra,24(sp)
    80003be6:	6442                	ld	s0,16(sp)
    80003be8:	64a2                	ld	s1,8(sp)
    80003bea:	6902                	ld	s2,0(sp)
    80003bec:	6105                	addi	sp,sp,32
    80003bee:	8082                	ret
    panic("freeing free block");
    80003bf0:	00005517          	auipc	a0,0x5
    80003bf4:	aa850513          	addi	a0,a0,-1368 # 80008698 <syscalls+0xf8>
    80003bf8:	ffffd097          	auipc	ra,0xffffd
    80003bfc:	946080e7          	jalr	-1722(ra) # 8000053e <panic>

0000000080003c00 <balloc>:
{
    80003c00:	711d                	addi	sp,sp,-96
    80003c02:	ec86                	sd	ra,88(sp)
    80003c04:	e8a2                	sd	s0,80(sp)
    80003c06:	e4a6                	sd	s1,72(sp)
    80003c08:	e0ca                	sd	s2,64(sp)
    80003c0a:	fc4e                	sd	s3,56(sp)
    80003c0c:	f852                	sd	s4,48(sp)
    80003c0e:	f456                	sd	s5,40(sp)
    80003c10:	f05a                	sd	s6,32(sp)
    80003c12:	ec5e                	sd	s7,24(sp)
    80003c14:	e862                	sd	s8,16(sp)
    80003c16:	e466                	sd	s9,8(sp)
    80003c18:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003c1a:	0001c797          	auipc	a5,0x1c
    80003c1e:	47a7a783          	lw	a5,1146(a5) # 80020094 <sb+0x4>
    80003c22:	cbd1                	beqz	a5,80003cb6 <balloc+0xb6>
    80003c24:	8baa                	mv	s7,a0
    80003c26:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003c28:	0001cb17          	auipc	s6,0x1c
    80003c2c:	468b0b13          	addi	s6,s6,1128 # 80020090 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c30:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003c32:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c34:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003c36:	6c89                	lui	s9,0x2
    80003c38:	a831                	j	80003c54 <balloc+0x54>
    brelse(bp);
    80003c3a:	854a                	mv	a0,s2
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	e32080e7          	jalr	-462(ra) # 80003a6e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003c44:	015c87bb          	addw	a5,s9,s5
    80003c48:	00078a9b          	sext.w	s5,a5
    80003c4c:	004b2703          	lw	a4,4(s6)
    80003c50:	06eaf363          	bgeu	s5,a4,80003cb6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003c54:	41fad79b          	sraiw	a5,s5,0x1f
    80003c58:	0137d79b          	srliw	a5,a5,0x13
    80003c5c:	015787bb          	addw	a5,a5,s5
    80003c60:	40d7d79b          	sraiw	a5,a5,0xd
    80003c64:	01cb2583          	lw	a1,28(s6)
    80003c68:	9dbd                	addw	a1,a1,a5
    80003c6a:	855e                	mv	a0,s7
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	cd2080e7          	jalr	-814(ra) # 8000393e <bread>
    80003c74:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c76:	004b2503          	lw	a0,4(s6)
    80003c7a:	000a849b          	sext.w	s1,s5
    80003c7e:	8662                	mv	a2,s8
    80003c80:	faa4fde3          	bgeu	s1,a0,80003c3a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003c84:	41f6579b          	sraiw	a5,a2,0x1f
    80003c88:	01d7d69b          	srliw	a3,a5,0x1d
    80003c8c:	00c6873b          	addw	a4,a3,a2
    80003c90:	00777793          	andi	a5,a4,7
    80003c94:	9f95                	subw	a5,a5,a3
    80003c96:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003c9a:	4037571b          	sraiw	a4,a4,0x3
    80003c9e:	00e906b3          	add	a3,s2,a4
    80003ca2:	0586c683          	lbu	a3,88(a3)
    80003ca6:	00d7f5b3          	and	a1,a5,a3
    80003caa:	cd91                	beqz	a1,80003cc6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003cac:	2605                	addiw	a2,a2,1
    80003cae:	2485                	addiw	s1,s1,1
    80003cb0:	fd4618e3          	bne	a2,s4,80003c80 <balloc+0x80>
    80003cb4:	b759                	j	80003c3a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003cb6:	00005517          	auipc	a0,0x5
    80003cba:	9fa50513          	addi	a0,a0,-1542 # 800086b0 <syscalls+0x110>
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	880080e7          	jalr	-1920(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003cc6:	974a                	add	a4,a4,s2
    80003cc8:	8fd5                	or	a5,a5,a3
    80003cca:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003cce:	854a                	mv	a0,s2
    80003cd0:	00001097          	auipc	ra,0x1
    80003cd4:	01a080e7          	jalr	26(ra) # 80004cea <log_write>
        brelse(bp);
    80003cd8:	854a                	mv	a0,s2
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	d94080e7          	jalr	-620(ra) # 80003a6e <brelse>
  bp = bread(dev, bno);
    80003ce2:	85a6                	mv	a1,s1
    80003ce4:	855e                	mv	a0,s7
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	c58080e7          	jalr	-936(ra) # 8000393e <bread>
    80003cee:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003cf0:	40000613          	li	a2,1024
    80003cf4:	4581                	li	a1,0
    80003cf6:	05850513          	addi	a0,a0,88
    80003cfa:	ffffd097          	auipc	ra,0xffffd
    80003cfe:	fe6080e7          	jalr	-26(ra) # 80000ce0 <memset>
  log_write(bp);
    80003d02:	854a                	mv	a0,s2
    80003d04:	00001097          	auipc	ra,0x1
    80003d08:	fe6080e7          	jalr	-26(ra) # 80004cea <log_write>
  brelse(bp);
    80003d0c:	854a                	mv	a0,s2
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	d60080e7          	jalr	-672(ra) # 80003a6e <brelse>
}
    80003d16:	8526                	mv	a0,s1
    80003d18:	60e6                	ld	ra,88(sp)
    80003d1a:	6446                	ld	s0,80(sp)
    80003d1c:	64a6                	ld	s1,72(sp)
    80003d1e:	6906                	ld	s2,64(sp)
    80003d20:	79e2                	ld	s3,56(sp)
    80003d22:	7a42                	ld	s4,48(sp)
    80003d24:	7aa2                	ld	s5,40(sp)
    80003d26:	7b02                	ld	s6,32(sp)
    80003d28:	6be2                	ld	s7,24(sp)
    80003d2a:	6c42                	ld	s8,16(sp)
    80003d2c:	6ca2                	ld	s9,8(sp)
    80003d2e:	6125                	addi	sp,sp,96
    80003d30:	8082                	ret

0000000080003d32 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003d32:	7179                	addi	sp,sp,-48
    80003d34:	f406                	sd	ra,40(sp)
    80003d36:	f022                	sd	s0,32(sp)
    80003d38:	ec26                	sd	s1,24(sp)
    80003d3a:	e84a                	sd	s2,16(sp)
    80003d3c:	e44e                	sd	s3,8(sp)
    80003d3e:	e052                	sd	s4,0(sp)
    80003d40:	1800                	addi	s0,sp,48
    80003d42:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003d44:	47ad                	li	a5,11
    80003d46:	04b7fe63          	bgeu	a5,a1,80003da2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003d4a:	ff45849b          	addiw	s1,a1,-12
    80003d4e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003d52:	0ff00793          	li	a5,255
    80003d56:	0ae7e363          	bltu	a5,a4,80003dfc <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003d5a:	08052583          	lw	a1,128(a0)
    80003d5e:	c5ad                	beqz	a1,80003dc8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003d60:	00092503          	lw	a0,0(s2)
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	bda080e7          	jalr	-1062(ra) # 8000393e <bread>
    80003d6c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003d6e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003d72:	02049593          	slli	a1,s1,0x20
    80003d76:	9181                	srli	a1,a1,0x20
    80003d78:	058a                	slli	a1,a1,0x2
    80003d7a:	00b784b3          	add	s1,a5,a1
    80003d7e:	0004a983          	lw	s3,0(s1)
    80003d82:	04098d63          	beqz	s3,80003ddc <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003d86:	8552                	mv	a0,s4
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	ce6080e7          	jalr	-794(ra) # 80003a6e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003d90:	854e                	mv	a0,s3
    80003d92:	70a2                	ld	ra,40(sp)
    80003d94:	7402                	ld	s0,32(sp)
    80003d96:	64e2                	ld	s1,24(sp)
    80003d98:	6942                	ld	s2,16(sp)
    80003d9a:	69a2                	ld	s3,8(sp)
    80003d9c:	6a02                	ld	s4,0(sp)
    80003d9e:	6145                	addi	sp,sp,48
    80003da0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003da2:	02059493          	slli	s1,a1,0x20
    80003da6:	9081                	srli	s1,s1,0x20
    80003da8:	048a                	slli	s1,s1,0x2
    80003daa:	94aa                	add	s1,s1,a0
    80003dac:	0504a983          	lw	s3,80(s1)
    80003db0:	fe0990e3          	bnez	s3,80003d90 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003db4:	4108                	lw	a0,0(a0)
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	e4a080e7          	jalr	-438(ra) # 80003c00 <balloc>
    80003dbe:	0005099b          	sext.w	s3,a0
    80003dc2:	0534a823          	sw	s3,80(s1)
    80003dc6:	b7e9                	j	80003d90 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003dc8:	4108                	lw	a0,0(a0)
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	e36080e7          	jalr	-458(ra) # 80003c00 <balloc>
    80003dd2:	0005059b          	sext.w	a1,a0
    80003dd6:	08b92023          	sw	a1,128(s2)
    80003dda:	b759                	j	80003d60 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003ddc:	00092503          	lw	a0,0(s2)
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	e20080e7          	jalr	-480(ra) # 80003c00 <balloc>
    80003de8:	0005099b          	sext.w	s3,a0
    80003dec:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003df0:	8552                	mv	a0,s4
    80003df2:	00001097          	auipc	ra,0x1
    80003df6:	ef8080e7          	jalr	-264(ra) # 80004cea <log_write>
    80003dfa:	b771                	j	80003d86 <bmap+0x54>
  panic("bmap: out of range");
    80003dfc:	00005517          	auipc	a0,0x5
    80003e00:	8cc50513          	addi	a0,a0,-1844 # 800086c8 <syscalls+0x128>
    80003e04:	ffffc097          	auipc	ra,0xffffc
    80003e08:	73a080e7          	jalr	1850(ra) # 8000053e <panic>

0000000080003e0c <iget>:
{
    80003e0c:	7179                	addi	sp,sp,-48
    80003e0e:	f406                	sd	ra,40(sp)
    80003e10:	f022                	sd	s0,32(sp)
    80003e12:	ec26                	sd	s1,24(sp)
    80003e14:	e84a                	sd	s2,16(sp)
    80003e16:	e44e                	sd	s3,8(sp)
    80003e18:	e052                	sd	s4,0(sp)
    80003e1a:	1800                	addi	s0,sp,48
    80003e1c:	89aa                	mv	s3,a0
    80003e1e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003e20:	0001c517          	auipc	a0,0x1c
    80003e24:	29050513          	addi	a0,a0,656 # 800200b0 <itable>
    80003e28:	ffffd097          	auipc	ra,0xffffd
    80003e2c:	dbc080e7          	jalr	-580(ra) # 80000be4 <acquire>
  empty = 0;
    80003e30:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e32:	0001c497          	auipc	s1,0x1c
    80003e36:	29648493          	addi	s1,s1,662 # 800200c8 <itable+0x18>
    80003e3a:	0001e697          	auipc	a3,0x1e
    80003e3e:	d1e68693          	addi	a3,a3,-738 # 80021b58 <log>
    80003e42:	a039                	j	80003e50 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e44:	02090b63          	beqz	s2,80003e7a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003e48:	08848493          	addi	s1,s1,136
    80003e4c:	02d48a63          	beq	s1,a3,80003e80 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003e50:	449c                	lw	a5,8(s1)
    80003e52:	fef059e3          	blez	a5,80003e44 <iget+0x38>
    80003e56:	4098                	lw	a4,0(s1)
    80003e58:	ff3716e3          	bne	a4,s3,80003e44 <iget+0x38>
    80003e5c:	40d8                	lw	a4,4(s1)
    80003e5e:	ff4713e3          	bne	a4,s4,80003e44 <iget+0x38>
      ip->ref++;
    80003e62:	2785                	addiw	a5,a5,1
    80003e64:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003e66:	0001c517          	auipc	a0,0x1c
    80003e6a:	24a50513          	addi	a0,a0,586 # 800200b0 <itable>
    80003e6e:	ffffd097          	auipc	ra,0xffffd
    80003e72:	e2a080e7          	jalr	-470(ra) # 80000c98 <release>
      return ip;
    80003e76:	8926                	mv	s2,s1
    80003e78:	a03d                	j	80003ea6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e7a:	f7f9                	bnez	a5,80003e48 <iget+0x3c>
    80003e7c:	8926                	mv	s2,s1
    80003e7e:	b7e9                	j	80003e48 <iget+0x3c>
  if(empty == 0)
    80003e80:	02090c63          	beqz	s2,80003eb8 <iget+0xac>
  ip->dev = dev;
    80003e84:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003e88:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003e8c:	4785                	li	a5,1
    80003e8e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003e92:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003e96:	0001c517          	auipc	a0,0x1c
    80003e9a:	21a50513          	addi	a0,a0,538 # 800200b0 <itable>
    80003e9e:	ffffd097          	auipc	ra,0xffffd
    80003ea2:	dfa080e7          	jalr	-518(ra) # 80000c98 <release>
}
    80003ea6:	854a                	mv	a0,s2
    80003ea8:	70a2                	ld	ra,40(sp)
    80003eaa:	7402                	ld	s0,32(sp)
    80003eac:	64e2                	ld	s1,24(sp)
    80003eae:	6942                	ld	s2,16(sp)
    80003eb0:	69a2                	ld	s3,8(sp)
    80003eb2:	6a02                	ld	s4,0(sp)
    80003eb4:	6145                	addi	sp,sp,48
    80003eb6:	8082                	ret
    panic("iget: no inodes");
    80003eb8:	00005517          	auipc	a0,0x5
    80003ebc:	82850513          	addi	a0,a0,-2008 # 800086e0 <syscalls+0x140>
    80003ec0:	ffffc097          	auipc	ra,0xffffc
    80003ec4:	67e080e7          	jalr	1662(ra) # 8000053e <panic>

0000000080003ec8 <fsinit>:
fsinit(int dev) {
    80003ec8:	7179                	addi	sp,sp,-48
    80003eca:	f406                	sd	ra,40(sp)
    80003ecc:	f022                	sd	s0,32(sp)
    80003ece:	ec26                	sd	s1,24(sp)
    80003ed0:	e84a                	sd	s2,16(sp)
    80003ed2:	e44e                	sd	s3,8(sp)
    80003ed4:	1800                	addi	s0,sp,48
    80003ed6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ed8:	4585                	li	a1,1
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	a64080e7          	jalr	-1436(ra) # 8000393e <bread>
    80003ee2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ee4:	0001c997          	auipc	s3,0x1c
    80003ee8:	1ac98993          	addi	s3,s3,428 # 80020090 <sb>
    80003eec:	02000613          	li	a2,32
    80003ef0:	05850593          	addi	a1,a0,88
    80003ef4:	854e                	mv	a0,s3
    80003ef6:	ffffd097          	auipc	ra,0xffffd
    80003efa:	e4a080e7          	jalr	-438(ra) # 80000d40 <memmove>
  brelse(bp);
    80003efe:	8526                	mv	a0,s1
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	b6e080e7          	jalr	-1170(ra) # 80003a6e <brelse>
  if(sb.magic != FSMAGIC)
    80003f08:	0009a703          	lw	a4,0(s3)
    80003f0c:	102037b7          	lui	a5,0x10203
    80003f10:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003f14:	02f71263          	bne	a4,a5,80003f38 <fsinit+0x70>
  initlog(dev, &sb);
    80003f18:	0001c597          	auipc	a1,0x1c
    80003f1c:	17858593          	addi	a1,a1,376 # 80020090 <sb>
    80003f20:	854a                	mv	a0,s2
    80003f22:	00001097          	auipc	ra,0x1
    80003f26:	b4c080e7          	jalr	-1204(ra) # 80004a6e <initlog>
}
    80003f2a:	70a2                	ld	ra,40(sp)
    80003f2c:	7402                	ld	s0,32(sp)
    80003f2e:	64e2                	ld	s1,24(sp)
    80003f30:	6942                	ld	s2,16(sp)
    80003f32:	69a2                	ld	s3,8(sp)
    80003f34:	6145                	addi	sp,sp,48
    80003f36:	8082                	ret
    panic("invalid file system");
    80003f38:	00004517          	auipc	a0,0x4
    80003f3c:	7b850513          	addi	a0,a0,1976 # 800086f0 <syscalls+0x150>
    80003f40:	ffffc097          	auipc	ra,0xffffc
    80003f44:	5fe080e7          	jalr	1534(ra) # 8000053e <panic>

0000000080003f48 <iinit>:
{
    80003f48:	7179                	addi	sp,sp,-48
    80003f4a:	f406                	sd	ra,40(sp)
    80003f4c:	f022                	sd	s0,32(sp)
    80003f4e:	ec26                	sd	s1,24(sp)
    80003f50:	e84a                	sd	s2,16(sp)
    80003f52:	e44e                	sd	s3,8(sp)
    80003f54:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003f56:	00004597          	auipc	a1,0x4
    80003f5a:	7b258593          	addi	a1,a1,1970 # 80008708 <syscalls+0x168>
    80003f5e:	0001c517          	auipc	a0,0x1c
    80003f62:	15250513          	addi	a0,a0,338 # 800200b0 <itable>
    80003f66:	ffffd097          	auipc	ra,0xffffd
    80003f6a:	bee080e7          	jalr	-1042(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003f6e:	0001c497          	auipc	s1,0x1c
    80003f72:	16a48493          	addi	s1,s1,362 # 800200d8 <itable+0x28>
    80003f76:	0001e997          	auipc	s3,0x1e
    80003f7a:	bf298993          	addi	s3,s3,-1038 # 80021b68 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003f7e:	00004917          	auipc	s2,0x4
    80003f82:	79290913          	addi	s2,s2,1938 # 80008710 <syscalls+0x170>
    80003f86:	85ca                	mv	a1,s2
    80003f88:	8526                	mv	a0,s1
    80003f8a:	00001097          	auipc	ra,0x1
    80003f8e:	e46080e7          	jalr	-442(ra) # 80004dd0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003f92:	08848493          	addi	s1,s1,136
    80003f96:	ff3498e3          	bne	s1,s3,80003f86 <iinit+0x3e>
}
    80003f9a:	70a2                	ld	ra,40(sp)
    80003f9c:	7402                	ld	s0,32(sp)
    80003f9e:	64e2                	ld	s1,24(sp)
    80003fa0:	6942                	ld	s2,16(sp)
    80003fa2:	69a2                	ld	s3,8(sp)
    80003fa4:	6145                	addi	sp,sp,48
    80003fa6:	8082                	ret

0000000080003fa8 <ialloc>:
{
    80003fa8:	715d                	addi	sp,sp,-80
    80003faa:	e486                	sd	ra,72(sp)
    80003fac:	e0a2                	sd	s0,64(sp)
    80003fae:	fc26                	sd	s1,56(sp)
    80003fb0:	f84a                	sd	s2,48(sp)
    80003fb2:	f44e                	sd	s3,40(sp)
    80003fb4:	f052                	sd	s4,32(sp)
    80003fb6:	ec56                	sd	s5,24(sp)
    80003fb8:	e85a                	sd	s6,16(sp)
    80003fba:	e45e                	sd	s7,8(sp)
    80003fbc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003fbe:	0001c717          	auipc	a4,0x1c
    80003fc2:	0de72703          	lw	a4,222(a4) # 8002009c <sb+0xc>
    80003fc6:	4785                	li	a5,1
    80003fc8:	04e7fa63          	bgeu	a5,a4,8000401c <ialloc+0x74>
    80003fcc:	8aaa                	mv	s5,a0
    80003fce:	8bae                	mv	s7,a1
    80003fd0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003fd2:	0001ca17          	auipc	s4,0x1c
    80003fd6:	0bea0a13          	addi	s4,s4,190 # 80020090 <sb>
    80003fda:	00048b1b          	sext.w	s6,s1
    80003fde:	0044d593          	srli	a1,s1,0x4
    80003fe2:	018a2783          	lw	a5,24(s4)
    80003fe6:	9dbd                	addw	a1,a1,a5
    80003fe8:	8556                	mv	a0,s5
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	954080e7          	jalr	-1708(ra) # 8000393e <bread>
    80003ff2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ff4:	05850993          	addi	s3,a0,88
    80003ff8:	00f4f793          	andi	a5,s1,15
    80003ffc:	079a                	slli	a5,a5,0x6
    80003ffe:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004000:	00099783          	lh	a5,0(s3)
    80004004:	c785                	beqz	a5,8000402c <ialloc+0x84>
    brelse(bp);
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	a68080e7          	jalr	-1432(ra) # 80003a6e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000400e:	0485                	addi	s1,s1,1
    80004010:	00ca2703          	lw	a4,12(s4)
    80004014:	0004879b          	sext.w	a5,s1
    80004018:	fce7e1e3          	bltu	a5,a4,80003fda <ialloc+0x32>
  panic("ialloc: no inodes");
    8000401c:	00004517          	auipc	a0,0x4
    80004020:	6fc50513          	addi	a0,a0,1788 # 80008718 <syscalls+0x178>
    80004024:	ffffc097          	auipc	ra,0xffffc
    80004028:	51a080e7          	jalr	1306(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000402c:	04000613          	li	a2,64
    80004030:	4581                	li	a1,0
    80004032:	854e                	mv	a0,s3
    80004034:	ffffd097          	auipc	ra,0xffffd
    80004038:	cac080e7          	jalr	-852(ra) # 80000ce0 <memset>
      dip->type = type;
    8000403c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004040:	854a                	mv	a0,s2
    80004042:	00001097          	auipc	ra,0x1
    80004046:	ca8080e7          	jalr	-856(ra) # 80004cea <log_write>
      brelse(bp);
    8000404a:	854a                	mv	a0,s2
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	a22080e7          	jalr	-1502(ra) # 80003a6e <brelse>
      return iget(dev, inum);
    80004054:	85da                	mv	a1,s6
    80004056:	8556                	mv	a0,s5
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	db4080e7          	jalr	-588(ra) # 80003e0c <iget>
}
    80004060:	60a6                	ld	ra,72(sp)
    80004062:	6406                	ld	s0,64(sp)
    80004064:	74e2                	ld	s1,56(sp)
    80004066:	7942                	ld	s2,48(sp)
    80004068:	79a2                	ld	s3,40(sp)
    8000406a:	7a02                	ld	s4,32(sp)
    8000406c:	6ae2                	ld	s5,24(sp)
    8000406e:	6b42                	ld	s6,16(sp)
    80004070:	6ba2                	ld	s7,8(sp)
    80004072:	6161                	addi	sp,sp,80
    80004074:	8082                	ret

0000000080004076 <iupdate>:
{
    80004076:	1101                	addi	sp,sp,-32
    80004078:	ec06                	sd	ra,24(sp)
    8000407a:	e822                	sd	s0,16(sp)
    8000407c:	e426                	sd	s1,8(sp)
    8000407e:	e04a                	sd	s2,0(sp)
    80004080:	1000                	addi	s0,sp,32
    80004082:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004084:	415c                	lw	a5,4(a0)
    80004086:	0047d79b          	srliw	a5,a5,0x4
    8000408a:	0001c597          	auipc	a1,0x1c
    8000408e:	01e5a583          	lw	a1,30(a1) # 800200a8 <sb+0x18>
    80004092:	9dbd                	addw	a1,a1,a5
    80004094:	4108                	lw	a0,0(a0)
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	8a8080e7          	jalr	-1880(ra) # 8000393e <bread>
    8000409e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800040a0:	05850793          	addi	a5,a0,88
    800040a4:	40c8                	lw	a0,4(s1)
    800040a6:	893d                	andi	a0,a0,15
    800040a8:	051a                	slli	a0,a0,0x6
    800040aa:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800040ac:	04449703          	lh	a4,68(s1)
    800040b0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800040b4:	04649703          	lh	a4,70(s1)
    800040b8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800040bc:	04849703          	lh	a4,72(s1)
    800040c0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800040c4:	04a49703          	lh	a4,74(s1)
    800040c8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800040cc:	44f8                	lw	a4,76(s1)
    800040ce:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800040d0:	03400613          	li	a2,52
    800040d4:	05048593          	addi	a1,s1,80
    800040d8:	0531                	addi	a0,a0,12
    800040da:	ffffd097          	auipc	ra,0xffffd
    800040de:	c66080e7          	jalr	-922(ra) # 80000d40 <memmove>
  log_write(bp);
    800040e2:	854a                	mv	a0,s2
    800040e4:	00001097          	auipc	ra,0x1
    800040e8:	c06080e7          	jalr	-1018(ra) # 80004cea <log_write>
  brelse(bp);
    800040ec:	854a                	mv	a0,s2
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	980080e7          	jalr	-1664(ra) # 80003a6e <brelse>
}
    800040f6:	60e2                	ld	ra,24(sp)
    800040f8:	6442                	ld	s0,16(sp)
    800040fa:	64a2                	ld	s1,8(sp)
    800040fc:	6902                	ld	s2,0(sp)
    800040fe:	6105                	addi	sp,sp,32
    80004100:	8082                	ret

0000000080004102 <idup>:
{
    80004102:	1101                	addi	sp,sp,-32
    80004104:	ec06                	sd	ra,24(sp)
    80004106:	e822                	sd	s0,16(sp)
    80004108:	e426                	sd	s1,8(sp)
    8000410a:	1000                	addi	s0,sp,32
    8000410c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000410e:	0001c517          	auipc	a0,0x1c
    80004112:	fa250513          	addi	a0,a0,-94 # 800200b0 <itable>
    80004116:	ffffd097          	auipc	ra,0xffffd
    8000411a:	ace080e7          	jalr	-1330(ra) # 80000be4 <acquire>
  ip->ref++;
    8000411e:	449c                	lw	a5,8(s1)
    80004120:	2785                	addiw	a5,a5,1
    80004122:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004124:	0001c517          	auipc	a0,0x1c
    80004128:	f8c50513          	addi	a0,a0,-116 # 800200b0 <itable>
    8000412c:	ffffd097          	auipc	ra,0xffffd
    80004130:	b6c080e7          	jalr	-1172(ra) # 80000c98 <release>
}
    80004134:	8526                	mv	a0,s1
    80004136:	60e2                	ld	ra,24(sp)
    80004138:	6442                	ld	s0,16(sp)
    8000413a:	64a2                	ld	s1,8(sp)
    8000413c:	6105                	addi	sp,sp,32
    8000413e:	8082                	ret

0000000080004140 <ilock>:
{
    80004140:	1101                	addi	sp,sp,-32
    80004142:	ec06                	sd	ra,24(sp)
    80004144:	e822                	sd	s0,16(sp)
    80004146:	e426                	sd	s1,8(sp)
    80004148:	e04a                	sd	s2,0(sp)
    8000414a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000414c:	c115                	beqz	a0,80004170 <ilock+0x30>
    8000414e:	84aa                	mv	s1,a0
    80004150:	451c                	lw	a5,8(a0)
    80004152:	00f05f63          	blez	a5,80004170 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004156:	0541                	addi	a0,a0,16
    80004158:	00001097          	auipc	ra,0x1
    8000415c:	cb2080e7          	jalr	-846(ra) # 80004e0a <acquiresleep>
  if(ip->valid == 0){
    80004160:	40bc                	lw	a5,64(s1)
    80004162:	cf99                	beqz	a5,80004180 <ilock+0x40>
}
    80004164:	60e2                	ld	ra,24(sp)
    80004166:	6442                	ld	s0,16(sp)
    80004168:	64a2                	ld	s1,8(sp)
    8000416a:	6902                	ld	s2,0(sp)
    8000416c:	6105                	addi	sp,sp,32
    8000416e:	8082                	ret
    panic("ilock");
    80004170:	00004517          	auipc	a0,0x4
    80004174:	5c050513          	addi	a0,a0,1472 # 80008730 <syscalls+0x190>
    80004178:	ffffc097          	auipc	ra,0xffffc
    8000417c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004180:	40dc                	lw	a5,4(s1)
    80004182:	0047d79b          	srliw	a5,a5,0x4
    80004186:	0001c597          	auipc	a1,0x1c
    8000418a:	f225a583          	lw	a1,-222(a1) # 800200a8 <sb+0x18>
    8000418e:	9dbd                	addw	a1,a1,a5
    80004190:	4088                	lw	a0,0(s1)
    80004192:	fffff097          	auipc	ra,0xfffff
    80004196:	7ac080e7          	jalr	1964(ra) # 8000393e <bread>
    8000419a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000419c:	05850593          	addi	a1,a0,88
    800041a0:	40dc                	lw	a5,4(s1)
    800041a2:	8bbd                	andi	a5,a5,15
    800041a4:	079a                	slli	a5,a5,0x6
    800041a6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800041a8:	00059783          	lh	a5,0(a1)
    800041ac:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800041b0:	00259783          	lh	a5,2(a1)
    800041b4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800041b8:	00459783          	lh	a5,4(a1)
    800041bc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800041c0:	00659783          	lh	a5,6(a1)
    800041c4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800041c8:	459c                	lw	a5,8(a1)
    800041ca:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800041cc:	03400613          	li	a2,52
    800041d0:	05b1                	addi	a1,a1,12
    800041d2:	05048513          	addi	a0,s1,80
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	b6a080e7          	jalr	-1174(ra) # 80000d40 <memmove>
    brelse(bp);
    800041de:	854a                	mv	a0,s2
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	88e080e7          	jalr	-1906(ra) # 80003a6e <brelse>
    ip->valid = 1;
    800041e8:	4785                	li	a5,1
    800041ea:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800041ec:	04449783          	lh	a5,68(s1)
    800041f0:	fbb5                	bnez	a5,80004164 <ilock+0x24>
      panic("ilock: no type");
    800041f2:	00004517          	auipc	a0,0x4
    800041f6:	54650513          	addi	a0,a0,1350 # 80008738 <syscalls+0x198>
    800041fa:	ffffc097          	auipc	ra,0xffffc
    800041fe:	344080e7          	jalr	836(ra) # 8000053e <panic>

0000000080004202 <iunlock>:
{
    80004202:	1101                	addi	sp,sp,-32
    80004204:	ec06                	sd	ra,24(sp)
    80004206:	e822                	sd	s0,16(sp)
    80004208:	e426                	sd	s1,8(sp)
    8000420a:	e04a                	sd	s2,0(sp)
    8000420c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000420e:	c905                	beqz	a0,8000423e <iunlock+0x3c>
    80004210:	84aa                	mv	s1,a0
    80004212:	01050913          	addi	s2,a0,16
    80004216:	854a                	mv	a0,s2
    80004218:	00001097          	auipc	ra,0x1
    8000421c:	c8c080e7          	jalr	-884(ra) # 80004ea4 <holdingsleep>
    80004220:	cd19                	beqz	a0,8000423e <iunlock+0x3c>
    80004222:	449c                	lw	a5,8(s1)
    80004224:	00f05d63          	blez	a5,8000423e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004228:	854a                	mv	a0,s2
    8000422a:	00001097          	auipc	ra,0x1
    8000422e:	c36080e7          	jalr	-970(ra) # 80004e60 <releasesleep>
}
    80004232:	60e2                	ld	ra,24(sp)
    80004234:	6442                	ld	s0,16(sp)
    80004236:	64a2                	ld	s1,8(sp)
    80004238:	6902                	ld	s2,0(sp)
    8000423a:	6105                	addi	sp,sp,32
    8000423c:	8082                	ret
    panic("iunlock");
    8000423e:	00004517          	auipc	a0,0x4
    80004242:	50a50513          	addi	a0,a0,1290 # 80008748 <syscalls+0x1a8>
    80004246:	ffffc097          	auipc	ra,0xffffc
    8000424a:	2f8080e7          	jalr	760(ra) # 8000053e <panic>

000000008000424e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000424e:	7179                	addi	sp,sp,-48
    80004250:	f406                	sd	ra,40(sp)
    80004252:	f022                	sd	s0,32(sp)
    80004254:	ec26                	sd	s1,24(sp)
    80004256:	e84a                	sd	s2,16(sp)
    80004258:	e44e                	sd	s3,8(sp)
    8000425a:	e052                	sd	s4,0(sp)
    8000425c:	1800                	addi	s0,sp,48
    8000425e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004260:	05050493          	addi	s1,a0,80
    80004264:	08050913          	addi	s2,a0,128
    80004268:	a021                	j	80004270 <itrunc+0x22>
    8000426a:	0491                	addi	s1,s1,4
    8000426c:	01248d63          	beq	s1,s2,80004286 <itrunc+0x38>
    if(ip->addrs[i]){
    80004270:	408c                	lw	a1,0(s1)
    80004272:	dde5                	beqz	a1,8000426a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004274:	0009a503          	lw	a0,0(s3)
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	90c080e7          	jalr	-1780(ra) # 80003b84 <bfree>
      ip->addrs[i] = 0;
    80004280:	0004a023          	sw	zero,0(s1)
    80004284:	b7dd                	j	8000426a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004286:	0809a583          	lw	a1,128(s3)
    8000428a:	e185                	bnez	a1,800042aa <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000428c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004290:	854e                	mv	a0,s3
    80004292:	00000097          	auipc	ra,0x0
    80004296:	de4080e7          	jalr	-540(ra) # 80004076 <iupdate>
}
    8000429a:	70a2                	ld	ra,40(sp)
    8000429c:	7402                	ld	s0,32(sp)
    8000429e:	64e2                	ld	s1,24(sp)
    800042a0:	6942                	ld	s2,16(sp)
    800042a2:	69a2                	ld	s3,8(sp)
    800042a4:	6a02                	ld	s4,0(sp)
    800042a6:	6145                	addi	sp,sp,48
    800042a8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800042aa:	0009a503          	lw	a0,0(s3)
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	690080e7          	jalr	1680(ra) # 8000393e <bread>
    800042b6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800042b8:	05850493          	addi	s1,a0,88
    800042bc:	45850913          	addi	s2,a0,1112
    800042c0:	a811                	j	800042d4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800042c2:	0009a503          	lw	a0,0(s3)
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	8be080e7          	jalr	-1858(ra) # 80003b84 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800042ce:	0491                	addi	s1,s1,4
    800042d0:	01248563          	beq	s1,s2,800042da <itrunc+0x8c>
      if(a[j])
    800042d4:	408c                	lw	a1,0(s1)
    800042d6:	dde5                	beqz	a1,800042ce <itrunc+0x80>
    800042d8:	b7ed                	j	800042c2 <itrunc+0x74>
    brelse(bp);
    800042da:	8552                	mv	a0,s4
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	792080e7          	jalr	1938(ra) # 80003a6e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800042e4:	0809a583          	lw	a1,128(s3)
    800042e8:	0009a503          	lw	a0,0(s3)
    800042ec:	00000097          	auipc	ra,0x0
    800042f0:	898080e7          	jalr	-1896(ra) # 80003b84 <bfree>
    ip->addrs[NDIRECT] = 0;
    800042f4:	0809a023          	sw	zero,128(s3)
    800042f8:	bf51                	j	8000428c <itrunc+0x3e>

00000000800042fa <iput>:
{
    800042fa:	1101                	addi	sp,sp,-32
    800042fc:	ec06                	sd	ra,24(sp)
    800042fe:	e822                	sd	s0,16(sp)
    80004300:	e426                	sd	s1,8(sp)
    80004302:	e04a                	sd	s2,0(sp)
    80004304:	1000                	addi	s0,sp,32
    80004306:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004308:	0001c517          	auipc	a0,0x1c
    8000430c:	da850513          	addi	a0,a0,-600 # 800200b0 <itable>
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	8d4080e7          	jalr	-1836(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004318:	4498                	lw	a4,8(s1)
    8000431a:	4785                	li	a5,1
    8000431c:	02f70363          	beq	a4,a5,80004342 <iput+0x48>
  ip->ref--;
    80004320:	449c                	lw	a5,8(s1)
    80004322:	37fd                	addiw	a5,a5,-1
    80004324:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004326:	0001c517          	auipc	a0,0x1c
    8000432a:	d8a50513          	addi	a0,a0,-630 # 800200b0 <itable>
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	96a080e7          	jalr	-1686(ra) # 80000c98 <release>
}
    80004336:	60e2                	ld	ra,24(sp)
    80004338:	6442                	ld	s0,16(sp)
    8000433a:	64a2                	ld	s1,8(sp)
    8000433c:	6902                	ld	s2,0(sp)
    8000433e:	6105                	addi	sp,sp,32
    80004340:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004342:	40bc                	lw	a5,64(s1)
    80004344:	dff1                	beqz	a5,80004320 <iput+0x26>
    80004346:	04a49783          	lh	a5,74(s1)
    8000434a:	fbf9                	bnez	a5,80004320 <iput+0x26>
    acquiresleep(&ip->lock);
    8000434c:	01048913          	addi	s2,s1,16
    80004350:	854a                	mv	a0,s2
    80004352:	00001097          	auipc	ra,0x1
    80004356:	ab8080e7          	jalr	-1352(ra) # 80004e0a <acquiresleep>
    release(&itable.lock);
    8000435a:	0001c517          	auipc	a0,0x1c
    8000435e:	d5650513          	addi	a0,a0,-682 # 800200b0 <itable>
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	936080e7          	jalr	-1738(ra) # 80000c98 <release>
    itrunc(ip);
    8000436a:	8526                	mv	a0,s1
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	ee2080e7          	jalr	-286(ra) # 8000424e <itrunc>
    ip->type = 0;
    80004374:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004378:	8526                	mv	a0,s1
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	cfc080e7          	jalr	-772(ra) # 80004076 <iupdate>
    ip->valid = 0;
    80004382:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004386:	854a                	mv	a0,s2
    80004388:	00001097          	auipc	ra,0x1
    8000438c:	ad8080e7          	jalr	-1320(ra) # 80004e60 <releasesleep>
    acquire(&itable.lock);
    80004390:	0001c517          	auipc	a0,0x1c
    80004394:	d2050513          	addi	a0,a0,-736 # 800200b0 <itable>
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	84c080e7          	jalr	-1972(ra) # 80000be4 <acquire>
    800043a0:	b741                	j	80004320 <iput+0x26>

00000000800043a2 <iunlockput>:
{
    800043a2:	1101                	addi	sp,sp,-32
    800043a4:	ec06                	sd	ra,24(sp)
    800043a6:	e822                	sd	s0,16(sp)
    800043a8:	e426                	sd	s1,8(sp)
    800043aa:	1000                	addi	s0,sp,32
    800043ac:	84aa                	mv	s1,a0
  iunlock(ip);
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	e54080e7          	jalr	-428(ra) # 80004202 <iunlock>
  iput(ip);
    800043b6:	8526                	mv	a0,s1
    800043b8:	00000097          	auipc	ra,0x0
    800043bc:	f42080e7          	jalr	-190(ra) # 800042fa <iput>
}
    800043c0:	60e2                	ld	ra,24(sp)
    800043c2:	6442                	ld	s0,16(sp)
    800043c4:	64a2                	ld	s1,8(sp)
    800043c6:	6105                	addi	sp,sp,32
    800043c8:	8082                	ret

00000000800043ca <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800043ca:	1141                	addi	sp,sp,-16
    800043cc:	e422                	sd	s0,8(sp)
    800043ce:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800043d0:	411c                	lw	a5,0(a0)
    800043d2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800043d4:	415c                	lw	a5,4(a0)
    800043d6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800043d8:	04451783          	lh	a5,68(a0)
    800043dc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800043e0:	04a51783          	lh	a5,74(a0)
    800043e4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800043e8:	04c56783          	lwu	a5,76(a0)
    800043ec:	e99c                	sd	a5,16(a1)
}
    800043ee:	6422                	ld	s0,8(sp)
    800043f0:	0141                	addi	sp,sp,16
    800043f2:	8082                	ret

00000000800043f4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800043f4:	457c                	lw	a5,76(a0)
    800043f6:	0ed7e963          	bltu	a5,a3,800044e8 <readi+0xf4>
{
    800043fa:	7159                	addi	sp,sp,-112
    800043fc:	f486                	sd	ra,104(sp)
    800043fe:	f0a2                	sd	s0,96(sp)
    80004400:	eca6                	sd	s1,88(sp)
    80004402:	e8ca                	sd	s2,80(sp)
    80004404:	e4ce                	sd	s3,72(sp)
    80004406:	e0d2                	sd	s4,64(sp)
    80004408:	fc56                	sd	s5,56(sp)
    8000440a:	f85a                	sd	s6,48(sp)
    8000440c:	f45e                	sd	s7,40(sp)
    8000440e:	f062                	sd	s8,32(sp)
    80004410:	ec66                	sd	s9,24(sp)
    80004412:	e86a                	sd	s10,16(sp)
    80004414:	e46e                	sd	s11,8(sp)
    80004416:	1880                	addi	s0,sp,112
    80004418:	8baa                	mv	s7,a0
    8000441a:	8c2e                	mv	s8,a1
    8000441c:	8ab2                	mv	s5,a2
    8000441e:	84b6                	mv	s1,a3
    80004420:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004422:	9f35                	addw	a4,a4,a3
    return 0;
    80004424:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004426:	0ad76063          	bltu	a4,a3,800044c6 <readi+0xd2>
  if(off + n > ip->size)
    8000442a:	00e7f463          	bgeu	a5,a4,80004432 <readi+0x3e>
    n = ip->size - off;
    8000442e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004432:	0a0b0963          	beqz	s6,800044e4 <readi+0xf0>
    80004436:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004438:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000443c:	5cfd                	li	s9,-1
    8000443e:	a82d                	j	80004478 <readi+0x84>
    80004440:	020a1d93          	slli	s11,s4,0x20
    80004444:	020ddd93          	srli	s11,s11,0x20
    80004448:	05890613          	addi	a2,s2,88
    8000444c:	86ee                	mv	a3,s11
    8000444e:	963a                	add	a2,a2,a4
    80004450:	85d6                	mv	a1,s5
    80004452:	8562                	mv	a0,s8
    80004454:	fffff097          	auipc	ra,0xfffff
    80004458:	ae4080e7          	jalr	-1308(ra) # 80002f38 <either_copyout>
    8000445c:	05950d63          	beq	a0,s9,800044b6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004460:	854a                	mv	a0,s2
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	60c080e7          	jalr	1548(ra) # 80003a6e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000446a:	013a09bb          	addw	s3,s4,s3
    8000446e:	009a04bb          	addw	s1,s4,s1
    80004472:	9aee                	add	s5,s5,s11
    80004474:	0569f763          	bgeu	s3,s6,800044c2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004478:	000ba903          	lw	s2,0(s7)
    8000447c:	00a4d59b          	srliw	a1,s1,0xa
    80004480:	855e                	mv	a0,s7
    80004482:	00000097          	auipc	ra,0x0
    80004486:	8b0080e7          	jalr	-1872(ra) # 80003d32 <bmap>
    8000448a:	0005059b          	sext.w	a1,a0
    8000448e:	854a                	mv	a0,s2
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	4ae080e7          	jalr	1198(ra) # 8000393e <bread>
    80004498:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000449a:	3ff4f713          	andi	a4,s1,1023
    8000449e:	40ed07bb          	subw	a5,s10,a4
    800044a2:	413b06bb          	subw	a3,s6,s3
    800044a6:	8a3e                	mv	s4,a5
    800044a8:	2781                	sext.w	a5,a5
    800044aa:	0006861b          	sext.w	a2,a3
    800044ae:	f8f679e3          	bgeu	a2,a5,80004440 <readi+0x4c>
    800044b2:	8a36                	mv	s4,a3
    800044b4:	b771                	j	80004440 <readi+0x4c>
      brelse(bp);
    800044b6:	854a                	mv	a0,s2
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	5b6080e7          	jalr	1462(ra) # 80003a6e <brelse>
      tot = -1;
    800044c0:	59fd                	li	s3,-1
  }
  return tot;
    800044c2:	0009851b          	sext.w	a0,s3
}
    800044c6:	70a6                	ld	ra,104(sp)
    800044c8:	7406                	ld	s0,96(sp)
    800044ca:	64e6                	ld	s1,88(sp)
    800044cc:	6946                	ld	s2,80(sp)
    800044ce:	69a6                	ld	s3,72(sp)
    800044d0:	6a06                	ld	s4,64(sp)
    800044d2:	7ae2                	ld	s5,56(sp)
    800044d4:	7b42                	ld	s6,48(sp)
    800044d6:	7ba2                	ld	s7,40(sp)
    800044d8:	7c02                	ld	s8,32(sp)
    800044da:	6ce2                	ld	s9,24(sp)
    800044dc:	6d42                	ld	s10,16(sp)
    800044de:	6da2                	ld	s11,8(sp)
    800044e0:	6165                	addi	sp,sp,112
    800044e2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800044e4:	89da                	mv	s3,s6
    800044e6:	bff1                	j	800044c2 <readi+0xce>
    return 0;
    800044e8:	4501                	li	a0,0
}
    800044ea:	8082                	ret

00000000800044ec <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800044ec:	457c                	lw	a5,76(a0)
    800044ee:	10d7e863          	bltu	a5,a3,800045fe <writei+0x112>
{
    800044f2:	7159                	addi	sp,sp,-112
    800044f4:	f486                	sd	ra,104(sp)
    800044f6:	f0a2                	sd	s0,96(sp)
    800044f8:	eca6                	sd	s1,88(sp)
    800044fa:	e8ca                	sd	s2,80(sp)
    800044fc:	e4ce                	sd	s3,72(sp)
    800044fe:	e0d2                	sd	s4,64(sp)
    80004500:	fc56                	sd	s5,56(sp)
    80004502:	f85a                	sd	s6,48(sp)
    80004504:	f45e                	sd	s7,40(sp)
    80004506:	f062                	sd	s8,32(sp)
    80004508:	ec66                	sd	s9,24(sp)
    8000450a:	e86a                	sd	s10,16(sp)
    8000450c:	e46e                	sd	s11,8(sp)
    8000450e:	1880                	addi	s0,sp,112
    80004510:	8b2a                	mv	s6,a0
    80004512:	8c2e                	mv	s8,a1
    80004514:	8ab2                	mv	s5,a2
    80004516:	8936                	mv	s2,a3
    80004518:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000451a:	00e687bb          	addw	a5,a3,a4
    8000451e:	0ed7e263          	bltu	a5,a3,80004602 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004522:	00043737          	lui	a4,0x43
    80004526:	0ef76063          	bltu	a4,a5,80004606 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000452a:	0c0b8863          	beqz	s7,800045fa <writei+0x10e>
    8000452e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004530:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004534:	5cfd                	li	s9,-1
    80004536:	a091                	j	8000457a <writei+0x8e>
    80004538:	02099d93          	slli	s11,s3,0x20
    8000453c:	020ddd93          	srli	s11,s11,0x20
    80004540:	05848513          	addi	a0,s1,88
    80004544:	86ee                	mv	a3,s11
    80004546:	8656                	mv	a2,s5
    80004548:	85e2                	mv	a1,s8
    8000454a:	953a                	add	a0,a0,a4
    8000454c:	fffff097          	auipc	ra,0xfffff
    80004550:	a42080e7          	jalr	-1470(ra) # 80002f8e <either_copyin>
    80004554:	07950263          	beq	a0,s9,800045b8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004558:	8526                	mv	a0,s1
    8000455a:	00000097          	auipc	ra,0x0
    8000455e:	790080e7          	jalr	1936(ra) # 80004cea <log_write>
    brelse(bp);
    80004562:	8526                	mv	a0,s1
    80004564:	fffff097          	auipc	ra,0xfffff
    80004568:	50a080e7          	jalr	1290(ra) # 80003a6e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000456c:	01498a3b          	addw	s4,s3,s4
    80004570:	0129893b          	addw	s2,s3,s2
    80004574:	9aee                	add	s5,s5,s11
    80004576:	057a7663          	bgeu	s4,s7,800045c2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000457a:	000b2483          	lw	s1,0(s6)
    8000457e:	00a9559b          	srliw	a1,s2,0xa
    80004582:	855a                	mv	a0,s6
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	7ae080e7          	jalr	1966(ra) # 80003d32 <bmap>
    8000458c:	0005059b          	sext.w	a1,a0
    80004590:	8526                	mv	a0,s1
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	3ac080e7          	jalr	940(ra) # 8000393e <bread>
    8000459a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000459c:	3ff97713          	andi	a4,s2,1023
    800045a0:	40ed07bb          	subw	a5,s10,a4
    800045a4:	414b86bb          	subw	a3,s7,s4
    800045a8:	89be                	mv	s3,a5
    800045aa:	2781                	sext.w	a5,a5
    800045ac:	0006861b          	sext.w	a2,a3
    800045b0:	f8f674e3          	bgeu	a2,a5,80004538 <writei+0x4c>
    800045b4:	89b6                	mv	s3,a3
    800045b6:	b749                	j	80004538 <writei+0x4c>
      brelse(bp);
    800045b8:	8526                	mv	a0,s1
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	4b4080e7          	jalr	1204(ra) # 80003a6e <brelse>
  }

  if(off > ip->size)
    800045c2:	04cb2783          	lw	a5,76(s6)
    800045c6:	0127f463          	bgeu	a5,s2,800045ce <writei+0xe2>
    ip->size = off;
    800045ca:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800045ce:	855a                	mv	a0,s6
    800045d0:	00000097          	auipc	ra,0x0
    800045d4:	aa6080e7          	jalr	-1370(ra) # 80004076 <iupdate>

  return tot;
    800045d8:	000a051b          	sext.w	a0,s4
}
    800045dc:	70a6                	ld	ra,104(sp)
    800045de:	7406                	ld	s0,96(sp)
    800045e0:	64e6                	ld	s1,88(sp)
    800045e2:	6946                	ld	s2,80(sp)
    800045e4:	69a6                	ld	s3,72(sp)
    800045e6:	6a06                	ld	s4,64(sp)
    800045e8:	7ae2                	ld	s5,56(sp)
    800045ea:	7b42                	ld	s6,48(sp)
    800045ec:	7ba2                	ld	s7,40(sp)
    800045ee:	7c02                	ld	s8,32(sp)
    800045f0:	6ce2                	ld	s9,24(sp)
    800045f2:	6d42                	ld	s10,16(sp)
    800045f4:	6da2                	ld	s11,8(sp)
    800045f6:	6165                	addi	sp,sp,112
    800045f8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800045fa:	8a5e                	mv	s4,s7
    800045fc:	bfc9                	j	800045ce <writei+0xe2>
    return -1;
    800045fe:	557d                	li	a0,-1
}
    80004600:	8082                	ret
    return -1;
    80004602:	557d                	li	a0,-1
    80004604:	bfe1                	j	800045dc <writei+0xf0>
    return -1;
    80004606:	557d                	li	a0,-1
    80004608:	bfd1                	j	800045dc <writei+0xf0>

000000008000460a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000460a:	1141                	addi	sp,sp,-16
    8000460c:	e406                	sd	ra,8(sp)
    8000460e:	e022                	sd	s0,0(sp)
    80004610:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004612:	4639                	li	a2,14
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	7a4080e7          	jalr	1956(ra) # 80000db8 <strncmp>
}
    8000461c:	60a2                	ld	ra,8(sp)
    8000461e:	6402                	ld	s0,0(sp)
    80004620:	0141                	addi	sp,sp,16
    80004622:	8082                	ret

0000000080004624 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004624:	7139                	addi	sp,sp,-64
    80004626:	fc06                	sd	ra,56(sp)
    80004628:	f822                	sd	s0,48(sp)
    8000462a:	f426                	sd	s1,40(sp)
    8000462c:	f04a                	sd	s2,32(sp)
    8000462e:	ec4e                	sd	s3,24(sp)
    80004630:	e852                	sd	s4,16(sp)
    80004632:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004634:	04451703          	lh	a4,68(a0)
    80004638:	4785                	li	a5,1
    8000463a:	00f71a63          	bne	a4,a5,8000464e <dirlookup+0x2a>
    8000463e:	892a                	mv	s2,a0
    80004640:	89ae                	mv	s3,a1
    80004642:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004644:	457c                	lw	a5,76(a0)
    80004646:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004648:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000464a:	e79d                	bnez	a5,80004678 <dirlookup+0x54>
    8000464c:	a8a5                	j	800046c4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000464e:	00004517          	auipc	a0,0x4
    80004652:	10250513          	addi	a0,a0,258 # 80008750 <syscalls+0x1b0>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	ee8080e7          	jalr	-280(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000465e:	00004517          	auipc	a0,0x4
    80004662:	10a50513          	addi	a0,a0,266 # 80008768 <syscalls+0x1c8>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	ed8080e7          	jalr	-296(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000466e:	24c1                	addiw	s1,s1,16
    80004670:	04c92783          	lw	a5,76(s2)
    80004674:	04f4f763          	bgeu	s1,a5,800046c2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004678:	4741                	li	a4,16
    8000467a:	86a6                	mv	a3,s1
    8000467c:	fc040613          	addi	a2,s0,-64
    80004680:	4581                	li	a1,0
    80004682:	854a                	mv	a0,s2
    80004684:	00000097          	auipc	ra,0x0
    80004688:	d70080e7          	jalr	-656(ra) # 800043f4 <readi>
    8000468c:	47c1                	li	a5,16
    8000468e:	fcf518e3          	bne	a0,a5,8000465e <dirlookup+0x3a>
    if(de.inum == 0)
    80004692:	fc045783          	lhu	a5,-64(s0)
    80004696:	dfe1                	beqz	a5,8000466e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004698:	fc240593          	addi	a1,s0,-62
    8000469c:	854e                	mv	a0,s3
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	f6c080e7          	jalr	-148(ra) # 8000460a <namecmp>
    800046a6:	f561                	bnez	a0,8000466e <dirlookup+0x4a>
      if(poff)
    800046a8:	000a0463          	beqz	s4,800046b0 <dirlookup+0x8c>
        *poff = off;
    800046ac:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800046b0:	fc045583          	lhu	a1,-64(s0)
    800046b4:	00092503          	lw	a0,0(s2)
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	754080e7          	jalr	1876(ra) # 80003e0c <iget>
    800046c0:	a011                	j	800046c4 <dirlookup+0xa0>
  return 0;
    800046c2:	4501                	li	a0,0
}
    800046c4:	70e2                	ld	ra,56(sp)
    800046c6:	7442                	ld	s0,48(sp)
    800046c8:	74a2                	ld	s1,40(sp)
    800046ca:	7902                	ld	s2,32(sp)
    800046cc:	69e2                	ld	s3,24(sp)
    800046ce:	6a42                	ld	s4,16(sp)
    800046d0:	6121                	addi	sp,sp,64
    800046d2:	8082                	ret

00000000800046d4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800046d4:	711d                	addi	sp,sp,-96
    800046d6:	ec86                	sd	ra,88(sp)
    800046d8:	e8a2                	sd	s0,80(sp)
    800046da:	e4a6                	sd	s1,72(sp)
    800046dc:	e0ca                	sd	s2,64(sp)
    800046de:	fc4e                	sd	s3,56(sp)
    800046e0:	f852                	sd	s4,48(sp)
    800046e2:	f456                	sd	s5,40(sp)
    800046e4:	f05a                	sd	s6,32(sp)
    800046e6:	ec5e                	sd	s7,24(sp)
    800046e8:	e862                	sd	s8,16(sp)
    800046ea:	e466                	sd	s9,8(sp)
    800046ec:	1080                	addi	s0,sp,96
    800046ee:	84aa                	mv	s1,a0
    800046f0:	8b2e                	mv	s6,a1
    800046f2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800046f4:	00054703          	lbu	a4,0(a0)
    800046f8:	02f00793          	li	a5,47
    800046fc:	02f70363          	beq	a4,a5,80004722 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004700:	ffffe097          	auipc	ra,0xffffe
    80004704:	afa080e7          	jalr	-1286(ra) # 800021fa <myproc>
    80004708:	17853503          	ld	a0,376(a0)
    8000470c:	00000097          	auipc	ra,0x0
    80004710:	9f6080e7          	jalr	-1546(ra) # 80004102 <idup>
    80004714:	89aa                	mv	s3,a0
  while(*path == '/')
    80004716:	02f00913          	li	s2,47
  len = path - s;
    8000471a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000471c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000471e:	4c05                	li	s8,1
    80004720:	a865                	j	800047d8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004722:	4585                	li	a1,1
    80004724:	4505                	li	a0,1
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	6e6080e7          	jalr	1766(ra) # 80003e0c <iget>
    8000472e:	89aa                	mv	s3,a0
    80004730:	b7dd                	j	80004716 <namex+0x42>
      iunlockput(ip);
    80004732:	854e                	mv	a0,s3
    80004734:	00000097          	auipc	ra,0x0
    80004738:	c6e080e7          	jalr	-914(ra) # 800043a2 <iunlockput>
      return 0;
    8000473c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000473e:	854e                	mv	a0,s3
    80004740:	60e6                	ld	ra,88(sp)
    80004742:	6446                	ld	s0,80(sp)
    80004744:	64a6                	ld	s1,72(sp)
    80004746:	6906                	ld	s2,64(sp)
    80004748:	79e2                	ld	s3,56(sp)
    8000474a:	7a42                	ld	s4,48(sp)
    8000474c:	7aa2                	ld	s5,40(sp)
    8000474e:	7b02                	ld	s6,32(sp)
    80004750:	6be2                	ld	s7,24(sp)
    80004752:	6c42                	ld	s8,16(sp)
    80004754:	6ca2                	ld	s9,8(sp)
    80004756:	6125                	addi	sp,sp,96
    80004758:	8082                	ret
      iunlock(ip);
    8000475a:	854e                	mv	a0,s3
    8000475c:	00000097          	auipc	ra,0x0
    80004760:	aa6080e7          	jalr	-1370(ra) # 80004202 <iunlock>
      return ip;
    80004764:	bfe9                	j	8000473e <namex+0x6a>
      iunlockput(ip);
    80004766:	854e                	mv	a0,s3
    80004768:	00000097          	auipc	ra,0x0
    8000476c:	c3a080e7          	jalr	-966(ra) # 800043a2 <iunlockput>
      return 0;
    80004770:	89d2                	mv	s3,s4
    80004772:	b7f1                	j	8000473e <namex+0x6a>
  len = path - s;
    80004774:	40b48633          	sub	a2,s1,a1
    80004778:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000477c:	094cd463          	bge	s9,s4,80004804 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004780:	4639                	li	a2,14
    80004782:	8556                	mv	a0,s5
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	5bc080e7          	jalr	1468(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000478c:	0004c783          	lbu	a5,0(s1)
    80004790:	01279763          	bne	a5,s2,8000479e <namex+0xca>
    path++;
    80004794:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004796:	0004c783          	lbu	a5,0(s1)
    8000479a:	ff278de3          	beq	a5,s2,80004794 <namex+0xc0>
    ilock(ip);
    8000479e:	854e                	mv	a0,s3
    800047a0:	00000097          	auipc	ra,0x0
    800047a4:	9a0080e7          	jalr	-1632(ra) # 80004140 <ilock>
    if(ip->type != T_DIR){
    800047a8:	04499783          	lh	a5,68(s3)
    800047ac:	f98793e3          	bne	a5,s8,80004732 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800047b0:	000b0563          	beqz	s6,800047ba <namex+0xe6>
    800047b4:	0004c783          	lbu	a5,0(s1)
    800047b8:	d3cd                	beqz	a5,8000475a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800047ba:	865e                	mv	a2,s7
    800047bc:	85d6                	mv	a1,s5
    800047be:	854e                	mv	a0,s3
    800047c0:	00000097          	auipc	ra,0x0
    800047c4:	e64080e7          	jalr	-412(ra) # 80004624 <dirlookup>
    800047c8:	8a2a                	mv	s4,a0
    800047ca:	dd51                	beqz	a0,80004766 <namex+0x92>
    iunlockput(ip);
    800047cc:	854e                	mv	a0,s3
    800047ce:	00000097          	auipc	ra,0x0
    800047d2:	bd4080e7          	jalr	-1068(ra) # 800043a2 <iunlockput>
    ip = next;
    800047d6:	89d2                	mv	s3,s4
  while(*path == '/')
    800047d8:	0004c783          	lbu	a5,0(s1)
    800047dc:	05279763          	bne	a5,s2,8000482a <namex+0x156>
    path++;
    800047e0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800047e2:	0004c783          	lbu	a5,0(s1)
    800047e6:	ff278de3          	beq	a5,s2,800047e0 <namex+0x10c>
  if(*path == 0)
    800047ea:	c79d                	beqz	a5,80004818 <namex+0x144>
    path++;
    800047ec:	85a6                	mv	a1,s1
  len = path - s;
    800047ee:	8a5e                	mv	s4,s7
    800047f0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800047f2:	01278963          	beq	a5,s2,80004804 <namex+0x130>
    800047f6:	dfbd                	beqz	a5,80004774 <namex+0xa0>
    path++;
    800047f8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800047fa:	0004c783          	lbu	a5,0(s1)
    800047fe:	ff279ce3          	bne	a5,s2,800047f6 <namex+0x122>
    80004802:	bf8d                	j	80004774 <namex+0xa0>
    memmove(name, s, len);
    80004804:	2601                	sext.w	a2,a2
    80004806:	8556                	mv	a0,s5
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	538080e7          	jalr	1336(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004810:	9a56                	add	s4,s4,s5
    80004812:	000a0023          	sb	zero,0(s4)
    80004816:	bf9d                	j	8000478c <namex+0xb8>
  if(nameiparent){
    80004818:	f20b03e3          	beqz	s6,8000473e <namex+0x6a>
    iput(ip);
    8000481c:	854e                	mv	a0,s3
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	adc080e7          	jalr	-1316(ra) # 800042fa <iput>
    return 0;
    80004826:	4981                	li	s3,0
    80004828:	bf19                	j	8000473e <namex+0x6a>
  if(*path == 0)
    8000482a:	d7fd                	beqz	a5,80004818 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000482c:	0004c783          	lbu	a5,0(s1)
    80004830:	85a6                	mv	a1,s1
    80004832:	b7d1                	j	800047f6 <namex+0x122>

0000000080004834 <dirlink>:
{
    80004834:	7139                	addi	sp,sp,-64
    80004836:	fc06                	sd	ra,56(sp)
    80004838:	f822                	sd	s0,48(sp)
    8000483a:	f426                	sd	s1,40(sp)
    8000483c:	f04a                	sd	s2,32(sp)
    8000483e:	ec4e                	sd	s3,24(sp)
    80004840:	e852                	sd	s4,16(sp)
    80004842:	0080                	addi	s0,sp,64
    80004844:	892a                	mv	s2,a0
    80004846:	8a2e                	mv	s4,a1
    80004848:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000484a:	4601                	li	a2,0
    8000484c:	00000097          	auipc	ra,0x0
    80004850:	dd8080e7          	jalr	-552(ra) # 80004624 <dirlookup>
    80004854:	e93d                	bnez	a0,800048ca <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004856:	04c92483          	lw	s1,76(s2)
    8000485a:	c49d                	beqz	s1,80004888 <dirlink+0x54>
    8000485c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000485e:	4741                	li	a4,16
    80004860:	86a6                	mv	a3,s1
    80004862:	fc040613          	addi	a2,s0,-64
    80004866:	4581                	li	a1,0
    80004868:	854a                	mv	a0,s2
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	b8a080e7          	jalr	-1142(ra) # 800043f4 <readi>
    80004872:	47c1                	li	a5,16
    80004874:	06f51163          	bne	a0,a5,800048d6 <dirlink+0xa2>
    if(de.inum == 0)
    80004878:	fc045783          	lhu	a5,-64(s0)
    8000487c:	c791                	beqz	a5,80004888 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000487e:	24c1                	addiw	s1,s1,16
    80004880:	04c92783          	lw	a5,76(s2)
    80004884:	fcf4ede3          	bltu	s1,a5,8000485e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004888:	4639                	li	a2,14
    8000488a:	85d2                	mv	a1,s4
    8000488c:	fc240513          	addi	a0,s0,-62
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	564080e7          	jalr	1380(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004898:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000489c:	4741                	li	a4,16
    8000489e:	86a6                	mv	a3,s1
    800048a0:	fc040613          	addi	a2,s0,-64
    800048a4:	4581                	li	a1,0
    800048a6:	854a                	mv	a0,s2
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	c44080e7          	jalr	-956(ra) # 800044ec <writei>
    800048b0:	872a                	mv	a4,a0
    800048b2:	47c1                	li	a5,16
  return 0;
    800048b4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048b6:	02f71863          	bne	a4,a5,800048e6 <dirlink+0xb2>
}
    800048ba:	70e2                	ld	ra,56(sp)
    800048bc:	7442                	ld	s0,48(sp)
    800048be:	74a2                	ld	s1,40(sp)
    800048c0:	7902                	ld	s2,32(sp)
    800048c2:	69e2                	ld	s3,24(sp)
    800048c4:	6a42                	ld	s4,16(sp)
    800048c6:	6121                	addi	sp,sp,64
    800048c8:	8082                	ret
    iput(ip);
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	a30080e7          	jalr	-1488(ra) # 800042fa <iput>
    return -1;
    800048d2:	557d                	li	a0,-1
    800048d4:	b7dd                	j	800048ba <dirlink+0x86>
      panic("dirlink read");
    800048d6:	00004517          	auipc	a0,0x4
    800048da:	ea250513          	addi	a0,a0,-350 # 80008778 <syscalls+0x1d8>
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	c60080e7          	jalr	-928(ra) # 8000053e <panic>
    panic("dirlink");
    800048e6:	00004517          	auipc	a0,0x4
    800048ea:	fa250513          	addi	a0,a0,-94 # 80008888 <syscalls+0x2e8>
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	c50080e7          	jalr	-944(ra) # 8000053e <panic>

00000000800048f6 <namei>:

struct inode*
namei(char *path)
{
    800048f6:	1101                	addi	sp,sp,-32
    800048f8:	ec06                	sd	ra,24(sp)
    800048fa:	e822                	sd	s0,16(sp)
    800048fc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800048fe:	fe040613          	addi	a2,s0,-32
    80004902:	4581                	li	a1,0
    80004904:	00000097          	auipc	ra,0x0
    80004908:	dd0080e7          	jalr	-560(ra) # 800046d4 <namex>
}
    8000490c:	60e2                	ld	ra,24(sp)
    8000490e:	6442                	ld	s0,16(sp)
    80004910:	6105                	addi	sp,sp,32
    80004912:	8082                	ret

0000000080004914 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004914:	1141                	addi	sp,sp,-16
    80004916:	e406                	sd	ra,8(sp)
    80004918:	e022                	sd	s0,0(sp)
    8000491a:	0800                	addi	s0,sp,16
    8000491c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000491e:	4585                	li	a1,1
    80004920:	00000097          	auipc	ra,0x0
    80004924:	db4080e7          	jalr	-588(ra) # 800046d4 <namex>
}
    80004928:	60a2                	ld	ra,8(sp)
    8000492a:	6402                	ld	s0,0(sp)
    8000492c:	0141                	addi	sp,sp,16
    8000492e:	8082                	ret

0000000080004930 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004930:	1101                	addi	sp,sp,-32
    80004932:	ec06                	sd	ra,24(sp)
    80004934:	e822                	sd	s0,16(sp)
    80004936:	e426                	sd	s1,8(sp)
    80004938:	e04a                	sd	s2,0(sp)
    8000493a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000493c:	0001d917          	auipc	s2,0x1d
    80004940:	21c90913          	addi	s2,s2,540 # 80021b58 <log>
    80004944:	01892583          	lw	a1,24(s2)
    80004948:	02892503          	lw	a0,40(s2)
    8000494c:	fffff097          	auipc	ra,0xfffff
    80004950:	ff2080e7          	jalr	-14(ra) # 8000393e <bread>
    80004954:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004956:	02c92683          	lw	a3,44(s2)
    8000495a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000495c:	02d05763          	blez	a3,8000498a <write_head+0x5a>
    80004960:	0001d797          	auipc	a5,0x1d
    80004964:	22878793          	addi	a5,a5,552 # 80021b88 <log+0x30>
    80004968:	05c50713          	addi	a4,a0,92
    8000496c:	36fd                	addiw	a3,a3,-1
    8000496e:	1682                	slli	a3,a3,0x20
    80004970:	9281                	srli	a3,a3,0x20
    80004972:	068a                	slli	a3,a3,0x2
    80004974:	0001d617          	auipc	a2,0x1d
    80004978:	21860613          	addi	a2,a2,536 # 80021b8c <log+0x34>
    8000497c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000497e:	4390                	lw	a2,0(a5)
    80004980:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004982:	0791                	addi	a5,a5,4
    80004984:	0711                	addi	a4,a4,4
    80004986:	fed79ce3          	bne	a5,a3,8000497e <write_head+0x4e>
  }
  bwrite(buf);
    8000498a:	8526                	mv	a0,s1
    8000498c:	fffff097          	auipc	ra,0xfffff
    80004990:	0a4080e7          	jalr	164(ra) # 80003a30 <bwrite>
  brelse(buf);
    80004994:	8526                	mv	a0,s1
    80004996:	fffff097          	auipc	ra,0xfffff
    8000499a:	0d8080e7          	jalr	216(ra) # 80003a6e <brelse>
}
    8000499e:	60e2                	ld	ra,24(sp)
    800049a0:	6442                	ld	s0,16(sp)
    800049a2:	64a2                	ld	s1,8(sp)
    800049a4:	6902                	ld	s2,0(sp)
    800049a6:	6105                	addi	sp,sp,32
    800049a8:	8082                	ret

00000000800049aa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800049aa:	0001d797          	auipc	a5,0x1d
    800049ae:	1da7a783          	lw	a5,474(a5) # 80021b84 <log+0x2c>
    800049b2:	0af05d63          	blez	a5,80004a6c <install_trans+0xc2>
{
    800049b6:	7139                	addi	sp,sp,-64
    800049b8:	fc06                	sd	ra,56(sp)
    800049ba:	f822                	sd	s0,48(sp)
    800049bc:	f426                	sd	s1,40(sp)
    800049be:	f04a                	sd	s2,32(sp)
    800049c0:	ec4e                	sd	s3,24(sp)
    800049c2:	e852                	sd	s4,16(sp)
    800049c4:	e456                	sd	s5,8(sp)
    800049c6:	e05a                	sd	s6,0(sp)
    800049c8:	0080                	addi	s0,sp,64
    800049ca:	8b2a                	mv	s6,a0
    800049cc:	0001da97          	auipc	s5,0x1d
    800049d0:	1bca8a93          	addi	s5,s5,444 # 80021b88 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049d4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800049d6:	0001d997          	auipc	s3,0x1d
    800049da:	18298993          	addi	s3,s3,386 # 80021b58 <log>
    800049de:	a035                	j	80004a0a <install_trans+0x60>
      bunpin(dbuf);
    800049e0:	8526                	mv	a0,s1
    800049e2:	fffff097          	auipc	ra,0xfffff
    800049e6:	166080e7          	jalr	358(ra) # 80003b48 <bunpin>
    brelse(lbuf);
    800049ea:	854a                	mv	a0,s2
    800049ec:	fffff097          	auipc	ra,0xfffff
    800049f0:	082080e7          	jalr	130(ra) # 80003a6e <brelse>
    brelse(dbuf);
    800049f4:	8526                	mv	a0,s1
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	078080e7          	jalr	120(ra) # 80003a6e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049fe:	2a05                	addiw	s4,s4,1
    80004a00:	0a91                	addi	s5,s5,4
    80004a02:	02c9a783          	lw	a5,44(s3)
    80004a06:	04fa5963          	bge	s4,a5,80004a58 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a0a:	0189a583          	lw	a1,24(s3)
    80004a0e:	014585bb          	addw	a1,a1,s4
    80004a12:	2585                	addiw	a1,a1,1
    80004a14:	0289a503          	lw	a0,40(s3)
    80004a18:	fffff097          	auipc	ra,0xfffff
    80004a1c:	f26080e7          	jalr	-218(ra) # 8000393e <bread>
    80004a20:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004a22:	000aa583          	lw	a1,0(s5)
    80004a26:	0289a503          	lw	a0,40(s3)
    80004a2a:	fffff097          	auipc	ra,0xfffff
    80004a2e:	f14080e7          	jalr	-236(ra) # 8000393e <bread>
    80004a32:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004a34:	40000613          	li	a2,1024
    80004a38:	05890593          	addi	a1,s2,88
    80004a3c:	05850513          	addi	a0,a0,88
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	300080e7          	jalr	768(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004a48:	8526                	mv	a0,s1
    80004a4a:	fffff097          	auipc	ra,0xfffff
    80004a4e:	fe6080e7          	jalr	-26(ra) # 80003a30 <bwrite>
    if(recovering == 0)
    80004a52:	f80b1ce3          	bnez	s6,800049ea <install_trans+0x40>
    80004a56:	b769                	j	800049e0 <install_trans+0x36>
}
    80004a58:	70e2                	ld	ra,56(sp)
    80004a5a:	7442                	ld	s0,48(sp)
    80004a5c:	74a2                	ld	s1,40(sp)
    80004a5e:	7902                	ld	s2,32(sp)
    80004a60:	69e2                	ld	s3,24(sp)
    80004a62:	6a42                	ld	s4,16(sp)
    80004a64:	6aa2                	ld	s5,8(sp)
    80004a66:	6b02                	ld	s6,0(sp)
    80004a68:	6121                	addi	sp,sp,64
    80004a6a:	8082                	ret
    80004a6c:	8082                	ret

0000000080004a6e <initlog>:
{
    80004a6e:	7179                	addi	sp,sp,-48
    80004a70:	f406                	sd	ra,40(sp)
    80004a72:	f022                	sd	s0,32(sp)
    80004a74:	ec26                	sd	s1,24(sp)
    80004a76:	e84a                	sd	s2,16(sp)
    80004a78:	e44e                	sd	s3,8(sp)
    80004a7a:	1800                	addi	s0,sp,48
    80004a7c:	892a                	mv	s2,a0
    80004a7e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004a80:	0001d497          	auipc	s1,0x1d
    80004a84:	0d848493          	addi	s1,s1,216 # 80021b58 <log>
    80004a88:	00004597          	auipc	a1,0x4
    80004a8c:	d0058593          	addi	a1,a1,-768 # 80008788 <syscalls+0x1e8>
    80004a90:	8526                	mv	a0,s1
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	0c2080e7          	jalr	194(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004a9a:	0149a583          	lw	a1,20(s3)
    80004a9e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004aa0:	0109a783          	lw	a5,16(s3)
    80004aa4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004aa6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004aaa:	854a                	mv	a0,s2
    80004aac:	fffff097          	auipc	ra,0xfffff
    80004ab0:	e92080e7          	jalr	-366(ra) # 8000393e <bread>
  log.lh.n = lh->n;
    80004ab4:	4d3c                	lw	a5,88(a0)
    80004ab6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004ab8:	02f05563          	blez	a5,80004ae2 <initlog+0x74>
    80004abc:	05c50713          	addi	a4,a0,92
    80004ac0:	0001d697          	auipc	a3,0x1d
    80004ac4:	0c868693          	addi	a3,a3,200 # 80021b88 <log+0x30>
    80004ac8:	37fd                	addiw	a5,a5,-1
    80004aca:	1782                	slli	a5,a5,0x20
    80004acc:	9381                	srli	a5,a5,0x20
    80004ace:	078a                	slli	a5,a5,0x2
    80004ad0:	06050613          	addi	a2,a0,96
    80004ad4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004ad6:	4310                	lw	a2,0(a4)
    80004ad8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004ada:	0711                	addi	a4,a4,4
    80004adc:	0691                	addi	a3,a3,4
    80004ade:	fef71ce3          	bne	a4,a5,80004ad6 <initlog+0x68>
  brelse(buf);
    80004ae2:	fffff097          	auipc	ra,0xfffff
    80004ae6:	f8c080e7          	jalr	-116(ra) # 80003a6e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004aea:	4505                	li	a0,1
    80004aec:	00000097          	auipc	ra,0x0
    80004af0:	ebe080e7          	jalr	-322(ra) # 800049aa <install_trans>
  log.lh.n = 0;
    80004af4:	0001d797          	auipc	a5,0x1d
    80004af8:	0807a823          	sw	zero,144(a5) # 80021b84 <log+0x2c>
  write_head(); // clear the log
    80004afc:	00000097          	auipc	ra,0x0
    80004b00:	e34080e7          	jalr	-460(ra) # 80004930 <write_head>
}
    80004b04:	70a2                	ld	ra,40(sp)
    80004b06:	7402                	ld	s0,32(sp)
    80004b08:	64e2                	ld	s1,24(sp)
    80004b0a:	6942                	ld	s2,16(sp)
    80004b0c:	69a2                	ld	s3,8(sp)
    80004b0e:	6145                	addi	sp,sp,48
    80004b10:	8082                	ret

0000000080004b12 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004b12:	1101                	addi	sp,sp,-32
    80004b14:	ec06                	sd	ra,24(sp)
    80004b16:	e822                	sd	s0,16(sp)
    80004b18:	e426                	sd	s1,8(sp)
    80004b1a:	e04a                	sd	s2,0(sp)
    80004b1c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004b1e:	0001d517          	auipc	a0,0x1d
    80004b22:	03a50513          	addi	a0,a0,58 # 80021b58 <log>
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	0be080e7          	jalr	190(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004b2e:	0001d497          	auipc	s1,0x1d
    80004b32:	02a48493          	addi	s1,s1,42 # 80021b58 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b36:	4979                	li	s2,30
    80004b38:	a039                	j	80004b46 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004b3a:	85a6                	mv	a1,s1
    80004b3c:	8526                	mv	a0,s1
    80004b3e:	ffffe097          	auipc	ra,0xffffe
    80004b42:	f32080e7          	jalr	-206(ra) # 80002a70 <sleep>
    if(log.committing){
    80004b46:	50dc                	lw	a5,36(s1)
    80004b48:	fbed                	bnez	a5,80004b3a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b4a:	509c                	lw	a5,32(s1)
    80004b4c:	0017871b          	addiw	a4,a5,1
    80004b50:	0007069b          	sext.w	a3,a4
    80004b54:	0027179b          	slliw	a5,a4,0x2
    80004b58:	9fb9                	addw	a5,a5,a4
    80004b5a:	0017979b          	slliw	a5,a5,0x1
    80004b5e:	54d8                	lw	a4,44(s1)
    80004b60:	9fb9                	addw	a5,a5,a4
    80004b62:	00f95963          	bge	s2,a5,80004b74 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004b66:	85a6                	mv	a1,s1
    80004b68:	8526                	mv	a0,s1
    80004b6a:	ffffe097          	auipc	ra,0xffffe
    80004b6e:	f06080e7          	jalr	-250(ra) # 80002a70 <sleep>
    80004b72:	bfd1                	j	80004b46 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004b74:	0001d517          	auipc	a0,0x1d
    80004b78:	fe450513          	addi	a0,a0,-28 # 80021b58 <log>
    80004b7c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	11a080e7          	jalr	282(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004b86:	60e2                	ld	ra,24(sp)
    80004b88:	6442                	ld	s0,16(sp)
    80004b8a:	64a2                	ld	s1,8(sp)
    80004b8c:	6902                	ld	s2,0(sp)
    80004b8e:	6105                	addi	sp,sp,32
    80004b90:	8082                	ret

0000000080004b92 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004b92:	7139                	addi	sp,sp,-64
    80004b94:	fc06                	sd	ra,56(sp)
    80004b96:	f822                	sd	s0,48(sp)
    80004b98:	f426                	sd	s1,40(sp)
    80004b9a:	f04a                	sd	s2,32(sp)
    80004b9c:	ec4e                	sd	s3,24(sp)
    80004b9e:	e852                	sd	s4,16(sp)
    80004ba0:	e456                	sd	s5,8(sp)
    80004ba2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004ba4:	0001d497          	auipc	s1,0x1d
    80004ba8:	fb448493          	addi	s1,s1,-76 # 80021b58 <log>
    80004bac:	8526                	mv	a0,s1
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	036080e7          	jalr	54(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004bb6:	509c                	lw	a5,32(s1)
    80004bb8:	37fd                	addiw	a5,a5,-1
    80004bba:	0007891b          	sext.w	s2,a5
    80004bbe:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004bc0:	50dc                	lw	a5,36(s1)
    80004bc2:	efb9                	bnez	a5,80004c20 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004bc4:	06091663          	bnez	s2,80004c30 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004bc8:	0001d497          	auipc	s1,0x1d
    80004bcc:	f9048493          	addi	s1,s1,-112 # 80021b58 <log>
    80004bd0:	4785                	li	a5,1
    80004bd2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004bd4:	8526                	mv	a0,s1
    80004bd6:	ffffc097          	auipc	ra,0xffffc
    80004bda:	0c2080e7          	jalr	194(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004bde:	54dc                	lw	a5,44(s1)
    80004be0:	06f04763          	bgtz	a5,80004c4e <end_op+0xbc>
    acquire(&log.lock);
    80004be4:	0001d497          	auipc	s1,0x1d
    80004be8:	f7448493          	addi	s1,s1,-140 # 80021b58 <log>
    80004bec:	8526                	mv	a0,s1
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	ff6080e7          	jalr	-10(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004bf6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffe097          	auipc	ra,0xffffe
    80004c00:	00e080e7          	jalr	14(ra) # 80002c0a <wakeup>
    release(&log.lock);
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	092080e7          	jalr	146(ra) # 80000c98 <release>
}
    80004c0e:	70e2                	ld	ra,56(sp)
    80004c10:	7442                	ld	s0,48(sp)
    80004c12:	74a2                	ld	s1,40(sp)
    80004c14:	7902                	ld	s2,32(sp)
    80004c16:	69e2                	ld	s3,24(sp)
    80004c18:	6a42                	ld	s4,16(sp)
    80004c1a:	6aa2                	ld	s5,8(sp)
    80004c1c:	6121                	addi	sp,sp,64
    80004c1e:	8082                	ret
    panic("log.committing");
    80004c20:	00004517          	auipc	a0,0x4
    80004c24:	b7050513          	addi	a0,a0,-1168 # 80008790 <syscalls+0x1f0>
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	916080e7          	jalr	-1770(ra) # 8000053e <panic>
    wakeup(&log);
    80004c30:	0001d497          	auipc	s1,0x1d
    80004c34:	f2848493          	addi	s1,s1,-216 # 80021b58 <log>
    80004c38:	8526                	mv	a0,s1
    80004c3a:	ffffe097          	auipc	ra,0xffffe
    80004c3e:	fd0080e7          	jalr	-48(ra) # 80002c0a <wakeup>
  release(&log.lock);
    80004c42:	8526                	mv	a0,s1
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	054080e7          	jalr	84(ra) # 80000c98 <release>
  if(do_commit){
    80004c4c:	b7c9                	j	80004c0e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c4e:	0001da97          	auipc	s5,0x1d
    80004c52:	f3aa8a93          	addi	s5,s5,-198 # 80021b88 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004c56:	0001da17          	auipc	s4,0x1d
    80004c5a:	f02a0a13          	addi	s4,s4,-254 # 80021b58 <log>
    80004c5e:	018a2583          	lw	a1,24(s4)
    80004c62:	012585bb          	addw	a1,a1,s2
    80004c66:	2585                	addiw	a1,a1,1
    80004c68:	028a2503          	lw	a0,40(s4)
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	cd2080e7          	jalr	-814(ra) # 8000393e <bread>
    80004c74:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004c76:	000aa583          	lw	a1,0(s5)
    80004c7a:	028a2503          	lw	a0,40(s4)
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	cc0080e7          	jalr	-832(ra) # 8000393e <bread>
    80004c86:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004c88:	40000613          	li	a2,1024
    80004c8c:	05850593          	addi	a1,a0,88
    80004c90:	05848513          	addi	a0,s1,88
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	0ac080e7          	jalr	172(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	d92080e7          	jalr	-622(ra) # 80003a30 <bwrite>
    brelse(from);
    80004ca6:	854e                	mv	a0,s3
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	dc6080e7          	jalr	-570(ra) # 80003a6e <brelse>
    brelse(to);
    80004cb0:	8526                	mv	a0,s1
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	dbc080e7          	jalr	-580(ra) # 80003a6e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004cba:	2905                	addiw	s2,s2,1
    80004cbc:	0a91                	addi	s5,s5,4
    80004cbe:	02ca2783          	lw	a5,44(s4)
    80004cc2:	f8f94ee3          	blt	s2,a5,80004c5e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004cc6:	00000097          	auipc	ra,0x0
    80004cca:	c6a080e7          	jalr	-918(ra) # 80004930 <write_head>
    install_trans(0); // Now install writes to home locations
    80004cce:	4501                	li	a0,0
    80004cd0:	00000097          	auipc	ra,0x0
    80004cd4:	cda080e7          	jalr	-806(ra) # 800049aa <install_trans>
    log.lh.n = 0;
    80004cd8:	0001d797          	auipc	a5,0x1d
    80004cdc:	ea07a623          	sw	zero,-340(a5) # 80021b84 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ce0:	00000097          	auipc	ra,0x0
    80004ce4:	c50080e7          	jalr	-944(ra) # 80004930 <write_head>
    80004ce8:	bdf5                	j	80004be4 <end_op+0x52>

0000000080004cea <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004cea:	1101                	addi	sp,sp,-32
    80004cec:	ec06                	sd	ra,24(sp)
    80004cee:	e822                	sd	s0,16(sp)
    80004cf0:	e426                	sd	s1,8(sp)
    80004cf2:	e04a                	sd	s2,0(sp)
    80004cf4:	1000                	addi	s0,sp,32
    80004cf6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004cf8:	0001d917          	auipc	s2,0x1d
    80004cfc:	e6090913          	addi	s2,s2,-416 # 80021b58 <log>
    80004d00:	854a                	mv	a0,s2
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	ee2080e7          	jalr	-286(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004d0a:	02c92603          	lw	a2,44(s2)
    80004d0e:	47f5                	li	a5,29
    80004d10:	06c7c563          	blt	a5,a2,80004d7a <log_write+0x90>
    80004d14:	0001d797          	auipc	a5,0x1d
    80004d18:	e607a783          	lw	a5,-416(a5) # 80021b74 <log+0x1c>
    80004d1c:	37fd                	addiw	a5,a5,-1
    80004d1e:	04f65e63          	bge	a2,a5,80004d7a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004d22:	0001d797          	auipc	a5,0x1d
    80004d26:	e567a783          	lw	a5,-426(a5) # 80021b78 <log+0x20>
    80004d2a:	06f05063          	blez	a5,80004d8a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004d2e:	4781                	li	a5,0
    80004d30:	06c05563          	blez	a2,80004d9a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d34:	44cc                	lw	a1,12(s1)
    80004d36:	0001d717          	auipc	a4,0x1d
    80004d3a:	e5270713          	addi	a4,a4,-430 # 80021b88 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004d3e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004d40:	4314                	lw	a3,0(a4)
    80004d42:	04b68c63          	beq	a3,a1,80004d9a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004d46:	2785                	addiw	a5,a5,1
    80004d48:	0711                	addi	a4,a4,4
    80004d4a:	fef61be3          	bne	a2,a5,80004d40 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004d4e:	0621                	addi	a2,a2,8
    80004d50:	060a                	slli	a2,a2,0x2
    80004d52:	0001d797          	auipc	a5,0x1d
    80004d56:	e0678793          	addi	a5,a5,-506 # 80021b58 <log>
    80004d5a:	963e                	add	a2,a2,a5
    80004d5c:	44dc                	lw	a5,12(s1)
    80004d5e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004d60:	8526                	mv	a0,s1
    80004d62:	fffff097          	auipc	ra,0xfffff
    80004d66:	daa080e7          	jalr	-598(ra) # 80003b0c <bpin>
    log.lh.n++;
    80004d6a:	0001d717          	auipc	a4,0x1d
    80004d6e:	dee70713          	addi	a4,a4,-530 # 80021b58 <log>
    80004d72:	575c                	lw	a5,44(a4)
    80004d74:	2785                	addiw	a5,a5,1
    80004d76:	d75c                	sw	a5,44(a4)
    80004d78:	a835                	j	80004db4 <log_write+0xca>
    panic("too big a transaction");
    80004d7a:	00004517          	auipc	a0,0x4
    80004d7e:	a2650513          	addi	a0,a0,-1498 # 800087a0 <syscalls+0x200>
    80004d82:	ffffb097          	auipc	ra,0xffffb
    80004d86:	7bc080e7          	jalr	1980(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004d8a:	00004517          	auipc	a0,0x4
    80004d8e:	a2e50513          	addi	a0,a0,-1490 # 800087b8 <syscalls+0x218>
    80004d92:	ffffb097          	auipc	ra,0xffffb
    80004d96:	7ac080e7          	jalr	1964(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004d9a:	00878713          	addi	a4,a5,8
    80004d9e:	00271693          	slli	a3,a4,0x2
    80004da2:	0001d717          	auipc	a4,0x1d
    80004da6:	db670713          	addi	a4,a4,-586 # 80021b58 <log>
    80004daa:	9736                	add	a4,a4,a3
    80004dac:	44d4                	lw	a3,12(s1)
    80004dae:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004db0:	faf608e3          	beq	a2,a5,80004d60 <log_write+0x76>
  }
  release(&log.lock);
    80004db4:	0001d517          	auipc	a0,0x1d
    80004db8:	da450513          	addi	a0,a0,-604 # 80021b58 <log>
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	edc080e7          	jalr	-292(ra) # 80000c98 <release>
}
    80004dc4:	60e2                	ld	ra,24(sp)
    80004dc6:	6442                	ld	s0,16(sp)
    80004dc8:	64a2                	ld	s1,8(sp)
    80004dca:	6902                	ld	s2,0(sp)
    80004dcc:	6105                	addi	sp,sp,32
    80004dce:	8082                	ret

0000000080004dd0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004dd0:	1101                	addi	sp,sp,-32
    80004dd2:	ec06                	sd	ra,24(sp)
    80004dd4:	e822                	sd	s0,16(sp)
    80004dd6:	e426                	sd	s1,8(sp)
    80004dd8:	e04a                	sd	s2,0(sp)
    80004dda:	1000                	addi	s0,sp,32
    80004ddc:	84aa                	mv	s1,a0
    80004dde:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004de0:	00004597          	auipc	a1,0x4
    80004de4:	9f858593          	addi	a1,a1,-1544 # 800087d8 <syscalls+0x238>
    80004de8:	0521                	addi	a0,a0,8
    80004dea:	ffffc097          	auipc	ra,0xffffc
    80004dee:	d6a080e7          	jalr	-662(ra) # 80000b54 <initlock>
  lk->name = name;
    80004df2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004df6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004dfa:	0204a423          	sw	zero,40(s1)
}
    80004dfe:	60e2                	ld	ra,24(sp)
    80004e00:	6442                	ld	s0,16(sp)
    80004e02:	64a2                	ld	s1,8(sp)
    80004e04:	6902                	ld	s2,0(sp)
    80004e06:	6105                	addi	sp,sp,32
    80004e08:	8082                	ret

0000000080004e0a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004e0a:	1101                	addi	sp,sp,-32
    80004e0c:	ec06                	sd	ra,24(sp)
    80004e0e:	e822                	sd	s0,16(sp)
    80004e10:	e426                	sd	s1,8(sp)
    80004e12:	e04a                	sd	s2,0(sp)
    80004e14:	1000                	addi	s0,sp,32
    80004e16:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e18:	00850913          	addi	s2,a0,8
    80004e1c:	854a                	mv	a0,s2
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	dc6080e7          	jalr	-570(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004e26:	409c                	lw	a5,0(s1)
    80004e28:	cb89                	beqz	a5,80004e3a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004e2a:	85ca                	mv	a1,s2
    80004e2c:	8526                	mv	a0,s1
    80004e2e:	ffffe097          	auipc	ra,0xffffe
    80004e32:	c42080e7          	jalr	-958(ra) # 80002a70 <sleep>
  while (lk->locked) {
    80004e36:	409c                	lw	a5,0(s1)
    80004e38:	fbed                	bnez	a5,80004e2a <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004e3a:	4785                	li	a5,1
    80004e3c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	3bc080e7          	jalr	956(ra) # 800021fa <myproc>
    80004e46:	453c                	lw	a5,72(a0)
    80004e48:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004e4a:	854a                	mv	a0,s2
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	e4c080e7          	jalr	-436(ra) # 80000c98 <release>
}
    80004e54:	60e2                	ld	ra,24(sp)
    80004e56:	6442                	ld	s0,16(sp)
    80004e58:	64a2                	ld	s1,8(sp)
    80004e5a:	6902                	ld	s2,0(sp)
    80004e5c:	6105                	addi	sp,sp,32
    80004e5e:	8082                	ret

0000000080004e60 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004e60:	1101                	addi	sp,sp,-32
    80004e62:	ec06                	sd	ra,24(sp)
    80004e64:	e822                	sd	s0,16(sp)
    80004e66:	e426                	sd	s1,8(sp)
    80004e68:	e04a                	sd	s2,0(sp)
    80004e6a:	1000                	addi	s0,sp,32
    80004e6c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e6e:	00850913          	addi	s2,a0,8
    80004e72:	854a                	mv	a0,s2
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	d70080e7          	jalr	-656(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004e7c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e80:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004e84:	8526                	mv	a0,s1
    80004e86:	ffffe097          	auipc	ra,0xffffe
    80004e8a:	d84080e7          	jalr	-636(ra) # 80002c0a <wakeup>
  release(&lk->lk);
    80004e8e:	854a                	mv	a0,s2
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	e08080e7          	jalr	-504(ra) # 80000c98 <release>
}
    80004e98:	60e2                	ld	ra,24(sp)
    80004e9a:	6442                	ld	s0,16(sp)
    80004e9c:	64a2                	ld	s1,8(sp)
    80004e9e:	6902                	ld	s2,0(sp)
    80004ea0:	6105                	addi	sp,sp,32
    80004ea2:	8082                	ret

0000000080004ea4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ea4:	7179                	addi	sp,sp,-48
    80004ea6:	f406                	sd	ra,40(sp)
    80004ea8:	f022                	sd	s0,32(sp)
    80004eaa:	ec26                	sd	s1,24(sp)
    80004eac:	e84a                	sd	s2,16(sp)
    80004eae:	e44e                	sd	s3,8(sp)
    80004eb0:	1800                	addi	s0,sp,48
    80004eb2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004eb4:	00850913          	addi	s2,a0,8
    80004eb8:	854a                	mv	a0,s2
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	d2a080e7          	jalr	-726(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ec2:	409c                	lw	a5,0(s1)
    80004ec4:	ef99                	bnez	a5,80004ee2 <holdingsleep+0x3e>
    80004ec6:	4481                	li	s1,0
  release(&lk->lk);
    80004ec8:	854a                	mv	a0,s2
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	dce080e7          	jalr	-562(ra) # 80000c98 <release>
  return r;
}
    80004ed2:	8526                	mv	a0,s1
    80004ed4:	70a2                	ld	ra,40(sp)
    80004ed6:	7402                	ld	s0,32(sp)
    80004ed8:	64e2                	ld	s1,24(sp)
    80004eda:	6942                	ld	s2,16(sp)
    80004edc:	69a2                	ld	s3,8(sp)
    80004ede:	6145                	addi	sp,sp,48
    80004ee0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ee2:	0284a983          	lw	s3,40(s1)
    80004ee6:	ffffd097          	auipc	ra,0xffffd
    80004eea:	314080e7          	jalr	788(ra) # 800021fa <myproc>
    80004eee:	4524                	lw	s1,72(a0)
    80004ef0:	413484b3          	sub	s1,s1,s3
    80004ef4:	0014b493          	seqz	s1,s1
    80004ef8:	bfc1                	j	80004ec8 <holdingsleep+0x24>

0000000080004efa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004efa:	1141                	addi	sp,sp,-16
    80004efc:	e406                	sd	ra,8(sp)
    80004efe:	e022                	sd	s0,0(sp)
    80004f00:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004f02:	00004597          	auipc	a1,0x4
    80004f06:	8e658593          	addi	a1,a1,-1818 # 800087e8 <syscalls+0x248>
    80004f0a:	0001d517          	auipc	a0,0x1d
    80004f0e:	d9650513          	addi	a0,a0,-618 # 80021ca0 <ftable>
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	c42080e7          	jalr	-958(ra) # 80000b54 <initlock>
}
    80004f1a:	60a2                	ld	ra,8(sp)
    80004f1c:	6402                	ld	s0,0(sp)
    80004f1e:	0141                	addi	sp,sp,16
    80004f20:	8082                	ret

0000000080004f22 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004f22:	1101                	addi	sp,sp,-32
    80004f24:	ec06                	sd	ra,24(sp)
    80004f26:	e822                	sd	s0,16(sp)
    80004f28:	e426                	sd	s1,8(sp)
    80004f2a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004f2c:	0001d517          	auipc	a0,0x1d
    80004f30:	d7450513          	addi	a0,a0,-652 # 80021ca0 <ftable>
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	cb0080e7          	jalr	-848(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f3c:	0001d497          	auipc	s1,0x1d
    80004f40:	d7c48493          	addi	s1,s1,-644 # 80021cb8 <ftable+0x18>
    80004f44:	0001e717          	auipc	a4,0x1e
    80004f48:	d1470713          	addi	a4,a4,-748 # 80022c58 <ftable+0xfb8>
    if(f->ref == 0){
    80004f4c:	40dc                	lw	a5,4(s1)
    80004f4e:	cf99                	beqz	a5,80004f6c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f50:	02848493          	addi	s1,s1,40
    80004f54:	fee49ce3          	bne	s1,a4,80004f4c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004f58:	0001d517          	auipc	a0,0x1d
    80004f5c:	d4850513          	addi	a0,a0,-696 # 80021ca0 <ftable>
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	d38080e7          	jalr	-712(ra) # 80000c98 <release>
  return 0;
    80004f68:	4481                	li	s1,0
    80004f6a:	a819                	j	80004f80 <filealloc+0x5e>
      f->ref = 1;
    80004f6c:	4785                	li	a5,1
    80004f6e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004f70:	0001d517          	auipc	a0,0x1d
    80004f74:	d3050513          	addi	a0,a0,-720 # 80021ca0 <ftable>
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	d20080e7          	jalr	-736(ra) # 80000c98 <release>
}
    80004f80:	8526                	mv	a0,s1
    80004f82:	60e2                	ld	ra,24(sp)
    80004f84:	6442                	ld	s0,16(sp)
    80004f86:	64a2                	ld	s1,8(sp)
    80004f88:	6105                	addi	sp,sp,32
    80004f8a:	8082                	ret

0000000080004f8c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004f8c:	1101                	addi	sp,sp,-32
    80004f8e:	ec06                	sd	ra,24(sp)
    80004f90:	e822                	sd	s0,16(sp)
    80004f92:	e426                	sd	s1,8(sp)
    80004f94:	1000                	addi	s0,sp,32
    80004f96:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004f98:	0001d517          	auipc	a0,0x1d
    80004f9c:	d0850513          	addi	a0,a0,-760 # 80021ca0 <ftable>
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	c44080e7          	jalr	-956(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004fa8:	40dc                	lw	a5,4(s1)
    80004faa:	02f05263          	blez	a5,80004fce <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004fae:	2785                	addiw	a5,a5,1
    80004fb0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004fb2:	0001d517          	auipc	a0,0x1d
    80004fb6:	cee50513          	addi	a0,a0,-786 # 80021ca0 <ftable>
    80004fba:	ffffc097          	auipc	ra,0xffffc
    80004fbe:	cde080e7          	jalr	-802(ra) # 80000c98 <release>
  return f;
}
    80004fc2:	8526                	mv	a0,s1
    80004fc4:	60e2                	ld	ra,24(sp)
    80004fc6:	6442                	ld	s0,16(sp)
    80004fc8:	64a2                	ld	s1,8(sp)
    80004fca:	6105                	addi	sp,sp,32
    80004fcc:	8082                	ret
    panic("filedup");
    80004fce:	00004517          	auipc	a0,0x4
    80004fd2:	82250513          	addi	a0,a0,-2014 # 800087f0 <syscalls+0x250>
    80004fd6:	ffffb097          	auipc	ra,0xffffb
    80004fda:	568080e7          	jalr	1384(ra) # 8000053e <panic>

0000000080004fde <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004fde:	7139                	addi	sp,sp,-64
    80004fe0:	fc06                	sd	ra,56(sp)
    80004fe2:	f822                	sd	s0,48(sp)
    80004fe4:	f426                	sd	s1,40(sp)
    80004fe6:	f04a                	sd	s2,32(sp)
    80004fe8:	ec4e                	sd	s3,24(sp)
    80004fea:	e852                	sd	s4,16(sp)
    80004fec:	e456                	sd	s5,8(sp)
    80004fee:	0080                	addi	s0,sp,64
    80004ff0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ff2:	0001d517          	auipc	a0,0x1d
    80004ff6:	cae50513          	addi	a0,a0,-850 # 80021ca0 <ftable>
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	bea080e7          	jalr	-1046(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005002:	40dc                	lw	a5,4(s1)
    80005004:	06f05163          	blez	a5,80005066 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005008:	37fd                	addiw	a5,a5,-1
    8000500a:	0007871b          	sext.w	a4,a5
    8000500e:	c0dc                	sw	a5,4(s1)
    80005010:	06e04363          	bgtz	a4,80005076 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005014:	0004a903          	lw	s2,0(s1)
    80005018:	0094ca83          	lbu	s5,9(s1)
    8000501c:	0104ba03          	ld	s4,16(s1)
    80005020:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005024:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005028:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000502c:	0001d517          	auipc	a0,0x1d
    80005030:	c7450513          	addi	a0,a0,-908 # 80021ca0 <ftable>
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	c64080e7          	jalr	-924(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000503c:	4785                	li	a5,1
    8000503e:	04f90d63          	beq	s2,a5,80005098 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005042:	3979                	addiw	s2,s2,-2
    80005044:	4785                	li	a5,1
    80005046:	0527e063          	bltu	a5,s2,80005086 <fileclose+0xa8>
    begin_op();
    8000504a:	00000097          	auipc	ra,0x0
    8000504e:	ac8080e7          	jalr	-1336(ra) # 80004b12 <begin_op>
    iput(ff.ip);
    80005052:	854e                	mv	a0,s3
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	2a6080e7          	jalr	678(ra) # 800042fa <iput>
    end_op();
    8000505c:	00000097          	auipc	ra,0x0
    80005060:	b36080e7          	jalr	-1226(ra) # 80004b92 <end_op>
    80005064:	a00d                	j	80005086 <fileclose+0xa8>
    panic("fileclose");
    80005066:	00003517          	auipc	a0,0x3
    8000506a:	79250513          	addi	a0,a0,1938 # 800087f8 <syscalls+0x258>
    8000506e:	ffffb097          	auipc	ra,0xffffb
    80005072:	4d0080e7          	jalr	1232(ra) # 8000053e <panic>
    release(&ftable.lock);
    80005076:	0001d517          	auipc	a0,0x1d
    8000507a:	c2a50513          	addi	a0,a0,-982 # 80021ca0 <ftable>
    8000507e:	ffffc097          	auipc	ra,0xffffc
    80005082:	c1a080e7          	jalr	-998(ra) # 80000c98 <release>
  }
}
    80005086:	70e2                	ld	ra,56(sp)
    80005088:	7442                	ld	s0,48(sp)
    8000508a:	74a2                	ld	s1,40(sp)
    8000508c:	7902                	ld	s2,32(sp)
    8000508e:	69e2                	ld	s3,24(sp)
    80005090:	6a42                	ld	s4,16(sp)
    80005092:	6aa2                	ld	s5,8(sp)
    80005094:	6121                	addi	sp,sp,64
    80005096:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005098:	85d6                	mv	a1,s5
    8000509a:	8552                	mv	a0,s4
    8000509c:	00000097          	auipc	ra,0x0
    800050a0:	34c080e7          	jalr	844(ra) # 800053e8 <pipeclose>
    800050a4:	b7cd                	j	80005086 <fileclose+0xa8>

00000000800050a6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800050a6:	715d                	addi	sp,sp,-80
    800050a8:	e486                	sd	ra,72(sp)
    800050aa:	e0a2                	sd	s0,64(sp)
    800050ac:	fc26                	sd	s1,56(sp)
    800050ae:	f84a                	sd	s2,48(sp)
    800050b0:	f44e                	sd	s3,40(sp)
    800050b2:	0880                	addi	s0,sp,80
    800050b4:	84aa                	mv	s1,a0
    800050b6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	142080e7          	jalr	322(ra) # 800021fa <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800050c0:	409c                	lw	a5,0(s1)
    800050c2:	37f9                	addiw	a5,a5,-2
    800050c4:	4705                	li	a4,1
    800050c6:	04f76763          	bltu	a4,a5,80005114 <filestat+0x6e>
    800050ca:	892a                	mv	s2,a0
    ilock(f->ip);
    800050cc:	6c88                	ld	a0,24(s1)
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	072080e7          	jalr	114(ra) # 80004140 <ilock>
    stati(f->ip, &st);
    800050d6:	fb840593          	addi	a1,s0,-72
    800050da:	6c88                	ld	a0,24(s1)
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	2ee080e7          	jalr	750(ra) # 800043ca <stati>
    iunlock(f->ip);
    800050e4:	6c88                	ld	a0,24(s1)
    800050e6:	fffff097          	auipc	ra,0xfffff
    800050ea:	11c080e7          	jalr	284(ra) # 80004202 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800050ee:	46e1                	li	a3,24
    800050f0:	fb840613          	addi	a2,s0,-72
    800050f4:	85ce                	mv	a1,s3
    800050f6:	07893503          	ld	a0,120(s2)
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	578080e7          	jalr	1400(ra) # 80001672 <copyout>
    80005102:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005106:	60a6                	ld	ra,72(sp)
    80005108:	6406                	ld	s0,64(sp)
    8000510a:	74e2                	ld	s1,56(sp)
    8000510c:	7942                	ld	s2,48(sp)
    8000510e:	79a2                	ld	s3,40(sp)
    80005110:	6161                	addi	sp,sp,80
    80005112:	8082                	ret
  return -1;
    80005114:	557d                	li	a0,-1
    80005116:	bfc5                	j	80005106 <filestat+0x60>

0000000080005118 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005118:	7179                	addi	sp,sp,-48
    8000511a:	f406                	sd	ra,40(sp)
    8000511c:	f022                	sd	s0,32(sp)
    8000511e:	ec26                	sd	s1,24(sp)
    80005120:	e84a                	sd	s2,16(sp)
    80005122:	e44e                	sd	s3,8(sp)
    80005124:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005126:	00854783          	lbu	a5,8(a0)
    8000512a:	c3d5                	beqz	a5,800051ce <fileread+0xb6>
    8000512c:	84aa                	mv	s1,a0
    8000512e:	89ae                	mv	s3,a1
    80005130:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005132:	411c                	lw	a5,0(a0)
    80005134:	4705                	li	a4,1
    80005136:	04e78963          	beq	a5,a4,80005188 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000513a:	470d                	li	a4,3
    8000513c:	04e78d63          	beq	a5,a4,80005196 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005140:	4709                	li	a4,2
    80005142:	06e79e63          	bne	a5,a4,800051be <fileread+0xa6>
    ilock(f->ip);
    80005146:	6d08                	ld	a0,24(a0)
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	ff8080e7          	jalr	-8(ra) # 80004140 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005150:	874a                	mv	a4,s2
    80005152:	5094                	lw	a3,32(s1)
    80005154:	864e                	mv	a2,s3
    80005156:	4585                	li	a1,1
    80005158:	6c88                	ld	a0,24(s1)
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	29a080e7          	jalr	666(ra) # 800043f4 <readi>
    80005162:	892a                	mv	s2,a0
    80005164:	00a05563          	blez	a0,8000516e <fileread+0x56>
      f->off += r;
    80005168:	509c                	lw	a5,32(s1)
    8000516a:	9fa9                	addw	a5,a5,a0
    8000516c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000516e:	6c88                	ld	a0,24(s1)
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	092080e7          	jalr	146(ra) # 80004202 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005178:	854a                	mv	a0,s2
    8000517a:	70a2                	ld	ra,40(sp)
    8000517c:	7402                	ld	s0,32(sp)
    8000517e:	64e2                	ld	s1,24(sp)
    80005180:	6942                	ld	s2,16(sp)
    80005182:	69a2                	ld	s3,8(sp)
    80005184:	6145                	addi	sp,sp,48
    80005186:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005188:	6908                	ld	a0,16(a0)
    8000518a:	00000097          	auipc	ra,0x0
    8000518e:	3c8080e7          	jalr	968(ra) # 80005552 <piperead>
    80005192:	892a                	mv	s2,a0
    80005194:	b7d5                	j	80005178 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005196:	02451783          	lh	a5,36(a0)
    8000519a:	03079693          	slli	a3,a5,0x30
    8000519e:	92c1                	srli	a3,a3,0x30
    800051a0:	4725                	li	a4,9
    800051a2:	02d76863          	bltu	a4,a3,800051d2 <fileread+0xba>
    800051a6:	0792                	slli	a5,a5,0x4
    800051a8:	0001d717          	auipc	a4,0x1d
    800051ac:	a5870713          	addi	a4,a4,-1448 # 80021c00 <devsw>
    800051b0:	97ba                	add	a5,a5,a4
    800051b2:	639c                	ld	a5,0(a5)
    800051b4:	c38d                	beqz	a5,800051d6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800051b6:	4505                	li	a0,1
    800051b8:	9782                	jalr	a5
    800051ba:	892a                	mv	s2,a0
    800051bc:	bf75                	j	80005178 <fileread+0x60>
    panic("fileread");
    800051be:	00003517          	auipc	a0,0x3
    800051c2:	64a50513          	addi	a0,a0,1610 # 80008808 <syscalls+0x268>
    800051c6:	ffffb097          	auipc	ra,0xffffb
    800051ca:	378080e7          	jalr	888(ra) # 8000053e <panic>
    return -1;
    800051ce:	597d                	li	s2,-1
    800051d0:	b765                	j	80005178 <fileread+0x60>
      return -1;
    800051d2:	597d                	li	s2,-1
    800051d4:	b755                	j	80005178 <fileread+0x60>
    800051d6:	597d                	li	s2,-1
    800051d8:	b745                	j	80005178 <fileread+0x60>

00000000800051da <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800051da:	715d                	addi	sp,sp,-80
    800051dc:	e486                	sd	ra,72(sp)
    800051de:	e0a2                	sd	s0,64(sp)
    800051e0:	fc26                	sd	s1,56(sp)
    800051e2:	f84a                	sd	s2,48(sp)
    800051e4:	f44e                	sd	s3,40(sp)
    800051e6:	f052                	sd	s4,32(sp)
    800051e8:	ec56                	sd	s5,24(sp)
    800051ea:	e85a                	sd	s6,16(sp)
    800051ec:	e45e                	sd	s7,8(sp)
    800051ee:	e062                	sd	s8,0(sp)
    800051f0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800051f2:	00954783          	lbu	a5,9(a0)
    800051f6:	10078663          	beqz	a5,80005302 <filewrite+0x128>
    800051fa:	892a                	mv	s2,a0
    800051fc:	8aae                	mv	s5,a1
    800051fe:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005200:	411c                	lw	a5,0(a0)
    80005202:	4705                	li	a4,1
    80005204:	02e78263          	beq	a5,a4,80005228 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005208:	470d                	li	a4,3
    8000520a:	02e78663          	beq	a5,a4,80005236 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000520e:	4709                	li	a4,2
    80005210:	0ee79163          	bne	a5,a4,800052f2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005214:	0ac05d63          	blez	a2,800052ce <filewrite+0xf4>
    int i = 0;
    80005218:	4981                	li	s3,0
    8000521a:	6b05                	lui	s6,0x1
    8000521c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005220:	6b85                	lui	s7,0x1
    80005222:	c00b8b9b          	addiw	s7,s7,-1024
    80005226:	a861                	j	800052be <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005228:	6908                	ld	a0,16(a0)
    8000522a:	00000097          	auipc	ra,0x0
    8000522e:	22e080e7          	jalr	558(ra) # 80005458 <pipewrite>
    80005232:	8a2a                	mv	s4,a0
    80005234:	a045                	j	800052d4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005236:	02451783          	lh	a5,36(a0)
    8000523a:	03079693          	slli	a3,a5,0x30
    8000523e:	92c1                	srli	a3,a3,0x30
    80005240:	4725                	li	a4,9
    80005242:	0cd76263          	bltu	a4,a3,80005306 <filewrite+0x12c>
    80005246:	0792                	slli	a5,a5,0x4
    80005248:	0001d717          	auipc	a4,0x1d
    8000524c:	9b870713          	addi	a4,a4,-1608 # 80021c00 <devsw>
    80005250:	97ba                	add	a5,a5,a4
    80005252:	679c                	ld	a5,8(a5)
    80005254:	cbdd                	beqz	a5,8000530a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005256:	4505                	li	a0,1
    80005258:	9782                	jalr	a5
    8000525a:	8a2a                	mv	s4,a0
    8000525c:	a8a5                	j	800052d4 <filewrite+0xfa>
    8000525e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005262:	00000097          	auipc	ra,0x0
    80005266:	8b0080e7          	jalr	-1872(ra) # 80004b12 <begin_op>
      ilock(f->ip);
    8000526a:	01893503          	ld	a0,24(s2)
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	ed2080e7          	jalr	-302(ra) # 80004140 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005276:	8762                	mv	a4,s8
    80005278:	02092683          	lw	a3,32(s2)
    8000527c:	01598633          	add	a2,s3,s5
    80005280:	4585                	li	a1,1
    80005282:	01893503          	ld	a0,24(s2)
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	266080e7          	jalr	614(ra) # 800044ec <writei>
    8000528e:	84aa                	mv	s1,a0
    80005290:	00a05763          	blez	a0,8000529e <filewrite+0xc4>
        f->off += r;
    80005294:	02092783          	lw	a5,32(s2)
    80005298:	9fa9                	addw	a5,a5,a0
    8000529a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000529e:	01893503          	ld	a0,24(s2)
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	f60080e7          	jalr	-160(ra) # 80004202 <iunlock>
      end_op();
    800052aa:	00000097          	auipc	ra,0x0
    800052ae:	8e8080e7          	jalr	-1816(ra) # 80004b92 <end_op>

      if(r != n1){
    800052b2:	009c1f63          	bne	s8,s1,800052d0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800052b6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800052ba:	0149db63          	bge	s3,s4,800052d0 <filewrite+0xf6>
      int n1 = n - i;
    800052be:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800052c2:	84be                	mv	s1,a5
    800052c4:	2781                	sext.w	a5,a5
    800052c6:	f8fb5ce3          	bge	s6,a5,8000525e <filewrite+0x84>
    800052ca:	84de                	mv	s1,s7
    800052cc:	bf49                	j	8000525e <filewrite+0x84>
    int i = 0;
    800052ce:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800052d0:	013a1f63          	bne	s4,s3,800052ee <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800052d4:	8552                	mv	a0,s4
    800052d6:	60a6                	ld	ra,72(sp)
    800052d8:	6406                	ld	s0,64(sp)
    800052da:	74e2                	ld	s1,56(sp)
    800052dc:	7942                	ld	s2,48(sp)
    800052de:	79a2                	ld	s3,40(sp)
    800052e0:	7a02                	ld	s4,32(sp)
    800052e2:	6ae2                	ld	s5,24(sp)
    800052e4:	6b42                	ld	s6,16(sp)
    800052e6:	6ba2                	ld	s7,8(sp)
    800052e8:	6c02                	ld	s8,0(sp)
    800052ea:	6161                	addi	sp,sp,80
    800052ec:	8082                	ret
    ret = (i == n ? n : -1);
    800052ee:	5a7d                	li	s4,-1
    800052f0:	b7d5                	j	800052d4 <filewrite+0xfa>
    panic("filewrite");
    800052f2:	00003517          	auipc	a0,0x3
    800052f6:	52650513          	addi	a0,a0,1318 # 80008818 <syscalls+0x278>
    800052fa:	ffffb097          	auipc	ra,0xffffb
    800052fe:	244080e7          	jalr	580(ra) # 8000053e <panic>
    return -1;
    80005302:	5a7d                	li	s4,-1
    80005304:	bfc1                	j	800052d4 <filewrite+0xfa>
      return -1;
    80005306:	5a7d                	li	s4,-1
    80005308:	b7f1                	j	800052d4 <filewrite+0xfa>
    8000530a:	5a7d                	li	s4,-1
    8000530c:	b7e1                	j	800052d4 <filewrite+0xfa>

000000008000530e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000530e:	7179                	addi	sp,sp,-48
    80005310:	f406                	sd	ra,40(sp)
    80005312:	f022                	sd	s0,32(sp)
    80005314:	ec26                	sd	s1,24(sp)
    80005316:	e84a                	sd	s2,16(sp)
    80005318:	e44e                	sd	s3,8(sp)
    8000531a:	e052                	sd	s4,0(sp)
    8000531c:	1800                	addi	s0,sp,48
    8000531e:	84aa                	mv	s1,a0
    80005320:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005322:	0005b023          	sd	zero,0(a1)
    80005326:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000532a:	00000097          	auipc	ra,0x0
    8000532e:	bf8080e7          	jalr	-1032(ra) # 80004f22 <filealloc>
    80005332:	e088                	sd	a0,0(s1)
    80005334:	c551                	beqz	a0,800053c0 <pipealloc+0xb2>
    80005336:	00000097          	auipc	ra,0x0
    8000533a:	bec080e7          	jalr	-1044(ra) # 80004f22 <filealloc>
    8000533e:	00aa3023          	sd	a0,0(s4)
    80005342:	c92d                	beqz	a0,800053b4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005344:	ffffb097          	auipc	ra,0xffffb
    80005348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000534c:	892a                	mv	s2,a0
    8000534e:	c125                	beqz	a0,800053ae <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005350:	4985                	li	s3,1
    80005352:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005356:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000535a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000535e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005362:	00003597          	auipc	a1,0x3
    80005366:	4c658593          	addi	a1,a1,1222 # 80008828 <syscalls+0x288>
    8000536a:	ffffb097          	auipc	ra,0xffffb
    8000536e:	7ea080e7          	jalr	2026(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005372:	609c                	ld	a5,0(s1)
    80005374:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005378:	609c                	ld	a5,0(s1)
    8000537a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000537e:	609c                	ld	a5,0(s1)
    80005380:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005384:	609c                	ld	a5,0(s1)
    80005386:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000538a:	000a3783          	ld	a5,0(s4)
    8000538e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005392:	000a3783          	ld	a5,0(s4)
    80005396:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000539a:	000a3783          	ld	a5,0(s4)
    8000539e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800053a2:	000a3783          	ld	a5,0(s4)
    800053a6:	0127b823          	sd	s2,16(a5)
  return 0;
    800053aa:	4501                	li	a0,0
    800053ac:	a025                	j	800053d4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800053ae:	6088                	ld	a0,0(s1)
    800053b0:	e501                	bnez	a0,800053b8 <pipealloc+0xaa>
    800053b2:	a039                	j	800053c0 <pipealloc+0xb2>
    800053b4:	6088                	ld	a0,0(s1)
    800053b6:	c51d                	beqz	a0,800053e4 <pipealloc+0xd6>
    fileclose(*f0);
    800053b8:	00000097          	auipc	ra,0x0
    800053bc:	c26080e7          	jalr	-986(ra) # 80004fde <fileclose>
  if(*f1)
    800053c0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800053c4:	557d                	li	a0,-1
  if(*f1)
    800053c6:	c799                	beqz	a5,800053d4 <pipealloc+0xc6>
    fileclose(*f1);
    800053c8:	853e                	mv	a0,a5
    800053ca:	00000097          	auipc	ra,0x0
    800053ce:	c14080e7          	jalr	-1004(ra) # 80004fde <fileclose>
  return -1;
    800053d2:	557d                	li	a0,-1
}
    800053d4:	70a2                	ld	ra,40(sp)
    800053d6:	7402                	ld	s0,32(sp)
    800053d8:	64e2                	ld	s1,24(sp)
    800053da:	6942                	ld	s2,16(sp)
    800053dc:	69a2                	ld	s3,8(sp)
    800053de:	6a02                	ld	s4,0(sp)
    800053e0:	6145                	addi	sp,sp,48
    800053e2:	8082                	ret
  return -1;
    800053e4:	557d                	li	a0,-1
    800053e6:	b7fd                	j	800053d4 <pipealloc+0xc6>

00000000800053e8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800053e8:	1101                	addi	sp,sp,-32
    800053ea:	ec06                	sd	ra,24(sp)
    800053ec:	e822                	sd	s0,16(sp)
    800053ee:	e426                	sd	s1,8(sp)
    800053f0:	e04a                	sd	s2,0(sp)
    800053f2:	1000                	addi	s0,sp,32
    800053f4:	84aa                	mv	s1,a0
    800053f6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800053f8:	ffffb097          	auipc	ra,0xffffb
    800053fc:	7ec080e7          	jalr	2028(ra) # 80000be4 <acquire>
  if(writable){
    80005400:	02090d63          	beqz	s2,8000543a <pipeclose+0x52>
    pi->writeopen = 0;
    80005404:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005408:	21848513          	addi	a0,s1,536
    8000540c:	ffffd097          	auipc	ra,0xffffd
    80005410:	7fe080e7          	jalr	2046(ra) # 80002c0a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005414:	2204b783          	ld	a5,544(s1)
    80005418:	eb95                	bnez	a5,8000544c <pipeclose+0x64>
    release(&pi->lock);
    8000541a:	8526                	mv	a0,s1
    8000541c:	ffffc097          	auipc	ra,0xffffc
    80005420:	87c080e7          	jalr	-1924(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005424:	8526                	mv	a0,s1
    80005426:	ffffb097          	auipc	ra,0xffffb
    8000542a:	5d2080e7          	jalr	1490(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000542e:	60e2                	ld	ra,24(sp)
    80005430:	6442                	ld	s0,16(sp)
    80005432:	64a2                	ld	s1,8(sp)
    80005434:	6902                	ld	s2,0(sp)
    80005436:	6105                	addi	sp,sp,32
    80005438:	8082                	ret
    pi->readopen = 0;
    8000543a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000543e:	21c48513          	addi	a0,s1,540
    80005442:	ffffd097          	auipc	ra,0xffffd
    80005446:	7c8080e7          	jalr	1992(ra) # 80002c0a <wakeup>
    8000544a:	b7e9                	j	80005414 <pipeclose+0x2c>
    release(&pi->lock);
    8000544c:	8526                	mv	a0,s1
    8000544e:	ffffc097          	auipc	ra,0xffffc
    80005452:	84a080e7          	jalr	-1974(ra) # 80000c98 <release>
}
    80005456:	bfe1                	j	8000542e <pipeclose+0x46>

0000000080005458 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005458:	7159                	addi	sp,sp,-112
    8000545a:	f486                	sd	ra,104(sp)
    8000545c:	f0a2                	sd	s0,96(sp)
    8000545e:	eca6                	sd	s1,88(sp)
    80005460:	e8ca                	sd	s2,80(sp)
    80005462:	e4ce                	sd	s3,72(sp)
    80005464:	e0d2                	sd	s4,64(sp)
    80005466:	fc56                	sd	s5,56(sp)
    80005468:	f85a                	sd	s6,48(sp)
    8000546a:	f45e                	sd	s7,40(sp)
    8000546c:	f062                	sd	s8,32(sp)
    8000546e:	ec66                	sd	s9,24(sp)
    80005470:	1880                	addi	s0,sp,112
    80005472:	84aa                	mv	s1,a0
    80005474:	8aae                	mv	s5,a1
    80005476:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005478:	ffffd097          	auipc	ra,0xffffd
    8000547c:	d82080e7          	jalr	-638(ra) # 800021fa <myproc>
    80005480:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005482:	8526                	mv	a0,s1
    80005484:	ffffb097          	auipc	ra,0xffffb
    80005488:	760080e7          	jalr	1888(ra) # 80000be4 <acquire>
  while(i < n){
    8000548c:	0d405163          	blez	s4,8000554e <pipewrite+0xf6>
    80005490:	8ba6                	mv	s7,s1
  int i = 0;
    80005492:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005494:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005496:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000549a:	21c48c13          	addi	s8,s1,540
    8000549e:	a08d                	j	80005500 <pipewrite+0xa8>
      release(&pi->lock);
    800054a0:	8526                	mv	a0,s1
    800054a2:	ffffb097          	auipc	ra,0xffffb
    800054a6:	7f6080e7          	jalr	2038(ra) # 80000c98 <release>
      return -1;
    800054aa:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800054ac:	854a                	mv	a0,s2
    800054ae:	70a6                	ld	ra,104(sp)
    800054b0:	7406                	ld	s0,96(sp)
    800054b2:	64e6                	ld	s1,88(sp)
    800054b4:	6946                	ld	s2,80(sp)
    800054b6:	69a6                	ld	s3,72(sp)
    800054b8:	6a06                	ld	s4,64(sp)
    800054ba:	7ae2                	ld	s5,56(sp)
    800054bc:	7b42                	ld	s6,48(sp)
    800054be:	7ba2                	ld	s7,40(sp)
    800054c0:	7c02                	ld	s8,32(sp)
    800054c2:	6ce2                	ld	s9,24(sp)
    800054c4:	6165                	addi	sp,sp,112
    800054c6:	8082                	ret
      wakeup(&pi->nread);
    800054c8:	8566                	mv	a0,s9
    800054ca:	ffffd097          	auipc	ra,0xffffd
    800054ce:	740080e7          	jalr	1856(ra) # 80002c0a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800054d2:	85de                	mv	a1,s7
    800054d4:	8562                	mv	a0,s8
    800054d6:	ffffd097          	auipc	ra,0xffffd
    800054da:	59a080e7          	jalr	1434(ra) # 80002a70 <sleep>
    800054de:	a839                	j	800054fc <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800054e0:	21c4a783          	lw	a5,540(s1)
    800054e4:	0017871b          	addiw	a4,a5,1
    800054e8:	20e4ae23          	sw	a4,540(s1)
    800054ec:	1ff7f793          	andi	a5,a5,511
    800054f0:	97a6                	add	a5,a5,s1
    800054f2:	f9f44703          	lbu	a4,-97(s0)
    800054f6:	00e78c23          	sb	a4,24(a5)
      i++;
    800054fa:	2905                	addiw	s2,s2,1
  while(i < n){
    800054fc:	03495d63          	bge	s2,s4,80005536 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005500:	2204a783          	lw	a5,544(s1)
    80005504:	dfd1                	beqz	a5,800054a0 <pipewrite+0x48>
    80005506:	0409a783          	lw	a5,64(s3)
    8000550a:	fbd9                	bnez	a5,800054a0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000550c:	2184a783          	lw	a5,536(s1)
    80005510:	21c4a703          	lw	a4,540(s1)
    80005514:	2007879b          	addiw	a5,a5,512
    80005518:	faf708e3          	beq	a4,a5,800054c8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000551c:	4685                	li	a3,1
    8000551e:	01590633          	add	a2,s2,s5
    80005522:	f9f40593          	addi	a1,s0,-97
    80005526:	0789b503          	ld	a0,120(s3)
    8000552a:	ffffc097          	auipc	ra,0xffffc
    8000552e:	1d4080e7          	jalr	468(ra) # 800016fe <copyin>
    80005532:	fb6517e3          	bne	a0,s6,800054e0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005536:	21848513          	addi	a0,s1,536
    8000553a:	ffffd097          	auipc	ra,0xffffd
    8000553e:	6d0080e7          	jalr	1744(ra) # 80002c0a <wakeup>
  release(&pi->lock);
    80005542:	8526                	mv	a0,s1
    80005544:	ffffb097          	auipc	ra,0xffffb
    80005548:	754080e7          	jalr	1876(ra) # 80000c98 <release>
  return i;
    8000554c:	b785                	j	800054ac <pipewrite+0x54>
  int i = 0;
    8000554e:	4901                	li	s2,0
    80005550:	b7dd                	j	80005536 <pipewrite+0xde>

0000000080005552 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005552:	715d                	addi	sp,sp,-80
    80005554:	e486                	sd	ra,72(sp)
    80005556:	e0a2                	sd	s0,64(sp)
    80005558:	fc26                	sd	s1,56(sp)
    8000555a:	f84a                	sd	s2,48(sp)
    8000555c:	f44e                	sd	s3,40(sp)
    8000555e:	f052                	sd	s4,32(sp)
    80005560:	ec56                	sd	s5,24(sp)
    80005562:	e85a                	sd	s6,16(sp)
    80005564:	0880                	addi	s0,sp,80
    80005566:	84aa                	mv	s1,a0
    80005568:	892e                	mv	s2,a1
    8000556a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000556c:	ffffd097          	auipc	ra,0xffffd
    80005570:	c8e080e7          	jalr	-882(ra) # 800021fa <myproc>
    80005574:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005576:	8b26                	mv	s6,s1
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffb097          	auipc	ra,0xffffb
    8000557e:	66a080e7          	jalr	1642(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005582:	2184a703          	lw	a4,536(s1)
    80005586:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000558a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000558e:	02f71463          	bne	a4,a5,800055b6 <piperead+0x64>
    80005592:	2244a783          	lw	a5,548(s1)
    80005596:	c385                	beqz	a5,800055b6 <piperead+0x64>
    if(pr->killed){
    80005598:	040a2783          	lw	a5,64(s4)
    8000559c:	ebc1                	bnez	a5,8000562c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000559e:	85da                	mv	a1,s6
    800055a0:	854e                	mv	a0,s3
    800055a2:	ffffd097          	auipc	ra,0xffffd
    800055a6:	4ce080e7          	jalr	1230(ra) # 80002a70 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055aa:	2184a703          	lw	a4,536(s1)
    800055ae:	21c4a783          	lw	a5,540(s1)
    800055b2:	fef700e3          	beq	a4,a5,80005592 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055b6:	09505263          	blez	s5,8000563a <piperead+0xe8>
    800055ba:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055bc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800055be:	2184a783          	lw	a5,536(s1)
    800055c2:	21c4a703          	lw	a4,540(s1)
    800055c6:	02f70d63          	beq	a4,a5,80005600 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800055ca:	0017871b          	addiw	a4,a5,1
    800055ce:	20e4ac23          	sw	a4,536(s1)
    800055d2:	1ff7f793          	andi	a5,a5,511
    800055d6:	97a6                	add	a5,a5,s1
    800055d8:	0187c783          	lbu	a5,24(a5)
    800055dc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055e0:	4685                	li	a3,1
    800055e2:	fbf40613          	addi	a2,s0,-65
    800055e6:	85ca                	mv	a1,s2
    800055e8:	078a3503          	ld	a0,120(s4)
    800055ec:	ffffc097          	auipc	ra,0xffffc
    800055f0:	086080e7          	jalr	134(ra) # 80001672 <copyout>
    800055f4:	01650663          	beq	a0,s6,80005600 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055f8:	2985                	addiw	s3,s3,1
    800055fa:	0905                	addi	s2,s2,1
    800055fc:	fd3a91e3          	bne	s5,s3,800055be <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005600:	21c48513          	addi	a0,s1,540
    80005604:	ffffd097          	auipc	ra,0xffffd
    80005608:	606080e7          	jalr	1542(ra) # 80002c0a <wakeup>
  release(&pi->lock);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffb097          	auipc	ra,0xffffb
    80005612:	68a080e7          	jalr	1674(ra) # 80000c98 <release>
  return i;
}
    80005616:	854e                	mv	a0,s3
    80005618:	60a6                	ld	ra,72(sp)
    8000561a:	6406                	ld	s0,64(sp)
    8000561c:	74e2                	ld	s1,56(sp)
    8000561e:	7942                	ld	s2,48(sp)
    80005620:	79a2                	ld	s3,40(sp)
    80005622:	7a02                	ld	s4,32(sp)
    80005624:	6ae2                	ld	s5,24(sp)
    80005626:	6b42                	ld	s6,16(sp)
    80005628:	6161                	addi	sp,sp,80
    8000562a:	8082                	ret
      release(&pi->lock);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffb097          	auipc	ra,0xffffb
    80005632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>
      return -1;
    80005636:	59fd                	li	s3,-1
    80005638:	bff9                	j	80005616 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000563a:	4981                	li	s3,0
    8000563c:	b7d1                	j	80005600 <piperead+0xae>

000000008000563e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000563e:	df010113          	addi	sp,sp,-528
    80005642:	20113423          	sd	ra,520(sp)
    80005646:	20813023          	sd	s0,512(sp)
    8000564a:	ffa6                	sd	s1,504(sp)
    8000564c:	fbca                	sd	s2,496(sp)
    8000564e:	f7ce                	sd	s3,488(sp)
    80005650:	f3d2                	sd	s4,480(sp)
    80005652:	efd6                	sd	s5,472(sp)
    80005654:	ebda                	sd	s6,464(sp)
    80005656:	e7de                	sd	s7,456(sp)
    80005658:	e3e2                	sd	s8,448(sp)
    8000565a:	ff66                	sd	s9,440(sp)
    8000565c:	fb6a                	sd	s10,432(sp)
    8000565e:	f76e                	sd	s11,424(sp)
    80005660:	0c00                	addi	s0,sp,528
    80005662:	84aa                	mv	s1,a0
    80005664:	dea43c23          	sd	a0,-520(s0)
    80005668:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000566c:	ffffd097          	auipc	ra,0xffffd
    80005670:	b8e080e7          	jalr	-1138(ra) # 800021fa <myproc>
    80005674:	892a                	mv	s2,a0

  begin_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	49c080e7          	jalr	1180(ra) # 80004b12 <begin_op>

  if((ip = namei(path)) == 0){
    8000567e:	8526                	mv	a0,s1
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	276080e7          	jalr	630(ra) # 800048f6 <namei>
    80005688:	c92d                	beqz	a0,800056fa <exec+0xbc>
    8000568a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	ab4080e7          	jalr	-1356(ra) # 80004140 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005694:	04000713          	li	a4,64
    80005698:	4681                	li	a3,0
    8000569a:	e5040613          	addi	a2,s0,-432
    8000569e:	4581                	li	a1,0
    800056a0:	8526                	mv	a0,s1
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	d52080e7          	jalr	-686(ra) # 800043f4 <readi>
    800056aa:	04000793          	li	a5,64
    800056ae:	00f51a63          	bne	a0,a5,800056c2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800056b2:	e5042703          	lw	a4,-432(s0)
    800056b6:	464c47b7          	lui	a5,0x464c4
    800056ba:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800056be:	04f70463          	beq	a4,a5,80005706 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800056c2:	8526                	mv	a0,s1
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	cde080e7          	jalr	-802(ra) # 800043a2 <iunlockput>
    end_op();
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	4c6080e7          	jalr	1222(ra) # 80004b92 <end_op>
  }
  return -1;
    800056d4:	557d                	li	a0,-1
}
    800056d6:	20813083          	ld	ra,520(sp)
    800056da:	20013403          	ld	s0,512(sp)
    800056de:	74fe                	ld	s1,504(sp)
    800056e0:	795e                	ld	s2,496(sp)
    800056e2:	79be                	ld	s3,488(sp)
    800056e4:	7a1e                	ld	s4,480(sp)
    800056e6:	6afe                	ld	s5,472(sp)
    800056e8:	6b5e                	ld	s6,464(sp)
    800056ea:	6bbe                	ld	s7,456(sp)
    800056ec:	6c1e                	ld	s8,448(sp)
    800056ee:	7cfa                	ld	s9,440(sp)
    800056f0:	7d5a                	ld	s10,432(sp)
    800056f2:	7dba                	ld	s11,424(sp)
    800056f4:	21010113          	addi	sp,sp,528
    800056f8:	8082                	ret
    end_op();
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	498080e7          	jalr	1176(ra) # 80004b92 <end_op>
    return -1;
    80005702:	557d                	li	a0,-1
    80005704:	bfc9                	j	800056d6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005706:	854a                	mv	a0,s2
    80005708:	ffffd097          	auipc	ra,0xffffd
    8000570c:	bca080e7          	jalr	-1078(ra) # 800022d2 <proc_pagetable>
    80005710:	8baa                	mv	s7,a0
    80005712:	d945                	beqz	a0,800056c2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005714:	e7042983          	lw	s3,-400(s0)
    80005718:	e8845783          	lhu	a5,-376(s0)
    8000571c:	c7ad                	beqz	a5,80005786 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000571e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005720:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005722:	6c85                	lui	s9,0x1
    80005724:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005728:	def43823          	sd	a5,-528(s0)
    8000572c:	a42d                	j	80005956 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000572e:	00003517          	auipc	a0,0x3
    80005732:	10250513          	addi	a0,a0,258 # 80008830 <syscalls+0x290>
    80005736:	ffffb097          	auipc	ra,0xffffb
    8000573a:	e08080e7          	jalr	-504(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000573e:	8756                	mv	a4,s5
    80005740:	012d86bb          	addw	a3,s11,s2
    80005744:	4581                	li	a1,0
    80005746:	8526                	mv	a0,s1
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	cac080e7          	jalr	-852(ra) # 800043f4 <readi>
    80005750:	2501                	sext.w	a0,a0
    80005752:	1aaa9963          	bne	s5,a0,80005904 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005756:	6785                	lui	a5,0x1
    80005758:	0127893b          	addw	s2,a5,s2
    8000575c:	77fd                	lui	a5,0xfffff
    8000575e:	01478a3b          	addw	s4,a5,s4
    80005762:	1f897163          	bgeu	s2,s8,80005944 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005766:	02091593          	slli	a1,s2,0x20
    8000576a:	9181                	srli	a1,a1,0x20
    8000576c:	95ea                	add	a1,a1,s10
    8000576e:	855e                	mv	a0,s7
    80005770:	ffffc097          	auipc	ra,0xffffc
    80005774:	8fe080e7          	jalr	-1794(ra) # 8000106e <walkaddr>
    80005778:	862a                	mv	a2,a0
    if(pa == 0)
    8000577a:	d955                	beqz	a0,8000572e <exec+0xf0>
      n = PGSIZE;
    8000577c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000577e:	fd9a70e3          	bgeu	s4,s9,8000573e <exec+0x100>
      n = sz - i;
    80005782:	8ad2                	mv	s5,s4
    80005784:	bf6d                	j	8000573e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005786:	4901                	li	s2,0
  iunlockput(ip);
    80005788:	8526                	mv	a0,s1
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	c18080e7          	jalr	-1000(ra) # 800043a2 <iunlockput>
  end_op();
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	400080e7          	jalr	1024(ra) # 80004b92 <end_op>
  p = myproc();
    8000579a:	ffffd097          	auipc	ra,0xffffd
    8000579e:	a60080e7          	jalr	-1440(ra) # 800021fa <myproc>
    800057a2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800057a4:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    800057a8:	6785                	lui	a5,0x1
    800057aa:	17fd                	addi	a5,a5,-1
    800057ac:	993e                	add	s2,s2,a5
    800057ae:	757d                	lui	a0,0xfffff
    800057b0:	00a977b3          	and	a5,s2,a0
    800057b4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800057b8:	6609                	lui	a2,0x2
    800057ba:	963e                	add	a2,a2,a5
    800057bc:	85be                	mv	a1,a5
    800057be:	855e                	mv	a0,s7
    800057c0:	ffffc097          	auipc	ra,0xffffc
    800057c4:	c62080e7          	jalr	-926(ra) # 80001422 <uvmalloc>
    800057c8:	8b2a                	mv	s6,a0
  ip = 0;
    800057ca:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800057cc:	12050c63          	beqz	a0,80005904 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800057d0:	75f9                	lui	a1,0xffffe
    800057d2:	95aa                	add	a1,a1,a0
    800057d4:	855e                	mv	a0,s7
    800057d6:	ffffc097          	auipc	ra,0xffffc
    800057da:	e6a080e7          	jalr	-406(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800057de:	7c7d                	lui	s8,0xfffff
    800057e0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800057e2:	e0043783          	ld	a5,-512(s0)
    800057e6:	6388                	ld	a0,0(a5)
    800057e8:	c535                	beqz	a0,80005854 <exec+0x216>
    800057ea:	e9040993          	addi	s3,s0,-368
    800057ee:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800057f2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800057f4:	ffffb097          	auipc	ra,0xffffb
    800057f8:	670080e7          	jalr	1648(ra) # 80000e64 <strlen>
    800057fc:	2505                	addiw	a0,a0,1
    800057fe:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005802:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005806:	13896363          	bltu	s2,s8,8000592c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000580a:	e0043d83          	ld	s11,-512(s0)
    8000580e:	000dba03          	ld	s4,0(s11)
    80005812:	8552                	mv	a0,s4
    80005814:	ffffb097          	auipc	ra,0xffffb
    80005818:	650080e7          	jalr	1616(ra) # 80000e64 <strlen>
    8000581c:	0015069b          	addiw	a3,a0,1
    80005820:	8652                	mv	a2,s4
    80005822:	85ca                	mv	a1,s2
    80005824:	855e                	mv	a0,s7
    80005826:	ffffc097          	auipc	ra,0xffffc
    8000582a:	e4c080e7          	jalr	-436(ra) # 80001672 <copyout>
    8000582e:	10054363          	bltz	a0,80005934 <exec+0x2f6>
    ustack[argc] = sp;
    80005832:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005836:	0485                	addi	s1,s1,1
    80005838:	008d8793          	addi	a5,s11,8
    8000583c:	e0f43023          	sd	a5,-512(s0)
    80005840:	008db503          	ld	a0,8(s11)
    80005844:	c911                	beqz	a0,80005858 <exec+0x21a>
    if(argc >= MAXARG)
    80005846:	09a1                	addi	s3,s3,8
    80005848:	fb3c96e3          	bne	s9,s3,800057f4 <exec+0x1b6>
  sz = sz1;
    8000584c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005850:	4481                	li	s1,0
    80005852:	a84d                	j	80005904 <exec+0x2c6>
  sp = sz;
    80005854:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005856:	4481                	li	s1,0
  ustack[argc] = 0;
    80005858:	00349793          	slli	a5,s1,0x3
    8000585c:	f9040713          	addi	a4,s0,-112
    80005860:	97ba                	add	a5,a5,a4
    80005862:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005866:	00148693          	addi	a3,s1,1
    8000586a:	068e                	slli	a3,a3,0x3
    8000586c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005870:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005874:	01897663          	bgeu	s2,s8,80005880 <exec+0x242>
  sz = sz1;
    80005878:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000587c:	4481                	li	s1,0
    8000587e:	a059                	j	80005904 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005880:	e9040613          	addi	a2,s0,-368
    80005884:	85ca                	mv	a1,s2
    80005886:	855e                	mv	a0,s7
    80005888:	ffffc097          	auipc	ra,0xffffc
    8000588c:	dea080e7          	jalr	-534(ra) # 80001672 <copyout>
    80005890:	0a054663          	bltz	a0,8000593c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005894:	080ab783          	ld	a5,128(s5)
    80005898:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000589c:	df843783          	ld	a5,-520(s0)
    800058a0:	0007c703          	lbu	a4,0(a5)
    800058a4:	cf11                	beqz	a4,800058c0 <exec+0x282>
    800058a6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800058a8:	02f00693          	li	a3,47
    800058ac:	a039                	j	800058ba <exec+0x27c>
      last = s+1;
    800058ae:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800058b2:	0785                	addi	a5,a5,1
    800058b4:	fff7c703          	lbu	a4,-1(a5)
    800058b8:	c701                	beqz	a4,800058c0 <exec+0x282>
    if(*s == '/')
    800058ba:	fed71ce3          	bne	a4,a3,800058b2 <exec+0x274>
    800058be:	bfc5                	j	800058ae <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800058c0:	4641                	li	a2,16
    800058c2:	df843583          	ld	a1,-520(s0)
    800058c6:	180a8513          	addi	a0,s5,384
    800058ca:	ffffb097          	auipc	ra,0xffffb
    800058ce:	568080e7          	jalr	1384(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800058d2:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    800058d6:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    800058da:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800058de:	080ab783          	ld	a5,128(s5)
    800058e2:	e6843703          	ld	a4,-408(s0)
    800058e6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800058e8:	080ab783          	ld	a5,128(s5)
    800058ec:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800058f0:	85ea                	mv	a1,s10
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	a7c080e7          	jalr	-1412(ra) # 8000236e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800058fa:	0004851b          	sext.w	a0,s1
    800058fe:	bbe1                	j	800056d6 <exec+0x98>
    80005900:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005904:	e0843583          	ld	a1,-504(s0)
    80005908:	855e                	mv	a0,s7
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	a64080e7          	jalr	-1436(ra) # 8000236e <proc_freepagetable>
  if(ip){
    80005912:	da0498e3          	bnez	s1,800056c2 <exec+0x84>
  return -1;
    80005916:	557d                	li	a0,-1
    80005918:	bb7d                	j	800056d6 <exec+0x98>
    8000591a:	e1243423          	sd	s2,-504(s0)
    8000591e:	b7dd                	j	80005904 <exec+0x2c6>
    80005920:	e1243423          	sd	s2,-504(s0)
    80005924:	b7c5                	j	80005904 <exec+0x2c6>
    80005926:	e1243423          	sd	s2,-504(s0)
    8000592a:	bfe9                	j	80005904 <exec+0x2c6>
  sz = sz1;
    8000592c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005930:	4481                	li	s1,0
    80005932:	bfc9                	j	80005904 <exec+0x2c6>
  sz = sz1;
    80005934:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005938:	4481                	li	s1,0
    8000593a:	b7e9                	j	80005904 <exec+0x2c6>
  sz = sz1;
    8000593c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005940:	4481                	li	s1,0
    80005942:	b7c9                	j	80005904 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005944:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005948:	2b05                	addiw	s6,s6,1
    8000594a:	0389899b          	addiw	s3,s3,56
    8000594e:	e8845783          	lhu	a5,-376(s0)
    80005952:	e2fb5be3          	bge	s6,a5,80005788 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005956:	2981                	sext.w	s3,s3
    80005958:	03800713          	li	a4,56
    8000595c:	86ce                	mv	a3,s3
    8000595e:	e1840613          	addi	a2,s0,-488
    80005962:	4581                	li	a1,0
    80005964:	8526                	mv	a0,s1
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	a8e080e7          	jalr	-1394(ra) # 800043f4 <readi>
    8000596e:	03800793          	li	a5,56
    80005972:	f8f517e3          	bne	a0,a5,80005900 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005976:	e1842783          	lw	a5,-488(s0)
    8000597a:	4705                	li	a4,1
    8000597c:	fce796e3          	bne	a5,a4,80005948 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005980:	e4043603          	ld	a2,-448(s0)
    80005984:	e3843783          	ld	a5,-456(s0)
    80005988:	f8f669e3          	bltu	a2,a5,8000591a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000598c:	e2843783          	ld	a5,-472(s0)
    80005990:	963e                	add	a2,a2,a5
    80005992:	f8f667e3          	bltu	a2,a5,80005920 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005996:	85ca                	mv	a1,s2
    80005998:	855e                	mv	a0,s7
    8000599a:	ffffc097          	auipc	ra,0xffffc
    8000599e:	a88080e7          	jalr	-1400(ra) # 80001422 <uvmalloc>
    800059a2:	e0a43423          	sd	a0,-504(s0)
    800059a6:	d141                	beqz	a0,80005926 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800059a8:	e2843d03          	ld	s10,-472(s0)
    800059ac:	df043783          	ld	a5,-528(s0)
    800059b0:	00fd77b3          	and	a5,s10,a5
    800059b4:	fba1                	bnez	a5,80005904 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800059b6:	e2042d83          	lw	s11,-480(s0)
    800059ba:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800059be:	f80c03e3          	beqz	s8,80005944 <exec+0x306>
    800059c2:	8a62                	mv	s4,s8
    800059c4:	4901                	li	s2,0
    800059c6:	b345                	j	80005766 <exec+0x128>

00000000800059c8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800059c8:	7179                	addi	sp,sp,-48
    800059ca:	f406                	sd	ra,40(sp)
    800059cc:	f022                	sd	s0,32(sp)
    800059ce:	ec26                	sd	s1,24(sp)
    800059d0:	e84a                	sd	s2,16(sp)
    800059d2:	1800                	addi	s0,sp,48
    800059d4:	892e                	mv	s2,a1
    800059d6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800059d8:	fdc40593          	addi	a1,s0,-36
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	ba8080e7          	jalr	-1112(ra) # 80003584 <argint>
    800059e4:	04054063          	bltz	a0,80005a24 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800059e8:	fdc42703          	lw	a4,-36(s0)
    800059ec:	47bd                	li	a5,15
    800059ee:	02e7ed63          	bltu	a5,a4,80005a28 <argfd+0x60>
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	808080e7          	jalr	-2040(ra) # 800021fa <myproc>
    800059fa:	fdc42703          	lw	a4,-36(s0)
    800059fe:	01e70793          	addi	a5,a4,30
    80005a02:	078e                	slli	a5,a5,0x3
    80005a04:	953e                	add	a0,a0,a5
    80005a06:	651c                	ld	a5,8(a0)
    80005a08:	c395                	beqz	a5,80005a2c <argfd+0x64>
    return -1;
  if(pfd)
    80005a0a:	00090463          	beqz	s2,80005a12 <argfd+0x4a>
    *pfd = fd;
    80005a0e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005a12:	4501                	li	a0,0
  if(pf)
    80005a14:	c091                	beqz	s1,80005a18 <argfd+0x50>
    *pf = f;
    80005a16:	e09c                	sd	a5,0(s1)
}
    80005a18:	70a2                	ld	ra,40(sp)
    80005a1a:	7402                	ld	s0,32(sp)
    80005a1c:	64e2                	ld	s1,24(sp)
    80005a1e:	6942                	ld	s2,16(sp)
    80005a20:	6145                	addi	sp,sp,48
    80005a22:	8082                	ret
    return -1;
    80005a24:	557d                	li	a0,-1
    80005a26:	bfcd                	j	80005a18 <argfd+0x50>
    return -1;
    80005a28:	557d                	li	a0,-1
    80005a2a:	b7fd                	j	80005a18 <argfd+0x50>
    80005a2c:	557d                	li	a0,-1
    80005a2e:	b7ed                	j	80005a18 <argfd+0x50>

0000000080005a30 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005a30:	1101                	addi	sp,sp,-32
    80005a32:	ec06                	sd	ra,24(sp)
    80005a34:	e822                	sd	s0,16(sp)
    80005a36:	e426                	sd	s1,8(sp)
    80005a38:	1000                	addi	s0,sp,32
    80005a3a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005a3c:	ffffc097          	auipc	ra,0xffffc
    80005a40:	7be080e7          	jalr	1982(ra) # 800021fa <myproc>
    80005a44:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005a46:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    80005a4a:	4501                	li	a0,0
    80005a4c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005a4e:	6398                	ld	a4,0(a5)
    80005a50:	cb19                	beqz	a4,80005a66 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005a52:	2505                	addiw	a0,a0,1
    80005a54:	07a1                	addi	a5,a5,8
    80005a56:	fed51ce3          	bne	a0,a3,80005a4e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005a5a:	557d                	li	a0,-1
}
    80005a5c:	60e2                	ld	ra,24(sp)
    80005a5e:	6442                	ld	s0,16(sp)
    80005a60:	64a2                	ld	s1,8(sp)
    80005a62:	6105                	addi	sp,sp,32
    80005a64:	8082                	ret
      p->ofile[fd] = f;
    80005a66:	01e50793          	addi	a5,a0,30
    80005a6a:	078e                	slli	a5,a5,0x3
    80005a6c:	963e                	add	a2,a2,a5
    80005a6e:	e604                	sd	s1,8(a2)
      return fd;
    80005a70:	b7f5                	j	80005a5c <fdalloc+0x2c>

0000000080005a72 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005a72:	715d                	addi	sp,sp,-80
    80005a74:	e486                	sd	ra,72(sp)
    80005a76:	e0a2                	sd	s0,64(sp)
    80005a78:	fc26                	sd	s1,56(sp)
    80005a7a:	f84a                	sd	s2,48(sp)
    80005a7c:	f44e                	sd	s3,40(sp)
    80005a7e:	f052                	sd	s4,32(sp)
    80005a80:	ec56                	sd	s5,24(sp)
    80005a82:	0880                	addi	s0,sp,80
    80005a84:	89ae                	mv	s3,a1
    80005a86:	8ab2                	mv	s5,a2
    80005a88:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005a8a:	fb040593          	addi	a1,s0,-80
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	e86080e7          	jalr	-378(ra) # 80004914 <nameiparent>
    80005a96:	892a                	mv	s2,a0
    80005a98:	12050f63          	beqz	a0,80005bd6 <create+0x164>
    return 0;

  ilock(dp);
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	6a4080e7          	jalr	1700(ra) # 80004140 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005aa4:	4601                	li	a2,0
    80005aa6:	fb040593          	addi	a1,s0,-80
    80005aaa:	854a                	mv	a0,s2
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	b78080e7          	jalr	-1160(ra) # 80004624 <dirlookup>
    80005ab4:	84aa                	mv	s1,a0
    80005ab6:	c921                	beqz	a0,80005b06 <create+0x94>
    iunlockput(dp);
    80005ab8:	854a                	mv	a0,s2
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	8e8080e7          	jalr	-1816(ra) # 800043a2 <iunlockput>
    ilock(ip);
    80005ac2:	8526                	mv	a0,s1
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	67c080e7          	jalr	1660(ra) # 80004140 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005acc:	2981                	sext.w	s3,s3
    80005ace:	4789                	li	a5,2
    80005ad0:	02f99463          	bne	s3,a5,80005af8 <create+0x86>
    80005ad4:	0444d783          	lhu	a5,68(s1)
    80005ad8:	37f9                	addiw	a5,a5,-2
    80005ada:	17c2                	slli	a5,a5,0x30
    80005adc:	93c1                	srli	a5,a5,0x30
    80005ade:	4705                	li	a4,1
    80005ae0:	00f76c63          	bltu	a4,a5,80005af8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005ae4:	8526                	mv	a0,s1
    80005ae6:	60a6                	ld	ra,72(sp)
    80005ae8:	6406                	ld	s0,64(sp)
    80005aea:	74e2                	ld	s1,56(sp)
    80005aec:	7942                	ld	s2,48(sp)
    80005aee:	79a2                	ld	s3,40(sp)
    80005af0:	7a02                	ld	s4,32(sp)
    80005af2:	6ae2                	ld	s5,24(sp)
    80005af4:	6161                	addi	sp,sp,80
    80005af6:	8082                	ret
    iunlockput(ip);
    80005af8:	8526                	mv	a0,s1
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	8a8080e7          	jalr	-1880(ra) # 800043a2 <iunlockput>
    return 0;
    80005b02:	4481                	li	s1,0
    80005b04:	b7c5                	j	80005ae4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005b06:	85ce                	mv	a1,s3
    80005b08:	00092503          	lw	a0,0(s2)
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	49c080e7          	jalr	1180(ra) # 80003fa8 <ialloc>
    80005b14:	84aa                	mv	s1,a0
    80005b16:	c529                	beqz	a0,80005b60 <create+0xee>
  ilock(ip);
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	628080e7          	jalr	1576(ra) # 80004140 <ilock>
  ip->major = major;
    80005b20:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005b24:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005b28:	4785                	li	a5,1
    80005b2a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b2e:	8526                	mv	a0,s1
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	546080e7          	jalr	1350(ra) # 80004076 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005b38:	2981                	sext.w	s3,s3
    80005b3a:	4785                	li	a5,1
    80005b3c:	02f98a63          	beq	s3,a5,80005b70 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005b40:	40d0                	lw	a2,4(s1)
    80005b42:	fb040593          	addi	a1,s0,-80
    80005b46:	854a                	mv	a0,s2
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	cec080e7          	jalr	-788(ra) # 80004834 <dirlink>
    80005b50:	06054b63          	bltz	a0,80005bc6 <create+0x154>
  iunlockput(dp);
    80005b54:	854a                	mv	a0,s2
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	84c080e7          	jalr	-1972(ra) # 800043a2 <iunlockput>
  return ip;
    80005b5e:	b759                	j	80005ae4 <create+0x72>
    panic("create: ialloc");
    80005b60:	00003517          	auipc	a0,0x3
    80005b64:	cf050513          	addi	a0,a0,-784 # 80008850 <syscalls+0x2b0>
    80005b68:	ffffb097          	auipc	ra,0xffffb
    80005b6c:	9d6080e7          	jalr	-1578(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005b70:	04a95783          	lhu	a5,74(s2)
    80005b74:	2785                	addiw	a5,a5,1
    80005b76:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005b7a:	854a                	mv	a0,s2
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	4fa080e7          	jalr	1274(ra) # 80004076 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005b84:	40d0                	lw	a2,4(s1)
    80005b86:	00003597          	auipc	a1,0x3
    80005b8a:	cda58593          	addi	a1,a1,-806 # 80008860 <syscalls+0x2c0>
    80005b8e:	8526                	mv	a0,s1
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	ca4080e7          	jalr	-860(ra) # 80004834 <dirlink>
    80005b98:	00054f63          	bltz	a0,80005bb6 <create+0x144>
    80005b9c:	00492603          	lw	a2,4(s2)
    80005ba0:	00003597          	auipc	a1,0x3
    80005ba4:	cc858593          	addi	a1,a1,-824 # 80008868 <syscalls+0x2c8>
    80005ba8:	8526                	mv	a0,s1
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	c8a080e7          	jalr	-886(ra) # 80004834 <dirlink>
    80005bb2:	f80557e3          	bgez	a0,80005b40 <create+0xce>
      panic("create dots");
    80005bb6:	00003517          	auipc	a0,0x3
    80005bba:	cba50513          	addi	a0,a0,-838 # 80008870 <syscalls+0x2d0>
    80005bbe:	ffffb097          	auipc	ra,0xffffb
    80005bc2:	980080e7          	jalr	-1664(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005bc6:	00003517          	auipc	a0,0x3
    80005bca:	cba50513          	addi	a0,a0,-838 # 80008880 <syscalls+0x2e0>
    80005bce:	ffffb097          	auipc	ra,0xffffb
    80005bd2:	970080e7          	jalr	-1680(ra) # 8000053e <panic>
    return 0;
    80005bd6:	84aa                	mv	s1,a0
    80005bd8:	b731                	j	80005ae4 <create+0x72>

0000000080005bda <sys_dup>:
{
    80005bda:	7179                	addi	sp,sp,-48
    80005bdc:	f406                	sd	ra,40(sp)
    80005bde:	f022                	sd	s0,32(sp)
    80005be0:	ec26                	sd	s1,24(sp)
    80005be2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005be4:	fd840613          	addi	a2,s0,-40
    80005be8:	4581                	li	a1,0
    80005bea:	4501                	li	a0,0
    80005bec:	00000097          	auipc	ra,0x0
    80005bf0:	ddc080e7          	jalr	-548(ra) # 800059c8 <argfd>
    return -1;
    80005bf4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005bf6:	02054363          	bltz	a0,80005c1c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005bfa:	fd843503          	ld	a0,-40(s0)
    80005bfe:	00000097          	auipc	ra,0x0
    80005c02:	e32080e7          	jalr	-462(ra) # 80005a30 <fdalloc>
    80005c06:	84aa                	mv	s1,a0
    return -1;
    80005c08:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005c0a:	00054963          	bltz	a0,80005c1c <sys_dup+0x42>
  filedup(f);
    80005c0e:	fd843503          	ld	a0,-40(s0)
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	37a080e7          	jalr	890(ra) # 80004f8c <filedup>
  return fd;
    80005c1a:	87a6                	mv	a5,s1
}
    80005c1c:	853e                	mv	a0,a5
    80005c1e:	70a2                	ld	ra,40(sp)
    80005c20:	7402                	ld	s0,32(sp)
    80005c22:	64e2                	ld	s1,24(sp)
    80005c24:	6145                	addi	sp,sp,48
    80005c26:	8082                	ret

0000000080005c28 <sys_read>:
{
    80005c28:	7179                	addi	sp,sp,-48
    80005c2a:	f406                	sd	ra,40(sp)
    80005c2c:	f022                	sd	s0,32(sp)
    80005c2e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c30:	fe840613          	addi	a2,s0,-24
    80005c34:	4581                	li	a1,0
    80005c36:	4501                	li	a0,0
    80005c38:	00000097          	auipc	ra,0x0
    80005c3c:	d90080e7          	jalr	-624(ra) # 800059c8 <argfd>
    return -1;
    80005c40:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c42:	04054163          	bltz	a0,80005c84 <sys_read+0x5c>
    80005c46:	fe440593          	addi	a1,s0,-28
    80005c4a:	4509                	li	a0,2
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	938080e7          	jalr	-1736(ra) # 80003584 <argint>
    return -1;
    80005c54:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c56:	02054763          	bltz	a0,80005c84 <sys_read+0x5c>
    80005c5a:	fd840593          	addi	a1,s0,-40
    80005c5e:	4505                	li	a0,1
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	946080e7          	jalr	-1722(ra) # 800035a6 <argaddr>
    return -1;
    80005c68:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c6a:	00054d63          	bltz	a0,80005c84 <sys_read+0x5c>
  return fileread(f, p, n);
    80005c6e:	fe442603          	lw	a2,-28(s0)
    80005c72:	fd843583          	ld	a1,-40(s0)
    80005c76:	fe843503          	ld	a0,-24(s0)
    80005c7a:	fffff097          	auipc	ra,0xfffff
    80005c7e:	49e080e7          	jalr	1182(ra) # 80005118 <fileread>
    80005c82:	87aa                	mv	a5,a0
}
    80005c84:	853e                	mv	a0,a5
    80005c86:	70a2                	ld	ra,40(sp)
    80005c88:	7402                	ld	s0,32(sp)
    80005c8a:	6145                	addi	sp,sp,48
    80005c8c:	8082                	ret

0000000080005c8e <sys_write>:
{
    80005c8e:	7179                	addi	sp,sp,-48
    80005c90:	f406                	sd	ra,40(sp)
    80005c92:	f022                	sd	s0,32(sp)
    80005c94:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c96:	fe840613          	addi	a2,s0,-24
    80005c9a:	4581                	li	a1,0
    80005c9c:	4501                	li	a0,0
    80005c9e:	00000097          	auipc	ra,0x0
    80005ca2:	d2a080e7          	jalr	-726(ra) # 800059c8 <argfd>
    return -1;
    80005ca6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ca8:	04054163          	bltz	a0,80005cea <sys_write+0x5c>
    80005cac:	fe440593          	addi	a1,s0,-28
    80005cb0:	4509                	li	a0,2
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	8d2080e7          	jalr	-1838(ra) # 80003584 <argint>
    return -1;
    80005cba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005cbc:	02054763          	bltz	a0,80005cea <sys_write+0x5c>
    80005cc0:	fd840593          	addi	a1,s0,-40
    80005cc4:	4505                	li	a0,1
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	8e0080e7          	jalr	-1824(ra) # 800035a6 <argaddr>
    return -1;
    80005cce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005cd0:	00054d63          	bltz	a0,80005cea <sys_write+0x5c>
  return filewrite(f, p, n);
    80005cd4:	fe442603          	lw	a2,-28(s0)
    80005cd8:	fd843583          	ld	a1,-40(s0)
    80005cdc:	fe843503          	ld	a0,-24(s0)
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	4fa080e7          	jalr	1274(ra) # 800051da <filewrite>
    80005ce8:	87aa                	mv	a5,a0
}
    80005cea:	853e                	mv	a0,a5
    80005cec:	70a2                	ld	ra,40(sp)
    80005cee:	7402                	ld	s0,32(sp)
    80005cf0:	6145                	addi	sp,sp,48
    80005cf2:	8082                	ret

0000000080005cf4 <sys_close>:
{
    80005cf4:	1101                	addi	sp,sp,-32
    80005cf6:	ec06                	sd	ra,24(sp)
    80005cf8:	e822                	sd	s0,16(sp)
    80005cfa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005cfc:	fe040613          	addi	a2,s0,-32
    80005d00:	fec40593          	addi	a1,s0,-20
    80005d04:	4501                	li	a0,0
    80005d06:	00000097          	auipc	ra,0x0
    80005d0a:	cc2080e7          	jalr	-830(ra) # 800059c8 <argfd>
    return -1;
    80005d0e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005d10:	02054463          	bltz	a0,80005d38 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005d14:	ffffc097          	auipc	ra,0xffffc
    80005d18:	4e6080e7          	jalr	1254(ra) # 800021fa <myproc>
    80005d1c:	fec42783          	lw	a5,-20(s0)
    80005d20:	07f9                	addi	a5,a5,30
    80005d22:	078e                	slli	a5,a5,0x3
    80005d24:	97aa                	add	a5,a5,a0
    80005d26:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005d2a:	fe043503          	ld	a0,-32(s0)
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	2b0080e7          	jalr	688(ra) # 80004fde <fileclose>
  return 0;
    80005d36:	4781                	li	a5,0
}
    80005d38:	853e                	mv	a0,a5
    80005d3a:	60e2                	ld	ra,24(sp)
    80005d3c:	6442                	ld	s0,16(sp)
    80005d3e:	6105                	addi	sp,sp,32
    80005d40:	8082                	ret

0000000080005d42 <sys_fstat>:
{
    80005d42:	1101                	addi	sp,sp,-32
    80005d44:	ec06                	sd	ra,24(sp)
    80005d46:	e822                	sd	s0,16(sp)
    80005d48:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005d4a:	fe840613          	addi	a2,s0,-24
    80005d4e:	4581                	li	a1,0
    80005d50:	4501                	li	a0,0
    80005d52:	00000097          	auipc	ra,0x0
    80005d56:	c76080e7          	jalr	-906(ra) # 800059c8 <argfd>
    return -1;
    80005d5a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005d5c:	02054563          	bltz	a0,80005d86 <sys_fstat+0x44>
    80005d60:	fe040593          	addi	a1,s0,-32
    80005d64:	4505                	li	a0,1
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	840080e7          	jalr	-1984(ra) # 800035a6 <argaddr>
    return -1;
    80005d6e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005d70:	00054b63          	bltz	a0,80005d86 <sys_fstat+0x44>
  return filestat(f, st);
    80005d74:	fe043583          	ld	a1,-32(s0)
    80005d78:	fe843503          	ld	a0,-24(s0)
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	32a080e7          	jalr	810(ra) # 800050a6 <filestat>
    80005d84:	87aa                	mv	a5,a0
}
    80005d86:	853e                	mv	a0,a5
    80005d88:	60e2                	ld	ra,24(sp)
    80005d8a:	6442                	ld	s0,16(sp)
    80005d8c:	6105                	addi	sp,sp,32
    80005d8e:	8082                	ret

0000000080005d90 <sys_link>:
{
    80005d90:	7169                	addi	sp,sp,-304
    80005d92:	f606                	sd	ra,296(sp)
    80005d94:	f222                	sd	s0,288(sp)
    80005d96:	ee26                	sd	s1,280(sp)
    80005d98:	ea4a                	sd	s2,272(sp)
    80005d9a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d9c:	08000613          	li	a2,128
    80005da0:	ed040593          	addi	a1,s0,-304
    80005da4:	4501                	li	a0,0
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	822080e7          	jalr	-2014(ra) # 800035c8 <argstr>
    return -1;
    80005dae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005db0:	10054e63          	bltz	a0,80005ecc <sys_link+0x13c>
    80005db4:	08000613          	li	a2,128
    80005db8:	f5040593          	addi	a1,s0,-176
    80005dbc:	4505                	li	a0,1
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	80a080e7          	jalr	-2038(ra) # 800035c8 <argstr>
    return -1;
    80005dc6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005dc8:	10054263          	bltz	a0,80005ecc <sys_link+0x13c>
  begin_op();
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	d46080e7          	jalr	-698(ra) # 80004b12 <begin_op>
  if((ip = namei(old)) == 0){
    80005dd4:	ed040513          	addi	a0,s0,-304
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	b1e080e7          	jalr	-1250(ra) # 800048f6 <namei>
    80005de0:	84aa                	mv	s1,a0
    80005de2:	c551                	beqz	a0,80005e6e <sys_link+0xde>
  ilock(ip);
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	35c080e7          	jalr	860(ra) # 80004140 <ilock>
  if(ip->type == T_DIR){
    80005dec:	04449703          	lh	a4,68(s1)
    80005df0:	4785                	li	a5,1
    80005df2:	08f70463          	beq	a4,a5,80005e7a <sys_link+0xea>
  ip->nlink++;
    80005df6:	04a4d783          	lhu	a5,74(s1)
    80005dfa:	2785                	addiw	a5,a5,1
    80005dfc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e00:	8526                	mv	a0,s1
    80005e02:	ffffe097          	auipc	ra,0xffffe
    80005e06:	274080e7          	jalr	628(ra) # 80004076 <iupdate>
  iunlock(ip);
    80005e0a:	8526                	mv	a0,s1
    80005e0c:	ffffe097          	auipc	ra,0xffffe
    80005e10:	3f6080e7          	jalr	1014(ra) # 80004202 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005e14:	fd040593          	addi	a1,s0,-48
    80005e18:	f5040513          	addi	a0,s0,-176
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	af8080e7          	jalr	-1288(ra) # 80004914 <nameiparent>
    80005e24:	892a                	mv	s2,a0
    80005e26:	c935                	beqz	a0,80005e9a <sys_link+0x10a>
  ilock(dp);
    80005e28:	ffffe097          	auipc	ra,0xffffe
    80005e2c:	318080e7          	jalr	792(ra) # 80004140 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005e30:	00092703          	lw	a4,0(s2)
    80005e34:	409c                	lw	a5,0(s1)
    80005e36:	04f71d63          	bne	a4,a5,80005e90 <sys_link+0x100>
    80005e3a:	40d0                	lw	a2,4(s1)
    80005e3c:	fd040593          	addi	a1,s0,-48
    80005e40:	854a                	mv	a0,s2
    80005e42:	fffff097          	auipc	ra,0xfffff
    80005e46:	9f2080e7          	jalr	-1550(ra) # 80004834 <dirlink>
    80005e4a:	04054363          	bltz	a0,80005e90 <sys_link+0x100>
  iunlockput(dp);
    80005e4e:	854a                	mv	a0,s2
    80005e50:	ffffe097          	auipc	ra,0xffffe
    80005e54:	552080e7          	jalr	1362(ra) # 800043a2 <iunlockput>
  iput(ip);
    80005e58:	8526                	mv	a0,s1
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	4a0080e7          	jalr	1184(ra) # 800042fa <iput>
  end_op();
    80005e62:	fffff097          	auipc	ra,0xfffff
    80005e66:	d30080e7          	jalr	-720(ra) # 80004b92 <end_op>
  return 0;
    80005e6a:	4781                	li	a5,0
    80005e6c:	a085                	j	80005ecc <sys_link+0x13c>
    end_op();
    80005e6e:	fffff097          	auipc	ra,0xfffff
    80005e72:	d24080e7          	jalr	-732(ra) # 80004b92 <end_op>
    return -1;
    80005e76:	57fd                	li	a5,-1
    80005e78:	a891                	j	80005ecc <sys_link+0x13c>
    iunlockput(ip);
    80005e7a:	8526                	mv	a0,s1
    80005e7c:	ffffe097          	auipc	ra,0xffffe
    80005e80:	526080e7          	jalr	1318(ra) # 800043a2 <iunlockput>
    end_op();
    80005e84:	fffff097          	auipc	ra,0xfffff
    80005e88:	d0e080e7          	jalr	-754(ra) # 80004b92 <end_op>
    return -1;
    80005e8c:	57fd                	li	a5,-1
    80005e8e:	a83d                	j	80005ecc <sys_link+0x13c>
    iunlockput(dp);
    80005e90:	854a                	mv	a0,s2
    80005e92:	ffffe097          	auipc	ra,0xffffe
    80005e96:	510080e7          	jalr	1296(ra) # 800043a2 <iunlockput>
  ilock(ip);
    80005e9a:	8526                	mv	a0,s1
    80005e9c:	ffffe097          	auipc	ra,0xffffe
    80005ea0:	2a4080e7          	jalr	676(ra) # 80004140 <ilock>
  ip->nlink--;
    80005ea4:	04a4d783          	lhu	a5,74(s1)
    80005ea8:	37fd                	addiw	a5,a5,-1
    80005eaa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005eae:	8526                	mv	a0,s1
    80005eb0:	ffffe097          	auipc	ra,0xffffe
    80005eb4:	1c6080e7          	jalr	454(ra) # 80004076 <iupdate>
  iunlockput(ip);
    80005eb8:	8526                	mv	a0,s1
    80005eba:	ffffe097          	auipc	ra,0xffffe
    80005ebe:	4e8080e7          	jalr	1256(ra) # 800043a2 <iunlockput>
  end_op();
    80005ec2:	fffff097          	auipc	ra,0xfffff
    80005ec6:	cd0080e7          	jalr	-816(ra) # 80004b92 <end_op>
  return -1;
    80005eca:	57fd                	li	a5,-1
}
    80005ecc:	853e                	mv	a0,a5
    80005ece:	70b2                	ld	ra,296(sp)
    80005ed0:	7412                	ld	s0,288(sp)
    80005ed2:	64f2                	ld	s1,280(sp)
    80005ed4:	6952                	ld	s2,272(sp)
    80005ed6:	6155                	addi	sp,sp,304
    80005ed8:	8082                	ret

0000000080005eda <sys_unlink>:
{
    80005eda:	7151                	addi	sp,sp,-240
    80005edc:	f586                	sd	ra,232(sp)
    80005ede:	f1a2                	sd	s0,224(sp)
    80005ee0:	eda6                	sd	s1,216(sp)
    80005ee2:	e9ca                	sd	s2,208(sp)
    80005ee4:	e5ce                	sd	s3,200(sp)
    80005ee6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ee8:	08000613          	li	a2,128
    80005eec:	f3040593          	addi	a1,s0,-208
    80005ef0:	4501                	li	a0,0
    80005ef2:	ffffd097          	auipc	ra,0xffffd
    80005ef6:	6d6080e7          	jalr	1750(ra) # 800035c8 <argstr>
    80005efa:	18054163          	bltz	a0,8000607c <sys_unlink+0x1a2>
  begin_op();
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	c14080e7          	jalr	-1004(ra) # 80004b12 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005f06:	fb040593          	addi	a1,s0,-80
    80005f0a:	f3040513          	addi	a0,s0,-208
    80005f0e:	fffff097          	auipc	ra,0xfffff
    80005f12:	a06080e7          	jalr	-1530(ra) # 80004914 <nameiparent>
    80005f16:	84aa                	mv	s1,a0
    80005f18:	c979                	beqz	a0,80005fee <sys_unlink+0x114>
  ilock(dp);
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	226080e7          	jalr	550(ra) # 80004140 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005f22:	00003597          	auipc	a1,0x3
    80005f26:	93e58593          	addi	a1,a1,-1730 # 80008860 <syscalls+0x2c0>
    80005f2a:	fb040513          	addi	a0,s0,-80
    80005f2e:	ffffe097          	auipc	ra,0xffffe
    80005f32:	6dc080e7          	jalr	1756(ra) # 8000460a <namecmp>
    80005f36:	14050a63          	beqz	a0,8000608a <sys_unlink+0x1b0>
    80005f3a:	00003597          	auipc	a1,0x3
    80005f3e:	92e58593          	addi	a1,a1,-1746 # 80008868 <syscalls+0x2c8>
    80005f42:	fb040513          	addi	a0,s0,-80
    80005f46:	ffffe097          	auipc	ra,0xffffe
    80005f4a:	6c4080e7          	jalr	1732(ra) # 8000460a <namecmp>
    80005f4e:	12050e63          	beqz	a0,8000608a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005f52:	f2c40613          	addi	a2,s0,-212
    80005f56:	fb040593          	addi	a1,s0,-80
    80005f5a:	8526                	mv	a0,s1
    80005f5c:	ffffe097          	auipc	ra,0xffffe
    80005f60:	6c8080e7          	jalr	1736(ra) # 80004624 <dirlookup>
    80005f64:	892a                	mv	s2,a0
    80005f66:	12050263          	beqz	a0,8000608a <sys_unlink+0x1b0>
  ilock(ip);
    80005f6a:	ffffe097          	auipc	ra,0xffffe
    80005f6e:	1d6080e7          	jalr	470(ra) # 80004140 <ilock>
  if(ip->nlink < 1)
    80005f72:	04a91783          	lh	a5,74(s2)
    80005f76:	08f05263          	blez	a5,80005ffa <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f7a:	04491703          	lh	a4,68(s2)
    80005f7e:	4785                	li	a5,1
    80005f80:	08f70563          	beq	a4,a5,8000600a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005f84:	4641                	li	a2,16
    80005f86:	4581                	li	a1,0
    80005f88:	fc040513          	addi	a0,s0,-64
    80005f8c:	ffffb097          	auipc	ra,0xffffb
    80005f90:	d54080e7          	jalr	-684(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f94:	4741                	li	a4,16
    80005f96:	f2c42683          	lw	a3,-212(s0)
    80005f9a:	fc040613          	addi	a2,s0,-64
    80005f9e:	4581                	li	a1,0
    80005fa0:	8526                	mv	a0,s1
    80005fa2:	ffffe097          	auipc	ra,0xffffe
    80005fa6:	54a080e7          	jalr	1354(ra) # 800044ec <writei>
    80005faa:	47c1                	li	a5,16
    80005fac:	0af51563          	bne	a0,a5,80006056 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005fb0:	04491703          	lh	a4,68(s2)
    80005fb4:	4785                	li	a5,1
    80005fb6:	0af70863          	beq	a4,a5,80006066 <sys_unlink+0x18c>
  iunlockput(dp);
    80005fba:	8526                	mv	a0,s1
    80005fbc:	ffffe097          	auipc	ra,0xffffe
    80005fc0:	3e6080e7          	jalr	998(ra) # 800043a2 <iunlockput>
  ip->nlink--;
    80005fc4:	04a95783          	lhu	a5,74(s2)
    80005fc8:	37fd                	addiw	a5,a5,-1
    80005fca:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005fce:	854a                	mv	a0,s2
    80005fd0:	ffffe097          	auipc	ra,0xffffe
    80005fd4:	0a6080e7          	jalr	166(ra) # 80004076 <iupdate>
  iunlockput(ip);
    80005fd8:	854a                	mv	a0,s2
    80005fda:	ffffe097          	auipc	ra,0xffffe
    80005fde:	3c8080e7          	jalr	968(ra) # 800043a2 <iunlockput>
  end_op();
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	bb0080e7          	jalr	-1104(ra) # 80004b92 <end_op>
  return 0;
    80005fea:	4501                	li	a0,0
    80005fec:	a84d                	j	8000609e <sys_unlink+0x1c4>
    end_op();
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	ba4080e7          	jalr	-1116(ra) # 80004b92 <end_op>
    return -1;
    80005ff6:	557d                	li	a0,-1
    80005ff8:	a05d                	j	8000609e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ffa:	00003517          	auipc	a0,0x3
    80005ffe:	89650513          	addi	a0,a0,-1898 # 80008890 <syscalls+0x2f0>
    80006002:	ffffa097          	auipc	ra,0xffffa
    80006006:	53c080e7          	jalr	1340(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000600a:	04c92703          	lw	a4,76(s2)
    8000600e:	02000793          	li	a5,32
    80006012:	f6e7f9e3          	bgeu	a5,a4,80005f84 <sys_unlink+0xaa>
    80006016:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000601a:	4741                	li	a4,16
    8000601c:	86ce                	mv	a3,s3
    8000601e:	f1840613          	addi	a2,s0,-232
    80006022:	4581                	li	a1,0
    80006024:	854a                	mv	a0,s2
    80006026:	ffffe097          	auipc	ra,0xffffe
    8000602a:	3ce080e7          	jalr	974(ra) # 800043f4 <readi>
    8000602e:	47c1                	li	a5,16
    80006030:	00f51b63          	bne	a0,a5,80006046 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006034:	f1845783          	lhu	a5,-232(s0)
    80006038:	e7a1                	bnez	a5,80006080 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000603a:	29c1                	addiw	s3,s3,16
    8000603c:	04c92783          	lw	a5,76(s2)
    80006040:	fcf9ede3          	bltu	s3,a5,8000601a <sys_unlink+0x140>
    80006044:	b781                	j	80005f84 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006046:	00003517          	auipc	a0,0x3
    8000604a:	86250513          	addi	a0,a0,-1950 # 800088a8 <syscalls+0x308>
    8000604e:	ffffa097          	auipc	ra,0xffffa
    80006052:	4f0080e7          	jalr	1264(ra) # 8000053e <panic>
    panic("unlink: writei");
    80006056:	00003517          	auipc	a0,0x3
    8000605a:	86a50513          	addi	a0,a0,-1942 # 800088c0 <syscalls+0x320>
    8000605e:	ffffa097          	auipc	ra,0xffffa
    80006062:	4e0080e7          	jalr	1248(ra) # 8000053e <panic>
    dp->nlink--;
    80006066:	04a4d783          	lhu	a5,74(s1)
    8000606a:	37fd                	addiw	a5,a5,-1
    8000606c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006070:	8526                	mv	a0,s1
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	004080e7          	jalr	4(ra) # 80004076 <iupdate>
    8000607a:	b781                	j	80005fba <sys_unlink+0xe0>
    return -1;
    8000607c:	557d                	li	a0,-1
    8000607e:	a005                	j	8000609e <sys_unlink+0x1c4>
    iunlockput(ip);
    80006080:	854a                	mv	a0,s2
    80006082:	ffffe097          	auipc	ra,0xffffe
    80006086:	320080e7          	jalr	800(ra) # 800043a2 <iunlockput>
  iunlockput(dp);
    8000608a:	8526                	mv	a0,s1
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	316080e7          	jalr	790(ra) # 800043a2 <iunlockput>
  end_op();
    80006094:	fffff097          	auipc	ra,0xfffff
    80006098:	afe080e7          	jalr	-1282(ra) # 80004b92 <end_op>
  return -1;
    8000609c:	557d                	li	a0,-1
}
    8000609e:	70ae                	ld	ra,232(sp)
    800060a0:	740e                	ld	s0,224(sp)
    800060a2:	64ee                	ld	s1,216(sp)
    800060a4:	694e                	ld	s2,208(sp)
    800060a6:	69ae                	ld	s3,200(sp)
    800060a8:	616d                	addi	sp,sp,240
    800060aa:	8082                	ret

00000000800060ac <sys_open>:

uint64
sys_open(void)
{
    800060ac:	7131                	addi	sp,sp,-192
    800060ae:	fd06                	sd	ra,184(sp)
    800060b0:	f922                	sd	s0,176(sp)
    800060b2:	f526                	sd	s1,168(sp)
    800060b4:	f14a                	sd	s2,160(sp)
    800060b6:	ed4e                	sd	s3,152(sp)
    800060b8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800060ba:	08000613          	li	a2,128
    800060be:	f5040593          	addi	a1,s0,-176
    800060c2:	4501                	li	a0,0
    800060c4:	ffffd097          	auipc	ra,0xffffd
    800060c8:	504080e7          	jalr	1284(ra) # 800035c8 <argstr>
    return -1;
    800060cc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800060ce:	0c054163          	bltz	a0,80006190 <sys_open+0xe4>
    800060d2:	f4c40593          	addi	a1,s0,-180
    800060d6:	4505                	li	a0,1
    800060d8:	ffffd097          	auipc	ra,0xffffd
    800060dc:	4ac080e7          	jalr	1196(ra) # 80003584 <argint>
    800060e0:	0a054863          	bltz	a0,80006190 <sys_open+0xe4>

  begin_op();
    800060e4:	fffff097          	auipc	ra,0xfffff
    800060e8:	a2e080e7          	jalr	-1490(ra) # 80004b12 <begin_op>

  if(omode & O_CREATE){
    800060ec:	f4c42783          	lw	a5,-180(s0)
    800060f0:	2007f793          	andi	a5,a5,512
    800060f4:	cbdd                	beqz	a5,800061aa <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800060f6:	4681                	li	a3,0
    800060f8:	4601                	li	a2,0
    800060fa:	4589                	li	a1,2
    800060fc:	f5040513          	addi	a0,s0,-176
    80006100:	00000097          	auipc	ra,0x0
    80006104:	972080e7          	jalr	-1678(ra) # 80005a72 <create>
    80006108:	892a                	mv	s2,a0
    if(ip == 0){
    8000610a:	c959                	beqz	a0,800061a0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000610c:	04491703          	lh	a4,68(s2)
    80006110:	478d                	li	a5,3
    80006112:	00f71763          	bne	a4,a5,80006120 <sys_open+0x74>
    80006116:	04695703          	lhu	a4,70(s2)
    8000611a:	47a5                	li	a5,9
    8000611c:	0ce7ec63          	bltu	a5,a4,800061f4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006120:	fffff097          	auipc	ra,0xfffff
    80006124:	e02080e7          	jalr	-510(ra) # 80004f22 <filealloc>
    80006128:	89aa                	mv	s3,a0
    8000612a:	10050263          	beqz	a0,8000622e <sys_open+0x182>
    8000612e:	00000097          	auipc	ra,0x0
    80006132:	902080e7          	jalr	-1790(ra) # 80005a30 <fdalloc>
    80006136:	84aa                	mv	s1,a0
    80006138:	0e054663          	bltz	a0,80006224 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000613c:	04491703          	lh	a4,68(s2)
    80006140:	478d                	li	a5,3
    80006142:	0cf70463          	beq	a4,a5,8000620a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006146:	4789                	li	a5,2
    80006148:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000614c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006150:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006154:	f4c42783          	lw	a5,-180(s0)
    80006158:	0017c713          	xori	a4,a5,1
    8000615c:	8b05                	andi	a4,a4,1
    8000615e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006162:	0037f713          	andi	a4,a5,3
    80006166:	00e03733          	snez	a4,a4
    8000616a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000616e:	4007f793          	andi	a5,a5,1024
    80006172:	c791                	beqz	a5,8000617e <sys_open+0xd2>
    80006174:	04491703          	lh	a4,68(s2)
    80006178:	4789                	li	a5,2
    8000617a:	08f70f63          	beq	a4,a5,80006218 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000617e:	854a                	mv	a0,s2
    80006180:	ffffe097          	auipc	ra,0xffffe
    80006184:	082080e7          	jalr	130(ra) # 80004202 <iunlock>
  end_op();
    80006188:	fffff097          	auipc	ra,0xfffff
    8000618c:	a0a080e7          	jalr	-1526(ra) # 80004b92 <end_op>

  return fd;
}
    80006190:	8526                	mv	a0,s1
    80006192:	70ea                	ld	ra,184(sp)
    80006194:	744a                	ld	s0,176(sp)
    80006196:	74aa                	ld	s1,168(sp)
    80006198:	790a                	ld	s2,160(sp)
    8000619a:	69ea                	ld	s3,152(sp)
    8000619c:	6129                	addi	sp,sp,192
    8000619e:	8082                	ret
      end_op();
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	9f2080e7          	jalr	-1550(ra) # 80004b92 <end_op>
      return -1;
    800061a8:	b7e5                	j	80006190 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800061aa:	f5040513          	addi	a0,s0,-176
    800061ae:	ffffe097          	auipc	ra,0xffffe
    800061b2:	748080e7          	jalr	1864(ra) # 800048f6 <namei>
    800061b6:	892a                	mv	s2,a0
    800061b8:	c905                	beqz	a0,800061e8 <sys_open+0x13c>
    ilock(ip);
    800061ba:	ffffe097          	auipc	ra,0xffffe
    800061be:	f86080e7          	jalr	-122(ra) # 80004140 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800061c2:	04491703          	lh	a4,68(s2)
    800061c6:	4785                	li	a5,1
    800061c8:	f4f712e3          	bne	a4,a5,8000610c <sys_open+0x60>
    800061cc:	f4c42783          	lw	a5,-180(s0)
    800061d0:	dba1                	beqz	a5,80006120 <sys_open+0x74>
      iunlockput(ip);
    800061d2:	854a                	mv	a0,s2
    800061d4:	ffffe097          	auipc	ra,0xffffe
    800061d8:	1ce080e7          	jalr	462(ra) # 800043a2 <iunlockput>
      end_op();
    800061dc:	fffff097          	auipc	ra,0xfffff
    800061e0:	9b6080e7          	jalr	-1610(ra) # 80004b92 <end_op>
      return -1;
    800061e4:	54fd                	li	s1,-1
    800061e6:	b76d                	j	80006190 <sys_open+0xe4>
      end_op();
    800061e8:	fffff097          	auipc	ra,0xfffff
    800061ec:	9aa080e7          	jalr	-1622(ra) # 80004b92 <end_op>
      return -1;
    800061f0:	54fd                	li	s1,-1
    800061f2:	bf79                	j	80006190 <sys_open+0xe4>
    iunlockput(ip);
    800061f4:	854a                	mv	a0,s2
    800061f6:	ffffe097          	auipc	ra,0xffffe
    800061fa:	1ac080e7          	jalr	428(ra) # 800043a2 <iunlockput>
    end_op();
    800061fe:	fffff097          	auipc	ra,0xfffff
    80006202:	994080e7          	jalr	-1644(ra) # 80004b92 <end_op>
    return -1;
    80006206:	54fd                	li	s1,-1
    80006208:	b761                	j	80006190 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000620a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000620e:	04691783          	lh	a5,70(s2)
    80006212:	02f99223          	sh	a5,36(s3)
    80006216:	bf2d                	j	80006150 <sys_open+0xa4>
    itrunc(ip);
    80006218:	854a                	mv	a0,s2
    8000621a:	ffffe097          	auipc	ra,0xffffe
    8000621e:	034080e7          	jalr	52(ra) # 8000424e <itrunc>
    80006222:	bfb1                	j	8000617e <sys_open+0xd2>
      fileclose(f);
    80006224:	854e                	mv	a0,s3
    80006226:	fffff097          	auipc	ra,0xfffff
    8000622a:	db8080e7          	jalr	-584(ra) # 80004fde <fileclose>
    iunlockput(ip);
    8000622e:	854a                	mv	a0,s2
    80006230:	ffffe097          	auipc	ra,0xffffe
    80006234:	172080e7          	jalr	370(ra) # 800043a2 <iunlockput>
    end_op();
    80006238:	fffff097          	auipc	ra,0xfffff
    8000623c:	95a080e7          	jalr	-1702(ra) # 80004b92 <end_op>
    return -1;
    80006240:	54fd                	li	s1,-1
    80006242:	b7b9                	j	80006190 <sys_open+0xe4>

0000000080006244 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006244:	7175                	addi	sp,sp,-144
    80006246:	e506                	sd	ra,136(sp)
    80006248:	e122                	sd	s0,128(sp)
    8000624a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000624c:	fffff097          	auipc	ra,0xfffff
    80006250:	8c6080e7          	jalr	-1850(ra) # 80004b12 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006254:	08000613          	li	a2,128
    80006258:	f7040593          	addi	a1,s0,-144
    8000625c:	4501                	li	a0,0
    8000625e:	ffffd097          	auipc	ra,0xffffd
    80006262:	36a080e7          	jalr	874(ra) # 800035c8 <argstr>
    80006266:	02054963          	bltz	a0,80006298 <sys_mkdir+0x54>
    8000626a:	4681                	li	a3,0
    8000626c:	4601                	li	a2,0
    8000626e:	4585                	li	a1,1
    80006270:	f7040513          	addi	a0,s0,-144
    80006274:	fffff097          	auipc	ra,0xfffff
    80006278:	7fe080e7          	jalr	2046(ra) # 80005a72 <create>
    8000627c:	cd11                	beqz	a0,80006298 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000627e:	ffffe097          	auipc	ra,0xffffe
    80006282:	124080e7          	jalr	292(ra) # 800043a2 <iunlockput>
  end_op();
    80006286:	fffff097          	auipc	ra,0xfffff
    8000628a:	90c080e7          	jalr	-1780(ra) # 80004b92 <end_op>
  return 0;
    8000628e:	4501                	li	a0,0
}
    80006290:	60aa                	ld	ra,136(sp)
    80006292:	640a                	ld	s0,128(sp)
    80006294:	6149                	addi	sp,sp,144
    80006296:	8082                	ret
    end_op();
    80006298:	fffff097          	auipc	ra,0xfffff
    8000629c:	8fa080e7          	jalr	-1798(ra) # 80004b92 <end_op>
    return -1;
    800062a0:	557d                	li	a0,-1
    800062a2:	b7fd                	j	80006290 <sys_mkdir+0x4c>

00000000800062a4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800062a4:	7135                	addi	sp,sp,-160
    800062a6:	ed06                	sd	ra,152(sp)
    800062a8:	e922                	sd	s0,144(sp)
    800062aa:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800062ac:	fffff097          	auipc	ra,0xfffff
    800062b0:	866080e7          	jalr	-1946(ra) # 80004b12 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800062b4:	08000613          	li	a2,128
    800062b8:	f7040593          	addi	a1,s0,-144
    800062bc:	4501                	li	a0,0
    800062be:	ffffd097          	auipc	ra,0xffffd
    800062c2:	30a080e7          	jalr	778(ra) # 800035c8 <argstr>
    800062c6:	04054a63          	bltz	a0,8000631a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800062ca:	f6c40593          	addi	a1,s0,-148
    800062ce:	4505                	li	a0,1
    800062d0:	ffffd097          	auipc	ra,0xffffd
    800062d4:	2b4080e7          	jalr	692(ra) # 80003584 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800062d8:	04054163          	bltz	a0,8000631a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800062dc:	f6840593          	addi	a1,s0,-152
    800062e0:	4509                	li	a0,2
    800062e2:	ffffd097          	auipc	ra,0xffffd
    800062e6:	2a2080e7          	jalr	674(ra) # 80003584 <argint>
     argint(1, &major) < 0 ||
    800062ea:	02054863          	bltz	a0,8000631a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800062ee:	f6841683          	lh	a3,-152(s0)
    800062f2:	f6c41603          	lh	a2,-148(s0)
    800062f6:	458d                	li	a1,3
    800062f8:	f7040513          	addi	a0,s0,-144
    800062fc:	fffff097          	auipc	ra,0xfffff
    80006300:	776080e7          	jalr	1910(ra) # 80005a72 <create>
     argint(2, &minor) < 0 ||
    80006304:	c919                	beqz	a0,8000631a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006306:	ffffe097          	auipc	ra,0xffffe
    8000630a:	09c080e7          	jalr	156(ra) # 800043a2 <iunlockput>
  end_op();
    8000630e:	fffff097          	auipc	ra,0xfffff
    80006312:	884080e7          	jalr	-1916(ra) # 80004b92 <end_op>
  return 0;
    80006316:	4501                	li	a0,0
    80006318:	a031                	j	80006324 <sys_mknod+0x80>
    end_op();
    8000631a:	fffff097          	auipc	ra,0xfffff
    8000631e:	878080e7          	jalr	-1928(ra) # 80004b92 <end_op>
    return -1;
    80006322:	557d                	li	a0,-1
}
    80006324:	60ea                	ld	ra,152(sp)
    80006326:	644a                	ld	s0,144(sp)
    80006328:	610d                	addi	sp,sp,160
    8000632a:	8082                	ret

000000008000632c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000632c:	7135                	addi	sp,sp,-160
    8000632e:	ed06                	sd	ra,152(sp)
    80006330:	e922                	sd	s0,144(sp)
    80006332:	e526                	sd	s1,136(sp)
    80006334:	e14a                	sd	s2,128(sp)
    80006336:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006338:	ffffc097          	auipc	ra,0xffffc
    8000633c:	ec2080e7          	jalr	-318(ra) # 800021fa <myproc>
    80006340:	892a                	mv	s2,a0
  
  begin_op();
    80006342:	ffffe097          	auipc	ra,0xffffe
    80006346:	7d0080e7          	jalr	2000(ra) # 80004b12 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000634a:	08000613          	li	a2,128
    8000634e:	f6040593          	addi	a1,s0,-160
    80006352:	4501                	li	a0,0
    80006354:	ffffd097          	auipc	ra,0xffffd
    80006358:	274080e7          	jalr	628(ra) # 800035c8 <argstr>
    8000635c:	04054b63          	bltz	a0,800063b2 <sys_chdir+0x86>
    80006360:	f6040513          	addi	a0,s0,-160
    80006364:	ffffe097          	auipc	ra,0xffffe
    80006368:	592080e7          	jalr	1426(ra) # 800048f6 <namei>
    8000636c:	84aa                	mv	s1,a0
    8000636e:	c131                	beqz	a0,800063b2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006370:	ffffe097          	auipc	ra,0xffffe
    80006374:	dd0080e7          	jalr	-560(ra) # 80004140 <ilock>
  if(ip->type != T_DIR){
    80006378:	04449703          	lh	a4,68(s1)
    8000637c:	4785                	li	a5,1
    8000637e:	04f71063          	bne	a4,a5,800063be <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006382:	8526                	mv	a0,s1
    80006384:	ffffe097          	auipc	ra,0xffffe
    80006388:	e7e080e7          	jalr	-386(ra) # 80004202 <iunlock>
  iput(p->cwd);
    8000638c:	17893503          	ld	a0,376(s2)
    80006390:	ffffe097          	auipc	ra,0xffffe
    80006394:	f6a080e7          	jalr	-150(ra) # 800042fa <iput>
  end_op();
    80006398:	ffffe097          	auipc	ra,0xffffe
    8000639c:	7fa080e7          	jalr	2042(ra) # 80004b92 <end_op>
  p->cwd = ip;
    800063a0:	16993c23          	sd	s1,376(s2)
  return 0;
    800063a4:	4501                	li	a0,0
}
    800063a6:	60ea                	ld	ra,152(sp)
    800063a8:	644a                	ld	s0,144(sp)
    800063aa:	64aa                	ld	s1,136(sp)
    800063ac:	690a                	ld	s2,128(sp)
    800063ae:	610d                	addi	sp,sp,160
    800063b0:	8082                	ret
    end_op();
    800063b2:	ffffe097          	auipc	ra,0xffffe
    800063b6:	7e0080e7          	jalr	2016(ra) # 80004b92 <end_op>
    return -1;
    800063ba:	557d                	li	a0,-1
    800063bc:	b7ed                	j	800063a6 <sys_chdir+0x7a>
    iunlockput(ip);
    800063be:	8526                	mv	a0,s1
    800063c0:	ffffe097          	auipc	ra,0xffffe
    800063c4:	fe2080e7          	jalr	-30(ra) # 800043a2 <iunlockput>
    end_op();
    800063c8:	ffffe097          	auipc	ra,0xffffe
    800063cc:	7ca080e7          	jalr	1994(ra) # 80004b92 <end_op>
    return -1;
    800063d0:	557d                	li	a0,-1
    800063d2:	bfd1                	j	800063a6 <sys_chdir+0x7a>

00000000800063d4 <sys_exec>:

uint64
sys_exec(void)
{
    800063d4:	7145                	addi	sp,sp,-464
    800063d6:	e786                	sd	ra,456(sp)
    800063d8:	e3a2                	sd	s0,448(sp)
    800063da:	ff26                	sd	s1,440(sp)
    800063dc:	fb4a                	sd	s2,432(sp)
    800063de:	f74e                	sd	s3,424(sp)
    800063e0:	f352                	sd	s4,416(sp)
    800063e2:	ef56                	sd	s5,408(sp)
    800063e4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800063e6:	08000613          	li	a2,128
    800063ea:	f4040593          	addi	a1,s0,-192
    800063ee:	4501                	li	a0,0
    800063f0:	ffffd097          	auipc	ra,0xffffd
    800063f4:	1d8080e7          	jalr	472(ra) # 800035c8 <argstr>
    return -1;
    800063f8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800063fa:	0c054a63          	bltz	a0,800064ce <sys_exec+0xfa>
    800063fe:	e3840593          	addi	a1,s0,-456
    80006402:	4505                	li	a0,1
    80006404:	ffffd097          	auipc	ra,0xffffd
    80006408:	1a2080e7          	jalr	418(ra) # 800035a6 <argaddr>
    8000640c:	0c054163          	bltz	a0,800064ce <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006410:	10000613          	li	a2,256
    80006414:	4581                	li	a1,0
    80006416:	e4040513          	addi	a0,s0,-448
    8000641a:	ffffb097          	auipc	ra,0xffffb
    8000641e:	8c6080e7          	jalr	-1850(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006422:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006426:	89a6                	mv	s3,s1
    80006428:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000642a:	02000a13          	li	s4,32
    8000642e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006432:	00391513          	slli	a0,s2,0x3
    80006436:	e3040593          	addi	a1,s0,-464
    8000643a:	e3843783          	ld	a5,-456(s0)
    8000643e:	953e                	add	a0,a0,a5
    80006440:	ffffd097          	auipc	ra,0xffffd
    80006444:	0aa080e7          	jalr	170(ra) # 800034ea <fetchaddr>
    80006448:	02054a63          	bltz	a0,8000647c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000644c:	e3043783          	ld	a5,-464(s0)
    80006450:	c3b9                	beqz	a5,80006496 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006452:	ffffa097          	auipc	ra,0xffffa
    80006456:	6a2080e7          	jalr	1698(ra) # 80000af4 <kalloc>
    8000645a:	85aa                	mv	a1,a0
    8000645c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006460:	cd11                	beqz	a0,8000647c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006462:	6605                	lui	a2,0x1
    80006464:	e3043503          	ld	a0,-464(s0)
    80006468:	ffffd097          	auipc	ra,0xffffd
    8000646c:	0d4080e7          	jalr	212(ra) # 8000353c <fetchstr>
    80006470:	00054663          	bltz	a0,8000647c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006474:	0905                	addi	s2,s2,1
    80006476:	09a1                	addi	s3,s3,8
    80006478:	fb491be3          	bne	s2,s4,8000642e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000647c:	10048913          	addi	s2,s1,256
    80006480:	6088                	ld	a0,0(s1)
    80006482:	c529                	beqz	a0,800064cc <sys_exec+0xf8>
    kfree(argv[i]);
    80006484:	ffffa097          	auipc	ra,0xffffa
    80006488:	574080e7          	jalr	1396(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000648c:	04a1                	addi	s1,s1,8
    8000648e:	ff2499e3          	bne	s1,s2,80006480 <sys_exec+0xac>
  return -1;
    80006492:	597d                	li	s2,-1
    80006494:	a82d                	j	800064ce <sys_exec+0xfa>
      argv[i] = 0;
    80006496:	0a8e                	slli	s5,s5,0x3
    80006498:	fc040793          	addi	a5,s0,-64
    8000649c:	9abe                	add	s5,s5,a5
    8000649e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800064a2:	e4040593          	addi	a1,s0,-448
    800064a6:	f4040513          	addi	a0,s0,-192
    800064aa:	fffff097          	auipc	ra,0xfffff
    800064ae:	194080e7          	jalr	404(ra) # 8000563e <exec>
    800064b2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064b4:	10048993          	addi	s3,s1,256
    800064b8:	6088                	ld	a0,0(s1)
    800064ba:	c911                	beqz	a0,800064ce <sys_exec+0xfa>
    kfree(argv[i]);
    800064bc:	ffffa097          	auipc	ra,0xffffa
    800064c0:	53c080e7          	jalr	1340(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064c4:	04a1                	addi	s1,s1,8
    800064c6:	ff3499e3          	bne	s1,s3,800064b8 <sys_exec+0xe4>
    800064ca:	a011                	j	800064ce <sys_exec+0xfa>
  return -1;
    800064cc:	597d                	li	s2,-1
}
    800064ce:	854a                	mv	a0,s2
    800064d0:	60be                	ld	ra,456(sp)
    800064d2:	641e                	ld	s0,448(sp)
    800064d4:	74fa                	ld	s1,440(sp)
    800064d6:	795a                	ld	s2,432(sp)
    800064d8:	79ba                	ld	s3,424(sp)
    800064da:	7a1a                	ld	s4,416(sp)
    800064dc:	6afa                	ld	s5,408(sp)
    800064de:	6179                	addi	sp,sp,464
    800064e0:	8082                	ret

00000000800064e2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800064e2:	7139                	addi	sp,sp,-64
    800064e4:	fc06                	sd	ra,56(sp)
    800064e6:	f822                	sd	s0,48(sp)
    800064e8:	f426                	sd	s1,40(sp)
    800064ea:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800064ec:	ffffc097          	auipc	ra,0xffffc
    800064f0:	d0e080e7          	jalr	-754(ra) # 800021fa <myproc>
    800064f4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800064f6:	fd840593          	addi	a1,s0,-40
    800064fa:	4501                	li	a0,0
    800064fc:	ffffd097          	auipc	ra,0xffffd
    80006500:	0aa080e7          	jalr	170(ra) # 800035a6 <argaddr>
    return -1;
    80006504:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006506:	0e054063          	bltz	a0,800065e6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000650a:	fc840593          	addi	a1,s0,-56
    8000650e:	fd040513          	addi	a0,s0,-48
    80006512:	fffff097          	auipc	ra,0xfffff
    80006516:	dfc080e7          	jalr	-516(ra) # 8000530e <pipealloc>
    return -1;
    8000651a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000651c:	0c054563          	bltz	a0,800065e6 <sys_pipe+0x104>
  fd0 = -1;
    80006520:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006524:	fd043503          	ld	a0,-48(s0)
    80006528:	fffff097          	auipc	ra,0xfffff
    8000652c:	508080e7          	jalr	1288(ra) # 80005a30 <fdalloc>
    80006530:	fca42223          	sw	a0,-60(s0)
    80006534:	08054c63          	bltz	a0,800065cc <sys_pipe+0xea>
    80006538:	fc843503          	ld	a0,-56(s0)
    8000653c:	fffff097          	auipc	ra,0xfffff
    80006540:	4f4080e7          	jalr	1268(ra) # 80005a30 <fdalloc>
    80006544:	fca42023          	sw	a0,-64(s0)
    80006548:	06054863          	bltz	a0,800065b8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000654c:	4691                	li	a3,4
    8000654e:	fc440613          	addi	a2,s0,-60
    80006552:	fd843583          	ld	a1,-40(s0)
    80006556:	7ca8                	ld	a0,120(s1)
    80006558:	ffffb097          	auipc	ra,0xffffb
    8000655c:	11a080e7          	jalr	282(ra) # 80001672 <copyout>
    80006560:	02054063          	bltz	a0,80006580 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006564:	4691                	li	a3,4
    80006566:	fc040613          	addi	a2,s0,-64
    8000656a:	fd843583          	ld	a1,-40(s0)
    8000656e:	0591                	addi	a1,a1,4
    80006570:	7ca8                	ld	a0,120(s1)
    80006572:	ffffb097          	auipc	ra,0xffffb
    80006576:	100080e7          	jalr	256(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000657a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000657c:	06055563          	bgez	a0,800065e6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006580:	fc442783          	lw	a5,-60(s0)
    80006584:	07f9                	addi	a5,a5,30
    80006586:	078e                	slli	a5,a5,0x3
    80006588:	97a6                	add	a5,a5,s1
    8000658a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    8000658e:	fc042503          	lw	a0,-64(s0)
    80006592:	0579                	addi	a0,a0,30
    80006594:	050e                	slli	a0,a0,0x3
    80006596:	9526                	add	a0,a0,s1
    80006598:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000659c:	fd043503          	ld	a0,-48(s0)
    800065a0:	fffff097          	auipc	ra,0xfffff
    800065a4:	a3e080e7          	jalr	-1474(ra) # 80004fde <fileclose>
    fileclose(wf);
    800065a8:	fc843503          	ld	a0,-56(s0)
    800065ac:	fffff097          	auipc	ra,0xfffff
    800065b0:	a32080e7          	jalr	-1486(ra) # 80004fde <fileclose>
    return -1;
    800065b4:	57fd                	li	a5,-1
    800065b6:	a805                	j	800065e6 <sys_pipe+0x104>
    if(fd0 >= 0)
    800065b8:	fc442783          	lw	a5,-60(s0)
    800065bc:	0007c863          	bltz	a5,800065cc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800065c0:	01e78513          	addi	a0,a5,30
    800065c4:	050e                	slli	a0,a0,0x3
    800065c6:	9526                	add	a0,a0,s1
    800065c8:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800065cc:	fd043503          	ld	a0,-48(s0)
    800065d0:	fffff097          	auipc	ra,0xfffff
    800065d4:	a0e080e7          	jalr	-1522(ra) # 80004fde <fileclose>
    fileclose(wf);
    800065d8:	fc843503          	ld	a0,-56(s0)
    800065dc:	fffff097          	auipc	ra,0xfffff
    800065e0:	a02080e7          	jalr	-1534(ra) # 80004fde <fileclose>
    return -1;
    800065e4:	57fd                	li	a5,-1
}
    800065e6:	853e                	mv	a0,a5
    800065e8:	70e2                	ld	ra,56(sp)
    800065ea:	7442                	ld	s0,48(sp)
    800065ec:	74a2                	ld	s1,40(sp)
    800065ee:	6121                	addi	sp,sp,64
    800065f0:	8082                	ret
	...

0000000080006600 <kernelvec>:
    80006600:	7111                	addi	sp,sp,-256
    80006602:	e006                	sd	ra,0(sp)
    80006604:	e40a                	sd	sp,8(sp)
    80006606:	e80e                	sd	gp,16(sp)
    80006608:	ec12                	sd	tp,24(sp)
    8000660a:	f016                	sd	t0,32(sp)
    8000660c:	f41a                	sd	t1,40(sp)
    8000660e:	f81e                	sd	t2,48(sp)
    80006610:	fc22                	sd	s0,56(sp)
    80006612:	e0a6                	sd	s1,64(sp)
    80006614:	e4aa                	sd	a0,72(sp)
    80006616:	e8ae                	sd	a1,80(sp)
    80006618:	ecb2                	sd	a2,88(sp)
    8000661a:	f0b6                	sd	a3,96(sp)
    8000661c:	f4ba                	sd	a4,104(sp)
    8000661e:	f8be                	sd	a5,112(sp)
    80006620:	fcc2                	sd	a6,120(sp)
    80006622:	e146                	sd	a7,128(sp)
    80006624:	e54a                	sd	s2,136(sp)
    80006626:	e94e                	sd	s3,144(sp)
    80006628:	ed52                	sd	s4,152(sp)
    8000662a:	f156                	sd	s5,160(sp)
    8000662c:	f55a                	sd	s6,168(sp)
    8000662e:	f95e                	sd	s7,176(sp)
    80006630:	fd62                	sd	s8,184(sp)
    80006632:	e1e6                	sd	s9,192(sp)
    80006634:	e5ea                	sd	s10,200(sp)
    80006636:	e9ee                	sd	s11,208(sp)
    80006638:	edf2                	sd	t3,216(sp)
    8000663a:	f1f6                	sd	t4,224(sp)
    8000663c:	f5fa                	sd	t5,232(sp)
    8000663e:	f9fe                	sd	t6,240(sp)
    80006640:	d77fc0ef          	jal	ra,800033b6 <kerneltrap>
    80006644:	6082                	ld	ra,0(sp)
    80006646:	6122                	ld	sp,8(sp)
    80006648:	61c2                	ld	gp,16(sp)
    8000664a:	7282                	ld	t0,32(sp)
    8000664c:	7322                	ld	t1,40(sp)
    8000664e:	73c2                	ld	t2,48(sp)
    80006650:	7462                	ld	s0,56(sp)
    80006652:	6486                	ld	s1,64(sp)
    80006654:	6526                	ld	a0,72(sp)
    80006656:	65c6                	ld	a1,80(sp)
    80006658:	6666                	ld	a2,88(sp)
    8000665a:	7686                	ld	a3,96(sp)
    8000665c:	7726                	ld	a4,104(sp)
    8000665e:	77c6                	ld	a5,112(sp)
    80006660:	7866                	ld	a6,120(sp)
    80006662:	688a                	ld	a7,128(sp)
    80006664:	692a                	ld	s2,136(sp)
    80006666:	69ca                	ld	s3,144(sp)
    80006668:	6a6a                	ld	s4,152(sp)
    8000666a:	7a8a                	ld	s5,160(sp)
    8000666c:	7b2a                	ld	s6,168(sp)
    8000666e:	7bca                	ld	s7,176(sp)
    80006670:	7c6a                	ld	s8,184(sp)
    80006672:	6c8e                	ld	s9,192(sp)
    80006674:	6d2e                	ld	s10,200(sp)
    80006676:	6dce                	ld	s11,208(sp)
    80006678:	6e6e                	ld	t3,216(sp)
    8000667a:	7e8e                	ld	t4,224(sp)
    8000667c:	7f2e                	ld	t5,232(sp)
    8000667e:	7fce                	ld	t6,240(sp)
    80006680:	6111                	addi	sp,sp,256
    80006682:	10200073          	sret
    80006686:	00000013          	nop
    8000668a:	00000013          	nop
    8000668e:	0001                	nop

0000000080006690 <timervec>:
    80006690:	34051573          	csrrw	a0,mscratch,a0
    80006694:	e10c                	sd	a1,0(a0)
    80006696:	e510                	sd	a2,8(a0)
    80006698:	e914                	sd	a3,16(a0)
    8000669a:	6d0c                	ld	a1,24(a0)
    8000669c:	7110                	ld	a2,32(a0)
    8000669e:	6194                	ld	a3,0(a1)
    800066a0:	96b2                	add	a3,a3,a2
    800066a2:	e194                	sd	a3,0(a1)
    800066a4:	4589                	li	a1,2
    800066a6:	14459073          	csrw	sip,a1
    800066aa:	6914                	ld	a3,16(a0)
    800066ac:	6510                	ld	a2,8(a0)
    800066ae:	610c                	ld	a1,0(a0)
    800066b0:	34051573          	csrrw	a0,mscratch,a0
    800066b4:	30200073          	mret
	...

00000000800066ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800066ba:	1141                	addi	sp,sp,-16
    800066bc:	e422                	sd	s0,8(sp)
    800066be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800066c0:	0c0007b7          	lui	a5,0xc000
    800066c4:	4705                	li	a4,1
    800066c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800066c8:	c3d8                	sw	a4,4(a5)
}
    800066ca:	6422                	ld	s0,8(sp)
    800066cc:	0141                	addi	sp,sp,16
    800066ce:	8082                	ret

00000000800066d0 <plicinithart>:

void
plicinithart(void)
{
    800066d0:	1141                	addi	sp,sp,-16
    800066d2:	e406                	sd	ra,8(sp)
    800066d4:	e022                	sd	s0,0(sp)
    800066d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800066d8:	ffffc097          	auipc	ra,0xffffc
    800066dc:	aee080e7          	jalr	-1298(ra) # 800021c6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800066e0:	0085171b          	slliw	a4,a0,0x8
    800066e4:	0c0027b7          	lui	a5,0xc002
    800066e8:	97ba                	add	a5,a5,a4
    800066ea:	40200713          	li	a4,1026
    800066ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800066f2:	00d5151b          	slliw	a0,a0,0xd
    800066f6:	0c2017b7          	lui	a5,0xc201
    800066fa:	953e                	add	a0,a0,a5
    800066fc:	00052023          	sw	zero,0(a0)
}
    80006700:	60a2                	ld	ra,8(sp)
    80006702:	6402                	ld	s0,0(sp)
    80006704:	0141                	addi	sp,sp,16
    80006706:	8082                	ret

0000000080006708 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006708:	1141                	addi	sp,sp,-16
    8000670a:	e406                	sd	ra,8(sp)
    8000670c:	e022                	sd	s0,0(sp)
    8000670e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006710:	ffffc097          	auipc	ra,0xffffc
    80006714:	ab6080e7          	jalr	-1354(ra) # 800021c6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006718:	00d5179b          	slliw	a5,a0,0xd
    8000671c:	0c201537          	lui	a0,0xc201
    80006720:	953e                	add	a0,a0,a5
  return irq;
}
    80006722:	4148                	lw	a0,4(a0)
    80006724:	60a2                	ld	ra,8(sp)
    80006726:	6402                	ld	s0,0(sp)
    80006728:	0141                	addi	sp,sp,16
    8000672a:	8082                	ret

000000008000672c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000672c:	1101                	addi	sp,sp,-32
    8000672e:	ec06                	sd	ra,24(sp)
    80006730:	e822                	sd	s0,16(sp)
    80006732:	e426                	sd	s1,8(sp)
    80006734:	1000                	addi	s0,sp,32
    80006736:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006738:	ffffc097          	auipc	ra,0xffffc
    8000673c:	a8e080e7          	jalr	-1394(ra) # 800021c6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006740:	00d5151b          	slliw	a0,a0,0xd
    80006744:	0c2017b7          	lui	a5,0xc201
    80006748:	97aa                	add	a5,a5,a0
    8000674a:	c3c4                	sw	s1,4(a5)
}
    8000674c:	60e2                	ld	ra,24(sp)
    8000674e:	6442                	ld	s0,16(sp)
    80006750:	64a2                	ld	s1,8(sp)
    80006752:	6105                	addi	sp,sp,32
    80006754:	8082                	ret

0000000080006756 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006756:	1141                	addi	sp,sp,-16
    80006758:	e406                	sd	ra,8(sp)
    8000675a:	e022                	sd	s0,0(sp)
    8000675c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000675e:	479d                	li	a5,7
    80006760:	06a7c963          	blt	a5,a0,800067d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006764:	0001d797          	auipc	a5,0x1d
    80006768:	89c78793          	addi	a5,a5,-1892 # 80023000 <disk>
    8000676c:	00a78733          	add	a4,a5,a0
    80006770:	6789                	lui	a5,0x2
    80006772:	97ba                	add	a5,a5,a4
    80006774:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006778:	e7ad                	bnez	a5,800067e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000677a:	00451793          	slli	a5,a0,0x4
    8000677e:	0001f717          	auipc	a4,0x1f
    80006782:	88270713          	addi	a4,a4,-1918 # 80025000 <disk+0x2000>
    80006786:	6314                	ld	a3,0(a4)
    80006788:	96be                	add	a3,a3,a5
    8000678a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000678e:	6314                	ld	a3,0(a4)
    80006790:	96be                	add	a3,a3,a5
    80006792:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006796:	6314                	ld	a3,0(a4)
    80006798:	96be                	add	a3,a3,a5
    8000679a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000679e:	6318                	ld	a4,0(a4)
    800067a0:	97ba                	add	a5,a5,a4
    800067a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800067a6:	0001d797          	auipc	a5,0x1d
    800067aa:	85a78793          	addi	a5,a5,-1958 # 80023000 <disk>
    800067ae:	97aa                	add	a5,a5,a0
    800067b0:	6509                	lui	a0,0x2
    800067b2:	953e                	add	a0,a0,a5
    800067b4:	4785                	li	a5,1
    800067b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800067ba:	0001f517          	auipc	a0,0x1f
    800067be:	85e50513          	addi	a0,a0,-1954 # 80025018 <disk+0x2018>
    800067c2:	ffffc097          	auipc	ra,0xffffc
    800067c6:	448080e7          	jalr	1096(ra) # 80002c0a <wakeup>
}
    800067ca:	60a2                	ld	ra,8(sp)
    800067cc:	6402                	ld	s0,0(sp)
    800067ce:	0141                	addi	sp,sp,16
    800067d0:	8082                	ret
    panic("free_desc 1");
    800067d2:	00002517          	auipc	a0,0x2
    800067d6:	0fe50513          	addi	a0,a0,254 # 800088d0 <syscalls+0x330>
    800067da:	ffffa097          	auipc	ra,0xffffa
    800067de:	d64080e7          	jalr	-668(ra) # 8000053e <panic>
    panic("free_desc 2");
    800067e2:	00002517          	auipc	a0,0x2
    800067e6:	0fe50513          	addi	a0,a0,254 # 800088e0 <syscalls+0x340>
    800067ea:	ffffa097          	auipc	ra,0xffffa
    800067ee:	d54080e7          	jalr	-684(ra) # 8000053e <panic>

00000000800067f2 <virtio_disk_init>:
{
    800067f2:	1101                	addi	sp,sp,-32
    800067f4:	ec06                	sd	ra,24(sp)
    800067f6:	e822                	sd	s0,16(sp)
    800067f8:	e426                	sd	s1,8(sp)
    800067fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800067fc:	00002597          	auipc	a1,0x2
    80006800:	0f458593          	addi	a1,a1,244 # 800088f0 <syscalls+0x350>
    80006804:	0001f517          	auipc	a0,0x1f
    80006808:	92450513          	addi	a0,a0,-1756 # 80025128 <disk+0x2128>
    8000680c:	ffffa097          	auipc	ra,0xffffa
    80006810:	348080e7          	jalr	840(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006814:	100017b7          	lui	a5,0x10001
    80006818:	4398                	lw	a4,0(a5)
    8000681a:	2701                	sext.w	a4,a4
    8000681c:	747277b7          	lui	a5,0x74727
    80006820:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006824:	0ef71163          	bne	a4,a5,80006906 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006828:	100017b7          	lui	a5,0x10001
    8000682c:	43dc                	lw	a5,4(a5)
    8000682e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006830:	4705                	li	a4,1
    80006832:	0ce79a63          	bne	a5,a4,80006906 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006836:	100017b7          	lui	a5,0x10001
    8000683a:	479c                	lw	a5,8(a5)
    8000683c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000683e:	4709                	li	a4,2
    80006840:	0ce79363          	bne	a5,a4,80006906 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006844:	100017b7          	lui	a5,0x10001
    80006848:	47d8                	lw	a4,12(a5)
    8000684a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000684c:	554d47b7          	lui	a5,0x554d4
    80006850:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006854:	0af71963          	bne	a4,a5,80006906 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006858:	100017b7          	lui	a5,0x10001
    8000685c:	4705                	li	a4,1
    8000685e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006860:	470d                	li	a4,3
    80006862:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006864:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006866:	c7ffe737          	lui	a4,0xc7ffe
    8000686a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000686e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006870:	2701                	sext.w	a4,a4
    80006872:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006874:	472d                	li	a4,11
    80006876:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006878:	473d                	li	a4,15
    8000687a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000687c:	6705                	lui	a4,0x1
    8000687e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006880:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006884:	5bdc                	lw	a5,52(a5)
    80006886:	2781                	sext.w	a5,a5
  if(max == 0)
    80006888:	c7d9                	beqz	a5,80006916 <virtio_disk_init+0x124>
  if(max < NUM)
    8000688a:	471d                	li	a4,7
    8000688c:	08f77d63          	bgeu	a4,a5,80006926 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006890:	100014b7          	lui	s1,0x10001
    80006894:	47a1                	li	a5,8
    80006896:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006898:	6609                	lui	a2,0x2
    8000689a:	4581                	li	a1,0
    8000689c:	0001c517          	auipc	a0,0x1c
    800068a0:	76450513          	addi	a0,a0,1892 # 80023000 <disk>
    800068a4:	ffffa097          	auipc	ra,0xffffa
    800068a8:	43c080e7          	jalr	1084(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800068ac:	0001c717          	auipc	a4,0x1c
    800068b0:	75470713          	addi	a4,a4,1876 # 80023000 <disk>
    800068b4:	00c75793          	srli	a5,a4,0xc
    800068b8:	2781                	sext.w	a5,a5
    800068ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800068bc:	0001e797          	auipc	a5,0x1e
    800068c0:	74478793          	addi	a5,a5,1860 # 80025000 <disk+0x2000>
    800068c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800068c6:	0001c717          	auipc	a4,0x1c
    800068ca:	7ba70713          	addi	a4,a4,1978 # 80023080 <disk+0x80>
    800068ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800068d0:	0001d717          	auipc	a4,0x1d
    800068d4:	73070713          	addi	a4,a4,1840 # 80024000 <disk+0x1000>
    800068d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800068da:	4705                	li	a4,1
    800068dc:	00e78c23          	sb	a4,24(a5)
    800068e0:	00e78ca3          	sb	a4,25(a5)
    800068e4:	00e78d23          	sb	a4,26(a5)
    800068e8:	00e78da3          	sb	a4,27(a5)
    800068ec:	00e78e23          	sb	a4,28(a5)
    800068f0:	00e78ea3          	sb	a4,29(a5)
    800068f4:	00e78f23          	sb	a4,30(a5)
    800068f8:	00e78fa3          	sb	a4,31(a5)
}
    800068fc:	60e2                	ld	ra,24(sp)
    800068fe:	6442                	ld	s0,16(sp)
    80006900:	64a2                	ld	s1,8(sp)
    80006902:	6105                	addi	sp,sp,32
    80006904:	8082                	ret
    panic("could not find virtio disk");
    80006906:	00002517          	auipc	a0,0x2
    8000690a:	ffa50513          	addi	a0,a0,-6 # 80008900 <syscalls+0x360>
    8000690e:	ffffa097          	auipc	ra,0xffffa
    80006912:	c30080e7          	jalr	-976(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006916:	00002517          	auipc	a0,0x2
    8000691a:	00a50513          	addi	a0,a0,10 # 80008920 <syscalls+0x380>
    8000691e:	ffffa097          	auipc	ra,0xffffa
    80006922:	c20080e7          	jalr	-992(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006926:	00002517          	auipc	a0,0x2
    8000692a:	01a50513          	addi	a0,a0,26 # 80008940 <syscalls+0x3a0>
    8000692e:	ffffa097          	auipc	ra,0xffffa
    80006932:	c10080e7          	jalr	-1008(ra) # 8000053e <panic>

0000000080006936 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006936:	7159                	addi	sp,sp,-112
    80006938:	f486                	sd	ra,104(sp)
    8000693a:	f0a2                	sd	s0,96(sp)
    8000693c:	eca6                	sd	s1,88(sp)
    8000693e:	e8ca                	sd	s2,80(sp)
    80006940:	e4ce                	sd	s3,72(sp)
    80006942:	e0d2                	sd	s4,64(sp)
    80006944:	fc56                	sd	s5,56(sp)
    80006946:	f85a                	sd	s6,48(sp)
    80006948:	f45e                	sd	s7,40(sp)
    8000694a:	f062                	sd	s8,32(sp)
    8000694c:	ec66                	sd	s9,24(sp)
    8000694e:	e86a                	sd	s10,16(sp)
    80006950:	1880                	addi	s0,sp,112
    80006952:	892a                	mv	s2,a0
    80006954:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006956:	00c52c83          	lw	s9,12(a0)
    8000695a:	001c9c9b          	slliw	s9,s9,0x1
    8000695e:	1c82                	slli	s9,s9,0x20
    80006960:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006964:	0001e517          	auipc	a0,0x1e
    80006968:	7c450513          	addi	a0,a0,1988 # 80025128 <disk+0x2128>
    8000696c:	ffffa097          	auipc	ra,0xffffa
    80006970:	278080e7          	jalr	632(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006974:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006976:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006978:	0001cb97          	auipc	s7,0x1c
    8000697c:	688b8b93          	addi	s7,s7,1672 # 80023000 <disk>
    80006980:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006982:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006984:	8a4e                	mv	s4,s3
    80006986:	a051                	j	80006a0a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006988:	00fb86b3          	add	a3,s7,a5
    8000698c:	96da                	add	a3,a3,s6
    8000698e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006992:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006994:	0207c563          	bltz	a5,800069be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006998:	2485                	addiw	s1,s1,1
    8000699a:	0711                	addi	a4,a4,4
    8000699c:	25548063          	beq	s1,s5,80006bdc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800069a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800069a2:	0001e697          	auipc	a3,0x1e
    800069a6:	67668693          	addi	a3,a3,1654 # 80025018 <disk+0x2018>
    800069aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800069ac:	0006c583          	lbu	a1,0(a3)
    800069b0:	fde1                	bnez	a1,80006988 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800069b2:	2785                	addiw	a5,a5,1
    800069b4:	0685                	addi	a3,a3,1
    800069b6:	ff879be3          	bne	a5,s8,800069ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800069ba:	57fd                	li	a5,-1
    800069bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800069be:	02905a63          	blez	s1,800069f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800069c2:	f9042503          	lw	a0,-112(s0)
    800069c6:	00000097          	auipc	ra,0x0
    800069ca:	d90080e7          	jalr	-624(ra) # 80006756 <free_desc>
      for(int j = 0; j < i; j++)
    800069ce:	4785                	li	a5,1
    800069d0:	0297d163          	bge	a5,s1,800069f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800069d4:	f9442503          	lw	a0,-108(s0)
    800069d8:	00000097          	auipc	ra,0x0
    800069dc:	d7e080e7          	jalr	-642(ra) # 80006756 <free_desc>
      for(int j = 0; j < i; j++)
    800069e0:	4789                	li	a5,2
    800069e2:	0097d863          	bge	a5,s1,800069f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800069e6:	f9842503          	lw	a0,-104(s0)
    800069ea:	00000097          	auipc	ra,0x0
    800069ee:	d6c080e7          	jalr	-660(ra) # 80006756 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800069f2:	0001e597          	auipc	a1,0x1e
    800069f6:	73658593          	addi	a1,a1,1846 # 80025128 <disk+0x2128>
    800069fa:	0001e517          	auipc	a0,0x1e
    800069fe:	61e50513          	addi	a0,a0,1566 # 80025018 <disk+0x2018>
    80006a02:	ffffc097          	auipc	ra,0xffffc
    80006a06:	06e080e7          	jalr	110(ra) # 80002a70 <sleep>
  for(int i = 0; i < 3; i++){
    80006a0a:	f9040713          	addi	a4,s0,-112
    80006a0e:	84ce                	mv	s1,s3
    80006a10:	bf41                	j	800069a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006a12:	20058713          	addi	a4,a1,512
    80006a16:	00471693          	slli	a3,a4,0x4
    80006a1a:	0001c717          	auipc	a4,0x1c
    80006a1e:	5e670713          	addi	a4,a4,1510 # 80023000 <disk>
    80006a22:	9736                	add	a4,a4,a3
    80006a24:	4685                	li	a3,1
    80006a26:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006a2a:	20058713          	addi	a4,a1,512
    80006a2e:	00471693          	slli	a3,a4,0x4
    80006a32:	0001c717          	auipc	a4,0x1c
    80006a36:	5ce70713          	addi	a4,a4,1486 # 80023000 <disk>
    80006a3a:	9736                	add	a4,a4,a3
    80006a3c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006a40:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006a44:	7679                	lui	a2,0xffffe
    80006a46:	963e                	add	a2,a2,a5
    80006a48:	0001e697          	auipc	a3,0x1e
    80006a4c:	5b868693          	addi	a3,a3,1464 # 80025000 <disk+0x2000>
    80006a50:	6298                	ld	a4,0(a3)
    80006a52:	9732                	add	a4,a4,a2
    80006a54:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006a56:	6298                	ld	a4,0(a3)
    80006a58:	9732                	add	a4,a4,a2
    80006a5a:	4541                	li	a0,16
    80006a5c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006a5e:	6298                	ld	a4,0(a3)
    80006a60:	9732                	add	a4,a4,a2
    80006a62:	4505                	li	a0,1
    80006a64:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006a68:	f9442703          	lw	a4,-108(s0)
    80006a6c:	6288                	ld	a0,0(a3)
    80006a6e:	962a                	add	a2,a2,a0
    80006a70:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006a74:	0712                	slli	a4,a4,0x4
    80006a76:	6290                	ld	a2,0(a3)
    80006a78:	963a                	add	a2,a2,a4
    80006a7a:	05890513          	addi	a0,s2,88
    80006a7e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006a80:	6294                	ld	a3,0(a3)
    80006a82:	96ba                	add	a3,a3,a4
    80006a84:	40000613          	li	a2,1024
    80006a88:	c690                	sw	a2,8(a3)
  if(write)
    80006a8a:	140d0063          	beqz	s10,80006bca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006a8e:	0001e697          	auipc	a3,0x1e
    80006a92:	5726b683          	ld	a3,1394(a3) # 80025000 <disk+0x2000>
    80006a96:	96ba                	add	a3,a3,a4
    80006a98:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006a9c:	0001c817          	auipc	a6,0x1c
    80006aa0:	56480813          	addi	a6,a6,1380 # 80023000 <disk>
    80006aa4:	0001e517          	auipc	a0,0x1e
    80006aa8:	55c50513          	addi	a0,a0,1372 # 80025000 <disk+0x2000>
    80006aac:	6114                	ld	a3,0(a0)
    80006aae:	96ba                	add	a3,a3,a4
    80006ab0:	00c6d603          	lhu	a2,12(a3)
    80006ab4:	00166613          	ori	a2,a2,1
    80006ab8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006abc:	f9842683          	lw	a3,-104(s0)
    80006ac0:	6110                	ld	a2,0(a0)
    80006ac2:	9732                	add	a4,a4,a2
    80006ac4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006ac8:	20058613          	addi	a2,a1,512
    80006acc:	0612                	slli	a2,a2,0x4
    80006ace:	9642                	add	a2,a2,a6
    80006ad0:	577d                	li	a4,-1
    80006ad2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006ad6:	00469713          	slli	a4,a3,0x4
    80006ada:	6114                	ld	a3,0(a0)
    80006adc:	96ba                	add	a3,a3,a4
    80006ade:	03078793          	addi	a5,a5,48
    80006ae2:	97c2                	add	a5,a5,a6
    80006ae4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006ae6:	611c                	ld	a5,0(a0)
    80006ae8:	97ba                	add	a5,a5,a4
    80006aea:	4685                	li	a3,1
    80006aec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006aee:	611c                	ld	a5,0(a0)
    80006af0:	97ba                	add	a5,a5,a4
    80006af2:	4809                	li	a6,2
    80006af4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006af8:	611c                	ld	a5,0(a0)
    80006afa:	973e                	add	a4,a4,a5
    80006afc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006b00:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006b04:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006b08:	6518                	ld	a4,8(a0)
    80006b0a:	00275783          	lhu	a5,2(a4)
    80006b0e:	8b9d                	andi	a5,a5,7
    80006b10:	0786                	slli	a5,a5,0x1
    80006b12:	97ba                	add	a5,a5,a4
    80006b14:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006b18:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006b1c:	6518                	ld	a4,8(a0)
    80006b1e:	00275783          	lhu	a5,2(a4)
    80006b22:	2785                	addiw	a5,a5,1
    80006b24:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006b28:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006b2c:	100017b7          	lui	a5,0x10001
    80006b30:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006b34:	00492703          	lw	a4,4(s2)
    80006b38:	4785                	li	a5,1
    80006b3a:	02f71163          	bne	a4,a5,80006b5c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006b3e:	0001e997          	auipc	s3,0x1e
    80006b42:	5ea98993          	addi	s3,s3,1514 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006b46:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006b48:	85ce                	mv	a1,s3
    80006b4a:	854a                	mv	a0,s2
    80006b4c:	ffffc097          	auipc	ra,0xffffc
    80006b50:	f24080e7          	jalr	-220(ra) # 80002a70 <sleep>
  while(b->disk == 1) {
    80006b54:	00492783          	lw	a5,4(s2)
    80006b58:	fe9788e3          	beq	a5,s1,80006b48 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006b5c:	f9042903          	lw	s2,-112(s0)
    80006b60:	20090793          	addi	a5,s2,512
    80006b64:	00479713          	slli	a4,a5,0x4
    80006b68:	0001c797          	auipc	a5,0x1c
    80006b6c:	49878793          	addi	a5,a5,1176 # 80023000 <disk>
    80006b70:	97ba                	add	a5,a5,a4
    80006b72:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006b76:	0001e997          	auipc	s3,0x1e
    80006b7a:	48a98993          	addi	s3,s3,1162 # 80025000 <disk+0x2000>
    80006b7e:	00491713          	slli	a4,s2,0x4
    80006b82:	0009b783          	ld	a5,0(s3)
    80006b86:	97ba                	add	a5,a5,a4
    80006b88:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006b8c:	854a                	mv	a0,s2
    80006b8e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006b92:	00000097          	auipc	ra,0x0
    80006b96:	bc4080e7          	jalr	-1084(ra) # 80006756 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006b9a:	8885                	andi	s1,s1,1
    80006b9c:	f0ed                	bnez	s1,80006b7e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006b9e:	0001e517          	auipc	a0,0x1e
    80006ba2:	58a50513          	addi	a0,a0,1418 # 80025128 <disk+0x2128>
    80006ba6:	ffffa097          	auipc	ra,0xffffa
    80006baa:	0f2080e7          	jalr	242(ra) # 80000c98 <release>
}
    80006bae:	70a6                	ld	ra,104(sp)
    80006bb0:	7406                	ld	s0,96(sp)
    80006bb2:	64e6                	ld	s1,88(sp)
    80006bb4:	6946                	ld	s2,80(sp)
    80006bb6:	69a6                	ld	s3,72(sp)
    80006bb8:	6a06                	ld	s4,64(sp)
    80006bba:	7ae2                	ld	s5,56(sp)
    80006bbc:	7b42                	ld	s6,48(sp)
    80006bbe:	7ba2                	ld	s7,40(sp)
    80006bc0:	7c02                	ld	s8,32(sp)
    80006bc2:	6ce2                	ld	s9,24(sp)
    80006bc4:	6d42                	ld	s10,16(sp)
    80006bc6:	6165                	addi	sp,sp,112
    80006bc8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006bca:	0001e697          	auipc	a3,0x1e
    80006bce:	4366b683          	ld	a3,1078(a3) # 80025000 <disk+0x2000>
    80006bd2:	96ba                	add	a3,a3,a4
    80006bd4:	4609                	li	a2,2
    80006bd6:	00c69623          	sh	a2,12(a3)
    80006bda:	b5c9                	j	80006a9c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006bdc:	f9042583          	lw	a1,-112(s0)
    80006be0:	20058793          	addi	a5,a1,512
    80006be4:	0792                	slli	a5,a5,0x4
    80006be6:	0001c517          	auipc	a0,0x1c
    80006bea:	4c250513          	addi	a0,a0,1218 # 800230a8 <disk+0xa8>
    80006bee:	953e                	add	a0,a0,a5
  if(write)
    80006bf0:	e20d11e3          	bnez	s10,80006a12 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006bf4:	20058713          	addi	a4,a1,512
    80006bf8:	00471693          	slli	a3,a4,0x4
    80006bfc:	0001c717          	auipc	a4,0x1c
    80006c00:	40470713          	addi	a4,a4,1028 # 80023000 <disk>
    80006c04:	9736                	add	a4,a4,a3
    80006c06:	0a072423          	sw	zero,168(a4)
    80006c0a:	b505                	j	80006a2a <virtio_disk_rw+0xf4>

0000000080006c0c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006c0c:	1101                	addi	sp,sp,-32
    80006c0e:	ec06                	sd	ra,24(sp)
    80006c10:	e822                	sd	s0,16(sp)
    80006c12:	e426                	sd	s1,8(sp)
    80006c14:	e04a                	sd	s2,0(sp)
    80006c16:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006c18:	0001e517          	auipc	a0,0x1e
    80006c1c:	51050513          	addi	a0,a0,1296 # 80025128 <disk+0x2128>
    80006c20:	ffffa097          	auipc	ra,0xffffa
    80006c24:	fc4080e7          	jalr	-60(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006c28:	10001737          	lui	a4,0x10001
    80006c2c:	533c                	lw	a5,96(a4)
    80006c2e:	8b8d                	andi	a5,a5,3
    80006c30:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006c32:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006c36:	0001e797          	auipc	a5,0x1e
    80006c3a:	3ca78793          	addi	a5,a5,970 # 80025000 <disk+0x2000>
    80006c3e:	6b94                	ld	a3,16(a5)
    80006c40:	0207d703          	lhu	a4,32(a5)
    80006c44:	0026d783          	lhu	a5,2(a3)
    80006c48:	06f70163          	beq	a4,a5,80006caa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006c4c:	0001c917          	auipc	s2,0x1c
    80006c50:	3b490913          	addi	s2,s2,948 # 80023000 <disk>
    80006c54:	0001e497          	auipc	s1,0x1e
    80006c58:	3ac48493          	addi	s1,s1,940 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006c5c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006c60:	6898                	ld	a4,16(s1)
    80006c62:	0204d783          	lhu	a5,32(s1)
    80006c66:	8b9d                	andi	a5,a5,7
    80006c68:	078e                	slli	a5,a5,0x3
    80006c6a:	97ba                	add	a5,a5,a4
    80006c6c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006c6e:	20078713          	addi	a4,a5,512
    80006c72:	0712                	slli	a4,a4,0x4
    80006c74:	974a                	add	a4,a4,s2
    80006c76:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006c7a:	e731                	bnez	a4,80006cc6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006c7c:	20078793          	addi	a5,a5,512
    80006c80:	0792                	slli	a5,a5,0x4
    80006c82:	97ca                	add	a5,a5,s2
    80006c84:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006c86:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006c8a:	ffffc097          	auipc	ra,0xffffc
    80006c8e:	f80080e7          	jalr	-128(ra) # 80002c0a <wakeup>

    disk.used_idx += 1;
    80006c92:	0204d783          	lhu	a5,32(s1)
    80006c96:	2785                	addiw	a5,a5,1
    80006c98:	17c2                	slli	a5,a5,0x30
    80006c9a:	93c1                	srli	a5,a5,0x30
    80006c9c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ca0:	6898                	ld	a4,16(s1)
    80006ca2:	00275703          	lhu	a4,2(a4)
    80006ca6:	faf71be3          	bne	a4,a5,80006c5c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006caa:	0001e517          	auipc	a0,0x1e
    80006cae:	47e50513          	addi	a0,a0,1150 # 80025128 <disk+0x2128>
    80006cb2:	ffffa097          	auipc	ra,0xffffa
    80006cb6:	fe6080e7          	jalr	-26(ra) # 80000c98 <release>
}
    80006cba:	60e2                	ld	ra,24(sp)
    80006cbc:	6442                	ld	s0,16(sp)
    80006cbe:	64a2                	ld	s1,8(sp)
    80006cc0:	6902                	ld	s2,0(sp)
    80006cc2:	6105                	addi	sp,sp,32
    80006cc4:	8082                	ret
      panic("virtio_disk_intr status");
    80006cc6:	00002517          	auipc	a0,0x2
    80006cca:	c9a50513          	addi	a0,a0,-870 # 80008960 <syscalls+0x3c0>
    80006cce:	ffffa097          	auipc	ra,0xffffa
    80006cd2:	870080e7          	jalr	-1936(ra) # 8000053e <panic>

0000000080006cd6 <cas>:
    80006cd6:	100522af          	lr.w	t0,(a0)
    80006cda:	00b29563          	bne	t0,a1,80006ce4 <fail>
    80006cde:	18c5252f          	sc.w	a0,a2,(a0)
    80006ce2:	8082                	ret

0000000080006ce4 <fail>:
    80006ce4:	4505                	li	a0,1
    80006ce6:	8082                	ret
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
