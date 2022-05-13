
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
    80000068:	78c78793          	addi	a5,a5,1932 # 800067f0 <timervec>
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
    80000130:	fcc080e7          	jalr	-52(ra) # 800030f8 <either_copyin>
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
    800001c8:	10c080e7          	jalr	268(ra) # 800022d0 <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	9ba080e7          	jalr	-1606(ra) # 80002b8e <sleep>
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
    80000214:	e92080e7          	jalr	-366(ra) # 800030a2 <either_copyout>
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
    800002f6:	e5c080e7          	jalr	-420(ra) # 8000314e <procdump>
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
    8000044a:	8ec080e7          	jalr	-1812(ra) # 80002d32 <wakeup>
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
    800008a4:	492080e7          	jalr	1170(ra) # 80002d32 <wakeup>
    
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
    80000930:	262080e7          	jalr	610(ra) # 80002b8e <sleep>
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
    80000b82:	72e080e7          	jalr	1838(ra) # 800022ac <mycpu>
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
    80000bb4:	6fc080e7          	jalr	1788(ra) # 800022ac <mycpu>
    80000bb8:	08052783          	lw	a5,128(a0)
    80000bbc:	cf99                	beqz	a5,80000bda <push_off+0x42>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	6ee080e7          	jalr	1774(ra) # 800022ac <mycpu>
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
    80000bde:	6d2080e7          	jalr	1746(ra) # 800022ac <mycpu>
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
    80000c20:	690080e7          	jalr	1680(ra) # 800022ac <mycpu>
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
    80000c4c:	664080e7          	jalr	1636(ra) # 800022ac <mycpu>
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
    80000ea8:	3f8080e7          	jalr	1016(ra) # 8000229c <cpuid>
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
    80000ec4:	3dc080e7          	jalr	988(ra) # 8000229c <cpuid>
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
    80000ee6:	3ac080e7          	jalr	940(ra) # 8000328e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eea:	00006097          	auipc	ra,0x6
    80000eee:	946080e7          	jalr	-1722(ra) # 80006830 <plicinithart>
  }

  scheduler();        
    80000ef2:	00002097          	auipc	ra,0x2
    80000ef6:	a26080e7          	jalr	-1498(ra) # 80002918 <scheduler>
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
    80000f56:	1f6080e7          	jalr	502(ra) # 80002148 <procinit>
    trapinit();      // trap vectors
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	30c080e7          	jalr	780(ra) # 80003266 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	32c080e7          	jalr	812(ra) # 8000328e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f6a:	00006097          	auipc	ra,0x6
    80000f6e:	8b0080e7          	jalr	-1872(ra) # 8000681a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f72:	00006097          	auipc	ra,0x6
    80000f76:	8be080e7          	jalr	-1858(ra) # 80006830 <plicinithart>
    binit();         // buffer cache
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	aa0080e7          	jalr	-1376(ra) # 80003a1a <binit>
    iinit();         // inode table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	130080e7          	jalr	304(ra) # 800040b2 <iinit>
    fileinit();      // file table
    80000f8a:	00004097          	auipc	ra,0x4
    80000f8e:	0da080e7          	jalr	218(ra) # 80005064 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f92:	00006097          	auipc	ra,0x6
    80000f96:	9c0080e7          	jalr	-1600(ra) # 80006952 <virtio_disk_init>
    userinit();      // first user process
    80000f9a:	00001097          	auipc	ra,0x1
    80000f9e:	628080e7          	jalr	1576(ra) # 800025c2 <userinit>
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
    80001252:	e64080e7          	jalr	-412(ra) # 800020b2 <proc_mapstacks>
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

000000008000184c <acquire_list2>:
 * 2 = zombie 
 * 3 = sleeping 
 * 4 = unused  
 */
void
acquire_list2(int number, int parent_cpu){ // TODO: change name of function
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
    80001856:	02f50763          	beq	a0,a5,80001884 <acquire_list2+0x38>
    number == 2 ? acquire(&zombieLock): 
    8000185a:	4789                	li	a5,2
    8000185c:	04f50263          	beq	a0,a5,800018a0 <acquire_list2+0x54>
      number == 3 ? acquire(&sleepLock): 
    80001860:	478d                	li	a5,3
    80001862:	04f50863          	beq	a0,a5,800018b2 <acquire_list2+0x66>
        number == 4 ? acquire(&unusedLock):  
    80001866:	4791                	li	a5,4
    80001868:	04f51e63          	bne	a0,a5,800018c4 <acquire_list2+0x78>
    8000186c:	00010517          	auipc	a0,0x10
    80001870:	aec50513          	addi	a0,a0,-1300 # 80011358 <unusedLock>
    80001874:	fffff097          	auipc	ra,0xfffff
    80001878:	378080e7          	jalr	888(ra) # 80000bec <acquire>
          panic("wrong call in acquire_list2");
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
    8000189e:	bff9                	j	8000187c <acquire_list2+0x30>
    number == 2 ? acquire(&zombieLock): 
    800018a0:	00010517          	auipc	a0,0x10
    800018a4:	a8850513          	addi	a0,a0,-1400 # 80011328 <zombieLock>
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	344080e7          	jalr	836(ra) # 80000bec <acquire>
    800018b0:	b7f1                	j	8000187c <acquire_list2+0x30>
      number == 3 ? acquire(&sleepLock): 
    800018b2:	00010517          	auipc	a0,0x10
    800018b6:	a8e50513          	addi	a0,a0,-1394 # 80011340 <sleepLock>
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	332080e7          	jalr	818(ra) # 80000bec <acquire>
    800018c2:	bf6d                	j	8000187c <acquire_list2+0x30>
          panic("wrong call in acquire_list2");
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
    8000192e:	8ce50513          	addi	a0,a0,-1842 # 800081f8 <digits+0x1b8>
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
    8000198c:	89050513          	addi	a0,a0,-1904 # 80008218 <digits+0x1d8>
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
    80001a14:	82850513          	addi	a0,a0,-2008 # 80008238 <digits+0x1f8>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>

0000000080001a20 <add_to_list2>:


void
add_to_list2(struct proc* p, struct proc* first, int type, int parent_cpu)//TODO: change name of function
{
    80001a20:	7139                	addi	sp,sp,-64
    80001a22:	fc06                	sd	ra,56(sp)
    80001a24:	f822                	sd	s0,48(sp)
    80001a26:	f426                	sd	s1,40(sp)
    80001a28:	f04a                	sd	s2,32(sp)
    80001a2a:	ec4e                	sd	s3,24(sp)
    80001a2c:	e852                	sd	s4,16(sp)
    80001a2e:	e456                	sd	s5,8(sp)
    80001a30:	e05a                	sd	s6,0(sp)
    80001a32:	0080                	addi	s0,sp,64
  if(!p){
    80001a34:	c505                	beqz	a0,80001a5c <add_to_list2+0x3c>
    80001a36:	8b2a                	mv	s6,a0
    80001a38:	84ae                	mv	s1,a1
    80001a3a:	8a32                	mv	s4,a2
    80001a3c:	8ab6                	mv	s5,a3
  if(!first){
      set_first2(p, type, parent_cpu);
      release_list2(type, parent_cpu);
  }
  else{
    struct proc* prev = 0;
    80001a3e:	4901                	li	s2,0
  if(!first){
    80001a40:	e1a1                	bnez	a1,80001a80 <add_to_list2+0x60>
      set_first2(p, type, parent_cpu);
    80001a42:	8636                	mv	a2,a3
    80001a44:	85d2                	mv	a1,s4
    80001a46:	00000097          	auipc	ra,0x0
    80001a4a:	ef4080e7          	jalr	-268(ra) # 8000193a <set_first2>
      release_list2(type, parent_cpu);
    80001a4e:	85d6                	mv	a1,s5
    80001a50:	8552                	mv	a0,s4
    80001a52:	00000097          	auipc	ra,0x0
    80001a56:	f46080e7          	jalr	-186(ra) # 80001998 <release_list2>
    80001a5a:	a891                	j	80001aae <add_to_list2+0x8e>
    panic("can't add null to list");
    80001a5c:	00006517          	auipc	a0,0x6
    80001a60:	7fc50513          	addi	a0,a0,2044 # 80008258 <digits+0x218>
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	ada080e7          	jalr	-1318(ra) # 8000053e <panic>

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list2(type, parent_cpu);
    80001a6c:	85d6                	mv	a1,s5
    80001a6e:	8552                	mv	a0,s4
    80001a70:	00000097          	auipc	ra,0x0
    80001a74:	f28080e7          	jalr	-216(ra) # 80001998 <release_list2>
      }
      prev = first;
      first = first->next;
    80001a78:	68bc                	ld	a5,80(s1)
    while(first){
    80001a7a:	8926                	mv	s2,s1
    80001a7c:	c395                	beqz	a5,80001aa0 <add_to_list2+0x80>
      first = first->next;
    80001a7e:	84be                	mv	s1,a5
      acquire(&first->list_lock);
    80001a80:	01848993          	addi	s3,s1,24
    80001a84:	854e                	mv	a0,s3
    80001a86:	fffff097          	auipc	ra,0xfffff
    80001a8a:	166080e7          	jalr	358(ra) # 80000bec <acquire>
      if(prev){
    80001a8e:	fc090fe3          	beqz	s2,80001a6c <add_to_list2+0x4c>
        release(&prev->list_lock);
    80001a92:	01890513          	addi	a0,s2,24 # 1018 <_entry-0x7fffefe8>
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	210080e7          	jalr	528(ra) # 80000ca6 <release>
    80001a9e:	bfe9                	j	80001a78 <add_to_list2+0x58>
    }
    prev->next = p;
    80001aa0:	0564b823          	sd	s6,80(s1)
    release(&prev->list_lock);
    80001aa4:	854e                	mv	a0,s3
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	200080e7          	jalr	512(ra) # 80000ca6 <release>
  }
}
    80001aae:	70e2                	ld	ra,56(sp)
    80001ab0:	7442                	ld	s0,48(sp)
    80001ab2:	74a2                	ld	s1,40(sp)
    80001ab4:	7902                	ld	s2,32(sp)
    80001ab6:	69e2                	ld	s3,24(sp)
    80001ab8:	6a42                	ld	s4,16(sp)
    80001aba:	6aa2                	ld	s5,8(sp)
    80001abc:	6b02                	ld	s6,0(sp)
    80001abe:	6121                	addi	sp,sp,64
    80001ac0:	8082                	ret

0000000080001ac2 <add_proc2>:

void //TODO: cahnge 
add_proc2(struct proc* p, int number, int parent_cpu)
{
    80001ac2:	7179                	addi	sp,sp,-48
    80001ac4:	f406                	sd	ra,40(sp)
    80001ac6:	f022                	sd	s0,32(sp)
    80001ac8:	ec26                	sd	s1,24(sp)
    80001aca:	e84a                	sd	s2,16(sp)
    80001acc:	e44e                	sd	s3,8(sp)
    80001ace:	1800                	addi	s0,sp,48
    80001ad0:	89aa                	mv	s3,a0
    80001ad2:	84ae                	mv	s1,a1
    80001ad4:	8932                	mv	s2,a2
  struct proc* first;
  acquire_list2(number, parent_cpu);
    80001ad6:	85b2                	mv	a1,a2
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	d72080e7          	jalr	-654(ra) # 8000184c <acquire_list2>
  first = get_first2(number, parent_cpu);
    80001ae2:	85ca                	mv	a1,s2
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	00000097          	auipc	ra,0x0
    80001aea:	dee080e7          	jalr	-530(ra) # 800018d4 <get_first2>
    80001aee:	85aa                	mv	a1,a0
  add_to_list2(p, first, number, parent_cpu);//TODO change name
    80001af0:	86ca                	mv	a3,s2
    80001af2:	8626                	mv	a2,s1
    80001af4:	854e                	mv	a0,s3
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	f2a080e7          	jalr	-214(ra) # 80001a20 <add_to_list2>
}
    80001afe:	70a2                	ld	ra,40(sp)
    80001b00:	7402                	ld	s0,32(sp)
    80001b02:	64e2                	ld	s1,24(sp)
    80001b04:	6942                	ld	s2,16(sp)
    80001b06:	69a2                	ld	s3,8(sp)
    80001b08:	6145                	addi	sp,sp,48
    80001b0a:	8082                	ret

0000000080001b0c <get_lazy_cpu>:
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
int init = 0;

int
get_lazy_cpu(){
    80001b0c:	1141                	addi	sp,sp,-16
    80001b0e:	e422                	sd	s0,8(sp)
    80001b10:	0800                	addi	s0,sp,16
  int curr_min = 0;
  for(int i=1; i<CPUS; i++){
    curr_min = (cpus[i].queue_size < cpus[curr_min].queue_size) ? i : curr_min;
    80001b12:	0000f717          	auipc	a4,0xf
    80001b16:	7ce70713          	addi	a4,a4,1998 # 800112e0 <readyLock>
    80001b1a:	12073503          	ld	a0,288(a4)
    80001b1e:	6b5c                	ld	a5,144(a4)
  for(int i=1; i<CPUS; i++){
    80001b20:	00f53533          	sltu	a0,a0,a5
    curr_min = (cpus[i].queue_size < cpus[curr_min].queue_size) ? i : curr_min;
    80001b24:	00351793          	slli	a5,a0,0x3
    80001b28:	97aa                	add	a5,a5,a0
    80001b2a:	0792                	slli	a5,a5,0x4
    80001b2c:	97ba                	add	a5,a5,a4
    80001b2e:	1b073703          	ld	a4,432(a4)
    80001b32:	6bdc                	ld	a5,144(a5)
    80001b34:	00f77363          	bgeu	a4,a5,80001b3a <get_lazy_cpu+0x2e>
  for(int i=1; i<CPUS; i++){
    80001b38:	4509                	li	a0,2
  }
  return curr_min;
}
    80001b3a:	6422                	ld	s0,8(sp)
    80001b3c:	0141                	addi	sp,sp,16
    80001b3e:	8082                	ret

0000000080001b40 <increase_size>:

void
increase_size(int cpu_id){
    80001b40:	1101                	addi	sp,sp,-32
    80001b42:	ec06                	sd	ra,24(sp)
    80001b44:	e822                	sd	s0,16(sp)
    80001b46:	e426                	sd	s1,8(sp)
    80001b48:	e04a                	sd	s2,0(sp)
    80001b4a:	1000                	addi	s0,sp,32
  struct cpu* c = &cpus[cpu_id];
  uint64 old;
  do{
    old = c->queue_size;
  } while(cas(&c->queue_size, old, old+1));
    80001b4c:	00351913          	slli	s2,a0,0x3
    80001b50:	992a                	add	s2,s2,a0
    80001b52:	00491793          	slli	a5,s2,0x4
    80001b56:	00010917          	auipc	s2,0x10
    80001b5a:	81a90913          	addi	s2,s2,-2022 # 80011370 <cpus>
    80001b5e:	993e                	add	s2,s2,a5
    old = c->queue_size;
    80001b60:	0000f497          	auipc	s1,0xf
    80001b64:	78048493          	addi	s1,s1,1920 # 800112e0 <readyLock>
    80001b68:	94be                	add	s1,s1,a5
    80001b6a:	68cc                	ld	a1,144(s1)
  } while(cas(&c->queue_size, old, old+1));
    80001b6c:	0015861b          	addiw	a2,a1,1
    80001b70:	2581                	sext.w	a1,a1
    80001b72:	854a                	mv	a0,s2
    80001b74:	00005097          	auipc	ra,0x5
    80001b78:	2c2080e7          	jalr	706(ra) # 80006e36 <cas>
    80001b7c:	f57d                	bnez	a0,80001b6a <increase_size+0x2a>
}
    80001b7e:	60e2                	ld	ra,24(sp)
    80001b80:	6442                	ld	s0,16(sp)
    80001b82:	64a2                	ld	s1,8(sp)
    80001b84:	6902                	ld	s2,0(sp)
    80001b86:	6105                	addi	sp,sp,32
    80001b88:	8082                	ret

0000000080001b8a <decrease_size>:


void
decrease_size(int cpu_id){
    80001b8a:	1101                	addi	sp,sp,-32
    80001b8c:	ec06                	sd	ra,24(sp)
    80001b8e:	e822                	sd	s0,16(sp)
    80001b90:	e426                	sd	s1,8(sp)
    80001b92:	e04a                	sd	s2,0(sp)
    80001b94:	1000                	addi	s0,sp,32
  struct cpu* c = &cpus[cpu_id];
  uint64 old;
  do{
    old = c->queue_size;
  } while(cas(&c->queue_size, old, old-1));
    80001b96:	00351913          	slli	s2,a0,0x3
    80001b9a:	992a                	add	s2,s2,a0
    80001b9c:	00491793          	slli	a5,s2,0x4
    80001ba0:	0000f917          	auipc	s2,0xf
    80001ba4:	7d090913          	addi	s2,s2,2000 # 80011370 <cpus>
    80001ba8:	993e                	add	s2,s2,a5
    old = c->queue_size;
    80001baa:	0000f497          	auipc	s1,0xf
    80001bae:	73648493          	addi	s1,s1,1846 # 800112e0 <readyLock>
    80001bb2:	94be                	add	s1,s1,a5
    80001bb4:	68cc                	ld	a1,144(s1)
  } while(cas(&c->queue_size, old, old-1));
    80001bb6:	fff5861b          	addiw	a2,a1,-1
    80001bba:	2581                	sext.w	a1,a1
    80001bbc:	854a                	mv	a0,s2
    80001bbe:	00005097          	auipc	ra,0x5
    80001bc2:	278080e7          	jalr	632(ra) # 80006e36 <cas>
    80001bc6:	f57d                	bnez	a0,80001bb4 <decrease_size+0x2a>
}
    80001bc8:	60e2                	ld	ra,24(sp)
    80001bca:	6442                	ld	s0,16(sp)
    80001bcc:	64a2                	ld	s1,8(sp)
    80001bce:	6902                	ld	s2,0(sp)
    80001bd0:	6105                	addi	sp,sp,32
    80001bd2:	8082                	ret

0000000080001bd4 <acquire_list>:
struct spinlock zombie_lock;
struct spinlock sleeping_lock;
struct spinlock unused_lock;

void
acquire_list(int type, int cpu_id){
    80001bd4:	1141                	addi	sp,sp,-16
    80001bd6:	e406                	sd	ra,8(sp)
    80001bd8:	e022                	sd	s0,0(sp)
    80001bda:	0800                	addi	s0,sp,16
  switch (type)
    80001bdc:	4789                	li	a5,2
    80001bde:	04f50e63          	beq	a0,a5,80001c3a <acquire_list+0x66>
    80001be2:	00a7cf63          	blt	a5,a0,80001c00 <acquire_list+0x2c>
    80001be6:	c90d                	beqz	a0,80001c18 <acquire_list+0x44>
    80001be8:	4785                	li	a5,1
    80001bea:	06f51163          	bne	a0,a5,80001c4c <acquire_list+0x78>
  {
  case READYL:
    acquire(&ready_lock[cpu_id]);
    break;
  case ZOMBIEL:
    acquire(&zombie_lock);
    80001bee:	00010517          	auipc	a0,0x10
    80001bf2:	97a50513          	addi	a0,a0,-1670 # 80011568 <zombie_lock>
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	ff6080e7          	jalr	-10(ra) # 80000bec <acquire>
    break;
    80001bfe:	a815                	j	80001c32 <acquire_list+0x5e>
  switch (type)
    80001c00:	478d                	li	a5,3
    80001c02:	04f51563          	bne	a0,a5,80001c4c <acquire_list+0x78>
  case SLEEPINGL:
    acquire(&sleeping_lock);
    break;
  case UNUSEDL:
    acquire(&unused_lock);
    80001c06:	00010517          	auipc	a0,0x10
    80001c0a:	99250513          	addi	a0,a0,-1646 # 80011598 <unused_lock>
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	fde080e7          	jalr	-34(ra) # 80000bec <acquire>
    break;
    80001c16:	a831                	j	80001c32 <acquire_list+0x5e>
    acquire(&ready_lock[cpu_id]);
    80001c18:	00159513          	slli	a0,a1,0x1
    80001c1c:	95aa                	add	a1,a1,a0
    80001c1e:	058e                	slli	a1,a1,0x3
    80001c20:	00010517          	auipc	a0,0x10
    80001c24:	90050513          	addi	a0,a0,-1792 # 80011520 <ready_lock>
    80001c28:	952e                	add	a0,a0,a1
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	fc2080e7          	jalr	-62(ra) # 80000bec <acquire>
  
  default:
    panic("wrong type list");
  }
}
    80001c32:	60a2                	ld	ra,8(sp)
    80001c34:	6402                	ld	s0,0(sp)
    80001c36:	0141                	addi	sp,sp,16
    80001c38:	8082                	ret
    acquire(&sleeping_lock);
    80001c3a:	00010517          	auipc	a0,0x10
    80001c3e:	94650513          	addi	a0,a0,-1722 # 80011580 <sleeping_lock>
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	faa080e7          	jalr	-86(ra) # 80000bec <acquire>
    break;
    80001c4a:	b7e5                	j	80001c32 <acquire_list+0x5e>
    panic("wrong type list");
    80001c4c:	00006517          	auipc	a0,0x6
    80001c50:	62450513          	addi	a0,a0,1572 # 80008270 <digits+0x230>
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	8ea080e7          	jalr	-1814(ra) # 8000053e <panic>

0000000080001c5c <get_head>:

struct proc* get_head(int type, int cpu_id){
  struct proc* p;

  switch (type)
    80001c5c:	4789                	li	a5,2
    80001c5e:	04f50163          	beq	a0,a5,80001ca0 <get_head+0x44>
    80001c62:	00a7cb63          	blt	a5,a0,80001c78 <get_head+0x1c>
    80001c66:	c10d                	beqz	a0,80001c88 <get_head+0x2c>
    80001c68:	4785                	li	a5,1
    80001c6a:	04f51063          	bne	a0,a5,80001caa <get_head+0x4e>
  {
  case READYL:
    p = cpus[cpu_id].first;
    break;
  case ZOMBIEL:
    p = zombie_list;
    80001c6e:	00007517          	auipc	a0,0x7
    80001c72:	3ca53503          	ld	a0,970(a0) # 80009038 <zombie_list>
    break;
    80001c76:	8082                	ret
  switch (type)
    80001c78:	478d                	li	a5,3
    80001c7a:	02f51863          	bne	a0,a5,80001caa <get_head+0x4e>
  case SLEEPINGL:
    p = sleeping_list;
    break;
  case UNUSEDL:
    p = unused_list;
    80001c7e:	00007517          	auipc	a0,0x7
    80001c82:	3aa53503          	ld	a0,938(a0) # 80009028 <unused_list>
  
  default:
    panic("wrong type list");
  }
  return p;
}
    80001c86:	8082                	ret
    p = cpus[cpu_id].first;
    80001c88:	00359793          	slli	a5,a1,0x3
    80001c8c:	95be                	add	a1,a1,a5
    80001c8e:	0592                	slli	a1,a1,0x4
    80001c90:	0000f797          	auipc	a5,0xf
    80001c94:	65078793          	addi	a5,a5,1616 # 800112e0 <readyLock>
    80001c98:	95be                	add	a1,a1,a5
    80001c9a:	1185b503          	ld	a0,280(a1)
    break;
    80001c9e:	8082                	ret
    p = sleeping_list;
    80001ca0:	00007517          	auipc	a0,0x7
    80001ca4:	39053503          	ld	a0,912(a0) # 80009030 <sleeping_list>
    break;
    80001ca8:	8082                	ret
struct proc* get_head(int type, int cpu_id){
    80001caa:	1141                	addi	sp,sp,-16
    80001cac:	e406                	sd	ra,8(sp)
    80001cae:	e022                	sd	s0,0(sp)
    80001cb0:	0800                	addi	s0,sp,16
    panic("wrong type list");
    80001cb2:	00006517          	auipc	a0,0x6
    80001cb6:	5be50513          	addi	a0,a0,1470 # 80008270 <digits+0x230>
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	884080e7          	jalr	-1916(ra) # 8000053e <panic>

0000000080001cc2 <set_head>:


void
set_head(struct proc* p, int type, int cpu_id)
{
  switch (type)
    80001cc2:	4789                	li	a5,2
    80001cc4:	04f58163          	beq	a1,a5,80001d06 <set_head+0x44>
    80001cc8:	00b7cb63          	blt	a5,a1,80001cde <set_head+0x1c>
    80001ccc:	c18d                	beqz	a1,80001cee <set_head+0x2c>
    80001cce:	4785                	li	a5,1
    80001cd0:	04f59063          	bne	a1,a5,80001d10 <set_head+0x4e>
  {
  case READYL:
    cpus[cpu_id].first = p;
    break;
  case ZOMBIEL:
    zombie_list = p;
    80001cd4:	00007797          	auipc	a5,0x7
    80001cd8:	36a7b223          	sd	a0,868(a5) # 80009038 <zombie_list>
    break;
    80001cdc:	8082                	ret
  switch (type)
    80001cde:	478d                	li	a5,3
    80001ce0:	02f59863          	bne	a1,a5,80001d10 <set_head+0x4e>
  case SLEEPINGL:
    sleeping_list = p;
    break;
  case UNUSEDL:
    unused_list = p;
    80001ce4:	00007797          	auipc	a5,0x7
    80001ce8:	34a7b223          	sd	a0,836(a5) # 80009028 <unused_list>
    break;
    80001cec:	8082                	ret
    cpus[cpu_id].first = p;
    80001cee:	00361793          	slli	a5,a2,0x3
    80001cf2:	963e                	add	a2,a2,a5
    80001cf4:	0612                	slli	a2,a2,0x4
    80001cf6:	0000f797          	auipc	a5,0xf
    80001cfa:	5ea78793          	addi	a5,a5,1514 # 800112e0 <readyLock>
    80001cfe:	963e                	add	a2,a2,a5
    80001d00:	10a63c23          	sd	a0,280(a2)
    break;
    80001d04:	8082                	ret
    sleeping_list = p;
    80001d06:	00007797          	auipc	a5,0x7
    80001d0a:	32a7b523          	sd	a0,810(a5) # 80009030 <sleeping_list>
    break;
    80001d0e:	8082                	ret
{
    80001d10:	1141                	addi	sp,sp,-16
    80001d12:	e406                	sd	ra,8(sp)
    80001d14:	e022                	sd	s0,0(sp)
    80001d16:	0800                	addi	s0,sp,16

  
  default:
    panic("wrong type list");
    80001d18:	00006517          	auipc	a0,0x6
    80001d1c:	55850513          	addi	a0,a0,1368 # 80008270 <digits+0x230>
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	81e080e7          	jalr	-2018(ra) # 8000053e <panic>

0000000080001d28 <release_list3>:
  }
}

void
release_list3(int number, int parent_cpu){
    80001d28:	1141                	addi	sp,sp,-16
    80001d2a:	e406                	sd	ra,8(sp)
    80001d2c:	e022                	sd	s0,0(sp)
    80001d2e:	0800                	addi	s0,sp,16
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001d30:	4785                	li	a5,1
    80001d32:	02f50763          	beq	a0,a5,80001d60 <release_list3+0x38>
      number == 2 ? release(&zombie_lock): 
    80001d36:	4789                	li	a5,2
    80001d38:	04f50263          	beq	a0,a5,80001d7c <release_list3+0x54>
        number == 3 ? release(&sleeping_lock): 
    80001d3c:	478d                	li	a5,3
    80001d3e:	04f50863          	beq	a0,a5,80001d8e <release_list3+0x66>
          number == 4 ? release(&unused_lock):  
    80001d42:	4791                	li	a5,4
    80001d44:	04f51e63          	bne	a0,a5,80001da0 <release_list3+0x78>
    80001d48:	00010517          	auipc	a0,0x10
    80001d4c:	85050513          	addi	a0,a0,-1968 # 80011598 <unused_lock>
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	f56080e7          	jalr	-170(ra) # 80000ca6 <release>
            panic("wrong call in release_list3");
}
    80001d58:	60a2                	ld	ra,8(sp)
    80001d5a:	6402                	ld	s0,0(sp)
    80001d5c:	0141                	addi	sp,sp,16
    80001d5e:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001d60:	00159513          	slli	a0,a1,0x1
    80001d64:	95aa                	add	a1,a1,a0
    80001d66:	058e                	slli	a1,a1,0x3
    80001d68:	0000f517          	auipc	a0,0xf
    80001d6c:	7b850513          	addi	a0,a0,1976 # 80011520 <ready_lock>
    80001d70:	952e                	add	a0,a0,a1
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	f34080e7          	jalr	-204(ra) # 80000ca6 <release>
    80001d7a:	bff9                	j	80001d58 <release_list3+0x30>
      number == 2 ? release(&zombie_lock): 
    80001d7c:	0000f517          	auipc	a0,0xf
    80001d80:	7ec50513          	addi	a0,a0,2028 # 80011568 <zombie_lock>
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	f22080e7          	jalr	-222(ra) # 80000ca6 <release>
    80001d8c:	b7f1                	j	80001d58 <release_list3+0x30>
        number == 3 ? release(&sleeping_lock): 
    80001d8e:	0000f517          	auipc	a0,0xf
    80001d92:	7f250513          	addi	a0,a0,2034 # 80011580 <sleeping_lock>
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	f10080e7          	jalr	-240(ra) # 80000ca6 <release>
    80001d9e:	bf6d                	j	80001d58 <release_list3+0x30>
            panic("wrong call in release_list3");
    80001da0:	00006517          	auipc	a0,0x6
    80001da4:	4e050513          	addi	a0,a0,1248 # 80008280 <digits+0x240>
    80001da8:	ffffe097          	auipc	ra,0xffffe
    80001dac:	796080e7          	jalr	1942(ra) # 8000053e <panic>

0000000080001db0 <release_list>:

void
release_list(int type, int parent_cpu){
    80001db0:	1141                	addi	sp,sp,-16
    80001db2:	e406                	sd	ra,8(sp)
    80001db4:	e022                	sd	s0,0(sp)
    80001db6:	0800                	addi	s0,sp,16
  type==READYL ? release_list3(1,parent_cpu): 
    80001db8:	c515                	beqz	a0,80001de4 <release_list+0x34>
    type==ZOMBIEL ? release_list3(2,parent_cpu):
    80001dba:	4785                	li	a5,1
    80001dbc:	04f50263          	beq	a0,a5,80001e00 <release_list+0x50>
      type==SLEEPINGL ? release_list3(3,parent_cpu):
    80001dc0:	4789                	li	a5,2
    80001dc2:	04f50863          	beq	a0,a5,80001e12 <release_list+0x62>
        type==UNUSEDL ? release_list3(4,parent_cpu):
    80001dc6:	478d                	li	a5,3
    80001dc8:	04f51e63          	bne	a0,a5,80001e24 <release_list+0x74>
          number == 4 ? release(&unused_lock):  
    80001dcc:	0000f517          	auipc	a0,0xf
    80001dd0:	7cc50513          	addi	a0,a0,1996 # 80011598 <unused_lock>
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	ed2080e7          	jalr	-302(ra) # 80000ca6 <release>
          panic("wrong type list");
}
    80001ddc:	60a2                	ld	ra,8(sp)
    80001dde:	6402                	ld	s0,0(sp)
    80001de0:	0141                	addi	sp,sp,16
    80001de2:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001de4:	00159513          	slli	a0,a1,0x1
    80001de8:	95aa                	add	a1,a1,a0
    80001dea:	058e                	slli	a1,a1,0x3
    80001dec:	0000f517          	auipc	a0,0xf
    80001df0:	73450513          	addi	a0,a0,1844 # 80011520 <ready_lock>
    80001df4:	952e                	add	a0,a0,a1
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	eb0080e7          	jalr	-336(ra) # 80000ca6 <release>
}
    80001dfe:	bff9                	j	80001ddc <release_list+0x2c>
      number == 2 ? release(&zombie_lock): 
    80001e00:	0000f517          	auipc	a0,0xf
    80001e04:	76850513          	addi	a0,a0,1896 # 80011568 <zombie_lock>
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	e9e080e7          	jalr	-354(ra) # 80000ca6 <release>
}
    80001e10:	b7f1                	j	80001ddc <release_list+0x2c>
        number == 3 ? release(&sleeping_lock): 
    80001e12:	0000f517          	auipc	a0,0xf
    80001e16:	76e50513          	addi	a0,a0,1902 # 80011580 <sleeping_lock>
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	e8c080e7          	jalr	-372(ra) # 80000ca6 <release>
}
    80001e22:	bf6d                	j	80001ddc <release_list+0x2c>
          panic("wrong type list");
    80001e24:	00006517          	auipc	a0,0x6
    80001e28:	44c50513          	addi	a0,a0,1100 # 80008270 <digits+0x230>
    80001e2c:	ffffe097          	auipc	ra,0xffffe
    80001e30:	712080e7          	jalr	1810(ra) # 8000053e <panic>

0000000080001e34 <add_to_list>:



void
add_to_list(struct proc* p, struct proc* head, int type, int cpu_id)
{
    80001e34:	7139                	addi	sp,sp,-64
    80001e36:	fc06                	sd	ra,56(sp)
    80001e38:	f822                	sd	s0,48(sp)
    80001e3a:	f426                	sd	s1,40(sp)
    80001e3c:	f04a                	sd	s2,32(sp)
    80001e3e:	ec4e                	sd	s3,24(sp)
    80001e40:	e852                	sd	s4,16(sp)
    80001e42:	e456                	sd	s5,8(sp)
    80001e44:	e05a                	sd	s6,0(sp)
    80001e46:	0080                	addi	s0,sp,64
  if(!p){
    80001e48:	c505                	beqz	a0,80001e70 <add_to_list+0x3c>
    80001e4a:	8b2a                	mv	s6,a0
    80001e4c:	84ae                	mv	s1,a1
    80001e4e:	8a32                	mv	s4,a2
    80001e50:	8ab6                	mv	s5,a3
  if(!head){
      set_head(p, type, cpu_id);
      release_list(type, cpu_id);
  }
  else{
    struct proc* prev = 0;
    80001e52:	4901                	li	s2,0
  if(!head){
    80001e54:	e1a1                	bnez	a1,80001e94 <add_to_list+0x60>
      set_head(p, type, cpu_id);
    80001e56:	8636                	mv	a2,a3
    80001e58:	85d2                	mv	a1,s4
    80001e5a:	00000097          	auipc	ra,0x0
    80001e5e:	e68080e7          	jalr	-408(ra) # 80001cc2 <set_head>
      release_list(type, cpu_id);
    80001e62:	85d6                	mv	a1,s5
    80001e64:	8552                	mv	a0,s4
    80001e66:	00000097          	auipc	ra,0x0
    80001e6a:	f4a080e7          	jalr	-182(ra) # 80001db0 <release_list>
    80001e6e:	a891                	j	80001ec2 <add_to_list+0x8e>
    panic("can't add null to list");
    80001e70:	00006517          	auipc	a0,0x6
    80001e74:	3e850513          	addi	a0,a0,1000 # 80008258 <digits+0x218>
    80001e78:	ffffe097          	auipc	ra,0xffffe
    80001e7c:	6c6080e7          	jalr	1734(ra) # 8000053e <panic>

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list(type, cpu_id);
    80001e80:	85d6                	mv	a1,s5
    80001e82:	8552                	mv	a0,s4
    80001e84:	00000097          	auipc	ra,0x0
    80001e88:	f2c080e7          	jalr	-212(ra) # 80001db0 <release_list>
      }
      prev = head;
      head = head->next;
    80001e8c:	68bc                	ld	a5,80(s1)
    while(head){
    80001e8e:	8926                	mv	s2,s1
    80001e90:	c395                	beqz	a5,80001eb4 <add_to_list+0x80>
      head = head->next;
    80001e92:	84be                	mv	s1,a5
      acquire(&head->list_lock);
    80001e94:	01848993          	addi	s3,s1,24
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	d52080e7          	jalr	-686(ra) # 80000bec <acquire>
      if(prev){
    80001ea2:	fc090fe3          	beqz	s2,80001e80 <add_to_list+0x4c>
        release(&prev->list_lock);
    80001ea6:	01890513          	addi	a0,s2,24
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	dfc080e7          	jalr	-516(ra) # 80000ca6 <release>
    80001eb2:	bfe9                	j	80001e8c <add_to_list+0x58>
    }
    prev->next = p;
    80001eb4:	0564b823          	sd	s6,80(s1)
    release(&prev->list_lock);
    80001eb8:	854e                	mv	a0,s3
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	dec080e7          	jalr	-532(ra) # 80000ca6 <release>
  }
}
    80001ec2:	70e2                	ld	ra,56(sp)
    80001ec4:	7442                	ld	s0,48(sp)
    80001ec6:	74a2                	ld	s1,40(sp)
    80001ec8:	7902                	ld	s2,32(sp)
    80001eca:	69e2                	ld	s3,24(sp)
    80001ecc:	6a42                	ld	s4,16(sp)
    80001ece:	6aa2                	ld	s5,8(sp)
    80001ed0:	6b02                	ld	s6,0(sp)
    80001ed2:	6121                	addi	sp,sp,64
    80001ed4:	8082                	ret

0000000080001ed6 <add_proc_to_list>:


void 
add_proc_to_list(struct proc* p, int type, int cpu_id)
{
    80001ed6:	7179                	addi	sp,sp,-48
    80001ed8:	f406                	sd	ra,40(sp)
    80001eda:	f022                	sd	s0,32(sp)
    80001edc:	ec26                	sd	s1,24(sp)
    80001ede:	e84a                	sd	s2,16(sp)
    80001ee0:	e44e                	sd	s3,8(sp)
    80001ee2:	1800                	addi	s0,sp,48
  // bad argument
  if(!p){
    80001ee4:	cd1d                	beqz	a0,80001f22 <add_proc_to_list+0x4c>
    80001ee6:	89aa                	mv	s3,a0
    80001ee8:	84ae                	mv	s1,a1
    80001eea:	8932                	mv	s2,a2
    panic("Add proc to list");
  }
  struct proc* head;
  acquire_list(type, cpu_id);
    80001eec:	85b2                	mv	a1,a2
    80001eee:	8526                	mv	a0,s1
    80001ef0:	00000097          	auipc	ra,0x0
    80001ef4:	ce4080e7          	jalr	-796(ra) # 80001bd4 <acquire_list>
  head = get_head(type, cpu_id);
    80001ef8:	85ca                	mv	a1,s2
    80001efa:	8526                	mv	a0,s1
    80001efc:	00000097          	auipc	ra,0x0
    80001f00:	d60080e7          	jalr	-672(ra) # 80001c5c <get_head>
    80001f04:	85aa                	mv	a1,a0
  add_to_list(p, head, type, cpu_id);
    80001f06:	86ca                	mv	a3,s2
    80001f08:	8626                	mv	a2,s1
    80001f0a:	854e                	mv	a0,s3
    80001f0c:	00000097          	auipc	ra,0x0
    80001f10:	f28080e7          	jalr	-216(ra) # 80001e34 <add_to_list>
}
    80001f14:	70a2                	ld	ra,40(sp)
    80001f16:	7402                	ld	s0,32(sp)
    80001f18:	64e2                	ld	s1,24(sp)
    80001f1a:	6942                	ld	s2,16(sp)
    80001f1c:	69a2                	ld	s3,8(sp)
    80001f1e:	6145                	addi	sp,sp,48
    80001f20:	8082                	ret
    panic("Add proc to list");
    80001f22:	00006517          	auipc	a0,0x6
    80001f26:	37e50513          	addi	a0,a0,894 # 800082a0 <digits+0x260>
    80001f2a:	ffffe097          	auipc	ra,0xffffe
    80001f2e:	614080e7          	jalr	1556(ra) # 8000053e <panic>

0000000080001f32 <remove_first>:



struct proc* 
remove_first(int type, int cpu_id)
{
    80001f32:	7179                	addi	sp,sp,-48
    80001f34:	f406                	sd	ra,40(sp)
    80001f36:	f022                	sd	s0,32(sp)
    80001f38:	ec26                	sd	s1,24(sp)
    80001f3a:	e84a                	sd	s2,16(sp)
    80001f3c:	e44e                	sd	s3,8(sp)
    80001f3e:	e052                	sd	s4,0(sp)
    80001f40:	1800                	addi	s0,sp,48
    80001f42:	892a                	mv	s2,a0
    80001f44:	89ae                	mv	s3,a1
  acquire_list(type, cpu_id);//acquire lock
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	c8e080e7          	jalr	-882(ra) # 80001bd4 <acquire_list>
  struct proc* head = get_head(type, cpu_id);//aquire list after we have loock 
    80001f4e:	85ce                	mv	a1,s3
    80001f50:	854a                	mv	a0,s2
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	d0a080e7          	jalr	-758(ra) # 80001c5c <get_head>
    80001f5a:	84aa                	mv	s1,a0
  if(!head){
    80001f5c:	c529                	beqz	a0,80001fa6 <remove_first+0x74>
    release_list(type, cpu_id);//realese loock 
  }
  else{
    acquire(&head->list_lock);
    80001f5e:	01850a13          	addi	s4,a0,24
    80001f62:	8552                	mv	a0,s4
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	c88080e7          	jalr	-888(ra) # 80000bec <acquire>

    set_head(head->next, type, cpu_id);
    80001f6c:	864e                	mv	a2,s3
    80001f6e:	85ca                	mv	a1,s2
    80001f70:	68a8                	ld	a0,80(s1)
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	d50080e7          	jalr	-688(ra) # 80001cc2 <set_head>
    head->next = 0;
    80001f7a:	0404b823          	sd	zero,80(s1)
    release(&head->list_lock);
    80001f7e:	8552                	mv	a0,s4
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	d26080e7          	jalr	-730(ra) # 80000ca6 <release>

    release_list(type, cpu_id);//realese loock 
    80001f88:	85ce                	mv	a1,s3
    80001f8a:	854a                	mv	a0,s2
    80001f8c:	00000097          	auipc	ra,0x0
    80001f90:	e24080e7          	jalr	-476(ra) # 80001db0 <release_list>

  }
  return head;
}
    80001f94:	8526                	mv	a0,s1
    80001f96:	70a2                	ld	ra,40(sp)
    80001f98:	7402                	ld	s0,32(sp)
    80001f9a:	64e2                	ld	s1,24(sp)
    80001f9c:	6942                	ld	s2,16(sp)
    80001f9e:	69a2                	ld	s3,8(sp)
    80001fa0:	6a02                	ld	s4,0(sp)
    80001fa2:	6145                	addi	sp,sp,48
    80001fa4:	8082                	ret
    release_list(type, cpu_id);//realese loock 
    80001fa6:	85ce                	mv	a1,s3
    80001fa8:	854a                	mv	a0,s2
    80001faa:	00000097          	auipc	ra,0x0
    80001fae:	e06080e7          	jalr	-506(ra) # 80001db0 <release_list>
    80001fb2:	b7cd                	j	80001f94 <remove_first+0x62>

0000000080001fb4 <remove_proc>:

int
remove_proc(struct proc* p, int type){
    80001fb4:	7179                	addi	sp,sp,-48
    80001fb6:	f406                	sd	ra,40(sp)
    80001fb8:	f022                	sd	s0,32(sp)
    80001fba:	ec26                	sd	s1,24(sp)
    80001fbc:	e84a                	sd	s2,16(sp)
    80001fbe:	e44e                	sd	s3,8(sp)
    80001fc0:	e052                	sd	s4,0(sp)
    80001fc2:	1800                	addi	s0,sp,48
    80001fc4:	8a2a                	mv	s4,a0
    80001fc6:	84ae                	mv	s1,a1
  acquire_list(type, p->parent_cpu);
    80001fc8:	4d2c                	lw	a1,88(a0)
    80001fca:	8526                	mv	a0,s1
    80001fcc:	00000097          	auipc	ra,0x0
    80001fd0:	c08080e7          	jalr	-1016(ra) # 80001bd4 <acquire_list>
  struct proc* head = get_head(type, p->parent_cpu);
    80001fd4:	058a2983          	lw	s3,88(s4) # fffffffffffff058 <end+0xffffffff7ffd9058>
    80001fd8:	85ce                	mv	a1,s3
    80001fda:	8526                	mv	a0,s1
    80001fdc:	00000097          	auipc	ra,0x0
    80001fe0:	c80080e7          	jalr	-896(ra) # 80001c5c <get_head>
  if(!head){
    80001fe4:	c521                	beqz	a0,8000202c <remove_proc+0x78>
    80001fe6:	892a                	mv	s2,a0
    release_list(type, p->parent_cpu);
    return 0;
  }
  else{
    struct proc* prev = 0;
    if(p == head){
    80001fe8:	04aa0a63          	beq	s4,a0,8000203c <remove_proc+0x88>
      release(&p->list_lock);
      release_list(type, p->parent_cpu);
    }
    else{
      while(head){
        acquire(&head->list_lock);
    80001fec:	0561                	addi	a0,a0,24
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	bfe080e7          	jalr	-1026(ra) # 80000bec <acquire>
          release(&prev->list_lock);
          return 1;
        }

        if(!prev)
          release_list(type,p->parent_cpu);
    80001ff6:	058a2583          	lw	a1,88(s4)
    80001ffa:	8526                	mv	a0,s1
    80001ffc:	00000097          	auipc	ra,0x0
    80002000:	db4080e7          	jalr	-588(ra) # 80001db0 <release_list>
          release(&prev->list_lock);
        }
          
        
        prev = head;
        head = head->next;
    80002004:	05093483          	ld	s1,80(s2)
      while(head){
    80002008:	c0dd                	beqz	s1,800020ae <remove_proc+0xfa>
        acquire(&head->list_lock);
    8000200a:	01848993          	addi	s3,s1,24
    8000200e:	854e                	mv	a0,s3
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	bdc080e7          	jalr	-1060(ra) # 80000bec <acquire>
        if(p == head){
    80002018:	069a0263          	beq	s4,s1,8000207c <remove_proc+0xc8>
          release(&prev->list_lock);
    8000201c:	01890513          	addi	a0,s2,24
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	c86080e7          	jalr	-890(ra) # 80000ca6 <release>
        head = head->next;
    80002028:	8926                	mv	s2,s1
    8000202a:	bfe9                	j	80002004 <remove_proc+0x50>
    release_list(type, p->parent_cpu);
    8000202c:	85ce                	mv	a1,s3
    8000202e:	8526                	mv	a0,s1
    80002030:	00000097          	auipc	ra,0x0
    80002034:	d80080e7          	jalr	-640(ra) # 80001db0 <release_list>
    return 0;
    80002038:	4501                	li	a0,0
    8000203a:	a095                	j	8000209e <remove_proc+0xea>
      acquire(&p->list_lock);
    8000203c:	01850993          	addi	s3,a0,24
    80002040:	854e                	mv	a0,s3
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	baa080e7          	jalr	-1110(ra) # 80000bec <acquire>
      set_head(p->next, type, p->parent_cpu);
    8000204a:	05892603          	lw	a2,88(s2)
    8000204e:	85a6                	mv	a1,s1
    80002050:	05093503          	ld	a0,80(s2)
    80002054:	00000097          	auipc	ra,0x0
    80002058:	c6e080e7          	jalr	-914(ra) # 80001cc2 <set_head>
      p->next = 0;
    8000205c:	04093823          	sd	zero,80(s2)
      release(&p->list_lock);
    80002060:	854e                	mv	a0,s3
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	c44080e7          	jalr	-956(ra) # 80000ca6 <release>
      release_list(type, p->parent_cpu);
    8000206a:	05892583          	lw	a1,88(s2)
    8000206e:	8526                	mv	a0,s1
    80002070:	00000097          	auipc	ra,0x0
    80002074:	d40080e7          	jalr	-704(ra) # 80001db0 <release_list>
      }
    }
    return 0;
    80002078:	4501                	li	a0,0
    8000207a:	a015                	j	8000209e <remove_proc+0xea>
          prev->next = head->next;
    8000207c:	68bc                	ld	a5,80(s1)
    8000207e:	04f93823          	sd	a5,80(s2)
          p->next = 0;
    80002082:	0404b823          	sd	zero,80(s1)
          release(&head->list_lock);
    80002086:	854e                	mv	a0,s3
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	c1e080e7          	jalr	-994(ra) # 80000ca6 <release>
          release(&prev->list_lock);
    80002090:	01890513          	addi	a0,s2,24
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	c12080e7          	jalr	-1006(ra) # 80000ca6 <release>
          return 1;
    8000209c:	4505                	li	a0,1
  }
}
    8000209e:	70a2                	ld	ra,40(sp)
    800020a0:	7402                	ld	s0,32(sp)
    800020a2:	64e2                	ld	s1,24(sp)
    800020a4:	6942                	ld	s2,16(sp)
    800020a6:	69a2                	ld	s3,8(sp)
    800020a8:	6a02                	ld	s4,0(sp)
    800020aa:	6145                	addi	sp,sp,48
    800020ac:	8082                	ret
    return 0;
    800020ae:	4501                	li	a0,0
    800020b0:	b7fd                	j	8000209e <remove_proc+0xea>

00000000800020b2 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800020b2:	7139                	addi	sp,sp,-64
    800020b4:	fc06                	sd	ra,56(sp)
    800020b6:	f822                	sd	s0,48(sp)
    800020b8:	f426                	sd	s1,40(sp)
    800020ba:	f04a                	sd	s2,32(sp)
    800020bc:	ec4e                	sd	s3,24(sp)
    800020be:	e852                	sd	s4,16(sp)
    800020c0:	e456                	sd	s5,8(sp)
    800020c2:	e05a                	sd	s6,0(sp)
    800020c4:	0080                	addi	s0,sp,64
    800020c6:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800020c8:	0000f497          	auipc	s1,0xf
    800020cc:	51848493          	addi	s1,s1,1304 # 800115e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800020d0:	8b26                	mv	s6,s1
    800020d2:	00006a97          	auipc	s5,0x6
    800020d6:	f2ea8a93          	addi	s5,s5,-210 # 80008000 <etext>
    800020da:	04000937          	lui	s2,0x4000
    800020de:	197d                	addi	s2,s2,-1
    800020e0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800020e2:	00016a17          	auipc	s4,0x16
    800020e6:	8fea0a13          	addi	s4,s4,-1794 # 800179e0 <tickslock>
    char *pa = kalloc();
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	a0a080e7          	jalr	-1526(ra) # 80000af4 <kalloc>
    800020f2:	862a                	mv	a2,a0
    if(pa == 0)
    800020f4:	c131                	beqz	a0,80002138 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800020f6:	416485b3          	sub	a1,s1,s6
    800020fa:	8591                	srai	a1,a1,0x4
    800020fc:	000ab783          	ld	a5,0(s5)
    80002100:	02f585b3          	mul	a1,a1,a5
    80002104:	2585                	addiw	a1,a1,1
    80002106:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000210a:	4719                	li	a4,6
    8000210c:	6685                	lui	a3,0x1
    8000210e:	40b905b3          	sub	a1,s2,a1
    80002112:	854e                	mv	a0,s3
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	04a080e7          	jalr	74(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000211c:	19048493          	addi	s1,s1,400
    80002120:	fd4495e3          	bne	s1,s4,800020ea <proc_mapstacks+0x38>
  }
}
    80002124:	70e2                	ld	ra,56(sp)
    80002126:	7442                	ld	s0,48(sp)
    80002128:	74a2                	ld	s1,40(sp)
    8000212a:	7902                	ld	s2,32(sp)
    8000212c:	69e2                	ld	s3,24(sp)
    8000212e:	6a42                	ld	s4,16(sp)
    80002130:	6aa2                	ld	s5,8(sp)
    80002132:	6b02                	ld	s6,0(sp)
    80002134:	6121                	addi	sp,sp,64
    80002136:	8082                	ret
      panic("kalloc");
    80002138:	00006517          	auipc	a0,0x6
    8000213c:	18050513          	addi	a0,a0,384 # 800082b8 <digits+0x278>
    80002140:	ffffe097          	auipc	ra,0xffffe
    80002144:	3fe080e7          	jalr	1022(ra) # 8000053e <panic>

0000000080002148 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80002148:	715d                	addi	sp,sp,-80
    8000214a:	e486                	sd	ra,72(sp)
    8000214c:	e0a2                	sd	s0,64(sp)
    8000214e:	fc26                	sd	s1,56(sp)
    80002150:	f84a                	sd	s2,48(sp)
    80002152:	f44e                	sd	s3,40(sp)
    80002154:	f052                	sd	s4,32(sp)
    80002156:	ec56                	sd	s5,24(sp)
    80002158:	e85a                	sd	s6,16(sp)
    8000215a:	e45e                	sd	s7,8(sp)
    8000215c:	e062                	sd	s8,0(sp)
    8000215e:	0880                	addi	s0,sp,80
  struct proc *p;
  //----------------------------------------------------------
  if(CPUS > NCPU){
    panic("recieved more CPUS than what is allowed");
  }
  initlock(&pid_lock, "nextpid");
    80002160:	00006597          	auipc	a1,0x6
    80002164:	16058593          	addi	a1,a1,352 # 800082c0 <digits+0x280>
    80002168:	0000f517          	auipc	a0,0xf
    8000216c:	44850513          	addi	a0,a0,1096 # 800115b0 <pid_lock>
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	9e4080e7          	jalr	-1564(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80002178:	00006597          	auipc	a1,0x6
    8000217c:	15058593          	addi	a1,a1,336 # 800082c8 <digits+0x288>
    80002180:	0000f517          	auipc	a0,0xf
    80002184:	44850513          	addi	a0,a0,1096 # 800115c8 <wait_lock>
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	9cc080e7          	jalr	-1588(ra) # 80000b54 <initlock>
  initlock(&zombie_lock, "zombie lock");
    80002190:	00006597          	auipc	a1,0x6
    80002194:	14858593          	addi	a1,a1,328 # 800082d8 <digits+0x298>
    80002198:	0000f517          	auipc	a0,0xf
    8000219c:	3d050513          	addi	a0,a0,976 # 80011568 <zombie_lock>
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	9b4080e7          	jalr	-1612(ra) # 80000b54 <initlock>
  initlock(&sleeping_lock, "sleeping lock");
    800021a8:	00006597          	auipc	a1,0x6
    800021ac:	14058593          	addi	a1,a1,320 # 800082e8 <digits+0x2a8>
    800021b0:	0000f517          	auipc	a0,0xf
    800021b4:	3d050513          	addi	a0,a0,976 # 80011580 <sleeping_lock>
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	99c080e7          	jalr	-1636(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused lock");
    800021c0:	00006597          	auipc	a1,0x6
    800021c4:	13858593          	addi	a1,a1,312 # 800082f8 <digits+0x2b8>
    800021c8:	0000f517          	auipc	a0,0xf
    800021cc:	3d050513          	addi	a0,a0,976 # 80011598 <unused_lock>
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	984080e7          	jalr	-1660(ra) # 80000b54 <initlock>

  struct spinlock* s;
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    800021d8:	0000f497          	auipc	s1,0xf
    800021dc:	34848493          	addi	s1,s1,840 # 80011520 <ready_lock>
    initlock(s, "ready lock");
    800021e0:	00006997          	auipc	s3,0x6
    800021e4:	12898993          	addi	s3,s3,296 # 80008308 <digits+0x2c8>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    800021e8:	0000f917          	auipc	s2,0xf
    800021ec:	38090913          	addi	s2,s2,896 # 80011568 <zombie_lock>
    initlock(s, "ready lock");
    800021f0:	85ce                	mv	a1,s3
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	960080e7          	jalr	-1696(ra) # 80000b54 <initlock>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    800021fc:	04e1                	addi	s1,s1,24
    800021fe:	ff2499e3          	bne	s1,s2,800021f0 <procinit+0xa8>
  }
  //--------------------------------------------------
  for(p = proc; p < &proc[NPROC]; p++) {
    80002202:	0000f497          	auipc	s1,0xf
    80002206:	3de48493          	addi	s1,s1,990 # 800115e0 <proc>
      initlock(&p->lock, "proc");
    8000220a:	00006c17          	auipc	s8,0x6
    8000220e:	10ec0c13          	addi	s8,s8,270 # 80008318 <digits+0x2d8>
      //--------------------------------------------------
      initlock(&p->list_lock, "list lock");
    80002212:	00006b97          	auipc	s7,0x6
    80002216:	10eb8b93          	addi	s7,s7,270 # 80008320 <digits+0x2e0>
      //--------------------------------------------------
      p->kstack = KSTACK((int) (p - proc));
    8000221a:	8b26                	mv	s6,s1
    8000221c:	00006a97          	auipc	s5,0x6
    80002220:	de4a8a93          	addi	s5,s5,-540 # 80008000 <etext>
    80002224:	04000937          	lui	s2,0x4000
    80002228:	197d                	addi	s2,s2,-1
    8000222a:	0932                	slli	s2,s2,0xc
      //--------------------------------------------------
       p->parent_cpu = -1;
    8000222c:	5a7d                	li	s4,-1
  for(p = proc; p < &proc[NPROC]; p++) {
    8000222e:	00015997          	auipc	s3,0x15
    80002232:	7b298993          	addi	s3,s3,1970 # 800179e0 <tickslock>
      initlock(&p->lock, "proc");
    80002236:	85e2                	mv	a1,s8
    80002238:	8526                	mv	a0,s1
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	91a080e7          	jalr	-1766(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list lock");
    80002242:	85de                	mv	a1,s7
    80002244:	01848513          	addi	a0,s1,24
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	90c080e7          	jalr	-1780(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80002250:	416487b3          	sub	a5,s1,s6
    80002254:	8791                	srai	a5,a5,0x4
    80002256:	000ab703          	ld	a4,0(s5)
    8000225a:	02e787b3          	mul	a5,a5,a4
    8000225e:	2785                	addiw	a5,a5,1
    80002260:	00d7979b          	slliw	a5,a5,0xd
    80002264:	40f907b3          	sub	a5,s2,a5
    80002268:	f4bc                	sd	a5,104(s1)
       p->parent_cpu = -1;
    8000226a:	0544ac23          	sw	s4,88(s1)
       add_proc_to_list(p, UNUSEDL, -1);
    8000226e:	567d                	li	a2,-1
    80002270:	458d                	li	a1,3
    80002272:	8526                	mv	a0,s1
    80002274:	00000097          	auipc	ra,0x0
    80002278:	c62080e7          	jalr	-926(ra) # 80001ed6 <add_proc_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000227c:	19048493          	addi	s1,s1,400
    80002280:	fb349be3          	bne	s1,s3,80002236 <procinit+0xee>
      
      //--------------------------------------------------
  }
}
    80002284:	60a6                	ld	ra,72(sp)
    80002286:	6406                	ld	s0,64(sp)
    80002288:	74e2                	ld	s1,56(sp)
    8000228a:	7942                	ld	s2,48(sp)
    8000228c:	79a2                	ld	s3,40(sp)
    8000228e:	7a02                	ld	s4,32(sp)
    80002290:	6ae2                	ld	s5,24(sp)
    80002292:	6b42                	ld	s6,16(sp)
    80002294:	6ba2                	ld	s7,8(sp)
    80002296:	6c02                	ld	s8,0(sp)
    80002298:	6161                	addi	sp,sp,80
    8000229a:	8082                	ret

000000008000229c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000229c:	1141                	addi	sp,sp,-16
    8000229e:	e422                	sd	s0,8(sp)
    800022a0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800022a2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800022a4:	2501                	sext.w	a0,a0
    800022a6:	6422                	ld	s0,8(sp)
    800022a8:	0141                	addi	sp,sp,16
    800022aa:	8082                	ret

00000000800022ac <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800022ac:	1141                	addi	sp,sp,-16
    800022ae:	e422                	sd	s0,8(sp)
    800022b0:	0800                	addi	s0,sp,16
    800022b2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800022b4:	0007851b          	sext.w	a0,a5
    800022b8:	00351793          	slli	a5,a0,0x3
    800022bc:	97aa                	add	a5,a5,a0
    800022be:	0792                	slli	a5,a5,0x4
  return c;
}
    800022c0:	0000f517          	auipc	a0,0xf
    800022c4:	0b050513          	addi	a0,a0,176 # 80011370 <cpus>
    800022c8:	953e                	add	a0,a0,a5
    800022ca:	6422                	ld	s0,8(sp)
    800022cc:	0141                	addi	sp,sp,16
    800022ce:	8082                	ret

00000000800022d0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
  push_off();
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	8be080e7          	jalr	-1858(ra) # 80000b98 <push_off>
    800022e2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800022e4:	0007871b          	sext.w	a4,a5
    800022e8:	00371793          	slli	a5,a4,0x3
    800022ec:	97ba                	add	a5,a5,a4
    800022ee:	0792                	slli	a5,a5,0x4
    800022f0:	0000f717          	auipc	a4,0xf
    800022f4:	ff070713          	addi	a4,a4,-16 # 800112e0 <readyLock>
    800022f8:	97ba                	add	a5,a5,a4
    800022fa:	6fc4                	ld	s1,152(a5)
  pop_off();
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	944080e7          	jalr	-1724(ra) # 80000c40 <pop_off>
  return p;
}
    80002304:	8526                	mv	a0,s1
    80002306:	60e2                	ld	ra,24(sp)
    80002308:	6442                	ld	s0,16(sp)
    8000230a:	64a2                	ld	s1,8(sp)
    8000230c:	6105                	addi	sp,sp,32
    8000230e:	8082                	ret

0000000080002310 <get_cpu>:
{
    80002310:	1141                	addi	sp,sp,-16
    80002312:	e406                	sd	ra,8(sp)
    80002314:	e022                	sd	s0,0(sp)
    80002316:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    80002318:	00000097          	auipc	ra,0x0
    8000231c:	fb8080e7          	jalr	-72(ra) # 800022d0 <myproc>
}
    80002320:	4d28                	lw	a0,88(a0)
    80002322:	60a2                	ld	ra,8(sp)
    80002324:	6402                	ld	s0,0(sp)
    80002326:	0141                	addi	sp,sp,16
    80002328:	8082                	ret

000000008000232a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    8000232a:	1141                	addi	sp,sp,-16
    8000232c:	e406                	sd	ra,8(sp)
    8000232e:	e022                	sd	s0,0(sp)
    80002330:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80002332:	00000097          	auipc	ra,0x0
    80002336:	f9e080e7          	jalr	-98(ra) # 800022d0 <myproc>
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	96c080e7          	jalr	-1684(ra) # 80000ca6 <release>

  if (first) {
    80002342:	00006797          	auipc	a5,0x6
    80002346:	63e7a783          	lw	a5,1598(a5) # 80008980 <first.1866>
    8000234a:	eb89                	bnez	a5,8000235c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    8000234c:	00001097          	auipc	ra,0x1
    80002350:	f5a080e7          	jalr	-166(ra) # 800032a6 <usertrapret>
}
    80002354:	60a2                	ld	ra,8(sp)
    80002356:	6402                	ld	s0,0(sp)
    80002358:	0141                	addi	sp,sp,16
    8000235a:	8082                	ret
    first = 0;
    8000235c:	00006797          	auipc	a5,0x6
    80002360:	6207a223          	sw	zero,1572(a5) # 80008980 <first.1866>
    fsinit(ROOTDEV);
    80002364:	4505                	li	a0,1
    80002366:	00002097          	auipc	ra,0x2
    8000236a:	ccc080e7          	jalr	-820(ra) # 80004032 <fsinit>
    8000236e:	bff9                	j	8000234c <forkret+0x22>

0000000080002370 <allocpid>:
allocpid() {
    80002370:	1101                	addi	sp,sp,-32
    80002372:	ec06                	sd	ra,24(sp)
    80002374:	e822                	sd	s0,16(sp)
    80002376:	e426                	sd	s1,8(sp)
    80002378:	e04a                	sd	s2,0(sp)
    8000237a:	1000                	addi	s0,sp,32
    pid = nextpid;
    8000237c:	00006917          	auipc	s2,0x6
    80002380:	60890913          	addi	s2,s2,1544 # 80008984 <nextpid>
    80002384:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid, pid, pid + 1));
    80002388:	0014861b          	addiw	a2,s1,1
    8000238c:	85a6                	mv	a1,s1
    8000238e:	854a                	mv	a0,s2
    80002390:	00005097          	auipc	ra,0x5
    80002394:	aa6080e7          	jalr	-1370(ra) # 80006e36 <cas>
    80002398:	f575                	bnez	a0,80002384 <allocpid+0x14>
}
    8000239a:	8526                	mv	a0,s1
    8000239c:	60e2                	ld	ra,24(sp)
    8000239e:	6442                	ld	s0,16(sp)
    800023a0:	64a2                	ld	s1,8(sp)
    800023a2:	6902                	ld	s2,0(sp)
    800023a4:	6105                	addi	sp,sp,32
    800023a6:	8082                	ret

00000000800023a8 <proc_pagetable>:
{
    800023a8:	1101                	addi	sp,sp,-32
    800023aa:	ec06                	sd	ra,24(sp)
    800023ac:	e822                	sd	s0,16(sp)
    800023ae:	e426                	sd	s1,8(sp)
    800023b0:	e04a                	sd	s2,0(sp)
    800023b2:	1000                	addi	s0,sp,32
    800023b4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	f92080e7          	jalr	-110(ra) # 80001348 <uvmcreate>
    800023be:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800023c0:	c121                	beqz	a0,80002400 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800023c2:	4729                	li	a4,10
    800023c4:	00005697          	auipc	a3,0x5
    800023c8:	c3c68693          	addi	a3,a3,-964 # 80007000 <_trampoline>
    800023cc:	6605                	lui	a2,0x1
    800023ce:	040005b7          	lui	a1,0x4000
    800023d2:	15fd                	addi	a1,a1,-1
    800023d4:	05b2                	slli	a1,a1,0xc
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	ce8080e7          	jalr	-792(ra) # 800010be <mappages>
    800023de:	02054863          	bltz	a0,8000240e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800023e2:	4719                	li	a4,6
    800023e4:	08093683          	ld	a3,128(s2)
    800023e8:	6605                	lui	a2,0x1
    800023ea:	020005b7          	lui	a1,0x2000
    800023ee:	15fd                	addi	a1,a1,-1
    800023f0:	05b6                	slli	a1,a1,0xd
    800023f2:	8526                	mv	a0,s1
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	cca080e7          	jalr	-822(ra) # 800010be <mappages>
    800023fc:	02054163          	bltz	a0,8000241e <proc_pagetable+0x76>
}
    80002400:	8526                	mv	a0,s1
    80002402:	60e2                	ld	ra,24(sp)
    80002404:	6442                	ld	s0,16(sp)
    80002406:	64a2                	ld	s1,8(sp)
    80002408:	6902                	ld	s2,0(sp)
    8000240a:	6105                	addi	sp,sp,32
    8000240c:	8082                	ret
    uvmfree(pagetable, 0);
    8000240e:	4581                	li	a1,0
    80002410:	8526                	mv	a0,s1
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	132080e7          	jalr	306(ra) # 80001544 <uvmfree>
    return 0;
    8000241a:	4481                	li	s1,0
    8000241c:	b7d5                	j	80002400 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000241e:	4681                	li	a3,0
    80002420:	4605                	li	a2,1
    80002422:	040005b7          	lui	a1,0x4000
    80002426:	15fd                	addi	a1,a1,-1
    80002428:	05b2                	slli	a1,a1,0xc
    8000242a:	8526                	mv	a0,s1
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	e58080e7          	jalr	-424(ra) # 80001284 <uvmunmap>
    uvmfree(pagetable, 0);
    80002434:	4581                	li	a1,0
    80002436:	8526                	mv	a0,s1
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	10c080e7          	jalr	268(ra) # 80001544 <uvmfree>
    return 0;
    80002440:	4481                	li	s1,0
    80002442:	bf7d                	j	80002400 <proc_pagetable+0x58>

0000000080002444 <proc_freepagetable>:
{
    80002444:	1101                	addi	sp,sp,-32
    80002446:	ec06                	sd	ra,24(sp)
    80002448:	e822                	sd	s0,16(sp)
    8000244a:	e426                	sd	s1,8(sp)
    8000244c:	e04a                	sd	s2,0(sp)
    8000244e:	1000                	addi	s0,sp,32
    80002450:	84aa                	mv	s1,a0
    80002452:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002454:	4681                	li	a3,0
    80002456:	4605                	li	a2,1
    80002458:	040005b7          	lui	a1,0x4000
    8000245c:	15fd                	addi	a1,a1,-1
    8000245e:	05b2                	slli	a1,a1,0xc
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	e24080e7          	jalr	-476(ra) # 80001284 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002468:	4681                	li	a3,0
    8000246a:	4605                	li	a2,1
    8000246c:	020005b7          	lui	a1,0x2000
    80002470:	15fd                	addi	a1,a1,-1
    80002472:	05b6                	slli	a1,a1,0xd
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	e0e080e7          	jalr	-498(ra) # 80001284 <uvmunmap>
  uvmfree(pagetable, sz);
    8000247e:	85ca                	mv	a1,s2
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	0c2080e7          	jalr	194(ra) # 80001544 <uvmfree>
}
    8000248a:	60e2                	ld	ra,24(sp)
    8000248c:	6442                	ld	s0,16(sp)
    8000248e:	64a2                	ld	s1,8(sp)
    80002490:	6902                	ld	s2,0(sp)
    80002492:	6105                	addi	sp,sp,32
    80002494:	8082                	ret

0000000080002496 <freeproc>:
{
    80002496:	1101                	addi	sp,sp,-32
    80002498:	ec06                	sd	ra,24(sp)
    8000249a:	e822                	sd	s0,16(sp)
    8000249c:	e426                	sd	s1,8(sp)
    8000249e:	1000                	addi	s0,sp,32
    800024a0:	84aa                	mv	s1,a0
  if(p->trapframe)
    800024a2:	6148                	ld	a0,128(a0)
    800024a4:	c509                	beqz	a0,800024ae <freeproc+0x18>
    kfree((void*)p->trapframe);
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	552080e7          	jalr	1362(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    800024ae:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    800024b2:	7ca8                	ld	a0,120(s1)
    800024b4:	c511                	beqz	a0,800024c0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800024b6:	78ac                	ld	a1,112(s1)
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	f8c080e7          	jalr	-116(ra) # 80002444 <proc_freepagetable>
  p->pagetable = 0;
    800024c0:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    800024c4:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    800024c8:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    800024cc:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    800024d0:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    800024d4:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    800024d8:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    800024dc:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    800024e0:	0204a823          	sw	zero,48(s1)
  remove_proc(p, ZOMBIEL);
    800024e4:	4585                	li	a1,1
    800024e6:	8526                	mv	a0,s1
    800024e8:	00000097          	auipc	ra,0x0
    800024ec:	acc080e7          	jalr	-1332(ra) # 80001fb4 <remove_proc>
  add_proc_to_list(p, UNUSEDL, -1);
    800024f0:	567d                	li	a2,-1
    800024f2:	458d                	li	a1,3
    800024f4:	8526                	mv	a0,s1
    800024f6:	00000097          	auipc	ra,0x0
    800024fa:	9e0080e7          	jalr	-1568(ra) # 80001ed6 <add_proc_to_list>
}
    800024fe:	60e2                	ld	ra,24(sp)
    80002500:	6442                	ld	s0,16(sp)
    80002502:	64a2                	ld	s1,8(sp)
    80002504:	6105                	addi	sp,sp,32
    80002506:	8082                	ret

0000000080002508 <allocproc>:
{
    80002508:	7179                	addi	sp,sp,-48
    8000250a:	f406                	sd	ra,40(sp)
    8000250c:	f022                	sd	s0,32(sp)
    8000250e:	ec26                	sd	s1,24(sp)
    80002510:	e84a                	sd	s2,16(sp)
    80002512:	e44e                	sd	s3,8(sp)
    80002514:	1800                	addi	s0,sp,48
  p = remove_first(UNUSEDL, -1);
    80002516:	55fd                	li	a1,-1
    80002518:	450d                	li	a0,3
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	a18080e7          	jalr	-1512(ra) # 80001f32 <remove_first>
    80002522:	84aa                	mv	s1,a0
  if(!p){
    80002524:	cd39                	beqz	a0,80002582 <allocproc+0x7a>
  acquire(&p->lock);
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	6c6080e7          	jalr	1734(ra) # 80000bec <acquire>
  p->pid = allocpid();
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	e42080e7          	jalr	-446(ra) # 80002370 <allocpid>
    80002536:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80002538:	4785                	li	a5,1
    8000253a:	d89c                	sw	a5,48(s1)
  p->next = 0;
    8000253c:	0404b823          	sd	zero,80(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	5b4080e7          	jalr	1460(ra) # 80000af4 <kalloc>
    80002548:	892a                	mv	s2,a0
    8000254a:	e0c8                	sd	a0,128(s1)
    8000254c:	c139                	beqz	a0,80002592 <allocproc+0x8a>
  p->pagetable = proc_pagetable(p);
    8000254e:	8526                	mv	a0,s1
    80002550:	00000097          	auipc	ra,0x0
    80002554:	e58080e7          	jalr	-424(ra) # 800023a8 <proc_pagetable>
    80002558:	892a                	mv	s2,a0
    8000255a:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    8000255c:	c539                	beqz	a0,800025aa <allocproc+0xa2>
  memset(&p->context, 0, sizeof(p->context));
    8000255e:	07000613          	li	a2,112
    80002562:	4581                	li	a1,0
    80002564:	08848513          	addi	a0,s1,136
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	786080e7          	jalr	1926(ra) # 80000cee <memset>
  p->context.ra = (uint64)forkret;
    80002570:	00000797          	auipc	a5,0x0
    80002574:	dba78793          	addi	a5,a5,-582 # 8000232a <forkret>
    80002578:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    8000257a:	74bc                	ld	a5,104(s1)
    8000257c:	6705                	lui	a4,0x1
    8000257e:	97ba                	add	a5,a5,a4
    80002580:	e8dc                	sd	a5,144(s1)
}
    80002582:	8526                	mv	a0,s1
    80002584:	70a2                	ld	ra,40(sp)
    80002586:	7402                	ld	s0,32(sp)
    80002588:	64e2                	ld	s1,24(sp)
    8000258a:	6942                	ld	s2,16(sp)
    8000258c:	69a2                	ld	s3,8(sp)
    8000258e:	6145                	addi	sp,sp,48
    80002590:	8082                	ret
    freeproc(p);
    80002592:	8526                	mv	a0,s1
    80002594:	00000097          	auipc	ra,0x0
    80002598:	f02080e7          	jalr	-254(ra) # 80002496 <freeproc>
    release(&p->lock);
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	708080e7          	jalr	1800(ra) # 80000ca6 <release>
    return 0;
    800025a6:	84ca                	mv	s1,s2
    800025a8:	bfe9                	j	80002582 <allocproc+0x7a>
    freeproc(p);
    800025aa:	8526                	mv	a0,s1
    800025ac:	00000097          	auipc	ra,0x0
    800025b0:	eea080e7          	jalr	-278(ra) # 80002496 <freeproc>
    release(&p->lock);
    800025b4:	8526                	mv	a0,s1
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	6f0080e7          	jalr	1776(ra) # 80000ca6 <release>
    return 0;
    800025be:	84ca                	mv	s1,s2
    800025c0:	b7c9                	j	80002582 <allocproc+0x7a>

00000000800025c2 <userinit>:
{
    800025c2:	1101                	addi	sp,sp,-32
    800025c4:	ec06                	sd	ra,24(sp)
    800025c6:	e822                	sd	s0,16(sp)
    800025c8:	e426                	sd	s1,8(sp)
    800025ca:	1000                	addi	s0,sp,32
  if(!init){
    800025cc:	00007797          	auipc	a5,0x7
    800025d0:	a747a783          	lw	a5,-1420(a5) # 80009040 <init>
    800025d4:	e795                	bnez	a5,80002600 <userinit+0x3e>
      c->first = 0;
    800025d6:	0000f797          	auipc	a5,0xf
    800025da:	d0a78793          	addi	a5,a5,-758 # 800112e0 <readyLock>
    800025de:	1007bc23          	sd	zero,280(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    800025e2:	0807b823          	sd	zero,144(a5)
      c->first = 0;
    800025e6:	1a07b423          	sd	zero,424(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    800025ea:	1207b023          	sd	zero,288(a5)
      c->first = 0;
    800025ee:	2207bc23          	sd	zero,568(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    800025f2:	1a07b823          	sd	zero,432(a5)
    init = 1;
    800025f6:	4785                	li	a5,1
    800025f8:	00007717          	auipc	a4,0x7
    800025fc:	a4f72423          	sw	a5,-1464(a4) # 80009040 <init>
  p = allocproc();
    80002600:	00000097          	auipc	ra,0x0
    80002604:	f08080e7          	jalr	-248(ra) # 80002508 <allocproc>
    80002608:	84aa                	mv	s1,a0
  initproc = p;
    8000260a:	00007797          	auipc	a5,0x7
    8000260e:	a4a7bb23          	sd	a0,-1450(a5) # 80009060 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002612:	03400613          	li	a2,52
    80002616:	00006597          	auipc	a1,0x6
    8000261a:	37a58593          	addi	a1,a1,890 # 80008990 <initcode>
    8000261e:	7d28                	ld	a0,120(a0)
    80002620:	fffff097          	auipc	ra,0xfffff
    80002624:	d56080e7          	jalr	-682(ra) # 80001376 <uvminit>
  p->sz = PGSIZE;
    80002628:	6785                	lui	a5,0x1
    8000262a:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    8000262c:	60d8                	ld	a4,128(s1)
    8000262e:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002632:	60d8                	ld	a4,128(s1)
    80002634:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002636:	4641                	li	a2,16
    80002638:	00006597          	auipc	a1,0x6
    8000263c:	cf858593          	addi	a1,a1,-776 # 80008330 <digits+0x2f0>
    80002640:	18048513          	addi	a0,s1,384
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	7fc080e7          	jalr	2044(ra) # 80000e40 <safestrcpy>
  p->cwd = namei("/");
    8000264c:	00006517          	auipc	a0,0x6
    80002650:	cf450513          	addi	a0,a0,-780 # 80008340 <digits+0x300>
    80002654:	00002097          	auipc	ra,0x2
    80002658:	40c080e7          	jalr	1036(ra) # 80004a60 <namei>
    8000265c:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    80002660:	478d                	li	a5,3
    80002662:	d89c                	sw	a5,48(s1)
  p->parent_cpu = 0;
    80002664:	0404ac23          	sw	zero,88(s1)
  increase_size(p->parent_cpu);
    80002668:	4501                	li	a0,0
    8000266a:	fffff097          	auipc	ra,0xfffff
    8000266e:	4d6080e7          	jalr	1238(ra) # 80001b40 <increase_size>
  cpus[p->parent_cpu].first = p;
    80002672:	4cb8                	lw	a4,88(s1)
    80002674:	00371793          	slli	a5,a4,0x3
    80002678:	97ba                	add	a5,a5,a4
    8000267a:	0792                	slli	a5,a5,0x4
    8000267c:	0000f717          	auipc	a4,0xf
    80002680:	c6470713          	addi	a4,a4,-924 # 800112e0 <readyLock>
    80002684:	97ba                	add	a5,a5,a4
    80002686:	1097bc23          	sd	s1,280(a5) # 1118 <_entry-0x7fffeee8>
  release(&p->lock);
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	61a080e7          	jalr	1562(ra) # 80000ca6 <release>
}
    80002694:	60e2                	ld	ra,24(sp)
    80002696:	6442                	ld	s0,16(sp)
    80002698:	64a2                	ld	s1,8(sp)
    8000269a:	6105                	addi	sp,sp,32
    8000269c:	8082                	ret

000000008000269e <growproc>:
{
    8000269e:	1101                	addi	sp,sp,-32
    800026a0:	ec06                	sd	ra,24(sp)
    800026a2:	e822                	sd	s0,16(sp)
    800026a4:	e426                	sd	s1,8(sp)
    800026a6:	e04a                	sd	s2,0(sp)
    800026a8:	1000                	addi	s0,sp,32
    800026aa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800026ac:	00000097          	auipc	ra,0x0
    800026b0:	c24080e7          	jalr	-988(ra) # 800022d0 <myproc>
    800026b4:	892a                	mv	s2,a0
  sz = p->sz;
    800026b6:	792c                	ld	a1,112(a0)
    800026b8:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800026bc:	00904f63          	bgtz	s1,800026da <growproc+0x3c>
  } else if(n < 0){
    800026c0:	0204cc63          	bltz	s1,800026f8 <growproc+0x5a>
  p->sz = sz;
    800026c4:	1602                	slli	a2,a2,0x20
    800026c6:	9201                	srli	a2,a2,0x20
    800026c8:	06c93823          	sd	a2,112(s2)
  return 0;
    800026cc:	4501                	li	a0,0
}
    800026ce:	60e2                	ld	ra,24(sp)
    800026d0:	6442                	ld	s0,16(sp)
    800026d2:	64a2                	ld	s1,8(sp)
    800026d4:	6902                	ld	s2,0(sp)
    800026d6:	6105                	addi	sp,sp,32
    800026d8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800026da:	9e25                	addw	a2,a2,s1
    800026dc:	1602                	slli	a2,a2,0x20
    800026de:	9201                	srli	a2,a2,0x20
    800026e0:	1582                	slli	a1,a1,0x20
    800026e2:	9181                	srli	a1,a1,0x20
    800026e4:	7d28                	ld	a0,120(a0)
    800026e6:	fffff097          	auipc	ra,0xfffff
    800026ea:	d4a080e7          	jalr	-694(ra) # 80001430 <uvmalloc>
    800026ee:	0005061b          	sext.w	a2,a0
    800026f2:	fa69                	bnez	a2,800026c4 <growproc+0x26>
      return -1;
    800026f4:	557d                	li	a0,-1
    800026f6:	bfe1                	j	800026ce <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800026f8:	9e25                	addw	a2,a2,s1
    800026fa:	1602                	slli	a2,a2,0x20
    800026fc:	9201                	srli	a2,a2,0x20
    800026fe:	1582                	slli	a1,a1,0x20
    80002700:	9181                	srli	a1,a1,0x20
    80002702:	7d28                	ld	a0,120(a0)
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	ce4080e7          	jalr	-796(ra) # 800013e8 <uvmdealloc>
    8000270c:	0005061b          	sext.w	a2,a0
    80002710:	bf55                	j	800026c4 <growproc+0x26>

0000000080002712 <fork>:
{
    80002712:	7179                	addi	sp,sp,-48
    80002714:	f406                	sd	ra,40(sp)
    80002716:	f022                	sd	s0,32(sp)
    80002718:	ec26                	sd	s1,24(sp)
    8000271a:	e84a                	sd	s2,16(sp)
    8000271c:	e44e                	sd	s3,8(sp)
    8000271e:	e052                	sd	s4,0(sp)
    80002720:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002722:	00000097          	auipc	ra,0x0
    80002726:	bae080e7          	jalr	-1106(ra) # 800022d0 <myproc>
    8000272a:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    8000272c:	00000097          	auipc	ra,0x0
    80002730:	ddc080e7          	jalr	-548(ra) # 80002508 <allocproc>
    80002734:	12050863          	beqz	a0,80002864 <fork+0x152>
    80002738:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000273a:	0709b603          	ld	a2,112(s3)
    8000273e:	7d2c                	ld	a1,120(a0)
    80002740:	0789b503          	ld	a0,120(s3)
    80002744:	fffff097          	auipc	ra,0xfffff
    80002748:	e38080e7          	jalr	-456(ra) # 8000157c <uvmcopy>
    8000274c:	04054663          	bltz	a0,80002798 <fork+0x86>
  np->sz = p->sz;
    80002750:	0709b783          	ld	a5,112(s3)
    80002754:	06f93823          	sd	a5,112(s2)
  *(np->trapframe) = *(p->trapframe);
    80002758:	0809b683          	ld	a3,128(s3)
    8000275c:	87b6                	mv	a5,a3
    8000275e:	08093703          	ld	a4,128(s2)
    80002762:	12068693          	addi	a3,a3,288
    80002766:	0007b803          	ld	a6,0(a5)
    8000276a:	6788                	ld	a0,8(a5)
    8000276c:	6b8c                	ld	a1,16(a5)
    8000276e:	6f90                	ld	a2,24(a5)
    80002770:	01073023          	sd	a6,0(a4)
    80002774:	e708                	sd	a0,8(a4)
    80002776:	eb0c                	sd	a1,16(a4)
    80002778:	ef10                	sd	a2,24(a4)
    8000277a:	02078793          	addi	a5,a5,32
    8000277e:	02070713          	addi	a4,a4,32
    80002782:	fed792e3          	bne	a5,a3,80002766 <fork+0x54>
  np->trapframe->a0 = 0;
    80002786:	08093783          	ld	a5,128(s2)
    8000278a:	0607b823          	sd	zero,112(a5)
    8000278e:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80002792:	17800a13          	li	s4,376
    80002796:	a03d                	j	800027c4 <fork+0xb2>
    freeproc(np);
    80002798:	854a                	mv	a0,s2
    8000279a:	00000097          	auipc	ra,0x0
    8000279e:	cfc080e7          	jalr	-772(ra) # 80002496 <freeproc>
    release(&np->lock);
    800027a2:	854a                	mv	a0,s2
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	502080e7          	jalr	1282(ra) # 80000ca6 <release>
    return -1;
    800027ac:	5a7d                	li	s4,-1
    800027ae:	a055                	j	80002852 <fork+0x140>
      np->ofile[i] = filedup(p->ofile[i]);
    800027b0:	00003097          	auipc	ra,0x3
    800027b4:	946080e7          	jalr	-1722(ra) # 800050f6 <filedup>
    800027b8:	009907b3          	add	a5,s2,s1
    800027bc:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800027be:	04a1                	addi	s1,s1,8
    800027c0:	01448763          	beq	s1,s4,800027ce <fork+0xbc>
    if(p->ofile[i])
    800027c4:	009987b3          	add	a5,s3,s1
    800027c8:	6388                	ld	a0,0(a5)
    800027ca:	f17d                	bnez	a0,800027b0 <fork+0x9e>
    800027cc:	bfcd                	j	800027be <fork+0xac>
  np->cwd = idup(p->cwd);
    800027ce:	1789b503          	ld	a0,376(s3)
    800027d2:	00002097          	auipc	ra,0x2
    800027d6:	a9a080e7          	jalr	-1382(ra) # 8000426c <idup>
    800027da:	16a93c23          	sd	a0,376(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800027de:	4641                	li	a2,16
    800027e0:	18098593          	addi	a1,s3,384
    800027e4:	18090513          	addi	a0,s2,384
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	658080e7          	jalr	1624(ra) # 80000e40 <safestrcpy>
  pid = np->pid;
    800027f0:	04892a03          	lw	s4,72(s2)
  release(&np->lock);
    800027f4:	854a                	mv	a0,s2
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	4b0080e7          	jalr	1200(ra) # 80000ca6 <release>
  acquire(&wait_lock);
    800027fe:	0000f497          	auipc	s1,0xf
    80002802:	dca48493          	addi	s1,s1,-566 # 800115c8 <wait_lock>
    80002806:	8526                	mv	a0,s1
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	3e4080e7          	jalr	996(ra) # 80000bec <acquire>
  np->parent = p;
    80002810:	07393023          	sd	s3,96(s2)
  release(&wait_lock);
    80002814:	8526                	mv	a0,s1
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	490080e7          	jalr	1168(ra) # 80000ca6 <release>
  acquire(&np->lock);
    8000281e:	854a                	mv	a0,s2
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	3cc080e7          	jalr	972(ra) # 80000bec <acquire>
  np->state = RUNNABLE;
    80002828:	478d                	li	a5,3
    8000282a:	02f92823          	sw	a5,48(s2)
    int cpu_id = (BLNCFLG) ? get_lazy_cpu() : p->parent_cpu;
    8000282e:	fffff097          	auipc	ra,0xfffff
    80002832:	2de080e7          	jalr	734(ra) # 80001b0c <get_lazy_cpu>
    80002836:	862a                	mv	a2,a0
  np->parent_cpu = cpu_id;
    80002838:	04a92c23          	sw	a0,88(s2)
  add_proc_to_list(np, READYL, cpu_id);
    8000283c:	4581                	li	a1,0
    8000283e:	854a                	mv	a0,s2
    80002840:	fffff097          	auipc	ra,0xfffff
    80002844:	696080e7          	jalr	1686(ra) # 80001ed6 <add_proc_to_list>
  release(&np->lock);
    80002848:	854a                	mv	a0,s2
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	45c080e7          	jalr	1116(ra) # 80000ca6 <release>
}
    80002852:	8552                	mv	a0,s4
    80002854:	70a2                	ld	ra,40(sp)
    80002856:	7402                	ld	s0,32(sp)
    80002858:	64e2                	ld	s1,24(sp)
    8000285a:	6942                	ld	s2,16(sp)
    8000285c:	69a2                	ld	s3,8(sp)
    8000285e:	6a02                	ld	s4,0(sp)
    80002860:	6145                	addi	sp,sp,48
    80002862:	8082                	ret
    return -1;
    80002864:	5a7d                	li	s4,-1
    80002866:	b7f5                	j	80002852 <fork+0x140>

0000000080002868 <blncflag_on>:
{
    80002868:	7139                	addi	sp,sp,-64
    8000286a:	fc06                	sd	ra,56(sp)
    8000286c:	f822                	sd	s0,48(sp)
    8000286e:	f426                	sd	s1,40(sp)
    80002870:	f04a                	sd	s2,32(sp)
    80002872:	ec4e                	sd	s3,24(sp)
    80002874:	e852                	sd	s4,16(sp)
    80002876:	e456                	sd	s5,8(sp)
    80002878:	e05a                	sd	s6,0(sp)
    8000287a:	0080                	addi	s0,sp,64
    8000287c:	8792                	mv	a5,tp
  int id = r_tp();
    8000287e:	2781                	sext.w	a5,a5
    80002880:	8a12                	mv	s4,tp
    80002882:	2a01                	sext.w	s4,s4
  c->proc = 0;
    80002884:	00379993          	slli	s3,a5,0x3
    80002888:	00f98733          	add	a4,s3,a5
    8000288c:	00471693          	slli	a3,a4,0x4
    80002890:	0000f717          	auipc	a4,0xf
    80002894:	a5070713          	addi	a4,a4,-1456 # 800112e0 <readyLock>
    80002898:	9736                	add	a4,a4,a3
    8000289a:	08073c23          	sd	zero,152(a4)
    swtch(&c->context, &p->context);
    8000289e:	0000f717          	auipc	a4,0xf
    800028a2:	ae270713          	addi	a4,a4,-1310 # 80011380 <cpus+0x10>
    800028a6:	00e689b3          	add	s3,a3,a4
    if(p->state!=RUNNABLE)
    800028aa:	4a8d                	li	s5,3
    p->state = RUNNING;
    800028ac:	4b11                	li	s6,4
    c->proc = p;
    800028ae:	0000f917          	auipc	s2,0xf
    800028b2:	a3290913          	addi	s2,s2,-1486 # 800112e0 <readyLock>
    800028b6:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028bc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c0:	10079073          	csrw	sstatus,a5
    p = remove_first(READYL, cpu_id);
    800028c4:	85d2                	mv	a1,s4
    800028c6:	4501                	li	a0,0
    800028c8:	fffff097          	auipc	ra,0xfffff
    800028cc:	66a080e7          	jalr	1642(ra) # 80001f32 <remove_first>
    800028d0:	84aa                	mv	s1,a0
    if(!p){
    800028d2:	d17d                	beqz	a0,800028b8 <blncflag_on+0x50>
    acquire(&p->lock);
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	318080e7          	jalr	792(ra) # 80000bec <acquire>
    if(p->state!=RUNNABLE)
    800028dc:	589c                	lw	a5,48(s1)
    800028de:	03579563          	bne	a5,s5,80002908 <blncflag_on+0xa0>
    p->state = RUNNING;
    800028e2:	0364a823          	sw	s6,48(s1)
    c->proc = p;
    800028e6:	08993c23          	sd	s1,152(s2)
    swtch(&c->context, &p->context);
    800028ea:	08848593          	addi	a1,s1,136
    800028ee:	854e                	mv	a0,s3
    800028f0:	00001097          	auipc	ra,0x1
    800028f4:	90c080e7          	jalr	-1780(ra) # 800031fc <swtch>
    c->proc = 0;
    800028f8:	08093c23          	sd	zero,152(s2)
    release(&p->lock);
    800028fc:	8526                	mv	a0,s1
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	3a8080e7          	jalr	936(ra) # 80000ca6 <release>
    80002906:	bf4d                	j	800028b8 <blncflag_on+0x50>
      panic("bad proc was selected");
    80002908:	00006517          	auipc	a0,0x6
    8000290c:	a4050513          	addi	a0,a0,-1472 # 80008348 <digits+0x308>
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	c2e080e7          	jalr	-978(ra) # 8000053e <panic>

0000000080002918 <scheduler>:
{
    80002918:	1141                	addi	sp,sp,-16
    8000291a:	e406                	sd	ra,8(sp)
    8000291c:	e022                	sd	s0,0(sp)
    8000291e:	0800                	addi	s0,sp,16
      if(!print_flag){
    80002920:	00006797          	auipc	a5,0x6
    80002924:	74c7a783          	lw	a5,1868(a5) # 8000906c <print_flag>
    80002928:	c789                	beqz	a5,80002932 <scheduler+0x1a>
    blncflag_on();
    8000292a:	00000097          	auipc	ra,0x0
    8000292e:	f3e080e7          	jalr	-194(ra) # 80002868 <blncflag_on>
      print_flag++;
    80002932:	4785                	li	a5,1
    80002934:	00006717          	auipc	a4,0x6
    80002938:	72f72c23          	sw	a5,1848(a4) # 8000906c <print_flag>
      printf("BLNCFLG is ON\n");
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	a2450513          	addi	a0,a0,-1500 # 80008360 <digits+0x320>
    80002944:	ffffe097          	auipc	ra,0xffffe
    80002948:	c44080e7          	jalr	-956(ra) # 80000588 <printf>
    8000294c:	bff9                	j	8000292a <scheduler+0x12>

000000008000294e <blncflag_off>:
{
    8000294e:	7139                	addi	sp,sp,-64
    80002950:	fc06                	sd	ra,56(sp)
    80002952:	f822                	sd	s0,48(sp)
    80002954:	f426                	sd	s1,40(sp)
    80002956:	f04a                	sd	s2,32(sp)
    80002958:	ec4e                	sd	s3,24(sp)
    8000295a:	e852                	sd	s4,16(sp)
    8000295c:	e456                	sd	s5,8(sp)
    8000295e:	e05a                	sd	s6,0(sp)
    80002960:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80002962:	8792                	mv	a5,tp
  int id = r_tp();
    80002964:	2781                	sext.w	a5,a5
    80002966:	8a12                	mv	s4,tp
    80002968:	2a01                	sext.w	s4,s4
  c->proc = 0;
    8000296a:	00379993          	slli	s3,a5,0x3
    8000296e:	00f98733          	add	a4,s3,a5
    80002972:	00471693          	slli	a3,a4,0x4
    80002976:	0000f717          	auipc	a4,0xf
    8000297a:	96a70713          	addi	a4,a4,-1686 # 800112e0 <readyLock>
    8000297e:	9736                	add	a4,a4,a3
    80002980:	08073c23          	sd	zero,152(a4)
        swtch(&c->context, &p->context);
    80002984:	0000f717          	auipc	a4,0xf
    80002988:	9fc70713          	addi	a4,a4,-1540 # 80011380 <cpus+0x10>
    8000298c:	00e689b3          	add	s3,a3,a4
      if(p->state != RUNNABLE)
    80002990:	4a8d                	li	s5,3
        p->state = RUNNING;
    80002992:	4b11                	li	s6,4
        c->proc = p;
    80002994:	0000f917          	auipc	s2,0xf
    80002998:	94c90913          	addi	s2,s2,-1716 # 800112e0 <readyLock>
    8000299c:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029a2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a6:	10079073          	csrw	sstatus,a5
    p = remove_first(READYL, cpu_id);
    800029aa:	85d2                	mv	a1,s4
    800029ac:	4501                	li	a0,0
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	584080e7          	jalr	1412(ra) # 80001f32 <remove_first>
    800029b6:	84aa                	mv	s1,a0
    if(!p){ // no proces ready 
    800029b8:	d17d                	beqz	a0,8000299e <blncflag_off+0x50>
      acquire(&p->lock);
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	232080e7          	jalr	562(ra) # 80000bec <acquire>
      if(p->state != RUNNABLE)
    800029c2:	589c                	lw	a5,48(s1)
    800029c4:	03579563          	bne	a5,s5,800029ee <blncflag_off+0xa0>
        p->state = RUNNING;
    800029c8:	0364a823          	sw	s6,48(s1)
        c->proc = p;
    800029cc:	08993c23          	sd	s1,152(s2)
        swtch(&c->context, &p->context);
    800029d0:	08848593          	addi	a1,s1,136
    800029d4:	854e                	mv	a0,s3
    800029d6:	00001097          	auipc	ra,0x1
    800029da:	826080e7          	jalr	-2010(ra) # 800031fc <swtch>
        c->proc = 0;
    800029de:	08093c23          	sd	zero,152(s2)
      release(&p->lock);
    800029e2:	8526                	mv	a0,s1
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	2c2080e7          	jalr	706(ra) # 80000ca6 <release>
    800029ec:	bf4d                	j	8000299e <blncflag_off+0x50>
        panic("bad proc was selected");
    800029ee:	00006517          	auipc	a0,0x6
    800029f2:	95a50513          	addi	a0,a0,-1702 # 80008348 <digits+0x308>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	b48080e7          	jalr	-1208(ra) # 8000053e <panic>

00000000800029fe <sched>:
{
    800029fe:	7179                	addi	sp,sp,-48
    80002a00:	f406                	sd	ra,40(sp)
    80002a02:	f022                	sd	s0,32(sp)
    80002a04:	ec26                	sd	s1,24(sp)
    80002a06:	e84a                	sd	s2,16(sp)
    80002a08:	e44e                	sd	s3,8(sp)
    80002a0a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002a0c:	00000097          	auipc	ra,0x0
    80002a10:	8c4080e7          	jalr	-1852(ra) # 800022d0 <myproc>
    80002a14:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	154080e7          	jalr	340(ra) # 80000b6a <holding>
    80002a1e:	c959                	beqz	a0,80002ab4 <sched+0xb6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a20:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002a22:	0007871b          	sext.w	a4,a5
    80002a26:	00371793          	slli	a5,a4,0x3
    80002a2a:	97ba                	add	a5,a5,a4
    80002a2c:	0792                	slli	a5,a5,0x4
    80002a2e:	0000f717          	auipc	a4,0xf
    80002a32:	8b270713          	addi	a4,a4,-1870 # 800112e0 <readyLock>
    80002a36:	97ba                	add	a5,a5,a4
    80002a38:	1107a703          	lw	a4,272(a5)
    80002a3c:	4785                	li	a5,1
    80002a3e:	08f71363          	bne	a4,a5,80002ac4 <sched+0xc6>
  if(p->state == RUNNING)
    80002a42:	5898                	lw	a4,48(s1)
    80002a44:	4791                	li	a5,4
    80002a46:	08f70763          	beq	a4,a5,80002ad4 <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a4a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a4e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002a50:	ebd1                	bnez	a5,80002ae4 <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a52:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002a54:	0000f917          	auipc	s2,0xf
    80002a58:	88c90913          	addi	s2,s2,-1908 # 800112e0 <readyLock>
    80002a5c:	0007871b          	sext.w	a4,a5
    80002a60:	00371793          	slli	a5,a4,0x3
    80002a64:	97ba                	add	a5,a5,a4
    80002a66:	0792                	slli	a5,a5,0x4
    80002a68:	97ca                	add	a5,a5,s2
    80002a6a:	1147a983          	lw	s3,276(a5)
    80002a6e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002a70:	0007859b          	sext.w	a1,a5
    80002a74:	00359793          	slli	a5,a1,0x3
    80002a78:	97ae                	add	a5,a5,a1
    80002a7a:	0792                	slli	a5,a5,0x4
    80002a7c:	0000f597          	auipc	a1,0xf
    80002a80:	90458593          	addi	a1,a1,-1788 # 80011380 <cpus+0x10>
    80002a84:	95be                	add	a1,a1,a5
    80002a86:	08848513          	addi	a0,s1,136
    80002a8a:	00000097          	auipc	ra,0x0
    80002a8e:	772080e7          	jalr	1906(ra) # 800031fc <swtch>
    80002a92:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002a94:	0007871b          	sext.w	a4,a5
    80002a98:	00371793          	slli	a5,a4,0x3
    80002a9c:	97ba                	add	a5,a5,a4
    80002a9e:	0792                	slli	a5,a5,0x4
    80002aa0:	97ca                	add	a5,a5,s2
    80002aa2:	1137aa23          	sw	s3,276(a5)
}
    80002aa6:	70a2                	ld	ra,40(sp)
    80002aa8:	7402                	ld	s0,32(sp)
    80002aaa:	64e2                	ld	s1,24(sp)
    80002aac:	6942                	ld	s2,16(sp)
    80002aae:	69a2                	ld	s3,8(sp)
    80002ab0:	6145                	addi	sp,sp,48
    80002ab2:	8082                	ret
    panic("sched p->lock");
    80002ab4:	00006517          	auipc	a0,0x6
    80002ab8:	8bc50513          	addi	a0,a0,-1860 # 80008370 <digits+0x330>
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	a82080e7          	jalr	-1406(ra) # 8000053e <panic>
    panic("sched locks");
    80002ac4:	00006517          	auipc	a0,0x6
    80002ac8:	8bc50513          	addi	a0,a0,-1860 # 80008380 <digits+0x340>
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	a72080e7          	jalr	-1422(ra) # 8000053e <panic>
    panic("sched running");
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	8bc50513          	addi	a0,a0,-1860 # 80008390 <digits+0x350>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	a62080e7          	jalr	-1438(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	8bc50513          	addi	a0,a0,-1860 # 800083a0 <digits+0x360>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	a52080e7          	jalr	-1454(ra) # 8000053e <panic>

0000000080002af4 <yield>:
{
    80002af4:	1101                	addi	sp,sp,-32
    80002af6:	ec06                	sd	ra,24(sp)
    80002af8:	e822                	sd	s0,16(sp)
    80002afa:	e426                	sd	s1,8(sp)
    80002afc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	7d2080e7          	jalr	2002(ra) # 800022d0 <myproc>
    80002b06:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	0e4080e7          	jalr	228(ra) # 80000bec <acquire>
  p->state = RUNNABLE;
    80002b10:	478d                	li	a5,3
    80002b12:	d89c                	sw	a5,48(s1)
  add_proc_to_list(p, READYL, p->parent_cpu);
    80002b14:	4cb0                	lw	a2,88(s1)
    80002b16:	4581                	li	a1,0
    80002b18:	8526                	mv	a0,s1
    80002b1a:	fffff097          	auipc	ra,0xfffff
    80002b1e:	3bc080e7          	jalr	956(ra) # 80001ed6 <add_proc_to_list>
  sched();
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	edc080e7          	jalr	-292(ra) # 800029fe <sched>
  release(&p->lock);
    80002b2a:	8526                	mv	a0,s1
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	17a080e7          	jalr	378(ra) # 80000ca6 <release>
}
    80002b34:	60e2                	ld	ra,24(sp)
    80002b36:	6442                	ld	s0,16(sp)
    80002b38:	64a2                	ld	s1,8(sp)
    80002b3a:	6105                	addi	sp,sp,32
    80002b3c:	8082                	ret

0000000080002b3e <set_cpu>:
  if(cpu_num<0 || cpu_num>NCPU){
    80002b3e:	47a1                	li	a5,8
    80002b40:	04a7e563          	bltu	a5,a0,80002b8a <set_cpu+0x4c>
{
    80002b44:	1101                	addi	sp,sp,-32
    80002b46:	ec06                	sd	ra,24(sp)
    80002b48:	e822                	sd	s0,16(sp)
    80002b4a:	e426                	sd	s1,8(sp)
    80002b4c:	e04a                	sd	s2,0(sp)
    80002b4e:	1000                	addi	s0,sp,32
    80002b50:	84aa                	mv	s1,a0
  struct proc* p = myproc();
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	77e080e7          	jalr	1918(ra) # 800022d0 <myproc>
    80002b5a:	892a                	mv	s2,a0
  decrease_size(p->parent_cpu);
    80002b5c:	4d28                	lw	a0,88(a0)
    80002b5e:	fffff097          	auipc	ra,0xfffff
    80002b62:	02c080e7          	jalr	44(ra) # 80001b8a <decrease_size>
  p->parent_cpu=cpu_num;
    80002b66:	04992c23          	sw	s1,88(s2)
  increase_size(cpu_num);
    80002b6a:	8526                	mv	a0,s1
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	fd4080e7          	jalr	-44(ra) # 80001b40 <increase_size>
  yield();
    80002b74:	00000097          	auipc	ra,0x0
    80002b78:	f80080e7          	jalr	-128(ra) # 80002af4 <yield>
  return cpu_num;
    80002b7c:	8526                	mv	a0,s1
}
    80002b7e:	60e2                	ld	ra,24(sp)
    80002b80:	6442                	ld	s0,16(sp)
    80002b82:	64a2                	ld	s1,8(sp)
    80002b84:	6902                	ld	s2,0(sp)
    80002b86:	6105                	addi	sp,sp,32
    80002b88:	8082                	ret
    return -1;
    80002b8a:	557d                	li	a0,-1
}
    80002b8c:	8082                	ret

0000000080002b8e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002b8e:	7179                	addi	sp,sp,-48
    80002b90:	f406                	sd	ra,40(sp)
    80002b92:	f022                	sd	s0,32(sp)
    80002b94:	ec26                	sd	s1,24(sp)
    80002b96:	e84a                	sd	s2,16(sp)
    80002b98:	e44e                	sd	s3,8(sp)
    80002b9a:	1800                	addi	s0,sp,48
    80002b9c:	89aa                	mv	s3,a0
    80002b9e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	730080e7          	jalr	1840(ra) # 800022d0 <myproc>
    80002ba8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	042080e7          	jalr	66(ra) # 80000bec <acquire>
  release(lk);
    80002bb2:	854a                	mv	a0,s2
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	0f2080e7          	jalr	242(ra) # 80000ca6 <release>

  // Go to sleep.
  p->chan = chan;
    80002bbc:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    80002bc0:	4789                	li	a5,2
    80002bc2:	d89c                	sw	a5,48(s1)
  decrease_size(p->parent_cpu);
    80002bc4:	4ca8                	lw	a0,88(s1)
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	fc4080e7          	jalr	-60(ra) # 80001b8a <decrease_size>
  //--------------------------------------------------------------------
    add_proc_to_list(p, SLEEPINGL,-1);
    80002bce:	567d                	li	a2,-1
    80002bd0:	4589                	li	a1,2
    80002bd2:	8526                	mv	a0,s1
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	302080e7          	jalr	770(ra) # 80001ed6 <add_proc_to_list>
  //--------------------------------------------------------------------

  sched();
    80002bdc:	00000097          	auipc	ra,0x0
    80002be0:	e22080e7          	jalr	-478(ra) # 800029fe <sched>

  // Tidy up.
  p->chan = 0;
    80002be4:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002be8:	8526                	mv	a0,s1
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	0bc080e7          	jalr	188(ra) # 80000ca6 <release>
  acquire(lk);
    80002bf2:	854a                	mv	a0,s2
    80002bf4:	ffffe097          	auipc	ra,0xffffe
    80002bf8:	ff8080e7          	jalr	-8(ra) # 80000bec <acquire>

}
    80002bfc:	70a2                	ld	ra,40(sp)
    80002bfe:	7402                	ld	s0,32(sp)
    80002c00:	64e2                	ld	s1,24(sp)
    80002c02:	6942                	ld	s2,16(sp)
    80002c04:	69a2                	ld	s3,8(sp)
    80002c06:	6145                	addi	sp,sp,48
    80002c08:	8082                	ret

0000000080002c0a <wait>:
{
    80002c0a:	715d                	addi	sp,sp,-80
    80002c0c:	e486                	sd	ra,72(sp)
    80002c0e:	e0a2                	sd	s0,64(sp)
    80002c10:	fc26                	sd	s1,56(sp)
    80002c12:	f84a                	sd	s2,48(sp)
    80002c14:	f44e                	sd	s3,40(sp)
    80002c16:	f052                	sd	s4,32(sp)
    80002c18:	ec56                	sd	s5,24(sp)
    80002c1a:	e85a                	sd	s6,16(sp)
    80002c1c:	e45e                	sd	s7,8(sp)
    80002c1e:	e062                	sd	s8,0(sp)
    80002c20:	0880                	addi	s0,sp,80
    80002c22:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	6ac080e7          	jalr	1708(ra) # 800022d0 <myproc>
    80002c2c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002c2e:	0000f517          	auipc	a0,0xf
    80002c32:	99a50513          	addi	a0,a0,-1638 # 800115c8 <wait_lock>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	fb6080e7          	jalr	-74(ra) # 80000bec <acquire>
    havekids = 0;
    80002c3e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002c40:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002c42:	00015997          	auipc	s3,0x15
    80002c46:	d9e98993          	addi	s3,s3,-610 # 800179e0 <tickslock>
        havekids = 1;
    80002c4a:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002c4c:	0000fc17          	auipc	s8,0xf
    80002c50:	97cc0c13          	addi	s8,s8,-1668 # 800115c8 <wait_lock>
    havekids = 0;
    80002c54:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002c56:	0000f497          	auipc	s1,0xf
    80002c5a:	98a48493          	addi	s1,s1,-1654 # 800115e0 <proc>
    80002c5e:	a0bd                	j	80002ccc <wait+0xc2>
          pid = np->pid;
    80002c60:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002c64:	000b0e63          	beqz	s6,80002c80 <wait+0x76>
    80002c68:	4691                	li	a3,4
    80002c6a:	04448613          	addi	a2,s1,68
    80002c6e:	85da                	mv	a1,s6
    80002c70:	07893503          	ld	a0,120(s2)
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	a0c080e7          	jalr	-1524(ra) # 80001680 <copyout>
    80002c7c:	02054563          	bltz	a0,80002ca6 <wait+0x9c>
          freeproc(np);
    80002c80:	8526                	mv	a0,s1
    80002c82:	00000097          	auipc	ra,0x0
    80002c86:	814080e7          	jalr	-2028(ra) # 80002496 <freeproc>
          release(&np->lock);
    80002c8a:	8526                	mv	a0,s1
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	01a080e7          	jalr	26(ra) # 80000ca6 <release>
          release(&wait_lock);
    80002c94:	0000f517          	auipc	a0,0xf
    80002c98:	93450513          	addi	a0,a0,-1740 # 800115c8 <wait_lock>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	00a080e7          	jalr	10(ra) # 80000ca6 <release>
          return pid;
    80002ca4:	a09d                	j	80002d0a <wait+0x100>
            release(&np->lock);
    80002ca6:	8526                	mv	a0,s1
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	ffe080e7          	jalr	-2(ra) # 80000ca6 <release>
            release(&wait_lock);
    80002cb0:	0000f517          	auipc	a0,0xf
    80002cb4:	91850513          	addi	a0,a0,-1768 # 800115c8 <wait_lock>
    80002cb8:	ffffe097          	auipc	ra,0xffffe
    80002cbc:	fee080e7          	jalr	-18(ra) # 80000ca6 <release>
            return -1;
    80002cc0:	59fd                	li	s3,-1
    80002cc2:	a0a1                	j	80002d0a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002cc4:	19048493          	addi	s1,s1,400
    80002cc8:	03348463          	beq	s1,s3,80002cf0 <wait+0xe6>
      if(np->parent == p){
    80002ccc:	70bc                	ld	a5,96(s1)
    80002cce:	ff279be3          	bne	a5,s2,80002cc4 <wait+0xba>
        acquire(&np->lock);
    80002cd2:	8526                	mv	a0,s1
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	f18080e7          	jalr	-232(ra) # 80000bec <acquire>
        if(np->state == ZOMBIE){
    80002cdc:	589c                	lw	a5,48(s1)
    80002cde:	f94781e3          	beq	a5,s4,80002c60 <wait+0x56>
        release(&np->lock);
    80002ce2:	8526                	mv	a0,s1
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	fc2080e7          	jalr	-62(ra) # 80000ca6 <release>
        havekids = 1;
    80002cec:	8756                	mv	a4,s5
    80002cee:	bfd9                	j	80002cc4 <wait+0xba>
    if(!havekids || p->killed){
    80002cf0:	c701                	beqz	a4,80002cf8 <wait+0xee>
    80002cf2:	04092783          	lw	a5,64(s2)
    80002cf6:	c79d                	beqz	a5,80002d24 <wait+0x11a>
      release(&wait_lock);
    80002cf8:	0000f517          	auipc	a0,0xf
    80002cfc:	8d050513          	addi	a0,a0,-1840 # 800115c8 <wait_lock>
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	fa6080e7          	jalr	-90(ra) # 80000ca6 <release>
      return -1;
    80002d08:	59fd                	li	s3,-1
}
    80002d0a:	854e                	mv	a0,s3
    80002d0c:	60a6                	ld	ra,72(sp)
    80002d0e:	6406                	ld	s0,64(sp)
    80002d10:	74e2                	ld	s1,56(sp)
    80002d12:	7942                	ld	s2,48(sp)
    80002d14:	79a2                	ld	s3,40(sp)
    80002d16:	7a02                	ld	s4,32(sp)
    80002d18:	6ae2                	ld	s5,24(sp)
    80002d1a:	6b42                	ld	s6,16(sp)
    80002d1c:	6ba2                	ld	s7,8(sp)
    80002d1e:	6c02                	ld	s8,0(sp)
    80002d20:	6161                	addi	sp,sp,80
    80002d22:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002d24:	85e2                	mv	a1,s8
    80002d26:	854a                	mv	a0,s2
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	e66080e7          	jalr	-410(ra) # 80002b8e <sleep>
    havekids = 0;
    80002d30:	b715                	j	80002c54 <wait+0x4a>

0000000080002d32 <wakeup>:
// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
//--------------------------------------------------------------------
void
wakeup(void *chan)
{
    80002d32:	711d                	addi	sp,sp,-96
    80002d34:	ec86                	sd	ra,88(sp)
    80002d36:	e8a2                	sd	s0,80(sp)
    80002d38:	e4a6                	sd	s1,72(sp)
    80002d3a:	e0ca                	sd	s2,64(sp)
    80002d3c:	fc4e                	sd	s3,56(sp)
    80002d3e:	f852                	sd	s4,48(sp)
    80002d40:	f456                	sd	s5,40(sp)
    80002d42:	f05a                	sd	s6,32(sp)
    80002d44:	ec5e                	sd	s7,24(sp)
    80002d46:	e862                	sd	s8,16(sp)
    80002d48:	e466                	sd	s9,8(sp)
    80002d4a:	e06a                	sd	s10,0(sp)
    80002d4c:	1080                	addi	s0,sp,96
    80002d4e:	8aaa                	mv	s5,a0
  int released_list = 0;
  struct proc *p;
  struct proc* prev = 0;
  struct proc* tmp;
  acquire_list(SLEEPINGL, -1);
    80002d50:	55fd                	li	a1,-1
    80002d52:	4509                	li	a0,2
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	e80080e7          	jalr	-384(ra) # 80001bd4 <acquire_list>
  p = get_head(SLEEPINGL, -1);
    80002d5c:	55fd                	li	a1,-1
    80002d5e:	4509                	li	a0,2
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	efc080e7          	jalr	-260(ra) # 80001c5c <get_head>
    80002d68:	84aa                	mv	s1,a0
  while(p){
    80002d6a:	14050463          	beqz	a0,80002eb2 <wakeup+0x180>
  struct proc* prev = 0;
    80002d6e:	4a01                	li	s4,0
  int released_list = 0;
    80002d70:	4b81                	li	s7,0
    } 
    else{
      //we are not on the chan
      if(p == get_head(SLEEPINGL, -1)){
        release_list(SLEEPINGL,-1);
        released_list = 1;
    80002d72:	4c85                	li	s9,1
        p->state = RUNNABLE;
    80002d74:	4c0d                	li	s8,3
    80002d76:	a0f9                	j	80002e44 <wakeup+0x112>
      if(p == get_head(SLEEPINGL, -1)){
    80002d78:	55fd                	li	a1,-1
    80002d7a:	4509                	li	a0,2
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	ee0080e7          	jalr	-288(ra) # 80001c5c <get_head>
    80002d84:	04a48763          	beq	s1,a0,80002dd2 <wakeup+0xa0>
        prev->next = p->next;
    80002d88:	68bc                	ld	a5,80(s1)
    80002d8a:	04fa3823          	sd	a5,80(s4)
        p->next = 0;
    80002d8e:	0404b823          	sd	zero,80(s1)
        p->state = RUNNABLE;
    80002d92:	0384a823          	sw	s8,48(s1)
        int cpu_id = (BLNCFLG) ? get_lazy_cpu() : p->parent_cpu;
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	d76080e7          	jalr	-650(ra) # 80001b0c <get_lazy_cpu>
    80002d9e:	8b2a                	mv	s6,a0
        p->parent_cpu = cpu_id;
    80002da0:	cca8                	sw	a0,88(s1)
        increase_size(cpu_id);
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	d9e080e7          	jalr	-610(ra) # 80001b40 <increase_size>
        add_proc_to_list(p, READYL, cpu_id);
    80002daa:	865a                	mv	a2,s6
    80002dac:	4581                	li	a1,0
    80002dae:	8526                	mv	a0,s1
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	126080e7          	jalr	294(ra) # 80001ed6 <add_proc_to_list>
        release(&p->list_lock);
    80002db8:	854a                	mv	a0,s2
    80002dba:	ffffe097          	auipc	ra,0xffffe
    80002dbe:	eec080e7          	jalr	-276(ra) # 80000ca6 <release>
        release(&p->lock);
    80002dc2:	8526                	mv	a0,s1
    80002dc4:	ffffe097          	auipc	ra,0xffffe
    80002dc8:	ee2080e7          	jalr	-286(ra) # 80000ca6 <release>
        p = prev->next;
    80002dcc:	050a3483          	ld	s1,80(s4)
    80002dd0:	a88d                	j	80002e42 <wakeup+0x110>
        set_head(p->next, SLEEPINGL, -1);
    80002dd2:	567d                	li	a2,-1
    80002dd4:	4589                	li	a1,2
    80002dd6:	68a8                	ld	a0,80(s1)
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	eea080e7          	jalr	-278(ra) # 80001cc2 <set_head>
        p = p->next;
    80002de0:	0504bd03          	ld	s10,80(s1)
        tmp->next = 0;
    80002de4:	0404b823          	sd	zero,80(s1)
        tmp->state = RUNNABLE;
    80002de8:	0384a823          	sw	s8,48(s1)
        int cpu_id = (BLNCFLG) ? get_lazy_cpu() : tmp->parent_cpu;
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	d20080e7          	jalr	-736(ra) # 80001b0c <get_lazy_cpu>
    80002df4:	8b2a                	mv	s6,a0
        tmp->parent_cpu = cpu_id;
    80002df6:	cca8                	sw	a0,88(s1)
        increase_size(cpu_id);
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	d48080e7          	jalr	-696(ra) # 80001b40 <increase_size>
        add_proc_to_list(tmp, READYL, cpu_id);
    80002e00:	865a                	mv	a2,s6
    80002e02:	4581                	li	a1,0
    80002e04:	8526                	mv	a0,s1
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	0d0080e7          	jalr	208(ra) # 80001ed6 <add_proc_to_list>
        release(&tmp->list_lock);
    80002e0e:	854a                	mv	a0,s2
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	e96080e7          	jalr	-362(ra) # 80000ca6 <release>
        release(&tmp->lock);
    80002e18:	8526                	mv	a0,s1
    80002e1a:	ffffe097          	auipc	ra,0xffffe
    80002e1e:	e8c080e7          	jalr	-372(ra) # 80000ca6 <release>
        p = p->next;
    80002e22:	84ea                	mv	s1,s10
    80002e24:	a839                	j	80002e42 <wakeup+0x110>
        release_list(SLEEPINGL,-1);
    80002e26:	55fd                	li	a1,-1
    80002e28:	4509                	li	a0,2
    80002e2a:	fffff097          	auipc	ra,0xfffff
    80002e2e:	f86080e7          	jalr	-122(ra) # 80001db0 <release_list>
        released_list = 1;
    80002e32:	8be6                	mv	s7,s9
      }
      else{
        release(&prev->list_lock);
      }
      release(&p->lock);  //because we dont need to change his fields
    80002e34:	854e                	mv	a0,s3
    80002e36:	ffffe097          	auipc	ra,0xffffe
    80002e3a:	e70080e7          	jalr	-400(ra) # 80000ca6 <release>
      prev = p;
      p = p->next;
    80002e3e:	8a26                	mv	s4,s1
    80002e40:	68a4                	ld	s1,80(s1)
  while(p){
    80002e42:	c0a1                	beqz	s1,80002e82 <wakeup+0x150>
    acquire(&p->lock);
    80002e44:	89a6                	mv	s3,s1
    80002e46:	8526                	mv	a0,s1
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	da4080e7          	jalr	-604(ra) # 80000bec <acquire>
    acquire(&p->list_lock);
    80002e50:	01848913          	addi	s2,s1,24
    80002e54:	854a                	mv	a0,s2
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	d96080e7          	jalr	-618(ra) # 80000bec <acquire>
    if(p->chan == chan){
    80002e5e:	7c9c                	ld	a5,56(s1)
    80002e60:	f1578ce3          	beq	a5,s5,80002d78 <wakeup+0x46>
      if(p == get_head(SLEEPINGL, -1)){
    80002e64:	55fd                	li	a1,-1
    80002e66:	4509                	li	a0,2
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	df4080e7          	jalr	-524(ra) # 80001c5c <get_head>
    80002e70:	faa48be3          	beq	s1,a0,80002e26 <wakeup+0xf4>
        release(&prev->list_lock);
    80002e74:	018a0513          	addi	a0,s4,24
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	e2e080e7          	jalr	-466(ra) # 80000ca6 <release>
    80002e80:	bf55                	j	80002e34 <wakeup+0x102>
    }
  }
  if(!released_list){
    80002e82:	020b8963          	beqz	s7,80002eb4 <wakeup+0x182>
    release_list(SLEEPINGL, -1);
  }
  if(prev){
    80002e86:	000a0863          	beqz	s4,80002e96 <wakeup+0x164>
    release(&prev->list_lock);
    80002e8a:	018a0513          	addi	a0,s4,24
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	e18080e7          	jalr	-488(ra) # 80000ca6 <release>
  }
}
    80002e96:	60e6                	ld	ra,88(sp)
    80002e98:	6446                	ld	s0,80(sp)
    80002e9a:	64a6                	ld	s1,72(sp)
    80002e9c:	6906                	ld	s2,64(sp)
    80002e9e:	79e2                	ld	s3,56(sp)
    80002ea0:	7a42                	ld	s4,48(sp)
    80002ea2:	7aa2                	ld	s5,40(sp)
    80002ea4:	7b02                	ld	s6,32(sp)
    80002ea6:	6be2                	ld	s7,24(sp)
    80002ea8:	6c42                	ld	s8,16(sp)
    80002eaa:	6ca2                	ld	s9,8(sp)
    80002eac:	6d02                	ld	s10,0(sp)
    80002eae:	6125                	addi	sp,sp,96
    80002eb0:	8082                	ret
  struct proc* prev = 0;
    80002eb2:	8a2a                	mv	s4,a0
    release_list(SLEEPINGL, -1);
    80002eb4:	55fd                	li	a1,-1
    80002eb6:	4509                	li	a0,2
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	ef8080e7          	jalr	-264(ra) # 80001db0 <release_list>
    80002ec0:	b7d9                	j	80002e86 <wakeup+0x154>

0000000080002ec2 <reparent>:
{
    80002ec2:	7179                	addi	sp,sp,-48
    80002ec4:	f406                	sd	ra,40(sp)
    80002ec6:	f022                	sd	s0,32(sp)
    80002ec8:	ec26                	sd	s1,24(sp)
    80002eca:	e84a                	sd	s2,16(sp)
    80002ecc:	e44e                	sd	s3,8(sp)
    80002ece:	e052                	sd	s4,0(sp)
    80002ed0:	1800                	addi	s0,sp,48
    80002ed2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ed4:	0000e497          	auipc	s1,0xe
    80002ed8:	70c48493          	addi	s1,s1,1804 # 800115e0 <proc>
      pp->parent = initproc;
    80002edc:	00006a17          	auipc	s4,0x6
    80002ee0:	184a0a13          	addi	s4,s4,388 # 80009060 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ee4:	00015997          	auipc	s3,0x15
    80002ee8:	afc98993          	addi	s3,s3,-1284 # 800179e0 <tickslock>
    80002eec:	a029                	j	80002ef6 <reparent+0x34>
    80002eee:	19048493          	addi	s1,s1,400
    80002ef2:	01348d63          	beq	s1,s3,80002f0c <reparent+0x4a>
    if(pp->parent == p){
    80002ef6:	70bc                	ld	a5,96(s1)
    80002ef8:	ff279be3          	bne	a5,s2,80002eee <reparent+0x2c>
      pp->parent = initproc;
    80002efc:	000a3503          	ld	a0,0(s4)
    80002f00:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	e30080e7          	jalr	-464(ra) # 80002d32 <wakeup>
    80002f0a:	b7d5                	j	80002eee <reparent+0x2c>
}
    80002f0c:	70a2                	ld	ra,40(sp)
    80002f0e:	7402                	ld	s0,32(sp)
    80002f10:	64e2                	ld	s1,24(sp)
    80002f12:	6942                	ld	s2,16(sp)
    80002f14:	69a2                	ld	s3,8(sp)
    80002f16:	6a02                	ld	s4,0(sp)
    80002f18:	6145                	addi	sp,sp,48
    80002f1a:	8082                	ret

0000000080002f1c <exit>:
{
    80002f1c:	7179                	addi	sp,sp,-48
    80002f1e:	f406                	sd	ra,40(sp)
    80002f20:	f022                	sd	s0,32(sp)
    80002f22:	ec26                	sd	s1,24(sp)
    80002f24:	e84a                	sd	s2,16(sp)
    80002f26:	e44e                	sd	s3,8(sp)
    80002f28:	e052                	sd	s4,0(sp)
    80002f2a:	1800                	addi	s0,sp,48
    80002f2c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	3a2080e7          	jalr	930(ra) # 800022d0 <myproc>
    80002f36:	89aa                	mv	s3,a0
  if(p == initproc)
    80002f38:	00006797          	auipc	a5,0x6
    80002f3c:	1287b783          	ld	a5,296(a5) # 80009060 <initproc>
    80002f40:	0f850493          	addi	s1,a0,248
    80002f44:	17850913          	addi	s2,a0,376
    80002f48:	02a79363          	bne	a5,a0,80002f6e <exit+0x52>
    panic("init exiting");
    80002f4c:	00005517          	auipc	a0,0x5
    80002f50:	46c50513          	addi	a0,a0,1132 # 800083b8 <digits+0x378>
    80002f54:	ffffd097          	auipc	ra,0xffffd
    80002f58:	5ea080e7          	jalr	1514(ra) # 8000053e <panic>
      fileclose(f);
    80002f5c:	00002097          	auipc	ra,0x2
    80002f60:	1ec080e7          	jalr	492(ra) # 80005148 <fileclose>
      p->ofile[fd] = 0;
    80002f64:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002f68:	04a1                	addi	s1,s1,8
    80002f6a:	01248563          	beq	s1,s2,80002f74 <exit+0x58>
    if(p->ofile[fd]){
    80002f6e:	6088                	ld	a0,0(s1)
    80002f70:	f575                	bnez	a0,80002f5c <exit+0x40>
    80002f72:	bfdd                	j	80002f68 <exit+0x4c>
  begin_op();
    80002f74:	00002097          	auipc	ra,0x2
    80002f78:	d08080e7          	jalr	-760(ra) # 80004c7c <begin_op>
  iput(p->cwd);
    80002f7c:	1789b503          	ld	a0,376(s3)
    80002f80:	00001097          	auipc	ra,0x1
    80002f84:	4e4080e7          	jalr	1252(ra) # 80004464 <iput>
  end_op();
    80002f88:	00002097          	auipc	ra,0x2
    80002f8c:	d74080e7          	jalr	-652(ra) # 80004cfc <end_op>
  p->cwd = 0;
    80002f90:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    80002f94:	0000e497          	auipc	s1,0xe
    80002f98:	63448493          	addi	s1,s1,1588 # 800115c8 <wait_lock>
    80002f9c:	8526                	mv	a0,s1
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	c4e080e7          	jalr	-946(ra) # 80000bec <acquire>
  reparent(p);
    80002fa6:	854e                	mv	a0,s3
    80002fa8:	00000097          	auipc	ra,0x0
    80002fac:	f1a080e7          	jalr	-230(ra) # 80002ec2 <reparent>
  wakeup(p->parent);
    80002fb0:	0609b503          	ld	a0,96(s3)
    80002fb4:	00000097          	auipc	ra,0x0
    80002fb8:	d7e080e7          	jalr	-642(ra) # 80002d32 <wakeup>
  acquire(&p->lock);
    80002fbc:	854e                	mv	a0,s3
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	c2e080e7          	jalr	-978(ra) # 80000bec <acquire>
  p->xstate = status;
    80002fc6:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    80002fca:	4795                	li	a5,5
    80002fcc:	02f9a823          	sw	a5,48(s3)
  decrease_size(p->parent_cpu);
    80002fd0:	0589a503          	lw	a0,88(s3)
    80002fd4:	fffff097          	auipc	ra,0xfffff
    80002fd8:	bb6080e7          	jalr	-1098(ra) # 80001b8a <decrease_size>
  add_proc_to_list(p, ZOMBIEL, -1);
    80002fdc:	567d                	li	a2,-1
    80002fde:	4585                	li	a1,1
    80002fe0:	854e                	mv	a0,s3
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	ef4080e7          	jalr	-268(ra) # 80001ed6 <add_proc_to_list>
  release(&wait_lock);
    80002fea:	8526                	mv	a0,s1
    80002fec:	ffffe097          	auipc	ra,0xffffe
    80002ff0:	cba080e7          	jalr	-838(ra) # 80000ca6 <release>
  sched();
    80002ff4:	00000097          	auipc	ra,0x0
    80002ff8:	a0a080e7          	jalr	-1526(ra) # 800029fe <sched>
  panic("zombie exit");
    80002ffc:	00005517          	auipc	a0,0x5
    80003000:	3cc50513          	addi	a0,a0,972 # 800083c8 <digits+0x388>
    80003004:	ffffd097          	auipc	ra,0xffffd
    80003008:	53a080e7          	jalr	1338(ra) # 8000053e <panic>

000000008000300c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000300c:	7179                	addi	sp,sp,-48
    8000300e:	f406                	sd	ra,40(sp)
    80003010:	f022                	sd	s0,32(sp)
    80003012:	ec26                	sd	s1,24(sp)
    80003014:	e84a                	sd	s2,16(sp)
    80003016:	e44e                	sd	s3,8(sp)
    80003018:	1800                	addi	s0,sp,48
    8000301a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000301c:	0000e497          	auipc	s1,0xe
    80003020:	5c448493          	addi	s1,s1,1476 # 800115e0 <proc>
    80003024:	00015997          	auipc	s3,0x15
    80003028:	9bc98993          	addi	s3,s3,-1604 # 800179e0 <tickslock>
    acquire(&p->lock);
    8000302c:	8526                	mv	a0,s1
    8000302e:	ffffe097          	auipc	ra,0xffffe
    80003032:	bbe080e7          	jalr	-1090(ra) # 80000bec <acquire>
    if(p->pid == pid){
    80003036:	44bc                	lw	a5,72(s1)
    80003038:	01278d63          	beq	a5,s2,80003052 <kill+0x46>
        increase_size(p->parent_cpu);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000303c:	8526                	mv	a0,s1
    8000303e:	ffffe097          	auipc	ra,0xffffe
    80003042:	c68080e7          	jalr	-920(ra) # 80000ca6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80003046:	19048493          	addi	s1,s1,400
    8000304a:	ff3491e3          	bne	s1,s3,8000302c <kill+0x20>
  }
  return -1;
    8000304e:	557d                	li	a0,-1
    80003050:	a829                	j	8000306a <kill+0x5e>
      p->killed = 1;
    80003052:	4785                	li	a5,1
    80003054:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    80003056:	5898                	lw	a4,48(s1)
    80003058:	4789                	li	a5,2
    8000305a:	00f70f63          	beq	a4,a5,80003078 <kill+0x6c>
      release(&p->lock);
    8000305e:	8526                	mv	a0,s1
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	c46080e7          	jalr	-954(ra) # 80000ca6 <release>
      return 0;
    80003068:	4501                	li	a0,0
}
    8000306a:	70a2                	ld	ra,40(sp)
    8000306c:	7402                	ld	s0,32(sp)
    8000306e:	64e2                	ld	s1,24(sp)
    80003070:	6942                	ld	s2,16(sp)
    80003072:	69a2                	ld	s3,8(sp)
    80003074:	6145                	addi	sp,sp,48
    80003076:	8082                	ret
        p->state = RUNNABLE;
    80003078:	478d                	li	a5,3
    8000307a:	d89c                	sw	a5,48(s1)
        remove_proc(p, SLEEPINGL);
    8000307c:	4589                	li	a1,2
    8000307e:	8526                	mv	a0,s1
    80003080:	fffff097          	auipc	ra,0xfffff
    80003084:	f34080e7          	jalr	-204(ra) # 80001fb4 <remove_proc>
        add_proc_to_list(p, READYL, p->parent_cpu);
    80003088:	4cb0                	lw	a2,88(s1)
    8000308a:	4581                	li	a1,0
    8000308c:	8526                	mv	a0,s1
    8000308e:	fffff097          	auipc	ra,0xfffff
    80003092:	e48080e7          	jalr	-440(ra) # 80001ed6 <add_proc_to_list>
        increase_size(p->parent_cpu);
    80003096:	4ca8                	lw	a0,88(s1)
    80003098:	fffff097          	auipc	ra,0xfffff
    8000309c:	aa8080e7          	jalr	-1368(ra) # 80001b40 <increase_size>
    800030a0:	bf7d                	j	8000305e <kill+0x52>

00000000800030a2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800030a2:	7179                	addi	sp,sp,-48
    800030a4:	f406                	sd	ra,40(sp)
    800030a6:	f022                	sd	s0,32(sp)
    800030a8:	ec26                	sd	s1,24(sp)
    800030aa:	e84a                	sd	s2,16(sp)
    800030ac:	e44e                	sd	s3,8(sp)
    800030ae:	e052                	sd	s4,0(sp)
    800030b0:	1800                	addi	s0,sp,48
    800030b2:	84aa                	mv	s1,a0
    800030b4:	892e                	mv	s2,a1
    800030b6:	89b2                	mv	s3,a2
    800030b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800030ba:	fffff097          	auipc	ra,0xfffff
    800030be:	216080e7          	jalr	534(ra) # 800022d0 <myproc>
  if(user_dst){
    800030c2:	c08d                	beqz	s1,800030e4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800030c4:	86d2                	mv	a3,s4
    800030c6:	864e                	mv	a2,s3
    800030c8:	85ca                	mv	a1,s2
    800030ca:	7d28                	ld	a0,120(a0)
    800030cc:	ffffe097          	auipc	ra,0xffffe
    800030d0:	5b4080e7          	jalr	1460(ra) # 80001680 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800030d4:	70a2                	ld	ra,40(sp)
    800030d6:	7402                	ld	s0,32(sp)
    800030d8:	64e2                	ld	s1,24(sp)
    800030da:	6942                	ld	s2,16(sp)
    800030dc:	69a2                	ld	s3,8(sp)
    800030de:	6a02                	ld	s4,0(sp)
    800030e0:	6145                	addi	sp,sp,48
    800030e2:	8082                	ret
    memmove((char *)dst, src, len);
    800030e4:	000a061b          	sext.w	a2,s4
    800030e8:	85ce                	mv	a1,s3
    800030ea:	854a                	mv	a0,s2
    800030ec:	ffffe097          	auipc	ra,0xffffe
    800030f0:	c62080e7          	jalr	-926(ra) # 80000d4e <memmove>
    return 0;
    800030f4:	8526                	mv	a0,s1
    800030f6:	bff9                	j	800030d4 <either_copyout+0x32>

00000000800030f8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800030f8:	7179                	addi	sp,sp,-48
    800030fa:	f406                	sd	ra,40(sp)
    800030fc:	f022                	sd	s0,32(sp)
    800030fe:	ec26                	sd	s1,24(sp)
    80003100:	e84a                	sd	s2,16(sp)
    80003102:	e44e                	sd	s3,8(sp)
    80003104:	e052                	sd	s4,0(sp)
    80003106:	1800                	addi	s0,sp,48
    80003108:	892a                	mv	s2,a0
    8000310a:	84ae                	mv	s1,a1
    8000310c:	89b2                	mv	s3,a2
    8000310e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003110:	fffff097          	auipc	ra,0xfffff
    80003114:	1c0080e7          	jalr	448(ra) # 800022d0 <myproc>
  if(user_src){
    80003118:	c08d                	beqz	s1,8000313a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000311a:	86d2                	mv	a3,s4
    8000311c:	864e                	mv	a2,s3
    8000311e:	85ca                	mv	a1,s2
    80003120:	7d28                	ld	a0,120(a0)
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	5ea080e7          	jalr	1514(ra) # 8000170c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000312a:	70a2                	ld	ra,40(sp)
    8000312c:	7402                	ld	s0,32(sp)
    8000312e:	64e2                	ld	s1,24(sp)
    80003130:	6942                	ld	s2,16(sp)
    80003132:	69a2                	ld	s3,8(sp)
    80003134:	6a02                	ld	s4,0(sp)
    80003136:	6145                	addi	sp,sp,48
    80003138:	8082                	ret
    memmove(dst, (char*)src, len);
    8000313a:	000a061b          	sext.w	a2,s4
    8000313e:	85ce                	mv	a1,s3
    80003140:	854a                	mv	a0,s2
    80003142:	ffffe097          	auipc	ra,0xffffe
    80003146:	c0c080e7          	jalr	-1012(ra) # 80000d4e <memmove>
    return 0;
    8000314a:	8526                	mv	a0,s1
    8000314c:	bff9                	j	8000312a <either_copyin+0x32>

000000008000314e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000314e:	715d                	addi	sp,sp,-80
    80003150:	e486                	sd	ra,72(sp)
    80003152:	e0a2                	sd	s0,64(sp)
    80003154:	fc26                	sd	s1,56(sp)
    80003156:	f84a                	sd	s2,48(sp)
    80003158:	f44e                	sd	s3,40(sp)
    8000315a:	f052                	sd	s4,32(sp)
    8000315c:	ec56                	sd	s5,24(sp)
    8000315e:	e85a                	sd	s6,16(sp)
    80003160:	e45e                	sd	s7,8(sp)
    80003162:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80003164:	00005517          	auipc	a0,0x5
    80003168:	f6450513          	addi	a0,a0,-156 # 800080c8 <digits+0x88>
    8000316c:	ffffd097          	auipc	ra,0xffffd
    80003170:	41c080e7          	jalr	1052(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003174:	0000e497          	auipc	s1,0xe
    80003178:	5ec48493          	addi	s1,s1,1516 # 80011760 <proc+0x180>
    8000317c:	00015917          	auipc	s2,0x15
    80003180:	9e490913          	addi	s2,s2,-1564 # 80017b60 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003184:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80003186:	00005997          	auipc	s3,0x5
    8000318a:	25298993          	addi	s3,s3,594 # 800083d8 <digits+0x398>
    printf("%d %s %s", p->pid, state, p->name);
    8000318e:	00005a97          	auipc	s5,0x5
    80003192:	252a8a93          	addi	s5,s5,594 # 800083e0 <digits+0x3a0>
    printf("\n");
    80003196:	00005a17          	auipc	s4,0x5
    8000319a:	f32a0a13          	addi	s4,s4,-206 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000319e:	00005b97          	auipc	s7,0x5
    800031a2:	27ab8b93          	addi	s7,s7,634 # 80008418 <states.1908>
    800031a6:	a00d                	j	800031c8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800031a8:	ec86a583          	lw	a1,-312(a3)
    800031ac:	8556                	mv	a0,s5
    800031ae:	ffffd097          	auipc	ra,0xffffd
    800031b2:	3da080e7          	jalr	986(ra) # 80000588 <printf>
    printf("\n");
    800031b6:	8552                	mv	a0,s4
    800031b8:	ffffd097          	auipc	ra,0xffffd
    800031bc:	3d0080e7          	jalr	976(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800031c0:	19048493          	addi	s1,s1,400
    800031c4:	03248163          	beq	s1,s2,800031e6 <procdump+0x98>
    if(p->state == UNUSED)
    800031c8:	86a6                	mv	a3,s1
    800031ca:	eb04a783          	lw	a5,-336(s1)
    800031ce:	dbed                	beqz	a5,800031c0 <procdump+0x72>
      state = "???";
    800031d0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800031d2:	fcfb6be3          	bltu	s6,a5,800031a8 <procdump+0x5a>
    800031d6:	1782                	slli	a5,a5,0x20
    800031d8:	9381                	srli	a5,a5,0x20
    800031da:	078e                	slli	a5,a5,0x3
    800031dc:	97de                	add	a5,a5,s7
    800031de:	6390                	ld	a2,0(a5)
    800031e0:	f661                	bnez	a2,800031a8 <procdump+0x5a>
      state = "???";
    800031e2:	864e                	mv	a2,s3
    800031e4:	b7d1                	j	800031a8 <procdump+0x5a>
  }
}
    800031e6:	60a6                	ld	ra,72(sp)
    800031e8:	6406                	ld	s0,64(sp)
    800031ea:	74e2                	ld	s1,56(sp)
    800031ec:	7942                	ld	s2,48(sp)
    800031ee:	79a2                	ld	s3,40(sp)
    800031f0:	7a02                	ld	s4,32(sp)
    800031f2:	6ae2                	ld	s5,24(sp)
    800031f4:	6b42                	ld	s6,16(sp)
    800031f6:	6ba2                	ld	s7,8(sp)
    800031f8:	6161                	addi	sp,sp,80
    800031fa:	8082                	ret

00000000800031fc <swtch>:
    800031fc:	00153023          	sd	ra,0(a0)
    80003200:	00253423          	sd	sp,8(a0)
    80003204:	e900                	sd	s0,16(a0)
    80003206:	ed04                	sd	s1,24(a0)
    80003208:	03253023          	sd	s2,32(a0)
    8000320c:	03353423          	sd	s3,40(a0)
    80003210:	03453823          	sd	s4,48(a0)
    80003214:	03553c23          	sd	s5,56(a0)
    80003218:	05653023          	sd	s6,64(a0)
    8000321c:	05753423          	sd	s7,72(a0)
    80003220:	05853823          	sd	s8,80(a0)
    80003224:	05953c23          	sd	s9,88(a0)
    80003228:	07a53023          	sd	s10,96(a0)
    8000322c:	07b53423          	sd	s11,104(a0)
    80003230:	0005b083          	ld	ra,0(a1)
    80003234:	0085b103          	ld	sp,8(a1)
    80003238:	6980                	ld	s0,16(a1)
    8000323a:	6d84                	ld	s1,24(a1)
    8000323c:	0205b903          	ld	s2,32(a1)
    80003240:	0285b983          	ld	s3,40(a1)
    80003244:	0305ba03          	ld	s4,48(a1)
    80003248:	0385ba83          	ld	s5,56(a1)
    8000324c:	0405bb03          	ld	s6,64(a1)
    80003250:	0485bb83          	ld	s7,72(a1)
    80003254:	0505bc03          	ld	s8,80(a1)
    80003258:	0585bc83          	ld	s9,88(a1)
    8000325c:	0605bd03          	ld	s10,96(a1)
    80003260:	0685bd83          	ld	s11,104(a1)
    80003264:	8082                	ret

0000000080003266 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003266:	1141                	addi	sp,sp,-16
    80003268:	e406                	sd	ra,8(sp)
    8000326a:	e022                	sd	s0,0(sp)
    8000326c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000326e:	00005597          	auipc	a1,0x5
    80003272:	1da58593          	addi	a1,a1,474 # 80008448 <states.1908+0x30>
    80003276:	00014517          	auipc	a0,0x14
    8000327a:	76a50513          	addi	a0,a0,1898 # 800179e0 <tickslock>
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	8d6080e7          	jalr	-1834(ra) # 80000b54 <initlock>
}
    80003286:	60a2                	ld	ra,8(sp)
    80003288:	6402                	ld	s0,0(sp)
    8000328a:	0141                	addi	sp,sp,16
    8000328c:	8082                	ret

000000008000328e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000328e:	1141                	addi	sp,sp,-16
    80003290:	e422                	sd	s0,8(sp)
    80003292:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003294:	00003797          	auipc	a5,0x3
    80003298:	4cc78793          	addi	a5,a5,1228 # 80006760 <kernelvec>
    8000329c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800032a0:	6422                	ld	s0,8(sp)
    800032a2:	0141                	addi	sp,sp,16
    800032a4:	8082                	ret

00000000800032a6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800032a6:	1141                	addi	sp,sp,-16
    800032a8:	e406                	sd	ra,8(sp)
    800032aa:	e022                	sd	s0,0(sp)
    800032ac:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800032ae:	fffff097          	auipc	ra,0xfffff
    800032b2:	022080e7          	jalr	34(ra) # 800022d0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032b6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800032ba:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032bc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800032c0:	00004617          	auipc	a2,0x4
    800032c4:	d4060613          	addi	a2,a2,-704 # 80007000 <_trampoline>
    800032c8:	00004697          	auipc	a3,0x4
    800032cc:	d3868693          	addi	a3,a3,-712 # 80007000 <_trampoline>
    800032d0:	8e91                	sub	a3,a3,a2
    800032d2:	040007b7          	lui	a5,0x4000
    800032d6:	17fd                	addi	a5,a5,-1
    800032d8:	07b2                	slli	a5,a5,0xc
    800032da:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800032dc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800032e0:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800032e2:	180026f3          	csrr	a3,satp
    800032e6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800032e8:	6158                	ld	a4,128(a0)
    800032ea:	7534                	ld	a3,104(a0)
    800032ec:	6585                	lui	a1,0x1
    800032ee:	96ae                	add	a3,a3,a1
    800032f0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800032f2:	6158                	ld	a4,128(a0)
    800032f4:	00000697          	auipc	a3,0x0
    800032f8:	13868693          	addi	a3,a3,312 # 8000342c <usertrap>
    800032fc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800032fe:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003300:	8692                	mv	a3,tp
    80003302:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003304:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003308:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000330c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003310:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003314:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003316:	6f18                	ld	a4,24(a4)
    80003318:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000331c:	7d2c                	ld	a1,120(a0)
    8000331e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003320:	00004717          	auipc	a4,0x4
    80003324:	d7070713          	addi	a4,a4,-656 # 80007090 <userret>
    80003328:	8f11                	sub	a4,a4,a2
    8000332a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000332c:	577d                	li	a4,-1
    8000332e:	177e                	slli	a4,a4,0x3f
    80003330:	8dd9                	or	a1,a1,a4
    80003332:	02000537          	lui	a0,0x2000
    80003336:	157d                	addi	a0,a0,-1
    80003338:	0536                	slli	a0,a0,0xd
    8000333a:	9782                	jalr	a5
}
    8000333c:	60a2                	ld	ra,8(sp)
    8000333e:	6402                	ld	s0,0(sp)
    80003340:	0141                	addi	sp,sp,16
    80003342:	8082                	ret

0000000080003344 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003344:	1101                	addi	sp,sp,-32
    80003346:	ec06                	sd	ra,24(sp)
    80003348:	e822                	sd	s0,16(sp)
    8000334a:	e426                	sd	s1,8(sp)
    8000334c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000334e:	00014497          	auipc	s1,0x14
    80003352:	69248493          	addi	s1,s1,1682 # 800179e0 <tickslock>
    80003356:	8526                	mv	a0,s1
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	894080e7          	jalr	-1900(ra) # 80000bec <acquire>
  ticks++;
    80003360:	00006517          	auipc	a0,0x6
    80003364:	d1050513          	addi	a0,a0,-752 # 80009070 <ticks>
    80003368:	411c                	lw	a5,0(a0)
    8000336a:	2785                	addiw	a5,a5,1
    8000336c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	9c4080e7          	jalr	-1596(ra) # 80002d32 <wakeup>
  release(&tickslock);
    80003376:	8526                	mv	a0,s1
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	92e080e7          	jalr	-1746(ra) # 80000ca6 <release>
}
    80003380:	60e2                	ld	ra,24(sp)
    80003382:	6442                	ld	s0,16(sp)
    80003384:	64a2                	ld	s1,8(sp)
    80003386:	6105                	addi	sp,sp,32
    80003388:	8082                	ret

000000008000338a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000338a:	1101                	addi	sp,sp,-32
    8000338c:	ec06                	sd	ra,24(sp)
    8000338e:	e822                	sd	s0,16(sp)
    80003390:	e426                	sd	s1,8(sp)
    80003392:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003394:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003398:	00074d63          	bltz	a4,800033b2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000339c:	57fd                	li	a5,-1
    8000339e:	17fe                	slli	a5,a5,0x3f
    800033a0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800033a2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800033a4:	06f70363          	beq	a4,a5,8000340a <devintr+0x80>
  }
}
    800033a8:	60e2                	ld	ra,24(sp)
    800033aa:	6442                	ld	s0,16(sp)
    800033ac:	64a2                	ld	s1,8(sp)
    800033ae:	6105                	addi	sp,sp,32
    800033b0:	8082                	ret
     (scause & 0xff) == 9){
    800033b2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800033b6:	46a5                	li	a3,9
    800033b8:	fed792e3          	bne	a5,a3,8000339c <devintr+0x12>
    int irq = plic_claim();
    800033bc:	00003097          	auipc	ra,0x3
    800033c0:	4ac080e7          	jalr	1196(ra) # 80006868 <plic_claim>
    800033c4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800033c6:	47a9                	li	a5,10
    800033c8:	02f50763          	beq	a0,a5,800033f6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800033cc:	4785                	li	a5,1
    800033ce:	02f50963          	beq	a0,a5,80003400 <devintr+0x76>
    return 1;
    800033d2:	4505                	li	a0,1
    } else if(irq){
    800033d4:	d8f1                	beqz	s1,800033a8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800033d6:	85a6                	mv	a1,s1
    800033d8:	00005517          	auipc	a0,0x5
    800033dc:	07850513          	addi	a0,a0,120 # 80008450 <states.1908+0x38>
    800033e0:	ffffd097          	auipc	ra,0xffffd
    800033e4:	1a8080e7          	jalr	424(ra) # 80000588 <printf>
      plic_complete(irq);
    800033e8:	8526                	mv	a0,s1
    800033ea:	00003097          	auipc	ra,0x3
    800033ee:	4a2080e7          	jalr	1186(ra) # 8000688c <plic_complete>
    return 1;
    800033f2:	4505                	li	a0,1
    800033f4:	bf55                	j	800033a8 <devintr+0x1e>
      uartintr();
    800033f6:	ffffd097          	auipc	ra,0xffffd
    800033fa:	5b2080e7          	jalr	1458(ra) # 800009a8 <uartintr>
    800033fe:	b7ed                	j	800033e8 <devintr+0x5e>
      virtio_disk_intr();
    80003400:	00004097          	auipc	ra,0x4
    80003404:	96c080e7          	jalr	-1684(ra) # 80006d6c <virtio_disk_intr>
    80003408:	b7c5                	j	800033e8 <devintr+0x5e>
    if(cpuid() == 0){
    8000340a:	fffff097          	auipc	ra,0xfffff
    8000340e:	e92080e7          	jalr	-366(ra) # 8000229c <cpuid>
    80003412:	c901                	beqz	a0,80003422 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003414:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003418:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000341a:	14479073          	csrw	sip,a5
    return 2;
    8000341e:	4509                	li	a0,2
    80003420:	b761                	j	800033a8 <devintr+0x1e>
      clockintr();
    80003422:	00000097          	auipc	ra,0x0
    80003426:	f22080e7          	jalr	-222(ra) # 80003344 <clockintr>
    8000342a:	b7ed                	j	80003414 <devintr+0x8a>

000000008000342c <usertrap>:
{
    8000342c:	1101                	addi	sp,sp,-32
    8000342e:	ec06                	sd	ra,24(sp)
    80003430:	e822                	sd	s0,16(sp)
    80003432:	e426                	sd	s1,8(sp)
    80003434:	e04a                	sd	s2,0(sp)
    80003436:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003438:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000343c:	1007f793          	andi	a5,a5,256
    80003440:	e3ad                	bnez	a5,800034a2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003442:	00003797          	auipc	a5,0x3
    80003446:	31e78793          	addi	a5,a5,798 # 80006760 <kernelvec>
    8000344a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000344e:	fffff097          	auipc	ra,0xfffff
    80003452:	e82080e7          	jalr	-382(ra) # 800022d0 <myproc>
    80003456:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003458:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000345a:	14102773          	csrr	a4,sepc
    8000345e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003460:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003464:	47a1                	li	a5,8
    80003466:	04f71c63          	bne	a4,a5,800034be <usertrap+0x92>
    if(p->killed)
    8000346a:	413c                	lw	a5,64(a0)
    8000346c:	e3b9                	bnez	a5,800034b2 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000346e:	60d8                	ld	a4,128(s1)
    80003470:	6f1c                	ld	a5,24(a4)
    80003472:	0791                	addi	a5,a5,4
    80003474:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003476:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000347a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000347e:	10079073          	csrw	sstatus,a5
    syscall();
    80003482:	00000097          	auipc	ra,0x0
    80003486:	2e0080e7          	jalr	736(ra) # 80003762 <syscall>
  if(p->killed)
    8000348a:	40bc                	lw	a5,64(s1)
    8000348c:	ebc1                	bnez	a5,8000351c <usertrap+0xf0>
  usertrapret();
    8000348e:	00000097          	auipc	ra,0x0
    80003492:	e18080e7          	jalr	-488(ra) # 800032a6 <usertrapret>
}
    80003496:	60e2                	ld	ra,24(sp)
    80003498:	6442                	ld	s0,16(sp)
    8000349a:	64a2                	ld	s1,8(sp)
    8000349c:	6902                	ld	s2,0(sp)
    8000349e:	6105                	addi	sp,sp,32
    800034a0:	8082                	ret
    panic("usertrap: not from user mode");
    800034a2:	00005517          	auipc	a0,0x5
    800034a6:	fce50513          	addi	a0,a0,-50 # 80008470 <states.1908+0x58>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	094080e7          	jalr	148(ra) # 8000053e <panic>
      exit(-1);
    800034b2:	557d                	li	a0,-1
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	a68080e7          	jalr	-1432(ra) # 80002f1c <exit>
    800034bc:	bf4d                	j	8000346e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	ecc080e7          	jalr	-308(ra) # 8000338a <devintr>
    800034c6:	892a                	mv	s2,a0
    800034c8:	c501                	beqz	a0,800034d0 <usertrap+0xa4>
  if(p->killed)
    800034ca:	40bc                	lw	a5,64(s1)
    800034cc:	c3a1                	beqz	a5,8000350c <usertrap+0xe0>
    800034ce:	a815                	j	80003502 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800034d0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800034d4:	44b0                	lw	a2,72(s1)
    800034d6:	00005517          	auipc	a0,0x5
    800034da:	fba50513          	addi	a0,a0,-70 # 80008490 <states.1908+0x78>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	0aa080e7          	jalr	170(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034e6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800034ea:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800034ee:	00005517          	auipc	a0,0x5
    800034f2:	fd250513          	addi	a0,a0,-46 # 800084c0 <states.1908+0xa8>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	092080e7          	jalr	146(ra) # 80000588 <printf>
    p->killed = 1;
    800034fe:	4785                	li	a5,1
    80003500:	c0bc                	sw	a5,64(s1)
    exit(-1);
    80003502:	557d                	li	a0,-1
    80003504:	00000097          	auipc	ra,0x0
    80003508:	a18080e7          	jalr	-1512(ra) # 80002f1c <exit>
  if(which_dev == 2)
    8000350c:	4789                	li	a5,2
    8000350e:	f8f910e3          	bne	s2,a5,8000348e <usertrap+0x62>
    yield();
    80003512:	fffff097          	auipc	ra,0xfffff
    80003516:	5e2080e7          	jalr	1506(ra) # 80002af4 <yield>
    8000351a:	bf95                	j	8000348e <usertrap+0x62>
  int which_dev = 0;
    8000351c:	4901                	li	s2,0
    8000351e:	b7d5                	j	80003502 <usertrap+0xd6>

0000000080003520 <kerneltrap>:
{
    80003520:	7179                	addi	sp,sp,-48
    80003522:	f406                	sd	ra,40(sp)
    80003524:	f022                	sd	s0,32(sp)
    80003526:	ec26                	sd	s1,24(sp)
    80003528:	e84a                	sd	s2,16(sp)
    8000352a:	e44e                	sd	s3,8(sp)
    8000352c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000352e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003532:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003536:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000353a:	1004f793          	andi	a5,s1,256
    8000353e:	cb85                	beqz	a5,8000356e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003540:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003544:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003546:	ef85                	bnez	a5,8000357e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	e42080e7          	jalr	-446(ra) # 8000338a <devintr>
    80003550:	cd1d                	beqz	a0,8000358e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003552:	4789                	li	a5,2
    80003554:	06f50a63          	beq	a0,a5,800035c8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003558:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000355c:	10049073          	csrw	sstatus,s1
}
    80003560:	70a2                	ld	ra,40(sp)
    80003562:	7402                	ld	s0,32(sp)
    80003564:	64e2                	ld	s1,24(sp)
    80003566:	6942                	ld	s2,16(sp)
    80003568:	69a2                	ld	s3,8(sp)
    8000356a:	6145                	addi	sp,sp,48
    8000356c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000356e:	00005517          	auipc	a0,0x5
    80003572:	f7250513          	addi	a0,a0,-142 # 800084e0 <states.1908+0xc8>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	fc8080e7          	jalr	-56(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000357e:	00005517          	auipc	a0,0x5
    80003582:	f8a50513          	addi	a0,a0,-118 # 80008508 <states.1908+0xf0>
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	fb8080e7          	jalr	-72(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000358e:	85ce                	mv	a1,s3
    80003590:	00005517          	auipc	a0,0x5
    80003594:	f9850513          	addi	a0,a0,-104 # 80008528 <states.1908+0x110>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	ff0080e7          	jalr	-16(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800035a0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800035a4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800035a8:	00005517          	auipc	a0,0x5
    800035ac:	f9050513          	addi	a0,a0,-112 # 80008538 <states.1908+0x120>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	fd8080e7          	jalr	-40(ra) # 80000588 <printf>
    panic("kerneltrap");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	f9850513          	addi	a0,a0,-104 # 80008550 <states.1908+0x138>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	f7e080e7          	jalr	-130(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800035c8:	fffff097          	auipc	ra,0xfffff
    800035cc:	d08080e7          	jalr	-760(ra) # 800022d0 <myproc>
    800035d0:	d541                	beqz	a0,80003558 <kerneltrap+0x38>
    800035d2:	fffff097          	auipc	ra,0xfffff
    800035d6:	cfe080e7          	jalr	-770(ra) # 800022d0 <myproc>
    800035da:	5918                	lw	a4,48(a0)
    800035dc:	4791                	li	a5,4
    800035de:	f6f71de3          	bne	a4,a5,80003558 <kerneltrap+0x38>
    yield();
    800035e2:	fffff097          	auipc	ra,0xfffff
    800035e6:	512080e7          	jalr	1298(ra) # 80002af4 <yield>
    800035ea:	b7bd                	j	80003558 <kerneltrap+0x38>

00000000800035ec <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800035ec:	1101                	addi	sp,sp,-32
    800035ee:	ec06                	sd	ra,24(sp)
    800035f0:	e822                	sd	s0,16(sp)
    800035f2:	e426                	sd	s1,8(sp)
    800035f4:	1000                	addi	s0,sp,32
    800035f6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800035f8:	fffff097          	auipc	ra,0xfffff
    800035fc:	cd8080e7          	jalr	-808(ra) # 800022d0 <myproc>
  switch (n) {
    80003600:	4795                	li	a5,5
    80003602:	0497e163          	bltu	a5,s1,80003644 <argraw+0x58>
    80003606:	048a                	slli	s1,s1,0x2
    80003608:	00005717          	auipc	a4,0x5
    8000360c:	f8070713          	addi	a4,a4,-128 # 80008588 <states.1908+0x170>
    80003610:	94ba                	add	s1,s1,a4
    80003612:	409c                	lw	a5,0(s1)
    80003614:	97ba                	add	a5,a5,a4
    80003616:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003618:	615c                	ld	a5,128(a0)
    8000361a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000361c:	60e2                	ld	ra,24(sp)
    8000361e:	6442                	ld	s0,16(sp)
    80003620:	64a2                	ld	s1,8(sp)
    80003622:	6105                	addi	sp,sp,32
    80003624:	8082                	ret
    return p->trapframe->a1;
    80003626:	615c                	ld	a5,128(a0)
    80003628:	7fa8                	ld	a0,120(a5)
    8000362a:	bfcd                	j	8000361c <argraw+0x30>
    return p->trapframe->a2;
    8000362c:	615c                	ld	a5,128(a0)
    8000362e:	63c8                	ld	a0,128(a5)
    80003630:	b7f5                	j	8000361c <argraw+0x30>
    return p->trapframe->a3;
    80003632:	615c                	ld	a5,128(a0)
    80003634:	67c8                	ld	a0,136(a5)
    80003636:	b7dd                	j	8000361c <argraw+0x30>
    return p->trapframe->a4;
    80003638:	615c                	ld	a5,128(a0)
    8000363a:	6bc8                	ld	a0,144(a5)
    8000363c:	b7c5                	j	8000361c <argraw+0x30>
    return p->trapframe->a5;
    8000363e:	615c                	ld	a5,128(a0)
    80003640:	6fc8                	ld	a0,152(a5)
    80003642:	bfe9                	j	8000361c <argraw+0x30>
  panic("argraw");
    80003644:	00005517          	auipc	a0,0x5
    80003648:	f1c50513          	addi	a0,a0,-228 # 80008560 <states.1908+0x148>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	ef2080e7          	jalr	-270(ra) # 8000053e <panic>

0000000080003654 <fetchaddr>:
{
    80003654:	1101                	addi	sp,sp,-32
    80003656:	ec06                	sd	ra,24(sp)
    80003658:	e822                	sd	s0,16(sp)
    8000365a:	e426                	sd	s1,8(sp)
    8000365c:	e04a                	sd	s2,0(sp)
    8000365e:	1000                	addi	s0,sp,32
    80003660:	84aa                	mv	s1,a0
    80003662:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003664:	fffff097          	auipc	ra,0xfffff
    80003668:	c6c080e7          	jalr	-916(ra) # 800022d0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000366c:	793c                	ld	a5,112(a0)
    8000366e:	02f4f863          	bgeu	s1,a5,8000369e <fetchaddr+0x4a>
    80003672:	00848713          	addi	a4,s1,8
    80003676:	02e7e663          	bltu	a5,a4,800036a2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000367a:	46a1                	li	a3,8
    8000367c:	8626                	mv	a2,s1
    8000367e:	85ca                	mv	a1,s2
    80003680:	7d28                	ld	a0,120(a0)
    80003682:	ffffe097          	auipc	ra,0xffffe
    80003686:	08a080e7          	jalr	138(ra) # 8000170c <copyin>
    8000368a:	00a03533          	snez	a0,a0
    8000368e:	40a00533          	neg	a0,a0
}
    80003692:	60e2                	ld	ra,24(sp)
    80003694:	6442                	ld	s0,16(sp)
    80003696:	64a2                	ld	s1,8(sp)
    80003698:	6902                	ld	s2,0(sp)
    8000369a:	6105                	addi	sp,sp,32
    8000369c:	8082                	ret
    return -1;
    8000369e:	557d                	li	a0,-1
    800036a0:	bfcd                	j	80003692 <fetchaddr+0x3e>
    800036a2:	557d                	li	a0,-1
    800036a4:	b7fd                	j	80003692 <fetchaddr+0x3e>

00000000800036a6 <fetchstr>:
{
    800036a6:	7179                	addi	sp,sp,-48
    800036a8:	f406                	sd	ra,40(sp)
    800036aa:	f022                	sd	s0,32(sp)
    800036ac:	ec26                	sd	s1,24(sp)
    800036ae:	e84a                	sd	s2,16(sp)
    800036b0:	e44e                	sd	s3,8(sp)
    800036b2:	1800                	addi	s0,sp,48
    800036b4:	892a                	mv	s2,a0
    800036b6:	84ae                	mv	s1,a1
    800036b8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800036ba:	fffff097          	auipc	ra,0xfffff
    800036be:	c16080e7          	jalr	-1002(ra) # 800022d0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800036c2:	86ce                	mv	a3,s3
    800036c4:	864a                	mv	a2,s2
    800036c6:	85a6                	mv	a1,s1
    800036c8:	7d28                	ld	a0,120(a0)
    800036ca:	ffffe097          	auipc	ra,0xffffe
    800036ce:	0ce080e7          	jalr	206(ra) # 80001798 <copyinstr>
  if(err < 0)
    800036d2:	00054763          	bltz	a0,800036e0 <fetchstr+0x3a>
  return strlen(buf);
    800036d6:	8526                	mv	a0,s1
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	79a080e7          	jalr	1946(ra) # 80000e72 <strlen>
}
    800036e0:	70a2                	ld	ra,40(sp)
    800036e2:	7402                	ld	s0,32(sp)
    800036e4:	64e2                	ld	s1,24(sp)
    800036e6:	6942                	ld	s2,16(sp)
    800036e8:	69a2                	ld	s3,8(sp)
    800036ea:	6145                	addi	sp,sp,48
    800036ec:	8082                	ret

00000000800036ee <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800036ee:	1101                	addi	sp,sp,-32
    800036f0:	ec06                	sd	ra,24(sp)
    800036f2:	e822                	sd	s0,16(sp)
    800036f4:	e426                	sd	s1,8(sp)
    800036f6:	1000                	addi	s0,sp,32
    800036f8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	ef2080e7          	jalr	-270(ra) # 800035ec <argraw>
    80003702:	c088                	sw	a0,0(s1)
  return 0;
}
    80003704:	4501                	li	a0,0
    80003706:	60e2                	ld	ra,24(sp)
    80003708:	6442                	ld	s0,16(sp)
    8000370a:	64a2                	ld	s1,8(sp)
    8000370c:	6105                	addi	sp,sp,32
    8000370e:	8082                	ret

0000000080003710 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003710:	1101                	addi	sp,sp,-32
    80003712:	ec06                	sd	ra,24(sp)
    80003714:	e822                	sd	s0,16(sp)
    80003716:	e426                	sd	s1,8(sp)
    80003718:	1000                	addi	s0,sp,32
    8000371a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	ed0080e7          	jalr	-304(ra) # 800035ec <argraw>
    80003724:	e088                	sd	a0,0(s1)
  return 0;
}
    80003726:	4501                	li	a0,0
    80003728:	60e2                	ld	ra,24(sp)
    8000372a:	6442                	ld	s0,16(sp)
    8000372c:	64a2                	ld	s1,8(sp)
    8000372e:	6105                	addi	sp,sp,32
    80003730:	8082                	ret

0000000080003732 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003732:	1101                	addi	sp,sp,-32
    80003734:	ec06                	sd	ra,24(sp)
    80003736:	e822                	sd	s0,16(sp)
    80003738:	e426                	sd	s1,8(sp)
    8000373a:	e04a                	sd	s2,0(sp)
    8000373c:	1000                	addi	s0,sp,32
    8000373e:	84ae                	mv	s1,a1
    80003740:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003742:	00000097          	auipc	ra,0x0
    80003746:	eaa080e7          	jalr	-342(ra) # 800035ec <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000374a:	864a                	mv	a2,s2
    8000374c:	85a6                	mv	a1,s1
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	f58080e7          	jalr	-168(ra) # 800036a6 <fetchstr>
}
    80003756:	60e2                	ld	ra,24(sp)
    80003758:	6442                	ld	s0,16(sp)
    8000375a:	64a2                	ld	s1,8(sp)
    8000375c:	6902                	ld	s2,0(sp)
    8000375e:	6105                	addi	sp,sp,32
    80003760:	8082                	ret

0000000080003762 <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    80003762:	1101                	addi	sp,sp,-32
    80003764:	ec06                	sd	ra,24(sp)
    80003766:	e822                	sd	s0,16(sp)
    80003768:	e426                	sd	s1,8(sp)
    8000376a:	e04a                	sd	s2,0(sp)
    8000376c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000376e:	fffff097          	auipc	ra,0xfffff
    80003772:	b62080e7          	jalr	-1182(ra) # 800022d0 <myproc>
    80003776:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003778:	08053903          	ld	s2,128(a0)
    8000377c:	0a893783          	ld	a5,168(s2)
    80003780:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003784:	37fd                	addiw	a5,a5,-1
    80003786:	4759                	li	a4,22
    80003788:	00f76f63          	bltu	a4,a5,800037a6 <syscall+0x44>
    8000378c:	00369713          	slli	a4,a3,0x3
    80003790:	00005797          	auipc	a5,0x5
    80003794:	e1078793          	addi	a5,a5,-496 # 800085a0 <syscalls>
    80003798:	97ba                	add	a5,a5,a4
    8000379a:	639c                	ld	a5,0(a5)
    8000379c:	c789                	beqz	a5,800037a6 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000379e:	9782                	jalr	a5
    800037a0:	06a93823          	sd	a0,112(s2)
    800037a4:	a839                	j	800037c2 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800037a6:	18048613          	addi	a2,s1,384
    800037aa:	44ac                	lw	a1,72(s1)
    800037ac:	00005517          	auipc	a0,0x5
    800037b0:	dbc50513          	addi	a0,a0,-580 # 80008568 <states.1908+0x150>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	dd4080e7          	jalr	-556(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800037bc:	60dc                	ld	a5,128(s1)
    800037be:	577d                	li	a4,-1
    800037c0:	fbb8                	sd	a4,112(a5)
  }
}
    800037c2:	60e2                	ld	ra,24(sp)
    800037c4:	6442                	ld	s0,16(sp)
    800037c6:	64a2                	ld	s1,8(sp)
    800037c8:	6902                	ld	s2,0(sp)
    800037ca:	6105                	addi	sp,sp,32
    800037cc:	8082                	ret

00000000800037ce <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    800037ce:	1101                	addi	sp,sp,-32
    800037d0:	ec06                	sd	ra,24(sp)
    800037d2:	e822                	sd	s0,16(sp)
    800037d4:	1000                	addi	s0,sp,32
  int a;

  if(argint(0, &a) < 0)
    800037d6:	fec40593          	addi	a1,s0,-20
    800037da:	4501                	li	a0,0
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	f12080e7          	jalr	-238(ra) # 800036ee <argint>
    800037e4:	87aa                	mv	a5,a0
    return -1;
    800037e6:	557d                	li	a0,-1
  if(argint(0, &a) < 0)
    800037e8:	0007c863          	bltz	a5,800037f8 <sys_set_cpu+0x2a>
  return set_cpu(a);
    800037ec:	fec42503          	lw	a0,-20(s0)
    800037f0:	fffff097          	auipc	ra,0xfffff
    800037f4:	34e080e7          	jalr	846(ra) # 80002b3e <set_cpu>
}
    800037f8:	60e2                	ld	ra,24(sp)
    800037fa:	6442                	ld	s0,16(sp)
    800037fc:	6105                	addi	sp,sp,32
    800037fe:	8082                	ret

0000000080003800 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003800:	1141                	addi	sp,sp,-16
    80003802:	e406                	sd	ra,8(sp)
    80003804:	e022                	sd	s0,0(sp)
    80003806:	0800                	addi	s0,sp,16
  return get_cpu();
    80003808:	fffff097          	auipc	ra,0xfffff
    8000380c:	b08080e7          	jalr	-1272(ra) # 80002310 <get_cpu>
}
    80003810:	60a2                	ld	ra,8(sp)
    80003812:	6402                	ld	s0,0(sp)
    80003814:	0141                	addi	sp,sp,16
    80003816:	8082                	ret

0000000080003818 <sys_exit>:

uint64
sys_exit(void)
{
    80003818:	1101                	addi	sp,sp,-32
    8000381a:	ec06                	sd	ra,24(sp)
    8000381c:	e822                	sd	s0,16(sp)
    8000381e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003820:	fec40593          	addi	a1,s0,-20
    80003824:	4501                	li	a0,0
    80003826:	00000097          	auipc	ra,0x0
    8000382a:	ec8080e7          	jalr	-312(ra) # 800036ee <argint>
    return -1;
    8000382e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003830:	00054963          	bltz	a0,80003842 <sys_exit+0x2a>
  exit(n);
    80003834:	fec42503          	lw	a0,-20(s0)
    80003838:	fffff097          	auipc	ra,0xfffff
    8000383c:	6e4080e7          	jalr	1764(ra) # 80002f1c <exit>
  return 0;  // not reached
    80003840:	4781                	li	a5,0
}
    80003842:	853e                	mv	a0,a5
    80003844:	60e2                	ld	ra,24(sp)
    80003846:	6442                	ld	s0,16(sp)
    80003848:	6105                	addi	sp,sp,32
    8000384a:	8082                	ret

000000008000384c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000384c:	1141                	addi	sp,sp,-16
    8000384e:	e406                	sd	ra,8(sp)
    80003850:	e022                	sd	s0,0(sp)
    80003852:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003854:	fffff097          	auipc	ra,0xfffff
    80003858:	a7c080e7          	jalr	-1412(ra) # 800022d0 <myproc>
}
    8000385c:	4528                	lw	a0,72(a0)
    8000385e:	60a2                	ld	ra,8(sp)
    80003860:	6402                	ld	s0,0(sp)
    80003862:	0141                	addi	sp,sp,16
    80003864:	8082                	ret

0000000080003866 <sys_fork>:

uint64
sys_fork(void)
{
    80003866:	1141                	addi	sp,sp,-16
    80003868:	e406                	sd	ra,8(sp)
    8000386a:	e022                	sd	s0,0(sp)
    8000386c:	0800                	addi	s0,sp,16
  return fork();
    8000386e:	fffff097          	auipc	ra,0xfffff
    80003872:	ea4080e7          	jalr	-348(ra) # 80002712 <fork>
}
    80003876:	60a2                	ld	ra,8(sp)
    80003878:	6402                	ld	s0,0(sp)
    8000387a:	0141                	addi	sp,sp,16
    8000387c:	8082                	ret

000000008000387e <sys_wait>:

uint64
sys_wait(void)
{
    8000387e:	1101                	addi	sp,sp,-32
    80003880:	ec06                	sd	ra,24(sp)
    80003882:	e822                	sd	s0,16(sp)
    80003884:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003886:	fe840593          	addi	a1,s0,-24
    8000388a:	4501                	li	a0,0
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	e84080e7          	jalr	-380(ra) # 80003710 <argaddr>
    80003894:	87aa                	mv	a5,a0
    return -1;
    80003896:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003898:	0007c863          	bltz	a5,800038a8 <sys_wait+0x2a>
  return wait(p);
    8000389c:	fe843503          	ld	a0,-24(s0)
    800038a0:	fffff097          	auipc	ra,0xfffff
    800038a4:	36a080e7          	jalr	874(ra) # 80002c0a <wait>
}
    800038a8:	60e2                	ld	ra,24(sp)
    800038aa:	6442                	ld	s0,16(sp)
    800038ac:	6105                	addi	sp,sp,32
    800038ae:	8082                	ret

00000000800038b0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800038b0:	7179                	addi	sp,sp,-48
    800038b2:	f406                	sd	ra,40(sp)
    800038b4:	f022                	sd	s0,32(sp)
    800038b6:	ec26                	sd	s1,24(sp)
    800038b8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800038ba:	fdc40593          	addi	a1,s0,-36
    800038be:	4501                	li	a0,0
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	e2e080e7          	jalr	-466(ra) # 800036ee <argint>
    800038c8:	87aa                	mv	a5,a0
    return -1;
    800038ca:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800038cc:	0207c063          	bltz	a5,800038ec <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800038d0:	fffff097          	auipc	ra,0xfffff
    800038d4:	a00080e7          	jalr	-1536(ra) # 800022d0 <myproc>
    800038d8:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    800038da:	fdc42503          	lw	a0,-36(s0)
    800038de:	fffff097          	auipc	ra,0xfffff
    800038e2:	dc0080e7          	jalr	-576(ra) # 8000269e <growproc>
    800038e6:	00054863          	bltz	a0,800038f6 <sys_sbrk+0x46>
    return -1;
  return addr;
    800038ea:	8526                	mv	a0,s1
}
    800038ec:	70a2                	ld	ra,40(sp)
    800038ee:	7402                	ld	s0,32(sp)
    800038f0:	64e2                	ld	s1,24(sp)
    800038f2:	6145                	addi	sp,sp,48
    800038f4:	8082                	ret
    return -1;
    800038f6:	557d                	li	a0,-1
    800038f8:	bfd5                	j	800038ec <sys_sbrk+0x3c>

00000000800038fa <sys_sleep>:

uint64
sys_sleep(void)
{
    800038fa:	7139                	addi	sp,sp,-64
    800038fc:	fc06                	sd	ra,56(sp)
    800038fe:	f822                	sd	s0,48(sp)
    80003900:	f426                	sd	s1,40(sp)
    80003902:	f04a                	sd	s2,32(sp)
    80003904:	ec4e                	sd	s3,24(sp)
    80003906:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003908:	fcc40593          	addi	a1,s0,-52
    8000390c:	4501                	li	a0,0
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	de0080e7          	jalr	-544(ra) # 800036ee <argint>
    return -1;
    80003916:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003918:	06054563          	bltz	a0,80003982 <sys_sleep+0x88>
  acquire(&tickslock);
    8000391c:	00014517          	auipc	a0,0x14
    80003920:	0c450513          	addi	a0,a0,196 # 800179e0 <tickslock>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	2c8080e7          	jalr	712(ra) # 80000bec <acquire>
  ticks0 = ticks;
    8000392c:	00005917          	auipc	s2,0x5
    80003930:	74492903          	lw	s2,1860(s2) # 80009070 <ticks>
  while(ticks - ticks0 < n){
    80003934:	fcc42783          	lw	a5,-52(s0)
    80003938:	cf85                	beqz	a5,80003970 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000393a:	00014997          	auipc	s3,0x14
    8000393e:	0a698993          	addi	s3,s3,166 # 800179e0 <tickslock>
    80003942:	00005497          	auipc	s1,0x5
    80003946:	72e48493          	addi	s1,s1,1838 # 80009070 <ticks>
    if(myproc()->killed){
    8000394a:	fffff097          	auipc	ra,0xfffff
    8000394e:	986080e7          	jalr	-1658(ra) # 800022d0 <myproc>
    80003952:	413c                	lw	a5,64(a0)
    80003954:	ef9d                	bnez	a5,80003992 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003956:	85ce                	mv	a1,s3
    80003958:	8526                	mv	a0,s1
    8000395a:	fffff097          	auipc	ra,0xfffff
    8000395e:	234080e7          	jalr	564(ra) # 80002b8e <sleep>
  while(ticks - ticks0 < n){
    80003962:	409c                	lw	a5,0(s1)
    80003964:	412787bb          	subw	a5,a5,s2
    80003968:	fcc42703          	lw	a4,-52(s0)
    8000396c:	fce7efe3          	bltu	a5,a4,8000394a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003970:	00014517          	auipc	a0,0x14
    80003974:	07050513          	addi	a0,a0,112 # 800179e0 <tickslock>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	32e080e7          	jalr	814(ra) # 80000ca6 <release>
  return 0;
    80003980:	4781                	li	a5,0
}
    80003982:	853e                	mv	a0,a5
    80003984:	70e2                	ld	ra,56(sp)
    80003986:	7442                	ld	s0,48(sp)
    80003988:	74a2                	ld	s1,40(sp)
    8000398a:	7902                	ld	s2,32(sp)
    8000398c:	69e2                	ld	s3,24(sp)
    8000398e:	6121                	addi	sp,sp,64
    80003990:	8082                	ret
      release(&tickslock);
    80003992:	00014517          	auipc	a0,0x14
    80003996:	04e50513          	addi	a0,a0,78 # 800179e0 <tickslock>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	30c080e7          	jalr	780(ra) # 80000ca6 <release>
      return -1;
    800039a2:	57fd                	li	a5,-1
    800039a4:	bff9                	j	80003982 <sys_sleep+0x88>

00000000800039a6 <sys_kill>:

uint64
sys_kill(void)
{
    800039a6:	1101                	addi	sp,sp,-32
    800039a8:	ec06                	sd	ra,24(sp)
    800039aa:	e822                	sd	s0,16(sp)
    800039ac:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800039ae:	fec40593          	addi	a1,s0,-20
    800039b2:	4501                	li	a0,0
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	d3a080e7          	jalr	-710(ra) # 800036ee <argint>
    800039bc:	87aa                	mv	a5,a0
    return -1;
    800039be:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800039c0:	0007c863          	bltz	a5,800039d0 <sys_kill+0x2a>
  return kill(pid);
    800039c4:	fec42503          	lw	a0,-20(s0)
    800039c8:	fffff097          	auipc	ra,0xfffff
    800039cc:	644080e7          	jalr	1604(ra) # 8000300c <kill>
}
    800039d0:	60e2                	ld	ra,24(sp)
    800039d2:	6442                	ld	s0,16(sp)
    800039d4:	6105                	addi	sp,sp,32
    800039d6:	8082                	ret

00000000800039d8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800039d8:	1101                	addi	sp,sp,-32
    800039da:	ec06                	sd	ra,24(sp)
    800039dc:	e822                	sd	s0,16(sp)
    800039de:	e426                	sd	s1,8(sp)
    800039e0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800039e2:	00014517          	auipc	a0,0x14
    800039e6:	ffe50513          	addi	a0,a0,-2 # 800179e0 <tickslock>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	202080e7          	jalr	514(ra) # 80000bec <acquire>
  xticks = ticks;
    800039f2:	00005497          	auipc	s1,0x5
    800039f6:	67e4a483          	lw	s1,1662(s1) # 80009070 <ticks>
  release(&tickslock);
    800039fa:	00014517          	auipc	a0,0x14
    800039fe:	fe650513          	addi	a0,a0,-26 # 800179e0 <tickslock>
    80003a02:	ffffd097          	auipc	ra,0xffffd
    80003a06:	2a4080e7          	jalr	676(ra) # 80000ca6 <release>
  return xticks;
}
    80003a0a:	02049513          	slli	a0,s1,0x20
    80003a0e:	9101                	srli	a0,a0,0x20
    80003a10:	60e2                	ld	ra,24(sp)
    80003a12:	6442                	ld	s0,16(sp)
    80003a14:	64a2                	ld	s1,8(sp)
    80003a16:	6105                	addi	sp,sp,32
    80003a18:	8082                	ret

0000000080003a1a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a1a:	7179                	addi	sp,sp,-48
    80003a1c:	f406                	sd	ra,40(sp)
    80003a1e:	f022                	sd	s0,32(sp)
    80003a20:	ec26                	sd	s1,24(sp)
    80003a22:	e84a                	sd	s2,16(sp)
    80003a24:	e44e                	sd	s3,8(sp)
    80003a26:	e052                	sd	s4,0(sp)
    80003a28:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003a2a:	00005597          	auipc	a1,0x5
    80003a2e:	c3658593          	addi	a1,a1,-970 # 80008660 <syscalls+0xc0>
    80003a32:	00014517          	auipc	a0,0x14
    80003a36:	fc650513          	addi	a0,a0,-58 # 800179f8 <bcache>
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	11a080e7          	jalr	282(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003a42:	0001c797          	auipc	a5,0x1c
    80003a46:	fb678793          	addi	a5,a5,-74 # 8001f9f8 <bcache+0x8000>
    80003a4a:	0001c717          	auipc	a4,0x1c
    80003a4e:	21670713          	addi	a4,a4,534 # 8001fc60 <bcache+0x8268>
    80003a52:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003a56:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a5a:	00014497          	auipc	s1,0x14
    80003a5e:	fb648493          	addi	s1,s1,-74 # 80017a10 <bcache+0x18>
    b->next = bcache.head.next;
    80003a62:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003a64:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003a66:	00005a17          	auipc	s4,0x5
    80003a6a:	c02a0a13          	addi	s4,s4,-1022 # 80008668 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003a6e:	2b893783          	ld	a5,696(s2)
    80003a72:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003a74:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003a78:	85d2                	mv	a1,s4
    80003a7a:	01048513          	addi	a0,s1,16
    80003a7e:	00001097          	auipc	ra,0x1
    80003a82:	4bc080e7          	jalr	1212(ra) # 80004f3a <initsleeplock>
    bcache.head.next->prev = b;
    80003a86:	2b893783          	ld	a5,696(s2)
    80003a8a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003a8c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a90:	45848493          	addi	s1,s1,1112
    80003a94:	fd349de3          	bne	s1,s3,80003a6e <binit+0x54>
  }
}
    80003a98:	70a2                	ld	ra,40(sp)
    80003a9a:	7402                	ld	s0,32(sp)
    80003a9c:	64e2                	ld	s1,24(sp)
    80003a9e:	6942                	ld	s2,16(sp)
    80003aa0:	69a2                	ld	s3,8(sp)
    80003aa2:	6a02                	ld	s4,0(sp)
    80003aa4:	6145                	addi	sp,sp,48
    80003aa6:	8082                	ret

0000000080003aa8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003aa8:	7179                	addi	sp,sp,-48
    80003aaa:	f406                	sd	ra,40(sp)
    80003aac:	f022                	sd	s0,32(sp)
    80003aae:	ec26                	sd	s1,24(sp)
    80003ab0:	e84a                	sd	s2,16(sp)
    80003ab2:	e44e                	sd	s3,8(sp)
    80003ab4:	1800                	addi	s0,sp,48
    80003ab6:	89aa                	mv	s3,a0
    80003ab8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003aba:	00014517          	auipc	a0,0x14
    80003abe:	f3e50513          	addi	a0,a0,-194 # 800179f8 <bcache>
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	12a080e7          	jalr	298(ra) # 80000bec <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003aca:	0001c497          	auipc	s1,0x1c
    80003ace:	1e64b483          	ld	s1,486(s1) # 8001fcb0 <bcache+0x82b8>
    80003ad2:	0001c797          	auipc	a5,0x1c
    80003ad6:	18e78793          	addi	a5,a5,398 # 8001fc60 <bcache+0x8268>
    80003ada:	02f48f63          	beq	s1,a5,80003b18 <bread+0x70>
    80003ade:	873e                	mv	a4,a5
    80003ae0:	a021                	j	80003ae8 <bread+0x40>
    80003ae2:	68a4                	ld	s1,80(s1)
    80003ae4:	02e48a63          	beq	s1,a4,80003b18 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003ae8:	449c                	lw	a5,8(s1)
    80003aea:	ff379ce3          	bne	a5,s3,80003ae2 <bread+0x3a>
    80003aee:	44dc                	lw	a5,12(s1)
    80003af0:	ff2799e3          	bne	a5,s2,80003ae2 <bread+0x3a>
      b->refcnt++;
    80003af4:	40bc                	lw	a5,64(s1)
    80003af6:	2785                	addiw	a5,a5,1
    80003af8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003afa:	00014517          	auipc	a0,0x14
    80003afe:	efe50513          	addi	a0,a0,-258 # 800179f8 <bcache>
    80003b02:	ffffd097          	auipc	ra,0xffffd
    80003b06:	1a4080e7          	jalr	420(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003b0a:	01048513          	addi	a0,s1,16
    80003b0e:	00001097          	auipc	ra,0x1
    80003b12:	466080e7          	jalr	1126(ra) # 80004f74 <acquiresleep>
      return b;
    80003b16:	a8b9                	j	80003b74 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b18:	0001c497          	auipc	s1,0x1c
    80003b1c:	1904b483          	ld	s1,400(s1) # 8001fca8 <bcache+0x82b0>
    80003b20:	0001c797          	auipc	a5,0x1c
    80003b24:	14078793          	addi	a5,a5,320 # 8001fc60 <bcache+0x8268>
    80003b28:	00f48863          	beq	s1,a5,80003b38 <bread+0x90>
    80003b2c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003b2e:	40bc                	lw	a5,64(s1)
    80003b30:	cf81                	beqz	a5,80003b48 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b32:	64a4                	ld	s1,72(s1)
    80003b34:	fee49de3          	bne	s1,a4,80003b2e <bread+0x86>
  panic("bget: no buffers");
    80003b38:	00005517          	auipc	a0,0x5
    80003b3c:	b3850513          	addi	a0,a0,-1224 # 80008670 <syscalls+0xd0>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	9fe080e7          	jalr	-1538(ra) # 8000053e <panic>
      b->dev = dev;
    80003b48:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003b4c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003b50:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003b54:	4785                	li	a5,1
    80003b56:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b58:	00014517          	auipc	a0,0x14
    80003b5c:	ea050513          	addi	a0,a0,-352 # 800179f8 <bcache>
    80003b60:	ffffd097          	auipc	ra,0xffffd
    80003b64:	146080e7          	jalr	326(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003b68:	01048513          	addi	a0,s1,16
    80003b6c:	00001097          	auipc	ra,0x1
    80003b70:	408080e7          	jalr	1032(ra) # 80004f74 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003b74:	409c                	lw	a5,0(s1)
    80003b76:	cb89                	beqz	a5,80003b88 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003b78:	8526                	mv	a0,s1
    80003b7a:	70a2                	ld	ra,40(sp)
    80003b7c:	7402                	ld	s0,32(sp)
    80003b7e:	64e2                	ld	s1,24(sp)
    80003b80:	6942                	ld	s2,16(sp)
    80003b82:	69a2                	ld	s3,8(sp)
    80003b84:	6145                	addi	sp,sp,48
    80003b86:	8082                	ret
    virtio_disk_rw(b, 0);
    80003b88:	4581                	li	a1,0
    80003b8a:	8526                	mv	a0,s1
    80003b8c:	00003097          	auipc	ra,0x3
    80003b90:	f0a080e7          	jalr	-246(ra) # 80006a96 <virtio_disk_rw>
    b->valid = 1;
    80003b94:	4785                	li	a5,1
    80003b96:	c09c                	sw	a5,0(s1)
  return b;
    80003b98:	b7c5                	j	80003b78 <bread+0xd0>

0000000080003b9a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003b9a:	1101                	addi	sp,sp,-32
    80003b9c:	ec06                	sd	ra,24(sp)
    80003b9e:	e822                	sd	s0,16(sp)
    80003ba0:	e426                	sd	s1,8(sp)
    80003ba2:	1000                	addi	s0,sp,32
    80003ba4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003ba6:	0541                	addi	a0,a0,16
    80003ba8:	00001097          	auipc	ra,0x1
    80003bac:	466080e7          	jalr	1126(ra) # 8000500e <holdingsleep>
    80003bb0:	cd01                	beqz	a0,80003bc8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003bb2:	4585                	li	a1,1
    80003bb4:	8526                	mv	a0,s1
    80003bb6:	00003097          	auipc	ra,0x3
    80003bba:	ee0080e7          	jalr	-288(ra) # 80006a96 <virtio_disk_rw>
}
    80003bbe:	60e2                	ld	ra,24(sp)
    80003bc0:	6442                	ld	s0,16(sp)
    80003bc2:	64a2                	ld	s1,8(sp)
    80003bc4:	6105                	addi	sp,sp,32
    80003bc6:	8082                	ret
    panic("bwrite");
    80003bc8:	00005517          	auipc	a0,0x5
    80003bcc:	ac050513          	addi	a0,a0,-1344 # 80008688 <syscalls+0xe8>
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	96e080e7          	jalr	-1682(ra) # 8000053e <panic>

0000000080003bd8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003bd8:	1101                	addi	sp,sp,-32
    80003bda:	ec06                	sd	ra,24(sp)
    80003bdc:	e822                	sd	s0,16(sp)
    80003bde:	e426                	sd	s1,8(sp)
    80003be0:	e04a                	sd	s2,0(sp)
    80003be2:	1000                	addi	s0,sp,32
    80003be4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003be6:	01050913          	addi	s2,a0,16
    80003bea:	854a                	mv	a0,s2
    80003bec:	00001097          	auipc	ra,0x1
    80003bf0:	422080e7          	jalr	1058(ra) # 8000500e <holdingsleep>
    80003bf4:	c92d                	beqz	a0,80003c66 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003bf6:	854a                	mv	a0,s2
    80003bf8:	00001097          	auipc	ra,0x1
    80003bfc:	3d2080e7          	jalr	978(ra) # 80004fca <releasesleep>

  acquire(&bcache.lock);
    80003c00:	00014517          	auipc	a0,0x14
    80003c04:	df850513          	addi	a0,a0,-520 # 800179f8 <bcache>
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	fe4080e7          	jalr	-28(ra) # 80000bec <acquire>
  b->refcnt--;
    80003c10:	40bc                	lw	a5,64(s1)
    80003c12:	37fd                	addiw	a5,a5,-1
    80003c14:	0007871b          	sext.w	a4,a5
    80003c18:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c1a:	eb05                	bnez	a4,80003c4a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c1c:	68bc                	ld	a5,80(s1)
    80003c1e:	64b8                	ld	a4,72(s1)
    80003c20:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003c22:	64bc                	ld	a5,72(s1)
    80003c24:	68b8                	ld	a4,80(s1)
    80003c26:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003c28:	0001c797          	auipc	a5,0x1c
    80003c2c:	dd078793          	addi	a5,a5,-560 # 8001f9f8 <bcache+0x8000>
    80003c30:	2b87b703          	ld	a4,696(a5)
    80003c34:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003c36:	0001c717          	auipc	a4,0x1c
    80003c3a:	02a70713          	addi	a4,a4,42 # 8001fc60 <bcache+0x8268>
    80003c3e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003c40:	2b87b703          	ld	a4,696(a5)
    80003c44:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003c46:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003c4a:	00014517          	auipc	a0,0x14
    80003c4e:	dae50513          	addi	a0,a0,-594 # 800179f8 <bcache>
    80003c52:	ffffd097          	auipc	ra,0xffffd
    80003c56:	054080e7          	jalr	84(ra) # 80000ca6 <release>
}
    80003c5a:	60e2                	ld	ra,24(sp)
    80003c5c:	6442                	ld	s0,16(sp)
    80003c5e:	64a2                	ld	s1,8(sp)
    80003c60:	6902                	ld	s2,0(sp)
    80003c62:	6105                	addi	sp,sp,32
    80003c64:	8082                	ret
    panic("brelse");
    80003c66:	00005517          	auipc	a0,0x5
    80003c6a:	a2a50513          	addi	a0,a0,-1494 # 80008690 <syscalls+0xf0>
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	8d0080e7          	jalr	-1840(ra) # 8000053e <panic>

0000000080003c76 <bpin>:

void
bpin(struct buf *b) {
    80003c76:	1101                	addi	sp,sp,-32
    80003c78:	ec06                	sd	ra,24(sp)
    80003c7a:	e822                	sd	s0,16(sp)
    80003c7c:	e426                	sd	s1,8(sp)
    80003c7e:	1000                	addi	s0,sp,32
    80003c80:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c82:	00014517          	auipc	a0,0x14
    80003c86:	d7650513          	addi	a0,a0,-650 # 800179f8 <bcache>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	f62080e7          	jalr	-158(ra) # 80000bec <acquire>
  b->refcnt++;
    80003c92:	40bc                	lw	a5,64(s1)
    80003c94:	2785                	addiw	a5,a5,1
    80003c96:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c98:	00014517          	auipc	a0,0x14
    80003c9c:	d6050513          	addi	a0,a0,-672 # 800179f8 <bcache>
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	006080e7          	jalr	6(ra) # 80000ca6 <release>
}
    80003ca8:	60e2                	ld	ra,24(sp)
    80003caa:	6442                	ld	s0,16(sp)
    80003cac:	64a2                	ld	s1,8(sp)
    80003cae:	6105                	addi	sp,sp,32
    80003cb0:	8082                	ret

0000000080003cb2 <bunpin>:

void
bunpin(struct buf *b) {
    80003cb2:	1101                	addi	sp,sp,-32
    80003cb4:	ec06                	sd	ra,24(sp)
    80003cb6:	e822                	sd	s0,16(sp)
    80003cb8:	e426                	sd	s1,8(sp)
    80003cba:	1000                	addi	s0,sp,32
    80003cbc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003cbe:	00014517          	auipc	a0,0x14
    80003cc2:	d3a50513          	addi	a0,a0,-710 # 800179f8 <bcache>
    80003cc6:	ffffd097          	auipc	ra,0xffffd
    80003cca:	f26080e7          	jalr	-218(ra) # 80000bec <acquire>
  b->refcnt--;
    80003cce:	40bc                	lw	a5,64(s1)
    80003cd0:	37fd                	addiw	a5,a5,-1
    80003cd2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003cd4:	00014517          	auipc	a0,0x14
    80003cd8:	d2450513          	addi	a0,a0,-732 # 800179f8 <bcache>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	fca080e7          	jalr	-54(ra) # 80000ca6 <release>
}
    80003ce4:	60e2                	ld	ra,24(sp)
    80003ce6:	6442                	ld	s0,16(sp)
    80003ce8:	64a2                	ld	s1,8(sp)
    80003cea:	6105                	addi	sp,sp,32
    80003cec:	8082                	ret

0000000080003cee <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003cee:	1101                	addi	sp,sp,-32
    80003cf0:	ec06                	sd	ra,24(sp)
    80003cf2:	e822                	sd	s0,16(sp)
    80003cf4:	e426                	sd	s1,8(sp)
    80003cf6:	e04a                	sd	s2,0(sp)
    80003cf8:	1000                	addi	s0,sp,32
    80003cfa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003cfc:	00d5d59b          	srliw	a1,a1,0xd
    80003d00:	0001c797          	auipc	a5,0x1c
    80003d04:	3d47a783          	lw	a5,980(a5) # 800200d4 <sb+0x1c>
    80003d08:	9dbd                	addw	a1,a1,a5
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	d9e080e7          	jalr	-610(ra) # 80003aa8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d12:	0074f713          	andi	a4,s1,7
    80003d16:	4785                	li	a5,1
    80003d18:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d1c:	14ce                	slli	s1,s1,0x33
    80003d1e:	90d9                	srli	s1,s1,0x36
    80003d20:	00950733          	add	a4,a0,s1
    80003d24:	05874703          	lbu	a4,88(a4)
    80003d28:	00e7f6b3          	and	a3,a5,a4
    80003d2c:	c69d                	beqz	a3,80003d5a <bfree+0x6c>
    80003d2e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003d30:	94aa                	add	s1,s1,a0
    80003d32:	fff7c793          	not	a5,a5
    80003d36:	8ff9                	and	a5,a5,a4
    80003d38:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003d3c:	00001097          	auipc	ra,0x1
    80003d40:	118080e7          	jalr	280(ra) # 80004e54 <log_write>
  brelse(bp);
    80003d44:	854a                	mv	a0,s2
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	e92080e7          	jalr	-366(ra) # 80003bd8 <brelse>
}
    80003d4e:	60e2                	ld	ra,24(sp)
    80003d50:	6442                	ld	s0,16(sp)
    80003d52:	64a2                	ld	s1,8(sp)
    80003d54:	6902                	ld	s2,0(sp)
    80003d56:	6105                	addi	sp,sp,32
    80003d58:	8082                	ret
    panic("freeing free block");
    80003d5a:	00005517          	auipc	a0,0x5
    80003d5e:	93e50513          	addi	a0,a0,-1730 # 80008698 <syscalls+0xf8>
    80003d62:	ffffc097          	auipc	ra,0xffffc
    80003d66:	7dc080e7          	jalr	2012(ra) # 8000053e <panic>

0000000080003d6a <balloc>:
{
    80003d6a:	711d                	addi	sp,sp,-96
    80003d6c:	ec86                	sd	ra,88(sp)
    80003d6e:	e8a2                	sd	s0,80(sp)
    80003d70:	e4a6                	sd	s1,72(sp)
    80003d72:	e0ca                	sd	s2,64(sp)
    80003d74:	fc4e                	sd	s3,56(sp)
    80003d76:	f852                	sd	s4,48(sp)
    80003d78:	f456                	sd	s5,40(sp)
    80003d7a:	f05a                	sd	s6,32(sp)
    80003d7c:	ec5e                	sd	s7,24(sp)
    80003d7e:	e862                	sd	s8,16(sp)
    80003d80:	e466                	sd	s9,8(sp)
    80003d82:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003d84:	0001c797          	auipc	a5,0x1c
    80003d88:	3387a783          	lw	a5,824(a5) # 800200bc <sb+0x4>
    80003d8c:	cbd1                	beqz	a5,80003e20 <balloc+0xb6>
    80003d8e:	8baa                	mv	s7,a0
    80003d90:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003d92:	0001cb17          	auipc	s6,0x1c
    80003d96:	326b0b13          	addi	s6,s6,806 # 800200b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d9a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003d9c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d9e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003da0:	6c89                	lui	s9,0x2
    80003da2:	a831                	j	80003dbe <balloc+0x54>
    brelse(bp);
    80003da4:	854a                	mv	a0,s2
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	e32080e7          	jalr	-462(ra) # 80003bd8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003dae:	015c87bb          	addw	a5,s9,s5
    80003db2:	00078a9b          	sext.w	s5,a5
    80003db6:	004b2703          	lw	a4,4(s6)
    80003dba:	06eaf363          	bgeu	s5,a4,80003e20 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003dbe:	41fad79b          	sraiw	a5,s5,0x1f
    80003dc2:	0137d79b          	srliw	a5,a5,0x13
    80003dc6:	015787bb          	addw	a5,a5,s5
    80003dca:	40d7d79b          	sraiw	a5,a5,0xd
    80003dce:	01cb2583          	lw	a1,28(s6)
    80003dd2:	9dbd                	addw	a1,a1,a5
    80003dd4:	855e                	mv	a0,s7
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	cd2080e7          	jalr	-814(ra) # 80003aa8 <bread>
    80003dde:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003de0:	004b2503          	lw	a0,4(s6)
    80003de4:	000a849b          	sext.w	s1,s5
    80003de8:	8662                	mv	a2,s8
    80003dea:	faa4fde3          	bgeu	s1,a0,80003da4 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003dee:	41f6579b          	sraiw	a5,a2,0x1f
    80003df2:	01d7d69b          	srliw	a3,a5,0x1d
    80003df6:	00c6873b          	addw	a4,a3,a2
    80003dfa:	00777793          	andi	a5,a4,7
    80003dfe:	9f95                	subw	a5,a5,a3
    80003e00:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e04:	4037571b          	sraiw	a4,a4,0x3
    80003e08:	00e906b3          	add	a3,s2,a4
    80003e0c:	0586c683          	lbu	a3,88(a3)
    80003e10:	00d7f5b3          	and	a1,a5,a3
    80003e14:	cd91                	beqz	a1,80003e30 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e16:	2605                	addiw	a2,a2,1
    80003e18:	2485                	addiw	s1,s1,1
    80003e1a:	fd4618e3          	bne	a2,s4,80003dea <balloc+0x80>
    80003e1e:	b759                	j	80003da4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003e20:	00005517          	auipc	a0,0x5
    80003e24:	89050513          	addi	a0,a0,-1904 # 800086b0 <syscalls+0x110>
    80003e28:	ffffc097          	auipc	ra,0xffffc
    80003e2c:	716080e7          	jalr	1814(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e30:	974a                	add	a4,a4,s2
    80003e32:	8fd5                	or	a5,a5,a3
    80003e34:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e38:	854a                	mv	a0,s2
    80003e3a:	00001097          	auipc	ra,0x1
    80003e3e:	01a080e7          	jalr	26(ra) # 80004e54 <log_write>
        brelse(bp);
    80003e42:	854a                	mv	a0,s2
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	d94080e7          	jalr	-620(ra) # 80003bd8 <brelse>
  bp = bread(dev, bno);
    80003e4c:	85a6                	mv	a1,s1
    80003e4e:	855e                	mv	a0,s7
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	c58080e7          	jalr	-936(ra) # 80003aa8 <bread>
    80003e58:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e5a:	40000613          	li	a2,1024
    80003e5e:	4581                	li	a1,0
    80003e60:	05850513          	addi	a0,a0,88
    80003e64:	ffffd097          	auipc	ra,0xffffd
    80003e68:	e8a080e7          	jalr	-374(ra) # 80000cee <memset>
  log_write(bp);
    80003e6c:	854a                	mv	a0,s2
    80003e6e:	00001097          	auipc	ra,0x1
    80003e72:	fe6080e7          	jalr	-26(ra) # 80004e54 <log_write>
  brelse(bp);
    80003e76:	854a                	mv	a0,s2
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	d60080e7          	jalr	-672(ra) # 80003bd8 <brelse>
}
    80003e80:	8526                	mv	a0,s1
    80003e82:	60e6                	ld	ra,88(sp)
    80003e84:	6446                	ld	s0,80(sp)
    80003e86:	64a6                	ld	s1,72(sp)
    80003e88:	6906                	ld	s2,64(sp)
    80003e8a:	79e2                	ld	s3,56(sp)
    80003e8c:	7a42                	ld	s4,48(sp)
    80003e8e:	7aa2                	ld	s5,40(sp)
    80003e90:	7b02                	ld	s6,32(sp)
    80003e92:	6be2                	ld	s7,24(sp)
    80003e94:	6c42                	ld	s8,16(sp)
    80003e96:	6ca2                	ld	s9,8(sp)
    80003e98:	6125                	addi	sp,sp,96
    80003e9a:	8082                	ret

0000000080003e9c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003e9c:	7179                	addi	sp,sp,-48
    80003e9e:	f406                	sd	ra,40(sp)
    80003ea0:	f022                	sd	s0,32(sp)
    80003ea2:	ec26                	sd	s1,24(sp)
    80003ea4:	e84a                	sd	s2,16(sp)
    80003ea6:	e44e                	sd	s3,8(sp)
    80003ea8:	e052                	sd	s4,0(sp)
    80003eaa:	1800                	addi	s0,sp,48
    80003eac:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003eae:	47ad                	li	a5,11
    80003eb0:	04b7fe63          	bgeu	a5,a1,80003f0c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003eb4:	ff45849b          	addiw	s1,a1,-12
    80003eb8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ebc:	0ff00793          	li	a5,255
    80003ec0:	0ae7e363          	bltu	a5,a4,80003f66 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003ec4:	08052583          	lw	a1,128(a0)
    80003ec8:	c5ad                	beqz	a1,80003f32 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003eca:	00092503          	lw	a0,0(s2)
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	bda080e7          	jalr	-1062(ra) # 80003aa8 <bread>
    80003ed6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003ed8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003edc:	02049593          	slli	a1,s1,0x20
    80003ee0:	9181                	srli	a1,a1,0x20
    80003ee2:	058a                	slli	a1,a1,0x2
    80003ee4:	00b784b3          	add	s1,a5,a1
    80003ee8:	0004a983          	lw	s3,0(s1)
    80003eec:	04098d63          	beqz	s3,80003f46 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003ef0:	8552                	mv	a0,s4
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	ce6080e7          	jalr	-794(ra) # 80003bd8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003efa:	854e                	mv	a0,s3
    80003efc:	70a2                	ld	ra,40(sp)
    80003efe:	7402                	ld	s0,32(sp)
    80003f00:	64e2                	ld	s1,24(sp)
    80003f02:	6942                	ld	s2,16(sp)
    80003f04:	69a2                	ld	s3,8(sp)
    80003f06:	6a02                	ld	s4,0(sp)
    80003f08:	6145                	addi	sp,sp,48
    80003f0a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003f0c:	02059493          	slli	s1,a1,0x20
    80003f10:	9081                	srli	s1,s1,0x20
    80003f12:	048a                	slli	s1,s1,0x2
    80003f14:	94aa                	add	s1,s1,a0
    80003f16:	0504a983          	lw	s3,80(s1)
    80003f1a:	fe0990e3          	bnez	s3,80003efa <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003f1e:	4108                	lw	a0,0(a0)
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	e4a080e7          	jalr	-438(ra) # 80003d6a <balloc>
    80003f28:	0005099b          	sext.w	s3,a0
    80003f2c:	0534a823          	sw	s3,80(s1)
    80003f30:	b7e9                	j	80003efa <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003f32:	4108                	lw	a0,0(a0)
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	e36080e7          	jalr	-458(ra) # 80003d6a <balloc>
    80003f3c:	0005059b          	sext.w	a1,a0
    80003f40:	08b92023          	sw	a1,128(s2)
    80003f44:	b759                	j	80003eca <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003f46:	00092503          	lw	a0,0(s2)
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	e20080e7          	jalr	-480(ra) # 80003d6a <balloc>
    80003f52:	0005099b          	sext.w	s3,a0
    80003f56:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003f5a:	8552                	mv	a0,s4
    80003f5c:	00001097          	auipc	ra,0x1
    80003f60:	ef8080e7          	jalr	-264(ra) # 80004e54 <log_write>
    80003f64:	b771                	j	80003ef0 <bmap+0x54>
  panic("bmap: out of range");
    80003f66:	00004517          	auipc	a0,0x4
    80003f6a:	76250513          	addi	a0,a0,1890 # 800086c8 <syscalls+0x128>
    80003f6e:	ffffc097          	auipc	ra,0xffffc
    80003f72:	5d0080e7          	jalr	1488(ra) # 8000053e <panic>

0000000080003f76 <iget>:
{
    80003f76:	7179                	addi	sp,sp,-48
    80003f78:	f406                	sd	ra,40(sp)
    80003f7a:	f022                	sd	s0,32(sp)
    80003f7c:	ec26                	sd	s1,24(sp)
    80003f7e:	e84a                	sd	s2,16(sp)
    80003f80:	e44e                	sd	s3,8(sp)
    80003f82:	e052                	sd	s4,0(sp)
    80003f84:	1800                	addi	s0,sp,48
    80003f86:	89aa                	mv	s3,a0
    80003f88:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003f8a:	0001c517          	auipc	a0,0x1c
    80003f8e:	14e50513          	addi	a0,a0,334 # 800200d8 <itable>
    80003f92:	ffffd097          	auipc	ra,0xffffd
    80003f96:	c5a080e7          	jalr	-934(ra) # 80000bec <acquire>
  empty = 0;
    80003f9a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f9c:	0001c497          	auipc	s1,0x1c
    80003fa0:	15448493          	addi	s1,s1,340 # 800200f0 <itable+0x18>
    80003fa4:	0001e697          	auipc	a3,0x1e
    80003fa8:	bdc68693          	addi	a3,a3,-1060 # 80021b80 <log>
    80003fac:	a039                	j	80003fba <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fae:	02090b63          	beqz	s2,80003fe4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fb2:	08848493          	addi	s1,s1,136
    80003fb6:	02d48a63          	beq	s1,a3,80003fea <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003fba:	449c                	lw	a5,8(s1)
    80003fbc:	fef059e3          	blez	a5,80003fae <iget+0x38>
    80003fc0:	4098                	lw	a4,0(s1)
    80003fc2:	ff3716e3          	bne	a4,s3,80003fae <iget+0x38>
    80003fc6:	40d8                	lw	a4,4(s1)
    80003fc8:	ff4713e3          	bne	a4,s4,80003fae <iget+0x38>
      ip->ref++;
    80003fcc:	2785                	addiw	a5,a5,1
    80003fce:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003fd0:	0001c517          	auipc	a0,0x1c
    80003fd4:	10850513          	addi	a0,a0,264 # 800200d8 <itable>
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	cce080e7          	jalr	-818(ra) # 80000ca6 <release>
      return ip;
    80003fe0:	8926                	mv	s2,s1
    80003fe2:	a03d                	j	80004010 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fe4:	f7f9                	bnez	a5,80003fb2 <iget+0x3c>
    80003fe6:	8926                	mv	s2,s1
    80003fe8:	b7e9                	j	80003fb2 <iget+0x3c>
  if(empty == 0)
    80003fea:	02090c63          	beqz	s2,80004022 <iget+0xac>
  ip->dev = dev;
    80003fee:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ff2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ff6:	4785                	li	a5,1
    80003ff8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ffc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004000:	0001c517          	auipc	a0,0x1c
    80004004:	0d850513          	addi	a0,a0,216 # 800200d8 <itable>
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	c9e080e7          	jalr	-866(ra) # 80000ca6 <release>
}
    80004010:	854a                	mv	a0,s2
    80004012:	70a2                	ld	ra,40(sp)
    80004014:	7402                	ld	s0,32(sp)
    80004016:	64e2                	ld	s1,24(sp)
    80004018:	6942                	ld	s2,16(sp)
    8000401a:	69a2                	ld	s3,8(sp)
    8000401c:	6a02                	ld	s4,0(sp)
    8000401e:	6145                	addi	sp,sp,48
    80004020:	8082                	ret
    panic("iget: no inodes");
    80004022:	00004517          	auipc	a0,0x4
    80004026:	6be50513          	addi	a0,a0,1726 # 800086e0 <syscalls+0x140>
    8000402a:	ffffc097          	auipc	ra,0xffffc
    8000402e:	514080e7          	jalr	1300(ra) # 8000053e <panic>

0000000080004032 <fsinit>:
fsinit(int dev) {
    80004032:	7179                	addi	sp,sp,-48
    80004034:	f406                	sd	ra,40(sp)
    80004036:	f022                	sd	s0,32(sp)
    80004038:	ec26                	sd	s1,24(sp)
    8000403a:	e84a                	sd	s2,16(sp)
    8000403c:	e44e                	sd	s3,8(sp)
    8000403e:	1800                	addi	s0,sp,48
    80004040:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004042:	4585                	li	a1,1
    80004044:	00000097          	auipc	ra,0x0
    80004048:	a64080e7          	jalr	-1436(ra) # 80003aa8 <bread>
    8000404c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000404e:	0001c997          	auipc	s3,0x1c
    80004052:	06a98993          	addi	s3,s3,106 # 800200b8 <sb>
    80004056:	02000613          	li	a2,32
    8000405a:	05850593          	addi	a1,a0,88
    8000405e:	854e                	mv	a0,s3
    80004060:	ffffd097          	auipc	ra,0xffffd
    80004064:	cee080e7          	jalr	-786(ra) # 80000d4e <memmove>
  brelse(bp);
    80004068:	8526                	mv	a0,s1
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	b6e080e7          	jalr	-1170(ra) # 80003bd8 <brelse>
  if(sb.magic != FSMAGIC)
    80004072:	0009a703          	lw	a4,0(s3)
    80004076:	102037b7          	lui	a5,0x10203
    8000407a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000407e:	02f71263          	bne	a4,a5,800040a2 <fsinit+0x70>
  initlog(dev, &sb);
    80004082:	0001c597          	auipc	a1,0x1c
    80004086:	03658593          	addi	a1,a1,54 # 800200b8 <sb>
    8000408a:	854a                	mv	a0,s2
    8000408c:	00001097          	auipc	ra,0x1
    80004090:	b4c080e7          	jalr	-1204(ra) # 80004bd8 <initlog>
}
    80004094:	70a2                	ld	ra,40(sp)
    80004096:	7402                	ld	s0,32(sp)
    80004098:	64e2                	ld	s1,24(sp)
    8000409a:	6942                	ld	s2,16(sp)
    8000409c:	69a2                	ld	s3,8(sp)
    8000409e:	6145                	addi	sp,sp,48
    800040a0:	8082                	ret
    panic("invalid file system");
    800040a2:	00004517          	auipc	a0,0x4
    800040a6:	64e50513          	addi	a0,a0,1614 # 800086f0 <syscalls+0x150>
    800040aa:	ffffc097          	auipc	ra,0xffffc
    800040ae:	494080e7          	jalr	1172(ra) # 8000053e <panic>

00000000800040b2 <iinit>:
{
    800040b2:	7179                	addi	sp,sp,-48
    800040b4:	f406                	sd	ra,40(sp)
    800040b6:	f022                	sd	s0,32(sp)
    800040b8:	ec26                	sd	s1,24(sp)
    800040ba:	e84a                	sd	s2,16(sp)
    800040bc:	e44e                	sd	s3,8(sp)
    800040be:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800040c0:	00004597          	auipc	a1,0x4
    800040c4:	64858593          	addi	a1,a1,1608 # 80008708 <syscalls+0x168>
    800040c8:	0001c517          	auipc	a0,0x1c
    800040cc:	01050513          	addi	a0,a0,16 # 800200d8 <itable>
    800040d0:	ffffd097          	auipc	ra,0xffffd
    800040d4:	a84080e7          	jalr	-1404(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800040d8:	0001c497          	auipc	s1,0x1c
    800040dc:	02848493          	addi	s1,s1,40 # 80020100 <itable+0x28>
    800040e0:	0001e997          	auipc	s3,0x1e
    800040e4:	ab098993          	addi	s3,s3,-1360 # 80021b90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800040e8:	00004917          	auipc	s2,0x4
    800040ec:	62890913          	addi	s2,s2,1576 # 80008710 <syscalls+0x170>
    800040f0:	85ca                	mv	a1,s2
    800040f2:	8526                	mv	a0,s1
    800040f4:	00001097          	auipc	ra,0x1
    800040f8:	e46080e7          	jalr	-442(ra) # 80004f3a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800040fc:	08848493          	addi	s1,s1,136
    80004100:	ff3498e3          	bne	s1,s3,800040f0 <iinit+0x3e>
}
    80004104:	70a2                	ld	ra,40(sp)
    80004106:	7402                	ld	s0,32(sp)
    80004108:	64e2                	ld	s1,24(sp)
    8000410a:	6942                	ld	s2,16(sp)
    8000410c:	69a2                	ld	s3,8(sp)
    8000410e:	6145                	addi	sp,sp,48
    80004110:	8082                	ret

0000000080004112 <ialloc>:
{
    80004112:	715d                	addi	sp,sp,-80
    80004114:	e486                	sd	ra,72(sp)
    80004116:	e0a2                	sd	s0,64(sp)
    80004118:	fc26                	sd	s1,56(sp)
    8000411a:	f84a                	sd	s2,48(sp)
    8000411c:	f44e                	sd	s3,40(sp)
    8000411e:	f052                	sd	s4,32(sp)
    80004120:	ec56                	sd	s5,24(sp)
    80004122:	e85a                	sd	s6,16(sp)
    80004124:	e45e                	sd	s7,8(sp)
    80004126:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004128:	0001c717          	auipc	a4,0x1c
    8000412c:	f9c72703          	lw	a4,-100(a4) # 800200c4 <sb+0xc>
    80004130:	4785                	li	a5,1
    80004132:	04e7fa63          	bgeu	a5,a4,80004186 <ialloc+0x74>
    80004136:	8aaa                	mv	s5,a0
    80004138:	8bae                	mv	s7,a1
    8000413a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000413c:	0001ca17          	auipc	s4,0x1c
    80004140:	f7ca0a13          	addi	s4,s4,-132 # 800200b8 <sb>
    80004144:	00048b1b          	sext.w	s6,s1
    80004148:	0044d593          	srli	a1,s1,0x4
    8000414c:	018a2783          	lw	a5,24(s4)
    80004150:	9dbd                	addw	a1,a1,a5
    80004152:	8556                	mv	a0,s5
    80004154:	00000097          	auipc	ra,0x0
    80004158:	954080e7          	jalr	-1708(ra) # 80003aa8 <bread>
    8000415c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000415e:	05850993          	addi	s3,a0,88
    80004162:	00f4f793          	andi	a5,s1,15
    80004166:	079a                	slli	a5,a5,0x6
    80004168:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000416a:	00099783          	lh	a5,0(s3)
    8000416e:	c785                	beqz	a5,80004196 <ialloc+0x84>
    brelse(bp);
    80004170:	00000097          	auipc	ra,0x0
    80004174:	a68080e7          	jalr	-1432(ra) # 80003bd8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004178:	0485                	addi	s1,s1,1
    8000417a:	00ca2703          	lw	a4,12(s4)
    8000417e:	0004879b          	sext.w	a5,s1
    80004182:	fce7e1e3          	bltu	a5,a4,80004144 <ialloc+0x32>
  panic("ialloc: no inodes");
    80004186:	00004517          	auipc	a0,0x4
    8000418a:	59250513          	addi	a0,a0,1426 # 80008718 <syscalls+0x178>
    8000418e:	ffffc097          	auipc	ra,0xffffc
    80004192:	3b0080e7          	jalr	944(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80004196:	04000613          	li	a2,64
    8000419a:	4581                	li	a1,0
    8000419c:	854e                	mv	a0,s3
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	b50080e7          	jalr	-1200(ra) # 80000cee <memset>
      dip->type = type;
    800041a6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800041aa:	854a                	mv	a0,s2
    800041ac:	00001097          	auipc	ra,0x1
    800041b0:	ca8080e7          	jalr	-856(ra) # 80004e54 <log_write>
      brelse(bp);
    800041b4:	854a                	mv	a0,s2
    800041b6:	00000097          	auipc	ra,0x0
    800041ba:	a22080e7          	jalr	-1502(ra) # 80003bd8 <brelse>
      return iget(dev, inum);
    800041be:	85da                	mv	a1,s6
    800041c0:	8556                	mv	a0,s5
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	db4080e7          	jalr	-588(ra) # 80003f76 <iget>
}
    800041ca:	60a6                	ld	ra,72(sp)
    800041cc:	6406                	ld	s0,64(sp)
    800041ce:	74e2                	ld	s1,56(sp)
    800041d0:	7942                	ld	s2,48(sp)
    800041d2:	79a2                	ld	s3,40(sp)
    800041d4:	7a02                	ld	s4,32(sp)
    800041d6:	6ae2                	ld	s5,24(sp)
    800041d8:	6b42                	ld	s6,16(sp)
    800041da:	6ba2                	ld	s7,8(sp)
    800041dc:	6161                	addi	sp,sp,80
    800041de:	8082                	ret

00000000800041e0 <iupdate>:
{
    800041e0:	1101                	addi	sp,sp,-32
    800041e2:	ec06                	sd	ra,24(sp)
    800041e4:	e822                	sd	s0,16(sp)
    800041e6:	e426                	sd	s1,8(sp)
    800041e8:	e04a                	sd	s2,0(sp)
    800041ea:	1000                	addi	s0,sp,32
    800041ec:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800041ee:	415c                	lw	a5,4(a0)
    800041f0:	0047d79b          	srliw	a5,a5,0x4
    800041f4:	0001c597          	auipc	a1,0x1c
    800041f8:	edc5a583          	lw	a1,-292(a1) # 800200d0 <sb+0x18>
    800041fc:	9dbd                	addw	a1,a1,a5
    800041fe:	4108                	lw	a0,0(a0)
    80004200:	00000097          	auipc	ra,0x0
    80004204:	8a8080e7          	jalr	-1880(ra) # 80003aa8 <bread>
    80004208:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000420a:	05850793          	addi	a5,a0,88
    8000420e:	40c8                	lw	a0,4(s1)
    80004210:	893d                	andi	a0,a0,15
    80004212:	051a                	slli	a0,a0,0x6
    80004214:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004216:	04449703          	lh	a4,68(s1)
    8000421a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000421e:	04649703          	lh	a4,70(s1)
    80004222:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004226:	04849703          	lh	a4,72(s1)
    8000422a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000422e:	04a49703          	lh	a4,74(s1)
    80004232:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004236:	44f8                	lw	a4,76(s1)
    80004238:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000423a:	03400613          	li	a2,52
    8000423e:	05048593          	addi	a1,s1,80
    80004242:	0531                	addi	a0,a0,12
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	b0a080e7          	jalr	-1270(ra) # 80000d4e <memmove>
  log_write(bp);
    8000424c:	854a                	mv	a0,s2
    8000424e:	00001097          	auipc	ra,0x1
    80004252:	c06080e7          	jalr	-1018(ra) # 80004e54 <log_write>
  brelse(bp);
    80004256:	854a                	mv	a0,s2
    80004258:	00000097          	auipc	ra,0x0
    8000425c:	980080e7          	jalr	-1664(ra) # 80003bd8 <brelse>
}
    80004260:	60e2                	ld	ra,24(sp)
    80004262:	6442                	ld	s0,16(sp)
    80004264:	64a2                	ld	s1,8(sp)
    80004266:	6902                	ld	s2,0(sp)
    80004268:	6105                	addi	sp,sp,32
    8000426a:	8082                	ret

000000008000426c <idup>:
{
    8000426c:	1101                	addi	sp,sp,-32
    8000426e:	ec06                	sd	ra,24(sp)
    80004270:	e822                	sd	s0,16(sp)
    80004272:	e426                	sd	s1,8(sp)
    80004274:	1000                	addi	s0,sp,32
    80004276:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004278:	0001c517          	auipc	a0,0x1c
    8000427c:	e6050513          	addi	a0,a0,-416 # 800200d8 <itable>
    80004280:	ffffd097          	auipc	ra,0xffffd
    80004284:	96c080e7          	jalr	-1684(ra) # 80000bec <acquire>
  ip->ref++;
    80004288:	449c                	lw	a5,8(s1)
    8000428a:	2785                	addiw	a5,a5,1
    8000428c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000428e:	0001c517          	auipc	a0,0x1c
    80004292:	e4a50513          	addi	a0,a0,-438 # 800200d8 <itable>
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	a10080e7          	jalr	-1520(ra) # 80000ca6 <release>
}
    8000429e:	8526                	mv	a0,s1
    800042a0:	60e2                	ld	ra,24(sp)
    800042a2:	6442                	ld	s0,16(sp)
    800042a4:	64a2                	ld	s1,8(sp)
    800042a6:	6105                	addi	sp,sp,32
    800042a8:	8082                	ret

00000000800042aa <ilock>:
{
    800042aa:	1101                	addi	sp,sp,-32
    800042ac:	ec06                	sd	ra,24(sp)
    800042ae:	e822                	sd	s0,16(sp)
    800042b0:	e426                	sd	s1,8(sp)
    800042b2:	e04a                	sd	s2,0(sp)
    800042b4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800042b6:	c115                	beqz	a0,800042da <ilock+0x30>
    800042b8:	84aa                	mv	s1,a0
    800042ba:	451c                	lw	a5,8(a0)
    800042bc:	00f05f63          	blez	a5,800042da <ilock+0x30>
  acquiresleep(&ip->lock);
    800042c0:	0541                	addi	a0,a0,16
    800042c2:	00001097          	auipc	ra,0x1
    800042c6:	cb2080e7          	jalr	-846(ra) # 80004f74 <acquiresleep>
  if(ip->valid == 0){
    800042ca:	40bc                	lw	a5,64(s1)
    800042cc:	cf99                	beqz	a5,800042ea <ilock+0x40>
}
    800042ce:	60e2                	ld	ra,24(sp)
    800042d0:	6442                	ld	s0,16(sp)
    800042d2:	64a2                	ld	s1,8(sp)
    800042d4:	6902                	ld	s2,0(sp)
    800042d6:	6105                	addi	sp,sp,32
    800042d8:	8082                	ret
    panic("ilock");
    800042da:	00004517          	auipc	a0,0x4
    800042de:	45650513          	addi	a0,a0,1110 # 80008730 <syscalls+0x190>
    800042e2:	ffffc097          	auipc	ra,0xffffc
    800042e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042ea:	40dc                	lw	a5,4(s1)
    800042ec:	0047d79b          	srliw	a5,a5,0x4
    800042f0:	0001c597          	auipc	a1,0x1c
    800042f4:	de05a583          	lw	a1,-544(a1) # 800200d0 <sb+0x18>
    800042f8:	9dbd                	addw	a1,a1,a5
    800042fa:	4088                	lw	a0,0(s1)
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	7ac080e7          	jalr	1964(ra) # 80003aa8 <bread>
    80004304:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004306:	05850593          	addi	a1,a0,88
    8000430a:	40dc                	lw	a5,4(s1)
    8000430c:	8bbd                	andi	a5,a5,15
    8000430e:	079a                	slli	a5,a5,0x6
    80004310:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004312:	00059783          	lh	a5,0(a1)
    80004316:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000431a:	00259783          	lh	a5,2(a1)
    8000431e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004322:	00459783          	lh	a5,4(a1)
    80004326:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000432a:	00659783          	lh	a5,6(a1)
    8000432e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004332:	459c                	lw	a5,8(a1)
    80004334:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004336:	03400613          	li	a2,52
    8000433a:	05b1                	addi	a1,a1,12
    8000433c:	05048513          	addi	a0,s1,80
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	a0e080e7          	jalr	-1522(ra) # 80000d4e <memmove>
    brelse(bp);
    80004348:	854a                	mv	a0,s2
    8000434a:	00000097          	auipc	ra,0x0
    8000434e:	88e080e7          	jalr	-1906(ra) # 80003bd8 <brelse>
    ip->valid = 1;
    80004352:	4785                	li	a5,1
    80004354:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004356:	04449783          	lh	a5,68(s1)
    8000435a:	fbb5                	bnez	a5,800042ce <ilock+0x24>
      panic("ilock: no type");
    8000435c:	00004517          	auipc	a0,0x4
    80004360:	3dc50513          	addi	a0,a0,988 # 80008738 <syscalls+0x198>
    80004364:	ffffc097          	auipc	ra,0xffffc
    80004368:	1da080e7          	jalr	474(ra) # 8000053e <panic>

000000008000436c <iunlock>:
{
    8000436c:	1101                	addi	sp,sp,-32
    8000436e:	ec06                	sd	ra,24(sp)
    80004370:	e822                	sd	s0,16(sp)
    80004372:	e426                	sd	s1,8(sp)
    80004374:	e04a                	sd	s2,0(sp)
    80004376:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004378:	c905                	beqz	a0,800043a8 <iunlock+0x3c>
    8000437a:	84aa                	mv	s1,a0
    8000437c:	01050913          	addi	s2,a0,16
    80004380:	854a                	mv	a0,s2
    80004382:	00001097          	auipc	ra,0x1
    80004386:	c8c080e7          	jalr	-884(ra) # 8000500e <holdingsleep>
    8000438a:	cd19                	beqz	a0,800043a8 <iunlock+0x3c>
    8000438c:	449c                	lw	a5,8(s1)
    8000438e:	00f05d63          	blez	a5,800043a8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004392:	854a                	mv	a0,s2
    80004394:	00001097          	auipc	ra,0x1
    80004398:	c36080e7          	jalr	-970(ra) # 80004fca <releasesleep>
}
    8000439c:	60e2                	ld	ra,24(sp)
    8000439e:	6442                	ld	s0,16(sp)
    800043a0:	64a2                	ld	s1,8(sp)
    800043a2:	6902                	ld	s2,0(sp)
    800043a4:	6105                	addi	sp,sp,32
    800043a6:	8082                	ret
    panic("iunlock");
    800043a8:	00004517          	auipc	a0,0x4
    800043ac:	3a050513          	addi	a0,a0,928 # 80008748 <syscalls+0x1a8>
    800043b0:	ffffc097          	auipc	ra,0xffffc
    800043b4:	18e080e7          	jalr	398(ra) # 8000053e <panic>

00000000800043b8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800043b8:	7179                	addi	sp,sp,-48
    800043ba:	f406                	sd	ra,40(sp)
    800043bc:	f022                	sd	s0,32(sp)
    800043be:	ec26                	sd	s1,24(sp)
    800043c0:	e84a                	sd	s2,16(sp)
    800043c2:	e44e                	sd	s3,8(sp)
    800043c4:	e052                	sd	s4,0(sp)
    800043c6:	1800                	addi	s0,sp,48
    800043c8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800043ca:	05050493          	addi	s1,a0,80
    800043ce:	08050913          	addi	s2,a0,128
    800043d2:	a021                	j	800043da <itrunc+0x22>
    800043d4:	0491                	addi	s1,s1,4
    800043d6:	01248d63          	beq	s1,s2,800043f0 <itrunc+0x38>
    if(ip->addrs[i]){
    800043da:	408c                	lw	a1,0(s1)
    800043dc:	dde5                	beqz	a1,800043d4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800043de:	0009a503          	lw	a0,0(s3)
    800043e2:	00000097          	auipc	ra,0x0
    800043e6:	90c080e7          	jalr	-1780(ra) # 80003cee <bfree>
      ip->addrs[i] = 0;
    800043ea:	0004a023          	sw	zero,0(s1)
    800043ee:	b7dd                	j	800043d4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800043f0:	0809a583          	lw	a1,128(s3)
    800043f4:	e185                	bnez	a1,80004414 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800043f6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800043fa:	854e                	mv	a0,s3
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	de4080e7          	jalr	-540(ra) # 800041e0 <iupdate>
}
    80004404:	70a2                	ld	ra,40(sp)
    80004406:	7402                	ld	s0,32(sp)
    80004408:	64e2                	ld	s1,24(sp)
    8000440a:	6942                	ld	s2,16(sp)
    8000440c:	69a2                	ld	s3,8(sp)
    8000440e:	6a02                	ld	s4,0(sp)
    80004410:	6145                	addi	sp,sp,48
    80004412:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004414:	0009a503          	lw	a0,0(s3)
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	690080e7          	jalr	1680(ra) # 80003aa8 <bread>
    80004420:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004422:	05850493          	addi	s1,a0,88
    80004426:	45850913          	addi	s2,a0,1112
    8000442a:	a811                	j	8000443e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000442c:	0009a503          	lw	a0,0(s3)
    80004430:	00000097          	auipc	ra,0x0
    80004434:	8be080e7          	jalr	-1858(ra) # 80003cee <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004438:	0491                	addi	s1,s1,4
    8000443a:	01248563          	beq	s1,s2,80004444 <itrunc+0x8c>
      if(a[j])
    8000443e:	408c                	lw	a1,0(s1)
    80004440:	dde5                	beqz	a1,80004438 <itrunc+0x80>
    80004442:	b7ed                	j	8000442c <itrunc+0x74>
    brelse(bp);
    80004444:	8552                	mv	a0,s4
    80004446:	fffff097          	auipc	ra,0xfffff
    8000444a:	792080e7          	jalr	1938(ra) # 80003bd8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000444e:	0809a583          	lw	a1,128(s3)
    80004452:	0009a503          	lw	a0,0(s3)
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	898080e7          	jalr	-1896(ra) # 80003cee <bfree>
    ip->addrs[NDIRECT] = 0;
    8000445e:	0809a023          	sw	zero,128(s3)
    80004462:	bf51                	j	800043f6 <itrunc+0x3e>

0000000080004464 <iput>:
{
    80004464:	1101                	addi	sp,sp,-32
    80004466:	ec06                	sd	ra,24(sp)
    80004468:	e822                	sd	s0,16(sp)
    8000446a:	e426                	sd	s1,8(sp)
    8000446c:	e04a                	sd	s2,0(sp)
    8000446e:	1000                	addi	s0,sp,32
    80004470:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004472:	0001c517          	auipc	a0,0x1c
    80004476:	c6650513          	addi	a0,a0,-922 # 800200d8 <itable>
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	772080e7          	jalr	1906(ra) # 80000bec <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004482:	4498                	lw	a4,8(s1)
    80004484:	4785                	li	a5,1
    80004486:	02f70363          	beq	a4,a5,800044ac <iput+0x48>
  ip->ref--;
    8000448a:	449c                	lw	a5,8(s1)
    8000448c:	37fd                	addiw	a5,a5,-1
    8000448e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004490:	0001c517          	auipc	a0,0x1c
    80004494:	c4850513          	addi	a0,a0,-952 # 800200d8 <itable>
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	80e080e7          	jalr	-2034(ra) # 80000ca6 <release>
}
    800044a0:	60e2                	ld	ra,24(sp)
    800044a2:	6442                	ld	s0,16(sp)
    800044a4:	64a2                	ld	s1,8(sp)
    800044a6:	6902                	ld	s2,0(sp)
    800044a8:	6105                	addi	sp,sp,32
    800044aa:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044ac:	40bc                	lw	a5,64(s1)
    800044ae:	dff1                	beqz	a5,8000448a <iput+0x26>
    800044b0:	04a49783          	lh	a5,74(s1)
    800044b4:	fbf9                	bnez	a5,8000448a <iput+0x26>
    acquiresleep(&ip->lock);
    800044b6:	01048913          	addi	s2,s1,16
    800044ba:	854a                	mv	a0,s2
    800044bc:	00001097          	auipc	ra,0x1
    800044c0:	ab8080e7          	jalr	-1352(ra) # 80004f74 <acquiresleep>
    release(&itable.lock);
    800044c4:	0001c517          	auipc	a0,0x1c
    800044c8:	c1450513          	addi	a0,a0,-1004 # 800200d8 <itable>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	7da080e7          	jalr	2010(ra) # 80000ca6 <release>
    itrunc(ip);
    800044d4:	8526                	mv	a0,s1
    800044d6:	00000097          	auipc	ra,0x0
    800044da:	ee2080e7          	jalr	-286(ra) # 800043b8 <itrunc>
    ip->type = 0;
    800044de:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800044e2:	8526                	mv	a0,s1
    800044e4:	00000097          	auipc	ra,0x0
    800044e8:	cfc080e7          	jalr	-772(ra) # 800041e0 <iupdate>
    ip->valid = 0;
    800044ec:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800044f0:	854a                	mv	a0,s2
    800044f2:	00001097          	auipc	ra,0x1
    800044f6:	ad8080e7          	jalr	-1320(ra) # 80004fca <releasesleep>
    acquire(&itable.lock);
    800044fa:	0001c517          	auipc	a0,0x1c
    800044fe:	bde50513          	addi	a0,a0,-1058 # 800200d8 <itable>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	6ea080e7          	jalr	1770(ra) # 80000bec <acquire>
    8000450a:	b741                	j	8000448a <iput+0x26>

000000008000450c <iunlockput>:
{
    8000450c:	1101                	addi	sp,sp,-32
    8000450e:	ec06                	sd	ra,24(sp)
    80004510:	e822                	sd	s0,16(sp)
    80004512:	e426                	sd	s1,8(sp)
    80004514:	1000                	addi	s0,sp,32
    80004516:	84aa                	mv	s1,a0
  iunlock(ip);
    80004518:	00000097          	auipc	ra,0x0
    8000451c:	e54080e7          	jalr	-428(ra) # 8000436c <iunlock>
  iput(ip);
    80004520:	8526                	mv	a0,s1
    80004522:	00000097          	auipc	ra,0x0
    80004526:	f42080e7          	jalr	-190(ra) # 80004464 <iput>
}
    8000452a:	60e2                	ld	ra,24(sp)
    8000452c:	6442                	ld	s0,16(sp)
    8000452e:	64a2                	ld	s1,8(sp)
    80004530:	6105                	addi	sp,sp,32
    80004532:	8082                	ret

0000000080004534 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004534:	1141                	addi	sp,sp,-16
    80004536:	e422                	sd	s0,8(sp)
    80004538:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000453a:	411c                	lw	a5,0(a0)
    8000453c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000453e:	415c                	lw	a5,4(a0)
    80004540:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004542:	04451783          	lh	a5,68(a0)
    80004546:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000454a:	04a51783          	lh	a5,74(a0)
    8000454e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004552:	04c56783          	lwu	a5,76(a0)
    80004556:	e99c                	sd	a5,16(a1)
}
    80004558:	6422                	ld	s0,8(sp)
    8000455a:	0141                	addi	sp,sp,16
    8000455c:	8082                	ret

000000008000455e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000455e:	457c                	lw	a5,76(a0)
    80004560:	0ed7e963          	bltu	a5,a3,80004652 <readi+0xf4>
{
    80004564:	7159                	addi	sp,sp,-112
    80004566:	f486                	sd	ra,104(sp)
    80004568:	f0a2                	sd	s0,96(sp)
    8000456a:	eca6                	sd	s1,88(sp)
    8000456c:	e8ca                	sd	s2,80(sp)
    8000456e:	e4ce                	sd	s3,72(sp)
    80004570:	e0d2                	sd	s4,64(sp)
    80004572:	fc56                	sd	s5,56(sp)
    80004574:	f85a                	sd	s6,48(sp)
    80004576:	f45e                	sd	s7,40(sp)
    80004578:	f062                	sd	s8,32(sp)
    8000457a:	ec66                	sd	s9,24(sp)
    8000457c:	e86a                	sd	s10,16(sp)
    8000457e:	e46e                	sd	s11,8(sp)
    80004580:	1880                	addi	s0,sp,112
    80004582:	8baa                	mv	s7,a0
    80004584:	8c2e                	mv	s8,a1
    80004586:	8ab2                	mv	s5,a2
    80004588:	84b6                	mv	s1,a3
    8000458a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000458c:	9f35                	addw	a4,a4,a3
    return 0;
    8000458e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004590:	0ad76063          	bltu	a4,a3,80004630 <readi+0xd2>
  if(off + n > ip->size)
    80004594:	00e7f463          	bgeu	a5,a4,8000459c <readi+0x3e>
    n = ip->size - off;
    80004598:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000459c:	0a0b0963          	beqz	s6,8000464e <readi+0xf0>
    800045a0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800045a2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800045a6:	5cfd                	li	s9,-1
    800045a8:	a82d                	j	800045e2 <readi+0x84>
    800045aa:	020a1d93          	slli	s11,s4,0x20
    800045ae:	020ddd93          	srli	s11,s11,0x20
    800045b2:	05890613          	addi	a2,s2,88
    800045b6:	86ee                	mv	a3,s11
    800045b8:	963a                	add	a2,a2,a4
    800045ba:	85d6                	mv	a1,s5
    800045bc:	8562                	mv	a0,s8
    800045be:	fffff097          	auipc	ra,0xfffff
    800045c2:	ae4080e7          	jalr	-1308(ra) # 800030a2 <either_copyout>
    800045c6:	05950d63          	beq	a0,s9,80004620 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800045ca:	854a                	mv	a0,s2
    800045cc:	fffff097          	auipc	ra,0xfffff
    800045d0:	60c080e7          	jalr	1548(ra) # 80003bd8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045d4:	013a09bb          	addw	s3,s4,s3
    800045d8:	009a04bb          	addw	s1,s4,s1
    800045dc:	9aee                	add	s5,s5,s11
    800045de:	0569f763          	bgeu	s3,s6,8000462c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800045e2:	000ba903          	lw	s2,0(s7)
    800045e6:	00a4d59b          	srliw	a1,s1,0xa
    800045ea:	855e                	mv	a0,s7
    800045ec:	00000097          	auipc	ra,0x0
    800045f0:	8b0080e7          	jalr	-1872(ra) # 80003e9c <bmap>
    800045f4:	0005059b          	sext.w	a1,a0
    800045f8:	854a                	mv	a0,s2
    800045fa:	fffff097          	auipc	ra,0xfffff
    800045fe:	4ae080e7          	jalr	1198(ra) # 80003aa8 <bread>
    80004602:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004604:	3ff4f713          	andi	a4,s1,1023
    80004608:	40ed07bb          	subw	a5,s10,a4
    8000460c:	413b06bb          	subw	a3,s6,s3
    80004610:	8a3e                	mv	s4,a5
    80004612:	2781                	sext.w	a5,a5
    80004614:	0006861b          	sext.w	a2,a3
    80004618:	f8f679e3          	bgeu	a2,a5,800045aa <readi+0x4c>
    8000461c:	8a36                	mv	s4,a3
    8000461e:	b771                	j	800045aa <readi+0x4c>
      brelse(bp);
    80004620:	854a                	mv	a0,s2
    80004622:	fffff097          	auipc	ra,0xfffff
    80004626:	5b6080e7          	jalr	1462(ra) # 80003bd8 <brelse>
      tot = -1;
    8000462a:	59fd                	li	s3,-1
  }
  return tot;
    8000462c:	0009851b          	sext.w	a0,s3
}
    80004630:	70a6                	ld	ra,104(sp)
    80004632:	7406                	ld	s0,96(sp)
    80004634:	64e6                	ld	s1,88(sp)
    80004636:	6946                	ld	s2,80(sp)
    80004638:	69a6                	ld	s3,72(sp)
    8000463a:	6a06                	ld	s4,64(sp)
    8000463c:	7ae2                	ld	s5,56(sp)
    8000463e:	7b42                	ld	s6,48(sp)
    80004640:	7ba2                	ld	s7,40(sp)
    80004642:	7c02                	ld	s8,32(sp)
    80004644:	6ce2                	ld	s9,24(sp)
    80004646:	6d42                	ld	s10,16(sp)
    80004648:	6da2                	ld	s11,8(sp)
    8000464a:	6165                	addi	sp,sp,112
    8000464c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000464e:	89da                	mv	s3,s6
    80004650:	bff1                	j	8000462c <readi+0xce>
    return 0;
    80004652:	4501                	li	a0,0
}
    80004654:	8082                	ret

0000000080004656 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004656:	457c                	lw	a5,76(a0)
    80004658:	10d7e863          	bltu	a5,a3,80004768 <writei+0x112>
{
    8000465c:	7159                	addi	sp,sp,-112
    8000465e:	f486                	sd	ra,104(sp)
    80004660:	f0a2                	sd	s0,96(sp)
    80004662:	eca6                	sd	s1,88(sp)
    80004664:	e8ca                	sd	s2,80(sp)
    80004666:	e4ce                	sd	s3,72(sp)
    80004668:	e0d2                	sd	s4,64(sp)
    8000466a:	fc56                	sd	s5,56(sp)
    8000466c:	f85a                	sd	s6,48(sp)
    8000466e:	f45e                	sd	s7,40(sp)
    80004670:	f062                	sd	s8,32(sp)
    80004672:	ec66                	sd	s9,24(sp)
    80004674:	e86a                	sd	s10,16(sp)
    80004676:	e46e                	sd	s11,8(sp)
    80004678:	1880                	addi	s0,sp,112
    8000467a:	8b2a                	mv	s6,a0
    8000467c:	8c2e                	mv	s8,a1
    8000467e:	8ab2                	mv	s5,a2
    80004680:	8936                	mv	s2,a3
    80004682:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004684:	00e687bb          	addw	a5,a3,a4
    80004688:	0ed7e263          	bltu	a5,a3,8000476c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000468c:	00043737          	lui	a4,0x43
    80004690:	0ef76063          	bltu	a4,a5,80004770 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004694:	0c0b8863          	beqz	s7,80004764 <writei+0x10e>
    80004698:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000469a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000469e:	5cfd                	li	s9,-1
    800046a0:	a091                	j	800046e4 <writei+0x8e>
    800046a2:	02099d93          	slli	s11,s3,0x20
    800046a6:	020ddd93          	srli	s11,s11,0x20
    800046aa:	05848513          	addi	a0,s1,88
    800046ae:	86ee                	mv	a3,s11
    800046b0:	8656                	mv	a2,s5
    800046b2:	85e2                	mv	a1,s8
    800046b4:	953a                	add	a0,a0,a4
    800046b6:	fffff097          	auipc	ra,0xfffff
    800046ba:	a42080e7          	jalr	-1470(ra) # 800030f8 <either_copyin>
    800046be:	07950263          	beq	a0,s9,80004722 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800046c2:	8526                	mv	a0,s1
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	790080e7          	jalr	1936(ra) # 80004e54 <log_write>
    brelse(bp);
    800046cc:	8526                	mv	a0,s1
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	50a080e7          	jalr	1290(ra) # 80003bd8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046d6:	01498a3b          	addw	s4,s3,s4
    800046da:	0129893b          	addw	s2,s3,s2
    800046de:	9aee                	add	s5,s5,s11
    800046e0:	057a7663          	bgeu	s4,s7,8000472c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800046e4:	000b2483          	lw	s1,0(s6)
    800046e8:	00a9559b          	srliw	a1,s2,0xa
    800046ec:	855a                	mv	a0,s6
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	7ae080e7          	jalr	1966(ra) # 80003e9c <bmap>
    800046f6:	0005059b          	sext.w	a1,a0
    800046fa:	8526                	mv	a0,s1
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	3ac080e7          	jalr	940(ra) # 80003aa8 <bread>
    80004704:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004706:	3ff97713          	andi	a4,s2,1023
    8000470a:	40ed07bb          	subw	a5,s10,a4
    8000470e:	414b86bb          	subw	a3,s7,s4
    80004712:	89be                	mv	s3,a5
    80004714:	2781                	sext.w	a5,a5
    80004716:	0006861b          	sext.w	a2,a3
    8000471a:	f8f674e3          	bgeu	a2,a5,800046a2 <writei+0x4c>
    8000471e:	89b6                	mv	s3,a3
    80004720:	b749                	j	800046a2 <writei+0x4c>
      brelse(bp);
    80004722:	8526                	mv	a0,s1
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	4b4080e7          	jalr	1204(ra) # 80003bd8 <brelse>
  }

  if(off > ip->size)
    8000472c:	04cb2783          	lw	a5,76(s6)
    80004730:	0127f463          	bgeu	a5,s2,80004738 <writei+0xe2>
    ip->size = off;
    80004734:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004738:	855a                	mv	a0,s6
    8000473a:	00000097          	auipc	ra,0x0
    8000473e:	aa6080e7          	jalr	-1370(ra) # 800041e0 <iupdate>

  return tot;
    80004742:	000a051b          	sext.w	a0,s4
}
    80004746:	70a6                	ld	ra,104(sp)
    80004748:	7406                	ld	s0,96(sp)
    8000474a:	64e6                	ld	s1,88(sp)
    8000474c:	6946                	ld	s2,80(sp)
    8000474e:	69a6                	ld	s3,72(sp)
    80004750:	6a06                	ld	s4,64(sp)
    80004752:	7ae2                	ld	s5,56(sp)
    80004754:	7b42                	ld	s6,48(sp)
    80004756:	7ba2                	ld	s7,40(sp)
    80004758:	7c02                	ld	s8,32(sp)
    8000475a:	6ce2                	ld	s9,24(sp)
    8000475c:	6d42                	ld	s10,16(sp)
    8000475e:	6da2                	ld	s11,8(sp)
    80004760:	6165                	addi	sp,sp,112
    80004762:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004764:	8a5e                	mv	s4,s7
    80004766:	bfc9                	j	80004738 <writei+0xe2>
    return -1;
    80004768:	557d                	li	a0,-1
}
    8000476a:	8082                	ret
    return -1;
    8000476c:	557d                	li	a0,-1
    8000476e:	bfe1                	j	80004746 <writei+0xf0>
    return -1;
    80004770:	557d                	li	a0,-1
    80004772:	bfd1                	j	80004746 <writei+0xf0>

0000000080004774 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004774:	1141                	addi	sp,sp,-16
    80004776:	e406                	sd	ra,8(sp)
    80004778:	e022                	sd	s0,0(sp)
    8000477a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000477c:	4639                	li	a2,14
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	648080e7          	jalr	1608(ra) # 80000dc6 <strncmp>
}
    80004786:	60a2                	ld	ra,8(sp)
    80004788:	6402                	ld	s0,0(sp)
    8000478a:	0141                	addi	sp,sp,16
    8000478c:	8082                	ret

000000008000478e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000478e:	7139                	addi	sp,sp,-64
    80004790:	fc06                	sd	ra,56(sp)
    80004792:	f822                	sd	s0,48(sp)
    80004794:	f426                	sd	s1,40(sp)
    80004796:	f04a                	sd	s2,32(sp)
    80004798:	ec4e                	sd	s3,24(sp)
    8000479a:	e852                	sd	s4,16(sp)
    8000479c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000479e:	04451703          	lh	a4,68(a0)
    800047a2:	4785                	li	a5,1
    800047a4:	00f71a63          	bne	a4,a5,800047b8 <dirlookup+0x2a>
    800047a8:	892a                	mv	s2,a0
    800047aa:	89ae                	mv	s3,a1
    800047ac:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800047ae:	457c                	lw	a5,76(a0)
    800047b0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800047b2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047b4:	e79d                	bnez	a5,800047e2 <dirlookup+0x54>
    800047b6:	a8a5                	j	8000482e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800047b8:	00004517          	auipc	a0,0x4
    800047bc:	f9850513          	addi	a0,a0,-104 # 80008750 <syscalls+0x1b0>
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	d7e080e7          	jalr	-642(ra) # 8000053e <panic>
      panic("dirlookup read");
    800047c8:	00004517          	auipc	a0,0x4
    800047cc:	fa050513          	addi	a0,a0,-96 # 80008768 <syscalls+0x1c8>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	d6e080e7          	jalr	-658(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047d8:	24c1                	addiw	s1,s1,16
    800047da:	04c92783          	lw	a5,76(s2)
    800047de:	04f4f763          	bgeu	s1,a5,8000482c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047e2:	4741                	li	a4,16
    800047e4:	86a6                	mv	a3,s1
    800047e6:	fc040613          	addi	a2,s0,-64
    800047ea:	4581                	li	a1,0
    800047ec:	854a                	mv	a0,s2
    800047ee:	00000097          	auipc	ra,0x0
    800047f2:	d70080e7          	jalr	-656(ra) # 8000455e <readi>
    800047f6:	47c1                	li	a5,16
    800047f8:	fcf518e3          	bne	a0,a5,800047c8 <dirlookup+0x3a>
    if(de.inum == 0)
    800047fc:	fc045783          	lhu	a5,-64(s0)
    80004800:	dfe1                	beqz	a5,800047d8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004802:	fc240593          	addi	a1,s0,-62
    80004806:	854e                	mv	a0,s3
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	f6c080e7          	jalr	-148(ra) # 80004774 <namecmp>
    80004810:	f561                	bnez	a0,800047d8 <dirlookup+0x4a>
      if(poff)
    80004812:	000a0463          	beqz	s4,8000481a <dirlookup+0x8c>
        *poff = off;
    80004816:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000481a:	fc045583          	lhu	a1,-64(s0)
    8000481e:	00092503          	lw	a0,0(s2)
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	754080e7          	jalr	1876(ra) # 80003f76 <iget>
    8000482a:	a011                	j	8000482e <dirlookup+0xa0>
  return 0;
    8000482c:	4501                	li	a0,0
}
    8000482e:	70e2                	ld	ra,56(sp)
    80004830:	7442                	ld	s0,48(sp)
    80004832:	74a2                	ld	s1,40(sp)
    80004834:	7902                	ld	s2,32(sp)
    80004836:	69e2                	ld	s3,24(sp)
    80004838:	6a42                	ld	s4,16(sp)
    8000483a:	6121                	addi	sp,sp,64
    8000483c:	8082                	ret

000000008000483e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000483e:	711d                	addi	sp,sp,-96
    80004840:	ec86                	sd	ra,88(sp)
    80004842:	e8a2                	sd	s0,80(sp)
    80004844:	e4a6                	sd	s1,72(sp)
    80004846:	e0ca                	sd	s2,64(sp)
    80004848:	fc4e                	sd	s3,56(sp)
    8000484a:	f852                	sd	s4,48(sp)
    8000484c:	f456                	sd	s5,40(sp)
    8000484e:	f05a                	sd	s6,32(sp)
    80004850:	ec5e                	sd	s7,24(sp)
    80004852:	e862                	sd	s8,16(sp)
    80004854:	e466                	sd	s9,8(sp)
    80004856:	1080                	addi	s0,sp,96
    80004858:	84aa                	mv	s1,a0
    8000485a:	8b2e                	mv	s6,a1
    8000485c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000485e:	00054703          	lbu	a4,0(a0)
    80004862:	02f00793          	li	a5,47
    80004866:	02f70363          	beq	a4,a5,8000488c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000486a:	ffffe097          	auipc	ra,0xffffe
    8000486e:	a66080e7          	jalr	-1434(ra) # 800022d0 <myproc>
    80004872:	17853503          	ld	a0,376(a0)
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	9f6080e7          	jalr	-1546(ra) # 8000426c <idup>
    8000487e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004880:	02f00913          	li	s2,47
  len = path - s;
    80004884:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004886:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004888:	4c05                	li	s8,1
    8000488a:	a865                	j	80004942 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000488c:	4585                	li	a1,1
    8000488e:	4505                	li	a0,1
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	6e6080e7          	jalr	1766(ra) # 80003f76 <iget>
    80004898:	89aa                	mv	s3,a0
    8000489a:	b7dd                	j	80004880 <namex+0x42>
      iunlockput(ip);
    8000489c:	854e                	mv	a0,s3
    8000489e:	00000097          	auipc	ra,0x0
    800048a2:	c6e080e7          	jalr	-914(ra) # 8000450c <iunlockput>
      return 0;
    800048a6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800048a8:	854e                	mv	a0,s3
    800048aa:	60e6                	ld	ra,88(sp)
    800048ac:	6446                	ld	s0,80(sp)
    800048ae:	64a6                	ld	s1,72(sp)
    800048b0:	6906                	ld	s2,64(sp)
    800048b2:	79e2                	ld	s3,56(sp)
    800048b4:	7a42                	ld	s4,48(sp)
    800048b6:	7aa2                	ld	s5,40(sp)
    800048b8:	7b02                	ld	s6,32(sp)
    800048ba:	6be2                	ld	s7,24(sp)
    800048bc:	6c42                	ld	s8,16(sp)
    800048be:	6ca2                	ld	s9,8(sp)
    800048c0:	6125                	addi	sp,sp,96
    800048c2:	8082                	ret
      iunlock(ip);
    800048c4:	854e                	mv	a0,s3
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	aa6080e7          	jalr	-1370(ra) # 8000436c <iunlock>
      return ip;
    800048ce:	bfe9                	j	800048a8 <namex+0x6a>
      iunlockput(ip);
    800048d0:	854e                	mv	a0,s3
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	c3a080e7          	jalr	-966(ra) # 8000450c <iunlockput>
      return 0;
    800048da:	89d2                	mv	s3,s4
    800048dc:	b7f1                	j	800048a8 <namex+0x6a>
  len = path - s;
    800048de:	40b48633          	sub	a2,s1,a1
    800048e2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800048e6:	094cd463          	bge	s9,s4,8000496e <namex+0x130>
    memmove(name, s, DIRSIZ);
    800048ea:	4639                	li	a2,14
    800048ec:	8556                	mv	a0,s5
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	460080e7          	jalr	1120(ra) # 80000d4e <memmove>
  while(*path == '/')
    800048f6:	0004c783          	lbu	a5,0(s1)
    800048fa:	01279763          	bne	a5,s2,80004908 <namex+0xca>
    path++;
    800048fe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004900:	0004c783          	lbu	a5,0(s1)
    80004904:	ff278de3          	beq	a5,s2,800048fe <namex+0xc0>
    ilock(ip);
    80004908:	854e                	mv	a0,s3
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	9a0080e7          	jalr	-1632(ra) # 800042aa <ilock>
    if(ip->type != T_DIR){
    80004912:	04499783          	lh	a5,68(s3)
    80004916:	f98793e3          	bne	a5,s8,8000489c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000491a:	000b0563          	beqz	s6,80004924 <namex+0xe6>
    8000491e:	0004c783          	lbu	a5,0(s1)
    80004922:	d3cd                	beqz	a5,800048c4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004924:	865e                	mv	a2,s7
    80004926:	85d6                	mv	a1,s5
    80004928:	854e                	mv	a0,s3
    8000492a:	00000097          	auipc	ra,0x0
    8000492e:	e64080e7          	jalr	-412(ra) # 8000478e <dirlookup>
    80004932:	8a2a                	mv	s4,a0
    80004934:	dd51                	beqz	a0,800048d0 <namex+0x92>
    iunlockput(ip);
    80004936:	854e                	mv	a0,s3
    80004938:	00000097          	auipc	ra,0x0
    8000493c:	bd4080e7          	jalr	-1068(ra) # 8000450c <iunlockput>
    ip = next;
    80004940:	89d2                	mv	s3,s4
  while(*path == '/')
    80004942:	0004c783          	lbu	a5,0(s1)
    80004946:	05279763          	bne	a5,s2,80004994 <namex+0x156>
    path++;
    8000494a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000494c:	0004c783          	lbu	a5,0(s1)
    80004950:	ff278de3          	beq	a5,s2,8000494a <namex+0x10c>
  if(*path == 0)
    80004954:	c79d                	beqz	a5,80004982 <namex+0x144>
    path++;
    80004956:	85a6                	mv	a1,s1
  len = path - s;
    80004958:	8a5e                	mv	s4,s7
    8000495a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000495c:	01278963          	beq	a5,s2,8000496e <namex+0x130>
    80004960:	dfbd                	beqz	a5,800048de <namex+0xa0>
    path++;
    80004962:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004964:	0004c783          	lbu	a5,0(s1)
    80004968:	ff279ce3          	bne	a5,s2,80004960 <namex+0x122>
    8000496c:	bf8d                	j	800048de <namex+0xa0>
    memmove(name, s, len);
    8000496e:	2601                	sext.w	a2,a2
    80004970:	8556                	mv	a0,s5
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	3dc080e7          	jalr	988(ra) # 80000d4e <memmove>
    name[len] = 0;
    8000497a:	9a56                	add	s4,s4,s5
    8000497c:	000a0023          	sb	zero,0(s4)
    80004980:	bf9d                	j	800048f6 <namex+0xb8>
  if(nameiparent){
    80004982:	f20b03e3          	beqz	s6,800048a8 <namex+0x6a>
    iput(ip);
    80004986:	854e                	mv	a0,s3
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	adc080e7          	jalr	-1316(ra) # 80004464 <iput>
    return 0;
    80004990:	4981                	li	s3,0
    80004992:	bf19                	j	800048a8 <namex+0x6a>
  if(*path == 0)
    80004994:	d7fd                	beqz	a5,80004982 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004996:	0004c783          	lbu	a5,0(s1)
    8000499a:	85a6                	mv	a1,s1
    8000499c:	b7d1                	j	80004960 <namex+0x122>

000000008000499e <dirlink>:
{
    8000499e:	7139                	addi	sp,sp,-64
    800049a0:	fc06                	sd	ra,56(sp)
    800049a2:	f822                	sd	s0,48(sp)
    800049a4:	f426                	sd	s1,40(sp)
    800049a6:	f04a                	sd	s2,32(sp)
    800049a8:	ec4e                	sd	s3,24(sp)
    800049aa:	e852                	sd	s4,16(sp)
    800049ac:	0080                	addi	s0,sp,64
    800049ae:	892a                	mv	s2,a0
    800049b0:	8a2e                	mv	s4,a1
    800049b2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800049b4:	4601                	li	a2,0
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	dd8080e7          	jalr	-552(ra) # 8000478e <dirlookup>
    800049be:	e93d                	bnez	a0,80004a34 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049c0:	04c92483          	lw	s1,76(s2)
    800049c4:	c49d                	beqz	s1,800049f2 <dirlink+0x54>
    800049c6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049c8:	4741                	li	a4,16
    800049ca:	86a6                	mv	a3,s1
    800049cc:	fc040613          	addi	a2,s0,-64
    800049d0:	4581                	li	a1,0
    800049d2:	854a                	mv	a0,s2
    800049d4:	00000097          	auipc	ra,0x0
    800049d8:	b8a080e7          	jalr	-1142(ra) # 8000455e <readi>
    800049dc:	47c1                	li	a5,16
    800049de:	06f51163          	bne	a0,a5,80004a40 <dirlink+0xa2>
    if(de.inum == 0)
    800049e2:	fc045783          	lhu	a5,-64(s0)
    800049e6:	c791                	beqz	a5,800049f2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049e8:	24c1                	addiw	s1,s1,16
    800049ea:	04c92783          	lw	a5,76(s2)
    800049ee:	fcf4ede3          	bltu	s1,a5,800049c8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800049f2:	4639                	li	a2,14
    800049f4:	85d2                	mv	a1,s4
    800049f6:	fc240513          	addi	a0,s0,-62
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	408080e7          	jalr	1032(ra) # 80000e02 <strncpy>
  de.inum = inum;
    80004a02:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a06:	4741                	li	a4,16
    80004a08:	86a6                	mv	a3,s1
    80004a0a:	fc040613          	addi	a2,s0,-64
    80004a0e:	4581                	li	a1,0
    80004a10:	854a                	mv	a0,s2
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	c44080e7          	jalr	-956(ra) # 80004656 <writei>
    80004a1a:	872a                	mv	a4,a0
    80004a1c:	47c1                	li	a5,16
  return 0;
    80004a1e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a20:	02f71863          	bne	a4,a5,80004a50 <dirlink+0xb2>
}
    80004a24:	70e2                	ld	ra,56(sp)
    80004a26:	7442                	ld	s0,48(sp)
    80004a28:	74a2                	ld	s1,40(sp)
    80004a2a:	7902                	ld	s2,32(sp)
    80004a2c:	69e2                	ld	s3,24(sp)
    80004a2e:	6a42                	ld	s4,16(sp)
    80004a30:	6121                	addi	sp,sp,64
    80004a32:	8082                	ret
    iput(ip);
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	a30080e7          	jalr	-1488(ra) # 80004464 <iput>
    return -1;
    80004a3c:	557d                	li	a0,-1
    80004a3e:	b7dd                	j	80004a24 <dirlink+0x86>
      panic("dirlink read");
    80004a40:	00004517          	auipc	a0,0x4
    80004a44:	d3850513          	addi	a0,a0,-712 # 80008778 <syscalls+0x1d8>
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	af6080e7          	jalr	-1290(ra) # 8000053e <panic>
    panic("dirlink");
    80004a50:	00004517          	auipc	a0,0x4
    80004a54:	e3850513          	addi	a0,a0,-456 # 80008888 <syscalls+0x2e8>
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080004a60 <namei>:

struct inode*
namei(char *path)
{
    80004a60:	1101                	addi	sp,sp,-32
    80004a62:	ec06                	sd	ra,24(sp)
    80004a64:	e822                	sd	s0,16(sp)
    80004a66:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004a68:	fe040613          	addi	a2,s0,-32
    80004a6c:	4581                	li	a1,0
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	dd0080e7          	jalr	-560(ra) # 8000483e <namex>
}
    80004a76:	60e2                	ld	ra,24(sp)
    80004a78:	6442                	ld	s0,16(sp)
    80004a7a:	6105                	addi	sp,sp,32
    80004a7c:	8082                	ret

0000000080004a7e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004a7e:	1141                	addi	sp,sp,-16
    80004a80:	e406                	sd	ra,8(sp)
    80004a82:	e022                	sd	s0,0(sp)
    80004a84:	0800                	addi	s0,sp,16
    80004a86:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004a88:	4585                	li	a1,1
    80004a8a:	00000097          	auipc	ra,0x0
    80004a8e:	db4080e7          	jalr	-588(ra) # 8000483e <namex>
}
    80004a92:	60a2                	ld	ra,8(sp)
    80004a94:	6402                	ld	s0,0(sp)
    80004a96:	0141                	addi	sp,sp,16
    80004a98:	8082                	ret

0000000080004a9a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004a9a:	1101                	addi	sp,sp,-32
    80004a9c:	ec06                	sd	ra,24(sp)
    80004a9e:	e822                	sd	s0,16(sp)
    80004aa0:	e426                	sd	s1,8(sp)
    80004aa2:	e04a                	sd	s2,0(sp)
    80004aa4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004aa6:	0001d917          	auipc	s2,0x1d
    80004aaa:	0da90913          	addi	s2,s2,218 # 80021b80 <log>
    80004aae:	01892583          	lw	a1,24(s2)
    80004ab2:	02892503          	lw	a0,40(s2)
    80004ab6:	fffff097          	auipc	ra,0xfffff
    80004aba:	ff2080e7          	jalr	-14(ra) # 80003aa8 <bread>
    80004abe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004ac0:	02c92683          	lw	a3,44(s2)
    80004ac4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004ac6:	02d05763          	blez	a3,80004af4 <write_head+0x5a>
    80004aca:	0001d797          	auipc	a5,0x1d
    80004ace:	0e678793          	addi	a5,a5,230 # 80021bb0 <log+0x30>
    80004ad2:	05c50713          	addi	a4,a0,92
    80004ad6:	36fd                	addiw	a3,a3,-1
    80004ad8:	1682                	slli	a3,a3,0x20
    80004ada:	9281                	srli	a3,a3,0x20
    80004adc:	068a                	slli	a3,a3,0x2
    80004ade:	0001d617          	auipc	a2,0x1d
    80004ae2:	0d660613          	addi	a2,a2,214 # 80021bb4 <log+0x34>
    80004ae6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004ae8:	4390                	lw	a2,0(a5)
    80004aea:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004aec:	0791                	addi	a5,a5,4
    80004aee:	0711                	addi	a4,a4,4
    80004af0:	fed79ce3          	bne	a5,a3,80004ae8 <write_head+0x4e>
  }
  bwrite(buf);
    80004af4:	8526                	mv	a0,s1
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	0a4080e7          	jalr	164(ra) # 80003b9a <bwrite>
  brelse(buf);
    80004afe:	8526                	mv	a0,s1
    80004b00:	fffff097          	auipc	ra,0xfffff
    80004b04:	0d8080e7          	jalr	216(ra) # 80003bd8 <brelse>
}
    80004b08:	60e2                	ld	ra,24(sp)
    80004b0a:	6442                	ld	s0,16(sp)
    80004b0c:	64a2                	ld	s1,8(sp)
    80004b0e:	6902                	ld	s2,0(sp)
    80004b10:	6105                	addi	sp,sp,32
    80004b12:	8082                	ret

0000000080004b14 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b14:	0001d797          	auipc	a5,0x1d
    80004b18:	0987a783          	lw	a5,152(a5) # 80021bac <log+0x2c>
    80004b1c:	0af05d63          	blez	a5,80004bd6 <install_trans+0xc2>
{
    80004b20:	7139                	addi	sp,sp,-64
    80004b22:	fc06                	sd	ra,56(sp)
    80004b24:	f822                	sd	s0,48(sp)
    80004b26:	f426                	sd	s1,40(sp)
    80004b28:	f04a                	sd	s2,32(sp)
    80004b2a:	ec4e                	sd	s3,24(sp)
    80004b2c:	e852                	sd	s4,16(sp)
    80004b2e:	e456                	sd	s5,8(sp)
    80004b30:	e05a                	sd	s6,0(sp)
    80004b32:	0080                	addi	s0,sp,64
    80004b34:	8b2a                	mv	s6,a0
    80004b36:	0001da97          	auipc	s5,0x1d
    80004b3a:	07aa8a93          	addi	s5,s5,122 # 80021bb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b3e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b40:	0001d997          	auipc	s3,0x1d
    80004b44:	04098993          	addi	s3,s3,64 # 80021b80 <log>
    80004b48:	a035                	j	80004b74 <install_trans+0x60>
      bunpin(dbuf);
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	fffff097          	auipc	ra,0xfffff
    80004b50:	166080e7          	jalr	358(ra) # 80003cb2 <bunpin>
    brelse(lbuf);
    80004b54:	854a                	mv	a0,s2
    80004b56:	fffff097          	auipc	ra,0xfffff
    80004b5a:	082080e7          	jalr	130(ra) # 80003bd8 <brelse>
    brelse(dbuf);
    80004b5e:	8526                	mv	a0,s1
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	078080e7          	jalr	120(ra) # 80003bd8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b68:	2a05                	addiw	s4,s4,1
    80004b6a:	0a91                	addi	s5,s5,4
    80004b6c:	02c9a783          	lw	a5,44(s3)
    80004b70:	04fa5963          	bge	s4,a5,80004bc2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b74:	0189a583          	lw	a1,24(s3)
    80004b78:	014585bb          	addw	a1,a1,s4
    80004b7c:	2585                	addiw	a1,a1,1
    80004b7e:	0289a503          	lw	a0,40(s3)
    80004b82:	fffff097          	auipc	ra,0xfffff
    80004b86:	f26080e7          	jalr	-218(ra) # 80003aa8 <bread>
    80004b8a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b8c:	000aa583          	lw	a1,0(s5)
    80004b90:	0289a503          	lw	a0,40(s3)
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	f14080e7          	jalr	-236(ra) # 80003aa8 <bread>
    80004b9c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004b9e:	40000613          	li	a2,1024
    80004ba2:	05890593          	addi	a1,s2,88
    80004ba6:	05850513          	addi	a0,a0,88
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	1a4080e7          	jalr	420(ra) # 80000d4e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	fffff097          	auipc	ra,0xfffff
    80004bb8:	fe6080e7          	jalr	-26(ra) # 80003b9a <bwrite>
    if(recovering == 0)
    80004bbc:	f80b1ce3          	bnez	s6,80004b54 <install_trans+0x40>
    80004bc0:	b769                	j	80004b4a <install_trans+0x36>
}
    80004bc2:	70e2                	ld	ra,56(sp)
    80004bc4:	7442                	ld	s0,48(sp)
    80004bc6:	74a2                	ld	s1,40(sp)
    80004bc8:	7902                	ld	s2,32(sp)
    80004bca:	69e2                	ld	s3,24(sp)
    80004bcc:	6a42                	ld	s4,16(sp)
    80004bce:	6aa2                	ld	s5,8(sp)
    80004bd0:	6b02                	ld	s6,0(sp)
    80004bd2:	6121                	addi	sp,sp,64
    80004bd4:	8082                	ret
    80004bd6:	8082                	ret

0000000080004bd8 <initlog>:
{
    80004bd8:	7179                	addi	sp,sp,-48
    80004bda:	f406                	sd	ra,40(sp)
    80004bdc:	f022                	sd	s0,32(sp)
    80004bde:	ec26                	sd	s1,24(sp)
    80004be0:	e84a                	sd	s2,16(sp)
    80004be2:	e44e                	sd	s3,8(sp)
    80004be4:	1800                	addi	s0,sp,48
    80004be6:	892a                	mv	s2,a0
    80004be8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004bea:	0001d497          	auipc	s1,0x1d
    80004bee:	f9648493          	addi	s1,s1,-106 # 80021b80 <log>
    80004bf2:	00004597          	auipc	a1,0x4
    80004bf6:	b9658593          	addi	a1,a1,-1130 # 80008788 <syscalls+0x1e8>
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	f58080e7          	jalr	-168(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004c04:	0149a583          	lw	a1,20(s3)
    80004c08:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c0a:	0109a783          	lw	a5,16(s3)
    80004c0e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c10:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c14:	854a                	mv	a0,s2
    80004c16:	fffff097          	auipc	ra,0xfffff
    80004c1a:	e92080e7          	jalr	-366(ra) # 80003aa8 <bread>
  log.lh.n = lh->n;
    80004c1e:	4d3c                	lw	a5,88(a0)
    80004c20:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c22:	02f05563          	blez	a5,80004c4c <initlog+0x74>
    80004c26:	05c50713          	addi	a4,a0,92
    80004c2a:	0001d697          	auipc	a3,0x1d
    80004c2e:	f8668693          	addi	a3,a3,-122 # 80021bb0 <log+0x30>
    80004c32:	37fd                	addiw	a5,a5,-1
    80004c34:	1782                	slli	a5,a5,0x20
    80004c36:	9381                	srli	a5,a5,0x20
    80004c38:	078a                	slli	a5,a5,0x2
    80004c3a:	06050613          	addi	a2,a0,96
    80004c3e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004c40:	4310                	lw	a2,0(a4)
    80004c42:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004c44:	0711                	addi	a4,a4,4
    80004c46:	0691                	addi	a3,a3,4
    80004c48:	fef71ce3          	bne	a4,a5,80004c40 <initlog+0x68>
  brelse(buf);
    80004c4c:	fffff097          	auipc	ra,0xfffff
    80004c50:	f8c080e7          	jalr	-116(ra) # 80003bd8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c54:	4505                	li	a0,1
    80004c56:	00000097          	auipc	ra,0x0
    80004c5a:	ebe080e7          	jalr	-322(ra) # 80004b14 <install_trans>
  log.lh.n = 0;
    80004c5e:	0001d797          	auipc	a5,0x1d
    80004c62:	f407a723          	sw	zero,-178(a5) # 80021bac <log+0x2c>
  write_head(); // clear the log
    80004c66:	00000097          	auipc	ra,0x0
    80004c6a:	e34080e7          	jalr	-460(ra) # 80004a9a <write_head>
}
    80004c6e:	70a2                	ld	ra,40(sp)
    80004c70:	7402                	ld	s0,32(sp)
    80004c72:	64e2                	ld	s1,24(sp)
    80004c74:	6942                	ld	s2,16(sp)
    80004c76:	69a2                	ld	s3,8(sp)
    80004c78:	6145                	addi	sp,sp,48
    80004c7a:	8082                	ret

0000000080004c7c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c7c:	1101                	addi	sp,sp,-32
    80004c7e:	ec06                	sd	ra,24(sp)
    80004c80:	e822                	sd	s0,16(sp)
    80004c82:	e426                	sd	s1,8(sp)
    80004c84:	e04a                	sd	s2,0(sp)
    80004c86:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c88:	0001d517          	auipc	a0,0x1d
    80004c8c:	ef850513          	addi	a0,a0,-264 # 80021b80 <log>
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	f5c080e7          	jalr	-164(ra) # 80000bec <acquire>
  while(1){
    if(log.committing){
    80004c98:	0001d497          	auipc	s1,0x1d
    80004c9c:	ee848493          	addi	s1,s1,-280 # 80021b80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ca0:	4979                	li	s2,30
    80004ca2:	a039                	j	80004cb0 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004ca4:	85a6                	mv	a1,s1
    80004ca6:	8526                	mv	a0,s1
    80004ca8:	ffffe097          	auipc	ra,0xffffe
    80004cac:	ee6080e7          	jalr	-282(ra) # 80002b8e <sleep>
    if(log.committing){
    80004cb0:	50dc                	lw	a5,36(s1)
    80004cb2:	fbed                	bnez	a5,80004ca4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cb4:	509c                	lw	a5,32(s1)
    80004cb6:	0017871b          	addiw	a4,a5,1
    80004cba:	0007069b          	sext.w	a3,a4
    80004cbe:	0027179b          	slliw	a5,a4,0x2
    80004cc2:	9fb9                	addw	a5,a5,a4
    80004cc4:	0017979b          	slliw	a5,a5,0x1
    80004cc8:	54d8                	lw	a4,44(s1)
    80004cca:	9fb9                	addw	a5,a5,a4
    80004ccc:	00f95963          	bge	s2,a5,80004cde <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004cd0:	85a6                	mv	a1,s1
    80004cd2:	8526                	mv	a0,s1
    80004cd4:	ffffe097          	auipc	ra,0xffffe
    80004cd8:	eba080e7          	jalr	-326(ra) # 80002b8e <sleep>
    80004cdc:	bfd1                	j	80004cb0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004cde:	0001d517          	auipc	a0,0x1d
    80004ce2:	ea250513          	addi	a0,a0,-350 # 80021b80 <log>
    80004ce6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	fbe080e7          	jalr	-66(ra) # 80000ca6 <release>
      break;
    }
  }
}
    80004cf0:	60e2                	ld	ra,24(sp)
    80004cf2:	6442                	ld	s0,16(sp)
    80004cf4:	64a2                	ld	s1,8(sp)
    80004cf6:	6902                	ld	s2,0(sp)
    80004cf8:	6105                	addi	sp,sp,32
    80004cfa:	8082                	ret

0000000080004cfc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004cfc:	7139                	addi	sp,sp,-64
    80004cfe:	fc06                	sd	ra,56(sp)
    80004d00:	f822                	sd	s0,48(sp)
    80004d02:	f426                	sd	s1,40(sp)
    80004d04:	f04a                	sd	s2,32(sp)
    80004d06:	ec4e                	sd	s3,24(sp)
    80004d08:	e852                	sd	s4,16(sp)
    80004d0a:	e456                	sd	s5,8(sp)
    80004d0c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d0e:	0001d497          	auipc	s1,0x1d
    80004d12:	e7248493          	addi	s1,s1,-398 # 80021b80 <log>
    80004d16:	8526                	mv	a0,s1
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	ed4080e7          	jalr	-300(ra) # 80000bec <acquire>
  log.outstanding -= 1;
    80004d20:	509c                	lw	a5,32(s1)
    80004d22:	37fd                	addiw	a5,a5,-1
    80004d24:	0007891b          	sext.w	s2,a5
    80004d28:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d2a:	50dc                	lw	a5,36(s1)
    80004d2c:	efb9                	bnez	a5,80004d8a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d2e:	06091663          	bnez	s2,80004d9a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004d32:	0001d497          	auipc	s1,0x1d
    80004d36:	e4e48493          	addi	s1,s1,-434 # 80021b80 <log>
    80004d3a:	4785                	li	a5,1
    80004d3c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d3e:	8526                	mv	a0,s1
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	f66080e7          	jalr	-154(ra) # 80000ca6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d48:	54dc                	lw	a5,44(s1)
    80004d4a:	06f04763          	bgtz	a5,80004db8 <end_op+0xbc>
    acquire(&log.lock);
    80004d4e:	0001d497          	auipc	s1,0x1d
    80004d52:	e3248493          	addi	s1,s1,-462 # 80021b80 <log>
    80004d56:	8526                	mv	a0,s1
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	e94080e7          	jalr	-364(ra) # 80000bec <acquire>
    log.committing = 0;
    80004d60:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d64:	8526                	mv	a0,s1
    80004d66:	ffffe097          	auipc	ra,0xffffe
    80004d6a:	fcc080e7          	jalr	-52(ra) # 80002d32 <wakeup>
    release(&log.lock);
    80004d6e:	8526                	mv	a0,s1
    80004d70:	ffffc097          	auipc	ra,0xffffc
    80004d74:	f36080e7          	jalr	-202(ra) # 80000ca6 <release>
}
    80004d78:	70e2                	ld	ra,56(sp)
    80004d7a:	7442                	ld	s0,48(sp)
    80004d7c:	74a2                	ld	s1,40(sp)
    80004d7e:	7902                	ld	s2,32(sp)
    80004d80:	69e2                	ld	s3,24(sp)
    80004d82:	6a42                	ld	s4,16(sp)
    80004d84:	6aa2                	ld	s5,8(sp)
    80004d86:	6121                	addi	sp,sp,64
    80004d88:	8082                	ret
    panic("log.committing");
    80004d8a:	00004517          	auipc	a0,0x4
    80004d8e:	a0650513          	addi	a0,a0,-1530 # 80008790 <syscalls+0x1f0>
    80004d92:	ffffb097          	auipc	ra,0xffffb
    80004d96:	7ac080e7          	jalr	1964(ra) # 8000053e <panic>
    wakeup(&log);
    80004d9a:	0001d497          	auipc	s1,0x1d
    80004d9e:	de648493          	addi	s1,s1,-538 # 80021b80 <log>
    80004da2:	8526                	mv	a0,s1
    80004da4:	ffffe097          	auipc	ra,0xffffe
    80004da8:	f8e080e7          	jalr	-114(ra) # 80002d32 <wakeup>
  release(&log.lock);
    80004dac:	8526                	mv	a0,s1
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	ef8080e7          	jalr	-264(ra) # 80000ca6 <release>
  if(do_commit){
    80004db6:	b7c9                	j	80004d78 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004db8:	0001da97          	auipc	s5,0x1d
    80004dbc:	df8a8a93          	addi	s5,s5,-520 # 80021bb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004dc0:	0001da17          	auipc	s4,0x1d
    80004dc4:	dc0a0a13          	addi	s4,s4,-576 # 80021b80 <log>
    80004dc8:	018a2583          	lw	a1,24(s4)
    80004dcc:	012585bb          	addw	a1,a1,s2
    80004dd0:	2585                	addiw	a1,a1,1
    80004dd2:	028a2503          	lw	a0,40(s4)
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	cd2080e7          	jalr	-814(ra) # 80003aa8 <bread>
    80004dde:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004de0:	000aa583          	lw	a1,0(s5)
    80004de4:	028a2503          	lw	a0,40(s4)
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	cc0080e7          	jalr	-832(ra) # 80003aa8 <bread>
    80004df0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004df2:	40000613          	li	a2,1024
    80004df6:	05850593          	addi	a1,a0,88
    80004dfa:	05848513          	addi	a0,s1,88
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	f50080e7          	jalr	-176(ra) # 80000d4e <memmove>
    bwrite(to);  // write the log
    80004e06:	8526                	mv	a0,s1
    80004e08:	fffff097          	auipc	ra,0xfffff
    80004e0c:	d92080e7          	jalr	-622(ra) # 80003b9a <bwrite>
    brelse(from);
    80004e10:	854e                	mv	a0,s3
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	dc6080e7          	jalr	-570(ra) # 80003bd8 <brelse>
    brelse(to);
    80004e1a:	8526                	mv	a0,s1
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	dbc080e7          	jalr	-580(ra) # 80003bd8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e24:	2905                	addiw	s2,s2,1
    80004e26:	0a91                	addi	s5,s5,4
    80004e28:	02ca2783          	lw	a5,44(s4)
    80004e2c:	f8f94ee3          	blt	s2,a5,80004dc8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e30:	00000097          	auipc	ra,0x0
    80004e34:	c6a080e7          	jalr	-918(ra) # 80004a9a <write_head>
    install_trans(0); // Now install writes to home locations
    80004e38:	4501                	li	a0,0
    80004e3a:	00000097          	auipc	ra,0x0
    80004e3e:	cda080e7          	jalr	-806(ra) # 80004b14 <install_trans>
    log.lh.n = 0;
    80004e42:	0001d797          	auipc	a5,0x1d
    80004e46:	d607a523          	sw	zero,-662(a5) # 80021bac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e4a:	00000097          	auipc	ra,0x0
    80004e4e:	c50080e7          	jalr	-944(ra) # 80004a9a <write_head>
    80004e52:	bdf5                	j	80004d4e <end_op+0x52>

0000000080004e54 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e54:	1101                	addi	sp,sp,-32
    80004e56:	ec06                	sd	ra,24(sp)
    80004e58:	e822                	sd	s0,16(sp)
    80004e5a:	e426                	sd	s1,8(sp)
    80004e5c:	e04a                	sd	s2,0(sp)
    80004e5e:	1000                	addi	s0,sp,32
    80004e60:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e62:	0001d917          	auipc	s2,0x1d
    80004e66:	d1e90913          	addi	s2,s2,-738 # 80021b80 <log>
    80004e6a:	854a                	mv	a0,s2
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	d80080e7          	jalr	-640(ra) # 80000bec <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e74:	02c92603          	lw	a2,44(s2)
    80004e78:	47f5                	li	a5,29
    80004e7a:	06c7c563          	blt	a5,a2,80004ee4 <log_write+0x90>
    80004e7e:	0001d797          	auipc	a5,0x1d
    80004e82:	d1e7a783          	lw	a5,-738(a5) # 80021b9c <log+0x1c>
    80004e86:	37fd                	addiw	a5,a5,-1
    80004e88:	04f65e63          	bge	a2,a5,80004ee4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004e8c:	0001d797          	auipc	a5,0x1d
    80004e90:	d147a783          	lw	a5,-748(a5) # 80021ba0 <log+0x20>
    80004e94:	06f05063          	blez	a5,80004ef4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004e98:	4781                	li	a5,0
    80004e9a:	06c05563          	blez	a2,80004f04 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004e9e:	44cc                	lw	a1,12(s1)
    80004ea0:	0001d717          	auipc	a4,0x1d
    80004ea4:	d1070713          	addi	a4,a4,-752 # 80021bb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ea8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004eaa:	4314                	lw	a3,0(a4)
    80004eac:	04b68c63          	beq	a3,a1,80004f04 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004eb0:	2785                	addiw	a5,a5,1
    80004eb2:	0711                	addi	a4,a4,4
    80004eb4:	fef61be3          	bne	a2,a5,80004eaa <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004eb8:	0621                	addi	a2,a2,8
    80004eba:	060a                	slli	a2,a2,0x2
    80004ebc:	0001d797          	auipc	a5,0x1d
    80004ec0:	cc478793          	addi	a5,a5,-828 # 80021b80 <log>
    80004ec4:	963e                	add	a2,a2,a5
    80004ec6:	44dc                	lw	a5,12(s1)
    80004ec8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004eca:	8526                	mv	a0,s1
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	daa080e7          	jalr	-598(ra) # 80003c76 <bpin>
    log.lh.n++;
    80004ed4:	0001d717          	auipc	a4,0x1d
    80004ed8:	cac70713          	addi	a4,a4,-852 # 80021b80 <log>
    80004edc:	575c                	lw	a5,44(a4)
    80004ede:	2785                	addiw	a5,a5,1
    80004ee0:	d75c                	sw	a5,44(a4)
    80004ee2:	a835                	j	80004f1e <log_write+0xca>
    panic("too big a transaction");
    80004ee4:	00004517          	auipc	a0,0x4
    80004ee8:	8bc50513          	addi	a0,a0,-1860 # 800087a0 <syscalls+0x200>
    80004eec:	ffffb097          	auipc	ra,0xffffb
    80004ef0:	652080e7          	jalr	1618(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004ef4:	00004517          	auipc	a0,0x4
    80004ef8:	8c450513          	addi	a0,a0,-1852 # 800087b8 <syscalls+0x218>
    80004efc:	ffffb097          	auipc	ra,0xffffb
    80004f00:	642080e7          	jalr	1602(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004f04:	00878713          	addi	a4,a5,8
    80004f08:	00271693          	slli	a3,a4,0x2
    80004f0c:	0001d717          	auipc	a4,0x1d
    80004f10:	c7470713          	addi	a4,a4,-908 # 80021b80 <log>
    80004f14:	9736                	add	a4,a4,a3
    80004f16:	44d4                	lw	a3,12(s1)
    80004f18:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f1a:	faf608e3          	beq	a2,a5,80004eca <log_write+0x76>
  }
  release(&log.lock);
    80004f1e:	0001d517          	auipc	a0,0x1d
    80004f22:	c6250513          	addi	a0,a0,-926 # 80021b80 <log>
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	d80080e7          	jalr	-640(ra) # 80000ca6 <release>
}
    80004f2e:	60e2                	ld	ra,24(sp)
    80004f30:	6442                	ld	s0,16(sp)
    80004f32:	64a2                	ld	s1,8(sp)
    80004f34:	6902                	ld	s2,0(sp)
    80004f36:	6105                	addi	sp,sp,32
    80004f38:	8082                	ret

0000000080004f3a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f3a:	1101                	addi	sp,sp,-32
    80004f3c:	ec06                	sd	ra,24(sp)
    80004f3e:	e822                	sd	s0,16(sp)
    80004f40:	e426                	sd	s1,8(sp)
    80004f42:	e04a                	sd	s2,0(sp)
    80004f44:	1000                	addi	s0,sp,32
    80004f46:	84aa                	mv	s1,a0
    80004f48:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f4a:	00004597          	auipc	a1,0x4
    80004f4e:	88e58593          	addi	a1,a1,-1906 # 800087d8 <syscalls+0x238>
    80004f52:	0521                	addi	a0,a0,8
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	c00080e7          	jalr	-1024(ra) # 80000b54 <initlock>
  lk->name = name;
    80004f5c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f60:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f64:	0204a423          	sw	zero,40(s1)
}
    80004f68:	60e2                	ld	ra,24(sp)
    80004f6a:	6442                	ld	s0,16(sp)
    80004f6c:	64a2                	ld	s1,8(sp)
    80004f6e:	6902                	ld	s2,0(sp)
    80004f70:	6105                	addi	sp,sp,32
    80004f72:	8082                	ret

0000000080004f74 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f74:	1101                	addi	sp,sp,-32
    80004f76:	ec06                	sd	ra,24(sp)
    80004f78:	e822                	sd	s0,16(sp)
    80004f7a:	e426                	sd	s1,8(sp)
    80004f7c:	e04a                	sd	s2,0(sp)
    80004f7e:	1000                	addi	s0,sp,32
    80004f80:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f82:	00850913          	addi	s2,a0,8
    80004f86:	854a                	mv	a0,s2
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	c64080e7          	jalr	-924(ra) # 80000bec <acquire>
  while (lk->locked) {
    80004f90:	409c                	lw	a5,0(s1)
    80004f92:	cb89                	beqz	a5,80004fa4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f94:	85ca                	mv	a1,s2
    80004f96:	8526                	mv	a0,s1
    80004f98:	ffffe097          	auipc	ra,0xffffe
    80004f9c:	bf6080e7          	jalr	-1034(ra) # 80002b8e <sleep>
  while (lk->locked) {
    80004fa0:	409c                	lw	a5,0(s1)
    80004fa2:	fbed                	bnez	a5,80004f94 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004fa4:	4785                	li	a5,1
    80004fa6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004fa8:	ffffd097          	auipc	ra,0xffffd
    80004fac:	328080e7          	jalr	808(ra) # 800022d0 <myproc>
    80004fb0:	453c                	lw	a5,72(a0)
    80004fb2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004fb4:	854a                	mv	a0,s2
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	cf0080e7          	jalr	-784(ra) # 80000ca6 <release>
}
    80004fbe:	60e2                	ld	ra,24(sp)
    80004fc0:	6442                	ld	s0,16(sp)
    80004fc2:	64a2                	ld	s1,8(sp)
    80004fc4:	6902                	ld	s2,0(sp)
    80004fc6:	6105                	addi	sp,sp,32
    80004fc8:	8082                	ret

0000000080004fca <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004fca:	1101                	addi	sp,sp,-32
    80004fcc:	ec06                	sd	ra,24(sp)
    80004fce:	e822                	sd	s0,16(sp)
    80004fd0:	e426                	sd	s1,8(sp)
    80004fd2:	e04a                	sd	s2,0(sp)
    80004fd4:	1000                	addi	s0,sp,32
    80004fd6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fd8:	00850913          	addi	s2,a0,8
    80004fdc:	854a                	mv	a0,s2
    80004fde:	ffffc097          	auipc	ra,0xffffc
    80004fe2:	c0e080e7          	jalr	-1010(ra) # 80000bec <acquire>
  lk->locked = 0;
    80004fe6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fea:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004fee:	8526                	mv	a0,s1
    80004ff0:	ffffe097          	auipc	ra,0xffffe
    80004ff4:	d42080e7          	jalr	-702(ra) # 80002d32 <wakeup>
  release(&lk->lk);
    80004ff8:	854a                	mv	a0,s2
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	cac080e7          	jalr	-852(ra) # 80000ca6 <release>
}
    80005002:	60e2                	ld	ra,24(sp)
    80005004:	6442                	ld	s0,16(sp)
    80005006:	64a2                	ld	s1,8(sp)
    80005008:	6902                	ld	s2,0(sp)
    8000500a:	6105                	addi	sp,sp,32
    8000500c:	8082                	ret

000000008000500e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000500e:	7179                	addi	sp,sp,-48
    80005010:	f406                	sd	ra,40(sp)
    80005012:	f022                	sd	s0,32(sp)
    80005014:	ec26                	sd	s1,24(sp)
    80005016:	e84a                	sd	s2,16(sp)
    80005018:	e44e                	sd	s3,8(sp)
    8000501a:	1800                	addi	s0,sp,48
    8000501c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000501e:	00850913          	addi	s2,a0,8
    80005022:	854a                	mv	a0,s2
    80005024:	ffffc097          	auipc	ra,0xffffc
    80005028:	bc8080e7          	jalr	-1080(ra) # 80000bec <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000502c:	409c                	lw	a5,0(s1)
    8000502e:	ef99                	bnez	a5,8000504c <holdingsleep+0x3e>
    80005030:	4481                	li	s1,0
  release(&lk->lk);
    80005032:	854a                	mv	a0,s2
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	c72080e7          	jalr	-910(ra) # 80000ca6 <release>
  return r;
}
    8000503c:	8526                	mv	a0,s1
    8000503e:	70a2                	ld	ra,40(sp)
    80005040:	7402                	ld	s0,32(sp)
    80005042:	64e2                	ld	s1,24(sp)
    80005044:	6942                	ld	s2,16(sp)
    80005046:	69a2                	ld	s3,8(sp)
    80005048:	6145                	addi	sp,sp,48
    8000504a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000504c:	0284a983          	lw	s3,40(s1)
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	280080e7          	jalr	640(ra) # 800022d0 <myproc>
    80005058:	4524                	lw	s1,72(a0)
    8000505a:	413484b3          	sub	s1,s1,s3
    8000505e:	0014b493          	seqz	s1,s1
    80005062:	bfc1                	j	80005032 <holdingsleep+0x24>

0000000080005064 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005064:	1141                	addi	sp,sp,-16
    80005066:	e406                	sd	ra,8(sp)
    80005068:	e022                	sd	s0,0(sp)
    8000506a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000506c:	00003597          	auipc	a1,0x3
    80005070:	77c58593          	addi	a1,a1,1916 # 800087e8 <syscalls+0x248>
    80005074:	0001d517          	auipc	a0,0x1d
    80005078:	c5450513          	addi	a0,a0,-940 # 80021cc8 <ftable>
    8000507c:	ffffc097          	auipc	ra,0xffffc
    80005080:	ad8080e7          	jalr	-1320(ra) # 80000b54 <initlock>
}
    80005084:	60a2                	ld	ra,8(sp)
    80005086:	6402                	ld	s0,0(sp)
    80005088:	0141                	addi	sp,sp,16
    8000508a:	8082                	ret

000000008000508c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000508c:	1101                	addi	sp,sp,-32
    8000508e:	ec06                	sd	ra,24(sp)
    80005090:	e822                	sd	s0,16(sp)
    80005092:	e426                	sd	s1,8(sp)
    80005094:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005096:	0001d517          	auipc	a0,0x1d
    8000509a:	c3250513          	addi	a0,a0,-974 # 80021cc8 <ftable>
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	b4e080e7          	jalr	-1202(ra) # 80000bec <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050a6:	0001d497          	auipc	s1,0x1d
    800050aa:	c3a48493          	addi	s1,s1,-966 # 80021ce0 <ftable+0x18>
    800050ae:	0001e717          	auipc	a4,0x1e
    800050b2:	bd270713          	addi	a4,a4,-1070 # 80022c80 <ftable+0xfb8>
    if(f->ref == 0){
    800050b6:	40dc                	lw	a5,4(s1)
    800050b8:	cf99                	beqz	a5,800050d6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050ba:	02848493          	addi	s1,s1,40
    800050be:	fee49ce3          	bne	s1,a4,800050b6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800050c2:	0001d517          	auipc	a0,0x1d
    800050c6:	c0650513          	addi	a0,a0,-1018 # 80021cc8 <ftable>
    800050ca:	ffffc097          	auipc	ra,0xffffc
    800050ce:	bdc080e7          	jalr	-1060(ra) # 80000ca6 <release>
  return 0;
    800050d2:	4481                	li	s1,0
    800050d4:	a819                	j	800050ea <filealloc+0x5e>
      f->ref = 1;
    800050d6:	4785                	li	a5,1
    800050d8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800050da:	0001d517          	auipc	a0,0x1d
    800050de:	bee50513          	addi	a0,a0,-1042 # 80021cc8 <ftable>
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	bc4080e7          	jalr	-1084(ra) # 80000ca6 <release>
}
    800050ea:	8526                	mv	a0,s1
    800050ec:	60e2                	ld	ra,24(sp)
    800050ee:	6442                	ld	s0,16(sp)
    800050f0:	64a2                	ld	s1,8(sp)
    800050f2:	6105                	addi	sp,sp,32
    800050f4:	8082                	ret

00000000800050f6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800050f6:	1101                	addi	sp,sp,-32
    800050f8:	ec06                	sd	ra,24(sp)
    800050fa:	e822                	sd	s0,16(sp)
    800050fc:	e426                	sd	s1,8(sp)
    800050fe:	1000                	addi	s0,sp,32
    80005100:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005102:	0001d517          	auipc	a0,0x1d
    80005106:	bc650513          	addi	a0,a0,-1082 # 80021cc8 <ftable>
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	ae2080e7          	jalr	-1310(ra) # 80000bec <acquire>
  if(f->ref < 1)
    80005112:	40dc                	lw	a5,4(s1)
    80005114:	02f05263          	blez	a5,80005138 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005118:	2785                	addiw	a5,a5,1
    8000511a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000511c:	0001d517          	auipc	a0,0x1d
    80005120:	bac50513          	addi	a0,a0,-1108 # 80021cc8 <ftable>
    80005124:	ffffc097          	auipc	ra,0xffffc
    80005128:	b82080e7          	jalr	-1150(ra) # 80000ca6 <release>
  return f;
}
    8000512c:	8526                	mv	a0,s1
    8000512e:	60e2                	ld	ra,24(sp)
    80005130:	6442                	ld	s0,16(sp)
    80005132:	64a2                	ld	s1,8(sp)
    80005134:	6105                	addi	sp,sp,32
    80005136:	8082                	ret
    panic("filedup");
    80005138:	00003517          	auipc	a0,0x3
    8000513c:	6b850513          	addi	a0,a0,1720 # 800087f0 <syscalls+0x250>
    80005140:	ffffb097          	auipc	ra,0xffffb
    80005144:	3fe080e7          	jalr	1022(ra) # 8000053e <panic>

0000000080005148 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005148:	7139                	addi	sp,sp,-64
    8000514a:	fc06                	sd	ra,56(sp)
    8000514c:	f822                	sd	s0,48(sp)
    8000514e:	f426                	sd	s1,40(sp)
    80005150:	f04a                	sd	s2,32(sp)
    80005152:	ec4e                	sd	s3,24(sp)
    80005154:	e852                	sd	s4,16(sp)
    80005156:	e456                	sd	s5,8(sp)
    80005158:	0080                	addi	s0,sp,64
    8000515a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000515c:	0001d517          	auipc	a0,0x1d
    80005160:	b6c50513          	addi	a0,a0,-1172 # 80021cc8 <ftable>
    80005164:	ffffc097          	auipc	ra,0xffffc
    80005168:	a88080e7          	jalr	-1400(ra) # 80000bec <acquire>
  if(f->ref < 1)
    8000516c:	40dc                	lw	a5,4(s1)
    8000516e:	06f05163          	blez	a5,800051d0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005172:	37fd                	addiw	a5,a5,-1
    80005174:	0007871b          	sext.w	a4,a5
    80005178:	c0dc                	sw	a5,4(s1)
    8000517a:	06e04363          	bgtz	a4,800051e0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000517e:	0004a903          	lw	s2,0(s1)
    80005182:	0094ca83          	lbu	s5,9(s1)
    80005186:	0104ba03          	ld	s4,16(s1)
    8000518a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000518e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005192:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005196:	0001d517          	auipc	a0,0x1d
    8000519a:	b3250513          	addi	a0,a0,-1230 # 80021cc8 <ftable>
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	b08080e7          	jalr	-1272(ra) # 80000ca6 <release>

  if(ff.type == FD_PIPE){
    800051a6:	4785                	li	a5,1
    800051a8:	04f90d63          	beq	s2,a5,80005202 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800051ac:	3979                	addiw	s2,s2,-2
    800051ae:	4785                	li	a5,1
    800051b0:	0527e063          	bltu	a5,s2,800051f0 <fileclose+0xa8>
    begin_op();
    800051b4:	00000097          	auipc	ra,0x0
    800051b8:	ac8080e7          	jalr	-1336(ra) # 80004c7c <begin_op>
    iput(ff.ip);
    800051bc:	854e                	mv	a0,s3
    800051be:	fffff097          	auipc	ra,0xfffff
    800051c2:	2a6080e7          	jalr	678(ra) # 80004464 <iput>
    end_op();
    800051c6:	00000097          	auipc	ra,0x0
    800051ca:	b36080e7          	jalr	-1226(ra) # 80004cfc <end_op>
    800051ce:	a00d                	j	800051f0 <fileclose+0xa8>
    panic("fileclose");
    800051d0:	00003517          	auipc	a0,0x3
    800051d4:	62850513          	addi	a0,a0,1576 # 800087f8 <syscalls+0x258>
    800051d8:	ffffb097          	auipc	ra,0xffffb
    800051dc:	366080e7          	jalr	870(ra) # 8000053e <panic>
    release(&ftable.lock);
    800051e0:	0001d517          	auipc	a0,0x1d
    800051e4:	ae850513          	addi	a0,a0,-1304 # 80021cc8 <ftable>
    800051e8:	ffffc097          	auipc	ra,0xffffc
    800051ec:	abe080e7          	jalr	-1346(ra) # 80000ca6 <release>
  }
}
    800051f0:	70e2                	ld	ra,56(sp)
    800051f2:	7442                	ld	s0,48(sp)
    800051f4:	74a2                	ld	s1,40(sp)
    800051f6:	7902                	ld	s2,32(sp)
    800051f8:	69e2                	ld	s3,24(sp)
    800051fa:	6a42                	ld	s4,16(sp)
    800051fc:	6aa2                	ld	s5,8(sp)
    800051fe:	6121                	addi	sp,sp,64
    80005200:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005202:	85d6                	mv	a1,s5
    80005204:	8552                	mv	a0,s4
    80005206:	00000097          	auipc	ra,0x0
    8000520a:	34c080e7          	jalr	844(ra) # 80005552 <pipeclose>
    8000520e:	b7cd                	j	800051f0 <fileclose+0xa8>

0000000080005210 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005210:	715d                	addi	sp,sp,-80
    80005212:	e486                	sd	ra,72(sp)
    80005214:	e0a2                	sd	s0,64(sp)
    80005216:	fc26                	sd	s1,56(sp)
    80005218:	f84a                	sd	s2,48(sp)
    8000521a:	f44e                	sd	s3,40(sp)
    8000521c:	0880                	addi	s0,sp,80
    8000521e:	84aa                	mv	s1,a0
    80005220:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005222:	ffffd097          	auipc	ra,0xffffd
    80005226:	0ae080e7          	jalr	174(ra) # 800022d0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000522a:	409c                	lw	a5,0(s1)
    8000522c:	37f9                	addiw	a5,a5,-2
    8000522e:	4705                	li	a4,1
    80005230:	04f76763          	bltu	a4,a5,8000527e <filestat+0x6e>
    80005234:	892a                	mv	s2,a0
    ilock(f->ip);
    80005236:	6c88                	ld	a0,24(s1)
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	072080e7          	jalr	114(ra) # 800042aa <ilock>
    stati(f->ip, &st);
    80005240:	fb840593          	addi	a1,s0,-72
    80005244:	6c88                	ld	a0,24(s1)
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	2ee080e7          	jalr	750(ra) # 80004534 <stati>
    iunlock(f->ip);
    8000524e:	6c88                	ld	a0,24(s1)
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	11c080e7          	jalr	284(ra) # 8000436c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005258:	46e1                	li	a3,24
    8000525a:	fb840613          	addi	a2,s0,-72
    8000525e:	85ce                	mv	a1,s3
    80005260:	07893503          	ld	a0,120(s2)
    80005264:	ffffc097          	auipc	ra,0xffffc
    80005268:	41c080e7          	jalr	1052(ra) # 80001680 <copyout>
    8000526c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005270:	60a6                	ld	ra,72(sp)
    80005272:	6406                	ld	s0,64(sp)
    80005274:	74e2                	ld	s1,56(sp)
    80005276:	7942                	ld	s2,48(sp)
    80005278:	79a2                	ld	s3,40(sp)
    8000527a:	6161                	addi	sp,sp,80
    8000527c:	8082                	ret
  return -1;
    8000527e:	557d                	li	a0,-1
    80005280:	bfc5                	j	80005270 <filestat+0x60>

0000000080005282 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005282:	7179                	addi	sp,sp,-48
    80005284:	f406                	sd	ra,40(sp)
    80005286:	f022                	sd	s0,32(sp)
    80005288:	ec26                	sd	s1,24(sp)
    8000528a:	e84a                	sd	s2,16(sp)
    8000528c:	e44e                	sd	s3,8(sp)
    8000528e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005290:	00854783          	lbu	a5,8(a0)
    80005294:	c3d5                	beqz	a5,80005338 <fileread+0xb6>
    80005296:	84aa                	mv	s1,a0
    80005298:	89ae                	mv	s3,a1
    8000529a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000529c:	411c                	lw	a5,0(a0)
    8000529e:	4705                	li	a4,1
    800052a0:	04e78963          	beq	a5,a4,800052f2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052a4:	470d                	li	a4,3
    800052a6:	04e78d63          	beq	a5,a4,80005300 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052aa:	4709                	li	a4,2
    800052ac:	06e79e63          	bne	a5,a4,80005328 <fileread+0xa6>
    ilock(f->ip);
    800052b0:	6d08                	ld	a0,24(a0)
    800052b2:	fffff097          	auipc	ra,0xfffff
    800052b6:	ff8080e7          	jalr	-8(ra) # 800042aa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800052ba:	874a                	mv	a4,s2
    800052bc:	5094                	lw	a3,32(s1)
    800052be:	864e                	mv	a2,s3
    800052c0:	4585                	li	a1,1
    800052c2:	6c88                	ld	a0,24(s1)
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	29a080e7          	jalr	666(ra) # 8000455e <readi>
    800052cc:	892a                	mv	s2,a0
    800052ce:	00a05563          	blez	a0,800052d8 <fileread+0x56>
      f->off += r;
    800052d2:	509c                	lw	a5,32(s1)
    800052d4:	9fa9                	addw	a5,a5,a0
    800052d6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052d8:	6c88                	ld	a0,24(s1)
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	092080e7          	jalr	146(ra) # 8000436c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800052e2:	854a                	mv	a0,s2
    800052e4:	70a2                	ld	ra,40(sp)
    800052e6:	7402                	ld	s0,32(sp)
    800052e8:	64e2                	ld	s1,24(sp)
    800052ea:	6942                	ld	s2,16(sp)
    800052ec:	69a2                	ld	s3,8(sp)
    800052ee:	6145                	addi	sp,sp,48
    800052f0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800052f2:	6908                	ld	a0,16(a0)
    800052f4:	00000097          	auipc	ra,0x0
    800052f8:	3c8080e7          	jalr	968(ra) # 800056bc <piperead>
    800052fc:	892a                	mv	s2,a0
    800052fe:	b7d5                	j	800052e2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005300:	02451783          	lh	a5,36(a0)
    80005304:	03079693          	slli	a3,a5,0x30
    80005308:	92c1                	srli	a3,a3,0x30
    8000530a:	4725                	li	a4,9
    8000530c:	02d76863          	bltu	a4,a3,8000533c <fileread+0xba>
    80005310:	0792                	slli	a5,a5,0x4
    80005312:	0001d717          	auipc	a4,0x1d
    80005316:	91670713          	addi	a4,a4,-1770 # 80021c28 <devsw>
    8000531a:	97ba                	add	a5,a5,a4
    8000531c:	639c                	ld	a5,0(a5)
    8000531e:	c38d                	beqz	a5,80005340 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005320:	4505                	li	a0,1
    80005322:	9782                	jalr	a5
    80005324:	892a                	mv	s2,a0
    80005326:	bf75                	j	800052e2 <fileread+0x60>
    panic("fileread");
    80005328:	00003517          	auipc	a0,0x3
    8000532c:	4e050513          	addi	a0,a0,1248 # 80008808 <syscalls+0x268>
    80005330:	ffffb097          	auipc	ra,0xffffb
    80005334:	20e080e7          	jalr	526(ra) # 8000053e <panic>
    return -1;
    80005338:	597d                	li	s2,-1
    8000533a:	b765                	j	800052e2 <fileread+0x60>
      return -1;
    8000533c:	597d                	li	s2,-1
    8000533e:	b755                	j	800052e2 <fileread+0x60>
    80005340:	597d                	li	s2,-1
    80005342:	b745                	j	800052e2 <fileread+0x60>

0000000080005344 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005344:	715d                	addi	sp,sp,-80
    80005346:	e486                	sd	ra,72(sp)
    80005348:	e0a2                	sd	s0,64(sp)
    8000534a:	fc26                	sd	s1,56(sp)
    8000534c:	f84a                	sd	s2,48(sp)
    8000534e:	f44e                	sd	s3,40(sp)
    80005350:	f052                	sd	s4,32(sp)
    80005352:	ec56                	sd	s5,24(sp)
    80005354:	e85a                	sd	s6,16(sp)
    80005356:	e45e                	sd	s7,8(sp)
    80005358:	e062                	sd	s8,0(sp)
    8000535a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000535c:	00954783          	lbu	a5,9(a0)
    80005360:	10078663          	beqz	a5,8000546c <filewrite+0x128>
    80005364:	892a                	mv	s2,a0
    80005366:	8aae                	mv	s5,a1
    80005368:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000536a:	411c                	lw	a5,0(a0)
    8000536c:	4705                	li	a4,1
    8000536e:	02e78263          	beq	a5,a4,80005392 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005372:	470d                	li	a4,3
    80005374:	02e78663          	beq	a5,a4,800053a0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005378:	4709                	li	a4,2
    8000537a:	0ee79163          	bne	a5,a4,8000545c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000537e:	0ac05d63          	blez	a2,80005438 <filewrite+0xf4>
    int i = 0;
    80005382:	4981                	li	s3,0
    80005384:	6b05                	lui	s6,0x1
    80005386:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000538a:	6b85                	lui	s7,0x1
    8000538c:	c00b8b9b          	addiw	s7,s7,-1024
    80005390:	a861                	j	80005428 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005392:	6908                	ld	a0,16(a0)
    80005394:	00000097          	auipc	ra,0x0
    80005398:	22e080e7          	jalr	558(ra) # 800055c2 <pipewrite>
    8000539c:	8a2a                	mv	s4,a0
    8000539e:	a045                	j	8000543e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800053a0:	02451783          	lh	a5,36(a0)
    800053a4:	03079693          	slli	a3,a5,0x30
    800053a8:	92c1                	srli	a3,a3,0x30
    800053aa:	4725                	li	a4,9
    800053ac:	0cd76263          	bltu	a4,a3,80005470 <filewrite+0x12c>
    800053b0:	0792                	slli	a5,a5,0x4
    800053b2:	0001d717          	auipc	a4,0x1d
    800053b6:	87670713          	addi	a4,a4,-1930 # 80021c28 <devsw>
    800053ba:	97ba                	add	a5,a5,a4
    800053bc:	679c                	ld	a5,8(a5)
    800053be:	cbdd                	beqz	a5,80005474 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053c0:	4505                	li	a0,1
    800053c2:	9782                	jalr	a5
    800053c4:	8a2a                	mv	s4,a0
    800053c6:	a8a5                	j	8000543e <filewrite+0xfa>
    800053c8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800053cc:	00000097          	auipc	ra,0x0
    800053d0:	8b0080e7          	jalr	-1872(ra) # 80004c7c <begin_op>
      ilock(f->ip);
    800053d4:	01893503          	ld	a0,24(s2)
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	ed2080e7          	jalr	-302(ra) # 800042aa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053e0:	8762                	mv	a4,s8
    800053e2:	02092683          	lw	a3,32(s2)
    800053e6:	01598633          	add	a2,s3,s5
    800053ea:	4585                	li	a1,1
    800053ec:	01893503          	ld	a0,24(s2)
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	266080e7          	jalr	614(ra) # 80004656 <writei>
    800053f8:	84aa                	mv	s1,a0
    800053fa:	00a05763          	blez	a0,80005408 <filewrite+0xc4>
        f->off += r;
    800053fe:	02092783          	lw	a5,32(s2)
    80005402:	9fa9                	addw	a5,a5,a0
    80005404:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005408:	01893503          	ld	a0,24(s2)
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	f60080e7          	jalr	-160(ra) # 8000436c <iunlock>
      end_op();
    80005414:	00000097          	auipc	ra,0x0
    80005418:	8e8080e7          	jalr	-1816(ra) # 80004cfc <end_op>

      if(r != n1){
    8000541c:	009c1f63          	bne	s8,s1,8000543a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005420:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005424:	0149db63          	bge	s3,s4,8000543a <filewrite+0xf6>
      int n1 = n - i;
    80005428:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000542c:	84be                	mv	s1,a5
    8000542e:	2781                	sext.w	a5,a5
    80005430:	f8fb5ce3          	bge	s6,a5,800053c8 <filewrite+0x84>
    80005434:	84de                	mv	s1,s7
    80005436:	bf49                	j	800053c8 <filewrite+0x84>
    int i = 0;
    80005438:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000543a:	013a1f63          	bne	s4,s3,80005458 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000543e:	8552                	mv	a0,s4
    80005440:	60a6                	ld	ra,72(sp)
    80005442:	6406                	ld	s0,64(sp)
    80005444:	74e2                	ld	s1,56(sp)
    80005446:	7942                	ld	s2,48(sp)
    80005448:	79a2                	ld	s3,40(sp)
    8000544a:	7a02                	ld	s4,32(sp)
    8000544c:	6ae2                	ld	s5,24(sp)
    8000544e:	6b42                	ld	s6,16(sp)
    80005450:	6ba2                	ld	s7,8(sp)
    80005452:	6c02                	ld	s8,0(sp)
    80005454:	6161                	addi	sp,sp,80
    80005456:	8082                	ret
    ret = (i == n ? n : -1);
    80005458:	5a7d                	li	s4,-1
    8000545a:	b7d5                	j	8000543e <filewrite+0xfa>
    panic("filewrite");
    8000545c:	00003517          	auipc	a0,0x3
    80005460:	3bc50513          	addi	a0,a0,956 # 80008818 <syscalls+0x278>
    80005464:	ffffb097          	auipc	ra,0xffffb
    80005468:	0da080e7          	jalr	218(ra) # 8000053e <panic>
    return -1;
    8000546c:	5a7d                	li	s4,-1
    8000546e:	bfc1                	j	8000543e <filewrite+0xfa>
      return -1;
    80005470:	5a7d                	li	s4,-1
    80005472:	b7f1                	j	8000543e <filewrite+0xfa>
    80005474:	5a7d                	li	s4,-1
    80005476:	b7e1                	j	8000543e <filewrite+0xfa>

0000000080005478 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005478:	7179                	addi	sp,sp,-48
    8000547a:	f406                	sd	ra,40(sp)
    8000547c:	f022                	sd	s0,32(sp)
    8000547e:	ec26                	sd	s1,24(sp)
    80005480:	e84a                	sd	s2,16(sp)
    80005482:	e44e                	sd	s3,8(sp)
    80005484:	e052                	sd	s4,0(sp)
    80005486:	1800                	addi	s0,sp,48
    80005488:	84aa                	mv	s1,a0
    8000548a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000548c:	0005b023          	sd	zero,0(a1)
    80005490:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005494:	00000097          	auipc	ra,0x0
    80005498:	bf8080e7          	jalr	-1032(ra) # 8000508c <filealloc>
    8000549c:	e088                	sd	a0,0(s1)
    8000549e:	c551                	beqz	a0,8000552a <pipealloc+0xb2>
    800054a0:	00000097          	auipc	ra,0x0
    800054a4:	bec080e7          	jalr	-1044(ra) # 8000508c <filealloc>
    800054a8:	00aa3023          	sd	a0,0(s4)
    800054ac:	c92d                	beqz	a0,8000551e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800054ae:	ffffb097          	auipc	ra,0xffffb
    800054b2:	646080e7          	jalr	1606(ra) # 80000af4 <kalloc>
    800054b6:	892a                	mv	s2,a0
    800054b8:	c125                	beqz	a0,80005518 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800054ba:	4985                	li	s3,1
    800054bc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800054c0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800054c4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800054c8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800054cc:	00003597          	auipc	a1,0x3
    800054d0:	35c58593          	addi	a1,a1,860 # 80008828 <syscalls+0x288>
    800054d4:	ffffb097          	auipc	ra,0xffffb
    800054d8:	680080e7          	jalr	1664(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800054dc:	609c                	ld	a5,0(s1)
    800054de:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800054e2:	609c                	ld	a5,0(s1)
    800054e4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800054e8:	609c                	ld	a5,0(s1)
    800054ea:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800054ee:	609c                	ld	a5,0(s1)
    800054f0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800054f4:	000a3783          	ld	a5,0(s4)
    800054f8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800054fc:	000a3783          	ld	a5,0(s4)
    80005500:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005504:	000a3783          	ld	a5,0(s4)
    80005508:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000550c:	000a3783          	ld	a5,0(s4)
    80005510:	0127b823          	sd	s2,16(a5)
  return 0;
    80005514:	4501                	li	a0,0
    80005516:	a025                	j	8000553e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005518:	6088                	ld	a0,0(s1)
    8000551a:	e501                	bnez	a0,80005522 <pipealloc+0xaa>
    8000551c:	a039                	j	8000552a <pipealloc+0xb2>
    8000551e:	6088                	ld	a0,0(s1)
    80005520:	c51d                	beqz	a0,8000554e <pipealloc+0xd6>
    fileclose(*f0);
    80005522:	00000097          	auipc	ra,0x0
    80005526:	c26080e7          	jalr	-986(ra) # 80005148 <fileclose>
  if(*f1)
    8000552a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000552e:	557d                	li	a0,-1
  if(*f1)
    80005530:	c799                	beqz	a5,8000553e <pipealloc+0xc6>
    fileclose(*f1);
    80005532:	853e                	mv	a0,a5
    80005534:	00000097          	auipc	ra,0x0
    80005538:	c14080e7          	jalr	-1004(ra) # 80005148 <fileclose>
  return -1;
    8000553c:	557d                	li	a0,-1
}
    8000553e:	70a2                	ld	ra,40(sp)
    80005540:	7402                	ld	s0,32(sp)
    80005542:	64e2                	ld	s1,24(sp)
    80005544:	6942                	ld	s2,16(sp)
    80005546:	69a2                	ld	s3,8(sp)
    80005548:	6a02                	ld	s4,0(sp)
    8000554a:	6145                	addi	sp,sp,48
    8000554c:	8082                	ret
  return -1;
    8000554e:	557d                	li	a0,-1
    80005550:	b7fd                	j	8000553e <pipealloc+0xc6>

0000000080005552 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005552:	1101                	addi	sp,sp,-32
    80005554:	ec06                	sd	ra,24(sp)
    80005556:	e822                	sd	s0,16(sp)
    80005558:	e426                	sd	s1,8(sp)
    8000555a:	e04a                	sd	s2,0(sp)
    8000555c:	1000                	addi	s0,sp,32
    8000555e:	84aa                	mv	s1,a0
    80005560:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005562:	ffffb097          	auipc	ra,0xffffb
    80005566:	68a080e7          	jalr	1674(ra) # 80000bec <acquire>
  if(writable){
    8000556a:	02090d63          	beqz	s2,800055a4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000556e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005572:	21848513          	addi	a0,s1,536
    80005576:	ffffd097          	auipc	ra,0xffffd
    8000557a:	7bc080e7          	jalr	1980(ra) # 80002d32 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000557e:	2204b783          	ld	a5,544(s1)
    80005582:	eb95                	bnez	a5,800055b6 <pipeclose+0x64>
    release(&pi->lock);
    80005584:	8526                	mv	a0,s1
    80005586:	ffffb097          	auipc	ra,0xffffb
    8000558a:	720080e7          	jalr	1824(ra) # 80000ca6 <release>
    kfree((char*)pi);
    8000558e:	8526                	mv	a0,s1
    80005590:	ffffb097          	auipc	ra,0xffffb
    80005594:	468080e7          	jalr	1128(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005598:	60e2                	ld	ra,24(sp)
    8000559a:	6442                	ld	s0,16(sp)
    8000559c:	64a2                	ld	s1,8(sp)
    8000559e:	6902                	ld	s2,0(sp)
    800055a0:	6105                	addi	sp,sp,32
    800055a2:	8082                	ret
    pi->readopen = 0;
    800055a4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800055a8:	21c48513          	addi	a0,s1,540
    800055ac:	ffffd097          	auipc	ra,0xffffd
    800055b0:	786080e7          	jalr	1926(ra) # 80002d32 <wakeup>
    800055b4:	b7e9                	j	8000557e <pipeclose+0x2c>
    release(&pi->lock);
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffb097          	auipc	ra,0xffffb
    800055bc:	6ee080e7          	jalr	1774(ra) # 80000ca6 <release>
}
    800055c0:	bfe1                	j	80005598 <pipeclose+0x46>

00000000800055c2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800055c2:	7159                	addi	sp,sp,-112
    800055c4:	f486                	sd	ra,104(sp)
    800055c6:	f0a2                	sd	s0,96(sp)
    800055c8:	eca6                	sd	s1,88(sp)
    800055ca:	e8ca                	sd	s2,80(sp)
    800055cc:	e4ce                	sd	s3,72(sp)
    800055ce:	e0d2                	sd	s4,64(sp)
    800055d0:	fc56                	sd	s5,56(sp)
    800055d2:	f85a                	sd	s6,48(sp)
    800055d4:	f45e                	sd	s7,40(sp)
    800055d6:	f062                	sd	s8,32(sp)
    800055d8:	ec66                	sd	s9,24(sp)
    800055da:	1880                	addi	s0,sp,112
    800055dc:	84aa                	mv	s1,a0
    800055de:	8aae                	mv	s5,a1
    800055e0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800055e2:	ffffd097          	auipc	ra,0xffffd
    800055e6:	cee080e7          	jalr	-786(ra) # 800022d0 <myproc>
    800055ea:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800055ec:	8526                	mv	a0,s1
    800055ee:	ffffb097          	auipc	ra,0xffffb
    800055f2:	5fe080e7          	jalr	1534(ra) # 80000bec <acquire>
  while(i < n){
    800055f6:	0d405163          	blez	s4,800056b8 <pipewrite+0xf6>
    800055fa:	8ba6                	mv	s7,s1
  int i = 0;
    800055fc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800055fe:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005600:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005604:	21c48c13          	addi	s8,s1,540
    80005608:	a08d                	j	8000566a <pipewrite+0xa8>
      release(&pi->lock);
    8000560a:	8526                	mv	a0,s1
    8000560c:	ffffb097          	auipc	ra,0xffffb
    80005610:	69a080e7          	jalr	1690(ra) # 80000ca6 <release>
      return -1;
    80005614:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005616:	854a                	mv	a0,s2
    80005618:	70a6                	ld	ra,104(sp)
    8000561a:	7406                	ld	s0,96(sp)
    8000561c:	64e6                	ld	s1,88(sp)
    8000561e:	6946                	ld	s2,80(sp)
    80005620:	69a6                	ld	s3,72(sp)
    80005622:	6a06                	ld	s4,64(sp)
    80005624:	7ae2                	ld	s5,56(sp)
    80005626:	7b42                	ld	s6,48(sp)
    80005628:	7ba2                	ld	s7,40(sp)
    8000562a:	7c02                	ld	s8,32(sp)
    8000562c:	6ce2                	ld	s9,24(sp)
    8000562e:	6165                	addi	sp,sp,112
    80005630:	8082                	ret
      wakeup(&pi->nread);
    80005632:	8566                	mv	a0,s9
    80005634:	ffffd097          	auipc	ra,0xffffd
    80005638:	6fe080e7          	jalr	1790(ra) # 80002d32 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000563c:	85de                	mv	a1,s7
    8000563e:	8562                	mv	a0,s8
    80005640:	ffffd097          	auipc	ra,0xffffd
    80005644:	54e080e7          	jalr	1358(ra) # 80002b8e <sleep>
    80005648:	a839                	j	80005666 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000564a:	21c4a783          	lw	a5,540(s1)
    8000564e:	0017871b          	addiw	a4,a5,1
    80005652:	20e4ae23          	sw	a4,540(s1)
    80005656:	1ff7f793          	andi	a5,a5,511
    8000565a:	97a6                	add	a5,a5,s1
    8000565c:	f9f44703          	lbu	a4,-97(s0)
    80005660:	00e78c23          	sb	a4,24(a5)
      i++;
    80005664:	2905                	addiw	s2,s2,1
  while(i < n){
    80005666:	03495d63          	bge	s2,s4,800056a0 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000566a:	2204a783          	lw	a5,544(s1)
    8000566e:	dfd1                	beqz	a5,8000560a <pipewrite+0x48>
    80005670:	0409a783          	lw	a5,64(s3)
    80005674:	fbd9                	bnez	a5,8000560a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005676:	2184a783          	lw	a5,536(s1)
    8000567a:	21c4a703          	lw	a4,540(s1)
    8000567e:	2007879b          	addiw	a5,a5,512
    80005682:	faf708e3          	beq	a4,a5,80005632 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005686:	4685                	li	a3,1
    80005688:	01590633          	add	a2,s2,s5
    8000568c:	f9f40593          	addi	a1,s0,-97
    80005690:	0789b503          	ld	a0,120(s3)
    80005694:	ffffc097          	auipc	ra,0xffffc
    80005698:	078080e7          	jalr	120(ra) # 8000170c <copyin>
    8000569c:	fb6517e3          	bne	a0,s6,8000564a <pipewrite+0x88>
  wakeup(&pi->nread);
    800056a0:	21848513          	addi	a0,s1,536
    800056a4:	ffffd097          	auipc	ra,0xffffd
    800056a8:	68e080e7          	jalr	1678(ra) # 80002d32 <wakeup>
  release(&pi->lock);
    800056ac:	8526                	mv	a0,s1
    800056ae:	ffffb097          	auipc	ra,0xffffb
    800056b2:	5f8080e7          	jalr	1528(ra) # 80000ca6 <release>
  return i;
    800056b6:	b785                	j	80005616 <pipewrite+0x54>
  int i = 0;
    800056b8:	4901                	li	s2,0
    800056ba:	b7dd                	j	800056a0 <pipewrite+0xde>

00000000800056bc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800056bc:	715d                	addi	sp,sp,-80
    800056be:	e486                	sd	ra,72(sp)
    800056c0:	e0a2                	sd	s0,64(sp)
    800056c2:	fc26                	sd	s1,56(sp)
    800056c4:	f84a                	sd	s2,48(sp)
    800056c6:	f44e                	sd	s3,40(sp)
    800056c8:	f052                	sd	s4,32(sp)
    800056ca:	ec56                	sd	s5,24(sp)
    800056cc:	e85a                	sd	s6,16(sp)
    800056ce:	0880                	addi	s0,sp,80
    800056d0:	84aa                	mv	s1,a0
    800056d2:	892e                	mv	s2,a1
    800056d4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800056d6:	ffffd097          	auipc	ra,0xffffd
    800056da:	bfa080e7          	jalr	-1030(ra) # 800022d0 <myproc>
    800056de:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800056e0:	8b26                	mv	s6,s1
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffb097          	auipc	ra,0xffffb
    800056e8:	508080e7          	jalr	1288(ra) # 80000bec <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056ec:	2184a703          	lw	a4,536(s1)
    800056f0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056f4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056f8:	02f71463          	bne	a4,a5,80005720 <piperead+0x64>
    800056fc:	2244a783          	lw	a5,548(s1)
    80005700:	c385                	beqz	a5,80005720 <piperead+0x64>
    if(pr->killed){
    80005702:	040a2783          	lw	a5,64(s4)
    80005706:	ebc1                	bnez	a5,80005796 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005708:	85da                	mv	a1,s6
    8000570a:	854e                	mv	a0,s3
    8000570c:	ffffd097          	auipc	ra,0xffffd
    80005710:	482080e7          	jalr	1154(ra) # 80002b8e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005714:	2184a703          	lw	a4,536(s1)
    80005718:	21c4a783          	lw	a5,540(s1)
    8000571c:	fef700e3          	beq	a4,a5,800056fc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005720:	09505263          	blez	s5,800057a4 <piperead+0xe8>
    80005724:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005726:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005728:	2184a783          	lw	a5,536(s1)
    8000572c:	21c4a703          	lw	a4,540(s1)
    80005730:	02f70d63          	beq	a4,a5,8000576a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005734:	0017871b          	addiw	a4,a5,1
    80005738:	20e4ac23          	sw	a4,536(s1)
    8000573c:	1ff7f793          	andi	a5,a5,511
    80005740:	97a6                	add	a5,a5,s1
    80005742:	0187c783          	lbu	a5,24(a5)
    80005746:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000574a:	4685                	li	a3,1
    8000574c:	fbf40613          	addi	a2,s0,-65
    80005750:	85ca                	mv	a1,s2
    80005752:	078a3503          	ld	a0,120(s4)
    80005756:	ffffc097          	auipc	ra,0xffffc
    8000575a:	f2a080e7          	jalr	-214(ra) # 80001680 <copyout>
    8000575e:	01650663          	beq	a0,s6,8000576a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005762:	2985                	addiw	s3,s3,1
    80005764:	0905                	addi	s2,s2,1
    80005766:	fd3a91e3          	bne	s5,s3,80005728 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000576a:	21c48513          	addi	a0,s1,540
    8000576e:	ffffd097          	auipc	ra,0xffffd
    80005772:	5c4080e7          	jalr	1476(ra) # 80002d32 <wakeup>
  release(&pi->lock);
    80005776:	8526                	mv	a0,s1
    80005778:	ffffb097          	auipc	ra,0xffffb
    8000577c:	52e080e7          	jalr	1326(ra) # 80000ca6 <release>
  return i;
}
    80005780:	854e                	mv	a0,s3
    80005782:	60a6                	ld	ra,72(sp)
    80005784:	6406                	ld	s0,64(sp)
    80005786:	74e2                	ld	s1,56(sp)
    80005788:	7942                	ld	s2,48(sp)
    8000578a:	79a2                	ld	s3,40(sp)
    8000578c:	7a02                	ld	s4,32(sp)
    8000578e:	6ae2                	ld	s5,24(sp)
    80005790:	6b42                	ld	s6,16(sp)
    80005792:	6161                	addi	sp,sp,80
    80005794:	8082                	ret
      release(&pi->lock);
    80005796:	8526                	mv	a0,s1
    80005798:	ffffb097          	auipc	ra,0xffffb
    8000579c:	50e080e7          	jalr	1294(ra) # 80000ca6 <release>
      return -1;
    800057a0:	59fd                	li	s3,-1
    800057a2:	bff9                	j	80005780 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057a4:	4981                	li	s3,0
    800057a6:	b7d1                	j	8000576a <piperead+0xae>

00000000800057a8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800057a8:	df010113          	addi	sp,sp,-528
    800057ac:	20113423          	sd	ra,520(sp)
    800057b0:	20813023          	sd	s0,512(sp)
    800057b4:	ffa6                	sd	s1,504(sp)
    800057b6:	fbca                	sd	s2,496(sp)
    800057b8:	f7ce                	sd	s3,488(sp)
    800057ba:	f3d2                	sd	s4,480(sp)
    800057bc:	efd6                	sd	s5,472(sp)
    800057be:	ebda                	sd	s6,464(sp)
    800057c0:	e7de                	sd	s7,456(sp)
    800057c2:	e3e2                	sd	s8,448(sp)
    800057c4:	ff66                	sd	s9,440(sp)
    800057c6:	fb6a                	sd	s10,432(sp)
    800057c8:	f76e                	sd	s11,424(sp)
    800057ca:	0c00                	addi	s0,sp,528
    800057cc:	84aa                	mv	s1,a0
    800057ce:	dea43c23          	sd	a0,-520(s0)
    800057d2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800057d6:	ffffd097          	auipc	ra,0xffffd
    800057da:	afa080e7          	jalr	-1286(ra) # 800022d0 <myproc>
    800057de:	892a                	mv	s2,a0

  begin_op();
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	49c080e7          	jalr	1180(ra) # 80004c7c <begin_op>

  if((ip = namei(path)) == 0){
    800057e8:	8526                	mv	a0,s1
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	276080e7          	jalr	630(ra) # 80004a60 <namei>
    800057f2:	c92d                	beqz	a0,80005864 <exec+0xbc>
    800057f4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	ab4080e7          	jalr	-1356(ra) # 800042aa <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800057fe:	04000713          	li	a4,64
    80005802:	4681                	li	a3,0
    80005804:	e5040613          	addi	a2,s0,-432
    80005808:	4581                	li	a1,0
    8000580a:	8526                	mv	a0,s1
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	d52080e7          	jalr	-686(ra) # 8000455e <readi>
    80005814:	04000793          	li	a5,64
    80005818:	00f51a63          	bne	a0,a5,8000582c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000581c:	e5042703          	lw	a4,-432(s0)
    80005820:	464c47b7          	lui	a5,0x464c4
    80005824:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005828:	04f70463          	beq	a4,a5,80005870 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000582c:	8526                	mv	a0,s1
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	cde080e7          	jalr	-802(ra) # 8000450c <iunlockput>
    end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	4c6080e7          	jalr	1222(ra) # 80004cfc <end_op>
  }
  return -1;
    8000583e:	557d                	li	a0,-1
}
    80005840:	20813083          	ld	ra,520(sp)
    80005844:	20013403          	ld	s0,512(sp)
    80005848:	74fe                	ld	s1,504(sp)
    8000584a:	795e                	ld	s2,496(sp)
    8000584c:	79be                	ld	s3,488(sp)
    8000584e:	7a1e                	ld	s4,480(sp)
    80005850:	6afe                	ld	s5,472(sp)
    80005852:	6b5e                	ld	s6,464(sp)
    80005854:	6bbe                	ld	s7,456(sp)
    80005856:	6c1e                	ld	s8,448(sp)
    80005858:	7cfa                	ld	s9,440(sp)
    8000585a:	7d5a                	ld	s10,432(sp)
    8000585c:	7dba                	ld	s11,424(sp)
    8000585e:	21010113          	addi	sp,sp,528
    80005862:	8082                	ret
    end_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	498080e7          	jalr	1176(ra) # 80004cfc <end_op>
    return -1;
    8000586c:	557d                	li	a0,-1
    8000586e:	bfc9                	j	80005840 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005870:	854a                	mv	a0,s2
    80005872:	ffffd097          	auipc	ra,0xffffd
    80005876:	b36080e7          	jalr	-1226(ra) # 800023a8 <proc_pagetable>
    8000587a:	8baa                	mv	s7,a0
    8000587c:	d945                	beqz	a0,8000582c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000587e:	e7042983          	lw	s3,-400(s0)
    80005882:	e8845783          	lhu	a5,-376(s0)
    80005886:	c7ad                	beqz	a5,800058f0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005888:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000588a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000588c:	6c85                	lui	s9,0x1
    8000588e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005892:	def43823          	sd	a5,-528(s0)
    80005896:	a42d                	j	80005ac0 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005898:	00003517          	auipc	a0,0x3
    8000589c:	f9850513          	addi	a0,a0,-104 # 80008830 <syscalls+0x290>
    800058a0:	ffffb097          	auipc	ra,0xffffb
    800058a4:	c9e080e7          	jalr	-866(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800058a8:	8756                	mv	a4,s5
    800058aa:	012d86bb          	addw	a3,s11,s2
    800058ae:	4581                	li	a1,0
    800058b0:	8526                	mv	a0,s1
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	cac080e7          	jalr	-852(ra) # 8000455e <readi>
    800058ba:	2501                	sext.w	a0,a0
    800058bc:	1aaa9963          	bne	s5,a0,80005a6e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800058c0:	6785                	lui	a5,0x1
    800058c2:	0127893b          	addw	s2,a5,s2
    800058c6:	77fd                	lui	a5,0xfffff
    800058c8:	01478a3b          	addw	s4,a5,s4
    800058cc:	1f897163          	bgeu	s2,s8,80005aae <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800058d0:	02091593          	slli	a1,s2,0x20
    800058d4:	9181                	srli	a1,a1,0x20
    800058d6:	95ea                	add	a1,a1,s10
    800058d8:	855e                	mv	a0,s7
    800058da:	ffffb097          	auipc	ra,0xffffb
    800058de:	7a2080e7          	jalr	1954(ra) # 8000107c <walkaddr>
    800058e2:	862a                	mv	a2,a0
    if(pa == 0)
    800058e4:	d955                	beqz	a0,80005898 <exec+0xf0>
      n = PGSIZE;
    800058e6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800058e8:	fd9a70e3          	bgeu	s4,s9,800058a8 <exec+0x100>
      n = sz - i;
    800058ec:	8ad2                	mv	s5,s4
    800058ee:	bf6d                	j	800058a8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800058f0:	4901                	li	s2,0
  iunlockput(ip);
    800058f2:	8526                	mv	a0,s1
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	c18080e7          	jalr	-1000(ra) # 8000450c <iunlockput>
  end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	400080e7          	jalr	1024(ra) # 80004cfc <end_op>
  p = myproc();
    80005904:	ffffd097          	auipc	ra,0xffffd
    80005908:	9cc080e7          	jalr	-1588(ra) # 800022d0 <myproc>
    8000590c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000590e:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80005912:	6785                	lui	a5,0x1
    80005914:	17fd                	addi	a5,a5,-1
    80005916:	993e                	add	s2,s2,a5
    80005918:	757d                	lui	a0,0xfffff
    8000591a:	00a977b3          	and	a5,s2,a0
    8000591e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005922:	6609                	lui	a2,0x2
    80005924:	963e                	add	a2,a2,a5
    80005926:	85be                	mv	a1,a5
    80005928:	855e                	mv	a0,s7
    8000592a:	ffffc097          	auipc	ra,0xffffc
    8000592e:	b06080e7          	jalr	-1274(ra) # 80001430 <uvmalloc>
    80005932:	8b2a                	mv	s6,a0
  ip = 0;
    80005934:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005936:	12050c63          	beqz	a0,80005a6e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000593a:	75f9                	lui	a1,0xffffe
    8000593c:	95aa                	add	a1,a1,a0
    8000593e:	855e                	mv	a0,s7
    80005940:	ffffc097          	auipc	ra,0xffffc
    80005944:	d0e080e7          	jalr	-754(ra) # 8000164e <uvmclear>
  stackbase = sp - PGSIZE;
    80005948:	7c7d                	lui	s8,0xfffff
    8000594a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000594c:	e0043783          	ld	a5,-512(s0)
    80005950:	6388                	ld	a0,0(a5)
    80005952:	c535                	beqz	a0,800059be <exec+0x216>
    80005954:	e9040993          	addi	s3,s0,-368
    80005958:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000595c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000595e:	ffffb097          	auipc	ra,0xffffb
    80005962:	514080e7          	jalr	1300(ra) # 80000e72 <strlen>
    80005966:	2505                	addiw	a0,a0,1
    80005968:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000596c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005970:	13896363          	bltu	s2,s8,80005a96 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005974:	e0043d83          	ld	s11,-512(s0)
    80005978:	000dba03          	ld	s4,0(s11)
    8000597c:	8552                	mv	a0,s4
    8000597e:	ffffb097          	auipc	ra,0xffffb
    80005982:	4f4080e7          	jalr	1268(ra) # 80000e72 <strlen>
    80005986:	0015069b          	addiw	a3,a0,1
    8000598a:	8652                	mv	a2,s4
    8000598c:	85ca                	mv	a1,s2
    8000598e:	855e                	mv	a0,s7
    80005990:	ffffc097          	auipc	ra,0xffffc
    80005994:	cf0080e7          	jalr	-784(ra) # 80001680 <copyout>
    80005998:	10054363          	bltz	a0,80005a9e <exec+0x2f6>
    ustack[argc] = sp;
    8000599c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800059a0:	0485                	addi	s1,s1,1
    800059a2:	008d8793          	addi	a5,s11,8
    800059a6:	e0f43023          	sd	a5,-512(s0)
    800059aa:	008db503          	ld	a0,8(s11)
    800059ae:	c911                	beqz	a0,800059c2 <exec+0x21a>
    if(argc >= MAXARG)
    800059b0:	09a1                	addi	s3,s3,8
    800059b2:	fb3c96e3          	bne	s9,s3,8000595e <exec+0x1b6>
  sz = sz1;
    800059b6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800059ba:	4481                	li	s1,0
    800059bc:	a84d                	j	80005a6e <exec+0x2c6>
  sp = sz;
    800059be:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800059c0:	4481                	li	s1,0
  ustack[argc] = 0;
    800059c2:	00349793          	slli	a5,s1,0x3
    800059c6:	f9040713          	addi	a4,s0,-112
    800059ca:	97ba                	add	a5,a5,a4
    800059cc:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800059d0:	00148693          	addi	a3,s1,1
    800059d4:	068e                	slli	a3,a3,0x3
    800059d6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800059da:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800059de:	01897663          	bgeu	s2,s8,800059ea <exec+0x242>
  sz = sz1;
    800059e2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800059e6:	4481                	li	s1,0
    800059e8:	a059                	j	80005a6e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800059ea:	e9040613          	addi	a2,s0,-368
    800059ee:	85ca                	mv	a1,s2
    800059f0:	855e                	mv	a0,s7
    800059f2:	ffffc097          	auipc	ra,0xffffc
    800059f6:	c8e080e7          	jalr	-882(ra) # 80001680 <copyout>
    800059fa:	0a054663          	bltz	a0,80005aa6 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800059fe:	080ab783          	ld	a5,128(s5)
    80005a02:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005a06:	df843783          	ld	a5,-520(s0)
    80005a0a:	0007c703          	lbu	a4,0(a5)
    80005a0e:	cf11                	beqz	a4,80005a2a <exec+0x282>
    80005a10:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005a12:	02f00693          	li	a3,47
    80005a16:	a039                	j	80005a24 <exec+0x27c>
      last = s+1;
    80005a18:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005a1c:	0785                	addi	a5,a5,1
    80005a1e:	fff7c703          	lbu	a4,-1(a5)
    80005a22:	c701                	beqz	a4,80005a2a <exec+0x282>
    if(*s == '/')
    80005a24:	fed71ce3          	bne	a4,a3,80005a1c <exec+0x274>
    80005a28:	bfc5                	j	80005a18 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005a2a:	4641                	li	a2,16
    80005a2c:	df843583          	ld	a1,-520(s0)
    80005a30:	180a8513          	addi	a0,s5,384
    80005a34:	ffffb097          	auipc	ra,0xffffb
    80005a38:	40c080e7          	jalr	1036(ra) # 80000e40 <safestrcpy>
  oldpagetable = p->pagetable;
    80005a3c:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    80005a40:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    80005a44:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005a48:	080ab783          	ld	a5,128(s5)
    80005a4c:	e6843703          	ld	a4,-408(s0)
    80005a50:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005a52:	080ab783          	ld	a5,128(s5)
    80005a56:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005a5a:	85ea                	mv	a1,s10
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	9e8080e7          	jalr	-1560(ra) # 80002444 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005a64:	0004851b          	sext.w	a0,s1
    80005a68:	bbe1                	j	80005840 <exec+0x98>
    80005a6a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005a6e:	e0843583          	ld	a1,-504(s0)
    80005a72:	855e                	mv	a0,s7
    80005a74:	ffffd097          	auipc	ra,0xffffd
    80005a78:	9d0080e7          	jalr	-1584(ra) # 80002444 <proc_freepagetable>
  if(ip){
    80005a7c:	da0498e3          	bnez	s1,8000582c <exec+0x84>
  return -1;
    80005a80:	557d                	li	a0,-1
    80005a82:	bb7d                	j	80005840 <exec+0x98>
    80005a84:	e1243423          	sd	s2,-504(s0)
    80005a88:	b7dd                	j	80005a6e <exec+0x2c6>
    80005a8a:	e1243423          	sd	s2,-504(s0)
    80005a8e:	b7c5                	j	80005a6e <exec+0x2c6>
    80005a90:	e1243423          	sd	s2,-504(s0)
    80005a94:	bfe9                	j	80005a6e <exec+0x2c6>
  sz = sz1;
    80005a96:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a9a:	4481                	li	s1,0
    80005a9c:	bfc9                	j	80005a6e <exec+0x2c6>
  sz = sz1;
    80005a9e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005aa2:	4481                	li	s1,0
    80005aa4:	b7e9                	j	80005a6e <exec+0x2c6>
  sz = sz1;
    80005aa6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005aaa:	4481                	li	s1,0
    80005aac:	b7c9                	j	80005a6e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005aae:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005ab2:	2b05                	addiw	s6,s6,1
    80005ab4:	0389899b          	addiw	s3,s3,56
    80005ab8:	e8845783          	lhu	a5,-376(s0)
    80005abc:	e2fb5be3          	bge	s6,a5,800058f2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005ac0:	2981                	sext.w	s3,s3
    80005ac2:	03800713          	li	a4,56
    80005ac6:	86ce                	mv	a3,s3
    80005ac8:	e1840613          	addi	a2,s0,-488
    80005acc:	4581                	li	a1,0
    80005ace:	8526                	mv	a0,s1
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	a8e080e7          	jalr	-1394(ra) # 8000455e <readi>
    80005ad8:	03800793          	li	a5,56
    80005adc:	f8f517e3          	bne	a0,a5,80005a6a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005ae0:	e1842783          	lw	a5,-488(s0)
    80005ae4:	4705                	li	a4,1
    80005ae6:	fce796e3          	bne	a5,a4,80005ab2 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005aea:	e4043603          	ld	a2,-448(s0)
    80005aee:	e3843783          	ld	a5,-456(s0)
    80005af2:	f8f669e3          	bltu	a2,a5,80005a84 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005af6:	e2843783          	ld	a5,-472(s0)
    80005afa:	963e                	add	a2,a2,a5
    80005afc:	f8f667e3          	bltu	a2,a5,80005a8a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005b00:	85ca                	mv	a1,s2
    80005b02:	855e                	mv	a0,s7
    80005b04:	ffffc097          	auipc	ra,0xffffc
    80005b08:	92c080e7          	jalr	-1748(ra) # 80001430 <uvmalloc>
    80005b0c:	e0a43423          	sd	a0,-504(s0)
    80005b10:	d141                	beqz	a0,80005a90 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005b12:	e2843d03          	ld	s10,-472(s0)
    80005b16:	df043783          	ld	a5,-528(s0)
    80005b1a:	00fd77b3          	and	a5,s10,a5
    80005b1e:	fba1                	bnez	a5,80005a6e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b20:	e2042d83          	lw	s11,-480(s0)
    80005b24:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005b28:	f80c03e3          	beqz	s8,80005aae <exec+0x306>
    80005b2c:	8a62                	mv	s4,s8
    80005b2e:	4901                	li	s2,0
    80005b30:	b345                	j	800058d0 <exec+0x128>

0000000080005b32 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005b32:	7179                	addi	sp,sp,-48
    80005b34:	f406                	sd	ra,40(sp)
    80005b36:	f022                	sd	s0,32(sp)
    80005b38:	ec26                	sd	s1,24(sp)
    80005b3a:	e84a                	sd	s2,16(sp)
    80005b3c:	1800                	addi	s0,sp,48
    80005b3e:	892e                	mv	s2,a1
    80005b40:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005b42:	fdc40593          	addi	a1,s0,-36
    80005b46:	ffffe097          	auipc	ra,0xffffe
    80005b4a:	ba8080e7          	jalr	-1112(ra) # 800036ee <argint>
    80005b4e:	04054063          	bltz	a0,80005b8e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005b52:	fdc42703          	lw	a4,-36(s0)
    80005b56:	47bd                	li	a5,15
    80005b58:	02e7ed63          	bltu	a5,a4,80005b92 <argfd+0x60>
    80005b5c:	ffffc097          	auipc	ra,0xffffc
    80005b60:	774080e7          	jalr	1908(ra) # 800022d0 <myproc>
    80005b64:	fdc42703          	lw	a4,-36(s0)
    80005b68:	01e70793          	addi	a5,a4,30
    80005b6c:	078e                	slli	a5,a5,0x3
    80005b6e:	953e                	add	a0,a0,a5
    80005b70:	651c                	ld	a5,8(a0)
    80005b72:	c395                	beqz	a5,80005b96 <argfd+0x64>
    return -1;
  if(pfd)
    80005b74:	00090463          	beqz	s2,80005b7c <argfd+0x4a>
    *pfd = fd;
    80005b78:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005b7c:	4501                	li	a0,0
  if(pf)
    80005b7e:	c091                	beqz	s1,80005b82 <argfd+0x50>
    *pf = f;
    80005b80:	e09c                	sd	a5,0(s1)
}
    80005b82:	70a2                	ld	ra,40(sp)
    80005b84:	7402                	ld	s0,32(sp)
    80005b86:	64e2                	ld	s1,24(sp)
    80005b88:	6942                	ld	s2,16(sp)
    80005b8a:	6145                	addi	sp,sp,48
    80005b8c:	8082                	ret
    return -1;
    80005b8e:	557d                	li	a0,-1
    80005b90:	bfcd                	j	80005b82 <argfd+0x50>
    return -1;
    80005b92:	557d                	li	a0,-1
    80005b94:	b7fd                	j	80005b82 <argfd+0x50>
    80005b96:	557d                	li	a0,-1
    80005b98:	b7ed                	j	80005b82 <argfd+0x50>

0000000080005b9a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005b9a:	1101                	addi	sp,sp,-32
    80005b9c:	ec06                	sd	ra,24(sp)
    80005b9e:	e822                	sd	s0,16(sp)
    80005ba0:	e426                	sd	s1,8(sp)
    80005ba2:	1000                	addi	s0,sp,32
    80005ba4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005ba6:	ffffc097          	auipc	ra,0xffffc
    80005baa:	72a080e7          	jalr	1834(ra) # 800022d0 <myproc>
    80005bae:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005bb0:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    80005bb4:	4501                	li	a0,0
    80005bb6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005bb8:	6398                	ld	a4,0(a5)
    80005bba:	cb19                	beqz	a4,80005bd0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005bbc:	2505                	addiw	a0,a0,1
    80005bbe:	07a1                	addi	a5,a5,8
    80005bc0:	fed51ce3          	bne	a0,a3,80005bb8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005bc4:	557d                	li	a0,-1
}
    80005bc6:	60e2                	ld	ra,24(sp)
    80005bc8:	6442                	ld	s0,16(sp)
    80005bca:	64a2                	ld	s1,8(sp)
    80005bcc:	6105                	addi	sp,sp,32
    80005bce:	8082                	ret
      p->ofile[fd] = f;
    80005bd0:	01e50793          	addi	a5,a0,30
    80005bd4:	078e                	slli	a5,a5,0x3
    80005bd6:	963e                	add	a2,a2,a5
    80005bd8:	e604                	sd	s1,8(a2)
      return fd;
    80005bda:	b7f5                	j	80005bc6 <fdalloc+0x2c>

0000000080005bdc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005bdc:	715d                	addi	sp,sp,-80
    80005bde:	e486                	sd	ra,72(sp)
    80005be0:	e0a2                	sd	s0,64(sp)
    80005be2:	fc26                	sd	s1,56(sp)
    80005be4:	f84a                	sd	s2,48(sp)
    80005be6:	f44e                	sd	s3,40(sp)
    80005be8:	f052                	sd	s4,32(sp)
    80005bea:	ec56                	sd	s5,24(sp)
    80005bec:	0880                	addi	s0,sp,80
    80005bee:	89ae                	mv	s3,a1
    80005bf0:	8ab2                	mv	s5,a2
    80005bf2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005bf4:	fb040593          	addi	a1,s0,-80
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	e86080e7          	jalr	-378(ra) # 80004a7e <nameiparent>
    80005c00:	892a                	mv	s2,a0
    80005c02:	12050f63          	beqz	a0,80005d40 <create+0x164>
    return 0;

  ilock(dp);
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	6a4080e7          	jalr	1700(ra) # 800042aa <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005c0e:	4601                	li	a2,0
    80005c10:	fb040593          	addi	a1,s0,-80
    80005c14:	854a                	mv	a0,s2
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	b78080e7          	jalr	-1160(ra) # 8000478e <dirlookup>
    80005c1e:	84aa                	mv	s1,a0
    80005c20:	c921                	beqz	a0,80005c70 <create+0x94>
    iunlockput(dp);
    80005c22:	854a                	mv	a0,s2
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	8e8080e7          	jalr	-1816(ra) # 8000450c <iunlockput>
    ilock(ip);
    80005c2c:	8526                	mv	a0,s1
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	67c080e7          	jalr	1660(ra) # 800042aa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c36:	2981                	sext.w	s3,s3
    80005c38:	4789                	li	a5,2
    80005c3a:	02f99463          	bne	s3,a5,80005c62 <create+0x86>
    80005c3e:	0444d783          	lhu	a5,68(s1)
    80005c42:	37f9                	addiw	a5,a5,-2
    80005c44:	17c2                	slli	a5,a5,0x30
    80005c46:	93c1                	srli	a5,a5,0x30
    80005c48:	4705                	li	a4,1
    80005c4a:	00f76c63          	bltu	a4,a5,80005c62 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005c4e:	8526                	mv	a0,s1
    80005c50:	60a6                	ld	ra,72(sp)
    80005c52:	6406                	ld	s0,64(sp)
    80005c54:	74e2                	ld	s1,56(sp)
    80005c56:	7942                	ld	s2,48(sp)
    80005c58:	79a2                	ld	s3,40(sp)
    80005c5a:	7a02                	ld	s4,32(sp)
    80005c5c:	6ae2                	ld	s5,24(sp)
    80005c5e:	6161                	addi	sp,sp,80
    80005c60:	8082                	ret
    iunlockput(ip);
    80005c62:	8526                	mv	a0,s1
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	8a8080e7          	jalr	-1880(ra) # 8000450c <iunlockput>
    return 0;
    80005c6c:	4481                	li	s1,0
    80005c6e:	b7c5                	j	80005c4e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005c70:	85ce                	mv	a1,s3
    80005c72:	00092503          	lw	a0,0(s2)
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	49c080e7          	jalr	1180(ra) # 80004112 <ialloc>
    80005c7e:	84aa                	mv	s1,a0
    80005c80:	c529                	beqz	a0,80005cca <create+0xee>
  ilock(ip);
    80005c82:	ffffe097          	auipc	ra,0xffffe
    80005c86:	628080e7          	jalr	1576(ra) # 800042aa <ilock>
  ip->major = major;
    80005c8a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005c8e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005c92:	4785                	li	a5,1
    80005c94:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c98:	8526                	mv	a0,s1
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	546080e7          	jalr	1350(ra) # 800041e0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005ca2:	2981                	sext.w	s3,s3
    80005ca4:	4785                	li	a5,1
    80005ca6:	02f98a63          	beq	s3,a5,80005cda <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005caa:	40d0                	lw	a2,4(s1)
    80005cac:	fb040593          	addi	a1,s0,-80
    80005cb0:	854a                	mv	a0,s2
    80005cb2:	fffff097          	auipc	ra,0xfffff
    80005cb6:	cec080e7          	jalr	-788(ra) # 8000499e <dirlink>
    80005cba:	06054b63          	bltz	a0,80005d30 <create+0x154>
  iunlockput(dp);
    80005cbe:	854a                	mv	a0,s2
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	84c080e7          	jalr	-1972(ra) # 8000450c <iunlockput>
  return ip;
    80005cc8:	b759                	j	80005c4e <create+0x72>
    panic("create: ialloc");
    80005cca:	00003517          	auipc	a0,0x3
    80005cce:	b8650513          	addi	a0,a0,-1146 # 80008850 <syscalls+0x2b0>
    80005cd2:	ffffb097          	auipc	ra,0xffffb
    80005cd6:	86c080e7          	jalr	-1940(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005cda:	04a95783          	lhu	a5,74(s2)
    80005cde:	2785                	addiw	a5,a5,1
    80005ce0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005ce4:	854a                	mv	a0,s2
    80005ce6:	ffffe097          	auipc	ra,0xffffe
    80005cea:	4fa080e7          	jalr	1274(ra) # 800041e0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005cee:	40d0                	lw	a2,4(s1)
    80005cf0:	00003597          	auipc	a1,0x3
    80005cf4:	b7058593          	addi	a1,a1,-1168 # 80008860 <syscalls+0x2c0>
    80005cf8:	8526                	mv	a0,s1
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	ca4080e7          	jalr	-860(ra) # 8000499e <dirlink>
    80005d02:	00054f63          	bltz	a0,80005d20 <create+0x144>
    80005d06:	00492603          	lw	a2,4(s2)
    80005d0a:	00003597          	auipc	a1,0x3
    80005d0e:	b5e58593          	addi	a1,a1,-1186 # 80008868 <syscalls+0x2c8>
    80005d12:	8526                	mv	a0,s1
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	c8a080e7          	jalr	-886(ra) # 8000499e <dirlink>
    80005d1c:	f80557e3          	bgez	a0,80005caa <create+0xce>
      panic("create dots");
    80005d20:	00003517          	auipc	a0,0x3
    80005d24:	b5050513          	addi	a0,a0,-1200 # 80008870 <syscalls+0x2d0>
    80005d28:	ffffb097          	auipc	ra,0xffffb
    80005d2c:	816080e7          	jalr	-2026(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005d30:	00003517          	auipc	a0,0x3
    80005d34:	b5050513          	addi	a0,a0,-1200 # 80008880 <syscalls+0x2e0>
    80005d38:	ffffb097          	auipc	ra,0xffffb
    80005d3c:	806080e7          	jalr	-2042(ra) # 8000053e <panic>
    return 0;
    80005d40:	84aa                	mv	s1,a0
    80005d42:	b731                	j	80005c4e <create+0x72>

0000000080005d44 <sys_dup>:
{
    80005d44:	7179                	addi	sp,sp,-48
    80005d46:	f406                	sd	ra,40(sp)
    80005d48:	f022                	sd	s0,32(sp)
    80005d4a:	ec26                	sd	s1,24(sp)
    80005d4c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005d4e:	fd840613          	addi	a2,s0,-40
    80005d52:	4581                	li	a1,0
    80005d54:	4501                	li	a0,0
    80005d56:	00000097          	auipc	ra,0x0
    80005d5a:	ddc080e7          	jalr	-548(ra) # 80005b32 <argfd>
    return -1;
    80005d5e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005d60:	02054363          	bltz	a0,80005d86 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005d64:	fd843503          	ld	a0,-40(s0)
    80005d68:	00000097          	auipc	ra,0x0
    80005d6c:	e32080e7          	jalr	-462(ra) # 80005b9a <fdalloc>
    80005d70:	84aa                	mv	s1,a0
    return -1;
    80005d72:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005d74:	00054963          	bltz	a0,80005d86 <sys_dup+0x42>
  filedup(f);
    80005d78:	fd843503          	ld	a0,-40(s0)
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	37a080e7          	jalr	890(ra) # 800050f6 <filedup>
  return fd;
    80005d84:	87a6                	mv	a5,s1
}
    80005d86:	853e                	mv	a0,a5
    80005d88:	70a2                	ld	ra,40(sp)
    80005d8a:	7402                	ld	s0,32(sp)
    80005d8c:	64e2                	ld	s1,24(sp)
    80005d8e:	6145                	addi	sp,sp,48
    80005d90:	8082                	ret

0000000080005d92 <sys_read>:
{
    80005d92:	7179                	addi	sp,sp,-48
    80005d94:	f406                	sd	ra,40(sp)
    80005d96:	f022                	sd	s0,32(sp)
    80005d98:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d9a:	fe840613          	addi	a2,s0,-24
    80005d9e:	4581                	li	a1,0
    80005da0:	4501                	li	a0,0
    80005da2:	00000097          	auipc	ra,0x0
    80005da6:	d90080e7          	jalr	-624(ra) # 80005b32 <argfd>
    return -1;
    80005daa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dac:	04054163          	bltz	a0,80005dee <sys_read+0x5c>
    80005db0:	fe440593          	addi	a1,s0,-28
    80005db4:	4509                	li	a0,2
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	938080e7          	jalr	-1736(ra) # 800036ee <argint>
    return -1;
    80005dbe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dc0:	02054763          	bltz	a0,80005dee <sys_read+0x5c>
    80005dc4:	fd840593          	addi	a1,s0,-40
    80005dc8:	4505                	li	a0,1
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	946080e7          	jalr	-1722(ra) # 80003710 <argaddr>
    return -1;
    80005dd2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dd4:	00054d63          	bltz	a0,80005dee <sys_read+0x5c>
  return fileread(f, p, n);
    80005dd8:	fe442603          	lw	a2,-28(s0)
    80005ddc:	fd843583          	ld	a1,-40(s0)
    80005de0:	fe843503          	ld	a0,-24(s0)
    80005de4:	fffff097          	auipc	ra,0xfffff
    80005de8:	49e080e7          	jalr	1182(ra) # 80005282 <fileread>
    80005dec:	87aa                	mv	a5,a0
}
    80005dee:	853e                	mv	a0,a5
    80005df0:	70a2                	ld	ra,40(sp)
    80005df2:	7402                	ld	s0,32(sp)
    80005df4:	6145                	addi	sp,sp,48
    80005df6:	8082                	ret

0000000080005df8 <sys_write>:
{
    80005df8:	7179                	addi	sp,sp,-48
    80005dfa:	f406                	sd	ra,40(sp)
    80005dfc:	f022                	sd	s0,32(sp)
    80005dfe:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e00:	fe840613          	addi	a2,s0,-24
    80005e04:	4581                	li	a1,0
    80005e06:	4501                	li	a0,0
    80005e08:	00000097          	auipc	ra,0x0
    80005e0c:	d2a080e7          	jalr	-726(ra) # 80005b32 <argfd>
    return -1;
    80005e10:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e12:	04054163          	bltz	a0,80005e54 <sys_write+0x5c>
    80005e16:	fe440593          	addi	a1,s0,-28
    80005e1a:	4509                	li	a0,2
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	8d2080e7          	jalr	-1838(ra) # 800036ee <argint>
    return -1;
    80005e24:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e26:	02054763          	bltz	a0,80005e54 <sys_write+0x5c>
    80005e2a:	fd840593          	addi	a1,s0,-40
    80005e2e:	4505                	li	a0,1
    80005e30:	ffffe097          	auipc	ra,0xffffe
    80005e34:	8e0080e7          	jalr	-1824(ra) # 80003710 <argaddr>
    return -1;
    80005e38:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e3a:	00054d63          	bltz	a0,80005e54 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005e3e:	fe442603          	lw	a2,-28(s0)
    80005e42:	fd843583          	ld	a1,-40(s0)
    80005e46:	fe843503          	ld	a0,-24(s0)
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	4fa080e7          	jalr	1274(ra) # 80005344 <filewrite>
    80005e52:	87aa                	mv	a5,a0
}
    80005e54:	853e                	mv	a0,a5
    80005e56:	70a2                	ld	ra,40(sp)
    80005e58:	7402                	ld	s0,32(sp)
    80005e5a:	6145                	addi	sp,sp,48
    80005e5c:	8082                	ret

0000000080005e5e <sys_close>:
{
    80005e5e:	1101                	addi	sp,sp,-32
    80005e60:	ec06                	sd	ra,24(sp)
    80005e62:	e822                	sd	s0,16(sp)
    80005e64:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005e66:	fe040613          	addi	a2,s0,-32
    80005e6a:	fec40593          	addi	a1,s0,-20
    80005e6e:	4501                	li	a0,0
    80005e70:	00000097          	auipc	ra,0x0
    80005e74:	cc2080e7          	jalr	-830(ra) # 80005b32 <argfd>
    return -1;
    80005e78:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005e7a:	02054463          	bltz	a0,80005ea2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005e7e:	ffffc097          	auipc	ra,0xffffc
    80005e82:	452080e7          	jalr	1106(ra) # 800022d0 <myproc>
    80005e86:	fec42783          	lw	a5,-20(s0)
    80005e8a:	07f9                	addi	a5,a5,30
    80005e8c:	078e                	slli	a5,a5,0x3
    80005e8e:	97aa                	add	a5,a5,a0
    80005e90:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005e94:	fe043503          	ld	a0,-32(s0)
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	2b0080e7          	jalr	688(ra) # 80005148 <fileclose>
  return 0;
    80005ea0:	4781                	li	a5,0
}
    80005ea2:	853e                	mv	a0,a5
    80005ea4:	60e2                	ld	ra,24(sp)
    80005ea6:	6442                	ld	s0,16(sp)
    80005ea8:	6105                	addi	sp,sp,32
    80005eaa:	8082                	ret

0000000080005eac <sys_fstat>:
{
    80005eac:	1101                	addi	sp,sp,-32
    80005eae:	ec06                	sd	ra,24(sp)
    80005eb0:	e822                	sd	s0,16(sp)
    80005eb2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005eb4:	fe840613          	addi	a2,s0,-24
    80005eb8:	4581                	li	a1,0
    80005eba:	4501                	li	a0,0
    80005ebc:	00000097          	auipc	ra,0x0
    80005ec0:	c76080e7          	jalr	-906(ra) # 80005b32 <argfd>
    return -1;
    80005ec4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ec6:	02054563          	bltz	a0,80005ef0 <sys_fstat+0x44>
    80005eca:	fe040593          	addi	a1,s0,-32
    80005ece:	4505                	li	a0,1
    80005ed0:	ffffe097          	auipc	ra,0xffffe
    80005ed4:	840080e7          	jalr	-1984(ra) # 80003710 <argaddr>
    return -1;
    80005ed8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005eda:	00054b63          	bltz	a0,80005ef0 <sys_fstat+0x44>
  return filestat(f, st);
    80005ede:	fe043583          	ld	a1,-32(s0)
    80005ee2:	fe843503          	ld	a0,-24(s0)
    80005ee6:	fffff097          	auipc	ra,0xfffff
    80005eea:	32a080e7          	jalr	810(ra) # 80005210 <filestat>
    80005eee:	87aa                	mv	a5,a0
}
    80005ef0:	853e                	mv	a0,a5
    80005ef2:	60e2                	ld	ra,24(sp)
    80005ef4:	6442                	ld	s0,16(sp)
    80005ef6:	6105                	addi	sp,sp,32
    80005ef8:	8082                	ret

0000000080005efa <sys_link>:
{
    80005efa:	7169                	addi	sp,sp,-304
    80005efc:	f606                	sd	ra,296(sp)
    80005efe:	f222                	sd	s0,288(sp)
    80005f00:	ee26                	sd	s1,280(sp)
    80005f02:	ea4a                	sd	s2,272(sp)
    80005f04:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f06:	08000613          	li	a2,128
    80005f0a:	ed040593          	addi	a1,s0,-304
    80005f0e:	4501                	li	a0,0
    80005f10:	ffffe097          	auipc	ra,0xffffe
    80005f14:	822080e7          	jalr	-2014(ra) # 80003732 <argstr>
    return -1;
    80005f18:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f1a:	10054e63          	bltz	a0,80006036 <sys_link+0x13c>
    80005f1e:	08000613          	li	a2,128
    80005f22:	f5040593          	addi	a1,s0,-176
    80005f26:	4505                	li	a0,1
    80005f28:	ffffe097          	auipc	ra,0xffffe
    80005f2c:	80a080e7          	jalr	-2038(ra) # 80003732 <argstr>
    return -1;
    80005f30:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f32:	10054263          	bltz	a0,80006036 <sys_link+0x13c>
  begin_op();
    80005f36:	fffff097          	auipc	ra,0xfffff
    80005f3a:	d46080e7          	jalr	-698(ra) # 80004c7c <begin_op>
  if((ip = namei(old)) == 0){
    80005f3e:	ed040513          	addi	a0,s0,-304
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	b1e080e7          	jalr	-1250(ra) # 80004a60 <namei>
    80005f4a:	84aa                	mv	s1,a0
    80005f4c:	c551                	beqz	a0,80005fd8 <sys_link+0xde>
  ilock(ip);
    80005f4e:	ffffe097          	auipc	ra,0xffffe
    80005f52:	35c080e7          	jalr	860(ra) # 800042aa <ilock>
  if(ip->type == T_DIR){
    80005f56:	04449703          	lh	a4,68(s1)
    80005f5a:	4785                	li	a5,1
    80005f5c:	08f70463          	beq	a4,a5,80005fe4 <sys_link+0xea>
  ip->nlink++;
    80005f60:	04a4d783          	lhu	a5,74(s1)
    80005f64:	2785                	addiw	a5,a5,1
    80005f66:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f6a:	8526                	mv	a0,s1
    80005f6c:	ffffe097          	auipc	ra,0xffffe
    80005f70:	274080e7          	jalr	628(ra) # 800041e0 <iupdate>
  iunlock(ip);
    80005f74:	8526                	mv	a0,s1
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	3f6080e7          	jalr	1014(ra) # 8000436c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005f7e:	fd040593          	addi	a1,s0,-48
    80005f82:	f5040513          	addi	a0,s0,-176
    80005f86:	fffff097          	auipc	ra,0xfffff
    80005f8a:	af8080e7          	jalr	-1288(ra) # 80004a7e <nameiparent>
    80005f8e:	892a                	mv	s2,a0
    80005f90:	c935                	beqz	a0,80006004 <sys_link+0x10a>
  ilock(dp);
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	318080e7          	jalr	792(ra) # 800042aa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005f9a:	00092703          	lw	a4,0(s2)
    80005f9e:	409c                	lw	a5,0(s1)
    80005fa0:	04f71d63          	bne	a4,a5,80005ffa <sys_link+0x100>
    80005fa4:	40d0                	lw	a2,4(s1)
    80005fa6:	fd040593          	addi	a1,s0,-48
    80005faa:	854a                	mv	a0,s2
    80005fac:	fffff097          	auipc	ra,0xfffff
    80005fb0:	9f2080e7          	jalr	-1550(ra) # 8000499e <dirlink>
    80005fb4:	04054363          	bltz	a0,80005ffa <sys_link+0x100>
  iunlockput(dp);
    80005fb8:	854a                	mv	a0,s2
    80005fba:	ffffe097          	auipc	ra,0xffffe
    80005fbe:	552080e7          	jalr	1362(ra) # 8000450c <iunlockput>
  iput(ip);
    80005fc2:	8526                	mv	a0,s1
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	4a0080e7          	jalr	1184(ra) # 80004464 <iput>
  end_op();
    80005fcc:	fffff097          	auipc	ra,0xfffff
    80005fd0:	d30080e7          	jalr	-720(ra) # 80004cfc <end_op>
  return 0;
    80005fd4:	4781                	li	a5,0
    80005fd6:	a085                	j	80006036 <sys_link+0x13c>
    end_op();
    80005fd8:	fffff097          	auipc	ra,0xfffff
    80005fdc:	d24080e7          	jalr	-732(ra) # 80004cfc <end_op>
    return -1;
    80005fe0:	57fd                	li	a5,-1
    80005fe2:	a891                	j	80006036 <sys_link+0x13c>
    iunlockput(ip);
    80005fe4:	8526                	mv	a0,s1
    80005fe6:	ffffe097          	auipc	ra,0xffffe
    80005fea:	526080e7          	jalr	1318(ra) # 8000450c <iunlockput>
    end_op();
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	d0e080e7          	jalr	-754(ra) # 80004cfc <end_op>
    return -1;
    80005ff6:	57fd                	li	a5,-1
    80005ff8:	a83d                	j	80006036 <sys_link+0x13c>
    iunlockput(dp);
    80005ffa:	854a                	mv	a0,s2
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	510080e7          	jalr	1296(ra) # 8000450c <iunlockput>
  ilock(ip);
    80006004:	8526                	mv	a0,s1
    80006006:	ffffe097          	auipc	ra,0xffffe
    8000600a:	2a4080e7          	jalr	676(ra) # 800042aa <ilock>
  ip->nlink--;
    8000600e:	04a4d783          	lhu	a5,74(s1)
    80006012:	37fd                	addiw	a5,a5,-1
    80006014:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006018:	8526                	mv	a0,s1
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	1c6080e7          	jalr	454(ra) # 800041e0 <iupdate>
  iunlockput(ip);
    80006022:	8526                	mv	a0,s1
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	4e8080e7          	jalr	1256(ra) # 8000450c <iunlockput>
  end_op();
    8000602c:	fffff097          	auipc	ra,0xfffff
    80006030:	cd0080e7          	jalr	-816(ra) # 80004cfc <end_op>
  return -1;
    80006034:	57fd                	li	a5,-1
}
    80006036:	853e                	mv	a0,a5
    80006038:	70b2                	ld	ra,296(sp)
    8000603a:	7412                	ld	s0,288(sp)
    8000603c:	64f2                	ld	s1,280(sp)
    8000603e:	6952                	ld	s2,272(sp)
    80006040:	6155                	addi	sp,sp,304
    80006042:	8082                	ret

0000000080006044 <sys_unlink>:
{
    80006044:	7151                	addi	sp,sp,-240
    80006046:	f586                	sd	ra,232(sp)
    80006048:	f1a2                	sd	s0,224(sp)
    8000604a:	eda6                	sd	s1,216(sp)
    8000604c:	e9ca                	sd	s2,208(sp)
    8000604e:	e5ce                	sd	s3,200(sp)
    80006050:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006052:	08000613          	li	a2,128
    80006056:	f3040593          	addi	a1,s0,-208
    8000605a:	4501                	li	a0,0
    8000605c:	ffffd097          	auipc	ra,0xffffd
    80006060:	6d6080e7          	jalr	1750(ra) # 80003732 <argstr>
    80006064:	18054163          	bltz	a0,800061e6 <sys_unlink+0x1a2>
  begin_op();
    80006068:	fffff097          	auipc	ra,0xfffff
    8000606c:	c14080e7          	jalr	-1004(ra) # 80004c7c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006070:	fb040593          	addi	a1,s0,-80
    80006074:	f3040513          	addi	a0,s0,-208
    80006078:	fffff097          	auipc	ra,0xfffff
    8000607c:	a06080e7          	jalr	-1530(ra) # 80004a7e <nameiparent>
    80006080:	84aa                	mv	s1,a0
    80006082:	c979                	beqz	a0,80006158 <sys_unlink+0x114>
  ilock(dp);
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	226080e7          	jalr	550(ra) # 800042aa <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000608c:	00002597          	auipc	a1,0x2
    80006090:	7d458593          	addi	a1,a1,2004 # 80008860 <syscalls+0x2c0>
    80006094:	fb040513          	addi	a0,s0,-80
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	6dc080e7          	jalr	1756(ra) # 80004774 <namecmp>
    800060a0:	14050a63          	beqz	a0,800061f4 <sys_unlink+0x1b0>
    800060a4:	00002597          	auipc	a1,0x2
    800060a8:	7c458593          	addi	a1,a1,1988 # 80008868 <syscalls+0x2c8>
    800060ac:	fb040513          	addi	a0,s0,-80
    800060b0:	ffffe097          	auipc	ra,0xffffe
    800060b4:	6c4080e7          	jalr	1732(ra) # 80004774 <namecmp>
    800060b8:	12050e63          	beqz	a0,800061f4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800060bc:	f2c40613          	addi	a2,s0,-212
    800060c0:	fb040593          	addi	a1,s0,-80
    800060c4:	8526                	mv	a0,s1
    800060c6:	ffffe097          	auipc	ra,0xffffe
    800060ca:	6c8080e7          	jalr	1736(ra) # 8000478e <dirlookup>
    800060ce:	892a                	mv	s2,a0
    800060d0:	12050263          	beqz	a0,800061f4 <sys_unlink+0x1b0>
  ilock(ip);
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	1d6080e7          	jalr	470(ra) # 800042aa <ilock>
  if(ip->nlink < 1)
    800060dc:	04a91783          	lh	a5,74(s2)
    800060e0:	08f05263          	blez	a5,80006164 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800060e4:	04491703          	lh	a4,68(s2)
    800060e8:	4785                	li	a5,1
    800060ea:	08f70563          	beq	a4,a5,80006174 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800060ee:	4641                	li	a2,16
    800060f0:	4581                	li	a1,0
    800060f2:	fc040513          	addi	a0,s0,-64
    800060f6:	ffffb097          	auipc	ra,0xffffb
    800060fa:	bf8080e7          	jalr	-1032(ra) # 80000cee <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060fe:	4741                	li	a4,16
    80006100:	f2c42683          	lw	a3,-212(s0)
    80006104:	fc040613          	addi	a2,s0,-64
    80006108:	4581                	li	a1,0
    8000610a:	8526                	mv	a0,s1
    8000610c:	ffffe097          	auipc	ra,0xffffe
    80006110:	54a080e7          	jalr	1354(ra) # 80004656 <writei>
    80006114:	47c1                	li	a5,16
    80006116:	0af51563          	bne	a0,a5,800061c0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000611a:	04491703          	lh	a4,68(s2)
    8000611e:	4785                	li	a5,1
    80006120:	0af70863          	beq	a4,a5,800061d0 <sys_unlink+0x18c>
  iunlockput(dp);
    80006124:	8526                	mv	a0,s1
    80006126:	ffffe097          	auipc	ra,0xffffe
    8000612a:	3e6080e7          	jalr	998(ra) # 8000450c <iunlockput>
  ip->nlink--;
    8000612e:	04a95783          	lhu	a5,74(s2)
    80006132:	37fd                	addiw	a5,a5,-1
    80006134:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006138:	854a                	mv	a0,s2
    8000613a:	ffffe097          	auipc	ra,0xffffe
    8000613e:	0a6080e7          	jalr	166(ra) # 800041e0 <iupdate>
  iunlockput(ip);
    80006142:	854a                	mv	a0,s2
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	3c8080e7          	jalr	968(ra) # 8000450c <iunlockput>
  end_op();
    8000614c:	fffff097          	auipc	ra,0xfffff
    80006150:	bb0080e7          	jalr	-1104(ra) # 80004cfc <end_op>
  return 0;
    80006154:	4501                	li	a0,0
    80006156:	a84d                	j	80006208 <sys_unlink+0x1c4>
    end_op();
    80006158:	fffff097          	auipc	ra,0xfffff
    8000615c:	ba4080e7          	jalr	-1116(ra) # 80004cfc <end_op>
    return -1;
    80006160:	557d                	li	a0,-1
    80006162:	a05d                	j	80006208 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006164:	00002517          	auipc	a0,0x2
    80006168:	72c50513          	addi	a0,a0,1836 # 80008890 <syscalls+0x2f0>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d2080e7          	jalr	978(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006174:	04c92703          	lw	a4,76(s2)
    80006178:	02000793          	li	a5,32
    8000617c:	f6e7f9e3          	bgeu	a5,a4,800060ee <sys_unlink+0xaa>
    80006180:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006184:	4741                	li	a4,16
    80006186:	86ce                	mv	a3,s3
    80006188:	f1840613          	addi	a2,s0,-232
    8000618c:	4581                	li	a1,0
    8000618e:	854a                	mv	a0,s2
    80006190:	ffffe097          	auipc	ra,0xffffe
    80006194:	3ce080e7          	jalr	974(ra) # 8000455e <readi>
    80006198:	47c1                	li	a5,16
    8000619a:	00f51b63          	bne	a0,a5,800061b0 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000619e:	f1845783          	lhu	a5,-232(s0)
    800061a2:	e7a1                	bnez	a5,800061ea <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061a4:	29c1                	addiw	s3,s3,16
    800061a6:	04c92783          	lw	a5,76(s2)
    800061aa:	fcf9ede3          	bltu	s3,a5,80006184 <sys_unlink+0x140>
    800061ae:	b781                	j	800060ee <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800061b0:	00002517          	auipc	a0,0x2
    800061b4:	6f850513          	addi	a0,a0,1784 # 800088a8 <syscalls+0x308>
    800061b8:	ffffa097          	auipc	ra,0xffffa
    800061bc:	386080e7          	jalr	902(ra) # 8000053e <panic>
    panic("unlink: writei");
    800061c0:	00002517          	auipc	a0,0x2
    800061c4:	70050513          	addi	a0,a0,1792 # 800088c0 <syscalls+0x320>
    800061c8:	ffffa097          	auipc	ra,0xffffa
    800061cc:	376080e7          	jalr	886(ra) # 8000053e <panic>
    dp->nlink--;
    800061d0:	04a4d783          	lhu	a5,74(s1)
    800061d4:	37fd                	addiw	a5,a5,-1
    800061d6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800061da:	8526                	mv	a0,s1
    800061dc:	ffffe097          	auipc	ra,0xffffe
    800061e0:	004080e7          	jalr	4(ra) # 800041e0 <iupdate>
    800061e4:	b781                	j	80006124 <sys_unlink+0xe0>
    return -1;
    800061e6:	557d                	li	a0,-1
    800061e8:	a005                	j	80006208 <sys_unlink+0x1c4>
    iunlockput(ip);
    800061ea:	854a                	mv	a0,s2
    800061ec:	ffffe097          	auipc	ra,0xffffe
    800061f0:	320080e7          	jalr	800(ra) # 8000450c <iunlockput>
  iunlockput(dp);
    800061f4:	8526                	mv	a0,s1
    800061f6:	ffffe097          	auipc	ra,0xffffe
    800061fa:	316080e7          	jalr	790(ra) # 8000450c <iunlockput>
  end_op();
    800061fe:	fffff097          	auipc	ra,0xfffff
    80006202:	afe080e7          	jalr	-1282(ra) # 80004cfc <end_op>
  return -1;
    80006206:	557d                	li	a0,-1
}
    80006208:	70ae                	ld	ra,232(sp)
    8000620a:	740e                	ld	s0,224(sp)
    8000620c:	64ee                	ld	s1,216(sp)
    8000620e:	694e                	ld	s2,208(sp)
    80006210:	69ae                	ld	s3,200(sp)
    80006212:	616d                	addi	sp,sp,240
    80006214:	8082                	ret

0000000080006216 <sys_open>:

uint64
sys_open(void)
{
    80006216:	7131                	addi	sp,sp,-192
    80006218:	fd06                	sd	ra,184(sp)
    8000621a:	f922                	sd	s0,176(sp)
    8000621c:	f526                	sd	s1,168(sp)
    8000621e:	f14a                	sd	s2,160(sp)
    80006220:	ed4e                	sd	s3,152(sp)
    80006222:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006224:	08000613          	li	a2,128
    80006228:	f5040593          	addi	a1,s0,-176
    8000622c:	4501                	li	a0,0
    8000622e:	ffffd097          	auipc	ra,0xffffd
    80006232:	504080e7          	jalr	1284(ra) # 80003732 <argstr>
    return -1;
    80006236:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006238:	0c054163          	bltz	a0,800062fa <sys_open+0xe4>
    8000623c:	f4c40593          	addi	a1,s0,-180
    80006240:	4505                	li	a0,1
    80006242:	ffffd097          	auipc	ra,0xffffd
    80006246:	4ac080e7          	jalr	1196(ra) # 800036ee <argint>
    8000624a:	0a054863          	bltz	a0,800062fa <sys_open+0xe4>

  begin_op();
    8000624e:	fffff097          	auipc	ra,0xfffff
    80006252:	a2e080e7          	jalr	-1490(ra) # 80004c7c <begin_op>

  if(omode & O_CREATE){
    80006256:	f4c42783          	lw	a5,-180(s0)
    8000625a:	2007f793          	andi	a5,a5,512
    8000625e:	cbdd                	beqz	a5,80006314 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006260:	4681                	li	a3,0
    80006262:	4601                	li	a2,0
    80006264:	4589                	li	a1,2
    80006266:	f5040513          	addi	a0,s0,-176
    8000626a:	00000097          	auipc	ra,0x0
    8000626e:	972080e7          	jalr	-1678(ra) # 80005bdc <create>
    80006272:	892a                	mv	s2,a0
    if(ip == 0){
    80006274:	c959                	beqz	a0,8000630a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006276:	04491703          	lh	a4,68(s2)
    8000627a:	478d                	li	a5,3
    8000627c:	00f71763          	bne	a4,a5,8000628a <sys_open+0x74>
    80006280:	04695703          	lhu	a4,70(s2)
    80006284:	47a5                	li	a5,9
    80006286:	0ce7ec63          	bltu	a5,a4,8000635e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000628a:	fffff097          	auipc	ra,0xfffff
    8000628e:	e02080e7          	jalr	-510(ra) # 8000508c <filealloc>
    80006292:	89aa                	mv	s3,a0
    80006294:	10050263          	beqz	a0,80006398 <sys_open+0x182>
    80006298:	00000097          	auipc	ra,0x0
    8000629c:	902080e7          	jalr	-1790(ra) # 80005b9a <fdalloc>
    800062a0:	84aa                	mv	s1,a0
    800062a2:	0e054663          	bltz	a0,8000638e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800062a6:	04491703          	lh	a4,68(s2)
    800062aa:	478d                	li	a5,3
    800062ac:	0cf70463          	beq	a4,a5,80006374 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800062b0:	4789                	li	a5,2
    800062b2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800062b6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800062ba:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800062be:	f4c42783          	lw	a5,-180(s0)
    800062c2:	0017c713          	xori	a4,a5,1
    800062c6:	8b05                	andi	a4,a4,1
    800062c8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800062cc:	0037f713          	andi	a4,a5,3
    800062d0:	00e03733          	snez	a4,a4
    800062d4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800062d8:	4007f793          	andi	a5,a5,1024
    800062dc:	c791                	beqz	a5,800062e8 <sys_open+0xd2>
    800062de:	04491703          	lh	a4,68(s2)
    800062e2:	4789                	li	a5,2
    800062e4:	08f70f63          	beq	a4,a5,80006382 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800062e8:	854a                	mv	a0,s2
    800062ea:	ffffe097          	auipc	ra,0xffffe
    800062ee:	082080e7          	jalr	130(ra) # 8000436c <iunlock>
  end_op();
    800062f2:	fffff097          	auipc	ra,0xfffff
    800062f6:	a0a080e7          	jalr	-1526(ra) # 80004cfc <end_op>

  return fd;
}
    800062fa:	8526                	mv	a0,s1
    800062fc:	70ea                	ld	ra,184(sp)
    800062fe:	744a                	ld	s0,176(sp)
    80006300:	74aa                	ld	s1,168(sp)
    80006302:	790a                	ld	s2,160(sp)
    80006304:	69ea                	ld	s3,152(sp)
    80006306:	6129                	addi	sp,sp,192
    80006308:	8082                	ret
      end_op();
    8000630a:	fffff097          	auipc	ra,0xfffff
    8000630e:	9f2080e7          	jalr	-1550(ra) # 80004cfc <end_op>
      return -1;
    80006312:	b7e5                	j	800062fa <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006314:	f5040513          	addi	a0,s0,-176
    80006318:	ffffe097          	auipc	ra,0xffffe
    8000631c:	748080e7          	jalr	1864(ra) # 80004a60 <namei>
    80006320:	892a                	mv	s2,a0
    80006322:	c905                	beqz	a0,80006352 <sys_open+0x13c>
    ilock(ip);
    80006324:	ffffe097          	auipc	ra,0xffffe
    80006328:	f86080e7          	jalr	-122(ra) # 800042aa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000632c:	04491703          	lh	a4,68(s2)
    80006330:	4785                	li	a5,1
    80006332:	f4f712e3          	bne	a4,a5,80006276 <sys_open+0x60>
    80006336:	f4c42783          	lw	a5,-180(s0)
    8000633a:	dba1                	beqz	a5,8000628a <sys_open+0x74>
      iunlockput(ip);
    8000633c:	854a                	mv	a0,s2
    8000633e:	ffffe097          	auipc	ra,0xffffe
    80006342:	1ce080e7          	jalr	462(ra) # 8000450c <iunlockput>
      end_op();
    80006346:	fffff097          	auipc	ra,0xfffff
    8000634a:	9b6080e7          	jalr	-1610(ra) # 80004cfc <end_op>
      return -1;
    8000634e:	54fd                	li	s1,-1
    80006350:	b76d                	j	800062fa <sys_open+0xe4>
      end_op();
    80006352:	fffff097          	auipc	ra,0xfffff
    80006356:	9aa080e7          	jalr	-1622(ra) # 80004cfc <end_op>
      return -1;
    8000635a:	54fd                	li	s1,-1
    8000635c:	bf79                	j	800062fa <sys_open+0xe4>
    iunlockput(ip);
    8000635e:	854a                	mv	a0,s2
    80006360:	ffffe097          	auipc	ra,0xffffe
    80006364:	1ac080e7          	jalr	428(ra) # 8000450c <iunlockput>
    end_op();
    80006368:	fffff097          	auipc	ra,0xfffff
    8000636c:	994080e7          	jalr	-1644(ra) # 80004cfc <end_op>
    return -1;
    80006370:	54fd                	li	s1,-1
    80006372:	b761                	j	800062fa <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006374:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006378:	04691783          	lh	a5,70(s2)
    8000637c:	02f99223          	sh	a5,36(s3)
    80006380:	bf2d                	j	800062ba <sys_open+0xa4>
    itrunc(ip);
    80006382:	854a                	mv	a0,s2
    80006384:	ffffe097          	auipc	ra,0xffffe
    80006388:	034080e7          	jalr	52(ra) # 800043b8 <itrunc>
    8000638c:	bfb1                	j	800062e8 <sys_open+0xd2>
      fileclose(f);
    8000638e:	854e                	mv	a0,s3
    80006390:	fffff097          	auipc	ra,0xfffff
    80006394:	db8080e7          	jalr	-584(ra) # 80005148 <fileclose>
    iunlockput(ip);
    80006398:	854a                	mv	a0,s2
    8000639a:	ffffe097          	auipc	ra,0xffffe
    8000639e:	172080e7          	jalr	370(ra) # 8000450c <iunlockput>
    end_op();
    800063a2:	fffff097          	auipc	ra,0xfffff
    800063a6:	95a080e7          	jalr	-1702(ra) # 80004cfc <end_op>
    return -1;
    800063aa:	54fd                	li	s1,-1
    800063ac:	b7b9                	j	800062fa <sys_open+0xe4>

00000000800063ae <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800063ae:	7175                	addi	sp,sp,-144
    800063b0:	e506                	sd	ra,136(sp)
    800063b2:	e122                	sd	s0,128(sp)
    800063b4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800063b6:	fffff097          	auipc	ra,0xfffff
    800063ba:	8c6080e7          	jalr	-1850(ra) # 80004c7c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800063be:	08000613          	li	a2,128
    800063c2:	f7040593          	addi	a1,s0,-144
    800063c6:	4501                	li	a0,0
    800063c8:	ffffd097          	auipc	ra,0xffffd
    800063cc:	36a080e7          	jalr	874(ra) # 80003732 <argstr>
    800063d0:	02054963          	bltz	a0,80006402 <sys_mkdir+0x54>
    800063d4:	4681                	li	a3,0
    800063d6:	4601                	li	a2,0
    800063d8:	4585                	li	a1,1
    800063da:	f7040513          	addi	a0,s0,-144
    800063de:	fffff097          	auipc	ra,0xfffff
    800063e2:	7fe080e7          	jalr	2046(ra) # 80005bdc <create>
    800063e6:	cd11                	beqz	a0,80006402 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800063e8:	ffffe097          	auipc	ra,0xffffe
    800063ec:	124080e7          	jalr	292(ra) # 8000450c <iunlockput>
  end_op();
    800063f0:	fffff097          	auipc	ra,0xfffff
    800063f4:	90c080e7          	jalr	-1780(ra) # 80004cfc <end_op>
  return 0;
    800063f8:	4501                	li	a0,0
}
    800063fa:	60aa                	ld	ra,136(sp)
    800063fc:	640a                	ld	s0,128(sp)
    800063fe:	6149                	addi	sp,sp,144
    80006400:	8082                	ret
    end_op();
    80006402:	fffff097          	auipc	ra,0xfffff
    80006406:	8fa080e7          	jalr	-1798(ra) # 80004cfc <end_op>
    return -1;
    8000640a:	557d                	li	a0,-1
    8000640c:	b7fd                	j	800063fa <sys_mkdir+0x4c>

000000008000640e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000640e:	7135                	addi	sp,sp,-160
    80006410:	ed06                	sd	ra,152(sp)
    80006412:	e922                	sd	s0,144(sp)
    80006414:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006416:	fffff097          	auipc	ra,0xfffff
    8000641a:	866080e7          	jalr	-1946(ra) # 80004c7c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000641e:	08000613          	li	a2,128
    80006422:	f7040593          	addi	a1,s0,-144
    80006426:	4501                	li	a0,0
    80006428:	ffffd097          	auipc	ra,0xffffd
    8000642c:	30a080e7          	jalr	778(ra) # 80003732 <argstr>
    80006430:	04054a63          	bltz	a0,80006484 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006434:	f6c40593          	addi	a1,s0,-148
    80006438:	4505                	li	a0,1
    8000643a:	ffffd097          	auipc	ra,0xffffd
    8000643e:	2b4080e7          	jalr	692(ra) # 800036ee <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006442:	04054163          	bltz	a0,80006484 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006446:	f6840593          	addi	a1,s0,-152
    8000644a:	4509                	li	a0,2
    8000644c:	ffffd097          	auipc	ra,0xffffd
    80006450:	2a2080e7          	jalr	674(ra) # 800036ee <argint>
     argint(1, &major) < 0 ||
    80006454:	02054863          	bltz	a0,80006484 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006458:	f6841683          	lh	a3,-152(s0)
    8000645c:	f6c41603          	lh	a2,-148(s0)
    80006460:	458d                	li	a1,3
    80006462:	f7040513          	addi	a0,s0,-144
    80006466:	fffff097          	auipc	ra,0xfffff
    8000646a:	776080e7          	jalr	1910(ra) # 80005bdc <create>
     argint(2, &minor) < 0 ||
    8000646e:	c919                	beqz	a0,80006484 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006470:	ffffe097          	auipc	ra,0xffffe
    80006474:	09c080e7          	jalr	156(ra) # 8000450c <iunlockput>
  end_op();
    80006478:	fffff097          	auipc	ra,0xfffff
    8000647c:	884080e7          	jalr	-1916(ra) # 80004cfc <end_op>
  return 0;
    80006480:	4501                	li	a0,0
    80006482:	a031                	j	8000648e <sys_mknod+0x80>
    end_op();
    80006484:	fffff097          	auipc	ra,0xfffff
    80006488:	878080e7          	jalr	-1928(ra) # 80004cfc <end_op>
    return -1;
    8000648c:	557d                	li	a0,-1
}
    8000648e:	60ea                	ld	ra,152(sp)
    80006490:	644a                	ld	s0,144(sp)
    80006492:	610d                	addi	sp,sp,160
    80006494:	8082                	ret

0000000080006496 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006496:	7135                	addi	sp,sp,-160
    80006498:	ed06                	sd	ra,152(sp)
    8000649a:	e922                	sd	s0,144(sp)
    8000649c:	e526                	sd	s1,136(sp)
    8000649e:	e14a                	sd	s2,128(sp)
    800064a0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800064a2:	ffffc097          	auipc	ra,0xffffc
    800064a6:	e2e080e7          	jalr	-466(ra) # 800022d0 <myproc>
    800064aa:	892a                	mv	s2,a0
  
  begin_op();
    800064ac:	ffffe097          	auipc	ra,0xffffe
    800064b0:	7d0080e7          	jalr	2000(ra) # 80004c7c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800064b4:	08000613          	li	a2,128
    800064b8:	f6040593          	addi	a1,s0,-160
    800064bc:	4501                	li	a0,0
    800064be:	ffffd097          	auipc	ra,0xffffd
    800064c2:	274080e7          	jalr	628(ra) # 80003732 <argstr>
    800064c6:	04054b63          	bltz	a0,8000651c <sys_chdir+0x86>
    800064ca:	f6040513          	addi	a0,s0,-160
    800064ce:	ffffe097          	auipc	ra,0xffffe
    800064d2:	592080e7          	jalr	1426(ra) # 80004a60 <namei>
    800064d6:	84aa                	mv	s1,a0
    800064d8:	c131                	beqz	a0,8000651c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800064da:	ffffe097          	auipc	ra,0xffffe
    800064de:	dd0080e7          	jalr	-560(ra) # 800042aa <ilock>
  if(ip->type != T_DIR){
    800064e2:	04449703          	lh	a4,68(s1)
    800064e6:	4785                	li	a5,1
    800064e8:	04f71063          	bne	a4,a5,80006528 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800064ec:	8526                	mv	a0,s1
    800064ee:	ffffe097          	auipc	ra,0xffffe
    800064f2:	e7e080e7          	jalr	-386(ra) # 8000436c <iunlock>
  iput(p->cwd);
    800064f6:	17893503          	ld	a0,376(s2)
    800064fa:	ffffe097          	auipc	ra,0xffffe
    800064fe:	f6a080e7          	jalr	-150(ra) # 80004464 <iput>
  end_op();
    80006502:	ffffe097          	auipc	ra,0xffffe
    80006506:	7fa080e7          	jalr	2042(ra) # 80004cfc <end_op>
  p->cwd = ip;
    8000650a:	16993c23          	sd	s1,376(s2)
  return 0;
    8000650e:	4501                	li	a0,0
}
    80006510:	60ea                	ld	ra,152(sp)
    80006512:	644a                	ld	s0,144(sp)
    80006514:	64aa                	ld	s1,136(sp)
    80006516:	690a                	ld	s2,128(sp)
    80006518:	610d                	addi	sp,sp,160
    8000651a:	8082                	ret
    end_op();
    8000651c:	ffffe097          	auipc	ra,0xffffe
    80006520:	7e0080e7          	jalr	2016(ra) # 80004cfc <end_op>
    return -1;
    80006524:	557d                	li	a0,-1
    80006526:	b7ed                	j	80006510 <sys_chdir+0x7a>
    iunlockput(ip);
    80006528:	8526                	mv	a0,s1
    8000652a:	ffffe097          	auipc	ra,0xffffe
    8000652e:	fe2080e7          	jalr	-30(ra) # 8000450c <iunlockput>
    end_op();
    80006532:	ffffe097          	auipc	ra,0xffffe
    80006536:	7ca080e7          	jalr	1994(ra) # 80004cfc <end_op>
    return -1;
    8000653a:	557d                	li	a0,-1
    8000653c:	bfd1                	j	80006510 <sys_chdir+0x7a>

000000008000653e <sys_exec>:

uint64
sys_exec(void)
{
    8000653e:	7145                	addi	sp,sp,-464
    80006540:	e786                	sd	ra,456(sp)
    80006542:	e3a2                	sd	s0,448(sp)
    80006544:	ff26                	sd	s1,440(sp)
    80006546:	fb4a                	sd	s2,432(sp)
    80006548:	f74e                	sd	s3,424(sp)
    8000654a:	f352                	sd	s4,416(sp)
    8000654c:	ef56                	sd	s5,408(sp)
    8000654e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006550:	08000613          	li	a2,128
    80006554:	f4040593          	addi	a1,s0,-192
    80006558:	4501                	li	a0,0
    8000655a:	ffffd097          	auipc	ra,0xffffd
    8000655e:	1d8080e7          	jalr	472(ra) # 80003732 <argstr>
    return -1;
    80006562:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006564:	0c054a63          	bltz	a0,80006638 <sys_exec+0xfa>
    80006568:	e3840593          	addi	a1,s0,-456
    8000656c:	4505                	li	a0,1
    8000656e:	ffffd097          	auipc	ra,0xffffd
    80006572:	1a2080e7          	jalr	418(ra) # 80003710 <argaddr>
    80006576:	0c054163          	bltz	a0,80006638 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000657a:	10000613          	li	a2,256
    8000657e:	4581                	li	a1,0
    80006580:	e4040513          	addi	a0,s0,-448
    80006584:	ffffa097          	auipc	ra,0xffffa
    80006588:	76a080e7          	jalr	1898(ra) # 80000cee <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000658c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006590:	89a6                	mv	s3,s1
    80006592:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006594:	02000a13          	li	s4,32
    80006598:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000659c:	00391513          	slli	a0,s2,0x3
    800065a0:	e3040593          	addi	a1,s0,-464
    800065a4:	e3843783          	ld	a5,-456(s0)
    800065a8:	953e                	add	a0,a0,a5
    800065aa:	ffffd097          	auipc	ra,0xffffd
    800065ae:	0aa080e7          	jalr	170(ra) # 80003654 <fetchaddr>
    800065b2:	02054a63          	bltz	a0,800065e6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800065b6:	e3043783          	ld	a5,-464(s0)
    800065ba:	c3b9                	beqz	a5,80006600 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800065bc:	ffffa097          	auipc	ra,0xffffa
    800065c0:	538080e7          	jalr	1336(ra) # 80000af4 <kalloc>
    800065c4:	85aa                	mv	a1,a0
    800065c6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800065ca:	cd11                	beqz	a0,800065e6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800065cc:	6605                	lui	a2,0x1
    800065ce:	e3043503          	ld	a0,-464(s0)
    800065d2:	ffffd097          	auipc	ra,0xffffd
    800065d6:	0d4080e7          	jalr	212(ra) # 800036a6 <fetchstr>
    800065da:	00054663          	bltz	a0,800065e6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800065de:	0905                	addi	s2,s2,1
    800065e0:	09a1                	addi	s3,s3,8
    800065e2:	fb491be3          	bne	s2,s4,80006598 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065e6:	10048913          	addi	s2,s1,256
    800065ea:	6088                	ld	a0,0(s1)
    800065ec:	c529                	beqz	a0,80006636 <sys_exec+0xf8>
    kfree(argv[i]);
    800065ee:	ffffa097          	auipc	ra,0xffffa
    800065f2:	40a080e7          	jalr	1034(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065f6:	04a1                	addi	s1,s1,8
    800065f8:	ff2499e3          	bne	s1,s2,800065ea <sys_exec+0xac>
  return -1;
    800065fc:	597d                	li	s2,-1
    800065fe:	a82d                	j	80006638 <sys_exec+0xfa>
      argv[i] = 0;
    80006600:	0a8e                	slli	s5,s5,0x3
    80006602:	fc040793          	addi	a5,s0,-64
    80006606:	9abe                	add	s5,s5,a5
    80006608:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000660c:	e4040593          	addi	a1,s0,-448
    80006610:	f4040513          	addi	a0,s0,-192
    80006614:	fffff097          	auipc	ra,0xfffff
    80006618:	194080e7          	jalr	404(ra) # 800057a8 <exec>
    8000661c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000661e:	10048993          	addi	s3,s1,256
    80006622:	6088                	ld	a0,0(s1)
    80006624:	c911                	beqz	a0,80006638 <sys_exec+0xfa>
    kfree(argv[i]);
    80006626:	ffffa097          	auipc	ra,0xffffa
    8000662a:	3d2080e7          	jalr	978(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000662e:	04a1                	addi	s1,s1,8
    80006630:	ff3499e3          	bne	s1,s3,80006622 <sys_exec+0xe4>
    80006634:	a011                	j	80006638 <sys_exec+0xfa>
  return -1;
    80006636:	597d                	li	s2,-1
}
    80006638:	854a                	mv	a0,s2
    8000663a:	60be                	ld	ra,456(sp)
    8000663c:	641e                	ld	s0,448(sp)
    8000663e:	74fa                	ld	s1,440(sp)
    80006640:	795a                	ld	s2,432(sp)
    80006642:	79ba                	ld	s3,424(sp)
    80006644:	7a1a                	ld	s4,416(sp)
    80006646:	6afa                	ld	s5,408(sp)
    80006648:	6179                	addi	sp,sp,464
    8000664a:	8082                	ret

000000008000664c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000664c:	7139                	addi	sp,sp,-64
    8000664e:	fc06                	sd	ra,56(sp)
    80006650:	f822                	sd	s0,48(sp)
    80006652:	f426                	sd	s1,40(sp)
    80006654:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006656:	ffffc097          	auipc	ra,0xffffc
    8000665a:	c7a080e7          	jalr	-902(ra) # 800022d0 <myproc>
    8000665e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006660:	fd840593          	addi	a1,s0,-40
    80006664:	4501                	li	a0,0
    80006666:	ffffd097          	auipc	ra,0xffffd
    8000666a:	0aa080e7          	jalr	170(ra) # 80003710 <argaddr>
    return -1;
    8000666e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006670:	0e054063          	bltz	a0,80006750 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006674:	fc840593          	addi	a1,s0,-56
    80006678:	fd040513          	addi	a0,s0,-48
    8000667c:	fffff097          	auipc	ra,0xfffff
    80006680:	dfc080e7          	jalr	-516(ra) # 80005478 <pipealloc>
    return -1;
    80006684:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006686:	0c054563          	bltz	a0,80006750 <sys_pipe+0x104>
  fd0 = -1;
    8000668a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000668e:	fd043503          	ld	a0,-48(s0)
    80006692:	fffff097          	auipc	ra,0xfffff
    80006696:	508080e7          	jalr	1288(ra) # 80005b9a <fdalloc>
    8000669a:	fca42223          	sw	a0,-60(s0)
    8000669e:	08054c63          	bltz	a0,80006736 <sys_pipe+0xea>
    800066a2:	fc843503          	ld	a0,-56(s0)
    800066a6:	fffff097          	auipc	ra,0xfffff
    800066aa:	4f4080e7          	jalr	1268(ra) # 80005b9a <fdalloc>
    800066ae:	fca42023          	sw	a0,-64(s0)
    800066b2:	06054863          	bltz	a0,80006722 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066b6:	4691                	li	a3,4
    800066b8:	fc440613          	addi	a2,s0,-60
    800066bc:	fd843583          	ld	a1,-40(s0)
    800066c0:	7ca8                	ld	a0,120(s1)
    800066c2:	ffffb097          	auipc	ra,0xffffb
    800066c6:	fbe080e7          	jalr	-66(ra) # 80001680 <copyout>
    800066ca:	02054063          	bltz	a0,800066ea <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800066ce:	4691                	li	a3,4
    800066d0:	fc040613          	addi	a2,s0,-64
    800066d4:	fd843583          	ld	a1,-40(s0)
    800066d8:	0591                	addi	a1,a1,4
    800066da:	7ca8                	ld	a0,120(s1)
    800066dc:	ffffb097          	auipc	ra,0xffffb
    800066e0:	fa4080e7          	jalr	-92(ra) # 80001680 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800066e4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066e6:	06055563          	bgez	a0,80006750 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800066ea:	fc442783          	lw	a5,-60(s0)
    800066ee:	07f9                	addi	a5,a5,30
    800066f0:	078e                	slli	a5,a5,0x3
    800066f2:	97a6                	add	a5,a5,s1
    800066f4:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800066f8:	fc042503          	lw	a0,-64(s0)
    800066fc:	0579                	addi	a0,a0,30
    800066fe:	050e                	slli	a0,a0,0x3
    80006700:	9526                	add	a0,a0,s1
    80006702:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006706:	fd043503          	ld	a0,-48(s0)
    8000670a:	fffff097          	auipc	ra,0xfffff
    8000670e:	a3e080e7          	jalr	-1474(ra) # 80005148 <fileclose>
    fileclose(wf);
    80006712:	fc843503          	ld	a0,-56(s0)
    80006716:	fffff097          	auipc	ra,0xfffff
    8000671a:	a32080e7          	jalr	-1486(ra) # 80005148 <fileclose>
    return -1;
    8000671e:	57fd                	li	a5,-1
    80006720:	a805                	j	80006750 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006722:	fc442783          	lw	a5,-60(s0)
    80006726:	0007c863          	bltz	a5,80006736 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000672a:	01e78513          	addi	a0,a5,30
    8000672e:	050e                	slli	a0,a0,0x3
    80006730:	9526                	add	a0,a0,s1
    80006732:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006736:	fd043503          	ld	a0,-48(s0)
    8000673a:	fffff097          	auipc	ra,0xfffff
    8000673e:	a0e080e7          	jalr	-1522(ra) # 80005148 <fileclose>
    fileclose(wf);
    80006742:	fc843503          	ld	a0,-56(s0)
    80006746:	fffff097          	auipc	ra,0xfffff
    8000674a:	a02080e7          	jalr	-1534(ra) # 80005148 <fileclose>
    return -1;
    8000674e:	57fd                	li	a5,-1
}
    80006750:	853e                	mv	a0,a5
    80006752:	70e2                	ld	ra,56(sp)
    80006754:	7442                	ld	s0,48(sp)
    80006756:	74a2                	ld	s1,40(sp)
    80006758:	6121                	addi	sp,sp,64
    8000675a:	8082                	ret
    8000675c:	0000                	unimp
	...

0000000080006760 <kernelvec>:
    80006760:	7111                	addi	sp,sp,-256
    80006762:	e006                	sd	ra,0(sp)
    80006764:	e40a                	sd	sp,8(sp)
    80006766:	e80e                	sd	gp,16(sp)
    80006768:	ec12                	sd	tp,24(sp)
    8000676a:	f016                	sd	t0,32(sp)
    8000676c:	f41a                	sd	t1,40(sp)
    8000676e:	f81e                	sd	t2,48(sp)
    80006770:	fc22                	sd	s0,56(sp)
    80006772:	e0a6                	sd	s1,64(sp)
    80006774:	e4aa                	sd	a0,72(sp)
    80006776:	e8ae                	sd	a1,80(sp)
    80006778:	ecb2                	sd	a2,88(sp)
    8000677a:	f0b6                	sd	a3,96(sp)
    8000677c:	f4ba                	sd	a4,104(sp)
    8000677e:	f8be                	sd	a5,112(sp)
    80006780:	fcc2                	sd	a6,120(sp)
    80006782:	e146                	sd	a7,128(sp)
    80006784:	e54a                	sd	s2,136(sp)
    80006786:	e94e                	sd	s3,144(sp)
    80006788:	ed52                	sd	s4,152(sp)
    8000678a:	f156                	sd	s5,160(sp)
    8000678c:	f55a                	sd	s6,168(sp)
    8000678e:	f95e                	sd	s7,176(sp)
    80006790:	fd62                	sd	s8,184(sp)
    80006792:	e1e6                	sd	s9,192(sp)
    80006794:	e5ea                	sd	s10,200(sp)
    80006796:	e9ee                	sd	s11,208(sp)
    80006798:	edf2                	sd	t3,216(sp)
    8000679a:	f1f6                	sd	t4,224(sp)
    8000679c:	f5fa                	sd	t5,232(sp)
    8000679e:	f9fe                	sd	t6,240(sp)
    800067a0:	d81fc0ef          	jal	ra,80003520 <kerneltrap>
    800067a4:	6082                	ld	ra,0(sp)
    800067a6:	6122                	ld	sp,8(sp)
    800067a8:	61c2                	ld	gp,16(sp)
    800067aa:	7282                	ld	t0,32(sp)
    800067ac:	7322                	ld	t1,40(sp)
    800067ae:	73c2                	ld	t2,48(sp)
    800067b0:	7462                	ld	s0,56(sp)
    800067b2:	6486                	ld	s1,64(sp)
    800067b4:	6526                	ld	a0,72(sp)
    800067b6:	65c6                	ld	a1,80(sp)
    800067b8:	6666                	ld	a2,88(sp)
    800067ba:	7686                	ld	a3,96(sp)
    800067bc:	7726                	ld	a4,104(sp)
    800067be:	77c6                	ld	a5,112(sp)
    800067c0:	7866                	ld	a6,120(sp)
    800067c2:	688a                	ld	a7,128(sp)
    800067c4:	692a                	ld	s2,136(sp)
    800067c6:	69ca                	ld	s3,144(sp)
    800067c8:	6a6a                	ld	s4,152(sp)
    800067ca:	7a8a                	ld	s5,160(sp)
    800067cc:	7b2a                	ld	s6,168(sp)
    800067ce:	7bca                	ld	s7,176(sp)
    800067d0:	7c6a                	ld	s8,184(sp)
    800067d2:	6c8e                	ld	s9,192(sp)
    800067d4:	6d2e                	ld	s10,200(sp)
    800067d6:	6dce                	ld	s11,208(sp)
    800067d8:	6e6e                	ld	t3,216(sp)
    800067da:	7e8e                	ld	t4,224(sp)
    800067dc:	7f2e                	ld	t5,232(sp)
    800067de:	7fce                	ld	t6,240(sp)
    800067e0:	6111                	addi	sp,sp,256
    800067e2:	10200073          	sret
    800067e6:	00000013          	nop
    800067ea:	00000013          	nop
    800067ee:	0001                	nop

00000000800067f0 <timervec>:
    800067f0:	34051573          	csrrw	a0,mscratch,a0
    800067f4:	e10c                	sd	a1,0(a0)
    800067f6:	e510                	sd	a2,8(a0)
    800067f8:	e914                	sd	a3,16(a0)
    800067fa:	6d0c                	ld	a1,24(a0)
    800067fc:	7110                	ld	a2,32(a0)
    800067fe:	6194                	ld	a3,0(a1)
    80006800:	96b2                	add	a3,a3,a2
    80006802:	e194                	sd	a3,0(a1)
    80006804:	4589                	li	a1,2
    80006806:	14459073          	csrw	sip,a1
    8000680a:	6914                	ld	a3,16(a0)
    8000680c:	6510                	ld	a2,8(a0)
    8000680e:	610c                	ld	a1,0(a0)
    80006810:	34051573          	csrrw	a0,mscratch,a0
    80006814:	30200073          	mret
	...

000000008000681a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000681a:	1141                	addi	sp,sp,-16
    8000681c:	e422                	sd	s0,8(sp)
    8000681e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006820:	0c0007b7          	lui	a5,0xc000
    80006824:	4705                	li	a4,1
    80006826:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006828:	c3d8                	sw	a4,4(a5)
}
    8000682a:	6422                	ld	s0,8(sp)
    8000682c:	0141                	addi	sp,sp,16
    8000682e:	8082                	ret

0000000080006830 <plicinithart>:

void
plicinithart(void)
{
    80006830:	1141                	addi	sp,sp,-16
    80006832:	e406                	sd	ra,8(sp)
    80006834:	e022                	sd	s0,0(sp)
    80006836:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006838:	ffffc097          	auipc	ra,0xffffc
    8000683c:	a64080e7          	jalr	-1436(ra) # 8000229c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006840:	0085171b          	slliw	a4,a0,0x8
    80006844:	0c0027b7          	lui	a5,0xc002
    80006848:	97ba                	add	a5,a5,a4
    8000684a:	40200713          	li	a4,1026
    8000684e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006852:	00d5151b          	slliw	a0,a0,0xd
    80006856:	0c2017b7          	lui	a5,0xc201
    8000685a:	953e                	add	a0,a0,a5
    8000685c:	00052023          	sw	zero,0(a0)
}
    80006860:	60a2                	ld	ra,8(sp)
    80006862:	6402                	ld	s0,0(sp)
    80006864:	0141                	addi	sp,sp,16
    80006866:	8082                	ret

0000000080006868 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006868:	1141                	addi	sp,sp,-16
    8000686a:	e406                	sd	ra,8(sp)
    8000686c:	e022                	sd	s0,0(sp)
    8000686e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006870:	ffffc097          	auipc	ra,0xffffc
    80006874:	a2c080e7          	jalr	-1492(ra) # 8000229c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006878:	00d5179b          	slliw	a5,a0,0xd
    8000687c:	0c201537          	lui	a0,0xc201
    80006880:	953e                	add	a0,a0,a5
  return irq;
}
    80006882:	4148                	lw	a0,4(a0)
    80006884:	60a2                	ld	ra,8(sp)
    80006886:	6402                	ld	s0,0(sp)
    80006888:	0141                	addi	sp,sp,16
    8000688a:	8082                	ret

000000008000688c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000688c:	1101                	addi	sp,sp,-32
    8000688e:	ec06                	sd	ra,24(sp)
    80006890:	e822                	sd	s0,16(sp)
    80006892:	e426                	sd	s1,8(sp)
    80006894:	1000                	addi	s0,sp,32
    80006896:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006898:	ffffc097          	auipc	ra,0xffffc
    8000689c:	a04080e7          	jalr	-1532(ra) # 8000229c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800068a0:	00d5151b          	slliw	a0,a0,0xd
    800068a4:	0c2017b7          	lui	a5,0xc201
    800068a8:	97aa                	add	a5,a5,a0
    800068aa:	c3c4                	sw	s1,4(a5)
}
    800068ac:	60e2                	ld	ra,24(sp)
    800068ae:	6442                	ld	s0,16(sp)
    800068b0:	64a2                	ld	s1,8(sp)
    800068b2:	6105                	addi	sp,sp,32
    800068b4:	8082                	ret

00000000800068b6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800068b6:	1141                	addi	sp,sp,-16
    800068b8:	e406                	sd	ra,8(sp)
    800068ba:	e022                	sd	s0,0(sp)
    800068bc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800068be:	479d                	li	a5,7
    800068c0:	06a7c963          	blt	a5,a0,80006932 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800068c4:	0001c797          	auipc	a5,0x1c
    800068c8:	73c78793          	addi	a5,a5,1852 # 80023000 <disk>
    800068cc:	00a78733          	add	a4,a5,a0
    800068d0:	6789                	lui	a5,0x2
    800068d2:	97ba                	add	a5,a5,a4
    800068d4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800068d8:	e7ad                	bnez	a5,80006942 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800068da:	00451793          	slli	a5,a0,0x4
    800068de:	0001e717          	auipc	a4,0x1e
    800068e2:	72270713          	addi	a4,a4,1826 # 80025000 <disk+0x2000>
    800068e6:	6314                	ld	a3,0(a4)
    800068e8:	96be                	add	a3,a3,a5
    800068ea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800068ee:	6314                	ld	a3,0(a4)
    800068f0:	96be                	add	a3,a3,a5
    800068f2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800068f6:	6314                	ld	a3,0(a4)
    800068f8:	96be                	add	a3,a3,a5
    800068fa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800068fe:	6318                	ld	a4,0(a4)
    80006900:	97ba                	add	a5,a5,a4
    80006902:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006906:	0001c797          	auipc	a5,0x1c
    8000690a:	6fa78793          	addi	a5,a5,1786 # 80023000 <disk>
    8000690e:	97aa                	add	a5,a5,a0
    80006910:	6509                	lui	a0,0x2
    80006912:	953e                	add	a0,a0,a5
    80006914:	4785                	li	a5,1
    80006916:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000691a:	0001e517          	auipc	a0,0x1e
    8000691e:	6fe50513          	addi	a0,a0,1790 # 80025018 <disk+0x2018>
    80006922:	ffffc097          	auipc	ra,0xffffc
    80006926:	410080e7          	jalr	1040(ra) # 80002d32 <wakeup>
}
    8000692a:	60a2                	ld	ra,8(sp)
    8000692c:	6402                	ld	s0,0(sp)
    8000692e:	0141                	addi	sp,sp,16
    80006930:	8082                	ret
    panic("free_desc 1");
    80006932:	00002517          	auipc	a0,0x2
    80006936:	f9e50513          	addi	a0,a0,-98 # 800088d0 <syscalls+0x330>
    8000693a:	ffffa097          	auipc	ra,0xffffa
    8000693e:	c04080e7          	jalr	-1020(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006942:	00002517          	auipc	a0,0x2
    80006946:	f9e50513          	addi	a0,a0,-98 # 800088e0 <syscalls+0x340>
    8000694a:	ffffa097          	auipc	ra,0xffffa
    8000694e:	bf4080e7          	jalr	-1036(ra) # 8000053e <panic>

0000000080006952 <virtio_disk_init>:
{
    80006952:	1101                	addi	sp,sp,-32
    80006954:	ec06                	sd	ra,24(sp)
    80006956:	e822                	sd	s0,16(sp)
    80006958:	e426                	sd	s1,8(sp)
    8000695a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000695c:	00002597          	auipc	a1,0x2
    80006960:	f9458593          	addi	a1,a1,-108 # 800088f0 <syscalls+0x350>
    80006964:	0001e517          	auipc	a0,0x1e
    80006968:	7c450513          	addi	a0,a0,1988 # 80025128 <disk+0x2128>
    8000696c:	ffffa097          	auipc	ra,0xffffa
    80006970:	1e8080e7          	jalr	488(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006974:	100017b7          	lui	a5,0x10001
    80006978:	4398                	lw	a4,0(a5)
    8000697a:	2701                	sext.w	a4,a4
    8000697c:	747277b7          	lui	a5,0x74727
    80006980:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006984:	0ef71163          	bne	a4,a5,80006a66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006988:	100017b7          	lui	a5,0x10001
    8000698c:	43dc                	lw	a5,4(a5)
    8000698e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006990:	4705                	li	a4,1
    80006992:	0ce79a63          	bne	a5,a4,80006a66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006996:	100017b7          	lui	a5,0x10001
    8000699a:	479c                	lw	a5,8(a5)
    8000699c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000699e:	4709                	li	a4,2
    800069a0:	0ce79363          	bne	a5,a4,80006a66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800069a4:	100017b7          	lui	a5,0x10001
    800069a8:	47d8                	lw	a4,12(a5)
    800069aa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800069ac:	554d47b7          	lui	a5,0x554d4
    800069b0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800069b4:	0af71963          	bne	a4,a5,80006a66 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800069b8:	100017b7          	lui	a5,0x10001
    800069bc:	4705                	li	a4,1
    800069be:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069c0:	470d                	li	a4,3
    800069c2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800069c4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800069c6:	c7ffe737          	lui	a4,0xc7ffe
    800069ca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800069ce:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800069d0:	2701                	sext.w	a4,a4
    800069d2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069d4:	472d                	li	a4,11
    800069d6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069d8:	473d                	li	a4,15
    800069da:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800069dc:	6705                	lui	a4,0x1
    800069de:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800069e0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800069e4:	5bdc                	lw	a5,52(a5)
    800069e6:	2781                	sext.w	a5,a5
  if(max == 0)
    800069e8:	c7d9                	beqz	a5,80006a76 <virtio_disk_init+0x124>
  if(max < NUM)
    800069ea:	471d                	li	a4,7
    800069ec:	08f77d63          	bgeu	a4,a5,80006a86 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800069f0:	100014b7          	lui	s1,0x10001
    800069f4:	47a1                	li	a5,8
    800069f6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800069f8:	6609                	lui	a2,0x2
    800069fa:	4581                	li	a1,0
    800069fc:	0001c517          	auipc	a0,0x1c
    80006a00:	60450513          	addi	a0,a0,1540 # 80023000 <disk>
    80006a04:	ffffa097          	auipc	ra,0xffffa
    80006a08:	2ea080e7          	jalr	746(ra) # 80000cee <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006a0c:	0001c717          	auipc	a4,0x1c
    80006a10:	5f470713          	addi	a4,a4,1524 # 80023000 <disk>
    80006a14:	00c75793          	srli	a5,a4,0xc
    80006a18:	2781                	sext.w	a5,a5
    80006a1a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006a1c:	0001e797          	auipc	a5,0x1e
    80006a20:	5e478793          	addi	a5,a5,1508 # 80025000 <disk+0x2000>
    80006a24:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006a26:	0001c717          	auipc	a4,0x1c
    80006a2a:	65a70713          	addi	a4,a4,1626 # 80023080 <disk+0x80>
    80006a2e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006a30:	0001d717          	auipc	a4,0x1d
    80006a34:	5d070713          	addi	a4,a4,1488 # 80024000 <disk+0x1000>
    80006a38:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006a3a:	4705                	li	a4,1
    80006a3c:	00e78c23          	sb	a4,24(a5)
    80006a40:	00e78ca3          	sb	a4,25(a5)
    80006a44:	00e78d23          	sb	a4,26(a5)
    80006a48:	00e78da3          	sb	a4,27(a5)
    80006a4c:	00e78e23          	sb	a4,28(a5)
    80006a50:	00e78ea3          	sb	a4,29(a5)
    80006a54:	00e78f23          	sb	a4,30(a5)
    80006a58:	00e78fa3          	sb	a4,31(a5)
}
    80006a5c:	60e2                	ld	ra,24(sp)
    80006a5e:	6442                	ld	s0,16(sp)
    80006a60:	64a2                	ld	s1,8(sp)
    80006a62:	6105                	addi	sp,sp,32
    80006a64:	8082                	ret
    panic("could not find virtio disk");
    80006a66:	00002517          	auipc	a0,0x2
    80006a6a:	e9a50513          	addi	a0,a0,-358 # 80008900 <syscalls+0x360>
    80006a6e:	ffffa097          	auipc	ra,0xffffa
    80006a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006a76:	00002517          	auipc	a0,0x2
    80006a7a:	eaa50513          	addi	a0,a0,-342 # 80008920 <syscalls+0x380>
    80006a7e:	ffffa097          	auipc	ra,0xffffa
    80006a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006a86:	00002517          	auipc	a0,0x2
    80006a8a:	eba50513          	addi	a0,a0,-326 # 80008940 <syscalls+0x3a0>
    80006a8e:	ffffa097          	auipc	ra,0xffffa
    80006a92:	ab0080e7          	jalr	-1360(ra) # 8000053e <panic>

0000000080006a96 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006a96:	7159                	addi	sp,sp,-112
    80006a98:	f486                	sd	ra,104(sp)
    80006a9a:	f0a2                	sd	s0,96(sp)
    80006a9c:	eca6                	sd	s1,88(sp)
    80006a9e:	e8ca                	sd	s2,80(sp)
    80006aa0:	e4ce                	sd	s3,72(sp)
    80006aa2:	e0d2                	sd	s4,64(sp)
    80006aa4:	fc56                	sd	s5,56(sp)
    80006aa6:	f85a                	sd	s6,48(sp)
    80006aa8:	f45e                	sd	s7,40(sp)
    80006aaa:	f062                	sd	s8,32(sp)
    80006aac:	ec66                	sd	s9,24(sp)
    80006aae:	e86a                	sd	s10,16(sp)
    80006ab0:	1880                	addi	s0,sp,112
    80006ab2:	892a                	mv	s2,a0
    80006ab4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006ab6:	00c52c83          	lw	s9,12(a0)
    80006aba:	001c9c9b          	slliw	s9,s9,0x1
    80006abe:	1c82                	slli	s9,s9,0x20
    80006ac0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006ac4:	0001e517          	auipc	a0,0x1e
    80006ac8:	66450513          	addi	a0,a0,1636 # 80025128 <disk+0x2128>
    80006acc:	ffffa097          	auipc	ra,0xffffa
    80006ad0:	120080e7          	jalr	288(ra) # 80000bec <acquire>
  for(int i = 0; i < 3; i++){
    80006ad4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006ad6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006ad8:	0001cb97          	auipc	s7,0x1c
    80006adc:	528b8b93          	addi	s7,s7,1320 # 80023000 <disk>
    80006ae0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006ae2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006ae4:	8a4e                	mv	s4,s3
    80006ae6:	a051                	j	80006b6a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006ae8:	00fb86b3          	add	a3,s7,a5
    80006aec:	96da                	add	a3,a3,s6
    80006aee:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006af2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006af4:	0207c563          	bltz	a5,80006b1e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006af8:	2485                	addiw	s1,s1,1
    80006afa:	0711                	addi	a4,a4,4
    80006afc:	25548063          	beq	s1,s5,80006d3c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006b00:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006b02:	0001e697          	auipc	a3,0x1e
    80006b06:	51668693          	addi	a3,a3,1302 # 80025018 <disk+0x2018>
    80006b0a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006b0c:	0006c583          	lbu	a1,0(a3)
    80006b10:	fde1                	bnez	a1,80006ae8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006b12:	2785                	addiw	a5,a5,1
    80006b14:	0685                	addi	a3,a3,1
    80006b16:	ff879be3          	bne	a5,s8,80006b0c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006b1a:	57fd                	li	a5,-1
    80006b1c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006b1e:	02905a63          	blez	s1,80006b52 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b22:	f9042503          	lw	a0,-112(s0)
    80006b26:	00000097          	auipc	ra,0x0
    80006b2a:	d90080e7          	jalr	-624(ra) # 800068b6 <free_desc>
      for(int j = 0; j < i; j++)
    80006b2e:	4785                	li	a5,1
    80006b30:	0297d163          	bge	a5,s1,80006b52 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b34:	f9442503          	lw	a0,-108(s0)
    80006b38:	00000097          	auipc	ra,0x0
    80006b3c:	d7e080e7          	jalr	-642(ra) # 800068b6 <free_desc>
      for(int j = 0; j < i; j++)
    80006b40:	4789                	li	a5,2
    80006b42:	0097d863          	bge	a5,s1,80006b52 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b46:	f9842503          	lw	a0,-104(s0)
    80006b4a:	00000097          	auipc	ra,0x0
    80006b4e:	d6c080e7          	jalr	-660(ra) # 800068b6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b52:	0001e597          	auipc	a1,0x1e
    80006b56:	5d658593          	addi	a1,a1,1494 # 80025128 <disk+0x2128>
    80006b5a:	0001e517          	auipc	a0,0x1e
    80006b5e:	4be50513          	addi	a0,a0,1214 # 80025018 <disk+0x2018>
    80006b62:	ffffc097          	auipc	ra,0xffffc
    80006b66:	02c080e7          	jalr	44(ra) # 80002b8e <sleep>
  for(int i = 0; i < 3; i++){
    80006b6a:	f9040713          	addi	a4,s0,-112
    80006b6e:	84ce                	mv	s1,s3
    80006b70:	bf41                	j	80006b00 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006b72:	20058713          	addi	a4,a1,512
    80006b76:	00471693          	slli	a3,a4,0x4
    80006b7a:	0001c717          	auipc	a4,0x1c
    80006b7e:	48670713          	addi	a4,a4,1158 # 80023000 <disk>
    80006b82:	9736                	add	a4,a4,a3
    80006b84:	4685                	li	a3,1
    80006b86:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006b8a:	20058713          	addi	a4,a1,512
    80006b8e:	00471693          	slli	a3,a4,0x4
    80006b92:	0001c717          	auipc	a4,0x1c
    80006b96:	46e70713          	addi	a4,a4,1134 # 80023000 <disk>
    80006b9a:	9736                	add	a4,a4,a3
    80006b9c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006ba0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006ba4:	7679                	lui	a2,0xffffe
    80006ba6:	963e                	add	a2,a2,a5
    80006ba8:	0001e697          	auipc	a3,0x1e
    80006bac:	45868693          	addi	a3,a3,1112 # 80025000 <disk+0x2000>
    80006bb0:	6298                	ld	a4,0(a3)
    80006bb2:	9732                	add	a4,a4,a2
    80006bb4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006bb6:	6298                	ld	a4,0(a3)
    80006bb8:	9732                	add	a4,a4,a2
    80006bba:	4541                	li	a0,16
    80006bbc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006bbe:	6298                	ld	a4,0(a3)
    80006bc0:	9732                	add	a4,a4,a2
    80006bc2:	4505                	li	a0,1
    80006bc4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006bc8:	f9442703          	lw	a4,-108(s0)
    80006bcc:	6288                	ld	a0,0(a3)
    80006bce:	962a                	add	a2,a2,a0
    80006bd0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006bd4:	0712                	slli	a4,a4,0x4
    80006bd6:	6290                	ld	a2,0(a3)
    80006bd8:	963a                	add	a2,a2,a4
    80006bda:	05890513          	addi	a0,s2,88
    80006bde:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006be0:	6294                	ld	a3,0(a3)
    80006be2:	96ba                	add	a3,a3,a4
    80006be4:	40000613          	li	a2,1024
    80006be8:	c690                	sw	a2,8(a3)
  if(write)
    80006bea:	140d0063          	beqz	s10,80006d2a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006bee:	0001e697          	auipc	a3,0x1e
    80006bf2:	4126b683          	ld	a3,1042(a3) # 80025000 <disk+0x2000>
    80006bf6:	96ba                	add	a3,a3,a4
    80006bf8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006bfc:	0001c817          	auipc	a6,0x1c
    80006c00:	40480813          	addi	a6,a6,1028 # 80023000 <disk>
    80006c04:	0001e517          	auipc	a0,0x1e
    80006c08:	3fc50513          	addi	a0,a0,1020 # 80025000 <disk+0x2000>
    80006c0c:	6114                	ld	a3,0(a0)
    80006c0e:	96ba                	add	a3,a3,a4
    80006c10:	00c6d603          	lhu	a2,12(a3)
    80006c14:	00166613          	ori	a2,a2,1
    80006c18:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006c1c:	f9842683          	lw	a3,-104(s0)
    80006c20:	6110                	ld	a2,0(a0)
    80006c22:	9732                	add	a4,a4,a2
    80006c24:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c28:	20058613          	addi	a2,a1,512
    80006c2c:	0612                	slli	a2,a2,0x4
    80006c2e:	9642                	add	a2,a2,a6
    80006c30:	577d                	li	a4,-1
    80006c32:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c36:	00469713          	slli	a4,a3,0x4
    80006c3a:	6114                	ld	a3,0(a0)
    80006c3c:	96ba                	add	a3,a3,a4
    80006c3e:	03078793          	addi	a5,a5,48
    80006c42:	97c2                	add	a5,a5,a6
    80006c44:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006c46:	611c                	ld	a5,0(a0)
    80006c48:	97ba                	add	a5,a5,a4
    80006c4a:	4685                	li	a3,1
    80006c4c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c4e:	611c                	ld	a5,0(a0)
    80006c50:	97ba                	add	a5,a5,a4
    80006c52:	4809                	li	a6,2
    80006c54:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006c58:	611c                	ld	a5,0(a0)
    80006c5a:	973e                	add	a4,a4,a5
    80006c5c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006c60:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006c64:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006c68:	6518                	ld	a4,8(a0)
    80006c6a:	00275783          	lhu	a5,2(a4)
    80006c6e:	8b9d                	andi	a5,a5,7
    80006c70:	0786                	slli	a5,a5,0x1
    80006c72:	97ba                	add	a5,a5,a4
    80006c74:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006c78:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006c7c:	6518                	ld	a4,8(a0)
    80006c7e:	00275783          	lhu	a5,2(a4)
    80006c82:	2785                	addiw	a5,a5,1
    80006c84:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006c88:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006c8c:	100017b7          	lui	a5,0x10001
    80006c90:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006c94:	00492703          	lw	a4,4(s2)
    80006c98:	4785                	li	a5,1
    80006c9a:	02f71163          	bne	a4,a5,80006cbc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006c9e:	0001e997          	auipc	s3,0x1e
    80006ca2:	48a98993          	addi	s3,s3,1162 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006ca6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006ca8:	85ce                	mv	a1,s3
    80006caa:	854a                	mv	a0,s2
    80006cac:	ffffc097          	auipc	ra,0xffffc
    80006cb0:	ee2080e7          	jalr	-286(ra) # 80002b8e <sleep>
  while(b->disk == 1) {
    80006cb4:	00492783          	lw	a5,4(s2)
    80006cb8:	fe9788e3          	beq	a5,s1,80006ca8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006cbc:	f9042903          	lw	s2,-112(s0)
    80006cc0:	20090793          	addi	a5,s2,512
    80006cc4:	00479713          	slli	a4,a5,0x4
    80006cc8:	0001c797          	auipc	a5,0x1c
    80006ccc:	33878793          	addi	a5,a5,824 # 80023000 <disk>
    80006cd0:	97ba                	add	a5,a5,a4
    80006cd2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006cd6:	0001e997          	auipc	s3,0x1e
    80006cda:	32a98993          	addi	s3,s3,810 # 80025000 <disk+0x2000>
    80006cde:	00491713          	slli	a4,s2,0x4
    80006ce2:	0009b783          	ld	a5,0(s3)
    80006ce6:	97ba                	add	a5,a5,a4
    80006ce8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006cec:	854a                	mv	a0,s2
    80006cee:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006cf2:	00000097          	auipc	ra,0x0
    80006cf6:	bc4080e7          	jalr	-1084(ra) # 800068b6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006cfa:	8885                	andi	s1,s1,1
    80006cfc:	f0ed                	bnez	s1,80006cde <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006cfe:	0001e517          	auipc	a0,0x1e
    80006d02:	42a50513          	addi	a0,a0,1066 # 80025128 <disk+0x2128>
    80006d06:	ffffa097          	auipc	ra,0xffffa
    80006d0a:	fa0080e7          	jalr	-96(ra) # 80000ca6 <release>
}
    80006d0e:	70a6                	ld	ra,104(sp)
    80006d10:	7406                	ld	s0,96(sp)
    80006d12:	64e6                	ld	s1,88(sp)
    80006d14:	6946                	ld	s2,80(sp)
    80006d16:	69a6                	ld	s3,72(sp)
    80006d18:	6a06                	ld	s4,64(sp)
    80006d1a:	7ae2                	ld	s5,56(sp)
    80006d1c:	7b42                	ld	s6,48(sp)
    80006d1e:	7ba2                	ld	s7,40(sp)
    80006d20:	7c02                	ld	s8,32(sp)
    80006d22:	6ce2                	ld	s9,24(sp)
    80006d24:	6d42                	ld	s10,16(sp)
    80006d26:	6165                	addi	sp,sp,112
    80006d28:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006d2a:	0001e697          	auipc	a3,0x1e
    80006d2e:	2d66b683          	ld	a3,726(a3) # 80025000 <disk+0x2000>
    80006d32:	96ba                	add	a3,a3,a4
    80006d34:	4609                	li	a2,2
    80006d36:	00c69623          	sh	a2,12(a3)
    80006d3a:	b5c9                	j	80006bfc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d3c:	f9042583          	lw	a1,-112(s0)
    80006d40:	20058793          	addi	a5,a1,512
    80006d44:	0792                	slli	a5,a5,0x4
    80006d46:	0001c517          	auipc	a0,0x1c
    80006d4a:	36250513          	addi	a0,a0,866 # 800230a8 <disk+0xa8>
    80006d4e:	953e                	add	a0,a0,a5
  if(write)
    80006d50:	e20d11e3          	bnez	s10,80006b72 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006d54:	20058713          	addi	a4,a1,512
    80006d58:	00471693          	slli	a3,a4,0x4
    80006d5c:	0001c717          	auipc	a4,0x1c
    80006d60:	2a470713          	addi	a4,a4,676 # 80023000 <disk>
    80006d64:	9736                	add	a4,a4,a3
    80006d66:	0a072423          	sw	zero,168(a4)
    80006d6a:	b505                	j	80006b8a <virtio_disk_rw+0xf4>

0000000080006d6c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006d6c:	1101                	addi	sp,sp,-32
    80006d6e:	ec06                	sd	ra,24(sp)
    80006d70:	e822                	sd	s0,16(sp)
    80006d72:	e426                	sd	s1,8(sp)
    80006d74:	e04a                	sd	s2,0(sp)
    80006d76:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006d78:	0001e517          	auipc	a0,0x1e
    80006d7c:	3b050513          	addi	a0,a0,944 # 80025128 <disk+0x2128>
    80006d80:	ffffa097          	auipc	ra,0xffffa
    80006d84:	e6c080e7          	jalr	-404(ra) # 80000bec <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006d88:	10001737          	lui	a4,0x10001
    80006d8c:	533c                	lw	a5,96(a4)
    80006d8e:	8b8d                	andi	a5,a5,3
    80006d90:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006d92:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006d96:	0001e797          	auipc	a5,0x1e
    80006d9a:	26a78793          	addi	a5,a5,618 # 80025000 <disk+0x2000>
    80006d9e:	6b94                	ld	a3,16(a5)
    80006da0:	0207d703          	lhu	a4,32(a5)
    80006da4:	0026d783          	lhu	a5,2(a3)
    80006da8:	06f70163          	beq	a4,a5,80006e0a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006dac:	0001c917          	auipc	s2,0x1c
    80006db0:	25490913          	addi	s2,s2,596 # 80023000 <disk>
    80006db4:	0001e497          	auipc	s1,0x1e
    80006db8:	24c48493          	addi	s1,s1,588 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006dbc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006dc0:	6898                	ld	a4,16(s1)
    80006dc2:	0204d783          	lhu	a5,32(s1)
    80006dc6:	8b9d                	andi	a5,a5,7
    80006dc8:	078e                	slli	a5,a5,0x3
    80006dca:	97ba                	add	a5,a5,a4
    80006dcc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006dce:	20078713          	addi	a4,a5,512
    80006dd2:	0712                	slli	a4,a4,0x4
    80006dd4:	974a                	add	a4,a4,s2
    80006dd6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006dda:	e731                	bnez	a4,80006e26 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006ddc:	20078793          	addi	a5,a5,512
    80006de0:	0792                	slli	a5,a5,0x4
    80006de2:	97ca                	add	a5,a5,s2
    80006de4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006de6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006dea:	ffffc097          	auipc	ra,0xffffc
    80006dee:	f48080e7          	jalr	-184(ra) # 80002d32 <wakeup>

    disk.used_idx += 1;
    80006df2:	0204d783          	lhu	a5,32(s1)
    80006df6:	2785                	addiw	a5,a5,1
    80006df8:	17c2                	slli	a5,a5,0x30
    80006dfa:	93c1                	srli	a5,a5,0x30
    80006dfc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e00:	6898                	ld	a4,16(s1)
    80006e02:	00275703          	lhu	a4,2(a4)
    80006e06:	faf71be3          	bne	a4,a5,80006dbc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006e0a:	0001e517          	auipc	a0,0x1e
    80006e0e:	31e50513          	addi	a0,a0,798 # 80025128 <disk+0x2128>
    80006e12:	ffffa097          	auipc	ra,0xffffa
    80006e16:	e94080e7          	jalr	-364(ra) # 80000ca6 <release>
}
    80006e1a:	60e2                	ld	ra,24(sp)
    80006e1c:	6442                	ld	s0,16(sp)
    80006e1e:	64a2                	ld	s1,8(sp)
    80006e20:	6902                	ld	s2,0(sp)
    80006e22:	6105                	addi	sp,sp,32
    80006e24:	8082                	ret
      panic("virtio_disk_intr status");
    80006e26:	00002517          	auipc	a0,0x2
    80006e2a:	b3a50513          	addi	a0,a0,-1222 # 80008960 <syscalls+0x3c0>
    80006e2e:	ffff9097          	auipc	ra,0xffff9
    80006e32:	710080e7          	jalr	1808(ra) # 8000053e <panic>

0000000080006e36 <cas>:
    80006e36:	100522af          	lr.w	t0,(a0)
    80006e3a:	00b29563          	bne	t0,a1,80006e44 <fail>
    80006e3e:	18c5252f          	sc.w	a0,a2,(a0)
    80006e42:	8082                	ret

0000000080006e44 <fail>:
    80006e44:	4505                	li	a0,1
    80006e46:	8082                	ret
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
