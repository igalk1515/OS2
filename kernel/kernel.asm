
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a0013103          	ld	sp,-1536(sp) # 80008a00 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000064:	00007797          	auipc	a5,0x7
    80000068:	89c78793          	addi	a5,a5,-1892 # 80006900 <timervec>
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
    80000130:	0d2080e7          	jalr	210(ra) # 800031fe <either_copyin>
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
    800001c8:	c48080e7          	jalr	-952(ra) # 80001e0c <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	ab6080e7          	jalr	-1354(ra) # 80002c8a <sleep>
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
    80000214:	f98080e7          	jalr	-104(ra) # 800031a8 <either_copyout>
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
    800002f6:	f62080e7          	jalr	-158(ra) # 80003254 <procdump>
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
    8000044a:	9ea080e7          	jalr	-1558(ra) # 80002e30 <wakeup>
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
    800008a4:	590080e7          	jalr	1424(ra) # 80002e30 <wakeup>
    
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
    80000930:	35e080e7          	jalr	862(ra) # 80002c8a <sleep>
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
    80000b82:	26a080e7          	jalr	618(ra) # 80001de8 <mycpu>
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
    80000bb4:	238080e7          	jalr	568(ra) # 80001de8 <mycpu>
    80000bb8:	08052783          	lw	a5,128(a0)
    80000bbc:	cf99                	beqz	a5,80000bda <push_off+0x42>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	22a080e7          	jalr	554(ra) # 80001de8 <mycpu>
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
    80000bde:	20e080e7          	jalr	526(ra) # 80001de8 <mycpu>
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
    80000c20:	1cc080e7          	jalr	460(ra) # 80001de8 <mycpu>
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
    80000c4c:	1a0080e7          	jalr	416(ra) # 80001de8 <mycpu>
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
    80000ea8:	f34080e7          	jalr	-204(ra) # 80001dd8 <cpuid>
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
    80000ec4:	f18080e7          	jalr	-232(ra) # 80001dd8 <cpuid>
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
    80000ee6:	4b2080e7          	jalr	1202(ra) # 80003394 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eea:	00006097          	auipc	ra,0x6
    80000eee:	a56080e7          	jalr	-1450(ra) # 80006940 <plicinithart>
  }

  scheduler();        
    80000ef2:	00002097          	auipc	ra,0x2
    80000ef6:	854080e7          	jalr	-1964(ra) # 80002746 <scheduler>
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
    80000f56:	56e080e7          	jalr	1390(ra) # 800024c0 <procinit>
    trapinit();      // trap vectors
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	412080e7          	jalr	1042(ra) # 8000336c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	432080e7          	jalr	1074(ra) # 80003394 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f6a:	00006097          	auipc	ra,0x6
    80000f6e:	9c0080e7          	jalr	-1600(ra) # 8000692a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f72:	00006097          	auipc	ra,0x6
    80000f76:	9ce080e7          	jalr	-1586(ra) # 80006940 <plicinithart>
    binit();         // buffer cache
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	ba6080e7          	jalr	-1114(ra) # 80003b20 <binit>
    iinit();         // inode table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	236080e7          	jalr	566(ra) # 800041b8 <iinit>
    fileinit();      // file table
    80000f8a:	00004097          	auipc	ra,0x4
    80000f8e:	1e0080e7          	jalr	480(ra) # 8000516a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f92:	00006097          	auipc	ra,0x6
    80000f96:	ad0080e7          	jalr	-1328(ra) # 80006a62 <virtio_disk_init>
    userinit();      // first user process
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	abc080e7          	jalr	-1348(ra) # 80002a56 <userinit>
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
    80001252:	af4080e7          	jalr	-1292(ra) # 80001d42 <proc_mapstacks>
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
    80001a60:	7f450513          	addi	a0,a0,2036 # 80008250 <digits+0x210>
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
  getList2(number, parent_cpu);
    80001ad6:	85b2                	mv	a1,a2
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	d72080e7          	jalr	-654(ra) # 8000184c <getList2>
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

0000000080001b0c <pick_cpu>:
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
int init = 0;

int//TODO
pick_cpu(){
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
    80001b34:	00f77363          	bgeu	a4,a5,80001b3a <pick_cpu+0x2e>
  for(int i=1; i<CPUS; i++){
    80001b38:	4509                	li	a0,2
  }
  return curr_min;
}
    80001b3a:	6422                	ld	s0,8(sp)
    80001b3c:	0141                	addi	sp,sp,16
    80001b3e:	8082                	ret

0000000080001b40 <cahnge_number_of_proc>:

void
cahnge_number_of_proc(int cpu_id,int number){
    80001b40:	7179                	addi	sp,sp,-48
    80001b42:	f406                	sd	ra,40(sp)
    80001b44:	f022                	sd	s0,32(sp)
    80001b46:	ec26                	sd	s1,24(sp)
    80001b48:	e84a                	sd	s2,16(sp)
    80001b4a:	e44e                	sd	s3,8(sp)
    80001b4c:	1800                	addi	s0,sp,48
    80001b4e:	89ae                	mv	s3,a1
  struct cpu* c = &cpus[cpu_id];
  uint64 old;
  do{
    old = c->queue_size;
  } while(cas(&c->queue_size, old, old+number));
    80001b50:	00351913          	slli	s2,a0,0x3
    80001b54:	992a                	add	s2,s2,a0
    80001b56:	00491793          	slli	a5,s2,0x4
    80001b5a:	00010917          	auipc	s2,0x10
    80001b5e:	81690913          	addi	s2,s2,-2026 # 80011370 <cpus>
    80001b62:	993e                	add	s2,s2,a5
    old = c->queue_size;
    80001b64:	0000f497          	auipc	s1,0xf
    80001b68:	77c48493          	addi	s1,s1,1916 # 800112e0 <readyLock>
    80001b6c:	94be                	add	s1,s1,a5
    80001b6e:	68cc                	ld	a1,144(s1)
  } while(cas(&c->queue_size, old, old+number));
    80001b70:	0135863b          	addw	a2,a1,s3
    80001b74:	2581                	sext.w	a1,a1
    80001b76:	854a                	mv	a0,s2
    80001b78:	00005097          	auipc	ra,0x5
    80001b7c:	3ce080e7          	jalr	974(ra) # 80006f46 <cas>
    80001b80:	f57d                	bnez	a0,80001b6e <cahnge_number_of_proc+0x2e>
}
    80001b82:	70a2                	ld	ra,40(sp)
    80001b84:	7402                	ld	s0,32(sp)
    80001b86:	64e2                	ld	s1,24(sp)
    80001b88:	6942                	ld	s2,16(sp)
    80001b8a:	69a2                	ld	s3,8(sp)
    80001b8c:	6145                	addi	sp,sp,48
    80001b8e:	8082                	ret

0000000080001b90 <getFirst>:
    panic("getList");
  }
}


struct proc* getFirst(int type, int cpu_id){
    80001b90:	1101                	addi	sp,sp,-32
    80001b92:	ec06                	sd	ra,24(sp)
    80001b94:	e822                	sd	s0,16(sp)
    80001b96:	e426                	sd	s1,8(sp)
    80001b98:	e04a                	sd	s2,0(sp)
    80001b9a:	1000                	addi	s0,sp,32
    80001b9c:	84aa                	mv	s1,a0
    80001b9e:	892e                	mv	s2,a1
  struct proc* p;

  if(type>3){
    80001ba0:	478d                	li	a5,3
    80001ba2:	02a7c463          	blt	a5,a0,80001bca <getFirst+0x3a>
  printf("type is %d\n",type);
  }

  if(type==readyList || type==11){
    80001ba6:	e141                	bnez	a0,80001c26 <getFirst+0x96>
    p = cpus[cpu_id].first;
    80001ba8:	00391593          	slli	a1,s2,0x3
    80001bac:	992e                	add	s2,s2,a1
    80001bae:	0912                	slli	s2,s2,0x4
    80001bb0:	0000f797          	auipc	a5,0xf
    80001bb4:	73078793          	addi	a5,a5,1840 # 800112e0 <readyLock>
    80001bb8:	993e                	add	s2,s2,a5
    80001bba:	11893503          	ld	a0,280(s2)
  }
  else{
    panic("getFirst");
  }
  return p;
}
    80001bbe:	60e2                	ld	ra,24(sp)
    80001bc0:	6442                	ld	s0,16(sp)
    80001bc2:	64a2                	ld	s1,8(sp)
    80001bc4:	6902                	ld	s2,0(sp)
    80001bc6:	6105                	addi	sp,sp,32
    80001bc8:	8082                	ret
  printf("type is %d\n",type);
    80001bca:	85aa                	mv	a1,a0
    80001bcc:	00006517          	auipc	a0,0x6
    80001bd0:	69c50513          	addi	a0,a0,1692 # 80008268 <digits+0x228>
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	9b4080e7          	jalr	-1612(ra) # 80000588 <printf>
  if(type==readyList || type==11){
    80001bdc:	47ad                	li	a5,11
    80001bde:	fcf485e3          	beq	s1,a5,80001ba8 <getFirst+0x18>
  else if(type==zombeList || type==21){
    80001be2:	47d5                	li	a5,21
    80001be4:	04f48463          	beq	s1,a5,80001c2c <getFirst+0x9c>
  else if(type==sleepLeast || type==31){
    80001be8:	4789                	li	a5,2
    80001bea:	02f48163          	beq	s1,a5,80001c0c <getFirst+0x7c>
    80001bee:	47fd                	li	a5,31
    80001bf0:	00f48e63          	beq	s1,a5,80001c0c <getFirst+0x7c>
  else if(type==unuseList || type==41){
    80001bf4:	478d                	li	a5,3
    80001bf6:	00f48663          	beq	s1,a5,80001c02 <getFirst+0x72>
    80001bfa:	02900793          	li	a5,41
    80001bfe:	00f49c63          	bne	s1,a5,80001c16 <getFirst+0x86>
  p = unused_list;
    80001c02:	00007517          	auipc	a0,0x7
    80001c06:	42e53503          	ld	a0,1070(a0) # 80009030 <unused_list>
    80001c0a:	bf55                	j	80001bbe <getFirst+0x2e>
  p = sleeping_list;
    80001c0c:	00007517          	auipc	a0,0x7
    80001c10:	41c53503          	ld	a0,1052(a0) # 80009028 <sleeping_list>
    80001c14:	b76d                	j	80001bbe <getFirst+0x2e>
    panic("getFirst");
    80001c16:	00006517          	auipc	a0,0x6
    80001c1a:	66250513          	addi	a0,a0,1634 # 80008278 <digits+0x238>
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	920080e7          	jalr	-1760(ra) # 8000053e <panic>
  else if(type==zombeList || type==21){
    80001c26:	4785                	li	a5,1
    80001c28:	faf51de3          	bne	a0,a5,80001be2 <getFirst+0x52>
   p = zombie_list;  }
    80001c2c:	00007517          	auipc	a0,0x7
    80001c30:	40c53503          	ld	a0,1036(a0) # 80009038 <zombie_list>
    80001c34:	b769                	j	80001bbe <getFirst+0x2e>

0000000080001c36 <release_list3>:
  }
}


void
release_list3(int number, int parent_cpu){
    80001c36:	1141                	addi	sp,sp,-16
    80001c38:	e406                	sd	ra,8(sp)
    80001c3a:	e022                	sd	s0,0(sp)
    80001c3c:	0800                	addi	s0,sp,16
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001c3e:	4785                	li	a5,1
    80001c40:	02f50763          	beq	a0,a5,80001c6e <release_list3+0x38>
      number == 2 ? release(&zombie_lock): 
    80001c44:	4789                	li	a5,2
    80001c46:	04f50263          	beq	a0,a5,80001c8a <release_list3+0x54>
        number == 3 ? release(&sleeping_lock): 
    80001c4a:	478d                	li	a5,3
    80001c4c:	04f50863          	beq	a0,a5,80001c9c <release_list3+0x66>
          number == 4 ? release(&unused_lock):  
    80001c50:	4791                	li	a5,4
    80001c52:	04f51e63          	bne	a0,a5,80001cae <release_list3+0x78>
    80001c56:	00010517          	auipc	a0,0x10
    80001c5a:	94250513          	addi	a0,a0,-1726 # 80011598 <unused_lock>
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	048080e7          	jalr	72(ra) # 80000ca6 <release>
            panic("wrong call in release_list3");
}
    80001c66:	60a2                	ld	ra,8(sp)
    80001c68:	6402                	ld	s0,0(sp)
    80001c6a:	0141                	addi	sp,sp,16
    80001c6c:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001c6e:	00159513          	slli	a0,a1,0x1
    80001c72:	95aa                	add	a1,a1,a0
    80001c74:	058e                	slli	a1,a1,0x3
    80001c76:	00010517          	auipc	a0,0x10
    80001c7a:	8aa50513          	addi	a0,a0,-1878 # 80011520 <ready_lock>
    80001c7e:	952e                	add	a0,a0,a1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	026080e7          	jalr	38(ra) # 80000ca6 <release>
    80001c88:	bff9                	j	80001c66 <release_list3+0x30>
      number == 2 ? release(&zombie_lock): 
    80001c8a:	00010517          	auipc	a0,0x10
    80001c8e:	8de50513          	addi	a0,a0,-1826 # 80011568 <zombie_lock>
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	014080e7          	jalr	20(ra) # 80000ca6 <release>
    80001c9a:	b7f1                	j	80001c66 <release_list3+0x30>
        number == 3 ? release(&sleeping_lock): 
    80001c9c:	00010517          	auipc	a0,0x10
    80001ca0:	8e450513          	addi	a0,a0,-1820 # 80011580 <sleeping_lock>
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	002080e7          	jalr	2(ra) # 80000ca6 <release>
    80001cac:	bf6d                	j	80001c66 <release_list3+0x30>
            panic("wrong call in release_list3");
    80001cae:	00006517          	auipc	a0,0x6
    80001cb2:	5da50513          	addi	a0,a0,1498 # 80008288 <digits+0x248>
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	888080e7          	jalr	-1912(ra) # 8000053e <panic>

0000000080001cbe <release_list>:

void
release_list(int type, int parent_cpu){
    80001cbe:	1141                	addi	sp,sp,-16
    80001cc0:	e406                	sd	ra,8(sp)
    80001cc2:	e022                	sd	s0,0(sp)
    80001cc4:	0800                	addi	s0,sp,16
  type==readyList ? release_list3(1,parent_cpu): 
    80001cc6:	c515                	beqz	a0,80001cf2 <release_list+0x34>
    type==zombeList ? release_list3(2,parent_cpu):
    80001cc8:	4785                	li	a5,1
    80001cca:	04f50263          	beq	a0,a5,80001d0e <release_list+0x50>
      type==sleepLeast ? release_list3(3,parent_cpu):
    80001cce:	4789                	li	a5,2
    80001cd0:	04f50863          	beq	a0,a5,80001d20 <release_list+0x62>
        type==unuseList ? release_list3(4,parent_cpu):
    80001cd4:	478d                	li	a5,3
    80001cd6:	04f51e63          	bne	a0,a5,80001d32 <release_list+0x74>
          number == 4 ? release(&unused_lock):  
    80001cda:	00010517          	auipc	a0,0x10
    80001cde:	8be50513          	addi	a0,a0,-1858 # 80011598 <unused_lock>
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	fc4080e7          	jalr	-60(ra) # 80000ca6 <release>
          panic("wrong type list");
}
    80001cea:	60a2                	ld	ra,8(sp)
    80001cec:	6402                	ld	s0,0(sp)
    80001cee:	0141                	addi	sp,sp,16
    80001cf0:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001cf2:	00159513          	slli	a0,a1,0x1
    80001cf6:	95aa                	add	a1,a1,a0
    80001cf8:	058e                	slli	a1,a1,0x3
    80001cfa:	00010517          	auipc	a0,0x10
    80001cfe:	82650513          	addi	a0,a0,-2010 # 80011520 <ready_lock>
    80001d02:	952e                	add	a0,a0,a1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	fa2080e7          	jalr	-94(ra) # 80000ca6 <release>
}
    80001d0c:	bff9                	j	80001cea <release_list+0x2c>
      number == 2 ? release(&zombie_lock): 
    80001d0e:	00010517          	auipc	a0,0x10
    80001d12:	85a50513          	addi	a0,a0,-1958 # 80011568 <zombie_lock>
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	f90080e7          	jalr	-112(ra) # 80000ca6 <release>
}
    80001d1e:	b7f1                	j	80001cea <release_list+0x2c>
        number == 3 ? release(&sleeping_lock): 
    80001d20:	00010517          	auipc	a0,0x10
    80001d24:	86050513          	addi	a0,a0,-1952 # 80011580 <sleeping_lock>
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	f7e080e7          	jalr	-130(ra) # 80000ca6 <release>
}
    80001d30:	bf6d                	j	80001cea <release_list+0x2c>
          panic("wrong type list");
    80001d32:	00006517          	auipc	a0,0x6
    80001d36:	57650513          	addi	a0,a0,1398 # 800082a8 <digits+0x268>
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	804080e7          	jalr	-2044(ra) # 8000053e <panic>

0000000080001d42 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001d42:	7139                	addi	sp,sp,-64
    80001d44:	fc06                	sd	ra,56(sp)
    80001d46:	f822                	sd	s0,48(sp)
    80001d48:	f426                	sd	s1,40(sp)
    80001d4a:	f04a                	sd	s2,32(sp)
    80001d4c:	ec4e                	sd	s3,24(sp)
    80001d4e:	e852                	sd	s4,16(sp)
    80001d50:	e456                	sd	s5,8(sp)
    80001d52:	e05a                	sd	s6,0(sp)
    80001d54:	0080                	addi	s0,sp,64
    80001d56:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d58:	00010497          	auipc	s1,0x10
    80001d5c:	88848493          	addi	s1,s1,-1912 # 800115e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001d60:	8b26                	mv	s6,s1
    80001d62:	00006a97          	auipc	s5,0x6
    80001d66:	29ea8a93          	addi	s5,s5,670 # 80008000 <etext>
    80001d6a:	04000937          	lui	s2,0x4000
    80001d6e:	197d                	addi	s2,s2,-1
    80001d70:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d72:	00016a17          	auipc	s4,0x16
    80001d76:	c6ea0a13          	addi	s4,s4,-914 # 800179e0 <tickslock>
    char *pa = kalloc();
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	d7a080e7          	jalr	-646(ra) # 80000af4 <kalloc>
    80001d82:	862a                	mv	a2,a0
    if(pa == 0)
    80001d84:	c131                	beqz	a0,80001dc8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001d86:	416485b3          	sub	a1,s1,s6
    80001d8a:	8591                	srai	a1,a1,0x4
    80001d8c:	000ab783          	ld	a5,0(s5)
    80001d90:	02f585b3          	mul	a1,a1,a5
    80001d94:	2585                	addiw	a1,a1,1
    80001d96:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d9a:	4719                	li	a4,6
    80001d9c:	6685                	lui	a3,0x1
    80001d9e:	40b905b3          	sub	a1,s2,a1
    80001da2:	854e                	mv	a0,s3
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	3ba080e7          	jalr	954(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dac:	19048493          	addi	s1,s1,400
    80001db0:	fd4495e3          	bne	s1,s4,80001d7a <proc_mapstacks+0x38>
  }
}
    80001db4:	70e2                	ld	ra,56(sp)
    80001db6:	7442                	ld	s0,48(sp)
    80001db8:	74a2                	ld	s1,40(sp)
    80001dba:	7902                	ld	s2,32(sp)
    80001dbc:	69e2                	ld	s3,24(sp)
    80001dbe:	6a42                	ld	s4,16(sp)
    80001dc0:	6aa2                	ld	s5,8(sp)
    80001dc2:	6b02                	ld	s6,0(sp)
    80001dc4:	6121                	addi	sp,sp,64
    80001dc6:	8082                	ret
      panic("kalloc");
    80001dc8:	00006517          	auipc	a0,0x6
    80001dcc:	4f050513          	addi	a0,a0,1264 # 800082b8 <digits+0x278>
    80001dd0:	ffffe097          	auipc	ra,0xffffe
    80001dd4:	76e080e7          	jalr	1902(ra) # 8000053e <panic>

0000000080001dd8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001dd8:	1141                	addi	sp,sp,-16
    80001dda:	e422                	sd	s0,8(sp)
    80001ddc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001dde:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001de0:	2501                	sext.w	a0,a0
    80001de2:	6422                	ld	s0,8(sp)
    80001de4:	0141                	addi	sp,sp,16
    80001de6:	8082                	ret

0000000080001de8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001de8:	1141                	addi	sp,sp,-16
    80001dea:	e422                	sd	s0,8(sp)
    80001dec:	0800                	addi	s0,sp,16
    80001dee:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001df0:	0007851b          	sext.w	a0,a5
    80001df4:	00351793          	slli	a5,a0,0x3
    80001df8:	97aa                	add	a5,a5,a0
    80001dfa:	0792                	slli	a5,a5,0x4
  return c;
}
    80001dfc:	0000f517          	auipc	a0,0xf
    80001e00:	57450513          	addi	a0,a0,1396 # 80011370 <cpus>
    80001e04:	953e                	add	a0,a0,a5
    80001e06:	6422                	ld	s0,8(sp)
    80001e08:	0141                	addi	sp,sp,16
    80001e0a:	8082                	ret

0000000080001e0c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001e0c:	1101                	addi	sp,sp,-32
    80001e0e:	ec06                	sd	ra,24(sp)
    80001e10:	e822                	sd	s0,16(sp)
    80001e12:	e426                	sd	s1,8(sp)
    80001e14:	1000                	addi	s0,sp,32
  push_off();
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	d82080e7          	jalr	-638(ra) # 80000b98 <push_off>
    80001e1e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e20:	0007871b          	sext.w	a4,a5
    80001e24:	00371793          	slli	a5,a4,0x3
    80001e28:	97ba                	add	a5,a5,a4
    80001e2a:	0792                	slli	a5,a5,0x4
    80001e2c:	0000f717          	auipc	a4,0xf
    80001e30:	4b470713          	addi	a4,a4,1204 # 800112e0 <readyLock>
    80001e34:	97ba                	add	a5,a5,a4
    80001e36:	6fc4                	ld	s1,152(a5)
  pop_off();
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	e08080e7          	jalr	-504(ra) # 80000c40 <pop_off>
  return p;
}
    80001e40:	8526                	mv	a0,s1
    80001e42:	60e2                	ld	ra,24(sp)
    80001e44:	6442                	ld	s0,16(sp)
    80001e46:	64a2                	ld	s1,8(sp)
    80001e48:	6105                	addi	sp,sp,32
    80001e4a:	8082                	ret

0000000080001e4c <get_cpu>:
{
    80001e4c:	1141                	addi	sp,sp,-16
    80001e4e:	e406                	sd	ra,8(sp)
    80001e50:	e022                	sd	s0,0(sp)
    80001e52:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	fb8080e7          	jalr	-72(ra) # 80001e0c <myproc>
}
    80001e5c:	4d28                	lw	a0,88(a0)
    80001e5e:	60a2                	ld	ra,8(sp)
    80001e60:	6402                	ld	s0,0(sp)
    80001e62:	0141                	addi	sp,sp,16
    80001e64:	8082                	ret

0000000080001e66 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e66:	1141                	addi	sp,sp,-16
    80001e68:	e406                	sd	ra,8(sp)
    80001e6a:	e022                	sd	s0,0(sp)
    80001e6c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e6e:	00000097          	auipc	ra,0x0
    80001e72:	f9e080e7          	jalr	-98(ra) # 80001e0c <myproc>
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e30080e7          	jalr	-464(ra) # 80000ca6 <release>

  if (first) {
    80001e7e:	00007797          	auipc	a5,0x7
    80001e82:	b327a783          	lw	a5,-1230(a5) # 800089b0 <first.1848>
    80001e86:	eb89                	bnez	a5,80001e98 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e88:	00001097          	auipc	ra,0x1
    80001e8c:	524080e7          	jalr	1316(ra) # 800033ac <usertrapret>
}
    80001e90:	60a2                	ld	ra,8(sp)
    80001e92:	6402                	ld	s0,0(sp)
    80001e94:	0141                	addi	sp,sp,16
    80001e96:	8082                	ret
    first = 0;
    80001e98:	00007797          	auipc	a5,0x7
    80001e9c:	b007ac23          	sw	zero,-1256(a5) # 800089b0 <first.1848>
    fsinit(ROOTDEV);
    80001ea0:	4505                	li	a0,1
    80001ea2:	00002097          	auipc	ra,0x2
    80001ea6:	296080e7          	jalr	662(ra) # 80004138 <fsinit>
    80001eaa:	bff9                	j	80001e88 <forkret+0x22>

0000000080001eac <allocpid>:
allocpid() {
    80001eac:	1101                	addi	sp,sp,-32
    80001eae:	ec06                	sd	ra,24(sp)
    80001eb0:	e822                	sd	s0,16(sp)
    80001eb2:	e426                	sd	s1,8(sp)
    80001eb4:	e04a                	sd	s2,0(sp)
    80001eb6:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001eb8:	00007917          	auipc	s2,0x7
    80001ebc:	afc90913          	addi	s2,s2,-1284 # 800089b4 <nextpid>
    80001ec0:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid, pid, pid + 1));
    80001ec4:	0014861b          	addiw	a2,s1,1
    80001ec8:	85a6                	mv	a1,s1
    80001eca:	854a                	mv	a0,s2
    80001ecc:	00005097          	auipc	ra,0x5
    80001ed0:	07a080e7          	jalr	122(ra) # 80006f46 <cas>
    80001ed4:	f575                	bnez	a0,80001ec0 <allocpid+0x14>
}
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	60e2                	ld	ra,24(sp)
    80001eda:	6442                	ld	s0,16(sp)
    80001edc:	64a2                	ld	s1,8(sp)
    80001ede:	6902                	ld	s2,0(sp)
    80001ee0:	6105                	addi	sp,sp,32
    80001ee2:	8082                	ret

0000000080001ee4 <proc_pagetable>:
{
    80001ee4:	1101                	addi	sp,sp,-32
    80001ee6:	ec06                	sd	ra,24(sp)
    80001ee8:	e822                	sd	s0,16(sp)
    80001eea:	e426                	sd	s1,8(sp)
    80001eec:	e04a                	sd	s2,0(sp)
    80001eee:	1000                	addi	s0,sp,32
    80001ef0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	456080e7          	jalr	1110(ra) # 80001348 <uvmcreate>
    80001efa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001efc:	c121                	beqz	a0,80001f3c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001efe:	4729                	li	a4,10
    80001f00:	00005697          	auipc	a3,0x5
    80001f04:	10068693          	addi	a3,a3,256 # 80007000 <_trampoline>
    80001f08:	6605                	lui	a2,0x1
    80001f0a:	040005b7          	lui	a1,0x4000
    80001f0e:	15fd                	addi	a1,a1,-1
    80001f10:	05b2                	slli	a1,a1,0xc
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	1ac080e7          	jalr	428(ra) # 800010be <mappages>
    80001f1a:	02054863          	bltz	a0,80001f4a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f1e:	4719                	li	a4,6
    80001f20:	08093683          	ld	a3,128(s2)
    80001f24:	6605                	lui	a2,0x1
    80001f26:	020005b7          	lui	a1,0x2000
    80001f2a:	15fd                	addi	a1,a1,-1
    80001f2c:	05b6                	slli	a1,a1,0xd
    80001f2e:	8526                	mv	a0,s1
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	18e080e7          	jalr	398(ra) # 800010be <mappages>
    80001f38:	02054163          	bltz	a0,80001f5a <proc_pagetable+0x76>
}
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	60e2                	ld	ra,24(sp)
    80001f40:	6442                	ld	s0,16(sp)
    80001f42:	64a2                	ld	s1,8(sp)
    80001f44:	6902                	ld	s2,0(sp)
    80001f46:	6105                	addi	sp,sp,32
    80001f48:	8082                	ret
    uvmfree(pagetable, 0);
    80001f4a:	4581                	li	a1,0
    80001f4c:	8526                	mv	a0,s1
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	5f6080e7          	jalr	1526(ra) # 80001544 <uvmfree>
    return 0;
    80001f56:	4481                	li	s1,0
    80001f58:	b7d5                	j	80001f3c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f5a:	4681                	li	a3,0
    80001f5c:	4605                	li	a2,1
    80001f5e:	040005b7          	lui	a1,0x4000
    80001f62:	15fd                	addi	a1,a1,-1
    80001f64:	05b2                	slli	a1,a1,0xc
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	31c080e7          	jalr	796(ra) # 80001284 <uvmunmap>
    uvmfree(pagetable, 0);
    80001f70:	4581                	li	a1,0
    80001f72:	8526                	mv	a0,s1
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	5d0080e7          	jalr	1488(ra) # 80001544 <uvmfree>
    return 0;
    80001f7c:	4481                	li	s1,0
    80001f7e:	bf7d                	j	80001f3c <proc_pagetable+0x58>

0000000080001f80 <proc_freepagetable>:
{
    80001f80:	1101                	addi	sp,sp,-32
    80001f82:	ec06                	sd	ra,24(sp)
    80001f84:	e822                	sd	s0,16(sp)
    80001f86:	e426                	sd	s1,8(sp)
    80001f88:	e04a                	sd	s2,0(sp)
    80001f8a:	1000                	addi	s0,sp,32
    80001f8c:	84aa                	mv	s1,a0
    80001f8e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f90:	4681                	li	a3,0
    80001f92:	4605                	li	a2,1
    80001f94:	040005b7          	lui	a1,0x4000
    80001f98:	15fd                	addi	a1,a1,-1
    80001f9a:	05b2                	slli	a1,a1,0xc
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	2e8080e7          	jalr	744(ra) # 80001284 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fa4:	4681                	li	a3,0
    80001fa6:	4605                	li	a2,1
    80001fa8:	020005b7          	lui	a1,0x2000
    80001fac:	15fd                	addi	a1,a1,-1
    80001fae:	05b6                	slli	a1,a1,0xd
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	2d2080e7          	jalr	722(ra) # 80001284 <uvmunmap>
  uvmfree(pagetable, sz);
    80001fba:	85ca                	mv	a1,s2
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	586080e7          	jalr	1414(ra) # 80001544 <uvmfree>
}
    80001fc6:	60e2                	ld	ra,24(sp)
    80001fc8:	6442                	ld	s0,16(sp)
    80001fca:	64a2                	ld	s1,8(sp)
    80001fcc:	6902                	ld	s2,0(sp)
    80001fce:	6105                	addi	sp,sp,32
    80001fd0:	8082                	ret

0000000080001fd2 <growproc>:
{
    80001fd2:	1101                	addi	sp,sp,-32
    80001fd4:	ec06                	sd	ra,24(sp)
    80001fd6:	e822                	sd	s0,16(sp)
    80001fd8:	e426                	sd	s1,8(sp)
    80001fda:	e04a                	sd	s2,0(sp)
    80001fdc:	1000                	addi	s0,sp,32
    80001fde:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001fe0:	00000097          	auipc	ra,0x0
    80001fe4:	e2c080e7          	jalr	-468(ra) # 80001e0c <myproc>
    80001fe8:	892a                	mv	s2,a0
  sz = p->sz;
    80001fea:	792c                	ld	a1,112(a0)
    80001fec:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ff0:	00904f63          	bgtz	s1,8000200e <growproc+0x3c>
  } else if(n < 0){
    80001ff4:	0204cc63          	bltz	s1,8000202c <growproc+0x5a>
  p->sz = sz;
    80001ff8:	1602                	slli	a2,a2,0x20
    80001ffa:	9201                	srli	a2,a2,0x20
    80001ffc:	06c93823          	sd	a2,112(s2)
  return 0;
    80002000:	4501                	li	a0,0
}
    80002002:	60e2                	ld	ra,24(sp)
    80002004:	6442                	ld	s0,16(sp)
    80002006:	64a2                	ld	s1,8(sp)
    80002008:	6902                	ld	s2,0(sp)
    8000200a:	6105                	addi	sp,sp,32
    8000200c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000200e:	9e25                	addw	a2,a2,s1
    80002010:	1602                	slli	a2,a2,0x20
    80002012:	9201                	srli	a2,a2,0x20
    80002014:	1582                	slli	a1,a1,0x20
    80002016:	9181                	srli	a1,a1,0x20
    80002018:	7d28                	ld	a0,120(a0)
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	416080e7          	jalr	1046(ra) # 80001430 <uvmalloc>
    80002022:	0005061b          	sext.w	a2,a0
    80002026:	fa69                	bnez	a2,80001ff8 <growproc+0x26>
      return -1;
    80002028:	557d                	li	a0,-1
    8000202a:	bfe1                	j	80002002 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000202c:	9e25                	addw	a2,a2,s1
    8000202e:	1602                	slli	a2,a2,0x20
    80002030:	9201                	srli	a2,a2,0x20
    80002032:	1582                	slli	a1,a1,0x20
    80002034:	9181                	srli	a1,a1,0x20
    80002036:	7d28                	ld	a0,120(a0)
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	3b0080e7          	jalr	944(ra) # 800013e8 <uvmdealloc>
    80002040:	0005061b          	sext.w	a2,a0
    80002044:	bf55                	j	80001ff8 <growproc+0x26>

0000000080002046 <sched>:
{
    80002046:	7179                	addi	sp,sp,-48
    80002048:	f406                	sd	ra,40(sp)
    8000204a:	f022                	sd	s0,32(sp)
    8000204c:	ec26                	sd	s1,24(sp)
    8000204e:	e84a                	sd	s2,16(sp)
    80002050:	e44e                	sd	s3,8(sp)
    80002052:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002054:	00000097          	auipc	ra,0x0
    80002058:	db8080e7          	jalr	-584(ra) # 80001e0c <myproc>
    8000205c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	b0c080e7          	jalr	-1268(ra) # 80000b6a <holding>
    80002066:	c959                	beqz	a0,800020fc <sched+0xb6>
    80002068:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000206a:	0007871b          	sext.w	a4,a5
    8000206e:	00371793          	slli	a5,a4,0x3
    80002072:	97ba                	add	a5,a5,a4
    80002074:	0792                	slli	a5,a5,0x4
    80002076:	0000f717          	auipc	a4,0xf
    8000207a:	26a70713          	addi	a4,a4,618 # 800112e0 <readyLock>
    8000207e:	97ba                	add	a5,a5,a4
    80002080:	1107a703          	lw	a4,272(a5)
    80002084:	4785                	li	a5,1
    80002086:	08f71363          	bne	a4,a5,8000210c <sched+0xc6>
  if(p->state == RUNNING)
    8000208a:	5898                	lw	a4,48(s1)
    8000208c:	4791                	li	a5,4
    8000208e:	08f70763          	beq	a4,a5,8000211c <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002092:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002096:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002098:	ebd1                	bnez	a5,8000212c <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000209a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000209c:	0000f917          	auipc	s2,0xf
    800020a0:	24490913          	addi	s2,s2,580 # 800112e0 <readyLock>
    800020a4:	0007871b          	sext.w	a4,a5
    800020a8:	00371793          	slli	a5,a4,0x3
    800020ac:	97ba                	add	a5,a5,a4
    800020ae:	0792                	slli	a5,a5,0x4
    800020b0:	97ca                	add	a5,a5,s2
    800020b2:	1147a983          	lw	s3,276(a5)
    800020b6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020b8:	0007859b          	sext.w	a1,a5
    800020bc:	00359793          	slli	a5,a1,0x3
    800020c0:	97ae                	add	a5,a5,a1
    800020c2:	0792                	slli	a5,a5,0x4
    800020c4:	0000f597          	auipc	a1,0xf
    800020c8:	2bc58593          	addi	a1,a1,700 # 80011380 <cpus+0x10>
    800020cc:	95be                	add	a1,a1,a5
    800020ce:	08848513          	addi	a0,s1,136
    800020d2:	00001097          	auipc	ra,0x1
    800020d6:	230080e7          	jalr	560(ra) # 80003302 <swtch>
    800020da:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020dc:	0007871b          	sext.w	a4,a5
    800020e0:	00371793          	slli	a5,a4,0x3
    800020e4:	97ba                	add	a5,a5,a4
    800020e6:	0792                	slli	a5,a5,0x4
    800020e8:	97ca                	add	a5,a5,s2
    800020ea:	1137aa23          	sw	s3,276(a5)
}
    800020ee:	70a2                	ld	ra,40(sp)
    800020f0:	7402                	ld	s0,32(sp)
    800020f2:	64e2                	ld	s1,24(sp)
    800020f4:	6942                	ld	s2,16(sp)
    800020f6:	69a2                	ld	s3,8(sp)
    800020f8:	6145                	addi	sp,sp,48
    800020fa:	8082                	ret
    panic("sched p->lock");
    800020fc:	00006517          	auipc	a0,0x6
    80002100:	1c450513          	addi	a0,a0,452 # 800082c0 <digits+0x280>
    80002104:	ffffe097          	auipc	ra,0xffffe
    80002108:	43a080e7          	jalr	1082(ra) # 8000053e <panic>
    panic("sched locks");
    8000210c:	00006517          	auipc	a0,0x6
    80002110:	1c450513          	addi	a0,a0,452 # 800082d0 <digits+0x290>
    80002114:	ffffe097          	auipc	ra,0xffffe
    80002118:	42a080e7          	jalr	1066(ra) # 8000053e <panic>
    panic("sched running");
    8000211c:	00006517          	auipc	a0,0x6
    80002120:	1c450513          	addi	a0,a0,452 # 800082e0 <digits+0x2a0>
    80002124:	ffffe097          	auipc	ra,0xffffe
    80002128:	41a080e7          	jalr	1050(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000212c:	00006517          	auipc	a0,0x6
    80002130:	1c450513          	addi	a0,a0,452 # 800082f0 <digits+0x2b0>
    80002134:	ffffe097          	auipc	ra,0xffffe
    80002138:	40a080e7          	jalr	1034(ra) # 8000053e <panic>

000000008000213c <yield>:
{
    8000213c:	1101                	addi	sp,sp,-32
    8000213e:	ec06                	sd	ra,24(sp)
    80002140:	e822                	sd	s0,16(sp)
    80002142:	e426                	sd	s1,8(sp)
    80002144:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002146:	00000097          	auipc	ra,0x0
    8000214a:	cc6080e7          	jalr	-826(ra) # 80001e0c <myproc>
    8000214e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	a9c080e7          	jalr	-1380(ra) # 80000bec <acquire>
  p->state = RUNNABLE;
    80002158:	478d                	li	a5,3
    8000215a:	d89c                	sw	a5,48(s1)
  add_proc_to_list(p, readyList, p->parent_cpu);
    8000215c:	4cb0                	lw	a2,88(s1)
    8000215e:	4581                	li	a1,0
    80002160:	8526                	mv	a0,s1
    80002162:	00000097          	auipc	ra,0x0
    80002166:	302080e7          	jalr	770(ra) # 80002464 <add_proc_to_list>
  sched();
    8000216a:	00000097          	auipc	ra,0x0
    8000216e:	edc080e7          	jalr	-292(ra) # 80002046 <sched>
  release(&p->lock);
    80002172:	8526                	mv	a0,s1
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	b32080e7          	jalr	-1230(ra) # 80000ca6 <release>
}
    8000217c:	60e2                	ld	ra,24(sp)
    8000217e:	6442                	ld	s0,16(sp)
    80002180:	64a2                	ld	s1,8(sp)
    80002182:	6105                	addi	sp,sp,32
    80002184:	8082                	ret

0000000080002186 <set_cpu>:
  if(cpu_num<0 || cpu_num>NCPU){
    80002186:	47a1                	li	a5,8
    80002188:	04a7e763          	bltu	a5,a0,800021d6 <set_cpu+0x50>
{
    8000218c:	1101                	addi	sp,sp,-32
    8000218e:	ec06                	sd	ra,24(sp)
    80002190:	e822                	sd	s0,16(sp)
    80002192:	e426                	sd	s1,8(sp)
    80002194:	e04a                	sd	s2,0(sp)
    80002196:	1000                	addi	s0,sp,32
    80002198:	84aa                	mv	s1,a0
  struct proc* p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	c72080e7          	jalr	-910(ra) # 80001e0c <myproc>
    800021a2:	892a                	mv	s2,a0
  cahnge_number_of_proc(p->parent_cpu,b);
    800021a4:	55fd                	li	a1,-1
    800021a6:	4d28                	lw	a0,88(a0)
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	998080e7          	jalr	-1640(ra) # 80001b40 <cahnge_number_of_proc>
  p->parent_cpu=cpu_num;
    800021b0:	04992c23          	sw	s1,88(s2)
  cahnge_number_of_proc(cpu_num,positive);
    800021b4:	4585                	li	a1,1
    800021b6:	8526                	mv	a0,s1
    800021b8:	00000097          	auipc	ra,0x0
    800021bc:	988080e7          	jalr	-1656(ra) # 80001b40 <cahnge_number_of_proc>
  yield();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	f7c080e7          	jalr	-132(ra) # 8000213c <yield>
  return cpu_num;
    800021c8:	8526                	mv	a0,s1
}
    800021ca:	60e2                	ld	ra,24(sp)
    800021cc:	6442                	ld	s0,16(sp)
    800021ce:	64a2                	ld	s1,8(sp)
    800021d0:	6902                	ld	s2,0(sp)
    800021d2:	6105                	addi	sp,sp,32
    800021d4:	8082                	ret
    return -1;
    800021d6:	557d                	li	a0,-1
}
    800021d8:	8082                	ret

00000000800021da <getList>:
getList(int type, int cpu_id){
    800021da:	1101                	addi	sp,sp,-32
    800021dc:	ec06                	sd	ra,24(sp)
    800021de:	e822                	sd	s0,16(sp)
    800021e0:	e426                	sd	s1,8(sp)
    800021e2:	e04a                	sd	s2,0(sp)
    800021e4:	1000                	addi	s0,sp,32
    800021e6:	84aa                	mv	s1,a0
    800021e8:	892e                	mv	s2,a1
  if(type>3){
    800021ea:	478d                	li	a5,3
    800021ec:	04a7c663          	blt	a5,a0,80002238 <getList+0x5e>
  if(type==readyList || type==11){
    800021f0:	c125                	beqz	a0,80002250 <getList+0x76>
  else if(type==zombeList || type==21){
    800021f2:	4785                	li	a5,1
    800021f4:	08f50263          	beq	a0,a5,80002278 <getList+0x9e>
    800021f8:	47d5                	li	a5,21
    800021fa:	06f48f63          	beq	s1,a5,80002278 <getList+0x9e>
  else if(type==sleepLeast || type==31){
    800021fe:	4789                	li	a5,2
    80002200:	08f48563          	beq	s1,a5,8000228a <getList+0xb0>
    80002204:	47fd                	li	a5,31
    80002206:	08f48263          	beq	s1,a5,8000228a <getList+0xb0>
  else if(type==unuseList || type==41){
    8000220a:	478d                	li	a5,3
    8000220c:	08f48863          	beq	s1,a5,8000229c <getList+0xc2>
    80002210:	02900793          	li	a5,41
    80002214:	08f48463          	beq	s1,a5,8000229c <getList+0xc2>
  else if(type == 51){
    80002218:	03300793          	li	a5,51
    8000221c:	08f48963          	beq	s1,a5,800022ae <getList+0xd4>
  else if(type == 61){
    80002220:	03d00793          	li	a5,61
    80002224:	0af49363          	bne	s1,a5,800022ca <getList+0xf0>
    print_flag++;
    80002228:	00007717          	auipc	a4,0x7
    8000222c:	e4470713          	addi	a4,a4,-444 # 8000906c <print_flag>
    80002230:	431c                	lw	a5,0(a4)
    80002232:	2785                	addiw	a5,a5,1
    80002234:	c31c                	sw	a5,0(a4)
    80002236:	a81d                	j	8000226c <getList+0x92>
  printf("type is %d\n",type);
    80002238:	85aa                	mv	a1,a0
    8000223a:	00006517          	auipc	a0,0x6
    8000223e:	02e50513          	addi	a0,a0,46 # 80008268 <digits+0x228>
    80002242:	ffffe097          	auipc	ra,0xffffe
    80002246:	346080e7          	jalr	838(ra) # 80000588 <printf>
  if(type==readyList || type==11){
    8000224a:	47ad                	li	a5,11
    8000224c:	faf496e3          	bne	s1,a5,800021f8 <getList+0x1e>
    acquire(&ready_lock[cpu_id]);
    80002250:	00191513          	slli	a0,s2,0x1
    80002254:	012505b3          	add	a1,a0,s2
    80002258:	058e                	slli	a1,a1,0x3
    8000225a:	0000f517          	auipc	a0,0xf
    8000225e:	2c650513          	addi	a0,a0,710 # 80011520 <ready_lock>
    80002262:	952e                	add	a0,a0,a1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	988080e7          	jalr	-1656(ra) # 80000bec <acquire>
}
    8000226c:	60e2                	ld	ra,24(sp)
    8000226e:	6442                	ld	s0,16(sp)
    80002270:	64a2                	ld	s1,8(sp)
    80002272:	6902                	ld	s2,0(sp)
    80002274:	6105                	addi	sp,sp,32
    80002276:	8082                	ret
    acquire(&zombie_lock);
    80002278:	0000f517          	auipc	a0,0xf
    8000227c:	2f050513          	addi	a0,a0,752 # 80011568 <zombie_lock>
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	96c080e7          	jalr	-1684(ra) # 80000bec <acquire>
    80002288:	b7d5                	j	8000226c <getList+0x92>
  acquire(&sleeping_lock);
    8000228a:	0000f517          	auipc	a0,0xf
    8000228e:	2f650513          	addi	a0,a0,758 # 80011580 <sleeping_lock>
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	95a080e7          	jalr	-1702(ra) # 80000bec <acquire>
    8000229a:	bfc9                	j	8000226c <getList+0x92>
  acquire(&unused_lock);
    8000229c:	0000f517          	auipc	a0,0xf
    800022a0:	2fc50513          	addi	a0,a0,764 # 80011598 <unused_lock>
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	948080e7          	jalr	-1720(ra) # 80000bec <acquire>
    800022ac:	b7c1                	j	8000226c <getList+0x92>
    set_cpu(cpu_id);
    800022ae:	854a                	mv	a0,s2
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	ed6080e7          	jalr	-298(ra) # 80002186 <set_cpu>
    printf("getList type ==5");
    800022b8:	00006517          	auipc	a0,0x6
    800022bc:	05050513          	addi	a0,a0,80 # 80008308 <digits+0x2c8>
    800022c0:	ffffe097          	auipc	ra,0xffffe
    800022c4:	2c8080e7          	jalr	712(ra) # 80000588 <printf>
    800022c8:	b755                	j	8000226c <getList+0x92>
    panic("getList");
    800022ca:	00006517          	auipc	a0,0x6
    800022ce:	05650513          	addi	a0,a0,86 # 80008320 <digits+0x2e0>
    800022d2:	ffffe097          	auipc	ra,0xffffe
    800022d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>

00000000800022da <setFirst>:
{
    800022da:	7179                	addi	sp,sp,-48
    800022dc:	f406                	sd	ra,40(sp)
    800022de:	f022                	sd	s0,32(sp)
    800022e0:	ec26                	sd	s1,24(sp)
    800022e2:	e84a                	sd	s2,16(sp)
    800022e4:	e44e                	sd	s3,8(sp)
    800022e6:	1800                	addi	s0,sp,48
    800022e8:	89aa                	mv	s3,a0
    800022ea:	84ae                	mv	s1,a1
    800022ec:	8932                	mv	s2,a2
  if(type>3){
    800022ee:	478d                	li	a5,3
    800022f0:	02b7c663          	blt	a5,a1,8000231c <setFirst+0x42>
  if(type==readyList || type==11){
    800022f4:	eddd                	bnez	a1,800023b2 <setFirst+0xd8>
    cpus[cpu_id].first = p;
    800022f6:	00391793          	slli	a5,s2,0x3
    800022fa:	01278633          	add	a2,a5,s2
    800022fe:	0612                	slli	a2,a2,0x4
    80002300:	0000f797          	auipc	a5,0xf
    80002304:	fe078793          	addi	a5,a5,-32 # 800112e0 <readyLock>
    80002308:	963e                	add	a2,a2,a5
    8000230a:	11363c23          	sd	s3,280(a2) # 1118 <_entry-0x7fffeee8>
}
    8000230e:	70a2                	ld	ra,40(sp)
    80002310:	7402                	ld	s0,32(sp)
    80002312:	64e2                	ld	s1,24(sp)
    80002314:	6942                	ld	s2,16(sp)
    80002316:	69a2                	ld	s3,8(sp)
    80002318:	6145                	addi	sp,sp,48
    8000231a:	8082                	ret
  printf("type is %d\n",type);
    8000231c:	00006517          	auipc	a0,0x6
    80002320:	f4c50513          	addi	a0,a0,-180 # 80008268 <digits+0x228>
    80002324:	ffffe097          	auipc	ra,0xffffe
    80002328:	264080e7          	jalr	612(ra) # 80000588 <printf>
  if(type==readyList || type==11){
    8000232c:	47ad                	li	a5,11
    8000232e:	fcf484e3          	beq	s1,a5,800022f6 <setFirst+0x1c>
  else if(type==zombeList || type==21){
    80002332:	47d5                	li	a5,21
    80002334:	08f48263          	beq	s1,a5,800023b8 <setFirst+0xde>
  else if(type==sleepLeast || type==31){
    80002338:	4789                	li	a5,2
    8000233a:	02f48c63          	beq	s1,a5,80002372 <setFirst+0x98>
    8000233e:	47fd                	li	a5,31
    80002340:	02f48963          	beq	s1,a5,80002372 <setFirst+0x98>
  else if(type==unuseList || type==41){
    80002344:	478d                	li	a5,3
    80002346:	02f48b63          	beq	s1,a5,8000237c <setFirst+0xa2>
    8000234a:	02900793          	li	a5,41
    8000234e:	02f48763          	beq	s1,a5,8000237c <setFirst+0xa2>
  else if(type == 51){
    80002352:	03300793          	li	a5,51
    80002356:	02f48863          	beq	s1,a5,80002386 <setFirst+0xac>
  else if(type == 61){
    8000235a:	03d00793          	li	a5,61
    8000235e:	04f49263          	bne	s1,a5,800023a2 <setFirst+0xc8>
    print_flag++;
    80002362:	00007717          	auipc	a4,0x7
    80002366:	d0a70713          	addi	a4,a4,-758 # 8000906c <print_flag>
    8000236a:	431c                	lw	a5,0(a4)
    8000236c:	2785                	addiw	a5,a5,1
    8000236e:	c31c                	sw	a5,0(a4)
    80002370:	bf79                	j	8000230e <setFirst+0x34>
    sleeping_list = p;
    80002372:	00007797          	auipc	a5,0x7
    80002376:	cb37bb23          	sd	s3,-842(a5) # 80009028 <sleeping_list>
    8000237a:	bf51                	j	8000230e <setFirst+0x34>
  unused_list = p;
    8000237c:	00007797          	auipc	a5,0x7
    80002380:	cb37ba23          	sd	s3,-844(a5) # 80009030 <unused_list>
    80002384:	b769                	j	8000230e <setFirst+0x34>
    set_cpu(cpu_id);
    80002386:	854a                	mv	a0,s2
    80002388:	00000097          	auipc	ra,0x0
    8000238c:	dfe080e7          	jalr	-514(ra) # 80002186 <set_cpu>
    printf("getList type ==5");
    80002390:	00006517          	auipc	a0,0x6
    80002394:	f7850513          	addi	a0,a0,-136 # 80008308 <digits+0x2c8>
    80002398:	ffffe097          	auipc	ra,0xffffe
    8000239c:	1f0080e7          	jalr	496(ra) # 80000588 <printf>
    800023a0:	b7bd                	j	8000230e <setFirst+0x34>
    panic("getList");
    800023a2:	00006517          	auipc	a0,0x6
    800023a6:	f7e50513          	addi	a0,a0,-130 # 80008320 <digits+0x2e0>
    800023aa:	ffffe097          	auipc	ra,0xffffe
    800023ae:	194080e7          	jalr	404(ra) # 8000053e <panic>
  else if(type==zombeList || type==21){
    800023b2:	4785                	li	a5,1
    800023b4:	f6f59fe3          	bne	a1,a5,80002332 <setFirst+0x58>
    zombie_list = p;
    800023b8:	00007797          	auipc	a5,0x7
    800023bc:	c937b023          	sd	s3,-896(a5) # 80009038 <zombie_list>
    800023c0:	b7b9                	j	8000230e <setFirst+0x34>

00000000800023c2 <add_to_list>:
{
    800023c2:	7139                	addi	sp,sp,-64
    800023c4:	fc06                	sd	ra,56(sp)
    800023c6:	f822                	sd	s0,48(sp)
    800023c8:	f426                	sd	s1,40(sp)
    800023ca:	f04a                	sd	s2,32(sp)
    800023cc:	ec4e                	sd	s3,24(sp)
    800023ce:	e852                	sd	s4,16(sp)
    800023d0:	e456                	sd	s5,8(sp)
    800023d2:	e05a                	sd	s6,0(sp)
    800023d4:	0080                	addi	s0,sp,64
  if(!p){
    800023d6:	c505                	beqz	a0,800023fe <add_to_list+0x3c>
    800023d8:	8b2a                	mv	s6,a0
    800023da:	84ae                	mv	s1,a1
    800023dc:	8a32                	mv	s4,a2
    800023de:	8ab6                	mv	s5,a3
    struct proc* prev = 0;
    800023e0:	4901                	li	s2,0
  if(!head){
    800023e2:	e1a1                	bnez	a1,80002422 <add_to_list+0x60>
      setFirst(p, type, cpu_id);
    800023e4:	8636                	mv	a2,a3
    800023e6:	85d2                	mv	a1,s4
    800023e8:	00000097          	auipc	ra,0x0
    800023ec:	ef2080e7          	jalr	-270(ra) # 800022da <setFirst>
      release_list(type, cpu_id);
    800023f0:	85d6                	mv	a1,s5
    800023f2:	8552                	mv	a0,s4
    800023f4:	00000097          	auipc	ra,0x0
    800023f8:	8ca080e7          	jalr	-1846(ra) # 80001cbe <release_list>
    800023fc:	a891                	j	80002450 <add_to_list+0x8e>
    panic("can't add null to list");
    800023fe:	00006517          	auipc	a0,0x6
    80002402:	e5250513          	addi	a0,a0,-430 # 80008250 <digits+0x210>
    80002406:	ffffe097          	auipc	ra,0xffffe
    8000240a:	138080e7          	jalr	312(ra) # 8000053e <panic>
        release_list(type, cpu_id);
    8000240e:	85d6                	mv	a1,s5
    80002410:	8552                	mv	a0,s4
    80002412:	00000097          	auipc	ra,0x0
    80002416:	8ac080e7          	jalr	-1876(ra) # 80001cbe <release_list>
      head = head->next;
    8000241a:	68bc                	ld	a5,80(s1)
    while(head){
    8000241c:	8926                	mv	s2,s1
    8000241e:	c395                	beqz	a5,80002442 <add_to_list+0x80>
      head = head->next;
    80002420:	84be                	mv	s1,a5
      acquire(&head->list_lock);
    80002422:	01848993          	addi	s3,s1,24
    80002426:	854e                	mv	a0,s3
    80002428:	ffffe097          	auipc	ra,0xffffe
    8000242c:	7c4080e7          	jalr	1988(ra) # 80000bec <acquire>
      if(prev){
    80002430:	fc090fe3          	beqz	s2,8000240e <add_to_list+0x4c>
        release(&prev->list_lock);
    80002434:	01890513          	addi	a0,s2,24
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	86e080e7          	jalr	-1938(ra) # 80000ca6 <release>
    80002440:	bfe9                	j	8000241a <add_to_list+0x58>
    prev->next = p;
    80002442:	0564b823          	sd	s6,80(s1)
    release(&prev->list_lock);
    80002446:	854e                	mv	a0,s3
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	85e080e7          	jalr	-1954(ra) # 80000ca6 <release>
}
    80002450:	70e2                	ld	ra,56(sp)
    80002452:	7442                	ld	s0,48(sp)
    80002454:	74a2                	ld	s1,40(sp)
    80002456:	7902                	ld	s2,32(sp)
    80002458:	69e2                	ld	s3,24(sp)
    8000245a:	6a42                	ld	s4,16(sp)
    8000245c:	6aa2                	ld	s5,8(sp)
    8000245e:	6b02                	ld	s6,0(sp)
    80002460:	6121                	addi	sp,sp,64
    80002462:	8082                	ret

0000000080002464 <add_proc_to_list>:
{
    80002464:	7179                	addi	sp,sp,-48
    80002466:	f406                	sd	ra,40(sp)
    80002468:	f022                	sd	s0,32(sp)
    8000246a:	ec26                	sd	s1,24(sp)
    8000246c:	e84a                	sd	s2,16(sp)
    8000246e:	e44e                	sd	s3,8(sp)
    80002470:	1800                	addi	s0,sp,48
  if(!p){
    80002472:	cd1d                	beqz	a0,800024b0 <add_proc_to_list+0x4c>
    80002474:	89aa                	mv	s3,a0
    80002476:	84ae                	mv	s1,a1
    80002478:	8932                	mv	s2,a2
  getList(type, cpu_id);
    8000247a:	85b2                	mv	a1,a2
    8000247c:	8526                	mv	a0,s1
    8000247e:	00000097          	auipc	ra,0x0
    80002482:	d5c080e7          	jalr	-676(ra) # 800021da <getList>
  head = getFirst(type, cpu_id);
    80002486:	85ca                	mv	a1,s2
    80002488:	8526                	mv	a0,s1
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	706080e7          	jalr	1798(ra) # 80001b90 <getFirst>
    80002492:	85aa                	mv	a1,a0
  add_to_list(p, head, type, cpu_id);
    80002494:	86ca                	mv	a3,s2
    80002496:	8626                	mv	a2,s1
    80002498:	854e                	mv	a0,s3
    8000249a:	00000097          	auipc	ra,0x0
    8000249e:	f28080e7          	jalr	-216(ra) # 800023c2 <add_to_list>
}
    800024a2:	70a2                	ld	ra,40(sp)
    800024a4:	7402                	ld	s0,32(sp)
    800024a6:	64e2                	ld	s1,24(sp)
    800024a8:	6942                	ld	s2,16(sp)
    800024aa:	69a2                	ld	s3,8(sp)
    800024ac:	6145                	addi	sp,sp,48
    800024ae:	8082                	ret
    panic("Add proc to list");
    800024b0:	00006517          	auipc	a0,0x6
    800024b4:	e7850513          	addi	a0,a0,-392 # 80008328 <digits+0x2e8>
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	086080e7          	jalr	134(ra) # 8000053e <panic>

00000000800024c0 <procinit>:
{
    800024c0:	715d                	addi	sp,sp,-80
    800024c2:	e486                	sd	ra,72(sp)
    800024c4:	e0a2                	sd	s0,64(sp)
    800024c6:	fc26                	sd	s1,56(sp)
    800024c8:	f84a                	sd	s2,48(sp)
    800024ca:	f44e                	sd	s3,40(sp)
    800024cc:	f052                	sd	s4,32(sp)
    800024ce:	ec56                	sd	s5,24(sp)
    800024d0:	e85a                	sd	s6,16(sp)
    800024d2:	e45e                	sd	s7,8(sp)
    800024d4:	e062                	sd	s8,0(sp)
    800024d6:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800024d8:	00006597          	auipc	a1,0x6
    800024dc:	e6858593          	addi	a1,a1,-408 # 80008340 <digits+0x300>
    800024e0:	0000f517          	auipc	a0,0xf
    800024e4:	0d050513          	addi	a0,a0,208 # 800115b0 <pid_lock>
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	66c080e7          	jalr	1644(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    800024f0:	00006597          	auipc	a1,0x6
    800024f4:	e5858593          	addi	a1,a1,-424 # 80008348 <digits+0x308>
    800024f8:	0000f517          	auipc	a0,0xf
    800024fc:	0d050513          	addi	a0,a0,208 # 800115c8 <wait_lock>
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	654080e7          	jalr	1620(ra) # 80000b54 <initlock>
  initlock(&zombie_lock, "zombie lock");
    80002508:	00006597          	auipc	a1,0x6
    8000250c:	e5058593          	addi	a1,a1,-432 # 80008358 <digits+0x318>
    80002510:	0000f517          	auipc	a0,0xf
    80002514:	05850513          	addi	a0,a0,88 # 80011568 <zombie_lock>
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	63c080e7          	jalr	1596(ra) # 80000b54 <initlock>
  initlock(&sleeping_lock, "sleeping lock");
    80002520:	00006597          	auipc	a1,0x6
    80002524:	e4858593          	addi	a1,a1,-440 # 80008368 <digits+0x328>
    80002528:	0000f517          	auipc	a0,0xf
    8000252c:	05850513          	addi	a0,a0,88 # 80011580 <sleeping_lock>
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	624080e7          	jalr	1572(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused lock");
    80002538:	00006597          	auipc	a1,0x6
    8000253c:	e4058593          	addi	a1,a1,-448 # 80008378 <digits+0x338>
    80002540:	0000f517          	auipc	a0,0xf
    80002544:	05850513          	addi	a0,a0,88 # 80011598 <unused_lock>
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	60c080e7          	jalr	1548(ra) # 80000b54 <initlock>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    80002550:	0000f497          	auipc	s1,0xf
    80002554:	fd048493          	addi	s1,s1,-48 # 80011520 <ready_lock>
    initlock(s, "ready lock");
    80002558:	00006997          	auipc	s3,0x6
    8000255c:	e3098993          	addi	s3,s3,-464 # 80008388 <digits+0x348>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    80002560:	0000f917          	auipc	s2,0xf
    80002564:	00890913          	addi	s2,s2,8 # 80011568 <zombie_lock>
    initlock(s, "ready lock");
    80002568:	85ce                	mv	a1,s3
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	5e8080e7          	jalr	1512(ra) # 80000b54 <initlock>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    80002574:	04e1                	addi	s1,s1,24
    80002576:	ff2499e3          	bne	s1,s2,80002568 <procinit+0xa8>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000257a:	0000f497          	auipc	s1,0xf
    8000257e:	06648493          	addi	s1,s1,102 # 800115e0 <proc>
      initlock(&p->lock, "proc");
    80002582:	00006c17          	auipc	s8,0x6
    80002586:	e16c0c13          	addi	s8,s8,-490 # 80008398 <digits+0x358>
      initlock(&p->list_lock, "list lock");
    8000258a:	00006b97          	auipc	s7,0x6
    8000258e:	e16b8b93          	addi	s7,s7,-490 # 800083a0 <digits+0x360>
      p->kstack = KSTACK((int) (p - proc));
    80002592:	8b26                	mv	s6,s1
    80002594:	00006a97          	auipc	s5,0x6
    80002598:	a6ca8a93          	addi	s5,s5,-1428 # 80008000 <etext>
    8000259c:	04000937          	lui	s2,0x4000
    800025a0:	197d                	addi	s2,s2,-1
    800025a2:	0932                	slli	s2,s2,0xc
       p->parent_cpu = -1;
    800025a4:	5a7d                	li	s4,-1
  for(p = proc; p < &proc[NPROC]; p++) {
    800025a6:	00015997          	auipc	s3,0x15
    800025aa:	43a98993          	addi	s3,s3,1082 # 800179e0 <tickslock>
      initlock(&p->lock, "proc");
    800025ae:	85e2                	mv	a1,s8
    800025b0:	8526                	mv	a0,s1
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	5a2080e7          	jalr	1442(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list lock");
    800025ba:	85de                	mv	a1,s7
    800025bc:	01848513          	addi	a0,s1,24
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	594080e7          	jalr	1428(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800025c8:	416487b3          	sub	a5,s1,s6
    800025cc:	8791                	srai	a5,a5,0x4
    800025ce:	000ab703          	ld	a4,0(s5)
    800025d2:	02e787b3          	mul	a5,a5,a4
    800025d6:	2785                	addiw	a5,a5,1
    800025d8:	00d7979b          	slliw	a5,a5,0xd
    800025dc:	40f907b3          	sub	a5,s2,a5
    800025e0:	f4bc                	sd	a5,104(s1)
       p->parent_cpu = -1;
    800025e2:	0544ac23          	sw	s4,88(s1)
       add_proc_to_list(p, unuseList, -1);
    800025e6:	567d                	li	a2,-1
    800025e8:	458d                	li	a1,3
    800025ea:	8526                	mv	a0,s1
    800025ec:	00000097          	auipc	ra,0x0
    800025f0:	e78080e7          	jalr	-392(ra) # 80002464 <add_proc_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025f4:	19048493          	addi	s1,s1,400
    800025f8:	fb349be3          	bne	s1,s3,800025ae <procinit+0xee>
}
    800025fc:	60a6                	ld	ra,72(sp)
    800025fe:	6406                	ld	s0,64(sp)
    80002600:	74e2                	ld	s1,56(sp)
    80002602:	7942                	ld	s2,48(sp)
    80002604:	79a2                	ld	s3,40(sp)
    80002606:	7a02                	ld	s4,32(sp)
    80002608:	6ae2                	ld	s5,24(sp)
    8000260a:	6b42                	ld	s6,16(sp)
    8000260c:	6ba2                	ld	s7,8(sp)
    8000260e:	6c02                	ld	s8,0(sp)
    80002610:	6161                	addi	sp,sp,80
    80002612:	8082                	ret

0000000080002614 <remove_first>:
{
    80002614:	7179                	addi	sp,sp,-48
    80002616:	f406                	sd	ra,40(sp)
    80002618:	f022                	sd	s0,32(sp)
    8000261a:	ec26                	sd	s1,24(sp)
    8000261c:	e84a                	sd	s2,16(sp)
    8000261e:	e44e                	sd	s3,8(sp)
    80002620:	e052                	sd	s4,0(sp)
    80002622:	1800                	addi	s0,sp,48
    80002624:	892a                	mv	s2,a0
    80002626:	89ae                	mv	s3,a1
  getList(type, cpu_id);//acquire lock
    80002628:	00000097          	auipc	ra,0x0
    8000262c:	bb2080e7          	jalr	-1102(ra) # 800021da <getList>
  struct proc* head = getFirst(type, cpu_id);//aquire list after we have loock 
    80002630:	85ce                	mv	a1,s3
    80002632:	854a                	mv	a0,s2
    80002634:	fffff097          	auipc	ra,0xfffff
    80002638:	55c080e7          	jalr	1372(ra) # 80001b90 <getFirst>
    8000263c:	84aa                	mv	s1,a0
  if(!head){
    8000263e:	c529                	beqz	a0,80002688 <remove_first+0x74>
    acquire(&head->list_lock);
    80002640:	01850a13          	addi	s4,a0,24
    80002644:	8552                	mv	a0,s4
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	5a6080e7          	jalr	1446(ra) # 80000bec <acquire>
    setFirst(head->next, type, cpu_id);
    8000264e:	864e                	mv	a2,s3
    80002650:	85ca                	mv	a1,s2
    80002652:	68a8                	ld	a0,80(s1)
    80002654:	00000097          	auipc	ra,0x0
    80002658:	c86080e7          	jalr	-890(ra) # 800022da <setFirst>
    head->next = 0;
    8000265c:	0404b823          	sd	zero,80(s1)
    release(&head->list_lock);
    80002660:	8552                	mv	a0,s4
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	644080e7          	jalr	1604(ra) # 80000ca6 <release>
    release_list(type, cpu_id);//realese loock 
    8000266a:	85ce                	mv	a1,s3
    8000266c:	854a                	mv	a0,s2
    8000266e:	fffff097          	auipc	ra,0xfffff
    80002672:	650080e7          	jalr	1616(ra) # 80001cbe <release_list>
}
    80002676:	8526                	mv	a0,s1
    80002678:	70a2                	ld	ra,40(sp)
    8000267a:	7402                	ld	s0,32(sp)
    8000267c:	64e2                	ld	s1,24(sp)
    8000267e:	6942                	ld	s2,16(sp)
    80002680:	69a2                	ld	s3,8(sp)
    80002682:	6a02                	ld	s4,0(sp)
    80002684:	6145                	addi	sp,sp,48
    80002686:	8082                	ret
    release_list(type, cpu_id);//realese loock 
    80002688:	85ce                	mv	a1,s3
    8000268a:	854a                	mv	a0,s2
    8000268c:	fffff097          	auipc	ra,0xfffff
    80002690:	632080e7          	jalr	1586(ra) # 80001cbe <release_list>
    80002694:	b7cd                	j	80002676 <remove_first+0x62>

0000000080002696 <blncflag_on>:
{
    80002696:	7139                	addi	sp,sp,-64
    80002698:	fc06                	sd	ra,56(sp)
    8000269a:	f822                	sd	s0,48(sp)
    8000269c:	f426                	sd	s1,40(sp)
    8000269e:	f04a                	sd	s2,32(sp)
    800026a0:	ec4e                	sd	s3,24(sp)
    800026a2:	e852                	sd	s4,16(sp)
    800026a4:	e456                	sd	s5,8(sp)
    800026a6:	e05a                	sd	s6,0(sp)
    800026a8:	0080                	addi	s0,sp,64
    800026aa:	8792                	mv	a5,tp
  int id = r_tp();
    800026ac:	2781                	sext.w	a5,a5
    800026ae:	8a12                	mv	s4,tp
    800026b0:	2a01                	sext.w	s4,s4
  c->proc = 0;
    800026b2:	00379993          	slli	s3,a5,0x3
    800026b6:	00f98733          	add	a4,s3,a5
    800026ba:	00471693          	slli	a3,a4,0x4
    800026be:	0000f717          	auipc	a4,0xf
    800026c2:	c2270713          	addi	a4,a4,-990 # 800112e0 <readyLock>
    800026c6:	9736                	add	a4,a4,a3
    800026c8:	08073c23          	sd	zero,152(a4)
    swtch(&c->context, &p->context);
    800026cc:	0000f717          	auipc	a4,0xf
    800026d0:	cb470713          	addi	a4,a4,-844 # 80011380 <cpus+0x10>
    800026d4:	00e689b3          	add	s3,a3,a4
    if(p->state!=RUNNABLE)
    800026d8:	4a8d                	li	s5,3
    p->state = RUNNING;
    800026da:	4b11                	li	s6,4
    c->proc = p;
    800026dc:	0000f917          	auipc	s2,0xf
    800026e0:	c0490913          	addi	s2,s2,-1020 # 800112e0 <readyLock>
    800026e4:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800026ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ee:	10079073          	csrw	sstatus,a5
    p = remove_first(readyList, cpu_id);
    800026f2:	85d2                	mv	a1,s4
    800026f4:	4501                	li	a0,0
    800026f6:	00000097          	auipc	ra,0x0
    800026fa:	f1e080e7          	jalr	-226(ra) # 80002614 <remove_first>
    800026fe:	84aa                	mv	s1,a0
    if(!p){
    80002700:	d17d                	beqz	a0,800026e6 <blncflag_on+0x50>
    acquire(&p->lock);
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	4ea080e7          	jalr	1258(ra) # 80000bec <acquire>
    if(p->state!=RUNNABLE)
    8000270a:	589c                	lw	a5,48(s1)
    8000270c:	03579563          	bne	a5,s5,80002736 <blncflag_on+0xa0>
    p->state = RUNNING;
    80002710:	0364a823          	sw	s6,48(s1)
    c->proc = p;
    80002714:	08993c23          	sd	s1,152(s2)
    swtch(&c->context, &p->context);
    80002718:	08848593          	addi	a1,s1,136
    8000271c:	854e                	mv	a0,s3
    8000271e:	00001097          	auipc	ra,0x1
    80002722:	be4080e7          	jalr	-1052(ra) # 80003302 <swtch>
    c->proc = 0;
    80002726:	08093c23          	sd	zero,152(s2)
    release(&p->lock);
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	57a080e7          	jalr	1402(ra) # 80000ca6 <release>
    80002734:	bf4d                	j	800026e6 <blncflag_on+0x50>
      panic("bad proc was selected");
    80002736:	00006517          	auipc	a0,0x6
    8000273a:	c7a50513          	addi	a0,a0,-902 # 800083b0 <digits+0x370>
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	e00080e7          	jalr	-512(ra) # 8000053e <panic>

0000000080002746 <scheduler>:
{
    80002746:	1141                	addi	sp,sp,-16
    80002748:	e406                	sd	ra,8(sp)
    8000274a:	e022                	sd	s0,0(sp)
    8000274c:	0800                	addi	s0,sp,16
      if(!print_flag){
    8000274e:	00007797          	auipc	a5,0x7
    80002752:	91e7a783          	lw	a5,-1762(a5) # 8000906c <print_flag>
    80002756:	c789                	beqz	a5,80002760 <scheduler+0x1a>
    blncflag_on();
    80002758:	00000097          	auipc	ra,0x0
    8000275c:	f3e080e7          	jalr	-194(ra) # 80002696 <blncflag_on>
      print_flag++;
    80002760:	4785                	li	a5,1
    80002762:	00007717          	auipc	a4,0x7
    80002766:	90f72523          	sw	a5,-1782(a4) # 8000906c <print_flag>
      printf("BLNCFLG is ON\n");
    8000276a:	00006517          	auipc	a0,0x6
    8000276e:	c5e50513          	addi	a0,a0,-930 # 800083c8 <digits+0x388>
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	e16080e7          	jalr	-490(ra) # 80000588 <printf>
    8000277a:	bff9                	j	80002758 <scheduler+0x12>

000000008000277c <blncflag_off>:
{
    8000277c:	7139                	addi	sp,sp,-64
    8000277e:	fc06                	sd	ra,56(sp)
    80002780:	f822                	sd	s0,48(sp)
    80002782:	f426                	sd	s1,40(sp)
    80002784:	f04a                	sd	s2,32(sp)
    80002786:	ec4e                	sd	s3,24(sp)
    80002788:	e852                	sd	s4,16(sp)
    8000278a:	e456                	sd	s5,8(sp)
    8000278c:	e05a                	sd	s6,0(sp)
    8000278e:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80002790:	8792                	mv	a5,tp
  int id = r_tp();
    80002792:	2781                	sext.w	a5,a5
    80002794:	8a12                	mv	s4,tp
    80002796:	2a01                	sext.w	s4,s4
  c->proc = 0;
    80002798:	00379993          	slli	s3,a5,0x3
    8000279c:	00f98733          	add	a4,s3,a5
    800027a0:	00471693          	slli	a3,a4,0x4
    800027a4:	0000f717          	auipc	a4,0xf
    800027a8:	b3c70713          	addi	a4,a4,-1220 # 800112e0 <readyLock>
    800027ac:	9736                	add	a4,a4,a3
    800027ae:	08073c23          	sd	zero,152(a4)
        swtch(&c->context, &p->context);
    800027b2:	0000f717          	auipc	a4,0xf
    800027b6:	bce70713          	addi	a4,a4,-1074 # 80011380 <cpus+0x10>
    800027ba:	00e689b3          	add	s3,a3,a4
      if(p->state != RUNNABLE)
    800027be:	4a8d                	li	s5,3
        p->state = RUNNING;
    800027c0:	4b11                	li	s6,4
        c->proc = p;
    800027c2:	0000f917          	auipc	s2,0xf
    800027c6:	b1e90913          	addi	s2,s2,-1250 # 800112e0 <readyLock>
    800027ca:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027d0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d4:	10079073          	csrw	sstatus,a5
    p = remove_first(readyList, cpu_id);
    800027d8:	85d2                	mv	a1,s4
    800027da:	4501                	li	a0,0
    800027dc:	00000097          	auipc	ra,0x0
    800027e0:	e38080e7          	jalr	-456(ra) # 80002614 <remove_first>
    800027e4:	84aa                	mv	s1,a0
    if(!p){ // no proces ready 
    800027e6:	d17d                	beqz	a0,800027cc <blncflag_off+0x50>
      acquire(&p->lock);
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	404080e7          	jalr	1028(ra) # 80000bec <acquire>
      if(p->state != RUNNABLE)
    800027f0:	589c                	lw	a5,48(s1)
    800027f2:	03579563          	bne	a5,s5,8000281c <blncflag_off+0xa0>
        p->state = RUNNING;
    800027f6:	0364a823          	sw	s6,48(s1)
        c->proc = p;
    800027fa:	08993c23          	sd	s1,152(s2)
        swtch(&c->context, &p->context);
    800027fe:	08848593          	addi	a1,s1,136
    80002802:	854e                	mv	a0,s3
    80002804:	00001097          	auipc	ra,0x1
    80002808:	afe080e7          	jalr	-1282(ra) # 80003302 <swtch>
        c->proc = 0;
    8000280c:	08093c23          	sd	zero,152(s2)
      release(&p->lock);
    80002810:	8526                	mv	a0,s1
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	494080e7          	jalr	1172(ra) # 80000ca6 <release>
    8000281a:	bf4d                	j	800027cc <blncflag_off+0x50>
        panic("bad proc was selected");
    8000281c:	00006517          	auipc	a0,0x6
    80002820:	b9450513          	addi	a0,a0,-1132 # 800083b0 <digits+0x370>
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	d1a080e7          	jalr	-742(ra) # 8000053e <panic>

000000008000282c <remove_proc>:
remove_proc(struct proc* p, int type){
    8000282c:	7179                	addi	sp,sp,-48
    8000282e:	f406                	sd	ra,40(sp)
    80002830:	f022                	sd	s0,32(sp)
    80002832:	ec26                	sd	s1,24(sp)
    80002834:	e84a                	sd	s2,16(sp)
    80002836:	e44e                	sd	s3,8(sp)
    80002838:	e052                	sd	s4,0(sp)
    8000283a:	1800                	addi	s0,sp,48
    8000283c:	8a2a                	mv	s4,a0
    8000283e:	84ae                	mv	s1,a1
  getList(type, p->parent_cpu);
    80002840:	4d2c                	lw	a1,88(a0)
    80002842:	8526                	mv	a0,s1
    80002844:	00000097          	auipc	ra,0x0
    80002848:	996080e7          	jalr	-1642(ra) # 800021da <getList>
  struct proc* head = getFirst(type, p->parent_cpu);
    8000284c:	058a2583          	lw	a1,88(s4)
    80002850:	8526                	mv	a0,s1
    80002852:	fffff097          	auipc	ra,0xfffff
    80002856:	33e080e7          	jalr	830(ra) # 80001b90 <getFirst>
  if(!head){
    8000285a:	c521                	beqz	a0,800028a2 <remove_proc+0x76>
    8000285c:	892a                	mv	s2,a0
    if(p == head){
    8000285e:	04aa0b63          	beq	s4,a0,800028b4 <remove_proc+0x88>
        acquire(&head->list_lock);
    80002862:	0561                	addi	a0,a0,24
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	388080e7          	jalr	904(ra) # 80000bec <acquire>
          release_list(type,p->parent_cpu);
    8000286c:	058a2583          	lw	a1,88(s4)
    80002870:	8526                	mv	a0,s1
    80002872:	fffff097          	auipc	ra,0xfffff
    80002876:	44c080e7          	jalr	1100(ra) # 80001cbe <release_list>
        head = head->next;
    8000287a:	05093483          	ld	s1,80(s2)
      while(head){
    8000287e:	c4c5                	beqz	s1,80002926 <remove_proc+0xfa>
        acquire(&head->list_lock);
    80002880:	01848993          	addi	s3,s1,24
    80002884:	854e                	mv	a0,s3
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	366080e7          	jalr	870(ra) # 80000bec <acquire>
        if(p == head){
    8000288e:	069a0363          	beq	s4,s1,800028f4 <remove_proc+0xc8>
          release(&prev->list_lock);
    80002892:	01890513          	addi	a0,s2,24
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	410080e7          	jalr	1040(ra) # 80000ca6 <release>
        head = head->next;
    8000289e:	8926                	mv	s2,s1
    800028a0:	bfe9                	j	8000287a <remove_proc+0x4e>
    release_list(type, p->parent_cpu);
    800028a2:	058a2583          	lw	a1,88(s4)
    800028a6:	8526                	mv	a0,s1
    800028a8:	fffff097          	auipc	ra,0xfffff
    800028ac:	416080e7          	jalr	1046(ra) # 80001cbe <release_list>
    return 0;
    800028b0:	4501                	li	a0,0
    800028b2:	a095                	j	80002916 <remove_proc+0xea>
      acquire(&p->list_lock);
    800028b4:	01850993          	addi	s3,a0,24
    800028b8:	854e                	mv	a0,s3
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	332080e7          	jalr	818(ra) # 80000bec <acquire>
      setFirst(p->next, type, p->parent_cpu);
    800028c2:	05892603          	lw	a2,88(s2)
    800028c6:	85a6                	mv	a1,s1
    800028c8:	05093503          	ld	a0,80(s2)
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	a0e080e7          	jalr	-1522(ra) # 800022da <setFirst>
      p->next = 0;
    800028d4:	04093823          	sd	zero,80(s2)
      release(&p->list_lock);
    800028d8:	854e                	mv	a0,s3
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	3cc080e7          	jalr	972(ra) # 80000ca6 <release>
      release_list(type, p->parent_cpu);
    800028e2:	05892583          	lw	a1,88(s2)
    800028e6:	8526                	mv	a0,s1
    800028e8:	fffff097          	auipc	ra,0xfffff
    800028ec:	3d6080e7          	jalr	982(ra) # 80001cbe <release_list>
    return 0;
    800028f0:	4501                	li	a0,0
    800028f2:	a015                	j	80002916 <remove_proc+0xea>
          prev->next = head->next;
    800028f4:	68bc                	ld	a5,80(s1)
    800028f6:	04f93823          	sd	a5,80(s2)
          p->next = 0;
    800028fa:	0404b823          	sd	zero,80(s1)
          release(&head->list_lock);
    800028fe:	854e                	mv	a0,s3
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	3a6080e7          	jalr	934(ra) # 80000ca6 <release>
          release(&prev->list_lock);
    80002908:	01890513          	addi	a0,s2,24
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	39a080e7          	jalr	922(ra) # 80000ca6 <release>
          return 1;
    80002914:	4505                	li	a0,1
}
    80002916:	70a2                	ld	ra,40(sp)
    80002918:	7402                	ld	s0,32(sp)
    8000291a:	64e2                	ld	s1,24(sp)
    8000291c:	6942                	ld	s2,16(sp)
    8000291e:	69a2                	ld	s3,8(sp)
    80002920:	6a02                	ld	s4,0(sp)
    80002922:	6145                	addi	sp,sp,48
    80002924:	8082                	ret
    return 0;
    80002926:	4501                	li	a0,0
    80002928:	b7fd                	j	80002916 <remove_proc+0xea>

000000008000292a <freeproc>:
{
    8000292a:	1101                	addi	sp,sp,-32
    8000292c:	ec06                	sd	ra,24(sp)
    8000292e:	e822                	sd	s0,16(sp)
    80002930:	e426                	sd	s1,8(sp)
    80002932:	1000                	addi	s0,sp,32
    80002934:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002936:	6148                	ld	a0,128(a0)
    80002938:	c509                	beqz	a0,80002942 <freeproc+0x18>
    kfree((void*)p->trapframe);
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	0be080e7          	jalr	190(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002942:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    80002946:	7ca8                	ld	a0,120(s1)
    80002948:	c511                	beqz	a0,80002954 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    8000294a:	78ac                	ld	a1,112(s1)
    8000294c:	fffff097          	auipc	ra,0xfffff
    80002950:	634080e7          	jalr	1588(ra) # 80001f80 <proc_freepagetable>
  p->pagetable = 0;
    80002954:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    80002958:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    8000295c:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    80002960:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    80002964:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    80002968:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    8000296c:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80002970:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    80002974:	0204a823          	sw	zero,48(s1)
  remove_proc(p, zombeList);
    80002978:	4585                	li	a1,1
    8000297a:	8526                	mv	a0,s1
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	eb0080e7          	jalr	-336(ra) # 8000282c <remove_proc>
  add_proc_to_list(p, unuseList, -1);
    80002984:	567d                	li	a2,-1
    80002986:	458d                	li	a1,3
    80002988:	8526                	mv	a0,s1
    8000298a:	00000097          	auipc	ra,0x0
    8000298e:	ada080e7          	jalr	-1318(ra) # 80002464 <add_proc_to_list>
}
    80002992:	60e2                	ld	ra,24(sp)
    80002994:	6442                	ld	s0,16(sp)
    80002996:	64a2                	ld	s1,8(sp)
    80002998:	6105                	addi	sp,sp,32
    8000299a:	8082                	ret

000000008000299c <allocproc>:
{
    8000299c:	7179                	addi	sp,sp,-48
    8000299e:	f406                	sd	ra,40(sp)
    800029a0:	f022                	sd	s0,32(sp)
    800029a2:	ec26                	sd	s1,24(sp)
    800029a4:	e84a                	sd	s2,16(sp)
    800029a6:	e44e                	sd	s3,8(sp)
    800029a8:	1800                	addi	s0,sp,48
  p = remove_first(unuseList, -1);
    800029aa:	55fd                	li	a1,-1
    800029ac:	450d                	li	a0,3
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	c66080e7          	jalr	-922(ra) # 80002614 <remove_first>
    800029b6:	84aa                	mv	s1,a0
  if(!p){
    800029b8:	cd39                	beqz	a0,80002a16 <allocproc+0x7a>
  acquire(&p->lock);
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	232080e7          	jalr	562(ra) # 80000bec <acquire>
  p->pid = allocpid();
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	4ea080e7          	jalr	1258(ra) # 80001eac <allocpid>
    800029ca:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    800029cc:	4785                	li	a5,1
    800029ce:	d89c                	sw	a5,48(s1)
  p->next = 0;
    800029d0:	0404b823          	sd	zero,80(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	120080e7          	jalr	288(ra) # 80000af4 <kalloc>
    800029dc:	892a                	mv	s2,a0
    800029de:	e0c8                	sd	a0,128(s1)
    800029e0:	c139                	beqz	a0,80002a26 <allocproc+0x8a>
  p->pagetable = proc_pagetable(p);
    800029e2:	8526                	mv	a0,s1
    800029e4:	fffff097          	auipc	ra,0xfffff
    800029e8:	500080e7          	jalr	1280(ra) # 80001ee4 <proc_pagetable>
    800029ec:	892a                	mv	s2,a0
    800029ee:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    800029f0:	c539                	beqz	a0,80002a3e <allocproc+0xa2>
  memset(&p->context, 0, sizeof(p->context));
    800029f2:	07000613          	li	a2,112
    800029f6:	4581                	li	a1,0
    800029f8:	08848513          	addi	a0,s1,136
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	2f2080e7          	jalr	754(ra) # 80000cee <memset>
  p->context.ra = (uint64)forkret;
    80002a04:	fffff797          	auipc	a5,0xfffff
    80002a08:	46278793          	addi	a5,a5,1122 # 80001e66 <forkret>
    80002a0c:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002a0e:	74bc                	ld	a5,104(s1)
    80002a10:	6705                	lui	a4,0x1
    80002a12:	97ba                	add	a5,a5,a4
    80002a14:	e8dc                	sd	a5,144(s1)
}
    80002a16:	8526                	mv	a0,s1
    80002a18:	70a2                	ld	ra,40(sp)
    80002a1a:	7402                	ld	s0,32(sp)
    80002a1c:	64e2                	ld	s1,24(sp)
    80002a1e:	6942                	ld	s2,16(sp)
    80002a20:	69a2                	ld	s3,8(sp)
    80002a22:	6145                	addi	sp,sp,48
    80002a24:	8082                	ret
    freeproc(p);
    80002a26:	8526                	mv	a0,s1
    80002a28:	00000097          	auipc	ra,0x0
    80002a2c:	f02080e7          	jalr	-254(ra) # 8000292a <freeproc>
    release(&p->lock);
    80002a30:	8526                	mv	a0,s1
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	274080e7          	jalr	628(ra) # 80000ca6 <release>
    return 0;
    80002a3a:	84ca                	mv	s1,s2
    80002a3c:	bfe9                	j	80002a16 <allocproc+0x7a>
    freeproc(p);
    80002a3e:	8526                	mv	a0,s1
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	eea080e7          	jalr	-278(ra) # 8000292a <freeproc>
    release(&p->lock);
    80002a48:	8526                	mv	a0,s1
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	25c080e7          	jalr	604(ra) # 80000ca6 <release>
    return 0;
    80002a52:	84ca                	mv	s1,s2
    80002a54:	b7c9                	j	80002a16 <allocproc+0x7a>

0000000080002a56 <userinit>:
{
    80002a56:	1101                	addi	sp,sp,-32
    80002a58:	ec06                	sd	ra,24(sp)
    80002a5a:	e822                	sd	s0,16(sp)
    80002a5c:	e426                	sd	s1,8(sp)
    80002a5e:	1000                	addi	s0,sp,32
  if(!init){
    80002a60:	00006797          	auipc	a5,0x6
    80002a64:	5e07a783          	lw	a5,1504(a5) # 80009040 <init>
    80002a68:	e795                	bnez	a5,80002a94 <userinit+0x3e>
      c->first = 0;
    80002a6a:	0000f797          	auipc	a5,0xf
    80002a6e:	87678793          	addi	a5,a5,-1930 # 800112e0 <readyLock>
    80002a72:	1007bc23          	sd	zero,280(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    80002a76:	0807b823          	sd	zero,144(a5)
      c->first = 0;
    80002a7a:	1a07b423          	sd	zero,424(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    80002a7e:	1207b023          	sd	zero,288(a5)
      c->first = 0;
    80002a82:	2207bc23          	sd	zero,568(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    80002a86:	1a07b823          	sd	zero,432(a5)
    init = 1;
    80002a8a:	4785                	li	a5,1
    80002a8c:	00006717          	auipc	a4,0x6
    80002a90:	5af72a23          	sw	a5,1460(a4) # 80009040 <init>
  p = allocproc();
    80002a94:	00000097          	auipc	ra,0x0
    80002a98:	f08080e7          	jalr	-248(ra) # 8000299c <allocproc>
    80002a9c:	84aa                	mv	s1,a0
  initproc = p;
    80002a9e:	00006797          	auipc	a5,0x6
    80002aa2:	5ca7b123          	sd	a0,1474(a5) # 80009060 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002aa6:	03400613          	li	a2,52
    80002aaa:	00006597          	auipc	a1,0x6
    80002aae:	f1658593          	addi	a1,a1,-234 # 800089c0 <initcode>
    80002ab2:	7d28                	ld	a0,120(a0)
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	8c2080e7          	jalr	-1854(ra) # 80001376 <uvminit>
  p->sz = PGSIZE;
    80002abc:	6785                	lui	a5,0x1
    80002abe:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    80002ac0:	60d8                	ld	a4,128(s1)
    80002ac2:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002ac6:	60d8                	ld	a4,128(s1)
    80002ac8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002aca:	4641                	li	a2,16
    80002acc:	00006597          	auipc	a1,0x6
    80002ad0:	90c58593          	addi	a1,a1,-1780 # 800083d8 <digits+0x398>
    80002ad4:	18048513          	addi	a0,s1,384
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	368080e7          	jalr	872(ra) # 80000e40 <safestrcpy>
  p->cwd = namei("/");
    80002ae0:	00006517          	auipc	a0,0x6
    80002ae4:	90850513          	addi	a0,a0,-1784 # 800083e8 <digits+0x3a8>
    80002ae8:	00002097          	auipc	ra,0x2
    80002aec:	07e080e7          	jalr	126(ra) # 80004b66 <namei>
    80002af0:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    80002af4:	478d                	li	a5,3
    80002af6:	d89c                	sw	a5,48(s1)
  p->parent_cpu = 0;
    80002af8:	0404ac23          	sw	zero,88(s1)
  cahnge_number_of_proc(p->parent_cpu,a);
    80002afc:	4585                	li	a1,1
    80002afe:	4501                	li	a0,0
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	040080e7          	jalr	64(ra) # 80001b40 <cahnge_number_of_proc>
  cpus[p->parent_cpu].first = p;
    80002b08:	4cb8                	lw	a4,88(s1)
    80002b0a:	00371793          	slli	a5,a4,0x3
    80002b0e:	97ba                	add	a5,a5,a4
    80002b10:	0792                	slli	a5,a5,0x4
    80002b12:	0000e717          	auipc	a4,0xe
    80002b16:	7ce70713          	addi	a4,a4,1998 # 800112e0 <readyLock>
    80002b1a:	97ba                	add	a5,a5,a4
    80002b1c:	1097bc23          	sd	s1,280(a5) # 1118 <_entry-0x7fffeee8>
  release(&p->lock);
    80002b20:	8526                	mv	a0,s1
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	184080e7          	jalr	388(ra) # 80000ca6 <release>
}
    80002b2a:	60e2                	ld	ra,24(sp)
    80002b2c:	6442                	ld	s0,16(sp)
    80002b2e:	64a2                	ld	s1,8(sp)
    80002b30:	6105                	addi	sp,sp,32
    80002b32:	8082                	ret

0000000080002b34 <fork>:
{
    80002b34:	7179                	addi	sp,sp,-48
    80002b36:	f406                	sd	ra,40(sp)
    80002b38:	f022                	sd	s0,32(sp)
    80002b3a:	ec26                	sd	s1,24(sp)
    80002b3c:	e84a                	sd	s2,16(sp)
    80002b3e:	e44e                	sd	s3,8(sp)
    80002b40:	e052                	sd	s4,0(sp)
    80002b42:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	2c8080e7          	jalr	712(ra) # 80001e0c <myproc>
    80002b4c:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	e4e080e7          	jalr	-434(ra) # 8000299c <allocproc>
    80002b56:	12050863          	beqz	a0,80002c86 <fork+0x152>
    80002b5a:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002b5c:	0709b603          	ld	a2,112(s3)
    80002b60:	7d2c                	ld	a1,120(a0)
    80002b62:	0789b503          	ld	a0,120(s3)
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	a16080e7          	jalr	-1514(ra) # 8000157c <uvmcopy>
    80002b6e:	04054663          	bltz	a0,80002bba <fork+0x86>
  np->sz = p->sz;
    80002b72:	0709b783          	ld	a5,112(s3)
    80002b76:	06f93823          	sd	a5,112(s2)
  *(np->trapframe) = *(p->trapframe);
    80002b7a:	0809b683          	ld	a3,128(s3)
    80002b7e:	87b6                	mv	a5,a3
    80002b80:	08093703          	ld	a4,128(s2)
    80002b84:	12068693          	addi	a3,a3,288
    80002b88:	0007b803          	ld	a6,0(a5)
    80002b8c:	6788                	ld	a0,8(a5)
    80002b8e:	6b8c                	ld	a1,16(a5)
    80002b90:	6f90                	ld	a2,24(a5)
    80002b92:	01073023          	sd	a6,0(a4)
    80002b96:	e708                	sd	a0,8(a4)
    80002b98:	eb0c                	sd	a1,16(a4)
    80002b9a:	ef10                	sd	a2,24(a4)
    80002b9c:	02078793          	addi	a5,a5,32
    80002ba0:	02070713          	addi	a4,a4,32
    80002ba4:	fed792e3          	bne	a5,a3,80002b88 <fork+0x54>
  np->trapframe->a0 = 0;
    80002ba8:	08093783          	ld	a5,128(s2)
    80002bac:	0607b823          	sd	zero,112(a5)
    80002bb0:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80002bb4:	17800a13          	li	s4,376
    80002bb8:	a03d                	j	80002be6 <fork+0xb2>
    freeproc(np);
    80002bba:	854a                	mv	a0,s2
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	d6e080e7          	jalr	-658(ra) # 8000292a <freeproc>
    release(&np->lock);
    80002bc4:	854a                	mv	a0,s2
    80002bc6:	ffffe097          	auipc	ra,0xffffe
    80002bca:	0e0080e7          	jalr	224(ra) # 80000ca6 <release>
    return -1;
    80002bce:	5a7d                	li	s4,-1
    80002bd0:	a055                	j	80002c74 <fork+0x140>
      np->ofile[i] = filedup(p->ofile[i]);
    80002bd2:	00002097          	auipc	ra,0x2
    80002bd6:	62a080e7          	jalr	1578(ra) # 800051fc <filedup>
    80002bda:	009907b3          	add	a5,s2,s1
    80002bde:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002be0:	04a1                	addi	s1,s1,8
    80002be2:	01448763          	beq	s1,s4,80002bf0 <fork+0xbc>
    if(p->ofile[i])
    80002be6:	009987b3          	add	a5,s3,s1
    80002bea:	6388                	ld	a0,0(a5)
    80002bec:	f17d                	bnez	a0,80002bd2 <fork+0x9e>
    80002bee:	bfcd                	j	80002be0 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002bf0:	1789b503          	ld	a0,376(s3)
    80002bf4:	00001097          	auipc	ra,0x1
    80002bf8:	77e080e7          	jalr	1918(ra) # 80004372 <idup>
    80002bfc:	16a93c23          	sd	a0,376(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002c00:	4641                	li	a2,16
    80002c02:	18098593          	addi	a1,s3,384
    80002c06:	18090513          	addi	a0,s2,384
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	236080e7          	jalr	566(ra) # 80000e40 <safestrcpy>
  pid = np->pid;
    80002c12:	04892a03          	lw	s4,72(s2)
  release(&np->lock);
    80002c16:	854a                	mv	a0,s2
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	08e080e7          	jalr	142(ra) # 80000ca6 <release>
  acquire(&wait_lock);
    80002c20:	0000f497          	auipc	s1,0xf
    80002c24:	9a848493          	addi	s1,s1,-1624 # 800115c8 <wait_lock>
    80002c28:	8526                	mv	a0,s1
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	fc2080e7          	jalr	-62(ra) # 80000bec <acquire>
  np->parent = p;
    80002c32:	07393023          	sd	s3,96(s2)
  release(&wait_lock);
    80002c36:	8526                	mv	a0,s1
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	06e080e7          	jalr	110(ra) # 80000ca6 <release>
  acquire(&np->lock);
    80002c40:	854a                	mv	a0,s2
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	faa080e7          	jalr	-86(ra) # 80000bec <acquire>
  np->state = RUNNABLE;
    80002c4a:	478d                	li	a5,3
    80002c4c:	02f92823          	sw	a5,48(s2)
    int cpu_id = (BLNCFLG) ? pick_cpu() : p->parent_cpu;
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	ebc080e7          	jalr	-324(ra) # 80001b0c <pick_cpu>
    80002c58:	862a                	mv	a2,a0
  np->parent_cpu = cpu_id;
    80002c5a:	04a92c23          	sw	a0,88(s2)
  add_proc_to_list(np, readyList, cpu_id);
    80002c5e:	4581                	li	a1,0
    80002c60:	854a                	mv	a0,s2
    80002c62:	00000097          	auipc	ra,0x0
    80002c66:	802080e7          	jalr	-2046(ra) # 80002464 <add_proc_to_list>
  release(&np->lock);
    80002c6a:	854a                	mv	a0,s2
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	03a080e7          	jalr	58(ra) # 80000ca6 <release>
}
    80002c74:	8552                	mv	a0,s4
    80002c76:	70a2                	ld	ra,40(sp)
    80002c78:	7402                	ld	s0,32(sp)
    80002c7a:	64e2                	ld	s1,24(sp)
    80002c7c:	6942                	ld	s2,16(sp)
    80002c7e:	69a2                	ld	s3,8(sp)
    80002c80:	6a02                	ld	s4,0(sp)
    80002c82:	6145                	addi	sp,sp,48
    80002c84:	8082                	ret
    return -1;
    80002c86:	5a7d                	li	s4,-1
    80002c88:	b7f5                	j	80002c74 <fork+0x140>

0000000080002c8a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002c8a:	7179                	addi	sp,sp,-48
    80002c8c:	f406                	sd	ra,40(sp)
    80002c8e:	f022                	sd	s0,32(sp)
    80002c90:	ec26                	sd	s1,24(sp)
    80002c92:	e84a                	sd	s2,16(sp)
    80002c94:	e44e                	sd	s3,8(sp)
    80002c96:	1800                	addi	s0,sp,48
    80002c98:	89aa                	mv	s3,a0
    80002c9a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	170080e7          	jalr	368(ra) # 80001e0c <myproc>
    80002ca4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	f46080e7          	jalr	-186(ra) # 80000bec <acquire>
  release(lk);
    80002cae:	854a                	mv	a0,s2
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	ff6080e7          	jalr	-10(ra) # 80000ca6 <release>

  // Go to sleep.
  p->chan = chan;
    80002cb8:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    80002cbc:	4789                	li	a5,2
    80002cbe:	d89c                	sw	a5,48(s1)
  // decrease_size(p->parent_cpu);
  int b=-1;
  cahnge_number_of_proc(p->parent_cpu,b);
    80002cc0:	55fd                	li	a1,-1
    80002cc2:	4ca8                	lw	a0,88(s1)
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	e7c080e7          	jalr	-388(ra) # 80001b40 <cahnge_number_of_proc>
  //--------------------------------------------------------------------
    add_proc_to_list(p, sleepLeast,-1);
    80002ccc:	567d                	li	a2,-1
    80002cce:	4589                	li	a1,2
    80002cd0:	8526                	mv	a0,s1
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	792080e7          	jalr	1938(ra) # 80002464 <add_proc_to_list>
  //--------------------------------------------------------------------

  sched();
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	36c080e7          	jalr	876(ra) # 80002046 <sched>

  // Tidy up.
  p->chan = 0;
    80002ce2:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002ce6:	8526                	mv	a0,s1
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	fbe080e7          	jalr	-66(ra) # 80000ca6 <release>
  acquire(lk);
    80002cf0:	854a                	mv	a0,s2
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	efa080e7          	jalr	-262(ra) # 80000bec <acquire>

}
    80002cfa:	70a2                	ld	ra,40(sp)
    80002cfc:	7402                	ld	s0,32(sp)
    80002cfe:	64e2                	ld	s1,24(sp)
    80002d00:	6942                	ld	s2,16(sp)
    80002d02:	69a2                	ld	s3,8(sp)
    80002d04:	6145                	addi	sp,sp,48
    80002d06:	8082                	ret

0000000080002d08 <wait>:
{
    80002d08:	715d                	addi	sp,sp,-80
    80002d0a:	e486                	sd	ra,72(sp)
    80002d0c:	e0a2                	sd	s0,64(sp)
    80002d0e:	fc26                	sd	s1,56(sp)
    80002d10:	f84a                	sd	s2,48(sp)
    80002d12:	f44e                	sd	s3,40(sp)
    80002d14:	f052                	sd	s4,32(sp)
    80002d16:	ec56                	sd	s5,24(sp)
    80002d18:	e85a                	sd	s6,16(sp)
    80002d1a:	e45e                	sd	s7,8(sp)
    80002d1c:	e062                	sd	s8,0(sp)
    80002d1e:	0880                	addi	s0,sp,80
    80002d20:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	0ea080e7          	jalr	234(ra) # 80001e0c <myproc>
    80002d2a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002d2c:	0000f517          	auipc	a0,0xf
    80002d30:	89c50513          	addi	a0,a0,-1892 # 800115c8 <wait_lock>
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	eb8080e7          	jalr	-328(ra) # 80000bec <acquire>
    havekids = 0;
    80002d3c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002d3e:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002d40:	00015997          	auipc	s3,0x15
    80002d44:	ca098993          	addi	s3,s3,-864 # 800179e0 <tickslock>
        havekids = 1;
    80002d48:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002d4a:	0000fc17          	auipc	s8,0xf
    80002d4e:	87ec0c13          	addi	s8,s8,-1922 # 800115c8 <wait_lock>
    havekids = 0;
    80002d52:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002d54:	0000f497          	auipc	s1,0xf
    80002d58:	88c48493          	addi	s1,s1,-1908 # 800115e0 <proc>
    80002d5c:	a0bd                	j	80002dca <wait+0xc2>
          pid = np->pid;
    80002d5e:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002d62:	000b0e63          	beqz	s6,80002d7e <wait+0x76>
    80002d66:	4691                	li	a3,4
    80002d68:	04448613          	addi	a2,s1,68
    80002d6c:	85da                	mv	a1,s6
    80002d6e:	07893503          	ld	a0,120(s2)
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	90e080e7          	jalr	-1778(ra) # 80001680 <copyout>
    80002d7a:	02054563          	bltz	a0,80002da4 <wait+0x9c>
          freeproc(np);
    80002d7e:	8526                	mv	a0,s1
    80002d80:	00000097          	auipc	ra,0x0
    80002d84:	baa080e7          	jalr	-1110(ra) # 8000292a <freeproc>
          release(&np->lock);
    80002d88:	8526                	mv	a0,s1
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	f1c080e7          	jalr	-228(ra) # 80000ca6 <release>
          release(&wait_lock);
    80002d92:	0000f517          	auipc	a0,0xf
    80002d96:	83650513          	addi	a0,a0,-1994 # 800115c8 <wait_lock>
    80002d9a:	ffffe097          	auipc	ra,0xffffe
    80002d9e:	f0c080e7          	jalr	-244(ra) # 80000ca6 <release>
          return pid;
    80002da2:	a09d                	j	80002e08 <wait+0x100>
            release(&np->lock);
    80002da4:	8526                	mv	a0,s1
    80002da6:	ffffe097          	auipc	ra,0xffffe
    80002daa:	f00080e7          	jalr	-256(ra) # 80000ca6 <release>
            release(&wait_lock);
    80002dae:	0000f517          	auipc	a0,0xf
    80002db2:	81a50513          	addi	a0,a0,-2022 # 800115c8 <wait_lock>
    80002db6:	ffffe097          	auipc	ra,0xffffe
    80002dba:	ef0080e7          	jalr	-272(ra) # 80000ca6 <release>
            return -1;
    80002dbe:	59fd                	li	s3,-1
    80002dc0:	a0a1                	j	80002e08 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002dc2:	19048493          	addi	s1,s1,400
    80002dc6:	03348463          	beq	s1,s3,80002dee <wait+0xe6>
      if(np->parent == p){
    80002dca:	70bc                	ld	a5,96(s1)
    80002dcc:	ff279be3          	bne	a5,s2,80002dc2 <wait+0xba>
        acquire(&np->lock);
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	e1a080e7          	jalr	-486(ra) # 80000bec <acquire>
        if(np->state == ZOMBIE){
    80002dda:	589c                	lw	a5,48(s1)
    80002ddc:	f94781e3          	beq	a5,s4,80002d5e <wait+0x56>
        release(&np->lock);
    80002de0:	8526                	mv	a0,s1
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	ec4080e7          	jalr	-316(ra) # 80000ca6 <release>
        havekids = 1;
    80002dea:	8756                	mv	a4,s5
    80002dec:	bfd9                	j	80002dc2 <wait+0xba>
    if(!havekids || p->killed){
    80002dee:	c701                	beqz	a4,80002df6 <wait+0xee>
    80002df0:	04092783          	lw	a5,64(s2)
    80002df4:	c79d                	beqz	a5,80002e22 <wait+0x11a>
      release(&wait_lock);
    80002df6:	0000e517          	auipc	a0,0xe
    80002dfa:	7d250513          	addi	a0,a0,2002 # 800115c8 <wait_lock>
    80002dfe:	ffffe097          	auipc	ra,0xffffe
    80002e02:	ea8080e7          	jalr	-344(ra) # 80000ca6 <release>
      return -1;
    80002e06:	59fd                	li	s3,-1
}
    80002e08:	854e                	mv	a0,s3
    80002e0a:	60a6                	ld	ra,72(sp)
    80002e0c:	6406                	ld	s0,64(sp)
    80002e0e:	74e2                	ld	s1,56(sp)
    80002e10:	7942                	ld	s2,48(sp)
    80002e12:	79a2                	ld	s3,40(sp)
    80002e14:	7a02                	ld	s4,32(sp)
    80002e16:	6ae2                	ld	s5,24(sp)
    80002e18:	6b42                	ld	s6,16(sp)
    80002e1a:	6ba2                	ld	s7,8(sp)
    80002e1c:	6c02                	ld	s8,0(sp)
    80002e1e:	6161                	addi	sp,sp,80
    80002e20:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002e22:	85e2                	mv	a1,s8
    80002e24:	854a                	mv	a0,s2
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	e64080e7          	jalr	-412(ra) # 80002c8a <sleep>
    havekids = 0;
    80002e2e:	b715                	j	80002d52 <wait+0x4a>

0000000080002e30 <wakeup>:
// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
//--------------------------------------------------------------------
void
wakeup(void *chan)
{
    80002e30:	711d                	addi	sp,sp,-96
    80002e32:	ec86                	sd	ra,88(sp)
    80002e34:	e8a2                	sd	s0,80(sp)
    80002e36:	e4a6                	sd	s1,72(sp)
    80002e38:	e0ca                	sd	s2,64(sp)
    80002e3a:	fc4e                	sd	s3,56(sp)
    80002e3c:	f852                	sd	s4,48(sp)
    80002e3e:	f456                	sd	s5,40(sp)
    80002e40:	f05a                	sd	s6,32(sp)
    80002e42:	ec5e                	sd	s7,24(sp)
    80002e44:	e862                	sd	s8,16(sp)
    80002e46:	e466                	sd	s9,8(sp)
    80002e48:	e06a                	sd	s10,0(sp)
    80002e4a:	1080                	addi	s0,sp,96
    80002e4c:	8aaa                	mv	s5,a0
  int released_list = 0;
  struct proc *p;
  struct proc* prev = 0;
  struct proc* tmp;
  getList(sleepLeast, -1);
    80002e4e:	55fd                	li	a1,-1
    80002e50:	4509                	li	a0,2
    80002e52:	fffff097          	auipc	ra,0xfffff
    80002e56:	388080e7          	jalr	904(ra) # 800021da <getList>
  p = getFirst(sleepLeast, -1);
    80002e5a:	55fd                	li	a1,-1
    80002e5c:	4509                	li	a0,2
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	d32080e7          	jalr	-718(ra) # 80001b90 <getFirst>
    80002e66:	84aa                	mv	s1,a0
  while(p){
    80002e68:	14050663          	beqz	a0,80002fb4 <wakeup+0x184>
  struct proc* prev = 0;
    80002e6c:	4a01                	li	s4,0
  int released_list = 0;
    80002e6e:	4c01                	li	s8,0
    } 
    else{
      //we are not on the chan
      if(p == getFirst(sleepLeast, -1)){
        release_list(sleepLeast,-1);
        released_list = 1;
    80002e70:	4b85                	li	s7,1
        p->state = RUNNABLE;
    80002e72:	4c8d                	li	s9,3
    80002e74:	a8c9                	j	80002f46 <wakeup+0x116>
      if(p == getFirst(sleepLeast, -1)){
    80002e76:	55fd                	li	a1,-1
    80002e78:	4509                	li	a0,2
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	d16080e7          	jalr	-746(ra) # 80001b90 <getFirst>
    80002e82:	04a48863          	beq	s1,a0,80002ed2 <wakeup+0xa2>
        prev->next = p->next;
    80002e86:	68bc                	ld	a5,80(s1)
    80002e88:	04fa3823          	sd	a5,80(s4)
        p->next = 0;
    80002e8c:	0404b823          	sd	zero,80(s1)
        p->state = RUNNABLE;
    80002e90:	0394a823          	sw	s9,48(s1)
        int cpu_id = (BLNCFLG) ? pick_cpu() : p->parent_cpu;
    80002e94:	fffff097          	auipc	ra,0xfffff
    80002e98:	c78080e7          	jalr	-904(ra) # 80001b0c <pick_cpu>
    80002e9c:	8b2a                	mv	s6,a0
        p->parent_cpu = cpu_id;
    80002e9e:	cca8                	sw	a0,88(s1)
        cahnge_number_of_proc(cpu_id,a);
    80002ea0:	85de                	mv	a1,s7
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	c9e080e7          	jalr	-866(ra) # 80001b40 <cahnge_number_of_proc>
        add_proc_to_list(p, readyList, cpu_id);
    80002eaa:	865a                	mv	a2,s6
    80002eac:	4581                	li	a1,0
    80002eae:	8526                	mv	a0,s1
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	5b4080e7          	jalr	1460(ra) # 80002464 <add_proc_to_list>
        release(&p->list_lock);
    80002eb8:	854a                	mv	a0,s2
    80002eba:	ffffe097          	auipc	ra,0xffffe
    80002ebe:	dec080e7          	jalr	-532(ra) # 80000ca6 <release>
        release(&p->lock);
    80002ec2:	8526                	mv	a0,s1
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	de2080e7          	jalr	-542(ra) # 80000ca6 <release>
        p = prev->next;
    80002ecc:	050a3483          	ld	s1,80(s4)
    80002ed0:	a895                	j	80002f44 <wakeup+0x114>
        setFirst(p->next, sleepLeast, -1);
    80002ed2:	567d                	li	a2,-1
    80002ed4:	4589                	li	a1,2
    80002ed6:	68a8                	ld	a0,80(s1)
    80002ed8:	fffff097          	auipc	ra,0xfffff
    80002edc:	402080e7          	jalr	1026(ra) # 800022da <setFirst>
        p = p->next;
    80002ee0:	0504bd03          	ld	s10,80(s1)
        tmp->next = 0;
    80002ee4:	0404b823          	sd	zero,80(s1)
        tmp->state = RUNNABLE;
    80002ee8:	0394a823          	sw	s9,48(s1)
        int cpu_id = (BLNCFLG) ? pick_cpu() : tmp->parent_cpu;
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	c20080e7          	jalr	-992(ra) # 80001b0c <pick_cpu>
    80002ef4:	8b2a                	mv	s6,a0
        tmp->parent_cpu = cpu_id;
    80002ef6:	cca8                	sw	a0,88(s1)
        cahnge_number_of_proc(cpu_id,a);
    80002ef8:	85de                	mv	a1,s7
    80002efa:	fffff097          	auipc	ra,0xfffff
    80002efe:	c46080e7          	jalr	-954(ra) # 80001b40 <cahnge_number_of_proc>
        add_proc_to_list(tmp, readyList, cpu_id);
    80002f02:	865a                	mv	a2,s6
    80002f04:	4581                	li	a1,0
    80002f06:	8526                	mv	a0,s1
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	55c080e7          	jalr	1372(ra) # 80002464 <add_proc_to_list>
        release(&tmp->list_lock);
    80002f10:	854a                	mv	a0,s2
    80002f12:	ffffe097          	auipc	ra,0xffffe
    80002f16:	d94080e7          	jalr	-620(ra) # 80000ca6 <release>
        release(&tmp->lock);
    80002f1a:	8526                	mv	a0,s1
    80002f1c:	ffffe097          	auipc	ra,0xffffe
    80002f20:	d8a080e7          	jalr	-630(ra) # 80000ca6 <release>
        p = p->next;
    80002f24:	84ea                	mv	s1,s10
    80002f26:	a839                	j	80002f44 <wakeup+0x114>
        release_list(sleepLeast,-1);
    80002f28:	55fd                	li	a1,-1
    80002f2a:	4509                	li	a0,2
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	d92080e7          	jalr	-622(ra) # 80001cbe <release_list>
        released_list = 1;
    80002f34:	8c5e                	mv	s8,s7
      }
      else{
        release(&prev->list_lock);
      }
      release(&p->lock);  //because we dont need to change his fields
    80002f36:	854e                	mv	a0,s3
    80002f38:	ffffe097          	auipc	ra,0xffffe
    80002f3c:	d6e080e7          	jalr	-658(ra) # 80000ca6 <release>
      prev = p;
      p = p->next;
    80002f40:	8a26                	mv	s4,s1
    80002f42:	68a4                	ld	s1,80(s1)
  while(p){
    80002f44:	c0a1                	beqz	s1,80002f84 <wakeup+0x154>
    acquire(&p->lock);
    80002f46:	89a6                	mv	s3,s1
    80002f48:	8526                	mv	a0,s1
    80002f4a:	ffffe097          	auipc	ra,0xffffe
    80002f4e:	ca2080e7          	jalr	-862(ra) # 80000bec <acquire>
    acquire(&p->list_lock);
    80002f52:	01848913          	addi	s2,s1,24
    80002f56:	854a                	mv	a0,s2
    80002f58:	ffffe097          	auipc	ra,0xffffe
    80002f5c:	c94080e7          	jalr	-876(ra) # 80000bec <acquire>
    if(p->chan == chan){
    80002f60:	7c9c                	ld	a5,56(s1)
    80002f62:	f1578ae3          	beq	a5,s5,80002e76 <wakeup+0x46>
      if(p == getFirst(sleepLeast, -1)){
    80002f66:	55fd                	li	a1,-1
    80002f68:	4509                	li	a0,2
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	c26080e7          	jalr	-986(ra) # 80001b90 <getFirst>
    80002f72:	faa48be3          	beq	s1,a0,80002f28 <wakeup+0xf8>
        release(&prev->list_lock);
    80002f76:	018a0513          	addi	a0,s4,24
    80002f7a:	ffffe097          	auipc	ra,0xffffe
    80002f7e:	d2c080e7          	jalr	-724(ra) # 80000ca6 <release>
    80002f82:	bf55                	j	80002f36 <wakeup+0x106>
    }
  }
  if(!released_list){
    80002f84:	020c0963          	beqz	s8,80002fb6 <wakeup+0x186>
    release_list(sleepLeast, -1);
  }
  if(prev){
    80002f88:	000a0863          	beqz	s4,80002f98 <wakeup+0x168>
    release(&prev->list_lock);
    80002f8c:	018a0513          	addi	a0,s4,24
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	d16080e7          	jalr	-746(ra) # 80000ca6 <release>
  }
}
    80002f98:	60e6                	ld	ra,88(sp)
    80002f9a:	6446                	ld	s0,80(sp)
    80002f9c:	64a6                	ld	s1,72(sp)
    80002f9e:	6906                	ld	s2,64(sp)
    80002fa0:	79e2                	ld	s3,56(sp)
    80002fa2:	7a42                	ld	s4,48(sp)
    80002fa4:	7aa2                	ld	s5,40(sp)
    80002fa6:	7b02                	ld	s6,32(sp)
    80002fa8:	6be2                	ld	s7,24(sp)
    80002faa:	6c42                	ld	s8,16(sp)
    80002fac:	6ca2                	ld	s9,8(sp)
    80002fae:	6d02                	ld	s10,0(sp)
    80002fb0:	6125                	addi	sp,sp,96
    80002fb2:	8082                	ret
  struct proc* prev = 0;
    80002fb4:	8a2a                	mv	s4,a0
    release_list(sleepLeast, -1);
    80002fb6:	55fd                	li	a1,-1
    80002fb8:	4509                	li	a0,2
    80002fba:	fffff097          	auipc	ra,0xfffff
    80002fbe:	d04080e7          	jalr	-764(ra) # 80001cbe <release_list>
    80002fc2:	b7d9                	j	80002f88 <wakeup+0x158>

0000000080002fc4 <reparent>:
{
    80002fc4:	7179                	addi	sp,sp,-48
    80002fc6:	f406                	sd	ra,40(sp)
    80002fc8:	f022                	sd	s0,32(sp)
    80002fca:	ec26                	sd	s1,24(sp)
    80002fcc:	e84a                	sd	s2,16(sp)
    80002fce:	e44e                	sd	s3,8(sp)
    80002fd0:	e052                	sd	s4,0(sp)
    80002fd2:	1800                	addi	s0,sp,48
    80002fd4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002fd6:	0000e497          	auipc	s1,0xe
    80002fda:	60a48493          	addi	s1,s1,1546 # 800115e0 <proc>
      pp->parent = initproc;
    80002fde:	00006a17          	auipc	s4,0x6
    80002fe2:	082a0a13          	addi	s4,s4,130 # 80009060 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002fe6:	00015997          	auipc	s3,0x15
    80002fea:	9fa98993          	addi	s3,s3,-1542 # 800179e0 <tickslock>
    80002fee:	a029                	j	80002ff8 <reparent+0x34>
    80002ff0:	19048493          	addi	s1,s1,400
    80002ff4:	01348d63          	beq	s1,s3,8000300e <reparent+0x4a>
    if(pp->parent == p){
    80002ff8:	70bc                	ld	a5,96(s1)
    80002ffa:	ff279be3          	bne	a5,s2,80002ff0 <reparent+0x2c>
      pp->parent = initproc;
    80002ffe:	000a3503          	ld	a0,0(s4)
    80003002:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80003004:	00000097          	auipc	ra,0x0
    80003008:	e2c080e7          	jalr	-468(ra) # 80002e30 <wakeup>
    8000300c:	b7d5                	j	80002ff0 <reparent+0x2c>
}
    8000300e:	70a2                	ld	ra,40(sp)
    80003010:	7402                	ld	s0,32(sp)
    80003012:	64e2                	ld	s1,24(sp)
    80003014:	6942                	ld	s2,16(sp)
    80003016:	69a2                	ld	s3,8(sp)
    80003018:	6a02                	ld	s4,0(sp)
    8000301a:	6145                	addi	sp,sp,48
    8000301c:	8082                	ret

000000008000301e <exit>:
{
    8000301e:	7179                	addi	sp,sp,-48
    80003020:	f406                	sd	ra,40(sp)
    80003022:	f022                	sd	s0,32(sp)
    80003024:	ec26                	sd	s1,24(sp)
    80003026:	e84a                	sd	s2,16(sp)
    80003028:	e44e                	sd	s3,8(sp)
    8000302a:	e052                	sd	s4,0(sp)
    8000302c:	1800                	addi	s0,sp,48
    8000302e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	ddc080e7          	jalr	-548(ra) # 80001e0c <myproc>
    80003038:	89aa                	mv	s3,a0
  if(p == initproc)
    8000303a:	00006797          	auipc	a5,0x6
    8000303e:	0267b783          	ld	a5,38(a5) # 80009060 <initproc>
    80003042:	0f850493          	addi	s1,a0,248
    80003046:	17850913          	addi	s2,a0,376
    8000304a:	02a79363          	bne	a5,a0,80003070 <exit+0x52>
    panic("init exiting");
    8000304e:	00005517          	auipc	a0,0x5
    80003052:	3a250513          	addi	a0,a0,930 # 800083f0 <digits+0x3b0>
    80003056:	ffffd097          	auipc	ra,0xffffd
    8000305a:	4e8080e7          	jalr	1256(ra) # 8000053e <panic>
      fileclose(f);
    8000305e:	00002097          	auipc	ra,0x2
    80003062:	1f0080e7          	jalr	496(ra) # 8000524e <fileclose>
      p->ofile[fd] = 0;
    80003066:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000306a:	04a1                	addi	s1,s1,8
    8000306c:	01248563          	beq	s1,s2,80003076 <exit+0x58>
    if(p->ofile[fd]){
    80003070:	6088                	ld	a0,0(s1)
    80003072:	f575                	bnez	a0,8000305e <exit+0x40>
    80003074:	bfdd                	j	8000306a <exit+0x4c>
  begin_op();
    80003076:	00002097          	auipc	ra,0x2
    8000307a:	d0c080e7          	jalr	-756(ra) # 80004d82 <begin_op>
  iput(p->cwd);
    8000307e:	1789b503          	ld	a0,376(s3)
    80003082:	00001097          	auipc	ra,0x1
    80003086:	4e8080e7          	jalr	1256(ra) # 8000456a <iput>
  end_op();
    8000308a:	00002097          	auipc	ra,0x2
    8000308e:	d78080e7          	jalr	-648(ra) # 80004e02 <end_op>
  p->cwd = 0;
    80003092:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    80003096:	0000e497          	auipc	s1,0xe
    8000309a:	53248493          	addi	s1,s1,1330 # 800115c8 <wait_lock>
    8000309e:	8526                	mv	a0,s1
    800030a0:	ffffe097          	auipc	ra,0xffffe
    800030a4:	b4c080e7          	jalr	-1204(ra) # 80000bec <acquire>
  reparent(p);
    800030a8:	854e                	mv	a0,s3
    800030aa:	00000097          	auipc	ra,0x0
    800030ae:	f1a080e7          	jalr	-230(ra) # 80002fc4 <reparent>
  wakeup(p->parent);
    800030b2:	0609b503          	ld	a0,96(s3)
    800030b6:	00000097          	auipc	ra,0x0
    800030ba:	d7a080e7          	jalr	-646(ra) # 80002e30 <wakeup>
  acquire(&p->lock);
    800030be:	854e                	mv	a0,s3
    800030c0:	ffffe097          	auipc	ra,0xffffe
    800030c4:	b2c080e7          	jalr	-1236(ra) # 80000bec <acquire>
  p->xstate = status;
    800030c8:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    800030cc:	4795                	li	a5,5
    800030ce:	02f9a823          	sw	a5,48(s3)
  cahnge_number_of_proc(p->parent_cpu,b);
    800030d2:	55fd                	li	a1,-1
    800030d4:	0589a503          	lw	a0,88(s3)
    800030d8:	fffff097          	auipc	ra,0xfffff
    800030dc:	a68080e7          	jalr	-1432(ra) # 80001b40 <cahnge_number_of_proc>
  add_proc_to_list(p, zombeList, -1);
    800030e0:	567d                	li	a2,-1
    800030e2:	4585                	li	a1,1
    800030e4:	854e                	mv	a0,s3
    800030e6:	fffff097          	auipc	ra,0xfffff
    800030ea:	37e080e7          	jalr	894(ra) # 80002464 <add_proc_to_list>
  release(&wait_lock);
    800030ee:	8526                	mv	a0,s1
    800030f0:	ffffe097          	auipc	ra,0xffffe
    800030f4:	bb6080e7          	jalr	-1098(ra) # 80000ca6 <release>
  sched();
    800030f8:	fffff097          	auipc	ra,0xfffff
    800030fc:	f4e080e7          	jalr	-178(ra) # 80002046 <sched>
  panic("zombie exit");
    80003100:	00005517          	auipc	a0,0x5
    80003104:	30050513          	addi	a0,a0,768 # 80008400 <digits+0x3c0>
    80003108:	ffffd097          	auipc	ra,0xffffd
    8000310c:	436080e7          	jalr	1078(ra) # 8000053e <panic>

0000000080003110 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80003110:	7179                	addi	sp,sp,-48
    80003112:	f406                	sd	ra,40(sp)
    80003114:	f022                	sd	s0,32(sp)
    80003116:	ec26                	sd	s1,24(sp)
    80003118:	e84a                	sd	s2,16(sp)
    8000311a:	e44e                	sd	s3,8(sp)
    8000311c:	1800                	addi	s0,sp,48
    8000311e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80003120:	0000e497          	auipc	s1,0xe
    80003124:	4c048493          	addi	s1,s1,1216 # 800115e0 <proc>
    80003128:	00015997          	auipc	s3,0x15
    8000312c:	8b898993          	addi	s3,s3,-1864 # 800179e0 <tickslock>
    acquire(&p->lock);
    80003130:	8526                	mv	a0,s1
    80003132:	ffffe097          	auipc	ra,0xffffe
    80003136:	aba080e7          	jalr	-1350(ra) # 80000bec <acquire>
    if(p->pid == pid){
    8000313a:	44bc                	lw	a5,72(s1)
    8000313c:	01278d63          	beq	a5,s2,80003156 <kill+0x46>
        cahnge_number_of_proc(p->parent_cpu,a);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80003140:	8526                	mv	a0,s1
    80003142:	ffffe097          	auipc	ra,0xffffe
    80003146:	b64080e7          	jalr	-1180(ra) # 80000ca6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000314a:	19048493          	addi	s1,s1,400
    8000314e:	ff3491e3          	bne	s1,s3,80003130 <kill+0x20>
  }
  return -1;
    80003152:	557d                	li	a0,-1
    80003154:	a829                	j	8000316e <kill+0x5e>
      p->killed = 1;
    80003156:	4785                	li	a5,1
    80003158:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    8000315a:	5898                	lw	a4,48(s1)
    8000315c:	4789                	li	a5,2
    8000315e:	00f70f63          	beq	a4,a5,8000317c <kill+0x6c>
      release(&p->lock);
    80003162:	8526                	mv	a0,s1
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b42080e7          	jalr	-1214(ra) # 80000ca6 <release>
      return 0;
    8000316c:	4501                	li	a0,0
}
    8000316e:	70a2                	ld	ra,40(sp)
    80003170:	7402                	ld	s0,32(sp)
    80003172:	64e2                	ld	s1,24(sp)
    80003174:	6942                	ld	s2,16(sp)
    80003176:	69a2                	ld	s3,8(sp)
    80003178:	6145                	addi	sp,sp,48
    8000317a:	8082                	ret
        p->state = RUNNABLE;
    8000317c:	478d                	li	a5,3
    8000317e:	d89c                	sw	a5,48(s1)
        remove_proc(p, sleepLeast);
    80003180:	4589                	li	a1,2
    80003182:	8526                	mv	a0,s1
    80003184:	fffff097          	auipc	ra,0xfffff
    80003188:	6a8080e7          	jalr	1704(ra) # 8000282c <remove_proc>
        add_proc_to_list(p, readyList, p->parent_cpu);
    8000318c:	4cb0                	lw	a2,88(s1)
    8000318e:	4581                	li	a1,0
    80003190:	8526                	mv	a0,s1
    80003192:	fffff097          	auipc	ra,0xfffff
    80003196:	2d2080e7          	jalr	722(ra) # 80002464 <add_proc_to_list>
        cahnge_number_of_proc(p->parent_cpu,a);
    8000319a:	4585                	li	a1,1
    8000319c:	4ca8                	lw	a0,88(s1)
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	9a2080e7          	jalr	-1630(ra) # 80001b40 <cahnge_number_of_proc>
    800031a6:	bf75                	j	80003162 <kill+0x52>

00000000800031a8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800031a8:	7179                	addi	sp,sp,-48
    800031aa:	f406                	sd	ra,40(sp)
    800031ac:	f022                	sd	s0,32(sp)
    800031ae:	ec26                	sd	s1,24(sp)
    800031b0:	e84a                	sd	s2,16(sp)
    800031b2:	e44e                	sd	s3,8(sp)
    800031b4:	e052                	sd	s4,0(sp)
    800031b6:	1800                	addi	s0,sp,48
    800031b8:	84aa                	mv	s1,a0
    800031ba:	892e                	mv	s2,a1
    800031bc:	89b2                	mv	s3,a2
    800031be:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800031c0:	fffff097          	auipc	ra,0xfffff
    800031c4:	c4c080e7          	jalr	-948(ra) # 80001e0c <myproc>
  if(user_dst){
    800031c8:	c08d                	beqz	s1,800031ea <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800031ca:	86d2                	mv	a3,s4
    800031cc:	864e                	mv	a2,s3
    800031ce:	85ca                	mv	a1,s2
    800031d0:	7d28                	ld	a0,120(a0)
    800031d2:	ffffe097          	auipc	ra,0xffffe
    800031d6:	4ae080e7          	jalr	1198(ra) # 80001680 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800031da:	70a2                	ld	ra,40(sp)
    800031dc:	7402                	ld	s0,32(sp)
    800031de:	64e2                	ld	s1,24(sp)
    800031e0:	6942                	ld	s2,16(sp)
    800031e2:	69a2                	ld	s3,8(sp)
    800031e4:	6a02                	ld	s4,0(sp)
    800031e6:	6145                	addi	sp,sp,48
    800031e8:	8082                	ret
    memmove((char *)dst, src, len);
    800031ea:	000a061b          	sext.w	a2,s4
    800031ee:	85ce                	mv	a1,s3
    800031f0:	854a                	mv	a0,s2
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	b5c080e7          	jalr	-1188(ra) # 80000d4e <memmove>
    return 0;
    800031fa:	8526                	mv	a0,s1
    800031fc:	bff9                	j	800031da <either_copyout+0x32>

00000000800031fe <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800031fe:	7179                	addi	sp,sp,-48
    80003200:	f406                	sd	ra,40(sp)
    80003202:	f022                	sd	s0,32(sp)
    80003204:	ec26                	sd	s1,24(sp)
    80003206:	e84a                	sd	s2,16(sp)
    80003208:	e44e                	sd	s3,8(sp)
    8000320a:	e052                	sd	s4,0(sp)
    8000320c:	1800                	addi	s0,sp,48
    8000320e:	892a                	mv	s2,a0
    80003210:	84ae                	mv	s1,a1
    80003212:	89b2                	mv	s3,a2
    80003214:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003216:	fffff097          	auipc	ra,0xfffff
    8000321a:	bf6080e7          	jalr	-1034(ra) # 80001e0c <myproc>
  if(user_src){
    8000321e:	c08d                	beqz	s1,80003240 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80003220:	86d2                	mv	a3,s4
    80003222:	864e                	mv	a2,s3
    80003224:	85ca                	mv	a1,s2
    80003226:	7d28                	ld	a0,120(a0)
    80003228:	ffffe097          	auipc	ra,0xffffe
    8000322c:	4e4080e7          	jalr	1252(ra) # 8000170c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80003230:	70a2                	ld	ra,40(sp)
    80003232:	7402                	ld	s0,32(sp)
    80003234:	64e2                	ld	s1,24(sp)
    80003236:	6942                	ld	s2,16(sp)
    80003238:	69a2                	ld	s3,8(sp)
    8000323a:	6a02                	ld	s4,0(sp)
    8000323c:	6145                	addi	sp,sp,48
    8000323e:	8082                	ret
    memmove(dst, (char*)src, len);
    80003240:	000a061b          	sext.w	a2,s4
    80003244:	85ce                	mv	a1,s3
    80003246:	854a                	mv	a0,s2
    80003248:	ffffe097          	auipc	ra,0xffffe
    8000324c:	b06080e7          	jalr	-1274(ra) # 80000d4e <memmove>
    return 0;
    80003250:	8526                	mv	a0,s1
    80003252:	bff9                	j	80003230 <either_copyin+0x32>

0000000080003254 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80003254:	715d                	addi	sp,sp,-80
    80003256:	e486                	sd	ra,72(sp)
    80003258:	e0a2                	sd	s0,64(sp)
    8000325a:	fc26                	sd	s1,56(sp)
    8000325c:	f84a                	sd	s2,48(sp)
    8000325e:	f44e                	sd	s3,40(sp)
    80003260:	f052                	sd	s4,32(sp)
    80003262:	ec56                	sd	s5,24(sp)
    80003264:	e85a                	sd	s6,16(sp)
    80003266:	e45e                	sd	s7,8(sp)
    80003268:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000326a:	00005517          	auipc	a0,0x5
    8000326e:	e5e50513          	addi	a0,a0,-418 # 800080c8 <digits+0x88>
    80003272:	ffffd097          	auipc	ra,0xffffd
    80003276:	316080e7          	jalr	790(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000327a:	0000e497          	auipc	s1,0xe
    8000327e:	4e648493          	addi	s1,s1,1254 # 80011760 <proc+0x180>
    80003282:	00015917          	auipc	s2,0x15
    80003286:	8de90913          	addi	s2,s2,-1826 # 80017b60 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000328a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000328c:	00005997          	auipc	s3,0x5
    80003290:	18498993          	addi	s3,s3,388 # 80008410 <digits+0x3d0>
    printf("%d %s %s", p->pid, state, p->name);
    80003294:	00005a97          	auipc	s5,0x5
    80003298:	184a8a93          	addi	s5,s5,388 # 80008418 <digits+0x3d8>
    printf("\n");
    8000329c:	00005a17          	auipc	s4,0x5
    800032a0:	e2ca0a13          	addi	s4,s4,-468 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800032a4:	00005b97          	auipc	s7,0x5
    800032a8:	1acb8b93          	addi	s7,s7,428 # 80008450 <states.1894>
    800032ac:	a00d                	j	800032ce <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800032ae:	ec86a583          	lw	a1,-312(a3)
    800032b2:	8556                	mv	a0,s5
    800032b4:	ffffd097          	auipc	ra,0xffffd
    800032b8:	2d4080e7          	jalr	724(ra) # 80000588 <printf>
    printf("\n");
    800032bc:	8552                	mv	a0,s4
    800032be:	ffffd097          	auipc	ra,0xffffd
    800032c2:	2ca080e7          	jalr	714(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800032c6:	19048493          	addi	s1,s1,400
    800032ca:	03248163          	beq	s1,s2,800032ec <procdump+0x98>
    if(p->state == UNUSED)
    800032ce:	86a6                	mv	a3,s1
    800032d0:	eb04a783          	lw	a5,-336(s1)
    800032d4:	dbed                	beqz	a5,800032c6 <procdump+0x72>
      state = "???";
    800032d6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800032d8:	fcfb6be3          	bltu	s6,a5,800032ae <procdump+0x5a>
    800032dc:	1782                	slli	a5,a5,0x20
    800032de:	9381                	srli	a5,a5,0x20
    800032e0:	078e                	slli	a5,a5,0x3
    800032e2:	97de                	add	a5,a5,s7
    800032e4:	6390                	ld	a2,0(a5)
    800032e6:	f661                	bnez	a2,800032ae <procdump+0x5a>
      state = "???";
    800032e8:	864e                	mv	a2,s3
    800032ea:	b7d1                	j	800032ae <procdump+0x5a>
  }
}
    800032ec:	60a6                	ld	ra,72(sp)
    800032ee:	6406                	ld	s0,64(sp)
    800032f0:	74e2                	ld	s1,56(sp)
    800032f2:	7942                	ld	s2,48(sp)
    800032f4:	79a2                	ld	s3,40(sp)
    800032f6:	7a02                	ld	s4,32(sp)
    800032f8:	6ae2                	ld	s5,24(sp)
    800032fa:	6b42                	ld	s6,16(sp)
    800032fc:	6ba2                	ld	s7,8(sp)
    800032fe:	6161                	addi	sp,sp,80
    80003300:	8082                	ret

0000000080003302 <swtch>:
    80003302:	00153023          	sd	ra,0(a0)
    80003306:	00253423          	sd	sp,8(a0)
    8000330a:	e900                	sd	s0,16(a0)
    8000330c:	ed04                	sd	s1,24(a0)
    8000330e:	03253023          	sd	s2,32(a0)
    80003312:	03353423          	sd	s3,40(a0)
    80003316:	03453823          	sd	s4,48(a0)
    8000331a:	03553c23          	sd	s5,56(a0)
    8000331e:	05653023          	sd	s6,64(a0)
    80003322:	05753423          	sd	s7,72(a0)
    80003326:	05853823          	sd	s8,80(a0)
    8000332a:	05953c23          	sd	s9,88(a0)
    8000332e:	07a53023          	sd	s10,96(a0)
    80003332:	07b53423          	sd	s11,104(a0)
    80003336:	0005b083          	ld	ra,0(a1)
    8000333a:	0085b103          	ld	sp,8(a1)
    8000333e:	6980                	ld	s0,16(a1)
    80003340:	6d84                	ld	s1,24(a1)
    80003342:	0205b903          	ld	s2,32(a1)
    80003346:	0285b983          	ld	s3,40(a1)
    8000334a:	0305ba03          	ld	s4,48(a1)
    8000334e:	0385ba83          	ld	s5,56(a1)
    80003352:	0405bb03          	ld	s6,64(a1)
    80003356:	0485bb83          	ld	s7,72(a1)
    8000335a:	0505bc03          	ld	s8,80(a1)
    8000335e:	0585bc83          	ld	s9,88(a1)
    80003362:	0605bd03          	ld	s10,96(a1)
    80003366:	0685bd83          	ld	s11,104(a1)
    8000336a:	8082                	ret

000000008000336c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000336c:	1141                	addi	sp,sp,-16
    8000336e:	e406                	sd	ra,8(sp)
    80003370:	e022                	sd	s0,0(sp)
    80003372:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003374:	00005597          	auipc	a1,0x5
    80003378:	10c58593          	addi	a1,a1,268 # 80008480 <states.1894+0x30>
    8000337c:	00014517          	auipc	a0,0x14
    80003380:	66450513          	addi	a0,a0,1636 # 800179e0 <tickslock>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	7d0080e7          	jalr	2000(ra) # 80000b54 <initlock>
}
    8000338c:	60a2                	ld	ra,8(sp)
    8000338e:	6402                	ld	s0,0(sp)
    80003390:	0141                	addi	sp,sp,16
    80003392:	8082                	ret

0000000080003394 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003394:	1141                	addi	sp,sp,-16
    80003396:	e422                	sd	s0,8(sp)
    80003398:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000339a:	00003797          	auipc	a5,0x3
    8000339e:	4d678793          	addi	a5,a5,1238 # 80006870 <kernelvec>
    800033a2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800033a6:	6422                	ld	s0,8(sp)
    800033a8:	0141                	addi	sp,sp,16
    800033aa:	8082                	ret

00000000800033ac <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800033ac:	1141                	addi	sp,sp,-16
    800033ae:	e406                	sd	ra,8(sp)
    800033b0:	e022                	sd	s0,0(sp)
    800033b2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800033b4:	fffff097          	auipc	ra,0xfffff
    800033b8:	a58080e7          	jalr	-1448(ra) # 80001e0c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800033c0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800033c2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800033c6:	00004617          	auipc	a2,0x4
    800033ca:	c3a60613          	addi	a2,a2,-966 # 80007000 <_trampoline>
    800033ce:	00004697          	auipc	a3,0x4
    800033d2:	c3268693          	addi	a3,a3,-974 # 80007000 <_trampoline>
    800033d6:	8e91                	sub	a3,a3,a2
    800033d8:	040007b7          	lui	a5,0x4000
    800033dc:	17fd                	addi	a5,a5,-1
    800033de:	07b2                	slli	a5,a5,0xc
    800033e0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800033e2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800033e6:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800033e8:	180026f3          	csrr	a3,satp
    800033ec:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800033ee:	6158                	ld	a4,128(a0)
    800033f0:	7534                	ld	a3,104(a0)
    800033f2:	6585                	lui	a1,0x1
    800033f4:	96ae                	add	a3,a3,a1
    800033f6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800033f8:	6158                	ld	a4,128(a0)
    800033fa:	00000697          	auipc	a3,0x0
    800033fe:	13868693          	addi	a3,a3,312 # 80003532 <usertrap>
    80003402:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003404:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003406:	8692                	mv	a3,tp
    80003408:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000340a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000340e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003412:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003416:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000341a:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000341c:	6f18                	ld	a4,24(a4)
    8000341e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003422:	7d2c                	ld	a1,120(a0)
    80003424:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003426:	00004717          	auipc	a4,0x4
    8000342a:	c6a70713          	addi	a4,a4,-918 # 80007090 <userret>
    8000342e:	8f11                	sub	a4,a4,a2
    80003430:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003432:	577d                	li	a4,-1
    80003434:	177e                	slli	a4,a4,0x3f
    80003436:	8dd9                	or	a1,a1,a4
    80003438:	02000537          	lui	a0,0x2000
    8000343c:	157d                	addi	a0,a0,-1
    8000343e:	0536                	slli	a0,a0,0xd
    80003440:	9782                	jalr	a5
}
    80003442:	60a2                	ld	ra,8(sp)
    80003444:	6402                	ld	s0,0(sp)
    80003446:	0141                	addi	sp,sp,16
    80003448:	8082                	ret

000000008000344a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000344a:	1101                	addi	sp,sp,-32
    8000344c:	ec06                	sd	ra,24(sp)
    8000344e:	e822                	sd	s0,16(sp)
    80003450:	e426                	sd	s1,8(sp)
    80003452:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003454:	00014497          	auipc	s1,0x14
    80003458:	58c48493          	addi	s1,s1,1420 # 800179e0 <tickslock>
    8000345c:	8526                	mv	a0,s1
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	78e080e7          	jalr	1934(ra) # 80000bec <acquire>
  ticks++;
    80003466:	00006517          	auipc	a0,0x6
    8000346a:	c0a50513          	addi	a0,a0,-1014 # 80009070 <ticks>
    8000346e:	411c                	lw	a5,0(a0)
    80003470:	2785                	addiw	a5,a5,1
    80003472:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003474:	00000097          	auipc	ra,0x0
    80003478:	9bc080e7          	jalr	-1604(ra) # 80002e30 <wakeup>
  release(&tickslock);
    8000347c:	8526                	mv	a0,s1
    8000347e:	ffffe097          	auipc	ra,0xffffe
    80003482:	828080e7          	jalr	-2008(ra) # 80000ca6 <release>
}
    80003486:	60e2                	ld	ra,24(sp)
    80003488:	6442                	ld	s0,16(sp)
    8000348a:	64a2                	ld	s1,8(sp)
    8000348c:	6105                	addi	sp,sp,32
    8000348e:	8082                	ret

0000000080003490 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003490:	1101                	addi	sp,sp,-32
    80003492:	ec06                	sd	ra,24(sp)
    80003494:	e822                	sd	s0,16(sp)
    80003496:	e426                	sd	s1,8(sp)
    80003498:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000349a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000349e:	00074d63          	bltz	a4,800034b8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800034a2:	57fd                	li	a5,-1
    800034a4:	17fe                	slli	a5,a5,0x3f
    800034a6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800034a8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800034aa:	06f70363          	beq	a4,a5,80003510 <devintr+0x80>
  }
}
    800034ae:	60e2                	ld	ra,24(sp)
    800034b0:	6442                	ld	s0,16(sp)
    800034b2:	64a2                	ld	s1,8(sp)
    800034b4:	6105                	addi	sp,sp,32
    800034b6:	8082                	ret
     (scause & 0xff) == 9){
    800034b8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800034bc:	46a5                	li	a3,9
    800034be:	fed792e3          	bne	a5,a3,800034a2 <devintr+0x12>
    int irq = plic_claim();
    800034c2:	00003097          	auipc	ra,0x3
    800034c6:	4b6080e7          	jalr	1206(ra) # 80006978 <plic_claim>
    800034ca:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800034cc:	47a9                	li	a5,10
    800034ce:	02f50763          	beq	a0,a5,800034fc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800034d2:	4785                	li	a5,1
    800034d4:	02f50963          	beq	a0,a5,80003506 <devintr+0x76>
    return 1;
    800034d8:	4505                	li	a0,1
    } else if(irq){
    800034da:	d8f1                	beqz	s1,800034ae <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800034dc:	85a6                	mv	a1,s1
    800034de:	00005517          	auipc	a0,0x5
    800034e2:	faa50513          	addi	a0,a0,-86 # 80008488 <states.1894+0x38>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	0a2080e7          	jalr	162(ra) # 80000588 <printf>
      plic_complete(irq);
    800034ee:	8526                	mv	a0,s1
    800034f0:	00003097          	auipc	ra,0x3
    800034f4:	4ac080e7          	jalr	1196(ra) # 8000699c <plic_complete>
    return 1;
    800034f8:	4505                	li	a0,1
    800034fa:	bf55                	j	800034ae <devintr+0x1e>
      uartintr();
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	4ac080e7          	jalr	1196(ra) # 800009a8 <uartintr>
    80003504:	b7ed                	j	800034ee <devintr+0x5e>
      virtio_disk_intr();
    80003506:	00004097          	auipc	ra,0x4
    8000350a:	976080e7          	jalr	-1674(ra) # 80006e7c <virtio_disk_intr>
    8000350e:	b7c5                	j	800034ee <devintr+0x5e>
    if(cpuid() == 0){
    80003510:	fffff097          	auipc	ra,0xfffff
    80003514:	8c8080e7          	jalr	-1848(ra) # 80001dd8 <cpuid>
    80003518:	c901                	beqz	a0,80003528 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000351a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000351e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003520:	14479073          	csrw	sip,a5
    return 2;
    80003524:	4509                	li	a0,2
    80003526:	b761                	j	800034ae <devintr+0x1e>
      clockintr();
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	f22080e7          	jalr	-222(ra) # 8000344a <clockintr>
    80003530:	b7ed                	j	8000351a <devintr+0x8a>

0000000080003532 <usertrap>:
{
    80003532:	1101                	addi	sp,sp,-32
    80003534:	ec06                	sd	ra,24(sp)
    80003536:	e822                	sd	s0,16(sp)
    80003538:	e426                	sd	s1,8(sp)
    8000353a:	e04a                	sd	s2,0(sp)
    8000353c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000353e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003542:	1007f793          	andi	a5,a5,256
    80003546:	e3ad                	bnez	a5,800035a8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003548:	00003797          	auipc	a5,0x3
    8000354c:	32878793          	addi	a5,a5,808 # 80006870 <kernelvec>
    80003550:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003554:	fffff097          	auipc	ra,0xfffff
    80003558:	8b8080e7          	jalr	-1864(ra) # 80001e0c <myproc>
    8000355c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000355e:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003560:	14102773          	csrr	a4,sepc
    80003564:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003566:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000356a:	47a1                	li	a5,8
    8000356c:	04f71c63          	bne	a4,a5,800035c4 <usertrap+0x92>
    if(p->killed)
    80003570:	413c                	lw	a5,64(a0)
    80003572:	e3b9                	bnez	a5,800035b8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003574:	60d8                	ld	a4,128(s1)
    80003576:	6f1c                	ld	a5,24(a4)
    80003578:	0791                	addi	a5,a5,4
    8000357a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000357c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003580:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003584:	10079073          	csrw	sstatus,a5
    syscall();
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	2e0080e7          	jalr	736(ra) # 80003868 <syscall>
  if(p->killed)
    80003590:	40bc                	lw	a5,64(s1)
    80003592:	ebc1                	bnez	a5,80003622 <usertrap+0xf0>
  usertrapret();
    80003594:	00000097          	auipc	ra,0x0
    80003598:	e18080e7          	jalr	-488(ra) # 800033ac <usertrapret>
}
    8000359c:	60e2                	ld	ra,24(sp)
    8000359e:	6442                	ld	s0,16(sp)
    800035a0:	64a2                	ld	s1,8(sp)
    800035a2:	6902                	ld	s2,0(sp)
    800035a4:	6105                	addi	sp,sp,32
    800035a6:	8082                	ret
    panic("usertrap: not from user mode");
    800035a8:	00005517          	auipc	a0,0x5
    800035ac:	f0050513          	addi	a0,a0,-256 # 800084a8 <states.1894+0x58>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	f8e080e7          	jalr	-114(ra) # 8000053e <panic>
      exit(-1);
    800035b8:	557d                	li	a0,-1
    800035ba:	00000097          	auipc	ra,0x0
    800035be:	a64080e7          	jalr	-1436(ra) # 8000301e <exit>
    800035c2:	bf4d                	j	80003574 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800035c4:	00000097          	auipc	ra,0x0
    800035c8:	ecc080e7          	jalr	-308(ra) # 80003490 <devintr>
    800035cc:	892a                	mv	s2,a0
    800035ce:	c501                	beqz	a0,800035d6 <usertrap+0xa4>
  if(p->killed)
    800035d0:	40bc                	lw	a5,64(s1)
    800035d2:	c3a1                	beqz	a5,80003612 <usertrap+0xe0>
    800035d4:	a815                	j	80003608 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800035d6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800035da:	44b0                	lw	a2,72(s1)
    800035dc:	00005517          	auipc	a0,0x5
    800035e0:	eec50513          	addi	a0,a0,-276 # 800084c8 <states.1894+0x78>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	fa4080e7          	jalr	-92(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800035ec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800035f0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800035f4:	00005517          	auipc	a0,0x5
    800035f8:	f0450513          	addi	a0,a0,-252 # 800084f8 <states.1894+0xa8>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	f8c080e7          	jalr	-116(ra) # 80000588 <printf>
    p->killed = 1;
    80003604:	4785                	li	a5,1
    80003606:	c0bc                	sw	a5,64(s1)
    exit(-1);
    80003608:	557d                	li	a0,-1
    8000360a:	00000097          	auipc	ra,0x0
    8000360e:	a14080e7          	jalr	-1516(ra) # 8000301e <exit>
  if(which_dev == 2)
    80003612:	4789                	li	a5,2
    80003614:	f8f910e3          	bne	s2,a5,80003594 <usertrap+0x62>
    yield();
    80003618:	fffff097          	auipc	ra,0xfffff
    8000361c:	b24080e7          	jalr	-1244(ra) # 8000213c <yield>
    80003620:	bf95                	j	80003594 <usertrap+0x62>
  int which_dev = 0;
    80003622:	4901                	li	s2,0
    80003624:	b7d5                	j	80003608 <usertrap+0xd6>

0000000080003626 <kerneltrap>:
{
    80003626:	7179                	addi	sp,sp,-48
    80003628:	f406                	sd	ra,40(sp)
    8000362a:	f022                	sd	s0,32(sp)
    8000362c:	ec26                	sd	s1,24(sp)
    8000362e:	e84a                	sd	s2,16(sp)
    80003630:	e44e                	sd	s3,8(sp)
    80003632:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003634:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003638:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000363c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003640:	1004f793          	andi	a5,s1,256
    80003644:	cb85                	beqz	a5,80003674 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003646:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000364a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000364c:	ef85                	bnez	a5,80003684 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	e42080e7          	jalr	-446(ra) # 80003490 <devintr>
    80003656:	cd1d                	beqz	a0,80003694 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003658:	4789                	li	a5,2
    8000365a:	06f50a63          	beq	a0,a5,800036ce <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000365e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003662:	10049073          	csrw	sstatus,s1
}
    80003666:	70a2                	ld	ra,40(sp)
    80003668:	7402                	ld	s0,32(sp)
    8000366a:	64e2                	ld	s1,24(sp)
    8000366c:	6942                	ld	s2,16(sp)
    8000366e:	69a2                	ld	s3,8(sp)
    80003670:	6145                	addi	sp,sp,48
    80003672:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003674:	00005517          	auipc	a0,0x5
    80003678:	ea450513          	addi	a0,a0,-348 # 80008518 <states.1894+0xc8>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	ec2080e7          	jalr	-318(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003684:	00005517          	auipc	a0,0x5
    80003688:	ebc50513          	addi	a0,a0,-324 # 80008540 <states.1894+0xf0>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	eb2080e7          	jalr	-334(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003694:	85ce                	mv	a1,s3
    80003696:	00005517          	auipc	a0,0x5
    8000369a:	eca50513          	addi	a0,a0,-310 # 80008560 <states.1894+0x110>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	eea080e7          	jalr	-278(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800036a6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800036aa:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800036ae:	00005517          	auipc	a0,0x5
    800036b2:	ec250513          	addi	a0,a0,-318 # 80008570 <states.1894+0x120>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	ed2080e7          	jalr	-302(ra) # 80000588 <printf>
    panic("kerneltrap");
    800036be:	00005517          	auipc	a0,0x5
    800036c2:	eca50513          	addi	a0,a0,-310 # 80008588 <states.1894+0x138>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	e78080e7          	jalr	-392(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800036ce:	ffffe097          	auipc	ra,0xffffe
    800036d2:	73e080e7          	jalr	1854(ra) # 80001e0c <myproc>
    800036d6:	d541                	beqz	a0,8000365e <kerneltrap+0x38>
    800036d8:	ffffe097          	auipc	ra,0xffffe
    800036dc:	734080e7          	jalr	1844(ra) # 80001e0c <myproc>
    800036e0:	5918                	lw	a4,48(a0)
    800036e2:	4791                	li	a5,4
    800036e4:	f6f71de3          	bne	a4,a5,8000365e <kerneltrap+0x38>
    yield();
    800036e8:	fffff097          	auipc	ra,0xfffff
    800036ec:	a54080e7          	jalr	-1452(ra) # 8000213c <yield>
    800036f0:	b7bd                	j	8000365e <kerneltrap+0x38>

00000000800036f2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800036f2:	1101                	addi	sp,sp,-32
    800036f4:	ec06                	sd	ra,24(sp)
    800036f6:	e822                	sd	s0,16(sp)
    800036f8:	e426                	sd	s1,8(sp)
    800036fa:	1000                	addi	s0,sp,32
    800036fc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800036fe:	ffffe097          	auipc	ra,0xffffe
    80003702:	70e080e7          	jalr	1806(ra) # 80001e0c <myproc>
  switch (n) {
    80003706:	4795                	li	a5,5
    80003708:	0497e163          	bltu	a5,s1,8000374a <argraw+0x58>
    8000370c:	048a                	slli	s1,s1,0x2
    8000370e:	00005717          	auipc	a4,0x5
    80003712:	eb270713          	addi	a4,a4,-334 # 800085c0 <states.1894+0x170>
    80003716:	94ba                	add	s1,s1,a4
    80003718:	409c                	lw	a5,0(s1)
    8000371a:	97ba                	add	a5,a5,a4
    8000371c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000371e:	615c                	ld	a5,128(a0)
    80003720:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003722:	60e2                	ld	ra,24(sp)
    80003724:	6442                	ld	s0,16(sp)
    80003726:	64a2                	ld	s1,8(sp)
    80003728:	6105                	addi	sp,sp,32
    8000372a:	8082                	ret
    return p->trapframe->a1;
    8000372c:	615c                	ld	a5,128(a0)
    8000372e:	7fa8                	ld	a0,120(a5)
    80003730:	bfcd                	j	80003722 <argraw+0x30>
    return p->trapframe->a2;
    80003732:	615c                	ld	a5,128(a0)
    80003734:	63c8                	ld	a0,128(a5)
    80003736:	b7f5                	j	80003722 <argraw+0x30>
    return p->trapframe->a3;
    80003738:	615c                	ld	a5,128(a0)
    8000373a:	67c8                	ld	a0,136(a5)
    8000373c:	b7dd                	j	80003722 <argraw+0x30>
    return p->trapframe->a4;
    8000373e:	615c                	ld	a5,128(a0)
    80003740:	6bc8                	ld	a0,144(a5)
    80003742:	b7c5                	j	80003722 <argraw+0x30>
    return p->trapframe->a5;
    80003744:	615c                	ld	a5,128(a0)
    80003746:	6fc8                	ld	a0,152(a5)
    80003748:	bfe9                	j	80003722 <argraw+0x30>
  panic("argraw");
    8000374a:	00005517          	auipc	a0,0x5
    8000374e:	e4e50513          	addi	a0,a0,-434 # 80008598 <states.1894+0x148>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	dec080e7          	jalr	-532(ra) # 8000053e <panic>

000000008000375a <fetchaddr>:
{
    8000375a:	1101                	addi	sp,sp,-32
    8000375c:	ec06                	sd	ra,24(sp)
    8000375e:	e822                	sd	s0,16(sp)
    80003760:	e426                	sd	s1,8(sp)
    80003762:	e04a                	sd	s2,0(sp)
    80003764:	1000                	addi	s0,sp,32
    80003766:	84aa                	mv	s1,a0
    80003768:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000376a:	ffffe097          	auipc	ra,0xffffe
    8000376e:	6a2080e7          	jalr	1698(ra) # 80001e0c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003772:	793c                	ld	a5,112(a0)
    80003774:	02f4f863          	bgeu	s1,a5,800037a4 <fetchaddr+0x4a>
    80003778:	00848713          	addi	a4,s1,8
    8000377c:	02e7e663          	bltu	a5,a4,800037a8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003780:	46a1                	li	a3,8
    80003782:	8626                	mv	a2,s1
    80003784:	85ca                	mv	a1,s2
    80003786:	7d28                	ld	a0,120(a0)
    80003788:	ffffe097          	auipc	ra,0xffffe
    8000378c:	f84080e7          	jalr	-124(ra) # 8000170c <copyin>
    80003790:	00a03533          	snez	a0,a0
    80003794:	40a00533          	neg	a0,a0
}
    80003798:	60e2                	ld	ra,24(sp)
    8000379a:	6442                	ld	s0,16(sp)
    8000379c:	64a2                	ld	s1,8(sp)
    8000379e:	6902                	ld	s2,0(sp)
    800037a0:	6105                	addi	sp,sp,32
    800037a2:	8082                	ret
    return -1;
    800037a4:	557d                	li	a0,-1
    800037a6:	bfcd                	j	80003798 <fetchaddr+0x3e>
    800037a8:	557d                	li	a0,-1
    800037aa:	b7fd                	j	80003798 <fetchaddr+0x3e>

00000000800037ac <fetchstr>:
{
    800037ac:	7179                	addi	sp,sp,-48
    800037ae:	f406                	sd	ra,40(sp)
    800037b0:	f022                	sd	s0,32(sp)
    800037b2:	ec26                	sd	s1,24(sp)
    800037b4:	e84a                	sd	s2,16(sp)
    800037b6:	e44e                	sd	s3,8(sp)
    800037b8:	1800                	addi	s0,sp,48
    800037ba:	892a                	mv	s2,a0
    800037bc:	84ae                	mv	s1,a1
    800037be:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800037c0:	ffffe097          	auipc	ra,0xffffe
    800037c4:	64c080e7          	jalr	1612(ra) # 80001e0c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800037c8:	86ce                	mv	a3,s3
    800037ca:	864a                	mv	a2,s2
    800037cc:	85a6                	mv	a1,s1
    800037ce:	7d28                	ld	a0,120(a0)
    800037d0:	ffffe097          	auipc	ra,0xffffe
    800037d4:	fc8080e7          	jalr	-56(ra) # 80001798 <copyinstr>
  if(err < 0)
    800037d8:	00054763          	bltz	a0,800037e6 <fetchstr+0x3a>
  return strlen(buf);
    800037dc:	8526                	mv	a0,s1
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	694080e7          	jalr	1684(ra) # 80000e72 <strlen>
}
    800037e6:	70a2                	ld	ra,40(sp)
    800037e8:	7402                	ld	s0,32(sp)
    800037ea:	64e2                	ld	s1,24(sp)
    800037ec:	6942                	ld	s2,16(sp)
    800037ee:	69a2                	ld	s3,8(sp)
    800037f0:	6145                	addi	sp,sp,48
    800037f2:	8082                	ret

00000000800037f4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800037f4:	1101                	addi	sp,sp,-32
    800037f6:	ec06                	sd	ra,24(sp)
    800037f8:	e822                	sd	s0,16(sp)
    800037fa:	e426                	sd	s1,8(sp)
    800037fc:	1000                	addi	s0,sp,32
    800037fe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003800:	00000097          	auipc	ra,0x0
    80003804:	ef2080e7          	jalr	-270(ra) # 800036f2 <argraw>
    80003808:	c088                	sw	a0,0(s1)
  return 0;
}
    8000380a:	4501                	li	a0,0
    8000380c:	60e2                	ld	ra,24(sp)
    8000380e:	6442                	ld	s0,16(sp)
    80003810:	64a2                	ld	s1,8(sp)
    80003812:	6105                	addi	sp,sp,32
    80003814:	8082                	ret

0000000080003816 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	1000                	addi	s0,sp,32
    80003820:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003822:	00000097          	auipc	ra,0x0
    80003826:	ed0080e7          	jalr	-304(ra) # 800036f2 <argraw>
    8000382a:	e088                	sd	a0,0(s1)
  return 0;
}
    8000382c:	4501                	li	a0,0
    8000382e:	60e2                	ld	ra,24(sp)
    80003830:	6442                	ld	s0,16(sp)
    80003832:	64a2                	ld	s1,8(sp)
    80003834:	6105                	addi	sp,sp,32
    80003836:	8082                	ret

0000000080003838 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003838:	1101                	addi	sp,sp,-32
    8000383a:	ec06                	sd	ra,24(sp)
    8000383c:	e822                	sd	s0,16(sp)
    8000383e:	e426                	sd	s1,8(sp)
    80003840:	e04a                	sd	s2,0(sp)
    80003842:	1000                	addi	s0,sp,32
    80003844:	84ae                	mv	s1,a1
    80003846:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	eaa080e7          	jalr	-342(ra) # 800036f2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003850:	864a                	mv	a2,s2
    80003852:	85a6                	mv	a1,s1
    80003854:	00000097          	auipc	ra,0x0
    80003858:	f58080e7          	jalr	-168(ra) # 800037ac <fetchstr>
}
    8000385c:	60e2                	ld	ra,24(sp)
    8000385e:	6442                	ld	s0,16(sp)
    80003860:	64a2                	ld	s1,8(sp)
    80003862:	6902                	ld	s2,0(sp)
    80003864:	6105                	addi	sp,sp,32
    80003866:	8082                	ret

0000000080003868 <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    80003868:	1101                	addi	sp,sp,-32
    8000386a:	ec06                	sd	ra,24(sp)
    8000386c:	e822                	sd	s0,16(sp)
    8000386e:	e426                	sd	s1,8(sp)
    80003870:	e04a                	sd	s2,0(sp)
    80003872:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003874:	ffffe097          	auipc	ra,0xffffe
    80003878:	598080e7          	jalr	1432(ra) # 80001e0c <myproc>
    8000387c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000387e:	08053903          	ld	s2,128(a0)
    80003882:	0a893783          	ld	a5,168(s2)
    80003886:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000388a:	37fd                	addiw	a5,a5,-1
    8000388c:	4759                	li	a4,22
    8000388e:	00f76f63          	bltu	a4,a5,800038ac <syscall+0x44>
    80003892:	00369713          	slli	a4,a3,0x3
    80003896:	00005797          	auipc	a5,0x5
    8000389a:	d4278793          	addi	a5,a5,-702 # 800085d8 <syscalls>
    8000389e:	97ba                	add	a5,a5,a4
    800038a0:	639c                	ld	a5,0(a5)
    800038a2:	c789                	beqz	a5,800038ac <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800038a4:	9782                	jalr	a5
    800038a6:	06a93823          	sd	a0,112(s2)
    800038aa:	a839                	j	800038c8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800038ac:	18048613          	addi	a2,s1,384
    800038b0:	44ac                	lw	a1,72(s1)
    800038b2:	00005517          	auipc	a0,0x5
    800038b6:	cee50513          	addi	a0,a0,-786 # 800085a0 <states.1894+0x150>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	cce080e7          	jalr	-818(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800038c2:	60dc                	ld	a5,128(s1)
    800038c4:	577d                	li	a4,-1
    800038c6:	fbb8                	sd	a4,112(a5)
  }
}
    800038c8:	60e2                	ld	ra,24(sp)
    800038ca:	6442                	ld	s0,16(sp)
    800038cc:	64a2                	ld	s1,8(sp)
    800038ce:	6902                	ld	s2,0(sp)
    800038d0:	6105                	addi	sp,sp,32
    800038d2:	8082                	ret

00000000800038d4 <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    800038d4:	1101                	addi	sp,sp,-32
    800038d6:	ec06                	sd	ra,24(sp)
    800038d8:	e822                	sd	s0,16(sp)
    800038da:	1000                	addi	s0,sp,32
  int a;

  if(argint(0, &a) < 0)
    800038dc:	fec40593          	addi	a1,s0,-20
    800038e0:	4501                	li	a0,0
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	f12080e7          	jalr	-238(ra) # 800037f4 <argint>
    800038ea:	87aa                	mv	a5,a0
    return -1;
    800038ec:	557d                	li	a0,-1
  if(argint(0, &a) < 0)
    800038ee:	0007c863          	bltz	a5,800038fe <sys_set_cpu+0x2a>
  return set_cpu(a);
    800038f2:	fec42503          	lw	a0,-20(s0)
    800038f6:	fffff097          	auipc	ra,0xfffff
    800038fa:	890080e7          	jalr	-1904(ra) # 80002186 <set_cpu>
}
    800038fe:	60e2                	ld	ra,24(sp)
    80003900:	6442                	ld	s0,16(sp)
    80003902:	6105                	addi	sp,sp,32
    80003904:	8082                	ret

0000000080003906 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003906:	1141                	addi	sp,sp,-16
    80003908:	e406                	sd	ra,8(sp)
    8000390a:	e022                	sd	s0,0(sp)
    8000390c:	0800                	addi	s0,sp,16
  return get_cpu();
    8000390e:	ffffe097          	auipc	ra,0xffffe
    80003912:	53e080e7          	jalr	1342(ra) # 80001e4c <get_cpu>
}
    80003916:	60a2                	ld	ra,8(sp)
    80003918:	6402                	ld	s0,0(sp)
    8000391a:	0141                	addi	sp,sp,16
    8000391c:	8082                	ret

000000008000391e <sys_exit>:

uint64
sys_exit(void)
{
    8000391e:	1101                	addi	sp,sp,-32
    80003920:	ec06                	sd	ra,24(sp)
    80003922:	e822                	sd	s0,16(sp)
    80003924:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003926:	fec40593          	addi	a1,s0,-20
    8000392a:	4501                	li	a0,0
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	ec8080e7          	jalr	-312(ra) # 800037f4 <argint>
    return -1;
    80003934:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003936:	00054963          	bltz	a0,80003948 <sys_exit+0x2a>
  exit(n);
    8000393a:	fec42503          	lw	a0,-20(s0)
    8000393e:	fffff097          	auipc	ra,0xfffff
    80003942:	6e0080e7          	jalr	1760(ra) # 8000301e <exit>
  return 0;  // not reached
    80003946:	4781                	li	a5,0
}
    80003948:	853e                	mv	a0,a5
    8000394a:	60e2                	ld	ra,24(sp)
    8000394c:	6442                	ld	s0,16(sp)
    8000394e:	6105                	addi	sp,sp,32
    80003950:	8082                	ret

0000000080003952 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003952:	1141                	addi	sp,sp,-16
    80003954:	e406                	sd	ra,8(sp)
    80003956:	e022                	sd	s0,0(sp)
    80003958:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000395a:	ffffe097          	auipc	ra,0xffffe
    8000395e:	4b2080e7          	jalr	1202(ra) # 80001e0c <myproc>
}
    80003962:	4528                	lw	a0,72(a0)
    80003964:	60a2                	ld	ra,8(sp)
    80003966:	6402                	ld	s0,0(sp)
    80003968:	0141                	addi	sp,sp,16
    8000396a:	8082                	ret

000000008000396c <sys_fork>:

uint64
sys_fork(void)
{
    8000396c:	1141                	addi	sp,sp,-16
    8000396e:	e406                	sd	ra,8(sp)
    80003970:	e022                	sd	s0,0(sp)
    80003972:	0800                	addi	s0,sp,16
  return fork();
    80003974:	fffff097          	auipc	ra,0xfffff
    80003978:	1c0080e7          	jalr	448(ra) # 80002b34 <fork>
}
    8000397c:	60a2                	ld	ra,8(sp)
    8000397e:	6402                	ld	s0,0(sp)
    80003980:	0141                	addi	sp,sp,16
    80003982:	8082                	ret

0000000080003984 <sys_wait>:

uint64
sys_wait(void)
{
    80003984:	1101                	addi	sp,sp,-32
    80003986:	ec06                	sd	ra,24(sp)
    80003988:	e822                	sd	s0,16(sp)
    8000398a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000398c:	fe840593          	addi	a1,s0,-24
    80003990:	4501                	li	a0,0
    80003992:	00000097          	auipc	ra,0x0
    80003996:	e84080e7          	jalr	-380(ra) # 80003816 <argaddr>
    8000399a:	87aa                	mv	a5,a0
    return -1;
    8000399c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000399e:	0007c863          	bltz	a5,800039ae <sys_wait+0x2a>
  return wait(p);
    800039a2:	fe843503          	ld	a0,-24(s0)
    800039a6:	fffff097          	auipc	ra,0xfffff
    800039aa:	362080e7          	jalr	866(ra) # 80002d08 <wait>
}
    800039ae:	60e2                	ld	ra,24(sp)
    800039b0:	6442                	ld	s0,16(sp)
    800039b2:	6105                	addi	sp,sp,32
    800039b4:	8082                	ret

00000000800039b6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800039b6:	7179                	addi	sp,sp,-48
    800039b8:	f406                	sd	ra,40(sp)
    800039ba:	f022                	sd	s0,32(sp)
    800039bc:	ec26                	sd	s1,24(sp)
    800039be:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800039c0:	fdc40593          	addi	a1,s0,-36
    800039c4:	4501                	li	a0,0
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	e2e080e7          	jalr	-466(ra) # 800037f4 <argint>
    800039ce:	87aa                	mv	a5,a0
    return -1;
    800039d0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800039d2:	0207c063          	bltz	a5,800039f2 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800039d6:	ffffe097          	auipc	ra,0xffffe
    800039da:	436080e7          	jalr	1078(ra) # 80001e0c <myproc>
    800039de:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    800039e0:	fdc42503          	lw	a0,-36(s0)
    800039e4:	ffffe097          	auipc	ra,0xffffe
    800039e8:	5ee080e7          	jalr	1518(ra) # 80001fd2 <growproc>
    800039ec:	00054863          	bltz	a0,800039fc <sys_sbrk+0x46>
    return -1;
  return addr;
    800039f0:	8526                	mv	a0,s1
}
    800039f2:	70a2                	ld	ra,40(sp)
    800039f4:	7402                	ld	s0,32(sp)
    800039f6:	64e2                	ld	s1,24(sp)
    800039f8:	6145                	addi	sp,sp,48
    800039fa:	8082                	ret
    return -1;
    800039fc:	557d                	li	a0,-1
    800039fe:	bfd5                	j	800039f2 <sys_sbrk+0x3c>

0000000080003a00 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003a00:	7139                	addi	sp,sp,-64
    80003a02:	fc06                	sd	ra,56(sp)
    80003a04:	f822                	sd	s0,48(sp)
    80003a06:	f426                	sd	s1,40(sp)
    80003a08:	f04a                	sd	s2,32(sp)
    80003a0a:	ec4e                	sd	s3,24(sp)
    80003a0c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003a0e:	fcc40593          	addi	a1,s0,-52
    80003a12:	4501                	li	a0,0
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	de0080e7          	jalr	-544(ra) # 800037f4 <argint>
    return -1;
    80003a1c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003a1e:	06054563          	bltz	a0,80003a88 <sys_sleep+0x88>
  acquire(&tickslock);
    80003a22:	00014517          	auipc	a0,0x14
    80003a26:	fbe50513          	addi	a0,a0,-66 # 800179e0 <tickslock>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	1c2080e7          	jalr	450(ra) # 80000bec <acquire>
  ticks0 = ticks;
    80003a32:	00005917          	auipc	s2,0x5
    80003a36:	63e92903          	lw	s2,1598(s2) # 80009070 <ticks>
  while(ticks - ticks0 < n){
    80003a3a:	fcc42783          	lw	a5,-52(s0)
    80003a3e:	cf85                	beqz	a5,80003a76 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003a40:	00014997          	auipc	s3,0x14
    80003a44:	fa098993          	addi	s3,s3,-96 # 800179e0 <tickslock>
    80003a48:	00005497          	auipc	s1,0x5
    80003a4c:	62848493          	addi	s1,s1,1576 # 80009070 <ticks>
    if(myproc()->killed){
    80003a50:	ffffe097          	auipc	ra,0xffffe
    80003a54:	3bc080e7          	jalr	956(ra) # 80001e0c <myproc>
    80003a58:	413c                	lw	a5,64(a0)
    80003a5a:	ef9d                	bnez	a5,80003a98 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003a5c:	85ce                	mv	a1,s3
    80003a5e:	8526                	mv	a0,s1
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	22a080e7          	jalr	554(ra) # 80002c8a <sleep>
  while(ticks - ticks0 < n){
    80003a68:	409c                	lw	a5,0(s1)
    80003a6a:	412787bb          	subw	a5,a5,s2
    80003a6e:	fcc42703          	lw	a4,-52(s0)
    80003a72:	fce7efe3          	bltu	a5,a4,80003a50 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003a76:	00014517          	auipc	a0,0x14
    80003a7a:	f6a50513          	addi	a0,a0,-150 # 800179e0 <tickslock>
    80003a7e:	ffffd097          	auipc	ra,0xffffd
    80003a82:	228080e7          	jalr	552(ra) # 80000ca6 <release>
  return 0;
    80003a86:	4781                	li	a5,0
}
    80003a88:	853e                	mv	a0,a5
    80003a8a:	70e2                	ld	ra,56(sp)
    80003a8c:	7442                	ld	s0,48(sp)
    80003a8e:	74a2                	ld	s1,40(sp)
    80003a90:	7902                	ld	s2,32(sp)
    80003a92:	69e2                	ld	s3,24(sp)
    80003a94:	6121                	addi	sp,sp,64
    80003a96:	8082                	ret
      release(&tickslock);
    80003a98:	00014517          	auipc	a0,0x14
    80003a9c:	f4850513          	addi	a0,a0,-184 # 800179e0 <tickslock>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	206080e7          	jalr	518(ra) # 80000ca6 <release>
      return -1;
    80003aa8:	57fd                	li	a5,-1
    80003aaa:	bff9                	j	80003a88 <sys_sleep+0x88>

0000000080003aac <sys_kill>:

uint64
sys_kill(void)
{
    80003aac:	1101                	addi	sp,sp,-32
    80003aae:	ec06                	sd	ra,24(sp)
    80003ab0:	e822                	sd	s0,16(sp)
    80003ab2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003ab4:	fec40593          	addi	a1,s0,-20
    80003ab8:	4501                	li	a0,0
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	d3a080e7          	jalr	-710(ra) # 800037f4 <argint>
    80003ac2:	87aa                	mv	a5,a0
    return -1;
    80003ac4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003ac6:	0007c863          	bltz	a5,80003ad6 <sys_kill+0x2a>
  return kill(pid);
    80003aca:	fec42503          	lw	a0,-20(s0)
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	642080e7          	jalr	1602(ra) # 80003110 <kill>
}
    80003ad6:	60e2                	ld	ra,24(sp)
    80003ad8:	6442                	ld	s0,16(sp)
    80003ada:	6105                	addi	sp,sp,32
    80003adc:	8082                	ret

0000000080003ade <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003ade:	1101                	addi	sp,sp,-32
    80003ae0:	ec06                	sd	ra,24(sp)
    80003ae2:	e822                	sd	s0,16(sp)
    80003ae4:	e426                	sd	s1,8(sp)
    80003ae6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003ae8:	00014517          	auipc	a0,0x14
    80003aec:	ef850513          	addi	a0,a0,-264 # 800179e0 <tickslock>
    80003af0:	ffffd097          	auipc	ra,0xffffd
    80003af4:	0fc080e7          	jalr	252(ra) # 80000bec <acquire>
  xticks = ticks;
    80003af8:	00005497          	auipc	s1,0x5
    80003afc:	5784a483          	lw	s1,1400(s1) # 80009070 <ticks>
  release(&tickslock);
    80003b00:	00014517          	auipc	a0,0x14
    80003b04:	ee050513          	addi	a0,a0,-288 # 800179e0 <tickslock>
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	19e080e7          	jalr	414(ra) # 80000ca6 <release>
  return xticks;
}
    80003b10:	02049513          	slli	a0,s1,0x20
    80003b14:	9101                	srli	a0,a0,0x20
    80003b16:	60e2                	ld	ra,24(sp)
    80003b18:	6442                	ld	s0,16(sp)
    80003b1a:	64a2                	ld	s1,8(sp)
    80003b1c:	6105                	addi	sp,sp,32
    80003b1e:	8082                	ret

0000000080003b20 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003b20:	7179                	addi	sp,sp,-48
    80003b22:	f406                	sd	ra,40(sp)
    80003b24:	f022                	sd	s0,32(sp)
    80003b26:	ec26                	sd	s1,24(sp)
    80003b28:	e84a                	sd	s2,16(sp)
    80003b2a:	e44e                	sd	s3,8(sp)
    80003b2c:	e052                	sd	s4,0(sp)
    80003b2e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003b30:	00005597          	auipc	a1,0x5
    80003b34:	b6858593          	addi	a1,a1,-1176 # 80008698 <syscalls+0xc0>
    80003b38:	00014517          	auipc	a0,0x14
    80003b3c:	ec050513          	addi	a0,a0,-320 # 800179f8 <bcache>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	014080e7          	jalr	20(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003b48:	0001c797          	auipc	a5,0x1c
    80003b4c:	eb078793          	addi	a5,a5,-336 # 8001f9f8 <bcache+0x8000>
    80003b50:	0001c717          	auipc	a4,0x1c
    80003b54:	11070713          	addi	a4,a4,272 # 8001fc60 <bcache+0x8268>
    80003b58:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003b5c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b60:	00014497          	auipc	s1,0x14
    80003b64:	eb048493          	addi	s1,s1,-336 # 80017a10 <bcache+0x18>
    b->next = bcache.head.next;
    80003b68:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003b6a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003b6c:	00005a17          	auipc	s4,0x5
    80003b70:	b34a0a13          	addi	s4,s4,-1228 # 800086a0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003b74:	2b893783          	ld	a5,696(s2)
    80003b78:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003b7a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003b7e:	85d2                	mv	a1,s4
    80003b80:	01048513          	addi	a0,s1,16
    80003b84:	00001097          	auipc	ra,0x1
    80003b88:	4bc080e7          	jalr	1212(ra) # 80005040 <initsleeplock>
    bcache.head.next->prev = b;
    80003b8c:	2b893783          	ld	a5,696(s2)
    80003b90:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003b92:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003b96:	45848493          	addi	s1,s1,1112
    80003b9a:	fd349de3          	bne	s1,s3,80003b74 <binit+0x54>
  }
}
    80003b9e:	70a2                	ld	ra,40(sp)
    80003ba0:	7402                	ld	s0,32(sp)
    80003ba2:	64e2                	ld	s1,24(sp)
    80003ba4:	6942                	ld	s2,16(sp)
    80003ba6:	69a2                	ld	s3,8(sp)
    80003ba8:	6a02                	ld	s4,0(sp)
    80003baa:	6145                	addi	sp,sp,48
    80003bac:	8082                	ret

0000000080003bae <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003bae:	7179                	addi	sp,sp,-48
    80003bb0:	f406                	sd	ra,40(sp)
    80003bb2:	f022                	sd	s0,32(sp)
    80003bb4:	ec26                	sd	s1,24(sp)
    80003bb6:	e84a                	sd	s2,16(sp)
    80003bb8:	e44e                	sd	s3,8(sp)
    80003bba:	1800                	addi	s0,sp,48
    80003bbc:	89aa                	mv	s3,a0
    80003bbe:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003bc0:	00014517          	auipc	a0,0x14
    80003bc4:	e3850513          	addi	a0,a0,-456 # 800179f8 <bcache>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	024080e7          	jalr	36(ra) # 80000bec <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003bd0:	0001c497          	auipc	s1,0x1c
    80003bd4:	0e04b483          	ld	s1,224(s1) # 8001fcb0 <bcache+0x82b8>
    80003bd8:	0001c797          	auipc	a5,0x1c
    80003bdc:	08878793          	addi	a5,a5,136 # 8001fc60 <bcache+0x8268>
    80003be0:	02f48f63          	beq	s1,a5,80003c1e <bread+0x70>
    80003be4:	873e                	mv	a4,a5
    80003be6:	a021                	j	80003bee <bread+0x40>
    80003be8:	68a4                	ld	s1,80(s1)
    80003bea:	02e48a63          	beq	s1,a4,80003c1e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003bee:	449c                	lw	a5,8(s1)
    80003bf0:	ff379ce3          	bne	a5,s3,80003be8 <bread+0x3a>
    80003bf4:	44dc                	lw	a5,12(s1)
    80003bf6:	ff2799e3          	bne	a5,s2,80003be8 <bread+0x3a>
      b->refcnt++;
    80003bfa:	40bc                	lw	a5,64(s1)
    80003bfc:	2785                	addiw	a5,a5,1
    80003bfe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003c00:	00014517          	auipc	a0,0x14
    80003c04:	df850513          	addi	a0,a0,-520 # 800179f8 <bcache>
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	09e080e7          	jalr	158(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003c10:	01048513          	addi	a0,s1,16
    80003c14:	00001097          	auipc	ra,0x1
    80003c18:	466080e7          	jalr	1126(ra) # 8000507a <acquiresleep>
      return b;
    80003c1c:	a8b9                	j	80003c7a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003c1e:	0001c497          	auipc	s1,0x1c
    80003c22:	08a4b483          	ld	s1,138(s1) # 8001fca8 <bcache+0x82b0>
    80003c26:	0001c797          	auipc	a5,0x1c
    80003c2a:	03a78793          	addi	a5,a5,58 # 8001fc60 <bcache+0x8268>
    80003c2e:	00f48863          	beq	s1,a5,80003c3e <bread+0x90>
    80003c32:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003c34:	40bc                	lw	a5,64(s1)
    80003c36:	cf81                	beqz	a5,80003c4e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003c38:	64a4                	ld	s1,72(s1)
    80003c3a:	fee49de3          	bne	s1,a4,80003c34 <bread+0x86>
  panic("bget: no buffers");
    80003c3e:	00005517          	auipc	a0,0x5
    80003c42:	a6a50513          	addi	a0,a0,-1430 # 800086a8 <syscalls+0xd0>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	8f8080e7          	jalr	-1800(ra) # 8000053e <panic>
      b->dev = dev;
    80003c4e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003c52:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003c56:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003c5a:	4785                	li	a5,1
    80003c5c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003c5e:	00014517          	auipc	a0,0x14
    80003c62:	d9a50513          	addi	a0,a0,-614 # 800179f8 <bcache>
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	040080e7          	jalr	64(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003c6e:	01048513          	addi	a0,s1,16
    80003c72:	00001097          	auipc	ra,0x1
    80003c76:	408080e7          	jalr	1032(ra) # 8000507a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003c7a:	409c                	lw	a5,0(s1)
    80003c7c:	cb89                	beqz	a5,80003c8e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003c7e:	8526                	mv	a0,s1
    80003c80:	70a2                	ld	ra,40(sp)
    80003c82:	7402                	ld	s0,32(sp)
    80003c84:	64e2                	ld	s1,24(sp)
    80003c86:	6942                	ld	s2,16(sp)
    80003c88:	69a2                	ld	s3,8(sp)
    80003c8a:	6145                	addi	sp,sp,48
    80003c8c:	8082                	ret
    virtio_disk_rw(b, 0);
    80003c8e:	4581                	li	a1,0
    80003c90:	8526                	mv	a0,s1
    80003c92:	00003097          	auipc	ra,0x3
    80003c96:	f14080e7          	jalr	-236(ra) # 80006ba6 <virtio_disk_rw>
    b->valid = 1;
    80003c9a:	4785                	li	a5,1
    80003c9c:	c09c                	sw	a5,0(s1)
  return b;
    80003c9e:	b7c5                	j	80003c7e <bread+0xd0>

0000000080003ca0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003ca0:	1101                	addi	sp,sp,-32
    80003ca2:	ec06                	sd	ra,24(sp)
    80003ca4:	e822                	sd	s0,16(sp)
    80003ca6:	e426                	sd	s1,8(sp)
    80003ca8:	1000                	addi	s0,sp,32
    80003caa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003cac:	0541                	addi	a0,a0,16
    80003cae:	00001097          	auipc	ra,0x1
    80003cb2:	466080e7          	jalr	1126(ra) # 80005114 <holdingsleep>
    80003cb6:	cd01                	beqz	a0,80003cce <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003cb8:	4585                	li	a1,1
    80003cba:	8526                	mv	a0,s1
    80003cbc:	00003097          	auipc	ra,0x3
    80003cc0:	eea080e7          	jalr	-278(ra) # 80006ba6 <virtio_disk_rw>
}
    80003cc4:	60e2                	ld	ra,24(sp)
    80003cc6:	6442                	ld	s0,16(sp)
    80003cc8:	64a2                	ld	s1,8(sp)
    80003cca:	6105                	addi	sp,sp,32
    80003ccc:	8082                	ret
    panic("bwrite");
    80003cce:	00005517          	auipc	a0,0x5
    80003cd2:	9f250513          	addi	a0,a0,-1550 # 800086c0 <syscalls+0xe8>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	868080e7          	jalr	-1944(ra) # 8000053e <panic>

0000000080003cde <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003cde:	1101                	addi	sp,sp,-32
    80003ce0:	ec06                	sd	ra,24(sp)
    80003ce2:	e822                	sd	s0,16(sp)
    80003ce4:	e426                	sd	s1,8(sp)
    80003ce6:	e04a                	sd	s2,0(sp)
    80003ce8:	1000                	addi	s0,sp,32
    80003cea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003cec:	01050913          	addi	s2,a0,16
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00001097          	auipc	ra,0x1
    80003cf6:	422080e7          	jalr	1058(ra) # 80005114 <holdingsleep>
    80003cfa:	c92d                	beqz	a0,80003d6c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003cfc:	854a                	mv	a0,s2
    80003cfe:	00001097          	auipc	ra,0x1
    80003d02:	3d2080e7          	jalr	978(ra) # 800050d0 <releasesleep>

  acquire(&bcache.lock);
    80003d06:	00014517          	auipc	a0,0x14
    80003d0a:	cf250513          	addi	a0,a0,-782 # 800179f8 <bcache>
    80003d0e:	ffffd097          	auipc	ra,0xffffd
    80003d12:	ede080e7          	jalr	-290(ra) # 80000bec <acquire>
  b->refcnt--;
    80003d16:	40bc                	lw	a5,64(s1)
    80003d18:	37fd                	addiw	a5,a5,-1
    80003d1a:	0007871b          	sext.w	a4,a5
    80003d1e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003d20:	eb05                	bnez	a4,80003d50 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003d22:	68bc                	ld	a5,80(s1)
    80003d24:	64b8                	ld	a4,72(s1)
    80003d26:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003d28:	64bc                	ld	a5,72(s1)
    80003d2a:	68b8                	ld	a4,80(s1)
    80003d2c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003d2e:	0001c797          	auipc	a5,0x1c
    80003d32:	cca78793          	addi	a5,a5,-822 # 8001f9f8 <bcache+0x8000>
    80003d36:	2b87b703          	ld	a4,696(a5)
    80003d3a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003d3c:	0001c717          	auipc	a4,0x1c
    80003d40:	f2470713          	addi	a4,a4,-220 # 8001fc60 <bcache+0x8268>
    80003d44:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003d46:	2b87b703          	ld	a4,696(a5)
    80003d4a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003d4c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003d50:	00014517          	auipc	a0,0x14
    80003d54:	ca850513          	addi	a0,a0,-856 # 800179f8 <bcache>
    80003d58:	ffffd097          	auipc	ra,0xffffd
    80003d5c:	f4e080e7          	jalr	-178(ra) # 80000ca6 <release>
}
    80003d60:	60e2                	ld	ra,24(sp)
    80003d62:	6442                	ld	s0,16(sp)
    80003d64:	64a2                	ld	s1,8(sp)
    80003d66:	6902                	ld	s2,0(sp)
    80003d68:	6105                	addi	sp,sp,32
    80003d6a:	8082                	ret
    panic("brelse");
    80003d6c:	00005517          	auipc	a0,0x5
    80003d70:	95c50513          	addi	a0,a0,-1700 # 800086c8 <syscalls+0xf0>
    80003d74:	ffffc097          	auipc	ra,0xffffc
    80003d78:	7ca080e7          	jalr	1994(ra) # 8000053e <panic>

0000000080003d7c <bpin>:

void
bpin(struct buf *b) {
    80003d7c:	1101                	addi	sp,sp,-32
    80003d7e:	ec06                	sd	ra,24(sp)
    80003d80:	e822                	sd	s0,16(sp)
    80003d82:	e426                	sd	s1,8(sp)
    80003d84:	1000                	addi	s0,sp,32
    80003d86:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d88:	00014517          	auipc	a0,0x14
    80003d8c:	c7050513          	addi	a0,a0,-912 # 800179f8 <bcache>
    80003d90:	ffffd097          	auipc	ra,0xffffd
    80003d94:	e5c080e7          	jalr	-420(ra) # 80000bec <acquire>
  b->refcnt++;
    80003d98:	40bc                	lw	a5,64(s1)
    80003d9a:	2785                	addiw	a5,a5,1
    80003d9c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d9e:	00014517          	auipc	a0,0x14
    80003da2:	c5a50513          	addi	a0,a0,-934 # 800179f8 <bcache>
    80003da6:	ffffd097          	auipc	ra,0xffffd
    80003daa:	f00080e7          	jalr	-256(ra) # 80000ca6 <release>
}
    80003dae:	60e2                	ld	ra,24(sp)
    80003db0:	6442                	ld	s0,16(sp)
    80003db2:	64a2                	ld	s1,8(sp)
    80003db4:	6105                	addi	sp,sp,32
    80003db6:	8082                	ret

0000000080003db8 <bunpin>:

void
bunpin(struct buf *b) {
    80003db8:	1101                	addi	sp,sp,-32
    80003dba:	ec06                	sd	ra,24(sp)
    80003dbc:	e822                	sd	s0,16(sp)
    80003dbe:	e426                	sd	s1,8(sp)
    80003dc0:	1000                	addi	s0,sp,32
    80003dc2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003dc4:	00014517          	auipc	a0,0x14
    80003dc8:	c3450513          	addi	a0,a0,-972 # 800179f8 <bcache>
    80003dcc:	ffffd097          	auipc	ra,0xffffd
    80003dd0:	e20080e7          	jalr	-480(ra) # 80000bec <acquire>
  b->refcnt--;
    80003dd4:	40bc                	lw	a5,64(s1)
    80003dd6:	37fd                	addiw	a5,a5,-1
    80003dd8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003dda:	00014517          	auipc	a0,0x14
    80003dde:	c1e50513          	addi	a0,a0,-994 # 800179f8 <bcache>
    80003de2:	ffffd097          	auipc	ra,0xffffd
    80003de6:	ec4080e7          	jalr	-316(ra) # 80000ca6 <release>
}
    80003dea:	60e2                	ld	ra,24(sp)
    80003dec:	6442                	ld	s0,16(sp)
    80003dee:	64a2                	ld	s1,8(sp)
    80003df0:	6105                	addi	sp,sp,32
    80003df2:	8082                	ret

0000000080003df4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003df4:	1101                	addi	sp,sp,-32
    80003df6:	ec06                	sd	ra,24(sp)
    80003df8:	e822                	sd	s0,16(sp)
    80003dfa:	e426                	sd	s1,8(sp)
    80003dfc:	e04a                	sd	s2,0(sp)
    80003dfe:	1000                	addi	s0,sp,32
    80003e00:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003e02:	00d5d59b          	srliw	a1,a1,0xd
    80003e06:	0001c797          	auipc	a5,0x1c
    80003e0a:	2ce7a783          	lw	a5,718(a5) # 800200d4 <sb+0x1c>
    80003e0e:	9dbd                	addw	a1,a1,a5
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	d9e080e7          	jalr	-610(ra) # 80003bae <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003e18:	0074f713          	andi	a4,s1,7
    80003e1c:	4785                	li	a5,1
    80003e1e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003e22:	14ce                	slli	s1,s1,0x33
    80003e24:	90d9                	srli	s1,s1,0x36
    80003e26:	00950733          	add	a4,a0,s1
    80003e2a:	05874703          	lbu	a4,88(a4)
    80003e2e:	00e7f6b3          	and	a3,a5,a4
    80003e32:	c69d                	beqz	a3,80003e60 <bfree+0x6c>
    80003e34:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003e36:	94aa                	add	s1,s1,a0
    80003e38:	fff7c793          	not	a5,a5
    80003e3c:	8ff9                	and	a5,a5,a4
    80003e3e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003e42:	00001097          	auipc	ra,0x1
    80003e46:	118080e7          	jalr	280(ra) # 80004f5a <log_write>
  brelse(bp);
    80003e4a:	854a                	mv	a0,s2
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	e92080e7          	jalr	-366(ra) # 80003cde <brelse>
}
    80003e54:	60e2                	ld	ra,24(sp)
    80003e56:	6442                	ld	s0,16(sp)
    80003e58:	64a2                	ld	s1,8(sp)
    80003e5a:	6902                	ld	s2,0(sp)
    80003e5c:	6105                	addi	sp,sp,32
    80003e5e:	8082                	ret
    panic("freeing free block");
    80003e60:	00005517          	auipc	a0,0x5
    80003e64:	87050513          	addi	a0,a0,-1936 # 800086d0 <syscalls+0xf8>
    80003e68:	ffffc097          	auipc	ra,0xffffc
    80003e6c:	6d6080e7          	jalr	1750(ra) # 8000053e <panic>

0000000080003e70 <balloc>:
{
    80003e70:	711d                	addi	sp,sp,-96
    80003e72:	ec86                	sd	ra,88(sp)
    80003e74:	e8a2                	sd	s0,80(sp)
    80003e76:	e4a6                	sd	s1,72(sp)
    80003e78:	e0ca                	sd	s2,64(sp)
    80003e7a:	fc4e                	sd	s3,56(sp)
    80003e7c:	f852                	sd	s4,48(sp)
    80003e7e:	f456                	sd	s5,40(sp)
    80003e80:	f05a                	sd	s6,32(sp)
    80003e82:	ec5e                	sd	s7,24(sp)
    80003e84:	e862                	sd	s8,16(sp)
    80003e86:	e466                	sd	s9,8(sp)
    80003e88:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003e8a:	0001c797          	auipc	a5,0x1c
    80003e8e:	2327a783          	lw	a5,562(a5) # 800200bc <sb+0x4>
    80003e92:	cbd1                	beqz	a5,80003f26 <balloc+0xb6>
    80003e94:	8baa                	mv	s7,a0
    80003e96:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003e98:	0001cb17          	auipc	s6,0x1c
    80003e9c:	220b0b13          	addi	s6,s6,544 # 800200b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ea0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003ea2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ea4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003ea6:	6c89                	lui	s9,0x2
    80003ea8:	a831                	j	80003ec4 <balloc+0x54>
    brelse(bp);
    80003eaa:	854a                	mv	a0,s2
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	e32080e7          	jalr	-462(ra) # 80003cde <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003eb4:	015c87bb          	addw	a5,s9,s5
    80003eb8:	00078a9b          	sext.w	s5,a5
    80003ebc:	004b2703          	lw	a4,4(s6)
    80003ec0:	06eaf363          	bgeu	s5,a4,80003f26 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003ec4:	41fad79b          	sraiw	a5,s5,0x1f
    80003ec8:	0137d79b          	srliw	a5,a5,0x13
    80003ecc:	015787bb          	addw	a5,a5,s5
    80003ed0:	40d7d79b          	sraiw	a5,a5,0xd
    80003ed4:	01cb2583          	lw	a1,28(s6)
    80003ed8:	9dbd                	addw	a1,a1,a5
    80003eda:	855e                	mv	a0,s7
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	cd2080e7          	jalr	-814(ra) # 80003bae <bread>
    80003ee4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ee6:	004b2503          	lw	a0,4(s6)
    80003eea:	000a849b          	sext.w	s1,s5
    80003eee:	8662                	mv	a2,s8
    80003ef0:	faa4fde3          	bgeu	s1,a0,80003eaa <balloc+0x3a>
      m = 1 << (bi % 8);
    80003ef4:	41f6579b          	sraiw	a5,a2,0x1f
    80003ef8:	01d7d69b          	srliw	a3,a5,0x1d
    80003efc:	00c6873b          	addw	a4,a3,a2
    80003f00:	00777793          	andi	a5,a4,7
    80003f04:	9f95                	subw	a5,a5,a3
    80003f06:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003f0a:	4037571b          	sraiw	a4,a4,0x3
    80003f0e:	00e906b3          	add	a3,s2,a4
    80003f12:	0586c683          	lbu	a3,88(a3)
    80003f16:	00d7f5b3          	and	a1,a5,a3
    80003f1a:	cd91                	beqz	a1,80003f36 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003f1c:	2605                	addiw	a2,a2,1
    80003f1e:	2485                	addiw	s1,s1,1
    80003f20:	fd4618e3          	bne	a2,s4,80003ef0 <balloc+0x80>
    80003f24:	b759                	j	80003eaa <balloc+0x3a>
  panic("balloc: out of blocks");
    80003f26:	00004517          	auipc	a0,0x4
    80003f2a:	7c250513          	addi	a0,a0,1986 # 800086e8 <syscalls+0x110>
    80003f2e:	ffffc097          	auipc	ra,0xffffc
    80003f32:	610080e7          	jalr	1552(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003f36:	974a                	add	a4,a4,s2
    80003f38:	8fd5                	or	a5,a5,a3
    80003f3a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003f3e:	854a                	mv	a0,s2
    80003f40:	00001097          	auipc	ra,0x1
    80003f44:	01a080e7          	jalr	26(ra) # 80004f5a <log_write>
        brelse(bp);
    80003f48:	854a                	mv	a0,s2
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	d94080e7          	jalr	-620(ra) # 80003cde <brelse>
  bp = bread(dev, bno);
    80003f52:	85a6                	mv	a1,s1
    80003f54:	855e                	mv	a0,s7
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	c58080e7          	jalr	-936(ra) # 80003bae <bread>
    80003f5e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003f60:	40000613          	li	a2,1024
    80003f64:	4581                	li	a1,0
    80003f66:	05850513          	addi	a0,a0,88
    80003f6a:	ffffd097          	auipc	ra,0xffffd
    80003f6e:	d84080e7          	jalr	-636(ra) # 80000cee <memset>
  log_write(bp);
    80003f72:	854a                	mv	a0,s2
    80003f74:	00001097          	auipc	ra,0x1
    80003f78:	fe6080e7          	jalr	-26(ra) # 80004f5a <log_write>
  brelse(bp);
    80003f7c:	854a                	mv	a0,s2
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	d60080e7          	jalr	-672(ra) # 80003cde <brelse>
}
    80003f86:	8526                	mv	a0,s1
    80003f88:	60e6                	ld	ra,88(sp)
    80003f8a:	6446                	ld	s0,80(sp)
    80003f8c:	64a6                	ld	s1,72(sp)
    80003f8e:	6906                	ld	s2,64(sp)
    80003f90:	79e2                	ld	s3,56(sp)
    80003f92:	7a42                	ld	s4,48(sp)
    80003f94:	7aa2                	ld	s5,40(sp)
    80003f96:	7b02                	ld	s6,32(sp)
    80003f98:	6be2                	ld	s7,24(sp)
    80003f9a:	6c42                	ld	s8,16(sp)
    80003f9c:	6ca2                	ld	s9,8(sp)
    80003f9e:	6125                	addi	sp,sp,96
    80003fa0:	8082                	ret

0000000080003fa2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003fa2:	7179                	addi	sp,sp,-48
    80003fa4:	f406                	sd	ra,40(sp)
    80003fa6:	f022                	sd	s0,32(sp)
    80003fa8:	ec26                	sd	s1,24(sp)
    80003faa:	e84a                	sd	s2,16(sp)
    80003fac:	e44e                	sd	s3,8(sp)
    80003fae:	e052                	sd	s4,0(sp)
    80003fb0:	1800                	addi	s0,sp,48
    80003fb2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003fb4:	47ad                	li	a5,11
    80003fb6:	04b7fe63          	bgeu	a5,a1,80004012 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003fba:	ff45849b          	addiw	s1,a1,-12
    80003fbe:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003fc2:	0ff00793          	li	a5,255
    80003fc6:	0ae7e363          	bltu	a5,a4,8000406c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003fca:	08052583          	lw	a1,128(a0)
    80003fce:	c5ad                	beqz	a1,80004038 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003fd0:	00092503          	lw	a0,0(s2)
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	bda080e7          	jalr	-1062(ra) # 80003bae <bread>
    80003fdc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003fde:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003fe2:	02049593          	slli	a1,s1,0x20
    80003fe6:	9181                	srli	a1,a1,0x20
    80003fe8:	058a                	slli	a1,a1,0x2
    80003fea:	00b784b3          	add	s1,a5,a1
    80003fee:	0004a983          	lw	s3,0(s1)
    80003ff2:	04098d63          	beqz	s3,8000404c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003ff6:	8552                	mv	a0,s4
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	ce6080e7          	jalr	-794(ra) # 80003cde <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004000:	854e                	mv	a0,s3
    80004002:	70a2                	ld	ra,40(sp)
    80004004:	7402                	ld	s0,32(sp)
    80004006:	64e2                	ld	s1,24(sp)
    80004008:	6942                	ld	s2,16(sp)
    8000400a:	69a2                	ld	s3,8(sp)
    8000400c:	6a02                	ld	s4,0(sp)
    8000400e:	6145                	addi	sp,sp,48
    80004010:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80004012:	02059493          	slli	s1,a1,0x20
    80004016:	9081                	srli	s1,s1,0x20
    80004018:	048a                	slli	s1,s1,0x2
    8000401a:	94aa                	add	s1,s1,a0
    8000401c:	0504a983          	lw	s3,80(s1)
    80004020:	fe0990e3          	bnez	s3,80004000 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80004024:	4108                	lw	a0,0(a0)
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	e4a080e7          	jalr	-438(ra) # 80003e70 <balloc>
    8000402e:	0005099b          	sext.w	s3,a0
    80004032:	0534a823          	sw	s3,80(s1)
    80004036:	b7e9                	j	80004000 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80004038:	4108                	lw	a0,0(a0)
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	e36080e7          	jalr	-458(ra) # 80003e70 <balloc>
    80004042:	0005059b          	sext.w	a1,a0
    80004046:	08b92023          	sw	a1,128(s2)
    8000404a:	b759                	j	80003fd0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000404c:	00092503          	lw	a0,0(s2)
    80004050:	00000097          	auipc	ra,0x0
    80004054:	e20080e7          	jalr	-480(ra) # 80003e70 <balloc>
    80004058:	0005099b          	sext.w	s3,a0
    8000405c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80004060:	8552                	mv	a0,s4
    80004062:	00001097          	auipc	ra,0x1
    80004066:	ef8080e7          	jalr	-264(ra) # 80004f5a <log_write>
    8000406a:	b771                	j	80003ff6 <bmap+0x54>
  panic("bmap: out of range");
    8000406c:	00004517          	auipc	a0,0x4
    80004070:	69450513          	addi	a0,a0,1684 # 80008700 <syscalls+0x128>
    80004074:	ffffc097          	auipc	ra,0xffffc
    80004078:	4ca080e7          	jalr	1226(ra) # 8000053e <panic>

000000008000407c <iget>:
{
    8000407c:	7179                	addi	sp,sp,-48
    8000407e:	f406                	sd	ra,40(sp)
    80004080:	f022                	sd	s0,32(sp)
    80004082:	ec26                	sd	s1,24(sp)
    80004084:	e84a                	sd	s2,16(sp)
    80004086:	e44e                	sd	s3,8(sp)
    80004088:	e052                	sd	s4,0(sp)
    8000408a:	1800                	addi	s0,sp,48
    8000408c:	89aa                	mv	s3,a0
    8000408e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004090:	0001c517          	auipc	a0,0x1c
    80004094:	04850513          	addi	a0,a0,72 # 800200d8 <itable>
    80004098:	ffffd097          	auipc	ra,0xffffd
    8000409c:	b54080e7          	jalr	-1196(ra) # 80000bec <acquire>
  empty = 0;
    800040a0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800040a2:	0001c497          	auipc	s1,0x1c
    800040a6:	04e48493          	addi	s1,s1,78 # 800200f0 <itable+0x18>
    800040aa:	0001e697          	auipc	a3,0x1e
    800040ae:	ad668693          	addi	a3,a3,-1322 # 80021b80 <log>
    800040b2:	a039                	j	800040c0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800040b4:	02090b63          	beqz	s2,800040ea <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800040b8:	08848493          	addi	s1,s1,136
    800040bc:	02d48a63          	beq	s1,a3,800040f0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800040c0:	449c                	lw	a5,8(s1)
    800040c2:	fef059e3          	blez	a5,800040b4 <iget+0x38>
    800040c6:	4098                	lw	a4,0(s1)
    800040c8:	ff3716e3          	bne	a4,s3,800040b4 <iget+0x38>
    800040cc:	40d8                	lw	a4,4(s1)
    800040ce:	ff4713e3          	bne	a4,s4,800040b4 <iget+0x38>
      ip->ref++;
    800040d2:	2785                	addiw	a5,a5,1
    800040d4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800040d6:	0001c517          	auipc	a0,0x1c
    800040da:	00250513          	addi	a0,a0,2 # 800200d8 <itable>
    800040de:	ffffd097          	auipc	ra,0xffffd
    800040e2:	bc8080e7          	jalr	-1080(ra) # 80000ca6 <release>
      return ip;
    800040e6:	8926                	mv	s2,s1
    800040e8:	a03d                	j	80004116 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800040ea:	f7f9                	bnez	a5,800040b8 <iget+0x3c>
    800040ec:	8926                	mv	s2,s1
    800040ee:	b7e9                	j	800040b8 <iget+0x3c>
  if(empty == 0)
    800040f0:	02090c63          	beqz	s2,80004128 <iget+0xac>
  ip->dev = dev;
    800040f4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800040f8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800040fc:	4785                	li	a5,1
    800040fe:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004102:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004106:	0001c517          	auipc	a0,0x1c
    8000410a:	fd250513          	addi	a0,a0,-46 # 800200d8 <itable>
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	b98080e7          	jalr	-1128(ra) # 80000ca6 <release>
}
    80004116:	854a                	mv	a0,s2
    80004118:	70a2                	ld	ra,40(sp)
    8000411a:	7402                	ld	s0,32(sp)
    8000411c:	64e2                	ld	s1,24(sp)
    8000411e:	6942                	ld	s2,16(sp)
    80004120:	69a2                	ld	s3,8(sp)
    80004122:	6a02                	ld	s4,0(sp)
    80004124:	6145                	addi	sp,sp,48
    80004126:	8082                	ret
    panic("iget: no inodes");
    80004128:	00004517          	auipc	a0,0x4
    8000412c:	5f050513          	addi	a0,a0,1520 # 80008718 <syscalls+0x140>
    80004130:	ffffc097          	auipc	ra,0xffffc
    80004134:	40e080e7          	jalr	1038(ra) # 8000053e <panic>

0000000080004138 <fsinit>:
fsinit(int dev) {
    80004138:	7179                	addi	sp,sp,-48
    8000413a:	f406                	sd	ra,40(sp)
    8000413c:	f022                	sd	s0,32(sp)
    8000413e:	ec26                	sd	s1,24(sp)
    80004140:	e84a                	sd	s2,16(sp)
    80004142:	e44e                	sd	s3,8(sp)
    80004144:	1800                	addi	s0,sp,48
    80004146:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004148:	4585                	li	a1,1
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	a64080e7          	jalr	-1436(ra) # 80003bae <bread>
    80004152:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004154:	0001c997          	auipc	s3,0x1c
    80004158:	f6498993          	addi	s3,s3,-156 # 800200b8 <sb>
    8000415c:	02000613          	li	a2,32
    80004160:	05850593          	addi	a1,a0,88
    80004164:	854e                	mv	a0,s3
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	be8080e7          	jalr	-1048(ra) # 80000d4e <memmove>
  brelse(bp);
    8000416e:	8526                	mv	a0,s1
    80004170:	00000097          	auipc	ra,0x0
    80004174:	b6e080e7          	jalr	-1170(ra) # 80003cde <brelse>
  if(sb.magic != FSMAGIC)
    80004178:	0009a703          	lw	a4,0(s3)
    8000417c:	102037b7          	lui	a5,0x10203
    80004180:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004184:	02f71263          	bne	a4,a5,800041a8 <fsinit+0x70>
  initlog(dev, &sb);
    80004188:	0001c597          	auipc	a1,0x1c
    8000418c:	f3058593          	addi	a1,a1,-208 # 800200b8 <sb>
    80004190:	854a                	mv	a0,s2
    80004192:	00001097          	auipc	ra,0x1
    80004196:	b4c080e7          	jalr	-1204(ra) # 80004cde <initlog>
}
    8000419a:	70a2                	ld	ra,40(sp)
    8000419c:	7402                	ld	s0,32(sp)
    8000419e:	64e2                	ld	s1,24(sp)
    800041a0:	6942                	ld	s2,16(sp)
    800041a2:	69a2                	ld	s3,8(sp)
    800041a4:	6145                	addi	sp,sp,48
    800041a6:	8082                	ret
    panic("invalid file system");
    800041a8:	00004517          	auipc	a0,0x4
    800041ac:	58050513          	addi	a0,a0,1408 # 80008728 <syscalls+0x150>
    800041b0:	ffffc097          	auipc	ra,0xffffc
    800041b4:	38e080e7          	jalr	910(ra) # 8000053e <panic>

00000000800041b8 <iinit>:
{
    800041b8:	7179                	addi	sp,sp,-48
    800041ba:	f406                	sd	ra,40(sp)
    800041bc:	f022                	sd	s0,32(sp)
    800041be:	ec26                	sd	s1,24(sp)
    800041c0:	e84a                	sd	s2,16(sp)
    800041c2:	e44e                	sd	s3,8(sp)
    800041c4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800041c6:	00004597          	auipc	a1,0x4
    800041ca:	57a58593          	addi	a1,a1,1402 # 80008740 <syscalls+0x168>
    800041ce:	0001c517          	auipc	a0,0x1c
    800041d2:	f0a50513          	addi	a0,a0,-246 # 800200d8 <itable>
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	97e080e7          	jalr	-1666(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800041de:	0001c497          	auipc	s1,0x1c
    800041e2:	f2248493          	addi	s1,s1,-222 # 80020100 <itable+0x28>
    800041e6:	0001e997          	auipc	s3,0x1e
    800041ea:	9aa98993          	addi	s3,s3,-1622 # 80021b90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800041ee:	00004917          	auipc	s2,0x4
    800041f2:	55a90913          	addi	s2,s2,1370 # 80008748 <syscalls+0x170>
    800041f6:	85ca                	mv	a1,s2
    800041f8:	8526                	mv	a0,s1
    800041fa:	00001097          	auipc	ra,0x1
    800041fe:	e46080e7          	jalr	-442(ra) # 80005040 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004202:	08848493          	addi	s1,s1,136
    80004206:	ff3498e3          	bne	s1,s3,800041f6 <iinit+0x3e>
}
    8000420a:	70a2                	ld	ra,40(sp)
    8000420c:	7402                	ld	s0,32(sp)
    8000420e:	64e2                	ld	s1,24(sp)
    80004210:	6942                	ld	s2,16(sp)
    80004212:	69a2                	ld	s3,8(sp)
    80004214:	6145                	addi	sp,sp,48
    80004216:	8082                	ret

0000000080004218 <ialloc>:
{
    80004218:	715d                	addi	sp,sp,-80
    8000421a:	e486                	sd	ra,72(sp)
    8000421c:	e0a2                	sd	s0,64(sp)
    8000421e:	fc26                	sd	s1,56(sp)
    80004220:	f84a                	sd	s2,48(sp)
    80004222:	f44e                	sd	s3,40(sp)
    80004224:	f052                	sd	s4,32(sp)
    80004226:	ec56                	sd	s5,24(sp)
    80004228:	e85a                	sd	s6,16(sp)
    8000422a:	e45e                	sd	s7,8(sp)
    8000422c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000422e:	0001c717          	auipc	a4,0x1c
    80004232:	e9672703          	lw	a4,-362(a4) # 800200c4 <sb+0xc>
    80004236:	4785                	li	a5,1
    80004238:	04e7fa63          	bgeu	a5,a4,8000428c <ialloc+0x74>
    8000423c:	8aaa                	mv	s5,a0
    8000423e:	8bae                	mv	s7,a1
    80004240:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004242:	0001ca17          	auipc	s4,0x1c
    80004246:	e76a0a13          	addi	s4,s4,-394 # 800200b8 <sb>
    8000424a:	00048b1b          	sext.w	s6,s1
    8000424e:	0044d593          	srli	a1,s1,0x4
    80004252:	018a2783          	lw	a5,24(s4)
    80004256:	9dbd                	addw	a1,a1,a5
    80004258:	8556                	mv	a0,s5
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	954080e7          	jalr	-1708(ra) # 80003bae <bread>
    80004262:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004264:	05850993          	addi	s3,a0,88
    80004268:	00f4f793          	andi	a5,s1,15
    8000426c:	079a                	slli	a5,a5,0x6
    8000426e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004270:	00099783          	lh	a5,0(s3)
    80004274:	c785                	beqz	a5,8000429c <ialloc+0x84>
    brelse(bp);
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	a68080e7          	jalr	-1432(ra) # 80003cde <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000427e:	0485                	addi	s1,s1,1
    80004280:	00ca2703          	lw	a4,12(s4)
    80004284:	0004879b          	sext.w	a5,s1
    80004288:	fce7e1e3          	bltu	a5,a4,8000424a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000428c:	00004517          	auipc	a0,0x4
    80004290:	4c450513          	addi	a0,a0,1220 # 80008750 <syscalls+0x178>
    80004294:	ffffc097          	auipc	ra,0xffffc
    80004298:	2aa080e7          	jalr	682(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000429c:	04000613          	li	a2,64
    800042a0:	4581                	li	a1,0
    800042a2:	854e                	mv	a0,s3
    800042a4:	ffffd097          	auipc	ra,0xffffd
    800042a8:	a4a080e7          	jalr	-1462(ra) # 80000cee <memset>
      dip->type = type;
    800042ac:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800042b0:	854a                	mv	a0,s2
    800042b2:	00001097          	auipc	ra,0x1
    800042b6:	ca8080e7          	jalr	-856(ra) # 80004f5a <log_write>
      brelse(bp);
    800042ba:	854a                	mv	a0,s2
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	a22080e7          	jalr	-1502(ra) # 80003cde <brelse>
      return iget(dev, inum);
    800042c4:	85da                	mv	a1,s6
    800042c6:	8556                	mv	a0,s5
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	db4080e7          	jalr	-588(ra) # 8000407c <iget>
}
    800042d0:	60a6                	ld	ra,72(sp)
    800042d2:	6406                	ld	s0,64(sp)
    800042d4:	74e2                	ld	s1,56(sp)
    800042d6:	7942                	ld	s2,48(sp)
    800042d8:	79a2                	ld	s3,40(sp)
    800042da:	7a02                	ld	s4,32(sp)
    800042dc:	6ae2                	ld	s5,24(sp)
    800042de:	6b42                	ld	s6,16(sp)
    800042e0:	6ba2                	ld	s7,8(sp)
    800042e2:	6161                	addi	sp,sp,80
    800042e4:	8082                	ret

00000000800042e6 <iupdate>:
{
    800042e6:	1101                	addi	sp,sp,-32
    800042e8:	ec06                	sd	ra,24(sp)
    800042ea:	e822                	sd	s0,16(sp)
    800042ec:	e426                	sd	s1,8(sp)
    800042ee:	e04a                	sd	s2,0(sp)
    800042f0:	1000                	addi	s0,sp,32
    800042f2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042f4:	415c                	lw	a5,4(a0)
    800042f6:	0047d79b          	srliw	a5,a5,0x4
    800042fa:	0001c597          	auipc	a1,0x1c
    800042fe:	dd65a583          	lw	a1,-554(a1) # 800200d0 <sb+0x18>
    80004302:	9dbd                	addw	a1,a1,a5
    80004304:	4108                	lw	a0,0(a0)
    80004306:	00000097          	auipc	ra,0x0
    8000430a:	8a8080e7          	jalr	-1880(ra) # 80003bae <bread>
    8000430e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004310:	05850793          	addi	a5,a0,88
    80004314:	40c8                	lw	a0,4(s1)
    80004316:	893d                	andi	a0,a0,15
    80004318:	051a                	slli	a0,a0,0x6
    8000431a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000431c:	04449703          	lh	a4,68(s1)
    80004320:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004324:	04649703          	lh	a4,70(s1)
    80004328:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000432c:	04849703          	lh	a4,72(s1)
    80004330:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004334:	04a49703          	lh	a4,74(s1)
    80004338:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000433c:	44f8                	lw	a4,76(s1)
    8000433e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004340:	03400613          	li	a2,52
    80004344:	05048593          	addi	a1,s1,80
    80004348:	0531                	addi	a0,a0,12
    8000434a:	ffffd097          	auipc	ra,0xffffd
    8000434e:	a04080e7          	jalr	-1532(ra) # 80000d4e <memmove>
  log_write(bp);
    80004352:	854a                	mv	a0,s2
    80004354:	00001097          	auipc	ra,0x1
    80004358:	c06080e7          	jalr	-1018(ra) # 80004f5a <log_write>
  brelse(bp);
    8000435c:	854a                	mv	a0,s2
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	980080e7          	jalr	-1664(ra) # 80003cde <brelse>
}
    80004366:	60e2                	ld	ra,24(sp)
    80004368:	6442                	ld	s0,16(sp)
    8000436a:	64a2                	ld	s1,8(sp)
    8000436c:	6902                	ld	s2,0(sp)
    8000436e:	6105                	addi	sp,sp,32
    80004370:	8082                	ret

0000000080004372 <idup>:
{
    80004372:	1101                	addi	sp,sp,-32
    80004374:	ec06                	sd	ra,24(sp)
    80004376:	e822                	sd	s0,16(sp)
    80004378:	e426                	sd	s1,8(sp)
    8000437a:	1000                	addi	s0,sp,32
    8000437c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000437e:	0001c517          	auipc	a0,0x1c
    80004382:	d5a50513          	addi	a0,a0,-678 # 800200d8 <itable>
    80004386:	ffffd097          	auipc	ra,0xffffd
    8000438a:	866080e7          	jalr	-1946(ra) # 80000bec <acquire>
  ip->ref++;
    8000438e:	449c                	lw	a5,8(s1)
    80004390:	2785                	addiw	a5,a5,1
    80004392:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004394:	0001c517          	auipc	a0,0x1c
    80004398:	d4450513          	addi	a0,a0,-700 # 800200d8 <itable>
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	90a080e7          	jalr	-1782(ra) # 80000ca6 <release>
}
    800043a4:	8526                	mv	a0,s1
    800043a6:	60e2                	ld	ra,24(sp)
    800043a8:	6442                	ld	s0,16(sp)
    800043aa:	64a2                	ld	s1,8(sp)
    800043ac:	6105                	addi	sp,sp,32
    800043ae:	8082                	ret

00000000800043b0 <ilock>:
{
    800043b0:	1101                	addi	sp,sp,-32
    800043b2:	ec06                	sd	ra,24(sp)
    800043b4:	e822                	sd	s0,16(sp)
    800043b6:	e426                	sd	s1,8(sp)
    800043b8:	e04a                	sd	s2,0(sp)
    800043ba:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800043bc:	c115                	beqz	a0,800043e0 <ilock+0x30>
    800043be:	84aa                	mv	s1,a0
    800043c0:	451c                	lw	a5,8(a0)
    800043c2:	00f05f63          	blez	a5,800043e0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800043c6:	0541                	addi	a0,a0,16
    800043c8:	00001097          	auipc	ra,0x1
    800043cc:	cb2080e7          	jalr	-846(ra) # 8000507a <acquiresleep>
  if(ip->valid == 0){
    800043d0:	40bc                	lw	a5,64(s1)
    800043d2:	cf99                	beqz	a5,800043f0 <ilock+0x40>
}
    800043d4:	60e2                	ld	ra,24(sp)
    800043d6:	6442                	ld	s0,16(sp)
    800043d8:	64a2                	ld	s1,8(sp)
    800043da:	6902                	ld	s2,0(sp)
    800043dc:	6105                	addi	sp,sp,32
    800043de:	8082                	ret
    panic("ilock");
    800043e0:	00004517          	auipc	a0,0x4
    800043e4:	38850513          	addi	a0,a0,904 # 80008768 <syscalls+0x190>
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	156080e7          	jalr	342(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800043f0:	40dc                	lw	a5,4(s1)
    800043f2:	0047d79b          	srliw	a5,a5,0x4
    800043f6:	0001c597          	auipc	a1,0x1c
    800043fa:	cda5a583          	lw	a1,-806(a1) # 800200d0 <sb+0x18>
    800043fe:	9dbd                	addw	a1,a1,a5
    80004400:	4088                	lw	a0,0(s1)
    80004402:	fffff097          	auipc	ra,0xfffff
    80004406:	7ac080e7          	jalr	1964(ra) # 80003bae <bread>
    8000440a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000440c:	05850593          	addi	a1,a0,88
    80004410:	40dc                	lw	a5,4(s1)
    80004412:	8bbd                	andi	a5,a5,15
    80004414:	079a                	slli	a5,a5,0x6
    80004416:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004418:	00059783          	lh	a5,0(a1)
    8000441c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004420:	00259783          	lh	a5,2(a1)
    80004424:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004428:	00459783          	lh	a5,4(a1)
    8000442c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004430:	00659783          	lh	a5,6(a1)
    80004434:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004438:	459c                	lw	a5,8(a1)
    8000443a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000443c:	03400613          	li	a2,52
    80004440:	05b1                	addi	a1,a1,12
    80004442:	05048513          	addi	a0,s1,80
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	908080e7          	jalr	-1784(ra) # 80000d4e <memmove>
    brelse(bp);
    8000444e:	854a                	mv	a0,s2
    80004450:	00000097          	auipc	ra,0x0
    80004454:	88e080e7          	jalr	-1906(ra) # 80003cde <brelse>
    ip->valid = 1;
    80004458:	4785                	li	a5,1
    8000445a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000445c:	04449783          	lh	a5,68(s1)
    80004460:	fbb5                	bnez	a5,800043d4 <ilock+0x24>
      panic("ilock: no type");
    80004462:	00004517          	auipc	a0,0x4
    80004466:	30e50513          	addi	a0,a0,782 # 80008770 <syscalls+0x198>
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	0d4080e7          	jalr	212(ra) # 8000053e <panic>

0000000080004472 <iunlock>:
{
    80004472:	1101                	addi	sp,sp,-32
    80004474:	ec06                	sd	ra,24(sp)
    80004476:	e822                	sd	s0,16(sp)
    80004478:	e426                	sd	s1,8(sp)
    8000447a:	e04a                	sd	s2,0(sp)
    8000447c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000447e:	c905                	beqz	a0,800044ae <iunlock+0x3c>
    80004480:	84aa                	mv	s1,a0
    80004482:	01050913          	addi	s2,a0,16
    80004486:	854a                	mv	a0,s2
    80004488:	00001097          	auipc	ra,0x1
    8000448c:	c8c080e7          	jalr	-884(ra) # 80005114 <holdingsleep>
    80004490:	cd19                	beqz	a0,800044ae <iunlock+0x3c>
    80004492:	449c                	lw	a5,8(s1)
    80004494:	00f05d63          	blez	a5,800044ae <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004498:	854a                	mv	a0,s2
    8000449a:	00001097          	auipc	ra,0x1
    8000449e:	c36080e7          	jalr	-970(ra) # 800050d0 <releasesleep>
}
    800044a2:	60e2                	ld	ra,24(sp)
    800044a4:	6442                	ld	s0,16(sp)
    800044a6:	64a2                	ld	s1,8(sp)
    800044a8:	6902                	ld	s2,0(sp)
    800044aa:	6105                	addi	sp,sp,32
    800044ac:	8082                	ret
    panic("iunlock");
    800044ae:	00004517          	auipc	a0,0x4
    800044b2:	2d250513          	addi	a0,a0,722 # 80008780 <syscalls+0x1a8>
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	088080e7          	jalr	136(ra) # 8000053e <panic>

00000000800044be <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800044be:	7179                	addi	sp,sp,-48
    800044c0:	f406                	sd	ra,40(sp)
    800044c2:	f022                	sd	s0,32(sp)
    800044c4:	ec26                	sd	s1,24(sp)
    800044c6:	e84a                	sd	s2,16(sp)
    800044c8:	e44e                	sd	s3,8(sp)
    800044ca:	e052                	sd	s4,0(sp)
    800044cc:	1800                	addi	s0,sp,48
    800044ce:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800044d0:	05050493          	addi	s1,a0,80
    800044d4:	08050913          	addi	s2,a0,128
    800044d8:	a021                	j	800044e0 <itrunc+0x22>
    800044da:	0491                	addi	s1,s1,4
    800044dc:	01248d63          	beq	s1,s2,800044f6 <itrunc+0x38>
    if(ip->addrs[i]){
    800044e0:	408c                	lw	a1,0(s1)
    800044e2:	dde5                	beqz	a1,800044da <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800044e4:	0009a503          	lw	a0,0(s3)
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	90c080e7          	jalr	-1780(ra) # 80003df4 <bfree>
      ip->addrs[i] = 0;
    800044f0:	0004a023          	sw	zero,0(s1)
    800044f4:	b7dd                	j	800044da <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800044f6:	0809a583          	lw	a1,128(s3)
    800044fa:	e185                	bnez	a1,8000451a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800044fc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004500:	854e                	mv	a0,s3
    80004502:	00000097          	auipc	ra,0x0
    80004506:	de4080e7          	jalr	-540(ra) # 800042e6 <iupdate>
}
    8000450a:	70a2                	ld	ra,40(sp)
    8000450c:	7402                	ld	s0,32(sp)
    8000450e:	64e2                	ld	s1,24(sp)
    80004510:	6942                	ld	s2,16(sp)
    80004512:	69a2                	ld	s3,8(sp)
    80004514:	6a02                	ld	s4,0(sp)
    80004516:	6145                	addi	sp,sp,48
    80004518:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000451a:	0009a503          	lw	a0,0(s3)
    8000451e:	fffff097          	auipc	ra,0xfffff
    80004522:	690080e7          	jalr	1680(ra) # 80003bae <bread>
    80004526:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004528:	05850493          	addi	s1,a0,88
    8000452c:	45850913          	addi	s2,a0,1112
    80004530:	a811                	j	80004544 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004532:	0009a503          	lw	a0,0(s3)
    80004536:	00000097          	auipc	ra,0x0
    8000453a:	8be080e7          	jalr	-1858(ra) # 80003df4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000453e:	0491                	addi	s1,s1,4
    80004540:	01248563          	beq	s1,s2,8000454a <itrunc+0x8c>
      if(a[j])
    80004544:	408c                	lw	a1,0(s1)
    80004546:	dde5                	beqz	a1,8000453e <itrunc+0x80>
    80004548:	b7ed                	j	80004532 <itrunc+0x74>
    brelse(bp);
    8000454a:	8552                	mv	a0,s4
    8000454c:	fffff097          	auipc	ra,0xfffff
    80004550:	792080e7          	jalr	1938(ra) # 80003cde <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004554:	0809a583          	lw	a1,128(s3)
    80004558:	0009a503          	lw	a0,0(s3)
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	898080e7          	jalr	-1896(ra) # 80003df4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004564:	0809a023          	sw	zero,128(s3)
    80004568:	bf51                	j	800044fc <itrunc+0x3e>

000000008000456a <iput>:
{
    8000456a:	1101                	addi	sp,sp,-32
    8000456c:	ec06                	sd	ra,24(sp)
    8000456e:	e822                	sd	s0,16(sp)
    80004570:	e426                	sd	s1,8(sp)
    80004572:	e04a                	sd	s2,0(sp)
    80004574:	1000                	addi	s0,sp,32
    80004576:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004578:	0001c517          	auipc	a0,0x1c
    8000457c:	b6050513          	addi	a0,a0,-1184 # 800200d8 <itable>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	66c080e7          	jalr	1644(ra) # 80000bec <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004588:	4498                	lw	a4,8(s1)
    8000458a:	4785                	li	a5,1
    8000458c:	02f70363          	beq	a4,a5,800045b2 <iput+0x48>
  ip->ref--;
    80004590:	449c                	lw	a5,8(s1)
    80004592:	37fd                	addiw	a5,a5,-1
    80004594:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004596:	0001c517          	auipc	a0,0x1c
    8000459a:	b4250513          	addi	a0,a0,-1214 # 800200d8 <itable>
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	708080e7          	jalr	1800(ra) # 80000ca6 <release>
}
    800045a6:	60e2                	ld	ra,24(sp)
    800045a8:	6442                	ld	s0,16(sp)
    800045aa:	64a2                	ld	s1,8(sp)
    800045ac:	6902                	ld	s2,0(sp)
    800045ae:	6105                	addi	sp,sp,32
    800045b0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800045b2:	40bc                	lw	a5,64(s1)
    800045b4:	dff1                	beqz	a5,80004590 <iput+0x26>
    800045b6:	04a49783          	lh	a5,74(s1)
    800045ba:	fbf9                	bnez	a5,80004590 <iput+0x26>
    acquiresleep(&ip->lock);
    800045bc:	01048913          	addi	s2,s1,16
    800045c0:	854a                	mv	a0,s2
    800045c2:	00001097          	auipc	ra,0x1
    800045c6:	ab8080e7          	jalr	-1352(ra) # 8000507a <acquiresleep>
    release(&itable.lock);
    800045ca:	0001c517          	auipc	a0,0x1c
    800045ce:	b0e50513          	addi	a0,a0,-1266 # 800200d8 <itable>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	6d4080e7          	jalr	1748(ra) # 80000ca6 <release>
    itrunc(ip);
    800045da:	8526                	mv	a0,s1
    800045dc:	00000097          	auipc	ra,0x0
    800045e0:	ee2080e7          	jalr	-286(ra) # 800044be <itrunc>
    ip->type = 0;
    800045e4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800045e8:	8526                	mv	a0,s1
    800045ea:	00000097          	auipc	ra,0x0
    800045ee:	cfc080e7          	jalr	-772(ra) # 800042e6 <iupdate>
    ip->valid = 0;
    800045f2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800045f6:	854a                	mv	a0,s2
    800045f8:	00001097          	auipc	ra,0x1
    800045fc:	ad8080e7          	jalr	-1320(ra) # 800050d0 <releasesleep>
    acquire(&itable.lock);
    80004600:	0001c517          	auipc	a0,0x1c
    80004604:	ad850513          	addi	a0,a0,-1320 # 800200d8 <itable>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	5e4080e7          	jalr	1508(ra) # 80000bec <acquire>
    80004610:	b741                	j	80004590 <iput+0x26>

0000000080004612 <iunlockput>:
{
    80004612:	1101                	addi	sp,sp,-32
    80004614:	ec06                	sd	ra,24(sp)
    80004616:	e822                	sd	s0,16(sp)
    80004618:	e426                	sd	s1,8(sp)
    8000461a:	1000                	addi	s0,sp,32
    8000461c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	e54080e7          	jalr	-428(ra) # 80004472 <iunlock>
  iput(ip);
    80004626:	8526                	mv	a0,s1
    80004628:	00000097          	auipc	ra,0x0
    8000462c:	f42080e7          	jalr	-190(ra) # 8000456a <iput>
}
    80004630:	60e2                	ld	ra,24(sp)
    80004632:	6442                	ld	s0,16(sp)
    80004634:	64a2                	ld	s1,8(sp)
    80004636:	6105                	addi	sp,sp,32
    80004638:	8082                	ret

000000008000463a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000463a:	1141                	addi	sp,sp,-16
    8000463c:	e422                	sd	s0,8(sp)
    8000463e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004640:	411c                	lw	a5,0(a0)
    80004642:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004644:	415c                	lw	a5,4(a0)
    80004646:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004648:	04451783          	lh	a5,68(a0)
    8000464c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004650:	04a51783          	lh	a5,74(a0)
    80004654:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004658:	04c56783          	lwu	a5,76(a0)
    8000465c:	e99c                	sd	a5,16(a1)
}
    8000465e:	6422                	ld	s0,8(sp)
    80004660:	0141                	addi	sp,sp,16
    80004662:	8082                	ret

0000000080004664 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004664:	457c                	lw	a5,76(a0)
    80004666:	0ed7e963          	bltu	a5,a3,80004758 <readi+0xf4>
{
    8000466a:	7159                	addi	sp,sp,-112
    8000466c:	f486                	sd	ra,104(sp)
    8000466e:	f0a2                	sd	s0,96(sp)
    80004670:	eca6                	sd	s1,88(sp)
    80004672:	e8ca                	sd	s2,80(sp)
    80004674:	e4ce                	sd	s3,72(sp)
    80004676:	e0d2                	sd	s4,64(sp)
    80004678:	fc56                	sd	s5,56(sp)
    8000467a:	f85a                	sd	s6,48(sp)
    8000467c:	f45e                	sd	s7,40(sp)
    8000467e:	f062                	sd	s8,32(sp)
    80004680:	ec66                	sd	s9,24(sp)
    80004682:	e86a                	sd	s10,16(sp)
    80004684:	e46e                	sd	s11,8(sp)
    80004686:	1880                	addi	s0,sp,112
    80004688:	8baa                	mv	s7,a0
    8000468a:	8c2e                	mv	s8,a1
    8000468c:	8ab2                	mv	s5,a2
    8000468e:	84b6                	mv	s1,a3
    80004690:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004692:	9f35                	addw	a4,a4,a3
    return 0;
    80004694:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004696:	0ad76063          	bltu	a4,a3,80004736 <readi+0xd2>
  if(off + n > ip->size)
    8000469a:	00e7f463          	bgeu	a5,a4,800046a2 <readi+0x3e>
    n = ip->size - off;
    8000469e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800046a2:	0a0b0963          	beqz	s6,80004754 <readi+0xf0>
    800046a6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800046a8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800046ac:	5cfd                	li	s9,-1
    800046ae:	a82d                	j	800046e8 <readi+0x84>
    800046b0:	020a1d93          	slli	s11,s4,0x20
    800046b4:	020ddd93          	srli	s11,s11,0x20
    800046b8:	05890613          	addi	a2,s2,88
    800046bc:	86ee                	mv	a3,s11
    800046be:	963a                	add	a2,a2,a4
    800046c0:	85d6                	mv	a1,s5
    800046c2:	8562                	mv	a0,s8
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	ae4080e7          	jalr	-1308(ra) # 800031a8 <either_copyout>
    800046cc:	05950d63          	beq	a0,s9,80004726 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800046d0:	854a                	mv	a0,s2
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	60c080e7          	jalr	1548(ra) # 80003cde <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800046da:	013a09bb          	addw	s3,s4,s3
    800046de:	009a04bb          	addw	s1,s4,s1
    800046e2:	9aee                	add	s5,s5,s11
    800046e4:	0569f763          	bgeu	s3,s6,80004732 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800046e8:	000ba903          	lw	s2,0(s7)
    800046ec:	00a4d59b          	srliw	a1,s1,0xa
    800046f0:	855e                	mv	a0,s7
    800046f2:	00000097          	auipc	ra,0x0
    800046f6:	8b0080e7          	jalr	-1872(ra) # 80003fa2 <bmap>
    800046fa:	0005059b          	sext.w	a1,a0
    800046fe:	854a                	mv	a0,s2
    80004700:	fffff097          	auipc	ra,0xfffff
    80004704:	4ae080e7          	jalr	1198(ra) # 80003bae <bread>
    80004708:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000470a:	3ff4f713          	andi	a4,s1,1023
    8000470e:	40ed07bb          	subw	a5,s10,a4
    80004712:	413b06bb          	subw	a3,s6,s3
    80004716:	8a3e                	mv	s4,a5
    80004718:	2781                	sext.w	a5,a5
    8000471a:	0006861b          	sext.w	a2,a3
    8000471e:	f8f679e3          	bgeu	a2,a5,800046b0 <readi+0x4c>
    80004722:	8a36                	mv	s4,a3
    80004724:	b771                	j	800046b0 <readi+0x4c>
      brelse(bp);
    80004726:	854a                	mv	a0,s2
    80004728:	fffff097          	auipc	ra,0xfffff
    8000472c:	5b6080e7          	jalr	1462(ra) # 80003cde <brelse>
      tot = -1;
    80004730:	59fd                	li	s3,-1
  }
  return tot;
    80004732:	0009851b          	sext.w	a0,s3
}
    80004736:	70a6                	ld	ra,104(sp)
    80004738:	7406                	ld	s0,96(sp)
    8000473a:	64e6                	ld	s1,88(sp)
    8000473c:	6946                	ld	s2,80(sp)
    8000473e:	69a6                	ld	s3,72(sp)
    80004740:	6a06                	ld	s4,64(sp)
    80004742:	7ae2                	ld	s5,56(sp)
    80004744:	7b42                	ld	s6,48(sp)
    80004746:	7ba2                	ld	s7,40(sp)
    80004748:	7c02                	ld	s8,32(sp)
    8000474a:	6ce2                	ld	s9,24(sp)
    8000474c:	6d42                	ld	s10,16(sp)
    8000474e:	6da2                	ld	s11,8(sp)
    80004750:	6165                	addi	sp,sp,112
    80004752:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004754:	89da                	mv	s3,s6
    80004756:	bff1                	j	80004732 <readi+0xce>
    return 0;
    80004758:	4501                	li	a0,0
}
    8000475a:	8082                	ret

000000008000475c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000475c:	457c                	lw	a5,76(a0)
    8000475e:	10d7e863          	bltu	a5,a3,8000486e <writei+0x112>
{
    80004762:	7159                	addi	sp,sp,-112
    80004764:	f486                	sd	ra,104(sp)
    80004766:	f0a2                	sd	s0,96(sp)
    80004768:	eca6                	sd	s1,88(sp)
    8000476a:	e8ca                	sd	s2,80(sp)
    8000476c:	e4ce                	sd	s3,72(sp)
    8000476e:	e0d2                	sd	s4,64(sp)
    80004770:	fc56                	sd	s5,56(sp)
    80004772:	f85a                	sd	s6,48(sp)
    80004774:	f45e                	sd	s7,40(sp)
    80004776:	f062                	sd	s8,32(sp)
    80004778:	ec66                	sd	s9,24(sp)
    8000477a:	e86a                	sd	s10,16(sp)
    8000477c:	e46e                	sd	s11,8(sp)
    8000477e:	1880                	addi	s0,sp,112
    80004780:	8b2a                	mv	s6,a0
    80004782:	8c2e                	mv	s8,a1
    80004784:	8ab2                	mv	s5,a2
    80004786:	8936                	mv	s2,a3
    80004788:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000478a:	00e687bb          	addw	a5,a3,a4
    8000478e:	0ed7e263          	bltu	a5,a3,80004872 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004792:	00043737          	lui	a4,0x43
    80004796:	0ef76063          	bltu	a4,a5,80004876 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000479a:	0c0b8863          	beqz	s7,8000486a <writei+0x10e>
    8000479e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800047a0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800047a4:	5cfd                	li	s9,-1
    800047a6:	a091                	j	800047ea <writei+0x8e>
    800047a8:	02099d93          	slli	s11,s3,0x20
    800047ac:	020ddd93          	srli	s11,s11,0x20
    800047b0:	05848513          	addi	a0,s1,88
    800047b4:	86ee                	mv	a3,s11
    800047b6:	8656                	mv	a2,s5
    800047b8:	85e2                	mv	a1,s8
    800047ba:	953a                	add	a0,a0,a4
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	a42080e7          	jalr	-1470(ra) # 800031fe <either_copyin>
    800047c4:	07950263          	beq	a0,s9,80004828 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800047c8:	8526                	mv	a0,s1
    800047ca:	00000097          	auipc	ra,0x0
    800047ce:	790080e7          	jalr	1936(ra) # 80004f5a <log_write>
    brelse(bp);
    800047d2:	8526                	mv	a0,s1
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	50a080e7          	jalr	1290(ra) # 80003cde <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800047dc:	01498a3b          	addw	s4,s3,s4
    800047e0:	0129893b          	addw	s2,s3,s2
    800047e4:	9aee                	add	s5,s5,s11
    800047e6:	057a7663          	bgeu	s4,s7,80004832 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800047ea:	000b2483          	lw	s1,0(s6)
    800047ee:	00a9559b          	srliw	a1,s2,0xa
    800047f2:	855a                	mv	a0,s6
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	7ae080e7          	jalr	1966(ra) # 80003fa2 <bmap>
    800047fc:	0005059b          	sext.w	a1,a0
    80004800:	8526                	mv	a0,s1
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	3ac080e7          	jalr	940(ra) # 80003bae <bread>
    8000480a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000480c:	3ff97713          	andi	a4,s2,1023
    80004810:	40ed07bb          	subw	a5,s10,a4
    80004814:	414b86bb          	subw	a3,s7,s4
    80004818:	89be                	mv	s3,a5
    8000481a:	2781                	sext.w	a5,a5
    8000481c:	0006861b          	sext.w	a2,a3
    80004820:	f8f674e3          	bgeu	a2,a5,800047a8 <writei+0x4c>
    80004824:	89b6                	mv	s3,a3
    80004826:	b749                	j	800047a8 <writei+0x4c>
      brelse(bp);
    80004828:	8526                	mv	a0,s1
    8000482a:	fffff097          	auipc	ra,0xfffff
    8000482e:	4b4080e7          	jalr	1204(ra) # 80003cde <brelse>
  }

  if(off > ip->size)
    80004832:	04cb2783          	lw	a5,76(s6)
    80004836:	0127f463          	bgeu	a5,s2,8000483e <writei+0xe2>
    ip->size = off;
    8000483a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000483e:	855a                	mv	a0,s6
    80004840:	00000097          	auipc	ra,0x0
    80004844:	aa6080e7          	jalr	-1370(ra) # 800042e6 <iupdate>

  return tot;
    80004848:	000a051b          	sext.w	a0,s4
}
    8000484c:	70a6                	ld	ra,104(sp)
    8000484e:	7406                	ld	s0,96(sp)
    80004850:	64e6                	ld	s1,88(sp)
    80004852:	6946                	ld	s2,80(sp)
    80004854:	69a6                	ld	s3,72(sp)
    80004856:	6a06                	ld	s4,64(sp)
    80004858:	7ae2                	ld	s5,56(sp)
    8000485a:	7b42                	ld	s6,48(sp)
    8000485c:	7ba2                	ld	s7,40(sp)
    8000485e:	7c02                	ld	s8,32(sp)
    80004860:	6ce2                	ld	s9,24(sp)
    80004862:	6d42                	ld	s10,16(sp)
    80004864:	6da2                	ld	s11,8(sp)
    80004866:	6165                	addi	sp,sp,112
    80004868:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000486a:	8a5e                	mv	s4,s7
    8000486c:	bfc9                	j	8000483e <writei+0xe2>
    return -1;
    8000486e:	557d                	li	a0,-1
}
    80004870:	8082                	ret
    return -1;
    80004872:	557d                	li	a0,-1
    80004874:	bfe1                	j	8000484c <writei+0xf0>
    return -1;
    80004876:	557d                	li	a0,-1
    80004878:	bfd1                	j	8000484c <writei+0xf0>

000000008000487a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000487a:	1141                	addi	sp,sp,-16
    8000487c:	e406                	sd	ra,8(sp)
    8000487e:	e022                	sd	s0,0(sp)
    80004880:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004882:	4639                	li	a2,14
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	542080e7          	jalr	1346(ra) # 80000dc6 <strncmp>
}
    8000488c:	60a2                	ld	ra,8(sp)
    8000488e:	6402                	ld	s0,0(sp)
    80004890:	0141                	addi	sp,sp,16
    80004892:	8082                	ret

0000000080004894 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004894:	7139                	addi	sp,sp,-64
    80004896:	fc06                	sd	ra,56(sp)
    80004898:	f822                	sd	s0,48(sp)
    8000489a:	f426                	sd	s1,40(sp)
    8000489c:	f04a                	sd	s2,32(sp)
    8000489e:	ec4e                	sd	s3,24(sp)
    800048a0:	e852                	sd	s4,16(sp)
    800048a2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800048a4:	04451703          	lh	a4,68(a0)
    800048a8:	4785                	li	a5,1
    800048aa:	00f71a63          	bne	a4,a5,800048be <dirlookup+0x2a>
    800048ae:	892a                	mv	s2,a0
    800048b0:	89ae                	mv	s3,a1
    800048b2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800048b4:	457c                	lw	a5,76(a0)
    800048b6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800048b8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048ba:	e79d                	bnez	a5,800048e8 <dirlookup+0x54>
    800048bc:	a8a5                	j	80004934 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800048be:	00004517          	auipc	a0,0x4
    800048c2:	eca50513          	addi	a0,a0,-310 # 80008788 <syscalls+0x1b0>
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	c78080e7          	jalr	-904(ra) # 8000053e <panic>
      panic("dirlookup read");
    800048ce:	00004517          	auipc	a0,0x4
    800048d2:	ed250513          	addi	a0,a0,-302 # 800087a0 <syscalls+0x1c8>
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	c68080e7          	jalr	-920(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800048de:	24c1                	addiw	s1,s1,16
    800048e0:	04c92783          	lw	a5,76(s2)
    800048e4:	04f4f763          	bgeu	s1,a5,80004932 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800048e8:	4741                	li	a4,16
    800048ea:	86a6                	mv	a3,s1
    800048ec:	fc040613          	addi	a2,s0,-64
    800048f0:	4581                	li	a1,0
    800048f2:	854a                	mv	a0,s2
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	d70080e7          	jalr	-656(ra) # 80004664 <readi>
    800048fc:	47c1                	li	a5,16
    800048fe:	fcf518e3          	bne	a0,a5,800048ce <dirlookup+0x3a>
    if(de.inum == 0)
    80004902:	fc045783          	lhu	a5,-64(s0)
    80004906:	dfe1                	beqz	a5,800048de <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004908:	fc240593          	addi	a1,s0,-62
    8000490c:	854e                	mv	a0,s3
    8000490e:	00000097          	auipc	ra,0x0
    80004912:	f6c080e7          	jalr	-148(ra) # 8000487a <namecmp>
    80004916:	f561                	bnez	a0,800048de <dirlookup+0x4a>
      if(poff)
    80004918:	000a0463          	beqz	s4,80004920 <dirlookup+0x8c>
        *poff = off;
    8000491c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004920:	fc045583          	lhu	a1,-64(s0)
    80004924:	00092503          	lw	a0,0(s2)
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	754080e7          	jalr	1876(ra) # 8000407c <iget>
    80004930:	a011                	j	80004934 <dirlookup+0xa0>
  return 0;
    80004932:	4501                	li	a0,0
}
    80004934:	70e2                	ld	ra,56(sp)
    80004936:	7442                	ld	s0,48(sp)
    80004938:	74a2                	ld	s1,40(sp)
    8000493a:	7902                	ld	s2,32(sp)
    8000493c:	69e2                	ld	s3,24(sp)
    8000493e:	6a42                	ld	s4,16(sp)
    80004940:	6121                	addi	sp,sp,64
    80004942:	8082                	ret

0000000080004944 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004944:	711d                	addi	sp,sp,-96
    80004946:	ec86                	sd	ra,88(sp)
    80004948:	e8a2                	sd	s0,80(sp)
    8000494a:	e4a6                	sd	s1,72(sp)
    8000494c:	e0ca                	sd	s2,64(sp)
    8000494e:	fc4e                	sd	s3,56(sp)
    80004950:	f852                	sd	s4,48(sp)
    80004952:	f456                	sd	s5,40(sp)
    80004954:	f05a                	sd	s6,32(sp)
    80004956:	ec5e                	sd	s7,24(sp)
    80004958:	e862                	sd	s8,16(sp)
    8000495a:	e466                	sd	s9,8(sp)
    8000495c:	1080                	addi	s0,sp,96
    8000495e:	84aa                	mv	s1,a0
    80004960:	8b2e                	mv	s6,a1
    80004962:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004964:	00054703          	lbu	a4,0(a0)
    80004968:	02f00793          	li	a5,47
    8000496c:	02f70363          	beq	a4,a5,80004992 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004970:	ffffd097          	auipc	ra,0xffffd
    80004974:	49c080e7          	jalr	1180(ra) # 80001e0c <myproc>
    80004978:	17853503          	ld	a0,376(a0)
    8000497c:	00000097          	auipc	ra,0x0
    80004980:	9f6080e7          	jalr	-1546(ra) # 80004372 <idup>
    80004984:	89aa                	mv	s3,a0
  while(*path == '/')
    80004986:	02f00913          	li	s2,47
  len = path - s;
    8000498a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000498c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000498e:	4c05                	li	s8,1
    80004990:	a865                	j	80004a48 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004992:	4585                	li	a1,1
    80004994:	4505                	li	a0,1
    80004996:	fffff097          	auipc	ra,0xfffff
    8000499a:	6e6080e7          	jalr	1766(ra) # 8000407c <iget>
    8000499e:	89aa                	mv	s3,a0
    800049a0:	b7dd                	j	80004986 <namex+0x42>
      iunlockput(ip);
    800049a2:	854e                	mv	a0,s3
    800049a4:	00000097          	auipc	ra,0x0
    800049a8:	c6e080e7          	jalr	-914(ra) # 80004612 <iunlockput>
      return 0;
    800049ac:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800049ae:	854e                	mv	a0,s3
    800049b0:	60e6                	ld	ra,88(sp)
    800049b2:	6446                	ld	s0,80(sp)
    800049b4:	64a6                	ld	s1,72(sp)
    800049b6:	6906                	ld	s2,64(sp)
    800049b8:	79e2                	ld	s3,56(sp)
    800049ba:	7a42                	ld	s4,48(sp)
    800049bc:	7aa2                	ld	s5,40(sp)
    800049be:	7b02                	ld	s6,32(sp)
    800049c0:	6be2                	ld	s7,24(sp)
    800049c2:	6c42                	ld	s8,16(sp)
    800049c4:	6ca2                	ld	s9,8(sp)
    800049c6:	6125                	addi	sp,sp,96
    800049c8:	8082                	ret
      iunlock(ip);
    800049ca:	854e                	mv	a0,s3
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	aa6080e7          	jalr	-1370(ra) # 80004472 <iunlock>
      return ip;
    800049d4:	bfe9                	j	800049ae <namex+0x6a>
      iunlockput(ip);
    800049d6:	854e                	mv	a0,s3
    800049d8:	00000097          	auipc	ra,0x0
    800049dc:	c3a080e7          	jalr	-966(ra) # 80004612 <iunlockput>
      return 0;
    800049e0:	89d2                	mv	s3,s4
    800049e2:	b7f1                	j	800049ae <namex+0x6a>
  len = path - s;
    800049e4:	40b48633          	sub	a2,s1,a1
    800049e8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800049ec:	094cd463          	bge	s9,s4,80004a74 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800049f0:	4639                	li	a2,14
    800049f2:	8556                	mv	a0,s5
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	35a080e7          	jalr	858(ra) # 80000d4e <memmove>
  while(*path == '/')
    800049fc:	0004c783          	lbu	a5,0(s1)
    80004a00:	01279763          	bne	a5,s2,80004a0e <namex+0xca>
    path++;
    80004a04:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004a06:	0004c783          	lbu	a5,0(s1)
    80004a0a:	ff278de3          	beq	a5,s2,80004a04 <namex+0xc0>
    ilock(ip);
    80004a0e:	854e                	mv	a0,s3
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	9a0080e7          	jalr	-1632(ra) # 800043b0 <ilock>
    if(ip->type != T_DIR){
    80004a18:	04499783          	lh	a5,68(s3)
    80004a1c:	f98793e3          	bne	a5,s8,800049a2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004a20:	000b0563          	beqz	s6,80004a2a <namex+0xe6>
    80004a24:	0004c783          	lbu	a5,0(s1)
    80004a28:	d3cd                	beqz	a5,800049ca <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004a2a:	865e                	mv	a2,s7
    80004a2c:	85d6                	mv	a1,s5
    80004a2e:	854e                	mv	a0,s3
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	e64080e7          	jalr	-412(ra) # 80004894 <dirlookup>
    80004a38:	8a2a                	mv	s4,a0
    80004a3a:	dd51                	beqz	a0,800049d6 <namex+0x92>
    iunlockput(ip);
    80004a3c:	854e                	mv	a0,s3
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	bd4080e7          	jalr	-1068(ra) # 80004612 <iunlockput>
    ip = next;
    80004a46:	89d2                	mv	s3,s4
  while(*path == '/')
    80004a48:	0004c783          	lbu	a5,0(s1)
    80004a4c:	05279763          	bne	a5,s2,80004a9a <namex+0x156>
    path++;
    80004a50:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004a52:	0004c783          	lbu	a5,0(s1)
    80004a56:	ff278de3          	beq	a5,s2,80004a50 <namex+0x10c>
  if(*path == 0)
    80004a5a:	c79d                	beqz	a5,80004a88 <namex+0x144>
    path++;
    80004a5c:	85a6                	mv	a1,s1
  len = path - s;
    80004a5e:	8a5e                	mv	s4,s7
    80004a60:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004a62:	01278963          	beq	a5,s2,80004a74 <namex+0x130>
    80004a66:	dfbd                	beqz	a5,800049e4 <namex+0xa0>
    path++;
    80004a68:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004a6a:	0004c783          	lbu	a5,0(s1)
    80004a6e:	ff279ce3          	bne	a5,s2,80004a66 <namex+0x122>
    80004a72:	bf8d                	j	800049e4 <namex+0xa0>
    memmove(name, s, len);
    80004a74:	2601                	sext.w	a2,a2
    80004a76:	8556                	mv	a0,s5
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	2d6080e7          	jalr	726(ra) # 80000d4e <memmove>
    name[len] = 0;
    80004a80:	9a56                	add	s4,s4,s5
    80004a82:	000a0023          	sb	zero,0(s4)
    80004a86:	bf9d                	j	800049fc <namex+0xb8>
  if(nameiparent){
    80004a88:	f20b03e3          	beqz	s6,800049ae <namex+0x6a>
    iput(ip);
    80004a8c:	854e                	mv	a0,s3
    80004a8e:	00000097          	auipc	ra,0x0
    80004a92:	adc080e7          	jalr	-1316(ra) # 8000456a <iput>
    return 0;
    80004a96:	4981                	li	s3,0
    80004a98:	bf19                	j	800049ae <namex+0x6a>
  if(*path == 0)
    80004a9a:	d7fd                	beqz	a5,80004a88 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004a9c:	0004c783          	lbu	a5,0(s1)
    80004aa0:	85a6                	mv	a1,s1
    80004aa2:	b7d1                	j	80004a66 <namex+0x122>

0000000080004aa4 <dirlink>:
{
    80004aa4:	7139                	addi	sp,sp,-64
    80004aa6:	fc06                	sd	ra,56(sp)
    80004aa8:	f822                	sd	s0,48(sp)
    80004aaa:	f426                	sd	s1,40(sp)
    80004aac:	f04a                	sd	s2,32(sp)
    80004aae:	ec4e                	sd	s3,24(sp)
    80004ab0:	e852                	sd	s4,16(sp)
    80004ab2:	0080                	addi	s0,sp,64
    80004ab4:	892a                	mv	s2,a0
    80004ab6:	8a2e                	mv	s4,a1
    80004ab8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004aba:	4601                	li	a2,0
    80004abc:	00000097          	auipc	ra,0x0
    80004ac0:	dd8080e7          	jalr	-552(ra) # 80004894 <dirlookup>
    80004ac4:	e93d                	bnez	a0,80004b3a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004ac6:	04c92483          	lw	s1,76(s2)
    80004aca:	c49d                	beqz	s1,80004af8 <dirlink+0x54>
    80004acc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ace:	4741                	li	a4,16
    80004ad0:	86a6                	mv	a3,s1
    80004ad2:	fc040613          	addi	a2,s0,-64
    80004ad6:	4581                	li	a1,0
    80004ad8:	854a                	mv	a0,s2
    80004ada:	00000097          	auipc	ra,0x0
    80004ade:	b8a080e7          	jalr	-1142(ra) # 80004664 <readi>
    80004ae2:	47c1                	li	a5,16
    80004ae4:	06f51163          	bne	a0,a5,80004b46 <dirlink+0xa2>
    if(de.inum == 0)
    80004ae8:	fc045783          	lhu	a5,-64(s0)
    80004aec:	c791                	beqz	a5,80004af8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004aee:	24c1                	addiw	s1,s1,16
    80004af0:	04c92783          	lw	a5,76(s2)
    80004af4:	fcf4ede3          	bltu	s1,a5,80004ace <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004af8:	4639                	li	a2,14
    80004afa:	85d2                	mv	a1,s4
    80004afc:	fc240513          	addi	a0,s0,-62
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	302080e7          	jalr	770(ra) # 80000e02 <strncpy>
  de.inum = inum;
    80004b08:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004b0c:	4741                	li	a4,16
    80004b0e:	86a6                	mv	a3,s1
    80004b10:	fc040613          	addi	a2,s0,-64
    80004b14:	4581                	li	a1,0
    80004b16:	854a                	mv	a0,s2
    80004b18:	00000097          	auipc	ra,0x0
    80004b1c:	c44080e7          	jalr	-956(ra) # 8000475c <writei>
    80004b20:	872a                	mv	a4,a0
    80004b22:	47c1                	li	a5,16
  return 0;
    80004b24:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004b26:	02f71863          	bne	a4,a5,80004b56 <dirlink+0xb2>
}
    80004b2a:	70e2                	ld	ra,56(sp)
    80004b2c:	7442                	ld	s0,48(sp)
    80004b2e:	74a2                	ld	s1,40(sp)
    80004b30:	7902                	ld	s2,32(sp)
    80004b32:	69e2                	ld	s3,24(sp)
    80004b34:	6a42                	ld	s4,16(sp)
    80004b36:	6121                	addi	sp,sp,64
    80004b38:	8082                	ret
    iput(ip);
    80004b3a:	00000097          	auipc	ra,0x0
    80004b3e:	a30080e7          	jalr	-1488(ra) # 8000456a <iput>
    return -1;
    80004b42:	557d                	li	a0,-1
    80004b44:	b7dd                	j	80004b2a <dirlink+0x86>
      panic("dirlink read");
    80004b46:	00004517          	auipc	a0,0x4
    80004b4a:	c6a50513          	addi	a0,a0,-918 # 800087b0 <syscalls+0x1d8>
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	9f0080e7          	jalr	-1552(ra) # 8000053e <panic>
    panic("dirlink");
    80004b56:	00004517          	auipc	a0,0x4
    80004b5a:	d6a50513          	addi	a0,a0,-662 # 800088c0 <syscalls+0x2e8>
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	9e0080e7          	jalr	-1568(ra) # 8000053e <panic>

0000000080004b66 <namei>:

struct inode*
namei(char *path)
{
    80004b66:	1101                	addi	sp,sp,-32
    80004b68:	ec06                	sd	ra,24(sp)
    80004b6a:	e822                	sd	s0,16(sp)
    80004b6c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004b6e:	fe040613          	addi	a2,s0,-32
    80004b72:	4581                	li	a1,0
    80004b74:	00000097          	auipc	ra,0x0
    80004b78:	dd0080e7          	jalr	-560(ra) # 80004944 <namex>
}
    80004b7c:	60e2                	ld	ra,24(sp)
    80004b7e:	6442                	ld	s0,16(sp)
    80004b80:	6105                	addi	sp,sp,32
    80004b82:	8082                	ret

0000000080004b84 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004b84:	1141                	addi	sp,sp,-16
    80004b86:	e406                	sd	ra,8(sp)
    80004b88:	e022                	sd	s0,0(sp)
    80004b8a:	0800                	addi	s0,sp,16
    80004b8c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004b8e:	4585                	li	a1,1
    80004b90:	00000097          	auipc	ra,0x0
    80004b94:	db4080e7          	jalr	-588(ra) # 80004944 <namex>
}
    80004b98:	60a2                	ld	ra,8(sp)
    80004b9a:	6402                	ld	s0,0(sp)
    80004b9c:	0141                	addi	sp,sp,16
    80004b9e:	8082                	ret

0000000080004ba0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004ba0:	1101                	addi	sp,sp,-32
    80004ba2:	ec06                	sd	ra,24(sp)
    80004ba4:	e822                	sd	s0,16(sp)
    80004ba6:	e426                	sd	s1,8(sp)
    80004ba8:	e04a                	sd	s2,0(sp)
    80004baa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004bac:	0001d917          	auipc	s2,0x1d
    80004bb0:	fd490913          	addi	s2,s2,-44 # 80021b80 <log>
    80004bb4:	01892583          	lw	a1,24(s2)
    80004bb8:	02892503          	lw	a0,40(s2)
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	ff2080e7          	jalr	-14(ra) # 80003bae <bread>
    80004bc4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004bc6:	02c92683          	lw	a3,44(s2)
    80004bca:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004bcc:	02d05763          	blez	a3,80004bfa <write_head+0x5a>
    80004bd0:	0001d797          	auipc	a5,0x1d
    80004bd4:	fe078793          	addi	a5,a5,-32 # 80021bb0 <log+0x30>
    80004bd8:	05c50713          	addi	a4,a0,92
    80004bdc:	36fd                	addiw	a3,a3,-1
    80004bde:	1682                	slli	a3,a3,0x20
    80004be0:	9281                	srli	a3,a3,0x20
    80004be2:	068a                	slli	a3,a3,0x2
    80004be4:	0001d617          	auipc	a2,0x1d
    80004be8:	fd060613          	addi	a2,a2,-48 # 80021bb4 <log+0x34>
    80004bec:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004bee:	4390                	lw	a2,0(a5)
    80004bf0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004bf2:	0791                	addi	a5,a5,4
    80004bf4:	0711                	addi	a4,a4,4
    80004bf6:	fed79ce3          	bne	a5,a3,80004bee <write_head+0x4e>
  }
  bwrite(buf);
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	0a4080e7          	jalr	164(ra) # 80003ca0 <bwrite>
  brelse(buf);
    80004c04:	8526                	mv	a0,s1
    80004c06:	fffff097          	auipc	ra,0xfffff
    80004c0a:	0d8080e7          	jalr	216(ra) # 80003cde <brelse>
}
    80004c0e:	60e2                	ld	ra,24(sp)
    80004c10:	6442                	ld	s0,16(sp)
    80004c12:	64a2                	ld	s1,8(sp)
    80004c14:	6902                	ld	s2,0(sp)
    80004c16:	6105                	addi	sp,sp,32
    80004c18:	8082                	ret

0000000080004c1a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c1a:	0001d797          	auipc	a5,0x1d
    80004c1e:	f927a783          	lw	a5,-110(a5) # 80021bac <log+0x2c>
    80004c22:	0af05d63          	blez	a5,80004cdc <install_trans+0xc2>
{
    80004c26:	7139                	addi	sp,sp,-64
    80004c28:	fc06                	sd	ra,56(sp)
    80004c2a:	f822                	sd	s0,48(sp)
    80004c2c:	f426                	sd	s1,40(sp)
    80004c2e:	f04a                	sd	s2,32(sp)
    80004c30:	ec4e                	sd	s3,24(sp)
    80004c32:	e852                	sd	s4,16(sp)
    80004c34:	e456                	sd	s5,8(sp)
    80004c36:	e05a                	sd	s6,0(sp)
    80004c38:	0080                	addi	s0,sp,64
    80004c3a:	8b2a                	mv	s6,a0
    80004c3c:	0001da97          	auipc	s5,0x1d
    80004c40:	f74a8a93          	addi	s5,s5,-140 # 80021bb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c44:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c46:	0001d997          	auipc	s3,0x1d
    80004c4a:	f3a98993          	addi	s3,s3,-198 # 80021b80 <log>
    80004c4e:	a035                	j	80004c7a <install_trans+0x60>
      bunpin(dbuf);
    80004c50:	8526                	mv	a0,s1
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	166080e7          	jalr	358(ra) # 80003db8 <bunpin>
    brelse(lbuf);
    80004c5a:	854a                	mv	a0,s2
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	082080e7          	jalr	130(ra) # 80003cde <brelse>
    brelse(dbuf);
    80004c64:	8526                	mv	a0,s1
    80004c66:	fffff097          	auipc	ra,0xfffff
    80004c6a:	078080e7          	jalr	120(ra) # 80003cde <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c6e:	2a05                	addiw	s4,s4,1
    80004c70:	0a91                	addi	s5,s5,4
    80004c72:	02c9a783          	lw	a5,44(s3)
    80004c76:	04fa5963          	bge	s4,a5,80004cc8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004c7a:	0189a583          	lw	a1,24(s3)
    80004c7e:	014585bb          	addw	a1,a1,s4
    80004c82:	2585                	addiw	a1,a1,1
    80004c84:	0289a503          	lw	a0,40(s3)
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	f26080e7          	jalr	-218(ra) # 80003bae <bread>
    80004c90:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004c92:	000aa583          	lw	a1,0(s5)
    80004c96:	0289a503          	lw	a0,40(s3)
    80004c9a:	fffff097          	auipc	ra,0xfffff
    80004c9e:	f14080e7          	jalr	-236(ra) # 80003bae <bread>
    80004ca2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004ca4:	40000613          	li	a2,1024
    80004ca8:	05890593          	addi	a1,s2,88
    80004cac:	05850513          	addi	a0,a0,88
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	09e080e7          	jalr	158(ra) # 80000d4e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004cb8:	8526                	mv	a0,s1
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	fe6080e7          	jalr	-26(ra) # 80003ca0 <bwrite>
    if(recovering == 0)
    80004cc2:	f80b1ce3          	bnez	s6,80004c5a <install_trans+0x40>
    80004cc6:	b769                	j	80004c50 <install_trans+0x36>
}
    80004cc8:	70e2                	ld	ra,56(sp)
    80004cca:	7442                	ld	s0,48(sp)
    80004ccc:	74a2                	ld	s1,40(sp)
    80004cce:	7902                	ld	s2,32(sp)
    80004cd0:	69e2                	ld	s3,24(sp)
    80004cd2:	6a42                	ld	s4,16(sp)
    80004cd4:	6aa2                	ld	s5,8(sp)
    80004cd6:	6b02                	ld	s6,0(sp)
    80004cd8:	6121                	addi	sp,sp,64
    80004cda:	8082                	ret
    80004cdc:	8082                	ret

0000000080004cde <initlog>:
{
    80004cde:	7179                	addi	sp,sp,-48
    80004ce0:	f406                	sd	ra,40(sp)
    80004ce2:	f022                	sd	s0,32(sp)
    80004ce4:	ec26                	sd	s1,24(sp)
    80004ce6:	e84a                	sd	s2,16(sp)
    80004ce8:	e44e                	sd	s3,8(sp)
    80004cea:	1800                	addi	s0,sp,48
    80004cec:	892a                	mv	s2,a0
    80004cee:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004cf0:	0001d497          	auipc	s1,0x1d
    80004cf4:	e9048493          	addi	s1,s1,-368 # 80021b80 <log>
    80004cf8:	00004597          	auipc	a1,0x4
    80004cfc:	ac858593          	addi	a1,a1,-1336 # 800087c0 <syscalls+0x1e8>
    80004d00:	8526                	mv	a0,s1
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	e52080e7          	jalr	-430(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004d0a:	0149a583          	lw	a1,20(s3)
    80004d0e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004d10:	0109a783          	lw	a5,16(s3)
    80004d14:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004d16:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004d1a:	854a                	mv	a0,s2
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	e92080e7          	jalr	-366(ra) # 80003bae <bread>
  log.lh.n = lh->n;
    80004d24:	4d3c                	lw	a5,88(a0)
    80004d26:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004d28:	02f05563          	blez	a5,80004d52 <initlog+0x74>
    80004d2c:	05c50713          	addi	a4,a0,92
    80004d30:	0001d697          	auipc	a3,0x1d
    80004d34:	e8068693          	addi	a3,a3,-384 # 80021bb0 <log+0x30>
    80004d38:	37fd                	addiw	a5,a5,-1
    80004d3a:	1782                	slli	a5,a5,0x20
    80004d3c:	9381                	srli	a5,a5,0x20
    80004d3e:	078a                	slli	a5,a5,0x2
    80004d40:	06050613          	addi	a2,a0,96
    80004d44:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004d46:	4310                	lw	a2,0(a4)
    80004d48:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004d4a:	0711                	addi	a4,a4,4
    80004d4c:	0691                	addi	a3,a3,4
    80004d4e:	fef71ce3          	bne	a4,a5,80004d46 <initlog+0x68>
  brelse(buf);
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	f8c080e7          	jalr	-116(ra) # 80003cde <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004d5a:	4505                	li	a0,1
    80004d5c:	00000097          	auipc	ra,0x0
    80004d60:	ebe080e7          	jalr	-322(ra) # 80004c1a <install_trans>
  log.lh.n = 0;
    80004d64:	0001d797          	auipc	a5,0x1d
    80004d68:	e407a423          	sw	zero,-440(a5) # 80021bac <log+0x2c>
  write_head(); // clear the log
    80004d6c:	00000097          	auipc	ra,0x0
    80004d70:	e34080e7          	jalr	-460(ra) # 80004ba0 <write_head>
}
    80004d74:	70a2                	ld	ra,40(sp)
    80004d76:	7402                	ld	s0,32(sp)
    80004d78:	64e2                	ld	s1,24(sp)
    80004d7a:	6942                	ld	s2,16(sp)
    80004d7c:	69a2                	ld	s3,8(sp)
    80004d7e:	6145                	addi	sp,sp,48
    80004d80:	8082                	ret

0000000080004d82 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004d82:	1101                	addi	sp,sp,-32
    80004d84:	ec06                	sd	ra,24(sp)
    80004d86:	e822                	sd	s0,16(sp)
    80004d88:	e426                	sd	s1,8(sp)
    80004d8a:	e04a                	sd	s2,0(sp)
    80004d8c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004d8e:	0001d517          	auipc	a0,0x1d
    80004d92:	df250513          	addi	a0,a0,-526 # 80021b80 <log>
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	e56080e7          	jalr	-426(ra) # 80000bec <acquire>
  while(1){
    if(log.committing){
    80004d9e:	0001d497          	auipc	s1,0x1d
    80004da2:	de248493          	addi	s1,s1,-542 # 80021b80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004da6:	4979                	li	s2,30
    80004da8:	a039                	j	80004db6 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004daa:	85a6                	mv	a1,s1
    80004dac:	8526                	mv	a0,s1
    80004dae:	ffffe097          	auipc	ra,0xffffe
    80004db2:	edc080e7          	jalr	-292(ra) # 80002c8a <sleep>
    if(log.committing){
    80004db6:	50dc                	lw	a5,36(s1)
    80004db8:	fbed                	bnez	a5,80004daa <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004dba:	509c                	lw	a5,32(s1)
    80004dbc:	0017871b          	addiw	a4,a5,1
    80004dc0:	0007069b          	sext.w	a3,a4
    80004dc4:	0027179b          	slliw	a5,a4,0x2
    80004dc8:	9fb9                	addw	a5,a5,a4
    80004dca:	0017979b          	slliw	a5,a5,0x1
    80004dce:	54d8                	lw	a4,44(s1)
    80004dd0:	9fb9                	addw	a5,a5,a4
    80004dd2:	00f95963          	bge	s2,a5,80004de4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004dd6:	85a6                	mv	a1,s1
    80004dd8:	8526                	mv	a0,s1
    80004dda:	ffffe097          	auipc	ra,0xffffe
    80004dde:	eb0080e7          	jalr	-336(ra) # 80002c8a <sleep>
    80004de2:	bfd1                	j	80004db6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004de4:	0001d517          	auipc	a0,0x1d
    80004de8:	d9c50513          	addi	a0,a0,-612 # 80021b80 <log>
    80004dec:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	eb8080e7          	jalr	-328(ra) # 80000ca6 <release>
      break;
    }
  }
}
    80004df6:	60e2                	ld	ra,24(sp)
    80004df8:	6442                	ld	s0,16(sp)
    80004dfa:	64a2                	ld	s1,8(sp)
    80004dfc:	6902                	ld	s2,0(sp)
    80004dfe:	6105                	addi	sp,sp,32
    80004e00:	8082                	ret

0000000080004e02 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004e02:	7139                	addi	sp,sp,-64
    80004e04:	fc06                	sd	ra,56(sp)
    80004e06:	f822                	sd	s0,48(sp)
    80004e08:	f426                	sd	s1,40(sp)
    80004e0a:	f04a                	sd	s2,32(sp)
    80004e0c:	ec4e                	sd	s3,24(sp)
    80004e0e:	e852                	sd	s4,16(sp)
    80004e10:	e456                	sd	s5,8(sp)
    80004e12:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004e14:	0001d497          	auipc	s1,0x1d
    80004e18:	d6c48493          	addi	s1,s1,-660 # 80021b80 <log>
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	dce080e7          	jalr	-562(ra) # 80000bec <acquire>
  log.outstanding -= 1;
    80004e26:	509c                	lw	a5,32(s1)
    80004e28:	37fd                	addiw	a5,a5,-1
    80004e2a:	0007891b          	sext.w	s2,a5
    80004e2e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004e30:	50dc                	lw	a5,36(s1)
    80004e32:	efb9                	bnez	a5,80004e90 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004e34:	06091663          	bnez	s2,80004ea0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004e38:	0001d497          	auipc	s1,0x1d
    80004e3c:	d4848493          	addi	s1,s1,-696 # 80021b80 <log>
    80004e40:	4785                	li	a5,1
    80004e42:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004e44:	8526                	mv	a0,s1
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	e60080e7          	jalr	-416(ra) # 80000ca6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004e4e:	54dc                	lw	a5,44(s1)
    80004e50:	06f04763          	bgtz	a5,80004ebe <end_op+0xbc>
    acquire(&log.lock);
    80004e54:	0001d497          	auipc	s1,0x1d
    80004e58:	d2c48493          	addi	s1,s1,-724 # 80021b80 <log>
    80004e5c:	8526                	mv	a0,s1
    80004e5e:	ffffc097          	auipc	ra,0xffffc
    80004e62:	d8e080e7          	jalr	-626(ra) # 80000bec <acquire>
    log.committing = 0;
    80004e66:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004e6a:	8526                	mv	a0,s1
    80004e6c:	ffffe097          	auipc	ra,0xffffe
    80004e70:	fc4080e7          	jalr	-60(ra) # 80002e30 <wakeup>
    release(&log.lock);
    80004e74:	8526                	mv	a0,s1
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	e30080e7          	jalr	-464(ra) # 80000ca6 <release>
}
    80004e7e:	70e2                	ld	ra,56(sp)
    80004e80:	7442                	ld	s0,48(sp)
    80004e82:	74a2                	ld	s1,40(sp)
    80004e84:	7902                	ld	s2,32(sp)
    80004e86:	69e2                	ld	s3,24(sp)
    80004e88:	6a42                	ld	s4,16(sp)
    80004e8a:	6aa2                	ld	s5,8(sp)
    80004e8c:	6121                	addi	sp,sp,64
    80004e8e:	8082                	ret
    panic("log.committing");
    80004e90:	00004517          	auipc	a0,0x4
    80004e94:	93850513          	addi	a0,a0,-1736 # 800087c8 <syscalls+0x1f0>
    80004e98:	ffffb097          	auipc	ra,0xffffb
    80004e9c:	6a6080e7          	jalr	1702(ra) # 8000053e <panic>
    wakeup(&log);
    80004ea0:	0001d497          	auipc	s1,0x1d
    80004ea4:	ce048493          	addi	s1,s1,-800 # 80021b80 <log>
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	ffffe097          	auipc	ra,0xffffe
    80004eae:	f86080e7          	jalr	-122(ra) # 80002e30 <wakeup>
  release(&log.lock);
    80004eb2:	8526                	mv	a0,s1
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	df2080e7          	jalr	-526(ra) # 80000ca6 <release>
  if(do_commit){
    80004ebc:	b7c9                	j	80004e7e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ebe:	0001da97          	auipc	s5,0x1d
    80004ec2:	cf2a8a93          	addi	s5,s5,-782 # 80021bb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004ec6:	0001da17          	auipc	s4,0x1d
    80004eca:	cbaa0a13          	addi	s4,s4,-838 # 80021b80 <log>
    80004ece:	018a2583          	lw	a1,24(s4)
    80004ed2:	012585bb          	addw	a1,a1,s2
    80004ed6:	2585                	addiw	a1,a1,1
    80004ed8:	028a2503          	lw	a0,40(s4)
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	cd2080e7          	jalr	-814(ra) # 80003bae <bread>
    80004ee4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004ee6:	000aa583          	lw	a1,0(s5)
    80004eea:	028a2503          	lw	a0,40(s4)
    80004eee:	fffff097          	auipc	ra,0xfffff
    80004ef2:	cc0080e7          	jalr	-832(ra) # 80003bae <bread>
    80004ef6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004ef8:	40000613          	li	a2,1024
    80004efc:	05850593          	addi	a1,a0,88
    80004f00:	05848513          	addi	a0,s1,88
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	e4a080e7          	jalr	-438(ra) # 80000d4e <memmove>
    bwrite(to);  // write the log
    80004f0c:	8526                	mv	a0,s1
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	d92080e7          	jalr	-622(ra) # 80003ca0 <bwrite>
    brelse(from);
    80004f16:	854e                	mv	a0,s3
    80004f18:	fffff097          	auipc	ra,0xfffff
    80004f1c:	dc6080e7          	jalr	-570(ra) # 80003cde <brelse>
    brelse(to);
    80004f20:	8526                	mv	a0,s1
    80004f22:	fffff097          	auipc	ra,0xfffff
    80004f26:	dbc080e7          	jalr	-580(ra) # 80003cde <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004f2a:	2905                	addiw	s2,s2,1
    80004f2c:	0a91                	addi	s5,s5,4
    80004f2e:	02ca2783          	lw	a5,44(s4)
    80004f32:	f8f94ee3          	blt	s2,a5,80004ece <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004f36:	00000097          	auipc	ra,0x0
    80004f3a:	c6a080e7          	jalr	-918(ra) # 80004ba0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004f3e:	4501                	li	a0,0
    80004f40:	00000097          	auipc	ra,0x0
    80004f44:	cda080e7          	jalr	-806(ra) # 80004c1a <install_trans>
    log.lh.n = 0;
    80004f48:	0001d797          	auipc	a5,0x1d
    80004f4c:	c607a223          	sw	zero,-924(a5) # 80021bac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004f50:	00000097          	auipc	ra,0x0
    80004f54:	c50080e7          	jalr	-944(ra) # 80004ba0 <write_head>
    80004f58:	bdf5                	j	80004e54 <end_op+0x52>

0000000080004f5a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004f5a:	1101                	addi	sp,sp,-32
    80004f5c:	ec06                	sd	ra,24(sp)
    80004f5e:	e822                	sd	s0,16(sp)
    80004f60:	e426                	sd	s1,8(sp)
    80004f62:	e04a                	sd	s2,0(sp)
    80004f64:	1000                	addi	s0,sp,32
    80004f66:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004f68:	0001d917          	auipc	s2,0x1d
    80004f6c:	c1890913          	addi	s2,s2,-1000 # 80021b80 <log>
    80004f70:	854a                	mv	a0,s2
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	c7a080e7          	jalr	-902(ra) # 80000bec <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004f7a:	02c92603          	lw	a2,44(s2)
    80004f7e:	47f5                	li	a5,29
    80004f80:	06c7c563          	blt	a5,a2,80004fea <log_write+0x90>
    80004f84:	0001d797          	auipc	a5,0x1d
    80004f88:	c187a783          	lw	a5,-1000(a5) # 80021b9c <log+0x1c>
    80004f8c:	37fd                	addiw	a5,a5,-1
    80004f8e:	04f65e63          	bge	a2,a5,80004fea <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004f92:	0001d797          	auipc	a5,0x1d
    80004f96:	c0e7a783          	lw	a5,-1010(a5) # 80021ba0 <log+0x20>
    80004f9a:	06f05063          	blez	a5,80004ffa <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004f9e:	4781                	li	a5,0
    80004fa0:	06c05563          	blez	a2,8000500a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004fa4:	44cc                	lw	a1,12(s1)
    80004fa6:	0001d717          	auipc	a4,0x1d
    80004faa:	c0a70713          	addi	a4,a4,-1014 # 80021bb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004fae:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004fb0:	4314                	lw	a3,0(a4)
    80004fb2:	04b68c63          	beq	a3,a1,8000500a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004fb6:	2785                	addiw	a5,a5,1
    80004fb8:	0711                	addi	a4,a4,4
    80004fba:	fef61be3          	bne	a2,a5,80004fb0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004fbe:	0621                	addi	a2,a2,8
    80004fc0:	060a                	slli	a2,a2,0x2
    80004fc2:	0001d797          	auipc	a5,0x1d
    80004fc6:	bbe78793          	addi	a5,a5,-1090 # 80021b80 <log>
    80004fca:	963e                	add	a2,a2,a5
    80004fcc:	44dc                	lw	a5,12(s1)
    80004fce:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	daa080e7          	jalr	-598(ra) # 80003d7c <bpin>
    log.lh.n++;
    80004fda:	0001d717          	auipc	a4,0x1d
    80004fde:	ba670713          	addi	a4,a4,-1114 # 80021b80 <log>
    80004fe2:	575c                	lw	a5,44(a4)
    80004fe4:	2785                	addiw	a5,a5,1
    80004fe6:	d75c                	sw	a5,44(a4)
    80004fe8:	a835                	j	80005024 <log_write+0xca>
    panic("too big a transaction");
    80004fea:	00003517          	auipc	a0,0x3
    80004fee:	7ee50513          	addi	a0,a0,2030 # 800087d8 <syscalls+0x200>
    80004ff2:	ffffb097          	auipc	ra,0xffffb
    80004ff6:	54c080e7          	jalr	1356(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004ffa:	00003517          	auipc	a0,0x3
    80004ffe:	7f650513          	addi	a0,a0,2038 # 800087f0 <syscalls+0x218>
    80005002:	ffffb097          	auipc	ra,0xffffb
    80005006:	53c080e7          	jalr	1340(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000500a:	00878713          	addi	a4,a5,8
    8000500e:	00271693          	slli	a3,a4,0x2
    80005012:	0001d717          	auipc	a4,0x1d
    80005016:	b6e70713          	addi	a4,a4,-1170 # 80021b80 <log>
    8000501a:	9736                	add	a4,a4,a3
    8000501c:	44d4                	lw	a3,12(s1)
    8000501e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80005020:	faf608e3          	beq	a2,a5,80004fd0 <log_write+0x76>
  }
  release(&log.lock);
    80005024:	0001d517          	auipc	a0,0x1d
    80005028:	b5c50513          	addi	a0,a0,-1188 # 80021b80 <log>
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	c7a080e7          	jalr	-902(ra) # 80000ca6 <release>
}
    80005034:	60e2                	ld	ra,24(sp)
    80005036:	6442                	ld	s0,16(sp)
    80005038:	64a2                	ld	s1,8(sp)
    8000503a:	6902                	ld	s2,0(sp)
    8000503c:	6105                	addi	sp,sp,32
    8000503e:	8082                	ret

0000000080005040 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80005040:	1101                	addi	sp,sp,-32
    80005042:	ec06                	sd	ra,24(sp)
    80005044:	e822                	sd	s0,16(sp)
    80005046:	e426                	sd	s1,8(sp)
    80005048:	e04a                	sd	s2,0(sp)
    8000504a:	1000                	addi	s0,sp,32
    8000504c:	84aa                	mv	s1,a0
    8000504e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80005050:	00003597          	auipc	a1,0x3
    80005054:	7c058593          	addi	a1,a1,1984 # 80008810 <syscalls+0x238>
    80005058:	0521                	addi	a0,a0,8
    8000505a:	ffffc097          	auipc	ra,0xffffc
    8000505e:	afa080e7          	jalr	-1286(ra) # 80000b54 <initlock>
  lk->name = name;
    80005062:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80005066:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000506a:	0204a423          	sw	zero,40(s1)
}
    8000506e:	60e2                	ld	ra,24(sp)
    80005070:	6442                	ld	s0,16(sp)
    80005072:	64a2                	ld	s1,8(sp)
    80005074:	6902                	ld	s2,0(sp)
    80005076:	6105                	addi	sp,sp,32
    80005078:	8082                	ret

000000008000507a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000507a:	1101                	addi	sp,sp,-32
    8000507c:	ec06                	sd	ra,24(sp)
    8000507e:	e822                	sd	s0,16(sp)
    80005080:	e426                	sd	s1,8(sp)
    80005082:	e04a                	sd	s2,0(sp)
    80005084:	1000                	addi	s0,sp,32
    80005086:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005088:	00850913          	addi	s2,a0,8
    8000508c:	854a                	mv	a0,s2
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	b5e080e7          	jalr	-1186(ra) # 80000bec <acquire>
  while (lk->locked) {
    80005096:	409c                	lw	a5,0(s1)
    80005098:	cb89                	beqz	a5,800050aa <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000509a:	85ca                	mv	a1,s2
    8000509c:	8526                	mv	a0,s1
    8000509e:	ffffe097          	auipc	ra,0xffffe
    800050a2:	bec080e7          	jalr	-1044(ra) # 80002c8a <sleep>
  while (lk->locked) {
    800050a6:	409c                	lw	a5,0(s1)
    800050a8:	fbed                	bnez	a5,8000509a <acquiresleep+0x20>
  }
  lk->locked = 1;
    800050aa:	4785                	li	a5,1
    800050ac:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800050ae:	ffffd097          	auipc	ra,0xffffd
    800050b2:	d5e080e7          	jalr	-674(ra) # 80001e0c <myproc>
    800050b6:	453c                	lw	a5,72(a0)
    800050b8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800050ba:	854a                	mv	a0,s2
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	bea080e7          	jalr	-1046(ra) # 80000ca6 <release>
}
    800050c4:	60e2                	ld	ra,24(sp)
    800050c6:	6442                	ld	s0,16(sp)
    800050c8:	64a2                	ld	s1,8(sp)
    800050ca:	6902                	ld	s2,0(sp)
    800050cc:	6105                	addi	sp,sp,32
    800050ce:	8082                	ret

00000000800050d0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800050d0:	1101                	addi	sp,sp,-32
    800050d2:	ec06                	sd	ra,24(sp)
    800050d4:	e822                	sd	s0,16(sp)
    800050d6:	e426                	sd	s1,8(sp)
    800050d8:	e04a                	sd	s2,0(sp)
    800050da:	1000                	addi	s0,sp,32
    800050dc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800050de:	00850913          	addi	s2,a0,8
    800050e2:	854a                	mv	a0,s2
    800050e4:	ffffc097          	auipc	ra,0xffffc
    800050e8:	b08080e7          	jalr	-1272(ra) # 80000bec <acquire>
  lk->locked = 0;
    800050ec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800050f0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800050f4:	8526                	mv	a0,s1
    800050f6:	ffffe097          	auipc	ra,0xffffe
    800050fa:	d3a080e7          	jalr	-710(ra) # 80002e30 <wakeup>
  release(&lk->lk);
    800050fe:	854a                	mv	a0,s2
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	ba6080e7          	jalr	-1114(ra) # 80000ca6 <release>
}
    80005108:	60e2                	ld	ra,24(sp)
    8000510a:	6442                	ld	s0,16(sp)
    8000510c:	64a2                	ld	s1,8(sp)
    8000510e:	6902                	ld	s2,0(sp)
    80005110:	6105                	addi	sp,sp,32
    80005112:	8082                	ret

0000000080005114 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005114:	7179                	addi	sp,sp,-48
    80005116:	f406                	sd	ra,40(sp)
    80005118:	f022                	sd	s0,32(sp)
    8000511a:	ec26                	sd	s1,24(sp)
    8000511c:	e84a                	sd	s2,16(sp)
    8000511e:	e44e                	sd	s3,8(sp)
    80005120:	1800                	addi	s0,sp,48
    80005122:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005124:	00850913          	addi	s2,a0,8
    80005128:	854a                	mv	a0,s2
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	ac2080e7          	jalr	-1342(ra) # 80000bec <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005132:	409c                	lw	a5,0(s1)
    80005134:	ef99                	bnez	a5,80005152 <holdingsleep+0x3e>
    80005136:	4481                	li	s1,0
  release(&lk->lk);
    80005138:	854a                	mv	a0,s2
    8000513a:	ffffc097          	auipc	ra,0xffffc
    8000513e:	b6c080e7          	jalr	-1172(ra) # 80000ca6 <release>
  return r;
}
    80005142:	8526                	mv	a0,s1
    80005144:	70a2                	ld	ra,40(sp)
    80005146:	7402                	ld	s0,32(sp)
    80005148:	64e2                	ld	s1,24(sp)
    8000514a:	6942                	ld	s2,16(sp)
    8000514c:	69a2                	ld	s3,8(sp)
    8000514e:	6145                	addi	sp,sp,48
    80005150:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005152:	0284a983          	lw	s3,40(s1)
    80005156:	ffffd097          	auipc	ra,0xffffd
    8000515a:	cb6080e7          	jalr	-842(ra) # 80001e0c <myproc>
    8000515e:	4524                	lw	s1,72(a0)
    80005160:	413484b3          	sub	s1,s1,s3
    80005164:	0014b493          	seqz	s1,s1
    80005168:	bfc1                	j	80005138 <holdingsleep+0x24>

000000008000516a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000516a:	1141                	addi	sp,sp,-16
    8000516c:	e406                	sd	ra,8(sp)
    8000516e:	e022                	sd	s0,0(sp)
    80005170:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005172:	00003597          	auipc	a1,0x3
    80005176:	6ae58593          	addi	a1,a1,1710 # 80008820 <syscalls+0x248>
    8000517a:	0001d517          	auipc	a0,0x1d
    8000517e:	b4e50513          	addi	a0,a0,-1202 # 80021cc8 <ftable>
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	9d2080e7          	jalr	-1582(ra) # 80000b54 <initlock>
}
    8000518a:	60a2                	ld	ra,8(sp)
    8000518c:	6402                	ld	s0,0(sp)
    8000518e:	0141                	addi	sp,sp,16
    80005190:	8082                	ret

0000000080005192 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005192:	1101                	addi	sp,sp,-32
    80005194:	ec06                	sd	ra,24(sp)
    80005196:	e822                	sd	s0,16(sp)
    80005198:	e426                	sd	s1,8(sp)
    8000519a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000519c:	0001d517          	auipc	a0,0x1d
    800051a0:	b2c50513          	addi	a0,a0,-1236 # 80021cc8 <ftable>
    800051a4:	ffffc097          	auipc	ra,0xffffc
    800051a8:	a48080e7          	jalr	-1464(ra) # 80000bec <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800051ac:	0001d497          	auipc	s1,0x1d
    800051b0:	b3448493          	addi	s1,s1,-1228 # 80021ce0 <ftable+0x18>
    800051b4:	0001e717          	auipc	a4,0x1e
    800051b8:	acc70713          	addi	a4,a4,-1332 # 80022c80 <ftable+0xfb8>
    if(f->ref == 0){
    800051bc:	40dc                	lw	a5,4(s1)
    800051be:	cf99                	beqz	a5,800051dc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800051c0:	02848493          	addi	s1,s1,40
    800051c4:	fee49ce3          	bne	s1,a4,800051bc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800051c8:	0001d517          	auipc	a0,0x1d
    800051cc:	b0050513          	addi	a0,a0,-1280 # 80021cc8 <ftable>
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	ad6080e7          	jalr	-1322(ra) # 80000ca6 <release>
  return 0;
    800051d8:	4481                	li	s1,0
    800051da:	a819                	j	800051f0 <filealloc+0x5e>
      f->ref = 1;
    800051dc:	4785                	li	a5,1
    800051de:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800051e0:	0001d517          	auipc	a0,0x1d
    800051e4:	ae850513          	addi	a0,a0,-1304 # 80021cc8 <ftable>
    800051e8:	ffffc097          	auipc	ra,0xffffc
    800051ec:	abe080e7          	jalr	-1346(ra) # 80000ca6 <release>
}
    800051f0:	8526                	mv	a0,s1
    800051f2:	60e2                	ld	ra,24(sp)
    800051f4:	6442                	ld	s0,16(sp)
    800051f6:	64a2                	ld	s1,8(sp)
    800051f8:	6105                	addi	sp,sp,32
    800051fa:	8082                	ret

00000000800051fc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800051fc:	1101                	addi	sp,sp,-32
    800051fe:	ec06                	sd	ra,24(sp)
    80005200:	e822                	sd	s0,16(sp)
    80005202:	e426                	sd	s1,8(sp)
    80005204:	1000                	addi	s0,sp,32
    80005206:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005208:	0001d517          	auipc	a0,0x1d
    8000520c:	ac050513          	addi	a0,a0,-1344 # 80021cc8 <ftable>
    80005210:	ffffc097          	auipc	ra,0xffffc
    80005214:	9dc080e7          	jalr	-1572(ra) # 80000bec <acquire>
  if(f->ref < 1)
    80005218:	40dc                	lw	a5,4(s1)
    8000521a:	02f05263          	blez	a5,8000523e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000521e:	2785                	addiw	a5,a5,1
    80005220:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005222:	0001d517          	auipc	a0,0x1d
    80005226:	aa650513          	addi	a0,a0,-1370 # 80021cc8 <ftable>
    8000522a:	ffffc097          	auipc	ra,0xffffc
    8000522e:	a7c080e7          	jalr	-1412(ra) # 80000ca6 <release>
  return f;
}
    80005232:	8526                	mv	a0,s1
    80005234:	60e2                	ld	ra,24(sp)
    80005236:	6442                	ld	s0,16(sp)
    80005238:	64a2                	ld	s1,8(sp)
    8000523a:	6105                	addi	sp,sp,32
    8000523c:	8082                	ret
    panic("filedup");
    8000523e:	00003517          	auipc	a0,0x3
    80005242:	5ea50513          	addi	a0,a0,1514 # 80008828 <syscalls+0x250>
    80005246:	ffffb097          	auipc	ra,0xffffb
    8000524a:	2f8080e7          	jalr	760(ra) # 8000053e <panic>

000000008000524e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000524e:	7139                	addi	sp,sp,-64
    80005250:	fc06                	sd	ra,56(sp)
    80005252:	f822                	sd	s0,48(sp)
    80005254:	f426                	sd	s1,40(sp)
    80005256:	f04a                	sd	s2,32(sp)
    80005258:	ec4e                	sd	s3,24(sp)
    8000525a:	e852                	sd	s4,16(sp)
    8000525c:	e456                	sd	s5,8(sp)
    8000525e:	0080                	addi	s0,sp,64
    80005260:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005262:	0001d517          	auipc	a0,0x1d
    80005266:	a6650513          	addi	a0,a0,-1434 # 80021cc8 <ftable>
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	982080e7          	jalr	-1662(ra) # 80000bec <acquire>
  if(f->ref < 1)
    80005272:	40dc                	lw	a5,4(s1)
    80005274:	06f05163          	blez	a5,800052d6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005278:	37fd                	addiw	a5,a5,-1
    8000527a:	0007871b          	sext.w	a4,a5
    8000527e:	c0dc                	sw	a5,4(s1)
    80005280:	06e04363          	bgtz	a4,800052e6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005284:	0004a903          	lw	s2,0(s1)
    80005288:	0094ca83          	lbu	s5,9(s1)
    8000528c:	0104ba03          	ld	s4,16(s1)
    80005290:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005294:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005298:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000529c:	0001d517          	auipc	a0,0x1d
    800052a0:	a2c50513          	addi	a0,a0,-1492 # 80021cc8 <ftable>
    800052a4:	ffffc097          	auipc	ra,0xffffc
    800052a8:	a02080e7          	jalr	-1534(ra) # 80000ca6 <release>

  if(ff.type == FD_PIPE){
    800052ac:	4785                	li	a5,1
    800052ae:	04f90d63          	beq	s2,a5,80005308 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800052b2:	3979                	addiw	s2,s2,-2
    800052b4:	4785                	li	a5,1
    800052b6:	0527e063          	bltu	a5,s2,800052f6 <fileclose+0xa8>
    begin_op();
    800052ba:	00000097          	auipc	ra,0x0
    800052be:	ac8080e7          	jalr	-1336(ra) # 80004d82 <begin_op>
    iput(ff.ip);
    800052c2:	854e                	mv	a0,s3
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	2a6080e7          	jalr	678(ra) # 8000456a <iput>
    end_op();
    800052cc:	00000097          	auipc	ra,0x0
    800052d0:	b36080e7          	jalr	-1226(ra) # 80004e02 <end_op>
    800052d4:	a00d                	j	800052f6 <fileclose+0xa8>
    panic("fileclose");
    800052d6:	00003517          	auipc	a0,0x3
    800052da:	55a50513          	addi	a0,a0,1370 # 80008830 <syscalls+0x258>
    800052de:	ffffb097          	auipc	ra,0xffffb
    800052e2:	260080e7          	jalr	608(ra) # 8000053e <panic>
    release(&ftable.lock);
    800052e6:	0001d517          	auipc	a0,0x1d
    800052ea:	9e250513          	addi	a0,a0,-1566 # 80021cc8 <ftable>
    800052ee:	ffffc097          	auipc	ra,0xffffc
    800052f2:	9b8080e7          	jalr	-1608(ra) # 80000ca6 <release>
  }
}
    800052f6:	70e2                	ld	ra,56(sp)
    800052f8:	7442                	ld	s0,48(sp)
    800052fa:	74a2                	ld	s1,40(sp)
    800052fc:	7902                	ld	s2,32(sp)
    800052fe:	69e2                	ld	s3,24(sp)
    80005300:	6a42                	ld	s4,16(sp)
    80005302:	6aa2                	ld	s5,8(sp)
    80005304:	6121                	addi	sp,sp,64
    80005306:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005308:	85d6                	mv	a1,s5
    8000530a:	8552                	mv	a0,s4
    8000530c:	00000097          	auipc	ra,0x0
    80005310:	34c080e7          	jalr	844(ra) # 80005658 <pipeclose>
    80005314:	b7cd                	j	800052f6 <fileclose+0xa8>

0000000080005316 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005316:	715d                	addi	sp,sp,-80
    80005318:	e486                	sd	ra,72(sp)
    8000531a:	e0a2                	sd	s0,64(sp)
    8000531c:	fc26                	sd	s1,56(sp)
    8000531e:	f84a                	sd	s2,48(sp)
    80005320:	f44e                	sd	s3,40(sp)
    80005322:	0880                	addi	s0,sp,80
    80005324:	84aa                	mv	s1,a0
    80005326:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005328:	ffffd097          	auipc	ra,0xffffd
    8000532c:	ae4080e7          	jalr	-1308(ra) # 80001e0c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005330:	409c                	lw	a5,0(s1)
    80005332:	37f9                	addiw	a5,a5,-2
    80005334:	4705                	li	a4,1
    80005336:	04f76763          	bltu	a4,a5,80005384 <filestat+0x6e>
    8000533a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000533c:	6c88                	ld	a0,24(s1)
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	072080e7          	jalr	114(ra) # 800043b0 <ilock>
    stati(f->ip, &st);
    80005346:	fb840593          	addi	a1,s0,-72
    8000534a:	6c88                	ld	a0,24(s1)
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	2ee080e7          	jalr	750(ra) # 8000463a <stati>
    iunlock(f->ip);
    80005354:	6c88                	ld	a0,24(s1)
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	11c080e7          	jalr	284(ra) # 80004472 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000535e:	46e1                	li	a3,24
    80005360:	fb840613          	addi	a2,s0,-72
    80005364:	85ce                	mv	a1,s3
    80005366:	07893503          	ld	a0,120(s2)
    8000536a:	ffffc097          	auipc	ra,0xffffc
    8000536e:	316080e7          	jalr	790(ra) # 80001680 <copyout>
    80005372:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005376:	60a6                	ld	ra,72(sp)
    80005378:	6406                	ld	s0,64(sp)
    8000537a:	74e2                	ld	s1,56(sp)
    8000537c:	7942                	ld	s2,48(sp)
    8000537e:	79a2                	ld	s3,40(sp)
    80005380:	6161                	addi	sp,sp,80
    80005382:	8082                	ret
  return -1;
    80005384:	557d                	li	a0,-1
    80005386:	bfc5                	j	80005376 <filestat+0x60>

0000000080005388 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005388:	7179                	addi	sp,sp,-48
    8000538a:	f406                	sd	ra,40(sp)
    8000538c:	f022                	sd	s0,32(sp)
    8000538e:	ec26                	sd	s1,24(sp)
    80005390:	e84a                	sd	s2,16(sp)
    80005392:	e44e                	sd	s3,8(sp)
    80005394:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005396:	00854783          	lbu	a5,8(a0)
    8000539a:	c3d5                	beqz	a5,8000543e <fileread+0xb6>
    8000539c:	84aa                	mv	s1,a0
    8000539e:	89ae                	mv	s3,a1
    800053a0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800053a2:	411c                	lw	a5,0(a0)
    800053a4:	4705                	li	a4,1
    800053a6:	04e78963          	beq	a5,a4,800053f8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800053aa:	470d                	li	a4,3
    800053ac:	04e78d63          	beq	a5,a4,80005406 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800053b0:	4709                	li	a4,2
    800053b2:	06e79e63          	bne	a5,a4,8000542e <fileread+0xa6>
    ilock(f->ip);
    800053b6:	6d08                	ld	a0,24(a0)
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	ff8080e7          	jalr	-8(ra) # 800043b0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800053c0:	874a                	mv	a4,s2
    800053c2:	5094                	lw	a3,32(s1)
    800053c4:	864e                	mv	a2,s3
    800053c6:	4585                	li	a1,1
    800053c8:	6c88                	ld	a0,24(s1)
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	29a080e7          	jalr	666(ra) # 80004664 <readi>
    800053d2:	892a                	mv	s2,a0
    800053d4:	00a05563          	blez	a0,800053de <fileread+0x56>
      f->off += r;
    800053d8:	509c                	lw	a5,32(s1)
    800053da:	9fa9                	addw	a5,a5,a0
    800053dc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800053de:	6c88                	ld	a0,24(s1)
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	092080e7          	jalr	146(ra) # 80004472 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800053e8:	854a                	mv	a0,s2
    800053ea:	70a2                	ld	ra,40(sp)
    800053ec:	7402                	ld	s0,32(sp)
    800053ee:	64e2                	ld	s1,24(sp)
    800053f0:	6942                	ld	s2,16(sp)
    800053f2:	69a2                	ld	s3,8(sp)
    800053f4:	6145                	addi	sp,sp,48
    800053f6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800053f8:	6908                	ld	a0,16(a0)
    800053fa:	00000097          	auipc	ra,0x0
    800053fe:	3c8080e7          	jalr	968(ra) # 800057c2 <piperead>
    80005402:	892a                	mv	s2,a0
    80005404:	b7d5                	j	800053e8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005406:	02451783          	lh	a5,36(a0)
    8000540a:	03079693          	slli	a3,a5,0x30
    8000540e:	92c1                	srli	a3,a3,0x30
    80005410:	4725                	li	a4,9
    80005412:	02d76863          	bltu	a4,a3,80005442 <fileread+0xba>
    80005416:	0792                	slli	a5,a5,0x4
    80005418:	0001d717          	auipc	a4,0x1d
    8000541c:	81070713          	addi	a4,a4,-2032 # 80021c28 <devsw>
    80005420:	97ba                	add	a5,a5,a4
    80005422:	639c                	ld	a5,0(a5)
    80005424:	c38d                	beqz	a5,80005446 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005426:	4505                	li	a0,1
    80005428:	9782                	jalr	a5
    8000542a:	892a                	mv	s2,a0
    8000542c:	bf75                	j	800053e8 <fileread+0x60>
    panic("fileread");
    8000542e:	00003517          	auipc	a0,0x3
    80005432:	41250513          	addi	a0,a0,1042 # 80008840 <syscalls+0x268>
    80005436:	ffffb097          	auipc	ra,0xffffb
    8000543a:	108080e7          	jalr	264(ra) # 8000053e <panic>
    return -1;
    8000543e:	597d                	li	s2,-1
    80005440:	b765                	j	800053e8 <fileread+0x60>
      return -1;
    80005442:	597d                	li	s2,-1
    80005444:	b755                	j	800053e8 <fileread+0x60>
    80005446:	597d                	li	s2,-1
    80005448:	b745                	j	800053e8 <fileread+0x60>

000000008000544a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000544a:	715d                	addi	sp,sp,-80
    8000544c:	e486                	sd	ra,72(sp)
    8000544e:	e0a2                	sd	s0,64(sp)
    80005450:	fc26                	sd	s1,56(sp)
    80005452:	f84a                	sd	s2,48(sp)
    80005454:	f44e                	sd	s3,40(sp)
    80005456:	f052                	sd	s4,32(sp)
    80005458:	ec56                	sd	s5,24(sp)
    8000545a:	e85a                	sd	s6,16(sp)
    8000545c:	e45e                	sd	s7,8(sp)
    8000545e:	e062                	sd	s8,0(sp)
    80005460:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005462:	00954783          	lbu	a5,9(a0)
    80005466:	10078663          	beqz	a5,80005572 <filewrite+0x128>
    8000546a:	892a                	mv	s2,a0
    8000546c:	8aae                	mv	s5,a1
    8000546e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005470:	411c                	lw	a5,0(a0)
    80005472:	4705                	li	a4,1
    80005474:	02e78263          	beq	a5,a4,80005498 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005478:	470d                	li	a4,3
    8000547a:	02e78663          	beq	a5,a4,800054a6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000547e:	4709                	li	a4,2
    80005480:	0ee79163          	bne	a5,a4,80005562 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005484:	0ac05d63          	blez	a2,8000553e <filewrite+0xf4>
    int i = 0;
    80005488:	4981                	li	s3,0
    8000548a:	6b05                	lui	s6,0x1
    8000548c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005490:	6b85                	lui	s7,0x1
    80005492:	c00b8b9b          	addiw	s7,s7,-1024
    80005496:	a861                	j	8000552e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005498:	6908                	ld	a0,16(a0)
    8000549a:	00000097          	auipc	ra,0x0
    8000549e:	22e080e7          	jalr	558(ra) # 800056c8 <pipewrite>
    800054a2:	8a2a                	mv	s4,a0
    800054a4:	a045                	j	80005544 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800054a6:	02451783          	lh	a5,36(a0)
    800054aa:	03079693          	slli	a3,a5,0x30
    800054ae:	92c1                	srli	a3,a3,0x30
    800054b0:	4725                	li	a4,9
    800054b2:	0cd76263          	bltu	a4,a3,80005576 <filewrite+0x12c>
    800054b6:	0792                	slli	a5,a5,0x4
    800054b8:	0001c717          	auipc	a4,0x1c
    800054bc:	77070713          	addi	a4,a4,1904 # 80021c28 <devsw>
    800054c0:	97ba                	add	a5,a5,a4
    800054c2:	679c                	ld	a5,8(a5)
    800054c4:	cbdd                	beqz	a5,8000557a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800054c6:	4505                	li	a0,1
    800054c8:	9782                	jalr	a5
    800054ca:	8a2a                	mv	s4,a0
    800054cc:	a8a5                	j	80005544 <filewrite+0xfa>
    800054ce:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800054d2:	00000097          	auipc	ra,0x0
    800054d6:	8b0080e7          	jalr	-1872(ra) # 80004d82 <begin_op>
      ilock(f->ip);
    800054da:	01893503          	ld	a0,24(s2)
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	ed2080e7          	jalr	-302(ra) # 800043b0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800054e6:	8762                	mv	a4,s8
    800054e8:	02092683          	lw	a3,32(s2)
    800054ec:	01598633          	add	a2,s3,s5
    800054f0:	4585                	li	a1,1
    800054f2:	01893503          	ld	a0,24(s2)
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	266080e7          	jalr	614(ra) # 8000475c <writei>
    800054fe:	84aa                	mv	s1,a0
    80005500:	00a05763          	blez	a0,8000550e <filewrite+0xc4>
        f->off += r;
    80005504:	02092783          	lw	a5,32(s2)
    80005508:	9fa9                	addw	a5,a5,a0
    8000550a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000550e:	01893503          	ld	a0,24(s2)
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	f60080e7          	jalr	-160(ra) # 80004472 <iunlock>
      end_op();
    8000551a:	00000097          	auipc	ra,0x0
    8000551e:	8e8080e7          	jalr	-1816(ra) # 80004e02 <end_op>

      if(r != n1){
    80005522:	009c1f63          	bne	s8,s1,80005540 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005526:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000552a:	0149db63          	bge	s3,s4,80005540 <filewrite+0xf6>
      int n1 = n - i;
    8000552e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005532:	84be                	mv	s1,a5
    80005534:	2781                	sext.w	a5,a5
    80005536:	f8fb5ce3          	bge	s6,a5,800054ce <filewrite+0x84>
    8000553a:	84de                	mv	s1,s7
    8000553c:	bf49                	j	800054ce <filewrite+0x84>
    int i = 0;
    8000553e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005540:	013a1f63          	bne	s4,s3,8000555e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005544:	8552                	mv	a0,s4
    80005546:	60a6                	ld	ra,72(sp)
    80005548:	6406                	ld	s0,64(sp)
    8000554a:	74e2                	ld	s1,56(sp)
    8000554c:	7942                	ld	s2,48(sp)
    8000554e:	79a2                	ld	s3,40(sp)
    80005550:	7a02                	ld	s4,32(sp)
    80005552:	6ae2                	ld	s5,24(sp)
    80005554:	6b42                	ld	s6,16(sp)
    80005556:	6ba2                	ld	s7,8(sp)
    80005558:	6c02                	ld	s8,0(sp)
    8000555a:	6161                	addi	sp,sp,80
    8000555c:	8082                	ret
    ret = (i == n ? n : -1);
    8000555e:	5a7d                	li	s4,-1
    80005560:	b7d5                	j	80005544 <filewrite+0xfa>
    panic("filewrite");
    80005562:	00003517          	auipc	a0,0x3
    80005566:	2ee50513          	addi	a0,a0,750 # 80008850 <syscalls+0x278>
    8000556a:	ffffb097          	auipc	ra,0xffffb
    8000556e:	fd4080e7          	jalr	-44(ra) # 8000053e <panic>
    return -1;
    80005572:	5a7d                	li	s4,-1
    80005574:	bfc1                	j	80005544 <filewrite+0xfa>
      return -1;
    80005576:	5a7d                	li	s4,-1
    80005578:	b7f1                	j	80005544 <filewrite+0xfa>
    8000557a:	5a7d                	li	s4,-1
    8000557c:	b7e1                	j	80005544 <filewrite+0xfa>

000000008000557e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000557e:	7179                	addi	sp,sp,-48
    80005580:	f406                	sd	ra,40(sp)
    80005582:	f022                	sd	s0,32(sp)
    80005584:	ec26                	sd	s1,24(sp)
    80005586:	e84a                	sd	s2,16(sp)
    80005588:	e44e                	sd	s3,8(sp)
    8000558a:	e052                	sd	s4,0(sp)
    8000558c:	1800                	addi	s0,sp,48
    8000558e:	84aa                	mv	s1,a0
    80005590:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005592:	0005b023          	sd	zero,0(a1)
    80005596:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000559a:	00000097          	auipc	ra,0x0
    8000559e:	bf8080e7          	jalr	-1032(ra) # 80005192 <filealloc>
    800055a2:	e088                	sd	a0,0(s1)
    800055a4:	c551                	beqz	a0,80005630 <pipealloc+0xb2>
    800055a6:	00000097          	auipc	ra,0x0
    800055aa:	bec080e7          	jalr	-1044(ra) # 80005192 <filealloc>
    800055ae:	00aa3023          	sd	a0,0(s4)
    800055b2:	c92d                	beqz	a0,80005624 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800055b4:	ffffb097          	auipc	ra,0xffffb
    800055b8:	540080e7          	jalr	1344(ra) # 80000af4 <kalloc>
    800055bc:	892a                	mv	s2,a0
    800055be:	c125                	beqz	a0,8000561e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800055c0:	4985                	li	s3,1
    800055c2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800055c6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800055ca:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800055ce:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800055d2:	00003597          	auipc	a1,0x3
    800055d6:	28e58593          	addi	a1,a1,654 # 80008860 <syscalls+0x288>
    800055da:	ffffb097          	auipc	ra,0xffffb
    800055de:	57a080e7          	jalr	1402(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800055e2:	609c                	ld	a5,0(s1)
    800055e4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800055e8:	609c                	ld	a5,0(s1)
    800055ea:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800055ee:	609c                	ld	a5,0(s1)
    800055f0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800055f4:	609c                	ld	a5,0(s1)
    800055f6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800055fa:	000a3783          	ld	a5,0(s4)
    800055fe:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005602:	000a3783          	ld	a5,0(s4)
    80005606:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000560a:	000a3783          	ld	a5,0(s4)
    8000560e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005612:	000a3783          	ld	a5,0(s4)
    80005616:	0127b823          	sd	s2,16(a5)
  return 0;
    8000561a:	4501                	li	a0,0
    8000561c:	a025                	j	80005644 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000561e:	6088                	ld	a0,0(s1)
    80005620:	e501                	bnez	a0,80005628 <pipealloc+0xaa>
    80005622:	a039                	j	80005630 <pipealloc+0xb2>
    80005624:	6088                	ld	a0,0(s1)
    80005626:	c51d                	beqz	a0,80005654 <pipealloc+0xd6>
    fileclose(*f0);
    80005628:	00000097          	auipc	ra,0x0
    8000562c:	c26080e7          	jalr	-986(ra) # 8000524e <fileclose>
  if(*f1)
    80005630:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005634:	557d                	li	a0,-1
  if(*f1)
    80005636:	c799                	beqz	a5,80005644 <pipealloc+0xc6>
    fileclose(*f1);
    80005638:	853e                	mv	a0,a5
    8000563a:	00000097          	auipc	ra,0x0
    8000563e:	c14080e7          	jalr	-1004(ra) # 8000524e <fileclose>
  return -1;
    80005642:	557d                	li	a0,-1
}
    80005644:	70a2                	ld	ra,40(sp)
    80005646:	7402                	ld	s0,32(sp)
    80005648:	64e2                	ld	s1,24(sp)
    8000564a:	6942                	ld	s2,16(sp)
    8000564c:	69a2                	ld	s3,8(sp)
    8000564e:	6a02                	ld	s4,0(sp)
    80005650:	6145                	addi	sp,sp,48
    80005652:	8082                	ret
  return -1;
    80005654:	557d                	li	a0,-1
    80005656:	b7fd                	j	80005644 <pipealloc+0xc6>

0000000080005658 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005658:	1101                	addi	sp,sp,-32
    8000565a:	ec06                	sd	ra,24(sp)
    8000565c:	e822                	sd	s0,16(sp)
    8000565e:	e426                	sd	s1,8(sp)
    80005660:	e04a                	sd	s2,0(sp)
    80005662:	1000                	addi	s0,sp,32
    80005664:	84aa                	mv	s1,a0
    80005666:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005668:	ffffb097          	auipc	ra,0xffffb
    8000566c:	584080e7          	jalr	1412(ra) # 80000bec <acquire>
  if(writable){
    80005670:	02090d63          	beqz	s2,800056aa <pipeclose+0x52>
    pi->writeopen = 0;
    80005674:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005678:	21848513          	addi	a0,s1,536
    8000567c:	ffffd097          	auipc	ra,0xffffd
    80005680:	7b4080e7          	jalr	1972(ra) # 80002e30 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005684:	2204b783          	ld	a5,544(s1)
    80005688:	eb95                	bnez	a5,800056bc <pipeclose+0x64>
    release(&pi->lock);
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffb097          	auipc	ra,0xffffb
    80005690:	61a080e7          	jalr	1562(ra) # 80000ca6 <release>
    kfree((char*)pi);
    80005694:	8526                	mv	a0,s1
    80005696:	ffffb097          	auipc	ra,0xffffb
    8000569a:	362080e7          	jalr	866(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000569e:	60e2                	ld	ra,24(sp)
    800056a0:	6442                	ld	s0,16(sp)
    800056a2:	64a2                	ld	s1,8(sp)
    800056a4:	6902                	ld	s2,0(sp)
    800056a6:	6105                	addi	sp,sp,32
    800056a8:	8082                	ret
    pi->readopen = 0;
    800056aa:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800056ae:	21c48513          	addi	a0,s1,540
    800056b2:	ffffd097          	auipc	ra,0xffffd
    800056b6:	77e080e7          	jalr	1918(ra) # 80002e30 <wakeup>
    800056ba:	b7e9                	j	80005684 <pipeclose+0x2c>
    release(&pi->lock);
    800056bc:	8526                	mv	a0,s1
    800056be:	ffffb097          	auipc	ra,0xffffb
    800056c2:	5e8080e7          	jalr	1512(ra) # 80000ca6 <release>
}
    800056c6:	bfe1                	j	8000569e <pipeclose+0x46>

00000000800056c8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800056c8:	7159                	addi	sp,sp,-112
    800056ca:	f486                	sd	ra,104(sp)
    800056cc:	f0a2                	sd	s0,96(sp)
    800056ce:	eca6                	sd	s1,88(sp)
    800056d0:	e8ca                	sd	s2,80(sp)
    800056d2:	e4ce                	sd	s3,72(sp)
    800056d4:	e0d2                	sd	s4,64(sp)
    800056d6:	fc56                	sd	s5,56(sp)
    800056d8:	f85a                	sd	s6,48(sp)
    800056da:	f45e                	sd	s7,40(sp)
    800056dc:	f062                	sd	s8,32(sp)
    800056de:	ec66                	sd	s9,24(sp)
    800056e0:	1880                	addi	s0,sp,112
    800056e2:	84aa                	mv	s1,a0
    800056e4:	8aae                	mv	s5,a1
    800056e6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800056e8:	ffffc097          	auipc	ra,0xffffc
    800056ec:	724080e7          	jalr	1828(ra) # 80001e0c <myproc>
    800056f0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800056f2:	8526                	mv	a0,s1
    800056f4:	ffffb097          	auipc	ra,0xffffb
    800056f8:	4f8080e7          	jalr	1272(ra) # 80000bec <acquire>
  while(i < n){
    800056fc:	0d405163          	blez	s4,800057be <pipewrite+0xf6>
    80005700:	8ba6                	mv	s7,s1
  int i = 0;
    80005702:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005704:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005706:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000570a:	21c48c13          	addi	s8,s1,540
    8000570e:	a08d                	j	80005770 <pipewrite+0xa8>
      release(&pi->lock);
    80005710:	8526                	mv	a0,s1
    80005712:	ffffb097          	auipc	ra,0xffffb
    80005716:	594080e7          	jalr	1428(ra) # 80000ca6 <release>
      return -1;
    8000571a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000571c:	854a                	mv	a0,s2
    8000571e:	70a6                	ld	ra,104(sp)
    80005720:	7406                	ld	s0,96(sp)
    80005722:	64e6                	ld	s1,88(sp)
    80005724:	6946                	ld	s2,80(sp)
    80005726:	69a6                	ld	s3,72(sp)
    80005728:	6a06                	ld	s4,64(sp)
    8000572a:	7ae2                	ld	s5,56(sp)
    8000572c:	7b42                	ld	s6,48(sp)
    8000572e:	7ba2                	ld	s7,40(sp)
    80005730:	7c02                	ld	s8,32(sp)
    80005732:	6ce2                	ld	s9,24(sp)
    80005734:	6165                	addi	sp,sp,112
    80005736:	8082                	ret
      wakeup(&pi->nread);
    80005738:	8566                	mv	a0,s9
    8000573a:	ffffd097          	auipc	ra,0xffffd
    8000573e:	6f6080e7          	jalr	1782(ra) # 80002e30 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005742:	85de                	mv	a1,s7
    80005744:	8562                	mv	a0,s8
    80005746:	ffffd097          	auipc	ra,0xffffd
    8000574a:	544080e7          	jalr	1348(ra) # 80002c8a <sleep>
    8000574e:	a839                	j	8000576c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005750:	21c4a783          	lw	a5,540(s1)
    80005754:	0017871b          	addiw	a4,a5,1
    80005758:	20e4ae23          	sw	a4,540(s1)
    8000575c:	1ff7f793          	andi	a5,a5,511
    80005760:	97a6                	add	a5,a5,s1
    80005762:	f9f44703          	lbu	a4,-97(s0)
    80005766:	00e78c23          	sb	a4,24(a5)
      i++;
    8000576a:	2905                	addiw	s2,s2,1
  while(i < n){
    8000576c:	03495d63          	bge	s2,s4,800057a6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005770:	2204a783          	lw	a5,544(s1)
    80005774:	dfd1                	beqz	a5,80005710 <pipewrite+0x48>
    80005776:	0409a783          	lw	a5,64(s3)
    8000577a:	fbd9                	bnez	a5,80005710 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000577c:	2184a783          	lw	a5,536(s1)
    80005780:	21c4a703          	lw	a4,540(s1)
    80005784:	2007879b          	addiw	a5,a5,512
    80005788:	faf708e3          	beq	a4,a5,80005738 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000578c:	4685                	li	a3,1
    8000578e:	01590633          	add	a2,s2,s5
    80005792:	f9f40593          	addi	a1,s0,-97
    80005796:	0789b503          	ld	a0,120(s3)
    8000579a:	ffffc097          	auipc	ra,0xffffc
    8000579e:	f72080e7          	jalr	-142(ra) # 8000170c <copyin>
    800057a2:	fb6517e3          	bne	a0,s6,80005750 <pipewrite+0x88>
  wakeup(&pi->nread);
    800057a6:	21848513          	addi	a0,s1,536
    800057aa:	ffffd097          	auipc	ra,0xffffd
    800057ae:	686080e7          	jalr	1670(ra) # 80002e30 <wakeup>
  release(&pi->lock);
    800057b2:	8526                	mv	a0,s1
    800057b4:	ffffb097          	auipc	ra,0xffffb
    800057b8:	4f2080e7          	jalr	1266(ra) # 80000ca6 <release>
  return i;
    800057bc:	b785                	j	8000571c <pipewrite+0x54>
  int i = 0;
    800057be:	4901                	li	s2,0
    800057c0:	b7dd                	j	800057a6 <pipewrite+0xde>

00000000800057c2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800057c2:	715d                	addi	sp,sp,-80
    800057c4:	e486                	sd	ra,72(sp)
    800057c6:	e0a2                	sd	s0,64(sp)
    800057c8:	fc26                	sd	s1,56(sp)
    800057ca:	f84a                	sd	s2,48(sp)
    800057cc:	f44e                	sd	s3,40(sp)
    800057ce:	f052                	sd	s4,32(sp)
    800057d0:	ec56                	sd	s5,24(sp)
    800057d2:	e85a                	sd	s6,16(sp)
    800057d4:	0880                	addi	s0,sp,80
    800057d6:	84aa                	mv	s1,a0
    800057d8:	892e                	mv	s2,a1
    800057da:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800057dc:	ffffc097          	auipc	ra,0xffffc
    800057e0:	630080e7          	jalr	1584(ra) # 80001e0c <myproc>
    800057e4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800057e6:	8b26                	mv	s6,s1
    800057e8:	8526                	mv	a0,s1
    800057ea:	ffffb097          	auipc	ra,0xffffb
    800057ee:	402080e7          	jalr	1026(ra) # 80000bec <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057f2:	2184a703          	lw	a4,536(s1)
    800057f6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800057fa:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800057fe:	02f71463          	bne	a4,a5,80005826 <piperead+0x64>
    80005802:	2244a783          	lw	a5,548(s1)
    80005806:	c385                	beqz	a5,80005826 <piperead+0x64>
    if(pr->killed){
    80005808:	040a2783          	lw	a5,64(s4)
    8000580c:	ebc1                	bnez	a5,8000589c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000580e:	85da                	mv	a1,s6
    80005810:	854e                	mv	a0,s3
    80005812:	ffffd097          	auipc	ra,0xffffd
    80005816:	478080e7          	jalr	1144(ra) # 80002c8a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000581a:	2184a703          	lw	a4,536(s1)
    8000581e:	21c4a783          	lw	a5,540(s1)
    80005822:	fef700e3          	beq	a4,a5,80005802 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005826:	09505263          	blez	s5,800058aa <piperead+0xe8>
    8000582a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000582c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000582e:	2184a783          	lw	a5,536(s1)
    80005832:	21c4a703          	lw	a4,540(s1)
    80005836:	02f70d63          	beq	a4,a5,80005870 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000583a:	0017871b          	addiw	a4,a5,1
    8000583e:	20e4ac23          	sw	a4,536(s1)
    80005842:	1ff7f793          	andi	a5,a5,511
    80005846:	97a6                	add	a5,a5,s1
    80005848:	0187c783          	lbu	a5,24(a5)
    8000584c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005850:	4685                	li	a3,1
    80005852:	fbf40613          	addi	a2,s0,-65
    80005856:	85ca                	mv	a1,s2
    80005858:	078a3503          	ld	a0,120(s4)
    8000585c:	ffffc097          	auipc	ra,0xffffc
    80005860:	e24080e7          	jalr	-476(ra) # 80001680 <copyout>
    80005864:	01650663          	beq	a0,s6,80005870 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005868:	2985                	addiw	s3,s3,1
    8000586a:	0905                	addi	s2,s2,1
    8000586c:	fd3a91e3          	bne	s5,s3,8000582e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005870:	21c48513          	addi	a0,s1,540
    80005874:	ffffd097          	auipc	ra,0xffffd
    80005878:	5bc080e7          	jalr	1468(ra) # 80002e30 <wakeup>
  release(&pi->lock);
    8000587c:	8526                	mv	a0,s1
    8000587e:	ffffb097          	auipc	ra,0xffffb
    80005882:	428080e7          	jalr	1064(ra) # 80000ca6 <release>
  return i;
}
    80005886:	854e                	mv	a0,s3
    80005888:	60a6                	ld	ra,72(sp)
    8000588a:	6406                	ld	s0,64(sp)
    8000588c:	74e2                	ld	s1,56(sp)
    8000588e:	7942                	ld	s2,48(sp)
    80005890:	79a2                	ld	s3,40(sp)
    80005892:	7a02                	ld	s4,32(sp)
    80005894:	6ae2                	ld	s5,24(sp)
    80005896:	6b42                	ld	s6,16(sp)
    80005898:	6161                	addi	sp,sp,80
    8000589a:	8082                	ret
      release(&pi->lock);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffb097          	auipc	ra,0xffffb
    800058a2:	408080e7          	jalr	1032(ra) # 80000ca6 <release>
      return -1;
    800058a6:	59fd                	li	s3,-1
    800058a8:	bff9                	j	80005886 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800058aa:	4981                	li	s3,0
    800058ac:	b7d1                	j	80005870 <piperead+0xae>

00000000800058ae <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800058ae:	df010113          	addi	sp,sp,-528
    800058b2:	20113423          	sd	ra,520(sp)
    800058b6:	20813023          	sd	s0,512(sp)
    800058ba:	ffa6                	sd	s1,504(sp)
    800058bc:	fbca                	sd	s2,496(sp)
    800058be:	f7ce                	sd	s3,488(sp)
    800058c0:	f3d2                	sd	s4,480(sp)
    800058c2:	efd6                	sd	s5,472(sp)
    800058c4:	ebda                	sd	s6,464(sp)
    800058c6:	e7de                	sd	s7,456(sp)
    800058c8:	e3e2                	sd	s8,448(sp)
    800058ca:	ff66                	sd	s9,440(sp)
    800058cc:	fb6a                	sd	s10,432(sp)
    800058ce:	f76e                	sd	s11,424(sp)
    800058d0:	0c00                	addi	s0,sp,528
    800058d2:	84aa                	mv	s1,a0
    800058d4:	dea43c23          	sd	a0,-520(s0)
    800058d8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800058dc:	ffffc097          	auipc	ra,0xffffc
    800058e0:	530080e7          	jalr	1328(ra) # 80001e0c <myproc>
    800058e4:	892a                	mv	s2,a0

  begin_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	49c080e7          	jalr	1180(ra) # 80004d82 <begin_op>

  if((ip = namei(path)) == 0){
    800058ee:	8526                	mv	a0,s1
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	276080e7          	jalr	630(ra) # 80004b66 <namei>
    800058f8:	c92d                	beqz	a0,8000596a <exec+0xbc>
    800058fa:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	ab4080e7          	jalr	-1356(ra) # 800043b0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005904:	04000713          	li	a4,64
    80005908:	4681                	li	a3,0
    8000590a:	e5040613          	addi	a2,s0,-432
    8000590e:	4581                	li	a1,0
    80005910:	8526                	mv	a0,s1
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	d52080e7          	jalr	-686(ra) # 80004664 <readi>
    8000591a:	04000793          	li	a5,64
    8000591e:	00f51a63          	bne	a0,a5,80005932 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005922:	e5042703          	lw	a4,-432(s0)
    80005926:	464c47b7          	lui	a5,0x464c4
    8000592a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000592e:	04f70463          	beq	a4,a5,80005976 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005932:	8526                	mv	a0,s1
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	cde080e7          	jalr	-802(ra) # 80004612 <iunlockput>
    end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	4c6080e7          	jalr	1222(ra) # 80004e02 <end_op>
  }
  return -1;
    80005944:	557d                	li	a0,-1
}
    80005946:	20813083          	ld	ra,520(sp)
    8000594a:	20013403          	ld	s0,512(sp)
    8000594e:	74fe                	ld	s1,504(sp)
    80005950:	795e                	ld	s2,496(sp)
    80005952:	79be                	ld	s3,488(sp)
    80005954:	7a1e                	ld	s4,480(sp)
    80005956:	6afe                	ld	s5,472(sp)
    80005958:	6b5e                	ld	s6,464(sp)
    8000595a:	6bbe                	ld	s7,456(sp)
    8000595c:	6c1e                	ld	s8,448(sp)
    8000595e:	7cfa                	ld	s9,440(sp)
    80005960:	7d5a                	ld	s10,432(sp)
    80005962:	7dba                	ld	s11,424(sp)
    80005964:	21010113          	addi	sp,sp,528
    80005968:	8082                	ret
    end_op();
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	498080e7          	jalr	1176(ra) # 80004e02 <end_op>
    return -1;
    80005972:	557d                	li	a0,-1
    80005974:	bfc9                	j	80005946 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005976:	854a                	mv	a0,s2
    80005978:	ffffc097          	auipc	ra,0xffffc
    8000597c:	56c080e7          	jalr	1388(ra) # 80001ee4 <proc_pagetable>
    80005980:	8baa                	mv	s7,a0
    80005982:	d945                	beqz	a0,80005932 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005984:	e7042983          	lw	s3,-400(s0)
    80005988:	e8845783          	lhu	a5,-376(s0)
    8000598c:	c7ad                	beqz	a5,800059f6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000598e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005990:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005992:	6c85                	lui	s9,0x1
    80005994:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005998:	def43823          	sd	a5,-528(s0)
    8000599c:	a42d                	j	80005bc6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000599e:	00003517          	auipc	a0,0x3
    800059a2:	eca50513          	addi	a0,a0,-310 # 80008868 <syscalls+0x290>
    800059a6:	ffffb097          	auipc	ra,0xffffb
    800059aa:	b98080e7          	jalr	-1128(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800059ae:	8756                	mv	a4,s5
    800059b0:	012d86bb          	addw	a3,s11,s2
    800059b4:	4581                	li	a1,0
    800059b6:	8526                	mv	a0,s1
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	cac080e7          	jalr	-852(ra) # 80004664 <readi>
    800059c0:	2501                	sext.w	a0,a0
    800059c2:	1aaa9963          	bne	s5,a0,80005b74 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800059c6:	6785                	lui	a5,0x1
    800059c8:	0127893b          	addw	s2,a5,s2
    800059cc:	77fd                	lui	a5,0xfffff
    800059ce:	01478a3b          	addw	s4,a5,s4
    800059d2:	1f897163          	bgeu	s2,s8,80005bb4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800059d6:	02091593          	slli	a1,s2,0x20
    800059da:	9181                	srli	a1,a1,0x20
    800059dc:	95ea                	add	a1,a1,s10
    800059de:	855e                	mv	a0,s7
    800059e0:	ffffb097          	auipc	ra,0xffffb
    800059e4:	69c080e7          	jalr	1692(ra) # 8000107c <walkaddr>
    800059e8:	862a                	mv	a2,a0
    if(pa == 0)
    800059ea:	d955                	beqz	a0,8000599e <exec+0xf0>
      n = PGSIZE;
    800059ec:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800059ee:	fd9a70e3          	bgeu	s4,s9,800059ae <exec+0x100>
      n = sz - i;
    800059f2:	8ad2                	mv	s5,s4
    800059f4:	bf6d                	j	800059ae <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800059f6:	4901                	li	s2,0
  iunlockput(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	c18080e7          	jalr	-1000(ra) # 80004612 <iunlockput>
  end_op();
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	400080e7          	jalr	1024(ra) # 80004e02 <end_op>
  p = myproc();
    80005a0a:	ffffc097          	auipc	ra,0xffffc
    80005a0e:	402080e7          	jalr	1026(ra) # 80001e0c <myproc>
    80005a12:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005a14:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80005a18:	6785                	lui	a5,0x1
    80005a1a:	17fd                	addi	a5,a5,-1
    80005a1c:	993e                	add	s2,s2,a5
    80005a1e:	757d                	lui	a0,0xfffff
    80005a20:	00a977b3          	and	a5,s2,a0
    80005a24:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005a28:	6609                	lui	a2,0x2
    80005a2a:	963e                	add	a2,a2,a5
    80005a2c:	85be                	mv	a1,a5
    80005a2e:	855e                	mv	a0,s7
    80005a30:	ffffc097          	auipc	ra,0xffffc
    80005a34:	a00080e7          	jalr	-1536(ra) # 80001430 <uvmalloc>
    80005a38:	8b2a                	mv	s6,a0
  ip = 0;
    80005a3a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005a3c:	12050c63          	beqz	a0,80005b74 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005a40:	75f9                	lui	a1,0xffffe
    80005a42:	95aa                	add	a1,a1,a0
    80005a44:	855e                	mv	a0,s7
    80005a46:	ffffc097          	auipc	ra,0xffffc
    80005a4a:	c08080e7          	jalr	-1016(ra) # 8000164e <uvmclear>
  stackbase = sp - PGSIZE;
    80005a4e:	7c7d                	lui	s8,0xfffff
    80005a50:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a52:	e0043783          	ld	a5,-512(s0)
    80005a56:	6388                	ld	a0,0(a5)
    80005a58:	c535                	beqz	a0,80005ac4 <exec+0x216>
    80005a5a:	e9040993          	addi	s3,s0,-368
    80005a5e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005a62:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005a64:	ffffb097          	auipc	ra,0xffffb
    80005a68:	40e080e7          	jalr	1038(ra) # 80000e72 <strlen>
    80005a6c:	2505                	addiw	a0,a0,1
    80005a6e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005a72:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005a76:	13896363          	bltu	s2,s8,80005b9c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005a7a:	e0043d83          	ld	s11,-512(s0)
    80005a7e:	000dba03          	ld	s4,0(s11)
    80005a82:	8552                	mv	a0,s4
    80005a84:	ffffb097          	auipc	ra,0xffffb
    80005a88:	3ee080e7          	jalr	1006(ra) # 80000e72 <strlen>
    80005a8c:	0015069b          	addiw	a3,a0,1
    80005a90:	8652                	mv	a2,s4
    80005a92:	85ca                	mv	a1,s2
    80005a94:	855e                	mv	a0,s7
    80005a96:	ffffc097          	auipc	ra,0xffffc
    80005a9a:	bea080e7          	jalr	-1046(ra) # 80001680 <copyout>
    80005a9e:	10054363          	bltz	a0,80005ba4 <exec+0x2f6>
    ustack[argc] = sp;
    80005aa2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005aa6:	0485                	addi	s1,s1,1
    80005aa8:	008d8793          	addi	a5,s11,8
    80005aac:	e0f43023          	sd	a5,-512(s0)
    80005ab0:	008db503          	ld	a0,8(s11)
    80005ab4:	c911                	beqz	a0,80005ac8 <exec+0x21a>
    if(argc >= MAXARG)
    80005ab6:	09a1                	addi	s3,s3,8
    80005ab8:	fb3c96e3          	bne	s9,s3,80005a64 <exec+0x1b6>
  sz = sz1;
    80005abc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ac0:	4481                	li	s1,0
    80005ac2:	a84d                	j	80005b74 <exec+0x2c6>
  sp = sz;
    80005ac4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005ac6:	4481                	li	s1,0
  ustack[argc] = 0;
    80005ac8:	00349793          	slli	a5,s1,0x3
    80005acc:	f9040713          	addi	a4,s0,-112
    80005ad0:	97ba                	add	a5,a5,a4
    80005ad2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005ad6:	00148693          	addi	a3,s1,1
    80005ada:	068e                	slli	a3,a3,0x3
    80005adc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005ae0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005ae4:	01897663          	bgeu	s2,s8,80005af0 <exec+0x242>
  sz = sz1;
    80005ae8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005aec:	4481                	li	s1,0
    80005aee:	a059                	j	80005b74 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005af0:	e9040613          	addi	a2,s0,-368
    80005af4:	85ca                	mv	a1,s2
    80005af6:	855e                	mv	a0,s7
    80005af8:	ffffc097          	auipc	ra,0xffffc
    80005afc:	b88080e7          	jalr	-1144(ra) # 80001680 <copyout>
    80005b00:	0a054663          	bltz	a0,80005bac <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005b04:	080ab783          	ld	a5,128(s5)
    80005b08:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005b0c:	df843783          	ld	a5,-520(s0)
    80005b10:	0007c703          	lbu	a4,0(a5)
    80005b14:	cf11                	beqz	a4,80005b30 <exec+0x282>
    80005b16:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005b18:	02f00693          	li	a3,47
    80005b1c:	a039                	j	80005b2a <exec+0x27c>
      last = s+1;
    80005b1e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005b22:	0785                	addi	a5,a5,1
    80005b24:	fff7c703          	lbu	a4,-1(a5)
    80005b28:	c701                	beqz	a4,80005b30 <exec+0x282>
    if(*s == '/')
    80005b2a:	fed71ce3          	bne	a4,a3,80005b22 <exec+0x274>
    80005b2e:	bfc5                	j	80005b1e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005b30:	4641                	li	a2,16
    80005b32:	df843583          	ld	a1,-520(s0)
    80005b36:	180a8513          	addi	a0,s5,384
    80005b3a:	ffffb097          	auipc	ra,0xffffb
    80005b3e:	306080e7          	jalr	774(ra) # 80000e40 <safestrcpy>
  oldpagetable = p->pagetable;
    80005b42:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    80005b46:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    80005b4a:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005b4e:	080ab783          	ld	a5,128(s5)
    80005b52:	e6843703          	ld	a4,-408(s0)
    80005b56:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005b58:	080ab783          	ld	a5,128(s5)
    80005b5c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005b60:	85ea                	mv	a1,s10
    80005b62:	ffffc097          	auipc	ra,0xffffc
    80005b66:	41e080e7          	jalr	1054(ra) # 80001f80 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b6a:	0004851b          	sext.w	a0,s1
    80005b6e:	bbe1                	j	80005946 <exec+0x98>
    80005b70:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005b74:	e0843583          	ld	a1,-504(s0)
    80005b78:	855e                	mv	a0,s7
    80005b7a:	ffffc097          	auipc	ra,0xffffc
    80005b7e:	406080e7          	jalr	1030(ra) # 80001f80 <proc_freepagetable>
  if(ip){
    80005b82:	da0498e3          	bnez	s1,80005932 <exec+0x84>
  return -1;
    80005b86:	557d                	li	a0,-1
    80005b88:	bb7d                	j	80005946 <exec+0x98>
    80005b8a:	e1243423          	sd	s2,-504(s0)
    80005b8e:	b7dd                	j	80005b74 <exec+0x2c6>
    80005b90:	e1243423          	sd	s2,-504(s0)
    80005b94:	b7c5                	j	80005b74 <exec+0x2c6>
    80005b96:	e1243423          	sd	s2,-504(s0)
    80005b9a:	bfe9                	j	80005b74 <exec+0x2c6>
  sz = sz1;
    80005b9c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ba0:	4481                	li	s1,0
    80005ba2:	bfc9                	j	80005b74 <exec+0x2c6>
  sz = sz1;
    80005ba4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ba8:	4481                	li	s1,0
    80005baa:	b7e9                	j	80005b74 <exec+0x2c6>
  sz = sz1;
    80005bac:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005bb0:	4481                	li	s1,0
    80005bb2:	b7c9                	j	80005b74 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005bb4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005bb8:	2b05                	addiw	s6,s6,1
    80005bba:	0389899b          	addiw	s3,s3,56
    80005bbe:	e8845783          	lhu	a5,-376(s0)
    80005bc2:	e2fb5be3          	bge	s6,a5,800059f8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005bc6:	2981                	sext.w	s3,s3
    80005bc8:	03800713          	li	a4,56
    80005bcc:	86ce                	mv	a3,s3
    80005bce:	e1840613          	addi	a2,s0,-488
    80005bd2:	4581                	li	a1,0
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	a8e080e7          	jalr	-1394(ra) # 80004664 <readi>
    80005bde:	03800793          	li	a5,56
    80005be2:	f8f517e3          	bne	a0,a5,80005b70 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005be6:	e1842783          	lw	a5,-488(s0)
    80005bea:	4705                	li	a4,1
    80005bec:	fce796e3          	bne	a5,a4,80005bb8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005bf0:	e4043603          	ld	a2,-448(s0)
    80005bf4:	e3843783          	ld	a5,-456(s0)
    80005bf8:	f8f669e3          	bltu	a2,a5,80005b8a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005bfc:	e2843783          	ld	a5,-472(s0)
    80005c00:	963e                	add	a2,a2,a5
    80005c02:	f8f667e3          	bltu	a2,a5,80005b90 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005c06:	85ca                	mv	a1,s2
    80005c08:	855e                	mv	a0,s7
    80005c0a:	ffffc097          	auipc	ra,0xffffc
    80005c0e:	826080e7          	jalr	-2010(ra) # 80001430 <uvmalloc>
    80005c12:	e0a43423          	sd	a0,-504(s0)
    80005c16:	d141                	beqz	a0,80005b96 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005c18:	e2843d03          	ld	s10,-472(s0)
    80005c1c:	df043783          	ld	a5,-528(s0)
    80005c20:	00fd77b3          	and	a5,s10,a5
    80005c24:	fba1                	bnez	a5,80005b74 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005c26:	e2042d83          	lw	s11,-480(s0)
    80005c2a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005c2e:	f80c03e3          	beqz	s8,80005bb4 <exec+0x306>
    80005c32:	8a62                	mv	s4,s8
    80005c34:	4901                	li	s2,0
    80005c36:	b345                	j	800059d6 <exec+0x128>

0000000080005c38 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005c38:	7179                	addi	sp,sp,-48
    80005c3a:	f406                	sd	ra,40(sp)
    80005c3c:	f022                	sd	s0,32(sp)
    80005c3e:	ec26                	sd	s1,24(sp)
    80005c40:	e84a                	sd	s2,16(sp)
    80005c42:	1800                	addi	s0,sp,48
    80005c44:	892e                	mv	s2,a1
    80005c46:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005c48:	fdc40593          	addi	a1,s0,-36
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	ba8080e7          	jalr	-1112(ra) # 800037f4 <argint>
    80005c54:	04054063          	bltz	a0,80005c94 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c58:	fdc42703          	lw	a4,-36(s0)
    80005c5c:	47bd                	li	a5,15
    80005c5e:	02e7ed63          	bltu	a5,a4,80005c98 <argfd+0x60>
    80005c62:	ffffc097          	auipc	ra,0xffffc
    80005c66:	1aa080e7          	jalr	426(ra) # 80001e0c <myproc>
    80005c6a:	fdc42703          	lw	a4,-36(s0)
    80005c6e:	01e70793          	addi	a5,a4,30
    80005c72:	078e                	slli	a5,a5,0x3
    80005c74:	953e                	add	a0,a0,a5
    80005c76:	651c                	ld	a5,8(a0)
    80005c78:	c395                	beqz	a5,80005c9c <argfd+0x64>
    return -1;
  if(pfd)
    80005c7a:	00090463          	beqz	s2,80005c82 <argfd+0x4a>
    *pfd = fd;
    80005c7e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005c82:	4501                	li	a0,0
  if(pf)
    80005c84:	c091                	beqz	s1,80005c88 <argfd+0x50>
    *pf = f;
    80005c86:	e09c                	sd	a5,0(s1)
}
    80005c88:	70a2                	ld	ra,40(sp)
    80005c8a:	7402                	ld	s0,32(sp)
    80005c8c:	64e2                	ld	s1,24(sp)
    80005c8e:	6942                	ld	s2,16(sp)
    80005c90:	6145                	addi	sp,sp,48
    80005c92:	8082                	ret
    return -1;
    80005c94:	557d                	li	a0,-1
    80005c96:	bfcd                	j	80005c88 <argfd+0x50>
    return -1;
    80005c98:	557d                	li	a0,-1
    80005c9a:	b7fd                	j	80005c88 <argfd+0x50>
    80005c9c:	557d                	li	a0,-1
    80005c9e:	b7ed                	j	80005c88 <argfd+0x50>

0000000080005ca0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005ca0:	1101                	addi	sp,sp,-32
    80005ca2:	ec06                	sd	ra,24(sp)
    80005ca4:	e822                	sd	s0,16(sp)
    80005ca6:	e426                	sd	s1,8(sp)
    80005ca8:	1000                	addi	s0,sp,32
    80005caa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005cac:	ffffc097          	auipc	ra,0xffffc
    80005cb0:	160080e7          	jalr	352(ra) # 80001e0c <myproc>
    80005cb4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005cb6:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    80005cba:	4501                	li	a0,0
    80005cbc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005cbe:	6398                	ld	a4,0(a5)
    80005cc0:	cb19                	beqz	a4,80005cd6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005cc2:	2505                	addiw	a0,a0,1
    80005cc4:	07a1                	addi	a5,a5,8
    80005cc6:	fed51ce3          	bne	a0,a3,80005cbe <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005cca:	557d                	li	a0,-1
}
    80005ccc:	60e2                	ld	ra,24(sp)
    80005cce:	6442                	ld	s0,16(sp)
    80005cd0:	64a2                	ld	s1,8(sp)
    80005cd2:	6105                	addi	sp,sp,32
    80005cd4:	8082                	ret
      p->ofile[fd] = f;
    80005cd6:	01e50793          	addi	a5,a0,30
    80005cda:	078e                	slli	a5,a5,0x3
    80005cdc:	963e                	add	a2,a2,a5
    80005cde:	e604                	sd	s1,8(a2)
      return fd;
    80005ce0:	b7f5                	j	80005ccc <fdalloc+0x2c>

0000000080005ce2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005ce2:	715d                	addi	sp,sp,-80
    80005ce4:	e486                	sd	ra,72(sp)
    80005ce6:	e0a2                	sd	s0,64(sp)
    80005ce8:	fc26                	sd	s1,56(sp)
    80005cea:	f84a                	sd	s2,48(sp)
    80005cec:	f44e                	sd	s3,40(sp)
    80005cee:	f052                	sd	s4,32(sp)
    80005cf0:	ec56                	sd	s5,24(sp)
    80005cf2:	0880                	addi	s0,sp,80
    80005cf4:	89ae                	mv	s3,a1
    80005cf6:	8ab2                	mv	s5,a2
    80005cf8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005cfa:	fb040593          	addi	a1,s0,-80
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	e86080e7          	jalr	-378(ra) # 80004b84 <nameiparent>
    80005d06:	892a                	mv	s2,a0
    80005d08:	12050f63          	beqz	a0,80005e46 <create+0x164>
    return 0;

  ilock(dp);
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	6a4080e7          	jalr	1700(ra) # 800043b0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005d14:	4601                	li	a2,0
    80005d16:	fb040593          	addi	a1,s0,-80
    80005d1a:	854a                	mv	a0,s2
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	b78080e7          	jalr	-1160(ra) # 80004894 <dirlookup>
    80005d24:	84aa                	mv	s1,a0
    80005d26:	c921                	beqz	a0,80005d76 <create+0x94>
    iunlockput(dp);
    80005d28:	854a                	mv	a0,s2
    80005d2a:	fffff097          	auipc	ra,0xfffff
    80005d2e:	8e8080e7          	jalr	-1816(ra) # 80004612 <iunlockput>
    ilock(ip);
    80005d32:	8526                	mv	a0,s1
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	67c080e7          	jalr	1660(ra) # 800043b0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005d3c:	2981                	sext.w	s3,s3
    80005d3e:	4789                	li	a5,2
    80005d40:	02f99463          	bne	s3,a5,80005d68 <create+0x86>
    80005d44:	0444d783          	lhu	a5,68(s1)
    80005d48:	37f9                	addiw	a5,a5,-2
    80005d4a:	17c2                	slli	a5,a5,0x30
    80005d4c:	93c1                	srli	a5,a5,0x30
    80005d4e:	4705                	li	a4,1
    80005d50:	00f76c63          	bltu	a4,a5,80005d68 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005d54:	8526                	mv	a0,s1
    80005d56:	60a6                	ld	ra,72(sp)
    80005d58:	6406                	ld	s0,64(sp)
    80005d5a:	74e2                	ld	s1,56(sp)
    80005d5c:	7942                	ld	s2,48(sp)
    80005d5e:	79a2                	ld	s3,40(sp)
    80005d60:	7a02                	ld	s4,32(sp)
    80005d62:	6ae2                	ld	s5,24(sp)
    80005d64:	6161                	addi	sp,sp,80
    80005d66:	8082                	ret
    iunlockput(ip);
    80005d68:	8526                	mv	a0,s1
    80005d6a:	fffff097          	auipc	ra,0xfffff
    80005d6e:	8a8080e7          	jalr	-1880(ra) # 80004612 <iunlockput>
    return 0;
    80005d72:	4481                	li	s1,0
    80005d74:	b7c5                	j	80005d54 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005d76:	85ce                	mv	a1,s3
    80005d78:	00092503          	lw	a0,0(s2)
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	49c080e7          	jalr	1180(ra) # 80004218 <ialloc>
    80005d84:	84aa                	mv	s1,a0
    80005d86:	c529                	beqz	a0,80005dd0 <create+0xee>
  ilock(ip);
    80005d88:	ffffe097          	auipc	ra,0xffffe
    80005d8c:	628080e7          	jalr	1576(ra) # 800043b0 <ilock>
  ip->major = major;
    80005d90:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005d94:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005d98:	4785                	li	a5,1
    80005d9a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d9e:	8526                	mv	a0,s1
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	546080e7          	jalr	1350(ra) # 800042e6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005da8:	2981                	sext.w	s3,s3
    80005daa:	4785                	li	a5,1
    80005dac:	02f98a63          	beq	s3,a5,80005de0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005db0:	40d0                	lw	a2,4(s1)
    80005db2:	fb040593          	addi	a1,s0,-80
    80005db6:	854a                	mv	a0,s2
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	cec080e7          	jalr	-788(ra) # 80004aa4 <dirlink>
    80005dc0:	06054b63          	bltz	a0,80005e36 <create+0x154>
  iunlockput(dp);
    80005dc4:	854a                	mv	a0,s2
    80005dc6:	fffff097          	auipc	ra,0xfffff
    80005dca:	84c080e7          	jalr	-1972(ra) # 80004612 <iunlockput>
  return ip;
    80005dce:	b759                	j	80005d54 <create+0x72>
    panic("create: ialloc");
    80005dd0:	00003517          	auipc	a0,0x3
    80005dd4:	ab850513          	addi	a0,a0,-1352 # 80008888 <syscalls+0x2b0>
    80005dd8:	ffffa097          	auipc	ra,0xffffa
    80005ddc:	766080e7          	jalr	1894(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005de0:	04a95783          	lhu	a5,74(s2)
    80005de4:	2785                	addiw	a5,a5,1
    80005de6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005dea:	854a                	mv	a0,s2
    80005dec:	ffffe097          	auipc	ra,0xffffe
    80005df0:	4fa080e7          	jalr	1274(ra) # 800042e6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005df4:	40d0                	lw	a2,4(s1)
    80005df6:	00003597          	auipc	a1,0x3
    80005dfa:	aa258593          	addi	a1,a1,-1374 # 80008898 <syscalls+0x2c0>
    80005dfe:	8526                	mv	a0,s1
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	ca4080e7          	jalr	-860(ra) # 80004aa4 <dirlink>
    80005e08:	00054f63          	bltz	a0,80005e26 <create+0x144>
    80005e0c:	00492603          	lw	a2,4(s2)
    80005e10:	00003597          	auipc	a1,0x3
    80005e14:	a9058593          	addi	a1,a1,-1392 # 800088a0 <syscalls+0x2c8>
    80005e18:	8526                	mv	a0,s1
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	c8a080e7          	jalr	-886(ra) # 80004aa4 <dirlink>
    80005e22:	f80557e3          	bgez	a0,80005db0 <create+0xce>
      panic("create dots");
    80005e26:	00003517          	auipc	a0,0x3
    80005e2a:	a8250513          	addi	a0,a0,-1406 # 800088a8 <syscalls+0x2d0>
    80005e2e:	ffffa097          	auipc	ra,0xffffa
    80005e32:	710080e7          	jalr	1808(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005e36:	00003517          	auipc	a0,0x3
    80005e3a:	a8250513          	addi	a0,a0,-1406 # 800088b8 <syscalls+0x2e0>
    80005e3e:	ffffa097          	auipc	ra,0xffffa
    80005e42:	700080e7          	jalr	1792(ra) # 8000053e <panic>
    return 0;
    80005e46:	84aa                	mv	s1,a0
    80005e48:	b731                	j	80005d54 <create+0x72>

0000000080005e4a <sys_dup>:
{
    80005e4a:	7179                	addi	sp,sp,-48
    80005e4c:	f406                	sd	ra,40(sp)
    80005e4e:	f022                	sd	s0,32(sp)
    80005e50:	ec26                	sd	s1,24(sp)
    80005e52:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005e54:	fd840613          	addi	a2,s0,-40
    80005e58:	4581                	li	a1,0
    80005e5a:	4501                	li	a0,0
    80005e5c:	00000097          	auipc	ra,0x0
    80005e60:	ddc080e7          	jalr	-548(ra) # 80005c38 <argfd>
    return -1;
    80005e64:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e66:	02054363          	bltz	a0,80005e8c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e6a:	fd843503          	ld	a0,-40(s0)
    80005e6e:	00000097          	auipc	ra,0x0
    80005e72:	e32080e7          	jalr	-462(ra) # 80005ca0 <fdalloc>
    80005e76:	84aa                	mv	s1,a0
    return -1;
    80005e78:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e7a:	00054963          	bltz	a0,80005e8c <sys_dup+0x42>
  filedup(f);
    80005e7e:	fd843503          	ld	a0,-40(s0)
    80005e82:	fffff097          	auipc	ra,0xfffff
    80005e86:	37a080e7          	jalr	890(ra) # 800051fc <filedup>
  return fd;
    80005e8a:	87a6                	mv	a5,s1
}
    80005e8c:	853e                	mv	a0,a5
    80005e8e:	70a2                	ld	ra,40(sp)
    80005e90:	7402                	ld	s0,32(sp)
    80005e92:	64e2                	ld	s1,24(sp)
    80005e94:	6145                	addi	sp,sp,48
    80005e96:	8082                	ret

0000000080005e98 <sys_read>:
{
    80005e98:	7179                	addi	sp,sp,-48
    80005e9a:	f406                	sd	ra,40(sp)
    80005e9c:	f022                	sd	s0,32(sp)
    80005e9e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ea0:	fe840613          	addi	a2,s0,-24
    80005ea4:	4581                	li	a1,0
    80005ea6:	4501                	li	a0,0
    80005ea8:	00000097          	auipc	ra,0x0
    80005eac:	d90080e7          	jalr	-624(ra) # 80005c38 <argfd>
    return -1;
    80005eb0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eb2:	04054163          	bltz	a0,80005ef4 <sys_read+0x5c>
    80005eb6:	fe440593          	addi	a1,s0,-28
    80005eba:	4509                	li	a0,2
    80005ebc:	ffffe097          	auipc	ra,0xffffe
    80005ec0:	938080e7          	jalr	-1736(ra) # 800037f4 <argint>
    return -1;
    80005ec4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ec6:	02054763          	bltz	a0,80005ef4 <sys_read+0x5c>
    80005eca:	fd840593          	addi	a1,s0,-40
    80005ece:	4505                	li	a0,1
    80005ed0:	ffffe097          	auipc	ra,0xffffe
    80005ed4:	946080e7          	jalr	-1722(ra) # 80003816 <argaddr>
    return -1;
    80005ed8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005eda:	00054d63          	bltz	a0,80005ef4 <sys_read+0x5c>
  return fileread(f, p, n);
    80005ede:	fe442603          	lw	a2,-28(s0)
    80005ee2:	fd843583          	ld	a1,-40(s0)
    80005ee6:	fe843503          	ld	a0,-24(s0)
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	49e080e7          	jalr	1182(ra) # 80005388 <fileread>
    80005ef2:	87aa                	mv	a5,a0
}
    80005ef4:	853e                	mv	a0,a5
    80005ef6:	70a2                	ld	ra,40(sp)
    80005ef8:	7402                	ld	s0,32(sp)
    80005efa:	6145                	addi	sp,sp,48
    80005efc:	8082                	ret

0000000080005efe <sys_write>:
{
    80005efe:	7179                	addi	sp,sp,-48
    80005f00:	f406                	sd	ra,40(sp)
    80005f02:	f022                	sd	s0,32(sp)
    80005f04:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f06:	fe840613          	addi	a2,s0,-24
    80005f0a:	4581                	li	a1,0
    80005f0c:	4501                	li	a0,0
    80005f0e:	00000097          	auipc	ra,0x0
    80005f12:	d2a080e7          	jalr	-726(ra) # 80005c38 <argfd>
    return -1;
    80005f16:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f18:	04054163          	bltz	a0,80005f5a <sys_write+0x5c>
    80005f1c:	fe440593          	addi	a1,s0,-28
    80005f20:	4509                	li	a0,2
    80005f22:	ffffe097          	auipc	ra,0xffffe
    80005f26:	8d2080e7          	jalr	-1838(ra) # 800037f4 <argint>
    return -1;
    80005f2a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f2c:	02054763          	bltz	a0,80005f5a <sys_write+0x5c>
    80005f30:	fd840593          	addi	a1,s0,-40
    80005f34:	4505                	li	a0,1
    80005f36:	ffffe097          	auipc	ra,0xffffe
    80005f3a:	8e0080e7          	jalr	-1824(ra) # 80003816 <argaddr>
    return -1;
    80005f3e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005f40:	00054d63          	bltz	a0,80005f5a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005f44:	fe442603          	lw	a2,-28(s0)
    80005f48:	fd843583          	ld	a1,-40(s0)
    80005f4c:	fe843503          	ld	a0,-24(s0)
    80005f50:	fffff097          	auipc	ra,0xfffff
    80005f54:	4fa080e7          	jalr	1274(ra) # 8000544a <filewrite>
    80005f58:	87aa                	mv	a5,a0
}
    80005f5a:	853e                	mv	a0,a5
    80005f5c:	70a2                	ld	ra,40(sp)
    80005f5e:	7402                	ld	s0,32(sp)
    80005f60:	6145                	addi	sp,sp,48
    80005f62:	8082                	ret

0000000080005f64 <sys_close>:
{
    80005f64:	1101                	addi	sp,sp,-32
    80005f66:	ec06                	sd	ra,24(sp)
    80005f68:	e822                	sd	s0,16(sp)
    80005f6a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005f6c:	fe040613          	addi	a2,s0,-32
    80005f70:	fec40593          	addi	a1,s0,-20
    80005f74:	4501                	li	a0,0
    80005f76:	00000097          	auipc	ra,0x0
    80005f7a:	cc2080e7          	jalr	-830(ra) # 80005c38 <argfd>
    return -1;
    80005f7e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f80:	02054463          	bltz	a0,80005fa8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005f84:	ffffc097          	auipc	ra,0xffffc
    80005f88:	e88080e7          	jalr	-376(ra) # 80001e0c <myproc>
    80005f8c:	fec42783          	lw	a5,-20(s0)
    80005f90:	07f9                	addi	a5,a5,30
    80005f92:	078e                	slli	a5,a5,0x3
    80005f94:	97aa                	add	a5,a5,a0
    80005f96:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005f9a:	fe043503          	ld	a0,-32(s0)
    80005f9e:	fffff097          	auipc	ra,0xfffff
    80005fa2:	2b0080e7          	jalr	688(ra) # 8000524e <fileclose>
  return 0;
    80005fa6:	4781                	li	a5,0
}
    80005fa8:	853e                	mv	a0,a5
    80005faa:	60e2                	ld	ra,24(sp)
    80005fac:	6442                	ld	s0,16(sp)
    80005fae:	6105                	addi	sp,sp,32
    80005fb0:	8082                	ret

0000000080005fb2 <sys_fstat>:
{
    80005fb2:	1101                	addi	sp,sp,-32
    80005fb4:	ec06                	sd	ra,24(sp)
    80005fb6:	e822                	sd	s0,16(sp)
    80005fb8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fba:	fe840613          	addi	a2,s0,-24
    80005fbe:	4581                	li	a1,0
    80005fc0:	4501                	li	a0,0
    80005fc2:	00000097          	auipc	ra,0x0
    80005fc6:	c76080e7          	jalr	-906(ra) # 80005c38 <argfd>
    return -1;
    80005fca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fcc:	02054563          	bltz	a0,80005ff6 <sys_fstat+0x44>
    80005fd0:	fe040593          	addi	a1,s0,-32
    80005fd4:	4505                	li	a0,1
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	840080e7          	jalr	-1984(ra) # 80003816 <argaddr>
    return -1;
    80005fde:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005fe0:	00054b63          	bltz	a0,80005ff6 <sys_fstat+0x44>
  return filestat(f, st);
    80005fe4:	fe043583          	ld	a1,-32(s0)
    80005fe8:	fe843503          	ld	a0,-24(s0)
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	32a080e7          	jalr	810(ra) # 80005316 <filestat>
    80005ff4:	87aa                	mv	a5,a0
}
    80005ff6:	853e                	mv	a0,a5
    80005ff8:	60e2                	ld	ra,24(sp)
    80005ffa:	6442                	ld	s0,16(sp)
    80005ffc:	6105                	addi	sp,sp,32
    80005ffe:	8082                	ret

0000000080006000 <sys_link>:
{
    80006000:	7169                	addi	sp,sp,-304
    80006002:	f606                	sd	ra,296(sp)
    80006004:	f222                	sd	s0,288(sp)
    80006006:	ee26                	sd	s1,280(sp)
    80006008:	ea4a                	sd	s2,272(sp)
    8000600a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000600c:	08000613          	li	a2,128
    80006010:	ed040593          	addi	a1,s0,-304
    80006014:	4501                	li	a0,0
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	822080e7          	jalr	-2014(ra) # 80003838 <argstr>
    return -1;
    8000601e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006020:	10054e63          	bltz	a0,8000613c <sys_link+0x13c>
    80006024:	08000613          	li	a2,128
    80006028:	f5040593          	addi	a1,s0,-176
    8000602c:	4505                	li	a0,1
    8000602e:	ffffe097          	auipc	ra,0xffffe
    80006032:	80a080e7          	jalr	-2038(ra) # 80003838 <argstr>
    return -1;
    80006036:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006038:	10054263          	bltz	a0,8000613c <sys_link+0x13c>
  begin_op();
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	d46080e7          	jalr	-698(ra) # 80004d82 <begin_op>
  if((ip = namei(old)) == 0){
    80006044:	ed040513          	addi	a0,s0,-304
    80006048:	fffff097          	auipc	ra,0xfffff
    8000604c:	b1e080e7          	jalr	-1250(ra) # 80004b66 <namei>
    80006050:	84aa                	mv	s1,a0
    80006052:	c551                	beqz	a0,800060de <sys_link+0xde>
  ilock(ip);
    80006054:	ffffe097          	auipc	ra,0xffffe
    80006058:	35c080e7          	jalr	860(ra) # 800043b0 <ilock>
  if(ip->type == T_DIR){
    8000605c:	04449703          	lh	a4,68(s1)
    80006060:	4785                	li	a5,1
    80006062:	08f70463          	beq	a4,a5,800060ea <sys_link+0xea>
  ip->nlink++;
    80006066:	04a4d783          	lhu	a5,74(s1)
    8000606a:	2785                	addiw	a5,a5,1
    8000606c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006070:	8526                	mv	a0,s1
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	274080e7          	jalr	628(ra) # 800042e6 <iupdate>
  iunlock(ip);
    8000607a:	8526                	mv	a0,s1
    8000607c:	ffffe097          	auipc	ra,0xffffe
    80006080:	3f6080e7          	jalr	1014(ra) # 80004472 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006084:	fd040593          	addi	a1,s0,-48
    80006088:	f5040513          	addi	a0,s0,-176
    8000608c:	fffff097          	auipc	ra,0xfffff
    80006090:	af8080e7          	jalr	-1288(ra) # 80004b84 <nameiparent>
    80006094:	892a                	mv	s2,a0
    80006096:	c935                	beqz	a0,8000610a <sys_link+0x10a>
  ilock(dp);
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	318080e7          	jalr	792(ra) # 800043b0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800060a0:	00092703          	lw	a4,0(s2)
    800060a4:	409c                	lw	a5,0(s1)
    800060a6:	04f71d63          	bne	a4,a5,80006100 <sys_link+0x100>
    800060aa:	40d0                	lw	a2,4(s1)
    800060ac:	fd040593          	addi	a1,s0,-48
    800060b0:	854a                	mv	a0,s2
    800060b2:	fffff097          	auipc	ra,0xfffff
    800060b6:	9f2080e7          	jalr	-1550(ra) # 80004aa4 <dirlink>
    800060ba:	04054363          	bltz	a0,80006100 <sys_link+0x100>
  iunlockput(dp);
    800060be:	854a                	mv	a0,s2
    800060c0:	ffffe097          	auipc	ra,0xffffe
    800060c4:	552080e7          	jalr	1362(ra) # 80004612 <iunlockput>
  iput(ip);
    800060c8:	8526                	mv	a0,s1
    800060ca:	ffffe097          	auipc	ra,0xffffe
    800060ce:	4a0080e7          	jalr	1184(ra) # 8000456a <iput>
  end_op();
    800060d2:	fffff097          	auipc	ra,0xfffff
    800060d6:	d30080e7          	jalr	-720(ra) # 80004e02 <end_op>
  return 0;
    800060da:	4781                	li	a5,0
    800060dc:	a085                	j	8000613c <sys_link+0x13c>
    end_op();
    800060de:	fffff097          	auipc	ra,0xfffff
    800060e2:	d24080e7          	jalr	-732(ra) # 80004e02 <end_op>
    return -1;
    800060e6:	57fd                	li	a5,-1
    800060e8:	a891                	j	8000613c <sys_link+0x13c>
    iunlockput(ip);
    800060ea:	8526                	mv	a0,s1
    800060ec:	ffffe097          	auipc	ra,0xffffe
    800060f0:	526080e7          	jalr	1318(ra) # 80004612 <iunlockput>
    end_op();
    800060f4:	fffff097          	auipc	ra,0xfffff
    800060f8:	d0e080e7          	jalr	-754(ra) # 80004e02 <end_op>
    return -1;
    800060fc:	57fd                	li	a5,-1
    800060fe:	a83d                	j	8000613c <sys_link+0x13c>
    iunlockput(dp);
    80006100:	854a                	mv	a0,s2
    80006102:	ffffe097          	auipc	ra,0xffffe
    80006106:	510080e7          	jalr	1296(ra) # 80004612 <iunlockput>
  ilock(ip);
    8000610a:	8526                	mv	a0,s1
    8000610c:	ffffe097          	auipc	ra,0xffffe
    80006110:	2a4080e7          	jalr	676(ra) # 800043b0 <ilock>
  ip->nlink--;
    80006114:	04a4d783          	lhu	a5,74(s1)
    80006118:	37fd                	addiw	a5,a5,-1
    8000611a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000611e:	8526                	mv	a0,s1
    80006120:	ffffe097          	auipc	ra,0xffffe
    80006124:	1c6080e7          	jalr	454(ra) # 800042e6 <iupdate>
  iunlockput(ip);
    80006128:	8526                	mv	a0,s1
    8000612a:	ffffe097          	auipc	ra,0xffffe
    8000612e:	4e8080e7          	jalr	1256(ra) # 80004612 <iunlockput>
  end_op();
    80006132:	fffff097          	auipc	ra,0xfffff
    80006136:	cd0080e7          	jalr	-816(ra) # 80004e02 <end_op>
  return -1;
    8000613a:	57fd                	li	a5,-1
}
    8000613c:	853e                	mv	a0,a5
    8000613e:	70b2                	ld	ra,296(sp)
    80006140:	7412                	ld	s0,288(sp)
    80006142:	64f2                	ld	s1,280(sp)
    80006144:	6952                	ld	s2,272(sp)
    80006146:	6155                	addi	sp,sp,304
    80006148:	8082                	ret

000000008000614a <sys_unlink>:
{
    8000614a:	7151                	addi	sp,sp,-240
    8000614c:	f586                	sd	ra,232(sp)
    8000614e:	f1a2                	sd	s0,224(sp)
    80006150:	eda6                	sd	s1,216(sp)
    80006152:	e9ca                	sd	s2,208(sp)
    80006154:	e5ce                	sd	s3,200(sp)
    80006156:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006158:	08000613          	li	a2,128
    8000615c:	f3040593          	addi	a1,s0,-208
    80006160:	4501                	li	a0,0
    80006162:	ffffd097          	auipc	ra,0xffffd
    80006166:	6d6080e7          	jalr	1750(ra) # 80003838 <argstr>
    8000616a:	18054163          	bltz	a0,800062ec <sys_unlink+0x1a2>
  begin_op();
    8000616e:	fffff097          	auipc	ra,0xfffff
    80006172:	c14080e7          	jalr	-1004(ra) # 80004d82 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006176:	fb040593          	addi	a1,s0,-80
    8000617a:	f3040513          	addi	a0,s0,-208
    8000617e:	fffff097          	auipc	ra,0xfffff
    80006182:	a06080e7          	jalr	-1530(ra) # 80004b84 <nameiparent>
    80006186:	84aa                	mv	s1,a0
    80006188:	c979                	beqz	a0,8000625e <sys_unlink+0x114>
  ilock(dp);
    8000618a:	ffffe097          	auipc	ra,0xffffe
    8000618e:	226080e7          	jalr	550(ra) # 800043b0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006192:	00002597          	auipc	a1,0x2
    80006196:	70658593          	addi	a1,a1,1798 # 80008898 <syscalls+0x2c0>
    8000619a:	fb040513          	addi	a0,s0,-80
    8000619e:	ffffe097          	auipc	ra,0xffffe
    800061a2:	6dc080e7          	jalr	1756(ra) # 8000487a <namecmp>
    800061a6:	14050a63          	beqz	a0,800062fa <sys_unlink+0x1b0>
    800061aa:	00002597          	auipc	a1,0x2
    800061ae:	6f658593          	addi	a1,a1,1782 # 800088a0 <syscalls+0x2c8>
    800061b2:	fb040513          	addi	a0,s0,-80
    800061b6:	ffffe097          	auipc	ra,0xffffe
    800061ba:	6c4080e7          	jalr	1732(ra) # 8000487a <namecmp>
    800061be:	12050e63          	beqz	a0,800062fa <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800061c2:	f2c40613          	addi	a2,s0,-212
    800061c6:	fb040593          	addi	a1,s0,-80
    800061ca:	8526                	mv	a0,s1
    800061cc:	ffffe097          	auipc	ra,0xffffe
    800061d0:	6c8080e7          	jalr	1736(ra) # 80004894 <dirlookup>
    800061d4:	892a                	mv	s2,a0
    800061d6:	12050263          	beqz	a0,800062fa <sys_unlink+0x1b0>
  ilock(ip);
    800061da:	ffffe097          	auipc	ra,0xffffe
    800061de:	1d6080e7          	jalr	470(ra) # 800043b0 <ilock>
  if(ip->nlink < 1)
    800061e2:	04a91783          	lh	a5,74(s2)
    800061e6:	08f05263          	blez	a5,8000626a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800061ea:	04491703          	lh	a4,68(s2)
    800061ee:	4785                	li	a5,1
    800061f0:	08f70563          	beq	a4,a5,8000627a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800061f4:	4641                	li	a2,16
    800061f6:	4581                	li	a1,0
    800061f8:	fc040513          	addi	a0,s0,-64
    800061fc:	ffffb097          	auipc	ra,0xffffb
    80006200:	af2080e7          	jalr	-1294(ra) # 80000cee <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006204:	4741                	li	a4,16
    80006206:	f2c42683          	lw	a3,-212(s0)
    8000620a:	fc040613          	addi	a2,s0,-64
    8000620e:	4581                	li	a1,0
    80006210:	8526                	mv	a0,s1
    80006212:	ffffe097          	auipc	ra,0xffffe
    80006216:	54a080e7          	jalr	1354(ra) # 8000475c <writei>
    8000621a:	47c1                	li	a5,16
    8000621c:	0af51563          	bne	a0,a5,800062c6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006220:	04491703          	lh	a4,68(s2)
    80006224:	4785                	li	a5,1
    80006226:	0af70863          	beq	a4,a5,800062d6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000622a:	8526                	mv	a0,s1
    8000622c:	ffffe097          	auipc	ra,0xffffe
    80006230:	3e6080e7          	jalr	998(ra) # 80004612 <iunlockput>
  ip->nlink--;
    80006234:	04a95783          	lhu	a5,74(s2)
    80006238:	37fd                	addiw	a5,a5,-1
    8000623a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000623e:	854a                	mv	a0,s2
    80006240:	ffffe097          	auipc	ra,0xffffe
    80006244:	0a6080e7          	jalr	166(ra) # 800042e6 <iupdate>
  iunlockput(ip);
    80006248:	854a                	mv	a0,s2
    8000624a:	ffffe097          	auipc	ra,0xffffe
    8000624e:	3c8080e7          	jalr	968(ra) # 80004612 <iunlockput>
  end_op();
    80006252:	fffff097          	auipc	ra,0xfffff
    80006256:	bb0080e7          	jalr	-1104(ra) # 80004e02 <end_op>
  return 0;
    8000625a:	4501                	li	a0,0
    8000625c:	a84d                	j	8000630e <sys_unlink+0x1c4>
    end_op();
    8000625e:	fffff097          	auipc	ra,0xfffff
    80006262:	ba4080e7          	jalr	-1116(ra) # 80004e02 <end_op>
    return -1;
    80006266:	557d                	li	a0,-1
    80006268:	a05d                	j	8000630e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000626a:	00002517          	auipc	a0,0x2
    8000626e:	65e50513          	addi	a0,a0,1630 # 800088c8 <syscalls+0x2f0>
    80006272:	ffffa097          	auipc	ra,0xffffa
    80006276:	2cc080e7          	jalr	716(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000627a:	04c92703          	lw	a4,76(s2)
    8000627e:	02000793          	li	a5,32
    80006282:	f6e7f9e3          	bgeu	a5,a4,800061f4 <sys_unlink+0xaa>
    80006286:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000628a:	4741                	li	a4,16
    8000628c:	86ce                	mv	a3,s3
    8000628e:	f1840613          	addi	a2,s0,-232
    80006292:	4581                	li	a1,0
    80006294:	854a                	mv	a0,s2
    80006296:	ffffe097          	auipc	ra,0xffffe
    8000629a:	3ce080e7          	jalr	974(ra) # 80004664 <readi>
    8000629e:	47c1                	li	a5,16
    800062a0:	00f51b63          	bne	a0,a5,800062b6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800062a4:	f1845783          	lhu	a5,-232(s0)
    800062a8:	e7a1                	bnez	a5,800062f0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800062aa:	29c1                	addiw	s3,s3,16
    800062ac:	04c92783          	lw	a5,76(s2)
    800062b0:	fcf9ede3          	bltu	s3,a5,8000628a <sys_unlink+0x140>
    800062b4:	b781                	j	800061f4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800062b6:	00002517          	auipc	a0,0x2
    800062ba:	62a50513          	addi	a0,a0,1578 # 800088e0 <syscalls+0x308>
    800062be:	ffffa097          	auipc	ra,0xffffa
    800062c2:	280080e7          	jalr	640(ra) # 8000053e <panic>
    panic("unlink: writei");
    800062c6:	00002517          	auipc	a0,0x2
    800062ca:	63250513          	addi	a0,a0,1586 # 800088f8 <syscalls+0x320>
    800062ce:	ffffa097          	auipc	ra,0xffffa
    800062d2:	270080e7          	jalr	624(ra) # 8000053e <panic>
    dp->nlink--;
    800062d6:	04a4d783          	lhu	a5,74(s1)
    800062da:	37fd                	addiw	a5,a5,-1
    800062dc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800062e0:	8526                	mv	a0,s1
    800062e2:	ffffe097          	auipc	ra,0xffffe
    800062e6:	004080e7          	jalr	4(ra) # 800042e6 <iupdate>
    800062ea:	b781                	j	8000622a <sys_unlink+0xe0>
    return -1;
    800062ec:	557d                	li	a0,-1
    800062ee:	a005                	j	8000630e <sys_unlink+0x1c4>
    iunlockput(ip);
    800062f0:	854a                	mv	a0,s2
    800062f2:	ffffe097          	auipc	ra,0xffffe
    800062f6:	320080e7          	jalr	800(ra) # 80004612 <iunlockput>
  iunlockput(dp);
    800062fa:	8526                	mv	a0,s1
    800062fc:	ffffe097          	auipc	ra,0xffffe
    80006300:	316080e7          	jalr	790(ra) # 80004612 <iunlockput>
  end_op();
    80006304:	fffff097          	auipc	ra,0xfffff
    80006308:	afe080e7          	jalr	-1282(ra) # 80004e02 <end_op>
  return -1;
    8000630c:	557d                	li	a0,-1
}
    8000630e:	70ae                	ld	ra,232(sp)
    80006310:	740e                	ld	s0,224(sp)
    80006312:	64ee                	ld	s1,216(sp)
    80006314:	694e                	ld	s2,208(sp)
    80006316:	69ae                	ld	s3,200(sp)
    80006318:	616d                	addi	sp,sp,240
    8000631a:	8082                	ret

000000008000631c <sys_open>:

uint64
sys_open(void)
{
    8000631c:	7131                	addi	sp,sp,-192
    8000631e:	fd06                	sd	ra,184(sp)
    80006320:	f922                	sd	s0,176(sp)
    80006322:	f526                	sd	s1,168(sp)
    80006324:	f14a                	sd	s2,160(sp)
    80006326:	ed4e                	sd	s3,152(sp)
    80006328:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000632a:	08000613          	li	a2,128
    8000632e:	f5040593          	addi	a1,s0,-176
    80006332:	4501                	li	a0,0
    80006334:	ffffd097          	auipc	ra,0xffffd
    80006338:	504080e7          	jalr	1284(ra) # 80003838 <argstr>
    return -1;
    8000633c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000633e:	0c054163          	bltz	a0,80006400 <sys_open+0xe4>
    80006342:	f4c40593          	addi	a1,s0,-180
    80006346:	4505                	li	a0,1
    80006348:	ffffd097          	auipc	ra,0xffffd
    8000634c:	4ac080e7          	jalr	1196(ra) # 800037f4 <argint>
    80006350:	0a054863          	bltz	a0,80006400 <sys_open+0xe4>

  begin_op();
    80006354:	fffff097          	auipc	ra,0xfffff
    80006358:	a2e080e7          	jalr	-1490(ra) # 80004d82 <begin_op>

  if(omode & O_CREATE){
    8000635c:	f4c42783          	lw	a5,-180(s0)
    80006360:	2007f793          	andi	a5,a5,512
    80006364:	cbdd                	beqz	a5,8000641a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006366:	4681                	li	a3,0
    80006368:	4601                	li	a2,0
    8000636a:	4589                	li	a1,2
    8000636c:	f5040513          	addi	a0,s0,-176
    80006370:	00000097          	auipc	ra,0x0
    80006374:	972080e7          	jalr	-1678(ra) # 80005ce2 <create>
    80006378:	892a                	mv	s2,a0
    if(ip == 0){
    8000637a:	c959                	beqz	a0,80006410 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000637c:	04491703          	lh	a4,68(s2)
    80006380:	478d                	li	a5,3
    80006382:	00f71763          	bne	a4,a5,80006390 <sys_open+0x74>
    80006386:	04695703          	lhu	a4,70(s2)
    8000638a:	47a5                	li	a5,9
    8000638c:	0ce7ec63          	bltu	a5,a4,80006464 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006390:	fffff097          	auipc	ra,0xfffff
    80006394:	e02080e7          	jalr	-510(ra) # 80005192 <filealloc>
    80006398:	89aa                	mv	s3,a0
    8000639a:	10050263          	beqz	a0,8000649e <sys_open+0x182>
    8000639e:	00000097          	auipc	ra,0x0
    800063a2:	902080e7          	jalr	-1790(ra) # 80005ca0 <fdalloc>
    800063a6:	84aa                	mv	s1,a0
    800063a8:	0e054663          	bltz	a0,80006494 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800063ac:	04491703          	lh	a4,68(s2)
    800063b0:	478d                	li	a5,3
    800063b2:	0cf70463          	beq	a4,a5,8000647a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800063b6:	4789                	li	a5,2
    800063b8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800063bc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800063c0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800063c4:	f4c42783          	lw	a5,-180(s0)
    800063c8:	0017c713          	xori	a4,a5,1
    800063cc:	8b05                	andi	a4,a4,1
    800063ce:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800063d2:	0037f713          	andi	a4,a5,3
    800063d6:	00e03733          	snez	a4,a4
    800063da:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800063de:	4007f793          	andi	a5,a5,1024
    800063e2:	c791                	beqz	a5,800063ee <sys_open+0xd2>
    800063e4:	04491703          	lh	a4,68(s2)
    800063e8:	4789                	li	a5,2
    800063ea:	08f70f63          	beq	a4,a5,80006488 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800063ee:	854a                	mv	a0,s2
    800063f0:	ffffe097          	auipc	ra,0xffffe
    800063f4:	082080e7          	jalr	130(ra) # 80004472 <iunlock>
  end_op();
    800063f8:	fffff097          	auipc	ra,0xfffff
    800063fc:	a0a080e7          	jalr	-1526(ra) # 80004e02 <end_op>

  return fd;
}
    80006400:	8526                	mv	a0,s1
    80006402:	70ea                	ld	ra,184(sp)
    80006404:	744a                	ld	s0,176(sp)
    80006406:	74aa                	ld	s1,168(sp)
    80006408:	790a                	ld	s2,160(sp)
    8000640a:	69ea                	ld	s3,152(sp)
    8000640c:	6129                	addi	sp,sp,192
    8000640e:	8082                	ret
      end_op();
    80006410:	fffff097          	auipc	ra,0xfffff
    80006414:	9f2080e7          	jalr	-1550(ra) # 80004e02 <end_op>
      return -1;
    80006418:	b7e5                	j	80006400 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000641a:	f5040513          	addi	a0,s0,-176
    8000641e:	ffffe097          	auipc	ra,0xffffe
    80006422:	748080e7          	jalr	1864(ra) # 80004b66 <namei>
    80006426:	892a                	mv	s2,a0
    80006428:	c905                	beqz	a0,80006458 <sys_open+0x13c>
    ilock(ip);
    8000642a:	ffffe097          	auipc	ra,0xffffe
    8000642e:	f86080e7          	jalr	-122(ra) # 800043b0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006432:	04491703          	lh	a4,68(s2)
    80006436:	4785                	li	a5,1
    80006438:	f4f712e3          	bne	a4,a5,8000637c <sys_open+0x60>
    8000643c:	f4c42783          	lw	a5,-180(s0)
    80006440:	dba1                	beqz	a5,80006390 <sys_open+0x74>
      iunlockput(ip);
    80006442:	854a                	mv	a0,s2
    80006444:	ffffe097          	auipc	ra,0xffffe
    80006448:	1ce080e7          	jalr	462(ra) # 80004612 <iunlockput>
      end_op();
    8000644c:	fffff097          	auipc	ra,0xfffff
    80006450:	9b6080e7          	jalr	-1610(ra) # 80004e02 <end_op>
      return -1;
    80006454:	54fd                	li	s1,-1
    80006456:	b76d                	j	80006400 <sys_open+0xe4>
      end_op();
    80006458:	fffff097          	auipc	ra,0xfffff
    8000645c:	9aa080e7          	jalr	-1622(ra) # 80004e02 <end_op>
      return -1;
    80006460:	54fd                	li	s1,-1
    80006462:	bf79                	j	80006400 <sys_open+0xe4>
    iunlockput(ip);
    80006464:	854a                	mv	a0,s2
    80006466:	ffffe097          	auipc	ra,0xffffe
    8000646a:	1ac080e7          	jalr	428(ra) # 80004612 <iunlockput>
    end_op();
    8000646e:	fffff097          	auipc	ra,0xfffff
    80006472:	994080e7          	jalr	-1644(ra) # 80004e02 <end_op>
    return -1;
    80006476:	54fd                	li	s1,-1
    80006478:	b761                	j	80006400 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000647a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000647e:	04691783          	lh	a5,70(s2)
    80006482:	02f99223          	sh	a5,36(s3)
    80006486:	bf2d                	j	800063c0 <sys_open+0xa4>
    itrunc(ip);
    80006488:	854a                	mv	a0,s2
    8000648a:	ffffe097          	auipc	ra,0xffffe
    8000648e:	034080e7          	jalr	52(ra) # 800044be <itrunc>
    80006492:	bfb1                	j	800063ee <sys_open+0xd2>
      fileclose(f);
    80006494:	854e                	mv	a0,s3
    80006496:	fffff097          	auipc	ra,0xfffff
    8000649a:	db8080e7          	jalr	-584(ra) # 8000524e <fileclose>
    iunlockput(ip);
    8000649e:	854a                	mv	a0,s2
    800064a0:	ffffe097          	auipc	ra,0xffffe
    800064a4:	172080e7          	jalr	370(ra) # 80004612 <iunlockput>
    end_op();
    800064a8:	fffff097          	auipc	ra,0xfffff
    800064ac:	95a080e7          	jalr	-1702(ra) # 80004e02 <end_op>
    return -1;
    800064b0:	54fd                	li	s1,-1
    800064b2:	b7b9                	j	80006400 <sys_open+0xe4>

00000000800064b4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800064b4:	7175                	addi	sp,sp,-144
    800064b6:	e506                	sd	ra,136(sp)
    800064b8:	e122                	sd	s0,128(sp)
    800064ba:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800064bc:	fffff097          	auipc	ra,0xfffff
    800064c0:	8c6080e7          	jalr	-1850(ra) # 80004d82 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800064c4:	08000613          	li	a2,128
    800064c8:	f7040593          	addi	a1,s0,-144
    800064cc:	4501                	li	a0,0
    800064ce:	ffffd097          	auipc	ra,0xffffd
    800064d2:	36a080e7          	jalr	874(ra) # 80003838 <argstr>
    800064d6:	02054963          	bltz	a0,80006508 <sys_mkdir+0x54>
    800064da:	4681                	li	a3,0
    800064dc:	4601                	li	a2,0
    800064de:	4585                	li	a1,1
    800064e0:	f7040513          	addi	a0,s0,-144
    800064e4:	fffff097          	auipc	ra,0xfffff
    800064e8:	7fe080e7          	jalr	2046(ra) # 80005ce2 <create>
    800064ec:	cd11                	beqz	a0,80006508 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800064ee:	ffffe097          	auipc	ra,0xffffe
    800064f2:	124080e7          	jalr	292(ra) # 80004612 <iunlockput>
  end_op();
    800064f6:	fffff097          	auipc	ra,0xfffff
    800064fa:	90c080e7          	jalr	-1780(ra) # 80004e02 <end_op>
  return 0;
    800064fe:	4501                	li	a0,0
}
    80006500:	60aa                	ld	ra,136(sp)
    80006502:	640a                	ld	s0,128(sp)
    80006504:	6149                	addi	sp,sp,144
    80006506:	8082                	ret
    end_op();
    80006508:	fffff097          	auipc	ra,0xfffff
    8000650c:	8fa080e7          	jalr	-1798(ra) # 80004e02 <end_op>
    return -1;
    80006510:	557d                	li	a0,-1
    80006512:	b7fd                	j	80006500 <sys_mkdir+0x4c>

0000000080006514 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006514:	7135                	addi	sp,sp,-160
    80006516:	ed06                	sd	ra,152(sp)
    80006518:	e922                	sd	s0,144(sp)
    8000651a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000651c:	fffff097          	auipc	ra,0xfffff
    80006520:	866080e7          	jalr	-1946(ra) # 80004d82 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006524:	08000613          	li	a2,128
    80006528:	f7040593          	addi	a1,s0,-144
    8000652c:	4501                	li	a0,0
    8000652e:	ffffd097          	auipc	ra,0xffffd
    80006532:	30a080e7          	jalr	778(ra) # 80003838 <argstr>
    80006536:	04054a63          	bltz	a0,8000658a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000653a:	f6c40593          	addi	a1,s0,-148
    8000653e:	4505                	li	a0,1
    80006540:	ffffd097          	auipc	ra,0xffffd
    80006544:	2b4080e7          	jalr	692(ra) # 800037f4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006548:	04054163          	bltz	a0,8000658a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000654c:	f6840593          	addi	a1,s0,-152
    80006550:	4509                	li	a0,2
    80006552:	ffffd097          	auipc	ra,0xffffd
    80006556:	2a2080e7          	jalr	674(ra) # 800037f4 <argint>
     argint(1, &major) < 0 ||
    8000655a:	02054863          	bltz	a0,8000658a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000655e:	f6841683          	lh	a3,-152(s0)
    80006562:	f6c41603          	lh	a2,-148(s0)
    80006566:	458d                	li	a1,3
    80006568:	f7040513          	addi	a0,s0,-144
    8000656c:	fffff097          	auipc	ra,0xfffff
    80006570:	776080e7          	jalr	1910(ra) # 80005ce2 <create>
     argint(2, &minor) < 0 ||
    80006574:	c919                	beqz	a0,8000658a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006576:	ffffe097          	auipc	ra,0xffffe
    8000657a:	09c080e7          	jalr	156(ra) # 80004612 <iunlockput>
  end_op();
    8000657e:	fffff097          	auipc	ra,0xfffff
    80006582:	884080e7          	jalr	-1916(ra) # 80004e02 <end_op>
  return 0;
    80006586:	4501                	li	a0,0
    80006588:	a031                	j	80006594 <sys_mknod+0x80>
    end_op();
    8000658a:	fffff097          	auipc	ra,0xfffff
    8000658e:	878080e7          	jalr	-1928(ra) # 80004e02 <end_op>
    return -1;
    80006592:	557d                	li	a0,-1
}
    80006594:	60ea                	ld	ra,152(sp)
    80006596:	644a                	ld	s0,144(sp)
    80006598:	610d                	addi	sp,sp,160
    8000659a:	8082                	ret

000000008000659c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000659c:	7135                	addi	sp,sp,-160
    8000659e:	ed06                	sd	ra,152(sp)
    800065a0:	e922                	sd	s0,144(sp)
    800065a2:	e526                	sd	s1,136(sp)
    800065a4:	e14a                	sd	s2,128(sp)
    800065a6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800065a8:	ffffc097          	auipc	ra,0xffffc
    800065ac:	864080e7          	jalr	-1948(ra) # 80001e0c <myproc>
    800065b0:	892a                	mv	s2,a0
  
  begin_op();
    800065b2:	ffffe097          	auipc	ra,0xffffe
    800065b6:	7d0080e7          	jalr	2000(ra) # 80004d82 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800065ba:	08000613          	li	a2,128
    800065be:	f6040593          	addi	a1,s0,-160
    800065c2:	4501                	li	a0,0
    800065c4:	ffffd097          	auipc	ra,0xffffd
    800065c8:	274080e7          	jalr	628(ra) # 80003838 <argstr>
    800065cc:	04054b63          	bltz	a0,80006622 <sys_chdir+0x86>
    800065d0:	f6040513          	addi	a0,s0,-160
    800065d4:	ffffe097          	auipc	ra,0xffffe
    800065d8:	592080e7          	jalr	1426(ra) # 80004b66 <namei>
    800065dc:	84aa                	mv	s1,a0
    800065de:	c131                	beqz	a0,80006622 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800065e0:	ffffe097          	auipc	ra,0xffffe
    800065e4:	dd0080e7          	jalr	-560(ra) # 800043b0 <ilock>
  if(ip->type != T_DIR){
    800065e8:	04449703          	lh	a4,68(s1)
    800065ec:	4785                	li	a5,1
    800065ee:	04f71063          	bne	a4,a5,8000662e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800065f2:	8526                	mv	a0,s1
    800065f4:	ffffe097          	auipc	ra,0xffffe
    800065f8:	e7e080e7          	jalr	-386(ra) # 80004472 <iunlock>
  iput(p->cwd);
    800065fc:	17893503          	ld	a0,376(s2)
    80006600:	ffffe097          	auipc	ra,0xffffe
    80006604:	f6a080e7          	jalr	-150(ra) # 8000456a <iput>
  end_op();
    80006608:	ffffe097          	auipc	ra,0xffffe
    8000660c:	7fa080e7          	jalr	2042(ra) # 80004e02 <end_op>
  p->cwd = ip;
    80006610:	16993c23          	sd	s1,376(s2)
  return 0;
    80006614:	4501                	li	a0,0
}
    80006616:	60ea                	ld	ra,152(sp)
    80006618:	644a                	ld	s0,144(sp)
    8000661a:	64aa                	ld	s1,136(sp)
    8000661c:	690a                	ld	s2,128(sp)
    8000661e:	610d                	addi	sp,sp,160
    80006620:	8082                	ret
    end_op();
    80006622:	ffffe097          	auipc	ra,0xffffe
    80006626:	7e0080e7          	jalr	2016(ra) # 80004e02 <end_op>
    return -1;
    8000662a:	557d                	li	a0,-1
    8000662c:	b7ed                	j	80006616 <sys_chdir+0x7a>
    iunlockput(ip);
    8000662e:	8526                	mv	a0,s1
    80006630:	ffffe097          	auipc	ra,0xffffe
    80006634:	fe2080e7          	jalr	-30(ra) # 80004612 <iunlockput>
    end_op();
    80006638:	ffffe097          	auipc	ra,0xffffe
    8000663c:	7ca080e7          	jalr	1994(ra) # 80004e02 <end_op>
    return -1;
    80006640:	557d                	li	a0,-1
    80006642:	bfd1                	j	80006616 <sys_chdir+0x7a>

0000000080006644 <sys_exec>:

uint64
sys_exec(void)
{
    80006644:	7145                	addi	sp,sp,-464
    80006646:	e786                	sd	ra,456(sp)
    80006648:	e3a2                	sd	s0,448(sp)
    8000664a:	ff26                	sd	s1,440(sp)
    8000664c:	fb4a                	sd	s2,432(sp)
    8000664e:	f74e                	sd	s3,424(sp)
    80006650:	f352                	sd	s4,416(sp)
    80006652:	ef56                	sd	s5,408(sp)
    80006654:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006656:	08000613          	li	a2,128
    8000665a:	f4040593          	addi	a1,s0,-192
    8000665e:	4501                	li	a0,0
    80006660:	ffffd097          	auipc	ra,0xffffd
    80006664:	1d8080e7          	jalr	472(ra) # 80003838 <argstr>
    return -1;
    80006668:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000666a:	0c054a63          	bltz	a0,8000673e <sys_exec+0xfa>
    8000666e:	e3840593          	addi	a1,s0,-456
    80006672:	4505                	li	a0,1
    80006674:	ffffd097          	auipc	ra,0xffffd
    80006678:	1a2080e7          	jalr	418(ra) # 80003816 <argaddr>
    8000667c:	0c054163          	bltz	a0,8000673e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006680:	10000613          	li	a2,256
    80006684:	4581                	li	a1,0
    80006686:	e4040513          	addi	a0,s0,-448
    8000668a:	ffffa097          	auipc	ra,0xffffa
    8000668e:	664080e7          	jalr	1636(ra) # 80000cee <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006692:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006696:	89a6                	mv	s3,s1
    80006698:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000669a:	02000a13          	li	s4,32
    8000669e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800066a2:	00391513          	slli	a0,s2,0x3
    800066a6:	e3040593          	addi	a1,s0,-464
    800066aa:	e3843783          	ld	a5,-456(s0)
    800066ae:	953e                	add	a0,a0,a5
    800066b0:	ffffd097          	auipc	ra,0xffffd
    800066b4:	0aa080e7          	jalr	170(ra) # 8000375a <fetchaddr>
    800066b8:	02054a63          	bltz	a0,800066ec <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800066bc:	e3043783          	ld	a5,-464(s0)
    800066c0:	c3b9                	beqz	a5,80006706 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800066c2:	ffffa097          	auipc	ra,0xffffa
    800066c6:	432080e7          	jalr	1074(ra) # 80000af4 <kalloc>
    800066ca:	85aa                	mv	a1,a0
    800066cc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800066d0:	cd11                	beqz	a0,800066ec <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800066d2:	6605                	lui	a2,0x1
    800066d4:	e3043503          	ld	a0,-464(s0)
    800066d8:	ffffd097          	auipc	ra,0xffffd
    800066dc:	0d4080e7          	jalr	212(ra) # 800037ac <fetchstr>
    800066e0:	00054663          	bltz	a0,800066ec <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800066e4:	0905                	addi	s2,s2,1
    800066e6:	09a1                	addi	s3,s3,8
    800066e8:	fb491be3          	bne	s2,s4,8000669e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066ec:	10048913          	addi	s2,s1,256
    800066f0:	6088                	ld	a0,0(s1)
    800066f2:	c529                	beqz	a0,8000673c <sys_exec+0xf8>
    kfree(argv[i]);
    800066f4:	ffffa097          	auipc	ra,0xffffa
    800066f8:	304080e7          	jalr	772(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066fc:	04a1                	addi	s1,s1,8
    800066fe:	ff2499e3          	bne	s1,s2,800066f0 <sys_exec+0xac>
  return -1;
    80006702:	597d                	li	s2,-1
    80006704:	a82d                	j	8000673e <sys_exec+0xfa>
      argv[i] = 0;
    80006706:	0a8e                	slli	s5,s5,0x3
    80006708:	fc040793          	addi	a5,s0,-64
    8000670c:	9abe                	add	s5,s5,a5
    8000670e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006712:	e4040593          	addi	a1,s0,-448
    80006716:	f4040513          	addi	a0,s0,-192
    8000671a:	fffff097          	auipc	ra,0xfffff
    8000671e:	194080e7          	jalr	404(ra) # 800058ae <exec>
    80006722:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006724:	10048993          	addi	s3,s1,256
    80006728:	6088                	ld	a0,0(s1)
    8000672a:	c911                	beqz	a0,8000673e <sys_exec+0xfa>
    kfree(argv[i]);
    8000672c:	ffffa097          	auipc	ra,0xffffa
    80006730:	2cc080e7          	jalr	716(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006734:	04a1                	addi	s1,s1,8
    80006736:	ff3499e3          	bne	s1,s3,80006728 <sys_exec+0xe4>
    8000673a:	a011                	j	8000673e <sys_exec+0xfa>
  return -1;
    8000673c:	597d                	li	s2,-1
}
    8000673e:	854a                	mv	a0,s2
    80006740:	60be                	ld	ra,456(sp)
    80006742:	641e                	ld	s0,448(sp)
    80006744:	74fa                	ld	s1,440(sp)
    80006746:	795a                	ld	s2,432(sp)
    80006748:	79ba                	ld	s3,424(sp)
    8000674a:	7a1a                	ld	s4,416(sp)
    8000674c:	6afa                	ld	s5,408(sp)
    8000674e:	6179                	addi	sp,sp,464
    80006750:	8082                	ret

0000000080006752 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006752:	7139                	addi	sp,sp,-64
    80006754:	fc06                	sd	ra,56(sp)
    80006756:	f822                	sd	s0,48(sp)
    80006758:	f426                	sd	s1,40(sp)
    8000675a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000675c:	ffffb097          	auipc	ra,0xffffb
    80006760:	6b0080e7          	jalr	1712(ra) # 80001e0c <myproc>
    80006764:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006766:	fd840593          	addi	a1,s0,-40
    8000676a:	4501                	li	a0,0
    8000676c:	ffffd097          	auipc	ra,0xffffd
    80006770:	0aa080e7          	jalr	170(ra) # 80003816 <argaddr>
    return -1;
    80006774:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006776:	0e054063          	bltz	a0,80006856 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000677a:	fc840593          	addi	a1,s0,-56
    8000677e:	fd040513          	addi	a0,s0,-48
    80006782:	fffff097          	auipc	ra,0xfffff
    80006786:	dfc080e7          	jalr	-516(ra) # 8000557e <pipealloc>
    return -1;
    8000678a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000678c:	0c054563          	bltz	a0,80006856 <sys_pipe+0x104>
  fd0 = -1;
    80006790:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006794:	fd043503          	ld	a0,-48(s0)
    80006798:	fffff097          	auipc	ra,0xfffff
    8000679c:	508080e7          	jalr	1288(ra) # 80005ca0 <fdalloc>
    800067a0:	fca42223          	sw	a0,-60(s0)
    800067a4:	08054c63          	bltz	a0,8000683c <sys_pipe+0xea>
    800067a8:	fc843503          	ld	a0,-56(s0)
    800067ac:	fffff097          	auipc	ra,0xfffff
    800067b0:	4f4080e7          	jalr	1268(ra) # 80005ca0 <fdalloc>
    800067b4:	fca42023          	sw	a0,-64(s0)
    800067b8:	06054863          	bltz	a0,80006828 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800067bc:	4691                	li	a3,4
    800067be:	fc440613          	addi	a2,s0,-60
    800067c2:	fd843583          	ld	a1,-40(s0)
    800067c6:	7ca8                	ld	a0,120(s1)
    800067c8:	ffffb097          	auipc	ra,0xffffb
    800067cc:	eb8080e7          	jalr	-328(ra) # 80001680 <copyout>
    800067d0:	02054063          	bltz	a0,800067f0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800067d4:	4691                	li	a3,4
    800067d6:	fc040613          	addi	a2,s0,-64
    800067da:	fd843583          	ld	a1,-40(s0)
    800067de:	0591                	addi	a1,a1,4
    800067e0:	7ca8                	ld	a0,120(s1)
    800067e2:	ffffb097          	auipc	ra,0xffffb
    800067e6:	e9e080e7          	jalr	-354(ra) # 80001680 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800067ea:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800067ec:	06055563          	bgez	a0,80006856 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800067f0:	fc442783          	lw	a5,-60(s0)
    800067f4:	07f9                	addi	a5,a5,30
    800067f6:	078e                	slli	a5,a5,0x3
    800067f8:	97a6                	add	a5,a5,s1
    800067fa:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800067fe:	fc042503          	lw	a0,-64(s0)
    80006802:	0579                	addi	a0,a0,30
    80006804:	050e                	slli	a0,a0,0x3
    80006806:	9526                	add	a0,a0,s1
    80006808:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000680c:	fd043503          	ld	a0,-48(s0)
    80006810:	fffff097          	auipc	ra,0xfffff
    80006814:	a3e080e7          	jalr	-1474(ra) # 8000524e <fileclose>
    fileclose(wf);
    80006818:	fc843503          	ld	a0,-56(s0)
    8000681c:	fffff097          	auipc	ra,0xfffff
    80006820:	a32080e7          	jalr	-1486(ra) # 8000524e <fileclose>
    return -1;
    80006824:	57fd                	li	a5,-1
    80006826:	a805                	j	80006856 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006828:	fc442783          	lw	a5,-60(s0)
    8000682c:	0007c863          	bltz	a5,8000683c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006830:	01e78513          	addi	a0,a5,30
    80006834:	050e                	slli	a0,a0,0x3
    80006836:	9526                	add	a0,a0,s1
    80006838:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000683c:	fd043503          	ld	a0,-48(s0)
    80006840:	fffff097          	auipc	ra,0xfffff
    80006844:	a0e080e7          	jalr	-1522(ra) # 8000524e <fileclose>
    fileclose(wf);
    80006848:	fc843503          	ld	a0,-56(s0)
    8000684c:	fffff097          	auipc	ra,0xfffff
    80006850:	a02080e7          	jalr	-1534(ra) # 8000524e <fileclose>
    return -1;
    80006854:	57fd                	li	a5,-1
}
    80006856:	853e                	mv	a0,a5
    80006858:	70e2                	ld	ra,56(sp)
    8000685a:	7442                	ld	s0,48(sp)
    8000685c:	74a2                	ld	s1,40(sp)
    8000685e:	6121                	addi	sp,sp,64
    80006860:	8082                	ret
	...

0000000080006870 <kernelvec>:
    80006870:	7111                	addi	sp,sp,-256
    80006872:	e006                	sd	ra,0(sp)
    80006874:	e40a                	sd	sp,8(sp)
    80006876:	e80e                	sd	gp,16(sp)
    80006878:	ec12                	sd	tp,24(sp)
    8000687a:	f016                	sd	t0,32(sp)
    8000687c:	f41a                	sd	t1,40(sp)
    8000687e:	f81e                	sd	t2,48(sp)
    80006880:	fc22                	sd	s0,56(sp)
    80006882:	e0a6                	sd	s1,64(sp)
    80006884:	e4aa                	sd	a0,72(sp)
    80006886:	e8ae                	sd	a1,80(sp)
    80006888:	ecb2                	sd	a2,88(sp)
    8000688a:	f0b6                	sd	a3,96(sp)
    8000688c:	f4ba                	sd	a4,104(sp)
    8000688e:	f8be                	sd	a5,112(sp)
    80006890:	fcc2                	sd	a6,120(sp)
    80006892:	e146                	sd	a7,128(sp)
    80006894:	e54a                	sd	s2,136(sp)
    80006896:	e94e                	sd	s3,144(sp)
    80006898:	ed52                	sd	s4,152(sp)
    8000689a:	f156                	sd	s5,160(sp)
    8000689c:	f55a                	sd	s6,168(sp)
    8000689e:	f95e                	sd	s7,176(sp)
    800068a0:	fd62                	sd	s8,184(sp)
    800068a2:	e1e6                	sd	s9,192(sp)
    800068a4:	e5ea                	sd	s10,200(sp)
    800068a6:	e9ee                	sd	s11,208(sp)
    800068a8:	edf2                	sd	t3,216(sp)
    800068aa:	f1f6                	sd	t4,224(sp)
    800068ac:	f5fa                	sd	t5,232(sp)
    800068ae:	f9fe                	sd	t6,240(sp)
    800068b0:	d77fc0ef          	jal	ra,80003626 <kerneltrap>
    800068b4:	6082                	ld	ra,0(sp)
    800068b6:	6122                	ld	sp,8(sp)
    800068b8:	61c2                	ld	gp,16(sp)
    800068ba:	7282                	ld	t0,32(sp)
    800068bc:	7322                	ld	t1,40(sp)
    800068be:	73c2                	ld	t2,48(sp)
    800068c0:	7462                	ld	s0,56(sp)
    800068c2:	6486                	ld	s1,64(sp)
    800068c4:	6526                	ld	a0,72(sp)
    800068c6:	65c6                	ld	a1,80(sp)
    800068c8:	6666                	ld	a2,88(sp)
    800068ca:	7686                	ld	a3,96(sp)
    800068cc:	7726                	ld	a4,104(sp)
    800068ce:	77c6                	ld	a5,112(sp)
    800068d0:	7866                	ld	a6,120(sp)
    800068d2:	688a                	ld	a7,128(sp)
    800068d4:	692a                	ld	s2,136(sp)
    800068d6:	69ca                	ld	s3,144(sp)
    800068d8:	6a6a                	ld	s4,152(sp)
    800068da:	7a8a                	ld	s5,160(sp)
    800068dc:	7b2a                	ld	s6,168(sp)
    800068de:	7bca                	ld	s7,176(sp)
    800068e0:	7c6a                	ld	s8,184(sp)
    800068e2:	6c8e                	ld	s9,192(sp)
    800068e4:	6d2e                	ld	s10,200(sp)
    800068e6:	6dce                	ld	s11,208(sp)
    800068e8:	6e6e                	ld	t3,216(sp)
    800068ea:	7e8e                	ld	t4,224(sp)
    800068ec:	7f2e                	ld	t5,232(sp)
    800068ee:	7fce                	ld	t6,240(sp)
    800068f0:	6111                	addi	sp,sp,256
    800068f2:	10200073          	sret
    800068f6:	00000013          	nop
    800068fa:	00000013          	nop
    800068fe:	0001                	nop

0000000080006900 <timervec>:
    80006900:	34051573          	csrrw	a0,mscratch,a0
    80006904:	e10c                	sd	a1,0(a0)
    80006906:	e510                	sd	a2,8(a0)
    80006908:	e914                	sd	a3,16(a0)
    8000690a:	6d0c                	ld	a1,24(a0)
    8000690c:	7110                	ld	a2,32(a0)
    8000690e:	6194                	ld	a3,0(a1)
    80006910:	96b2                	add	a3,a3,a2
    80006912:	e194                	sd	a3,0(a1)
    80006914:	4589                	li	a1,2
    80006916:	14459073          	csrw	sip,a1
    8000691a:	6914                	ld	a3,16(a0)
    8000691c:	6510                	ld	a2,8(a0)
    8000691e:	610c                	ld	a1,0(a0)
    80006920:	34051573          	csrrw	a0,mscratch,a0
    80006924:	30200073          	mret
	...

000000008000692a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000692a:	1141                	addi	sp,sp,-16
    8000692c:	e422                	sd	s0,8(sp)
    8000692e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006930:	0c0007b7          	lui	a5,0xc000
    80006934:	4705                	li	a4,1
    80006936:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006938:	c3d8                	sw	a4,4(a5)
}
    8000693a:	6422                	ld	s0,8(sp)
    8000693c:	0141                	addi	sp,sp,16
    8000693e:	8082                	ret

0000000080006940 <plicinithart>:

void
plicinithart(void)
{
    80006940:	1141                	addi	sp,sp,-16
    80006942:	e406                	sd	ra,8(sp)
    80006944:	e022                	sd	s0,0(sp)
    80006946:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006948:	ffffb097          	auipc	ra,0xffffb
    8000694c:	490080e7          	jalr	1168(ra) # 80001dd8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006950:	0085171b          	slliw	a4,a0,0x8
    80006954:	0c0027b7          	lui	a5,0xc002
    80006958:	97ba                	add	a5,a5,a4
    8000695a:	40200713          	li	a4,1026
    8000695e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006962:	00d5151b          	slliw	a0,a0,0xd
    80006966:	0c2017b7          	lui	a5,0xc201
    8000696a:	953e                	add	a0,a0,a5
    8000696c:	00052023          	sw	zero,0(a0)
}
    80006970:	60a2                	ld	ra,8(sp)
    80006972:	6402                	ld	s0,0(sp)
    80006974:	0141                	addi	sp,sp,16
    80006976:	8082                	ret

0000000080006978 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006978:	1141                	addi	sp,sp,-16
    8000697a:	e406                	sd	ra,8(sp)
    8000697c:	e022                	sd	s0,0(sp)
    8000697e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006980:	ffffb097          	auipc	ra,0xffffb
    80006984:	458080e7          	jalr	1112(ra) # 80001dd8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006988:	00d5179b          	slliw	a5,a0,0xd
    8000698c:	0c201537          	lui	a0,0xc201
    80006990:	953e                	add	a0,a0,a5
  return irq;
}
    80006992:	4148                	lw	a0,4(a0)
    80006994:	60a2                	ld	ra,8(sp)
    80006996:	6402                	ld	s0,0(sp)
    80006998:	0141                	addi	sp,sp,16
    8000699a:	8082                	ret

000000008000699c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000699c:	1101                	addi	sp,sp,-32
    8000699e:	ec06                	sd	ra,24(sp)
    800069a0:	e822                	sd	s0,16(sp)
    800069a2:	e426                	sd	s1,8(sp)
    800069a4:	1000                	addi	s0,sp,32
    800069a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800069a8:	ffffb097          	auipc	ra,0xffffb
    800069ac:	430080e7          	jalr	1072(ra) # 80001dd8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800069b0:	00d5151b          	slliw	a0,a0,0xd
    800069b4:	0c2017b7          	lui	a5,0xc201
    800069b8:	97aa                	add	a5,a5,a0
    800069ba:	c3c4                	sw	s1,4(a5)
}
    800069bc:	60e2                	ld	ra,24(sp)
    800069be:	6442                	ld	s0,16(sp)
    800069c0:	64a2                	ld	s1,8(sp)
    800069c2:	6105                	addi	sp,sp,32
    800069c4:	8082                	ret

00000000800069c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800069c6:	1141                	addi	sp,sp,-16
    800069c8:	e406                	sd	ra,8(sp)
    800069ca:	e022                	sd	s0,0(sp)
    800069cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800069ce:	479d                	li	a5,7
    800069d0:	06a7c963          	blt	a5,a0,80006a42 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800069d4:	0001c797          	auipc	a5,0x1c
    800069d8:	62c78793          	addi	a5,a5,1580 # 80023000 <disk>
    800069dc:	00a78733          	add	a4,a5,a0
    800069e0:	6789                	lui	a5,0x2
    800069e2:	97ba                	add	a5,a5,a4
    800069e4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800069e8:	e7ad                	bnez	a5,80006a52 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800069ea:	00451793          	slli	a5,a0,0x4
    800069ee:	0001e717          	auipc	a4,0x1e
    800069f2:	61270713          	addi	a4,a4,1554 # 80025000 <disk+0x2000>
    800069f6:	6314                	ld	a3,0(a4)
    800069f8:	96be                	add	a3,a3,a5
    800069fa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800069fe:	6314                	ld	a3,0(a4)
    80006a00:	96be                	add	a3,a3,a5
    80006a02:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006a06:	6314                	ld	a3,0(a4)
    80006a08:	96be                	add	a3,a3,a5
    80006a0a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006a0e:	6318                	ld	a4,0(a4)
    80006a10:	97ba                	add	a5,a5,a4
    80006a12:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006a16:	0001c797          	auipc	a5,0x1c
    80006a1a:	5ea78793          	addi	a5,a5,1514 # 80023000 <disk>
    80006a1e:	97aa                	add	a5,a5,a0
    80006a20:	6509                	lui	a0,0x2
    80006a22:	953e                	add	a0,a0,a5
    80006a24:	4785                	li	a5,1
    80006a26:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006a2a:	0001e517          	auipc	a0,0x1e
    80006a2e:	5ee50513          	addi	a0,a0,1518 # 80025018 <disk+0x2018>
    80006a32:	ffffc097          	auipc	ra,0xffffc
    80006a36:	3fe080e7          	jalr	1022(ra) # 80002e30 <wakeup>
}
    80006a3a:	60a2                	ld	ra,8(sp)
    80006a3c:	6402                	ld	s0,0(sp)
    80006a3e:	0141                	addi	sp,sp,16
    80006a40:	8082                	ret
    panic("free_desc 1");
    80006a42:	00002517          	auipc	a0,0x2
    80006a46:	ec650513          	addi	a0,a0,-314 # 80008908 <syscalls+0x330>
    80006a4a:	ffffa097          	auipc	ra,0xffffa
    80006a4e:	af4080e7          	jalr	-1292(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006a52:	00002517          	auipc	a0,0x2
    80006a56:	ec650513          	addi	a0,a0,-314 # 80008918 <syscalls+0x340>
    80006a5a:	ffffa097          	auipc	ra,0xffffa
    80006a5e:	ae4080e7          	jalr	-1308(ra) # 8000053e <panic>

0000000080006a62 <virtio_disk_init>:
{
    80006a62:	1101                	addi	sp,sp,-32
    80006a64:	ec06                	sd	ra,24(sp)
    80006a66:	e822                	sd	s0,16(sp)
    80006a68:	e426                	sd	s1,8(sp)
    80006a6a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006a6c:	00002597          	auipc	a1,0x2
    80006a70:	ebc58593          	addi	a1,a1,-324 # 80008928 <syscalls+0x350>
    80006a74:	0001e517          	auipc	a0,0x1e
    80006a78:	6b450513          	addi	a0,a0,1716 # 80025128 <disk+0x2128>
    80006a7c:	ffffa097          	auipc	ra,0xffffa
    80006a80:	0d8080e7          	jalr	216(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a84:	100017b7          	lui	a5,0x10001
    80006a88:	4398                	lw	a4,0(a5)
    80006a8a:	2701                	sext.w	a4,a4
    80006a8c:	747277b7          	lui	a5,0x74727
    80006a90:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006a94:	0ef71163          	bne	a4,a5,80006b76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006a98:	100017b7          	lui	a5,0x10001
    80006a9c:	43dc                	lw	a5,4(a5)
    80006a9e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006aa0:	4705                	li	a4,1
    80006aa2:	0ce79a63          	bne	a5,a4,80006b76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006aa6:	100017b7          	lui	a5,0x10001
    80006aaa:	479c                	lw	a5,8(a5)
    80006aac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006aae:	4709                	li	a4,2
    80006ab0:	0ce79363          	bne	a5,a4,80006b76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006ab4:	100017b7          	lui	a5,0x10001
    80006ab8:	47d8                	lw	a4,12(a5)
    80006aba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006abc:	554d47b7          	lui	a5,0x554d4
    80006ac0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006ac4:	0af71963          	bne	a4,a5,80006b76 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ac8:	100017b7          	lui	a5,0x10001
    80006acc:	4705                	li	a4,1
    80006ace:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ad0:	470d                	li	a4,3
    80006ad2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006ad4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006ad6:	c7ffe737          	lui	a4,0xc7ffe
    80006ada:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80006ade:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006ae0:	2701                	sext.w	a4,a4
    80006ae2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ae4:	472d                	li	a4,11
    80006ae6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ae8:	473d                	li	a4,15
    80006aea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006aec:	6705                	lui	a4,0x1
    80006aee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006af0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006af4:	5bdc                	lw	a5,52(a5)
    80006af6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006af8:	c7d9                	beqz	a5,80006b86 <virtio_disk_init+0x124>
  if(max < NUM)
    80006afa:	471d                	li	a4,7
    80006afc:	08f77d63          	bgeu	a4,a5,80006b96 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006b00:	100014b7          	lui	s1,0x10001
    80006b04:	47a1                	li	a5,8
    80006b06:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006b08:	6609                	lui	a2,0x2
    80006b0a:	4581                	li	a1,0
    80006b0c:	0001c517          	auipc	a0,0x1c
    80006b10:	4f450513          	addi	a0,a0,1268 # 80023000 <disk>
    80006b14:	ffffa097          	auipc	ra,0xffffa
    80006b18:	1da080e7          	jalr	474(ra) # 80000cee <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006b1c:	0001c717          	auipc	a4,0x1c
    80006b20:	4e470713          	addi	a4,a4,1252 # 80023000 <disk>
    80006b24:	00c75793          	srli	a5,a4,0xc
    80006b28:	2781                	sext.w	a5,a5
    80006b2a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006b2c:	0001e797          	auipc	a5,0x1e
    80006b30:	4d478793          	addi	a5,a5,1236 # 80025000 <disk+0x2000>
    80006b34:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006b36:	0001c717          	auipc	a4,0x1c
    80006b3a:	54a70713          	addi	a4,a4,1354 # 80023080 <disk+0x80>
    80006b3e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006b40:	0001d717          	auipc	a4,0x1d
    80006b44:	4c070713          	addi	a4,a4,1216 # 80024000 <disk+0x1000>
    80006b48:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006b4a:	4705                	li	a4,1
    80006b4c:	00e78c23          	sb	a4,24(a5)
    80006b50:	00e78ca3          	sb	a4,25(a5)
    80006b54:	00e78d23          	sb	a4,26(a5)
    80006b58:	00e78da3          	sb	a4,27(a5)
    80006b5c:	00e78e23          	sb	a4,28(a5)
    80006b60:	00e78ea3          	sb	a4,29(a5)
    80006b64:	00e78f23          	sb	a4,30(a5)
    80006b68:	00e78fa3          	sb	a4,31(a5)
}
    80006b6c:	60e2                	ld	ra,24(sp)
    80006b6e:	6442                	ld	s0,16(sp)
    80006b70:	64a2                	ld	s1,8(sp)
    80006b72:	6105                	addi	sp,sp,32
    80006b74:	8082                	ret
    panic("could not find virtio disk");
    80006b76:	00002517          	auipc	a0,0x2
    80006b7a:	dc250513          	addi	a0,a0,-574 # 80008938 <syscalls+0x360>
    80006b7e:	ffffa097          	auipc	ra,0xffffa
    80006b82:	9c0080e7          	jalr	-1600(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006b86:	00002517          	auipc	a0,0x2
    80006b8a:	dd250513          	addi	a0,a0,-558 # 80008958 <syscalls+0x380>
    80006b8e:	ffffa097          	auipc	ra,0xffffa
    80006b92:	9b0080e7          	jalr	-1616(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006b96:	00002517          	auipc	a0,0x2
    80006b9a:	de250513          	addi	a0,a0,-542 # 80008978 <syscalls+0x3a0>
    80006b9e:	ffffa097          	auipc	ra,0xffffa
    80006ba2:	9a0080e7          	jalr	-1632(ra) # 8000053e <panic>

0000000080006ba6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006ba6:	7159                	addi	sp,sp,-112
    80006ba8:	f486                	sd	ra,104(sp)
    80006baa:	f0a2                	sd	s0,96(sp)
    80006bac:	eca6                	sd	s1,88(sp)
    80006bae:	e8ca                	sd	s2,80(sp)
    80006bb0:	e4ce                	sd	s3,72(sp)
    80006bb2:	e0d2                	sd	s4,64(sp)
    80006bb4:	fc56                	sd	s5,56(sp)
    80006bb6:	f85a                	sd	s6,48(sp)
    80006bb8:	f45e                	sd	s7,40(sp)
    80006bba:	f062                	sd	s8,32(sp)
    80006bbc:	ec66                	sd	s9,24(sp)
    80006bbe:	e86a                	sd	s10,16(sp)
    80006bc0:	1880                	addi	s0,sp,112
    80006bc2:	892a                	mv	s2,a0
    80006bc4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006bc6:	00c52c83          	lw	s9,12(a0)
    80006bca:	001c9c9b          	slliw	s9,s9,0x1
    80006bce:	1c82                	slli	s9,s9,0x20
    80006bd0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006bd4:	0001e517          	auipc	a0,0x1e
    80006bd8:	55450513          	addi	a0,a0,1364 # 80025128 <disk+0x2128>
    80006bdc:	ffffa097          	auipc	ra,0xffffa
    80006be0:	010080e7          	jalr	16(ra) # 80000bec <acquire>
  for(int i = 0; i < 3; i++){
    80006be4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006be6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006be8:	0001cb97          	auipc	s7,0x1c
    80006bec:	418b8b93          	addi	s7,s7,1048 # 80023000 <disk>
    80006bf0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006bf2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006bf4:	8a4e                	mv	s4,s3
    80006bf6:	a051                	j	80006c7a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006bf8:	00fb86b3          	add	a3,s7,a5
    80006bfc:	96da                	add	a3,a3,s6
    80006bfe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006c02:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006c04:	0207c563          	bltz	a5,80006c2e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006c08:	2485                	addiw	s1,s1,1
    80006c0a:	0711                	addi	a4,a4,4
    80006c0c:	25548063          	beq	s1,s5,80006e4c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006c10:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006c12:	0001e697          	auipc	a3,0x1e
    80006c16:	40668693          	addi	a3,a3,1030 # 80025018 <disk+0x2018>
    80006c1a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006c1c:	0006c583          	lbu	a1,0(a3)
    80006c20:	fde1                	bnez	a1,80006bf8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006c22:	2785                	addiw	a5,a5,1
    80006c24:	0685                	addi	a3,a3,1
    80006c26:	ff879be3          	bne	a5,s8,80006c1c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006c2a:	57fd                	li	a5,-1
    80006c2c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006c2e:	02905a63          	blez	s1,80006c62 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006c32:	f9042503          	lw	a0,-112(s0)
    80006c36:	00000097          	auipc	ra,0x0
    80006c3a:	d90080e7          	jalr	-624(ra) # 800069c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006c3e:	4785                	li	a5,1
    80006c40:	0297d163          	bge	a5,s1,80006c62 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006c44:	f9442503          	lw	a0,-108(s0)
    80006c48:	00000097          	auipc	ra,0x0
    80006c4c:	d7e080e7          	jalr	-642(ra) # 800069c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006c50:	4789                	li	a5,2
    80006c52:	0097d863          	bge	a5,s1,80006c62 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006c56:	f9842503          	lw	a0,-104(s0)
    80006c5a:	00000097          	auipc	ra,0x0
    80006c5e:	d6c080e7          	jalr	-660(ra) # 800069c6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c62:	0001e597          	auipc	a1,0x1e
    80006c66:	4c658593          	addi	a1,a1,1222 # 80025128 <disk+0x2128>
    80006c6a:	0001e517          	auipc	a0,0x1e
    80006c6e:	3ae50513          	addi	a0,a0,942 # 80025018 <disk+0x2018>
    80006c72:	ffffc097          	auipc	ra,0xffffc
    80006c76:	018080e7          	jalr	24(ra) # 80002c8a <sleep>
  for(int i = 0; i < 3; i++){
    80006c7a:	f9040713          	addi	a4,s0,-112
    80006c7e:	84ce                	mv	s1,s3
    80006c80:	bf41                	j	80006c10 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006c82:	20058713          	addi	a4,a1,512
    80006c86:	00471693          	slli	a3,a4,0x4
    80006c8a:	0001c717          	auipc	a4,0x1c
    80006c8e:	37670713          	addi	a4,a4,886 # 80023000 <disk>
    80006c92:	9736                	add	a4,a4,a3
    80006c94:	4685                	li	a3,1
    80006c96:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006c9a:	20058713          	addi	a4,a1,512
    80006c9e:	00471693          	slli	a3,a4,0x4
    80006ca2:	0001c717          	auipc	a4,0x1c
    80006ca6:	35e70713          	addi	a4,a4,862 # 80023000 <disk>
    80006caa:	9736                	add	a4,a4,a3
    80006cac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006cb0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006cb4:	7679                	lui	a2,0xffffe
    80006cb6:	963e                	add	a2,a2,a5
    80006cb8:	0001e697          	auipc	a3,0x1e
    80006cbc:	34868693          	addi	a3,a3,840 # 80025000 <disk+0x2000>
    80006cc0:	6298                	ld	a4,0(a3)
    80006cc2:	9732                	add	a4,a4,a2
    80006cc4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006cc6:	6298                	ld	a4,0(a3)
    80006cc8:	9732                	add	a4,a4,a2
    80006cca:	4541                	li	a0,16
    80006ccc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006cce:	6298                	ld	a4,0(a3)
    80006cd0:	9732                	add	a4,a4,a2
    80006cd2:	4505                	li	a0,1
    80006cd4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006cd8:	f9442703          	lw	a4,-108(s0)
    80006cdc:	6288                	ld	a0,0(a3)
    80006cde:	962a                	add	a2,a2,a0
    80006ce0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006ce4:	0712                	slli	a4,a4,0x4
    80006ce6:	6290                	ld	a2,0(a3)
    80006ce8:	963a                	add	a2,a2,a4
    80006cea:	05890513          	addi	a0,s2,88
    80006cee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006cf0:	6294                	ld	a3,0(a3)
    80006cf2:	96ba                	add	a3,a3,a4
    80006cf4:	40000613          	li	a2,1024
    80006cf8:	c690                	sw	a2,8(a3)
  if(write)
    80006cfa:	140d0063          	beqz	s10,80006e3a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006cfe:	0001e697          	auipc	a3,0x1e
    80006d02:	3026b683          	ld	a3,770(a3) # 80025000 <disk+0x2000>
    80006d06:	96ba                	add	a3,a3,a4
    80006d08:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006d0c:	0001c817          	auipc	a6,0x1c
    80006d10:	2f480813          	addi	a6,a6,756 # 80023000 <disk>
    80006d14:	0001e517          	auipc	a0,0x1e
    80006d18:	2ec50513          	addi	a0,a0,748 # 80025000 <disk+0x2000>
    80006d1c:	6114                	ld	a3,0(a0)
    80006d1e:	96ba                	add	a3,a3,a4
    80006d20:	00c6d603          	lhu	a2,12(a3)
    80006d24:	00166613          	ori	a2,a2,1
    80006d28:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006d2c:	f9842683          	lw	a3,-104(s0)
    80006d30:	6110                	ld	a2,0(a0)
    80006d32:	9732                	add	a4,a4,a2
    80006d34:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006d38:	20058613          	addi	a2,a1,512
    80006d3c:	0612                	slli	a2,a2,0x4
    80006d3e:	9642                	add	a2,a2,a6
    80006d40:	577d                	li	a4,-1
    80006d42:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006d46:	00469713          	slli	a4,a3,0x4
    80006d4a:	6114                	ld	a3,0(a0)
    80006d4c:	96ba                	add	a3,a3,a4
    80006d4e:	03078793          	addi	a5,a5,48
    80006d52:	97c2                	add	a5,a5,a6
    80006d54:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006d56:	611c                	ld	a5,0(a0)
    80006d58:	97ba                	add	a5,a5,a4
    80006d5a:	4685                	li	a3,1
    80006d5c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006d5e:	611c                	ld	a5,0(a0)
    80006d60:	97ba                	add	a5,a5,a4
    80006d62:	4809                	li	a6,2
    80006d64:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006d68:	611c                	ld	a5,0(a0)
    80006d6a:	973e                	add	a4,a4,a5
    80006d6c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006d70:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006d74:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006d78:	6518                	ld	a4,8(a0)
    80006d7a:	00275783          	lhu	a5,2(a4)
    80006d7e:	8b9d                	andi	a5,a5,7
    80006d80:	0786                	slli	a5,a5,0x1
    80006d82:	97ba                	add	a5,a5,a4
    80006d84:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006d88:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006d8c:	6518                	ld	a4,8(a0)
    80006d8e:	00275783          	lhu	a5,2(a4)
    80006d92:	2785                	addiw	a5,a5,1
    80006d94:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006d98:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006d9c:	100017b7          	lui	a5,0x10001
    80006da0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006da4:	00492703          	lw	a4,4(s2)
    80006da8:	4785                	li	a5,1
    80006daa:	02f71163          	bne	a4,a5,80006dcc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006dae:	0001e997          	auipc	s3,0x1e
    80006db2:	37a98993          	addi	s3,s3,890 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006db6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006db8:	85ce                	mv	a1,s3
    80006dba:	854a                	mv	a0,s2
    80006dbc:	ffffc097          	auipc	ra,0xffffc
    80006dc0:	ece080e7          	jalr	-306(ra) # 80002c8a <sleep>
  while(b->disk == 1) {
    80006dc4:	00492783          	lw	a5,4(s2)
    80006dc8:	fe9788e3          	beq	a5,s1,80006db8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006dcc:	f9042903          	lw	s2,-112(s0)
    80006dd0:	20090793          	addi	a5,s2,512
    80006dd4:	00479713          	slli	a4,a5,0x4
    80006dd8:	0001c797          	auipc	a5,0x1c
    80006ddc:	22878793          	addi	a5,a5,552 # 80023000 <disk>
    80006de0:	97ba                	add	a5,a5,a4
    80006de2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006de6:	0001e997          	auipc	s3,0x1e
    80006dea:	21a98993          	addi	s3,s3,538 # 80025000 <disk+0x2000>
    80006dee:	00491713          	slli	a4,s2,0x4
    80006df2:	0009b783          	ld	a5,0(s3)
    80006df6:	97ba                	add	a5,a5,a4
    80006df8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006dfc:	854a                	mv	a0,s2
    80006dfe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006e02:	00000097          	auipc	ra,0x0
    80006e06:	bc4080e7          	jalr	-1084(ra) # 800069c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006e0a:	8885                	andi	s1,s1,1
    80006e0c:	f0ed                	bnez	s1,80006dee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006e0e:	0001e517          	auipc	a0,0x1e
    80006e12:	31a50513          	addi	a0,a0,794 # 80025128 <disk+0x2128>
    80006e16:	ffffa097          	auipc	ra,0xffffa
    80006e1a:	e90080e7          	jalr	-368(ra) # 80000ca6 <release>
}
    80006e1e:	70a6                	ld	ra,104(sp)
    80006e20:	7406                	ld	s0,96(sp)
    80006e22:	64e6                	ld	s1,88(sp)
    80006e24:	6946                	ld	s2,80(sp)
    80006e26:	69a6                	ld	s3,72(sp)
    80006e28:	6a06                	ld	s4,64(sp)
    80006e2a:	7ae2                	ld	s5,56(sp)
    80006e2c:	7b42                	ld	s6,48(sp)
    80006e2e:	7ba2                	ld	s7,40(sp)
    80006e30:	7c02                	ld	s8,32(sp)
    80006e32:	6ce2                	ld	s9,24(sp)
    80006e34:	6d42                	ld	s10,16(sp)
    80006e36:	6165                	addi	sp,sp,112
    80006e38:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006e3a:	0001e697          	auipc	a3,0x1e
    80006e3e:	1c66b683          	ld	a3,454(a3) # 80025000 <disk+0x2000>
    80006e42:	96ba                	add	a3,a3,a4
    80006e44:	4609                	li	a2,2
    80006e46:	00c69623          	sh	a2,12(a3)
    80006e4a:	b5c9                	j	80006d0c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006e4c:	f9042583          	lw	a1,-112(s0)
    80006e50:	20058793          	addi	a5,a1,512
    80006e54:	0792                	slli	a5,a5,0x4
    80006e56:	0001c517          	auipc	a0,0x1c
    80006e5a:	25250513          	addi	a0,a0,594 # 800230a8 <disk+0xa8>
    80006e5e:	953e                	add	a0,a0,a5
  if(write)
    80006e60:	e20d11e3          	bnez	s10,80006c82 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006e64:	20058713          	addi	a4,a1,512
    80006e68:	00471693          	slli	a3,a4,0x4
    80006e6c:	0001c717          	auipc	a4,0x1c
    80006e70:	19470713          	addi	a4,a4,404 # 80023000 <disk>
    80006e74:	9736                	add	a4,a4,a3
    80006e76:	0a072423          	sw	zero,168(a4)
    80006e7a:	b505                	j	80006c9a <virtio_disk_rw+0xf4>

0000000080006e7c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006e7c:	1101                	addi	sp,sp,-32
    80006e7e:	ec06                	sd	ra,24(sp)
    80006e80:	e822                	sd	s0,16(sp)
    80006e82:	e426                	sd	s1,8(sp)
    80006e84:	e04a                	sd	s2,0(sp)
    80006e86:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006e88:	0001e517          	auipc	a0,0x1e
    80006e8c:	2a050513          	addi	a0,a0,672 # 80025128 <disk+0x2128>
    80006e90:	ffffa097          	auipc	ra,0xffffa
    80006e94:	d5c080e7          	jalr	-676(ra) # 80000bec <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006e98:	10001737          	lui	a4,0x10001
    80006e9c:	533c                	lw	a5,96(a4)
    80006e9e:	8b8d                	andi	a5,a5,3
    80006ea0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ea2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ea6:	0001e797          	auipc	a5,0x1e
    80006eaa:	15a78793          	addi	a5,a5,346 # 80025000 <disk+0x2000>
    80006eae:	6b94                	ld	a3,16(a5)
    80006eb0:	0207d703          	lhu	a4,32(a5)
    80006eb4:	0026d783          	lhu	a5,2(a3)
    80006eb8:	06f70163          	beq	a4,a5,80006f1a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ebc:	0001c917          	auipc	s2,0x1c
    80006ec0:	14490913          	addi	s2,s2,324 # 80023000 <disk>
    80006ec4:	0001e497          	auipc	s1,0x1e
    80006ec8:	13c48493          	addi	s1,s1,316 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006ecc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ed0:	6898                	ld	a4,16(s1)
    80006ed2:	0204d783          	lhu	a5,32(s1)
    80006ed6:	8b9d                	andi	a5,a5,7
    80006ed8:	078e                	slli	a5,a5,0x3
    80006eda:	97ba                	add	a5,a5,a4
    80006edc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006ede:	20078713          	addi	a4,a5,512
    80006ee2:	0712                	slli	a4,a4,0x4
    80006ee4:	974a                	add	a4,a4,s2
    80006ee6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006eea:	e731                	bnez	a4,80006f36 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006eec:	20078793          	addi	a5,a5,512
    80006ef0:	0792                	slli	a5,a5,0x4
    80006ef2:	97ca                	add	a5,a5,s2
    80006ef4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006ef6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006efa:	ffffc097          	auipc	ra,0xffffc
    80006efe:	f36080e7          	jalr	-202(ra) # 80002e30 <wakeup>

    disk.used_idx += 1;
    80006f02:	0204d783          	lhu	a5,32(s1)
    80006f06:	2785                	addiw	a5,a5,1
    80006f08:	17c2                	slli	a5,a5,0x30
    80006f0a:	93c1                	srli	a5,a5,0x30
    80006f0c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006f10:	6898                	ld	a4,16(s1)
    80006f12:	00275703          	lhu	a4,2(a4)
    80006f16:	faf71be3          	bne	a4,a5,80006ecc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006f1a:	0001e517          	auipc	a0,0x1e
    80006f1e:	20e50513          	addi	a0,a0,526 # 80025128 <disk+0x2128>
    80006f22:	ffffa097          	auipc	ra,0xffffa
    80006f26:	d84080e7          	jalr	-636(ra) # 80000ca6 <release>
}
    80006f2a:	60e2                	ld	ra,24(sp)
    80006f2c:	6442                	ld	s0,16(sp)
    80006f2e:	64a2                	ld	s1,8(sp)
    80006f30:	6902                	ld	s2,0(sp)
    80006f32:	6105                	addi	sp,sp,32
    80006f34:	8082                	ret
      panic("virtio_disk_intr status");
    80006f36:	00002517          	auipc	a0,0x2
    80006f3a:	a6250513          	addi	a0,a0,-1438 # 80008998 <syscalls+0x3c0>
    80006f3e:	ffff9097          	auipc	ra,0xffff9
    80006f42:	600080e7          	jalr	1536(ra) # 8000053e <panic>

0000000080006f46 <cas>:
    80006f46:	100522af          	lr.w	t0,(a0)
    80006f4a:	00b29563          	bne	t0,a1,80006f54 <fail>
    80006f4e:	18c5252f          	sc.w	a0,a2,(a0)
    80006f52:	8082                	ret

0000000080006f54 <fail>:
    80006f54:	4505                	li	a0,1
    80006f56:	8082                	ret
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
