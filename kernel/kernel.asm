
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9f013103          	ld	sp,-1552(sp) # 800089f0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	02e70713          	addi	a4,a4,46 # 80009080 <timer_scratch>
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
    80000068:	7ec78793          	addi	a5,a5,2028 # 80006850 <timervec>
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
    80000130:	028080e7          	jalr	40(ra) # 80003154 <either_copyin>
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
    80000190:	03450513          	addi	a0,a0,52 # 800111c0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a58080e7          	jalr	-1448(ra) # 80000bec <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	02448493          	addi	s1,s1,36 # 800111c0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	0b290913          	addi	s2,s2,178 # 80011258 <cons+0x98>
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
    800001c8:	be0080e7          	jalr	-1056(ra) # 80001da4 <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	a0c080e7          	jalr	-1524(ra) # 80002be0 <sleep>
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
    80000214:	eee080e7          	jalr	-274(ra) # 800030fe <either_copyout>
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
    80000228:	f9c50513          	addi	a0,a0,-100 # 800111c0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a7a080e7          	jalr	-1414(ra) # 80000ca6 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f8650513          	addi	a0,a0,-122 # 800111c0 <cons>
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
    80000272:	00011717          	auipc	a4,0x11
    80000276:	fef72323          	sw	a5,-26(a4) # 80011258 <cons+0x98>
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
    800002d0:	ef450513          	addi	a0,a0,-268 # 800111c0 <cons>
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
    800002f6:	eb8080e7          	jalr	-328(ra) # 800031aa <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ec650513          	addi	a0,a0,-314 # 800111c0 <cons>
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
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	ea270713          	addi	a4,a4,-350 # 800111c0 <cons>
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
    8000034c:	e7878793          	addi	a5,a5,-392 # 800111c0 <cons>
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
    8000037a:	ee27a783          	lw	a5,-286(a5) # 80011258 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e3670713          	addi	a4,a4,-458 # 800111c0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e2648493          	addi	s1,s1,-474 # 800111c0 <cons>
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
    800003da:	dea70713          	addi	a4,a4,-534 # 800111c0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e6f72a23          	sw	a5,-396(a4) # 80011260 <cons+0xa0>
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
    80000416:	dae78793          	addi	a5,a5,-594 # 800111c0 <cons>
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
    8000043a:	e2c7a323          	sw	a2,-474(a5) # 8001125c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	e1a50513          	addi	a0,a0,-486 # 80011258 <cons+0x98>
    80000446:	00003097          	auipc	ra,0x3
    8000044a:	940080e7          	jalr	-1728(ra) # 80002d86 <wakeup>
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
    80000464:	d6050513          	addi	a0,a0,-672 # 800111c0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	7b078793          	addi	a5,a5,1968 # 80021c28 <devsw>
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
    8000054e:	d207ab23          	sw	zero,-714(a5) # 80011280 <pr+0x18>
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
    800005be:	cc6dad83          	lw	s11,-826(s11) # 80011280 <pr+0x18>
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
    800005fc:	c7050513          	addi	a0,a0,-912 # 80011268 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5ec080e7          	jalr	1516(ra) # 80000bec <acquire>
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
    80000760:	b0c50513          	addi	a0,a0,-1268 # 80011268 <pr>
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
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	af048493          	addi	s1,s1,-1296 # 80011268 <pr>
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
    800007dc:	ab050513          	addi	a0,a0,-1360 # 80011288 <uart_tx_lock>
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
    8000086e:	a1ea0a13          	addi	s4,s4,-1506 # 80011288 <uart_tx_lock>
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
    800008a4:	4e6080e7          	jalr	1254(ra) # 80002d86 <wakeup>
    
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
    800008e0:	9ac50513          	addi	a0,a0,-1620 # 80011288 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	308080e7          	jalr	776(ra) # 80000bec <acquire>
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
    80000914:	978a0a13          	addi	s4,s4,-1672 # 80011288 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	2b4080e7          	jalr	692(ra) # 80002be0 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	94648493          	addi	s1,s1,-1722 # 80011288 <uart_tx_lock>
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
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	8be48493          	addi	s1,s1,-1858 # 80011288 <uart_tx_lock>
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
    80000a28:	2ca080e7          	jalr	714(ra) # 80000cee <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	89490913          	addi	s2,s2,-1900 # 800112c0 <kmem>
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
    80000acc:	7f850513          	addi	a0,a0,2040 # 800112c0 <kmem>
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
    80000b02:	7c248493          	addi	s1,s1,1986 # 800112c0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0e4080e7          	jalr	228(ra) # 80000bec <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	7aa50513          	addi	a0,a0,1962 # 800112c0 <kmem>
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
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	77e50513          	addi	a0,a0,1918 # 800112c0 <kmem>
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
    80000b82:	202080e7          	jalr	514(ra) # 80001d80 <mycpu>
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
    80000bb4:	1d0080e7          	jalr	464(ra) # 80001d80 <mycpu>
    80000bb8:	08052783          	lw	a5,128(a0)
    80000bbc:	cf99                	beqz	a5,80000bda <push_off+0x42>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	1c2080e7          	jalr	450(ra) # 80001d80 <mycpu>
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
    80000bde:	1a6080e7          	jalr	422(ra) # 80001d80 <mycpu>
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
    80000c20:	164080e7          	jalr	356(ra) # 80001d80 <mycpu>
    80000c24:	e888                	sd	a0,16(s1)
}
    80000c26:	60e2                	ld	ra,24(sp)
    80000c28:	6442                	ld	s0,16(sp)
    80000c2a:	64a2                	ld	s1,8(sp)
    80000c2c:	6105                	addi	sp,sp,32
    80000c2e:	8082                	ret
    panic("acquire");
    80000c30:	00007517          	auipc	a0,0x7
    80000c34:	44050513          	addi	a0,a0,1088 # 80008070 <digits+0x30>
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
    80000c4c:	138080e7          	jalr	312(ra) # 80001d80 <mycpu>
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
    80000c86:	00007517          	auipc	a0,0x7
    80000c8a:	3f250513          	addi	a0,a0,1010 # 80008078 <digits+0x38>
    80000c8e:	00000097          	auipc	ra,0x0
    80000c92:	8b0080e7          	jalr	-1872(ra) # 8000053e <panic>
    panic("pop_off");
    80000c96:	00007517          	auipc	a0,0x7
    80000c9a:	3fa50513          	addi	a0,a0,1018 # 80008090 <digits+0x50>
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
    80000cde:	00007517          	auipc	a0,0x7
    80000ce2:	3ba50513          	addi	a0,a0,954 # 80008098 <digits+0x58>
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
    80000ea8:	ecc080e7          	jalr	-308(ra) # 80001d70 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eac:	00008717          	auipc	a4,0x8
    80000eb0:	16c70713          	addi	a4,a4,364 # 80009018 <started>
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
    80000ec4:	eb0080e7          	jalr	-336(ra) # 80001d70 <cpuid>
    80000ec8:	85aa                	mv	a1,a0
    80000eca:	00007517          	auipc	a0,0x7
    80000ece:	1ee50513          	addi	a0,a0,494 # 800080b8 <digits+0x78>
    80000ed2:	fffff097          	auipc	ra,0xfffff
    80000ed6:	6b6080e7          	jalr	1718(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eda:	00000097          	auipc	ra,0x0
    80000ede:	0d8080e7          	jalr	216(ra) # 80000fb2 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ee2:	00002097          	auipc	ra,0x2
    80000ee6:	408080e7          	jalr	1032(ra) # 800032ea <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eea:	00006097          	auipc	ra,0x6
    80000eee:	9a6080e7          	jalr	-1626(ra) # 80006890 <plicinithart>
  }

  scheduler();        
    80000ef2:	00001097          	auipc	ra,0x1
    80000ef6:	7aa080e7          	jalr	1962(ra) # 8000269c <scheduler>
    consoleinit();
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	556080e7          	jalr	1366(ra) # 80000450 <consoleinit>
    printfinit();
    80000f02:	00000097          	auipc	ra,0x0
    80000f06:	86c080e7          	jalr	-1940(ra) # 8000076e <printfinit>
    printf("\n");
    80000f0a:	00007517          	auipc	a0,0x7
    80000f0e:	1be50513          	addi	a0,a0,446 # 800080c8 <digits+0x88>
    80000f12:	fffff097          	auipc	ra,0xfffff
    80000f16:	676080e7          	jalr	1654(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f1a:	00007517          	auipc	a0,0x7
    80000f1e:	18650513          	addi	a0,a0,390 # 800080a0 <digits+0x60>
    80000f22:	fffff097          	auipc	ra,0xfffff
    80000f26:	666080e7          	jalr	1638(ra) # 80000588 <printf>
    printf("\n");
    80000f2a:	00007517          	auipc	a0,0x7
    80000f2e:	19e50513          	addi	a0,a0,414 # 800080c8 <digits+0x88>
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
    80000f56:	4c4080e7          	jalr	1220(ra) # 80002416 <procinit>
    trapinit();      // trap vectors
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	368080e7          	jalr	872(ra) # 800032c2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	388080e7          	jalr	904(ra) # 800032ea <trapinithart>
    plicinit();      // set up interrupt controller
    80000f6a:	00006097          	auipc	ra,0x6
    80000f6e:	910080e7          	jalr	-1776(ra) # 8000687a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f72:	00006097          	auipc	ra,0x6
    80000f76:	91e080e7          	jalr	-1762(ra) # 80006890 <plicinithart>
    binit();         // buffer cache
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	afc080e7          	jalr	-1284(ra) # 80003a76 <binit>
    iinit();         // inode table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	18c080e7          	jalr	396(ra) # 8000410e <iinit>
    fileinit();      // file table
    80000f8a:	00004097          	auipc	ra,0x4
    80000f8e:	136080e7          	jalr	310(ra) # 800050c0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f92:	00006097          	auipc	ra,0x6
    80000f96:	a20080e7          	jalr	-1504(ra) # 800069b2 <virtio_disk_init>
    userinit();      // first user process
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	a12080e7          	jalr	-1518(ra) # 800029ac <userinit>
    __sync_synchronize();
    80000fa2:	0ff0000f          	fence
    started = 1;
    80000fa6:	4785                	li	a5,1
    80000fa8:	00008717          	auipc	a4,0x8
    80000fac:	06f72823          	sw	a5,112(a4) # 80009018 <started>
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
    80000fb8:	00008797          	auipc	a5,0x8
    80000fbc:	0687b783          	ld	a5,104(a5) # 80009020 <kernel_pagetable>
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
    80000ffc:	00007517          	auipc	a0,0x7
    80001000:	0d450513          	addi	a0,a0,212 # 800080d0 <digits+0x90>
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
    800010f4:	00007517          	auipc	a0,0x7
    800010f8:	fe450513          	addi	a0,a0,-28 # 800080d8 <digits+0x98>
    800010fc:	fffff097          	auipc	ra,0xfffff
    80001100:	442080e7          	jalr	1090(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001104:	00007517          	auipc	a0,0x7
    80001108:	fe450513          	addi	a0,a0,-28 # 800080e8 <digits+0xa8>
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
    8000117e:	00007517          	auipc	a0,0x7
    80001182:	f7a50513          	addi	a0,a0,-134 # 800080f8 <digits+0xb8>
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
    800011f4:	00007917          	auipc	s2,0x7
    800011f8:	e0c90913          	addi	s2,s2,-500 # 80008000 <etext>
    800011fc:	4729                	li	a4,10
    800011fe:	80007697          	auipc	a3,0x80007
    80001202:	e0268693          	addi	a3,a3,-510 # 8000 <_entry-0x7fff8000>
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
    80001232:	00006617          	auipc	a2,0x6
    80001236:	dce60613          	addi	a2,a2,-562 # 80007000 <_trampoline>
    8000123a:	040005b7          	lui	a1,0x4000
    8000123e:	15fd                	addi	a1,a1,-1
    80001240:	05b2                	slli	a1,a1,0xc
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f1a080e7          	jalr	-230(ra) # 8000115e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000124c:	8526                	mv	a0,s1
    8000124e:	00001097          	auipc	ra,0x1
    80001252:	a8c080e7          	jalr	-1396(ra) # 80001cda <proc_mapstacks>
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
    80001274:	00008797          	auipc	a5,0x8
    80001278:	daa7b623          	sd	a0,-596(a5) # 80009020 <kernel_pagetable>
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
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e3650513          	addi	a0,a0,-458 # 80008100 <digits+0xc0>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e3e50513          	addi	a0,a0,-450 # 80008118 <digits+0xd8>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e3e50513          	addi	a0,a0,-450 # 80008128 <digits+0xe8>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012fa:	00007517          	auipc	a0,0x7
    800012fe:	e4650513          	addi	a0,a0,-442 # 80008140 <digits+0x100>
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
    800013d8:	00007517          	auipc	a0,0x7
    800013dc:	d8050513          	addi	a0,a0,-640 # 80008158 <digits+0x118>
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
    8000151a:	00007517          	auipc	a0,0x7
    8000151e:	c5e50513          	addi	a0,a0,-930 # 80008178 <digits+0x138>
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
    800015f6:	00007517          	auipc	a0,0x7
    800015fa:	b9250513          	addi	a0,a0,-1134 # 80008188 <digits+0x148>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001606:	00007517          	auipc	a0,0x7
    8000160a:	ba250513          	addi	a0,a0,-1118 # 800081a8 <digits+0x168>
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
    80001670:	00007517          	auipc	a0,0x7
    80001674:	b5850513          	addi	a0,a0,-1192 # 800081c8 <digits+0x188>
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
    8000186c:	00010517          	auipc	a0,0x10
    80001870:	aec50513          	addi	a0,a0,-1300 # 80011358 <unusedLock>
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
    8000188c:	00010517          	auipc	a0,0x10
    80001890:	a5450513          	addi	a0,a0,-1452 # 800112e0 <readyLock>
    80001894:	952e                	add	a0,a0,a1
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	356080e7          	jalr	854(ra) # 80000bec <acquire>
    8000189e:	bff9                	j	8000187c <getList2+0x30>
    number == 2 ? acquire(&zombieLock): 
    800018a0:	00010517          	auipc	a0,0x10
    800018a4:	a8850513          	addi	a0,a0,-1400 # 80011328 <zombieLock>
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	344080e7          	jalr	836(ra) # 80000bec <acquire>
    800018b0:	b7f1                	j	8000187c <getList2+0x30>
      number == 3 ? acquire(&sleepLock): 
    800018b2:	00010517          	auipc	a0,0x10
    800018b6:	a8e50513          	addi	a0,a0,-1394 # 80011340 <sleepLock>
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	332080e7          	jalr	818(ra) # 80000bec <acquire>
    800018c2:	bf6d                	j	8000187c <getList2+0x30>
          panic("wrong call in getList2");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
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
    800018ec:	00007517          	auipc	a0,0x7
    800018f0:	75c53503          	ld	a0,1884(a0) # 80009048 <unusedList>
          panic("wrong call in get_first2");
  return p;
}
    800018f4:	8082                	ret
  number == 1 ? p = cpus[parent_cpu].first :
    800018f6:	00359793          	slli	a5,a1,0x3
    800018fa:	95be                	add	a1,a1,a5
    800018fc:	0592                	slli	a1,a1,0x4
    800018fe:	00010797          	auipc	a5,0x10
    80001902:	9e278793          	addi	a5,a5,-1566 # 800112e0 <readyLock>
    80001906:	95be                	add	a1,a1,a5
    80001908:	1185b503          	ld	a0,280(a1) # 4000118 <_entry-0x7bfffee8>
    8000190c:	8082                	ret
    number == 2 ? p = zombieList  :
    8000190e:	00007517          	auipc	a0,0x7
    80001912:	74a53503          	ld	a0,1866(a0) # 80009058 <zombieList>
    80001916:	8082                	ret
      number == 3 ? p = sleepingList :
    80001918:	00007517          	auipc	a0,0x7
    8000191c:	73853503          	ld	a0,1848(a0) # 80009050 <sleepingList>
    80001920:	8082                	ret
struct proc* get_first2(int number, int parent_cpu){
    80001922:	1141                	addi	sp,sp,-16
    80001924:	e406                	sd	ra,8(sp)
    80001926:	e022                	sd	s0,0(sp)
    80001928:	0800                	addi	s0,sp,16
          panic("wrong call in get_first2");
    8000192a:	00007517          	auipc	a0,0x7
    8000192e:	8c650513          	addi	a0,a0,-1850 # 800081f0 <digits+0x1b0>
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
    8000195c:	00010797          	auipc	a5,0x10
    80001960:	98478793          	addi	a5,a5,-1660 # 800112e0 <readyLock>
    80001964:	963e                	add	a2,a2,a5
    80001966:	10a63c23          	sd	a0,280(a2) # 1118 <_entry-0x7fffeee8>
    8000196a:	8082                	ret
    number == 2 ? zombieList = p: 
    8000196c:	00007797          	auipc	a5,0x7
    80001970:	6ea7b623          	sd	a0,1772(a5) # 80009058 <zombieList>
    80001974:	8082                	ret
      number == 3 ? sleepingList = p: 
    80001976:	00007797          	auipc	a5,0x7
    8000197a:	6ca7bd23          	sd	a0,1754(a5) # 80009050 <sleepingList>
    8000197e:	8082                	ret
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e406                	sd	ra,8(sp)
    80001984:	e022                	sd	s0,0(sp)
    80001986:	0800                	addi	s0,sp,16
          panic("wrong call in set_first2");
    80001988:	00007517          	auipc	a0,0x7
    8000198c:	88850513          	addi	a0,a0,-1912 # 80008210 <digits+0x1d0>
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
    800019b8:	00010517          	auipc	a0,0x10
    800019bc:	9a050513          	addi	a0,a0,-1632 # 80011358 <unusedLock>
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
    800019d8:	00010517          	auipc	a0,0x10
    800019dc:	90850513          	addi	a0,a0,-1784 # 800112e0 <readyLock>
    800019e0:	952e                	add	a0,a0,a1
    800019e2:	fffff097          	auipc	ra,0xfffff
    800019e6:	2c4080e7          	jalr	708(ra) # 80000ca6 <release>
    800019ea:	bff9                	j	800019c8 <release_list2+0x30>
      number == 2 ? release(&zombieLock): 
    800019ec:	00010517          	auipc	a0,0x10
    800019f0:	93c50513          	addi	a0,a0,-1732 # 80011328 <zombieLock>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	2b2080e7          	jalr	690(ra) # 80000ca6 <release>
    800019fc:	b7f1                	j	800019c8 <release_list2+0x30>
        number == 3 ? release(&sleepLock): 
    800019fe:	00010517          	auipc	a0,0x10
    80001a02:	94250513          	addi	a0,a0,-1726 # 80011340 <sleepLock>
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	2a0080e7          	jalr	672(ra) # 80000ca6 <release>
    80001a0e:	bf6d                	j	800019c8 <release_list2+0x30>
            panic("wrong call in release_list2");
    80001a10:	00007517          	auipc	a0,0x7
    80001a14:	82050513          	addi	a0,a0,-2016 # 80008230 <digits+0x1f0>
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
    80001af2:	00010917          	auipc	s2,0x10
    80001af6:	87e90913          	addi	s2,s2,-1922 # 80011370 <cpus>
    80001afa:	993e                	add	s2,s2,a5
    old = c->queue_size;
    80001afc:	0000f497          	auipc	s1,0xf
    80001b00:	7e448493          	addi	s1,s1,2020 # 800112e0 <readyLock>
    80001b04:	94be                	add	s1,s1,a5
    80001b06:	68cc                	ld	a1,144(s1)
  } while(cas(&c->queue_size, old, old+number));
    80001b08:	0135863b          	addw	a2,a1,s3
    80001b0c:	2581                	sext.w	a1,a1
    80001b0e:	854a                	mv	a0,s2
    80001b10:	00005097          	auipc	ra,0x5
    80001b14:	386080e7          	jalr	902(ra) # 80006e96 <cas>
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
    80001b48:	0000f797          	auipc	a5,0xf
    80001b4c:	79878793          	addi	a5,a5,1944 # 800112e0 <readyLock>
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
    80001b64:	00006517          	auipc	a0,0x6
    80001b68:	6ec50513          	addi	a0,a0,1772 # 80008250 <digits+0x210>
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
    80001b9a:	00007517          	auipc	a0,0x7
    80001b9e:	49653503          	ld	a0,1174(a0) # 80009030 <unused_list>
    80001ba2:	bf55                	j	80001b56 <getFirst+0x2e>
  p = sleeping_list;
    80001ba4:	00007517          	auipc	a0,0x7
    80001ba8:	48453503          	ld	a0,1156(a0) # 80009028 <sleeping_list>
    80001bac:	b76d                	j	80001b56 <getFirst+0x2e>
    panic("getFirst");
    80001bae:	00006517          	auipc	a0,0x6
    80001bb2:	6b250513          	addi	a0,a0,1714 # 80008260 <digits+0x220>
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	988080e7          	jalr	-1656(ra) # 8000053e <panic>
  else if(type==zombeList || type==21){
    80001bbe:	4785                	li	a5,1
    80001bc0:	faf51de3          	bne	a0,a5,80001b7a <getFirst+0x52>
   p = zombie_list;  }
    80001bc4:	00007517          	auipc	a0,0x7
    80001bc8:	47453503          	ld	a0,1140(a0) # 80009038 <zombie_list>
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
    80001bee:	00010517          	auipc	a0,0x10
    80001bf2:	9aa50513          	addi	a0,a0,-1622 # 80011598 <unused_lock>
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
    80001c0e:	00010517          	auipc	a0,0x10
    80001c12:	91250513          	addi	a0,a0,-1774 # 80011520 <ready_lock>
    80001c16:	952e                	add	a0,a0,a1
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	08e080e7          	jalr	142(ra) # 80000ca6 <release>
    80001c20:	bff9                	j	80001bfe <release_list3+0x30>
      number == 2 ? release(&zombie_lock): 
    80001c22:	00010517          	auipc	a0,0x10
    80001c26:	94650513          	addi	a0,a0,-1722 # 80011568 <zombie_lock>
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	07c080e7          	jalr	124(ra) # 80000ca6 <release>
    80001c32:	b7f1                	j	80001bfe <release_list3+0x30>
        number == 3 ? release(&sleeping_lock): 
    80001c34:	00010517          	auipc	a0,0x10
    80001c38:	94c50513          	addi	a0,a0,-1716 # 80011580 <sleeping_lock>
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	06a080e7          	jalr	106(ra) # 80000ca6 <release>
    80001c44:	bf6d                	j	80001bfe <release_list3+0x30>
            panic("wrong call in release_list3");
    80001c46:	00006517          	auipc	a0,0x6
    80001c4a:	62a50513          	addi	a0,a0,1578 # 80008270 <digits+0x230>
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
    80001c72:	00010517          	auipc	a0,0x10
    80001c76:	92650513          	addi	a0,a0,-1754 # 80011598 <unused_lock>
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
    80001c92:	00010517          	auipc	a0,0x10
    80001c96:	88e50513          	addi	a0,a0,-1906 # 80011520 <ready_lock>
    80001c9a:	952e                	add	a0,a0,a1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	00a080e7          	jalr	10(ra) # 80000ca6 <release>
}
    80001ca4:	bff9                	j	80001c82 <release_list+0x2c>
      number == 2 ? release(&zombie_lock): 
    80001ca6:	00010517          	auipc	a0,0x10
    80001caa:	8c250513          	addi	a0,a0,-1854 # 80011568 <zombie_lock>
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	ff8080e7          	jalr	-8(ra) # 80000ca6 <release>
}
    80001cb6:	b7f1                	j	80001c82 <release_list+0x2c>
        number == 3 ? release(&sleeping_lock): 
    80001cb8:	00010517          	auipc	a0,0x10
    80001cbc:	8c850513          	addi	a0,a0,-1848 # 80011580 <sleeping_lock>
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	fe6080e7          	jalr	-26(ra) # 80000ca6 <release>
}
    80001cc8:	bf6d                	j	80001c82 <release_list+0x2c>
          panic("wrong type list");
    80001cca:	00006517          	auipc	a0,0x6
    80001cce:	5c650513          	addi	a0,a0,1478 # 80008290 <digits+0x250>
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	86c080e7          	jalr	-1940(ra) # 8000053e <panic>

0000000080001cda <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001cda:	7139                	addi	sp,sp,-64
    80001cdc:	fc06                	sd	ra,56(sp)
    80001cde:	f822                	sd	s0,48(sp)
    80001ce0:	f426                	sd	s1,40(sp)
    80001ce2:	f04a                	sd	s2,32(sp)
    80001ce4:	ec4e                	sd	s3,24(sp)
    80001ce6:	e852                	sd	s4,16(sp)
    80001ce8:	e456                	sd	s5,8(sp)
    80001cea:	e05a                	sd	s6,0(sp)
    80001cec:	0080                	addi	s0,sp,64
    80001cee:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf0:	00010497          	auipc	s1,0x10
    80001cf4:	8f048493          	addi	s1,s1,-1808 # 800115e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001cf8:	8b26                	mv	s6,s1
    80001cfa:	00006a97          	auipc	s5,0x6
    80001cfe:	306a8a93          	addi	s5,s5,774 # 80008000 <etext>
    80001d02:	04000937          	lui	s2,0x4000
    80001d06:	197d                	addi	s2,s2,-1
    80001d08:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d0a:	00016a17          	auipc	s4,0x16
    80001d0e:	cd6a0a13          	addi	s4,s4,-810 # 800179e0 <tickslock>
    char *pa = kalloc();
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	de2080e7          	jalr	-542(ra) # 80000af4 <kalloc>
    80001d1a:	862a                	mv	a2,a0
    if(pa == 0)
    80001d1c:	c131                	beqz	a0,80001d60 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001d1e:	416485b3          	sub	a1,s1,s6
    80001d22:	8591                	srai	a1,a1,0x4
    80001d24:	000ab783          	ld	a5,0(s5)
    80001d28:	02f585b3          	mul	a1,a1,a5
    80001d2c:	2585                	addiw	a1,a1,1
    80001d2e:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d32:	4719                	li	a4,6
    80001d34:	6685                	lui	a3,0x1
    80001d36:	40b905b3          	sub	a1,s2,a1
    80001d3a:	854e                	mv	a0,s3
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	422080e7          	jalr	1058(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d44:	19048493          	addi	s1,s1,400
    80001d48:	fd4495e3          	bne	s1,s4,80001d12 <proc_mapstacks+0x38>
  }
}
    80001d4c:	70e2                	ld	ra,56(sp)
    80001d4e:	7442                	ld	s0,48(sp)
    80001d50:	74a2                	ld	s1,40(sp)
    80001d52:	7902                	ld	s2,32(sp)
    80001d54:	69e2                	ld	s3,24(sp)
    80001d56:	6a42                	ld	s4,16(sp)
    80001d58:	6aa2                	ld	s5,8(sp)
    80001d5a:	6b02                	ld	s6,0(sp)
    80001d5c:	6121                	addi	sp,sp,64
    80001d5e:	8082                	ret
      panic("kalloc");
    80001d60:	00006517          	auipc	a0,0x6
    80001d64:	54050513          	addi	a0,a0,1344 # 800082a0 <digits+0x260>
    80001d68:	ffffe097          	auipc	ra,0xffffe
    80001d6c:	7d6080e7          	jalr	2006(ra) # 8000053e <panic>

0000000080001d70 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001d70:	1141                	addi	sp,sp,-16
    80001d72:	e422                	sd	s0,8(sp)
    80001d74:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d76:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001d78:	2501                	sext.w	a0,a0
    80001d7a:	6422                	ld	s0,8(sp)
    80001d7c:	0141                	addi	sp,sp,16
    80001d7e:	8082                	ret

0000000080001d80 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001d80:	1141                	addi	sp,sp,-16
    80001d82:	e422                	sd	s0,8(sp)
    80001d84:	0800                	addi	s0,sp,16
    80001d86:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d88:	0007851b          	sext.w	a0,a5
    80001d8c:	00351793          	slli	a5,a0,0x3
    80001d90:	97aa                	add	a5,a5,a0
    80001d92:	0792                	slli	a5,a5,0x4
  return c;
}
    80001d94:	0000f517          	auipc	a0,0xf
    80001d98:	5dc50513          	addi	a0,a0,1500 # 80011370 <cpus>
    80001d9c:	953e                	add	a0,a0,a5
    80001d9e:	6422                	ld	s0,8(sp)
    80001da0:	0141                	addi	sp,sp,16
    80001da2:	8082                	ret

0000000080001da4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001da4:	1101                	addi	sp,sp,-32
    80001da6:	ec06                	sd	ra,24(sp)
    80001da8:	e822                	sd	s0,16(sp)
    80001daa:	e426                	sd	s1,8(sp)
    80001dac:	1000                	addi	s0,sp,32
  push_off();
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	dea080e7          	jalr	-534(ra) # 80000b98 <push_off>
    80001db6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001db8:	0007871b          	sext.w	a4,a5
    80001dbc:	00371793          	slli	a5,a4,0x3
    80001dc0:	97ba                	add	a5,a5,a4
    80001dc2:	0792                	slli	a5,a5,0x4
    80001dc4:	0000f717          	auipc	a4,0xf
    80001dc8:	51c70713          	addi	a4,a4,1308 # 800112e0 <readyLock>
    80001dcc:	97ba                	add	a5,a5,a4
    80001dce:	6fc4                	ld	s1,152(a5)
  pop_off();
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	e70080e7          	jalr	-400(ra) # 80000c40 <pop_off>
  return p;
}
    80001dd8:	8526                	mv	a0,s1
    80001dda:	60e2                	ld	ra,24(sp)
    80001ddc:	6442                	ld	s0,16(sp)
    80001dde:	64a2                	ld	s1,8(sp)
    80001de0:	6105                	addi	sp,sp,32
    80001de2:	8082                	ret

0000000080001de4 <get_cpu>:
{
    80001de4:	1141                	addi	sp,sp,-16
    80001de6:	e406                	sd	ra,8(sp)
    80001de8:	e022                	sd	s0,0(sp)
    80001dea:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	fb8080e7          	jalr	-72(ra) # 80001da4 <myproc>
}
    80001df4:	4d28                	lw	a0,88(a0)
    80001df6:	60a2                	ld	ra,8(sp)
    80001df8:	6402                	ld	s0,0(sp)
    80001dfa:	0141                	addi	sp,sp,16
    80001dfc:	8082                	ret

0000000080001dfe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001dfe:	1141                	addi	sp,sp,-16
    80001e00:	e406                	sd	ra,8(sp)
    80001e02:	e022                	sd	s0,0(sp)
    80001e04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	f9e080e7          	jalr	-98(ra) # 80001da4 <myproc>
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e98080e7          	jalr	-360(ra) # 80000ca6 <release>

  if (first) {
    80001e16:	00007797          	auipc	a5,0x7
    80001e1a:	b8a7a783          	lw	a5,-1142(a5) # 800089a0 <first.1844>
    80001e1e:	eb89                	bnez	a5,80001e30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e20:	00001097          	auipc	ra,0x1
    80001e24:	4e2080e7          	jalr	1250(ra) # 80003302 <usertrapret>
}
    80001e28:	60a2                	ld	ra,8(sp)
    80001e2a:	6402                	ld	s0,0(sp)
    80001e2c:	0141                	addi	sp,sp,16
    80001e2e:	8082                	ret
    first = 0;
    80001e30:	00007797          	auipc	a5,0x7
    80001e34:	b607a823          	sw	zero,-1168(a5) # 800089a0 <first.1844>
    fsinit(ROOTDEV);
    80001e38:	4505                	li	a0,1
    80001e3a:	00002097          	auipc	ra,0x2
    80001e3e:	254080e7          	jalr	596(ra) # 8000408e <fsinit>
    80001e42:	bff9                	j	80001e20 <forkret+0x22>

0000000080001e44 <allocpid>:
allocpid() {
    80001e44:	1101                	addi	sp,sp,-32
    80001e46:	ec06                	sd	ra,24(sp)
    80001e48:	e822                	sd	s0,16(sp)
    80001e4a:	e426                	sd	s1,8(sp)
    80001e4c:	e04a                	sd	s2,0(sp)
    80001e4e:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001e50:	00007917          	auipc	s2,0x7
    80001e54:	b5490913          	addi	s2,s2,-1196 # 800089a4 <nextpid>
    80001e58:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid, pid, pid + 1));
    80001e5c:	0014861b          	addiw	a2,s1,1
    80001e60:	85a6                	mv	a1,s1
    80001e62:	854a                	mv	a0,s2
    80001e64:	00005097          	auipc	ra,0x5
    80001e68:	032080e7          	jalr	50(ra) # 80006e96 <cas>
    80001e6c:	f575                	bnez	a0,80001e58 <allocpid+0x14>
}
    80001e6e:	8526                	mv	a0,s1
    80001e70:	60e2                	ld	ra,24(sp)
    80001e72:	6442                	ld	s0,16(sp)
    80001e74:	64a2                	ld	s1,8(sp)
    80001e76:	6902                	ld	s2,0(sp)
    80001e78:	6105                	addi	sp,sp,32
    80001e7a:	8082                	ret

0000000080001e7c <proc_pagetable>:
{
    80001e7c:	1101                	addi	sp,sp,-32
    80001e7e:	ec06                	sd	ra,24(sp)
    80001e80:	e822                	sd	s0,16(sp)
    80001e82:	e426                	sd	s1,8(sp)
    80001e84:	e04a                	sd	s2,0(sp)
    80001e86:	1000                	addi	s0,sp,32
    80001e88:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	4be080e7          	jalr	1214(ra) # 80001348 <uvmcreate>
    80001e92:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e94:	c121                	beqz	a0,80001ed4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e96:	4729                	li	a4,10
    80001e98:	00005697          	auipc	a3,0x5
    80001e9c:	16868693          	addi	a3,a3,360 # 80007000 <_trampoline>
    80001ea0:	6605                	lui	a2,0x1
    80001ea2:	040005b7          	lui	a1,0x4000
    80001ea6:	15fd                	addi	a1,a1,-1
    80001ea8:	05b2                	slli	a1,a1,0xc
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	214080e7          	jalr	532(ra) # 800010be <mappages>
    80001eb2:	02054863          	bltz	a0,80001ee2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001eb6:	4719                	li	a4,6
    80001eb8:	08093683          	ld	a3,128(s2)
    80001ebc:	6605                	lui	a2,0x1
    80001ebe:	020005b7          	lui	a1,0x2000
    80001ec2:	15fd                	addi	a1,a1,-1
    80001ec4:	05b6                	slli	a1,a1,0xd
    80001ec6:	8526                	mv	a0,s1
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	1f6080e7          	jalr	502(ra) # 800010be <mappages>
    80001ed0:	02054163          	bltz	a0,80001ef2 <proc_pagetable+0x76>
}
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	60e2                	ld	ra,24(sp)
    80001ed8:	6442                	ld	s0,16(sp)
    80001eda:	64a2                	ld	s1,8(sp)
    80001edc:	6902                	ld	s2,0(sp)
    80001ede:	6105                	addi	sp,sp,32
    80001ee0:	8082                	ret
    uvmfree(pagetable, 0);
    80001ee2:	4581                	li	a1,0
    80001ee4:	8526                	mv	a0,s1
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	65e080e7          	jalr	1630(ra) # 80001544 <uvmfree>
    return 0;
    80001eee:	4481                	li	s1,0
    80001ef0:	b7d5                	j	80001ed4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ef2:	4681                	li	a3,0
    80001ef4:	4605                	li	a2,1
    80001ef6:	040005b7          	lui	a1,0x4000
    80001efa:	15fd                	addi	a1,a1,-1
    80001efc:	05b2                	slli	a1,a1,0xc
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	384080e7          	jalr	900(ra) # 80001284 <uvmunmap>
    uvmfree(pagetable, 0);
    80001f08:	4581                	li	a1,0
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	638080e7          	jalr	1592(ra) # 80001544 <uvmfree>
    return 0;
    80001f14:	4481                	li	s1,0
    80001f16:	bf7d                	j	80001ed4 <proc_pagetable+0x58>

0000000080001f18 <proc_freepagetable>:
{
    80001f18:	1101                	addi	sp,sp,-32
    80001f1a:	ec06                	sd	ra,24(sp)
    80001f1c:	e822                	sd	s0,16(sp)
    80001f1e:	e426                	sd	s1,8(sp)
    80001f20:	e04a                	sd	s2,0(sp)
    80001f22:	1000                	addi	s0,sp,32
    80001f24:	84aa                	mv	s1,a0
    80001f26:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f28:	4681                	li	a3,0
    80001f2a:	4605                	li	a2,1
    80001f2c:	040005b7          	lui	a1,0x4000
    80001f30:	15fd                	addi	a1,a1,-1
    80001f32:	05b2                	slli	a1,a1,0xc
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	350080e7          	jalr	848(ra) # 80001284 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f3c:	4681                	li	a3,0
    80001f3e:	4605                	li	a2,1
    80001f40:	020005b7          	lui	a1,0x2000
    80001f44:	15fd                	addi	a1,a1,-1
    80001f46:	05b6                	slli	a1,a1,0xd
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	33a080e7          	jalr	826(ra) # 80001284 <uvmunmap>
  uvmfree(pagetable, sz);
    80001f52:	85ca                	mv	a1,s2
    80001f54:	8526                	mv	a0,s1
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	5ee080e7          	jalr	1518(ra) # 80001544 <uvmfree>
}
    80001f5e:	60e2                	ld	ra,24(sp)
    80001f60:	6442                	ld	s0,16(sp)
    80001f62:	64a2                	ld	s1,8(sp)
    80001f64:	6902                	ld	s2,0(sp)
    80001f66:	6105                	addi	sp,sp,32
    80001f68:	8082                	ret

0000000080001f6a <growproc>:
{
    80001f6a:	1101                	addi	sp,sp,-32
    80001f6c:	ec06                	sd	ra,24(sp)
    80001f6e:	e822                	sd	s0,16(sp)
    80001f70:	e426                	sd	s1,8(sp)
    80001f72:	e04a                	sd	s2,0(sp)
    80001f74:	1000                	addi	s0,sp,32
    80001f76:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f78:	00000097          	auipc	ra,0x0
    80001f7c:	e2c080e7          	jalr	-468(ra) # 80001da4 <myproc>
    80001f80:	892a                	mv	s2,a0
  sz = p->sz;
    80001f82:	792c                	ld	a1,112(a0)
    80001f84:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f88:	00904f63          	bgtz	s1,80001fa6 <growproc+0x3c>
  } else if(n < 0){
    80001f8c:	0204cc63          	bltz	s1,80001fc4 <growproc+0x5a>
  p->sz = sz;
    80001f90:	1602                	slli	a2,a2,0x20
    80001f92:	9201                	srli	a2,a2,0x20
    80001f94:	06c93823          	sd	a2,112(s2)
  return 0;
    80001f98:	4501                	li	a0,0
}
    80001f9a:	60e2                	ld	ra,24(sp)
    80001f9c:	6442                	ld	s0,16(sp)
    80001f9e:	64a2                	ld	s1,8(sp)
    80001fa0:	6902                	ld	s2,0(sp)
    80001fa2:	6105                	addi	sp,sp,32
    80001fa4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fa6:	9e25                	addw	a2,a2,s1
    80001fa8:	1602                	slli	a2,a2,0x20
    80001faa:	9201                	srli	a2,a2,0x20
    80001fac:	1582                	slli	a1,a1,0x20
    80001fae:	9181                	srli	a1,a1,0x20
    80001fb0:	7d28                	ld	a0,120(a0)
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	47e080e7          	jalr	1150(ra) # 80001430 <uvmalloc>
    80001fba:	0005061b          	sext.w	a2,a0
    80001fbe:	fa69                	bnez	a2,80001f90 <growproc+0x26>
      return -1;
    80001fc0:	557d                	li	a0,-1
    80001fc2:	bfe1                	j	80001f9a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fc4:	9e25                	addw	a2,a2,s1
    80001fc6:	1602                	slli	a2,a2,0x20
    80001fc8:	9201                	srli	a2,a2,0x20
    80001fca:	1582                	slli	a1,a1,0x20
    80001fcc:	9181                	srli	a1,a1,0x20
    80001fce:	7d28                	ld	a0,120(a0)
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	418080e7          	jalr	1048(ra) # 800013e8 <uvmdealloc>
    80001fd8:	0005061b          	sext.w	a2,a0
    80001fdc:	bf55                	j	80001f90 <growproc+0x26>

0000000080001fde <sched>:
{
    80001fde:	7179                	addi	sp,sp,-48
    80001fe0:	f406                	sd	ra,40(sp)
    80001fe2:	f022                	sd	s0,32(sp)
    80001fe4:	ec26                	sd	s1,24(sp)
    80001fe6:	e84a                	sd	s2,16(sp)
    80001fe8:	e44e                	sd	s3,8(sp)
    80001fea:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fec:	00000097          	auipc	ra,0x0
    80001ff0:	db8080e7          	jalr	-584(ra) # 80001da4 <myproc>
    80001ff4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	b74080e7          	jalr	-1164(ra) # 80000b6a <holding>
    80001ffe:	c959                	beqz	a0,80002094 <sched+0xb6>
    80002000:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002002:	0007871b          	sext.w	a4,a5
    80002006:	00371793          	slli	a5,a4,0x3
    8000200a:	97ba                	add	a5,a5,a4
    8000200c:	0792                	slli	a5,a5,0x4
    8000200e:	0000f717          	auipc	a4,0xf
    80002012:	2d270713          	addi	a4,a4,722 # 800112e0 <readyLock>
    80002016:	97ba                	add	a5,a5,a4
    80002018:	1107a703          	lw	a4,272(a5)
    8000201c:	4785                	li	a5,1
    8000201e:	08f71363          	bne	a4,a5,800020a4 <sched+0xc6>
  if(p->state == RUNNING)
    80002022:	5898                	lw	a4,48(s1)
    80002024:	4791                	li	a5,4
    80002026:	08f70763          	beq	a4,a5,800020b4 <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000202e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002030:	ebd1                	bnez	a5,800020c4 <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002032:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002034:	0000f917          	auipc	s2,0xf
    80002038:	2ac90913          	addi	s2,s2,684 # 800112e0 <readyLock>
    8000203c:	0007871b          	sext.w	a4,a5
    80002040:	00371793          	slli	a5,a4,0x3
    80002044:	97ba                	add	a5,a5,a4
    80002046:	0792                	slli	a5,a5,0x4
    80002048:	97ca                	add	a5,a5,s2
    8000204a:	1147a983          	lw	s3,276(a5)
    8000204e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002050:	0007859b          	sext.w	a1,a5
    80002054:	00359793          	slli	a5,a1,0x3
    80002058:	97ae                	add	a5,a5,a1
    8000205a:	0792                	slli	a5,a5,0x4
    8000205c:	0000f597          	auipc	a1,0xf
    80002060:	32458593          	addi	a1,a1,804 # 80011380 <cpus+0x10>
    80002064:	95be                	add	a1,a1,a5
    80002066:	08848513          	addi	a0,s1,136
    8000206a:	00001097          	auipc	ra,0x1
    8000206e:	1ee080e7          	jalr	494(ra) # 80003258 <swtch>
    80002072:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002074:	0007871b          	sext.w	a4,a5
    80002078:	00371793          	slli	a5,a4,0x3
    8000207c:	97ba                	add	a5,a5,a4
    8000207e:	0792                	slli	a5,a5,0x4
    80002080:	97ca                	add	a5,a5,s2
    80002082:	1137aa23          	sw	s3,276(a5)
}
    80002086:	70a2                	ld	ra,40(sp)
    80002088:	7402                	ld	s0,32(sp)
    8000208a:	64e2                	ld	s1,24(sp)
    8000208c:	6942                	ld	s2,16(sp)
    8000208e:	69a2                	ld	s3,8(sp)
    80002090:	6145                	addi	sp,sp,48
    80002092:	8082                	ret
    panic("sched p->lock");
    80002094:	00006517          	auipc	a0,0x6
    80002098:	21450513          	addi	a0,a0,532 # 800082a8 <digits+0x268>
    8000209c:	ffffe097          	auipc	ra,0xffffe
    800020a0:	4a2080e7          	jalr	1186(ra) # 8000053e <panic>
    panic("sched locks");
    800020a4:	00006517          	auipc	a0,0x6
    800020a8:	21450513          	addi	a0,a0,532 # 800082b8 <digits+0x278>
    800020ac:	ffffe097          	auipc	ra,0xffffe
    800020b0:	492080e7          	jalr	1170(ra) # 8000053e <panic>
    panic("sched running");
    800020b4:	00006517          	auipc	a0,0x6
    800020b8:	21450513          	addi	a0,a0,532 # 800082c8 <digits+0x288>
    800020bc:	ffffe097          	auipc	ra,0xffffe
    800020c0:	482080e7          	jalr	1154(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020c4:	00006517          	auipc	a0,0x6
    800020c8:	21450513          	addi	a0,a0,532 # 800082d8 <digits+0x298>
    800020cc:	ffffe097          	auipc	ra,0xffffe
    800020d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>

00000000800020d4 <yield>:
{
    800020d4:	1101                	addi	sp,sp,-32
    800020d6:	ec06                	sd	ra,24(sp)
    800020d8:	e822                	sd	s0,16(sp)
    800020da:	e426                	sd	s1,8(sp)
    800020dc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	cc6080e7          	jalr	-826(ra) # 80001da4 <myproc>
    800020e6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	b04080e7          	jalr	-1276(ra) # 80000bec <acquire>
  p->state = RUNNABLE;
    800020f0:	478d                	li	a5,3
    800020f2:	d89c                	sw	a5,48(s1)
  add_proc_to_specific_list(p, readyList, p->parent_cpu);
    800020f4:	4cb0                	lw	a2,88(s1)
    800020f6:	4581                	li	a1,0
    800020f8:	8526                	mv	a0,s1
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	260080e7          	jalr	608(ra) # 8000235a <add_proc_to_specific_list>
  sched();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	edc080e7          	jalr	-292(ra) # 80001fde <sched>
  release(&p->lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b9a080e7          	jalr	-1126(ra) # 80000ca6 <release>
}
    80002114:	60e2                	ld	ra,24(sp)
    80002116:	6442                	ld	s0,16(sp)
    80002118:	64a2                	ld	s1,8(sp)
    8000211a:	6105                	addi	sp,sp,32
    8000211c:	8082                	ret

000000008000211e <set_cpu>:
  if(number<0 || number>NCPU){
    8000211e:	47a1                	li	a5,8
    80002120:	04a7e763          	bltu	a5,a0,8000216e <set_cpu+0x50>
{
    80002124:	1101                	addi	sp,sp,-32
    80002126:	ec06                	sd	ra,24(sp)
    80002128:	e822                	sd	s0,16(sp)
    8000212a:	e426                	sd	s1,8(sp)
    8000212c:	e04a                	sd	s2,0(sp)
    8000212e:	1000                	addi	s0,sp,32
    80002130:	84aa                	mv	s1,a0
  struct proc* p = myproc();
    80002132:	00000097          	auipc	ra,0x0
    80002136:	c72080e7          	jalr	-910(ra) # 80001da4 <myproc>
    8000213a:	892a                	mv	s2,a0
  cahnge_number_of_proc(p->parent_cpu,b);
    8000213c:	55fd                	li	a1,-1
    8000213e:	4d28                	lw	a0,88(a0)
    80002140:	00000097          	auipc	ra,0x0
    80002144:	998080e7          	jalr	-1640(ra) # 80001ad8 <cahnge_number_of_proc>
  p->parent_cpu=number;
    80002148:	04992c23          	sw	s1,88(s2)
  cahnge_number_of_proc(number,positive);
    8000214c:	4585                	li	a1,1
    8000214e:	8526                	mv	a0,s1
    80002150:	00000097          	auipc	ra,0x0
    80002154:	988080e7          	jalr	-1656(ra) # 80001ad8 <cahnge_number_of_proc>
  yield();
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	f7c080e7          	jalr	-132(ra) # 800020d4 <yield>
  return number;
    80002160:	8526                	mv	a0,s1
}
    80002162:	60e2                	ld	ra,24(sp)
    80002164:	6442                	ld	s0,16(sp)
    80002166:	64a2                	ld	s1,8(sp)
    80002168:	6902                	ld	s2,0(sp)
    8000216a:	6105                	addi	sp,sp,32
    8000216c:	8082                	ret
    return -1;
    8000216e:	557d                	li	a0,-1
}
    80002170:	8082                	ret

0000000080002172 <getList>:
getList(int type, int cpu_id){
    80002172:	1101                	addi	sp,sp,-32
    80002174:	ec06                	sd	ra,24(sp)
    80002176:	e822                	sd	s0,16(sp)
    80002178:	e426                	sd	s1,8(sp)
    8000217a:	e04a                	sd	s2,0(sp)
    8000217c:	1000                	addi	s0,sp,32
    8000217e:	84aa                	mv	s1,a0
    80002180:	892e                	mv	s2,a1
  if(type>3){
    80002182:	478d                	li	a5,3
    80002184:	04a7c663          	blt	a5,a0,800021d0 <getList+0x5e>
  if(type==readyList || type==11){
    80002188:	c125                	beqz	a0,800021e8 <getList+0x76>
  else if(type==zombeList || type==21){
    8000218a:	4785                	li	a5,1
    8000218c:	08f50263          	beq	a0,a5,80002210 <getList+0x9e>
    80002190:	47d5                	li	a5,21
    80002192:	06f48f63          	beq	s1,a5,80002210 <getList+0x9e>
  else if(type==sleepLeast || type==31){
    80002196:	4789                	li	a5,2
    80002198:	08f48563          	beq	s1,a5,80002222 <getList+0xb0>
    8000219c:	47fd                	li	a5,31
    8000219e:	08f48263          	beq	s1,a5,80002222 <getList+0xb0>
  else if(type==unuseList || type==41){
    800021a2:	478d                	li	a5,3
    800021a4:	08f48863          	beq	s1,a5,80002234 <getList+0xc2>
    800021a8:	02900793          	li	a5,41
    800021ac:	08f48463          	beq	s1,a5,80002234 <getList+0xc2>
  else if(type == 51){
    800021b0:	03300793          	li	a5,51
    800021b4:	08f48963          	beq	s1,a5,80002246 <getList+0xd4>
  else if(type == 61){
    800021b8:	03d00793          	li	a5,61
    800021bc:	0af49363          	bne	s1,a5,80002262 <getList+0xf0>
    print_flag++;
    800021c0:	00007717          	auipc	a4,0x7
    800021c4:	eac70713          	addi	a4,a4,-340 # 8000906c <print_flag>
    800021c8:	431c                	lw	a5,0(a4)
    800021ca:	2785                	addiw	a5,a5,1
    800021cc:	c31c                	sw	a5,0(a4)
    800021ce:	a81d                	j	80002204 <getList+0x92>
  printf("type is %d\n",type);
    800021d0:	85aa                	mv	a1,a0
    800021d2:	00006517          	auipc	a0,0x6
    800021d6:	07e50513          	addi	a0,a0,126 # 80008250 <digits+0x210>
    800021da:	ffffe097          	auipc	ra,0xffffe
    800021de:	3ae080e7          	jalr	942(ra) # 80000588 <printf>
  if(type==readyList || type==11){
    800021e2:	47ad                	li	a5,11
    800021e4:	faf496e3          	bne	s1,a5,80002190 <getList+0x1e>
    acquire(&ready_lock[cpu_id]);
    800021e8:	00191513          	slli	a0,s2,0x1
    800021ec:	012505b3          	add	a1,a0,s2
    800021f0:	058e                	slli	a1,a1,0x3
    800021f2:	0000f517          	auipc	a0,0xf
    800021f6:	32e50513          	addi	a0,a0,814 # 80011520 <ready_lock>
    800021fa:	952e                	add	a0,a0,a1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	9f0080e7          	jalr	-1552(ra) # 80000bec <acquire>
}
    80002204:	60e2                	ld	ra,24(sp)
    80002206:	6442                	ld	s0,16(sp)
    80002208:	64a2                	ld	s1,8(sp)
    8000220a:	6902                	ld	s2,0(sp)
    8000220c:	6105                	addi	sp,sp,32
    8000220e:	8082                	ret
    acquire(&zombie_lock);
    80002210:	0000f517          	auipc	a0,0xf
    80002214:	35850513          	addi	a0,a0,856 # 80011568 <zombie_lock>
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	9d4080e7          	jalr	-1580(ra) # 80000bec <acquire>
    80002220:	b7d5                	j	80002204 <getList+0x92>
  acquire(&sleeping_lock);
    80002222:	0000f517          	auipc	a0,0xf
    80002226:	35e50513          	addi	a0,a0,862 # 80011580 <sleeping_lock>
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9c2080e7          	jalr	-1598(ra) # 80000bec <acquire>
    80002232:	bfc9                	j	80002204 <getList+0x92>
  acquire(&unused_lock);
    80002234:	0000f517          	auipc	a0,0xf
    80002238:	36450513          	addi	a0,a0,868 # 80011598 <unused_lock>
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	9b0080e7          	jalr	-1616(ra) # 80000bec <acquire>
    80002244:	b7c1                	j	80002204 <getList+0x92>
    set_cpu(cpu_id);
    80002246:	854a                	mv	a0,s2
    80002248:	00000097          	auipc	ra,0x0
    8000224c:	ed6080e7          	jalr	-298(ra) # 8000211e <set_cpu>
    printf("getList type ==5");
    80002250:	00006517          	auipc	a0,0x6
    80002254:	0a050513          	addi	a0,a0,160 # 800082f0 <digits+0x2b0>
    80002258:	ffffe097          	auipc	ra,0xffffe
    8000225c:	330080e7          	jalr	816(ra) # 80000588 <printf>
    80002260:	b755                	j	80002204 <getList+0x92>
    panic("getList");
    80002262:	00006517          	auipc	a0,0x6
    80002266:	0a650513          	addi	a0,a0,166 # 80008308 <digits+0x2c8>
    8000226a:	ffffe097          	auipc	ra,0xffffe
    8000226e:	2d4080e7          	jalr	724(ra) # 8000053e <panic>

0000000080002272 <setFirst>:
{
    80002272:	7179                	addi	sp,sp,-48
    80002274:	f406                	sd	ra,40(sp)
    80002276:	f022                	sd	s0,32(sp)
    80002278:	ec26                	sd	s1,24(sp)
    8000227a:	e84a                	sd	s2,16(sp)
    8000227c:	e44e                	sd	s3,8(sp)
    8000227e:	1800                	addi	s0,sp,48
    80002280:	89aa                	mv	s3,a0
    80002282:	84ae                	mv	s1,a1
    80002284:	8932                	mv	s2,a2
  if(type>3){
    80002286:	478d                	li	a5,3
    80002288:	02b7c663          	blt	a5,a1,800022b4 <setFirst+0x42>
  if(type==readyList || type==11){
    8000228c:	eddd                	bnez	a1,8000234a <setFirst+0xd8>
    cpus[cpu_id].first = p;
    8000228e:	00391793          	slli	a5,s2,0x3
    80002292:	01278633          	add	a2,a5,s2
    80002296:	0612                	slli	a2,a2,0x4
    80002298:	0000f797          	auipc	a5,0xf
    8000229c:	04878793          	addi	a5,a5,72 # 800112e0 <readyLock>
    800022a0:	963e                	add	a2,a2,a5
    800022a2:	11363c23          	sd	s3,280(a2) # 1118 <_entry-0x7fffeee8>
}
    800022a6:	70a2                	ld	ra,40(sp)
    800022a8:	7402                	ld	s0,32(sp)
    800022aa:	64e2                	ld	s1,24(sp)
    800022ac:	6942                	ld	s2,16(sp)
    800022ae:	69a2                	ld	s3,8(sp)
    800022b0:	6145                	addi	sp,sp,48
    800022b2:	8082                	ret
  printf("type is %d\n",type);
    800022b4:	00006517          	auipc	a0,0x6
    800022b8:	f9c50513          	addi	a0,a0,-100 # 80008250 <digits+0x210>
    800022bc:	ffffe097          	auipc	ra,0xffffe
    800022c0:	2cc080e7          	jalr	716(ra) # 80000588 <printf>
  if(type==readyList || type==11){
    800022c4:	47ad                	li	a5,11
    800022c6:	fcf484e3          	beq	s1,a5,8000228e <setFirst+0x1c>
  else if(type==zombeList || type==21){
    800022ca:	47d5                	li	a5,21
    800022cc:	08f48263          	beq	s1,a5,80002350 <setFirst+0xde>
  else if(type==sleepLeast || type==31){
    800022d0:	4789                	li	a5,2
    800022d2:	02f48c63          	beq	s1,a5,8000230a <setFirst+0x98>
    800022d6:	47fd                	li	a5,31
    800022d8:	02f48963          	beq	s1,a5,8000230a <setFirst+0x98>
  else if(type==unuseList || type==41){
    800022dc:	478d                	li	a5,3
    800022de:	02f48b63          	beq	s1,a5,80002314 <setFirst+0xa2>
    800022e2:	02900793          	li	a5,41
    800022e6:	02f48763          	beq	s1,a5,80002314 <setFirst+0xa2>
  else if(type == 51){
    800022ea:	03300793          	li	a5,51
    800022ee:	02f48863          	beq	s1,a5,8000231e <setFirst+0xac>
  else if(type == 61){
    800022f2:	03d00793          	li	a5,61
    800022f6:	04f49263          	bne	s1,a5,8000233a <setFirst+0xc8>
    print_flag++;
    800022fa:	00007717          	auipc	a4,0x7
    800022fe:	d7270713          	addi	a4,a4,-654 # 8000906c <print_flag>
    80002302:	431c                	lw	a5,0(a4)
    80002304:	2785                	addiw	a5,a5,1
    80002306:	c31c                	sw	a5,0(a4)
    80002308:	bf79                	j	800022a6 <setFirst+0x34>
    sleeping_list = p;
    8000230a:	00007797          	auipc	a5,0x7
    8000230e:	d137bf23          	sd	s3,-738(a5) # 80009028 <sleeping_list>
    80002312:	bf51                	j	800022a6 <setFirst+0x34>
  unused_list = p;
    80002314:	00007797          	auipc	a5,0x7
    80002318:	d137be23          	sd	s3,-740(a5) # 80009030 <unused_list>
    8000231c:	b769                	j	800022a6 <setFirst+0x34>
    set_cpu(cpu_id);
    8000231e:	854a                	mv	a0,s2
    80002320:	00000097          	auipc	ra,0x0
    80002324:	dfe080e7          	jalr	-514(ra) # 8000211e <set_cpu>
    printf("getList type ==5");
    80002328:	00006517          	auipc	a0,0x6
    8000232c:	fc850513          	addi	a0,a0,-56 # 800082f0 <digits+0x2b0>
    80002330:	ffffe097          	auipc	ra,0xffffe
    80002334:	258080e7          	jalr	600(ra) # 80000588 <printf>
    80002338:	b7bd                	j	800022a6 <setFirst+0x34>
    panic("getList");
    8000233a:	00006517          	auipc	a0,0x6
    8000233e:	fce50513          	addi	a0,a0,-50 # 80008308 <digits+0x2c8>
    80002342:	ffffe097          	auipc	ra,0xffffe
    80002346:	1fc080e7          	jalr	508(ra) # 8000053e <panic>
  else if(type==zombeList || type==21){
    8000234a:	4785                	li	a5,1
    8000234c:	f6f59fe3          	bne	a1,a5,800022ca <setFirst+0x58>
    zombie_list = p;
    80002350:	00007797          	auipc	a5,0x7
    80002354:	cf37b423          	sd	s3,-792(a5) # 80009038 <zombie_list>
    80002358:	b7b9                	j	800022a6 <setFirst+0x34>

000000008000235a <add_proc_to_specific_list>:
{
    8000235a:	7139                	addi	sp,sp,-64
    8000235c:	fc06                	sd	ra,56(sp)
    8000235e:	f822                	sd	s0,48(sp)
    80002360:	f426                	sd	s1,40(sp)
    80002362:	f04a                	sd	s2,32(sp)
    80002364:	ec4e                	sd	s3,24(sp)
    80002366:	e852                	sd	s4,16(sp)
    80002368:	e456                	sd	s5,8(sp)
    8000236a:	e05a                	sd	s6,0(sp)
    8000236c:	0080                	addi	s0,sp,64
  if(!p){
    8000236e:	c129                	beqz	a0,800023b0 <add_proc_to_specific_list+0x56>
    80002370:	8b2a                	mv	s6,a0
    80002372:	8a2e                	mv	s4,a1
    80002374:	8ab2                	mv	s5,a2
  getList(type, cpu_id);
    80002376:	85b2                	mv	a1,a2
    80002378:	8552                	mv	a0,s4
    8000237a:	00000097          	auipc	ra,0x0
    8000237e:	df8080e7          	jalr	-520(ra) # 80002172 <getList>
  current = getFirst(type, cpu_id);
    80002382:	85d6                	mv	a1,s5
    80002384:	8552                	mv	a0,s4
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	7a2080e7          	jalr	1954(ra) # 80001b28 <getFirst>
    8000238e:	84aa                	mv	s1,a0
  struct proc* prev = 0;
    80002390:	4901                	li	s2,0
  if(!current){// set first in list
    80002392:	e129                	bnez	a0,800023d4 <add_proc_to_specific_list+0x7a>
    setFirst(p, type, cpu_id);
    80002394:	8656                	mv	a2,s5
    80002396:	85d2                	mv	a1,s4
    80002398:	855a                	mv	a0,s6
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	ed8080e7          	jalr	-296(ra) # 80002272 <setFirst>
    release_list(type, cpu_id);
    800023a2:	85d6                	mv	a1,s5
    800023a4:	8552                	mv	a0,s4
    800023a6:	00000097          	auipc	ra,0x0
    800023aa:	8b0080e7          	jalr	-1872(ra) # 80001c56 <release_list>
    800023ae:	a891                	j	80002402 <add_proc_to_specific_list+0xa8>
    panic("add_proc_to_specific_list");
    800023b0:	00006517          	auipc	a0,0x6
    800023b4:	f6050513          	addi	a0,a0,-160 # 80008310 <digits+0x2d0>
    800023b8:	ffffe097          	auipc	ra,0xffffe
    800023bc:	186080e7          	jalr	390(ra) # 8000053e <panic>
        release_list(type, cpu_id);
    800023c0:	85d6                	mv	a1,s5
    800023c2:	8552                	mv	a0,s4
    800023c4:	00000097          	auipc	ra,0x0
    800023c8:	892080e7          	jalr	-1902(ra) # 80001c56 <release_list>
      current = current->next;
    800023cc:	68bc                	ld	a5,80(s1)
    while(current){
    800023ce:	8926                	mv	s2,s1
    800023d0:	c395                	beqz	a5,800023f4 <add_proc_to_specific_list+0x9a>
      current = current->next;
    800023d2:	84be                	mv	s1,a5
      acquire(&current->list_lock);
    800023d4:	01848993          	addi	s3,s1,24
    800023d8:	854e                	mv	a0,s3
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	812080e7          	jalr	-2030(ra) # 80000bec <acquire>
      if(prev){
    800023e2:	fc090fe3          	beqz	s2,800023c0 <add_proc_to_specific_list+0x66>
        release(&prev->list_lock);
    800023e6:	01890513          	addi	a0,s2,24
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8bc080e7          	jalr	-1860(ra) # 80000ca6 <release>
    800023f2:	bfe9                	j	800023cc <add_proc_to_specific_list+0x72>
    prev->next = p;
    800023f4:	0564b823          	sd	s6,80(s1)
    release(&prev->list_lock);
    800023f8:	854e                	mv	a0,s3
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	8ac080e7          	jalr	-1876(ra) # 80000ca6 <release>
}
    80002402:	70e2                	ld	ra,56(sp)
    80002404:	7442                	ld	s0,48(sp)
    80002406:	74a2                	ld	s1,40(sp)
    80002408:	7902                	ld	s2,32(sp)
    8000240a:	69e2                	ld	s3,24(sp)
    8000240c:	6a42                	ld	s4,16(sp)
    8000240e:	6aa2                	ld	s5,8(sp)
    80002410:	6b02                	ld	s6,0(sp)
    80002412:	6121                	addi	sp,sp,64
    80002414:	8082                	ret

0000000080002416 <procinit>:
{
    80002416:	715d                	addi	sp,sp,-80
    80002418:	e486                	sd	ra,72(sp)
    8000241a:	e0a2                	sd	s0,64(sp)
    8000241c:	fc26                	sd	s1,56(sp)
    8000241e:	f84a                	sd	s2,48(sp)
    80002420:	f44e                	sd	s3,40(sp)
    80002422:	f052                	sd	s4,32(sp)
    80002424:	ec56                	sd	s5,24(sp)
    80002426:	e85a                	sd	s6,16(sp)
    80002428:	e45e                	sd	s7,8(sp)
    8000242a:	e062                	sd	s8,0(sp)
    8000242c:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000242e:	00006597          	auipc	a1,0x6
    80002432:	f0258593          	addi	a1,a1,-254 # 80008330 <digits+0x2f0>
    80002436:	0000f517          	auipc	a0,0xf
    8000243a:	17a50513          	addi	a0,a0,378 # 800115b0 <pid_lock>
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	716080e7          	jalr	1814(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80002446:	00006597          	auipc	a1,0x6
    8000244a:	ef258593          	addi	a1,a1,-270 # 80008338 <digits+0x2f8>
    8000244e:	0000f517          	auipc	a0,0xf
    80002452:	17a50513          	addi	a0,a0,378 # 800115c8 <wait_lock>
    80002456:	ffffe097          	auipc	ra,0xffffe
    8000245a:	6fe080e7          	jalr	1790(ra) # 80000b54 <initlock>
  initlock(&zombie_lock, "zombie lock");
    8000245e:	00006597          	auipc	a1,0x6
    80002462:	eea58593          	addi	a1,a1,-278 # 80008348 <digits+0x308>
    80002466:	0000f517          	auipc	a0,0xf
    8000246a:	10250513          	addi	a0,a0,258 # 80011568 <zombie_lock>
    8000246e:	ffffe097          	auipc	ra,0xffffe
    80002472:	6e6080e7          	jalr	1766(ra) # 80000b54 <initlock>
  initlock(&sleeping_lock, "sleeping lock");
    80002476:	00006597          	auipc	a1,0x6
    8000247a:	ee258593          	addi	a1,a1,-286 # 80008358 <digits+0x318>
    8000247e:	0000f517          	auipc	a0,0xf
    80002482:	10250513          	addi	a0,a0,258 # 80011580 <sleeping_lock>
    80002486:	ffffe097          	auipc	ra,0xffffe
    8000248a:	6ce080e7          	jalr	1742(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused lock");
    8000248e:	00006597          	auipc	a1,0x6
    80002492:	eda58593          	addi	a1,a1,-294 # 80008368 <digits+0x328>
    80002496:	0000f517          	auipc	a0,0xf
    8000249a:	10250513          	addi	a0,a0,258 # 80011598 <unused_lock>
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	6b6080e7          	jalr	1718(ra) # 80000b54 <initlock>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    800024a6:	0000f497          	auipc	s1,0xf
    800024aa:	07a48493          	addi	s1,s1,122 # 80011520 <ready_lock>
    initlock(s, "ready lock");
    800024ae:	00006997          	auipc	s3,0x6
    800024b2:	eca98993          	addi	s3,s3,-310 # 80008378 <digits+0x338>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    800024b6:	0000f917          	auipc	s2,0xf
    800024ba:	0b290913          	addi	s2,s2,178 # 80011568 <zombie_lock>
    initlock(s, "ready lock");
    800024be:	85ce                	mv	a1,s3
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	692080e7          	jalr	1682(ra) # 80000b54 <initlock>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    800024ca:	04e1                	addi	s1,s1,24
    800024cc:	ff2499e3          	bne	s1,s2,800024be <procinit+0xa8>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024d0:	0000f497          	auipc	s1,0xf
    800024d4:	11048493          	addi	s1,s1,272 # 800115e0 <proc>
      initlock(&p->lock, "proc");
    800024d8:	00006c17          	auipc	s8,0x6
    800024dc:	eb0c0c13          	addi	s8,s8,-336 # 80008388 <digits+0x348>
      initlock(&p->list_lock, "list lock");
    800024e0:	00006b97          	auipc	s7,0x6
    800024e4:	eb0b8b93          	addi	s7,s7,-336 # 80008390 <digits+0x350>
      p->kstack = KSTACK((int) (p - proc));
    800024e8:	8b26                	mv	s6,s1
    800024ea:	00006a97          	auipc	s5,0x6
    800024ee:	b16a8a93          	addi	s5,s5,-1258 # 80008000 <etext>
    800024f2:	04000937          	lui	s2,0x4000
    800024f6:	197d                	addi	s2,s2,-1
    800024f8:	0932                	slli	s2,s2,0xc
       p->parent_cpu = -1;
    800024fa:	5a7d                	li	s4,-1
  for(p = proc; p < &proc[NPROC]; p++) {
    800024fc:	00015997          	auipc	s3,0x15
    80002500:	4e498993          	addi	s3,s3,1252 # 800179e0 <tickslock>
      initlock(&p->lock, "proc");
    80002504:	85e2                	mv	a1,s8
    80002506:	8526                	mv	a0,s1
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	64c080e7          	jalr	1612(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list lock");
    80002510:	85de                	mv	a1,s7
    80002512:	01848513          	addi	a0,s1,24
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	63e080e7          	jalr	1598(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000251e:	416487b3          	sub	a5,s1,s6
    80002522:	8791                	srai	a5,a5,0x4
    80002524:	000ab703          	ld	a4,0(s5)
    80002528:	02e787b3          	mul	a5,a5,a4
    8000252c:	2785                	addiw	a5,a5,1
    8000252e:	00d7979b          	slliw	a5,a5,0xd
    80002532:	40f907b3          	sub	a5,s2,a5
    80002536:	f4bc                	sd	a5,104(s1)
       p->parent_cpu = -1;
    80002538:	0544ac23          	sw	s4,88(s1)
       add_proc_to_specific_list(p, unuseList, -1);
    8000253c:	567d                	li	a2,-1
    8000253e:	458d                	li	a1,3
    80002540:	8526                	mv	a0,s1
    80002542:	00000097          	auipc	ra,0x0
    80002546:	e18080e7          	jalr	-488(ra) # 8000235a <add_proc_to_specific_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000254a:	19048493          	addi	s1,s1,400
    8000254e:	fb349be3          	bne	s1,s3,80002504 <procinit+0xee>
}
    80002552:	60a6                	ld	ra,72(sp)
    80002554:	6406                	ld	s0,64(sp)
    80002556:	74e2                	ld	s1,56(sp)
    80002558:	7942                	ld	s2,48(sp)
    8000255a:	79a2                	ld	s3,40(sp)
    8000255c:	7a02                	ld	s4,32(sp)
    8000255e:	6ae2                	ld	s5,24(sp)
    80002560:	6b42                	ld	s6,16(sp)
    80002562:	6ba2                	ld	s7,8(sp)
    80002564:	6c02                	ld	s8,0(sp)
    80002566:	6161                	addi	sp,sp,80
    80002568:	8082                	ret

000000008000256a <remove_first>:
{
    8000256a:	7179                	addi	sp,sp,-48
    8000256c:	f406                	sd	ra,40(sp)
    8000256e:	f022                	sd	s0,32(sp)
    80002570:	ec26                	sd	s1,24(sp)
    80002572:	e84a                	sd	s2,16(sp)
    80002574:	e44e                	sd	s3,8(sp)
    80002576:	e052                	sd	s4,0(sp)
    80002578:	1800                	addi	s0,sp,48
    8000257a:	892a                	mv	s2,a0
    8000257c:	89ae                	mv	s3,a1
  getList(type, cpu_id);//acquire lock
    8000257e:	00000097          	auipc	ra,0x0
    80002582:	bf4080e7          	jalr	-1036(ra) # 80002172 <getList>
  struct proc* head = getFirst(type, cpu_id);//aquire list after we have loock 
    80002586:	85ce                	mv	a1,s3
    80002588:	854a                	mv	a0,s2
    8000258a:	fffff097          	auipc	ra,0xfffff
    8000258e:	59e080e7          	jalr	1438(ra) # 80001b28 <getFirst>
    80002592:	84aa                	mv	s1,a0
  if(!head){
    80002594:	c529                	beqz	a0,800025de <remove_first+0x74>
    acquire(&head->list_lock);
    80002596:	01850a13          	addi	s4,a0,24
    8000259a:	8552                	mv	a0,s4
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	650080e7          	jalr	1616(ra) # 80000bec <acquire>
    setFirst(head->next, type, cpu_id);
    800025a4:	864e                	mv	a2,s3
    800025a6:	85ca                	mv	a1,s2
    800025a8:	68a8                	ld	a0,80(s1)
    800025aa:	00000097          	auipc	ra,0x0
    800025ae:	cc8080e7          	jalr	-824(ra) # 80002272 <setFirst>
    head->next = 0;
    800025b2:	0404b823          	sd	zero,80(s1)
    release(&head->list_lock);
    800025b6:	8552                	mv	a0,s4
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	6ee080e7          	jalr	1774(ra) # 80000ca6 <release>
    release_list(type, cpu_id);//realese loock 
    800025c0:	85ce                	mv	a1,s3
    800025c2:	854a                	mv	a0,s2
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	692080e7          	jalr	1682(ra) # 80001c56 <release_list>
}
    800025cc:	8526                	mv	a0,s1
    800025ce:	70a2                	ld	ra,40(sp)
    800025d0:	7402                	ld	s0,32(sp)
    800025d2:	64e2                	ld	s1,24(sp)
    800025d4:	6942                	ld	s2,16(sp)
    800025d6:	69a2                	ld	s3,8(sp)
    800025d8:	6a02                	ld	s4,0(sp)
    800025da:	6145                	addi	sp,sp,48
    800025dc:	8082                	ret
    release_list(type, cpu_id);//realese loock 
    800025de:	85ce                	mv	a1,s3
    800025e0:	854a                	mv	a0,s2
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	674080e7          	jalr	1652(ra) # 80001c56 <release_list>
    800025ea:	b7cd                	j	800025cc <remove_first+0x62>

00000000800025ec <blncflag_on>:
{
    800025ec:	7139                	addi	sp,sp,-64
    800025ee:	fc06                	sd	ra,56(sp)
    800025f0:	f822                	sd	s0,48(sp)
    800025f2:	f426                	sd	s1,40(sp)
    800025f4:	f04a                	sd	s2,32(sp)
    800025f6:	ec4e                	sd	s3,24(sp)
    800025f8:	e852                	sd	s4,16(sp)
    800025fa:	e456                	sd	s5,8(sp)
    800025fc:	e05a                	sd	s6,0(sp)
    800025fe:	0080                	addi	s0,sp,64
    80002600:	8792                	mv	a5,tp
  int id = r_tp();
    80002602:	2781                	sext.w	a5,a5
    80002604:	8a12                	mv	s4,tp
    80002606:	2a01                	sext.w	s4,s4
  c->proc = 0;
    80002608:	00379993          	slli	s3,a5,0x3
    8000260c:	00f98733          	add	a4,s3,a5
    80002610:	00471693          	slli	a3,a4,0x4
    80002614:	0000f717          	auipc	a4,0xf
    80002618:	ccc70713          	addi	a4,a4,-820 # 800112e0 <readyLock>
    8000261c:	9736                	add	a4,a4,a3
    8000261e:	08073c23          	sd	zero,152(a4)
    swtch(&c->context, &p->context);
    80002622:	0000f717          	auipc	a4,0xf
    80002626:	d5e70713          	addi	a4,a4,-674 # 80011380 <cpus+0x10>
    8000262a:	00e689b3          	add	s3,a3,a4
    if(p->state!=RUNNABLE)
    8000262e:	4a8d                	li	s5,3
    p->state = RUNNING;
    80002630:	4b11                	li	s6,4
    c->proc = p;
    80002632:	0000f917          	auipc	s2,0xf
    80002636:	cae90913          	addi	s2,s2,-850 # 800112e0 <readyLock>
    8000263a:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000263c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002640:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002644:	10079073          	csrw	sstatus,a5
    p = remove_first(readyList, cpu_id);
    80002648:	85d2                	mv	a1,s4
    8000264a:	4501                	li	a0,0
    8000264c:	00000097          	auipc	ra,0x0
    80002650:	f1e080e7          	jalr	-226(ra) # 8000256a <remove_first>
    80002654:	84aa                	mv	s1,a0
    if(!p){
    80002656:	d17d                	beqz	a0,8000263c <blncflag_on+0x50>
    acquire(&p->lock);
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	594080e7          	jalr	1428(ra) # 80000bec <acquire>
    if(p->state!=RUNNABLE)
    80002660:	589c                	lw	a5,48(s1)
    80002662:	03579563          	bne	a5,s5,8000268c <blncflag_on+0xa0>
    p->state = RUNNING;
    80002666:	0364a823          	sw	s6,48(s1)
    c->proc = p;
    8000266a:	08993c23          	sd	s1,152(s2)
    swtch(&c->context, &p->context);
    8000266e:	08848593          	addi	a1,s1,136
    80002672:	854e                	mv	a0,s3
    80002674:	00001097          	auipc	ra,0x1
    80002678:	be4080e7          	jalr	-1052(ra) # 80003258 <swtch>
    c->proc = 0;
    8000267c:	08093c23          	sd	zero,152(s2)
    release(&p->lock);
    80002680:	8526                	mv	a0,s1
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	624080e7          	jalr	1572(ra) # 80000ca6 <release>
    8000268a:	bf4d                	j	8000263c <blncflag_on+0x50>
      panic("bad proc was selected");
    8000268c:	00006517          	auipc	a0,0x6
    80002690:	d1450513          	addi	a0,a0,-748 # 800083a0 <digits+0x360>
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	eaa080e7          	jalr	-342(ra) # 8000053e <panic>

000000008000269c <scheduler>:
{
    8000269c:	1141                	addi	sp,sp,-16
    8000269e:	e406                	sd	ra,8(sp)
    800026a0:	e022                	sd	s0,0(sp)
    800026a2:	0800                	addi	s0,sp,16
      if(!print_flag){
    800026a4:	00007797          	auipc	a5,0x7
    800026a8:	9c87a783          	lw	a5,-1592(a5) # 8000906c <print_flag>
    800026ac:	c789                	beqz	a5,800026b6 <scheduler+0x1a>
    blncflag_on();
    800026ae:	00000097          	auipc	ra,0x0
    800026b2:	f3e080e7          	jalr	-194(ra) # 800025ec <blncflag_on>
      print_flag++;
    800026b6:	4785                	li	a5,1
    800026b8:	00007717          	auipc	a4,0x7
    800026bc:	9af72a23          	sw	a5,-1612(a4) # 8000906c <print_flag>
      printf("BLNCFLG is ON\n");
    800026c0:	00006517          	auipc	a0,0x6
    800026c4:	cf850513          	addi	a0,a0,-776 # 800083b8 <digits+0x378>
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	ec0080e7          	jalr	-320(ra) # 80000588 <printf>
    800026d0:	bff9                	j	800026ae <scheduler+0x12>

00000000800026d2 <blncflag_off>:
{
    800026d2:	7139                	addi	sp,sp,-64
    800026d4:	fc06                	sd	ra,56(sp)
    800026d6:	f822                	sd	s0,48(sp)
    800026d8:	f426                	sd	s1,40(sp)
    800026da:	f04a                	sd	s2,32(sp)
    800026dc:	ec4e                	sd	s3,24(sp)
    800026de:	e852                	sd	s4,16(sp)
    800026e0:	e456                	sd	s5,8(sp)
    800026e2:	e05a                	sd	s6,0(sp)
    800026e4:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    800026e6:	8792                	mv	a5,tp
  int id = r_tp();
    800026e8:	2781                	sext.w	a5,a5
    800026ea:	8a12                	mv	s4,tp
    800026ec:	2a01                	sext.w	s4,s4
  c->proc = 0;
    800026ee:	00379993          	slli	s3,a5,0x3
    800026f2:	00f98733          	add	a4,s3,a5
    800026f6:	00471693          	slli	a3,a4,0x4
    800026fa:	0000f717          	auipc	a4,0xf
    800026fe:	be670713          	addi	a4,a4,-1050 # 800112e0 <readyLock>
    80002702:	9736                	add	a4,a4,a3
    80002704:	08073c23          	sd	zero,152(a4)
        swtch(&c->context, &p->context);
    80002708:	0000f717          	auipc	a4,0xf
    8000270c:	c7870713          	addi	a4,a4,-904 # 80011380 <cpus+0x10>
    80002710:	00e689b3          	add	s3,a3,a4
      if(p->state != RUNNABLE)
    80002714:	4a8d                	li	s5,3
        p->state = RUNNING;
    80002716:	4b11                	li	s6,4
        c->proc = p;
    80002718:	0000f917          	auipc	s2,0xf
    8000271c:	bc890913          	addi	s2,s2,-1080 # 800112e0 <readyLock>
    80002720:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002722:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002726:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000272a:	10079073          	csrw	sstatus,a5
    p = remove_first(readyList, cpu_id);
    8000272e:	85d2                	mv	a1,s4
    80002730:	4501                	li	a0,0
    80002732:	00000097          	auipc	ra,0x0
    80002736:	e38080e7          	jalr	-456(ra) # 8000256a <remove_first>
    8000273a:	84aa                	mv	s1,a0
    if(!p){ // no proces ready 
    8000273c:	d17d                	beqz	a0,80002722 <blncflag_off+0x50>
      acquire(&p->lock);
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	4ae080e7          	jalr	1198(ra) # 80000bec <acquire>
      if(p->state != RUNNABLE)
    80002746:	589c                	lw	a5,48(s1)
    80002748:	03579563          	bne	a5,s5,80002772 <blncflag_off+0xa0>
        p->state = RUNNING;
    8000274c:	0364a823          	sw	s6,48(s1)
        c->proc = p;
    80002750:	08993c23          	sd	s1,152(s2)
        swtch(&c->context, &p->context);
    80002754:	08848593          	addi	a1,s1,136
    80002758:	854e                	mv	a0,s3
    8000275a:	00001097          	auipc	ra,0x1
    8000275e:	afe080e7          	jalr	-1282(ra) # 80003258 <swtch>
        c->proc = 0;
    80002762:	08093c23          	sd	zero,152(s2)
      release(&p->lock);
    80002766:	8526                	mv	a0,s1
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	53e080e7          	jalr	1342(ra) # 80000ca6 <release>
    80002770:	bf4d                	j	80002722 <blncflag_off+0x50>
        panic("bad proc was selected");
    80002772:	00006517          	auipc	a0,0x6
    80002776:	c2e50513          	addi	a0,a0,-978 # 800083a0 <digits+0x360>
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	dc4080e7          	jalr	-572(ra) # 8000053e <panic>

0000000080002782 <remove_proc>:
remove_proc(struct proc* p, int type){
    80002782:	7179                	addi	sp,sp,-48
    80002784:	f406                	sd	ra,40(sp)
    80002786:	f022                	sd	s0,32(sp)
    80002788:	ec26                	sd	s1,24(sp)
    8000278a:	e84a                	sd	s2,16(sp)
    8000278c:	e44e                	sd	s3,8(sp)
    8000278e:	e052                	sd	s4,0(sp)
    80002790:	1800                	addi	s0,sp,48
    80002792:	8a2a                	mv	s4,a0
    80002794:	84ae                	mv	s1,a1
  getList(type, p->parent_cpu);
    80002796:	4d2c                	lw	a1,88(a0)
    80002798:	8526                	mv	a0,s1
    8000279a:	00000097          	auipc	ra,0x0
    8000279e:	9d8080e7          	jalr	-1576(ra) # 80002172 <getList>
  struct proc* head = getFirst(type, p->parent_cpu);
    800027a2:	058a2583          	lw	a1,88(s4)
    800027a6:	8526                	mv	a0,s1
    800027a8:	fffff097          	auipc	ra,0xfffff
    800027ac:	380080e7          	jalr	896(ra) # 80001b28 <getFirst>
  if(!head){
    800027b0:	c521                	beqz	a0,800027f8 <remove_proc+0x76>
    800027b2:	892a                	mv	s2,a0
    if(p == head){
    800027b4:	04aa0b63          	beq	s4,a0,8000280a <remove_proc+0x88>
        acquire(&head->list_lock);
    800027b8:	0561                	addi	a0,a0,24
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	432080e7          	jalr	1074(ra) # 80000bec <acquire>
          release_list(type,p->parent_cpu);
    800027c2:	058a2583          	lw	a1,88(s4)
    800027c6:	8526                	mv	a0,s1
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	48e080e7          	jalr	1166(ra) # 80001c56 <release_list>
        head = head->next;
    800027d0:	05093483          	ld	s1,80(s2)
      while(head){
    800027d4:	c4c5                	beqz	s1,8000287c <remove_proc+0xfa>
        acquire(&head->list_lock);
    800027d6:	01848993          	addi	s3,s1,24
    800027da:	854e                	mv	a0,s3
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	410080e7          	jalr	1040(ra) # 80000bec <acquire>
        if(p == head){
    800027e4:	069a0363          	beq	s4,s1,8000284a <remove_proc+0xc8>
          release(&prev->list_lock);
    800027e8:	01890513          	addi	a0,s2,24
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	4ba080e7          	jalr	1210(ra) # 80000ca6 <release>
        head = head->next;
    800027f4:	8926                	mv	s2,s1
    800027f6:	bfe9                	j	800027d0 <remove_proc+0x4e>
    release_list(type, p->parent_cpu);
    800027f8:	058a2583          	lw	a1,88(s4)
    800027fc:	8526                	mv	a0,s1
    800027fe:	fffff097          	auipc	ra,0xfffff
    80002802:	458080e7          	jalr	1112(ra) # 80001c56 <release_list>
    return 0;
    80002806:	4501                	li	a0,0
    80002808:	a095                	j	8000286c <remove_proc+0xea>
      acquire(&p->list_lock);
    8000280a:	01850993          	addi	s3,a0,24
    8000280e:	854e                	mv	a0,s3
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	3dc080e7          	jalr	988(ra) # 80000bec <acquire>
      setFirst(p->next, type, p->parent_cpu);
    80002818:	05892603          	lw	a2,88(s2)
    8000281c:	85a6                	mv	a1,s1
    8000281e:	05093503          	ld	a0,80(s2)
    80002822:	00000097          	auipc	ra,0x0
    80002826:	a50080e7          	jalr	-1456(ra) # 80002272 <setFirst>
      p->next = 0;
    8000282a:	04093823          	sd	zero,80(s2)
      release(&p->list_lock);
    8000282e:	854e                	mv	a0,s3
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	476080e7          	jalr	1142(ra) # 80000ca6 <release>
      release_list(type, p->parent_cpu);
    80002838:	05892583          	lw	a1,88(s2)
    8000283c:	8526                	mv	a0,s1
    8000283e:	fffff097          	auipc	ra,0xfffff
    80002842:	418080e7          	jalr	1048(ra) # 80001c56 <release_list>
    return 0;
    80002846:	4501                	li	a0,0
    80002848:	a015                	j	8000286c <remove_proc+0xea>
          prev->next = head->next;
    8000284a:	68bc                	ld	a5,80(s1)
    8000284c:	04f93823          	sd	a5,80(s2)
          p->next = 0;
    80002850:	0404b823          	sd	zero,80(s1)
          release(&head->list_lock);
    80002854:	854e                	mv	a0,s3
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	450080e7          	jalr	1104(ra) # 80000ca6 <release>
          release(&prev->list_lock);
    8000285e:	01890513          	addi	a0,s2,24
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	444080e7          	jalr	1092(ra) # 80000ca6 <release>
          return 1;
    8000286a:	4505                	li	a0,1
}
    8000286c:	70a2                	ld	ra,40(sp)
    8000286e:	7402                	ld	s0,32(sp)
    80002870:	64e2                	ld	s1,24(sp)
    80002872:	6942                	ld	s2,16(sp)
    80002874:	69a2                	ld	s3,8(sp)
    80002876:	6a02                	ld	s4,0(sp)
    80002878:	6145                	addi	sp,sp,48
    8000287a:	8082                	ret
    return 0;
    8000287c:	4501                	li	a0,0
    8000287e:	b7fd                	j	8000286c <remove_proc+0xea>

0000000080002880 <freeproc>:
{
    80002880:	1101                	addi	sp,sp,-32
    80002882:	ec06                	sd	ra,24(sp)
    80002884:	e822                	sd	s0,16(sp)
    80002886:	e426                	sd	s1,8(sp)
    80002888:	1000                	addi	s0,sp,32
    8000288a:	84aa                	mv	s1,a0
  if(p->trapframe)
    8000288c:	6148                	ld	a0,128(a0)
    8000288e:	c509                	beqz	a0,80002898 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	168080e7          	jalr	360(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002898:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    8000289c:	7ca8                	ld	a0,120(s1)
    8000289e:	c511                	beqz	a0,800028aa <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800028a0:	78ac                	ld	a1,112(s1)
    800028a2:	fffff097          	auipc	ra,0xfffff
    800028a6:	676080e7          	jalr	1654(ra) # 80001f18 <proc_freepagetable>
  p->pagetable = 0;
    800028aa:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    800028ae:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    800028b2:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    800028b6:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    800028ba:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    800028be:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    800028c2:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    800028c6:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    800028ca:	0204a823          	sw	zero,48(s1)
  remove_proc(p, zombeList);
    800028ce:	4585                	li	a1,1
    800028d0:	8526                	mv	a0,s1
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	eb0080e7          	jalr	-336(ra) # 80002782 <remove_proc>
  add_proc_to_specific_list(p, unuseList, -1);
    800028da:	567d                	li	a2,-1
    800028dc:	458d                	li	a1,3
    800028de:	8526                	mv	a0,s1
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	a7a080e7          	jalr	-1414(ra) # 8000235a <add_proc_to_specific_list>
}
    800028e8:	60e2                	ld	ra,24(sp)
    800028ea:	6442                	ld	s0,16(sp)
    800028ec:	64a2                	ld	s1,8(sp)
    800028ee:	6105                	addi	sp,sp,32
    800028f0:	8082                	ret

00000000800028f2 <allocproc>:
{
    800028f2:	7179                	addi	sp,sp,-48
    800028f4:	f406                	sd	ra,40(sp)
    800028f6:	f022                	sd	s0,32(sp)
    800028f8:	ec26                	sd	s1,24(sp)
    800028fa:	e84a                	sd	s2,16(sp)
    800028fc:	e44e                	sd	s3,8(sp)
    800028fe:	1800                	addi	s0,sp,48
  p = remove_first(unuseList, -1);
    80002900:	55fd                	li	a1,-1
    80002902:	450d                	li	a0,3
    80002904:	00000097          	auipc	ra,0x0
    80002908:	c66080e7          	jalr	-922(ra) # 8000256a <remove_first>
    8000290c:	84aa                	mv	s1,a0
  if(!p){
    8000290e:	cd39                	beqz	a0,8000296c <allocproc+0x7a>
  acquire(&p->lock);
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	2dc080e7          	jalr	732(ra) # 80000bec <acquire>
  p->pid = allocpid();
    80002918:	fffff097          	auipc	ra,0xfffff
    8000291c:	52c080e7          	jalr	1324(ra) # 80001e44 <allocpid>
    80002920:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80002922:	4785                	li	a5,1
    80002924:	d89c                	sw	a5,48(s1)
  p->next = 0;
    80002926:	0404b823          	sd	zero,80(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	1ca080e7          	jalr	458(ra) # 80000af4 <kalloc>
    80002932:	892a                	mv	s2,a0
    80002934:	e0c8                	sd	a0,128(s1)
    80002936:	c139                	beqz	a0,8000297c <allocproc+0x8a>
  p->pagetable = proc_pagetable(p);
    80002938:	8526                	mv	a0,s1
    8000293a:	fffff097          	auipc	ra,0xfffff
    8000293e:	542080e7          	jalr	1346(ra) # 80001e7c <proc_pagetable>
    80002942:	892a                	mv	s2,a0
    80002944:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    80002946:	c539                	beqz	a0,80002994 <allocproc+0xa2>
  memset(&p->context, 0, sizeof(p->context));
    80002948:	07000613          	li	a2,112
    8000294c:	4581                	li	a1,0
    8000294e:	08848513          	addi	a0,s1,136
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	39c080e7          	jalr	924(ra) # 80000cee <memset>
  p->context.ra = (uint64)forkret;
    8000295a:	fffff797          	auipc	a5,0xfffff
    8000295e:	4a478793          	addi	a5,a5,1188 # 80001dfe <forkret>
    80002962:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002964:	74bc                	ld	a5,104(s1)
    80002966:	6705                	lui	a4,0x1
    80002968:	97ba                	add	a5,a5,a4
    8000296a:	e8dc                	sd	a5,144(s1)
}
    8000296c:	8526                	mv	a0,s1
    8000296e:	70a2                	ld	ra,40(sp)
    80002970:	7402                	ld	s0,32(sp)
    80002972:	64e2                	ld	s1,24(sp)
    80002974:	6942                	ld	s2,16(sp)
    80002976:	69a2                	ld	s3,8(sp)
    80002978:	6145                	addi	sp,sp,48
    8000297a:	8082                	ret
    freeproc(p);
    8000297c:	8526                	mv	a0,s1
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	f02080e7          	jalr	-254(ra) # 80002880 <freeproc>
    release(&p->lock);
    80002986:	8526                	mv	a0,s1
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	31e080e7          	jalr	798(ra) # 80000ca6 <release>
    return 0;
    80002990:	84ca                	mv	s1,s2
    80002992:	bfe9                	j	8000296c <allocproc+0x7a>
    freeproc(p);
    80002994:	8526                	mv	a0,s1
    80002996:	00000097          	auipc	ra,0x0
    8000299a:	eea080e7          	jalr	-278(ra) # 80002880 <freeproc>
    release(&p->lock);
    8000299e:	8526                	mv	a0,s1
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	306080e7          	jalr	774(ra) # 80000ca6 <release>
    return 0;
    800029a8:	84ca                	mv	s1,s2
    800029aa:	b7c9                	j	8000296c <allocproc+0x7a>

00000000800029ac <userinit>:
{
    800029ac:	1101                	addi	sp,sp,-32
    800029ae:	ec06                	sd	ra,24(sp)
    800029b0:	e822                	sd	s0,16(sp)
    800029b2:	e426                	sd	s1,8(sp)
    800029b4:	1000                	addi	s0,sp,32
  if(!flag_init){
    800029b6:	00006797          	auipc	a5,0x6
    800029ba:	68a7a783          	lw	a5,1674(a5) # 80009040 <flag_init>
    800029be:	e795                	bnez	a5,800029ea <userinit+0x3e>
      c->first = 0;
    800029c0:	0000f797          	auipc	a5,0xf
    800029c4:	92078793          	addi	a5,a5,-1760 # 800112e0 <readyLock>
    800029c8:	1007bc23          	sd	zero,280(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    800029cc:	0807b823          	sd	zero,144(a5)
      c->first = 0;
    800029d0:	1a07b423          	sd	zero,424(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    800029d4:	1207b023          	sd	zero,288(a5)
      c->first = 0;
    800029d8:	2207bc23          	sd	zero,568(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    800029dc:	1a07b823          	sd	zero,432(a5)
    flag_init = 1;
    800029e0:	4785                	li	a5,1
    800029e2:	00006717          	auipc	a4,0x6
    800029e6:	64f72f23          	sw	a5,1630(a4) # 80009040 <flag_init>
  p = allocproc();
    800029ea:	00000097          	auipc	ra,0x0
    800029ee:	f08080e7          	jalr	-248(ra) # 800028f2 <allocproc>
    800029f2:	84aa                	mv	s1,a0
  initproc = p;
    800029f4:	00006797          	auipc	a5,0x6
    800029f8:	66a7b623          	sd	a0,1644(a5) # 80009060 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800029fc:	03400613          	li	a2,52
    80002a00:	00006597          	auipc	a1,0x6
    80002a04:	fb058593          	addi	a1,a1,-80 # 800089b0 <initcode>
    80002a08:	7d28                	ld	a0,120(a0)
    80002a0a:	fffff097          	auipc	ra,0xfffff
    80002a0e:	96c080e7          	jalr	-1684(ra) # 80001376 <uvminit>
  p->sz = PGSIZE;
    80002a12:	6785                	lui	a5,0x1
    80002a14:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    80002a16:	60d8                	ld	a4,128(s1)
    80002a18:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002a1c:	60d8                	ld	a4,128(s1)
    80002a1e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002a20:	4641                	li	a2,16
    80002a22:	00006597          	auipc	a1,0x6
    80002a26:	9a658593          	addi	a1,a1,-1626 # 800083c8 <digits+0x388>
    80002a2a:	18048513          	addi	a0,s1,384
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	412080e7          	jalr	1042(ra) # 80000e40 <safestrcpy>
  p->cwd = namei("/");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	9a250513          	addi	a0,a0,-1630 # 800083d8 <digits+0x398>
    80002a3e:	00002097          	auipc	ra,0x2
    80002a42:	07e080e7          	jalr	126(ra) # 80004abc <namei>
    80002a46:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    80002a4a:	478d                	li	a5,3
    80002a4c:	d89c                	sw	a5,48(s1)
  p->parent_cpu = 0;
    80002a4e:	0404ac23          	sw	zero,88(s1)
  cahnge_number_of_proc(p->parent_cpu,a);
    80002a52:	4585                	li	a1,1
    80002a54:	4501                	li	a0,0
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	082080e7          	jalr	130(ra) # 80001ad8 <cahnge_number_of_proc>
  cpus[p->parent_cpu].first = p;
    80002a5e:	4cb8                	lw	a4,88(s1)
    80002a60:	00371793          	slli	a5,a4,0x3
    80002a64:	97ba                	add	a5,a5,a4
    80002a66:	0792                	slli	a5,a5,0x4
    80002a68:	0000f717          	auipc	a4,0xf
    80002a6c:	87870713          	addi	a4,a4,-1928 # 800112e0 <readyLock>
    80002a70:	97ba                	add	a5,a5,a4
    80002a72:	1097bc23          	sd	s1,280(a5) # 1118 <_entry-0x7fffeee8>
  release(&p->lock);
    80002a76:	8526                	mv	a0,s1
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	22e080e7          	jalr	558(ra) # 80000ca6 <release>
}
    80002a80:	60e2                	ld	ra,24(sp)
    80002a82:	6442                	ld	s0,16(sp)
    80002a84:	64a2                	ld	s1,8(sp)
    80002a86:	6105                	addi	sp,sp,32
    80002a88:	8082                	ret

0000000080002a8a <fork>:
{
    80002a8a:	7179                	addi	sp,sp,-48
    80002a8c:	f406                	sd	ra,40(sp)
    80002a8e:	f022                	sd	s0,32(sp)
    80002a90:	ec26                	sd	s1,24(sp)
    80002a92:	e84a                	sd	s2,16(sp)
    80002a94:	e44e                	sd	s3,8(sp)
    80002a96:	e052                	sd	s4,0(sp)
    80002a98:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	30a080e7          	jalr	778(ra) # 80001da4 <myproc>
    80002aa2:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002aa4:	00000097          	auipc	ra,0x0
    80002aa8:	e4e080e7          	jalr	-434(ra) # 800028f2 <allocproc>
    80002aac:	12050863          	beqz	a0,80002bdc <fork+0x152>
    80002ab0:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002ab2:	0709b603          	ld	a2,112(s3)
    80002ab6:	7d2c                	ld	a1,120(a0)
    80002ab8:	0789b503          	ld	a0,120(s3)
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	ac0080e7          	jalr	-1344(ra) # 8000157c <uvmcopy>
    80002ac4:	04054663          	bltz	a0,80002b10 <fork+0x86>
  np->sz = p->sz;
    80002ac8:	0709b783          	ld	a5,112(s3)
    80002acc:	06f93823          	sd	a5,112(s2)
  *(np->trapframe) = *(p->trapframe);
    80002ad0:	0809b683          	ld	a3,128(s3)
    80002ad4:	87b6                	mv	a5,a3
    80002ad6:	08093703          	ld	a4,128(s2)
    80002ada:	12068693          	addi	a3,a3,288
    80002ade:	0007b803          	ld	a6,0(a5)
    80002ae2:	6788                	ld	a0,8(a5)
    80002ae4:	6b8c                	ld	a1,16(a5)
    80002ae6:	6f90                	ld	a2,24(a5)
    80002ae8:	01073023          	sd	a6,0(a4)
    80002aec:	e708                	sd	a0,8(a4)
    80002aee:	eb0c                	sd	a1,16(a4)
    80002af0:	ef10                	sd	a2,24(a4)
    80002af2:	02078793          	addi	a5,a5,32
    80002af6:	02070713          	addi	a4,a4,32
    80002afa:	fed792e3          	bne	a5,a3,80002ade <fork+0x54>
  np->trapframe->a0 = 0;
    80002afe:	08093783          	ld	a5,128(s2)
    80002b02:	0607b823          	sd	zero,112(a5)
    80002b06:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80002b0a:	17800a13          	li	s4,376
    80002b0e:	a03d                	j	80002b3c <fork+0xb2>
    freeproc(np);
    80002b10:	854a                	mv	a0,s2
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	d6e080e7          	jalr	-658(ra) # 80002880 <freeproc>
    release(&np->lock);
    80002b1a:	854a                	mv	a0,s2
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	18a080e7          	jalr	394(ra) # 80000ca6 <release>
    return -1;
    80002b24:	5a7d                	li	s4,-1
    80002b26:	a055                	j	80002bca <fork+0x140>
      np->ofile[i] = filedup(p->ofile[i]);
    80002b28:	00002097          	auipc	ra,0x2
    80002b2c:	62a080e7          	jalr	1578(ra) # 80005152 <filedup>
    80002b30:	009907b3          	add	a5,s2,s1
    80002b34:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002b36:	04a1                	addi	s1,s1,8
    80002b38:	01448763          	beq	s1,s4,80002b46 <fork+0xbc>
    if(p->ofile[i])
    80002b3c:	009987b3          	add	a5,s3,s1
    80002b40:	6388                	ld	a0,0(a5)
    80002b42:	f17d                	bnez	a0,80002b28 <fork+0x9e>
    80002b44:	bfcd                	j	80002b36 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002b46:	1789b503          	ld	a0,376(s3)
    80002b4a:	00001097          	auipc	ra,0x1
    80002b4e:	77e080e7          	jalr	1918(ra) # 800042c8 <idup>
    80002b52:	16a93c23          	sd	a0,376(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002b56:	4641                	li	a2,16
    80002b58:	18098593          	addi	a1,s3,384
    80002b5c:	18090513          	addi	a0,s2,384
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	2e0080e7          	jalr	736(ra) # 80000e40 <safestrcpy>
  pid = np->pid;
    80002b68:	04892a03          	lw	s4,72(s2)
  release(&np->lock);
    80002b6c:	854a                	mv	a0,s2
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	138080e7          	jalr	312(ra) # 80000ca6 <release>
  acquire(&wait_lock);
    80002b76:	0000f497          	auipc	s1,0xf
    80002b7a:	a5248493          	addi	s1,s1,-1454 # 800115c8 <wait_lock>
    80002b7e:	8526                	mv	a0,s1
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	06c080e7          	jalr	108(ra) # 80000bec <acquire>
  np->parent = p;
    80002b88:	07393023          	sd	s3,96(s2)
  release(&wait_lock);
    80002b8c:	8526                	mv	a0,s1
    80002b8e:	ffffe097          	auipc	ra,0xffffe
    80002b92:	118080e7          	jalr	280(ra) # 80000ca6 <release>
  acquire(&np->lock);
    80002b96:	854a                	mv	a0,s2
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	054080e7          	jalr	84(ra) # 80000bec <acquire>
  np->state = RUNNABLE;
    80002ba0:	478d                	li	a5,3
    80002ba2:	02f92823          	sw	a5,48(s2)
    int cpu_id = (BLNCFLG) ? pick_cpu() : p->parent_cpu;
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	f24080e7          	jalr	-220(ra) # 80001aca <pick_cpu>
    80002bae:	862a                	mv	a2,a0
  np->parent_cpu = cpu_id;
    80002bb0:	04a92c23          	sw	a0,88(s2)
  add_proc_to_specific_list(np, readyList, cpu_id);
    80002bb4:	4581                	li	a1,0
    80002bb6:	854a                	mv	a0,s2
    80002bb8:	fffff097          	auipc	ra,0xfffff
    80002bbc:	7a2080e7          	jalr	1954(ra) # 8000235a <add_proc_to_specific_list>
  release(&np->lock);
    80002bc0:	854a                	mv	a0,s2
    80002bc2:	ffffe097          	auipc	ra,0xffffe
    80002bc6:	0e4080e7          	jalr	228(ra) # 80000ca6 <release>
}
    80002bca:	8552                	mv	a0,s4
    80002bcc:	70a2                	ld	ra,40(sp)
    80002bce:	7402                	ld	s0,32(sp)
    80002bd0:	64e2                	ld	s1,24(sp)
    80002bd2:	6942                	ld	s2,16(sp)
    80002bd4:	69a2                	ld	s3,8(sp)
    80002bd6:	6a02                	ld	s4,0(sp)
    80002bd8:	6145                	addi	sp,sp,48
    80002bda:	8082                	ret
    return -1;
    80002bdc:	5a7d                	li	s4,-1
    80002bde:	b7f5                	j	80002bca <fork+0x140>

0000000080002be0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002be0:	7179                	addi	sp,sp,-48
    80002be2:	f406                	sd	ra,40(sp)
    80002be4:	f022                	sd	s0,32(sp)
    80002be6:	ec26                	sd	s1,24(sp)
    80002be8:	e84a                	sd	s2,16(sp)
    80002bea:	e44e                	sd	s3,8(sp)
    80002bec:	1800                	addi	s0,sp,48
    80002bee:	89aa                	mv	s3,a0
    80002bf0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	1b2080e7          	jalr	434(ra) # 80001da4 <myproc>
    80002bfa:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	ff0080e7          	jalr	-16(ra) # 80000bec <acquire>
  release(lk);
    80002c04:	854a                	mv	a0,s2
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	0a0080e7          	jalr	160(ra) # 80000ca6 <release>

  // Go to sleep.
  p->chan = chan;
    80002c0e:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    80002c12:	4789                	li	a5,2
    80002c14:	d89c                	sw	a5,48(s1)
  // decrease_size(p->parent_cpu);
  int b=-1;
  cahnge_number_of_proc(p->parent_cpu,b);
    80002c16:	55fd                	li	a1,-1
    80002c18:	4ca8                	lw	a0,88(s1)
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	ebe080e7          	jalr	-322(ra) # 80001ad8 <cahnge_number_of_proc>
  //--------------------------------------------------------------------
    add_proc_to_specific_list(p, sleepLeast,-1);
    80002c22:	567d                	li	a2,-1
    80002c24:	4589                	li	a1,2
    80002c26:	8526                	mv	a0,s1
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	732080e7          	jalr	1842(ra) # 8000235a <add_proc_to_specific_list>
  //--------------------------------------------------------------------

  sched();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	3ae080e7          	jalr	942(ra) # 80001fde <sched>

  // Tidy up.
  p->chan = 0;
    80002c38:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002c3c:	8526                	mv	a0,s1
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	068080e7          	jalr	104(ra) # 80000ca6 <release>
  acquire(lk);
    80002c46:	854a                	mv	a0,s2
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	fa4080e7          	jalr	-92(ra) # 80000bec <acquire>

}
    80002c50:	70a2                	ld	ra,40(sp)
    80002c52:	7402                	ld	s0,32(sp)
    80002c54:	64e2                	ld	s1,24(sp)
    80002c56:	6942                	ld	s2,16(sp)
    80002c58:	69a2                	ld	s3,8(sp)
    80002c5a:	6145                	addi	sp,sp,48
    80002c5c:	8082                	ret

0000000080002c5e <wait>:
{
    80002c5e:	715d                	addi	sp,sp,-80
    80002c60:	e486                	sd	ra,72(sp)
    80002c62:	e0a2                	sd	s0,64(sp)
    80002c64:	fc26                	sd	s1,56(sp)
    80002c66:	f84a                	sd	s2,48(sp)
    80002c68:	f44e                	sd	s3,40(sp)
    80002c6a:	f052                	sd	s4,32(sp)
    80002c6c:	ec56                	sd	s5,24(sp)
    80002c6e:	e85a                	sd	s6,16(sp)
    80002c70:	e45e                	sd	s7,8(sp)
    80002c72:	e062                	sd	s8,0(sp)
    80002c74:	0880                	addi	s0,sp,80
    80002c76:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	12c080e7          	jalr	300(ra) # 80001da4 <myproc>
    80002c80:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002c82:	0000f517          	auipc	a0,0xf
    80002c86:	94650513          	addi	a0,a0,-1722 # 800115c8 <wait_lock>
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	f62080e7          	jalr	-158(ra) # 80000bec <acquire>
    havekids = 0;
    80002c92:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002c94:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002c96:	00015997          	auipc	s3,0x15
    80002c9a:	d4a98993          	addi	s3,s3,-694 # 800179e0 <tickslock>
        havekids = 1;
    80002c9e:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002ca0:	0000fc17          	auipc	s8,0xf
    80002ca4:	928c0c13          	addi	s8,s8,-1752 # 800115c8 <wait_lock>
    havekids = 0;
    80002ca8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002caa:	0000f497          	auipc	s1,0xf
    80002cae:	93648493          	addi	s1,s1,-1738 # 800115e0 <proc>
    80002cb2:	a0bd                	j	80002d20 <wait+0xc2>
          pid = np->pid;
    80002cb4:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002cb8:	000b0e63          	beqz	s6,80002cd4 <wait+0x76>
    80002cbc:	4691                	li	a3,4
    80002cbe:	04448613          	addi	a2,s1,68
    80002cc2:	85da                	mv	a1,s6
    80002cc4:	07893503          	ld	a0,120(s2)
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	9b8080e7          	jalr	-1608(ra) # 80001680 <copyout>
    80002cd0:	02054563          	bltz	a0,80002cfa <wait+0x9c>
          freeproc(np);
    80002cd4:	8526                	mv	a0,s1
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	baa080e7          	jalr	-1110(ra) # 80002880 <freeproc>
          release(&np->lock);
    80002cde:	8526                	mv	a0,s1
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	fc6080e7          	jalr	-58(ra) # 80000ca6 <release>
          release(&wait_lock);
    80002ce8:	0000f517          	auipc	a0,0xf
    80002cec:	8e050513          	addi	a0,a0,-1824 # 800115c8 <wait_lock>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	fb6080e7          	jalr	-74(ra) # 80000ca6 <release>
          return pid;
    80002cf8:	a09d                	j	80002d5e <wait+0x100>
            release(&np->lock);
    80002cfa:	8526                	mv	a0,s1
    80002cfc:	ffffe097          	auipc	ra,0xffffe
    80002d00:	faa080e7          	jalr	-86(ra) # 80000ca6 <release>
            release(&wait_lock);
    80002d04:	0000f517          	auipc	a0,0xf
    80002d08:	8c450513          	addi	a0,a0,-1852 # 800115c8 <wait_lock>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	f9a080e7          	jalr	-102(ra) # 80000ca6 <release>
            return -1;
    80002d14:	59fd                	li	s3,-1
    80002d16:	a0a1                	j	80002d5e <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002d18:	19048493          	addi	s1,s1,400
    80002d1c:	03348463          	beq	s1,s3,80002d44 <wait+0xe6>
      if(np->parent == p){
    80002d20:	70bc                	ld	a5,96(s1)
    80002d22:	ff279be3          	bne	a5,s2,80002d18 <wait+0xba>
        acquire(&np->lock);
    80002d26:	8526                	mv	a0,s1
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	ec4080e7          	jalr	-316(ra) # 80000bec <acquire>
        if(np->state == ZOMBIE){
    80002d30:	589c                	lw	a5,48(s1)
    80002d32:	f94781e3          	beq	a5,s4,80002cb4 <wait+0x56>
        release(&np->lock);
    80002d36:	8526                	mv	a0,s1
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	f6e080e7          	jalr	-146(ra) # 80000ca6 <release>
        havekids = 1;
    80002d40:	8756                	mv	a4,s5
    80002d42:	bfd9                	j	80002d18 <wait+0xba>
    if(!havekids || p->killed){
    80002d44:	c701                	beqz	a4,80002d4c <wait+0xee>
    80002d46:	04092783          	lw	a5,64(s2)
    80002d4a:	c79d                	beqz	a5,80002d78 <wait+0x11a>
      release(&wait_lock);
    80002d4c:	0000f517          	auipc	a0,0xf
    80002d50:	87c50513          	addi	a0,a0,-1924 # 800115c8 <wait_lock>
    80002d54:	ffffe097          	auipc	ra,0xffffe
    80002d58:	f52080e7          	jalr	-174(ra) # 80000ca6 <release>
      return -1;
    80002d5c:	59fd                	li	s3,-1
}
    80002d5e:	854e                	mv	a0,s3
    80002d60:	60a6                	ld	ra,72(sp)
    80002d62:	6406                	ld	s0,64(sp)
    80002d64:	74e2                	ld	s1,56(sp)
    80002d66:	7942                	ld	s2,48(sp)
    80002d68:	79a2                	ld	s3,40(sp)
    80002d6a:	7a02                	ld	s4,32(sp)
    80002d6c:	6ae2                	ld	s5,24(sp)
    80002d6e:	6b42                	ld	s6,16(sp)
    80002d70:	6ba2                	ld	s7,8(sp)
    80002d72:	6c02                	ld	s8,0(sp)
    80002d74:	6161                	addi	sp,sp,80
    80002d76:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002d78:	85e2                	mv	a1,s8
    80002d7a:	854a                	mv	a0,s2
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	e64080e7          	jalr	-412(ra) # 80002be0 <sleep>
    havekids = 0;
    80002d84:	b715                	j	80002ca8 <wait+0x4a>

0000000080002d86 <wakeup>:
// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
//--------------------------------------------------------------------
void
wakeup(void *chan)
{
    80002d86:	711d                	addi	sp,sp,-96
    80002d88:	ec86                	sd	ra,88(sp)
    80002d8a:	e8a2                	sd	s0,80(sp)
    80002d8c:	e4a6                	sd	s1,72(sp)
    80002d8e:	e0ca                	sd	s2,64(sp)
    80002d90:	fc4e                	sd	s3,56(sp)
    80002d92:	f852                	sd	s4,48(sp)
    80002d94:	f456                	sd	s5,40(sp)
    80002d96:	f05a                	sd	s6,32(sp)
    80002d98:	ec5e                	sd	s7,24(sp)
    80002d9a:	e862                	sd	s8,16(sp)
    80002d9c:	e466                	sd	s9,8(sp)
    80002d9e:	e06a                	sd	s10,0(sp)
    80002da0:	1080                	addi	s0,sp,96
    80002da2:	8aaa                	mv	s5,a0
  int released_list = 0;
  struct proc *p;
  struct proc* prev = 0;
  struct proc* tmp;
  getList(sleepLeast, -1);
    80002da4:	55fd                	li	a1,-1
    80002da6:	4509                	li	a0,2
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	3ca080e7          	jalr	970(ra) # 80002172 <getList>
  p = getFirst(sleepLeast, -1);
    80002db0:	55fd                	li	a1,-1
    80002db2:	4509                	li	a0,2
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	d74080e7          	jalr	-652(ra) # 80001b28 <getFirst>
    80002dbc:	84aa                	mv	s1,a0
  while(p){
    80002dbe:	14050663          	beqz	a0,80002f0a <wakeup+0x184>
  struct proc* prev = 0;
    80002dc2:	4a01                	li	s4,0
  int released_list = 0;
    80002dc4:	4c01                	li	s8,0
    } 
    else{
      //we are not on the chan
      if(p == getFirst(sleepLeast, -1)){
        release_list(sleepLeast,-1);
        released_list = 1;
    80002dc6:	4b85                	li	s7,1
        p->state = RUNNABLE;
    80002dc8:	4c8d                	li	s9,3
    80002dca:	a8c9                	j	80002e9c <wakeup+0x116>
      if(p == getFirst(sleepLeast, -1)){
    80002dcc:	55fd                	li	a1,-1
    80002dce:	4509                	li	a0,2
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	d58080e7          	jalr	-680(ra) # 80001b28 <getFirst>
    80002dd8:	04a48863          	beq	s1,a0,80002e28 <wakeup+0xa2>
        prev->next = p->next;
    80002ddc:	68bc                	ld	a5,80(s1)
    80002dde:	04fa3823          	sd	a5,80(s4)
        p->next = 0;
    80002de2:	0404b823          	sd	zero,80(s1)
        p->state = RUNNABLE;
    80002de6:	0394a823          	sw	s9,48(s1)
        int cpu_id = (BLNCFLG) ? pick_cpu() : p->parent_cpu;
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	ce0080e7          	jalr	-800(ra) # 80001aca <pick_cpu>
    80002df2:	8b2a                	mv	s6,a0
        p->parent_cpu = cpu_id;
    80002df4:	cca8                	sw	a0,88(s1)
        cahnge_number_of_proc(cpu_id,a);
    80002df6:	85de                	mv	a1,s7
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	ce0080e7          	jalr	-800(ra) # 80001ad8 <cahnge_number_of_proc>
        add_proc_to_specific_list(p, readyList, cpu_id);
    80002e00:	865a                	mv	a2,s6
    80002e02:	4581                	li	a1,0
    80002e04:	8526                	mv	a0,s1
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	554080e7          	jalr	1364(ra) # 8000235a <add_proc_to_specific_list>
        release(&p->list_lock);
    80002e0e:	854a                	mv	a0,s2
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	e96080e7          	jalr	-362(ra) # 80000ca6 <release>
        release(&p->lock);
    80002e18:	8526                	mv	a0,s1
    80002e1a:	ffffe097          	auipc	ra,0xffffe
    80002e1e:	e8c080e7          	jalr	-372(ra) # 80000ca6 <release>
        p = prev->next;
    80002e22:	050a3483          	ld	s1,80(s4)
    80002e26:	a895                	j	80002e9a <wakeup+0x114>
        setFirst(p->next, sleepLeast, -1);
    80002e28:	567d                	li	a2,-1
    80002e2a:	4589                	li	a1,2
    80002e2c:	68a8                	ld	a0,80(s1)
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	444080e7          	jalr	1092(ra) # 80002272 <setFirst>
        p = p->next;
    80002e36:	0504bd03          	ld	s10,80(s1)
        tmp->next = 0;
    80002e3a:	0404b823          	sd	zero,80(s1)
        tmp->state = RUNNABLE;
    80002e3e:	0394a823          	sw	s9,48(s1)
        int cpu_id = (BLNCFLG) ? pick_cpu() : tmp->parent_cpu;
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	c88080e7          	jalr	-888(ra) # 80001aca <pick_cpu>
    80002e4a:	8b2a                	mv	s6,a0
        tmp->parent_cpu = cpu_id;
    80002e4c:	cca8                	sw	a0,88(s1)
        cahnge_number_of_proc(cpu_id,a);
    80002e4e:	85de                	mv	a1,s7
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	c88080e7          	jalr	-888(ra) # 80001ad8 <cahnge_number_of_proc>
        add_proc_to_specific_list(tmp, readyList, cpu_id);
    80002e58:	865a                	mv	a2,s6
    80002e5a:	4581                	li	a1,0
    80002e5c:	8526                	mv	a0,s1
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	4fc080e7          	jalr	1276(ra) # 8000235a <add_proc_to_specific_list>
        release(&tmp->list_lock);
    80002e66:	854a                	mv	a0,s2
    80002e68:	ffffe097          	auipc	ra,0xffffe
    80002e6c:	e3e080e7          	jalr	-450(ra) # 80000ca6 <release>
        release(&tmp->lock);
    80002e70:	8526                	mv	a0,s1
    80002e72:	ffffe097          	auipc	ra,0xffffe
    80002e76:	e34080e7          	jalr	-460(ra) # 80000ca6 <release>
        p = p->next;
    80002e7a:	84ea                	mv	s1,s10
    80002e7c:	a839                	j	80002e9a <wakeup+0x114>
        release_list(sleepLeast,-1);
    80002e7e:	55fd                	li	a1,-1
    80002e80:	4509                	li	a0,2
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	dd4080e7          	jalr	-556(ra) # 80001c56 <release_list>
        released_list = 1;
    80002e8a:	8c5e                	mv	s8,s7
      }
      else{
        release(&prev->list_lock);
      }
      release(&p->lock);  //because we dont need to change his fields
    80002e8c:	854e                	mv	a0,s3
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	e18080e7          	jalr	-488(ra) # 80000ca6 <release>
      prev = p;
      p = p->next;
    80002e96:	8a26                	mv	s4,s1
    80002e98:	68a4                	ld	s1,80(s1)
  while(p){
    80002e9a:	c0a1                	beqz	s1,80002eda <wakeup+0x154>
    acquire(&p->lock);
    80002e9c:	89a6                	mv	s3,s1
    80002e9e:	8526                	mv	a0,s1
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	d4c080e7          	jalr	-692(ra) # 80000bec <acquire>
    acquire(&p->list_lock);
    80002ea8:	01848913          	addi	s2,s1,24
    80002eac:	854a                	mv	a0,s2
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	d3e080e7          	jalr	-706(ra) # 80000bec <acquire>
    if(p->chan == chan){
    80002eb6:	7c9c                	ld	a5,56(s1)
    80002eb8:	f1578ae3          	beq	a5,s5,80002dcc <wakeup+0x46>
      if(p == getFirst(sleepLeast, -1)){
    80002ebc:	55fd                	li	a1,-1
    80002ebe:	4509                	li	a0,2
    80002ec0:	fffff097          	auipc	ra,0xfffff
    80002ec4:	c68080e7          	jalr	-920(ra) # 80001b28 <getFirst>
    80002ec8:	faa48be3          	beq	s1,a0,80002e7e <wakeup+0xf8>
        release(&prev->list_lock);
    80002ecc:	018a0513          	addi	a0,s4,24
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	dd6080e7          	jalr	-554(ra) # 80000ca6 <release>
    80002ed8:	bf55                	j	80002e8c <wakeup+0x106>
    }
  }
  if(!released_list){
    80002eda:	020c0963          	beqz	s8,80002f0c <wakeup+0x186>
    release_list(sleepLeast, -1);
  }
  if(prev){
    80002ede:	000a0863          	beqz	s4,80002eee <wakeup+0x168>
    release(&prev->list_lock);
    80002ee2:	018a0513          	addi	a0,s4,24
    80002ee6:	ffffe097          	auipc	ra,0xffffe
    80002eea:	dc0080e7          	jalr	-576(ra) # 80000ca6 <release>
  }
}
    80002eee:	60e6                	ld	ra,88(sp)
    80002ef0:	6446                	ld	s0,80(sp)
    80002ef2:	64a6                	ld	s1,72(sp)
    80002ef4:	6906                	ld	s2,64(sp)
    80002ef6:	79e2                	ld	s3,56(sp)
    80002ef8:	7a42                	ld	s4,48(sp)
    80002efa:	7aa2                	ld	s5,40(sp)
    80002efc:	7b02                	ld	s6,32(sp)
    80002efe:	6be2                	ld	s7,24(sp)
    80002f00:	6c42                	ld	s8,16(sp)
    80002f02:	6ca2                	ld	s9,8(sp)
    80002f04:	6d02                	ld	s10,0(sp)
    80002f06:	6125                	addi	sp,sp,96
    80002f08:	8082                	ret
  struct proc* prev = 0;
    80002f0a:	8a2a                	mv	s4,a0
    release_list(sleepLeast, -1);
    80002f0c:	55fd                	li	a1,-1
    80002f0e:	4509                	li	a0,2
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	d46080e7          	jalr	-698(ra) # 80001c56 <release_list>
    80002f18:	b7d9                	j	80002ede <wakeup+0x158>

0000000080002f1a <reparent>:
{
    80002f1a:	7179                	addi	sp,sp,-48
    80002f1c:	f406                	sd	ra,40(sp)
    80002f1e:	f022                	sd	s0,32(sp)
    80002f20:	ec26                	sd	s1,24(sp)
    80002f22:	e84a                	sd	s2,16(sp)
    80002f24:	e44e                	sd	s3,8(sp)
    80002f26:	e052                	sd	s4,0(sp)
    80002f28:	1800                	addi	s0,sp,48
    80002f2a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002f2c:	0000e497          	auipc	s1,0xe
    80002f30:	6b448493          	addi	s1,s1,1716 # 800115e0 <proc>
      pp->parent = initproc;
    80002f34:	00006a17          	auipc	s4,0x6
    80002f38:	12ca0a13          	addi	s4,s4,300 # 80009060 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002f3c:	00015997          	auipc	s3,0x15
    80002f40:	aa498993          	addi	s3,s3,-1372 # 800179e0 <tickslock>
    80002f44:	a029                	j	80002f4e <reparent+0x34>
    80002f46:	19048493          	addi	s1,s1,400
    80002f4a:	01348d63          	beq	s1,s3,80002f64 <reparent+0x4a>
    if(pp->parent == p){
    80002f4e:	70bc                	ld	a5,96(s1)
    80002f50:	ff279be3          	bne	a5,s2,80002f46 <reparent+0x2c>
      pp->parent = initproc;
    80002f54:	000a3503          	ld	a0,0(s4)
    80002f58:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	e2c080e7          	jalr	-468(ra) # 80002d86 <wakeup>
    80002f62:	b7d5                	j	80002f46 <reparent+0x2c>
}
    80002f64:	70a2                	ld	ra,40(sp)
    80002f66:	7402                	ld	s0,32(sp)
    80002f68:	64e2                	ld	s1,24(sp)
    80002f6a:	6942                	ld	s2,16(sp)
    80002f6c:	69a2                	ld	s3,8(sp)
    80002f6e:	6a02                	ld	s4,0(sp)
    80002f70:	6145                	addi	sp,sp,48
    80002f72:	8082                	ret

0000000080002f74 <exit>:
{
    80002f74:	7179                	addi	sp,sp,-48
    80002f76:	f406                	sd	ra,40(sp)
    80002f78:	f022                	sd	s0,32(sp)
    80002f7a:	ec26                	sd	s1,24(sp)
    80002f7c:	e84a                	sd	s2,16(sp)
    80002f7e:	e44e                	sd	s3,8(sp)
    80002f80:	e052                	sd	s4,0(sp)
    80002f82:	1800                	addi	s0,sp,48
    80002f84:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	e1e080e7          	jalr	-482(ra) # 80001da4 <myproc>
    80002f8e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002f90:	00006797          	auipc	a5,0x6
    80002f94:	0d07b783          	ld	a5,208(a5) # 80009060 <initproc>
    80002f98:	0f850493          	addi	s1,a0,248
    80002f9c:	17850913          	addi	s2,a0,376
    80002fa0:	02a79363          	bne	a5,a0,80002fc6 <exit+0x52>
    panic("init exiting");
    80002fa4:	00005517          	auipc	a0,0x5
    80002fa8:	43c50513          	addi	a0,a0,1084 # 800083e0 <digits+0x3a0>
    80002fac:	ffffd097          	auipc	ra,0xffffd
    80002fb0:	592080e7          	jalr	1426(ra) # 8000053e <panic>
      fileclose(f);
    80002fb4:	00002097          	auipc	ra,0x2
    80002fb8:	1f0080e7          	jalr	496(ra) # 800051a4 <fileclose>
      p->ofile[fd] = 0;
    80002fbc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002fc0:	04a1                	addi	s1,s1,8
    80002fc2:	01248563          	beq	s1,s2,80002fcc <exit+0x58>
    if(p->ofile[fd]){
    80002fc6:	6088                	ld	a0,0(s1)
    80002fc8:	f575                	bnez	a0,80002fb4 <exit+0x40>
    80002fca:	bfdd                	j	80002fc0 <exit+0x4c>
  begin_op();
    80002fcc:	00002097          	auipc	ra,0x2
    80002fd0:	d0c080e7          	jalr	-756(ra) # 80004cd8 <begin_op>
  iput(p->cwd);
    80002fd4:	1789b503          	ld	a0,376(s3)
    80002fd8:	00001097          	auipc	ra,0x1
    80002fdc:	4e8080e7          	jalr	1256(ra) # 800044c0 <iput>
  end_op();
    80002fe0:	00002097          	auipc	ra,0x2
    80002fe4:	d78080e7          	jalr	-648(ra) # 80004d58 <end_op>
  p->cwd = 0;
    80002fe8:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    80002fec:	0000e497          	auipc	s1,0xe
    80002ff0:	5dc48493          	addi	s1,s1,1500 # 800115c8 <wait_lock>
    80002ff4:	8526                	mv	a0,s1
    80002ff6:	ffffe097          	auipc	ra,0xffffe
    80002ffa:	bf6080e7          	jalr	-1034(ra) # 80000bec <acquire>
  reparent(p);
    80002ffe:	854e                	mv	a0,s3
    80003000:	00000097          	auipc	ra,0x0
    80003004:	f1a080e7          	jalr	-230(ra) # 80002f1a <reparent>
  wakeup(p->parent);
    80003008:	0609b503          	ld	a0,96(s3)
    8000300c:	00000097          	auipc	ra,0x0
    80003010:	d7a080e7          	jalr	-646(ra) # 80002d86 <wakeup>
  acquire(&p->lock);
    80003014:	854e                	mv	a0,s3
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	bd6080e7          	jalr	-1066(ra) # 80000bec <acquire>
  p->xstate = status;
    8000301e:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    80003022:	4795                	li	a5,5
    80003024:	02f9a823          	sw	a5,48(s3)
  cahnge_number_of_proc(p->parent_cpu,b);
    80003028:	55fd                	li	a1,-1
    8000302a:	0589a503          	lw	a0,88(s3)
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	aaa080e7          	jalr	-1366(ra) # 80001ad8 <cahnge_number_of_proc>
  add_proc_to_specific_list(p, zombeList, -1);
    80003036:	567d                	li	a2,-1
    80003038:	4585                	li	a1,1
    8000303a:	854e                	mv	a0,s3
    8000303c:	fffff097          	auipc	ra,0xfffff
    80003040:	31e080e7          	jalr	798(ra) # 8000235a <add_proc_to_specific_list>
  release(&wait_lock);
    80003044:	8526                	mv	a0,s1
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	c60080e7          	jalr	-928(ra) # 80000ca6 <release>
  sched();
    8000304e:	fffff097          	auipc	ra,0xfffff
    80003052:	f90080e7          	jalr	-112(ra) # 80001fde <sched>
  panic("zombie exit");
    80003056:	00005517          	auipc	a0,0x5
    8000305a:	39a50513          	addi	a0,a0,922 # 800083f0 <digits+0x3b0>
    8000305e:	ffffd097          	auipc	ra,0xffffd
    80003062:	4e0080e7          	jalr	1248(ra) # 8000053e <panic>

0000000080003066 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80003066:	7179                	addi	sp,sp,-48
    80003068:	f406                	sd	ra,40(sp)
    8000306a:	f022                	sd	s0,32(sp)
    8000306c:	ec26                	sd	s1,24(sp)
    8000306e:	e84a                	sd	s2,16(sp)
    80003070:	e44e                	sd	s3,8(sp)
    80003072:	1800                	addi	s0,sp,48
    80003074:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80003076:	0000e497          	auipc	s1,0xe
    8000307a:	56a48493          	addi	s1,s1,1386 # 800115e0 <proc>
    8000307e:	00015997          	auipc	s3,0x15
    80003082:	96298993          	addi	s3,s3,-1694 # 800179e0 <tickslock>
    acquire(&p->lock);
    80003086:	8526                	mv	a0,s1
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	b64080e7          	jalr	-1180(ra) # 80000bec <acquire>
    if(p->pid == pid){
    80003090:	44bc                	lw	a5,72(s1)
    80003092:	01278d63          	beq	a5,s2,800030ac <kill+0x46>
        cahnge_number_of_proc(p->parent_cpu,a);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80003096:	8526                	mv	a0,s1
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	c0e080e7          	jalr	-1010(ra) # 80000ca6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800030a0:	19048493          	addi	s1,s1,400
    800030a4:	ff3491e3          	bne	s1,s3,80003086 <kill+0x20>
  }
  return -1;
    800030a8:	557d                	li	a0,-1
    800030aa:	a829                	j	800030c4 <kill+0x5e>
      p->killed = 1;
    800030ac:	4785                	li	a5,1
    800030ae:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    800030b0:	5898                	lw	a4,48(s1)
    800030b2:	4789                	li	a5,2
    800030b4:	00f70f63          	beq	a4,a5,800030d2 <kill+0x6c>
      release(&p->lock);
    800030b8:	8526                	mv	a0,s1
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	bec080e7          	jalr	-1044(ra) # 80000ca6 <release>
      return 0;
    800030c2:	4501                	li	a0,0
}
    800030c4:	70a2                	ld	ra,40(sp)
    800030c6:	7402                	ld	s0,32(sp)
    800030c8:	64e2                	ld	s1,24(sp)
    800030ca:	6942                	ld	s2,16(sp)
    800030cc:	69a2                	ld	s3,8(sp)
    800030ce:	6145                	addi	sp,sp,48
    800030d0:	8082                	ret
        p->state = RUNNABLE;
    800030d2:	478d                	li	a5,3
    800030d4:	d89c                	sw	a5,48(s1)
        remove_proc(p, sleepLeast);
    800030d6:	4589                	li	a1,2
    800030d8:	8526                	mv	a0,s1
    800030da:	fffff097          	auipc	ra,0xfffff
    800030de:	6a8080e7          	jalr	1704(ra) # 80002782 <remove_proc>
        add_proc_to_specific_list(p, readyList, p->parent_cpu);
    800030e2:	4cb0                	lw	a2,88(s1)
    800030e4:	4581                	li	a1,0
    800030e6:	8526                	mv	a0,s1
    800030e8:	fffff097          	auipc	ra,0xfffff
    800030ec:	272080e7          	jalr	626(ra) # 8000235a <add_proc_to_specific_list>
        cahnge_number_of_proc(p->parent_cpu,a);
    800030f0:	4585                	li	a1,1
    800030f2:	4ca8                	lw	a0,88(s1)
    800030f4:	fffff097          	auipc	ra,0xfffff
    800030f8:	9e4080e7          	jalr	-1564(ra) # 80001ad8 <cahnge_number_of_proc>
    800030fc:	bf75                	j	800030b8 <kill+0x52>

00000000800030fe <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800030fe:	7179                	addi	sp,sp,-48
    80003100:	f406                	sd	ra,40(sp)
    80003102:	f022                	sd	s0,32(sp)
    80003104:	ec26                	sd	s1,24(sp)
    80003106:	e84a                	sd	s2,16(sp)
    80003108:	e44e                	sd	s3,8(sp)
    8000310a:	e052                	sd	s4,0(sp)
    8000310c:	1800                	addi	s0,sp,48
    8000310e:	84aa                	mv	s1,a0
    80003110:	892e                	mv	s2,a1
    80003112:	89b2                	mv	s3,a2
    80003114:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003116:	fffff097          	auipc	ra,0xfffff
    8000311a:	c8e080e7          	jalr	-882(ra) # 80001da4 <myproc>
  if(user_dst){
    8000311e:	c08d                	beqz	s1,80003140 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80003120:	86d2                	mv	a3,s4
    80003122:	864e                	mv	a2,s3
    80003124:	85ca                	mv	a1,s2
    80003126:	7d28                	ld	a0,120(a0)
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	558080e7          	jalr	1368(ra) # 80001680 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80003130:	70a2                	ld	ra,40(sp)
    80003132:	7402                	ld	s0,32(sp)
    80003134:	64e2                	ld	s1,24(sp)
    80003136:	6942                	ld	s2,16(sp)
    80003138:	69a2                	ld	s3,8(sp)
    8000313a:	6a02                	ld	s4,0(sp)
    8000313c:	6145                	addi	sp,sp,48
    8000313e:	8082                	ret
    memmove((char *)dst, src, len);
    80003140:	000a061b          	sext.w	a2,s4
    80003144:	85ce                	mv	a1,s3
    80003146:	854a                	mv	a0,s2
    80003148:	ffffe097          	auipc	ra,0xffffe
    8000314c:	c06080e7          	jalr	-1018(ra) # 80000d4e <memmove>
    return 0;
    80003150:	8526                	mv	a0,s1
    80003152:	bff9                	j	80003130 <either_copyout+0x32>

0000000080003154 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80003154:	7179                	addi	sp,sp,-48
    80003156:	f406                	sd	ra,40(sp)
    80003158:	f022                	sd	s0,32(sp)
    8000315a:	ec26                	sd	s1,24(sp)
    8000315c:	e84a                	sd	s2,16(sp)
    8000315e:	e44e                	sd	s3,8(sp)
    80003160:	e052                	sd	s4,0(sp)
    80003162:	1800                	addi	s0,sp,48
    80003164:	892a                	mv	s2,a0
    80003166:	84ae                	mv	s1,a1
    80003168:	89b2                	mv	s3,a2
    8000316a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	c38080e7          	jalr	-968(ra) # 80001da4 <myproc>
  if(user_src){
    80003174:	c08d                	beqz	s1,80003196 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80003176:	86d2                	mv	a3,s4
    80003178:	864e                	mv	a2,s3
    8000317a:	85ca                	mv	a1,s2
    8000317c:	7d28                	ld	a0,120(a0)
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	58e080e7          	jalr	1422(ra) # 8000170c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80003186:	70a2                	ld	ra,40(sp)
    80003188:	7402                	ld	s0,32(sp)
    8000318a:	64e2                	ld	s1,24(sp)
    8000318c:	6942                	ld	s2,16(sp)
    8000318e:	69a2                	ld	s3,8(sp)
    80003190:	6a02                	ld	s4,0(sp)
    80003192:	6145                	addi	sp,sp,48
    80003194:	8082                	ret
    memmove(dst, (char*)src, len);
    80003196:	000a061b          	sext.w	a2,s4
    8000319a:	85ce                	mv	a1,s3
    8000319c:	854a                	mv	a0,s2
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	bb0080e7          	jalr	-1104(ra) # 80000d4e <memmove>
    return 0;
    800031a6:	8526                	mv	a0,s1
    800031a8:	bff9                	j	80003186 <either_copyin+0x32>

00000000800031aa <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800031aa:	715d                	addi	sp,sp,-80
    800031ac:	e486                	sd	ra,72(sp)
    800031ae:	e0a2                	sd	s0,64(sp)
    800031b0:	fc26                	sd	s1,56(sp)
    800031b2:	f84a                	sd	s2,48(sp)
    800031b4:	f44e                	sd	s3,40(sp)
    800031b6:	f052                	sd	s4,32(sp)
    800031b8:	ec56                	sd	s5,24(sp)
    800031ba:	e85a                	sd	s6,16(sp)
    800031bc:	e45e                	sd	s7,8(sp)
    800031be:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800031c0:	00005517          	auipc	a0,0x5
    800031c4:	f0850513          	addi	a0,a0,-248 # 800080c8 <digits+0x88>
    800031c8:	ffffd097          	auipc	ra,0xffffd
    800031cc:	3c0080e7          	jalr	960(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800031d0:	0000e497          	auipc	s1,0xe
    800031d4:	59048493          	addi	s1,s1,1424 # 80011760 <proc+0x180>
    800031d8:	00015917          	auipc	s2,0x15
    800031dc:	98890913          	addi	s2,s2,-1656 # 80017b60 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800031e0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800031e2:	00005997          	auipc	s3,0x5
    800031e6:	21e98993          	addi	s3,s3,542 # 80008400 <digits+0x3c0>
    printf("%d %s %s", p->pid, state, p->name);
    800031ea:	00005a97          	auipc	s5,0x5
    800031ee:	21ea8a93          	addi	s5,s5,542 # 80008408 <digits+0x3c8>
    printf("\n");
    800031f2:	00005a17          	auipc	s4,0x5
    800031f6:	ed6a0a13          	addi	s4,s4,-298 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800031fa:	00005b97          	auipc	s7,0x5
    800031fe:	246b8b93          	addi	s7,s7,582 # 80008440 <states.1890>
    80003202:	a00d                	j	80003224 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80003204:	ec86a583          	lw	a1,-312(a3)
    80003208:	8556                	mv	a0,s5
    8000320a:	ffffd097          	auipc	ra,0xffffd
    8000320e:	37e080e7          	jalr	894(ra) # 80000588 <printf>
    printf("\n");
    80003212:	8552                	mv	a0,s4
    80003214:	ffffd097          	auipc	ra,0xffffd
    80003218:	374080e7          	jalr	884(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000321c:	19048493          	addi	s1,s1,400
    80003220:	03248163          	beq	s1,s2,80003242 <procdump+0x98>
    if(p->state == UNUSED)
    80003224:	86a6                	mv	a3,s1
    80003226:	eb04a783          	lw	a5,-336(s1)
    8000322a:	dbed                	beqz	a5,8000321c <procdump+0x72>
      state = "???";
    8000322c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000322e:	fcfb6be3          	bltu	s6,a5,80003204 <procdump+0x5a>
    80003232:	1782                	slli	a5,a5,0x20
    80003234:	9381                	srli	a5,a5,0x20
    80003236:	078e                	slli	a5,a5,0x3
    80003238:	97de                	add	a5,a5,s7
    8000323a:	6390                	ld	a2,0(a5)
    8000323c:	f661                	bnez	a2,80003204 <procdump+0x5a>
      state = "???";
    8000323e:	864e                	mv	a2,s3
    80003240:	b7d1                	j	80003204 <procdump+0x5a>
  }
}
    80003242:	60a6                	ld	ra,72(sp)
    80003244:	6406                	ld	s0,64(sp)
    80003246:	74e2                	ld	s1,56(sp)
    80003248:	7942                	ld	s2,48(sp)
    8000324a:	79a2                	ld	s3,40(sp)
    8000324c:	7a02                	ld	s4,32(sp)
    8000324e:	6ae2                	ld	s5,24(sp)
    80003250:	6b42                	ld	s6,16(sp)
    80003252:	6ba2                	ld	s7,8(sp)
    80003254:	6161                	addi	sp,sp,80
    80003256:	8082                	ret

0000000080003258 <swtch>:
    80003258:	00153023          	sd	ra,0(a0)
    8000325c:	00253423          	sd	sp,8(a0)
    80003260:	e900                	sd	s0,16(a0)
    80003262:	ed04                	sd	s1,24(a0)
    80003264:	03253023          	sd	s2,32(a0)
    80003268:	03353423          	sd	s3,40(a0)
    8000326c:	03453823          	sd	s4,48(a0)
    80003270:	03553c23          	sd	s5,56(a0)
    80003274:	05653023          	sd	s6,64(a0)
    80003278:	05753423          	sd	s7,72(a0)
    8000327c:	05853823          	sd	s8,80(a0)
    80003280:	05953c23          	sd	s9,88(a0)
    80003284:	07a53023          	sd	s10,96(a0)
    80003288:	07b53423          	sd	s11,104(a0)
    8000328c:	0005b083          	ld	ra,0(a1)
    80003290:	0085b103          	ld	sp,8(a1)
    80003294:	6980                	ld	s0,16(a1)
    80003296:	6d84                	ld	s1,24(a1)
    80003298:	0205b903          	ld	s2,32(a1)
    8000329c:	0285b983          	ld	s3,40(a1)
    800032a0:	0305ba03          	ld	s4,48(a1)
    800032a4:	0385ba83          	ld	s5,56(a1)
    800032a8:	0405bb03          	ld	s6,64(a1)
    800032ac:	0485bb83          	ld	s7,72(a1)
    800032b0:	0505bc03          	ld	s8,80(a1)
    800032b4:	0585bc83          	ld	s9,88(a1)
    800032b8:	0605bd03          	ld	s10,96(a1)
    800032bc:	0685bd83          	ld	s11,104(a1)
    800032c0:	8082                	ret

00000000800032c2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800032c2:	1141                	addi	sp,sp,-16
    800032c4:	e406                	sd	ra,8(sp)
    800032c6:	e022                	sd	s0,0(sp)
    800032c8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800032ca:	00005597          	auipc	a1,0x5
    800032ce:	1a658593          	addi	a1,a1,422 # 80008470 <states.1890+0x30>
    800032d2:	00014517          	auipc	a0,0x14
    800032d6:	70e50513          	addi	a0,a0,1806 # 800179e0 <tickslock>
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	87a080e7          	jalr	-1926(ra) # 80000b54 <initlock>
}
    800032e2:	60a2                	ld	ra,8(sp)
    800032e4:	6402                	ld	s0,0(sp)
    800032e6:	0141                	addi	sp,sp,16
    800032e8:	8082                	ret

00000000800032ea <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800032ea:	1141                	addi	sp,sp,-16
    800032ec:	e422                	sd	s0,8(sp)
    800032ee:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800032f0:	00003797          	auipc	a5,0x3
    800032f4:	4d078793          	addi	a5,a5,1232 # 800067c0 <kernelvec>
    800032f8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800032fc:	6422                	ld	s0,8(sp)
    800032fe:	0141                	addi	sp,sp,16
    80003300:	8082                	ret

0000000080003302 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003302:	1141                	addi	sp,sp,-16
    80003304:	e406                	sd	ra,8(sp)
    80003306:	e022                	sd	s0,0(sp)
    80003308:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000330a:	fffff097          	auipc	ra,0xfffff
    8000330e:	a9a080e7          	jalr	-1382(ra) # 80001da4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003312:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003316:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003318:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000331c:	00004617          	auipc	a2,0x4
    80003320:	ce460613          	addi	a2,a2,-796 # 80007000 <_trampoline>
    80003324:	00004697          	auipc	a3,0x4
    80003328:	cdc68693          	addi	a3,a3,-804 # 80007000 <_trampoline>
    8000332c:	8e91                	sub	a3,a3,a2
    8000332e:	040007b7          	lui	a5,0x4000
    80003332:	17fd                	addi	a5,a5,-1
    80003334:	07b2                	slli	a5,a5,0xc
    80003336:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003338:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000333c:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000333e:	180026f3          	csrr	a3,satp
    80003342:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003344:	6158                	ld	a4,128(a0)
    80003346:	7534                	ld	a3,104(a0)
    80003348:	6585                	lui	a1,0x1
    8000334a:	96ae                	add	a3,a3,a1
    8000334c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000334e:	6158                	ld	a4,128(a0)
    80003350:	00000697          	auipc	a3,0x0
    80003354:	13868693          	addi	a3,a3,312 # 80003488 <usertrap>
    80003358:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000335a:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000335c:	8692                	mv	a3,tp
    8000335e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003360:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003364:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003368:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000336c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003370:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003372:	6f18                	ld	a4,24(a4)
    80003374:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003378:	7d2c                	ld	a1,120(a0)
    8000337a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000337c:	00004717          	auipc	a4,0x4
    80003380:	d1470713          	addi	a4,a4,-748 # 80007090 <userret>
    80003384:	8f11                	sub	a4,a4,a2
    80003386:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003388:	577d                	li	a4,-1
    8000338a:	177e                	slli	a4,a4,0x3f
    8000338c:	8dd9                	or	a1,a1,a4
    8000338e:	02000537          	lui	a0,0x2000
    80003392:	157d                	addi	a0,a0,-1
    80003394:	0536                	slli	a0,a0,0xd
    80003396:	9782                	jalr	a5
}
    80003398:	60a2                	ld	ra,8(sp)
    8000339a:	6402                	ld	s0,0(sp)
    8000339c:	0141                	addi	sp,sp,16
    8000339e:	8082                	ret

00000000800033a0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800033aa:	00014497          	auipc	s1,0x14
    800033ae:	63648493          	addi	s1,s1,1590 # 800179e0 <tickslock>
    800033b2:	8526                	mv	a0,s1
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	838080e7          	jalr	-1992(ra) # 80000bec <acquire>
  ticks++;
    800033bc:	00006517          	auipc	a0,0x6
    800033c0:	cb450513          	addi	a0,a0,-844 # 80009070 <ticks>
    800033c4:	411c                	lw	a5,0(a0)
    800033c6:	2785                	addiw	a5,a5,1
    800033c8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	9bc080e7          	jalr	-1604(ra) # 80002d86 <wakeup>
  release(&tickslock);
    800033d2:	8526                	mv	a0,s1
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	8d2080e7          	jalr	-1838(ra) # 80000ca6 <release>
}
    800033dc:	60e2                	ld	ra,24(sp)
    800033de:	6442                	ld	s0,16(sp)
    800033e0:	64a2                	ld	s1,8(sp)
    800033e2:	6105                	addi	sp,sp,32
    800033e4:	8082                	ret

00000000800033e6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800033e6:	1101                	addi	sp,sp,-32
    800033e8:	ec06                	sd	ra,24(sp)
    800033ea:	e822                	sd	s0,16(sp)
    800033ec:	e426                	sd	s1,8(sp)
    800033ee:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033f0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800033f4:	00074d63          	bltz	a4,8000340e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800033f8:	57fd                	li	a5,-1
    800033fa:	17fe                	slli	a5,a5,0x3f
    800033fc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800033fe:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003400:	06f70363          	beq	a4,a5,80003466 <devintr+0x80>
  }
}
    80003404:	60e2                	ld	ra,24(sp)
    80003406:	6442                	ld	s0,16(sp)
    80003408:	64a2                	ld	s1,8(sp)
    8000340a:	6105                	addi	sp,sp,32
    8000340c:	8082                	ret
     (scause & 0xff) == 9){
    8000340e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003412:	46a5                	li	a3,9
    80003414:	fed792e3          	bne	a5,a3,800033f8 <devintr+0x12>
    int irq = plic_claim();
    80003418:	00003097          	auipc	ra,0x3
    8000341c:	4b0080e7          	jalr	1200(ra) # 800068c8 <plic_claim>
    80003420:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003422:	47a9                	li	a5,10
    80003424:	02f50763          	beq	a0,a5,80003452 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003428:	4785                	li	a5,1
    8000342a:	02f50963          	beq	a0,a5,8000345c <devintr+0x76>
    return 1;
    8000342e:	4505                	li	a0,1
    } else if(irq){
    80003430:	d8f1                	beqz	s1,80003404 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003432:	85a6                	mv	a1,s1
    80003434:	00005517          	auipc	a0,0x5
    80003438:	04450513          	addi	a0,a0,68 # 80008478 <states.1890+0x38>
    8000343c:	ffffd097          	auipc	ra,0xffffd
    80003440:	14c080e7          	jalr	332(ra) # 80000588 <printf>
      plic_complete(irq);
    80003444:	8526                	mv	a0,s1
    80003446:	00003097          	auipc	ra,0x3
    8000344a:	4a6080e7          	jalr	1190(ra) # 800068ec <plic_complete>
    return 1;
    8000344e:	4505                	li	a0,1
    80003450:	bf55                	j	80003404 <devintr+0x1e>
      uartintr();
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	556080e7          	jalr	1366(ra) # 800009a8 <uartintr>
    8000345a:	b7ed                	j	80003444 <devintr+0x5e>
      virtio_disk_intr();
    8000345c:	00004097          	auipc	ra,0x4
    80003460:	970080e7          	jalr	-1680(ra) # 80006dcc <virtio_disk_intr>
    80003464:	b7c5                	j	80003444 <devintr+0x5e>
    if(cpuid() == 0){
    80003466:	fffff097          	auipc	ra,0xfffff
    8000346a:	90a080e7          	jalr	-1782(ra) # 80001d70 <cpuid>
    8000346e:	c901                	beqz	a0,8000347e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003470:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003474:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003476:	14479073          	csrw	sip,a5
    return 2;
    8000347a:	4509                	li	a0,2
    8000347c:	b761                	j	80003404 <devintr+0x1e>
      clockintr();
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	f22080e7          	jalr	-222(ra) # 800033a0 <clockintr>
    80003486:	b7ed                	j	80003470 <devintr+0x8a>

0000000080003488 <usertrap>:
{
    80003488:	1101                	addi	sp,sp,-32
    8000348a:	ec06                	sd	ra,24(sp)
    8000348c:	e822                	sd	s0,16(sp)
    8000348e:	e426                	sd	s1,8(sp)
    80003490:	e04a                	sd	s2,0(sp)
    80003492:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003494:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003498:	1007f793          	andi	a5,a5,256
    8000349c:	e3ad                	bnez	a5,800034fe <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000349e:	00003797          	auipc	a5,0x3
    800034a2:	32278793          	addi	a5,a5,802 # 800067c0 <kernelvec>
    800034a6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800034aa:	fffff097          	auipc	ra,0xfffff
    800034ae:	8fa080e7          	jalr	-1798(ra) # 80001da4 <myproc>
    800034b2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800034b4:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034b6:	14102773          	csrr	a4,sepc
    800034ba:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800034bc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800034c0:	47a1                	li	a5,8
    800034c2:	04f71c63          	bne	a4,a5,8000351a <usertrap+0x92>
    if(p->killed)
    800034c6:	413c                	lw	a5,64(a0)
    800034c8:	e3b9                	bnez	a5,8000350e <usertrap+0x86>
    p->trapframe->epc += 4;
    800034ca:	60d8                	ld	a4,128(s1)
    800034cc:	6f1c                	ld	a5,24(a4)
    800034ce:	0791                	addi	a5,a5,4
    800034d0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034d2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800034d6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034da:	10079073          	csrw	sstatus,a5
    syscall();
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	2e0080e7          	jalr	736(ra) # 800037be <syscall>
  if(p->killed)
    800034e6:	40bc                	lw	a5,64(s1)
    800034e8:	ebc1                	bnez	a5,80003578 <usertrap+0xf0>
  usertrapret();
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	e18080e7          	jalr	-488(ra) # 80003302 <usertrapret>
}
    800034f2:	60e2                	ld	ra,24(sp)
    800034f4:	6442                	ld	s0,16(sp)
    800034f6:	64a2                	ld	s1,8(sp)
    800034f8:	6902                	ld	s2,0(sp)
    800034fa:	6105                	addi	sp,sp,32
    800034fc:	8082                	ret
    panic("usertrap: not from user mode");
    800034fe:	00005517          	auipc	a0,0x5
    80003502:	f9a50513          	addi	a0,a0,-102 # 80008498 <states.1890+0x58>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	038080e7          	jalr	56(ra) # 8000053e <panic>
      exit(-1);
    8000350e:	557d                	li	a0,-1
    80003510:	00000097          	auipc	ra,0x0
    80003514:	a64080e7          	jalr	-1436(ra) # 80002f74 <exit>
    80003518:	bf4d                	j	800034ca <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	ecc080e7          	jalr	-308(ra) # 800033e6 <devintr>
    80003522:	892a                	mv	s2,a0
    80003524:	c501                	beqz	a0,8000352c <usertrap+0xa4>
  if(p->killed)
    80003526:	40bc                	lw	a5,64(s1)
    80003528:	c3a1                	beqz	a5,80003568 <usertrap+0xe0>
    8000352a:	a815                	j	8000355e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000352c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003530:	44b0                	lw	a2,72(s1)
    80003532:	00005517          	auipc	a0,0x5
    80003536:	f8650513          	addi	a0,a0,-122 # 800084b8 <states.1890+0x78>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	04e080e7          	jalr	78(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003542:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003546:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000354a:	00005517          	auipc	a0,0x5
    8000354e:	f9e50513          	addi	a0,a0,-98 # 800084e8 <states.1890+0xa8>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	036080e7          	jalr	54(ra) # 80000588 <printf>
    p->killed = 1;
    8000355a:	4785                	li	a5,1
    8000355c:	c0bc                	sw	a5,64(s1)
    exit(-1);
    8000355e:	557d                	li	a0,-1
    80003560:	00000097          	auipc	ra,0x0
    80003564:	a14080e7          	jalr	-1516(ra) # 80002f74 <exit>
  if(which_dev == 2)
    80003568:	4789                	li	a5,2
    8000356a:	f8f910e3          	bne	s2,a5,800034ea <usertrap+0x62>
    yield();
    8000356e:	fffff097          	auipc	ra,0xfffff
    80003572:	b66080e7          	jalr	-1178(ra) # 800020d4 <yield>
    80003576:	bf95                	j	800034ea <usertrap+0x62>
  int which_dev = 0;
    80003578:	4901                	li	s2,0
    8000357a:	b7d5                	j	8000355e <usertrap+0xd6>

000000008000357c <kerneltrap>:
{
    8000357c:	7179                	addi	sp,sp,-48
    8000357e:	f406                	sd	ra,40(sp)
    80003580:	f022                	sd	s0,32(sp)
    80003582:	ec26                	sd	s1,24(sp)
    80003584:	e84a                	sd	s2,16(sp)
    80003586:	e44e                	sd	s3,8(sp)
    80003588:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000358a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000358e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003592:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003596:	1004f793          	andi	a5,s1,256
    8000359a:	cb85                	beqz	a5,800035ca <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000359c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800035a0:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800035a2:	ef85                	bnez	a5,800035da <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	e42080e7          	jalr	-446(ra) # 800033e6 <devintr>
    800035ac:	cd1d                	beqz	a0,800035ea <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800035ae:	4789                	li	a5,2
    800035b0:	06f50a63          	beq	a0,a5,80003624 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800035b4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800035b8:	10049073          	csrw	sstatus,s1
}
    800035bc:	70a2                	ld	ra,40(sp)
    800035be:	7402                	ld	s0,32(sp)
    800035c0:	64e2                	ld	s1,24(sp)
    800035c2:	6942                	ld	s2,16(sp)
    800035c4:	69a2                	ld	s3,8(sp)
    800035c6:	6145                	addi	sp,sp,48
    800035c8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800035ca:	00005517          	auipc	a0,0x5
    800035ce:	f3e50513          	addi	a0,a0,-194 # 80008508 <states.1890+0xc8>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	f6c080e7          	jalr	-148(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800035da:	00005517          	auipc	a0,0x5
    800035de:	f5650513          	addi	a0,a0,-170 # 80008530 <states.1890+0xf0>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	f5c080e7          	jalr	-164(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800035ea:	85ce                	mv	a1,s3
    800035ec:	00005517          	auipc	a0,0x5
    800035f0:	f6450513          	addi	a0,a0,-156 # 80008550 <states.1890+0x110>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	f94080e7          	jalr	-108(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800035fc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003600:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003604:	00005517          	auipc	a0,0x5
    80003608:	f5c50513          	addi	a0,a0,-164 # 80008560 <states.1890+0x120>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	f7c080e7          	jalr	-132(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003614:	00005517          	auipc	a0,0x5
    80003618:	f6450513          	addi	a0,a0,-156 # 80008578 <states.1890+0x138>
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	f22080e7          	jalr	-222(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003624:	ffffe097          	auipc	ra,0xffffe
    80003628:	780080e7          	jalr	1920(ra) # 80001da4 <myproc>
    8000362c:	d541                	beqz	a0,800035b4 <kerneltrap+0x38>
    8000362e:	ffffe097          	auipc	ra,0xffffe
    80003632:	776080e7          	jalr	1910(ra) # 80001da4 <myproc>
    80003636:	5918                	lw	a4,48(a0)
    80003638:	4791                	li	a5,4
    8000363a:	f6f71de3          	bne	a4,a5,800035b4 <kerneltrap+0x38>
    yield();
    8000363e:	fffff097          	auipc	ra,0xfffff
    80003642:	a96080e7          	jalr	-1386(ra) # 800020d4 <yield>
    80003646:	b7bd                	j	800035b4 <kerneltrap+0x38>

0000000080003648 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003648:	1101                	addi	sp,sp,-32
    8000364a:	ec06                	sd	ra,24(sp)
    8000364c:	e822                	sd	s0,16(sp)
    8000364e:	e426                	sd	s1,8(sp)
    80003650:	1000                	addi	s0,sp,32
    80003652:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003654:	ffffe097          	auipc	ra,0xffffe
    80003658:	750080e7          	jalr	1872(ra) # 80001da4 <myproc>
  switch (n) {
    8000365c:	4795                	li	a5,5
    8000365e:	0497e163          	bltu	a5,s1,800036a0 <argraw+0x58>
    80003662:	048a                	slli	s1,s1,0x2
    80003664:	00005717          	auipc	a4,0x5
    80003668:	f4c70713          	addi	a4,a4,-180 # 800085b0 <states.1890+0x170>
    8000366c:	94ba                	add	s1,s1,a4
    8000366e:	409c                	lw	a5,0(s1)
    80003670:	97ba                	add	a5,a5,a4
    80003672:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003674:	615c                	ld	a5,128(a0)
    80003676:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003678:	60e2                	ld	ra,24(sp)
    8000367a:	6442                	ld	s0,16(sp)
    8000367c:	64a2                	ld	s1,8(sp)
    8000367e:	6105                	addi	sp,sp,32
    80003680:	8082                	ret
    return p->trapframe->a1;
    80003682:	615c                	ld	a5,128(a0)
    80003684:	7fa8                	ld	a0,120(a5)
    80003686:	bfcd                	j	80003678 <argraw+0x30>
    return p->trapframe->a2;
    80003688:	615c                	ld	a5,128(a0)
    8000368a:	63c8                	ld	a0,128(a5)
    8000368c:	b7f5                	j	80003678 <argraw+0x30>
    return p->trapframe->a3;
    8000368e:	615c                	ld	a5,128(a0)
    80003690:	67c8                	ld	a0,136(a5)
    80003692:	b7dd                	j	80003678 <argraw+0x30>
    return p->trapframe->a4;
    80003694:	615c                	ld	a5,128(a0)
    80003696:	6bc8                	ld	a0,144(a5)
    80003698:	b7c5                	j	80003678 <argraw+0x30>
    return p->trapframe->a5;
    8000369a:	615c                	ld	a5,128(a0)
    8000369c:	6fc8                	ld	a0,152(a5)
    8000369e:	bfe9                	j	80003678 <argraw+0x30>
  panic("argraw");
    800036a0:	00005517          	auipc	a0,0x5
    800036a4:	ee850513          	addi	a0,a0,-280 # 80008588 <states.1890+0x148>
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	e96080e7          	jalr	-362(ra) # 8000053e <panic>

00000000800036b0 <fetchaddr>:
{
    800036b0:	1101                	addi	sp,sp,-32
    800036b2:	ec06                	sd	ra,24(sp)
    800036b4:	e822                	sd	s0,16(sp)
    800036b6:	e426                	sd	s1,8(sp)
    800036b8:	e04a                	sd	s2,0(sp)
    800036ba:	1000                	addi	s0,sp,32
    800036bc:	84aa                	mv	s1,a0
    800036be:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800036c0:	ffffe097          	auipc	ra,0xffffe
    800036c4:	6e4080e7          	jalr	1764(ra) # 80001da4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800036c8:	793c                	ld	a5,112(a0)
    800036ca:	02f4f863          	bgeu	s1,a5,800036fa <fetchaddr+0x4a>
    800036ce:	00848713          	addi	a4,s1,8
    800036d2:	02e7e663          	bltu	a5,a4,800036fe <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800036d6:	46a1                	li	a3,8
    800036d8:	8626                	mv	a2,s1
    800036da:	85ca                	mv	a1,s2
    800036dc:	7d28                	ld	a0,120(a0)
    800036de:	ffffe097          	auipc	ra,0xffffe
    800036e2:	02e080e7          	jalr	46(ra) # 8000170c <copyin>
    800036e6:	00a03533          	snez	a0,a0
    800036ea:	40a00533          	neg	a0,a0
}
    800036ee:	60e2                	ld	ra,24(sp)
    800036f0:	6442                	ld	s0,16(sp)
    800036f2:	64a2                	ld	s1,8(sp)
    800036f4:	6902                	ld	s2,0(sp)
    800036f6:	6105                	addi	sp,sp,32
    800036f8:	8082                	ret
    return -1;
    800036fa:	557d                	li	a0,-1
    800036fc:	bfcd                	j	800036ee <fetchaddr+0x3e>
    800036fe:	557d                	li	a0,-1
    80003700:	b7fd                	j	800036ee <fetchaddr+0x3e>

0000000080003702 <fetchstr>:
{
    80003702:	7179                	addi	sp,sp,-48
    80003704:	f406                	sd	ra,40(sp)
    80003706:	f022                	sd	s0,32(sp)
    80003708:	ec26                	sd	s1,24(sp)
    8000370a:	e84a                	sd	s2,16(sp)
    8000370c:	e44e                	sd	s3,8(sp)
    8000370e:	1800                	addi	s0,sp,48
    80003710:	892a                	mv	s2,a0
    80003712:	84ae                	mv	s1,a1
    80003714:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003716:	ffffe097          	auipc	ra,0xffffe
    8000371a:	68e080e7          	jalr	1678(ra) # 80001da4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000371e:	86ce                	mv	a3,s3
    80003720:	864a                	mv	a2,s2
    80003722:	85a6                	mv	a1,s1
    80003724:	7d28                	ld	a0,120(a0)
    80003726:	ffffe097          	auipc	ra,0xffffe
    8000372a:	072080e7          	jalr	114(ra) # 80001798 <copyinstr>
  if(err < 0)
    8000372e:	00054763          	bltz	a0,8000373c <fetchstr+0x3a>
  return strlen(buf);
    80003732:	8526                	mv	a0,s1
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	73e080e7          	jalr	1854(ra) # 80000e72 <strlen>
}
    8000373c:	70a2                	ld	ra,40(sp)
    8000373e:	7402                	ld	s0,32(sp)
    80003740:	64e2                	ld	s1,24(sp)
    80003742:	6942                	ld	s2,16(sp)
    80003744:	69a2                	ld	s3,8(sp)
    80003746:	6145                	addi	sp,sp,48
    80003748:	8082                	ret

000000008000374a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000374a:	1101                	addi	sp,sp,-32
    8000374c:	ec06                	sd	ra,24(sp)
    8000374e:	e822                	sd	s0,16(sp)
    80003750:	e426                	sd	s1,8(sp)
    80003752:	1000                	addi	s0,sp,32
    80003754:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	ef2080e7          	jalr	-270(ra) # 80003648 <argraw>
    8000375e:	c088                	sw	a0,0(s1)
  return 0;
}
    80003760:	4501                	li	a0,0
    80003762:	60e2                	ld	ra,24(sp)
    80003764:	6442                	ld	s0,16(sp)
    80003766:	64a2                	ld	s1,8(sp)
    80003768:	6105                	addi	sp,sp,32
    8000376a:	8082                	ret

000000008000376c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000376c:	1101                	addi	sp,sp,-32
    8000376e:	ec06                	sd	ra,24(sp)
    80003770:	e822                	sd	s0,16(sp)
    80003772:	e426                	sd	s1,8(sp)
    80003774:	1000                	addi	s0,sp,32
    80003776:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	ed0080e7          	jalr	-304(ra) # 80003648 <argraw>
    80003780:	e088                	sd	a0,0(s1)
  return 0;
}
    80003782:	4501                	li	a0,0
    80003784:	60e2                	ld	ra,24(sp)
    80003786:	6442                	ld	s0,16(sp)
    80003788:	64a2                	ld	s1,8(sp)
    8000378a:	6105                	addi	sp,sp,32
    8000378c:	8082                	ret

000000008000378e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000378e:	1101                	addi	sp,sp,-32
    80003790:	ec06                	sd	ra,24(sp)
    80003792:	e822                	sd	s0,16(sp)
    80003794:	e426                	sd	s1,8(sp)
    80003796:	e04a                	sd	s2,0(sp)
    80003798:	1000                	addi	s0,sp,32
    8000379a:	84ae                	mv	s1,a1
    8000379c:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	eaa080e7          	jalr	-342(ra) # 80003648 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800037a6:	864a                	mv	a2,s2
    800037a8:	85a6                	mv	a1,s1
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	f58080e7          	jalr	-168(ra) # 80003702 <fetchstr>
}
    800037b2:	60e2                	ld	ra,24(sp)
    800037b4:	6442                	ld	s0,16(sp)
    800037b6:	64a2                	ld	s1,8(sp)
    800037b8:	6902                	ld	s2,0(sp)
    800037ba:	6105                	addi	sp,sp,32
    800037bc:	8082                	ret

00000000800037be <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    800037be:	1101                	addi	sp,sp,-32
    800037c0:	ec06                	sd	ra,24(sp)
    800037c2:	e822                	sd	s0,16(sp)
    800037c4:	e426                	sd	s1,8(sp)
    800037c6:	e04a                	sd	s2,0(sp)
    800037c8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800037ca:	ffffe097          	auipc	ra,0xffffe
    800037ce:	5da080e7          	jalr	1498(ra) # 80001da4 <myproc>
    800037d2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800037d4:	08053903          	ld	s2,128(a0)
    800037d8:	0a893783          	ld	a5,168(s2)
    800037dc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800037e0:	37fd                	addiw	a5,a5,-1
    800037e2:	4759                	li	a4,22
    800037e4:	00f76f63          	bltu	a4,a5,80003802 <syscall+0x44>
    800037e8:	00369713          	slli	a4,a3,0x3
    800037ec:	00005797          	auipc	a5,0x5
    800037f0:	ddc78793          	addi	a5,a5,-548 # 800085c8 <syscalls>
    800037f4:	97ba                	add	a5,a5,a4
    800037f6:	639c                	ld	a5,0(a5)
    800037f8:	c789                	beqz	a5,80003802 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800037fa:	9782                	jalr	a5
    800037fc:	06a93823          	sd	a0,112(s2)
    80003800:	a839                	j	8000381e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003802:	18048613          	addi	a2,s1,384
    80003806:	44ac                	lw	a1,72(s1)
    80003808:	00005517          	auipc	a0,0x5
    8000380c:	d8850513          	addi	a0,a0,-632 # 80008590 <states.1890+0x150>
    80003810:	ffffd097          	auipc	ra,0xffffd
    80003814:	d78080e7          	jalr	-648(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003818:	60dc                	ld	a5,128(s1)
    8000381a:	577d                	li	a4,-1
    8000381c:	fbb8                	sd	a4,112(a5)
  }
}
    8000381e:	60e2                	ld	ra,24(sp)
    80003820:	6442                	ld	s0,16(sp)
    80003822:	64a2                	ld	s1,8(sp)
    80003824:	6902                	ld	s2,0(sp)
    80003826:	6105                	addi	sp,sp,32
    80003828:	8082                	ret

000000008000382a <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    8000382a:	1101                	addi	sp,sp,-32
    8000382c:	ec06                	sd	ra,24(sp)
    8000382e:	e822                	sd	s0,16(sp)
    80003830:	1000                	addi	s0,sp,32
  int a;

  if(argint(0, &a) < 0)
    80003832:	fec40593          	addi	a1,s0,-20
    80003836:	4501                	li	a0,0
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	f12080e7          	jalr	-238(ra) # 8000374a <argint>
    80003840:	87aa                	mv	a5,a0
    return -1;
    80003842:	557d                	li	a0,-1
  if(argint(0, &a) < 0)
    80003844:	0007c863          	bltz	a5,80003854 <sys_set_cpu+0x2a>
  return set_cpu(a);
    80003848:	fec42503          	lw	a0,-20(s0)
    8000384c:	fffff097          	auipc	ra,0xfffff
    80003850:	8d2080e7          	jalr	-1838(ra) # 8000211e <set_cpu>
}
    80003854:	60e2                	ld	ra,24(sp)
    80003856:	6442                	ld	s0,16(sp)
    80003858:	6105                	addi	sp,sp,32
    8000385a:	8082                	ret

000000008000385c <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    8000385c:	1141                	addi	sp,sp,-16
    8000385e:	e406                	sd	ra,8(sp)
    80003860:	e022                	sd	s0,0(sp)
    80003862:	0800                	addi	s0,sp,16
  return get_cpu();
    80003864:	ffffe097          	auipc	ra,0xffffe
    80003868:	580080e7          	jalr	1408(ra) # 80001de4 <get_cpu>
}
    8000386c:	60a2                	ld	ra,8(sp)
    8000386e:	6402                	ld	s0,0(sp)
    80003870:	0141                	addi	sp,sp,16
    80003872:	8082                	ret

0000000080003874 <sys_exit>:

uint64
sys_exit(void)
{
    80003874:	1101                	addi	sp,sp,-32
    80003876:	ec06                	sd	ra,24(sp)
    80003878:	e822                	sd	s0,16(sp)
    8000387a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000387c:	fec40593          	addi	a1,s0,-20
    80003880:	4501                	li	a0,0
    80003882:	00000097          	auipc	ra,0x0
    80003886:	ec8080e7          	jalr	-312(ra) # 8000374a <argint>
    return -1;
    8000388a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000388c:	00054963          	bltz	a0,8000389e <sys_exit+0x2a>
  exit(n);
    80003890:	fec42503          	lw	a0,-20(s0)
    80003894:	fffff097          	auipc	ra,0xfffff
    80003898:	6e0080e7          	jalr	1760(ra) # 80002f74 <exit>
  return 0;  // not reached
    8000389c:	4781                	li	a5,0
}
    8000389e:	853e                	mv	a0,a5
    800038a0:	60e2                	ld	ra,24(sp)
    800038a2:	6442                	ld	s0,16(sp)
    800038a4:	6105                	addi	sp,sp,32
    800038a6:	8082                	ret

00000000800038a8 <sys_getpid>:

uint64
sys_getpid(void)
{
    800038a8:	1141                	addi	sp,sp,-16
    800038aa:	e406                	sd	ra,8(sp)
    800038ac:	e022                	sd	s0,0(sp)
    800038ae:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800038b0:	ffffe097          	auipc	ra,0xffffe
    800038b4:	4f4080e7          	jalr	1268(ra) # 80001da4 <myproc>
}
    800038b8:	4528                	lw	a0,72(a0)
    800038ba:	60a2                	ld	ra,8(sp)
    800038bc:	6402                	ld	s0,0(sp)
    800038be:	0141                	addi	sp,sp,16
    800038c0:	8082                	ret

00000000800038c2 <sys_fork>:

uint64
sys_fork(void)
{
    800038c2:	1141                	addi	sp,sp,-16
    800038c4:	e406                	sd	ra,8(sp)
    800038c6:	e022                	sd	s0,0(sp)
    800038c8:	0800                	addi	s0,sp,16
  return fork();
    800038ca:	fffff097          	auipc	ra,0xfffff
    800038ce:	1c0080e7          	jalr	448(ra) # 80002a8a <fork>
}
    800038d2:	60a2                	ld	ra,8(sp)
    800038d4:	6402                	ld	s0,0(sp)
    800038d6:	0141                	addi	sp,sp,16
    800038d8:	8082                	ret

00000000800038da <sys_wait>:

uint64
sys_wait(void)
{
    800038da:	1101                	addi	sp,sp,-32
    800038dc:	ec06                	sd	ra,24(sp)
    800038de:	e822                	sd	s0,16(sp)
    800038e0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800038e2:	fe840593          	addi	a1,s0,-24
    800038e6:	4501                	li	a0,0
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	e84080e7          	jalr	-380(ra) # 8000376c <argaddr>
    800038f0:	87aa                	mv	a5,a0
    return -1;
    800038f2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800038f4:	0007c863          	bltz	a5,80003904 <sys_wait+0x2a>
  return wait(p);
    800038f8:	fe843503          	ld	a0,-24(s0)
    800038fc:	fffff097          	auipc	ra,0xfffff
    80003900:	362080e7          	jalr	866(ra) # 80002c5e <wait>
}
    80003904:	60e2                	ld	ra,24(sp)
    80003906:	6442                	ld	s0,16(sp)
    80003908:	6105                	addi	sp,sp,32
    8000390a:	8082                	ret

000000008000390c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000390c:	7179                	addi	sp,sp,-48
    8000390e:	f406                	sd	ra,40(sp)
    80003910:	f022                	sd	s0,32(sp)
    80003912:	ec26                	sd	s1,24(sp)
    80003914:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003916:	fdc40593          	addi	a1,s0,-36
    8000391a:	4501                	li	a0,0
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	e2e080e7          	jalr	-466(ra) # 8000374a <argint>
    80003924:	87aa                	mv	a5,a0
    return -1;
    80003926:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003928:	0207c063          	bltz	a5,80003948 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000392c:	ffffe097          	auipc	ra,0xffffe
    80003930:	478080e7          	jalr	1144(ra) # 80001da4 <myproc>
    80003934:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    80003936:	fdc42503          	lw	a0,-36(s0)
    8000393a:	ffffe097          	auipc	ra,0xffffe
    8000393e:	630080e7          	jalr	1584(ra) # 80001f6a <growproc>
    80003942:	00054863          	bltz	a0,80003952 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003946:	8526                	mv	a0,s1
}
    80003948:	70a2                	ld	ra,40(sp)
    8000394a:	7402                	ld	s0,32(sp)
    8000394c:	64e2                	ld	s1,24(sp)
    8000394e:	6145                	addi	sp,sp,48
    80003950:	8082                	ret
    return -1;
    80003952:	557d                	li	a0,-1
    80003954:	bfd5                	j	80003948 <sys_sbrk+0x3c>

0000000080003956 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003956:	7139                	addi	sp,sp,-64
    80003958:	fc06                	sd	ra,56(sp)
    8000395a:	f822                	sd	s0,48(sp)
    8000395c:	f426                	sd	s1,40(sp)
    8000395e:	f04a                	sd	s2,32(sp)
    80003960:	ec4e                	sd	s3,24(sp)
    80003962:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003964:	fcc40593          	addi	a1,s0,-52
    80003968:	4501                	li	a0,0
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	de0080e7          	jalr	-544(ra) # 8000374a <argint>
    return -1;
    80003972:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003974:	06054563          	bltz	a0,800039de <sys_sleep+0x88>
  acquire(&tickslock);
    80003978:	00014517          	auipc	a0,0x14
    8000397c:	06850513          	addi	a0,a0,104 # 800179e0 <tickslock>
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	26c080e7          	jalr	620(ra) # 80000bec <acquire>
  ticks0 = ticks;
    80003988:	00005917          	auipc	s2,0x5
    8000398c:	6e892903          	lw	s2,1768(s2) # 80009070 <ticks>
  while(ticks - ticks0 < n){
    80003990:	fcc42783          	lw	a5,-52(s0)
    80003994:	cf85                	beqz	a5,800039cc <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003996:	00014997          	auipc	s3,0x14
    8000399a:	04a98993          	addi	s3,s3,74 # 800179e0 <tickslock>
    8000399e:	00005497          	auipc	s1,0x5
    800039a2:	6d248493          	addi	s1,s1,1746 # 80009070 <ticks>
    if(myproc()->killed){
    800039a6:	ffffe097          	auipc	ra,0xffffe
    800039aa:	3fe080e7          	jalr	1022(ra) # 80001da4 <myproc>
    800039ae:	413c                	lw	a5,64(a0)
    800039b0:	ef9d                	bnez	a5,800039ee <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800039b2:	85ce                	mv	a1,s3
    800039b4:	8526                	mv	a0,s1
    800039b6:	fffff097          	auipc	ra,0xfffff
    800039ba:	22a080e7          	jalr	554(ra) # 80002be0 <sleep>
  while(ticks - ticks0 < n){
    800039be:	409c                	lw	a5,0(s1)
    800039c0:	412787bb          	subw	a5,a5,s2
    800039c4:	fcc42703          	lw	a4,-52(s0)
    800039c8:	fce7efe3          	bltu	a5,a4,800039a6 <sys_sleep+0x50>
  }
  release(&tickslock);
    800039cc:	00014517          	auipc	a0,0x14
    800039d0:	01450513          	addi	a0,a0,20 # 800179e0 <tickslock>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	2d2080e7          	jalr	722(ra) # 80000ca6 <release>
  return 0;
    800039dc:	4781                	li	a5,0
}
    800039de:	853e                	mv	a0,a5
    800039e0:	70e2                	ld	ra,56(sp)
    800039e2:	7442                	ld	s0,48(sp)
    800039e4:	74a2                	ld	s1,40(sp)
    800039e6:	7902                	ld	s2,32(sp)
    800039e8:	69e2                	ld	s3,24(sp)
    800039ea:	6121                	addi	sp,sp,64
    800039ec:	8082                	ret
      release(&tickslock);
    800039ee:	00014517          	auipc	a0,0x14
    800039f2:	ff250513          	addi	a0,a0,-14 # 800179e0 <tickslock>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	2b0080e7          	jalr	688(ra) # 80000ca6 <release>
      return -1;
    800039fe:	57fd                	li	a5,-1
    80003a00:	bff9                	j	800039de <sys_sleep+0x88>

0000000080003a02 <sys_kill>:

uint64
sys_kill(void)
{
    80003a02:	1101                	addi	sp,sp,-32
    80003a04:	ec06                	sd	ra,24(sp)
    80003a06:	e822                	sd	s0,16(sp)
    80003a08:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003a0a:	fec40593          	addi	a1,s0,-20
    80003a0e:	4501                	li	a0,0
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	d3a080e7          	jalr	-710(ra) # 8000374a <argint>
    80003a18:	87aa                	mv	a5,a0
    return -1;
    80003a1a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003a1c:	0007c863          	bltz	a5,80003a2c <sys_kill+0x2a>
  return kill(pid);
    80003a20:	fec42503          	lw	a0,-20(s0)
    80003a24:	fffff097          	auipc	ra,0xfffff
    80003a28:	642080e7          	jalr	1602(ra) # 80003066 <kill>
}
    80003a2c:	60e2                	ld	ra,24(sp)
    80003a2e:	6442                	ld	s0,16(sp)
    80003a30:	6105                	addi	sp,sp,32
    80003a32:	8082                	ret

0000000080003a34 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003a34:	1101                	addi	sp,sp,-32
    80003a36:	ec06                	sd	ra,24(sp)
    80003a38:	e822                	sd	s0,16(sp)
    80003a3a:	e426                	sd	s1,8(sp)
    80003a3c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003a3e:	00014517          	auipc	a0,0x14
    80003a42:	fa250513          	addi	a0,a0,-94 # 800179e0 <tickslock>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	1a6080e7          	jalr	422(ra) # 80000bec <acquire>
  xticks = ticks;
    80003a4e:	00005497          	auipc	s1,0x5
    80003a52:	6224a483          	lw	s1,1570(s1) # 80009070 <ticks>
  release(&tickslock);
    80003a56:	00014517          	auipc	a0,0x14
    80003a5a:	f8a50513          	addi	a0,a0,-118 # 800179e0 <tickslock>
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	248080e7          	jalr	584(ra) # 80000ca6 <release>
  return xticks;
}
    80003a66:	02049513          	slli	a0,s1,0x20
    80003a6a:	9101                	srli	a0,a0,0x20
    80003a6c:	60e2                	ld	ra,24(sp)
    80003a6e:	6442                	ld	s0,16(sp)
    80003a70:	64a2                	ld	s1,8(sp)
    80003a72:	6105                	addi	sp,sp,32
    80003a74:	8082                	ret

0000000080003a76 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a76:	7179                	addi	sp,sp,-48
    80003a78:	f406                	sd	ra,40(sp)
    80003a7a:	f022                	sd	s0,32(sp)
    80003a7c:	ec26                	sd	s1,24(sp)
    80003a7e:	e84a                	sd	s2,16(sp)
    80003a80:	e44e                	sd	s3,8(sp)
    80003a82:	e052                	sd	s4,0(sp)
    80003a84:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003a86:	00005597          	auipc	a1,0x5
    80003a8a:	c0258593          	addi	a1,a1,-1022 # 80008688 <syscalls+0xc0>
    80003a8e:	00014517          	auipc	a0,0x14
    80003a92:	f6a50513          	addi	a0,a0,-150 # 800179f8 <bcache>
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	0be080e7          	jalr	190(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003a9e:	0001c797          	auipc	a5,0x1c
    80003aa2:	f5a78793          	addi	a5,a5,-166 # 8001f9f8 <bcache+0x8000>
    80003aa6:	0001c717          	auipc	a4,0x1c
    80003aaa:	1ba70713          	addi	a4,a4,442 # 8001fc60 <bcache+0x8268>
    80003aae:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003ab2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003ab6:	00014497          	auipc	s1,0x14
    80003aba:	f5a48493          	addi	s1,s1,-166 # 80017a10 <bcache+0x18>
    b->next = bcache.head.next;
    80003abe:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003ac0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003ac2:	00005a17          	auipc	s4,0x5
    80003ac6:	bcea0a13          	addi	s4,s4,-1074 # 80008690 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003aca:	2b893783          	ld	a5,696(s2)
    80003ace:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003ad0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003ad4:	85d2                	mv	a1,s4
    80003ad6:	01048513          	addi	a0,s1,16
    80003ada:	00001097          	auipc	ra,0x1
    80003ade:	4bc080e7          	jalr	1212(ra) # 80004f96 <initsleeplock>
    bcache.head.next->prev = b;
    80003ae2:	2b893783          	ld	a5,696(s2)
    80003ae6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003ae8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003aec:	45848493          	addi	s1,s1,1112
    80003af0:	fd349de3          	bne	s1,s3,80003aca <binit+0x54>
  }
}
    80003af4:	70a2                	ld	ra,40(sp)
    80003af6:	7402                	ld	s0,32(sp)
    80003af8:	64e2                	ld	s1,24(sp)
    80003afa:	6942                	ld	s2,16(sp)
    80003afc:	69a2                	ld	s3,8(sp)
    80003afe:	6a02                	ld	s4,0(sp)
    80003b00:	6145                	addi	sp,sp,48
    80003b02:	8082                	ret

0000000080003b04 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003b04:	7179                	addi	sp,sp,-48
    80003b06:	f406                	sd	ra,40(sp)
    80003b08:	f022                	sd	s0,32(sp)
    80003b0a:	ec26                	sd	s1,24(sp)
    80003b0c:	e84a                	sd	s2,16(sp)
    80003b0e:	e44e                	sd	s3,8(sp)
    80003b10:	1800                	addi	s0,sp,48
    80003b12:	89aa                	mv	s3,a0
    80003b14:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003b16:	00014517          	auipc	a0,0x14
    80003b1a:	ee250513          	addi	a0,a0,-286 # 800179f8 <bcache>
    80003b1e:	ffffd097          	auipc	ra,0xffffd
    80003b22:	0ce080e7          	jalr	206(ra) # 80000bec <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003b26:	0001c497          	auipc	s1,0x1c
    80003b2a:	18a4b483          	ld	s1,394(s1) # 8001fcb0 <bcache+0x82b8>
    80003b2e:	0001c797          	auipc	a5,0x1c
    80003b32:	13278793          	addi	a5,a5,306 # 8001fc60 <bcache+0x8268>
    80003b36:	02f48f63          	beq	s1,a5,80003b74 <bread+0x70>
    80003b3a:	873e                	mv	a4,a5
    80003b3c:	a021                	j	80003b44 <bread+0x40>
    80003b3e:	68a4                	ld	s1,80(s1)
    80003b40:	02e48a63          	beq	s1,a4,80003b74 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003b44:	449c                	lw	a5,8(s1)
    80003b46:	ff379ce3          	bne	a5,s3,80003b3e <bread+0x3a>
    80003b4a:	44dc                	lw	a5,12(s1)
    80003b4c:	ff2799e3          	bne	a5,s2,80003b3e <bread+0x3a>
      b->refcnt++;
    80003b50:	40bc                	lw	a5,64(s1)
    80003b52:	2785                	addiw	a5,a5,1
    80003b54:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b56:	00014517          	auipc	a0,0x14
    80003b5a:	ea250513          	addi	a0,a0,-350 # 800179f8 <bcache>
    80003b5e:	ffffd097          	auipc	ra,0xffffd
    80003b62:	148080e7          	jalr	328(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003b66:	01048513          	addi	a0,s1,16
    80003b6a:	00001097          	auipc	ra,0x1
    80003b6e:	466080e7          	jalr	1126(ra) # 80004fd0 <acquiresleep>
      return b;
    80003b72:	a8b9                	j	80003bd0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b74:	0001c497          	auipc	s1,0x1c
    80003b78:	1344b483          	ld	s1,308(s1) # 8001fca8 <bcache+0x82b0>
    80003b7c:	0001c797          	auipc	a5,0x1c
    80003b80:	0e478793          	addi	a5,a5,228 # 8001fc60 <bcache+0x8268>
    80003b84:	00f48863          	beq	s1,a5,80003b94 <bread+0x90>
    80003b88:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003b8a:	40bc                	lw	a5,64(s1)
    80003b8c:	cf81                	beqz	a5,80003ba4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b8e:	64a4                	ld	s1,72(s1)
    80003b90:	fee49de3          	bne	s1,a4,80003b8a <bread+0x86>
  panic("bget: no buffers");
    80003b94:	00005517          	auipc	a0,0x5
    80003b98:	b0450513          	addi	a0,a0,-1276 # 80008698 <syscalls+0xd0>
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	9a2080e7          	jalr	-1630(ra) # 8000053e <panic>
      b->dev = dev;
    80003ba4:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003ba8:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003bac:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003bb0:	4785                	li	a5,1
    80003bb2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003bb4:	00014517          	auipc	a0,0x14
    80003bb8:	e4450513          	addi	a0,a0,-444 # 800179f8 <bcache>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	0ea080e7          	jalr	234(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003bc4:	01048513          	addi	a0,s1,16
    80003bc8:	00001097          	auipc	ra,0x1
    80003bcc:	408080e7          	jalr	1032(ra) # 80004fd0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003bd0:	409c                	lw	a5,0(s1)
    80003bd2:	cb89                	beqz	a5,80003be4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003bd4:	8526                	mv	a0,s1
    80003bd6:	70a2                	ld	ra,40(sp)
    80003bd8:	7402                	ld	s0,32(sp)
    80003bda:	64e2                	ld	s1,24(sp)
    80003bdc:	6942                	ld	s2,16(sp)
    80003bde:	69a2                	ld	s3,8(sp)
    80003be0:	6145                	addi	sp,sp,48
    80003be2:	8082                	ret
    virtio_disk_rw(b, 0);
    80003be4:	4581                	li	a1,0
    80003be6:	8526                	mv	a0,s1
    80003be8:	00003097          	auipc	ra,0x3
    80003bec:	f0e080e7          	jalr	-242(ra) # 80006af6 <virtio_disk_rw>
    b->valid = 1;
    80003bf0:	4785                	li	a5,1
    80003bf2:	c09c                	sw	a5,0(s1)
  return b;
    80003bf4:	b7c5                	j	80003bd4 <bread+0xd0>

0000000080003bf6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003bf6:	1101                	addi	sp,sp,-32
    80003bf8:	ec06                	sd	ra,24(sp)
    80003bfa:	e822                	sd	s0,16(sp)
    80003bfc:	e426                	sd	s1,8(sp)
    80003bfe:	1000                	addi	s0,sp,32
    80003c00:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c02:	0541                	addi	a0,a0,16
    80003c04:	00001097          	auipc	ra,0x1
    80003c08:	466080e7          	jalr	1126(ra) # 8000506a <holdingsleep>
    80003c0c:	cd01                	beqz	a0,80003c24 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003c0e:	4585                	li	a1,1
    80003c10:	8526                	mv	a0,s1
    80003c12:	00003097          	auipc	ra,0x3
    80003c16:	ee4080e7          	jalr	-284(ra) # 80006af6 <virtio_disk_rw>
}
    80003c1a:	60e2                	ld	ra,24(sp)
    80003c1c:	6442                	ld	s0,16(sp)
    80003c1e:	64a2                	ld	s1,8(sp)
    80003c20:	6105                	addi	sp,sp,32
    80003c22:	8082                	ret
    panic("bwrite");
    80003c24:	00005517          	auipc	a0,0x5
    80003c28:	a8c50513          	addi	a0,a0,-1396 # 800086b0 <syscalls+0xe8>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	912080e7          	jalr	-1774(ra) # 8000053e <panic>

0000000080003c34 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003c34:	1101                	addi	sp,sp,-32
    80003c36:	ec06                	sd	ra,24(sp)
    80003c38:	e822                	sd	s0,16(sp)
    80003c3a:	e426                	sd	s1,8(sp)
    80003c3c:	e04a                	sd	s2,0(sp)
    80003c3e:	1000                	addi	s0,sp,32
    80003c40:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c42:	01050913          	addi	s2,a0,16
    80003c46:	854a                	mv	a0,s2
    80003c48:	00001097          	auipc	ra,0x1
    80003c4c:	422080e7          	jalr	1058(ra) # 8000506a <holdingsleep>
    80003c50:	c92d                	beqz	a0,80003cc2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c52:	854a                	mv	a0,s2
    80003c54:	00001097          	auipc	ra,0x1
    80003c58:	3d2080e7          	jalr	978(ra) # 80005026 <releasesleep>

  acquire(&bcache.lock);
    80003c5c:	00014517          	auipc	a0,0x14
    80003c60:	d9c50513          	addi	a0,a0,-612 # 800179f8 <bcache>
    80003c64:	ffffd097          	auipc	ra,0xffffd
    80003c68:	f88080e7          	jalr	-120(ra) # 80000bec <acquire>
  b->refcnt--;
    80003c6c:	40bc                	lw	a5,64(s1)
    80003c6e:	37fd                	addiw	a5,a5,-1
    80003c70:	0007871b          	sext.w	a4,a5
    80003c74:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c76:	eb05                	bnez	a4,80003ca6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c78:	68bc                	ld	a5,80(s1)
    80003c7a:	64b8                	ld	a4,72(s1)
    80003c7c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003c7e:	64bc                	ld	a5,72(s1)
    80003c80:	68b8                	ld	a4,80(s1)
    80003c82:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003c84:	0001c797          	auipc	a5,0x1c
    80003c88:	d7478793          	addi	a5,a5,-652 # 8001f9f8 <bcache+0x8000>
    80003c8c:	2b87b703          	ld	a4,696(a5)
    80003c90:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003c92:	0001c717          	auipc	a4,0x1c
    80003c96:	fce70713          	addi	a4,a4,-50 # 8001fc60 <bcache+0x8268>
    80003c9a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003c9c:	2b87b703          	ld	a4,696(a5)
    80003ca0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003ca2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003ca6:	00014517          	auipc	a0,0x14
    80003caa:	d5250513          	addi	a0,a0,-686 # 800179f8 <bcache>
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	ff8080e7          	jalr	-8(ra) # 80000ca6 <release>
}
    80003cb6:	60e2                	ld	ra,24(sp)
    80003cb8:	6442                	ld	s0,16(sp)
    80003cba:	64a2                	ld	s1,8(sp)
    80003cbc:	6902                	ld	s2,0(sp)
    80003cbe:	6105                	addi	sp,sp,32
    80003cc0:	8082                	ret
    panic("brelse");
    80003cc2:	00005517          	auipc	a0,0x5
    80003cc6:	9f650513          	addi	a0,a0,-1546 # 800086b8 <syscalls+0xf0>
    80003cca:	ffffd097          	auipc	ra,0xffffd
    80003cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080003cd2 <bpin>:

void
bpin(struct buf *b) {
    80003cd2:	1101                	addi	sp,sp,-32
    80003cd4:	ec06                	sd	ra,24(sp)
    80003cd6:	e822                	sd	s0,16(sp)
    80003cd8:	e426                	sd	s1,8(sp)
    80003cda:	1000                	addi	s0,sp,32
    80003cdc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003cde:	00014517          	auipc	a0,0x14
    80003ce2:	d1a50513          	addi	a0,a0,-742 # 800179f8 <bcache>
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	f06080e7          	jalr	-250(ra) # 80000bec <acquire>
  b->refcnt++;
    80003cee:	40bc                	lw	a5,64(s1)
    80003cf0:	2785                	addiw	a5,a5,1
    80003cf2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003cf4:	00014517          	auipc	a0,0x14
    80003cf8:	d0450513          	addi	a0,a0,-764 # 800179f8 <bcache>
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	faa080e7          	jalr	-86(ra) # 80000ca6 <release>
}
    80003d04:	60e2                	ld	ra,24(sp)
    80003d06:	6442                	ld	s0,16(sp)
    80003d08:	64a2                	ld	s1,8(sp)
    80003d0a:	6105                	addi	sp,sp,32
    80003d0c:	8082                	ret

0000000080003d0e <bunpin>:

void
bunpin(struct buf *b) {
    80003d0e:	1101                	addi	sp,sp,-32
    80003d10:	ec06                	sd	ra,24(sp)
    80003d12:	e822                	sd	s0,16(sp)
    80003d14:	e426                	sd	s1,8(sp)
    80003d16:	1000                	addi	s0,sp,32
    80003d18:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d1a:	00014517          	auipc	a0,0x14
    80003d1e:	cde50513          	addi	a0,a0,-802 # 800179f8 <bcache>
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	eca080e7          	jalr	-310(ra) # 80000bec <acquire>
  b->refcnt--;
    80003d2a:	40bc                	lw	a5,64(s1)
    80003d2c:	37fd                	addiw	a5,a5,-1
    80003d2e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d30:	00014517          	auipc	a0,0x14
    80003d34:	cc850513          	addi	a0,a0,-824 # 800179f8 <bcache>
    80003d38:	ffffd097          	auipc	ra,0xffffd
    80003d3c:	f6e080e7          	jalr	-146(ra) # 80000ca6 <release>
}
    80003d40:	60e2                	ld	ra,24(sp)
    80003d42:	6442                	ld	s0,16(sp)
    80003d44:	64a2                	ld	s1,8(sp)
    80003d46:	6105                	addi	sp,sp,32
    80003d48:	8082                	ret

0000000080003d4a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003d4a:	1101                	addi	sp,sp,-32
    80003d4c:	ec06                	sd	ra,24(sp)
    80003d4e:	e822                	sd	s0,16(sp)
    80003d50:	e426                	sd	s1,8(sp)
    80003d52:	e04a                	sd	s2,0(sp)
    80003d54:	1000                	addi	s0,sp,32
    80003d56:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003d58:	00d5d59b          	srliw	a1,a1,0xd
    80003d5c:	0001c797          	auipc	a5,0x1c
    80003d60:	3787a783          	lw	a5,888(a5) # 800200d4 <sb+0x1c>
    80003d64:	9dbd                	addw	a1,a1,a5
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	d9e080e7          	jalr	-610(ra) # 80003b04 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d6e:	0074f713          	andi	a4,s1,7
    80003d72:	4785                	li	a5,1
    80003d74:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d78:	14ce                	slli	s1,s1,0x33
    80003d7a:	90d9                	srli	s1,s1,0x36
    80003d7c:	00950733          	add	a4,a0,s1
    80003d80:	05874703          	lbu	a4,88(a4)
    80003d84:	00e7f6b3          	and	a3,a5,a4
    80003d88:	c69d                	beqz	a3,80003db6 <bfree+0x6c>
    80003d8a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003d8c:	94aa                	add	s1,s1,a0
    80003d8e:	fff7c793          	not	a5,a5
    80003d92:	8ff9                	and	a5,a5,a4
    80003d94:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003d98:	00001097          	auipc	ra,0x1
    80003d9c:	118080e7          	jalr	280(ra) # 80004eb0 <log_write>
  brelse(bp);
    80003da0:	854a                	mv	a0,s2
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	e92080e7          	jalr	-366(ra) # 80003c34 <brelse>
}
    80003daa:	60e2                	ld	ra,24(sp)
    80003dac:	6442                	ld	s0,16(sp)
    80003dae:	64a2                	ld	s1,8(sp)
    80003db0:	6902                	ld	s2,0(sp)
    80003db2:	6105                	addi	sp,sp,32
    80003db4:	8082                	ret
    panic("freeing free block");
    80003db6:	00005517          	auipc	a0,0x5
    80003dba:	90a50513          	addi	a0,a0,-1782 # 800086c0 <syscalls+0xf8>
    80003dbe:	ffffc097          	auipc	ra,0xffffc
    80003dc2:	780080e7          	jalr	1920(ra) # 8000053e <panic>

0000000080003dc6 <balloc>:
{
    80003dc6:	711d                	addi	sp,sp,-96
    80003dc8:	ec86                	sd	ra,88(sp)
    80003dca:	e8a2                	sd	s0,80(sp)
    80003dcc:	e4a6                	sd	s1,72(sp)
    80003dce:	e0ca                	sd	s2,64(sp)
    80003dd0:	fc4e                	sd	s3,56(sp)
    80003dd2:	f852                	sd	s4,48(sp)
    80003dd4:	f456                	sd	s5,40(sp)
    80003dd6:	f05a                	sd	s6,32(sp)
    80003dd8:	ec5e                	sd	s7,24(sp)
    80003dda:	e862                	sd	s8,16(sp)
    80003ddc:	e466                	sd	s9,8(sp)
    80003dde:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003de0:	0001c797          	auipc	a5,0x1c
    80003de4:	2dc7a783          	lw	a5,732(a5) # 800200bc <sb+0x4>
    80003de8:	cbd1                	beqz	a5,80003e7c <balloc+0xb6>
    80003dea:	8baa                	mv	s7,a0
    80003dec:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003dee:	0001cb17          	auipc	s6,0x1c
    80003df2:	2cab0b13          	addi	s6,s6,714 # 800200b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003df6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003df8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003dfa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003dfc:	6c89                	lui	s9,0x2
    80003dfe:	a831                	j	80003e1a <balloc+0x54>
    brelse(bp);
    80003e00:	854a                	mv	a0,s2
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	e32080e7          	jalr	-462(ra) # 80003c34 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003e0a:	015c87bb          	addw	a5,s9,s5
    80003e0e:	00078a9b          	sext.w	s5,a5
    80003e12:	004b2703          	lw	a4,4(s6)
    80003e16:	06eaf363          	bgeu	s5,a4,80003e7c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003e1a:	41fad79b          	sraiw	a5,s5,0x1f
    80003e1e:	0137d79b          	srliw	a5,a5,0x13
    80003e22:	015787bb          	addw	a5,a5,s5
    80003e26:	40d7d79b          	sraiw	a5,a5,0xd
    80003e2a:	01cb2583          	lw	a1,28(s6)
    80003e2e:	9dbd                	addw	a1,a1,a5
    80003e30:	855e                	mv	a0,s7
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	cd2080e7          	jalr	-814(ra) # 80003b04 <bread>
    80003e3a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e3c:	004b2503          	lw	a0,4(s6)
    80003e40:	000a849b          	sext.w	s1,s5
    80003e44:	8662                	mv	a2,s8
    80003e46:	faa4fde3          	bgeu	s1,a0,80003e00 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003e4a:	41f6579b          	sraiw	a5,a2,0x1f
    80003e4e:	01d7d69b          	srliw	a3,a5,0x1d
    80003e52:	00c6873b          	addw	a4,a3,a2
    80003e56:	00777793          	andi	a5,a4,7
    80003e5a:	9f95                	subw	a5,a5,a3
    80003e5c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e60:	4037571b          	sraiw	a4,a4,0x3
    80003e64:	00e906b3          	add	a3,s2,a4
    80003e68:	0586c683          	lbu	a3,88(a3)
    80003e6c:	00d7f5b3          	and	a1,a5,a3
    80003e70:	cd91                	beqz	a1,80003e8c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e72:	2605                	addiw	a2,a2,1
    80003e74:	2485                	addiw	s1,s1,1
    80003e76:	fd4618e3          	bne	a2,s4,80003e46 <balloc+0x80>
    80003e7a:	b759                	j	80003e00 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003e7c:	00005517          	auipc	a0,0x5
    80003e80:	85c50513          	addi	a0,a0,-1956 # 800086d8 <syscalls+0x110>
    80003e84:	ffffc097          	auipc	ra,0xffffc
    80003e88:	6ba080e7          	jalr	1722(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e8c:	974a                	add	a4,a4,s2
    80003e8e:	8fd5                	or	a5,a5,a3
    80003e90:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e94:	854a                	mv	a0,s2
    80003e96:	00001097          	auipc	ra,0x1
    80003e9a:	01a080e7          	jalr	26(ra) # 80004eb0 <log_write>
        brelse(bp);
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	d94080e7          	jalr	-620(ra) # 80003c34 <brelse>
  bp = bread(dev, bno);
    80003ea8:	85a6                	mv	a1,s1
    80003eaa:	855e                	mv	a0,s7
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	c58080e7          	jalr	-936(ra) # 80003b04 <bread>
    80003eb4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003eb6:	40000613          	li	a2,1024
    80003eba:	4581                	li	a1,0
    80003ebc:	05850513          	addi	a0,a0,88
    80003ec0:	ffffd097          	auipc	ra,0xffffd
    80003ec4:	e2e080e7          	jalr	-466(ra) # 80000cee <memset>
  log_write(bp);
    80003ec8:	854a                	mv	a0,s2
    80003eca:	00001097          	auipc	ra,0x1
    80003ece:	fe6080e7          	jalr	-26(ra) # 80004eb0 <log_write>
  brelse(bp);
    80003ed2:	854a                	mv	a0,s2
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	d60080e7          	jalr	-672(ra) # 80003c34 <brelse>
}
    80003edc:	8526                	mv	a0,s1
    80003ede:	60e6                	ld	ra,88(sp)
    80003ee0:	6446                	ld	s0,80(sp)
    80003ee2:	64a6                	ld	s1,72(sp)
    80003ee4:	6906                	ld	s2,64(sp)
    80003ee6:	79e2                	ld	s3,56(sp)
    80003ee8:	7a42                	ld	s4,48(sp)
    80003eea:	7aa2                	ld	s5,40(sp)
    80003eec:	7b02                	ld	s6,32(sp)
    80003eee:	6be2                	ld	s7,24(sp)
    80003ef0:	6c42                	ld	s8,16(sp)
    80003ef2:	6ca2                	ld	s9,8(sp)
    80003ef4:	6125                	addi	sp,sp,96
    80003ef6:	8082                	ret

0000000080003ef8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ef8:	7179                	addi	sp,sp,-48
    80003efa:	f406                	sd	ra,40(sp)
    80003efc:	f022                	sd	s0,32(sp)
    80003efe:	ec26                	sd	s1,24(sp)
    80003f00:	e84a                	sd	s2,16(sp)
    80003f02:	e44e                	sd	s3,8(sp)
    80003f04:	e052                	sd	s4,0(sp)
    80003f06:	1800                	addi	s0,sp,48
    80003f08:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003f0a:	47ad                	li	a5,11
    80003f0c:	04b7fe63          	bgeu	a5,a1,80003f68 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003f10:	ff45849b          	addiw	s1,a1,-12
    80003f14:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003f18:	0ff00793          	li	a5,255
    80003f1c:	0ae7e363          	bltu	a5,a4,80003fc2 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003f20:	08052583          	lw	a1,128(a0)
    80003f24:	c5ad                	beqz	a1,80003f8e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003f26:	00092503          	lw	a0,0(s2)
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	bda080e7          	jalr	-1062(ra) # 80003b04 <bread>
    80003f32:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003f34:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003f38:	02049593          	slli	a1,s1,0x20
    80003f3c:	9181                	srli	a1,a1,0x20
    80003f3e:	058a                	slli	a1,a1,0x2
    80003f40:	00b784b3          	add	s1,a5,a1
    80003f44:	0004a983          	lw	s3,0(s1)
    80003f48:	04098d63          	beqz	s3,80003fa2 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003f4c:	8552                	mv	a0,s4
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	ce6080e7          	jalr	-794(ra) # 80003c34 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003f56:	854e                	mv	a0,s3
    80003f58:	70a2                	ld	ra,40(sp)
    80003f5a:	7402                	ld	s0,32(sp)
    80003f5c:	64e2                	ld	s1,24(sp)
    80003f5e:	6942                	ld	s2,16(sp)
    80003f60:	69a2                	ld	s3,8(sp)
    80003f62:	6a02                	ld	s4,0(sp)
    80003f64:	6145                	addi	sp,sp,48
    80003f66:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003f68:	02059493          	slli	s1,a1,0x20
    80003f6c:	9081                	srli	s1,s1,0x20
    80003f6e:	048a                	slli	s1,s1,0x2
    80003f70:	94aa                	add	s1,s1,a0
    80003f72:	0504a983          	lw	s3,80(s1)
    80003f76:	fe0990e3          	bnez	s3,80003f56 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003f7a:	4108                	lw	a0,0(a0)
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	e4a080e7          	jalr	-438(ra) # 80003dc6 <balloc>
    80003f84:	0005099b          	sext.w	s3,a0
    80003f88:	0534a823          	sw	s3,80(s1)
    80003f8c:	b7e9                	j	80003f56 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003f8e:	4108                	lw	a0,0(a0)
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	e36080e7          	jalr	-458(ra) # 80003dc6 <balloc>
    80003f98:	0005059b          	sext.w	a1,a0
    80003f9c:	08b92023          	sw	a1,128(s2)
    80003fa0:	b759                	j	80003f26 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003fa2:	00092503          	lw	a0,0(s2)
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	e20080e7          	jalr	-480(ra) # 80003dc6 <balloc>
    80003fae:	0005099b          	sext.w	s3,a0
    80003fb2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003fb6:	8552                	mv	a0,s4
    80003fb8:	00001097          	auipc	ra,0x1
    80003fbc:	ef8080e7          	jalr	-264(ra) # 80004eb0 <log_write>
    80003fc0:	b771                	j	80003f4c <bmap+0x54>
  panic("bmap: out of range");
    80003fc2:	00004517          	auipc	a0,0x4
    80003fc6:	72e50513          	addi	a0,a0,1838 # 800086f0 <syscalls+0x128>
    80003fca:	ffffc097          	auipc	ra,0xffffc
    80003fce:	574080e7          	jalr	1396(ra) # 8000053e <panic>

0000000080003fd2 <iget>:
{
    80003fd2:	7179                	addi	sp,sp,-48
    80003fd4:	f406                	sd	ra,40(sp)
    80003fd6:	f022                	sd	s0,32(sp)
    80003fd8:	ec26                	sd	s1,24(sp)
    80003fda:	e84a                	sd	s2,16(sp)
    80003fdc:	e44e                	sd	s3,8(sp)
    80003fde:	e052                	sd	s4,0(sp)
    80003fe0:	1800                	addi	s0,sp,48
    80003fe2:	89aa                	mv	s3,a0
    80003fe4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003fe6:	0001c517          	auipc	a0,0x1c
    80003fea:	0f250513          	addi	a0,a0,242 # 800200d8 <itable>
    80003fee:	ffffd097          	auipc	ra,0xffffd
    80003ff2:	bfe080e7          	jalr	-1026(ra) # 80000bec <acquire>
  empty = 0;
    80003ff6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ff8:	0001c497          	auipc	s1,0x1c
    80003ffc:	0f848493          	addi	s1,s1,248 # 800200f0 <itable+0x18>
    80004000:	0001e697          	auipc	a3,0x1e
    80004004:	b8068693          	addi	a3,a3,-1152 # 80021b80 <log>
    80004008:	a039                	j	80004016 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000400a:	02090b63          	beqz	s2,80004040 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000400e:	08848493          	addi	s1,s1,136
    80004012:	02d48a63          	beq	s1,a3,80004046 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004016:	449c                	lw	a5,8(s1)
    80004018:	fef059e3          	blez	a5,8000400a <iget+0x38>
    8000401c:	4098                	lw	a4,0(s1)
    8000401e:	ff3716e3          	bne	a4,s3,8000400a <iget+0x38>
    80004022:	40d8                	lw	a4,4(s1)
    80004024:	ff4713e3          	bne	a4,s4,8000400a <iget+0x38>
      ip->ref++;
    80004028:	2785                	addiw	a5,a5,1
    8000402a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000402c:	0001c517          	auipc	a0,0x1c
    80004030:	0ac50513          	addi	a0,a0,172 # 800200d8 <itable>
    80004034:	ffffd097          	auipc	ra,0xffffd
    80004038:	c72080e7          	jalr	-910(ra) # 80000ca6 <release>
      return ip;
    8000403c:	8926                	mv	s2,s1
    8000403e:	a03d                	j	8000406c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004040:	f7f9                	bnez	a5,8000400e <iget+0x3c>
    80004042:	8926                	mv	s2,s1
    80004044:	b7e9                	j	8000400e <iget+0x3c>
  if(empty == 0)
    80004046:	02090c63          	beqz	s2,8000407e <iget+0xac>
  ip->dev = dev;
    8000404a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000404e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004052:	4785                	li	a5,1
    80004054:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004058:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000405c:	0001c517          	auipc	a0,0x1c
    80004060:	07c50513          	addi	a0,a0,124 # 800200d8 <itable>
    80004064:	ffffd097          	auipc	ra,0xffffd
    80004068:	c42080e7          	jalr	-958(ra) # 80000ca6 <release>
}
    8000406c:	854a                	mv	a0,s2
    8000406e:	70a2                	ld	ra,40(sp)
    80004070:	7402                	ld	s0,32(sp)
    80004072:	64e2                	ld	s1,24(sp)
    80004074:	6942                	ld	s2,16(sp)
    80004076:	69a2                	ld	s3,8(sp)
    80004078:	6a02                	ld	s4,0(sp)
    8000407a:	6145                	addi	sp,sp,48
    8000407c:	8082                	ret
    panic("iget: no inodes");
    8000407e:	00004517          	auipc	a0,0x4
    80004082:	68a50513          	addi	a0,a0,1674 # 80008708 <syscalls+0x140>
    80004086:	ffffc097          	auipc	ra,0xffffc
    8000408a:	4b8080e7          	jalr	1208(ra) # 8000053e <panic>

000000008000408e <fsinit>:
fsinit(int dev) {
    8000408e:	7179                	addi	sp,sp,-48
    80004090:	f406                	sd	ra,40(sp)
    80004092:	f022                	sd	s0,32(sp)
    80004094:	ec26                	sd	s1,24(sp)
    80004096:	e84a                	sd	s2,16(sp)
    80004098:	e44e                	sd	s3,8(sp)
    8000409a:	1800                	addi	s0,sp,48
    8000409c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000409e:	4585                	li	a1,1
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	a64080e7          	jalr	-1436(ra) # 80003b04 <bread>
    800040a8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800040aa:	0001c997          	auipc	s3,0x1c
    800040ae:	00e98993          	addi	s3,s3,14 # 800200b8 <sb>
    800040b2:	02000613          	li	a2,32
    800040b6:	05850593          	addi	a1,a0,88
    800040ba:	854e                	mv	a0,s3
    800040bc:	ffffd097          	auipc	ra,0xffffd
    800040c0:	c92080e7          	jalr	-878(ra) # 80000d4e <memmove>
  brelse(bp);
    800040c4:	8526                	mv	a0,s1
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	b6e080e7          	jalr	-1170(ra) # 80003c34 <brelse>
  if(sb.magic != FSMAGIC)
    800040ce:	0009a703          	lw	a4,0(s3)
    800040d2:	102037b7          	lui	a5,0x10203
    800040d6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800040da:	02f71263          	bne	a4,a5,800040fe <fsinit+0x70>
  initlog(dev, &sb);
    800040de:	0001c597          	auipc	a1,0x1c
    800040e2:	fda58593          	addi	a1,a1,-38 # 800200b8 <sb>
    800040e6:	854a                	mv	a0,s2
    800040e8:	00001097          	auipc	ra,0x1
    800040ec:	b4c080e7          	jalr	-1204(ra) # 80004c34 <initlog>
}
    800040f0:	70a2                	ld	ra,40(sp)
    800040f2:	7402                	ld	s0,32(sp)
    800040f4:	64e2                	ld	s1,24(sp)
    800040f6:	6942                	ld	s2,16(sp)
    800040f8:	69a2                	ld	s3,8(sp)
    800040fa:	6145                	addi	sp,sp,48
    800040fc:	8082                	ret
    panic("invalid file system");
    800040fe:	00004517          	auipc	a0,0x4
    80004102:	61a50513          	addi	a0,a0,1562 # 80008718 <syscalls+0x150>
    80004106:	ffffc097          	auipc	ra,0xffffc
    8000410a:	438080e7          	jalr	1080(ra) # 8000053e <panic>

000000008000410e <iinit>:
{
    8000410e:	7179                	addi	sp,sp,-48
    80004110:	f406                	sd	ra,40(sp)
    80004112:	f022                	sd	s0,32(sp)
    80004114:	ec26                	sd	s1,24(sp)
    80004116:	e84a                	sd	s2,16(sp)
    80004118:	e44e                	sd	s3,8(sp)
    8000411a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000411c:	00004597          	auipc	a1,0x4
    80004120:	61458593          	addi	a1,a1,1556 # 80008730 <syscalls+0x168>
    80004124:	0001c517          	auipc	a0,0x1c
    80004128:	fb450513          	addi	a0,a0,-76 # 800200d8 <itable>
    8000412c:	ffffd097          	auipc	ra,0xffffd
    80004130:	a28080e7          	jalr	-1496(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004134:	0001c497          	auipc	s1,0x1c
    80004138:	fcc48493          	addi	s1,s1,-52 # 80020100 <itable+0x28>
    8000413c:	0001e997          	auipc	s3,0x1e
    80004140:	a5498993          	addi	s3,s3,-1452 # 80021b90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004144:	00004917          	auipc	s2,0x4
    80004148:	5f490913          	addi	s2,s2,1524 # 80008738 <syscalls+0x170>
    8000414c:	85ca                	mv	a1,s2
    8000414e:	8526                	mv	a0,s1
    80004150:	00001097          	auipc	ra,0x1
    80004154:	e46080e7          	jalr	-442(ra) # 80004f96 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004158:	08848493          	addi	s1,s1,136
    8000415c:	ff3498e3          	bne	s1,s3,8000414c <iinit+0x3e>
}
    80004160:	70a2                	ld	ra,40(sp)
    80004162:	7402                	ld	s0,32(sp)
    80004164:	64e2                	ld	s1,24(sp)
    80004166:	6942                	ld	s2,16(sp)
    80004168:	69a2                	ld	s3,8(sp)
    8000416a:	6145                	addi	sp,sp,48
    8000416c:	8082                	ret

000000008000416e <ialloc>:
{
    8000416e:	715d                	addi	sp,sp,-80
    80004170:	e486                	sd	ra,72(sp)
    80004172:	e0a2                	sd	s0,64(sp)
    80004174:	fc26                	sd	s1,56(sp)
    80004176:	f84a                	sd	s2,48(sp)
    80004178:	f44e                	sd	s3,40(sp)
    8000417a:	f052                	sd	s4,32(sp)
    8000417c:	ec56                	sd	s5,24(sp)
    8000417e:	e85a                	sd	s6,16(sp)
    80004180:	e45e                	sd	s7,8(sp)
    80004182:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004184:	0001c717          	auipc	a4,0x1c
    80004188:	f4072703          	lw	a4,-192(a4) # 800200c4 <sb+0xc>
    8000418c:	4785                	li	a5,1
    8000418e:	04e7fa63          	bgeu	a5,a4,800041e2 <ialloc+0x74>
    80004192:	8aaa                	mv	s5,a0
    80004194:	8bae                	mv	s7,a1
    80004196:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004198:	0001ca17          	auipc	s4,0x1c
    8000419c:	f20a0a13          	addi	s4,s4,-224 # 800200b8 <sb>
    800041a0:	00048b1b          	sext.w	s6,s1
    800041a4:	0044d593          	srli	a1,s1,0x4
    800041a8:	018a2783          	lw	a5,24(s4)
    800041ac:	9dbd                	addw	a1,a1,a5
    800041ae:	8556                	mv	a0,s5
    800041b0:	00000097          	auipc	ra,0x0
    800041b4:	954080e7          	jalr	-1708(ra) # 80003b04 <bread>
    800041b8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800041ba:	05850993          	addi	s3,a0,88
    800041be:	00f4f793          	andi	a5,s1,15
    800041c2:	079a                	slli	a5,a5,0x6
    800041c4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800041c6:	00099783          	lh	a5,0(s3)
    800041ca:	c785                	beqz	a5,800041f2 <ialloc+0x84>
    brelse(bp);
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	a68080e7          	jalr	-1432(ra) # 80003c34 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800041d4:	0485                	addi	s1,s1,1
    800041d6:	00ca2703          	lw	a4,12(s4)
    800041da:	0004879b          	sext.w	a5,s1
    800041de:	fce7e1e3          	bltu	a5,a4,800041a0 <ialloc+0x32>
  panic("ialloc: no inodes");
    800041e2:	00004517          	auipc	a0,0x4
    800041e6:	55e50513          	addi	a0,a0,1374 # 80008740 <syscalls+0x178>
    800041ea:	ffffc097          	auipc	ra,0xffffc
    800041ee:	354080e7          	jalr	852(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800041f2:	04000613          	li	a2,64
    800041f6:	4581                	li	a1,0
    800041f8:	854e                	mv	a0,s3
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	af4080e7          	jalr	-1292(ra) # 80000cee <memset>
      dip->type = type;
    80004202:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004206:	854a                	mv	a0,s2
    80004208:	00001097          	auipc	ra,0x1
    8000420c:	ca8080e7          	jalr	-856(ra) # 80004eb0 <log_write>
      brelse(bp);
    80004210:	854a                	mv	a0,s2
    80004212:	00000097          	auipc	ra,0x0
    80004216:	a22080e7          	jalr	-1502(ra) # 80003c34 <brelse>
      return iget(dev, inum);
    8000421a:	85da                	mv	a1,s6
    8000421c:	8556                	mv	a0,s5
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	db4080e7          	jalr	-588(ra) # 80003fd2 <iget>
}
    80004226:	60a6                	ld	ra,72(sp)
    80004228:	6406                	ld	s0,64(sp)
    8000422a:	74e2                	ld	s1,56(sp)
    8000422c:	7942                	ld	s2,48(sp)
    8000422e:	79a2                	ld	s3,40(sp)
    80004230:	7a02                	ld	s4,32(sp)
    80004232:	6ae2                	ld	s5,24(sp)
    80004234:	6b42                	ld	s6,16(sp)
    80004236:	6ba2                	ld	s7,8(sp)
    80004238:	6161                	addi	sp,sp,80
    8000423a:	8082                	ret

000000008000423c <iupdate>:
{
    8000423c:	1101                	addi	sp,sp,-32
    8000423e:	ec06                	sd	ra,24(sp)
    80004240:	e822                	sd	s0,16(sp)
    80004242:	e426                	sd	s1,8(sp)
    80004244:	e04a                	sd	s2,0(sp)
    80004246:	1000                	addi	s0,sp,32
    80004248:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000424a:	415c                	lw	a5,4(a0)
    8000424c:	0047d79b          	srliw	a5,a5,0x4
    80004250:	0001c597          	auipc	a1,0x1c
    80004254:	e805a583          	lw	a1,-384(a1) # 800200d0 <sb+0x18>
    80004258:	9dbd                	addw	a1,a1,a5
    8000425a:	4108                	lw	a0,0(a0)
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	8a8080e7          	jalr	-1880(ra) # 80003b04 <bread>
    80004264:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004266:	05850793          	addi	a5,a0,88
    8000426a:	40c8                	lw	a0,4(s1)
    8000426c:	893d                	andi	a0,a0,15
    8000426e:	051a                	slli	a0,a0,0x6
    80004270:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004272:	04449703          	lh	a4,68(s1)
    80004276:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000427a:	04649703          	lh	a4,70(s1)
    8000427e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004282:	04849703          	lh	a4,72(s1)
    80004286:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000428a:	04a49703          	lh	a4,74(s1)
    8000428e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004292:	44f8                	lw	a4,76(s1)
    80004294:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004296:	03400613          	li	a2,52
    8000429a:	05048593          	addi	a1,s1,80
    8000429e:	0531                	addi	a0,a0,12
    800042a0:	ffffd097          	auipc	ra,0xffffd
    800042a4:	aae080e7          	jalr	-1362(ra) # 80000d4e <memmove>
  log_write(bp);
    800042a8:	854a                	mv	a0,s2
    800042aa:	00001097          	auipc	ra,0x1
    800042ae:	c06080e7          	jalr	-1018(ra) # 80004eb0 <log_write>
  brelse(bp);
    800042b2:	854a                	mv	a0,s2
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	980080e7          	jalr	-1664(ra) # 80003c34 <brelse>
}
    800042bc:	60e2                	ld	ra,24(sp)
    800042be:	6442                	ld	s0,16(sp)
    800042c0:	64a2                	ld	s1,8(sp)
    800042c2:	6902                	ld	s2,0(sp)
    800042c4:	6105                	addi	sp,sp,32
    800042c6:	8082                	ret

00000000800042c8 <idup>:
{
    800042c8:	1101                	addi	sp,sp,-32
    800042ca:	ec06                	sd	ra,24(sp)
    800042cc:	e822                	sd	s0,16(sp)
    800042ce:	e426                	sd	s1,8(sp)
    800042d0:	1000                	addi	s0,sp,32
    800042d2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800042d4:	0001c517          	auipc	a0,0x1c
    800042d8:	e0450513          	addi	a0,a0,-508 # 800200d8 <itable>
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	910080e7          	jalr	-1776(ra) # 80000bec <acquire>
  ip->ref++;
    800042e4:	449c                	lw	a5,8(s1)
    800042e6:	2785                	addiw	a5,a5,1
    800042e8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800042ea:	0001c517          	auipc	a0,0x1c
    800042ee:	dee50513          	addi	a0,a0,-530 # 800200d8 <itable>
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	9b4080e7          	jalr	-1612(ra) # 80000ca6 <release>
}
    800042fa:	8526                	mv	a0,s1
    800042fc:	60e2                	ld	ra,24(sp)
    800042fe:	6442                	ld	s0,16(sp)
    80004300:	64a2                	ld	s1,8(sp)
    80004302:	6105                	addi	sp,sp,32
    80004304:	8082                	ret

0000000080004306 <ilock>:
{
    80004306:	1101                	addi	sp,sp,-32
    80004308:	ec06                	sd	ra,24(sp)
    8000430a:	e822                	sd	s0,16(sp)
    8000430c:	e426                	sd	s1,8(sp)
    8000430e:	e04a                	sd	s2,0(sp)
    80004310:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004312:	c115                	beqz	a0,80004336 <ilock+0x30>
    80004314:	84aa                	mv	s1,a0
    80004316:	451c                	lw	a5,8(a0)
    80004318:	00f05f63          	blez	a5,80004336 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000431c:	0541                	addi	a0,a0,16
    8000431e:	00001097          	auipc	ra,0x1
    80004322:	cb2080e7          	jalr	-846(ra) # 80004fd0 <acquiresleep>
  if(ip->valid == 0){
    80004326:	40bc                	lw	a5,64(s1)
    80004328:	cf99                	beqz	a5,80004346 <ilock+0x40>
}
    8000432a:	60e2                	ld	ra,24(sp)
    8000432c:	6442                	ld	s0,16(sp)
    8000432e:	64a2                	ld	s1,8(sp)
    80004330:	6902                	ld	s2,0(sp)
    80004332:	6105                	addi	sp,sp,32
    80004334:	8082                	ret
    panic("ilock");
    80004336:	00004517          	auipc	a0,0x4
    8000433a:	42250513          	addi	a0,a0,1058 # 80008758 <syscalls+0x190>
    8000433e:	ffffc097          	auipc	ra,0xffffc
    80004342:	200080e7          	jalr	512(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004346:	40dc                	lw	a5,4(s1)
    80004348:	0047d79b          	srliw	a5,a5,0x4
    8000434c:	0001c597          	auipc	a1,0x1c
    80004350:	d845a583          	lw	a1,-636(a1) # 800200d0 <sb+0x18>
    80004354:	9dbd                	addw	a1,a1,a5
    80004356:	4088                	lw	a0,0(s1)
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	7ac080e7          	jalr	1964(ra) # 80003b04 <bread>
    80004360:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004362:	05850593          	addi	a1,a0,88
    80004366:	40dc                	lw	a5,4(s1)
    80004368:	8bbd                	andi	a5,a5,15
    8000436a:	079a                	slli	a5,a5,0x6
    8000436c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000436e:	00059783          	lh	a5,0(a1)
    80004372:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004376:	00259783          	lh	a5,2(a1)
    8000437a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000437e:	00459783          	lh	a5,4(a1)
    80004382:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004386:	00659783          	lh	a5,6(a1)
    8000438a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000438e:	459c                	lw	a5,8(a1)
    80004390:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004392:	03400613          	li	a2,52
    80004396:	05b1                	addi	a1,a1,12
    80004398:	05048513          	addi	a0,s1,80
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	9b2080e7          	jalr	-1614(ra) # 80000d4e <memmove>
    brelse(bp);
    800043a4:	854a                	mv	a0,s2
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	88e080e7          	jalr	-1906(ra) # 80003c34 <brelse>
    ip->valid = 1;
    800043ae:	4785                	li	a5,1
    800043b0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800043b2:	04449783          	lh	a5,68(s1)
    800043b6:	fbb5                	bnez	a5,8000432a <ilock+0x24>
      panic("ilock: no type");
    800043b8:	00004517          	auipc	a0,0x4
    800043bc:	3a850513          	addi	a0,a0,936 # 80008760 <syscalls+0x198>
    800043c0:	ffffc097          	auipc	ra,0xffffc
    800043c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800043c8 <iunlock>:
{
    800043c8:	1101                	addi	sp,sp,-32
    800043ca:	ec06                	sd	ra,24(sp)
    800043cc:	e822                	sd	s0,16(sp)
    800043ce:	e426                	sd	s1,8(sp)
    800043d0:	e04a                	sd	s2,0(sp)
    800043d2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800043d4:	c905                	beqz	a0,80004404 <iunlock+0x3c>
    800043d6:	84aa                	mv	s1,a0
    800043d8:	01050913          	addi	s2,a0,16
    800043dc:	854a                	mv	a0,s2
    800043de:	00001097          	auipc	ra,0x1
    800043e2:	c8c080e7          	jalr	-884(ra) # 8000506a <holdingsleep>
    800043e6:	cd19                	beqz	a0,80004404 <iunlock+0x3c>
    800043e8:	449c                	lw	a5,8(s1)
    800043ea:	00f05d63          	blez	a5,80004404 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800043ee:	854a                	mv	a0,s2
    800043f0:	00001097          	auipc	ra,0x1
    800043f4:	c36080e7          	jalr	-970(ra) # 80005026 <releasesleep>
}
    800043f8:	60e2                	ld	ra,24(sp)
    800043fa:	6442                	ld	s0,16(sp)
    800043fc:	64a2                	ld	s1,8(sp)
    800043fe:	6902                	ld	s2,0(sp)
    80004400:	6105                	addi	sp,sp,32
    80004402:	8082                	ret
    panic("iunlock");
    80004404:	00004517          	auipc	a0,0x4
    80004408:	36c50513          	addi	a0,a0,876 # 80008770 <syscalls+0x1a8>
    8000440c:	ffffc097          	auipc	ra,0xffffc
    80004410:	132080e7          	jalr	306(ra) # 8000053e <panic>

0000000080004414 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004414:	7179                	addi	sp,sp,-48
    80004416:	f406                	sd	ra,40(sp)
    80004418:	f022                	sd	s0,32(sp)
    8000441a:	ec26                	sd	s1,24(sp)
    8000441c:	e84a                	sd	s2,16(sp)
    8000441e:	e44e                	sd	s3,8(sp)
    80004420:	e052                	sd	s4,0(sp)
    80004422:	1800                	addi	s0,sp,48
    80004424:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004426:	05050493          	addi	s1,a0,80
    8000442a:	08050913          	addi	s2,a0,128
    8000442e:	a021                	j	80004436 <itrunc+0x22>
    80004430:	0491                	addi	s1,s1,4
    80004432:	01248d63          	beq	s1,s2,8000444c <itrunc+0x38>
    if(ip->addrs[i]){
    80004436:	408c                	lw	a1,0(s1)
    80004438:	dde5                	beqz	a1,80004430 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000443a:	0009a503          	lw	a0,0(s3)
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	90c080e7          	jalr	-1780(ra) # 80003d4a <bfree>
      ip->addrs[i] = 0;
    80004446:	0004a023          	sw	zero,0(s1)
    8000444a:	b7dd                	j	80004430 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000444c:	0809a583          	lw	a1,128(s3)
    80004450:	e185                	bnez	a1,80004470 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004452:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004456:	854e                	mv	a0,s3
    80004458:	00000097          	auipc	ra,0x0
    8000445c:	de4080e7          	jalr	-540(ra) # 8000423c <iupdate>
}
    80004460:	70a2                	ld	ra,40(sp)
    80004462:	7402                	ld	s0,32(sp)
    80004464:	64e2                	ld	s1,24(sp)
    80004466:	6942                	ld	s2,16(sp)
    80004468:	69a2                	ld	s3,8(sp)
    8000446a:	6a02                	ld	s4,0(sp)
    8000446c:	6145                	addi	sp,sp,48
    8000446e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004470:	0009a503          	lw	a0,0(s3)
    80004474:	fffff097          	auipc	ra,0xfffff
    80004478:	690080e7          	jalr	1680(ra) # 80003b04 <bread>
    8000447c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000447e:	05850493          	addi	s1,a0,88
    80004482:	45850913          	addi	s2,a0,1112
    80004486:	a811                	j	8000449a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004488:	0009a503          	lw	a0,0(s3)
    8000448c:	00000097          	auipc	ra,0x0
    80004490:	8be080e7          	jalr	-1858(ra) # 80003d4a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004494:	0491                	addi	s1,s1,4
    80004496:	01248563          	beq	s1,s2,800044a0 <itrunc+0x8c>
      if(a[j])
    8000449a:	408c                	lw	a1,0(s1)
    8000449c:	dde5                	beqz	a1,80004494 <itrunc+0x80>
    8000449e:	b7ed                	j	80004488 <itrunc+0x74>
    brelse(bp);
    800044a0:	8552                	mv	a0,s4
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	792080e7          	jalr	1938(ra) # 80003c34 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800044aa:	0809a583          	lw	a1,128(s3)
    800044ae:	0009a503          	lw	a0,0(s3)
    800044b2:	00000097          	auipc	ra,0x0
    800044b6:	898080e7          	jalr	-1896(ra) # 80003d4a <bfree>
    ip->addrs[NDIRECT] = 0;
    800044ba:	0809a023          	sw	zero,128(s3)
    800044be:	bf51                	j	80004452 <itrunc+0x3e>

00000000800044c0 <iput>:
{
    800044c0:	1101                	addi	sp,sp,-32
    800044c2:	ec06                	sd	ra,24(sp)
    800044c4:	e822                	sd	s0,16(sp)
    800044c6:	e426                	sd	s1,8(sp)
    800044c8:	e04a                	sd	s2,0(sp)
    800044ca:	1000                	addi	s0,sp,32
    800044cc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800044ce:	0001c517          	auipc	a0,0x1c
    800044d2:	c0a50513          	addi	a0,a0,-1014 # 800200d8 <itable>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	716080e7          	jalr	1814(ra) # 80000bec <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044de:	4498                	lw	a4,8(s1)
    800044e0:	4785                	li	a5,1
    800044e2:	02f70363          	beq	a4,a5,80004508 <iput+0x48>
  ip->ref--;
    800044e6:	449c                	lw	a5,8(s1)
    800044e8:	37fd                	addiw	a5,a5,-1
    800044ea:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800044ec:	0001c517          	auipc	a0,0x1c
    800044f0:	bec50513          	addi	a0,a0,-1044 # 800200d8 <itable>
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	7b2080e7          	jalr	1970(ra) # 80000ca6 <release>
}
    800044fc:	60e2                	ld	ra,24(sp)
    800044fe:	6442                	ld	s0,16(sp)
    80004500:	64a2                	ld	s1,8(sp)
    80004502:	6902                	ld	s2,0(sp)
    80004504:	6105                	addi	sp,sp,32
    80004506:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004508:	40bc                	lw	a5,64(s1)
    8000450a:	dff1                	beqz	a5,800044e6 <iput+0x26>
    8000450c:	04a49783          	lh	a5,74(s1)
    80004510:	fbf9                	bnez	a5,800044e6 <iput+0x26>
    acquiresleep(&ip->lock);
    80004512:	01048913          	addi	s2,s1,16
    80004516:	854a                	mv	a0,s2
    80004518:	00001097          	auipc	ra,0x1
    8000451c:	ab8080e7          	jalr	-1352(ra) # 80004fd0 <acquiresleep>
    release(&itable.lock);
    80004520:	0001c517          	auipc	a0,0x1c
    80004524:	bb850513          	addi	a0,a0,-1096 # 800200d8 <itable>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	77e080e7          	jalr	1918(ra) # 80000ca6 <release>
    itrunc(ip);
    80004530:	8526                	mv	a0,s1
    80004532:	00000097          	auipc	ra,0x0
    80004536:	ee2080e7          	jalr	-286(ra) # 80004414 <itrunc>
    ip->type = 0;
    8000453a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000453e:	8526                	mv	a0,s1
    80004540:	00000097          	auipc	ra,0x0
    80004544:	cfc080e7          	jalr	-772(ra) # 8000423c <iupdate>
    ip->valid = 0;
    80004548:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000454c:	854a                	mv	a0,s2
    8000454e:	00001097          	auipc	ra,0x1
    80004552:	ad8080e7          	jalr	-1320(ra) # 80005026 <releasesleep>
    acquire(&itable.lock);
    80004556:	0001c517          	auipc	a0,0x1c
    8000455a:	b8250513          	addi	a0,a0,-1150 # 800200d8 <itable>
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	68e080e7          	jalr	1678(ra) # 80000bec <acquire>
    80004566:	b741                	j	800044e6 <iput+0x26>

0000000080004568 <iunlockput>:
{
    80004568:	1101                	addi	sp,sp,-32
    8000456a:	ec06                	sd	ra,24(sp)
    8000456c:	e822                	sd	s0,16(sp)
    8000456e:	e426                	sd	s1,8(sp)
    80004570:	1000                	addi	s0,sp,32
    80004572:	84aa                	mv	s1,a0
  iunlock(ip);
    80004574:	00000097          	auipc	ra,0x0
    80004578:	e54080e7          	jalr	-428(ra) # 800043c8 <iunlock>
  iput(ip);
    8000457c:	8526                	mv	a0,s1
    8000457e:	00000097          	auipc	ra,0x0
    80004582:	f42080e7          	jalr	-190(ra) # 800044c0 <iput>
}
    80004586:	60e2                	ld	ra,24(sp)
    80004588:	6442                	ld	s0,16(sp)
    8000458a:	64a2                	ld	s1,8(sp)
    8000458c:	6105                	addi	sp,sp,32
    8000458e:	8082                	ret

0000000080004590 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004590:	1141                	addi	sp,sp,-16
    80004592:	e422                	sd	s0,8(sp)
    80004594:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004596:	411c                	lw	a5,0(a0)
    80004598:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000459a:	415c                	lw	a5,4(a0)
    8000459c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000459e:	04451783          	lh	a5,68(a0)
    800045a2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800045a6:	04a51783          	lh	a5,74(a0)
    800045aa:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800045ae:	04c56783          	lwu	a5,76(a0)
    800045b2:	e99c                	sd	a5,16(a1)
}
    800045b4:	6422                	ld	s0,8(sp)
    800045b6:	0141                	addi	sp,sp,16
    800045b8:	8082                	ret

00000000800045ba <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800045ba:	457c                	lw	a5,76(a0)
    800045bc:	0ed7e963          	bltu	a5,a3,800046ae <readi+0xf4>
{
    800045c0:	7159                	addi	sp,sp,-112
    800045c2:	f486                	sd	ra,104(sp)
    800045c4:	f0a2                	sd	s0,96(sp)
    800045c6:	eca6                	sd	s1,88(sp)
    800045c8:	e8ca                	sd	s2,80(sp)
    800045ca:	e4ce                	sd	s3,72(sp)
    800045cc:	e0d2                	sd	s4,64(sp)
    800045ce:	fc56                	sd	s5,56(sp)
    800045d0:	f85a                	sd	s6,48(sp)
    800045d2:	f45e                	sd	s7,40(sp)
    800045d4:	f062                	sd	s8,32(sp)
    800045d6:	ec66                	sd	s9,24(sp)
    800045d8:	e86a                	sd	s10,16(sp)
    800045da:	e46e                	sd	s11,8(sp)
    800045dc:	1880                	addi	s0,sp,112
    800045de:	8baa                	mv	s7,a0
    800045e0:	8c2e                	mv	s8,a1
    800045e2:	8ab2                	mv	s5,a2
    800045e4:	84b6                	mv	s1,a3
    800045e6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800045e8:	9f35                	addw	a4,a4,a3
    return 0;
    800045ea:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800045ec:	0ad76063          	bltu	a4,a3,8000468c <readi+0xd2>
  if(off + n > ip->size)
    800045f0:	00e7f463          	bgeu	a5,a4,800045f8 <readi+0x3e>
    n = ip->size - off;
    800045f4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045f8:	0a0b0963          	beqz	s6,800046aa <readi+0xf0>
    800045fc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800045fe:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004602:	5cfd                	li	s9,-1
    80004604:	a82d                	j	8000463e <readi+0x84>
    80004606:	020a1d93          	slli	s11,s4,0x20
    8000460a:	020ddd93          	srli	s11,s11,0x20
    8000460e:	05890613          	addi	a2,s2,88
    80004612:	86ee                	mv	a3,s11
    80004614:	963a                	add	a2,a2,a4
    80004616:	85d6                	mv	a1,s5
    80004618:	8562                	mv	a0,s8
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	ae4080e7          	jalr	-1308(ra) # 800030fe <either_copyout>
    80004622:	05950d63          	beq	a0,s9,8000467c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004626:	854a                	mv	a0,s2
    80004628:	fffff097          	auipc	ra,0xfffff
    8000462c:	60c080e7          	jalr	1548(ra) # 80003c34 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004630:	013a09bb          	addw	s3,s4,s3
    80004634:	009a04bb          	addw	s1,s4,s1
    80004638:	9aee                	add	s5,s5,s11
    8000463a:	0569f763          	bgeu	s3,s6,80004688 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000463e:	000ba903          	lw	s2,0(s7)
    80004642:	00a4d59b          	srliw	a1,s1,0xa
    80004646:	855e                	mv	a0,s7
    80004648:	00000097          	auipc	ra,0x0
    8000464c:	8b0080e7          	jalr	-1872(ra) # 80003ef8 <bmap>
    80004650:	0005059b          	sext.w	a1,a0
    80004654:	854a                	mv	a0,s2
    80004656:	fffff097          	auipc	ra,0xfffff
    8000465a:	4ae080e7          	jalr	1198(ra) # 80003b04 <bread>
    8000465e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004660:	3ff4f713          	andi	a4,s1,1023
    80004664:	40ed07bb          	subw	a5,s10,a4
    80004668:	413b06bb          	subw	a3,s6,s3
    8000466c:	8a3e                	mv	s4,a5
    8000466e:	2781                	sext.w	a5,a5
    80004670:	0006861b          	sext.w	a2,a3
    80004674:	f8f679e3          	bgeu	a2,a5,80004606 <readi+0x4c>
    80004678:	8a36                	mv	s4,a3
    8000467a:	b771                	j	80004606 <readi+0x4c>
      brelse(bp);
    8000467c:	854a                	mv	a0,s2
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	5b6080e7          	jalr	1462(ra) # 80003c34 <brelse>
      tot = -1;
    80004686:	59fd                	li	s3,-1
  }
  return tot;
    80004688:	0009851b          	sext.w	a0,s3
}
    8000468c:	70a6                	ld	ra,104(sp)
    8000468e:	7406                	ld	s0,96(sp)
    80004690:	64e6                	ld	s1,88(sp)
    80004692:	6946                	ld	s2,80(sp)
    80004694:	69a6                	ld	s3,72(sp)
    80004696:	6a06                	ld	s4,64(sp)
    80004698:	7ae2                	ld	s5,56(sp)
    8000469a:	7b42                	ld	s6,48(sp)
    8000469c:	7ba2                	ld	s7,40(sp)
    8000469e:	7c02                	ld	s8,32(sp)
    800046a0:	6ce2                	ld	s9,24(sp)
    800046a2:	6d42                	ld	s10,16(sp)
    800046a4:	6da2                	ld	s11,8(sp)
    800046a6:	6165                	addi	sp,sp,112
    800046a8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800046aa:	89da                	mv	s3,s6
    800046ac:	bff1                	j	80004688 <readi+0xce>
    return 0;
    800046ae:	4501                	li	a0,0
}
    800046b0:	8082                	ret

00000000800046b2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800046b2:	457c                	lw	a5,76(a0)
    800046b4:	10d7e863          	bltu	a5,a3,800047c4 <writei+0x112>
{
    800046b8:	7159                	addi	sp,sp,-112
    800046ba:	f486                	sd	ra,104(sp)
    800046bc:	f0a2                	sd	s0,96(sp)
    800046be:	eca6                	sd	s1,88(sp)
    800046c0:	e8ca                	sd	s2,80(sp)
    800046c2:	e4ce                	sd	s3,72(sp)
    800046c4:	e0d2                	sd	s4,64(sp)
    800046c6:	fc56                	sd	s5,56(sp)
    800046c8:	f85a                	sd	s6,48(sp)
    800046ca:	f45e                	sd	s7,40(sp)
    800046cc:	f062                	sd	s8,32(sp)
    800046ce:	ec66                	sd	s9,24(sp)
    800046d0:	e86a                	sd	s10,16(sp)
    800046d2:	e46e                	sd	s11,8(sp)
    800046d4:	1880                	addi	s0,sp,112
    800046d6:	8b2a                	mv	s6,a0
    800046d8:	8c2e                	mv	s8,a1
    800046da:	8ab2                	mv	s5,a2
    800046dc:	8936                	mv	s2,a3
    800046de:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800046e0:	00e687bb          	addw	a5,a3,a4
    800046e4:	0ed7e263          	bltu	a5,a3,800047c8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800046e8:	00043737          	lui	a4,0x43
    800046ec:	0ef76063          	bltu	a4,a5,800047cc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046f0:	0c0b8863          	beqz	s7,800047c0 <writei+0x10e>
    800046f4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800046f6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800046fa:	5cfd                	li	s9,-1
    800046fc:	a091                	j	80004740 <writei+0x8e>
    800046fe:	02099d93          	slli	s11,s3,0x20
    80004702:	020ddd93          	srli	s11,s11,0x20
    80004706:	05848513          	addi	a0,s1,88
    8000470a:	86ee                	mv	a3,s11
    8000470c:	8656                	mv	a2,s5
    8000470e:	85e2                	mv	a1,s8
    80004710:	953a                	add	a0,a0,a4
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	a42080e7          	jalr	-1470(ra) # 80003154 <either_copyin>
    8000471a:	07950263          	beq	a0,s9,8000477e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000471e:	8526                	mv	a0,s1
    80004720:	00000097          	auipc	ra,0x0
    80004724:	790080e7          	jalr	1936(ra) # 80004eb0 <log_write>
    brelse(bp);
    80004728:	8526                	mv	a0,s1
    8000472a:	fffff097          	auipc	ra,0xfffff
    8000472e:	50a080e7          	jalr	1290(ra) # 80003c34 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004732:	01498a3b          	addw	s4,s3,s4
    80004736:	0129893b          	addw	s2,s3,s2
    8000473a:	9aee                	add	s5,s5,s11
    8000473c:	057a7663          	bgeu	s4,s7,80004788 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004740:	000b2483          	lw	s1,0(s6)
    80004744:	00a9559b          	srliw	a1,s2,0xa
    80004748:	855a                	mv	a0,s6
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	7ae080e7          	jalr	1966(ra) # 80003ef8 <bmap>
    80004752:	0005059b          	sext.w	a1,a0
    80004756:	8526                	mv	a0,s1
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	3ac080e7          	jalr	940(ra) # 80003b04 <bread>
    80004760:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004762:	3ff97713          	andi	a4,s2,1023
    80004766:	40ed07bb          	subw	a5,s10,a4
    8000476a:	414b86bb          	subw	a3,s7,s4
    8000476e:	89be                	mv	s3,a5
    80004770:	2781                	sext.w	a5,a5
    80004772:	0006861b          	sext.w	a2,a3
    80004776:	f8f674e3          	bgeu	a2,a5,800046fe <writei+0x4c>
    8000477a:	89b6                	mv	s3,a3
    8000477c:	b749                	j	800046fe <writei+0x4c>
      brelse(bp);
    8000477e:	8526                	mv	a0,s1
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	4b4080e7          	jalr	1204(ra) # 80003c34 <brelse>
  }

  if(off > ip->size)
    80004788:	04cb2783          	lw	a5,76(s6)
    8000478c:	0127f463          	bgeu	a5,s2,80004794 <writei+0xe2>
    ip->size = off;
    80004790:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004794:	855a                	mv	a0,s6
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	aa6080e7          	jalr	-1370(ra) # 8000423c <iupdate>

  return tot;
    8000479e:	000a051b          	sext.w	a0,s4
}
    800047a2:	70a6                	ld	ra,104(sp)
    800047a4:	7406                	ld	s0,96(sp)
    800047a6:	64e6                	ld	s1,88(sp)
    800047a8:	6946                	ld	s2,80(sp)
    800047aa:	69a6                	ld	s3,72(sp)
    800047ac:	6a06                	ld	s4,64(sp)
    800047ae:	7ae2                	ld	s5,56(sp)
    800047b0:	7b42                	ld	s6,48(sp)
    800047b2:	7ba2                	ld	s7,40(sp)
    800047b4:	7c02                	ld	s8,32(sp)
    800047b6:	6ce2                	ld	s9,24(sp)
    800047b8:	6d42                	ld	s10,16(sp)
    800047ba:	6da2                	ld	s11,8(sp)
    800047bc:	6165                	addi	sp,sp,112
    800047be:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800047c0:	8a5e                	mv	s4,s7
    800047c2:	bfc9                	j	80004794 <writei+0xe2>
    return -1;
    800047c4:	557d                	li	a0,-1
}
    800047c6:	8082                	ret
    return -1;
    800047c8:	557d                	li	a0,-1
    800047ca:	bfe1                	j	800047a2 <writei+0xf0>
    return -1;
    800047cc:	557d                	li	a0,-1
    800047ce:	bfd1                	j	800047a2 <writei+0xf0>

00000000800047d0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800047d0:	1141                	addi	sp,sp,-16
    800047d2:	e406                	sd	ra,8(sp)
    800047d4:	e022                	sd	s0,0(sp)
    800047d6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800047d8:	4639                	li	a2,14
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	5ec080e7          	jalr	1516(ra) # 80000dc6 <strncmp>
}
    800047e2:	60a2                	ld	ra,8(sp)
    800047e4:	6402                	ld	s0,0(sp)
    800047e6:	0141                	addi	sp,sp,16
    800047e8:	8082                	ret

00000000800047ea <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800047ea:	7139                	addi	sp,sp,-64
    800047ec:	fc06                	sd	ra,56(sp)
    800047ee:	f822                	sd	s0,48(sp)
    800047f0:	f426                	sd	s1,40(sp)
    800047f2:	f04a                	sd	s2,32(sp)
    800047f4:	ec4e                	sd	s3,24(sp)
    800047f6:	e852                	sd	s4,16(sp)
    800047f8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800047fa:	04451703          	lh	a4,68(a0)
    800047fe:	4785                	li	a5,1
    80004800:	00f71a63          	bne	a4,a5,80004814 <dirlookup+0x2a>
    80004804:	892a                	mv	s2,a0
    80004806:	89ae                	mv	s3,a1
    80004808:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000480a:	457c                	lw	a5,76(a0)
    8000480c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000480e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004810:	e79d                	bnez	a5,8000483e <dirlookup+0x54>
    80004812:	a8a5                	j	8000488a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004814:	00004517          	auipc	a0,0x4
    80004818:	f6450513          	addi	a0,a0,-156 # 80008778 <syscalls+0x1b0>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	d22080e7          	jalr	-734(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004824:	00004517          	auipc	a0,0x4
    80004828:	f6c50513          	addi	a0,a0,-148 # 80008790 <syscalls+0x1c8>
    8000482c:	ffffc097          	auipc	ra,0xffffc
    80004830:	d12080e7          	jalr	-750(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004834:	24c1                	addiw	s1,s1,16
    80004836:	04c92783          	lw	a5,76(s2)
    8000483a:	04f4f763          	bgeu	s1,a5,80004888 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000483e:	4741                	li	a4,16
    80004840:	86a6                	mv	a3,s1
    80004842:	fc040613          	addi	a2,s0,-64
    80004846:	4581                	li	a1,0
    80004848:	854a                	mv	a0,s2
    8000484a:	00000097          	auipc	ra,0x0
    8000484e:	d70080e7          	jalr	-656(ra) # 800045ba <readi>
    80004852:	47c1                	li	a5,16
    80004854:	fcf518e3          	bne	a0,a5,80004824 <dirlookup+0x3a>
    if(de.inum == 0)
    80004858:	fc045783          	lhu	a5,-64(s0)
    8000485c:	dfe1                	beqz	a5,80004834 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000485e:	fc240593          	addi	a1,s0,-62
    80004862:	854e                	mv	a0,s3
    80004864:	00000097          	auipc	ra,0x0
    80004868:	f6c080e7          	jalr	-148(ra) # 800047d0 <namecmp>
    8000486c:	f561                	bnez	a0,80004834 <dirlookup+0x4a>
      if(poff)
    8000486e:	000a0463          	beqz	s4,80004876 <dirlookup+0x8c>
        *poff = off;
    80004872:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004876:	fc045583          	lhu	a1,-64(s0)
    8000487a:	00092503          	lw	a0,0(s2)
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	754080e7          	jalr	1876(ra) # 80003fd2 <iget>
    80004886:	a011                	j	8000488a <dirlookup+0xa0>
  return 0;
    80004888:	4501                	li	a0,0
}
    8000488a:	70e2                	ld	ra,56(sp)
    8000488c:	7442                	ld	s0,48(sp)
    8000488e:	74a2                	ld	s1,40(sp)
    80004890:	7902                	ld	s2,32(sp)
    80004892:	69e2                	ld	s3,24(sp)
    80004894:	6a42                	ld	s4,16(sp)
    80004896:	6121                	addi	sp,sp,64
    80004898:	8082                	ret

000000008000489a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000489a:	711d                	addi	sp,sp,-96
    8000489c:	ec86                	sd	ra,88(sp)
    8000489e:	e8a2                	sd	s0,80(sp)
    800048a0:	e4a6                	sd	s1,72(sp)
    800048a2:	e0ca                	sd	s2,64(sp)
    800048a4:	fc4e                	sd	s3,56(sp)
    800048a6:	f852                	sd	s4,48(sp)
    800048a8:	f456                	sd	s5,40(sp)
    800048aa:	f05a                	sd	s6,32(sp)
    800048ac:	ec5e                	sd	s7,24(sp)
    800048ae:	e862                	sd	s8,16(sp)
    800048b0:	e466                	sd	s9,8(sp)
    800048b2:	1080                	addi	s0,sp,96
    800048b4:	84aa                	mv	s1,a0
    800048b6:	8b2e                	mv	s6,a1
    800048b8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800048ba:	00054703          	lbu	a4,0(a0)
    800048be:	02f00793          	li	a5,47
    800048c2:	02f70363          	beq	a4,a5,800048e8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800048c6:	ffffd097          	auipc	ra,0xffffd
    800048ca:	4de080e7          	jalr	1246(ra) # 80001da4 <myproc>
    800048ce:	17853503          	ld	a0,376(a0)
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	9f6080e7          	jalr	-1546(ra) # 800042c8 <idup>
    800048da:	89aa                	mv	s3,a0
  while(*path == '/')
    800048dc:	02f00913          	li	s2,47
  len = path - s;
    800048e0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800048e2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800048e4:	4c05                	li	s8,1
    800048e6:	a865                	j	8000499e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800048e8:	4585                	li	a1,1
    800048ea:	4505                	li	a0,1
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	6e6080e7          	jalr	1766(ra) # 80003fd2 <iget>
    800048f4:	89aa                	mv	s3,a0
    800048f6:	b7dd                	j	800048dc <namex+0x42>
      iunlockput(ip);
    800048f8:	854e                	mv	a0,s3
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	c6e080e7          	jalr	-914(ra) # 80004568 <iunlockput>
      return 0;
    80004902:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004904:	854e                	mv	a0,s3
    80004906:	60e6                	ld	ra,88(sp)
    80004908:	6446                	ld	s0,80(sp)
    8000490a:	64a6                	ld	s1,72(sp)
    8000490c:	6906                	ld	s2,64(sp)
    8000490e:	79e2                	ld	s3,56(sp)
    80004910:	7a42                	ld	s4,48(sp)
    80004912:	7aa2                	ld	s5,40(sp)
    80004914:	7b02                	ld	s6,32(sp)
    80004916:	6be2                	ld	s7,24(sp)
    80004918:	6c42                	ld	s8,16(sp)
    8000491a:	6ca2                	ld	s9,8(sp)
    8000491c:	6125                	addi	sp,sp,96
    8000491e:	8082                	ret
      iunlock(ip);
    80004920:	854e                	mv	a0,s3
    80004922:	00000097          	auipc	ra,0x0
    80004926:	aa6080e7          	jalr	-1370(ra) # 800043c8 <iunlock>
      return ip;
    8000492a:	bfe9                	j	80004904 <namex+0x6a>
      iunlockput(ip);
    8000492c:	854e                	mv	a0,s3
    8000492e:	00000097          	auipc	ra,0x0
    80004932:	c3a080e7          	jalr	-966(ra) # 80004568 <iunlockput>
      return 0;
    80004936:	89d2                	mv	s3,s4
    80004938:	b7f1                	j	80004904 <namex+0x6a>
  len = path - s;
    8000493a:	40b48633          	sub	a2,s1,a1
    8000493e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004942:	094cd463          	bge	s9,s4,800049ca <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004946:	4639                	li	a2,14
    80004948:	8556                	mv	a0,s5
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	404080e7          	jalr	1028(ra) # 80000d4e <memmove>
  while(*path == '/')
    80004952:	0004c783          	lbu	a5,0(s1)
    80004956:	01279763          	bne	a5,s2,80004964 <namex+0xca>
    path++;
    8000495a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000495c:	0004c783          	lbu	a5,0(s1)
    80004960:	ff278de3          	beq	a5,s2,8000495a <namex+0xc0>
    ilock(ip);
    80004964:	854e                	mv	a0,s3
    80004966:	00000097          	auipc	ra,0x0
    8000496a:	9a0080e7          	jalr	-1632(ra) # 80004306 <ilock>
    if(ip->type != T_DIR){
    8000496e:	04499783          	lh	a5,68(s3)
    80004972:	f98793e3          	bne	a5,s8,800048f8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004976:	000b0563          	beqz	s6,80004980 <namex+0xe6>
    8000497a:	0004c783          	lbu	a5,0(s1)
    8000497e:	d3cd                	beqz	a5,80004920 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004980:	865e                	mv	a2,s7
    80004982:	85d6                	mv	a1,s5
    80004984:	854e                	mv	a0,s3
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	e64080e7          	jalr	-412(ra) # 800047ea <dirlookup>
    8000498e:	8a2a                	mv	s4,a0
    80004990:	dd51                	beqz	a0,8000492c <namex+0x92>
    iunlockput(ip);
    80004992:	854e                	mv	a0,s3
    80004994:	00000097          	auipc	ra,0x0
    80004998:	bd4080e7          	jalr	-1068(ra) # 80004568 <iunlockput>
    ip = next;
    8000499c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000499e:	0004c783          	lbu	a5,0(s1)
    800049a2:	05279763          	bne	a5,s2,800049f0 <namex+0x156>
    path++;
    800049a6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800049a8:	0004c783          	lbu	a5,0(s1)
    800049ac:	ff278de3          	beq	a5,s2,800049a6 <namex+0x10c>
  if(*path == 0)
    800049b0:	c79d                	beqz	a5,800049de <namex+0x144>
    path++;
    800049b2:	85a6                	mv	a1,s1
  len = path - s;
    800049b4:	8a5e                	mv	s4,s7
    800049b6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800049b8:	01278963          	beq	a5,s2,800049ca <namex+0x130>
    800049bc:	dfbd                	beqz	a5,8000493a <namex+0xa0>
    path++;
    800049be:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800049c0:	0004c783          	lbu	a5,0(s1)
    800049c4:	ff279ce3          	bne	a5,s2,800049bc <namex+0x122>
    800049c8:	bf8d                	j	8000493a <namex+0xa0>
    memmove(name, s, len);
    800049ca:	2601                	sext.w	a2,a2
    800049cc:	8556                	mv	a0,s5
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	380080e7          	jalr	896(ra) # 80000d4e <memmove>
    name[len] = 0;
    800049d6:	9a56                	add	s4,s4,s5
    800049d8:	000a0023          	sb	zero,0(s4)
    800049dc:	bf9d                	j	80004952 <namex+0xb8>
  if(nameiparent){
    800049de:	f20b03e3          	beqz	s6,80004904 <namex+0x6a>
    iput(ip);
    800049e2:	854e                	mv	a0,s3
    800049e4:	00000097          	auipc	ra,0x0
    800049e8:	adc080e7          	jalr	-1316(ra) # 800044c0 <iput>
    return 0;
    800049ec:	4981                	li	s3,0
    800049ee:	bf19                	j	80004904 <namex+0x6a>
  if(*path == 0)
    800049f0:	d7fd                	beqz	a5,800049de <namex+0x144>
  while(*path != '/' && *path != 0)
    800049f2:	0004c783          	lbu	a5,0(s1)
    800049f6:	85a6                	mv	a1,s1
    800049f8:	b7d1                	j	800049bc <namex+0x122>

00000000800049fa <dirlink>:
{
    800049fa:	7139                	addi	sp,sp,-64
    800049fc:	fc06                	sd	ra,56(sp)
    800049fe:	f822                	sd	s0,48(sp)
    80004a00:	f426                	sd	s1,40(sp)
    80004a02:	f04a                	sd	s2,32(sp)
    80004a04:	ec4e                	sd	s3,24(sp)
    80004a06:	e852                	sd	s4,16(sp)
    80004a08:	0080                	addi	s0,sp,64
    80004a0a:	892a                	mv	s2,a0
    80004a0c:	8a2e                	mv	s4,a1
    80004a0e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a10:	4601                	li	a2,0
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	dd8080e7          	jalr	-552(ra) # 800047ea <dirlookup>
    80004a1a:	e93d                	bnez	a0,80004a90 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a1c:	04c92483          	lw	s1,76(s2)
    80004a20:	c49d                	beqz	s1,80004a4e <dirlink+0x54>
    80004a22:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a24:	4741                	li	a4,16
    80004a26:	86a6                	mv	a3,s1
    80004a28:	fc040613          	addi	a2,s0,-64
    80004a2c:	4581                	li	a1,0
    80004a2e:	854a                	mv	a0,s2
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	b8a080e7          	jalr	-1142(ra) # 800045ba <readi>
    80004a38:	47c1                	li	a5,16
    80004a3a:	06f51163          	bne	a0,a5,80004a9c <dirlink+0xa2>
    if(de.inum == 0)
    80004a3e:	fc045783          	lhu	a5,-64(s0)
    80004a42:	c791                	beqz	a5,80004a4e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a44:	24c1                	addiw	s1,s1,16
    80004a46:	04c92783          	lw	a5,76(s2)
    80004a4a:	fcf4ede3          	bltu	s1,a5,80004a24 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004a4e:	4639                	li	a2,14
    80004a50:	85d2                	mv	a1,s4
    80004a52:	fc240513          	addi	a0,s0,-62
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	3ac080e7          	jalr	940(ra) # 80000e02 <strncpy>
  de.inum = inum;
    80004a5e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a62:	4741                	li	a4,16
    80004a64:	86a6                	mv	a3,s1
    80004a66:	fc040613          	addi	a2,s0,-64
    80004a6a:	4581                	li	a1,0
    80004a6c:	854a                	mv	a0,s2
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	c44080e7          	jalr	-956(ra) # 800046b2 <writei>
    80004a76:	872a                	mv	a4,a0
    80004a78:	47c1                	li	a5,16
  return 0;
    80004a7a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a7c:	02f71863          	bne	a4,a5,80004aac <dirlink+0xb2>
}
    80004a80:	70e2                	ld	ra,56(sp)
    80004a82:	7442                	ld	s0,48(sp)
    80004a84:	74a2                	ld	s1,40(sp)
    80004a86:	7902                	ld	s2,32(sp)
    80004a88:	69e2                	ld	s3,24(sp)
    80004a8a:	6a42                	ld	s4,16(sp)
    80004a8c:	6121                	addi	sp,sp,64
    80004a8e:	8082                	ret
    iput(ip);
    80004a90:	00000097          	auipc	ra,0x0
    80004a94:	a30080e7          	jalr	-1488(ra) # 800044c0 <iput>
    return -1;
    80004a98:	557d                	li	a0,-1
    80004a9a:	b7dd                	j	80004a80 <dirlink+0x86>
      panic("dirlink read");
    80004a9c:	00004517          	auipc	a0,0x4
    80004aa0:	d0450513          	addi	a0,a0,-764 # 800087a0 <syscalls+0x1d8>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	a9a080e7          	jalr	-1382(ra) # 8000053e <panic>
    panic("dirlink");
    80004aac:	00004517          	auipc	a0,0x4
    80004ab0:	e0450513          	addi	a0,a0,-508 # 800088b0 <syscalls+0x2e8>
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	a8a080e7          	jalr	-1398(ra) # 8000053e <panic>

0000000080004abc <namei>:

struct inode*
namei(char *path)
{
    80004abc:	1101                	addi	sp,sp,-32
    80004abe:	ec06                	sd	ra,24(sp)
    80004ac0:	e822                	sd	s0,16(sp)
    80004ac2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004ac4:	fe040613          	addi	a2,s0,-32
    80004ac8:	4581                	li	a1,0
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	dd0080e7          	jalr	-560(ra) # 8000489a <namex>
}
    80004ad2:	60e2                	ld	ra,24(sp)
    80004ad4:	6442                	ld	s0,16(sp)
    80004ad6:	6105                	addi	sp,sp,32
    80004ad8:	8082                	ret

0000000080004ada <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004ada:	1141                	addi	sp,sp,-16
    80004adc:	e406                	sd	ra,8(sp)
    80004ade:	e022                	sd	s0,0(sp)
    80004ae0:	0800                	addi	s0,sp,16
    80004ae2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004ae4:	4585                	li	a1,1
    80004ae6:	00000097          	auipc	ra,0x0
    80004aea:	db4080e7          	jalr	-588(ra) # 8000489a <namex>
}
    80004aee:	60a2                	ld	ra,8(sp)
    80004af0:	6402                	ld	s0,0(sp)
    80004af2:	0141                	addi	sp,sp,16
    80004af4:	8082                	ret

0000000080004af6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004af6:	1101                	addi	sp,sp,-32
    80004af8:	ec06                	sd	ra,24(sp)
    80004afa:	e822                	sd	s0,16(sp)
    80004afc:	e426                	sd	s1,8(sp)
    80004afe:	e04a                	sd	s2,0(sp)
    80004b00:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004b02:	0001d917          	auipc	s2,0x1d
    80004b06:	07e90913          	addi	s2,s2,126 # 80021b80 <log>
    80004b0a:	01892583          	lw	a1,24(s2)
    80004b0e:	02892503          	lw	a0,40(s2)
    80004b12:	fffff097          	auipc	ra,0xfffff
    80004b16:	ff2080e7          	jalr	-14(ra) # 80003b04 <bread>
    80004b1a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004b1c:	02c92683          	lw	a3,44(s2)
    80004b20:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004b22:	02d05763          	blez	a3,80004b50 <write_head+0x5a>
    80004b26:	0001d797          	auipc	a5,0x1d
    80004b2a:	08a78793          	addi	a5,a5,138 # 80021bb0 <log+0x30>
    80004b2e:	05c50713          	addi	a4,a0,92
    80004b32:	36fd                	addiw	a3,a3,-1
    80004b34:	1682                	slli	a3,a3,0x20
    80004b36:	9281                	srli	a3,a3,0x20
    80004b38:	068a                	slli	a3,a3,0x2
    80004b3a:	0001d617          	auipc	a2,0x1d
    80004b3e:	07a60613          	addi	a2,a2,122 # 80021bb4 <log+0x34>
    80004b42:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004b44:	4390                	lw	a2,0(a5)
    80004b46:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b48:	0791                	addi	a5,a5,4
    80004b4a:	0711                	addi	a4,a4,4
    80004b4c:	fed79ce3          	bne	a5,a3,80004b44 <write_head+0x4e>
  }
  bwrite(buf);
    80004b50:	8526                	mv	a0,s1
    80004b52:	fffff097          	auipc	ra,0xfffff
    80004b56:	0a4080e7          	jalr	164(ra) # 80003bf6 <bwrite>
  brelse(buf);
    80004b5a:	8526                	mv	a0,s1
    80004b5c:	fffff097          	auipc	ra,0xfffff
    80004b60:	0d8080e7          	jalr	216(ra) # 80003c34 <brelse>
}
    80004b64:	60e2                	ld	ra,24(sp)
    80004b66:	6442                	ld	s0,16(sp)
    80004b68:	64a2                	ld	s1,8(sp)
    80004b6a:	6902                	ld	s2,0(sp)
    80004b6c:	6105                	addi	sp,sp,32
    80004b6e:	8082                	ret

0000000080004b70 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b70:	0001d797          	auipc	a5,0x1d
    80004b74:	03c7a783          	lw	a5,60(a5) # 80021bac <log+0x2c>
    80004b78:	0af05d63          	blez	a5,80004c32 <install_trans+0xc2>
{
    80004b7c:	7139                	addi	sp,sp,-64
    80004b7e:	fc06                	sd	ra,56(sp)
    80004b80:	f822                	sd	s0,48(sp)
    80004b82:	f426                	sd	s1,40(sp)
    80004b84:	f04a                	sd	s2,32(sp)
    80004b86:	ec4e                	sd	s3,24(sp)
    80004b88:	e852                	sd	s4,16(sp)
    80004b8a:	e456                	sd	s5,8(sp)
    80004b8c:	e05a                	sd	s6,0(sp)
    80004b8e:	0080                	addi	s0,sp,64
    80004b90:	8b2a                	mv	s6,a0
    80004b92:	0001da97          	auipc	s5,0x1d
    80004b96:	01ea8a93          	addi	s5,s5,30 # 80021bb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b9a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b9c:	0001d997          	auipc	s3,0x1d
    80004ba0:	fe498993          	addi	s3,s3,-28 # 80021b80 <log>
    80004ba4:	a035                	j	80004bd0 <install_trans+0x60>
      bunpin(dbuf);
    80004ba6:	8526                	mv	a0,s1
    80004ba8:	fffff097          	auipc	ra,0xfffff
    80004bac:	166080e7          	jalr	358(ra) # 80003d0e <bunpin>
    brelse(lbuf);
    80004bb0:	854a                	mv	a0,s2
    80004bb2:	fffff097          	auipc	ra,0xfffff
    80004bb6:	082080e7          	jalr	130(ra) # 80003c34 <brelse>
    brelse(dbuf);
    80004bba:	8526                	mv	a0,s1
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	078080e7          	jalr	120(ra) # 80003c34 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bc4:	2a05                	addiw	s4,s4,1
    80004bc6:	0a91                	addi	s5,s5,4
    80004bc8:	02c9a783          	lw	a5,44(s3)
    80004bcc:	04fa5963          	bge	s4,a5,80004c1e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004bd0:	0189a583          	lw	a1,24(s3)
    80004bd4:	014585bb          	addw	a1,a1,s4
    80004bd8:	2585                	addiw	a1,a1,1
    80004bda:	0289a503          	lw	a0,40(s3)
    80004bde:	fffff097          	auipc	ra,0xfffff
    80004be2:	f26080e7          	jalr	-218(ra) # 80003b04 <bread>
    80004be6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004be8:	000aa583          	lw	a1,0(s5)
    80004bec:	0289a503          	lw	a0,40(s3)
    80004bf0:	fffff097          	auipc	ra,0xfffff
    80004bf4:	f14080e7          	jalr	-236(ra) # 80003b04 <bread>
    80004bf8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004bfa:	40000613          	li	a2,1024
    80004bfe:	05890593          	addi	a1,s2,88
    80004c02:	05850513          	addi	a0,a0,88
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	148080e7          	jalr	328(ra) # 80000d4e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004c0e:	8526                	mv	a0,s1
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	fe6080e7          	jalr	-26(ra) # 80003bf6 <bwrite>
    if(recovering == 0)
    80004c18:	f80b1ce3          	bnez	s6,80004bb0 <install_trans+0x40>
    80004c1c:	b769                	j	80004ba6 <install_trans+0x36>
}
    80004c1e:	70e2                	ld	ra,56(sp)
    80004c20:	7442                	ld	s0,48(sp)
    80004c22:	74a2                	ld	s1,40(sp)
    80004c24:	7902                	ld	s2,32(sp)
    80004c26:	69e2                	ld	s3,24(sp)
    80004c28:	6a42                	ld	s4,16(sp)
    80004c2a:	6aa2                	ld	s5,8(sp)
    80004c2c:	6b02                	ld	s6,0(sp)
    80004c2e:	6121                	addi	sp,sp,64
    80004c30:	8082                	ret
    80004c32:	8082                	ret

0000000080004c34 <initlog>:
{
    80004c34:	7179                	addi	sp,sp,-48
    80004c36:	f406                	sd	ra,40(sp)
    80004c38:	f022                	sd	s0,32(sp)
    80004c3a:	ec26                	sd	s1,24(sp)
    80004c3c:	e84a                	sd	s2,16(sp)
    80004c3e:	e44e                	sd	s3,8(sp)
    80004c40:	1800                	addi	s0,sp,48
    80004c42:	892a                	mv	s2,a0
    80004c44:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c46:	0001d497          	auipc	s1,0x1d
    80004c4a:	f3a48493          	addi	s1,s1,-198 # 80021b80 <log>
    80004c4e:	00004597          	auipc	a1,0x4
    80004c52:	b6258593          	addi	a1,a1,-1182 # 800087b0 <syscalls+0x1e8>
    80004c56:	8526                	mv	a0,s1
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	efc080e7          	jalr	-260(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004c60:	0149a583          	lw	a1,20(s3)
    80004c64:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c66:	0109a783          	lw	a5,16(s3)
    80004c6a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c6c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c70:	854a                	mv	a0,s2
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	e92080e7          	jalr	-366(ra) # 80003b04 <bread>
  log.lh.n = lh->n;
    80004c7a:	4d3c                	lw	a5,88(a0)
    80004c7c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c7e:	02f05563          	blez	a5,80004ca8 <initlog+0x74>
    80004c82:	05c50713          	addi	a4,a0,92
    80004c86:	0001d697          	auipc	a3,0x1d
    80004c8a:	f2a68693          	addi	a3,a3,-214 # 80021bb0 <log+0x30>
    80004c8e:	37fd                	addiw	a5,a5,-1
    80004c90:	1782                	slli	a5,a5,0x20
    80004c92:	9381                	srli	a5,a5,0x20
    80004c94:	078a                	slli	a5,a5,0x2
    80004c96:	06050613          	addi	a2,a0,96
    80004c9a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004c9c:	4310                	lw	a2,0(a4)
    80004c9e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004ca0:	0711                	addi	a4,a4,4
    80004ca2:	0691                	addi	a3,a3,4
    80004ca4:	fef71ce3          	bne	a4,a5,80004c9c <initlog+0x68>
  brelse(buf);
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	f8c080e7          	jalr	-116(ra) # 80003c34 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004cb0:	4505                	li	a0,1
    80004cb2:	00000097          	auipc	ra,0x0
    80004cb6:	ebe080e7          	jalr	-322(ra) # 80004b70 <install_trans>
  log.lh.n = 0;
    80004cba:	0001d797          	auipc	a5,0x1d
    80004cbe:	ee07a923          	sw	zero,-270(a5) # 80021bac <log+0x2c>
  write_head(); // clear the log
    80004cc2:	00000097          	auipc	ra,0x0
    80004cc6:	e34080e7          	jalr	-460(ra) # 80004af6 <write_head>
}
    80004cca:	70a2                	ld	ra,40(sp)
    80004ccc:	7402                	ld	s0,32(sp)
    80004cce:	64e2                	ld	s1,24(sp)
    80004cd0:	6942                	ld	s2,16(sp)
    80004cd2:	69a2                	ld	s3,8(sp)
    80004cd4:	6145                	addi	sp,sp,48
    80004cd6:	8082                	ret

0000000080004cd8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004cd8:	1101                	addi	sp,sp,-32
    80004cda:	ec06                	sd	ra,24(sp)
    80004cdc:	e822                	sd	s0,16(sp)
    80004cde:	e426                	sd	s1,8(sp)
    80004ce0:	e04a                	sd	s2,0(sp)
    80004ce2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004ce4:	0001d517          	auipc	a0,0x1d
    80004ce8:	e9c50513          	addi	a0,a0,-356 # 80021b80 <log>
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	f00080e7          	jalr	-256(ra) # 80000bec <acquire>
  while(1){
    if(log.committing){
    80004cf4:	0001d497          	auipc	s1,0x1d
    80004cf8:	e8c48493          	addi	s1,s1,-372 # 80021b80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cfc:	4979                	li	s2,30
    80004cfe:	a039                	j	80004d0c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004d00:	85a6                	mv	a1,s1
    80004d02:	8526                	mv	a0,s1
    80004d04:	ffffe097          	auipc	ra,0xffffe
    80004d08:	edc080e7          	jalr	-292(ra) # 80002be0 <sleep>
    if(log.committing){
    80004d0c:	50dc                	lw	a5,36(s1)
    80004d0e:	fbed                	bnez	a5,80004d00 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d10:	509c                	lw	a5,32(s1)
    80004d12:	0017871b          	addiw	a4,a5,1
    80004d16:	0007069b          	sext.w	a3,a4
    80004d1a:	0027179b          	slliw	a5,a4,0x2
    80004d1e:	9fb9                	addw	a5,a5,a4
    80004d20:	0017979b          	slliw	a5,a5,0x1
    80004d24:	54d8                	lw	a4,44(s1)
    80004d26:	9fb9                	addw	a5,a5,a4
    80004d28:	00f95963          	bge	s2,a5,80004d3a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004d2c:	85a6                	mv	a1,s1
    80004d2e:	8526                	mv	a0,s1
    80004d30:	ffffe097          	auipc	ra,0xffffe
    80004d34:	eb0080e7          	jalr	-336(ra) # 80002be0 <sleep>
    80004d38:	bfd1                	j	80004d0c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004d3a:	0001d517          	auipc	a0,0x1d
    80004d3e:	e4650513          	addi	a0,a0,-442 # 80021b80 <log>
    80004d42:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004d44:	ffffc097          	auipc	ra,0xffffc
    80004d48:	f62080e7          	jalr	-158(ra) # 80000ca6 <release>
      break;
    }
  }
}
    80004d4c:	60e2                	ld	ra,24(sp)
    80004d4e:	6442                	ld	s0,16(sp)
    80004d50:	64a2                	ld	s1,8(sp)
    80004d52:	6902                	ld	s2,0(sp)
    80004d54:	6105                	addi	sp,sp,32
    80004d56:	8082                	ret

0000000080004d58 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d58:	7139                	addi	sp,sp,-64
    80004d5a:	fc06                	sd	ra,56(sp)
    80004d5c:	f822                	sd	s0,48(sp)
    80004d5e:	f426                	sd	s1,40(sp)
    80004d60:	f04a                	sd	s2,32(sp)
    80004d62:	ec4e                	sd	s3,24(sp)
    80004d64:	e852                	sd	s4,16(sp)
    80004d66:	e456                	sd	s5,8(sp)
    80004d68:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d6a:	0001d497          	auipc	s1,0x1d
    80004d6e:	e1648493          	addi	s1,s1,-490 # 80021b80 <log>
    80004d72:	8526                	mv	a0,s1
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	e78080e7          	jalr	-392(ra) # 80000bec <acquire>
  log.outstanding -= 1;
    80004d7c:	509c                	lw	a5,32(s1)
    80004d7e:	37fd                	addiw	a5,a5,-1
    80004d80:	0007891b          	sext.w	s2,a5
    80004d84:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d86:	50dc                	lw	a5,36(s1)
    80004d88:	efb9                	bnez	a5,80004de6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d8a:	06091663          	bnez	s2,80004df6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004d8e:	0001d497          	auipc	s1,0x1d
    80004d92:	df248493          	addi	s1,s1,-526 # 80021b80 <log>
    80004d96:	4785                	li	a5,1
    80004d98:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	f0a080e7          	jalr	-246(ra) # 80000ca6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004da4:	54dc                	lw	a5,44(s1)
    80004da6:	06f04763          	bgtz	a5,80004e14 <end_op+0xbc>
    acquire(&log.lock);
    80004daa:	0001d497          	auipc	s1,0x1d
    80004dae:	dd648493          	addi	s1,s1,-554 # 80021b80 <log>
    80004db2:	8526                	mv	a0,s1
    80004db4:	ffffc097          	auipc	ra,0xffffc
    80004db8:	e38080e7          	jalr	-456(ra) # 80000bec <acquire>
    log.committing = 0;
    80004dbc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004dc0:	8526                	mv	a0,s1
    80004dc2:	ffffe097          	auipc	ra,0xffffe
    80004dc6:	fc4080e7          	jalr	-60(ra) # 80002d86 <wakeup>
    release(&log.lock);
    80004dca:	8526                	mv	a0,s1
    80004dcc:	ffffc097          	auipc	ra,0xffffc
    80004dd0:	eda080e7          	jalr	-294(ra) # 80000ca6 <release>
}
    80004dd4:	70e2                	ld	ra,56(sp)
    80004dd6:	7442                	ld	s0,48(sp)
    80004dd8:	74a2                	ld	s1,40(sp)
    80004dda:	7902                	ld	s2,32(sp)
    80004ddc:	69e2                	ld	s3,24(sp)
    80004dde:	6a42                	ld	s4,16(sp)
    80004de0:	6aa2                	ld	s5,8(sp)
    80004de2:	6121                	addi	sp,sp,64
    80004de4:	8082                	ret
    panic("log.committing");
    80004de6:	00004517          	auipc	a0,0x4
    80004dea:	9d250513          	addi	a0,a0,-1582 # 800087b8 <syscalls+0x1f0>
    80004dee:	ffffb097          	auipc	ra,0xffffb
    80004df2:	750080e7          	jalr	1872(ra) # 8000053e <panic>
    wakeup(&log);
    80004df6:	0001d497          	auipc	s1,0x1d
    80004dfa:	d8a48493          	addi	s1,s1,-630 # 80021b80 <log>
    80004dfe:	8526                	mv	a0,s1
    80004e00:	ffffe097          	auipc	ra,0xffffe
    80004e04:	f86080e7          	jalr	-122(ra) # 80002d86 <wakeup>
  release(&log.lock);
    80004e08:	8526                	mv	a0,s1
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	e9c080e7          	jalr	-356(ra) # 80000ca6 <release>
  if(do_commit){
    80004e12:	b7c9                	j	80004dd4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e14:	0001da97          	auipc	s5,0x1d
    80004e18:	d9ca8a93          	addi	s5,s5,-612 # 80021bb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004e1c:	0001da17          	auipc	s4,0x1d
    80004e20:	d64a0a13          	addi	s4,s4,-668 # 80021b80 <log>
    80004e24:	018a2583          	lw	a1,24(s4)
    80004e28:	012585bb          	addw	a1,a1,s2
    80004e2c:	2585                	addiw	a1,a1,1
    80004e2e:	028a2503          	lw	a0,40(s4)
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	cd2080e7          	jalr	-814(ra) # 80003b04 <bread>
    80004e3a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004e3c:	000aa583          	lw	a1,0(s5)
    80004e40:	028a2503          	lw	a0,40(s4)
    80004e44:	fffff097          	auipc	ra,0xfffff
    80004e48:	cc0080e7          	jalr	-832(ra) # 80003b04 <bread>
    80004e4c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e4e:	40000613          	li	a2,1024
    80004e52:	05850593          	addi	a1,a0,88
    80004e56:	05848513          	addi	a0,s1,88
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	ef4080e7          	jalr	-268(ra) # 80000d4e <memmove>
    bwrite(to);  // write the log
    80004e62:	8526                	mv	a0,s1
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	d92080e7          	jalr	-622(ra) # 80003bf6 <bwrite>
    brelse(from);
    80004e6c:	854e                	mv	a0,s3
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	dc6080e7          	jalr	-570(ra) # 80003c34 <brelse>
    brelse(to);
    80004e76:	8526                	mv	a0,s1
    80004e78:	fffff097          	auipc	ra,0xfffff
    80004e7c:	dbc080e7          	jalr	-580(ra) # 80003c34 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e80:	2905                	addiw	s2,s2,1
    80004e82:	0a91                	addi	s5,s5,4
    80004e84:	02ca2783          	lw	a5,44(s4)
    80004e88:	f8f94ee3          	blt	s2,a5,80004e24 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e8c:	00000097          	auipc	ra,0x0
    80004e90:	c6a080e7          	jalr	-918(ra) # 80004af6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e94:	4501                	li	a0,0
    80004e96:	00000097          	auipc	ra,0x0
    80004e9a:	cda080e7          	jalr	-806(ra) # 80004b70 <install_trans>
    log.lh.n = 0;
    80004e9e:	0001d797          	auipc	a5,0x1d
    80004ea2:	d007a723          	sw	zero,-754(a5) # 80021bac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ea6:	00000097          	auipc	ra,0x0
    80004eaa:	c50080e7          	jalr	-944(ra) # 80004af6 <write_head>
    80004eae:	bdf5                	j	80004daa <end_op+0x52>

0000000080004eb0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004eb0:	1101                	addi	sp,sp,-32
    80004eb2:	ec06                	sd	ra,24(sp)
    80004eb4:	e822                	sd	s0,16(sp)
    80004eb6:	e426                	sd	s1,8(sp)
    80004eb8:	e04a                	sd	s2,0(sp)
    80004eba:	1000                	addi	s0,sp,32
    80004ebc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004ebe:	0001d917          	auipc	s2,0x1d
    80004ec2:	cc290913          	addi	s2,s2,-830 # 80021b80 <log>
    80004ec6:	854a                	mv	a0,s2
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	d24080e7          	jalr	-732(ra) # 80000bec <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004ed0:	02c92603          	lw	a2,44(s2)
    80004ed4:	47f5                	li	a5,29
    80004ed6:	06c7c563          	blt	a5,a2,80004f40 <log_write+0x90>
    80004eda:	0001d797          	auipc	a5,0x1d
    80004ede:	cc27a783          	lw	a5,-830(a5) # 80021b9c <log+0x1c>
    80004ee2:	37fd                	addiw	a5,a5,-1
    80004ee4:	04f65e63          	bge	a2,a5,80004f40 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ee8:	0001d797          	auipc	a5,0x1d
    80004eec:	cb87a783          	lw	a5,-840(a5) # 80021ba0 <log+0x20>
    80004ef0:	06f05063          	blez	a5,80004f50 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ef4:	4781                	li	a5,0
    80004ef6:	06c05563          	blez	a2,80004f60 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004efa:	44cc                	lw	a1,12(s1)
    80004efc:	0001d717          	auipc	a4,0x1d
    80004f00:	cb470713          	addi	a4,a4,-844 # 80021bb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004f04:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f06:	4314                	lw	a3,0(a4)
    80004f08:	04b68c63          	beq	a3,a1,80004f60 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004f0c:	2785                	addiw	a5,a5,1
    80004f0e:	0711                	addi	a4,a4,4
    80004f10:	fef61be3          	bne	a2,a5,80004f06 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004f14:	0621                	addi	a2,a2,8
    80004f16:	060a                	slli	a2,a2,0x2
    80004f18:	0001d797          	auipc	a5,0x1d
    80004f1c:	c6878793          	addi	a5,a5,-920 # 80021b80 <log>
    80004f20:	963e                	add	a2,a2,a5
    80004f22:	44dc                	lw	a5,12(s1)
    80004f24:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004f26:	8526                	mv	a0,s1
    80004f28:	fffff097          	auipc	ra,0xfffff
    80004f2c:	daa080e7          	jalr	-598(ra) # 80003cd2 <bpin>
    log.lh.n++;
    80004f30:	0001d717          	auipc	a4,0x1d
    80004f34:	c5070713          	addi	a4,a4,-944 # 80021b80 <log>
    80004f38:	575c                	lw	a5,44(a4)
    80004f3a:	2785                	addiw	a5,a5,1
    80004f3c:	d75c                	sw	a5,44(a4)
    80004f3e:	a835                	j	80004f7a <log_write+0xca>
    panic("too big a transaction");
    80004f40:	00004517          	auipc	a0,0x4
    80004f44:	88850513          	addi	a0,a0,-1912 # 800087c8 <syscalls+0x200>
    80004f48:	ffffb097          	auipc	ra,0xffffb
    80004f4c:	5f6080e7          	jalr	1526(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004f50:	00004517          	auipc	a0,0x4
    80004f54:	89050513          	addi	a0,a0,-1904 # 800087e0 <syscalls+0x218>
    80004f58:	ffffb097          	auipc	ra,0xffffb
    80004f5c:	5e6080e7          	jalr	1510(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004f60:	00878713          	addi	a4,a5,8
    80004f64:	00271693          	slli	a3,a4,0x2
    80004f68:	0001d717          	auipc	a4,0x1d
    80004f6c:	c1870713          	addi	a4,a4,-1000 # 80021b80 <log>
    80004f70:	9736                	add	a4,a4,a3
    80004f72:	44d4                	lw	a3,12(s1)
    80004f74:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f76:	faf608e3          	beq	a2,a5,80004f26 <log_write+0x76>
  }
  release(&log.lock);
    80004f7a:	0001d517          	auipc	a0,0x1d
    80004f7e:	c0650513          	addi	a0,a0,-1018 # 80021b80 <log>
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	d24080e7          	jalr	-732(ra) # 80000ca6 <release>
}
    80004f8a:	60e2                	ld	ra,24(sp)
    80004f8c:	6442                	ld	s0,16(sp)
    80004f8e:	64a2                	ld	s1,8(sp)
    80004f90:	6902                	ld	s2,0(sp)
    80004f92:	6105                	addi	sp,sp,32
    80004f94:	8082                	ret

0000000080004f96 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f96:	1101                	addi	sp,sp,-32
    80004f98:	ec06                	sd	ra,24(sp)
    80004f9a:	e822                	sd	s0,16(sp)
    80004f9c:	e426                	sd	s1,8(sp)
    80004f9e:	e04a                	sd	s2,0(sp)
    80004fa0:	1000                	addi	s0,sp,32
    80004fa2:	84aa                	mv	s1,a0
    80004fa4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004fa6:	00004597          	auipc	a1,0x4
    80004faa:	85a58593          	addi	a1,a1,-1958 # 80008800 <syscalls+0x238>
    80004fae:	0521                	addi	a0,a0,8
    80004fb0:	ffffc097          	auipc	ra,0xffffc
    80004fb4:	ba4080e7          	jalr	-1116(ra) # 80000b54 <initlock>
  lk->name = name;
    80004fb8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004fbc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fc0:	0204a423          	sw	zero,40(s1)
}
    80004fc4:	60e2                	ld	ra,24(sp)
    80004fc6:	6442                	ld	s0,16(sp)
    80004fc8:	64a2                	ld	s1,8(sp)
    80004fca:	6902                	ld	s2,0(sp)
    80004fcc:	6105                	addi	sp,sp,32
    80004fce:	8082                	ret

0000000080004fd0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004fd0:	1101                	addi	sp,sp,-32
    80004fd2:	ec06                	sd	ra,24(sp)
    80004fd4:	e822                	sd	s0,16(sp)
    80004fd6:	e426                	sd	s1,8(sp)
    80004fd8:	e04a                	sd	s2,0(sp)
    80004fda:	1000                	addi	s0,sp,32
    80004fdc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fde:	00850913          	addi	s2,a0,8
    80004fe2:	854a                	mv	a0,s2
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	c08080e7          	jalr	-1016(ra) # 80000bec <acquire>
  while (lk->locked) {
    80004fec:	409c                	lw	a5,0(s1)
    80004fee:	cb89                	beqz	a5,80005000 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ff0:	85ca                	mv	a1,s2
    80004ff2:	8526                	mv	a0,s1
    80004ff4:	ffffe097          	auipc	ra,0xffffe
    80004ff8:	bec080e7          	jalr	-1044(ra) # 80002be0 <sleep>
  while (lk->locked) {
    80004ffc:	409c                	lw	a5,0(s1)
    80004ffe:	fbed                	bnez	a5,80004ff0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005000:	4785                	li	a5,1
    80005002:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80005004:	ffffd097          	auipc	ra,0xffffd
    80005008:	da0080e7          	jalr	-608(ra) # 80001da4 <myproc>
    8000500c:	453c                	lw	a5,72(a0)
    8000500e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005010:	854a                	mv	a0,s2
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	c94080e7          	jalr	-876(ra) # 80000ca6 <release>
}
    8000501a:	60e2                	ld	ra,24(sp)
    8000501c:	6442                	ld	s0,16(sp)
    8000501e:	64a2                	ld	s1,8(sp)
    80005020:	6902                	ld	s2,0(sp)
    80005022:	6105                	addi	sp,sp,32
    80005024:	8082                	ret

0000000080005026 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005026:	1101                	addi	sp,sp,-32
    80005028:	ec06                	sd	ra,24(sp)
    8000502a:	e822                	sd	s0,16(sp)
    8000502c:	e426                	sd	s1,8(sp)
    8000502e:	e04a                	sd	s2,0(sp)
    80005030:	1000                	addi	s0,sp,32
    80005032:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005034:	00850913          	addi	s2,a0,8
    80005038:	854a                	mv	a0,s2
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	bb2080e7          	jalr	-1102(ra) # 80000bec <acquire>
  lk->locked = 0;
    80005042:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005046:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000504a:	8526                	mv	a0,s1
    8000504c:	ffffe097          	auipc	ra,0xffffe
    80005050:	d3a080e7          	jalr	-710(ra) # 80002d86 <wakeup>
  release(&lk->lk);
    80005054:	854a                	mv	a0,s2
    80005056:	ffffc097          	auipc	ra,0xffffc
    8000505a:	c50080e7          	jalr	-944(ra) # 80000ca6 <release>
}
    8000505e:	60e2                	ld	ra,24(sp)
    80005060:	6442                	ld	s0,16(sp)
    80005062:	64a2                	ld	s1,8(sp)
    80005064:	6902                	ld	s2,0(sp)
    80005066:	6105                	addi	sp,sp,32
    80005068:	8082                	ret

000000008000506a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000506a:	7179                	addi	sp,sp,-48
    8000506c:	f406                	sd	ra,40(sp)
    8000506e:	f022                	sd	s0,32(sp)
    80005070:	ec26                	sd	s1,24(sp)
    80005072:	e84a                	sd	s2,16(sp)
    80005074:	e44e                	sd	s3,8(sp)
    80005076:	1800                	addi	s0,sp,48
    80005078:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000507a:	00850913          	addi	s2,a0,8
    8000507e:	854a                	mv	a0,s2
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	b6c080e7          	jalr	-1172(ra) # 80000bec <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005088:	409c                	lw	a5,0(s1)
    8000508a:	ef99                	bnez	a5,800050a8 <holdingsleep+0x3e>
    8000508c:	4481                	li	s1,0
  release(&lk->lk);
    8000508e:	854a                	mv	a0,s2
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	c16080e7          	jalr	-1002(ra) # 80000ca6 <release>
  return r;
}
    80005098:	8526                	mv	a0,s1
    8000509a:	70a2                	ld	ra,40(sp)
    8000509c:	7402                	ld	s0,32(sp)
    8000509e:	64e2                	ld	s1,24(sp)
    800050a0:	6942                	ld	s2,16(sp)
    800050a2:	69a2                	ld	s3,8(sp)
    800050a4:	6145                	addi	sp,sp,48
    800050a6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800050a8:	0284a983          	lw	s3,40(s1)
    800050ac:	ffffd097          	auipc	ra,0xffffd
    800050b0:	cf8080e7          	jalr	-776(ra) # 80001da4 <myproc>
    800050b4:	4524                	lw	s1,72(a0)
    800050b6:	413484b3          	sub	s1,s1,s3
    800050ba:	0014b493          	seqz	s1,s1
    800050be:	bfc1                	j	8000508e <holdingsleep+0x24>

00000000800050c0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800050c0:	1141                	addi	sp,sp,-16
    800050c2:	e406                	sd	ra,8(sp)
    800050c4:	e022                	sd	s0,0(sp)
    800050c6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800050c8:	00003597          	auipc	a1,0x3
    800050cc:	74858593          	addi	a1,a1,1864 # 80008810 <syscalls+0x248>
    800050d0:	0001d517          	auipc	a0,0x1d
    800050d4:	bf850513          	addi	a0,a0,-1032 # 80021cc8 <ftable>
    800050d8:	ffffc097          	auipc	ra,0xffffc
    800050dc:	a7c080e7          	jalr	-1412(ra) # 80000b54 <initlock>
}
    800050e0:	60a2                	ld	ra,8(sp)
    800050e2:	6402                	ld	s0,0(sp)
    800050e4:	0141                	addi	sp,sp,16
    800050e6:	8082                	ret

00000000800050e8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800050e8:	1101                	addi	sp,sp,-32
    800050ea:	ec06                	sd	ra,24(sp)
    800050ec:	e822                	sd	s0,16(sp)
    800050ee:	e426                	sd	s1,8(sp)
    800050f0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800050f2:	0001d517          	auipc	a0,0x1d
    800050f6:	bd650513          	addi	a0,a0,-1066 # 80021cc8 <ftable>
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	af2080e7          	jalr	-1294(ra) # 80000bec <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005102:	0001d497          	auipc	s1,0x1d
    80005106:	bde48493          	addi	s1,s1,-1058 # 80021ce0 <ftable+0x18>
    8000510a:	0001e717          	auipc	a4,0x1e
    8000510e:	b7670713          	addi	a4,a4,-1162 # 80022c80 <ftable+0xfb8>
    if(f->ref == 0){
    80005112:	40dc                	lw	a5,4(s1)
    80005114:	cf99                	beqz	a5,80005132 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005116:	02848493          	addi	s1,s1,40
    8000511a:	fee49ce3          	bne	s1,a4,80005112 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000511e:	0001d517          	auipc	a0,0x1d
    80005122:	baa50513          	addi	a0,a0,-1110 # 80021cc8 <ftable>
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	b80080e7          	jalr	-1152(ra) # 80000ca6 <release>
  return 0;
    8000512e:	4481                	li	s1,0
    80005130:	a819                	j	80005146 <filealloc+0x5e>
      f->ref = 1;
    80005132:	4785                	li	a5,1
    80005134:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005136:	0001d517          	auipc	a0,0x1d
    8000513a:	b9250513          	addi	a0,a0,-1134 # 80021cc8 <ftable>
    8000513e:	ffffc097          	auipc	ra,0xffffc
    80005142:	b68080e7          	jalr	-1176(ra) # 80000ca6 <release>
}
    80005146:	8526                	mv	a0,s1
    80005148:	60e2                	ld	ra,24(sp)
    8000514a:	6442                	ld	s0,16(sp)
    8000514c:	64a2                	ld	s1,8(sp)
    8000514e:	6105                	addi	sp,sp,32
    80005150:	8082                	ret

0000000080005152 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005152:	1101                	addi	sp,sp,-32
    80005154:	ec06                	sd	ra,24(sp)
    80005156:	e822                	sd	s0,16(sp)
    80005158:	e426                	sd	s1,8(sp)
    8000515a:	1000                	addi	s0,sp,32
    8000515c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000515e:	0001d517          	auipc	a0,0x1d
    80005162:	b6a50513          	addi	a0,a0,-1174 # 80021cc8 <ftable>
    80005166:	ffffc097          	auipc	ra,0xffffc
    8000516a:	a86080e7          	jalr	-1402(ra) # 80000bec <acquire>
  if(f->ref < 1)
    8000516e:	40dc                	lw	a5,4(s1)
    80005170:	02f05263          	blez	a5,80005194 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005174:	2785                	addiw	a5,a5,1
    80005176:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005178:	0001d517          	auipc	a0,0x1d
    8000517c:	b5050513          	addi	a0,a0,-1200 # 80021cc8 <ftable>
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	b26080e7          	jalr	-1242(ra) # 80000ca6 <release>
  return f;
}
    80005188:	8526                	mv	a0,s1
    8000518a:	60e2                	ld	ra,24(sp)
    8000518c:	6442                	ld	s0,16(sp)
    8000518e:	64a2                	ld	s1,8(sp)
    80005190:	6105                	addi	sp,sp,32
    80005192:	8082                	ret
    panic("filedup");
    80005194:	00003517          	auipc	a0,0x3
    80005198:	68450513          	addi	a0,a0,1668 # 80008818 <syscalls+0x250>
    8000519c:	ffffb097          	auipc	ra,0xffffb
    800051a0:	3a2080e7          	jalr	930(ra) # 8000053e <panic>

00000000800051a4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800051a4:	7139                	addi	sp,sp,-64
    800051a6:	fc06                	sd	ra,56(sp)
    800051a8:	f822                	sd	s0,48(sp)
    800051aa:	f426                	sd	s1,40(sp)
    800051ac:	f04a                	sd	s2,32(sp)
    800051ae:	ec4e                	sd	s3,24(sp)
    800051b0:	e852                	sd	s4,16(sp)
    800051b2:	e456                	sd	s5,8(sp)
    800051b4:	0080                	addi	s0,sp,64
    800051b6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800051b8:	0001d517          	auipc	a0,0x1d
    800051bc:	b1050513          	addi	a0,a0,-1264 # 80021cc8 <ftable>
    800051c0:	ffffc097          	auipc	ra,0xffffc
    800051c4:	a2c080e7          	jalr	-1492(ra) # 80000bec <acquire>
  if(f->ref < 1)
    800051c8:	40dc                	lw	a5,4(s1)
    800051ca:	06f05163          	blez	a5,8000522c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800051ce:	37fd                	addiw	a5,a5,-1
    800051d0:	0007871b          	sext.w	a4,a5
    800051d4:	c0dc                	sw	a5,4(s1)
    800051d6:	06e04363          	bgtz	a4,8000523c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800051da:	0004a903          	lw	s2,0(s1)
    800051de:	0094ca83          	lbu	s5,9(s1)
    800051e2:	0104ba03          	ld	s4,16(s1)
    800051e6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800051ea:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800051ee:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800051f2:	0001d517          	auipc	a0,0x1d
    800051f6:	ad650513          	addi	a0,a0,-1322 # 80021cc8 <ftable>
    800051fa:	ffffc097          	auipc	ra,0xffffc
    800051fe:	aac080e7          	jalr	-1364(ra) # 80000ca6 <release>

  if(ff.type == FD_PIPE){
    80005202:	4785                	li	a5,1
    80005204:	04f90d63          	beq	s2,a5,8000525e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005208:	3979                	addiw	s2,s2,-2
    8000520a:	4785                	li	a5,1
    8000520c:	0527e063          	bltu	a5,s2,8000524c <fileclose+0xa8>
    begin_op();
    80005210:	00000097          	auipc	ra,0x0
    80005214:	ac8080e7          	jalr	-1336(ra) # 80004cd8 <begin_op>
    iput(ff.ip);
    80005218:	854e                	mv	a0,s3
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	2a6080e7          	jalr	678(ra) # 800044c0 <iput>
    end_op();
    80005222:	00000097          	auipc	ra,0x0
    80005226:	b36080e7          	jalr	-1226(ra) # 80004d58 <end_op>
    8000522a:	a00d                	j	8000524c <fileclose+0xa8>
    panic("fileclose");
    8000522c:	00003517          	auipc	a0,0x3
    80005230:	5f450513          	addi	a0,a0,1524 # 80008820 <syscalls+0x258>
    80005234:	ffffb097          	auipc	ra,0xffffb
    80005238:	30a080e7          	jalr	778(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000523c:	0001d517          	auipc	a0,0x1d
    80005240:	a8c50513          	addi	a0,a0,-1396 # 80021cc8 <ftable>
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	a62080e7          	jalr	-1438(ra) # 80000ca6 <release>
  }
}
    8000524c:	70e2                	ld	ra,56(sp)
    8000524e:	7442                	ld	s0,48(sp)
    80005250:	74a2                	ld	s1,40(sp)
    80005252:	7902                	ld	s2,32(sp)
    80005254:	69e2                	ld	s3,24(sp)
    80005256:	6a42                	ld	s4,16(sp)
    80005258:	6aa2                	ld	s5,8(sp)
    8000525a:	6121                	addi	sp,sp,64
    8000525c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000525e:	85d6                	mv	a1,s5
    80005260:	8552                	mv	a0,s4
    80005262:	00000097          	auipc	ra,0x0
    80005266:	34c080e7          	jalr	844(ra) # 800055ae <pipeclose>
    8000526a:	b7cd                	j	8000524c <fileclose+0xa8>

000000008000526c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000526c:	715d                	addi	sp,sp,-80
    8000526e:	e486                	sd	ra,72(sp)
    80005270:	e0a2                	sd	s0,64(sp)
    80005272:	fc26                	sd	s1,56(sp)
    80005274:	f84a                	sd	s2,48(sp)
    80005276:	f44e                	sd	s3,40(sp)
    80005278:	0880                	addi	s0,sp,80
    8000527a:	84aa                	mv	s1,a0
    8000527c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000527e:	ffffd097          	auipc	ra,0xffffd
    80005282:	b26080e7          	jalr	-1242(ra) # 80001da4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005286:	409c                	lw	a5,0(s1)
    80005288:	37f9                	addiw	a5,a5,-2
    8000528a:	4705                	li	a4,1
    8000528c:	04f76763          	bltu	a4,a5,800052da <filestat+0x6e>
    80005290:	892a                	mv	s2,a0
    ilock(f->ip);
    80005292:	6c88                	ld	a0,24(s1)
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	072080e7          	jalr	114(ra) # 80004306 <ilock>
    stati(f->ip, &st);
    8000529c:	fb840593          	addi	a1,s0,-72
    800052a0:	6c88                	ld	a0,24(s1)
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	2ee080e7          	jalr	750(ra) # 80004590 <stati>
    iunlock(f->ip);
    800052aa:	6c88                	ld	a0,24(s1)
    800052ac:	fffff097          	auipc	ra,0xfffff
    800052b0:	11c080e7          	jalr	284(ra) # 800043c8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800052b4:	46e1                	li	a3,24
    800052b6:	fb840613          	addi	a2,s0,-72
    800052ba:	85ce                	mv	a1,s3
    800052bc:	07893503          	ld	a0,120(s2)
    800052c0:	ffffc097          	auipc	ra,0xffffc
    800052c4:	3c0080e7          	jalr	960(ra) # 80001680 <copyout>
    800052c8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800052cc:	60a6                	ld	ra,72(sp)
    800052ce:	6406                	ld	s0,64(sp)
    800052d0:	74e2                	ld	s1,56(sp)
    800052d2:	7942                	ld	s2,48(sp)
    800052d4:	79a2                	ld	s3,40(sp)
    800052d6:	6161                	addi	sp,sp,80
    800052d8:	8082                	ret
  return -1;
    800052da:	557d                	li	a0,-1
    800052dc:	bfc5                	j	800052cc <filestat+0x60>

00000000800052de <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800052de:	7179                	addi	sp,sp,-48
    800052e0:	f406                	sd	ra,40(sp)
    800052e2:	f022                	sd	s0,32(sp)
    800052e4:	ec26                	sd	s1,24(sp)
    800052e6:	e84a                	sd	s2,16(sp)
    800052e8:	e44e                	sd	s3,8(sp)
    800052ea:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800052ec:	00854783          	lbu	a5,8(a0)
    800052f0:	c3d5                	beqz	a5,80005394 <fileread+0xb6>
    800052f2:	84aa                	mv	s1,a0
    800052f4:	89ae                	mv	s3,a1
    800052f6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800052f8:	411c                	lw	a5,0(a0)
    800052fa:	4705                	li	a4,1
    800052fc:	04e78963          	beq	a5,a4,8000534e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005300:	470d                	li	a4,3
    80005302:	04e78d63          	beq	a5,a4,8000535c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005306:	4709                	li	a4,2
    80005308:	06e79e63          	bne	a5,a4,80005384 <fileread+0xa6>
    ilock(f->ip);
    8000530c:	6d08                	ld	a0,24(a0)
    8000530e:	fffff097          	auipc	ra,0xfffff
    80005312:	ff8080e7          	jalr	-8(ra) # 80004306 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005316:	874a                	mv	a4,s2
    80005318:	5094                	lw	a3,32(s1)
    8000531a:	864e                	mv	a2,s3
    8000531c:	4585                	li	a1,1
    8000531e:	6c88                	ld	a0,24(s1)
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	29a080e7          	jalr	666(ra) # 800045ba <readi>
    80005328:	892a                	mv	s2,a0
    8000532a:	00a05563          	blez	a0,80005334 <fileread+0x56>
      f->off += r;
    8000532e:	509c                	lw	a5,32(s1)
    80005330:	9fa9                	addw	a5,a5,a0
    80005332:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005334:	6c88                	ld	a0,24(s1)
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	092080e7          	jalr	146(ra) # 800043c8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000533e:	854a                	mv	a0,s2
    80005340:	70a2                	ld	ra,40(sp)
    80005342:	7402                	ld	s0,32(sp)
    80005344:	64e2                	ld	s1,24(sp)
    80005346:	6942                	ld	s2,16(sp)
    80005348:	69a2                	ld	s3,8(sp)
    8000534a:	6145                	addi	sp,sp,48
    8000534c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000534e:	6908                	ld	a0,16(a0)
    80005350:	00000097          	auipc	ra,0x0
    80005354:	3c8080e7          	jalr	968(ra) # 80005718 <piperead>
    80005358:	892a                	mv	s2,a0
    8000535a:	b7d5                	j	8000533e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000535c:	02451783          	lh	a5,36(a0)
    80005360:	03079693          	slli	a3,a5,0x30
    80005364:	92c1                	srli	a3,a3,0x30
    80005366:	4725                	li	a4,9
    80005368:	02d76863          	bltu	a4,a3,80005398 <fileread+0xba>
    8000536c:	0792                	slli	a5,a5,0x4
    8000536e:	0001d717          	auipc	a4,0x1d
    80005372:	8ba70713          	addi	a4,a4,-1862 # 80021c28 <devsw>
    80005376:	97ba                	add	a5,a5,a4
    80005378:	639c                	ld	a5,0(a5)
    8000537a:	c38d                	beqz	a5,8000539c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000537c:	4505                	li	a0,1
    8000537e:	9782                	jalr	a5
    80005380:	892a                	mv	s2,a0
    80005382:	bf75                	j	8000533e <fileread+0x60>
    panic("fileread");
    80005384:	00003517          	auipc	a0,0x3
    80005388:	4ac50513          	addi	a0,a0,1196 # 80008830 <syscalls+0x268>
    8000538c:	ffffb097          	auipc	ra,0xffffb
    80005390:	1b2080e7          	jalr	434(ra) # 8000053e <panic>
    return -1;
    80005394:	597d                	li	s2,-1
    80005396:	b765                	j	8000533e <fileread+0x60>
      return -1;
    80005398:	597d                	li	s2,-1
    8000539a:	b755                	j	8000533e <fileread+0x60>
    8000539c:	597d                	li	s2,-1
    8000539e:	b745                	j	8000533e <fileread+0x60>

00000000800053a0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800053a0:	715d                	addi	sp,sp,-80
    800053a2:	e486                	sd	ra,72(sp)
    800053a4:	e0a2                	sd	s0,64(sp)
    800053a6:	fc26                	sd	s1,56(sp)
    800053a8:	f84a                	sd	s2,48(sp)
    800053aa:	f44e                	sd	s3,40(sp)
    800053ac:	f052                	sd	s4,32(sp)
    800053ae:	ec56                	sd	s5,24(sp)
    800053b0:	e85a                	sd	s6,16(sp)
    800053b2:	e45e                	sd	s7,8(sp)
    800053b4:	e062                	sd	s8,0(sp)
    800053b6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800053b8:	00954783          	lbu	a5,9(a0)
    800053bc:	10078663          	beqz	a5,800054c8 <filewrite+0x128>
    800053c0:	892a                	mv	s2,a0
    800053c2:	8aae                	mv	s5,a1
    800053c4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800053c6:	411c                	lw	a5,0(a0)
    800053c8:	4705                	li	a4,1
    800053ca:	02e78263          	beq	a5,a4,800053ee <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800053ce:	470d                	li	a4,3
    800053d0:	02e78663          	beq	a5,a4,800053fc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800053d4:	4709                	li	a4,2
    800053d6:	0ee79163          	bne	a5,a4,800054b8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800053da:	0ac05d63          	blez	a2,80005494 <filewrite+0xf4>
    int i = 0;
    800053de:	4981                	li	s3,0
    800053e0:	6b05                	lui	s6,0x1
    800053e2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800053e6:	6b85                	lui	s7,0x1
    800053e8:	c00b8b9b          	addiw	s7,s7,-1024
    800053ec:	a861                	j	80005484 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800053ee:	6908                	ld	a0,16(a0)
    800053f0:	00000097          	auipc	ra,0x0
    800053f4:	22e080e7          	jalr	558(ra) # 8000561e <pipewrite>
    800053f8:	8a2a                	mv	s4,a0
    800053fa:	a045                	j	8000549a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800053fc:	02451783          	lh	a5,36(a0)
    80005400:	03079693          	slli	a3,a5,0x30
    80005404:	92c1                	srli	a3,a3,0x30
    80005406:	4725                	li	a4,9
    80005408:	0cd76263          	bltu	a4,a3,800054cc <filewrite+0x12c>
    8000540c:	0792                	slli	a5,a5,0x4
    8000540e:	0001d717          	auipc	a4,0x1d
    80005412:	81a70713          	addi	a4,a4,-2022 # 80021c28 <devsw>
    80005416:	97ba                	add	a5,a5,a4
    80005418:	679c                	ld	a5,8(a5)
    8000541a:	cbdd                	beqz	a5,800054d0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000541c:	4505                	li	a0,1
    8000541e:	9782                	jalr	a5
    80005420:	8a2a                	mv	s4,a0
    80005422:	a8a5                	j	8000549a <filewrite+0xfa>
    80005424:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005428:	00000097          	auipc	ra,0x0
    8000542c:	8b0080e7          	jalr	-1872(ra) # 80004cd8 <begin_op>
      ilock(f->ip);
    80005430:	01893503          	ld	a0,24(s2)
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	ed2080e7          	jalr	-302(ra) # 80004306 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000543c:	8762                	mv	a4,s8
    8000543e:	02092683          	lw	a3,32(s2)
    80005442:	01598633          	add	a2,s3,s5
    80005446:	4585                	li	a1,1
    80005448:	01893503          	ld	a0,24(s2)
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	266080e7          	jalr	614(ra) # 800046b2 <writei>
    80005454:	84aa                	mv	s1,a0
    80005456:	00a05763          	blez	a0,80005464 <filewrite+0xc4>
        f->off += r;
    8000545a:	02092783          	lw	a5,32(s2)
    8000545e:	9fa9                	addw	a5,a5,a0
    80005460:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005464:	01893503          	ld	a0,24(s2)
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	f60080e7          	jalr	-160(ra) # 800043c8 <iunlock>
      end_op();
    80005470:	00000097          	auipc	ra,0x0
    80005474:	8e8080e7          	jalr	-1816(ra) # 80004d58 <end_op>

      if(r != n1){
    80005478:	009c1f63          	bne	s8,s1,80005496 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000547c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005480:	0149db63          	bge	s3,s4,80005496 <filewrite+0xf6>
      int n1 = n - i;
    80005484:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005488:	84be                	mv	s1,a5
    8000548a:	2781                	sext.w	a5,a5
    8000548c:	f8fb5ce3          	bge	s6,a5,80005424 <filewrite+0x84>
    80005490:	84de                	mv	s1,s7
    80005492:	bf49                	j	80005424 <filewrite+0x84>
    int i = 0;
    80005494:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005496:	013a1f63          	bne	s4,s3,800054b4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000549a:	8552                	mv	a0,s4
    8000549c:	60a6                	ld	ra,72(sp)
    8000549e:	6406                	ld	s0,64(sp)
    800054a0:	74e2                	ld	s1,56(sp)
    800054a2:	7942                	ld	s2,48(sp)
    800054a4:	79a2                	ld	s3,40(sp)
    800054a6:	7a02                	ld	s4,32(sp)
    800054a8:	6ae2                	ld	s5,24(sp)
    800054aa:	6b42                	ld	s6,16(sp)
    800054ac:	6ba2                	ld	s7,8(sp)
    800054ae:	6c02                	ld	s8,0(sp)
    800054b0:	6161                	addi	sp,sp,80
    800054b2:	8082                	ret
    ret = (i == n ? n : -1);
    800054b4:	5a7d                	li	s4,-1
    800054b6:	b7d5                	j	8000549a <filewrite+0xfa>
    panic("filewrite");
    800054b8:	00003517          	auipc	a0,0x3
    800054bc:	38850513          	addi	a0,a0,904 # 80008840 <syscalls+0x278>
    800054c0:	ffffb097          	auipc	ra,0xffffb
    800054c4:	07e080e7          	jalr	126(ra) # 8000053e <panic>
    return -1;
    800054c8:	5a7d                	li	s4,-1
    800054ca:	bfc1                	j	8000549a <filewrite+0xfa>
      return -1;
    800054cc:	5a7d                	li	s4,-1
    800054ce:	b7f1                	j	8000549a <filewrite+0xfa>
    800054d0:	5a7d                	li	s4,-1
    800054d2:	b7e1                	j	8000549a <filewrite+0xfa>

00000000800054d4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800054d4:	7179                	addi	sp,sp,-48
    800054d6:	f406                	sd	ra,40(sp)
    800054d8:	f022                	sd	s0,32(sp)
    800054da:	ec26                	sd	s1,24(sp)
    800054dc:	e84a                	sd	s2,16(sp)
    800054de:	e44e                	sd	s3,8(sp)
    800054e0:	e052                	sd	s4,0(sp)
    800054e2:	1800                	addi	s0,sp,48
    800054e4:	84aa                	mv	s1,a0
    800054e6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800054e8:	0005b023          	sd	zero,0(a1)
    800054ec:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800054f0:	00000097          	auipc	ra,0x0
    800054f4:	bf8080e7          	jalr	-1032(ra) # 800050e8 <filealloc>
    800054f8:	e088                	sd	a0,0(s1)
    800054fa:	c551                	beqz	a0,80005586 <pipealloc+0xb2>
    800054fc:	00000097          	auipc	ra,0x0
    80005500:	bec080e7          	jalr	-1044(ra) # 800050e8 <filealloc>
    80005504:	00aa3023          	sd	a0,0(s4)
    80005508:	c92d                	beqz	a0,8000557a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000550a:	ffffb097          	auipc	ra,0xffffb
    8000550e:	5ea080e7          	jalr	1514(ra) # 80000af4 <kalloc>
    80005512:	892a                	mv	s2,a0
    80005514:	c125                	beqz	a0,80005574 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005516:	4985                	li	s3,1
    80005518:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000551c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005520:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005524:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005528:	00003597          	auipc	a1,0x3
    8000552c:	32858593          	addi	a1,a1,808 # 80008850 <syscalls+0x288>
    80005530:	ffffb097          	auipc	ra,0xffffb
    80005534:	624080e7          	jalr	1572(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005538:	609c                	ld	a5,0(s1)
    8000553a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000553e:	609c                	ld	a5,0(s1)
    80005540:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005544:	609c                	ld	a5,0(s1)
    80005546:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000554a:	609c                	ld	a5,0(s1)
    8000554c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005550:	000a3783          	ld	a5,0(s4)
    80005554:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005558:	000a3783          	ld	a5,0(s4)
    8000555c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005560:	000a3783          	ld	a5,0(s4)
    80005564:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005568:	000a3783          	ld	a5,0(s4)
    8000556c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005570:	4501                	li	a0,0
    80005572:	a025                	j	8000559a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005574:	6088                	ld	a0,0(s1)
    80005576:	e501                	bnez	a0,8000557e <pipealloc+0xaa>
    80005578:	a039                	j	80005586 <pipealloc+0xb2>
    8000557a:	6088                	ld	a0,0(s1)
    8000557c:	c51d                	beqz	a0,800055aa <pipealloc+0xd6>
    fileclose(*f0);
    8000557e:	00000097          	auipc	ra,0x0
    80005582:	c26080e7          	jalr	-986(ra) # 800051a4 <fileclose>
  if(*f1)
    80005586:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000558a:	557d                	li	a0,-1
  if(*f1)
    8000558c:	c799                	beqz	a5,8000559a <pipealloc+0xc6>
    fileclose(*f1);
    8000558e:	853e                	mv	a0,a5
    80005590:	00000097          	auipc	ra,0x0
    80005594:	c14080e7          	jalr	-1004(ra) # 800051a4 <fileclose>
  return -1;
    80005598:	557d                	li	a0,-1
}
    8000559a:	70a2                	ld	ra,40(sp)
    8000559c:	7402                	ld	s0,32(sp)
    8000559e:	64e2                	ld	s1,24(sp)
    800055a0:	6942                	ld	s2,16(sp)
    800055a2:	69a2                	ld	s3,8(sp)
    800055a4:	6a02                	ld	s4,0(sp)
    800055a6:	6145                	addi	sp,sp,48
    800055a8:	8082                	ret
  return -1;
    800055aa:	557d                	li	a0,-1
    800055ac:	b7fd                	j	8000559a <pipealloc+0xc6>

00000000800055ae <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800055ae:	1101                	addi	sp,sp,-32
    800055b0:	ec06                	sd	ra,24(sp)
    800055b2:	e822                	sd	s0,16(sp)
    800055b4:	e426                	sd	s1,8(sp)
    800055b6:	e04a                	sd	s2,0(sp)
    800055b8:	1000                	addi	s0,sp,32
    800055ba:	84aa                	mv	s1,a0
    800055bc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800055be:	ffffb097          	auipc	ra,0xffffb
    800055c2:	62e080e7          	jalr	1582(ra) # 80000bec <acquire>
  if(writable){
    800055c6:	02090d63          	beqz	s2,80005600 <pipeclose+0x52>
    pi->writeopen = 0;
    800055ca:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800055ce:	21848513          	addi	a0,s1,536
    800055d2:	ffffd097          	auipc	ra,0xffffd
    800055d6:	7b4080e7          	jalr	1972(ra) # 80002d86 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800055da:	2204b783          	ld	a5,544(s1)
    800055de:	eb95                	bnez	a5,80005612 <pipeclose+0x64>
    release(&pi->lock);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffb097          	auipc	ra,0xffffb
    800055e6:	6c4080e7          	jalr	1732(ra) # 80000ca6 <release>
    kfree((char*)pi);
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffb097          	auipc	ra,0xffffb
    800055f0:	40c080e7          	jalr	1036(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800055f4:	60e2                	ld	ra,24(sp)
    800055f6:	6442                	ld	s0,16(sp)
    800055f8:	64a2                	ld	s1,8(sp)
    800055fa:	6902                	ld	s2,0(sp)
    800055fc:	6105                	addi	sp,sp,32
    800055fe:	8082                	ret
    pi->readopen = 0;
    80005600:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005604:	21c48513          	addi	a0,s1,540
    80005608:	ffffd097          	auipc	ra,0xffffd
    8000560c:	77e080e7          	jalr	1918(ra) # 80002d86 <wakeup>
    80005610:	b7e9                	j	800055da <pipeclose+0x2c>
    release(&pi->lock);
    80005612:	8526                	mv	a0,s1
    80005614:	ffffb097          	auipc	ra,0xffffb
    80005618:	692080e7          	jalr	1682(ra) # 80000ca6 <release>
}
    8000561c:	bfe1                	j	800055f4 <pipeclose+0x46>

000000008000561e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000561e:	7159                	addi	sp,sp,-112
    80005620:	f486                	sd	ra,104(sp)
    80005622:	f0a2                	sd	s0,96(sp)
    80005624:	eca6                	sd	s1,88(sp)
    80005626:	e8ca                	sd	s2,80(sp)
    80005628:	e4ce                	sd	s3,72(sp)
    8000562a:	e0d2                	sd	s4,64(sp)
    8000562c:	fc56                	sd	s5,56(sp)
    8000562e:	f85a                	sd	s6,48(sp)
    80005630:	f45e                	sd	s7,40(sp)
    80005632:	f062                	sd	s8,32(sp)
    80005634:	ec66                	sd	s9,24(sp)
    80005636:	1880                	addi	s0,sp,112
    80005638:	84aa                	mv	s1,a0
    8000563a:	8aae                	mv	s5,a1
    8000563c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000563e:	ffffc097          	auipc	ra,0xffffc
    80005642:	766080e7          	jalr	1894(ra) # 80001da4 <myproc>
    80005646:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffb097          	auipc	ra,0xffffb
    8000564e:	5a2080e7          	jalr	1442(ra) # 80000bec <acquire>
  while(i < n){
    80005652:	0d405163          	blez	s4,80005714 <pipewrite+0xf6>
    80005656:	8ba6                	mv	s7,s1
  int i = 0;
    80005658:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000565a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000565c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005660:	21c48c13          	addi	s8,s1,540
    80005664:	a08d                	j	800056c6 <pipewrite+0xa8>
      release(&pi->lock);
    80005666:	8526                	mv	a0,s1
    80005668:	ffffb097          	auipc	ra,0xffffb
    8000566c:	63e080e7          	jalr	1598(ra) # 80000ca6 <release>
      return -1;
    80005670:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005672:	854a                	mv	a0,s2
    80005674:	70a6                	ld	ra,104(sp)
    80005676:	7406                	ld	s0,96(sp)
    80005678:	64e6                	ld	s1,88(sp)
    8000567a:	6946                	ld	s2,80(sp)
    8000567c:	69a6                	ld	s3,72(sp)
    8000567e:	6a06                	ld	s4,64(sp)
    80005680:	7ae2                	ld	s5,56(sp)
    80005682:	7b42                	ld	s6,48(sp)
    80005684:	7ba2                	ld	s7,40(sp)
    80005686:	7c02                	ld	s8,32(sp)
    80005688:	6ce2                	ld	s9,24(sp)
    8000568a:	6165                	addi	sp,sp,112
    8000568c:	8082                	ret
      wakeup(&pi->nread);
    8000568e:	8566                	mv	a0,s9
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	6f6080e7          	jalr	1782(ra) # 80002d86 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005698:	85de                	mv	a1,s7
    8000569a:	8562                	mv	a0,s8
    8000569c:	ffffd097          	auipc	ra,0xffffd
    800056a0:	544080e7          	jalr	1348(ra) # 80002be0 <sleep>
    800056a4:	a839                	j	800056c2 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800056a6:	21c4a783          	lw	a5,540(s1)
    800056aa:	0017871b          	addiw	a4,a5,1
    800056ae:	20e4ae23          	sw	a4,540(s1)
    800056b2:	1ff7f793          	andi	a5,a5,511
    800056b6:	97a6                	add	a5,a5,s1
    800056b8:	f9f44703          	lbu	a4,-97(s0)
    800056bc:	00e78c23          	sb	a4,24(a5)
      i++;
    800056c0:	2905                	addiw	s2,s2,1
  while(i < n){
    800056c2:	03495d63          	bge	s2,s4,800056fc <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800056c6:	2204a783          	lw	a5,544(s1)
    800056ca:	dfd1                	beqz	a5,80005666 <pipewrite+0x48>
    800056cc:	0409a783          	lw	a5,64(s3)
    800056d0:	fbd9                	bnez	a5,80005666 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800056d2:	2184a783          	lw	a5,536(s1)
    800056d6:	21c4a703          	lw	a4,540(s1)
    800056da:	2007879b          	addiw	a5,a5,512
    800056de:	faf708e3          	beq	a4,a5,8000568e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800056e2:	4685                	li	a3,1
    800056e4:	01590633          	add	a2,s2,s5
    800056e8:	f9f40593          	addi	a1,s0,-97
    800056ec:	0789b503          	ld	a0,120(s3)
    800056f0:	ffffc097          	auipc	ra,0xffffc
    800056f4:	01c080e7          	jalr	28(ra) # 8000170c <copyin>
    800056f8:	fb6517e3          	bne	a0,s6,800056a6 <pipewrite+0x88>
  wakeup(&pi->nread);
    800056fc:	21848513          	addi	a0,s1,536
    80005700:	ffffd097          	auipc	ra,0xffffd
    80005704:	686080e7          	jalr	1670(ra) # 80002d86 <wakeup>
  release(&pi->lock);
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffb097          	auipc	ra,0xffffb
    8000570e:	59c080e7          	jalr	1436(ra) # 80000ca6 <release>
  return i;
    80005712:	b785                	j	80005672 <pipewrite+0x54>
  int i = 0;
    80005714:	4901                	li	s2,0
    80005716:	b7dd                	j	800056fc <pipewrite+0xde>

0000000080005718 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005718:	715d                	addi	sp,sp,-80
    8000571a:	e486                	sd	ra,72(sp)
    8000571c:	e0a2                	sd	s0,64(sp)
    8000571e:	fc26                	sd	s1,56(sp)
    80005720:	f84a                	sd	s2,48(sp)
    80005722:	f44e                	sd	s3,40(sp)
    80005724:	f052                	sd	s4,32(sp)
    80005726:	ec56                	sd	s5,24(sp)
    80005728:	e85a                	sd	s6,16(sp)
    8000572a:	0880                	addi	s0,sp,80
    8000572c:	84aa                	mv	s1,a0
    8000572e:	892e                	mv	s2,a1
    80005730:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005732:	ffffc097          	auipc	ra,0xffffc
    80005736:	672080e7          	jalr	1650(ra) # 80001da4 <myproc>
    8000573a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000573c:	8b26                	mv	s6,s1
    8000573e:	8526                	mv	a0,s1
    80005740:	ffffb097          	auipc	ra,0xffffb
    80005744:	4ac080e7          	jalr	1196(ra) # 80000bec <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005748:	2184a703          	lw	a4,536(s1)
    8000574c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005750:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005754:	02f71463          	bne	a4,a5,8000577c <piperead+0x64>
    80005758:	2244a783          	lw	a5,548(s1)
    8000575c:	c385                	beqz	a5,8000577c <piperead+0x64>
    if(pr->killed){
    8000575e:	040a2783          	lw	a5,64(s4)
    80005762:	ebc1                	bnez	a5,800057f2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005764:	85da                	mv	a1,s6
    80005766:	854e                	mv	a0,s3
    80005768:	ffffd097          	auipc	ra,0xffffd
    8000576c:	478080e7          	jalr	1144(ra) # 80002be0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005770:	2184a703          	lw	a4,536(s1)
    80005774:	21c4a783          	lw	a5,540(s1)
    80005778:	fef700e3          	beq	a4,a5,80005758 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000577c:	09505263          	blez	s5,80005800 <piperead+0xe8>
    80005780:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005782:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005784:	2184a783          	lw	a5,536(s1)
    80005788:	21c4a703          	lw	a4,540(s1)
    8000578c:	02f70d63          	beq	a4,a5,800057c6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005790:	0017871b          	addiw	a4,a5,1
    80005794:	20e4ac23          	sw	a4,536(s1)
    80005798:	1ff7f793          	andi	a5,a5,511
    8000579c:	97a6                	add	a5,a5,s1
    8000579e:	0187c783          	lbu	a5,24(a5)
    800057a2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057a6:	4685                	li	a3,1
    800057a8:	fbf40613          	addi	a2,s0,-65
    800057ac:	85ca                	mv	a1,s2
    800057ae:	078a3503          	ld	a0,120(s4)
    800057b2:	ffffc097          	auipc	ra,0xffffc
    800057b6:	ece080e7          	jalr	-306(ra) # 80001680 <copyout>
    800057ba:	01650663          	beq	a0,s6,800057c6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057be:	2985                	addiw	s3,s3,1
    800057c0:	0905                	addi	s2,s2,1
    800057c2:	fd3a91e3          	bne	s5,s3,80005784 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800057c6:	21c48513          	addi	a0,s1,540
    800057ca:	ffffd097          	auipc	ra,0xffffd
    800057ce:	5bc080e7          	jalr	1468(ra) # 80002d86 <wakeup>
  release(&pi->lock);
    800057d2:	8526                	mv	a0,s1
    800057d4:	ffffb097          	auipc	ra,0xffffb
    800057d8:	4d2080e7          	jalr	1234(ra) # 80000ca6 <release>
  return i;
}
    800057dc:	854e                	mv	a0,s3
    800057de:	60a6                	ld	ra,72(sp)
    800057e0:	6406                	ld	s0,64(sp)
    800057e2:	74e2                	ld	s1,56(sp)
    800057e4:	7942                	ld	s2,48(sp)
    800057e6:	79a2                	ld	s3,40(sp)
    800057e8:	7a02                	ld	s4,32(sp)
    800057ea:	6ae2                	ld	s5,24(sp)
    800057ec:	6b42                	ld	s6,16(sp)
    800057ee:	6161                	addi	sp,sp,80
    800057f0:	8082                	ret
      release(&pi->lock);
    800057f2:	8526                	mv	a0,s1
    800057f4:	ffffb097          	auipc	ra,0xffffb
    800057f8:	4b2080e7          	jalr	1202(ra) # 80000ca6 <release>
      return -1;
    800057fc:	59fd                	li	s3,-1
    800057fe:	bff9                	j	800057dc <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005800:	4981                	li	s3,0
    80005802:	b7d1                	j	800057c6 <piperead+0xae>

0000000080005804 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005804:	df010113          	addi	sp,sp,-528
    80005808:	20113423          	sd	ra,520(sp)
    8000580c:	20813023          	sd	s0,512(sp)
    80005810:	ffa6                	sd	s1,504(sp)
    80005812:	fbca                	sd	s2,496(sp)
    80005814:	f7ce                	sd	s3,488(sp)
    80005816:	f3d2                	sd	s4,480(sp)
    80005818:	efd6                	sd	s5,472(sp)
    8000581a:	ebda                	sd	s6,464(sp)
    8000581c:	e7de                	sd	s7,456(sp)
    8000581e:	e3e2                	sd	s8,448(sp)
    80005820:	ff66                	sd	s9,440(sp)
    80005822:	fb6a                	sd	s10,432(sp)
    80005824:	f76e                	sd	s11,424(sp)
    80005826:	0c00                	addi	s0,sp,528
    80005828:	84aa                	mv	s1,a0
    8000582a:	dea43c23          	sd	a0,-520(s0)
    8000582e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005832:	ffffc097          	auipc	ra,0xffffc
    80005836:	572080e7          	jalr	1394(ra) # 80001da4 <myproc>
    8000583a:	892a                	mv	s2,a0

  begin_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	49c080e7          	jalr	1180(ra) # 80004cd8 <begin_op>

  if((ip = namei(path)) == 0){
    80005844:	8526                	mv	a0,s1
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	276080e7          	jalr	630(ra) # 80004abc <namei>
    8000584e:	c92d                	beqz	a0,800058c0 <exec+0xbc>
    80005850:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	ab4080e7          	jalr	-1356(ra) # 80004306 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000585a:	04000713          	li	a4,64
    8000585e:	4681                	li	a3,0
    80005860:	e5040613          	addi	a2,s0,-432
    80005864:	4581                	li	a1,0
    80005866:	8526                	mv	a0,s1
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	d52080e7          	jalr	-686(ra) # 800045ba <readi>
    80005870:	04000793          	li	a5,64
    80005874:	00f51a63          	bne	a0,a5,80005888 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005878:	e5042703          	lw	a4,-432(s0)
    8000587c:	464c47b7          	lui	a5,0x464c4
    80005880:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005884:	04f70463          	beq	a4,a5,800058cc <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005888:	8526                	mv	a0,s1
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	cde080e7          	jalr	-802(ra) # 80004568 <iunlockput>
    end_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	4c6080e7          	jalr	1222(ra) # 80004d58 <end_op>
  }
  return -1;
    8000589a:	557d                	li	a0,-1
}
    8000589c:	20813083          	ld	ra,520(sp)
    800058a0:	20013403          	ld	s0,512(sp)
    800058a4:	74fe                	ld	s1,504(sp)
    800058a6:	795e                	ld	s2,496(sp)
    800058a8:	79be                	ld	s3,488(sp)
    800058aa:	7a1e                	ld	s4,480(sp)
    800058ac:	6afe                	ld	s5,472(sp)
    800058ae:	6b5e                	ld	s6,464(sp)
    800058b0:	6bbe                	ld	s7,456(sp)
    800058b2:	6c1e                	ld	s8,448(sp)
    800058b4:	7cfa                	ld	s9,440(sp)
    800058b6:	7d5a                	ld	s10,432(sp)
    800058b8:	7dba                	ld	s11,424(sp)
    800058ba:	21010113          	addi	sp,sp,528
    800058be:	8082                	ret
    end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	498080e7          	jalr	1176(ra) # 80004d58 <end_op>
    return -1;
    800058c8:	557d                	li	a0,-1
    800058ca:	bfc9                	j	8000589c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800058cc:	854a                	mv	a0,s2
    800058ce:	ffffc097          	auipc	ra,0xffffc
    800058d2:	5ae080e7          	jalr	1454(ra) # 80001e7c <proc_pagetable>
    800058d6:	8baa                	mv	s7,a0
    800058d8:	d945                	beqz	a0,80005888 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058da:	e7042983          	lw	s3,-400(s0)
    800058de:	e8845783          	lhu	a5,-376(s0)
    800058e2:	c7ad                	beqz	a5,8000594c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800058e4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058e6:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800058e8:	6c85                	lui	s9,0x1
    800058ea:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800058ee:	def43823          	sd	a5,-528(s0)
    800058f2:	a42d                	j	80005b1c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800058f4:	00003517          	auipc	a0,0x3
    800058f8:	f6450513          	addi	a0,a0,-156 # 80008858 <syscalls+0x290>
    800058fc:	ffffb097          	auipc	ra,0xffffb
    80005900:	c42080e7          	jalr	-958(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005904:	8756                	mv	a4,s5
    80005906:	012d86bb          	addw	a3,s11,s2
    8000590a:	4581                	li	a1,0
    8000590c:	8526                	mv	a0,s1
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	cac080e7          	jalr	-852(ra) # 800045ba <readi>
    80005916:	2501                	sext.w	a0,a0
    80005918:	1aaa9963          	bne	s5,a0,80005aca <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000591c:	6785                	lui	a5,0x1
    8000591e:	0127893b          	addw	s2,a5,s2
    80005922:	77fd                	lui	a5,0xfffff
    80005924:	01478a3b          	addw	s4,a5,s4
    80005928:	1f897163          	bgeu	s2,s8,80005b0a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000592c:	02091593          	slli	a1,s2,0x20
    80005930:	9181                	srli	a1,a1,0x20
    80005932:	95ea                	add	a1,a1,s10
    80005934:	855e                	mv	a0,s7
    80005936:	ffffb097          	auipc	ra,0xffffb
    8000593a:	746080e7          	jalr	1862(ra) # 8000107c <walkaddr>
    8000593e:	862a                	mv	a2,a0
    if(pa == 0)
    80005940:	d955                	beqz	a0,800058f4 <exec+0xf0>
      n = PGSIZE;
    80005942:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005944:	fd9a70e3          	bgeu	s4,s9,80005904 <exec+0x100>
      n = sz - i;
    80005948:	8ad2                	mv	s5,s4
    8000594a:	bf6d                	j	80005904 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000594c:	4901                	li	s2,0
  iunlockput(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	c18080e7          	jalr	-1000(ra) # 80004568 <iunlockput>
  end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	400080e7          	jalr	1024(ra) # 80004d58 <end_op>
  p = myproc();
    80005960:	ffffc097          	auipc	ra,0xffffc
    80005964:	444080e7          	jalr	1092(ra) # 80001da4 <myproc>
    80005968:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000596a:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    8000596e:	6785                	lui	a5,0x1
    80005970:	17fd                	addi	a5,a5,-1
    80005972:	993e                	add	s2,s2,a5
    80005974:	757d                	lui	a0,0xfffff
    80005976:	00a977b3          	and	a5,s2,a0
    8000597a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000597e:	6609                	lui	a2,0x2
    80005980:	963e                	add	a2,a2,a5
    80005982:	85be                	mv	a1,a5
    80005984:	855e                	mv	a0,s7
    80005986:	ffffc097          	auipc	ra,0xffffc
    8000598a:	aaa080e7          	jalr	-1366(ra) # 80001430 <uvmalloc>
    8000598e:	8b2a                	mv	s6,a0
  ip = 0;
    80005990:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005992:	12050c63          	beqz	a0,80005aca <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005996:	75f9                	lui	a1,0xffffe
    80005998:	95aa                	add	a1,a1,a0
    8000599a:	855e                	mv	a0,s7
    8000599c:	ffffc097          	auipc	ra,0xffffc
    800059a0:	cb2080e7          	jalr	-846(ra) # 8000164e <uvmclear>
  stackbase = sp - PGSIZE;
    800059a4:	7c7d                	lui	s8,0xfffff
    800059a6:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800059a8:	e0043783          	ld	a5,-512(s0)
    800059ac:	6388                	ld	a0,0(a5)
    800059ae:	c535                	beqz	a0,80005a1a <exec+0x216>
    800059b0:	e9040993          	addi	s3,s0,-368
    800059b4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800059b8:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800059ba:	ffffb097          	auipc	ra,0xffffb
    800059be:	4b8080e7          	jalr	1208(ra) # 80000e72 <strlen>
    800059c2:	2505                	addiw	a0,a0,1
    800059c4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800059c8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800059cc:	13896363          	bltu	s2,s8,80005af2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800059d0:	e0043d83          	ld	s11,-512(s0)
    800059d4:	000dba03          	ld	s4,0(s11)
    800059d8:	8552                	mv	a0,s4
    800059da:	ffffb097          	auipc	ra,0xffffb
    800059de:	498080e7          	jalr	1176(ra) # 80000e72 <strlen>
    800059e2:	0015069b          	addiw	a3,a0,1
    800059e6:	8652                	mv	a2,s4
    800059e8:	85ca                	mv	a1,s2
    800059ea:	855e                	mv	a0,s7
    800059ec:	ffffc097          	auipc	ra,0xffffc
    800059f0:	c94080e7          	jalr	-876(ra) # 80001680 <copyout>
    800059f4:	10054363          	bltz	a0,80005afa <exec+0x2f6>
    ustack[argc] = sp;
    800059f8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800059fc:	0485                	addi	s1,s1,1
    800059fe:	008d8793          	addi	a5,s11,8
    80005a02:	e0f43023          	sd	a5,-512(s0)
    80005a06:	008db503          	ld	a0,8(s11)
    80005a0a:	c911                	beqz	a0,80005a1e <exec+0x21a>
    if(argc >= MAXARG)
    80005a0c:	09a1                	addi	s3,s3,8
    80005a0e:	fb3c96e3          	bne	s9,s3,800059ba <exec+0x1b6>
  sz = sz1;
    80005a12:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a16:	4481                	li	s1,0
    80005a18:	a84d                	j	80005aca <exec+0x2c6>
  sp = sz;
    80005a1a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a1c:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a1e:	00349793          	slli	a5,s1,0x3
    80005a22:	f9040713          	addi	a4,s0,-112
    80005a26:	97ba                	add	a5,a5,a4
    80005a28:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005a2c:	00148693          	addi	a3,s1,1
    80005a30:	068e                	slli	a3,a3,0x3
    80005a32:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005a36:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005a3a:	01897663          	bgeu	s2,s8,80005a46 <exec+0x242>
  sz = sz1;
    80005a3e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a42:	4481                	li	s1,0
    80005a44:	a059                	j	80005aca <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005a46:	e9040613          	addi	a2,s0,-368
    80005a4a:	85ca                	mv	a1,s2
    80005a4c:	855e                	mv	a0,s7
    80005a4e:	ffffc097          	auipc	ra,0xffffc
    80005a52:	c32080e7          	jalr	-974(ra) # 80001680 <copyout>
    80005a56:	0a054663          	bltz	a0,80005b02 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005a5a:	080ab783          	ld	a5,128(s5)
    80005a5e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005a62:	df843783          	ld	a5,-520(s0)
    80005a66:	0007c703          	lbu	a4,0(a5)
    80005a6a:	cf11                	beqz	a4,80005a86 <exec+0x282>
    80005a6c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005a6e:	02f00693          	li	a3,47
    80005a72:	a039                	j	80005a80 <exec+0x27c>
      last = s+1;
    80005a74:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005a78:	0785                	addi	a5,a5,1
    80005a7a:	fff7c703          	lbu	a4,-1(a5)
    80005a7e:	c701                	beqz	a4,80005a86 <exec+0x282>
    if(*s == '/')
    80005a80:	fed71ce3          	bne	a4,a3,80005a78 <exec+0x274>
    80005a84:	bfc5                	j	80005a74 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005a86:	4641                	li	a2,16
    80005a88:	df843583          	ld	a1,-520(s0)
    80005a8c:	180a8513          	addi	a0,s5,384
    80005a90:	ffffb097          	auipc	ra,0xffffb
    80005a94:	3b0080e7          	jalr	944(ra) # 80000e40 <safestrcpy>
  oldpagetable = p->pagetable;
    80005a98:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    80005a9c:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    80005aa0:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005aa4:	080ab783          	ld	a5,128(s5)
    80005aa8:	e6843703          	ld	a4,-408(s0)
    80005aac:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005aae:	080ab783          	ld	a5,128(s5)
    80005ab2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005ab6:	85ea                	mv	a1,s10
    80005ab8:	ffffc097          	auipc	ra,0xffffc
    80005abc:	460080e7          	jalr	1120(ra) # 80001f18 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005ac0:	0004851b          	sext.w	a0,s1
    80005ac4:	bbe1                	j	8000589c <exec+0x98>
    80005ac6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005aca:	e0843583          	ld	a1,-504(s0)
    80005ace:	855e                	mv	a0,s7
    80005ad0:	ffffc097          	auipc	ra,0xffffc
    80005ad4:	448080e7          	jalr	1096(ra) # 80001f18 <proc_freepagetable>
  if(ip){
    80005ad8:	da0498e3          	bnez	s1,80005888 <exec+0x84>
  return -1;
    80005adc:	557d                	li	a0,-1
    80005ade:	bb7d                	j	8000589c <exec+0x98>
    80005ae0:	e1243423          	sd	s2,-504(s0)
    80005ae4:	b7dd                	j	80005aca <exec+0x2c6>
    80005ae6:	e1243423          	sd	s2,-504(s0)
    80005aea:	b7c5                	j	80005aca <exec+0x2c6>
    80005aec:	e1243423          	sd	s2,-504(s0)
    80005af0:	bfe9                	j	80005aca <exec+0x2c6>
  sz = sz1;
    80005af2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005af6:	4481                	li	s1,0
    80005af8:	bfc9                	j	80005aca <exec+0x2c6>
  sz = sz1;
    80005afa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005afe:	4481                	li	s1,0
    80005b00:	b7e9                	j	80005aca <exec+0x2c6>
  sz = sz1;
    80005b02:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b06:	4481                	li	s1,0
    80005b08:	b7c9                	j	80005aca <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005b0a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b0e:	2b05                	addiw	s6,s6,1
    80005b10:	0389899b          	addiw	s3,s3,56
    80005b14:	e8845783          	lhu	a5,-376(s0)
    80005b18:	e2fb5be3          	bge	s6,a5,8000594e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005b1c:	2981                	sext.w	s3,s3
    80005b1e:	03800713          	li	a4,56
    80005b22:	86ce                	mv	a3,s3
    80005b24:	e1840613          	addi	a2,s0,-488
    80005b28:	4581                	li	a1,0
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	a8e080e7          	jalr	-1394(ra) # 800045ba <readi>
    80005b34:	03800793          	li	a5,56
    80005b38:	f8f517e3          	bne	a0,a5,80005ac6 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005b3c:	e1842783          	lw	a5,-488(s0)
    80005b40:	4705                	li	a4,1
    80005b42:	fce796e3          	bne	a5,a4,80005b0e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005b46:	e4043603          	ld	a2,-448(s0)
    80005b4a:	e3843783          	ld	a5,-456(s0)
    80005b4e:	f8f669e3          	bltu	a2,a5,80005ae0 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005b52:	e2843783          	ld	a5,-472(s0)
    80005b56:	963e                	add	a2,a2,a5
    80005b58:	f8f667e3          	bltu	a2,a5,80005ae6 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005b5c:	85ca                	mv	a1,s2
    80005b5e:	855e                	mv	a0,s7
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	8d0080e7          	jalr	-1840(ra) # 80001430 <uvmalloc>
    80005b68:	e0a43423          	sd	a0,-504(s0)
    80005b6c:	d141                	beqz	a0,80005aec <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005b6e:	e2843d03          	ld	s10,-472(s0)
    80005b72:	df043783          	ld	a5,-528(s0)
    80005b76:	00fd77b3          	and	a5,s10,a5
    80005b7a:	fba1                	bnez	a5,80005aca <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b7c:	e2042d83          	lw	s11,-480(s0)
    80005b80:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005b84:	f80c03e3          	beqz	s8,80005b0a <exec+0x306>
    80005b88:	8a62                	mv	s4,s8
    80005b8a:	4901                	li	s2,0
    80005b8c:	b345                	j	8000592c <exec+0x128>

0000000080005b8e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005b8e:	7179                	addi	sp,sp,-48
    80005b90:	f406                	sd	ra,40(sp)
    80005b92:	f022                	sd	s0,32(sp)
    80005b94:	ec26                	sd	s1,24(sp)
    80005b96:	e84a                	sd	s2,16(sp)
    80005b98:	1800                	addi	s0,sp,48
    80005b9a:	892e                	mv	s2,a1
    80005b9c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005b9e:	fdc40593          	addi	a1,s0,-36
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	ba8080e7          	jalr	-1112(ra) # 8000374a <argint>
    80005baa:	04054063          	bltz	a0,80005bea <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005bae:	fdc42703          	lw	a4,-36(s0)
    80005bb2:	47bd                	li	a5,15
    80005bb4:	02e7ed63          	bltu	a5,a4,80005bee <argfd+0x60>
    80005bb8:	ffffc097          	auipc	ra,0xffffc
    80005bbc:	1ec080e7          	jalr	492(ra) # 80001da4 <myproc>
    80005bc0:	fdc42703          	lw	a4,-36(s0)
    80005bc4:	01e70793          	addi	a5,a4,30
    80005bc8:	078e                	slli	a5,a5,0x3
    80005bca:	953e                	add	a0,a0,a5
    80005bcc:	651c                	ld	a5,8(a0)
    80005bce:	c395                	beqz	a5,80005bf2 <argfd+0x64>
    return -1;
  if(pfd)
    80005bd0:	00090463          	beqz	s2,80005bd8 <argfd+0x4a>
    *pfd = fd;
    80005bd4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005bd8:	4501                	li	a0,0
  if(pf)
    80005bda:	c091                	beqz	s1,80005bde <argfd+0x50>
    *pf = f;
    80005bdc:	e09c                	sd	a5,0(s1)
}
    80005bde:	70a2                	ld	ra,40(sp)
    80005be0:	7402                	ld	s0,32(sp)
    80005be2:	64e2                	ld	s1,24(sp)
    80005be4:	6942                	ld	s2,16(sp)
    80005be6:	6145                	addi	sp,sp,48
    80005be8:	8082                	ret
    return -1;
    80005bea:	557d                	li	a0,-1
    80005bec:	bfcd                	j	80005bde <argfd+0x50>
    return -1;
    80005bee:	557d                	li	a0,-1
    80005bf0:	b7fd                	j	80005bde <argfd+0x50>
    80005bf2:	557d                	li	a0,-1
    80005bf4:	b7ed                	j	80005bde <argfd+0x50>

0000000080005bf6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005bf6:	1101                	addi	sp,sp,-32
    80005bf8:	ec06                	sd	ra,24(sp)
    80005bfa:	e822                	sd	s0,16(sp)
    80005bfc:	e426                	sd	s1,8(sp)
    80005bfe:	1000                	addi	s0,sp,32
    80005c00:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005c02:	ffffc097          	auipc	ra,0xffffc
    80005c06:	1a2080e7          	jalr	418(ra) # 80001da4 <myproc>
    80005c0a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005c0c:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    80005c10:	4501                	li	a0,0
    80005c12:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005c14:	6398                	ld	a4,0(a5)
    80005c16:	cb19                	beqz	a4,80005c2c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005c18:	2505                	addiw	a0,a0,1
    80005c1a:	07a1                	addi	a5,a5,8
    80005c1c:	fed51ce3          	bne	a0,a3,80005c14 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005c20:	557d                	li	a0,-1
}
    80005c22:	60e2                	ld	ra,24(sp)
    80005c24:	6442                	ld	s0,16(sp)
    80005c26:	64a2                	ld	s1,8(sp)
    80005c28:	6105                	addi	sp,sp,32
    80005c2a:	8082                	ret
      p->ofile[fd] = f;
    80005c2c:	01e50793          	addi	a5,a0,30
    80005c30:	078e                	slli	a5,a5,0x3
    80005c32:	963e                	add	a2,a2,a5
    80005c34:	e604                	sd	s1,8(a2)
      return fd;
    80005c36:	b7f5                	j	80005c22 <fdalloc+0x2c>

0000000080005c38 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005c38:	715d                	addi	sp,sp,-80
    80005c3a:	e486                	sd	ra,72(sp)
    80005c3c:	e0a2                	sd	s0,64(sp)
    80005c3e:	fc26                	sd	s1,56(sp)
    80005c40:	f84a                	sd	s2,48(sp)
    80005c42:	f44e                	sd	s3,40(sp)
    80005c44:	f052                	sd	s4,32(sp)
    80005c46:	ec56                	sd	s5,24(sp)
    80005c48:	0880                	addi	s0,sp,80
    80005c4a:	89ae                	mv	s3,a1
    80005c4c:	8ab2                	mv	s5,a2
    80005c4e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005c50:	fb040593          	addi	a1,s0,-80
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	e86080e7          	jalr	-378(ra) # 80004ada <nameiparent>
    80005c5c:	892a                	mv	s2,a0
    80005c5e:	12050f63          	beqz	a0,80005d9c <create+0x164>
    return 0;

  ilock(dp);
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	6a4080e7          	jalr	1700(ra) # 80004306 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005c6a:	4601                	li	a2,0
    80005c6c:	fb040593          	addi	a1,s0,-80
    80005c70:	854a                	mv	a0,s2
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	b78080e7          	jalr	-1160(ra) # 800047ea <dirlookup>
    80005c7a:	84aa                	mv	s1,a0
    80005c7c:	c921                	beqz	a0,80005ccc <create+0x94>
    iunlockput(dp);
    80005c7e:	854a                	mv	a0,s2
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	8e8080e7          	jalr	-1816(ra) # 80004568 <iunlockput>
    ilock(ip);
    80005c88:	8526                	mv	a0,s1
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	67c080e7          	jalr	1660(ra) # 80004306 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c92:	2981                	sext.w	s3,s3
    80005c94:	4789                	li	a5,2
    80005c96:	02f99463          	bne	s3,a5,80005cbe <create+0x86>
    80005c9a:	0444d783          	lhu	a5,68(s1)
    80005c9e:	37f9                	addiw	a5,a5,-2
    80005ca0:	17c2                	slli	a5,a5,0x30
    80005ca2:	93c1                	srli	a5,a5,0x30
    80005ca4:	4705                	li	a4,1
    80005ca6:	00f76c63          	bltu	a4,a5,80005cbe <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005caa:	8526                	mv	a0,s1
    80005cac:	60a6                	ld	ra,72(sp)
    80005cae:	6406                	ld	s0,64(sp)
    80005cb0:	74e2                	ld	s1,56(sp)
    80005cb2:	7942                	ld	s2,48(sp)
    80005cb4:	79a2                	ld	s3,40(sp)
    80005cb6:	7a02                	ld	s4,32(sp)
    80005cb8:	6ae2                	ld	s5,24(sp)
    80005cba:	6161                	addi	sp,sp,80
    80005cbc:	8082                	ret
    iunlockput(ip);
    80005cbe:	8526                	mv	a0,s1
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	8a8080e7          	jalr	-1880(ra) # 80004568 <iunlockput>
    return 0;
    80005cc8:	4481                	li	s1,0
    80005cca:	b7c5                	j	80005caa <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005ccc:	85ce                	mv	a1,s3
    80005cce:	00092503          	lw	a0,0(s2)
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	49c080e7          	jalr	1180(ra) # 8000416e <ialloc>
    80005cda:	84aa                	mv	s1,a0
    80005cdc:	c529                	beqz	a0,80005d26 <create+0xee>
  ilock(ip);
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	628080e7          	jalr	1576(ra) # 80004306 <ilock>
  ip->major = major;
    80005ce6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005cea:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005cee:	4785                	li	a5,1
    80005cf0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005cf4:	8526                	mv	a0,s1
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	546080e7          	jalr	1350(ra) # 8000423c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005cfe:	2981                	sext.w	s3,s3
    80005d00:	4785                	li	a5,1
    80005d02:	02f98a63          	beq	s3,a5,80005d36 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005d06:	40d0                	lw	a2,4(s1)
    80005d08:	fb040593          	addi	a1,s0,-80
    80005d0c:	854a                	mv	a0,s2
    80005d0e:	fffff097          	auipc	ra,0xfffff
    80005d12:	cec080e7          	jalr	-788(ra) # 800049fa <dirlink>
    80005d16:	06054b63          	bltz	a0,80005d8c <create+0x154>
  iunlockput(dp);
    80005d1a:	854a                	mv	a0,s2
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	84c080e7          	jalr	-1972(ra) # 80004568 <iunlockput>
  return ip;
    80005d24:	b759                	j	80005caa <create+0x72>
    panic("create: ialloc");
    80005d26:	00003517          	auipc	a0,0x3
    80005d2a:	b5250513          	addi	a0,a0,-1198 # 80008878 <syscalls+0x2b0>
    80005d2e:	ffffb097          	auipc	ra,0xffffb
    80005d32:	810080e7          	jalr	-2032(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005d36:	04a95783          	lhu	a5,74(s2)
    80005d3a:	2785                	addiw	a5,a5,1
    80005d3c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005d40:	854a                	mv	a0,s2
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	4fa080e7          	jalr	1274(ra) # 8000423c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005d4a:	40d0                	lw	a2,4(s1)
    80005d4c:	00003597          	auipc	a1,0x3
    80005d50:	b3c58593          	addi	a1,a1,-1220 # 80008888 <syscalls+0x2c0>
    80005d54:	8526                	mv	a0,s1
    80005d56:	fffff097          	auipc	ra,0xfffff
    80005d5a:	ca4080e7          	jalr	-860(ra) # 800049fa <dirlink>
    80005d5e:	00054f63          	bltz	a0,80005d7c <create+0x144>
    80005d62:	00492603          	lw	a2,4(s2)
    80005d66:	00003597          	auipc	a1,0x3
    80005d6a:	b2a58593          	addi	a1,a1,-1238 # 80008890 <syscalls+0x2c8>
    80005d6e:	8526                	mv	a0,s1
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	c8a080e7          	jalr	-886(ra) # 800049fa <dirlink>
    80005d78:	f80557e3          	bgez	a0,80005d06 <create+0xce>
      panic("create dots");
    80005d7c:	00003517          	auipc	a0,0x3
    80005d80:	b1c50513          	addi	a0,a0,-1252 # 80008898 <syscalls+0x2d0>
    80005d84:	ffffa097          	auipc	ra,0xffffa
    80005d88:	7ba080e7          	jalr	1978(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005d8c:	00003517          	auipc	a0,0x3
    80005d90:	b1c50513          	addi	a0,a0,-1252 # 800088a8 <syscalls+0x2e0>
    80005d94:	ffffa097          	auipc	ra,0xffffa
    80005d98:	7aa080e7          	jalr	1962(ra) # 8000053e <panic>
    return 0;
    80005d9c:	84aa                	mv	s1,a0
    80005d9e:	b731                	j	80005caa <create+0x72>

0000000080005da0 <sys_dup>:
{
    80005da0:	7179                	addi	sp,sp,-48
    80005da2:	f406                	sd	ra,40(sp)
    80005da4:	f022                	sd	s0,32(sp)
    80005da6:	ec26                	sd	s1,24(sp)
    80005da8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005daa:	fd840613          	addi	a2,s0,-40
    80005dae:	4581                	li	a1,0
    80005db0:	4501                	li	a0,0
    80005db2:	00000097          	auipc	ra,0x0
    80005db6:	ddc080e7          	jalr	-548(ra) # 80005b8e <argfd>
    return -1;
    80005dba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005dbc:	02054363          	bltz	a0,80005de2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005dc0:	fd843503          	ld	a0,-40(s0)
    80005dc4:	00000097          	auipc	ra,0x0
    80005dc8:	e32080e7          	jalr	-462(ra) # 80005bf6 <fdalloc>
    80005dcc:	84aa                	mv	s1,a0
    return -1;
    80005dce:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005dd0:	00054963          	bltz	a0,80005de2 <sys_dup+0x42>
  filedup(f);
    80005dd4:	fd843503          	ld	a0,-40(s0)
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	37a080e7          	jalr	890(ra) # 80005152 <filedup>
  return fd;
    80005de0:	87a6                	mv	a5,s1
}
    80005de2:	853e                	mv	a0,a5
    80005de4:	70a2                	ld	ra,40(sp)
    80005de6:	7402                	ld	s0,32(sp)
    80005de8:	64e2                	ld	s1,24(sp)
    80005dea:	6145                	addi	sp,sp,48
    80005dec:	8082                	ret

0000000080005dee <sys_read>:
{
    80005dee:	7179                	addi	sp,sp,-48
    80005df0:	f406                	sd	ra,40(sp)
    80005df2:	f022                	sd	s0,32(sp)
    80005df4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005df6:	fe840613          	addi	a2,s0,-24
    80005dfa:	4581                	li	a1,0
    80005dfc:	4501                	li	a0,0
    80005dfe:	00000097          	auipc	ra,0x0
    80005e02:	d90080e7          	jalr	-624(ra) # 80005b8e <argfd>
    return -1;
    80005e06:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e08:	04054163          	bltz	a0,80005e4a <sys_read+0x5c>
    80005e0c:	fe440593          	addi	a1,s0,-28
    80005e10:	4509                	li	a0,2
    80005e12:	ffffe097          	auipc	ra,0xffffe
    80005e16:	938080e7          	jalr	-1736(ra) # 8000374a <argint>
    return -1;
    80005e1a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e1c:	02054763          	bltz	a0,80005e4a <sys_read+0x5c>
    80005e20:	fd840593          	addi	a1,s0,-40
    80005e24:	4505                	li	a0,1
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	946080e7          	jalr	-1722(ra) # 8000376c <argaddr>
    return -1;
    80005e2e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e30:	00054d63          	bltz	a0,80005e4a <sys_read+0x5c>
  return fileread(f, p, n);
    80005e34:	fe442603          	lw	a2,-28(s0)
    80005e38:	fd843583          	ld	a1,-40(s0)
    80005e3c:	fe843503          	ld	a0,-24(s0)
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	49e080e7          	jalr	1182(ra) # 800052de <fileread>
    80005e48:	87aa                	mv	a5,a0
}
    80005e4a:	853e                	mv	a0,a5
    80005e4c:	70a2                	ld	ra,40(sp)
    80005e4e:	7402                	ld	s0,32(sp)
    80005e50:	6145                	addi	sp,sp,48
    80005e52:	8082                	ret

0000000080005e54 <sys_write>:
{
    80005e54:	7179                	addi	sp,sp,-48
    80005e56:	f406                	sd	ra,40(sp)
    80005e58:	f022                	sd	s0,32(sp)
    80005e5a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e5c:	fe840613          	addi	a2,s0,-24
    80005e60:	4581                	li	a1,0
    80005e62:	4501                	li	a0,0
    80005e64:	00000097          	auipc	ra,0x0
    80005e68:	d2a080e7          	jalr	-726(ra) # 80005b8e <argfd>
    return -1;
    80005e6c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e6e:	04054163          	bltz	a0,80005eb0 <sys_write+0x5c>
    80005e72:	fe440593          	addi	a1,s0,-28
    80005e76:	4509                	li	a0,2
    80005e78:	ffffe097          	auipc	ra,0xffffe
    80005e7c:	8d2080e7          	jalr	-1838(ra) # 8000374a <argint>
    return -1;
    80005e80:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e82:	02054763          	bltz	a0,80005eb0 <sys_write+0x5c>
    80005e86:	fd840593          	addi	a1,s0,-40
    80005e8a:	4505                	li	a0,1
    80005e8c:	ffffe097          	auipc	ra,0xffffe
    80005e90:	8e0080e7          	jalr	-1824(ra) # 8000376c <argaddr>
    return -1;
    80005e94:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e96:	00054d63          	bltz	a0,80005eb0 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005e9a:	fe442603          	lw	a2,-28(s0)
    80005e9e:	fd843583          	ld	a1,-40(s0)
    80005ea2:	fe843503          	ld	a0,-24(s0)
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	4fa080e7          	jalr	1274(ra) # 800053a0 <filewrite>
    80005eae:	87aa                	mv	a5,a0
}
    80005eb0:	853e                	mv	a0,a5
    80005eb2:	70a2                	ld	ra,40(sp)
    80005eb4:	7402                	ld	s0,32(sp)
    80005eb6:	6145                	addi	sp,sp,48
    80005eb8:	8082                	ret

0000000080005eba <sys_close>:
{
    80005eba:	1101                	addi	sp,sp,-32
    80005ebc:	ec06                	sd	ra,24(sp)
    80005ebe:	e822                	sd	s0,16(sp)
    80005ec0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005ec2:	fe040613          	addi	a2,s0,-32
    80005ec6:	fec40593          	addi	a1,s0,-20
    80005eca:	4501                	li	a0,0
    80005ecc:	00000097          	auipc	ra,0x0
    80005ed0:	cc2080e7          	jalr	-830(ra) # 80005b8e <argfd>
    return -1;
    80005ed4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ed6:	02054463          	bltz	a0,80005efe <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005eda:	ffffc097          	auipc	ra,0xffffc
    80005ede:	eca080e7          	jalr	-310(ra) # 80001da4 <myproc>
    80005ee2:	fec42783          	lw	a5,-20(s0)
    80005ee6:	07f9                	addi	a5,a5,30
    80005ee8:	078e                	slli	a5,a5,0x3
    80005eea:	97aa                	add	a5,a5,a0
    80005eec:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005ef0:	fe043503          	ld	a0,-32(s0)
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	2b0080e7          	jalr	688(ra) # 800051a4 <fileclose>
  return 0;
    80005efc:	4781                	li	a5,0
}
    80005efe:	853e                	mv	a0,a5
    80005f00:	60e2                	ld	ra,24(sp)
    80005f02:	6442                	ld	s0,16(sp)
    80005f04:	6105                	addi	sp,sp,32
    80005f06:	8082                	ret

0000000080005f08 <sys_fstat>:
{
    80005f08:	1101                	addi	sp,sp,-32
    80005f0a:	ec06                	sd	ra,24(sp)
    80005f0c:	e822                	sd	s0,16(sp)
    80005f0e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f10:	fe840613          	addi	a2,s0,-24
    80005f14:	4581                	li	a1,0
    80005f16:	4501                	li	a0,0
    80005f18:	00000097          	auipc	ra,0x0
    80005f1c:	c76080e7          	jalr	-906(ra) # 80005b8e <argfd>
    return -1;
    80005f20:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f22:	02054563          	bltz	a0,80005f4c <sys_fstat+0x44>
    80005f26:	fe040593          	addi	a1,s0,-32
    80005f2a:	4505                	li	a0,1
    80005f2c:	ffffe097          	auipc	ra,0xffffe
    80005f30:	840080e7          	jalr	-1984(ra) # 8000376c <argaddr>
    return -1;
    80005f34:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005f36:	00054b63          	bltz	a0,80005f4c <sys_fstat+0x44>
  return filestat(f, st);
    80005f3a:	fe043583          	ld	a1,-32(s0)
    80005f3e:	fe843503          	ld	a0,-24(s0)
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	32a080e7          	jalr	810(ra) # 8000526c <filestat>
    80005f4a:	87aa                	mv	a5,a0
}
    80005f4c:	853e                	mv	a0,a5
    80005f4e:	60e2                	ld	ra,24(sp)
    80005f50:	6442                	ld	s0,16(sp)
    80005f52:	6105                	addi	sp,sp,32
    80005f54:	8082                	ret

0000000080005f56 <sys_link>:
{
    80005f56:	7169                	addi	sp,sp,-304
    80005f58:	f606                	sd	ra,296(sp)
    80005f5a:	f222                	sd	s0,288(sp)
    80005f5c:	ee26                	sd	s1,280(sp)
    80005f5e:	ea4a                	sd	s2,272(sp)
    80005f60:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f62:	08000613          	li	a2,128
    80005f66:	ed040593          	addi	a1,s0,-304
    80005f6a:	4501                	li	a0,0
    80005f6c:	ffffe097          	auipc	ra,0xffffe
    80005f70:	822080e7          	jalr	-2014(ra) # 8000378e <argstr>
    return -1;
    80005f74:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f76:	10054e63          	bltz	a0,80006092 <sys_link+0x13c>
    80005f7a:	08000613          	li	a2,128
    80005f7e:	f5040593          	addi	a1,s0,-176
    80005f82:	4505                	li	a0,1
    80005f84:	ffffe097          	auipc	ra,0xffffe
    80005f88:	80a080e7          	jalr	-2038(ra) # 8000378e <argstr>
    return -1;
    80005f8c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f8e:	10054263          	bltz	a0,80006092 <sys_link+0x13c>
  begin_op();
    80005f92:	fffff097          	auipc	ra,0xfffff
    80005f96:	d46080e7          	jalr	-698(ra) # 80004cd8 <begin_op>
  if((ip = namei(old)) == 0){
    80005f9a:	ed040513          	addi	a0,s0,-304
    80005f9e:	fffff097          	auipc	ra,0xfffff
    80005fa2:	b1e080e7          	jalr	-1250(ra) # 80004abc <namei>
    80005fa6:	84aa                	mv	s1,a0
    80005fa8:	c551                	beqz	a0,80006034 <sys_link+0xde>
  ilock(ip);
    80005faa:	ffffe097          	auipc	ra,0xffffe
    80005fae:	35c080e7          	jalr	860(ra) # 80004306 <ilock>
  if(ip->type == T_DIR){
    80005fb2:	04449703          	lh	a4,68(s1)
    80005fb6:	4785                	li	a5,1
    80005fb8:	08f70463          	beq	a4,a5,80006040 <sys_link+0xea>
  ip->nlink++;
    80005fbc:	04a4d783          	lhu	a5,74(s1)
    80005fc0:	2785                	addiw	a5,a5,1
    80005fc2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005fc6:	8526                	mv	a0,s1
    80005fc8:	ffffe097          	auipc	ra,0xffffe
    80005fcc:	274080e7          	jalr	628(ra) # 8000423c <iupdate>
  iunlock(ip);
    80005fd0:	8526                	mv	a0,s1
    80005fd2:	ffffe097          	auipc	ra,0xffffe
    80005fd6:	3f6080e7          	jalr	1014(ra) # 800043c8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005fda:	fd040593          	addi	a1,s0,-48
    80005fde:	f5040513          	addi	a0,s0,-176
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	af8080e7          	jalr	-1288(ra) # 80004ada <nameiparent>
    80005fea:	892a                	mv	s2,a0
    80005fec:	c935                	beqz	a0,80006060 <sys_link+0x10a>
  ilock(dp);
    80005fee:	ffffe097          	auipc	ra,0xffffe
    80005ff2:	318080e7          	jalr	792(ra) # 80004306 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ff6:	00092703          	lw	a4,0(s2)
    80005ffa:	409c                	lw	a5,0(s1)
    80005ffc:	04f71d63          	bne	a4,a5,80006056 <sys_link+0x100>
    80006000:	40d0                	lw	a2,4(s1)
    80006002:	fd040593          	addi	a1,s0,-48
    80006006:	854a                	mv	a0,s2
    80006008:	fffff097          	auipc	ra,0xfffff
    8000600c:	9f2080e7          	jalr	-1550(ra) # 800049fa <dirlink>
    80006010:	04054363          	bltz	a0,80006056 <sys_link+0x100>
  iunlockput(dp);
    80006014:	854a                	mv	a0,s2
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	552080e7          	jalr	1362(ra) # 80004568 <iunlockput>
  iput(ip);
    8000601e:	8526                	mv	a0,s1
    80006020:	ffffe097          	auipc	ra,0xffffe
    80006024:	4a0080e7          	jalr	1184(ra) # 800044c0 <iput>
  end_op();
    80006028:	fffff097          	auipc	ra,0xfffff
    8000602c:	d30080e7          	jalr	-720(ra) # 80004d58 <end_op>
  return 0;
    80006030:	4781                	li	a5,0
    80006032:	a085                	j	80006092 <sys_link+0x13c>
    end_op();
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	d24080e7          	jalr	-732(ra) # 80004d58 <end_op>
    return -1;
    8000603c:	57fd                	li	a5,-1
    8000603e:	a891                	j	80006092 <sys_link+0x13c>
    iunlockput(ip);
    80006040:	8526                	mv	a0,s1
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	526080e7          	jalr	1318(ra) # 80004568 <iunlockput>
    end_op();
    8000604a:	fffff097          	auipc	ra,0xfffff
    8000604e:	d0e080e7          	jalr	-754(ra) # 80004d58 <end_op>
    return -1;
    80006052:	57fd                	li	a5,-1
    80006054:	a83d                	j	80006092 <sys_link+0x13c>
    iunlockput(dp);
    80006056:	854a                	mv	a0,s2
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	510080e7          	jalr	1296(ra) # 80004568 <iunlockput>
  ilock(ip);
    80006060:	8526                	mv	a0,s1
    80006062:	ffffe097          	auipc	ra,0xffffe
    80006066:	2a4080e7          	jalr	676(ra) # 80004306 <ilock>
  ip->nlink--;
    8000606a:	04a4d783          	lhu	a5,74(s1)
    8000606e:	37fd                	addiw	a5,a5,-1
    80006070:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006074:	8526                	mv	a0,s1
    80006076:	ffffe097          	auipc	ra,0xffffe
    8000607a:	1c6080e7          	jalr	454(ra) # 8000423c <iupdate>
  iunlockput(ip);
    8000607e:	8526                	mv	a0,s1
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	4e8080e7          	jalr	1256(ra) # 80004568 <iunlockput>
  end_op();
    80006088:	fffff097          	auipc	ra,0xfffff
    8000608c:	cd0080e7          	jalr	-816(ra) # 80004d58 <end_op>
  return -1;
    80006090:	57fd                	li	a5,-1
}
    80006092:	853e                	mv	a0,a5
    80006094:	70b2                	ld	ra,296(sp)
    80006096:	7412                	ld	s0,288(sp)
    80006098:	64f2                	ld	s1,280(sp)
    8000609a:	6952                	ld	s2,272(sp)
    8000609c:	6155                	addi	sp,sp,304
    8000609e:	8082                	ret

00000000800060a0 <sys_unlink>:
{
    800060a0:	7151                	addi	sp,sp,-240
    800060a2:	f586                	sd	ra,232(sp)
    800060a4:	f1a2                	sd	s0,224(sp)
    800060a6:	eda6                	sd	s1,216(sp)
    800060a8:	e9ca                	sd	s2,208(sp)
    800060aa:	e5ce                	sd	s3,200(sp)
    800060ac:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800060ae:	08000613          	li	a2,128
    800060b2:	f3040593          	addi	a1,s0,-208
    800060b6:	4501                	li	a0,0
    800060b8:	ffffd097          	auipc	ra,0xffffd
    800060bc:	6d6080e7          	jalr	1750(ra) # 8000378e <argstr>
    800060c0:	18054163          	bltz	a0,80006242 <sys_unlink+0x1a2>
  begin_op();
    800060c4:	fffff097          	auipc	ra,0xfffff
    800060c8:	c14080e7          	jalr	-1004(ra) # 80004cd8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800060cc:	fb040593          	addi	a1,s0,-80
    800060d0:	f3040513          	addi	a0,s0,-208
    800060d4:	fffff097          	auipc	ra,0xfffff
    800060d8:	a06080e7          	jalr	-1530(ra) # 80004ada <nameiparent>
    800060dc:	84aa                	mv	s1,a0
    800060de:	c979                	beqz	a0,800061b4 <sys_unlink+0x114>
  ilock(dp);
    800060e0:	ffffe097          	auipc	ra,0xffffe
    800060e4:	226080e7          	jalr	550(ra) # 80004306 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800060e8:	00002597          	auipc	a1,0x2
    800060ec:	7a058593          	addi	a1,a1,1952 # 80008888 <syscalls+0x2c0>
    800060f0:	fb040513          	addi	a0,s0,-80
    800060f4:	ffffe097          	auipc	ra,0xffffe
    800060f8:	6dc080e7          	jalr	1756(ra) # 800047d0 <namecmp>
    800060fc:	14050a63          	beqz	a0,80006250 <sys_unlink+0x1b0>
    80006100:	00002597          	auipc	a1,0x2
    80006104:	79058593          	addi	a1,a1,1936 # 80008890 <syscalls+0x2c8>
    80006108:	fb040513          	addi	a0,s0,-80
    8000610c:	ffffe097          	auipc	ra,0xffffe
    80006110:	6c4080e7          	jalr	1732(ra) # 800047d0 <namecmp>
    80006114:	12050e63          	beqz	a0,80006250 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006118:	f2c40613          	addi	a2,s0,-212
    8000611c:	fb040593          	addi	a1,s0,-80
    80006120:	8526                	mv	a0,s1
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	6c8080e7          	jalr	1736(ra) # 800047ea <dirlookup>
    8000612a:	892a                	mv	s2,a0
    8000612c:	12050263          	beqz	a0,80006250 <sys_unlink+0x1b0>
  ilock(ip);
    80006130:	ffffe097          	auipc	ra,0xffffe
    80006134:	1d6080e7          	jalr	470(ra) # 80004306 <ilock>
  if(ip->nlink < 1)
    80006138:	04a91783          	lh	a5,74(s2)
    8000613c:	08f05263          	blez	a5,800061c0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006140:	04491703          	lh	a4,68(s2)
    80006144:	4785                	li	a5,1
    80006146:	08f70563          	beq	a4,a5,800061d0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000614a:	4641                	li	a2,16
    8000614c:	4581                	li	a1,0
    8000614e:	fc040513          	addi	a0,s0,-64
    80006152:	ffffb097          	auipc	ra,0xffffb
    80006156:	b9c080e7          	jalr	-1124(ra) # 80000cee <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000615a:	4741                	li	a4,16
    8000615c:	f2c42683          	lw	a3,-212(s0)
    80006160:	fc040613          	addi	a2,s0,-64
    80006164:	4581                	li	a1,0
    80006166:	8526                	mv	a0,s1
    80006168:	ffffe097          	auipc	ra,0xffffe
    8000616c:	54a080e7          	jalr	1354(ra) # 800046b2 <writei>
    80006170:	47c1                	li	a5,16
    80006172:	0af51563          	bne	a0,a5,8000621c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006176:	04491703          	lh	a4,68(s2)
    8000617a:	4785                	li	a5,1
    8000617c:	0af70863          	beq	a4,a5,8000622c <sys_unlink+0x18c>
  iunlockput(dp);
    80006180:	8526                	mv	a0,s1
    80006182:	ffffe097          	auipc	ra,0xffffe
    80006186:	3e6080e7          	jalr	998(ra) # 80004568 <iunlockput>
  ip->nlink--;
    8000618a:	04a95783          	lhu	a5,74(s2)
    8000618e:	37fd                	addiw	a5,a5,-1
    80006190:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006194:	854a                	mv	a0,s2
    80006196:	ffffe097          	auipc	ra,0xffffe
    8000619a:	0a6080e7          	jalr	166(ra) # 8000423c <iupdate>
  iunlockput(ip);
    8000619e:	854a                	mv	a0,s2
    800061a0:	ffffe097          	auipc	ra,0xffffe
    800061a4:	3c8080e7          	jalr	968(ra) # 80004568 <iunlockput>
  end_op();
    800061a8:	fffff097          	auipc	ra,0xfffff
    800061ac:	bb0080e7          	jalr	-1104(ra) # 80004d58 <end_op>
  return 0;
    800061b0:	4501                	li	a0,0
    800061b2:	a84d                	j	80006264 <sys_unlink+0x1c4>
    end_op();
    800061b4:	fffff097          	auipc	ra,0xfffff
    800061b8:	ba4080e7          	jalr	-1116(ra) # 80004d58 <end_op>
    return -1;
    800061bc:	557d                	li	a0,-1
    800061be:	a05d                	j	80006264 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800061c0:	00002517          	auipc	a0,0x2
    800061c4:	6f850513          	addi	a0,a0,1784 # 800088b8 <syscalls+0x2f0>
    800061c8:	ffffa097          	auipc	ra,0xffffa
    800061cc:	376080e7          	jalr	886(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061d0:	04c92703          	lw	a4,76(s2)
    800061d4:	02000793          	li	a5,32
    800061d8:	f6e7f9e3          	bgeu	a5,a4,8000614a <sys_unlink+0xaa>
    800061dc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061e0:	4741                	li	a4,16
    800061e2:	86ce                	mv	a3,s3
    800061e4:	f1840613          	addi	a2,s0,-232
    800061e8:	4581                	li	a1,0
    800061ea:	854a                	mv	a0,s2
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	3ce080e7          	jalr	974(ra) # 800045ba <readi>
    800061f4:	47c1                	li	a5,16
    800061f6:	00f51b63          	bne	a0,a5,8000620c <sys_unlink+0x16c>
    if(de.inum != 0)
    800061fa:	f1845783          	lhu	a5,-232(s0)
    800061fe:	e7a1                	bnez	a5,80006246 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006200:	29c1                	addiw	s3,s3,16
    80006202:	04c92783          	lw	a5,76(s2)
    80006206:	fcf9ede3          	bltu	s3,a5,800061e0 <sys_unlink+0x140>
    8000620a:	b781                	j	8000614a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000620c:	00002517          	auipc	a0,0x2
    80006210:	6c450513          	addi	a0,a0,1732 # 800088d0 <syscalls+0x308>
    80006214:	ffffa097          	auipc	ra,0xffffa
    80006218:	32a080e7          	jalr	810(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000621c:	00002517          	auipc	a0,0x2
    80006220:	6cc50513          	addi	a0,a0,1740 # 800088e8 <syscalls+0x320>
    80006224:	ffffa097          	auipc	ra,0xffffa
    80006228:	31a080e7          	jalr	794(ra) # 8000053e <panic>
    dp->nlink--;
    8000622c:	04a4d783          	lhu	a5,74(s1)
    80006230:	37fd                	addiw	a5,a5,-1
    80006232:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006236:	8526                	mv	a0,s1
    80006238:	ffffe097          	auipc	ra,0xffffe
    8000623c:	004080e7          	jalr	4(ra) # 8000423c <iupdate>
    80006240:	b781                	j	80006180 <sys_unlink+0xe0>
    return -1;
    80006242:	557d                	li	a0,-1
    80006244:	a005                	j	80006264 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006246:	854a                	mv	a0,s2
    80006248:	ffffe097          	auipc	ra,0xffffe
    8000624c:	320080e7          	jalr	800(ra) # 80004568 <iunlockput>
  iunlockput(dp);
    80006250:	8526                	mv	a0,s1
    80006252:	ffffe097          	auipc	ra,0xffffe
    80006256:	316080e7          	jalr	790(ra) # 80004568 <iunlockput>
  end_op();
    8000625a:	fffff097          	auipc	ra,0xfffff
    8000625e:	afe080e7          	jalr	-1282(ra) # 80004d58 <end_op>
  return -1;
    80006262:	557d                	li	a0,-1
}
    80006264:	70ae                	ld	ra,232(sp)
    80006266:	740e                	ld	s0,224(sp)
    80006268:	64ee                	ld	s1,216(sp)
    8000626a:	694e                	ld	s2,208(sp)
    8000626c:	69ae                	ld	s3,200(sp)
    8000626e:	616d                	addi	sp,sp,240
    80006270:	8082                	ret

0000000080006272 <sys_open>:

uint64
sys_open(void)
{
    80006272:	7131                	addi	sp,sp,-192
    80006274:	fd06                	sd	ra,184(sp)
    80006276:	f922                	sd	s0,176(sp)
    80006278:	f526                	sd	s1,168(sp)
    8000627a:	f14a                	sd	s2,160(sp)
    8000627c:	ed4e                	sd	s3,152(sp)
    8000627e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006280:	08000613          	li	a2,128
    80006284:	f5040593          	addi	a1,s0,-176
    80006288:	4501                	li	a0,0
    8000628a:	ffffd097          	auipc	ra,0xffffd
    8000628e:	504080e7          	jalr	1284(ra) # 8000378e <argstr>
    return -1;
    80006292:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006294:	0c054163          	bltz	a0,80006356 <sys_open+0xe4>
    80006298:	f4c40593          	addi	a1,s0,-180
    8000629c:	4505                	li	a0,1
    8000629e:	ffffd097          	auipc	ra,0xffffd
    800062a2:	4ac080e7          	jalr	1196(ra) # 8000374a <argint>
    800062a6:	0a054863          	bltz	a0,80006356 <sys_open+0xe4>

  begin_op();
    800062aa:	fffff097          	auipc	ra,0xfffff
    800062ae:	a2e080e7          	jalr	-1490(ra) # 80004cd8 <begin_op>

  if(omode & O_CREATE){
    800062b2:	f4c42783          	lw	a5,-180(s0)
    800062b6:	2007f793          	andi	a5,a5,512
    800062ba:	cbdd                	beqz	a5,80006370 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800062bc:	4681                	li	a3,0
    800062be:	4601                	li	a2,0
    800062c0:	4589                	li	a1,2
    800062c2:	f5040513          	addi	a0,s0,-176
    800062c6:	00000097          	auipc	ra,0x0
    800062ca:	972080e7          	jalr	-1678(ra) # 80005c38 <create>
    800062ce:	892a                	mv	s2,a0
    if(ip == 0){
    800062d0:	c959                	beqz	a0,80006366 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800062d2:	04491703          	lh	a4,68(s2)
    800062d6:	478d                	li	a5,3
    800062d8:	00f71763          	bne	a4,a5,800062e6 <sys_open+0x74>
    800062dc:	04695703          	lhu	a4,70(s2)
    800062e0:	47a5                	li	a5,9
    800062e2:	0ce7ec63          	bltu	a5,a4,800063ba <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800062e6:	fffff097          	auipc	ra,0xfffff
    800062ea:	e02080e7          	jalr	-510(ra) # 800050e8 <filealloc>
    800062ee:	89aa                	mv	s3,a0
    800062f0:	10050263          	beqz	a0,800063f4 <sys_open+0x182>
    800062f4:	00000097          	auipc	ra,0x0
    800062f8:	902080e7          	jalr	-1790(ra) # 80005bf6 <fdalloc>
    800062fc:	84aa                	mv	s1,a0
    800062fe:	0e054663          	bltz	a0,800063ea <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006302:	04491703          	lh	a4,68(s2)
    80006306:	478d                	li	a5,3
    80006308:	0cf70463          	beq	a4,a5,800063d0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000630c:	4789                	li	a5,2
    8000630e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006312:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006316:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000631a:	f4c42783          	lw	a5,-180(s0)
    8000631e:	0017c713          	xori	a4,a5,1
    80006322:	8b05                	andi	a4,a4,1
    80006324:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006328:	0037f713          	andi	a4,a5,3
    8000632c:	00e03733          	snez	a4,a4
    80006330:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006334:	4007f793          	andi	a5,a5,1024
    80006338:	c791                	beqz	a5,80006344 <sys_open+0xd2>
    8000633a:	04491703          	lh	a4,68(s2)
    8000633e:	4789                	li	a5,2
    80006340:	08f70f63          	beq	a4,a5,800063de <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006344:	854a                	mv	a0,s2
    80006346:	ffffe097          	auipc	ra,0xffffe
    8000634a:	082080e7          	jalr	130(ra) # 800043c8 <iunlock>
  end_op();
    8000634e:	fffff097          	auipc	ra,0xfffff
    80006352:	a0a080e7          	jalr	-1526(ra) # 80004d58 <end_op>

  return fd;
}
    80006356:	8526                	mv	a0,s1
    80006358:	70ea                	ld	ra,184(sp)
    8000635a:	744a                	ld	s0,176(sp)
    8000635c:	74aa                	ld	s1,168(sp)
    8000635e:	790a                	ld	s2,160(sp)
    80006360:	69ea                	ld	s3,152(sp)
    80006362:	6129                	addi	sp,sp,192
    80006364:	8082                	ret
      end_op();
    80006366:	fffff097          	auipc	ra,0xfffff
    8000636a:	9f2080e7          	jalr	-1550(ra) # 80004d58 <end_op>
      return -1;
    8000636e:	b7e5                	j	80006356 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006370:	f5040513          	addi	a0,s0,-176
    80006374:	ffffe097          	auipc	ra,0xffffe
    80006378:	748080e7          	jalr	1864(ra) # 80004abc <namei>
    8000637c:	892a                	mv	s2,a0
    8000637e:	c905                	beqz	a0,800063ae <sys_open+0x13c>
    ilock(ip);
    80006380:	ffffe097          	auipc	ra,0xffffe
    80006384:	f86080e7          	jalr	-122(ra) # 80004306 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006388:	04491703          	lh	a4,68(s2)
    8000638c:	4785                	li	a5,1
    8000638e:	f4f712e3          	bne	a4,a5,800062d2 <sys_open+0x60>
    80006392:	f4c42783          	lw	a5,-180(s0)
    80006396:	dba1                	beqz	a5,800062e6 <sys_open+0x74>
      iunlockput(ip);
    80006398:	854a                	mv	a0,s2
    8000639a:	ffffe097          	auipc	ra,0xffffe
    8000639e:	1ce080e7          	jalr	462(ra) # 80004568 <iunlockput>
      end_op();
    800063a2:	fffff097          	auipc	ra,0xfffff
    800063a6:	9b6080e7          	jalr	-1610(ra) # 80004d58 <end_op>
      return -1;
    800063aa:	54fd                	li	s1,-1
    800063ac:	b76d                	j	80006356 <sys_open+0xe4>
      end_op();
    800063ae:	fffff097          	auipc	ra,0xfffff
    800063b2:	9aa080e7          	jalr	-1622(ra) # 80004d58 <end_op>
      return -1;
    800063b6:	54fd                	li	s1,-1
    800063b8:	bf79                	j	80006356 <sys_open+0xe4>
    iunlockput(ip);
    800063ba:	854a                	mv	a0,s2
    800063bc:	ffffe097          	auipc	ra,0xffffe
    800063c0:	1ac080e7          	jalr	428(ra) # 80004568 <iunlockput>
    end_op();
    800063c4:	fffff097          	auipc	ra,0xfffff
    800063c8:	994080e7          	jalr	-1644(ra) # 80004d58 <end_op>
    return -1;
    800063cc:	54fd                	li	s1,-1
    800063ce:	b761                	j	80006356 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800063d0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800063d4:	04691783          	lh	a5,70(s2)
    800063d8:	02f99223          	sh	a5,36(s3)
    800063dc:	bf2d                	j	80006316 <sys_open+0xa4>
    itrunc(ip);
    800063de:	854a                	mv	a0,s2
    800063e0:	ffffe097          	auipc	ra,0xffffe
    800063e4:	034080e7          	jalr	52(ra) # 80004414 <itrunc>
    800063e8:	bfb1                	j	80006344 <sys_open+0xd2>
      fileclose(f);
    800063ea:	854e                	mv	a0,s3
    800063ec:	fffff097          	auipc	ra,0xfffff
    800063f0:	db8080e7          	jalr	-584(ra) # 800051a4 <fileclose>
    iunlockput(ip);
    800063f4:	854a                	mv	a0,s2
    800063f6:	ffffe097          	auipc	ra,0xffffe
    800063fa:	172080e7          	jalr	370(ra) # 80004568 <iunlockput>
    end_op();
    800063fe:	fffff097          	auipc	ra,0xfffff
    80006402:	95a080e7          	jalr	-1702(ra) # 80004d58 <end_op>
    return -1;
    80006406:	54fd                	li	s1,-1
    80006408:	b7b9                	j	80006356 <sys_open+0xe4>

000000008000640a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000640a:	7175                	addi	sp,sp,-144
    8000640c:	e506                	sd	ra,136(sp)
    8000640e:	e122                	sd	s0,128(sp)
    80006410:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006412:	fffff097          	auipc	ra,0xfffff
    80006416:	8c6080e7          	jalr	-1850(ra) # 80004cd8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000641a:	08000613          	li	a2,128
    8000641e:	f7040593          	addi	a1,s0,-144
    80006422:	4501                	li	a0,0
    80006424:	ffffd097          	auipc	ra,0xffffd
    80006428:	36a080e7          	jalr	874(ra) # 8000378e <argstr>
    8000642c:	02054963          	bltz	a0,8000645e <sys_mkdir+0x54>
    80006430:	4681                	li	a3,0
    80006432:	4601                	li	a2,0
    80006434:	4585                	li	a1,1
    80006436:	f7040513          	addi	a0,s0,-144
    8000643a:	fffff097          	auipc	ra,0xfffff
    8000643e:	7fe080e7          	jalr	2046(ra) # 80005c38 <create>
    80006442:	cd11                	beqz	a0,8000645e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006444:	ffffe097          	auipc	ra,0xffffe
    80006448:	124080e7          	jalr	292(ra) # 80004568 <iunlockput>
  end_op();
    8000644c:	fffff097          	auipc	ra,0xfffff
    80006450:	90c080e7          	jalr	-1780(ra) # 80004d58 <end_op>
  return 0;
    80006454:	4501                	li	a0,0
}
    80006456:	60aa                	ld	ra,136(sp)
    80006458:	640a                	ld	s0,128(sp)
    8000645a:	6149                	addi	sp,sp,144
    8000645c:	8082                	ret
    end_op();
    8000645e:	fffff097          	auipc	ra,0xfffff
    80006462:	8fa080e7          	jalr	-1798(ra) # 80004d58 <end_op>
    return -1;
    80006466:	557d                	li	a0,-1
    80006468:	b7fd                	j	80006456 <sys_mkdir+0x4c>

000000008000646a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000646a:	7135                	addi	sp,sp,-160
    8000646c:	ed06                	sd	ra,152(sp)
    8000646e:	e922                	sd	s0,144(sp)
    80006470:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006472:	fffff097          	auipc	ra,0xfffff
    80006476:	866080e7          	jalr	-1946(ra) # 80004cd8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000647a:	08000613          	li	a2,128
    8000647e:	f7040593          	addi	a1,s0,-144
    80006482:	4501                	li	a0,0
    80006484:	ffffd097          	auipc	ra,0xffffd
    80006488:	30a080e7          	jalr	778(ra) # 8000378e <argstr>
    8000648c:	04054a63          	bltz	a0,800064e0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006490:	f6c40593          	addi	a1,s0,-148
    80006494:	4505                	li	a0,1
    80006496:	ffffd097          	auipc	ra,0xffffd
    8000649a:	2b4080e7          	jalr	692(ra) # 8000374a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000649e:	04054163          	bltz	a0,800064e0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800064a2:	f6840593          	addi	a1,s0,-152
    800064a6:	4509                	li	a0,2
    800064a8:	ffffd097          	auipc	ra,0xffffd
    800064ac:	2a2080e7          	jalr	674(ra) # 8000374a <argint>
     argint(1, &major) < 0 ||
    800064b0:	02054863          	bltz	a0,800064e0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800064b4:	f6841683          	lh	a3,-152(s0)
    800064b8:	f6c41603          	lh	a2,-148(s0)
    800064bc:	458d                	li	a1,3
    800064be:	f7040513          	addi	a0,s0,-144
    800064c2:	fffff097          	auipc	ra,0xfffff
    800064c6:	776080e7          	jalr	1910(ra) # 80005c38 <create>
     argint(2, &minor) < 0 ||
    800064ca:	c919                	beqz	a0,800064e0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800064cc:	ffffe097          	auipc	ra,0xffffe
    800064d0:	09c080e7          	jalr	156(ra) # 80004568 <iunlockput>
  end_op();
    800064d4:	fffff097          	auipc	ra,0xfffff
    800064d8:	884080e7          	jalr	-1916(ra) # 80004d58 <end_op>
  return 0;
    800064dc:	4501                	li	a0,0
    800064de:	a031                	j	800064ea <sys_mknod+0x80>
    end_op();
    800064e0:	fffff097          	auipc	ra,0xfffff
    800064e4:	878080e7          	jalr	-1928(ra) # 80004d58 <end_op>
    return -1;
    800064e8:	557d                	li	a0,-1
}
    800064ea:	60ea                	ld	ra,152(sp)
    800064ec:	644a                	ld	s0,144(sp)
    800064ee:	610d                	addi	sp,sp,160
    800064f0:	8082                	ret

00000000800064f2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800064f2:	7135                	addi	sp,sp,-160
    800064f4:	ed06                	sd	ra,152(sp)
    800064f6:	e922                	sd	s0,144(sp)
    800064f8:	e526                	sd	s1,136(sp)
    800064fa:	e14a                	sd	s2,128(sp)
    800064fc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800064fe:	ffffc097          	auipc	ra,0xffffc
    80006502:	8a6080e7          	jalr	-1882(ra) # 80001da4 <myproc>
    80006506:	892a                	mv	s2,a0
  
  begin_op();
    80006508:	ffffe097          	auipc	ra,0xffffe
    8000650c:	7d0080e7          	jalr	2000(ra) # 80004cd8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006510:	08000613          	li	a2,128
    80006514:	f6040593          	addi	a1,s0,-160
    80006518:	4501                	li	a0,0
    8000651a:	ffffd097          	auipc	ra,0xffffd
    8000651e:	274080e7          	jalr	628(ra) # 8000378e <argstr>
    80006522:	04054b63          	bltz	a0,80006578 <sys_chdir+0x86>
    80006526:	f6040513          	addi	a0,s0,-160
    8000652a:	ffffe097          	auipc	ra,0xffffe
    8000652e:	592080e7          	jalr	1426(ra) # 80004abc <namei>
    80006532:	84aa                	mv	s1,a0
    80006534:	c131                	beqz	a0,80006578 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006536:	ffffe097          	auipc	ra,0xffffe
    8000653a:	dd0080e7          	jalr	-560(ra) # 80004306 <ilock>
  if(ip->type != T_DIR){
    8000653e:	04449703          	lh	a4,68(s1)
    80006542:	4785                	li	a5,1
    80006544:	04f71063          	bne	a4,a5,80006584 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006548:	8526                	mv	a0,s1
    8000654a:	ffffe097          	auipc	ra,0xffffe
    8000654e:	e7e080e7          	jalr	-386(ra) # 800043c8 <iunlock>
  iput(p->cwd);
    80006552:	17893503          	ld	a0,376(s2)
    80006556:	ffffe097          	auipc	ra,0xffffe
    8000655a:	f6a080e7          	jalr	-150(ra) # 800044c0 <iput>
  end_op();
    8000655e:	ffffe097          	auipc	ra,0xffffe
    80006562:	7fa080e7          	jalr	2042(ra) # 80004d58 <end_op>
  p->cwd = ip;
    80006566:	16993c23          	sd	s1,376(s2)
  return 0;
    8000656a:	4501                	li	a0,0
}
    8000656c:	60ea                	ld	ra,152(sp)
    8000656e:	644a                	ld	s0,144(sp)
    80006570:	64aa                	ld	s1,136(sp)
    80006572:	690a                	ld	s2,128(sp)
    80006574:	610d                	addi	sp,sp,160
    80006576:	8082                	ret
    end_op();
    80006578:	ffffe097          	auipc	ra,0xffffe
    8000657c:	7e0080e7          	jalr	2016(ra) # 80004d58 <end_op>
    return -1;
    80006580:	557d                	li	a0,-1
    80006582:	b7ed                	j	8000656c <sys_chdir+0x7a>
    iunlockput(ip);
    80006584:	8526                	mv	a0,s1
    80006586:	ffffe097          	auipc	ra,0xffffe
    8000658a:	fe2080e7          	jalr	-30(ra) # 80004568 <iunlockput>
    end_op();
    8000658e:	ffffe097          	auipc	ra,0xffffe
    80006592:	7ca080e7          	jalr	1994(ra) # 80004d58 <end_op>
    return -1;
    80006596:	557d                	li	a0,-1
    80006598:	bfd1                	j	8000656c <sys_chdir+0x7a>

000000008000659a <sys_exec>:

uint64
sys_exec(void)
{
    8000659a:	7145                	addi	sp,sp,-464
    8000659c:	e786                	sd	ra,456(sp)
    8000659e:	e3a2                	sd	s0,448(sp)
    800065a0:	ff26                	sd	s1,440(sp)
    800065a2:	fb4a                	sd	s2,432(sp)
    800065a4:	f74e                	sd	s3,424(sp)
    800065a6:	f352                	sd	s4,416(sp)
    800065a8:	ef56                	sd	s5,408(sp)
    800065aa:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800065ac:	08000613          	li	a2,128
    800065b0:	f4040593          	addi	a1,s0,-192
    800065b4:	4501                	li	a0,0
    800065b6:	ffffd097          	auipc	ra,0xffffd
    800065ba:	1d8080e7          	jalr	472(ra) # 8000378e <argstr>
    return -1;
    800065be:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800065c0:	0c054a63          	bltz	a0,80006694 <sys_exec+0xfa>
    800065c4:	e3840593          	addi	a1,s0,-456
    800065c8:	4505                	li	a0,1
    800065ca:	ffffd097          	auipc	ra,0xffffd
    800065ce:	1a2080e7          	jalr	418(ra) # 8000376c <argaddr>
    800065d2:	0c054163          	bltz	a0,80006694 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800065d6:	10000613          	li	a2,256
    800065da:	4581                	li	a1,0
    800065dc:	e4040513          	addi	a0,s0,-448
    800065e0:	ffffa097          	auipc	ra,0xffffa
    800065e4:	70e080e7          	jalr	1806(ra) # 80000cee <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800065e8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800065ec:	89a6                	mv	s3,s1
    800065ee:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800065f0:	02000a13          	li	s4,32
    800065f4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800065f8:	00391513          	slli	a0,s2,0x3
    800065fc:	e3040593          	addi	a1,s0,-464
    80006600:	e3843783          	ld	a5,-456(s0)
    80006604:	953e                	add	a0,a0,a5
    80006606:	ffffd097          	auipc	ra,0xffffd
    8000660a:	0aa080e7          	jalr	170(ra) # 800036b0 <fetchaddr>
    8000660e:	02054a63          	bltz	a0,80006642 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006612:	e3043783          	ld	a5,-464(s0)
    80006616:	c3b9                	beqz	a5,8000665c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006618:	ffffa097          	auipc	ra,0xffffa
    8000661c:	4dc080e7          	jalr	1244(ra) # 80000af4 <kalloc>
    80006620:	85aa                	mv	a1,a0
    80006622:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006626:	cd11                	beqz	a0,80006642 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006628:	6605                	lui	a2,0x1
    8000662a:	e3043503          	ld	a0,-464(s0)
    8000662e:	ffffd097          	auipc	ra,0xffffd
    80006632:	0d4080e7          	jalr	212(ra) # 80003702 <fetchstr>
    80006636:	00054663          	bltz	a0,80006642 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000663a:	0905                	addi	s2,s2,1
    8000663c:	09a1                	addi	s3,s3,8
    8000663e:	fb491be3          	bne	s2,s4,800065f4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006642:	10048913          	addi	s2,s1,256
    80006646:	6088                	ld	a0,0(s1)
    80006648:	c529                	beqz	a0,80006692 <sys_exec+0xf8>
    kfree(argv[i]);
    8000664a:	ffffa097          	auipc	ra,0xffffa
    8000664e:	3ae080e7          	jalr	942(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006652:	04a1                	addi	s1,s1,8
    80006654:	ff2499e3          	bne	s1,s2,80006646 <sys_exec+0xac>
  return -1;
    80006658:	597d                	li	s2,-1
    8000665a:	a82d                	j	80006694 <sys_exec+0xfa>
      argv[i] = 0;
    8000665c:	0a8e                	slli	s5,s5,0x3
    8000665e:	fc040793          	addi	a5,s0,-64
    80006662:	9abe                	add	s5,s5,a5
    80006664:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006668:	e4040593          	addi	a1,s0,-448
    8000666c:	f4040513          	addi	a0,s0,-192
    80006670:	fffff097          	auipc	ra,0xfffff
    80006674:	194080e7          	jalr	404(ra) # 80005804 <exec>
    80006678:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000667a:	10048993          	addi	s3,s1,256
    8000667e:	6088                	ld	a0,0(s1)
    80006680:	c911                	beqz	a0,80006694 <sys_exec+0xfa>
    kfree(argv[i]);
    80006682:	ffffa097          	auipc	ra,0xffffa
    80006686:	376080e7          	jalr	886(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000668a:	04a1                	addi	s1,s1,8
    8000668c:	ff3499e3          	bne	s1,s3,8000667e <sys_exec+0xe4>
    80006690:	a011                	j	80006694 <sys_exec+0xfa>
  return -1;
    80006692:	597d                	li	s2,-1
}
    80006694:	854a                	mv	a0,s2
    80006696:	60be                	ld	ra,456(sp)
    80006698:	641e                	ld	s0,448(sp)
    8000669a:	74fa                	ld	s1,440(sp)
    8000669c:	795a                	ld	s2,432(sp)
    8000669e:	79ba                	ld	s3,424(sp)
    800066a0:	7a1a                	ld	s4,416(sp)
    800066a2:	6afa                	ld	s5,408(sp)
    800066a4:	6179                	addi	sp,sp,464
    800066a6:	8082                	ret

00000000800066a8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800066a8:	7139                	addi	sp,sp,-64
    800066aa:	fc06                	sd	ra,56(sp)
    800066ac:	f822                	sd	s0,48(sp)
    800066ae:	f426                	sd	s1,40(sp)
    800066b0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800066b2:	ffffb097          	auipc	ra,0xffffb
    800066b6:	6f2080e7          	jalr	1778(ra) # 80001da4 <myproc>
    800066ba:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800066bc:	fd840593          	addi	a1,s0,-40
    800066c0:	4501                	li	a0,0
    800066c2:	ffffd097          	auipc	ra,0xffffd
    800066c6:	0aa080e7          	jalr	170(ra) # 8000376c <argaddr>
    return -1;
    800066ca:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800066cc:	0e054063          	bltz	a0,800067ac <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800066d0:	fc840593          	addi	a1,s0,-56
    800066d4:	fd040513          	addi	a0,s0,-48
    800066d8:	fffff097          	auipc	ra,0xfffff
    800066dc:	dfc080e7          	jalr	-516(ra) # 800054d4 <pipealloc>
    return -1;
    800066e0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800066e2:	0c054563          	bltz	a0,800067ac <sys_pipe+0x104>
  fd0 = -1;
    800066e6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800066ea:	fd043503          	ld	a0,-48(s0)
    800066ee:	fffff097          	auipc	ra,0xfffff
    800066f2:	508080e7          	jalr	1288(ra) # 80005bf6 <fdalloc>
    800066f6:	fca42223          	sw	a0,-60(s0)
    800066fa:	08054c63          	bltz	a0,80006792 <sys_pipe+0xea>
    800066fe:	fc843503          	ld	a0,-56(s0)
    80006702:	fffff097          	auipc	ra,0xfffff
    80006706:	4f4080e7          	jalr	1268(ra) # 80005bf6 <fdalloc>
    8000670a:	fca42023          	sw	a0,-64(s0)
    8000670e:	06054863          	bltz	a0,8000677e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006712:	4691                	li	a3,4
    80006714:	fc440613          	addi	a2,s0,-60
    80006718:	fd843583          	ld	a1,-40(s0)
    8000671c:	7ca8                	ld	a0,120(s1)
    8000671e:	ffffb097          	auipc	ra,0xffffb
    80006722:	f62080e7          	jalr	-158(ra) # 80001680 <copyout>
    80006726:	02054063          	bltz	a0,80006746 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000672a:	4691                	li	a3,4
    8000672c:	fc040613          	addi	a2,s0,-64
    80006730:	fd843583          	ld	a1,-40(s0)
    80006734:	0591                	addi	a1,a1,4
    80006736:	7ca8                	ld	a0,120(s1)
    80006738:	ffffb097          	auipc	ra,0xffffb
    8000673c:	f48080e7          	jalr	-184(ra) # 80001680 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006740:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006742:	06055563          	bgez	a0,800067ac <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006746:	fc442783          	lw	a5,-60(s0)
    8000674a:	07f9                	addi	a5,a5,30
    8000674c:	078e                	slli	a5,a5,0x3
    8000674e:	97a6                	add	a5,a5,s1
    80006750:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006754:	fc042503          	lw	a0,-64(s0)
    80006758:	0579                	addi	a0,a0,30
    8000675a:	050e                	slli	a0,a0,0x3
    8000675c:	9526                	add	a0,a0,s1
    8000675e:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006762:	fd043503          	ld	a0,-48(s0)
    80006766:	fffff097          	auipc	ra,0xfffff
    8000676a:	a3e080e7          	jalr	-1474(ra) # 800051a4 <fileclose>
    fileclose(wf);
    8000676e:	fc843503          	ld	a0,-56(s0)
    80006772:	fffff097          	auipc	ra,0xfffff
    80006776:	a32080e7          	jalr	-1486(ra) # 800051a4 <fileclose>
    return -1;
    8000677a:	57fd                	li	a5,-1
    8000677c:	a805                	j	800067ac <sys_pipe+0x104>
    if(fd0 >= 0)
    8000677e:	fc442783          	lw	a5,-60(s0)
    80006782:	0007c863          	bltz	a5,80006792 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006786:	01e78513          	addi	a0,a5,30
    8000678a:	050e                	slli	a0,a0,0x3
    8000678c:	9526                	add	a0,a0,s1
    8000678e:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006792:	fd043503          	ld	a0,-48(s0)
    80006796:	fffff097          	auipc	ra,0xfffff
    8000679a:	a0e080e7          	jalr	-1522(ra) # 800051a4 <fileclose>
    fileclose(wf);
    8000679e:	fc843503          	ld	a0,-56(s0)
    800067a2:	fffff097          	auipc	ra,0xfffff
    800067a6:	a02080e7          	jalr	-1534(ra) # 800051a4 <fileclose>
    return -1;
    800067aa:	57fd                	li	a5,-1
}
    800067ac:	853e                	mv	a0,a5
    800067ae:	70e2                	ld	ra,56(sp)
    800067b0:	7442                	ld	s0,48(sp)
    800067b2:	74a2                	ld	s1,40(sp)
    800067b4:	6121                	addi	sp,sp,64
    800067b6:	8082                	ret
	...

00000000800067c0 <kernelvec>:
    800067c0:	7111                	addi	sp,sp,-256
    800067c2:	e006                	sd	ra,0(sp)
    800067c4:	e40a                	sd	sp,8(sp)
    800067c6:	e80e                	sd	gp,16(sp)
    800067c8:	ec12                	sd	tp,24(sp)
    800067ca:	f016                	sd	t0,32(sp)
    800067cc:	f41a                	sd	t1,40(sp)
    800067ce:	f81e                	sd	t2,48(sp)
    800067d0:	fc22                	sd	s0,56(sp)
    800067d2:	e0a6                	sd	s1,64(sp)
    800067d4:	e4aa                	sd	a0,72(sp)
    800067d6:	e8ae                	sd	a1,80(sp)
    800067d8:	ecb2                	sd	a2,88(sp)
    800067da:	f0b6                	sd	a3,96(sp)
    800067dc:	f4ba                	sd	a4,104(sp)
    800067de:	f8be                	sd	a5,112(sp)
    800067e0:	fcc2                	sd	a6,120(sp)
    800067e2:	e146                	sd	a7,128(sp)
    800067e4:	e54a                	sd	s2,136(sp)
    800067e6:	e94e                	sd	s3,144(sp)
    800067e8:	ed52                	sd	s4,152(sp)
    800067ea:	f156                	sd	s5,160(sp)
    800067ec:	f55a                	sd	s6,168(sp)
    800067ee:	f95e                	sd	s7,176(sp)
    800067f0:	fd62                	sd	s8,184(sp)
    800067f2:	e1e6                	sd	s9,192(sp)
    800067f4:	e5ea                	sd	s10,200(sp)
    800067f6:	e9ee                	sd	s11,208(sp)
    800067f8:	edf2                	sd	t3,216(sp)
    800067fa:	f1f6                	sd	t4,224(sp)
    800067fc:	f5fa                	sd	t5,232(sp)
    800067fe:	f9fe                	sd	t6,240(sp)
    80006800:	d7dfc0ef          	jal	ra,8000357c <kerneltrap>
    80006804:	6082                	ld	ra,0(sp)
    80006806:	6122                	ld	sp,8(sp)
    80006808:	61c2                	ld	gp,16(sp)
    8000680a:	7282                	ld	t0,32(sp)
    8000680c:	7322                	ld	t1,40(sp)
    8000680e:	73c2                	ld	t2,48(sp)
    80006810:	7462                	ld	s0,56(sp)
    80006812:	6486                	ld	s1,64(sp)
    80006814:	6526                	ld	a0,72(sp)
    80006816:	65c6                	ld	a1,80(sp)
    80006818:	6666                	ld	a2,88(sp)
    8000681a:	7686                	ld	a3,96(sp)
    8000681c:	7726                	ld	a4,104(sp)
    8000681e:	77c6                	ld	a5,112(sp)
    80006820:	7866                	ld	a6,120(sp)
    80006822:	688a                	ld	a7,128(sp)
    80006824:	692a                	ld	s2,136(sp)
    80006826:	69ca                	ld	s3,144(sp)
    80006828:	6a6a                	ld	s4,152(sp)
    8000682a:	7a8a                	ld	s5,160(sp)
    8000682c:	7b2a                	ld	s6,168(sp)
    8000682e:	7bca                	ld	s7,176(sp)
    80006830:	7c6a                	ld	s8,184(sp)
    80006832:	6c8e                	ld	s9,192(sp)
    80006834:	6d2e                	ld	s10,200(sp)
    80006836:	6dce                	ld	s11,208(sp)
    80006838:	6e6e                	ld	t3,216(sp)
    8000683a:	7e8e                	ld	t4,224(sp)
    8000683c:	7f2e                	ld	t5,232(sp)
    8000683e:	7fce                	ld	t6,240(sp)
    80006840:	6111                	addi	sp,sp,256
    80006842:	10200073          	sret
    80006846:	00000013          	nop
    8000684a:	00000013          	nop
    8000684e:	0001                	nop

0000000080006850 <timervec>:
    80006850:	34051573          	csrrw	a0,mscratch,a0
    80006854:	e10c                	sd	a1,0(a0)
    80006856:	e510                	sd	a2,8(a0)
    80006858:	e914                	sd	a3,16(a0)
    8000685a:	6d0c                	ld	a1,24(a0)
    8000685c:	7110                	ld	a2,32(a0)
    8000685e:	6194                	ld	a3,0(a1)
    80006860:	96b2                	add	a3,a3,a2
    80006862:	e194                	sd	a3,0(a1)
    80006864:	4589                	li	a1,2
    80006866:	14459073          	csrw	sip,a1
    8000686a:	6914                	ld	a3,16(a0)
    8000686c:	6510                	ld	a2,8(a0)
    8000686e:	610c                	ld	a1,0(a0)
    80006870:	34051573          	csrrw	a0,mscratch,a0
    80006874:	30200073          	mret
	...

000000008000687a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000687a:	1141                	addi	sp,sp,-16
    8000687c:	e422                	sd	s0,8(sp)
    8000687e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006880:	0c0007b7          	lui	a5,0xc000
    80006884:	4705                	li	a4,1
    80006886:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006888:	c3d8                	sw	a4,4(a5)
}
    8000688a:	6422                	ld	s0,8(sp)
    8000688c:	0141                	addi	sp,sp,16
    8000688e:	8082                	ret

0000000080006890 <plicinithart>:

void
plicinithart(void)
{
    80006890:	1141                	addi	sp,sp,-16
    80006892:	e406                	sd	ra,8(sp)
    80006894:	e022                	sd	s0,0(sp)
    80006896:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006898:	ffffb097          	auipc	ra,0xffffb
    8000689c:	4d8080e7          	jalr	1240(ra) # 80001d70 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800068a0:	0085171b          	slliw	a4,a0,0x8
    800068a4:	0c0027b7          	lui	a5,0xc002
    800068a8:	97ba                	add	a5,a5,a4
    800068aa:	40200713          	li	a4,1026
    800068ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800068b2:	00d5151b          	slliw	a0,a0,0xd
    800068b6:	0c2017b7          	lui	a5,0xc201
    800068ba:	953e                	add	a0,a0,a5
    800068bc:	00052023          	sw	zero,0(a0)
}
    800068c0:	60a2                	ld	ra,8(sp)
    800068c2:	6402                	ld	s0,0(sp)
    800068c4:	0141                	addi	sp,sp,16
    800068c6:	8082                	ret

00000000800068c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800068c8:	1141                	addi	sp,sp,-16
    800068ca:	e406                	sd	ra,8(sp)
    800068cc:	e022                	sd	s0,0(sp)
    800068ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800068d0:	ffffb097          	auipc	ra,0xffffb
    800068d4:	4a0080e7          	jalr	1184(ra) # 80001d70 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800068d8:	00d5179b          	slliw	a5,a0,0xd
    800068dc:	0c201537          	lui	a0,0xc201
    800068e0:	953e                	add	a0,a0,a5
  return irq;
}
    800068e2:	4148                	lw	a0,4(a0)
    800068e4:	60a2                	ld	ra,8(sp)
    800068e6:	6402                	ld	s0,0(sp)
    800068e8:	0141                	addi	sp,sp,16
    800068ea:	8082                	ret

00000000800068ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800068ec:	1101                	addi	sp,sp,-32
    800068ee:	ec06                	sd	ra,24(sp)
    800068f0:	e822                	sd	s0,16(sp)
    800068f2:	e426                	sd	s1,8(sp)
    800068f4:	1000                	addi	s0,sp,32
    800068f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800068f8:	ffffb097          	auipc	ra,0xffffb
    800068fc:	478080e7          	jalr	1144(ra) # 80001d70 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006900:	00d5151b          	slliw	a0,a0,0xd
    80006904:	0c2017b7          	lui	a5,0xc201
    80006908:	97aa                	add	a5,a5,a0
    8000690a:	c3c4                	sw	s1,4(a5)
}
    8000690c:	60e2                	ld	ra,24(sp)
    8000690e:	6442                	ld	s0,16(sp)
    80006910:	64a2                	ld	s1,8(sp)
    80006912:	6105                	addi	sp,sp,32
    80006914:	8082                	ret

0000000080006916 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006916:	1141                	addi	sp,sp,-16
    80006918:	e406                	sd	ra,8(sp)
    8000691a:	e022                	sd	s0,0(sp)
    8000691c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000691e:	479d                	li	a5,7
    80006920:	06a7c963          	blt	a5,a0,80006992 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006924:	0001c797          	auipc	a5,0x1c
    80006928:	6dc78793          	addi	a5,a5,1756 # 80023000 <disk>
    8000692c:	00a78733          	add	a4,a5,a0
    80006930:	6789                	lui	a5,0x2
    80006932:	97ba                	add	a5,a5,a4
    80006934:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006938:	e7ad                	bnez	a5,800069a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000693a:	00451793          	slli	a5,a0,0x4
    8000693e:	0001e717          	auipc	a4,0x1e
    80006942:	6c270713          	addi	a4,a4,1730 # 80025000 <disk+0x2000>
    80006946:	6314                	ld	a3,0(a4)
    80006948:	96be                	add	a3,a3,a5
    8000694a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000694e:	6314                	ld	a3,0(a4)
    80006950:	96be                	add	a3,a3,a5
    80006952:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006956:	6314                	ld	a3,0(a4)
    80006958:	96be                	add	a3,a3,a5
    8000695a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000695e:	6318                	ld	a4,0(a4)
    80006960:	97ba                	add	a5,a5,a4
    80006962:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006966:	0001c797          	auipc	a5,0x1c
    8000696a:	69a78793          	addi	a5,a5,1690 # 80023000 <disk>
    8000696e:	97aa                	add	a5,a5,a0
    80006970:	6509                	lui	a0,0x2
    80006972:	953e                	add	a0,a0,a5
    80006974:	4785                	li	a5,1
    80006976:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000697a:	0001e517          	auipc	a0,0x1e
    8000697e:	69e50513          	addi	a0,a0,1694 # 80025018 <disk+0x2018>
    80006982:	ffffc097          	auipc	ra,0xffffc
    80006986:	404080e7          	jalr	1028(ra) # 80002d86 <wakeup>
}
    8000698a:	60a2                	ld	ra,8(sp)
    8000698c:	6402                	ld	s0,0(sp)
    8000698e:	0141                	addi	sp,sp,16
    80006990:	8082                	ret
    panic("free_desc 1");
    80006992:	00002517          	auipc	a0,0x2
    80006996:	f6650513          	addi	a0,a0,-154 # 800088f8 <syscalls+0x330>
    8000699a:	ffffa097          	auipc	ra,0xffffa
    8000699e:	ba4080e7          	jalr	-1116(ra) # 8000053e <panic>
    panic("free_desc 2");
    800069a2:	00002517          	auipc	a0,0x2
    800069a6:	f6650513          	addi	a0,a0,-154 # 80008908 <syscalls+0x340>
    800069aa:	ffffa097          	auipc	ra,0xffffa
    800069ae:	b94080e7          	jalr	-1132(ra) # 8000053e <panic>

00000000800069b2 <virtio_disk_init>:
{
    800069b2:	1101                	addi	sp,sp,-32
    800069b4:	ec06                	sd	ra,24(sp)
    800069b6:	e822                	sd	s0,16(sp)
    800069b8:	e426                	sd	s1,8(sp)
    800069ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800069bc:	00002597          	auipc	a1,0x2
    800069c0:	f5c58593          	addi	a1,a1,-164 # 80008918 <syscalls+0x350>
    800069c4:	0001e517          	auipc	a0,0x1e
    800069c8:	76450513          	addi	a0,a0,1892 # 80025128 <disk+0x2128>
    800069cc:	ffffa097          	auipc	ra,0xffffa
    800069d0:	188080e7          	jalr	392(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069d4:	100017b7          	lui	a5,0x10001
    800069d8:	4398                	lw	a4,0(a5)
    800069da:	2701                	sext.w	a4,a4
    800069dc:	747277b7          	lui	a5,0x74727
    800069e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800069e4:	0ef71163          	bne	a4,a5,80006ac6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800069e8:	100017b7          	lui	a5,0x10001
    800069ec:	43dc                	lw	a5,4(a5)
    800069ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069f0:	4705                	li	a4,1
    800069f2:	0ce79a63          	bne	a5,a4,80006ac6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800069f6:	100017b7          	lui	a5,0x10001
    800069fa:	479c                	lw	a5,8(a5)
    800069fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800069fe:	4709                	li	a4,2
    80006a00:	0ce79363          	bne	a5,a4,80006ac6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006a04:	100017b7          	lui	a5,0x10001
    80006a08:	47d8                	lw	a4,12(a5)
    80006a0a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a0c:	554d47b7          	lui	a5,0x554d4
    80006a10:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006a14:	0af71963          	bne	a4,a5,80006ac6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a18:	100017b7          	lui	a5,0x10001
    80006a1c:	4705                	li	a4,1
    80006a1e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a20:	470d                	li	a4,3
    80006a22:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006a24:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006a26:	c7ffe737          	lui	a4,0xc7ffe
    80006a2a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80006a2e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006a30:	2701                	sext.w	a4,a4
    80006a32:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a34:	472d                	li	a4,11
    80006a36:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a38:	473d                	li	a4,15
    80006a3a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006a3c:	6705                	lui	a4,0x1
    80006a3e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006a40:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006a44:	5bdc                	lw	a5,52(a5)
    80006a46:	2781                	sext.w	a5,a5
  if(max == 0)
    80006a48:	c7d9                	beqz	a5,80006ad6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006a4a:	471d                	li	a4,7
    80006a4c:	08f77d63          	bgeu	a4,a5,80006ae6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a50:	100014b7          	lui	s1,0x10001
    80006a54:	47a1                	li	a5,8
    80006a56:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006a58:	6609                	lui	a2,0x2
    80006a5a:	4581                	li	a1,0
    80006a5c:	0001c517          	auipc	a0,0x1c
    80006a60:	5a450513          	addi	a0,a0,1444 # 80023000 <disk>
    80006a64:	ffffa097          	auipc	ra,0xffffa
    80006a68:	28a080e7          	jalr	650(ra) # 80000cee <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006a6c:	0001c717          	auipc	a4,0x1c
    80006a70:	59470713          	addi	a4,a4,1428 # 80023000 <disk>
    80006a74:	00c75793          	srli	a5,a4,0xc
    80006a78:	2781                	sext.w	a5,a5
    80006a7a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006a7c:	0001e797          	auipc	a5,0x1e
    80006a80:	58478793          	addi	a5,a5,1412 # 80025000 <disk+0x2000>
    80006a84:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006a86:	0001c717          	auipc	a4,0x1c
    80006a8a:	5fa70713          	addi	a4,a4,1530 # 80023080 <disk+0x80>
    80006a8e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006a90:	0001d717          	auipc	a4,0x1d
    80006a94:	57070713          	addi	a4,a4,1392 # 80024000 <disk+0x1000>
    80006a98:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006a9a:	4705                	li	a4,1
    80006a9c:	00e78c23          	sb	a4,24(a5)
    80006aa0:	00e78ca3          	sb	a4,25(a5)
    80006aa4:	00e78d23          	sb	a4,26(a5)
    80006aa8:	00e78da3          	sb	a4,27(a5)
    80006aac:	00e78e23          	sb	a4,28(a5)
    80006ab0:	00e78ea3          	sb	a4,29(a5)
    80006ab4:	00e78f23          	sb	a4,30(a5)
    80006ab8:	00e78fa3          	sb	a4,31(a5)
}
    80006abc:	60e2                	ld	ra,24(sp)
    80006abe:	6442                	ld	s0,16(sp)
    80006ac0:	64a2                	ld	s1,8(sp)
    80006ac2:	6105                	addi	sp,sp,32
    80006ac4:	8082                	ret
    panic("could not find virtio disk");
    80006ac6:	00002517          	auipc	a0,0x2
    80006aca:	e6250513          	addi	a0,a0,-414 # 80008928 <syscalls+0x360>
    80006ace:	ffffa097          	auipc	ra,0xffffa
    80006ad2:	a70080e7          	jalr	-1424(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006ad6:	00002517          	auipc	a0,0x2
    80006ada:	e7250513          	addi	a0,a0,-398 # 80008948 <syscalls+0x380>
    80006ade:	ffffa097          	auipc	ra,0xffffa
    80006ae2:	a60080e7          	jalr	-1440(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006ae6:	00002517          	auipc	a0,0x2
    80006aea:	e8250513          	addi	a0,a0,-382 # 80008968 <syscalls+0x3a0>
    80006aee:	ffffa097          	auipc	ra,0xffffa
    80006af2:	a50080e7          	jalr	-1456(ra) # 8000053e <panic>

0000000080006af6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006af6:	7159                	addi	sp,sp,-112
    80006af8:	f486                	sd	ra,104(sp)
    80006afa:	f0a2                	sd	s0,96(sp)
    80006afc:	eca6                	sd	s1,88(sp)
    80006afe:	e8ca                	sd	s2,80(sp)
    80006b00:	e4ce                	sd	s3,72(sp)
    80006b02:	e0d2                	sd	s4,64(sp)
    80006b04:	fc56                	sd	s5,56(sp)
    80006b06:	f85a                	sd	s6,48(sp)
    80006b08:	f45e                	sd	s7,40(sp)
    80006b0a:	f062                	sd	s8,32(sp)
    80006b0c:	ec66                	sd	s9,24(sp)
    80006b0e:	e86a                	sd	s10,16(sp)
    80006b10:	1880                	addi	s0,sp,112
    80006b12:	892a                	mv	s2,a0
    80006b14:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006b16:	00c52c83          	lw	s9,12(a0)
    80006b1a:	001c9c9b          	slliw	s9,s9,0x1
    80006b1e:	1c82                	slli	s9,s9,0x20
    80006b20:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006b24:	0001e517          	auipc	a0,0x1e
    80006b28:	60450513          	addi	a0,a0,1540 # 80025128 <disk+0x2128>
    80006b2c:	ffffa097          	auipc	ra,0xffffa
    80006b30:	0c0080e7          	jalr	192(ra) # 80000bec <acquire>
  for(int i = 0; i < 3; i++){
    80006b34:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006b36:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006b38:	0001cb97          	auipc	s7,0x1c
    80006b3c:	4c8b8b93          	addi	s7,s7,1224 # 80023000 <disk>
    80006b40:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006b42:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006b44:	8a4e                	mv	s4,s3
    80006b46:	a051                	j	80006bca <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006b48:	00fb86b3          	add	a3,s7,a5
    80006b4c:	96da                	add	a3,a3,s6
    80006b4e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006b52:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006b54:	0207c563          	bltz	a5,80006b7e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006b58:	2485                	addiw	s1,s1,1
    80006b5a:	0711                	addi	a4,a4,4
    80006b5c:	25548063          	beq	s1,s5,80006d9c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006b60:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006b62:	0001e697          	auipc	a3,0x1e
    80006b66:	4b668693          	addi	a3,a3,1206 # 80025018 <disk+0x2018>
    80006b6a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006b6c:	0006c583          	lbu	a1,0(a3)
    80006b70:	fde1                	bnez	a1,80006b48 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006b72:	2785                	addiw	a5,a5,1
    80006b74:	0685                	addi	a3,a3,1
    80006b76:	ff879be3          	bne	a5,s8,80006b6c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006b7a:	57fd                	li	a5,-1
    80006b7c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006b7e:	02905a63          	blez	s1,80006bb2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b82:	f9042503          	lw	a0,-112(s0)
    80006b86:	00000097          	auipc	ra,0x0
    80006b8a:	d90080e7          	jalr	-624(ra) # 80006916 <free_desc>
      for(int j = 0; j < i; j++)
    80006b8e:	4785                	li	a5,1
    80006b90:	0297d163          	bge	a5,s1,80006bb2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b94:	f9442503          	lw	a0,-108(s0)
    80006b98:	00000097          	auipc	ra,0x0
    80006b9c:	d7e080e7          	jalr	-642(ra) # 80006916 <free_desc>
      for(int j = 0; j < i; j++)
    80006ba0:	4789                	li	a5,2
    80006ba2:	0097d863          	bge	a5,s1,80006bb2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006ba6:	f9842503          	lw	a0,-104(s0)
    80006baa:	00000097          	auipc	ra,0x0
    80006bae:	d6c080e7          	jalr	-660(ra) # 80006916 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006bb2:	0001e597          	auipc	a1,0x1e
    80006bb6:	57658593          	addi	a1,a1,1398 # 80025128 <disk+0x2128>
    80006bba:	0001e517          	auipc	a0,0x1e
    80006bbe:	45e50513          	addi	a0,a0,1118 # 80025018 <disk+0x2018>
    80006bc2:	ffffc097          	auipc	ra,0xffffc
    80006bc6:	01e080e7          	jalr	30(ra) # 80002be0 <sleep>
  for(int i = 0; i < 3; i++){
    80006bca:	f9040713          	addi	a4,s0,-112
    80006bce:	84ce                	mv	s1,s3
    80006bd0:	bf41                	j	80006b60 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006bd2:	20058713          	addi	a4,a1,512
    80006bd6:	00471693          	slli	a3,a4,0x4
    80006bda:	0001c717          	auipc	a4,0x1c
    80006bde:	42670713          	addi	a4,a4,1062 # 80023000 <disk>
    80006be2:	9736                	add	a4,a4,a3
    80006be4:	4685                	li	a3,1
    80006be6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006bea:	20058713          	addi	a4,a1,512
    80006bee:	00471693          	slli	a3,a4,0x4
    80006bf2:	0001c717          	auipc	a4,0x1c
    80006bf6:	40e70713          	addi	a4,a4,1038 # 80023000 <disk>
    80006bfa:	9736                	add	a4,a4,a3
    80006bfc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006c00:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c04:	7679                	lui	a2,0xffffe
    80006c06:	963e                	add	a2,a2,a5
    80006c08:	0001e697          	auipc	a3,0x1e
    80006c0c:	3f868693          	addi	a3,a3,1016 # 80025000 <disk+0x2000>
    80006c10:	6298                	ld	a4,0(a3)
    80006c12:	9732                	add	a4,a4,a2
    80006c14:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006c16:	6298                	ld	a4,0(a3)
    80006c18:	9732                	add	a4,a4,a2
    80006c1a:	4541                	li	a0,16
    80006c1c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006c1e:	6298                	ld	a4,0(a3)
    80006c20:	9732                	add	a4,a4,a2
    80006c22:	4505                	li	a0,1
    80006c24:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006c28:	f9442703          	lw	a4,-108(s0)
    80006c2c:	6288                	ld	a0,0(a3)
    80006c2e:	962a                	add	a2,a2,a0
    80006c30:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c34:	0712                	slli	a4,a4,0x4
    80006c36:	6290                	ld	a2,0(a3)
    80006c38:	963a                	add	a2,a2,a4
    80006c3a:	05890513          	addi	a0,s2,88
    80006c3e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006c40:	6294                	ld	a3,0(a3)
    80006c42:	96ba                	add	a3,a3,a4
    80006c44:	40000613          	li	a2,1024
    80006c48:	c690                	sw	a2,8(a3)
  if(write)
    80006c4a:	140d0063          	beqz	s10,80006d8a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006c4e:	0001e697          	auipc	a3,0x1e
    80006c52:	3b26b683          	ld	a3,946(a3) # 80025000 <disk+0x2000>
    80006c56:	96ba                	add	a3,a3,a4
    80006c58:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c5c:	0001c817          	auipc	a6,0x1c
    80006c60:	3a480813          	addi	a6,a6,932 # 80023000 <disk>
    80006c64:	0001e517          	auipc	a0,0x1e
    80006c68:	39c50513          	addi	a0,a0,924 # 80025000 <disk+0x2000>
    80006c6c:	6114                	ld	a3,0(a0)
    80006c6e:	96ba                	add	a3,a3,a4
    80006c70:	00c6d603          	lhu	a2,12(a3)
    80006c74:	00166613          	ori	a2,a2,1
    80006c78:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006c7c:	f9842683          	lw	a3,-104(s0)
    80006c80:	6110                	ld	a2,0(a0)
    80006c82:	9732                	add	a4,a4,a2
    80006c84:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c88:	20058613          	addi	a2,a1,512
    80006c8c:	0612                	slli	a2,a2,0x4
    80006c8e:	9642                	add	a2,a2,a6
    80006c90:	577d                	li	a4,-1
    80006c92:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c96:	00469713          	slli	a4,a3,0x4
    80006c9a:	6114                	ld	a3,0(a0)
    80006c9c:	96ba                	add	a3,a3,a4
    80006c9e:	03078793          	addi	a5,a5,48
    80006ca2:	97c2                	add	a5,a5,a6
    80006ca4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006ca6:	611c                	ld	a5,0(a0)
    80006ca8:	97ba                	add	a5,a5,a4
    80006caa:	4685                	li	a3,1
    80006cac:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006cae:	611c                	ld	a5,0(a0)
    80006cb0:	97ba                	add	a5,a5,a4
    80006cb2:	4809                	li	a6,2
    80006cb4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006cb8:	611c                	ld	a5,0(a0)
    80006cba:	973e                	add	a4,a4,a5
    80006cbc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006cc0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006cc4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006cc8:	6518                	ld	a4,8(a0)
    80006cca:	00275783          	lhu	a5,2(a4)
    80006cce:	8b9d                	andi	a5,a5,7
    80006cd0:	0786                	slli	a5,a5,0x1
    80006cd2:	97ba                	add	a5,a5,a4
    80006cd4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006cd8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006cdc:	6518                	ld	a4,8(a0)
    80006cde:	00275783          	lhu	a5,2(a4)
    80006ce2:	2785                	addiw	a5,a5,1
    80006ce4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006ce8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006cec:	100017b7          	lui	a5,0x10001
    80006cf0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006cf4:	00492703          	lw	a4,4(s2)
    80006cf8:	4785                	li	a5,1
    80006cfa:	02f71163          	bne	a4,a5,80006d1c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006cfe:	0001e997          	auipc	s3,0x1e
    80006d02:	42a98993          	addi	s3,s3,1066 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006d06:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006d08:	85ce                	mv	a1,s3
    80006d0a:	854a                	mv	a0,s2
    80006d0c:	ffffc097          	auipc	ra,0xffffc
    80006d10:	ed4080e7          	jalr	-300(ra) # 80002be0 <sleep>
  while(b->disk == 1) {
    80006d14:	00492783          	lw	a5,4(s2)
    80006d18:	fe9788e3          	beq	a5,s1,80006d08 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006d1c:	f9042903          	lw	s2,-112(s0)
    80006d20:	20090793          	addi	a5,s2,512
    80006d24:	00479713          	slli	a4,a5,0x4
    80006d28:	0001c797          	auipc	a5,0x1c
    80006d2c:	2d878793          	addi	a5,a5,728 # 80023000 <disk>
    80006d30:	97ba                	add	a5,a5,a4
    80006d32:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006d36:	0001e997          	auipc	s3,0x1e
    80006d3a:	2ca98993          	addi	s3,s3,714 # 80025000 <disk+0x2000>
    80006d3e:	00491713          	slli	a4,s2,0x4
    80006d42:	0009b783          	ld	a5,0(s3)
    80006d46:	97ba                	add	a5,a5,a4
    80006d48:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d4c:	854a                	mv	a0,s2
    80006d4e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d52:	00000097          	auipc	ra,0x0
    80006d56:	bc4080e7          	jalr	-1084(ra) # 80006916 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d5a:	8885                	andi	s1,s1,1
    80006d5c:	f0ed                	bnez	s1,80006d3e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d5e:	0001e517          	auipc	a0,0x1e
    80006d62:	3ca50513          	addi	a0,a0,970 # 80025128 <disk+0x2128>
    80006d66:	ffffa097          	auipc	ra,0xffffa
    80006d6a:	f40080e7          	jalr	-192(ra) # 80000ca6 <release>
}
    80006d6e:	70a6                	ld	ra,104(sp)
    80006d70:	7406                	ld	s0,96(sp)
    80006d72:	64e6                	ld	s1,88(sp)
    80006d74:	6946                	ld	s2,80(sp)
    80006d76:	69a6                	ld	s3,72(sp)
    80006d78:	6a06                	ld	s4,64(sp)
    80006d7a:	7ae2                	ld	s5,56(sp)
    80006d7c:	7b42                	ld	s6,48(sp)
    80006d7e:	7ba2                	ld	s7,40(sp)
    80006d80:	7c02                	ld	s8,32(sp)
    80006d82:	6ce2                	ld	s9,24(sp)
    80006d84:	6d42                	ld	s10,16(sp)
    80006d86:	6165                	addi	sp,sp,112
    80006d88:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006d8a:	0001e697          	auipc	a3,0x1e
    80006d8e:	2766b683          	ld	a3,630(a3) # 80025000 <disk+0x2000>
    80006d92:	96ba                	add	a3,a3,a4
    80006d94:	4609                	li	a2,2
    80006d96:	00c69623          	sh	a2,12(a3)
    80006d9a:	b5c9                	j	80006c5c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d9c:	f9042583          	lw	a1,-112(s0)
    80006da0:	20058793          	addi	a5,a1,512
    80006da4:	0792                	slli	a5,a5,0x4
    80006da6:	0001c517          	auipc	a0,0x1c
    80006daa:	30250513          	addi	a0,a0,770 # 800230a8 <disk+0xa8>
    80006dae:	953e                	add	a0,a0,a5
  if(write)
    80006db0:	e20d11e3          	bnez	s10,80006bd2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006db4:	20058713          	addi	a4,a1,512
    80006db8:	00471693          	slli	a3,a4,0x4
    80006dbc:	0001c717          	auipc	a4,0x1c
    80006dc0:	24470713          	addi	a4,a4,580 # 80023000 <disk>
    80006dc4:	9736                	add	a4,a4,a3
    80006dc6:	0a072423          	sw	zero,168(a4)
    80006dca:	b505                	j	80006bea <virtio_disk_rw+0xf4>

0000000080006dcc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006dcc:	1101                	addi	sp,sp,-32
    80006dce:	ec06                	sd	ra,24(sp)
    80006dd0:	e822                	sd	s0,16(sp)
    80006dd2:	e426                	sd	s1,8(sp)
    80006dd4:	e04a                	sd	s2,0(sp)
    80006dd6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006dd8:	0001e517          	auipc	a0,0x1e
    80006ddc:	35050513          	addi	a0,a0,848 # 80025128 <disk+0x2128>
    80006de0:	ffffa097          	auipc	ra,0xffffa
    80006de4:	e0c080e7          	jalr	-500(ra) # 80000bec <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006de8:	10001737          	lui	a4,0x10001
    80006dec:	533c                	lw	a5,96(a4)
    80006dee:	8b8d                	andi	a5,a5,3
    80006df0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006df2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006df6:	0001e797          	auipc	a5,0x1e
    80006dfa:	20a78793          	addi	a5,a5,522 # 80025000 <disk+0x2000>
    80006dfe:	6b94                	ld	a3,16(a5)
    80006e00:	0207d703          	lhu	a4,32(a5)
    80006e04:	0026d783          	lhu	a5,2(a3)
    80006e08:	06f70163          	beq	a4,a5,80006e6a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e0c:	0001c917          	auipc	s2,0x1c
    80006e10:	1f490913          	addi	s2,s2,500 # 80023000 <disk>
    80006e14:	0001e497          	auipc	s1,0x1e
    80006e18:	1ec48493          	addi	s1,s1,492 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006e1c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e20:	6898                	ld	a4,16(s1)
    80006e22:	0204d783          	lhu	a5,32(s1)
    80006e26:	8b9d                	andi	a5,a5,7
    80006e28:	078e                	slli	a5,a5,0x3
    80006e2a:	97ba                	add	a5,a5,a4
    80006e2c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006e2e:	20078713          	addi	a4,a5,512
    80006e32:	0712                	slli	a4,a4,0x4
    80006e34:	974a                	add	a4,a4,s2
    80006e36:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006e3a:	e731                	bnez	a4,80006e86 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006e3c:	20078793          	addi	a5,a5,512
    80006e40:	0792                	slli	a5,a5,0x4
    80006e42:	97ca                	add	a5,a5,s2
    80006e44:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006e46:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006e4a:	ffffc097          	auipc	ra,0xffffc
    80006e4e:	f3c080e7          	jalr	-196(ra) # 80002d86 <wakeup>

    disk.used_idx += 1;
    80006e52:	0204d783          	lhu	a5,32(s1)
    80006e56:	2785                	addiw	a5,a5,1
    80006e58:	17c2                	slli	a5,a5,0x30
    80006e5a:	93c1                	srli	a5,a5,0x30
    80006e5c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e60:	6898                	ld	a4,16(s1)
    80006e62:	00275703          	lhu	a4,2(a4)
    80006e66:	faf71be3          	bne	a4,a5,80006e1c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006e6a:	0001e517          	auipc	a0,0x1e
    80006e6e:	2be50513          	addi	a0,a0,702 # 80025128 <disk+0x2128>
    80006e72:	ffffa097          	auipc	ra,0xffffa
    80006e76:	e34080e7          	jalr	-460(ra) # 80000ca6 <release>
}
    80006e7a:	60e2                	ld	ra,24(sp)
    80006e7c:	6442                	ld	s0,16(sp)
    80006e7e:	64a2                	ld	s1,8(sp)
    80006e80:	6902                	ld	s2,0(sp)
    80006e82:	6105                	addi	sp,sp,32
    80006e84:	8082                	ret
      panic("virtio_disk_intr status");
    80006e86:	00002517          	auipc	a0,0x2
    80006e8a:	b0250513          	addi	a0,a0,-1278 # 80008988 <syscalls+0x3c0>
    80006e8e:	ffff9097          	auipc	ra,0xffff9
    80006e92:	6b0080e7          	jalr	1712(ra) # 8000053e <panic>

0000000080006e96 <cas>:
    80006e96:	100522af          	lr.w	t0,(a0)
    80006e9a:	00b29563          	bne	t0,a1,80006ea4 <fail>
    80006e9e:	18c5252f          	sc.w	a0,a2,(a0)
    80006ea2:	8082                	ret

0000000080006ea4 <fail>:
    80006ea4:	4505                	li	a0,1
    80006ea6:	8082                	ret
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
