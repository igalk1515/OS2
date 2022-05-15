
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	a6013103          	ld	sp,-1440(sp) # 80009a60 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	9cc78793          	addi	a5,a5,-1588 # 80006a30 <timervec>
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
    80000130:	20e080e7          	jalr	526(ra) # 8000333a <either_copyin>
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
    800001d8:	bde080e7          	jalr	-1058(ra) # 80002db2 <sleep>
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
    80000214:	0d4080e7          	jalr	212(ra) # 800032e4 <either_copyout>
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
    800002f6:	09e080e7          	jalr	158(ra) # 80003390 <procdump>
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
    8000044a:	b14080e7          	jalr	-1260(ra) # 80002f5a <wakeup>
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
    800008a4:	6ba080e7          	jalr	1722(ra) # 80002f5a <wakeup>
    
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
    80000930:	486080e7          	jalr	1158(ra) # 80002db2 <sleep>
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
    80000ee6:	5ee080e7          	jalr	1518(ra) # 800034d0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eea:	00006097          	auipc	ra,0x6
    80000eee:	b86080e7          	jalr	-1146(ra) # 80006a70 <plicinithart>
  }

  scheduler();        
    80000ef2:	00002097          	auipc	ra,0x2
    80000ef6:	972080e7          	jalr	-1678(ra) # 80002864 <scheduler>
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
    80000f5e:	54e080e7          	jalr	1358(ra) # 800034a8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	56e080e7          	jalr	1390(ra) # 800034d0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f6a:	00006097          	auipc	ra,0x6
    80000f6e:	af0080e7          	jalr	-1296(ra) # 80006a5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f72:	00006097          	auipc	ra,0x6
    80000f76:	afe080e7          	jalr	-1282(ra) # 80006a70 <plicinithart>
    binit();         // buffer cache
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	ce2080e7          	jalr	-798(ra) # 80003c5c <binit>
    iinit();         // inode table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	372080e7          	jalr	882(ra) # 800042f4 <iinit>
    fileinit();      // file table
    80000f8a:	00004097          	auipc	ra,0x4
    80000f8e:	31c080e7          	jalr	796(ra) # 800052a6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f92:	00006097          	auipc	ra,0x6
    80000f96:	c00080e7          	jalr	-1024(ra) # 80006b92 <virtio_disk_init>
    userinit();      // first user process
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	bdc080e7          	jalr	-1060(ra) # 80002b76 <userinit>
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
    80001b14:	566080e7          	jalr	1382(ra) # 80007076 <cas>
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
    80001f18:	afc7a783          	lw	a5,-1284(a5) # 80009a10 <first.1866>
    80001f1c:	eb89                	bnez	a5,80001f2e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001f1e:	00001097          	auipc	ra,0x1
    80001f22:	5ca080e7          	jalr	1482(ra) # 800034e8 <usertrapret>
}
    80001f26:	60a2                	ld	ra,8(sp)
    80001f28:	6402                	ld	s0,0(sp)
    80001f2a:	0141                	addi	sp,sp,16
    80001f2c:	8082                	ret
    first = 0;
    80001f2e:	00008797          	auipc	a5,0x8
    80001f32:	ae07a123          	sw	zero,-1310(a5) # 80009a10 <first.1866>
    fsinit(ROOTDEV);
    80001f36:	4505                	li	a0,1
    80001f38:	00002097          	auipc	ra,0x2
    80001f3c:	33c080e7          	jalr	828(ra) # 80004274 <fsinit>
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
    80001f52:	ac690913          	addi	s2,s2,-1338 # 80009a14 <nextpid>
    80001f56:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid, pid, pid + 1));
    80001f5a:	0014861b          	addiw	a2,s1,1
    80001f5e:	85a6                	mv	a1,s1
    80001f60:	854a                	mv	a0,s2
    80001f62:	00005097          	auipc	ra,0x5
    80001f66:	114080e7          	jalr	276(ra) # 80007076 <cas>
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
    8000216c:	2d6080e7          	jalr	726(ra) # 8000343e <swtch>
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
    800027ae:	8912                	mv	s2,tp
    800027b0:	2901                	sext.w	s2,s2
  c->proc = 0;
    800027b2:	00379a13          	slli	s4,a5,0x3
    800027b6:	00fa0733          	add	a4,s4,a5
    800027ba:	00471693          	slli	a3,a4,0x4
    800027be:	00010717          	auipc	a4,0x10
    800027c2:	b2270713          	addi	a4,a4,-1246 # 800122e0 <readyLock>
    800027c6:	9736                	add	a4,a4,a3
    800027c8:	08073c23          	sd	zero,152(a4)
      swtch(&c->context, &p->context);
    800027cc:	00010717          	auipc	a4,0x10
    800027d0:	bb470713          	addi	a4,a4,-1100 # 80012380 <cpus+0x10>
    800027d4:	00e68a33          	add	s4,a3,a4
      if(p->state!=RUNNABLE){
    800027d8:	4a8d                	li	s5,3
      p->state = RUNNING;
    800027da:	4b11                	li	s6,4
      c->proc = p;
    800027dc:	00010997          	auipc	s3,0x10
    800027e0:	b0498993          	addi	s3,s3,-1276 # 800122e0 <readyLock>
    800027e4:	99b6                	add	s3,s3,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ee:	10079073          	csrw	sstatus,a5
    p = get_first(readyList, cpu_id);
    800027f2:	85ca                	mv	a1,s2
    800027f4:	4501                	li	a0,0
    800027f6:	00000097          	auipc	ra,0x0
    800027fa:	f08080e7          	jalr	-248(ra) # 800026fe <get_first>
    800027fe:	84aa                	mv	s1,a0
    if(!p){ 
    80002800:	d17d                	beqz	a0,800027e6 <blncflag_on+0x50>
      cahnge_number_of_proc(p->parent_cpu,b);
    80002802:	55fd                	li	a1,-1
    80002804:	4d28                	lw	a0,88(a0)
    80002806:	fffff097          	auipc	ra,0xfffff
    8000280a:	2d2080e7          	jalr	722(ra) # 80001ad8 <cahnge_number_of_proc>
      p->parent_cpu = cpu_id;
    8000280e:	0524ac23          	sw	s2,88(s1)
      cahnge_number_of_proc(cpu_id,a);
    80002812:	4585                	li	a1,1
    80002814:	854a                	mv	a0,s2
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	2c2080e7          	jalr	706(ra) # 80001ad8 <cahnge_number_of_proc>
      acquire(&p->lock);
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	3cc080e7          	jalr	972(ra) # 80000bec <acquire>
      if(p->state!=RUNNABLE){
    80002828:	589c                	lw	a5,48(s1)
    8000282a:	03579563          	bne	a5,s5,80002854 <blncflag_on+0xbe>
      p->state = RUNNING;
    8000282e:	0364a823          	sw	s6,48(s1)
      c->proc = p;
    80002832:	0899bc23          	sd	s1,152(s3)
      swtch(&c->context, &p->context);
    80002836:	08848593          	addi	a1,s1,136
    8000283a:	8552                	mv	a0,s4
    8000283c:	00001097          	auipc	ra,0x1
    80002840:	c02080e7          	jalr	-1022(ra) # 8000343e <swtch>
      c->proc = 0;
    80002844:	0809bc23          	sd	zero,152(s3)
      release(&p->lock);
    80002848:	8526                	mv	a0,s1
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	45c080e7          	jalr	1116(ra) # 80000ca6 <release>
    80002852:	bf51                	j	800027e6 <blncflag_on+0x50>
        panic("blncflag_on");
    80002854:	00007517          	auipc	a0,0x7
    80002858:	b9c50513          	addi	a0,a0,-1124 # 800093f0 <digits+0x3b0>
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	ce2080e7          	jalr	-798(ra) # 8000053e <panic>

0000000080002864 <scheduler>:
{
    80002864:	1141                	addi	sp,sp,-16
    80002866:	e406                	sd	ra,8(sp)
    80002868:	e022                	sd	s0,0(sp)
    8000286a:	0800                	addi	s0,sp,16
      if(!print_flag){
    8000286c:	00008797          	auipc	a5,0x8
    80002870:	8007a783          	lw	a5,-2048(a5) # 8000a06c <print_flag>
    80002874:	c789                	beqz	a5,8000287e <scheduler+0x1a>
    blncflag_on();
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	f20080e7          	jalr	-224(ra) # 80002796 <blncflag_on>
      print_flag++;
    8000287e:	4785                	li	a5,1
    80002880:	00007717          	auipc	a4,0x7
    80002884:	7ef72623          	sw	a5,2028(a4) # 8000a06c <print_flag>
      printf("BLNCFLG is ON\n");
    80002888:	00007517          	auipc	a0,0x7
    8000288c:	b7850513          	addi	a0,a0,-1160 # 80009400 <digits+0x3c0>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	cf8080e7          	jalr	-776(ra) # 80000588 <printf>
    80002898:	bff9                	j	80002876 <scheduler+0x12>

000000008000289a <blncflag_off>:
{
    8000289a:	7139                	addi	sp,sp,-64
    8000289c:	fc06                	sd	ra,56(sp)
    8000289e:	f822                	sd	s0,48(sp)
    800028a0:	f426                	sd	s1,40(sp)
    800028a2:	f04a                	sd	s2,32(sp)
    800028a4:	ec4e                	sd	s3,24(sp)
    800028a6:	e852                	sd	s4,16(sp)
    800028a8:	e456                	sd	s5,8(sp)
    800028aa:	e05a                	sd	s6,0(sp)
    800028ac:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    800028ae:	8792                	mv	a5,tp
  int id = r_tp();
    800028b0:	2781                	sext.w	a5,a5
    800028b2:	8a12                	mv	s4,tp
    800028b4:	2a01                	sext.w	s4,s4
  c->proc = 0;
    800028b6:	00379993          	slli	s3,a5,0x3
    800028ba:	00f98733          	add	a4,s3,a5
    800028be:	00471693          	slli	a3,a4,0x4
    800028c2:	00010717          	auipc	a4,0x10
    800028c6:	a1e70713          	addi	a4,a4,-1506 # 800122e0 <readyLock>
    800028ca:	9736                	add	a4,a4,a3
    800028cc:	08073c23          	sd	zero,152(a4)
        swtch(&c->context, &p->context);
    800028d0:	00010717          	auipc	a4,0x10
    800028d4:	ab070713          	addi	a4,a4,-1360 # 80012380 <cpus+0x10>
    800028d8:	00e689b3          	add	s3,a3,a4
      if(p->state != RUNNABLE)
    800028dc:	4a8d                	li	s5,3
        p->state = RUNNING;
    800028de:	4b11                	li	s6,4
        c->proc = p;
    800028e0:	00010917          	auipc	s2,0x10
    800028e4:	a0090913          	addi	s2,s2,-1536 # 800122e0 <readyLock>
    800028e8:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028ee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f2:	10079073          	csrw	sstatus,a5
    p = get_first(readyList, cpu_id);
    800028f6:	85d2                	mv	a1,s4
    800028f8:	4501                	li	a0,0
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	e04080e7          	jalr	-508(ra) # 800026fe <get_first>
    80002902:	84aa                	mv	s1,a0
    if(!p){ // no proces ready 
    80002904:	d17d                	beqz	a0,800028ea <blncflag_off+0x50>
      acquire(&p->lock);
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	2e6080e7          	jalr	742(ra) # 80000bec <acquire>
      if(p->state != RUNNABLE)
    8000290e:	589c                	lw	a5,48(s1)
    80002910:	03579563          	bne	a5,s5,8000293a <blncflag_off+0xa0>
        p->state = RUNNING;
    80002914:	0364a823          	sw	s6,48(s1)
        c->proc = p;
    80002918:	08993c23          	sd	s1,152(s2)
        swtch(&c->context, &p->context);
    8000291c:	08848593          	addi	a1,s1,136
    80002920:	854e                	mv	a0,s3
    80002922:	00001097          	auipc	ra,0x1
    80002926:	b1c080e7          	jalr	-1252(ra) # 8000343e <swtch>
        c->proc = 0;
    8000292a:	08093c23          	sd	zero,152(s2)
      release(&p->lock);
    8000292e:	8526                	mv	a0,s1
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	376080e7          	jalr	886(ra) # 80000ca6 <release>
    80002938:	bf4d                	j	800028ea <blncflag_off+0x50>
        panic("blncflag_off");
    8000293a:	00007517          	auipc	a0,0x7
    8000293e:	ad650513          	addi	a0,a0,-1322 # 80009410 <digits+0x3d0>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	bfc080e7          	jalr	-1028(ra) # 8000053e <panic>

000000008000294a <delete_proc_from_list>:
delete_proc_from_list(struct proc* first,struct proc* proc, int number, int debug_flag){
    8000294a:	7179                	addi	sp,sp,-48
    8000294c:	f406                	sd	ra,40(sp)
    8000294e:	f022                	sd	s0,32(sp)
    80002950:	ec26                	sd	s1,24(sp)
    80002952:	e84a                	sd	s2,16(sp)
    80002954:	e44e                	sd	s3,8(sp)
    80002956:	e052                	sd	s4,0(sp)
    80002958:	1800                	addi	s0,sp,48
    8000295a:	892a                	mv	s2,a0
    8000295c:	84ae                	mv	s1,a1
    8000295e:	8a32                	mv	s4,a2
    80002960:	89b6                	mv	s3,a3
  if(debug_flag==debugFlag){
    80002962:	4791                	li	a5,4
    80002964:	02f68963          	beq	a3,a5,80002996 <delete_proc_from_list+0x4c>
  if(!first){
    80002968:	04090163          	beqz	s2,800029aa <delete_proc_from_list+0x60>
  else if(proc == first){
    8000296c:	04990a63          	beq	s2,s1,800029c0 <delete_proc_from_list+0x76>
    if(debug_flag==debugFlag){
    80002970:	4791                	li	a5,4
    80002972:	0af98163          	beq	s3,a5,80002a14 <delete_proc_from_list+0xca>
    return delete_the_first_not_empty_list(proc,first,number,0);
    80002976:	4681                	li	a3,0
    80002978:	8652                	mv	a2,s4
    8000297a:	85ca                	mv	a1,s2
    8000297c:	8526                	mv	a0,s1
    8000297e:	fffff097          	auipc	ra,0xfffff
    80002982:	37e080e7          	jalr	894(ra) # 80001cfc <delete_the_first_not_empty_list>
}
    80002986:	70a2                	ld	ra,40(sp)
    80002988:	7402                	ld	s0,32(sp)
    8000298a:	64e2                	ld	s1,24(sp)
    8000298c:	6942                	ld	s2,16(sp)
    8000298e:	69a2                	ld	s3,8(sp)
    80002990:	6a02                	ld	s4,0(sp)
    80002992:	6145                	addi	sp,sp,48
    80002994:	8082                	ret
    printf("first is %d",first);
    80002996:	85aa                	mv	a1,a0
    80002998:	00007517          	auipc	a0,0x7
    8000299c:	90850513          	addi	a0,a0,-1784 # 800092a0 <digits+0x260>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	be8080e7          	jalr	-1048(ra) # 80000588 <printf>
    800029a8:	b7c1                	j	80002968 <delete_proc_from_list+0x1e>
  release_list(number, proc->parent_cpu);
    800029aa:	00010597          	auipc	a1,0x10
    800029ae:	c8e5a583          	lw	a1,-882(a1) # 80012638 <proc+0x58>
    800029b2:	8552                	mv	a0,s4
    800029b4:	fffff097          	auipc	ra,0xfffff
    800029b8:	2a2080e7          	jalr	674(ra) # 80001c56 <release_list>
    return delet_the_first(number, proc->parent_cpu);
    800029bc:	4501                	li	a0,0
    800029be:	b7e1                	j	80002986 <delete_proc_from_list+0x3c>
      acquire(&proc->list_lock);
    800029c0:	01848913          	addi	s2,s1,24
    800029c4:	854a                	mv	a0,s2
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	226080e7          	jalr	550(ra) # 80000bec <acquire>
      setFirst(proc->next, number, proc->parent_cpu);
    800029ce:	4cb0                	lw	a2,88(s1)
    800029d0:	85d2                	mv	a1,s4
    800029d2:	68a8                	ld	a0,80(s1)
    800029d4:	00000097          	auipc	ra,0x0
    800029d8:	99e080e7          	jalr	-1634(ra) # 80002372 <setFirst>
      if(debug_flag==debugFlag){
    800029dc:	4791                	li	a5,4
    800029de:	02f98163          	beq	s3,a5,80002a00 <delete_proc_from_list+0xb6>
      proc->next = 0;
    800029e2:	0404b823          	sd	zero,80(s1)
      release(&proc->list_lock);
    800029e6:	854a                	mv	a0,s2
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	2be080e7          	jalr	702(ra) # 80000ca6 <release>
      release_list(number, proc->parent_cpu);
    800029f0:	4cac                	lw	a1,88(s1)
    800029f2:	8552                	mv	a0,s4
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	262080e7          	jalr	610(ra) # 80001c56 <release_list>
    return 0;
    800029fc:	4501                	li	a0,0
    800029fe:	b761                	j	80002986 <delete_proc_from_list+0x3c>
        printf("nest is %d",proc->parent_cpu);
    80002a00:	4cac                	lw	a1,88(s1)
    80002a02:	00007517          	auipc	a0,0x7
    80002a06:	a1e50513          	addi	a0,a0,-1506 # 80009420 <digits+0x3e0>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b7e080e7          	jalr	-1154(ra) # 80000588 <printf>
    80002a12:	bfc1                	j	800029e2 <delete_proc_from_list+0x98>
      printf("first is %d",first);
    80002a14:	85ca                	mv	a1,s2
    80002a16:	00007517          	auipc	a0,0x7
    80002a1a:	88a50513          	addi	a0,a0,-1910 # 800092a0 <digits+0x260>
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	b6a080e7          	jalr	-1174(ra) # 80000588 <printf>
    80002a26:	bf81                	j	80002976 <delete_proc_from_list+0x2c>

0000000080002a28 <freeproc>:
{
    80002a28:	1101                	addi	sp,sp,-32
    80002a2a:	ec06                	sd	ra,24(sp)
    80002a2c:	e822                	sd	s0,16(sp)
    80002a2e:	e426                	sd	s1,8(sp)
    80002a30:	1000                	addi	s0,sp,32
    80002a32:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002a34:	6148                	ld	a0,128(a0)
    80002a36:	c509                	beqz	a0,80002a40 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	fc0080e7          	jalr	-64(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002a40:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    80002a44:	7ca8                	ld	a0,120(s1)
    80002a46:	c511                	beqz	a0,80002a52 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002a48:	78ac                	ld	a1,112(s1)
    80002a4a:	fffff097          	auipc	ra,0xfffff
    80002a4e:	5cc080e7          	jalr	1484(ra) # 80002016 <proc_freepagetable>
  p->pagetable = 0;
    80002a52:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    80002a56:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    80002a5a:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    80002a5e:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    80002a62:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    80002a66:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    80002a6a:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80002a6e:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    80002a72:	0204a823          	sw	zero,48(s1)
  getList(zombeList, proc->parent_cpu); // get list is grabing the loock of relevnt list
    80002a76:	00010597          	auipc	a1,0x10
    80002a7a:	bc25a583          	lw	a1,-1086(a1) # 80012638 <proc+0x58>
    80002a7e:	4505                	li	a0,1
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	7f2080e7          	jalr	2034(ra) # 80002272 <getList>
  struct proc* first = getFirst(zombeList, p->parent_cpu);//aquire first proc in the list after we have loock 
    80002a88:	4cac                	lw	a1,88(s1)
    80002a8a:	4505                	li	a0,1
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	09c080e7          	jalr	156(ra) # 80001b28 <getFirst>
  delete_proc_from_list(first,p, zombeList,0 );
    80002a94:	4681                	li	a3,0
    80002a96:	4605                	li	a2,1
    80002a98:	85a6                	mv	a1,s1
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	eb0080e7          	jalr	-336(ra) # 8000294a <delete_proc_from_list>
  add_proc_to_specific_list(p, unuseList, -1,0);
    80002aa2:	4681                	li	a3,0
    80002aa4:	567d                	li	a2,-1
    80002aa6:	458d                	li	a1,3
    80002aa8:	8526                	mv	a0,s1
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	9b0080e7          	jalr	-1616(ra) # 8000245a <add_proc_to_specific_list>
}
    80002ab2:	60e2                	ld	ra,24(sp)
    80002ab4:	6442                	ld	s0,16(sp)
    80002ab6:	64a2                	ld	s1,8(sp)
    80002ab8:	6105                	addi	sp,sp,32
    80002aba:	8082                	ret

0000000080002abc <allocproc>:
{
    80002abc:	7179                	addi	sp,sp,-48
    80002abe:	f406                	sd	ra,40(sp)
    80002ac0:	f022                	sd	s0,32(sp)
    80002ac2:	ec26                	sd	s1,24(sp)
    80002ac4:	e84a                	sd	s2,16(sp)
    80002ac6:	e44e                	sd	s3,8(sp)
    80002ac8:	1800                	addi	s0,sp,48
  p = get_first(unuseList, -1);
    80002aca:	55fd                	li	a1,-1
    80002acc:	450d                	li	a0,3
    80002ace:	00000097          	auipc	ra,0x0
    80002ad2:	c30080e7          	jalr	-976(ra) # 800026fe <get_first>
    80002ad6:	84aa                	mv	s1,a0
  if(!p){
    80002ad8:	cd39                	beqz	a0,80002b36 <allocproc+0x7a>
  acquire(&p->lock);
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	112080e7          	jalr	274(ra) # 80000bec <acquire>
  p->pid = allocpid();
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	460080e7          	jalr	1120(ra) # 80001f42 <allocpid>
    80002aea:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80002aec:	4785                	li	a5,1
    80002aee:	d89c                	sw	a5,48(s1)
  p->next = 0;
    80002af0:	0404b823          	sd	zero,80(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	000080e7          	jalr	ra # 80000af4 <kalloc>
    80002afc:	892a                	mv	s2,a0
    80002afe:	e0c8                	sd	a0,128(s1)
    80002b00:	c139                	beqz	a0,80002b46 <allocproc+0x8a>
  p->pagetable = proc_pagetable(p);
    80002b02:	8526                	mv	a0,s1
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	476080e7          	jalr	1142(ra) # 80001f7a <proc_pagetable>
    80002b0c:	892a                	mv	s2,a0
    80002b0e:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    80002b10:	c539                	beqz	a0,80002b5e <allocproc+0xa2>
  memset(&p->context, 0, sizeof(p->context));
    80002b12:	07000613          	li	a2,112
    80002b16:	4581                	li	a1,0
    80002b18:	08848513          	addi	a0,s1,136
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	1d2080e7          	jalr	466(ra) # 80000cee <memset>
  p->context.ra = (uint64)forkret;
    80002b24:	fffff797          	auipc	a5,0xfffff
    80002b28:	3d878793          	addi	a5,a5,984 # 80001efc <forkret>
    80002b2c:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002b2e:	74bc                	ld	a5,104(s1)
    80002b30:	6705                	lui	a4,0x1
    80002b32:	97ba                	add	a5,a5,a4
    80002b34:	e8dc                	sd	a5,144(s1)
}
    80002b36:	8526                	mv	a0,s1
    80002b38:	70a2                	ld	ra,40(sp)
    80002b3a:	7402                	ld	s0,32(sp)
    80002b3c:	64e2                	ld	s1,24(sp)
    80002b3e:	6942                	ld	s2,16(sp)
    80002b40:	69a2                	ld	s3,8(sp)
    80002b42:	6145                	addi	sp,sp,48
    80002b44:	8082                	ret
    freeproc(p);
    80002b46:	8526                	mv	a0,s1
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	ee0080e7          	jalr	-288(ra) # 80002a28 <freeproc>
    release(&p->lock);
    80002b50:	8526                	mv	a0,s1
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	154080e7          	jalr	340(ra) # 80000ca6 <release>
    return 0;
    80002b5a:	84ca                	mv	s1,s2
    80002b5c:	bfe9                	j	80002b36 <allocproc+0x7a>
    freeproc(p);
    80002b5e:	8526                	mv	a0,s1
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	ec8080e7          	jalr	-312(ra) # 80002a28 <freeproc>
    release(&p->lock);
    80002b68:	8526                	mv	a0,s1
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	13c080e7          	jalr	316(ra) # 80000ca6 <release>
    return 0;
    80002b72:	84ca                	mv	s1,s2
    80002b74:	b7c9                	j	80002b36 <allocproc+0x7a>

0000000080002b76 <userinit>:
{
    80002b76:	1101                	addi	sp,sp,-32
    80002b78:	ec06                	sd	ra,24(sp)
    80002b7a:	e822                	sd	s0,16(sp)
    80002b7c:	e426                	sd	s1,8(sp)
    80002b7e:	1000                	addi	s0,sp,32
  if(!flag_init){
    80002b80:	00007797          	auipc	a5,0x7
    80002b84:	4c07a783          	lw	a5,1216(a5) # 8000a040 <flag_init>
    80002b88:	e795                	bnez	a5,80002bb4 <userinit+0x3e>
      c->first = 0;
    80002b8a:	0000f797          	auipc	a5,0xf
    80002b8e:	75678793          	addi	a5,a5,1878 # 800122e0 <readyLock>
    80002b92:	1007bc23          	sd	zero,280(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    80002b96:	0807b823          	sd	zero,144(a5)
      c->first = 0;
    80002b9a:	1a07b423          	sd	zero,424(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    80002b9e:	1207b023          	sd	zero,288(a5)
      c->first = 0;
    80002ba2:	2207bc23          	sd	zero,568(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    80002ba6:	1a07b823          	sd	zero,432(a5)
    flag_init = 1;
    80002baa:	4785                	li	a5,1
    80002bac:	00007717          	auipc	a4,0x7
    80002bb0:	48f72a23          	sw	a5,1172(a4) # 8000a040 <flag_init>
  p = allocproc();
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	f08080e7          	jalr	-248(ra) # 80002abc <allocproc>
    80002bbc:	84aa                	mv	s1,a0
  initproc = p;
    80002bbe:	00007797          	auipc	a5,0x7
    80002bc2:	4aa7b123          	sd	a0,1186(a5) # 8000a060 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002bc6:	03400613          	li	a2,52
    80002bca:	00007597          	auipc	a1,0x7
    80002bce:	e5658593          	addi	a1,a1,-426 # 80009a20 <initcode>
    80002bd2:	7d28                	ld	a0,120(a0)
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	7a2080e7          	jalr	1954(ra) # 80001376 <uvminit>
  p->sz = PGSIZE;
    80002bdc:	6785                	lui	a5,0x1
    80002bde:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    80002be0:	60d8                	ld	a4,128(s1)
    80002be2:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002be6:	60d8                	ld	a4,128(s1)
    80002be8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002bea:	4641                	li	a2,16
    80002bec:	00007597          	auipc	a1,0x7
    80002bf0:	84458593          	addi	a1,a1,-1980 # 80009430 <digits+0x3f0>
    80002bf4:	18048513          	addi	a0,s1,384
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	248080e7          	jalr	584(ra) # 80000e40 <safestrcpy>
  p->cwd = namei("/");
    80002c00:	00007517          	auipc	a0,0x7
    80002c04:	84050513          	addi	a0,a0,-1984 # 80009440 <digits+0x400>
    80002c08:	00002097          	auipc	ra,0x2
    80002c0c:	09a080e7          	jalr	154(ra) # 80004ca2 <namei>
    80002c10:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    80002c14:	478d                	li	a5,3
    80002c16:	d89c                	sw	a5,48(s1)
  p->parent_cpu = 0;
    80002c18:	0404ac23          	sw	zero,88(s1)
  BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,a):counter_blance++;
    80002c1c:	4585                	li	a1,1
    80002c1e:	4501                	li	a0,0
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	eb8080e7          	jalr	-328(ra) # 80001ad8 <cahnge_number_of_proc>
  cpus[p->parent_cpu].first = p;
    80002c28:	4cb8                	lw	a4,88(s1)
    80002c2a:	00371793          	slli	a5,a4,0x3
    80002c2e:	97ba                	add	a5,a5,a4
    80002c30:	0792                	slli	a5,a5,0x4
    80002c32:	0000f717          	auipc	a4,0xf
    80002c36:	6ae70713          	addi	a4,a4,1710 # 800122e0 <readyLock>
    80002c3a:	97ba                	add	a5,a5,a4
    80002c3c:	1097bc23          	sd	s1,280(a5) # 1118 <_entry-0x7fffeee8>
  release(&p->lock);
    80002c40:	8526                	mv	a0,s1
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	064080e7          	jalr	100(ra) # 80000ca6 <release>
}
    80002c4a:	60e2                	ld	ra,24(sp)
    80002c4c:	6442                	ld	s0,16(sp)
    80002c4e:	64a2                	ld	s1,8(sp)
    80002c50:	6105                	addi	sp,sp,32
    80002c52:	8082                	ret

0000000080002c54 <fork>:
{
    80002c54:	7179                	addi	sp,sp,-48
    80002c56:	f406                	sd	ra,40(sp)
    80002c58:	f022                	sd	s0,32(sp)
    80002c5a:	ec26                	sd	s1,24(sp)
    80002c5c:	e84a                	sd	s2,16(sp)
    80002c5e:	e44e                	sd	s3,8(sp)
    80002c60:	e052                	sd	s4,0(sp)
    80002c62:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	23e080e7          	jalr	574(ra) # 80001ea2 <myproc>
    80002c6c:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002c6e:	00000097          	auipc	ra,0x0
    80002c72:	e4e080e7          	jalr	-434(ra) # 80002abc <allocproc>
    80002c76:	12050c63          	beqz	a0,80002dae <fork+0x15a>
    80002c7a:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002c7c:	0709b603          	ld	a2,112(s3)
    80002c80:	7d2c                	ld	a1,120(a0)
    80002c82:	0789b503          	ld	a0,120(s3)
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	8f6080e7          	jalr	-1802(ra) # 8000157c <uvmcopy>
    80002c8e:	04054663          	bltz	a0,80002cda <fork+0x86>
  np->sz = p->sz;
    80002c92:	0709b783          	ld	a5,112(s3)
    80002c96:	06f93823          	sd	a5,112(s2)
  *(np->trapframe) = *(p->trapframe);
    80002c9a:	0809b683          	ld	a3,128(s3)
    80002c9e:	87b6                	mv	a5,a3
    80002ca0:	08093703          	ld	a4,128(s2)
    80002ca4:	12068693          	addi	a3,a3,288
    80002ca8:	0007b803          	ld	a6,0(a5)
    80002cac:	6788                	ld	a0,8(a5)
    80002cae:	6b8c                	ld	a1,16(a5)
    80002cb0:	6f90                	ld	a2,24(a5)
    80002cb2:	01073023          	sd	a6,0(a4)
    80002cb6:	e708                	sd	a0,8(a4)
    80002cb8:	eb0c                	sd	a1,16(a4)
    80002cba:	ef10                	sd	a2,24(a4)
    80002cbc:	02078793          	addi	a5,a5,32
    80002cc0:	02070713          	addi	a4,a4,32
    80002cc4:	fed792e3          	bne	a5,a3,80002ca8 <fork+0x54>
  np->trapframe->a0 = 0;
    80002cc8:	08093783          	ld	a5,128(s2)
    80002ccc:	0607b823          	sd	zero,112(a5)
    80002cd0:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80002cd4:	17800a13          	li	s4,376
    80002cd8:	a03d                	j	80002d06 <fork+0xb2>
    freeproc(np);
    80002cda:	854a                	mv	a0,s2
    80002cdc:	00000097          	auipc	ra,0x0
    80002ce0:	d4c080e7          	jalr	-692(ra) # 80002a28 <freeproc>
    release(&np->lock);
    80002ce4:	854a                	mv	a0,s2
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	fc0080e7          	jalr	-64(ra) # 80000ca6 <release>
    return -1;
    80002cee:	5a7d                	li	s4,-1
    80002cf0:	a075                	j	80002d9c <fork+0x148>
      np->ofile[i] = filedup(p->ofile[i]);
    80002cf2:	00002097          	auipc	ra,0x2
    80002cf6:	646080e7          	jalr	1606(ra) # 80005338 <filedup>
    80002cfa:	009907b3          	add	a5,s2,s1
    80002cfe:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002d00:	04a1                	addi	s1,s1,8
    80002d02:	01448763          	beq	s1,s4,80002d10 <fork+0xbc>
    if(p->ofile[i])
    80002d06:	009987b3          	add	a5,s3,s1
    80002d0a:	6388                	ld	a0,0(a5)
    80002d0c:	f17d                	bnez	a0,80002cf2 <fork+0x9e>
    80002d0e:	bfcd                	j	80002d00 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002d10:	1789b503          	ld	a0,376(s3)
    80002d14:	00001097          	auipc	ra,0x1
    80002d18:	79a080e7          	jalr	1946(ra) # 800044ae <idup>
    80002d1c:	16a93c23          	sd	a0,376(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002d20:	4641                	li	a2,16
    80002d22:	18098593          	addi	a1,s3,384
    80002d26:	18090513          	addi	a0,s2,384
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	116080e7          	jalr	278(ra) # 80000e40 <safestrcpy>
  pid = np->pid;
    80002d32:	04892a03          	lw	s4,72(s2)
  release(&np->lock);
    80002d36:	854a                	mv	a0,s2
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	f6e080e7          	jalr	-146(ra) # 80000ca6 <release>
  acquire(&wait_lock);
    80002d40:	00010497          	auipc	s1,0x10
    80002d44:	88848493          	addi	s1,s1,-1912 # 800125c8 <wait_lock>
    80002d48:	8526                	mv	a0,s1
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	ea2080e7          	jalr	-350(ra) # 80000bec <acquire>
  np->parent = p;
    80002d52:	07393023          	sd	s3,96(s2)
  release(&wait_lock);
    80002d56:	8526                	mv	a0,s1
    80002d58:	ffffe097          	auipc	ra,0xffffe
    80002d5c:	f4e080e7          	jalr	-178(ra) # 80000ca6 <release>
  acquire(&np->lock);
    80002d60:	854a                	mv	a0,s2
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	e8a080e7          	jalr	-374(ra) # 80000bec <acquire>
  np->state = RUNNABLE;
    80002d6a:	478d                	li	a5,3
    80002d6c:	02f92823          	sw	a5,48(s2)
  np->parent_cpu = parent_cpu;
    80002d70:	04092c23          	sw	zero,88(s2)
  add_proc_to_specific_list(np, readyList, parent_cpu,0);
    80002d74:	4681                	li	a3,0
    80002d76:	4601                	li	a2,0
    80002d78:	4581                	li	a1,0
    80002d7a:	854a                	mv	a0,s2
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	6de080e7          	jalr	1758(ra) # 8000245a <add_proc_to_specific_list>
  BLNCFLG ?cahnge_number_of_proc(np->parent_cpu,a):counter_blance++;
    80002d84:	4585                	li	a1,1
    80002d86:	05892503          	lw	a0,88(s2)
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	d4e080e7          	jalr	-690(ra) # 80001ad8 <cahnge_number_of_proc>
  release(&np->lock);
    80002d92:	854a                	mv	a0,s2
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	f12080e7          	jalr	-238(ra) # 80000ca6 <release>
}
    80002d9c:	8552                	mv	a0,s4
    80002d9e:	70a2                	ld	ra,40(sp)
    80002da0:	7402                	ld	s0,32(sp)
    80002da2:	64e2                	ld	s1,24(sp)
    80002da4:	6942                	ld	s2,16(sp)
    80002da6:	69a2                	ld	s3,8(sp)
    80002da8:	6a02                	ld	s4,0(sp)
    80002daa:	6145                	addi	sp,sp,48
    80002dac:	8082                	ret
    return -1;
    80002dae:	5a7d                	li	s4,-1
    80002db0:	b7f5                	j	80002d9c <fork+0x148>

0000000080002db2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002db2:	7179                	addi	sp,sp,-48
    80002db4:	f406                	sd	ra,40(sp)
    80002db6:	f022                	sd	s0,32(sp)
    80002db8:	ec26                	sd	s1,24(sp)
    80002dba:	e84a                	sd	s2,16(sp)
    80002dbc:	e44e                	sd	s3,8(sp)
    80002dbe:	1800                	addi	s0,sp,48
    80002dc0:	89aa                	mv	s3,a0
    80002dc2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	0de080e7          	jalr	222(ra) # 80001ea2 <myproc>
    80002dcc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002dce:	ffffe097          	auipc	ra,0xffffe
    80002dd2:	e1e080e7          	jalr	-482(ra) # 80000bec <acquire>
  release(lk);
    80002dd6:	854a                	mv	a0,s2
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	ece080e7          	jalr	-306(ra) # 80000ca6 <release>

  // Go to sleep.
  p->chan = chan;
    80002de0:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    80002de4:	4789                	li	a5,2
    80002de6:	d89c                	sw	a5,48(s1)
  //--------------------------------------------------------------------
  int b=-1;
  BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,b):counter_blance++;
    80002de8:	55fd                	li	a1,-1
    80002dea:	4ca8                	lw	a0,88(s1)
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	cec080e7          	jalr	-788(ra) # 80001ad8 <cahnge_number_of_proc>
  add_proc_to_specific_list(p, sleepLeast,-1,0);
    80002df4:	4681                	li	a3,0
    80002df6:	567d                	li	a2,-1
    80002df8:	4589                	li	a1,2
    80002dfa:	8526                	mv	a0,s1
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	65e080e7          	jalr	1630(ra) # 8000245a <add_proc_to_specific_list>
  //--------------------------------------------------------------------

  sched();
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	2d8080e7          	jalr	728(ra) # 800020dc <sched>

  // Tidy up.
  p->chan = 0;
    80002e0c:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002e10:	8526                	mv	a0,s1
    80002e12:	ffffe097          	auipc	ra,0xffffe
    80002e16:	e94080e7          	jalr	-364(ra) # 80000ca6 <release>
  acquire(lk);
    80002e1a:	854a                	mv	a0,s2
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	dd0080e7          	jalr	-560(ra) # 80000bec <acquire>

}
    80002e24:	70a2                	ld	ra,40(sp)
    80002e26:	7402                	ld	s0,32(sp)
    80002e28:	64e2                	ld	s1,24(sp)
    80002e2a:	6942                	ld	s2,16(sp)
    80002e2c:	69a2                	ld	s3,8(sp)
    80002e2e:	6145                	addi	sp,sp,48
    80002e30:	8082                	ret

0000000080002e32 <wait>:
{
    80002e32:	715d                	addi	sp,sp,-80
    80002e34:	e486                	sd	ra,72(sp)
    80002e36:	e0a2                	sd	s0,64(sp)
    80002e38:	fc26                	sd	s1,56(sp)
    80002e3a:	f84a                	sd	s2,48(sp)
    80002e3c:	f44e                	sd	s3,40(sp)
    80002e3e:	f052                	sd	s4,32(sp)
    80002e40:	ec56                	sd	s5,24(sp)
    80002e42:	e85a                	sd	s6,16(sp)
    80002e44:	e45e                	sd	s7,8(sp)
    80002e46:	e062                	sd	s8,0(sp)
    80002e48:	0880                	addi	s0,sp,80
    80002e4a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	056080e7          	jalr	86(ra) # 80001ea2 <myproc>
    80002e54:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002e56:	0000f517          	auipc	a0,0xf
    80002e5a:	77250513          	addi	a0,a0,1906 # 800125c8 <wait_lock>
    80002e5e:	ffffe097          	auipc	ra,0xffffe
    80002e62:	d8e080e7          	jalr	-626(ra) # 80000bec <acquire>
    havekids = 0;
    80002e66:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002e68:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002e6a:	00016997          	auipc	s3,0x16
    80002e6e:	b7698993          	addi	s3,s3,-1162 # 800189e0 <tickslock>
        havekids = 1;
    80002e72:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002e74:	0000fc17          	auipc	s8,0xf
    80002e78:	754c0c13          	addi	s8,s8,1876 # 800125c8 <wait_lock>
    havekids = 0;
    80002e7c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002e7e:	0000f497          	auipc	s1,0xf
    80002e82:	76248493          	addi	s1,s1,1890 # 800125e0 <proc>
    80002e86:	a0bd                	j	80002ef4 <wait+0xc2>
          pid = np->pid;
    80002e88:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002e8c:	000b0e63          	beqz	s6,80002ea8 <wait+0x76>
    80002e90:	4691                	li	a3,4
    80002e92:	04448613          	addi	a2,s1,68
    80002e96:	85da                	mv	a1,s6
    80002e98:	07893503          	ld	a0,120(s2)
    80002e9c:	ffffe097          	auipc	ra,0xffffe
    80002ea0:	7e4080e7          	jalr	2020(ra) # 80001680 <copyout>
    80002ea4:	02054563          	bltz	a0,80002ece <wait+0x9c>
          freeproc(np);
    80002ea8:	8526                	mv	a0,s1
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	b7e080e7          	jalr	-1154(ra) # 80002a28 <freeproc>
          release(&np->lock);
    80002eb2:	8526                	mv	a0,s1
    80002eb4:	ffffe097          	auipc	ra,0xffffe
    80002eb8:	df2080e7          	jalr	-526(ra) # 80000ca6 <release>
          release(&wait_lock);
    80002ebc:	0000f517          	auipc	a0,0xf
    80002ec0:	70c50513          	addi	a0,a0,1804 # 800125c8 <wait_lock>
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	de2080e7          	jalr	-542(ra) # 80000ca6 <release>
          return pid;
    80002ecc:	a09d                	j	80002f32 <wait+0x100>
            release(&np->lock);
    80002ece:	8526                	mv	a0,s1
    80002ed0:	ffffe097          	auipc	ra,0xffffe
    80002ed4:	dd6080e7          	jalr	-554(ra) # 80000ca6 <release>
            release(&wait_lock);
    80002ed8:	0000f517          	auipc	a0,0xf
    80002edc:	6f050513          	addi	a0,a0,1776 # 800125c8 <wait_lock>
    80002ee0:	ffffe097          	auipc	ra,0xffffe
    80002ee4:	dc6080e7          	jalr	-570(ra) # 80000ca6 <release>
            return -1;
    80002ee8:	59fd                	li	s3,-1
    80002eea:	a0a1                	j	80002f32 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002eec:	19048493          	addi	s1,s1,400
    80002ef0:	03348463          	beq	s1,s3,80002f18 <wait+0xe6>
      if(np->parent == p){
    80002ef4:	70bc                	ld	a5,96(s1)
    80002ef6:	ff279be3          	bne	a5,s2,80002eec <wait+0xba>
        acquire(&np->lock);
    80002efa:	8526                	mv	a0,s1
    80002efc:	ffffe097          	auipc	ra,0xffffe
    80002f00:	cf0080e7          	jalr	-784(ra) # 80000bec <acquire>
        if(np->state == ZOMBIE){
    80002f04:	589c                	lw	a5,48(s1)
    80002f06:	f94781e3          	beq	a5,s4,80002e88 <wait+0x56>
        release(&np->lock);
    80002f0a:	8526                	mv	a0,s1
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	d9a080e7          	jalr	-614(ra) # 80000ca6 <release>
        havekids = 1;
    80002f14:	8756                	mv	a4,s5
    80002f16:	bfd9                	j	80002eec <wait+0xba>
    if(!havekids || p->killed){
    80002f18:	c701                	beqz	a4,80002f20 <wait+0xee>
    80002f1a:	04092783          	lw	a5,64(s2)
    80002f1e:	c79d                	beqz	a5,80002f4c <wait+0x11a>
      release(&wait_lock);
    80002f20:	0000f517          	auipc	a0,0xf
    80002f24:	6a850513          	addi	a0,a0,1704 # 800125c8 <wait_lock>
    80002f28:	ffffe097          	auipc	ra,0xffffe
    80002f2c:	d7e080e7          	jalr	-642(ra) # 80000ca6 <release>
      return -1;
    80002f30:	59fd                	li	s3,-1
}
    80002f32:	854e                	mv	a0,s3
    80002f34:	60a6                	ld	ra,72(sp)
    80002f36:	6406                	ld	s0,64(sp)
    80002f38:	74e2                	ld	s1,56(sp)
    80002f3a:	7942                	ld	s2,48(sp)
    80002f3c:	79a2                	ld	s3,40(sp)
    80002f3e:	7a02                	ld	s4,32(sp)
    80002f40:	6ae2                	ld	s5,24(sp)
    80002f42:	6b42                	ld	s6,16(sp)
    80002f44:	6ba2                	ld	s7,8(sp)
    80002f46:	6c02                	ld	s8,0(sp)
    80002f48:	6161                	addi	sp,sp,80
    80002f4a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002f4c:	85e2                	mv	a1,s8
    80002f4e:	854a                	mv	a0,s2
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	e62080e7          	jalr	-414(ra) # 80002db2 <sleep>
    havekids = 0;
    80002f58:	b715                	j	80002e7c <wait+0x4a>

0000000080002f5a <wakeup>:
// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
//--------------------------------------------------------------------
void
wakeup(void *chan)
{
    80002f5a:	711d                	addi	sp,sp,-96
    80002f5c:	ec86                	sd	ra,88(sp)
    80002f5e:	e8a2                	sd	s0,80(sp)
    80002f60:	e4a6                	sd	s1,72(sp)
    80002f62:	e0ca                	sd	s2,64(sp)
    80002f64:	fc4e                	sd	s3,56(sp)
    80002f66:	f852                	sd	s4,48(sp)
    80002f68:	f456                	sd	s5,40(sp)
    80002f6a:	f05a                	sd	s6,32(sp)
    80002f6c:	ec5e                	sd	s7,24(sp)
    80002f6e:	e862                	sd	s8,16(sp)
    80002f70:	e466                	sd	s9,8(sp)
    80002f72:	1080                	addi	s0,sp,96
    80002f74:	8aaa                	mv	s5,a0
  int released_list = 0;
  struct proc *p;
  struct proc* prev = 0;
  struct proc* tmp;
  getList(sleepLeast, -1);//get lock for list
    80002f76:	55fd                	li	a1,-1
    80002f78:	4509                	li	a0,2
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	2f8080e7          	jalr	760(ra) # 80002272 <getList>
  p = getFirst(sleepLeast, -1);//get list 
    80002f82:	55fd                	li	a1,-1
    80002f84:	4509                	li	a0,2
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	ba2080e7          	jalr	-1118(ra) # 80001b28 <getFirst>
    80002f8e:	84aa                	mv	s1,a0
  while(p){
    80002f90:	14050163          	beqz	a0,800030d2 <wakeup+0x178>
  struct proc* prev = 0;
    80002f94:	4a01                	li	s4,0
  int released_list = 0;
    80002f96:	4b81                	li	s7,0
    } 
    else{
      //we are not on the chan
      if(p == getFirst(sleepLeast, -1)){
        release_list(sleepLeast,-1);
        released_list = 1;
    80002f98:	4b05                	li	s6,1
        p->state = RUNNABLE;
    80002f9a:	4c0d                	li	s8,3
    80002f9c:	a0e9                	j	80003066 <wakeup+0x10c>
      if(p == getFirst(sleepLeast, -1)){
    80002f9e:	55fd                	li	a1,-1
    80002fa0:	4509                	li	a0,2
    80002fa2:	fffff097          	auipc	ra,0xfffff
    80002fa6:	b86080e7          	jalr	-1146(ra) # 80001b28 <getFirst>
    80002faa:	04a48663          	beq	s1,a0,80002ff6 <wakeup+0x9c>
        prev->next = p->next;
    80002fae:	68bc                	ld	a5,80(s1)
    80002fb0:	04fa3823          	sd	a5,80(s4)
        p->next = 0;
    80002fb4:	0404b823          	sd	zero,80(s1)
        p->state = RUNNABLE;
    80002fb8:	0384a823          	sw	s8,48(s1)
        p->parent_cpu = parent_cpu;
    80002fbc:	0404ac23          	sw	zero,88(s1)
        BLNCFLG ?cahnge_number_of_proc(parent_cpu,a):counter_blance++;
    80002fc0:	85da                	mv	a1,s6
    80002fc2:	4501                	li	a0,0
    80002fc4:	fffff097          	auipc	ra,0xfffff
    80002fc8:	b14080e7          	jalr	-1260(ra) # 80001ad8 <cahnge_number_of_proc>
        add_proc_to_specific_list(p, readyList, parent_cpu,0);
    80002fcc:	4681                	li	a3,0
    80002fce:	4601                	li	a2,0
    80002fd0:	4581                	li	a1,0
    80002fd2:	8526                	mv	a0,s1
    80002fd4:	fffff097          	auipc	ra,0xfffff
    80002fd8:	486080e7          	jalr	1158(ra) # 8000245a <add_proc_to_specific_list>
        release(&p->list_lock);
    80002fdc:	854a                	mv	a0,s2
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	cc8080e7          	jalr	-824(ra) # 80000ca6 <release>
        release(&p->lock);
    80002fe6:	8526                	mv	a0,s1
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	cbe080e7          	jalr	-834(ra) # 80000ca6 <release>
        p = prev->next;
    80002ff0:	050a3483          	ld	s1,80(s4)
    80002ff4:	a885                	j	80003064 <wakeup+0x10a>
        setFirst(p->next, sleepLeast, -1);
    80002ff6:	567d                	li	a2,-1
    80002ff8:	4589                	li	a1,2
    80002ffa:	68a8                	ld	a0,80(s1)
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	376080e7          	jalr	886(ra) # 80002372 <setFirst>
        p = p->next;
    80003004:	0504bc83          	ld	s9,80(s1)
        tmp->next = 0;
    80003008:	0404b823          	sd	zero,80(s1)
        tmp->state = RUNNABLE;
    8000300c:	0384a823          	sw	s8,48(s1)
        tmp->parent_cpu = parent_cpu;
    80003010:	0404ac23          	sw	zero,88(s1)
        BLNCFLG ?cahnge_number_of_proc(parent_cpu,a):counter_blance++;
    80003014:	85da                	mv	a1,s6
    80003016:	4501                	li	a0,0
    80003018:	fffff097          	auipc	ra,0xfffff
    8000301c:	ac0080e7          	jalr	-1344(ra) # 80001ad8 <cahnge_number_of_proc>
        add_proc_to_specific_list(tmp, readyList, parent_cpu,0);
    80003020:	4681                	li	a3,0
    80003022:	4601                	li	a2,0
    80003024:	4581                	li	a1,0
    80003026:	8526                	mv	a0,s1
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	432080e7          	jalr	1074(ra) # 8000245a <add_proc_to_specific_list>
        release(&tmp->list_lock);
    80003030:	854a                	mv	a0,s2
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	c74080e7          	jalr	-908(ra) # 80000ca6 <release>
        release(&tmp->lock);
    8000303a:	8526                	mv	a0,s1
    8000303c:	ffffe097          	auipc	ra,0xffffe
    80003040:	c6a080e7          	jalr	-918(ra) # 80000ca6 <release>
        p = p->next;
    80003044:	84e6                	mv	s1,s9
    80003046:	a839                	j	80003064 <wakeup+0x10a>
        release_list(sleepLeast,-1);
    80003048:	55fd                	li	a1,-1
    8000304a:	4509                	li	a0,2
    8000304c:	fffff097          	auipc	ra,0xfffff
    80003050:	c0a080e7          	jalr	-1014(ra) # 80001c56 <release_list>
        released_list = 1;
    80003054:	8bda                	mv	s7,s6
      }
      else{
        release(&prev->list_lock);
      }
      release(&p->lock);  //because we dont need to change his fields
    80003056:	854e                	mv	a0,s3
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	c4e080e7          	jalr	-946(ra) # 80000ca6 <release>
      prev = p;
      p = p->next;
    80003060:	8a26                	mv	s4,s1
    80003062:	68a4                	ld	s1,80(s1)
  while(p){
    80003064:	c0a1                	beqz	s1,800030a4 <wakeup+0x14a>
    acquire(&p->lock);
    80003066:	89a6                	mv	s3,s1
    80003068:	8526                	mv	a0,s1
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	b82080e7          	jalr	-1150(ra) # 80000bec <acquire>
    acquire(&p->list_lock);
    80003072:	01848913          	addi	s2,s1,24
    80003076:	854a                	mv	a0,s2
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	b74080e7          	jalr	-1164(ra) # 80000bec <acquire>
    if(p->chan == chan){
    80003080:	7c9c                	ld	a5,56(s1)
    80003082:	f1578ee3          	beq	a5,s5,80002f9e <wakeup+0x44>
      if(p == getFirst(sleepLeast, -1)){
    80003086:	55fd                	li	a1,-1
    80003088:	4509                	li	a0,2
    8000308a:	fffff097          	auipc	ra,0xfffff
    8000308e:	a9e080e7          	jalr	-1378(ra) # 80001b28 <getFirst>
    80003092:	faa48be3          	beq	s1,a0,80003048 <wakeup+0xee>
        release(&prev->list_lock);
    80003096:	018a0513          	addi	a0,s4,24
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	c0c080e7          	jalr	-1012(ra) # 80000ca6 <release>
    800030a2:	bf55                	j	80003056 <wakeup+0xfc>
    }
  }
  if(!released_list){
    800030a4:	020b8863          	beqz	s7,800030d4 <wakeup+0x17a>
    release_list(sleepLeast, -1);
  }
  if(prev){
    800030a8:	000a0863          	beqz	s4,800030b8 <wakeup+0x15e>
    release(&prev->list_lock);
    800030ac:	018a0513          	addi	a0,s4,24
    800030b0:	ffffe097          	auipc	ra,0xffffe
    800030b4:	bf6080e7          	jalr	-1034(ra) # 80000ca6 <release>
  }
}
    800030b8:	60e6                	ld	ra,88(sp)
    800030ba:	6446                	ld	s0,80(sp)
    800030bc:	64a6                	ld	s1,72(sp)
    800030be:	6906                	ld	s2,64(sp)
    800030c0:	79e2                	ld	s3,56(sp)
    800030c2:	7a42                	ld	s4,48(sp)
    800030c4:	7aa2                	ld	s5,40(sp)
    800030c6:	7b02                	ld	s6,32(sp)
    800030c8:	6be2                	ld	s7,24(sp)
    800030ca:	6c42                	ld	s8,16(sp)
    800030cc:	6ca2                	ld	s9,8(sp)
    800030ce:	6125                	addi	sp,sp,96
    800030d0:	8082                	ret
  struct proc* prev = 0;
    800030d2:	8a2a                	mv	s4,a0
    release_list(sleepLeast, -1);
    800030d4:	55fd                	li	a1,-1
    800030d6:	4509                	li	a0,2
    800030d8:	fffff097          	auipc	ra,0xfffff
    800030dc:	b7e080e7          	jalr	-1154(ra) # 80001c56 <release_list>
    800030e0:	b7e1                	j	800030a8 <wakeup+0x14e>

00000000800030e2 <reparent>:
{
    800030e2:	7179                	addi	sp,sp,-48
    800030e4:	f406                	sd	ra,40(sp)
    800030e6:	f022                	sd	s0,32(sp)
    800030e8:	ec26                	sd	s1,24(sp)
    800030ea:	e84a                	sd	s2,16(sp)
    800030ec:	e44e                	sd	s3,8(sp)
    800030ee:	e052                	sd	s4,0(sp)
    800030f0:	1800                	addi	s0,sp,48
    800030f2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800030f4:	0000f497          	auipc	s1,0xf
    800030f8:	4ec48493          	addi	s1,s1,1260 # 800125e0 <proc>
      pp->parent = initproc;
    800030fc:	00007a17          	auipc	s4,0x7
    80003100:	f64a0a13          	addi	s4,s4,-156 # 8000a060 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80003104:	00016997          	auipc	s3,0x16
    80003108:	8dc98993          	addi	s3,s3,-1828 # 800189e0 <tickslock>
    8000310c:	a029                	j	80003116 <reparent+0x34>
    8000310e:	19048493          	addi	s1,s1,400
    80003112:	01348d63          	beq	s1,s3,8000312c <reparent+0x4a>
    if(pp->parent == p){
    80003116:	70bc                	ld	a5,96(s1)
    80003118:	ff279be3          	bne	a5,s2,8000310e <reparent+0x2c>
      pp->parent = initproc;
    8000311c:	000a3503          	ld	a0,0(s4)
    80003120:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80003122:	00000097          	auipc	ra,0x0
    80003126:	e38080e7          	jalr	-456(ra) # 80002f5a <wakeup>
    8000312a:	b7d5                	j	8000310e <reparent+0x2c>
}
    8000312c:	70a2                	ld	ra,40(sp)
    8000312e:	7402                	ld	s0,32(sp)
    80003130:	64e2                	ld	s1,24(sp)
    80003132:	6942                	ld	s2,16(sp)
    80003134:	69a2                	ld	s3,8(sp)
    80003136:	6a02                	ld	s4,0(sp)
    80003138:	6145                	addi	sp,sp,48
    8000313a:	8082                	ret

000000008000313c <exit>:
{
    8000313c:	7179                	addi	sp,sp,-48
    8000313e:	f406                	sd	ra,40(sp)
    80003140:	f022                	sd	s0,32(sp)
    80003142:	ec26                	sd	s1,24(sp)
    80003144:	e84a                	sd	s2,16(sp)
    80003146:	e44e                	sd	s3,8(sp)
    80003148:	e052                	sd	s4,0(sp)
    8000314a:	1800                	addi	s0,sp,48
    8000314c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000314e:	fffff097          	auipc	ra,0xfffff
    80003152:	d54080e7          	jalr	-684(ra) # 80001ea2 <myproc>
    80003156:	89aa                	mv	s3,a0
  if(p == initproc)
    80003158:	00007797          	auipc	a5,0x7
    8000315c:	f087b783          	ld	a5,-248(a5) # 8000a060 <initproc>
    80003160:	0f850493          	addi	s1,a0,248
    80003164:	17850913          	addi	s2,a0,376
    80003168:	02a79363          	bne	a5,a0,8000318e <exit+0x52>
    panic("init exiting");
    8000316c:	00006517          	auipc	a0,0x6
    80003170:	2dc50513          	addi	a0,a0,732 # 80009448 <digits+0x408>
    80003174:	ffffd097          	auipc	ra,0xffffd
    80003178:	3ca080e7          	jalr	970(ra) # 8000053e <panic>
      fileclose(f);
    8000317c:	00002097          	auipc	ra,0x2
    80003180:	20e080e7          	jalr	526(ra) # 8000538a <fileclose>
      p->ofile[fd] = 0;
    80003184:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80003188:	04a1                	addi	s1,s1,8
    8000318a:	01248563          	beq	s1,s2,80003194 <exit+0x58>
    if(p->ofile[fd]){
    8000318e:	6088                	ld	a0,0(s1)
    80003190:	f575                	bnez	a0,8000317c <exit+0x40>
    80003192:	bfdd                	j	80003188 <exit+0x4c>
  begin_op();
    80003194:	00002097          	auipc	ra,0x2
    80003198:	d2a080e7          	jalr	-726(ra) # 80004ebe <begin_op>
  iput(p->cwd);
    8000319c:	1789b503          	ld	a0,376(s3)
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	506080e7          	jalr	1286(ra) # 800046a6 <iput>
  end_op();
    800031a8:	00002097          	auipc	ra,0x2
    800031ac:	d96080e7          	jalr	-618(ra) # 80004f3e <end_op>
  p->cwd = 0;
    800031b0:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    800031b4:	0000f497          	auipc	s1,0xf
    800031b8:	41448493          	addi	s1,s1,1044 # 800125c8 <wait_lock>
    800031bc:	8526                	mv	a0,s1
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	a2e080e7          	jalr	-1490(ra) # 80000bec <acquire>
  reparent(p);
    800031c6:	854e                	mv	a0,s3
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	f1a080e7          	jalr	-230(ra) # 800030e2 <reparent>
  wakeup(p->parent);
    800031d0:	0609b503          	ld	a0,96(s3)
    800031d4:	00000097          	auipc	ra,0x0
    800031d8:	d86080e7          	jalr	-634(ra) # 80002f5a <wakeup>
  acquire(&p->lock);
    800031dc:	854e                	mv	a0,s3
    800031de:	ffffe097          	auipc	ra,0xffffe
    800031e2:	a0e080e7          	jalr	-1522(ra) # 80000bec <acquire>
  p->xstate = status;
    800031e6:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    800031ea:	4795                	li	a5,5
    800031ec:	02f9a823          	sw	a5,48(s3)
  BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,b):counter_blance++;
    800031f0:	55fd                	li	a1,-1
    800031f2:	0589a503          	lw	a0,88(s3)
    800031f6:	fffff097          	auipc	ra,0xfffff
    800031fa:	8e2080e7          	jalr	-1822(ra) # 80001ad8 <cahnge_number_of_proc>
  add_proc_to_specific_list(p, zombeList, -1,0);
    800031fe:	4681                	li	a3,0
    80003200:	567d                	li	a2,-1
    80003202:	4585                	li	a1,1
    80003204:	854e                	mv	a0,s3
    80003206:	fffff097          	auipc	ra,0xfffff
    8000320a:	254080e7          	jalr	596(ra) # 8000245a <add_proc_to_specific_list>
  release(&wait_lock);
    8000320e:	8526                	mv	a0,s1
    80003210:	ffffe097          	auipc	ra,0xffffe
    80003214:	a96080e7          	jalr	-1386(ra) # 80000ca6 <release>
  sched();
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	ec4080e7          	jalr	-316(ra) # 800020dc <sched>
  panic("zombie exit");
    80003220:	00006517          	auipc	a0,0x6
    80003224:	23850513          	addi	a0,a0,568 # 80009458 <digits+0x418>
    80003228:	ffffd097          	auipc	ra,0xffffd
    8000322c:	316080e7          	jalr	790(ra) # 8000053e <panic>

0000000080003230 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80003230:	7179                	addi	sp,sp,-48
    80003232:	f406                	sd	ra,40(sp)
    80003234:	f022                	sd	s0,32(sp)
    80003236:	ec26                	sd	s1,24(sp)
    80003238:	e84a                	sd	s2,16(sp)
    8000323a:	e44e                	sd	s3,8(sp)
    8000323c:	1800                	addi	s0,sp,48
    8000323e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80003240:	0000f497          	auipc	s1,0xf
    80003244:	3a048493          	addi	s1,s1,928 # 800125e0 <proc>
    80003248:	00015997          	auipc	s3,0x15
    8000324c:	79898993          	addi	s3,s3,1944 # 800189e0 <tickslock>
    acquire(&p->lock);
    80003250:	8526                	mv	a0,s1
    80003252:	ffffe097          	auipc	ra,0xffffe
    80003256:	99a080e7          	jalr	-1638(ra) # 80000bec <acquire>
    if(p->pid == pid){
    8000325a:	44bc                	lw	a5,72(s1)
    8000325c:	01278d63          	beq	a5,s2,80003276 <kill+0x46>
        BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,a):counter_blance++;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80003260:	8526                	mv	a0,s1
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	a44080e7          	jalr	-1468(ra) # 80000ca6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000326a:	19048493          	addi	s1,s1,400
    8000326e:	ff3491e3          	bne	s1,s3,80003250 <kill+0x20>
  }
  return -1;
    80003272:	557d                	li	a0,-1
    80003274:	a829                	j	8000328e <kill+0x5e>
      p->killed = 1;
    80003276:	4785                	li	a5,1
    80003278:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    8000327a:	5898                	lw	a4,48(s1)
    8000327c:	4789                	li	a5,2
    8000327e:	00f70f63          	beq	a4,a5,8000329c <kill+0x6c>
      release(&p->lock);
    80003282:	8526                	mv	a0,s1
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	a22080e7          	jalr	-1502(ra) # 80000ca6 <release>
      return 0;
    8000328c:	4501                	li	a0,0
}
    8000328e:	70a2                	ld	ra,40(sp)
    80003290:	7402                	ld	s0,32(sp)
    80003292:	64e2                	ld	s1,24(sp)
    80003294:	6942                	ld	s2,16(sp)
    80003296:	69a2                	ld	s3,8(sp)
    80003298:	6145                	addi	sp,sp,48
    8000329a:	8082                	ret
        p->state = RUNNABLE;
    8000329c:	478d                	li	a5,3
    8000329e:	d89c                	sw	a5,48(s1)
        getList(sleepLeast, p->parent_cpu); // get list is grabing the loock of relevnt list
    800032a0:	4cac                	lw	a1,88(s1)
    800032a2:	4509                	li	a0,2
    800032a4:	fffff097          	auipc	ra,0xfffff
    800032a8:	fce080e7          	jalr	-50(ra) # 80002272 <getList>
        struct proc* first = getFirst(sleepLeast, p->parent_cpu);//aquire first proc in the list after we have loock 
    800032ac:	4cac                	lw	a1,88(s1)
    800032ae:	4509                	li	a0,2
    800032b0:	fffff097          	auipc	ra,0xfffff
    800032b4:	878080e7          	jalr	-1928(ra) # 80001b28 <getFirst>
        delete_proc_from_list(first,p, sleepLeast,0);
    800032b8:	4681                	li	a3,0
    800032ba:	4609                	li	a2,2
    800032bc:	85a6                	mv	a1,s1
    800032be:	fffff097          	auipc	ra,0xfffff
    800032c2:	68c080e7          	jalr	1676(ra) # 8000294a <delete_proc_from_list>
        add_proc_to_specific_list(p, readyList, p->parent_cpu,0);
    800032c6:	4681                	li	a3,0
    800032c8:	4cb0                	lw	a2,88(s1)
    800032ca:	4581                	li	a1,0
    800032cc:	8526                	mv	a0,s1
    800032ce:	fffff097          	auipc	ra,0xfffff
    800032d2:	18c080e7          	jalr	396(ra) # 8000245a <add_proc_to_specific_list>
        BLNCFLG ?cahnge_number_of_proc(p->parent_cpu,a):counter_blance++;
    800032d6:	4585                	li	a1,1
    800032d8:	4ca8                	lw	a0,88(s1)
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	7fe080e7          	jalr	2046(ra) # 80001ad8 <cahnge_number_of_proc>
    800032e2:	b745                	j	80003282 <kill+0x52>

00000000800032e4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800032e4:	7179                	addi	sp,sp,-48
    800032e6:	f406                	sd	ra,40(sp)
    800032e8:	f022                	sd	s0,32(sp)
    800032ea:	ec26                	sd	s1,24(sp)
    800032ec:	e84a                	sd	s2,16(sp)
    800032ee:	e44e                	sd	s3,8(sp)
    800032f0:	e052                	sd	s4,0(sp)
    800032f2:	1800                	addi	s0,sp,48
    800032f4:	84aa                	mv	s1,a0
    800032f6:	892e                	mv	s2,a1
    800032f8:	89b2                	mv	s3,a2
    800032fa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800032fc:	fffff097          	auipc	ra,0xfffff
    80003300:	ba6080e7          	jalr	-1114(ra) # 80001ea2 <myproc>
  if(user_dst){
    80003304:	c08d                	beqz	s1,80003326 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80003306:	86d2                	mv	a3,s4
    80003308:	864e                	mv	a2,s3
    8000330a:	85ca                	mv	a1,s2
    8000330c:	7d28                	ld	a0,120(a0)
    8000330e:	ffffe097          	auipc	ra,0xffffe
    80003312:	372080e7          	jalr	882(ra) # 80001680 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80003316:	70a2                	ld	ra,40(sp)
    80003318:	7402                	ld	s0,32(sp)
    8000331a:	64e2                	ld	s1,24(sp)
    8000331c:	6942                	ld	s2,16(sp)
    8000331e:	69a2                	ld	s3,8(sp)
    80003320:	6a02                	ld	s4,0(sp)
    80003322:	6145                	addi	sp,sp,48
    80003324:	8082                	ret
    memmove((char *)dst, src, len);
    80003326:	000a061b          	sext.w	a2,s4
    8000332a:	85ce                	mv	a1,s3
    8000332c:	854a                	mv	a0,s2
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	a20080e7          	jalr	-1504(ra) # 80000d4e <memmove>
    return 0;
    80003336:	8526                	mv	a0,s1
    80003338:	bff9                	j	80003316 <either_copyout+0x32>

000000008000333a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000333a:	7179                	addi	sp,sp,-48
    8000333c:	f406                	sd	ra,40(sp)
    8000333e:	f022                	sd	s0,32(sp)
    80003340:	ec26                	sd	s1,24(sp)
    80003342:	e84a                	sd	s2,16(sp)
    80003344:	e44e                	sd	s3,8(sp)
    80003346:	e052                	sd	s4,0(sp)
    80003348:	1800                	addi	s0,sp,48
    8000334a:	892a                	mv	s2,a0
    8000334c:	84ae                	mv	s1,a1
    8000334e:	89b2                	mv	s3,a2
    80003350:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003352:	fffff097          	auipc	ra,0xfffff
    80003356:	b50080e7          	jalr	-1200(ra) # 80001ea2 <myproc>
  if(user_src){
    8000335a:	c08d                	beqz	s1,8000337c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000335c:	86d2                	mv	a3,s4
    8000335e:	864e                	mv	a2,s3
    80003360:	85ca                	mv	a1,s2
    80003362:	7d28                	ld	a0,120(a0)
    80003364:	ffffe097          	auipc	ra,0xffffe
    80003368:	3a8080e7          	jalr	936(ra) # 8000170c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000336c:	70a2                	ld	ra,40(sp)
    8000336e:	7402                	ld	s0,32(sp)
    80003370:	64e2                	ld	s1,24(sp)
    80003372:	6942                	ld	s2,16(sp)
    80003374:	69a2                	ld	s3,8(sp)
    80003376:	6a02                	ld	s4,0(sp)
    80003378:	6145                	addi	sp,sp,48
    8000337a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000337c:	000a061b          	sext.w	a2,s4
    80003380:	85ce                	mv	a1,s3
    80003382:	854a                	mv	a0,s2
    80003384:	ffffe097          	auipc	ra,0xffffe
    80003388:	9ca080e7          	jalr	-1590(ra) # 80000d4e <memmove>
    return 0;
    8000338c:	8526                	mv	a0,s1
    8000338e:	bff9                	j	8000336c <either_copyin+0x32>

0000000080003390 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80003390:	715d                	addi	sp,sp,-80
    80003392:	e486                	sd	ra,72(sp)
    80003394:	e0a2                	sd	s0,64(sp)
    80003396:	fc26                	sd	s1,56(sp)
    80003398:	f84a                	sd	s2,48(sp)
    8000339a:	f44e                	sd	s3,40(sp)
    8000339c:	f052                	sd	s4,32(sp)
    8000339e:	ec56                	sd	s5,24(sp)
    800033a0:	e85a                	sd	s6,16(sp)
    800033a2:	e45e                	sd	s7,8(sp)
    800033a4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800033a6:	00006517          	auipc	a0,0x6
    800033aa:	fa250513          	addi	a0,a0,-94 # 80009348 <digits+0x308>
    800033ae:	ffffd097          	auipc	ra,0xffffd
    800033b2:	1da080e7          	jalr	474(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800033b6:	0000f497          	auipc	s1,0xf
    800033ba:	3aa48493          	addi	s1,s1,938 # 80012760 <proc+0x180>
    800033be:	00015917          	auipc	s2,0x15
    800033c2:	7a290913          	addi	s2,s2,1954 # 80018b60 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800033c6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800033c8:	00006997          	auipc	s3,0x6
    800033cc:	0a098993          	addi	s3,s3,160 # 80009468 <digits+0x428>
    printf("%d %s %s", p->pid, state, p->name);
    800033d0:	00006a97          	auipc	s5,0x6
    800033d4:	0a0a8a93          	addi	s5,s5,160 # 80009470 <digits+0x430>
    printf("\n");
    800033d8:	00006a17          	auipc	s4,0x6
    800033dc:	f70a0a13          	addi	s4,s4,-144 # 80009348 <digits+0x308>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800033e0:	00006b97          	auipc	s7,0x6
    800033e4:	0c8b8b93          	addi	s7,s7,200 # 800094a8 <states.1927>
    800033e8:	a00d                	j	8000340a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800033ea:	ec86a583          	lw	a1,-312(a3)
    800033ee:	8556                	mv	a0,s5
    800033f0:	ffffd097          	auipc	ra,0xffffd
    800033f4:	198080e7          	jalr	408(ra) # 80000588 <printf>
    printf("\n");
    800033f8:	8552                	mv	a0,s4
    800033fa:	ffffd097          	auipc	ra,0xffffd
    800033fe:	18e080e7          	jalr	398(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003402:	19048493          	addi	s1,s1,400
    80003406:	03248163          	beq	s1,s2,80003428 <procdump+0x98>
    if(p->state == UNUSED)
    8000340a:	86a6                	mv	a3,s1
    8000340c:	eb04a783          	lw	a5,-336(s1)
    80003410:	dbed                	beqz	a5,80003402 <procdump+0x72>
      state = "???";
    80003412:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003414:	fcfb6be3          	bltu	s6,a5,800033ea <procdump+0x5a>
    80003418:	1782                	slli	a5,a5,0x20
    8000341a:	9381                	srli	a5,a5,0x20
    8000341c:	078e                	slli	a5,a5,0x3
    8000341e:	97de                	add	a5,a5,s7
    80003420:	6390                	ld	a2,0(a5)
    80003422:	f661                	bnez	a2,800033ea <procdump+0x5a>
      state = "???";
    80003424:	864e                	mv	a2,s3
    80003426:	b7d1                	j	800033ea <procdump+0x5a>
  }
}
    80003428:	60a6                	ld	ra,72(sp)
    8000342a:	6406                	ld	s0,64(sp)
    8000342c:	74e2                	ld	s1,56(sp)
    8000342e:	7942                	ld	s2,48(sp)
    80003430:	79a2                	ld	s3,40(sp)
    80003432:	7a02                	ld	s4,32(sp)
    80003434:	6ae2                	ld	s5,24(sp)
    80003436:	6b42                	ld	s6,16(sp)
    80003438:	6ba2                	ld	s7,8(sp)
    8000343a:	6161                	addi	sp,sp,80
    8000343c:	8082                	ret

000000008000343e <swtch>:
    8000343e:	00153023          	sd	ra,0(a0)
    80003442:	00253423          	sd	sp,8(a0)
    80003446:	e900                	sd	s0,16(a0)
    80003448:	ed04                	sd	s1,24(a0)
    8000344a:	03253023          	sd	s2,32(a0)
    8000344e:	03353423          	sd	s3,40(a0)
    80003452:	03453823          	sd	s4,48(a0)
    80003456:	03553c23          	sd	s5,56(a0)
    8000345a:	05653023          	sd	s6,64(a0)
    8000345e:	05753423          	sd	s7,72(a0)
    80003462:	05853823          	sd	s8,80(a0)
    80003466:	05953c23          	sd	s9,88(a0)
    8000346a:	07a53023          	sd	s10,96(a0)
    8000346e:	07b53423          	sd	s11,104(a0)
    80003472:	0005b083          	ld	ra,0(a1)
    80003476:	0085b103          	ld	sp,8(a1)
    8000347a:	6980                	ld	s0,16(a1)
    8000347c:	6d84                	ld	s1,24(a1)
    8000347e:	0205b903          	ld	s2,32(a1)
    80003482:	0285b983          	ld	s3,40(a1)
    80003486:	0305ba03          	ld	s4,48(a1)
    8000348a:	0385ba83          	ld	s5,56(a1)
    8000348e:	0405bb03          	ld	s6,64(a1)
    80003492:	0485bb83          	ld	s7,72(a1)
    80003496:	0505bc03          	ld	s8,80(a1)
    8000349a:	0585bc83          	ld	s9,88(a1)
    8000349e:	0605bd03          	ld	s10,96(a1)
    800034a2:	0685bd83          	ld	s11,104(a1)
    800034a6:	8082                	ret

00000000800034a8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800034a8:	1141                	addi	sp,sp,-16
    800034aa:	e406                	sd	ra,8(sp)
    800034ac:	e022                	sd	s0,0(sp)
    800034ae:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800034b0:	00006597          	auipc	a1,0x6
    800034b4:	02858593          	addi	a1,a1,40 # 800094d8 <states.1927+0x30>
    800034b8:	00015517          	auipc	a0,0x15
    800034bc:	52850513          	addi	a0,a0,1320 # 800189e0 <tickslock>
    800034c0:	ffffd097          	auipc	ra,0xffffd
    800034c4:	694080e7          	jalr	1684(ra) # 80000b54 <initlock>
}
    800034c8:	60a2                	ld	ra,8(sp)
    800034ca:	6402                	ld	s0,0(sp)
    800034cc:	0141                	addi	sp,sp,16
    800034ce:	8082                	ret

00000000800034d0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800034d0:	1141                	addi	sp,sp,-16
    800034d2:	e422                	sd	s0,8(sp)
    800034d4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800034d6:	00003797          	auipc	a5,0x3
    800034da:	4ca78793          	addi	a5,a5,1226 # 800069a0 <kernelvec>
    800034de:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800034e2:	6422                	ld	s0,8(sp)
    800034e4:	0141                	addi	sp,sp,16
    800034e6:	8082                	ret

00000000800034e8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800034e8:	1141                	addi	sp,sp,-16
    800034ea:	e406                	sd	ra,8(sp)
    800034ec:	e022                	sd	s0,0(sp)
    800034ee:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800034f0:	fffff097          	auipc	ra,0xfffff
    800034f4:	9b2080e7          	jalr	-1614(ra) # 80001ea2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034f8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800034fc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034fe:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003502:	00005617          	auipc	a2,0x5
    80003506:	afe60613          	addi	a2,a2,-1282 # 80008000 <_trampoline>
    8000350a:	00005697          	auipc	a3,0x5
    8000350e:	af668693          	addi	a3,a3,-1290 # 80008000 <_trampoline>
    80003512:	8e91                	sub	a3,a3,a2
    80003514:	040007b7          	lui	a5,0x4000
    80003518:	17fd                	addi	a5,a5,-1
    8000351a:	07b2                	slli	a5,a5,0xc
    8000351c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000351e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003522:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003524:	180026f3          	csrr	a3,satp
    80003528:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000352a:	6158                	ld	a4,128(a0)
    8000352c:	7534                	ld	a3,104(a0)
    8000352e:	6585                	lui	a1,0x1
    80003530:	96ae                	add	a3,a3,a1
    80003532:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003534:	6158                	ld	a4,128(a0)
    80003536:	00000697          	auipc	a3,0x0
    8000353a:	13868693          	addi	a3,a3,312 # 8000366e <usertrap>
    8000353e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003540:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003542:	8692                	mv	a3,tp
    80003544:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003546:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000354a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000354e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003552:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003556:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003558:	6f18                	ld	a4,24(a4)
    8000355a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000355e:	7d2c                	ld	a1,120(a0)
    80003560:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003562:	00005717          	auipc	a4,0x5
    80003566:	b2e70713          	addi	a4,a4,-1234 # 80008090 <userret>
    8000356a:	8f11                	sub	a4,a4,a2
    8000356c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000356e:	577d                	li	a4,-1
    80003570:	177e                	slli	a4,a4,0x3f
    80003572:	8dd9                	or	a1,a1,a4
    80003574:	02000537          	lui	a0,0x2000
    80003578:	157d                	addi	a0,a0,-1
    8000357a:	0536                	slli	a0,a0,0xd
    8000357c:	9782                	jalr	a5
}
    8000357e:	60a2                	ld	ra,8(sp)
    80003580:	6402                	ld	s0,0(sp)
    80003582:	0141                	addi	sp,sp,16
    80003584:	8082                	ret

0000000080003586 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003586:	1101                	addi	sp,sp,-32
    80003588:	ec06                	sd	ra,24(sp)
    8000358a:	e822                	sd	s0,16(sp)
    8000358c:	e426                	sd	s1,8(sp)
    8000358e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003590:	00015497          	auipc	s1,0x15
    80003594:	45048493          	addi	s1,s1,1104 # 800189e0 <tickslock>
    80003598:	8526                	mv	a0,s1
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	652080e7          	jalr	1618(ra) # 80000bec <acquire>
  ticks++;
    800035a2:	00007517          	auipc	a0,0x7
    800035a6:	ace50513          	addi	a0,a0,-1330 # 8000a070 <ticks>
    800035aa:	411c                	lw	a5,0(a0)
    800035ac:	2785                	addiw	a5,a5,1
    800035ae:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	9aa080e7          	jalr	-1622(ra) # 80002f5a <wakeup>
  release(&tickslock);
    800035b8:	8526                	mv	a0,s1
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	6ec080e7          	jalr	1772(ra) # 80000ca6 <release>
}
    800035c2:	60e2                	ld	ra,24(sp)
    800035c4:	6442                	ld	s0,16(sp)
    800035c6:	64a2                	ld	s1,8(sp)
    800035c8:	6105                	addi	sp,sp,32
    800035ca:	8082                	ret

00000000800035cc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800035cc:	1101                	addi	sp,sp,-32
    800035ce:	ec06                	sd	ra,24(sp)
    800035d0:	e822                	sd	s0,16(sp)
    800035d2:	e426                	sd	s1,8(sp)
    800035d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800035d6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800035da:	00074d63          	bltz	a4,800035f4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800035de:	57fd                	li	a5,-1
    800035e0:	17fe                	slli	a5,a5,0x3f
    800035e2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800035e4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800035e6:	06f70363          	beq	a4,a5,8000364c <devintr+0x80>
  }
}
    800035ea:	60e2                	ld	ra,24(sp)
    800035ec:	6442                	ld	s0,16(sp)
    800035ee:	64a2                	ld	s1,8(sp)
    800035f0:	6105                	addi	sp,sp,32
    800035f2:	8082                	ret
     (scause & 0xff) == 9){
    800035f4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800035f8:	46a5                	li	a3,9
    800035fa:	fed792e3          	bne	a5,a3,800035de <devintr+0x12>
    int irq = plic_claim();
    800035fe:	00003097          	auipc	ra,0x3
    80003602:	4aa080e7          	jalr	1194(ra) # 80006aa8 <plic_claim>
    80003606:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003608:	47a9                	li	a5,10
    8000360a:	02f50763          	beq	a0,a5,80003638 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000360e:	4785                	li	a5,1
    80003610:	02f50963          	beq	a0,a5,80003642 <devintr+0x76>
    return 1;
    80003614:	4505                	li	a0,1
    } else if(irq){
    80003616:	d8f1                	beqz	s1,800035ea <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003618:	85a6                	mv	a1,s1
    8000361a:	00006517          	auipc	a0,0x6
    8000361e:	ec650513          	addi	a0,a0,-314 # 800094e0 <states.1927+0x38>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	f66080e7          	jalr	-154(ra) # 80000588 <printf>
      plic_complete(irq);
    8000362a:	8526                	mv	a0,s1
    8000362c:	00003097          	auipc	ra,0x3
    80003630:	4a0080e7          	jalr	1184(ra) # 80006acc <plic_complete>
    return 1;
    80003634:	4505                	li	a0,1
    80003636:	bf55                	j	800035ea <devintr+0x1e>
      uartintr();
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	370080e7          	jalr	880(ra) # 800009a8 <uartintr>
    80003640:	b7ed                	j	8000362a <devintr+0x5e>
      virtio_disk_intr();
    80003642:	00004097          	auipc	ra,0x4
    80003646:	96a080e7          	jalr	-1686(ra) # 80006fac <virtio_disk_intr>
    8000364a:	b7c5                	j	8000362a <devintr+0x5e>
    if(cpuid() == 0){
    8000364c:	fffff097          	auipc	ra,0xfffff
    80003650:	822080e7          	jalr	-2014(ra) # 80001e6e <cpuid>
    80003654:	c901                	beqz	a0,80003664 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003656:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000365a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000365c:	14479073          	csrw	sip,a5
    return 2;
    80003660:	4509                	li	a0,2
    80003662:	b761                	j	800035ea <devintr+0x1e>
      clockintr();
    80003664:	00000097          	auipc	ra,0x0
    80003668:	f22080e7          	jalr	-222(ra) # 80003586 <clockintr>
    8000366c:	b7ed                	j	80003656 <devintr+0x8a>

000000008000366e <usertrap>:
{
    8000366e:	1101                	addi	sp,sp,-32
    80003670:	ec06                	sd	ra,24(sp)
    80003672:	e822                	sd	s0,16(sp)
    80003674:	e426                	sd	s1,8(sp)
    80003676:	e04a                	sd	s2,0(sp)
    80003678:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000367a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000367e:	1007f793          	andi	a5,a5,256
    80003682:	e3ad                	bnez	a5,800036e4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003684:	00003797          	auipc	a5,0x3
    80003688:	31c78793          	addi	a5,a5,796 # 800069a0 <kernelvec>
    8000368c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003690:	fffff097          	auipc	ra,0xfffff
    80003694:	812080e7          	jalr	-2030(ra) # 80001ea2 <myproc>
    80003698:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000369a:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000369c:	14102773          	csrr	a4,sepc
    800036a0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800036a2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800036a6:	47a1                	li	a5,8
    800036a8:	04f71c63          	bne	a4,a5,80003700 <usertrap+0x92>
    if(p->killed)
    800036ac:	413c                	lw	a5,64(a0)
    800036ae:	e3b9                	bnez	a5,800036f4 <usertrap+0x86>
    p->trapframe->epc += 4;
    800036b0:	60d8                	ld	a4,128(s1)
    800036b2:	6f1c                	ld	a5,24(a4)
    800036b4:	0791                	addi	a5,a5,4
    800036b6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800036b8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800036bc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800036c0:	10079073          	csrw	sstatus,a5
    syscall();
    800036c4:	00000097          	auipc	ra,0x0
    800036c8:	2e0080e7          	jalr	736(ra) # 800039a4 <syscall>
  if(p->killed)
    800036cc:	40bc                	lw	a5,64(s1)
    800036ce:	ebc1                	bnez	a5,8000375e <usertrap+0xf0>
  usertrapret();
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	e18080e7          	jalr	-488(ra) # 800034e8 <usertrapret>
}
    800036d8:	60e2                	ld	ra,24(sp)
    800036da:	6442                	ld	s0,16(sp)
    800036dc:	64a2                	ld	s1,8(sp)
    800036de:	6902                	ld	s2,0(sp)
    800036e0:	6105                	addi	sp,sp,32
    800036e2:	8082                	ret
    panic("usertrap: not from user mode");
    800036e4:	00006517          	auipc	a0,0x6
    800036e8:	e1c50513          	addi	a0,a0,-484 # 80009500 <states.1927+0x58>
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	e52080e7          	jalr	-430(ra) # 8000053e <panic>
      exit(-1);
    800036f4:	557d                	li	a0,-1
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	a46080e7          	jalr	-1466(ra) # 8000313c <exit>
    800036fe:	bf4d                	j	800036b0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003700:	00000097          	auipc	ra,0x0
    80003704:	ecc080e7          	jalr	-308(ra) # 800035cc <devintr>
    80003708:	892a                	mv	s2,a0
    8000370a:	c501                	beqz	a0,80003712 <usertrap+0xa4>
  if(p->killed)
    8000370c:	40bc                	lw	a5,64(s1)
    8000370e:	c3a1                	beqz	a5,8000374e <usertrap+0xe0>
    80003710:	a815                	j	80003744 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003712:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003716:	44b0                	lw	a2,72(s1)
    80003718:	00006517          	auipc	a0,0x6
    8000371c:	e0850513          	addi	a0,a0,-504 # 80009520 <states.1927+0x78>
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	e68080e7          	jalr	-408(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003728:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000372c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003730:	00006517          	auipc	a0,0x6
    80003734:	e2050513          	addi	a0,a0,-480 # 80009550 <states.1927+0xa8>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	e50080e7          	jalr	-432(ra) # 80000588 <printf>
    p->killed = 1;
    80003740:	4785                	li	a5,1
    80003742:	c0bc                	sw	a5,64(s1)
    exit(-1);
    80003744:	557d                	li	a0,-1
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	9f6080e7          	jalr	-1546(ra) # 8000313c <exit>
  if(which_dev == 2)
    8000374e:	4789                	li	a5,2
    80003750:	f8f910e3          	bne	s2,a5,800036d0 <usertrap+0x62>
    yield();
    80003754:	fffff097          	auipc	ra,0xfffff
    80003758:	a7e080e7          	jalr	-1410(ra) # 800021d2 <yield>
    8000375c:	bf95                	j	800036d0 <usertrap+0x62>
  int which_dev = 0;
    8000375e:	4901                	li	s2,0
    80003760:	b7d5                	j	80003744 <usertrap+0xd6>

0000000080003762 <kerneltrap>:
{
    80003762:	7179                	addi	sp,sp,-48
    80003764:	f406                	sd	ra,40(sp)
    80003766:	f022                	sd	s0,32(sp)
    80003768:	ec26                	sd	s1,24(sp)
    8000376a:	e84a                	sd	s2,16(sp)
    8000376c:	e44e                	sd	s3,8(sp)
    8000376e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003770:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003774:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003778:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000377c:	1004f793          	andi	a5,s1,256
    80003780:	cb85                	beqz	a5,800037b0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003782:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003786:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003788:	ef85                	bnez	a5,800037c0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	e42080e7          	jalr	-446(ra) # 800035cc <devintr>
    80003792:	cd1d                	beqz	a0,800037d0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003794:	4789                	li	a5,2
    80003796:	06f50a63          	beq	a0,a5,8000380a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000379a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000379e:	10049073          	csrw	sstatus,s1
}
    800037a2:	70a2                	ld	ra,40(sp)
    800037a4:	7402                	ld	s0,32(sp)
    800037a6:	64e2                	ld	s1,24(sp)
    800037a8:	6942                	ld	s2,16(sp)
    800037aa:	69a2                	ld	s3,8(sp)
    800037ac:	6145                	addi	sp,sp,48
    800037ae:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800037b0:	00006517          	auipc	a0,0x6
    800037b4:	dc050513          	addi	a0,a0,-576 # 80009570 <states.1927+0xc8>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	d86080e7          	jalr	-634(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800037c0:	00006517          	auipc	a0,0x6
    800037c4:	dd850513          	addi	a0,a0,-552 # 80009598 <states.1927+0xf0>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	d76080e7          	jalr	-650(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800037d0:	85ce                	mv	a1,s3
    800037d2:	00006517          	auipc	a0,0x6
    800037d6:	de650513          	addi	a0,a0,-538 # 800095b8 <states.1927+0x110>
    800037da:	ffffd097          	auipc	ra,0xffffd
    800037de:	dae080e7          	jalr	-594(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800037e2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800037e6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800037ea:	00006517          	auipc	a0,0x6
    800037ee:	dde50513          	addi	a0,a0,-546 # 800095c8 <states.1927+0x120>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	d96080e7          	jalr	-618(ra) # 80000588 <printf>
    panic("kerneltrap");
    800037fa:	00006517          	auipc	a0,0x6
    800037fe:	de650513          	addi	a0,a0,-538 # 800095e0 <states.1927+0x138>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	d3c080e7          	jalr	-708(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000380a:	ffffe097          	auipc	ra,0xffffe
    8000380e:	698080e7          	jalr	1688(ra) # 80001ea2 <myproc>
    80003812:	d541                	beqz	a0,8000379a <kerneltrap+0x38>
    80003814:	ffffe097          	auipc	ra,0xffffe
    80003818:	68e080e7          	jalr	1678(ra) # 80001ea2 <myproc>
    8000381c:	5918                	lw	a4,48(a0)
    8000381e:	4791                	li	a5,4
    80003820:	f6f71de3          	bne	a4,a5,8000379a <kerneltrap+0x38>
    yield();
    80003824:	fffff097          	auipc	ra,0xfffff
    80003828:	9ae080e7          	jalr	-1618(ra) # 800021d2 <yield>
    8000382c:	b7bd                	j	8000379a <kerneltrap+0x38>

000000008000382e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000382e:	1101                	addi	sp,sp,-32
    80003830:	ec06                	sd	ra,24(sp)
    80003832:	e822                	sd	s0,16(sp)
    80003834:	e426                	sd	s1,8(sp)
    80003836:	1000                	addi	s0,sp,32
    80003838:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000383a:	ffffe097          	auipc	ra,0xffffe
    8000383e:	668080e7          	jalr	1640(ra) # 80001ea2 <myproc>
  switch (n) {
    80003842:	4795                	li	a5,5
    80003844:	0497e163          	bltu	a5,s1,80003886 <argraw+0x58>
    80003848:	048a                	slli	s1,s1,0x2
    8000384a:	00006717          	auipc	a4,0x6
    8000384e:	dce70713          	addi	a4,a4,-562 # 80009618 <states.1927+0x170>
    80003852:	94ba                	add	s1,s1,a4
    80003854:	409c                	lw	a5,0(s1)
    80003856:	97ba                	add	a5,a5,a4
    80003858:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000385a:	615c                	ld	a5,128(a0)
    8000385c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000385e:	60e2                	ld	ra,24(sp)
    80003860:	6442                	ld	s0,16(sp)
    80003862:	64a2                	ld	s1,8(sp)
    80003864:	6105                	addi	sp,sp,32
    80003866:	8082                	ret
    return p->trapframe->a1;
    80003868:	615c                	ld	a5,128(a0)
    8000386a:	7fa8                	ld	a0,120(a5)
    8000386c:	bfcd                	j	8000385e <argraw+0x30>
    return p->trapframe->a2;
    8000386e:	615c                	ld	a5,128(a0)
    80003870:	63c8                	ld	a0,128(a5)
    80003872:	b7f5                	j	8000385e <argraw+0x30>
    return p->trapframe->a3;
    80003874:	615c                	ld	a5,128(a0)
    80003876:	67c8                	ld	a0,136(a5)
    80003878:	b7dd                	j	8000385e <argraw+0x30>
    return p->trapframe->a4;
    8000387a:	615c                	ld	a5,128(a0)
    8000387c:	6bc8                	ld	a0,144(a5)
    8000387e:	b7c5                	j	8000385e <argraw+0x30>
    return p->trapframe->a5;
    80003880:	615c                	ld	a5,128(a0)
    80003882:	6fc8                	ld	a0,152(a5)
    80003884:	bfe9                	j	8000385e <argraw+0x30>
  panic("argraw");
    80003886:	00006517          	auipc	a0,0x6
    8000388a:	d6a50513          	addi	a0,a0,-662 # 800095f0 <states.1927+0x148>
    8000388e:	ffffd097          	auipc	ra,0xffffd
    80003892:	cb0080e7          	jalr	-848(ra) # 8000053e <panic>

0000000080003896 <fetchaddr>:
{
    80003896:	1101                	addi	sp,sp,-32
    80003898:	ec06                	sd	ra,24(sp)
    8000389a:	e822                	sd	s0,16(sp)
    8000389c:	e426                	sd	s1,8(sp)
    8000389e:	e04a                	sd	s2,0(sp)
    800038a0:	1000                	addi	s0,sp,32
    800038a2:	84aa                	mv	s1,a0
    800038a4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800038a6:	ffffe097          	auipc	ra,0xffffe
    800038aa:	5fc080e7          	jalr	1532(ra) # 80001ea2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800038ae:	793c                	ld	a5,112(a0)
    800038b0:	02f4f863          	bgeu	s1,a5,800038e0 <fetchaddr+0x4a>
    800038b4:	00848713          	addi	a4,s1,8
    800038b8:	02e7e663          	bltu	a5,a4,800038e4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800038bc:	46a1                	li	a3,8
    800038be:	8626                	mv	a2,s1
    800038c0:	85ca                	mv	a1,s2
    800038c2:	7d28                	ld	a0,120(a0)
    800038c4:	ffffe097          	auipc	ra,0xffffe
    800038c8:	e48080e7          	jalr	-440(ra) # 8000170c <copyin>
    800038cc:	00a03533          	snez	a0,a0
    800038d0:	40a00533          	neg	a0,a0
}
    800038d4:	60e2                	ld	ra,24(sp)
    800038d6:	6442                	ld	s0,16(sp)
    800038d8:	64a2                	ld	s1,8(sp)
    800038da:	6902                	ld	s2,0(sp)
    800038dc:	6105                	addi	sp,sp,32
    800038de:	8082                	ret
    return -1;
    800038e0:	557d                	li	a0,-1
    800038e2:	bfcd                	j	800038d4 <fetchaddr+0x3e>
    800038e4:	557d                	li	a0,-1
    800038e6:	b7fd                	j	800038d4 <fetchaddr+0x3e>

00000000800038e8 <fetchstr>:
{
    800038e8:	7179                	addi	sp,sp,-48
    800038ea:	f406                	sd	ra,40(sp)
    800038ec:	f022                	sd	s0,32(sp)
    800038ee:	ec26                	sd	s1,24(sp)
    800038f0:	e84a                	sd	s2,16(sp)
    800038f2:	e44e                	sd	s3,8(sp)
    800038f4:	1800                	addi	s0,sp,48
    800038f6:	892a                	mv	s2,a0
    800038f8:	84ae                	mv	s1,a1
    800038fa:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800038fc:	ffffe097          	auipc	ra,0xffffe
    80003900:	5a6080e7          	jalr	1446(ra) # 80001ea2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003904:	86ce                	mv	a3,s3
    80003906:	864a                	mv	a2,s2
    80003908:	85a6                	mv	a1,s1
    8000390a:	7d28                	ld	a0,120(a0)
    8000390c:	ffffe097          	auipc	ra,0xffffe
    80003910:	e8c080e7          	jalr	-372(ra) # 80001798 <copyinstr>
  if(err < 0)
    80003914:	00054763          	bltz	a0,80003922 <fetchstr+0x3a>
  return strlen(buf);
    80003918:	8526                	mv	a0,s1
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	558080e7          	jalr	1368(ra) # 80000e72 <strlen>
}
    80003922:	70a2                	ld	ra,40(sp)
    80003924:	7402                	ld	s0,32(sp)
    80003926:	64e2                	ld	s1,24(sp)
    80003928:	6942                	ld	s2,16(sp)
    8000392a:	69a2                	ld	s3,8(sp)
    8000392c:	6145                	addi	sp,sp,48
    8000392e:	8082                	ret

0000000080003930 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003930:	1101                	addi	sp,sp,-32
    80003932:	ec06                	sd	ra,24(sp)
    80003934:	e822                	sd	s0,16(sp)
    80003936:	e426                	sd	s1,8(sp)
    80003938:	1000                	addi	s0,sp,32
    8000393a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	ef2080e7          	jalr	-270(ra) # 8000382e <argraw>
    80003944:	c088                	sw	a0,0(s1)
  return 0;
}
    80003946:	4501                	li	a0,0
    80003948:	60e2                	ld	ra,24(sp)
    8000394a:	6442                	ld	s0,16(sp)
    8000394c:	64a2                	ld	s1,8(sp)
    8000394e:	6105                	addi	sp,sp,32
    80003950:	8082                	ret

0000000080003952 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003952:	1101                	addi	sp,sp,-32
    80003954:	ec06                	sd	ra,24(sp)
    80003956:	e822                	sd	s0,16(sp)
    80003958:	e426                	sd	s1,8(sp)
    8000395a:	1000                	addi	s0,sp,32
    8000395c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	ed0080e7          	jalr	-304(ra) # 8000382e <argraw>
    80003966:	e088                	sd	a0,0(s1)
  return 0;
}
    80003968:	4501                	li	a0,0
    8000396a:	60e2                	ld	ra,24(sp)
    8000396c:	6442                	ld	s0,16(sp)
    8000396e:	64a2                	ld	s1,8(sp)
    80003970:	6105                	addi	sp,sp,32
    80003972:	8082                	ret

0000000080003974 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003974:	1101                	addi	sp,sp,-32
    80003976:	ec06                	sd	ra,24(sp)
    80003978:	e822                	sd	s0,16(sp)
    8000397a:	e426                	sd	s1,8(sp)
    8000397c:	e04a                	sd	s2,0(sp)
    8000397e:	1000                	addi	s0,sp,32
    80003980:	84ae                	mv	s1,a1
    80003982:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003984:	00000097          	auipc	ra,0x0
    80003988:	eaa080e7          	jalr	-342(ra) # 8000382e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000398c:	864a                	mv	a2,s2
    8000398e:	85a6                	mv	a1,s1
    80003990:	00000097          	auipc	ra,0x0
    80003994:	f58080e7          	jalr	-168(ra) # 800038e8 <fetchstr>
}
    80003998:	60e2                	ld	ra,24(sp)
    8000399a:	6442                	ld	s0,16(sp)
    8000399c:	64a2                	ld	s1,8(sp)
    8000399e:	6902                	ld	s2,0(sp)
    800039a0:	6105                	addi	sp,sp,32
    800039a2:	8082                	ret

00000000800039a4 <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    800039a4:	1101                	addi	sp,sp,-32
    800039a6:	ec06                	sd	ra,24(sp)
    800039a8:	e822                	sd	s0,16(sp)
    800039aa:	e426                	sd	s1,8(sp)
    800039ac:	e04a                	sd	s2,0(sp)
    800039ae:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800039b0:	ffffe097          	auipc	ra,0xffffe
    800039b4:	4f2080e7          	jalr	1266(ra) # 80001ea2 <myproc>
    800039b8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800039ba:	08053903          	ld	s2,128(a0)
    800039be:	0a893783          	ld	a5,168(s2)
    800039c2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800039c6:	37fd                	addiw	a5,a5,-1
    800039c8:	4759                	li	a4,22
    800039ca:	00f76f63          	bltu	a4,a5,800039e8 <syscall+0x44>
    800039ce:	00369713          	slli	a4,a3,0x3
    800039d2:	00006797          	auipc	a5,0x6
    800039d6:	c5e78793          	addi	a5,a5,-930 # 80009630 <syscalls>
    800039da:	97ba                	add	a5,a5,a4
    800039dc:	639c                	ld	a5,0(a5)
    800039de:	c789                	beqz	a5,800039e8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800039e0:	9782                	jalr	a5
    800039e2:	06a93823          	sd	a0,112(s2)
    800039e6:	a839                	j	80003a04 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800039e8:	18048613          	addi	a2,s1,384
    800039ec:	44ac                	lw	a1,72(s1)
    800039ee:	00006517          	auipc	a0,0x6
    800039f2:	c0a50513          	addi	a0,a0,-1014 # 800095f8 <states.1927+0x150>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	b92080e7          	jalr	-1134(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800039fe:	60dc                	ld	a5,128(s1)
    80003a00:	577d                	li	a4,-1
    80003a02:	fbb8                	sd	a4,112(a5)
  }
}
    80003a04:	60e2                	ld	ra,24(sp)
    80003a06:	6442                	ld	s0,16(sp)
    80003a08:	64a2                	ld	s1,8(sp)
    80003a0a:	6902                	ld	s2,0(sp)
    80003a0c:	6105                	addi	sp,sp,32
    80003a0e:	8082                	ret

0000000080003a10 <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    80003a10:	1101                	addi	sp,sp,-32
    80003a12:	ec06                	sd	ra,24(sp)
    80003a14:	e822                	sd	s0,16(sp)
    80003a16:	1000                	addi	s0,sp,32
  int a;

  if(argint(0, &a) < 0)
    80003a18:	fec40593          	addi	a1,s0,-20
    80003a1c:	4501                	li	a0,0
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	f12080e7          	jalr	-238(ra) # 80003930 <argint>
    80003a26:	87aa                	mv	a5,a0
    return -1;
    80003a28:	557d                	li	a0,-1
  if(argint(0, &a) < 0)
    80003a2a:	0007c863          	bltz	a5,80003a3a <sys_set_cpu+0x2a>
  return set_cpu(a);
    80003a2e:	fec42503          	lw	a0,-20(s0)
    80003a32:	ffffe097          	auipc	ra,0xffffe
    80003a36:	7ec080e7          	jalr	2028(ra) # 8000221e <set_cpu>
}
    80003a3a:	60e2                	ld	ra,24(sp)
    80003a3c:	6442                	ld	s0,16(sp)
    80003a3e:	6105                	addi	sp,sp,32
    80003a40:	8082                	ret

0000000080003a42 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003a42:	1141                	addi	sp,sp,-16
    80003a44:	e406                	sd	ra,8(sp)
    80003a46:	e022                	sd	s0,0(sp)
    80003a48:	0800                	addi	s0,sp,16
  return get_cpu();
    80003a4a:	ffffe097          	auipc	ra,0xffffe
    80003a4e:	498080e7          	jalr	1176(ra) # 80001ee2 <get_cpu>
}
    80003a52:	60a2                	ld	ra,8(sp)
    80003a54:	6402                	ld	s0,0(sp)
    80003a56:	0141                	addi	sp,sp,16
    80003a58:	8082                	ret

0000000080003a5a <sys_exit>:

uint64
sys_exit(void)
{
    80003a5a:	1101                	addi	sp,sp,-32
    80003a5c:	ec06                	sd	ra,24(sp)
    80003a5e:	e822                	sd	s0,16(sp)
    80003a60:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003a62:	fec40593          	addi	a1,s0,-20
    80003a66:	4501                	li	a0,0
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	ec8080e7          	jalr	-312(ra) # 80003930 <argint>
    return -1;
    80003a70:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003a72:	00054963          	bltz	a0,80003a84 <sys_exit+0x2a>
  exit(n);
    80003a76:	fec42503          	lw	a0,-20(s0)
    80003a7a:	fffff097          	auipc	ra,0xfffff
    80003a7e:	6c2080e7          	jalr	1730(ra) # 8000313c <exit>
  return 0;  // not reached
    80003a82:	4781                	li	a5,0
}
    80003a84:	853e                	mv	a0,a5
    80003a86:	60e2                	ld	ra,24(sp)
    80003a88:	6442                	ld	s0,16(sp)
    80003a8a:	6105                	addi	sp,sp,32
    80003a8c:	8082                	ret

0000000080003a8e <sys_getpid>:

uint64
sys_getpid(void)
{
    80003a8e:	1141                	addi	sp,sp,-16
    80003a90:	e406                	sd	ra,8(sp)
    80003a92:	e022                	sd	s0,0(sp)
    80003a94:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003a96:	ffffe097          	auipc	ra,0xffffe
    80003a9a:	40c080e7          	jalr	1036(ra) # 80001ea2 <myproc>
}
    80003a9e:	4528                	lw	a0,72(a0)
    80003aa0:	60a2                	ld	ra,8(sp)
    80003aa2:	6402                	ld	s0,0(sp)
    80003aa4:	0141                	addi	sp,sp,16
    80003aa6:	8082                	ret

0000000080003aa8 <sys_fork>:

uint64
sys_fork(void)
{
    80003aa8:	1141                	addi	sp,sp,-16
    80003aaa:	e406                	sd	ra,8(sp)
    80003aac:	e022                	sd	s0,0(sp)
    80003aae:	0800                	addi	s0,sp,16
  return fork();
    80003ab0:	fffff097          	auipc	ra,0xfffff
    80003ab4:	1a4080e7          	jalr	420(ra) # 80002c54 <fork>
}
    80003ab8:	60a2                	ld	ra,8(sp)
    80003aba:	6402                	ld	s0,0(sp)
    80003abc:	0141                	addi	sp,sp,16
    80003abe:	8082                	ret

0000000080003ac0 <sys_wait>:

uint64
sys_wait(void)
{
    80003ac0:	1101                	addi	sp,sp,-32
    80003ac2:	ec06                	sd	ra,24(sp)
    80003ac4:	e822                	sd	s0,16(sp)
    80003ac6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003ac8:	fe840593          	addi	a1,s0,-24
    80003acc:	4501                	li	a0,0
    80003ace:	00000097          	auipc	ra,0x0
    80003ad2:	e84080e7          	jalr	-380(ra) # 80003952 <argaddr>
    80003ad6:	87aa                	mv	a5,a0
    return -1;
    80003ad8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003ada:	0007c863          	bltz	a5,80003aea <sys_wait+0x2a>
  return wait(p);
    80003ade:	fe843503          	ld	a0,-24(s0)
    80003ae2:	fffff097          	auipc	ra,0xfffff
    80003ae6:	350080e7          	jalr	848(ra) # 80002e32 <wait>
}
    80003aea:	60e2                	ld	ra,24(sp)
    80003aec:	6442                	ld	s0,16(sp)
    80003aee:	6105                	addi	sp,sp,32
    80003af0:	8082                	ret

0000000080003af2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003af2:	7179                	addi	sp,sp,-48
    80003af4:	f406                	sd	ra,40(sp)
    80003af6:	f022                	sd	s0,32(sp)
    80003af8:	ec26                	sd	s1,24(sp)
    80003afa:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003afc:	fdc40593          	addi	a1,s0,-36
    80003b00:	4501                	li	a0,0
    80003b02:	00000097          	auipc	ra,0x0
    80003b06:	e2e080e7          	jalr	-466(ra) # 80003930 <argint>
    80003b0a:	87aa                	mv	a5,a0
    return -1;
    80003b0c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003b0e:	0207c063          	bltz	a5,80003b2e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003b12:	ffffe097          	auipc	ra,0xffffe
    80003b16:	390080e7          	jalr	912(ra) # 80001ea2 <myproc>
    80003b1a:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    80003b1c:	fdc42503          	lw	a0,-36(s0)
    80003b20:	ffffe097          	auipc	ra,0xffffe
    80003b24:	548080e7          	jalr	1352(ra) # 80002068 <growproc>
    80003b28:	00054863          	bltz	a0,80003b38 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003b2c:	8526                	mv	a0,s1
}
    80003b2e:	70a2                	ld	ra,40(sp)
    80003b30:	7402                	ld	s0,32(sp)
    80003b32:	64e2                	ld	s1,24(sp)
    80003b34:	6145                	addi	sp,sp,48
    80003b36:	8082                	ret
    return -1;
    80003b38:	557d                	li	a0,-1
    80003b3a:	bfd5                	j	80003b2e <sys_sbrk+0x3c>

0000000080003b3c <sys_sleep>:

uint64
sys_sleep(void)
{
    80003b3c:	7139                	addi	sp,sp,-64
    80003b3e:	fc06                	sd	ra,56(sp)
    80003b40:	f822                	sd	s0,48(sp)
    80003b42:	f426                	sd	s1,40(sp)
    80003b44:	f04a                	sd	s2,32(sp)
    80003b46:	ec4e                	sd	s3,24(sp)
    80003b48:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003b4a:	fcc40593          	addi	a1,s0,-52
    80003b4e:	4501                	li	a0,0
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	de0080e7          	jalr	-544(ra) # 80003930 <argint>
    return -1;
    80003b58:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003b5a:	06054563          	bltz	a0,80003bc4 <sys_sleep+0x88>
  acquire(&tickslock);
    80003b5e:	00015517          	auipc	a0,0x15
    80003b62:	e8250513          	addi	a0,a0,-382 # 800189e0 <tickslock>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	086080e7          	jalr	134(ra) # 80000bec <acquire>
  ticks0 = ticks;
    80003b6e:	00006917          	auipc	s2,0x6
    80003b72:	50292903          	lw	s2,1282(s2) # 8000a070 <ticks>
  while(ticks - ticks0 < n){
    80003b76:	fcc42783          	lw	a5,-52(s0)
    80003b7a:	cf85                	beqz	a5,80003bb2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003b7c:	00015997          	auipc	s3,0x15
    80003b80:	e6498993          	addi	s3,s3,-412 # 800189e0 <tickslock>
    80003b84:	00006497          	auipc	s1,0x6
    80003b88:	4ec48493          	addi	s1,s1,1260 # 8000a070 <ticks>
    if(myproc()->killed){
    80003b8c:	ffffe097          	auipc	ra,0xffffe
    80003b90:	316080e7          	jalr	790(ra) # 80001ea2 <myproc>
    80003b94:	413c                	lw	a5,64(a0)
    80003b96:	ef9d                	bnez	a5,80003bd4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003b98:	85ce                	mv	a1,s3
    80003b9a:	8526                	mv	a0,s1
    80003b9c:	fffff097          	auipc	ra,0xfffff
    80003ba0:	216080e7          	jalr	534(ra) # 80002db2 <sleep>
  while(ticks - ticks0 < n){
    80003ba4:	409c                	lw	a5,0(s1)
    80003ba6:	412787bb          	subw	a5,a5,s2
    80003baa:	fcc42703          	lw	a4,-52(s0)
    80003bae:	fce7efe3          	bltu	a5,a4,80003b8c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003bb2:	00015517          	auipc	a0,0x15
    80003bb6:	e2e50513          	addi	a0,a0,-466 # 800189e0 <tickslock>
    80003bba:	ffffd097          	auipc	ra,0xffffd
    80003bbe:	0ec080e7          	jalr	236(ra) # 80000ca6 <release>
  return 0;
    80003bc2:	4781                	li	a5,0
}
    80003bc4:	853e                	mv	a0,a5
    80003bc6:	70e2                	ld	ra,56(sp)
    80003bc8:	7442                	ld	s0,48(sp)
    80003bca:	74a2                	ld	s1,40(sp)
    80003bcc:	7902                	ld	s2,32(sp)
    80003bce:	69e2                	ld	s3,24(sp)
    80003bd0:	6121                	addi	sp,sp,64
    80003bd2:	8082                	ret
      release(&tickslock);
    80003bd4:	00015517          	auipc	a0,0x15
    80003bd8:	e0c50513          	addi	a0,a0,-500 # 800189e0 <tickslock>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	0ca080e7          	jalr	202(ra) # 80000ca6 <release>
      return -1;
    80003be4:	57fd                	li	a5,-1
    80003be6:	bff9                	j	80003bc4 <sys_sleep+0x88>

0000000080003be8 <sys_kill>:

uint64
sys_kill(void)
{
    80003be8:	1101                	addi	sp,sp,-32
    80003bea:	ec06                	sd	ra,24(sp)
    80003bec:	e822                	sd	s0,16(sp)
    80003bee:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003bf0:	fec40593          	addi	a1,s0,-20
    80003bf4:	4501                	li	a0,0
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	d3a080e7          	jalr	-710(ra) # 80003930 <argint>
    80003bfe:	87aa                	mv	a5,a0
    return -1;
    80003c00:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003c02:	0007c863          	bltz	a5,80003c12 <sys_kill+0x2a>
  return kill(pid);
    80003c06:	fec42503          	lw	a0,-20(s0)
    80003c0a:	fffff097          	auipc	ra,0xfffff
    80003c0e:	626080e7          	jalr	1574(ra) # 80003230 <kill>
}
    80003c12:	60e2                	ld	ra,24(sp)
    80003c14:	6442                	ld	s0,16(sp)
    80003c16:	6105                	addi	sp,sp,32
    80003c18:	8082                	ret

0000000080003c1a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003c1a:	1101                	addi	sp,sp,-32
    80003c1c:	ec06                	sd	ra,24(sp)
    80003c1e:	e822                	sd	s0,16(sp)
    80003c20:	e426                	sd	s1,8(sp)
    80003c22:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003c24:	00015517          	auipc	a0,0x15
    80003c28:	dbc50513          	addi	a0,a0,-580 # 800189e0 <tickslock>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	fc0080e7          	jalr	-64(ra) # 80000bec <acquire>
  xticks = ticks;
    80003c34:	00006497          	auipc	s1,0x6
    80003c38:	43c4a483          	lw	s1,1084(s1) # 8000a070 <ticks>
  release(&tickslock);
    80003c3c:	00015517          	auipc	a0,0x15
    80003c40:	da450513          	addi	a0,a0,-604 # 800189e0 <tickslock>
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	062080e7          	jalr	98(ra) # 80000ca6 <release>
  return xticks;
}
    80003c4c:	02049513          	slli	a0,s1,0x20
    80003c50:	9101                	srli	a0,a0,0x20
    80003c52:	60e2                	ld	ra,24(sp)
    80003c54:	6442                	ld	s0,16(sp)
    80003c56:	64a2                	ld	s1,8(sp)
    80003c58:	6105                	addi	sp,sp,32
    80003c5a:	8082                	ret

0000000080003c5c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003c5c:	7179                	addi	sp,sp,-48
    80003c5e:	f406                	sd	ra,40(sp)
    80003c60:	f022                	sd	s0,32(sp)
    80003c62:	ec26                	sd	s1,24(sp)
    80003c64:	e84a                	sd	s2,16(sp)
    80003c66:	e44e                	sd	s3,8(sp)
    80003c68:	e052                	sd	s4,0(sp)
    80003c6a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003c6c:	00006597          	auipc	a1,0x6
    80003c70:	a8458593          	addi	a1,a1,-1404 # 800096f0 <syscalls+0xc0>
    80003c74:	00015517          	auipc	a0,0x15
    80003c78:	d8450513          	addi	a0,a0,-636 # 800189f8 <bcache>
    80003c7c:	ffffd097          	auipc	ra,0xffffd
    80003c80:	ed8080e7          	jalr	-296(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003c84:	0001d797          	auipc	a5,0x1d
    80003c88:	d7478793          	addi	a5,a5,-652 # 800209f8 <bcache+0x8000>
    80003c8c:	0001d717          	auipc	a4,0x1d
    80003c90:	fd470713          	addi	a4,a4,-44 # 80020c60 <bcache+0x8268>
    80003c94:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003c98:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003c9c:	00015497          	auipc	s1,0x15
    80003ca0:	d7448493          	addi	s1,s1,-652 # 80018a10 <bcache+0x18>
    b->next = bcache.head.next;
    80003ca4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003ca6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003ca8:	00006a17          	auipc	s4,0x6
    80003cac:	a50a0a13          	addi	s4,s4,-1456 # 800096f8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003cb0:	2b893783          	ld	a5,696(s2)
    80003cb4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003cb6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003cba:	85d2                	mv	a1,s4
    80003cbc:	01048513          	addi	a0,s1,16
    80003cc0:	00001097          	auipc	ra,0x1
    80003cc4:	4bc080e7          	jalr	1212(ra) # 8000517c <initsleeplock>
    bcache.head.next->prev = b;
    80003cc8:	2b893783          	ld	a5,696(s2)
    80003ccc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003cce:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003cd2:	45848493          	addi	s1,s1,1112
    80003cd6:	fd349de3          	bne	s1,s3,80003cb0 <binit+0x54>
  }
}
    80003cda:	70a2                	ld	ra,40(sp)
    80003cdc:	7402                	ld	s0,32(sp)
    80003cde:	64e2                	ld	s1,24(sp)
    80003ce0:	6942                	ld	s2,16(sp)
    80003ce2:	69a2                	ld	s3,8(sp)
    80003ce4:	6a02                	ld	s4,0(sp)
    80003ce6:	6145                	addi	sp,sp,48
    80003ce8:	8082                	ret

0000000080003cea <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003cea:	7179                	addi	sp,sp,-48
    80003cec:	f406                	sd	ra,40(sp)
    80003cee:	f022                	sd	s0,32(sp)
    80003cf0:	ec26                	sd	s1,24(sp)
    80003cf2:	e84a                	sd	s2,16(sp)
    80003cf4:	e44e                	sd	s3,8(sp)
    80003cf6:	1800                	addi	s0,sp,48
    80003cf8:	89aa                	mv	s3,a0
    80003cfa:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003cfc:	00015517          	auipc	a0,0x15
    80003d00:	cfc50513          	addi	a0,a0,-772 # 800189f8 <bcache>
    80003d04:	ffffd097          	auipc	ra,0xffffd
    80003d08:	ee8080e7          	jalr	-280(ra) # 80000bec <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003d0c:	0001d497          	auipc	s1,0x1d
    80003d10:	fa44b483          	ld	s1,-92(s1) # 80020cb0 <bcache+0x82b8>
    80003d14:	0001d797          	auipc	a5,0x1d
    80003d18:	f4c78793          	addi	a5,a5,-180 # 80020c60 <bcache+0x8268>
    80003d1c:	02f48f63          	beq	s1,a5,80003d5a <bread+0x70>
    80003d20:	873e                	mv	a4,a5
    80003d22:	a021                	j	80003d2a <bread+0x40>
    80003d24:	68a4                	ld	s1,80(s1)
    80003d26:	02e48a63          	beq	s1,a4,80003d5a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003d2a:	449c                	lw	a5,8(s1)
    80003d2c:	ff379ce3          	bne	a5,s3,80003d24 <bread+0x3a>
    80003d30:	44dc                	lw	a5,12(s1)
    80003d32:	ff2799e3          	bne	a5,s2,80003d24 <bread+0x3a>
      b->refcnt++;
    80003d36:	40bc                	lw	a5,64(s1)
    80003d38:	2785                	addiw	a5,a5,1
    80003d3a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003d3c:	00015517          	auipc	a0,0x15
    80003d40:	cbc50513          	addi	a0,a0,-836 # 800189f8 <bcache>
    80003d44:	ffffd097          	auipc	ra,0xffffd
    80003d48:	f62080e7          	jalr	-158(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003d4c:	01048513          	addi	a0,s1,16
    80003d50:	00001097          	auipc	ra,0x1
    80003d54:	466080e7          	jalr	1126(ra) # 800051b6 <acquiresleep>
      return b;
    80003d58:	a8b9                	j	80003db6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003d5a:	0001d497          	auipc	s1,0x1d
    80003d5e:	f4e4b483          	ld	s1,-178(s1) # 80020ca8 <bcache+0x82b0>
    80003d62:	0001d797          	auipc	a5,0x1d
    80003d66:	efe78793          	addi	a5,a5,-258 # 80020c60 <bcache+0x8268>
    80003d6a:	00f48863          	beq	s1,a5,80003d7a <bread+0x90>
    80003d6e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003d70:	40bc                	lw	a5,64(s1)
    80003d72:	cf81                	beqz	a5,80003d8a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003d74:	64a4                	ld	s1,72(s1)
    80003d76:	fee49de3          	bne	s1,a4,80003d70 <bread+0x86>
  panic("bget: no buffers");
    80003d7a:	00006517          	auipc	a0,0x6
    80003d7e:	98650513          	addi	a0,a0,-1658 # 80009700 <syscalls+0xd0>
    80003d82:	ffffc097          	auipc	ra,0xffffc
    80003d86:	7bc080e7          	jalr	1980(ra) # 8000053e <panic>
      b->dev = dev;
    80003d8a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003d8e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003d92:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003d96:	4785                	li	a5,1
    80003d98:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003d9a:	00015517          	auipc	a0,0x15
    80003d9e:	c5e50513          	addi	a0,a0,-930 # 800189f8 <bcache>
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	f04080e7          	jalr	-252(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003daa:	01048513          	addi	a0,s1,16
    80003dae:	00001097          	auipc	ra,0x1
    80003db2:	408080e7          	jalr	1032(ra) # 800051b6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003db6:	409c                	lw	a5,0(s1)
    80003db8:	cb89                	beqz	a5,80003dca <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003dba:	8526                	mv	a0,s1
    80003dbc:	70a2                	ld	ra,40(sp)
    80003dbe:	7402                	ld	s0,32(sp)
    80003dc0:	64e2                	ld	s1,24(sp)
    80003dc2:	6942                	ld	s2,16(sp)
    80003dc4:	69a2                	ld	s3,8(sp)
    80003dc6:	6145                	addi	sp,sp,48
    80003dc8:	8082                	ret
    virtio_disk_rw(b, 0);
    80003dca:	4581                	li	a1,0
    80003dcc:	8526                	mv	a0,s1
    80003dce:	00003097          	auipc	ra,0x3
    80003dd2:	f08080e7          	jalr	-248(ra) # 80006cd6 <virtio_disk_rw>
    b->valid = 1;
    80003dd6:	4785                	li	a5,1
    80003dd8:	c09c                	sw	a5,0(s1)
  return b;
    80003dda:	b7c5                	j	80003dba <bread+0xd0>

0000000080003ddc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003ddc:	1101                	addi	sp,sp,-32
    80003dde:	ec06                	sd	ra,24(sp)
    80003de0:	e822                	sd	s0,16(sp)
    80003de2:	e426                	sd	s1,8(sp)
    80003de4:	1000                	addi	s0,sp,32
    80003de6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003de8:	0541                	addi	a0,a0,16
    80003dea:	00001097          	auipc	ra,0x1
    80003dee:	466080e7          	jalr	1126(ra) # 80005250 <holdingsleep>
    80003df2:	cd01                	beqz	a0,80003e0a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003df4:	4585                	li	a1,1
    80003df6:	8526                	mv	a0,s1
    80003df8:	00003097          	auipc	ra,0x3
    80003dfc:	ede080e7          	jalr	-290(ra) # 80006cd6 <virtio_disk_rw>
}
    80003e00:	60e2                	ld	ra,24(sp)
    80003e02:	6442                	ld	s0,16(sp)
    80003e04:	64a2                	ld	s1,8(sp)
    80003e06:	6105                	addi	sp,sp,32
    80003e08:	8082                	ret
    panic("bwrite");
    80003e0a:	00006517          	auipc	a0,0x6
    80003e0e:	90e50513          	addi	a0,a0,-1778 # 80009718 <syscalls+0xe8>
    80003e12:	ffffc097          	auipc	ra,0xffffc
    80003e16:	72c080e7          	jalr	1836(ra) # 8000053e <panic>

0000000080003e1a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003e1a:	1101                	addi	sp,sp,-32
    80003e1c:	ec06                	sd	ra,24(sp)
    80003e1e:	e822                	sd	s0,16(sp)
    80003e20:	e426                	sd	s1,8(sp)
    80003e22:	e04a                	sd	s2,0(sp)
    80003e24:	1000                	addi	s0,sp,32
    80003e26:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003e28:	01050913          	addi	s2,a0,16
    80003e2c:	854a                	mv	a0,s2
    80003e2e:	00001097          	auipc	ra,0x1
    80003e32:	422080e7          	jalr	1058(ra) # 80005250 <holdingsleep>
    80003e36:	c92d                	beqz	a0,80003ea8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003e38:	854a                	mv	a0,s2
    80003e3a:	00001097          	auipc	ra,0x1
    80003e3e:	3d2080e7          	jalr	978(ra) # 8000520c <releasesleep>

  acquire(&bcache.lock);
    80003e42:	00015517          	auipc	a0,0x15
    80003e46:	bb650513          	addi	a0,a0,-1098 # 800189f8 <bcache>
    80003e4a:	ffffd097          	auipc	ra,0xffffd
    80003e4e:	da2080e7          	jalr	-606(ra) # 80000bec <acquire>
  b->refcnt--;
    80003e52:	40bc                	lw	a5,64(s1)
    80003e54:	37fd                	addiw	a5,a5,-1
    80003e56:	0007871b          	sext.w	a4,a5
    80003e5a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003e5c:	eb05                	bnez	a4,80003e8c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003e5e:	68bc                	ld	a5,80(s1)
    80003e60:	64b8                	ld	a4,72(s1)
    80003e62:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003e64:	64bc                	ld	a5,72(s1)
    80003e66:	68b8                	ld	a4,80(s1)
    80003e68:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003e6a:	0001d797          	auipc	a5,0x1d
    80003e6e:	b8e78793          	addi	a5,a5,-1138 # 800209f8 <bcache+0x8000>
    80003e72:	2b87b703          	ld	a4,696(a5)
    80003e76:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003e78:	0001d717          	auipc	a4,0x1d
    80003e7c:	de870713          	addi	a4,a4,-536 # 80020c60 <bcache+0x8268>
    80003e80:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003e82:	2b87b703          	ld	a4,696(a5)
    80003e86:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003e88:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003e8c:	00015517          	auipc	a0,0x15
    80003e90:	b6c50513          	addi	a0,a0,-1172 # 800189f8 <bcache>
    80003e94:	ffffd097          	auipc	ra,0xffffd
    80003e98:	e12080e7          	jalr	-494(ra) # 80000ca6 <release>
}
    80003e9c:	60e2                	ld	ra,24(sp)
    80003e9e:	6442                	ld	s0,16(sp)
    80003ea0:	64a2                	ld	s1,8(sp)
    80003ea2:	6902                	ld	s2,0(sp)
    80003ea4:	6105                	addi	sp,sp,32
    80003ea6:	8082                	ret
    panic("brelse");
    80003ea8:	00006517          	auipc	a0,0x6
    80003eac:	87850513          	addi	a0,a0,-1928 # 80009720 <syscalls+0xf0>
    80003eb0:	ffffc097          	auipc	ra,0xffffc
    80003eb4:	68e080e7          	jalr	1678(ra) # 8000053e <panic>

0000000080003eb8 <bpin>:

void
bpin(struct buf *b) {
    80003eb8:	1101                	addi	sp,sp,-32
    80003eba:	ec06                	sd	ra,24(sp)
    80003ebc:	e822                	sd	s0,16(sp)
    80003ebe:	e426                	sd	s1,8(sp)
    80003ec0:	1000                	addi	s0,sp,32
    80003ec2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003ec4:	00015517          	auipc	a0,0x15
    80003ec8:	b3450513          	addi	a0,a0,-1228 # 800189f8 <bcache>
    80003ecc:	ffffd097          	auipc	ra,0xffffd
    80003ed0:	d20080e7          	jalr	-736(ra) # 80000bec <acquire>
  b->refcnt++;
    80003ed4:	40bc                	lw	a5,64(s1)
    80003ed6:	2785                	addiw	a5,a5,1
    80003ed8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003eda:	00015517          	auipc	a0,0x15
    80003ede:	b1e50513          	addi	a0,a0,-1250 # 800189f8 <bcache>
    80003ee2:	ffffd097          	auipc	ra,0xffffd
    80003ee6:	dc4080e7          	jalr	-572(ra) # 80000ca6 <release>
}
    80003eea:	60e2                	ld	ra,24(sp)
    80003eec:	6442                	ld	s0,16(sp)
    80003eee:	64a2                	ld	s1,8(sp)
    80003ef0:	6105                	addi	sp,sp,32
    80003ef2:	8082                	ret

0000000080003ef4 <bunpin>:

void
bunpin(struct buf *b) {
    80003ef4:	1101                	addi	sp,sp,-32
    80003ef6:	ec06                	sd	ra,24(sp)
    80003ef8:	e822                	sd	s0,16(sp)
    80003efa:	e426                	sd	s1,8(sp)
    80003efc:	1000                	addi	s0,sp,32
    80003efe:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003f00:	00015517          	auipc	a0,0x15
    80003f04:	af850513          	addi	a0,a0,-1288 # 800189f8 <bcache>
    80003f08:	ffffd097          	auipc	ra,0xffffd
    80003f0c:	ce4080e7          	jalr	-796(ra) # 80000bec <acquire>
  b->refcnt--;
    80003f10:	40bc                	lw	a5,64(s1)
    80003f12:	37fd                	addiw	a5,a5,-1
    80003f14:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003f16:	00015517          	auipc	a0,0x15
    80003f1a:	ae250513          	addi	a0,a0,-1310 # 800189f8 <bcache>
    80003f1e:	ffffd097          	auipc	ra,0xffffd
    80003f22:	d88080e7          	jalr	-632(ra) # 80000ca6 <release>
}
    80003f26:	60e2                	ld	ra,24(sp)
    80003f28:	6442                	ld	s0,16(sp)
    80003f2a:	64a2                	ld	s1,8(sp)
    80003f2c:	6105                	addi	sp,sp,32
    80003f2e:	8082                	ret

0000000080003f30 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003f30:	1101                	addi	sp,sp,-32
    80003f32:	ec06                	sd	ra,24(sp)
    80003f34:	e822                	sd	s0,16(sp)
    80003f36:	e426                	sd	s1,8(sp)
    80003f38:	e04a                	sd	s2,0(sp)
    80003f3a:	1000                	addi	s0,sp,32
    80003f3c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003f3e:	00d5d59b          	srliw	a1,a1,0xd
    80003f42:	0001d797          	auipc	a5,0x1d
    80003f46:	1927a783          	lw	a5,402(a5) # 800210d4 <sb+0x1c>
    80003f4a:	9dbd                	addw	a1,a1,a5
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	d9e080e7          	jalr	-610(ra) # 80003cea <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003f54:	0074f713          	andi	a4,s1,7
    80003f58:	4785                	li	a5,1
    80003f5a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003f5e:	14ce                	slli	s1,s1,0x33
    80003f60:	90d9                	srli	s1,s1,0x36
    80003f62:	00950733          	add	a4,a0,s1
    80003f66:	05874703          	lbu	a4,88(a4)
    80003f6a:	00e7f6b3          	and	a3,a5,a4
    80003f6e:	c69d                	beqz	a3,80003f9c <bfree+0x6c>
    80003f70:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003f72:	94aa                	add	s1,s1,a0
    80003f74:	fff7c793          	not	a5,a5
    80003f78:	8ff9                	and	a5,a5,a4
    80003f7a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003f7e:	00001097          	auipc	ra,0x1
    80003f82:	118080e7          	jalr	280(ra) # 80005096 <log_write>
  brelse(bp);
    80003f86:	854a                	mv	a0,s2
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	e92080e7          	jalr	-366(ra) # 80003e1a <brelse>
}
    80003f90:	60e2                	ld	ra,24(sp)
    80003f92:	6442                	ld	s0,16(sp)
    80003f94:	64a2                	ld	s1,8(sp)
    80003f96:	6902                	ld	s2,0(sp)
    80003f98:	6105                	addi	sp,sp,32
    80003f9a:	8082                	ret
    panic("freeing free block");
    80003f9c:	00005517          	auipc	a0,0x5
    80003fa0:	78c50513          	addi	a0,a0,1932 # 80009728 <syscalls+0xf8>
    80003fa4:	ffffc097          	auipc	ra,0xffffc
    80003fa8:	59a080e7          	jalr	1434(ra) # 8000053e <panic>

0000000080003fac <balloc>:
{
    80003fac:	711d                	addi	sp,sp,-96
    80003fae:	ec86                	sd	ra,88(sp)
    80003fb0:	e8a2                	sd	s0,80(sp)
    80003fb2:	e4a6                	sd	s1,72(sp)
    80003fb4:	e0ca                	sd	s2,64(sp)
    80003fb6:	fc4e                	sd	s3,56(sp)
    80003fb8:	f852                	sd	s4,48(sp)
    80003fba:	f456                	sd	s5,40(sp)
    80003fbc:	f05a                	sd	s6,32(sp)
    80003fbe:	ec5e                	sd	s7,24(sp)
    80003fc0:	e862                	sd	s8,16(sp)
    80003fc2:	e466                	sd	s9,8(sp)
    80003fc4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003fc6:	0001d797          	auipc	a5,0x1d
    80003fca:	0f67a783          	lw	a5,246(a5) # 800210bc <sb+0x4>
    80003fce:	cbd1                	beqz	a5,80004062 <balloc+0xb6>
    80003fd0:	8baa                	mv	s7,a0
    80003fd2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003fd4:	0001db17          	auipc	s6,0x1d
    80003fd8:	0e4b0b13          	addi	s6,s6,228 # 800210b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003fdc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003fde:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003fe0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003fe2:	6c89                	lui	s9,0x2
    80003fe4:	a831                	j	80004000 <balloc+0x54>
    brelse(bp);
    80003fe6:	854a                	mv	a0,s2
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	e32080e7          	jalr	-462(ra) # 80003e1a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003ff0:	015c87bb          	addw	a5,s9,s5
    80003ff4:	00078a9b          	sext.w	s5,a5
    80003ff8:	004b2703          	lw	a4,4(s6)
    80003ffc:	06eaf363          	bgeu	s5,a4,80004062 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80004000:	41fad79b          	sraiw	a5,s5,0x1f
    80004004:	0137d79b          	srliw	a5,a5,0x13
    80004008:	015787bb          	addw	a5,a5,s5
    8000400c:	40d7d79b          	sraiw	a5,a5,0xd
    80004010:	01cb2583          	lw	a1,28(s6)
    80004014:	9dbd                	addw	a1,a1,a5
    80004016:	855e                	mv	a0,s7
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	cd2080e7          	jalr	-814(ra) # 80003cea <bread>
    80004020:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004022:	004b2503          	lw	a0,4(s6)
    80004026:	000a849b          	sext.w	s1,s5
    8000402a:	8662                	mv	a2,s8
    8000402c:	faa4fde3          	bgeu	s1,a0,80003fe6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80004030:	41f6579b          	sraiw	a5,a2,0x1f
    80004034:	01d7d69b          	srliw	a3,a5,0x1d
    80004038:	00c6873b          	addw	a4,a3,a2
    8000403c:	00777793          	andi	a5,a4,7
    80004040:	9f95                	subw	a5,a5,a3
    80004042:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004046:	4037571b          	sraiw	a4,a4,0x3
    8000404a:	00e906b3          	add	a3,s2,a4
    8000404e:	0586c683          	lbu	a3,88(a3)
    80004052:	00d7f5b3          	and	a1,a5,a3
    80004056:	cd91                	beqz	a1,80004072 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004058:	2605                	addiw	a2,a2,1
    8000405a:	2485                	addiw	s1,s1,1
    8000405c:	fd4618e3          	bne	a2,s4,8000402c <balloc+0x80>
    80004060:	b759                	j	80003fe6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80004062:	00005517          	auipc	a0,0x5
    80004066:	6de50513          	addi	a0,a0,1758 # 80009740 <syscalls+0x110>
    8000406a:	ffffc097          	auipc	ra,0xffffc
    8000406e:	4d4080e7          	jalr	1236(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80004072:	974a                	add	a4,a4,s2
    80004074:	8fd5                	or	a5,a5,a3
    80004076:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000407a:	854a                	mv	a0,s2
    8000407c:	00001097          	auipc	ra,0x1
    80004080:	01a080e7          	jalr	26(ra) # 80005096 <log_write>
        brelse(bp);
    80004084:	854a                	mv	a0,s2
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	d94080e7          	jalr	-620(ra) # 80003e1a <brelse>
  bp = bread(dev, bno);
    8000408e:	85a6                	mv	a1,s1
    80004090:	855e                	mv	a0,s7
    80004092:	00000097          	auipc	ra,0x0
    80004096:	c58080e7          	jalr	-936(ra) # 80003cea <bread>
    8000409a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000409c:	40000613          	li	a2,1024
    800040a0:	4581                	li	a1,0
    800040a2:	05850513          	addi	a0,a0,88
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	c48080e7          	jalr	-952(ra) # 80000cee <memset>
  log_write(bp);
    800040ae:	854a                	mv	a0,s2
    800040b0:	00001097          	auipc	ra,0x1
    800040b4:	fe6080e7          	jalr	-26(ra) # 80005096 <log_write>
  brelse(bp);
    800040b8:	854a                	mv	a0,s2
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	d60080e7          	jalr	-672(ra) # 80003e1a <brelse>
}
    800040c2:	8526                	mv	a0,s1
    800040c4:	60e6                	ld	ra,88(sp)
    800040c6:	6446                	ld	s0,80(sp)
    800040c8:	64a6                	ld	s1,72(sp)
    800040ca:	6906                	ld	s2,64(sp)
    800040cc:	79e2                	ld	s3,56(sp)
    800040ce:	7a42                	ld	s4,48(sp)
    800040d0:	7aa2                	ld	s5,40(sp)
    800040d2:	7b02                	ld	s6,32(sp)
    800040d4:	6be2                	ld	s7,24(sp)
    800040d6:	6c42                	ld	s8,16(sp)
    800040d8:	6ca2                	ld	s9,8(sp)
    800040da:	6125                	addi	sp,sp,96
    800040dc:	8082                	ret

00000000800040de <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800040de:	7179                	addi	sp,sp,-48
    800040e0:	f406                	sd	ra,40(sp)
    800040e2:	f022                	sd	s0,32(sp)
    800040e4:	ec26                	sd	s1,24(sp)
    800040e6:	e84a                	sd	s2,16(sp)
    800040e8:	e44e                	sd	s3,8(sp)
    800040ea:	e052                	sd	s4,0(sp)
    800040ec:	1800                	addi	s0,sp,48
    800040ee:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800040f0:	47ad                	li	a5,11
    800040f2:	04b7fe63          	bgeu	a5,a1,8000414e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800040f6:	ff45849b          	addiw	s1,a1,-12
    800040fa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800040fe:	0ff00793          	li	a5,255
    80004102:	0ae7e363          	bltu	a5,a4,800041a8 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80004106:	08052583          	lw	a1,128(a0)
    8000410a:	c5ad                	beqz	a1,80004174 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000410c:	00092503          	lw	a0,0(s2)
    80004110:	00000097          	auipc	ra,0x0
    80004114:	bda080e7          	jalr	-1062(ra) # 80003cea <bread>
    80004118:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000411a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000411e:	02049593          	slli	a1,s1,0x20
    80004122:	9181                	srli	a1,a1,0x20
    80004124:	058a                	slli	a1,a1,0x2
    80004126:	00b784b3          	add	s1,a5,a1
    8000412a:	0004a983          	lw	s3,0(s1)
    8000412e:	04098d63          	beqz	s3,80004188 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80004132:	8552                	mv	a0,s4
    80004134:	00000097          	auipc	ra,0x0
    80004138:	ce6080e7          	jalr	-794(ra) # 80003e1a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000413c:	854e                	mv	a0,s3
    8000413e:	70a2                	ld	ra,40(sp)
    80004140:	7402                	ld	s0,32(sp)
    80004142:	64e2                	ld	s1,24(sp)
    80004144:	6942                	ld	s2,16(sp)
    80004146:	69a2                	ld	s3,8(sp)
    80004148:	6a02                	ld	s4,0(sp)
    8000414a:	6145                	addi	sp,sp,48
    8000414c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000414e:	02059493          	slli	s1,a1,0x20
    80004152:	9081                	srli	s1,s1,0x20
    80004154:	048a                	slli	s1,s1,0x2
    80004156:	94aa                	add	s1,s1,a0
    80004158:	0504a983          	lw	s3,80(s1)
    8000415c:	fe0990e3          	bnez	s3,8000413c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80004160:	4108                	lw	a0,0(a0)
    80004162:	00000097          	auipc	ra,0x0
    80004166:	e4a080e7          	jalr	-438(ra) # 80003fac <balloc>
    8000416a:	0005099b          	sext.w	s3,a0
    8000416e:	0534a823          	sw	s3,80(s1)
    80004172:	b7e9                	j	8000413c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80004174:	4108                	lw	a0,0(a0)
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	e36080e7          	jalr	-458(ra) # 80003fac <balloc>
    8000417e:	0005059b          	sext.w	a1,a0
    80004182:	08b92023          	sw	a1,128(s2)
    80004186:	b759                	j	8000410c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80004188:	00092503          	lw	a0,0(s2)
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	e20080e7          	jalr	-480(ra) # 80003fac <balloc>
    80004194:	0005099b          	sext.w	s3,a0
    80004198:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000419c:	8552                	mv	a0,s4
    8000419e:	00001097          	auipc	ra,0x1
    800041a2:	ef8080e7          	jalr	-264(ra) # 80005096 <log_write>
    800041a6:	b771                	j	80004132 <bmap+0x54>
  panic("bmap: out of range");
    800041a8:	00005517          	auipc	a0,0x5
    800041ac:	5b050513          	addi	a0,a0,1456 # 80009758 <syscalls+0x128>
    800041b0:	ffffc097          	auipc	ra,0xffffc
    800041b4:	38e080e7          	jalr	910(ra) # 8000053e <panic>

00000000800041b8 <iget>:
{
    800041b8:	7179                	addi	sp,sp,-48
    800041ba:	f406                	sd	ra,40(sp)
    800041bc:	f022                	sd	s0,32(sp)
    800041be:	ec26                	sd	s1,24(sp)
    800041c0:	e84a                	sd	s2,16(sp)
    800041c2:	e44e                	sd	s3,8(sp)
    800041c4:	e052                	sd	s4,0(sp)
    800041c6:	1800                	addi	s0,sp,48
    800041c8:	89aa                	mv	s3,a0
    800041ca:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800041cc:	0001d517          	auipc	a0,0x1d
    800041d0:	f0c50513          	addi	a0,a0,-244 # 800210d8 <itable>
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	a18080e7          	jalr	-1512(ra) # 80000bec <acquire>
  empty = 0;
    800041dc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800041de:	0001d497          	auipc	s1,0x1d
    800041e2:	f1248493          	addi	s1,s1,-238 # 800210f0 <itable+0x18>
    800041e6:	0001f697          	auipc	a3,0x1f
    800041ea:	99a68693          	addi	a3,a3,-1638 # 80022b80 <log>
    800041ee:	a039                	j	800041fc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800041f0:	02090b63          	beqz	s2,80004226 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800041f4:	08848493          	addi	s1,s1,136
    800041f8:	02d48a63          	beq	s1,a3,8000422c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800041fc:	449c                	lw	a5,8(s1)
    800041fe:	fef059e3          	blez	a5,800041f0 <iget+0x38>
    80004202:	4098                	lw	a4,0(s1)
    80004204:	ff3716e3          	bne	a4,s3,800041f0 <iget+0x38>
    80004208:	40d8                	lw	a4,4(s1)
    8000420a:	ff4713e3          	bne	a4,s4,800041f0 <iget+0x38>
      ip->ref++;
    8000420e:	2785                	addiw	a5,a5,1
    80004210:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004212:	0001d517          	auipc	a0,0x1d
    80004216:	ec650513          	addi	a0,a0,-314 # 800210d8 <itable>
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	a8c080e7          	jalr	-1396(ra) # 80000ca6 <release>
      return ip;
    80004222:	8926                	mv	s2,s1
    80004224:	a03d                	j	80004252 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004226:	f7f9                	bnez	a5,800041f4 <iget+0x3c>
    80004228:	8926                	mv	s2,s1
    8000422a:	b7e9                	j	800041f4 <iget+0x3c>
  if(empty == 0)
    8000422c:	02090c63          	beqz	s2,80004264 <iget+0xac>
  ip->dev = dev;
    80004230:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004234:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004238:	4785                	li	a5,1
    8000423a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000423e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004242:	0001d517          	auipc	a0,0x1d
    80004246:	e9650513          	addi	a0,a0,-362 # 800210d8 <itable>
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	a5c080e7          	jalr	-1444(ra) # 80000ca6 <release>
}
    80004252:	854a                	mv	a0,s2
    80004254:	70a2                	ld	ra,40(sp)
    80004256:	7402                	ld	s0,32(sp)
    80004258:	64e2                	ld	s1,24(sp)
    8000425a:	6942                	ld	s2,16(sp)
    8000425c:	69a2                	ld	s3,8(sp)
    8000425e:	6a02                	ld	s4,0(sp)
    80004260:	6145                	addi	sp,sp,48
    80004262:	8082                	ret
    panic("iget: no inodes");
    80004264:	00005517          	auipc	a0,0x5
    80004268:	50c50513          	addi	a0,a0,1292 # 80009770 <syscalls+0x140>
    8000426c:	ffffc097          	auipc	ra,0xffffc
    80004270:	2d2080e7          	jalr	722(ra) # 8000053e <panic>

0000000080004274 <fsinit>:
fsinit(int dev) {
    80004274:	7179                	addi	sp,sp,-48
    80004276:	f406                	sd	ra,40(sp)
    80004278:	f022                	sd	s0,32(sp)
    8000427a:	ec26                	sd	s1,24(sp)
    8000427c:	e84a                	sd	s2,16(sp)
    8000427e:	e44e                	sd	s3,8(sp)
    80004280:	1800                	addi	s0,sp,48
    80004282:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004284:	4585                	li	a1,1
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	a64080e7          	jalr	-1436(ra) # 80003cea <bread>
    8000428e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004290:	0001d997          	auipc	s3,0x1d
    80004294:	e2898993          	addi	s3,s3,-472 # 800210b8 <sb>
    80004298:	02000613          	li	a2,32
    8000429c:	05850593          	addi	a1,a0,88
    800042a0:	854e                	mv	a0,s3
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	aac080e7          	jalr	-1364(ra) # 80000d4e <memmove>
  brelse(bp);
    800042aa:	8526                	mv	a0,s1
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	b6e080e7          	jalr	-1170(ra) # 80003e1a <brelse>
  if(sb.magic != FSMAGIC)
    800042b4:	0009a703          	lw	a4,0(s3)
    800042b8:	102037b7          	lui	a5,0x10203
    800042bc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800042c0:	02f71263          	bne	a4,a5,800042e4 <fsinit+0x70>
  initlog(dev, &sb);
    800042c4:	0001d597          	auipc	a1,0x1d
    800042c8:	df458593          	addi	a1,a1,-524 # 800210b8 <sb>
    800042cc:	854a                	mv	a0,s2
    800042ce:	00001097          	auipc	ra,0x1
    800042d2:	b4c080e7          	jalr	-1204(ra) # 80004e1a <initlog>
}
    800042d6:	70a2                	ld	ra,40(sp)
    800042d8:	7402                	ld	s0,32(sp)
    800042da:	64e2                	ld	s1,24(sp)
    800042dc:	6942                	ld	s2,16(sp)
    800042de:	69a2                	ld	s3,8(sp)
    800042e0:	6145                	addi	sp,sp,48
    800042e2:	8082                	ret
    panic("invalid file system");
    800042e4:	00005517          	auipc	a0,0x5
    800042e8:	49c50513          	addi	a0,a0,1180 # 80009780 <syscalls+0x150>
    800042ec:	ffffc097          	auipc	ra,0xffffc
    800042f0:	252080e7          	jalr	594(ra) # 8000053e <panic>

00000000800042f4 <iinit>:
{
    800042f4:	7179                	addi	sp,sp,-48
    800042f6:	f406                	sd	ra,40(sp)
    800042f8:	f022                	sd	s0,32(sp)
    800042fa:	ec26                	sd	s1,24(sp)
    800042fc:	e84a                	sd	s2,16(sp)
    800042fe:	e44e                	sd	s3,8(sp)
    80004300:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004302:	00005597          	auipc	a1,0x5
    80004306:	49658593          	addi	a1,a1,1174 # 80009798 <syscalls+0x168>
    8000430a:	0001d517          	auipc	a0,0x1d
    8000430e:	dce50513          	addi	a0,a0,-562 # 800210d8 <itable>
    80004312:	ffffd097          	auipc	ra,0xffffd
    80004316:	842080e7          	jalr	-1982(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000431a:	0001d497          	auipc	s1,0x1d
    8000431e:	de648493          	addi	s1,s1,-538 # 80021100 <itable+0x28>
    80004322:	0001f997          	auipc	s3,0x1f
    80004326:	86e98993          	addi	s3,s3,-1938 # 80022b90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000432a:	00005917          	auipc	s2,0x5
    8000432e:	47690913          	addi	s2,s2,1142 # 800097a0 <syscalls+0x170>
    80004332:	85ca                	mv	a1,s2
    80004334:	8526                	mv	a0,s1
    80004336:	00001097          	auipc	ra,0x1
    8000433a:	e46080e7          	jalr	-442(ra) # 8000517c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000433e:	08848493          	addi	s1,s1,136
    80004342:	ff3498e3          	bne	s1,s3,80004332 <iinit+0x3e>
}
    80004346:	70a2                	ld	ra,40(sp)
    80004348:	7402                	ld	s0,32(sp)
    8000434a:	64e2                	ld	s1,24(sp)
    8000434c:	6942                	ld	s2,16(sp)
    8000434e:	69a2                	ld	s3,8(sp)
    80004350:	6145                	addi	sp,sp,48
    80004352:	8082                	ret

0000000080004354 <ialloc>:
{
    80004354:	715d                	addi	sp,sp,-80
    80004356:	e486                	sd	ra,72(sp)
    80004358:	e0a2                	sd	s0,64(sp)
    8000435a:	fc26                	sd	s1,56(sp)
    8000435c:	f84a                	sd	s2,48(sp)
    8000435e:	f44e                	sd	s3,40(sp)
    80004360:	f052                	sd	s4,32(sp)
    80004362:	ec56                	sd	s5,24(sp)
    80004364:	e85a                	sd	s6,16(sp)
    80004366:	e45e                	sd	s7,8(sp)
    80004368:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000436a:	0001d717          	auipc	a4,0x1d
    8000436e:	d5a72703          	lw	a4,-678(a4) # 800210c4 <sb+0xc>
    80004372:	4785                	li	a5,1
    80004374:	04e7fa63          	bgeu	a5,a4,800043c8 <ialloc+0x74>
    80004378:	8aaa                	mv	s5,a0
    8000437a:	8bae                	mv	s7,a1
    8000437c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000437e:	0001da17          	auipc	s4,0x1d
    80004382:	d3aa0a13          	addi	s4,s4,-710 # 800210b8 <sb>
    80004386:	00048b1b          	sext.w	s6,s1
    8000438a:	0044d593          	srli	a1,s1,0x4
    8000438e:	018a2783          	lw	a5,24(s4)
    80004392:	9dbd                	addw	a1,a1,a5
    80004394:	8556                	mv	a0,s5
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	954080e7          	jalr	-1708(ra) # 80003cea <bread>
    8000439e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800043a0:	05850993          	addi	s3,a0,88
    800043a4:	00f4f793          	andi	a5,s1,15
    800043a8:	079a                	slli	a5,a5,0x6
    800043aa:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800043ac:	00099783          	lh	a5,0(s3)
    800043b0:	c785                	beqz	a5,800043d8 <ialloc+0x84>
    brelse(bp);
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	a68080e7          	jalr	-1432(ra) # 80003e1a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800043ba:	0485                	addi	s1,s1,1
    800043bc:	00ca2703          	lw	a4,12(s4)
    800043c0:	0004879b          	sext.w	a5,s1
    800043c4:	fce7e1e3          	bltu	a5,a4,80004386 <ialloc+0x32>
  panic("ialloc: no inodes");
    800043c8:	00005517          	auipc	a0,0x5
    800043cc:	3e050513          	addi	a0,a0,992 # 800097a8 <syscalls+0x178>
    800043d0:	ffffc097          	auipc	ra,0xffffc
    800043d4:	16e080e7          	jalr	366(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800043d8:	04000613          	li	a2,64
    800043dc:	4581                	li	a1,0
    800043de:	854e                	mv	a0,s3
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	90e080e7          	jalr	-1778(ra) # 80000cee <memset>
      dip->type = type;
    800043e8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800043ec:	854a                	mv	a0,s2
    800043ee:	00001097          	auipc	ra,0x1
    800043f2:	ca8080e7          	jalr	-856(ra) # 80005096 <log_write>
      brelse(bp);
    800043f6:	854a                	mv	a0,s2
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	a22080e7          	jalr	-1502(ra) # 80003e1a <brelse>
      return iget(dev, inum);
    80004400:	85da                	mv	a1,s6
    80004402:	8556                	mv	a0,s5
    80004404:	00000097          	auipc	ra,0x0
    80004408:	db4080e7          	jalr	-588(ra) # 800041b8 <iget>
}
    8000440c:	60a6                	ld	ra,72(sp)
    8000440e:	6406                	ld	s0,64(sp)
    80004410:	74e2                	ld	s1,56(sp)
    80004412:	7942                	ld	s2,48(sp)
    80004414:	79a2                	ld	s3,40(sp)
    80004416:	7a02                	ld	s4,32(sp)
    80004418:	6ae2                	ld	s5,24(sp)
    8000441a:	6b42                	ld	s6,16(sp)
    8000441c:	6ba2                	ld	s7,8(sp)
    8000441e:	6161                	addi	sp,sp,80
    80004420:	8082                	ret

0000000080004422 <iupdate>:
{
    80004422:	1101                	addi	sp,sp,-32
    80004424:	ec06                	sd	ra,24(sp)
    80004426:	e822                	sd	s0,16(sp)
    80004428:	e426                	sd	s1,8(sp)
    8000442a:	e04a                	sd	s2,0(sp)
    8000442c:	1000                	addi	s0,sp,32
    8000442e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004430:	415c                	lw	a5,4(a0)
    80004432:	0047d79b          	srliw	a5,a5,0x4
    80004436:	0001d597          	auipc	a1,0x1d
    8000443a:	c9a5a583          	lw	a1,-870(a1) # 800210d0 <sb+0x18>
    8000443e:	9dbd                	addw	a1,a1,a5
    80004440:	4108                	lw	a0,0(a0)
    80004442:	00000097          	auipc	ra,0x0
    80004446:	8a8080e7          	jalr	-1880(ra) # 80003cea <bread>
    8000444a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000444c:	05850793          	addi	a5,a0,88
    80004450:	40c8                	lw	a0,4(s1)
    80004452:	893d                	andi	a0,a0,15
    80004454:	051a                	slli	a0,a0,0x6
    80004456:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004458:	04449703          	lh	a4,68(s1)
    8000445c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004460:	04649703          	lh	a4,70(s1)
    80004464:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004468:	04849703          	lh	a4,72(s1)
    8000446c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004470:	04a49703          	lh	a4,74(s1)
    80004474:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004478:	44f8                	lw	a4,76(s1)
    8000447a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000447c:	03400613          	li	a2,52
    80004480:	05048593          	addi	a1,s1,80
    80004484:	0531                	addi	a0,a0,12
    80004486:	ffffd097          	auipc	ra,0xffffd
    8000448a:	8c8080e7          	jalr	-1848(ra) # 80000d4e <memmove>
  log_write(bp);
    8000448e:	854a                	mv	a0,s2
    80004490:	00001097          	auipc	ra,0x1
    80004494:	c06080e7          	jalr	-1018(ra) # 80005096 <log_write>
  brelse(bp);
    80004498:	854a                	mv	a0,s2
    8000449a:	00000097          	auipc	ra,0x0
    8000449e:	980080e7          	jalr	-1664(ra) # 80003e1a <brelse>
}
    800044a2:	60e2                	ld	ra,24(sp)
    800044a4:	6442                	ld	s0,16(sp)
    800044a6:	64a2                	ld	s1,8(sp)
    800044a8:	6902                	ld	s2,0(sp)
    800044aa:	6105                	addi	sp,sp,32
    800044ac:	8082                	ret

00000000800044ae <idup>:
{
    800044ae:	1101                	addi	sp,sp,-32
    800044b0:	ec06                	sd	ra,24(sp)
    800044b2:	e822                	sd	s0,16(sp)
    800044b4:	e426                	sd	s1,8(sp)
    800044b6:	1000                	addi	s0,sp,32
    800044b8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800044ba:	0001d517          	auipc	a0,0x1d
    800044be:	c1e50513          	addi	a0,a0,-994 # 800210d8 <itable>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	72a080e7          	jalr	1834(ra) # 80000bec <acquire>
  ip->ref++;
    800044ca:	449c                	lw	a5,8(s1)
    800044cc:	2785                	addiw	a5,a5,1
    800044ce:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800044d0:	0001d517          	auipc	a0,0x1d
    800044d4:	c0850513          	addi	a0,a0,-1016 # 800210d8 <itable>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	7ce080e7          	jalr	1998(ra) # 80000ca6 <release>
}
    800044e0:	8526                	mv	a0,s1
    800044e2:	60e2                	ld	ra,24(sp)
    800044e4:	6442                	ld	s0,16(sp)
    800044e6:	64a2                	ld	s1,8(sp)
    800044e8:	6105                	addi	sp,sp,32
    800044ea:	8082                	ret

00000000800044ec <ilock>:
{
    800044ec:	1101                	addi	sp,sp,-32
    800044ee:	ec06                	sd	ra,24(sp)
    800044f0:	e822                	sd	s0,16(sp)
    800044f2:	e426                	sd	s1,8(sp)
    800044f4:	e04a                	sd	s2,0(sp)
    800044f6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800044f8:	c115                	beqz	a0,8000451c <ilock+0x30>
    800044fa:	84aa                	mv	s1,a0
    800044fc:	451c                	lw	a5,8(a0)
    800044fe:	00f05f63          	blez	a5,8000451c <ilock+0x30>
  acquiresleep(&ip->lock);
    80004502:	0541                	addi	a0,a0,16
    80004504:	00001097          	auipc	ra,0x1
    80004508:	cb2080e7          	jalr	-846(ra) # 800051b6 <acquiresleep>
  if(ip->valid == 0){
    8000450c:	40bc                	lw	a5,64(s1)
    8000450e:	cf99                	beqz	a5,8000452c <ilock+0x40>
}
    80004510:	60e2                	ld	ra,24(sp)
    80004512:	6442                	ld	s0,16(sp)
    80004514:	64a2                	ld	s1,8(sp)
    80004516:	6902                	ld	s2,0(sp)
    80004518:	6105                	addi	sp,sp,32
    8000451a:	8082                	ret
    panic("ilock");
    8000451c:	00005517          	auipc	a0,0x5
    80004520:	2a450513          	addi	a0,a0,676 # 800097c0 <syscalls+0x190>
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	01a080e7          	jalr	26(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000452c:	40dc                	lw	a5,4(s1)
    8000452e:	0047d79b          	srliw	a5,a5,0x4
    80004532:	0001d597          	auipc	a1,0x1d
    80004536:	b9e5a583          	lw	a1,-1122(a1) # 800210d0 <sb+0x18>
    8000453a:	9dbd                	addw	a1,a1,a5
    8000453c:	4088                	lw	a0,0(s1)
    8000453e:	fffff097          	auipc	ra,0xfffff
    80004542:	7ac080e7          	jalr	1964(ra) # 80003cea <bread>
    80004546:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004548:	05850593          	addi	a1,a0,88
    8000454c:	40dc                	lw	a5,4(s1)
    8000454e:	8bbd                	andi	a5,a5,15
    80004550:	079a                	slli	a5,a5,0x6
    80004552:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004554:	00059783          	lh	a5,0(a1)
    80004558:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000455c:	00259783          	lh	a5,2(a1)
    80004560:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004564:	00459783          	lh	a5,4(a1)
    80004568:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000456c:	00659783          	lh	a5,6(a1)
    80004570:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004574:	459c                	lw	a5,8(a1)
    80004576:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004578:	03400613          	li	a2,52
    8000457c:	05b1                	addi	a1,a1,12
    8000457e:	05048513          	addi	a0,s1,80
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	7cc080e7          	jalr	1996(ra) # 80000d4e <memmove>
    brelse(bp);
    8000458a:	854a                	mv	a0,s2
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	88e080e7          	jalr	-1906(ra) # 80003e1a <brelse>
    ip->valid = 1;
    80004594:	4785                	li	a5,1
    80004596:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004598:	04449783          	lh	a5,68(s1)
    8000459c:	fbb5                	bnez	a5,80004510 <ilock+0x24>
      panic("ilock: no type");
    8000459e:	00005517          	auipc	a0,0x5
    800045a2:	22a50513          	addi	a0,a0,554 # 800097c8 <syscalls+0x198>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>

00000000800045ae <iunlock>:
{
    800045ae:	1101                	addi	sp,sp,-32
    800045b0:	ec06                	sd	ra,24(sp)
    800045b2:	e822                	sd	s0,16(sp)
    800045b4:	e426                	sd	s1,8(sp)
    800045b6:	e04a                	sd	s2,0(sp)
    800045b8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800045ba:	c905                	beqz	a0,800045ea <iunlock+0x3c>
    800045bc:	84aa                	mv	s1,a0
    800045be:	01050913          	addi	s2,a0,16
    800045c2:	854a                	mv	a0,s2
    800045c4:	00001097          	auipc	ra,0x1
    800045c8:	c8c080e7          	jalr	-884(ra) # 80005250 <holdingsleep>
    800045cc:	cd19                	beqz	a0,800045ea <iunlock+0x3c>
    800045ce:	449c                	lw	a5,8(s1)
    800045d0:	00f05d63          	blez	a5,800045ea <iunlock+0x3c>
  releasesleep(&ip->lock);
    800045d4:	854a                	mv	a0,s2
    800045d6:	00001097          	auipc	ra,0x1
    800045da:	c36080e7          	jalr	-970(ra) # 8000520c <releasesleep>
}
    800045de:	60e2                	ld	ra,24(sp)
    800045e0:	6442                	ld	s0,16(sp)
    800045e2:	64a2                	ld	s1,8(sp)
    800045e4:	6902                	ld	s2,0(sp)
    800045e6:	6105                	addi	sp,sp,32
    800045e8:	8082                	ret
    panic("iunlock");
    800045ea:	00005517          	auipc	a0,0x5
    800045ee:	1ee50513          	addi	a0,a0,494 # 800097d8 <syscalls+0x1a8>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	f4c080e7          	jalr	-180(ra) # 8000053e <panic>

00000000800045fa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800045fa:	7179                	addi	sp,sp,-48
    800045fc:	f406                	sd	ra,40(sp)
    800045fe:	f022                	sd	s0,32(sp)
    80004600:	ec26                	sd	s1,24(sp)
    80004602:	e84a                	sd	s2,16(sp)
    80004604:	e44e                	sd	s3,8(sp)
    80004606:	e052                	sd	s4,0(sp)
    80004608:	1800                	addi	s0,sp,48
    8000460a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000460c:	05050493          	addi	s1,a0,80
    80004610:	08050913          	addi	s2,a0,128
    80004614:	a021                	j	8000461c <itrunc+0x22>
    80004616:	0491                	addi	s1,s1,4
    80004618:	01248d63          	beq	s1,s2,80004632 <itrunc+0x38>
    if(ip->addrs[i]){
    8000461c:	408c                	lw	a1,0(s1)
    8000461e:	dde5                	beqz	a1,80004616 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004620:	0009a503          	lw	a0,0(s3)
    80004624:	00000097          	auipc	ra,0x0
    80004628:	90c080e7          	jalr	-1780(ra) # 80003f30 <bfree>
      ip->addrs[i] = 0;
    8000462c:	0004a023          	sw	zero,0(s1)
    80004630:	b7dd                	j	80004616 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004632:	0809a583          	lw	a1,128(s3)
    80004636:	e185                	bnez	a1,80004656 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004638:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000463c:	854e                	mv	a0,s3
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	de4080e7          	jalr	-540(ra) # 80004422 <iupdate>
}
    80004646:	70a2                	ld	ra,40(sp)
    80004648:	7402                	ld	s0,32(sp)
    8000464a:	64e2                	ld	s1,24(sp)
    8000464c:	6942                	ld	s2,16(sp)
    8000464e:	69a2                	ld	s3,8(sp)
    80004650:	6a02                	ld	s4,0(sp)
    80004652:	6145                	addi	sp,sp,48
    80004654:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004656:	0009a503          	lw	a0,0(s3)
    8000465a:	fffff097          	auipc	ra,0xfffff
    8000465e:	690080e7          	jalr	1680(ra) # 80003cea <bread>
    80004662:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004664:	05850493          	addi	s1,a0,88
    80004668:	45850913          	addi	s2,a0,1112
    8000466c:	a811                	j	80004680 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000466e:	0009a503          	lw	a0,0(s3)
    80004672:	00000097          	auipc	ra,0x0
    80004676:	8be080e7          	jalr	-1858(ra) # 80003f30 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000467a:	0491                	addi	s1,s1,4
    8000467c:	01248563          	beq	s1,s2,80004686 <itrunc+0x8c>
      if(a[j])
    80004680:	408c                	lw	a1,0(s1)
    80004682:	dde5                	beqz	a1,8000467a <itrunc+0x80>
    80004684:	b7ed                	j	8000466e <itrunc+0x74>
    brelse(bp);
    80004686:	8552                	mv	a0,s4
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	792080e7          	jalr	1938(ra) # 80003e1a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004690:	0809a583          	lw	a1,128(s3)
    80004694:	0009a503          	lw	a0,0(s3)
    80004698:	00000097          	auipc	ra,0x0
    8000469c:	898080e7          	jalr	-1896(ra) # 80003f30 <bfree>
    ip->addrs[NDIRECT] = 0;
    800046a0:	0809a023          	sw	zero,128(s3)
    800046a4:	bf51                	j	80004638 <itrunc+0x3e>

00000000800046a6 <iput>:
{
    800046a6:	1101                	addi	sp,sp,-32
    800046a8:	ec06                	sd	ra,24(sp)
    800046aa:	e822                	sd	s0,16(sp)
    800046ac:	e426                	sd	s1,8(sp)
    800046ae:	e04a                	sd	s2,0(sp)
    800046b0:	1000                	addi	s0,sp,32
    800046b2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800046b4:	0001d517          	auipc	a0,0x1d
    800046b8:	a2450513          	addi	a0,a0,-1500 # 800210d8 <itable>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	530080e7          	jalr	1328(ra) # 80000bec <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800046c4:	4498                	lw	a4,8(s1)
    800046c6:	4785                	li	a5,1
    800046c8:	02f70363          	beq	a4,a5,800046ee <iput+0x48>
  ip->ref--;
    800046cc:	449c                	lw	a5,8(s1)
    800046ce:	37fd                	addiw	a5,a5,-1
    800046d0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800046d2:	0001d517          	auipc	a0,0x1d
    800046d6:	a0650513          	addi	a0,a0,-1530 # 800210d8 <itable>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	5cc080e7          	jalr	1484(ra) # 80000ca6 <release>
}
    800046e2:	60e2                	ld	ra,24(sp)
    800046e4:	6442                	ld	s0,16(sp)
    800046e6:	64a2                	ld	s1,8(sp)
    800046e8:	6902                	ld	s2,0(sp)
    800046ea:	6105                	addi	sp,sp,32
    800046ec:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800046ee:	40bc                	lw	a5,64(s1)
    800046f0:	dff1                	beqz	a5,800046cc <iput+0x26>
    800046f2:	04a49783          	lh	a5,74(s1)
    800046f6:	fbf9                	bnez	a5,800046cc <iput+0x26>
    acquiresleep(&ip->lock);
    800046f8:	01048913          	addi	s2,s1,16
    800046fc:	854a                	mv	a0,s2
    800046fe:	00001097          	auipc	ra,0x1
    80004702:	ab8080e7          	jalr	-1352(ra) # 800051b6 <acquiresleep>
    release(&itable.lock);
    80004706:	0001d517          	auipc	a0,0x1d
    8000470a:	9d250513          	addi	a0,a0,-1582 # 800210d8 <itable>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	598080e7          	jalr	1432(ra) # 80000ca6 <release>
    itrunc(ip);
    80004716:	8526                	mv	a0,s1
    80004718:	00000097          	auipc	ra,0x0
    8000471c:	ee2080e7          	jalr	-286(ra) # 800045fa <itrunc>
    ip->type = 0;
    80004720:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004724:	8526                	mv	a0,s1
    80004726:	00000097          	auipc	ra,0x0
    8000472a:	cfc080e7          	jalr	-772(ra) # 80004422 <iupdate>
    ip->valid = 0;
    8000472e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004732:	854a                	mv	a0,s2
    80004734:	00001097          	auipc	ra,0x1
    80004738:	ad8080e7          	jalr	-1320(ra) # 8000520c <releasesleep>
    acquire(&itable.lock);
    8000473c:	0001d517          	auipc	a0,0x1d
    80004740:	99c50513          	addi	a0,a0,-1636 # 800210d8 <itable>
    80004744:	ffffc097          	auipc	ra,0xffffc
    80004748:	4a8080e7          	jalr	1192(ra) # 80000bec <acquire>
    8000474c:	b741                	j	800046cc <iput+0x26>

000000008000474e <iunlockput>:
{
    8000474e:	1101                	addi	sp,sp,-32
    80004750:	ec06                	sd	ra,24(sp)
    80004752:	e822                	sd	s0,16(sp)
    80004754:	e426                	sd	s1,8(sp)
    80004756:	1000                	addi	s0,sp,32
    80004758:	84aa                	mv	s1,a0
  iunlock(ip);
    8000475a:	00000097          	auipc	ra,0x0
    8000475e:	e54080e7          	jalr	-428(ra) # 800045ae <iunlock>
  iput(ip);
    80004762:	8526                	mv	a0,s1
    80004764:	00000097          	auipc	ra,0x0
    80004768:	f42080e7          	jalr	-190(ra) # 800046a6 <iput>
}
    8000476c:	60e2                	ld	ra,24(sp)
    8000476e:	6442                	ld	s0,16(sp)
    80004770:	64a2                	ld	s1,8(sp)
    80004772:	6105                	addi	sp,sp,32
    80004774:	8082                	ret

0000000080004776 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004776:	1141                	addi	sp,sp,-16
    80004778:	e422                	sd	s0,8(sp)
    8000477a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000477c:	411c                	lw	a5,0(a0)
    8000477e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004780:	415c                	lw	a5,4(a0)
    80004782:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004784:	04451783          	lh	a5,68(a0)
    80004788:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000478c:	04a51783          	lh	a5,74(a0)
    80004790:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004794:	04c56783          	lwu	a5,76(a0)
    80004798:	e99c                	sd	a5,16(a1)
}
    8000479a:	6422                	ld	s0,8(sp)
    8000479c:	0141                	addi	sp,sp,16
    8000479e:	8082                	ret

00000000800047a0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800047a0:	457c                	lw	a5,76(a0)
    800047a2:	0ed7e963          	bltu	a5,a3,80004894 <readi+0xf4>
{
    800047a6:	7159                	addi	sp,sp,-112
    800047a8:	f486                	sd	ra,104(sp)
    800047aa:	f0a2                	sd	s0,96(sp)
    800047ac:	eca6                	sd	s1,88(sp)
    800047ae:	e8ca                	sd	s2,80(sp)
    800047b0:	e4ce                	sd	s3,72(sp)
    800047b2:	e0d2                	sd	s4,64(sp)
    800047b4:	fc56                	sd	s5,56(sp)
    800047b6:	f85a                	sd	s6,48(sp)
    800047b8:	f45e                	sd	s7,40(sp)
    800047ba:	f062                	sd	s8,32(sp)
    800047bc:	ec66                	sd	s9,24(sp)
    800047be:	e86a                	sd	s10,16(sp)
    800047c0:	e46e                	sd	s11,8(sp)
    800047c2:	1880                	addi	s0,sp,112
    800047c4:	8baa                	mv	s7,a0
    800047c6:	8c2e                	mv	s8,a1
    800047c8:	8ab2                	mv	s5,a2
    800047ca:	84b6                	mv	s1,a3
    800047cc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800047ce:	9f35                	addw	a4,a4,a3
    return 0;
    800047d0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800047d2:	0ad76063          	bltu	a4,a3,80004872 <readi+0xd2>
  if(off + n > ip->size)
    800047d6:	00e7f463          	bgeu	a5,a4,800047de <readi+0x3e>
    n = ip->size - off;
    800047da:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800047de:	0a0b0963          	beqz	s6,80004890 <readi+0xf0>
    800047e2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800047e4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800047e8:	5cfd                	li	s9,-1
    800047ea:	a82d                	j	80004824 <readi+0x84>
    800047ec:	020a1d93          	slli	s11,s4,0x20
    800047f0:	020ddd93          	srli	s11,s11,0x20
    800047f4:	05890613          	addi	a2,s2,88
    800047f8:	86ee                	mv	a3,s11
    800047fa:	963a                	add	a2,a2,a4
    800047fc:	85d6                	mv	a1,s5
    800047fe:	8562                	mv	a0,s8
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	ae4080e7          	jalr	-1308(ra) # 800032e4 <either_copyout>
    80004808:	05950d63          	beq	a0,s9,80004862 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000480c:	854a                	mv	a0,s2
    8000480e:	fffff097          	auipc	ra,0xfffff
    80004812:	60c080e7          	jalr	1548(ra) # 80003e1a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004816:	013a09bb          	addw	s3,s4,s3
    8000481a:	009a04bb          	addw	s1,s4,s1
    8000481e:	9aee                	add	s5,s5,s11
    80004820:	0569f763          	bgeu	s3,s6,8000486e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004824:	000ba903          	lw	s2,0(s7)
    80004828:	00a4d59b          	srliw	a1,s1,0xa
    8000482c:	855e                	mv	a0,s7
    8000482e:	00000097          	auipc	ra,0x0
    80004832:	8b0080e7          	jalr	-1872(ra) # 800040de <bmap>
    80004836:	0005059b          	sext.w	a1,a0
    8000483a:	854a                	mv	a0,s2
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	4ae080e7          	jalr	1198(ra) # 80003cea <bread>
    80004844:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004846:	3ff4f713          	andi	a4,s1,1023
    8000484a:	40ed07bb          	subw	a5,s10,a4
    8000484e:	413b06bb          	subw	a3,s6,s3
    80004852:	8a3e                	mv	s4,a5
    80004854:	2781                	sext.w	a5,a5
    80004856:	0006861b          	sext.w	a2,a3
    8000485a:	f8f679e3          	bgeu	a2,a5,800047ec <readi+0x4c>
    8000485e:	8a36                	mv	s4,a3
    80004860:	b771                	j	800047ec <readi+0x4c>
      brelse(bp);
    80004862:	854a                	mv	a0,s2
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	5b6080e7          	jalr	1462(ra) # 80003e1a <brelse>
      tot = -1;
    8000486c:	59fd                	li	s3,-1
  }
  return tot;
    8000486e:	0009851b          	sext.w	a0,s3
}
    80004872:	70a6                	ld	ra,104(sp)
    80004874:	7406                	ld	s0,96(sp)
    80004876:	64e6                	ld	s1,88(sp)
    80004878:	6946                	ld	s2,80(sp)
    8000487a:	69a6                	ld	s3,72(sp)
    8000487c:	6a06                	ld	s4,64(sp)
    8000487e:	7ae2                	ld	s5,56(sp)
    80004880:	7b42                	ld	s6,48(sp)
    80004882:	7ba2                	ld	s7,40(sp)
    80004884:	7c02                	ld	s8,32(sp)
    80004886:	6ce2                	ld	s9,24(sp)
    80004888:	6d42                	ld	s10,16(sp)
    8000488a:	6da2                	ld	s11,8(sp)
    8000488c:	6165                	addi	sp,sp,112
    8000488e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004890:	89da                	mv	s3,s6
    80004892:	bff1                	j	8000486e <readi+0xce>
    return 0;
    80004894:	4501                	li	a0,0
}
    80004896:	8082                	ret

0000000080004898 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004898:	457c                	lw	a5,76(a0)
    8000489a:	10d7e863          	bltu	a5,a3,800049aa <writei+0x112>
{
    8000489e:	7159                	addi	sp,sp,-112
    800048a0:	f486                	sd	ra,104(sp)
    800048a2:	f0a2                	sd	s0,96(sp)
    800048a4:	eca6                	sd	s1,88(sp)
    800048a6:	e8ca                	sd	s2,80(sp)
    800048a8:	e4ce                	sd	s3,72(sp)
    800048aa:	e0d2                	sd	s4,64(sp)
    800048ac:	fc56                	sd	s5,56(sp)
    800048ae:	f85a                	sd	s6,48(sp)
    800048b0:	f45e                	sd	s7,40(sp)
    800048b2:	f062                	sd	s8,32(sp)
    800048b4:	ec66                	sd	s9,24(sp)
    800048b6:	e86a                	sd	s10,16(sp)
    800048b8:	e46e                	sd	s11,8(sp)
    800048ba:	1880                	addi	s0,sp,112
    800048bc:	8b2a                	mv	s6,a0
    800048be:	8c2e                	mv	s8,a1
    800048c0:	8ab2                	mv	s5,a2
    800048c2:	8936                	mv	s2,a3
    800048c4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800048c6:	00e687bb          	addw	a5,a3,a4
    800048ca:	0ed7e263          	bltu	a5,a3,800049ae <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800048ce:	00043737          	lui	a4,0x43
    800048d2:	0ef76063          	bltu	a4,a5,800049b2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800048d6:	0c0b8863          	beqz	s7,800049a6 <writei+0x10e>
    800048da:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800048dc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800048e0:	5cfd                	li	s9,-1
    800048e2:	a091                	j	80004926 <writei+0x8e>
    800048e4:	02099d93          	slli	s11,s3,0x20
    800048e8:	020ddd93          	srli	s11,s11,0x20
    800048ec:	05848513          	addi	a0,s1,88
    800048f0:	86ee                	mv	a3,s11
    800048f2:	8656                	mv	a2,s5
    800048f4:	85e2                	mv	a1,s8
    800048f6:	953a                	add	a0,a0,a4
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	a42080e7          	jalr	-1470(ra) # 8000333a <either_copyin>
    80004900:	07950263          	beq	a0,s9,80004964 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004904:	8526                	mv	a0,s1
    80004906:	00000097          	auipc	ra,0x0
    8000490a:	790080e7          	jalr	1936(ra) # 80005096 <log_write>
    brelse(bp);
    8000490e:	8526                	mv	a0,s1
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	50a080e7          	jalr	1290(ra) # 80003e1a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004918:	01498a3b          	addw	s4,s3,s4
    8000491c:	0129893b          	addw	s2,s3,s2
    80004920:	9aee                	add	s5,s5,s11
    80004922:	057a7663          	bgeu	s4,s7,8000496e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004926:	000b2483          	lw	s1,0(s6)
    8000492a:	00a9559b          	srliw	a1,s2,0xa
    8000492e:	855a                	mv	a0,s6
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	7ae080e7          	jalr	1966(ra) # 800040de <bmap>
    80004938:	0005059b          	sext.w	a1,a0
    8000493c:	8526                	mv	a0,s1
    8000493e:	fffff097          	auipc	ra,0xfffff
    80004942:	3ac080e7          	jalr	940(ra) # 80003cea <bread>
    80004946:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004948:	3ff97713          	andi	a4,s2,1023
    8000494c:	40ed07bb          	subw	a5,s10,a4
    80004950:	414b86bb          	subw	a3,s7,s4
    80004954:	89be                	mv	s3,a5
    80004956:	2781                	sext.w	a5,a5
    80004958:	0006861b          	sext.w	a2,a3
    8000495c:	f8f674e3          	bgeu	a2,a5,800048e4 <writei+0x4c>
    80004960:	89b6                	mv	s3,a3
    80004962:	b749                	j	800048e4 <writei+0x4c>
      brelse(bp);
    80004964:	8526                	mv	a0,s1
    80004966:	fffff097          	auipc	ra,0xfffff
    8000496a:	4b4080e7          	jalr	1204(ra) # 80003e1a <brelse>
  }

  if(off > ip->size)
    8000496e:	04cb2783          	lw	a5,76(s6)
    80004972:	0127f463          	bgeu	a5,s2,8000497a <writei+0xe2>
    ip->size = off;
    80004976:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000497a:	855a                	mv	a0,s6
    8000497c:	00000097          	auipc	ra,0x0
    80004980:	aa6080e7          	jalr	-1370(ra) # 80004422 <iupdate>

  return tot;
    80004984:	000a051b          	sext.w	a0,s4
}
    80004988:	70a6                	ld	ra,104(sp)
    8000498a:	7406                	ld	s0,96(sp)
    8000498c:	64e6                	ld	s1,88(sp)
    8000498e:	6946                	ld	s2,80(sp)
    80004990:	69a6                	ld	s3,72(sp)
    80004992:	6a06                	ld	s4,64(sp)
    80004994:	7ae2                	ld	s5,56(sp)
    80004996:	7b42                	ld	s6,48(sp)
    80004998:	7ba2                	ld	s7,40(sp)
    8000499a:	7c02                	ld	s8,32(sp)
    8000499c:	6ce2                	ld	s9,24(sp)
    8000499e:	6d42                	ld	s10,16(sp)
    800049a0:	6da2                	ld	s11,8(sp)
    800049a2:	6165                	addi	sp,sp,112
    800049a4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800049a6:	8a5e                	mv	s4,s7
    800049a8:	bfc9                	j	8000497a <writei+0xe2>
    return -1;
    800049aa:	557d                	li	a0,-1
}
    800049ac:	8082                	ret
    return -1;
    800049ae:	557d                	li	a0,-1
    800049b0:	bfe1                	j	80004988 <writei+0xf0>
    return -1;
    800049b2:	557d                	li	a0,-1
    800049b4:	bfd1                	j	80004988 <writei+0xf0>

00000000800049b6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800049b6:	1141                	addi	sp,sp,-16
    800049b8:	e406                	sd	ra,8(sp)
    800049ba:	e022                	sd	s0,0(sp)
    800049bc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800049be:	4639                	li	a2,14
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	406080e7          	jalr	1030(ra) # 80000dc6 <strncmp>
}
    800049c8:	60a2                	ld	ra,8(sp)
    800049ca:	6402                	ld	s0,0(sp)
    800049cc:	0141                	addi	sp,sp,16
    800049ce:	8082                	ret

00000000800049d0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800049d0:	7139                	addi	sp,sp,-64
    800049d2:	fc06                	sd	ra,56(sp)
    800049d4:	f822                	sd	s0,48(sp)
    800049d6:	f426                	sd	s1,40(sp)
    800049d8:	f04a                	sd	s2,32(sp)
    800049da:	ec4e                	sd	s3,24(sp)
    800049dc:	e852                	sd	s4,16(sp)
    800049de:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800049e0:	04451703          	lh	a4,68(a0)
    800049e4:	4785                	li	a5,1
    800049e6:	00f71a63          	bne	a4,a5,800049fa <dirlookup+0x2a>
    800049ea:	892a                	mv	s2,a0
    800049ec:	89ae                	mv	s3,a1
    800049ee:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800049f0:	457c                	lw	a5,76(a0)
    800049f2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800049f4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049f6:	e79d                	bnez	a5,80004a24 <dirlookup+0x54>
    800049f8:	a8a5                	j	80004a70 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800049fa:	00005517          	auipc	a0,0x5
    800049fe:	de650513          	addi	a0,a0,-538 # 800097e0 <syscalls+0x1b0>
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	b3c080e7          	jalr	-1220(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004a0a:	00005517          	auipc	a0,0x5
    80004a0e:	dee50513          	addi	a0,a0,-530 # 800097f8 <syscalls+0x1c8>
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	b2c080e7          	jalr	-1236(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a1a:	24c1                	addiw	s1,s1,16
    80004a1c:	04c92783          	lw	a5,76(s2)
    80004a20:	04f4f763          	bgeu	s1,a5,80004a6e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a24:	4741                	li	a4,16
    80004a26:	86a6                	mv	a3,s1
    80004a28:	fc040613          	addi	a2,s0,-64
    80004a2c:	4581                	li	a1,0
    80004a2e:	854a                	mv	a0,s2
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	d70080e7          	jalr	-656(ra) # 800047a0 <readi>
    80004a38:	47c1                	li	a5,16
    80004a3a:	fcf518e3          	bne	a0,a5,80004a0a <dirlookup+0x3a>
    if(de.inum == 0)
    80004a3e:	fc045783          	lhu	a5,-64(s0)
    80004a42:	dfe1                	beqz	a5,80004a1a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004a44:	fc240593          	addi	a1,s0,-62
    80004a48:	854e                	mv	a0,s3
    80004a4a:	00000097          	auipc	ra,0x0
    80004a4e:	f6c080e7          	jalr	-148(ra) # 800049b6 <namecmp>
    80004a52:	f561                	bnez	a0,80004a1a <dirlookup+0x4a>
      if(poff)
    80004a54:	000a0463          	beqz	s4,80004a5c <dirlookup+0x8c>
        *poff = off;
    80004a58:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004a5c:	fc045583          	lhu	a1,-64(s0)
    80004a60:	00092503          	lw	a0,0(s2)
    80004a64:	fffff097          	auipc	ra,0xfffff
    80004a68:	754080e7          	jalr	1876(ra) # 800041b8 <iget>
    80004a6c:	a011                	j	80004a70 <dirlookup+0xa0>
  return 0;
    80004a6e:	4501                	li	a0,0
}
    80004a70:	70e2                	ld	ra,56(sp)
    80004a72:	7442                	ld	s0,48(sp)
    80004a74:	74a2                	ld	s1,40(sp)
    80004a76:	7902                	ld	s2,32(sp)
    80004a78:	69e2                	ld	s3,24(sp)
    80004a7a:	6a42                	ld	s4,16(sp)
    80004a7c:	6121                	addi	sp,sp,64
    80004a7e:	8082                	ret

0000000080004a80 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004a80:	711d                	addi	sp,sp,-96
    80004a82:	ec86                	sd	ra,88(sp)
    80004a84:	e8a2                	sd	s0,80(sp)
    80004a86:	e4a6                	sd	s1,72(sp)
    80004a88:	e0ca                	sd	s2,64(sp)
    80004a8a:	fc4e                	sd	s3,56(sp)
    80004a8c:	f852                	sd	s4,48(sp)
    80004a8e:	f456                	sd	s5,40(sp)
    80004a90:	f05a                	sd	s6,32(sp)
    80004a92:	ec5e                	sd	s7,24(sp)
    80004a94:	e862                	sd	s8,16(sp)
    80004a96:	e466                	sd	s9,8(sp)
    80004a98:	1080                	addi	s0,sp,96
    80004a9a:	84aa                	mv	s1,a0
    80004a9c:	8b2e                	mv	s6,a1
    80004a9e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004aa0:	00054703          	lbu	a4,0(a0)
    80004aa4:	02f00793          	li	a5,47
    80004aa8:	02f70363          	beq	a4,a5,80004ace <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004aac:	ffffd097          	auipc	ra,0xffffd
    80004ab0:	3f6080e7          	jalr	1014(ra) # 80001ea2 <myproc>
    80004ab4:	17853503          	ld	a0,376(a0)
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	9f6080e7          	jalr	-1546(ra) # 800044ae <idup>
    80004ac0:	89aa                	mv	s3,a0
  while(*path == '/')
    80004ac2:	02f00913          	li	s2,47
  len = path - s;
    80004ac6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004ac8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004aca:	4c05                	li	s8,1
    80004acc:	a865                	j	80004b84 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004ace:	4585                	li	a1,1
    80004ad0:	4505                	li	a0,1
    80004ad2:	fffff097          	auipc	ra,0xfffff
    80004ad6:	6e6080e7          	jalr	1766(ra) # 800041b8 <iget>
    80004ada:	89aa                	mv	s3,a0
    80004adc:	b7dd                	j	80004ac2 <namex+0x42>
      iunlockput(ip);
    80004ade:	854e                	mv	a0,s3
    80004ae0:	00000097          	auipc	ra,0x0
    80004ae4:	c6e080e7          	jalr	-914(ra) # 8000474e <iunlockput>
      return 0;
    80004ae8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004aea:	854e                	mv	a0,s3
    80004aec:	60e6                	ld	ra,88(sp)
    80004aee:	6446                	ld	s0,80(sp)
    80004af0:	64a6                	ld	s1,72(sp)
    80004af2:	6906                	ld	s2,64(sp)
    80004af4:	79e2                	ld	s3,56(sp)
    80004af6:	7a42                	ld	s4,48(sp)
    80004af8:	7aa2                	ld	s5,40(sp)
    80004afa:	7b02                	ld	s6,32(sp)
    80004afc:	6be2                	ld	s7,24(sp)
    80004afe:	6c42                	ld	s8,16(sp)
    80004b00:	6ca2                	ld	s9,8(sp)
    80004b02:	6125                	addi	sp,sp,96
    80004b04:	8082                	ret
      iunlock(ip);
    80004b06:	854e                	mv	a0,s3
    80004b08:	00000097          	auipc	ra,0x0
    80004b0c:	aa6080e7          	jalr	-1370(ra) # 800045ae <iunlock>
      return ip;
    80004b10:	bfe9                	j	80004aea <namex+0x6a>
      iunlockput(ip);
    80004b12:	854e                	mv	a0,s3
    80004b14:	00000097          	auipc	ra,0x0
    80004b18:	c3a080e7          	jalr	-966(ra) # 8000474e <iunlockput>
      return 0;
    80004b1c:	89d2                	mv	s3,s4
    80004b1e:	b7f1                	j	80004aea <namex+0x6a>
  len = path - s;
    80004b20:	40b48633          	sub	a2,s1,a1
    80004b24:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004b28:	094cd463          	bge	s9,s4,80004bb0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004b2c:	4639                	li	a2,14
    80004b2e:	8556                	mv	a0,s5
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	21e080e7          	jalr	542(ra) # 80000d4e <memmove>
  while(*path == '/')
    80004b38:	0004c783          	lbu	a5,0(s1)
    80004b3c:	01279763          	bne	a5,s2,80004b4a <namex+0xca>
    path++;
    80004b40:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004b42:	0004c783          	lbu	a5,0(s1)
    80004b46:	ff278de3          	beq	a5,s2,80004b40 <namex+0xc0>
    ilock(ip);
    80004b4a:	854e                	mv	a0,s3
    80004b4c:	00000097          	auipc	ra,0x0
    80004b50:	9a0080e7          	jalr	-1632(ra) # 800044ec <ilock>
    if(ip->type != T_DIR){
    80004b54:	04499783          	lh	a5,68(s3)
    80004b58:	f98793e3          	bne	a5,s8,80004ade <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004b5c:	000b0563          	beqz	s6,80004b66 <namex+0xe6>
    80004b60:	0004c783          	lbu	a5,0(s1)
    80004b64:	d3cd                	beqz	a5,80004b06 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004b66:	865e                	mv	a2,s7
    80004b68:	85d6                	mv	a1,s5
    80004b6a:	854e                	mv	a0,s3
    80004b6c:	00000097          	auipc	ra,0x0
    80004b70:	e64080e7          	jalr	-412(ra) # 800049d0 <dirlookup>
    80004b74:	8a2a                	mv	s4,a0
    80004b76:	dd51                	beqz	a0,80004b12 <namex+0x92>
    iunlockput(ip);
    80004b78:	854e                	mv	a0,s3
    80004b7a:	00000097          	auipc	ra,0x0
    80004b7e:	bd4080e7          	jalr	-1068(ra) # 8000474e <iunlockput>
    ip = next;
    80004b82:	89d2                	mv	s3,s4
  while(*path == '/')
    80004b84:	0004c783          	lbu	a5,0(s1)
    80004b88:	05279763          	bne	a5,s2,80004bd6 <namex+0x156>
    path++;
    80004b8c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004b8e:	0004c783          	lbu	a5,0(s1)
    80004b92:	ff278de3          	beq	a5,s2,80004b8c <namex+0x10c>
  if(*path == 0)
    80004b96:	c79d                	beqz	a5,80004bc4 <namex+0x144>
    path++;
    80004b98:	85a6                	mv	a1,s1
  len = path - s;
    80004b9a:	8a5e                	mv	s4,s7
    80004b9c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004b9e:	01278963          	beq	a5,s2,80004bb0 <namex+0x130>
    80004ba2:	dfbd                	beqz	a5,80004b20 <namex+0xa0>
    path++;
    80004ba4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004ba6:	0004c783          	lbu	a5,0(s1)
    80004baa:	ff279ce3          	bne	a5,s2,80004ba2 <namex+0x122>
    80004bae:	bf8d                	j	80004b20 <namex+0xa0>
    memmove(name, s, len);
    80004bb0:	2601                	sext.w	a2,a2
    80004bb2:	8556                	mv	a0,s5
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	19a080e7          	jalr	410(ra) # 80000d4e <memmove>
    name[len] = 0;
    80004bbc:	9a56                	add	s4,s4,s5
    80004bbe:	000a0023          	sb	zero,0(s4)
    80004bc2:	bf9d                	j	80004b38 <namex+0xb8>
  if(nameiparent){
    80004bc4:	f20b03e3          	beqz	s6,80004aea <namex+0x6a>
    iput(ip);
    80004bc8:	854e                	mv	a0,s3
    80004bca:	00000097          	auipc	ra,0x0
    80004bce:	adc080e7          	jalr	-1316(ra) # 800046a6 <iput>
    return 0;
    80004bd2:	4981                	li	s3,0
    80004bd4:	bf19                	j	80004aea <namex+0x6a>
  if(*path == 0)
    80004bd6:	d7fd                	beqz	a5,80004bc4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004bd8:	0004c783          	lbu	a5,0(s1)
    80004bdc:	85a6                	mv	a1,s1
    80004bde:	b7d1                	j	80004ba2 <namex+0x122>

0000000080004be0 <dirlink>:
{
    80004be0:	7139                	addi	sp,sp,-64
    80004be2:	fc06                	sd	ra,56(sp)
    80004be4:	f822                	sd	s0,48(sp)
    80004be6:	f426                	sd	s1,40(sp)
    80004be8:	f04a                	sd	s2,32(sp)
    80004bea:	ec4e                	sd	s3,24(sp)
    80004bec:	e852                	sd	s4,16(sp)
    80004bee:	0080                	addi	s0,sp,64
    80004bf0:	892a                	mv	s2,a0
    80004bf2:	8a2e                	mv	s4,a1
    80004bf4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004bf6:	4601                	li	a2,0
    80004bf8:	00000097          	auipc	ra,0x0
    80004bfc:	dd8080e7          	jalr	-552(ra) # 800049d0 <dirlookup>
    80004c00:	e93d                	bnez	a0,80004c76 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004c02:	04c92483          	lw	s1,76(s2)
    80004c06:	c49d                	beqz	s1,80004c34 <dirlink+0x54>
    80004c08:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004c0a:	4741                	li	a4,16
    80004c0c:	86a6                	mv	a3,s1
    80004c0e:	fc040613          	addi	a2,s0,-64
    80004c12:	4581                	li	a1,0
    80004c14:	854a                	mv	a0,s2
    80004c16:	00000097          	auipc	ra,0x0
    80004c1a:	b8a080e7          	jalr	-1142(ra) # 800047a0 <readi>
    80004c1e:	47c1                	li	a5,16
    80004c20:	06f51163          	bne	a0,a5,80004c82 <dirlink+0xa2>
    if(de.inum == 0)
    80004c24:	fc045783          	lhu	a5,-64(s0)
    80004c28:	c791                	beqz	a5,80004c34 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004c2a:	24c1                	addiw	s1,s1,16
    80004c2c:	04c92783          	lw	a5,76(s2)
    80004c30:	fcf4ede3          	bltu	s1,a5,80004c0a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004c34:	4639                	li	a2,14
    80004c36:	85d2                	mv	a1,s4
    80004c38:	fc240513          	addi	a0,s0,-62
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	1c6080e7          	jalr	454(ra) # 80000e02 <strncpy>
  de.inum = inum;
    80004c44:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004c48:	4741                	li	a4,16
    80004c4a:	86a6                	mv	a3,s1
    80004c4c:	fc040613          	addi	a2,s0,-64
    80004c50:	4581                	li	a1,0
    80004c52:	854a                	mv	a0,s2
    80004c54:	00000097          	auipc	ra,0x0
    80004c58:	c44080e7          	jalr	-956(ra) # 80004898 <writei>
    80004c5c:	872a                	mv	a4,a0
    80004c5e:	47c1                	li	a5,16
  return 0;
    80004c60:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004c62:	02f71863          	bne	a4,a5,80004c92 <dirlink+0xb2>
}
    80004c66:	70e2                	ld	ra,56(sp)
    80004c68:	7442                	ld	s0,48(sp)
    80004c6a:	74a2                	ld	s1,40(sp)
    80004c6c:	7902                	ld	s2,32(sp)
    80004c6e:	69e2                	ld	s3,24(sp)
    80004c70:	6a42                	ld	s4,16(sp)
    80004c72:	6121                	addi	sp,sp,64
    80004c74:	8082                	ret
    iput(ip);
    80004c76:	00000097          	auipc	ra,0x0
    80004c7a:	a30080e7          	jalr	-1488(ra) # 800046a6 <iput>
    return -1;
    80004c7e:	557d                	li	a0,-1
    80004c80:	b7dd                	j	80004c66 <dirlink+0x86>
      panic("dirlink read");
    80004c82:	00005517          	auipc	a0,0x5
    80004c86:	b8650513          	addi	a0,a0,-1146 # 80009808 <syscalls+0x1d8>
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	8b4080e7          	jalr	-1868(ra) # 8000053e <panic>
    panic("dirlink");
    80004c92:	00005517          	auipc	a0,0x5
    80004c96:	c8650513          	addi	a0,a0,-890 # 80009918 <syscalls+0x2e8>
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	8a4080e7          	jalr	-1884(ra) # 8000053e <panic>

0000000080004ca2 <namei>:

struct inode*
namei(char *path)
{
    80004ca2:	1101                	addi	sp,sp,-32
    80004ca4:	ec06                	sd	ra,24(sp)
    80004ca6:	e822                	sd	s0,16(sp)
    80004ca8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004caa:	fe040613          	addi	a2,s0,-32
    80004cae:	4581                	li	a1,0
    80004cb0:	00000097          	auipc	ra,0x0
    80004cb4:	dd0080e7          	jalr	-560(ra) # 80004a80 <namex>
}
    80004cb8:	60e2                	ld	ra,24(sp)
    80004cba:	6442                	ld	s0,16(sp)
    80004cbc:	6105                	addi	sp,sp,32
    80004cbe:	8082                	ret

0000000080004cc0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004cc0:	1141                	addi	sp,sp,-16
    80004cc2:	e406                	sd	ra,8(sp)
    80004cc4:	e022                	sd	s0,0(sp)
    80004cc6:	0800                	addi	s0,sp,16
    80004cc8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004cca:	4585                	li	a1,1
    80004ccc:	00000097          	auipc	ra,0x0
    80004cd0:	db4080e7          	jalr	-588(ra) # 80004a80 <namex>
}
    80004cd4:	60a2                	ld	ra,8(sp)
    80004cd6:	6402                	ld	s0,0(sp)
    80004cd8:	0141                	addi	sp,sp,16
    80004cda:	8082                	ret

0000000080004cdc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004cdc:	1101                	addi	sp,sp,-32
    80004cde:	ec06                	sd	ra,24(sp)
    80004ce0:	e822                	sd	s0,16(sp)
    80004ce2:	e426                	sd	s1,8(sp)
    80004ce4:	e04a                	sd	s2,0(sp)
    80004ce6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004ce8:	0001e917          	auipc	s2,0x1e
    80004cec:	e9890913          	addi	s2,s2,-360 # 80022b80 <log>
    80004cf0:	01892583          	lw	a1,24(s2)
    80004cf4:	02892503          	lw	a0,40(s2)
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	ff2080e7          	jalr	-14(ra) # 80003cea <bread>
    80004d00:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004d02:	02c92683          	lw	a3,44(s2)
    80004d06:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004d08:	02d05763          	blez	a3,80004d36 <write_head+0x5a>
    80004d0c:	0001e797          	auipc	a5,0x1e
    80004d10:	ea478793          	addi	a5,a5,-348 # 80022bb0 <log+0x30>
    80004d14:	05c50713          	addi	a4,a0,92
    80004d18:	36fd                	addiw	a3,a3,-1
    80004d1a:	1682                	slli	a3,a3,0x20
    80004d1c:	9281                	srli	a3,a3,0x20
    80004d1e:	068a                	slli	a3,a3,0x2
    80004d20:	0001e617          	auipc	a2,0x1e
    80004d24:	e9460613          	addi	a2,a2,-364 # 80022bb4 <log+0x34>
    80004d28:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004d2a:	4390                	lw	a2,0(a5)
    80004d2c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004d2e:	0791                	addi	a5,a5,4
    80004d30:	0711                	addi	a4,a4,4
    80004d32:	fed79ce3          	bne	a5,a3,80004d2a <write_head+0x4e>
  }
  bwrite(buf);
    80004d36:	8526                	mv	a0,s1
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	0a4080e7          	jalr	164(ra) # 80003ddc <bwrite>
  brelse(buf);
    80004d40:	8526                	mv	a0,s1
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	0d8080e7          	jalr	216(ra) # 80003e1a <brelse>
}
    80004d4a:	60e2                	ld	ra,24(sp)
    80004d4c:	6442                	ld	s0,16(sp)
    80004d4e:	64a2                	ld	s1,8(sp)
    80004d50:	6902                	ld	s2,0(sp)
    80004d52:	6105                	addi	sp,sp,32
    80004d54:	8082                	ret

0000000080004d56 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d56:	0001e797          	auipc	a5,0x1e
    80004d5a:	e567a783          	lw	a5,-426(a5) # 80022bac <log+0x2c>
    80004d5e:	0af05d63          	blez	a5,80004e18 <install_trans+0xc2>
{
    80004d62:	7139                	addi	sp,sp,-64
    80004d64:	fc06                	sd	ra,56(sp)
    80004d66:	f822                	sd	s0,48(sp)
    80004d68:	f426                	sd	s1,40(sp)
    80004d6a:	f04a                	sd	s2,32(sp)
    80004d6c:	ec4e                	sd	s3,24(sp)
    80004d6e:	e852                	sd	s4,16(sp)
    80004d70:	e456                	sd	s5,8(sp)
    80004d72:	e05a                	sd	s6,0(sp)
    80004d74:	0080                	addi	s0,sp,64
    80004d76:	8b2a                	mv	s6,a0
    80004d78:	0001ea97          	auipc	s5,0x1e
    80004d7c:	e38a8a93          	addi	s5,s5,-456 # 80022bb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d80:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004d82:	0001e997          	auipc	s3,0x1e
    80004d86:	dfe98993          	addi	s3,s3,-514 # 80022b80 <log>
    80004d8a:	a035                	j	80004db6 <install_trans+0x60>
      bunpin(dbuf);
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	166080e7          	jalr	358(ra) # 80003ef4 <bunpin>
    brelse(lbuf);
    80004d96:	854a                	mv	a0,s2
    80004d98:	fffff097          	auipc	ra,0xfffff
    80004d9c:	082080e7          	jalr	130(ra) # 80003e1a <brelse>
    brelse(dbuf);
    80004da0:	8526                	mv	a0,s1
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	078080e7          	jalr	120(ra) # 80003e1a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004daa:	2a05                	addiw	s4,s4,1
    80004dac:	0a91                	addi	s5,s5,4
    80004dae:	02c9a783          	lw	a5,44(s3)
    80004db2:	04fa5963          	bge	s4,a5,80004e04 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004db6:	0189a583          	lw	a1,24(s3)
    80004dba:	014585bb          	addw	a1,a1,s4
    80004dbe:	2585                	addiw	a1,a1,1
    80004dc0:	0289a503          	lw	a0,40(s3)
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	f26080e7          	jalr	-218(ra) # 80003cea <bread>
    80004dcc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004dce:	000aa583          	lw	a1,0(s5)
    80004dd2:	0289a503          	lw	a0,40(s3)
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	f14080e7          	jalr	-236(ra) # 80003cea <bread>
    80004dde:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004de0:	40000613          	li	a2,1024
    80004de4:	05890593          	addi	a1,s2,88
    80004de8:	05850513          	addi	a0,a0,88
    80004dec:	ffffc097          	auipc	ra,0xffffc
    80004df0:	f62080e7          	jalr	-158(ra) # 80000d4e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004df4:	8526                	mv	a0,s1
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	fe6080e7          	jalr	-26(ra) # 80003ddc <bwrite>
    if(recovering == 0)
    80004dfe:	f80b1ce3          	bnez	s6,80004d96 <install_trans+0x40>
    80004e02:	b769                	j	80004d8c <install_trans+0x36>
}
    80004e04:	70e2                	ld	ra,56(sp)
    80004e06:	7442                	ld	s0,48(sp)
    80004e08:	74a2                	ld	s1,40(sp)
    80004e0a:	7902                	ld	s2,32(sp)
    80004e0c:	69e2                	ld	s3,24(sp)
    80004e0e:	6a42                	ld	s4,16(sp)
    80004e10:	6aa2                	ld	s5,8(sp)
    80004e12:	6b02                	ld	s6,0(sp)
    80004e14:	6121                	addi	sp,sp,64
    80004e16:	8082                	ret
    80004e18:	8082                	ret

0000000080004e1a <initlog>:
{
    80004e1a:	7179                	addi	sp,sp,-48
    80004e1c:	f406                	sd	ra,40(sp)
    80004e1e:	f022                	sd	s0,32(sp)
    80004e20:	ec26                	sd	s1,24(sp)
    80004e22:	e84a                	sd	s2,16(sp)
    80004e24:	e44e                	sd	s3,8(sp)
    80004e26:	1800                	addi	s0,sp,48
    80004e28:	892a                	mv	s2,a0
    80004e2a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004e2c:	0001e497          	auipc	s1,0x1e
    80004e30:	d5448493          	addi	s1,s1,-684 # 80022b80 <log>
    80004e34:	00005597          	auipc	a1,0x5
    80004e38:	9e458593          	addi	a1,a1,-1564 # 80009818 <syscalls+0x1e8>
    80004e3c:	8526                	mv	a0,s1
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	d16080e7          	jalr	-746(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004e46:	0149a583          	lw	a1,20(s3)
    80004e4a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004e4c:	0109a783          	lw	a5,16(s3)
    80004e50:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004e52:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004e56:	854a                	mv	a0,s2
    80004e58:	fffff097          	auipc	ra,0xfffff
    80004e5c:	e92080e7          	jalr	-366(ra) # 80003cea <bread>
  log.lh.n = lh->n;
    80004e60:	4d3c                	lw	a5,88(a0)
    80004e62:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004e64:	02f05563          	blez	a5,80004e8e <initlog+0x74>
    80004e68:	05c50713          	addi	a4,a0,92
    80004e6c:	0001e697          	auipc	a3,0x1e
    80004e70:	d4468693          	addi	a3,a3,-700 # 80022bb0 <log+0x30>
    80004e74:	37fd                	addiw	a5,a5,-1
    80004e76:	1782                	slli	a5,a5,0x20
    80004e78:	9381                	srli	a5,a5,0x20
    80004e7a:	078a                	slli	a5,a5,0x2
    80004e7c:	06050613          	addi	a2,a0,96
    80004e80:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004e82:	4310                	lw	a2,0(a4)
    80004e84:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004e86:	0711                	addi	a4,a4,4
    80004e88:	0691                	addi	a3,a3,4
    80004e8a:	fef71ce3          	bne	a4,a5,80004e82 <initlog+0x68>
  brelse(buf);
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	f8c080e7          	jalr	-116(ra) # 80003e1a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004e96:	4505                	li	a0,1
    80004e98:	00000097          	auipc	ra,0x0
    80004e9c:	ebe080e7          	jalr	-322(ra) # 80004d56 <install_trans>
  log.lh.n = 0;
    80004ea0:	0001e797          	auipc	a5,0x1e
    80004ea4:	d007a623          	sw	zero,-756(a5) # 80022bac <log+0x2c>
  write_head(); // clear the log
    80004ea8:	00000097          	auipc	ra,0x0
    80004eac:	e34080e7          	jalr	-460(ra) # 80004cdc <write_head>
}
    80004eb0:	70a2                	ld	ra,40(sp)
    80004eb2:	7402                	ld	s0,32(sp)
    80004eb4:	64e2                	ld	s1,24(sp)
    80004eb6:	6942                	ld	s2,16(sp)
    80004eb8:	69a2                	ld	s3,8(sp)
    80004eba:	6145                	addi	sp,sp,48
    80004ebc:	8082                	ret

0000000080004ebe <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004ebe:	1101                	addi	sp,sp,-32
    80004ec0:	ec06                	sd	ra,24(sp)
    80004ec2:	e822                	sd	s0,16(sp)
    80004ec4:	e426                	sd	s1,8(sp)
    80004ec6:	e04a                	sd	s2,0(sp)
    80004ec8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004eca:	0001e517          	auipc	a0,0x1e
    80004ece:	cb650513          	addi	a0,a0,-842 # 80022b80 <log>
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	d1a080e7          	jalr	-742(ra) # 80000bec <acquire>
  while(1){
    if(log.committing){
    80004eda:	0001e497          	auipc	s1,0x1e
    80004ede:	ca648493          	addi	s1,s1,-858 # 80022b80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ee2:	4979                	li	s2,30
    80004ee4:	a039                	j	80004ef2 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004ee6:	85a6                	mv	a1,s1
    80004ee8:	8526                	mv	a0,s1
    80004eea:	ffffe097          	auipc	ra,0xffffe
    80004eee:	ec8080e7          	jalr	-312(ra) # 80002db2 <sleep>
    if(log.committing){
    80004ef2:	50dc                	lw	a5,36(s1)
    80004ef4:	fbed                	bnez	a5,80004ee6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ef6:	509c                	lw	a5,32(s1)
    80004ef8:	0017871b          	addiw	a4,a5,1
    80004efc:	0007069b          	sext.w	a3,a4
    80004f00:	0027179b          	slliw	a5,a4,0x2
    80004f04:	9fb9                	addw	a5,a5,a4
    80004f06:	0017979b          	slliw	a5,a5,0x1
    80004f0a:	54d8                	lw	a4,44(s1)
    80004f0c:	9fb9                	addw	a5,a5,a4
    80004f0e:	00f95963          	bge	s2,a5,80004f20 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004f12:	85a6                	mv	a1,s1
    80004f14:	8526                	mv	a0,s1
    80004f16:	ffffe097          	auipc	ra,0xffffe
    80004f1a:	e9c080e7          	jalr	-356(ra) # 80002db2 <sleep>
    80004f1e:	bfd1                	j	80004ef2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004f20:	0001e517          	auipc	a0,0x1e
    80004f24:	c6050513          	addi	a0,a0,-928 # 80022b80 <log>
    80004f28:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	d7c080e7          	jalr	-644(ra) # 80000ca6 <release>
      break;
    }
  }
}
    80004f32:	60e2                	ld	ra,24(sp)
    80004f34:	6442                	ld	s0,16(sp)
    80004f36:	64a2                	ld	s1,8(sp)
    80004f38:	6902                	ld	s2,0(sp)
    80004f3a:	6105                	addi	sp,sp,32
    80004f3c:	8082                	ret

0000000080004f3e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004f3e:	7139                	addi	sp,sp,-64
    80004f40:	fc06                	sd	ra,56(sp)
    80004f42:	f822                	sd	s0,48(sp)
    80004f44:	f426                	sd	s1,40(sp)
    80004f46:	f04a                	sd	s2,32(sp)
    80004f48:	ec4e                	sd	s3,24(sp)
    80004f4a:	e852                	sd	s4,16(sp)
    80004f4c:	e456                	sd	s5,8(sp)
    80004f4e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004f50:	0001e497          	auipc	s1,0x1e
    80004f54:	c3048493          	addi	s1,s1,-976 # 80022b80 <log>
    80004f58:	8526                	mv	a0,s1
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	c92080e7          	jalr	-878(ra) # 80000bec <acquire>
  log.outstanding -= 1;
    80004f62:	509c                	lw	a5,32(s1)
    80004f64:	37fd                	addiw	a5,a5,-1
    80004f66:	0007891b          	sext.w	s2,a5
    80004f6a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004f6c:	50dc                	lw	a5,36(s1)
    80004f6e:	efb9                	bnez	a5,80004fcc <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004f70:	06091663          	bnez	s2,80004fdc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004f74:	0001e497          	auipc	s1,0x1e
    80004f78:	c0c48493          	addi	s1,s1,-1012 # 80022b80 <log>
    80004f7c:	4785                	li	a5,1
    80004f7e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004f80:	8526                	mv	a0,s1
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	d24080e7          	jalr	-732(ra) # 80000ca6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004f8a:	54dc                	lw	a5,44(s1)
    80004f8c:	06f04763          	bgtz	a5,80004ffa <end_op+0xbc>
    acquire(&log.lock);
    80004f90:	0001e497          	auipc	s1,0x1e
    80004f94:	bf048493          	addi	s1,s1,-1040 # 80022b80 <log>
    80004f98:	8526                	mv	a0,s1
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	c52080e7          	jalr	-942(ra) # 80000bec <acquire>
    log.committing = 0;
    80004fa2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004fa6:	8526                	mv	a0,s1
    80004fa8:	ffffe097          	auipc	ra,0xffffe
    80004fac:	fb2080e7          	jalr	-78(ra) # 80002f5a <wakeup>
    release(&log.lock);
    80004fb0:	8526                	mv	a0,s1
    80004fb2:	ffffc097          	auipc	ra,0xffffc
    80004fb6:	cf4080e7          	jalr	-780(ra) # 80000ca6 <release>
}
    80004fba:	70e2                	ld	ra,56(sp)
    80004fbc:	7442                	ld	s0,48(sp)
    80004fbe:	74a2                	ld	s1,40(sp)
    80004fc0:	7902                	ld	s2,32(sp)
    80004fc2:	69e2                	ld	s3,24(sp)
    80004fc4:	6a42                	ld	s4,16(sp)
    80004fc6:	6aa2                	ld	s5,8(sp)
    80004fc8:	6121                	addi	sp,sp,64
    80004fca:	8082                	ret
    panic("log.committing");
    80004fcc:	00005517          	auipc	a0,0x5
    80004fd0:	85450513          	addi	a0,a0,-1964 # 80009820 <syscalls+0x1f0>
    80004fd4:	ffffb097          	auipc	ra,0xffffb
    80004fd8:	56a080e7          	jalr	1386(ra) # 8000053e <panic>
    wakeup(&log);
    80004fdc:	0001e497          	auipc	s1,0x1e
    80004fe0:	ba448493          	addi	s1,s1,-1116 # 80022b80 <log>
    80004fe4:	8526                	mv	a0,s1
    80004fe6:	ffffe097          	auipc	ra,0xffffe
    80004fea:	f74080e7          	jalr	-140(ra) # 80002f5a <wakeup>
  release(&log.lock);
    80004fee:	8526                	mv	a0,s1
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	cb6080e7          	jalr	-842(ra) # 80000ca6 <release>
  if(do_commit){
    80004ff8:	b7c9                	j	80004fba <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ffa:	0001ea97          	auipc	s5,0x1e
    80004ffe:	bb6a8a93          	addi	s5,s5,-1098 # 80022bb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80005002:	0001ea17          	auipc	s4,0x1e
    80005006:	b7ea0a13          	addi	s4,s4,-1154 # 80022b80 <log>
    8000500a:	018a2583          	lw	a1,24(s4)
    8000500e:	012585bb          	addw	a1,a1,s2
    80005012:	2585                	addiw	a1,a1,1
    80005014:	028a2503          	lw	a0,40(s4)
    80005018:	fffff097          	auipc	ra,0xfffff
    8000501c:	cd2080e7          	jalr	-814(ra) # 80003cea <bread>
    80005020:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80005022:	000aa583          	lw	a1,0(s5)
    80005026:	028a2503          	lw	a0,40(s4)
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	cc0080e7          	jalr	-832(ra) # 80003cea <bread>
    80005032:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005034:	40000613          	li	a2,1024
    80005038:	05850593          	addi	a1,a0,88
    8000503c:	05848513          	addi	a0,s1,88
    80005040:	ffffc097          	auipc	ra,0xffffc
    80005044:	d0e080e7          	jalr	-754(ra) # 80000d4e <memmove>
    bwrite(to);  // write the log
    80005048:	8526                	mv	a0,s1
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	d92080e7          	jalr	-622(ra) # 80003ddc <bwrite>
    brelse(from);
    80005052:	854e                	mv	a0,s3
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	dc6080e7          	jalr	-570(ra) # 80003e1a <brelse>
    brelse(to);
    8000505c:	8526                	mv	a0,s1
    8000505e:	fffff097          	auipc	ra,0xfffff
    80005062:	dbc080e7          	jalr	-580(ra) # 80003e1a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005066:	2905                	addiw	s2,s2,1
    80005068:	0a91                	addi	s5,s5,4
    8000506a:	02ca2783          	lw	a5,44(s4)
    8000506e:	f8f94ee3          	blt	s2,a5,8000500a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80005072:	00000097          	auipc	ra,0x0
    80005076:	c6a080e7          	jalr	-918(ra) # 80004cdc <write_head>
    install_trans(0); // Now install writes to home locations
    8000507a:	4501                	li	a0,0
    8000507c:	00000097          	auipc	ra,0x0
    80005080:	cda080e7          	jalr	-806(ra) # 80004d56 <install_trans>
    log.lh.n = 0;
    80005084:	0001e797          	auipc	a5,0x1e
    80005088:	b207a423          	sw	zero,-1240(a5) # 80022bac <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000508c:	00000097          	auipc	ra,0x0
    80005090:	c50080e7          	jalr	-944(ra) # 80004cdc <write_head>
    80005094:	bdf5                	j	80004f90 <end_op+0x52>

0000000080005096 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80005096:	1101                	addi	sp,sp,-32
    80005098:	ec06                	sd	ra,24(sp)
    8000509a:	e822                	sd	s0,16(sp)
    8000509c:	e426                	sd	s1,8(sp)
    8000509e:	e04a                	sd	s2,0(sp)
    800050a0:	1000                	addi	s0,sp,32
    800050a2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800050a4:	0001e917          	auipc	s2,0x1e
    800050a8:	adc90913          	addi	s2,s2,-1316 # 80022b80 <log>
    800050ac:	854a                	mv	a0,s2
    800050ae:	ffffc097          	auipc	ra,0xffffc
    800050b2:	b3e080e7          	jalr	-1218(ra) # 80000bec <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800050b6:	02c92603          	lw	a2,44(s2)
    800050ba:	47f5                	li	a5,29
    800050bc:	06c7c563          	blt	a5,a2,80005126 <log_write+0x90>
    800050c0:	0001e797          	auipc	a5,0x1e
    800050c4:	adc7a783          	lw	a5,-1316(a5) # 80022b9c <log+0x1c>
    800050c8:	37fd                	addiw	a5,a5,-1
    800050ca:	04f65e63          	bge	a2,a5,80005126 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800050ce:	0001e797          	auipc	a5,0x1e
    800050d2:	ad27a783          	lw	a5,-1326(a5) # 80022ba0 <log+0x20>
    800050d6:	06f05063          	blez	a5,80005136 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800050da:	4781                	li	a5,0
    800050dc:	06c05563          	blez	a2,80005146 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800050e0:	44cc                	lw	a1,12(s1)
    800050e2:	0001e717          	auipc	a4,0x1e
    800050e6:	ace70713          	addi	a4,a4,-1330 # 80022bb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800050ea:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800050ec:	4314                	lw	a3,0(a4)
    800050ee:	04b68c63          	beq	a3,a1,80005146 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800050f2:	2785                	addiw	a5,a5,1
    800050f4:	0711                	addi	a4,a4,4
    800050f6:	fef61be3          	bne	a2,a5,800050ec <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800050fa:	0621                	addi	a2,a2,8
    800050fc:	060a                	slli	a2,a2,0x2
    800050fe:	0001e797          	auipc	a5,0x1e
    80005102:	a8278793          	addi	a5,a5,-1406 # 80022b80 <log>
    80005106:	963e                	add	a2,a2,a5
    80005108:	44dc                	lw	a5,12(s1)
    8000510a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000510c:	8526                	mv	a0,s1
    8000510e:	fffff097          	auipc	ra,0xfffff
    80005112:	daa080e7          	jalr	-598(ra) # 80003eb8 <bpin>
    log.lh.n++;
    80005116:	0001e717          	auipc	a4,0x1e
    8000511a:	a6a70713          	addi	a4,a4,-1430 # 80022b80 <log>
    8000511e:	575c                	lw	a5,44(a4)
    80005120:	2785                	addiw	a5,a5,1
    80005122:	d75c                	sw	a5,44(a4)
    80005124:	a835                	j	80005160 <log_write+0xca>
    panic("too big a transaction");
    80005126:	00004517          	auipc	a0,0x4
    8000512a:	70a50513          	addi	a0,a0,1802 # 80009830 <syscalls+0x200>
    8000512e:	ffffb097          	auipc	ra,0xffffb
    80005132:	410080e7          	jalr	1040(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80005136:	00004517          	auipc	a0,0x4
    8000513a:	71250513          	addi	a0,a0,1810 # 80009848 <syscalls+0x218>
    8000513e:	ffffb097          	auipc	ra,0xffffb
    80005142:	400080e7          	jalr	1024(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80005146:	00878713          	addi	a4,a5,8
    8000514a:	00271693          	slli	a3,a4,0x2
    8000514e:	0001e717          	auipc	a4,0x1e
    80005152:	a3270713          	addi	a4,a4,-1486 # 80022b80 <log>
    80005156:	9736                	add	a4,a4,a3
    80005158:	44d4                	lw	a3,12(s1)
    8000515a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000515c:	faf608e3          	beq	a2,a5,8000510c <log_write+0x76>
  }
  release(&log.lock);
    80005160:	0001e517          	auipc	a0,0x1e
    80005164:	a2050513          	addi	a0,a0,-1504 # 80022b80 <log>
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	b3e080e7          	jalr	-1218(ra) # 80000ca6 <release>
}
    80005170:	60e2                	ld	ra,24(sp)
    80005172:	6442                	ld	s0,16(sp)
    80005174:	64a2                	ld	s1,8(sp)
    80005176:	6902                	ld	s2,0(sp)
    80005178:	6105                	addi	sp,sp,32
    8000517a:	8082                	ret

000000008000517c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000517c:	1101                	addi	sp,sp,-32
    8000517e:	ec06                	sd	ra,24(sp)
    80005180:	e822                	sd	s0,16(sp)
    80005182:	e426                	sd	s1,8(sp)
    80005184:	e04a                	sd	s2,0(sp)
    80005186:	1000                	addi	s0,sp,32
    80005188:	84aa                	mv	s1,a0
    8000518a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000518c:	00004597          	auipc	a1,0x4
    80005190:	6dc58593          	addi	a1,a1,1756 # 80009868 <syscalls+0x238>
    80005194:	0521                	addi	a0,a0,8
    80005196:	ffffc097          	auipc	ra,0xffffc
    8000519a:	9be080e7          	jalr	-1602(ra) # 80000b54 <initlock>
  lk->name = name;
    8000519e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800051a2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800051a6:	0204a423          	sw	zero,40(s1)
}
    800051aa:	60e2                	ld	ra,24(sp)
    800051ac:	6442                	ld	s0,16(sp)
    800051ae:	64a2                	ld	s1,8(sp)
    800051b0:	6902                	ld	s2,0(sp)
    800051b2:	6105                	addi	sp,sp,32
    800051b4:	8082                	ret

00000000800051b6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800051b6:	1101                	addi	sp,sp,-32
    800051b8:	ec06                	sd	ra,24(sp)
    800051ba:	e822                	sd	s0,16(sp)
    800051bc:	e426                	sd	s1,8(sp)
    800051be:	e04a                	sd	s2,0(sp)
    800051c0:	1000                	addi	s0,sp,32
    800051c2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800051c4:	00850913          	addi	s2,a0,8
    800051c8:	854a                	mv	a0,s2
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	a22080e7          	jalr	-1502(ra) # 80000bec <acquire>
  while (lk->locked) {
    800051d2:	409c                	lw	a5,0(s1)
    800051d4:	cb89                	beqz	a5,800051e6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800051d6:	85ca                	mv	a1,s2
    800051d8:	8526                	mv	a0,s1
    800051da:	ffffe097          	auipc	ra,0xffffe
    800051de:	bd8080e7          	jalr	-1064(ra) # 80002db2 <sleep>
  while (lk->locked) {
    800051e2:	409c                	lw	a5,0(s1)
    800051e4:	fbed                	bnez	a5,800051d6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800051e6:	4785                	li	a5,1
    800051e8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800051ea:	ffffd097          	auipc	ra,0xffffd
    800051ee:	cb8080e7          	jalr	-840(ra) # 80001ea2 <myproc>
    800051f2:	453c                	lw	a5,72(a0)
    800051f4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800051f6:	854a                	mv	a0,s2
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	aae080e7          	jalr	-1362(ra) # 80000ca6 <release>
}
    80005200:	60e2                	ld	ra,24(sp)
    80005202:	6442                	ld	s0,16(sp)
    80005204:	64a2                	ld	s1,8(sp)
    80005206:	6902                	ld	s2,0(sp)
    80005208:	6105                	addi	sp,sp,32
    8000520a:	8082                	ret

000000008000520c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000520c:	1101                	addi	sp,sp,-32
    8000520e:	ec06                	sd	ra,24(sp)
    80005210:	e822                	sd	s0,16(sp)
    80005212:	e426                	sd	s1,8(sp)
    80005214:	e04a                	sd	s2,0(sp)
    80005216:	1000                	addi	s0,sp,32
    80005218:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000521a:	00850913          	addi	s2,a0,8
    8000521e:	854a                	mv	a0,s2
    80005220:	ffffc097          	auipc	ra,0xffffc
    80005224:	9cc080e7          	jalr	-1588(ra) # 80000bec <acquire>
  lk->locked = 0;
    80005228:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000522c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005230:	8526                	mv	a0,s1
    80005232:	ffffe097          	auipc	ra,0xffffe
    80005236:	d28080e7          	jalr	-728(ra) # 80002f5a <wakeup>
  release(&lk->lk);
    8000523a:	854a                	mv	a0,s2
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	a6a080e7          	jalr	-1430(ra) # 80000ca6 <release>
}
    80005244:	60e2                	ld	ra,24(sp)
    80005246:	6442                	ld	s0,16(sp)
    80005248:	64a2                	ld	s1,8(sp)
    8000524a:	6902                	ld	s2,0(sp)
    8000524c:	6105                	addi	sp,sp,32
    8000524e:	8082                	ret

0000000080005250 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005250:	7179                	addi	sp,sp,-48
    80005252:	f406                	sd	ra,40(sp)
    80005254:	f022                	sd	s0,32(sp)
    80005256:	ec26                	sd	s1,24(sp)
    80005258:	e84a                	sd	s2,16(sp)
    8000525a:	e44e                	sd	s3,8(sp)
    8000525c:	1800                	addi	s0,sp,48
    8000525e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005260:	00850913          	addi	s2,a0,8
    80005264:	854a                	mv	a0,s2
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	986080e7          	jalr	-1658(ra) # 80000bec <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000526e:	409c                	lw	a5,0(s1)
    80005270:	ef99                	bnez	a5,8000528e <holdingsleep+0x3e>
    80005272:	4481                	li	s1,0
  release(&lk->lk);
    80005274:	854a                	mv	a0,s2
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	a30080e7          	jalr	-1488(ra) # 80000ca6 <release>
  return r;
}
    8000527e:	8526                	mv	a0,s1
    80005280:	70a2                	ld	ra,40(sp)
    80005282:	7402                	ld	s0,32(sp)
    80005284:	64e2                	ld	s1,24(sp)
    80005286:	6942                	ld	s2,16(sp)
    80005288:	69a2                	ld	s3,8(sp)
    8000528a:	6145                	addi	sp,sp,48
    8000528c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000528e:	0284a983          	lw	s3,40(s1)
    80005292:	ffffd097          	auipc	ra,0xffffd
    80005296:	c10080e7          	jalr	-1008(ra) # 80001ea2 <myproc>
    8000529a:	4524                	lw	s1,72(a0)
    8000529c:	413484b3          	sub	s1,s1,s3
    800052a0:	0014b493          	seqz	s1,s1
    800052a4:	bfc1                	j	80005274 <holdingsleep+0x24>

00000000800052a6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800052a6:	1141                	addi	sp,sp,-16
    800052a8:	e406                	sd	ra,8(sp)
    800052aa:	e022                	sd	s0,0(sp)
    800052ac:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800052ae:	00004597          	auipc	a1,0x4
    800052b2:	5ca58593          	addi	a1,a1,1482 # 80009878 <syscalls+0x248>
    800052b6:	0001e517          	auipc	a0,0x1e
    800052ba:	a1250513          	addi	a0,a0,-1518 # 80022cc8 <ftable>
    800052be:	ffffc097          	auipc	ra,0xffffc
    800052c2:	896080e7          	jalr	-1898(ra) # 80000b54 <initlock>
}
    800052c6:	60a2                	ld	ra,8(sp)
    800052c8:	6402                	ld	s0,0(sp)
    800052ca:	0141                	addi	sp,sp,16
    800052cc:	8082                	ret

00000000800052ce <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800052ce:	1101                	addi	sp,sp,-32
    800052d0:	ec06                	sd	ra,24(sp)
    800052d2:	e822                	sd	s0,16(sp)
    800052d4:	e426                	sd	s1,8(sp)
    800052d6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800052d8:	0001e517          	auipc	a0,0x1e
    800052dc:	9f050513          	addi	a0,a0,-1552 # 80022cc8 <ftable>
    800052e0:	ffffc097          	auipc	ra,0xffffc
    800052e4:	90c080e7          	jalr	-1780(ra) # 80000bec <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800052e8:	0001e497          	auipc	s1,0x1e
    800052ec:	9f848493          	addi	s1,s1,-1544 # 80022ce0 <ftable+0x18>
    800052f0:	0001f717          	auipc	a4,0x1f
    800052f4:	99070713          	addi	a4,a4,-1648 # 80023c80 <ftable+0xfb8>
    if(f->ref == 0){
    800052f8:	40dc                	lw	a5,4(s1)
    800052fa:	cf99                	beqz	a5,80005318 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800052fc:	02848493          	addi	s1,s1,40
    80005300:	fee49ce3          	bne	s1,a4,800052f8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005304:	0001e517          	auipc	a0,0x1e
    80005308:	9c450513          	addi	a0,a0,-1596 # 80022cc8 <ftable>
    8000530c:	ffffc097          	auipc	ra,0xffffc
    80005310:	99a080e7          	jalr	-1638(ra) # 80000ca6 <release>
  return 0;
    80005314:	4481                	li	s1,0
    80005316:	a819                	j	8000532c <filealloc+0x5e>
      f->ref = 1;
    80005318:	4785                	li	a5,1
    8000531a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000531c:	0001e517          	auipc	a0,0x1e
    80005320:	9ac50513          	addi	a0,a0,-1620 # 80022cc8 <ftable>
    80005324:	ffffc097          	auipc	ra,0xffffc
    80005328:	982080e7          	jalr	-1662(ra) # 80000ca6 <release>
}
    8000532c:	8526                	mv	a0,s1
    8000532e:	60e2                	ld	ra,24(sp)
    80005330:	6442                	ld	s0,16(sp)
    80005332:	64a2                	ld	s1,8(sp)
    80005334:	6105                	addi	sp,sp,32
    80005336:	8082                	ret

0000000080005338 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005338:	1101                	addi	sp,sp,-32
    8000533a:	ec06                	sd	ra,24(sp)
    8000533c:	e822                	sd	s0,16(sp)
    8000533e:	e426                	sd	s1,8(sp)
    80005340:	1000                	addi	s0,sp,32
    80005342:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005344:	0001e517          	auipc	a0,0x1e
    80005348:	98450513          	addi	a0,a0,-1660 # 80022cc8 <ftable>
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	8a0080e7          	jalr	-1888(ra) # 80000bec <acquire>
  if(f->ref < 1)
    80005354:	40dc                	lw	a5,4(s1)
    80005356:	02f05263          	blez	a5,8000537a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000535a:	2785                	addiw	a5,a5,1
    8000535c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000535e:	0001e517          	auipc	a0,0x1e
    80005362:	96a50513          	addi	a0,a0,-1686 # 80022cc8 <ftable>
    80005366:	ffffc097          	auipc	ra,0xffffc
    8000536a:	940080e7          	jalr	-1728(ra) # 80000ca6 <release>
  return f;
}
    8000536e:	8526                	mv	a0,s1
    80005370:	60e2                	ld	ra,24(sp)
    80005372:	6442                	ld	s0,16(sp)
    80005374:	64a2                	ld	s1,8(sp)
    80005376:	6105                	addi	sp,sp,32
    80005378:	8082                	ret
    panic("filedup");
    8000537a:	00004517          	auipc	a0,0x4
    8000537e:	50650513          	addi	a0,a0,1286 # 80009880 <syscalls+0x250>
    80005382:	ffffb097          	auipc	ra,0xffffb
    80005386:	1bc080e7          	jalr	444(ra) # 8000053e <panic>

000000008000538a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000538a:	7139                	addi	sp,sp,-64
    8000538c:	fc06                	sd	ra,56(sp)
    8000538e:	f822                	sd	s0,48(sp)
    80005390:	f426                	sd	s1,40(sp)
    80005392:	f04a                	sd	s2,32(sp)
    80005394:	ec4e                	sd	s3,24(sp)
    80005396:	e852                	sd	s4,16(sp)
    80005398:	e456                	sd	s5,8(sp)
    8000539a:	0080                	addi	s0,sp,64
    8000539c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000539e:	0001e517          	auipc	a0,0x1e
    800053a2:	92a50513          	addi	a0,a0,-1750 # 80022cc8 <ftable>
    800053a6:	ffffc097          	auipc	ra,0xffffc
    800053aa:	846080e7          	jalr	-1978(ra) # 80000bec <acquire>
  if(f->ref < 1)
    800053ae:	40dc                	lw	a5,4(s1)
    800053b0:	06f05163          	blez	a5,80005412 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800053b4:	37fd                	addiw	a5,a5,-1
    800053b6:	0007871b          	sext.w	a4,a5
    800053ba:	c0dc                	sw	a5,4(s1)
    800053bc:	06e04363          	bgtz	a4,80005422 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800053c0:	0004a903          	lw	s2,0(s1)
    800053c4:	0094ca83          	lbu	s5,9(s1)
    800053c8:	0104ba03          	ld	s4,16(s1)
    800053cc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800053d0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800053d4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800053d8:	0001e517          	auipc	a0,0x1e
    800053dc:	8f050513          	addi	a0,a0,-1808 # 80022cc8 <ftable>
    800053e0:	ffffc097          	auipc	ra,0xffffc
    800053e4:	8c6080e7          	jalr	-1850(ra) # 80000ca6 <release>

  if(ff.type == FD_PIPE){
    800053e8:	4785                	li	a5,1
    800053ea:	04f90d63          	beq	s2,a5,80005444 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800053ee:	3979                	addiw	s2,s2,-2
    800053f0:	4785                	li	a5,1
    800053f2:	0527e063          	bltu	a5,s2,80005432 <fileclose+0xa8>
    begin_op();
    800053f6:	00000097          	auipc	ra,0x0
    800053fa:	ac8080e7          	jalr	-1336(ra) # 80004ebe <begin_op>
    iput(ff.ip);
    800053fe:	854e                	mv	a0,s3
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	2a6080e7          	jalr	678(ra) # 800046a6 <iput>
    end_op();
    80005408:	00000097          	auipc	ra,0x0
    8000540c:	b36080e7          	jalr	-1226(ra) # 80004f3e <end_op>
    80005410:	a00d                	j	80005432 <fileclose+0xa8>
    panic("fileclose");
    80005412:	00004517          	auipc	a0,0x4
    80005416:	47650513          	addi	a0,a0,1142 # 80009888 <syscalls+0x258>
    8000541a:	ffffb097          	auipc	ra,0xffffb
    8000541e:	124080e7          	jalr	292(ra) # 8000053e <panic>
    release(&ftable.lock);
    80005422:	0001e517          	auipc	a0,0x1e
    80005426:	8a650513          	addi	a0,a0,-1882 # 80022cc8 <ftable>
    8000542a:	ffffc097          	auipc	ra,0xffffc
    8000542e:	87c080e7          	jalr	-1924(ra) # 80000ca6 <release>
  }
}
    80005432:	70e2                	ld	ra,56(sp)
    80005434:	7442                	ld	s0,48(sp)
    80005436:	74a2                	ld	s1,40(sp)
    80005438:	7902                	ld	s2,32(sp)
    8000543a:	69e2                	ld	s3,24(sp)
    8000543c:	6a42                	ld	s4,16(sp)
    8000543e:	6aa2                	ld	s5,8(sp)
    80005440:	6121                	addi	sp,sp,64
    80005442:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005444:	85d6                	mv	a1,s5
    80005446:	8552                	mv	a0,s4
    80005448:	00000097          	auipc	ra,0x0
    8000544c:	34c080e7          	jalr	844(ra) # 80005794 <pipeclose>
    80005450:	b7cd                	j	80005432 <fileclose+0xa8>

0000000080005452 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005452:	715d                	addi	sp,sp,-80
    80005454:	e486                	sd	ra,72(sp)
    80005456:	e0a2                	sd	s0,64(sp)
    80005458:	fc26                	sd	s1,56(sp)
    8000545a:	f84a                	sd	s2,48(sp)
    8000545c:	f44e                	sd	s3,40(sp)
    8000545e:	0880                	addi	s0,sp,80
    80005460:	84aa                	mv	s1,a0
    80005462:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005464:	ffffd097          	auipc	ra,0xffffd
    80005468:	a3e080e7          	jalr	-1474(ra) # 80001ea2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000546c:	409c                	lw	a5,0(s1)
    8000546e:	37f9                	addiw	a5,a5,-2
    80005470:	4705                	li	a4,1
    80005472:	04f76763          	bltu	a4,a5,800054c0 <filestat+0x6e>
    80005476:	892a                	mv	s2,a0
    ilock(f->ip);
    80005478:	6c88                	ld	a0,24(s1)
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	072080e7          	jalr	114(ra) # 800044ec <ilock>
    stati(f->ip, &st);
    80005482:	fb840593          	addi	a1,s0,-72
    80005486:	6c88                	ld	a0,24(s1)
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	2ee080e7          	jalr	750(ra) # 80004776 <stati>
    iunlock(f->ip);
    80005490:	6c88                	ld	a0,24(s1)
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	11c080e7          	jalr	284(ra) # 800045ae <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000549a:	46e1                	li	a3,24
    8000549c:	fb840613          	addi	a2,s0,-72
    800054a0:	85ce                	mv	a1,s3
    800054a2:	07893503          	ld	a0,120(s2)
    800054a6:	ffffc097          	auipc	ra,0xffffc
    800054aa:	1da080e7          	jalr	474(ra) # 80001680 <copyout>
    800054ae:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800054b2:	60a6                	ld	ra,72(sp)
    800054b4:	6406                	ld	s0,64(sp)
    800054b6:	74e2                	ld	s1,56(sp)
    800054b8:	7942                	ld	s2,48(sp)
    800054ba:	79a2                	ld	s3,40(sp)
    800054bc:	6161                	addi	sp,sp,80
    800054be:	8082                	ret
  return -1;
    800054c0:	557d                	li	a0,-1
    800054c2:	bfc5                	j	800054b2 <filestat+0x60>

00000000800054c4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800054c4:	7179                	addi	sp,sp,-48
    800054c6:	f406                	sd	ra,40(sp)
    800054c8:	f022                	sd	s0,32(sp)
    800054ca:	ec26                	sd	s1,24(sp)
    800054cc:	e84a                	sd	s2,16(sp)
    800054ce:	e44e                	sd	s3,8(sp)
    800054d0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800054d2:	00854783          	lbu	a5,8(a0)
    800054d6:	c3d5                	beqz	a5,8000557a <fileread+0xb6>
    800054d8:	84aa                	mv	s1,a0
    800054da:	89ae                	mv	s3,a1
    800054dc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800054de:	411c                	lw	a5,0(a0)
    800054e0:	4705                	li	a4,1
    800054e2:	04e78963          	beq	a5,a4,80005534 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054e6:	470d                	li	a4,3
    800054e8:	04e78d63          	beq	a5,a4,80005542 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800054ec:	4709                	li	a4,2
    800054ee:	06e79e63          	bne	a5,a4,8000556a <fileread+0xa6>
    ilock(f->ip);
    800054f2:	6d08                	ld	a0,24(a0)
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	ff8080e7          	jalr	-8(ra) # 800044ec <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800054fc:	874a                	mv	a4,s2
    800054fe:	5094                	lw	a3,32(s1)
    80005500:	864e                	mv	a2,s3
    80005502:	4585                	li	a1,1
    80005504:	6c88                	ld	a0,24(s1)
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	29a080e7          	jalr	666(ra) # 800047a0 <readi>
    8000550e:	892a                	mv	s2,a0
    80005510:	00a05563          	blez	a0,8000551a <fileread+0x56>
      f->off += r;
    80005514:	509c                	lw	a5,32(s1)
    80005516:	9fa9                	addw	a5,a5,a0
    80005518:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000551a:	6c88                	ld	a0,24(s1)
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	092080e7          	jalr	146(ra) # 800045ae <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005524:	854a                	mv	a0,s2
    80005526:	70a2                	ld	ra,40(sp)
    80005528:	7402                	ld	s0,32(sp)
    8000552a:	64e2                	ld	s1,24(sp)
    8000552c:	6942                	ld	s2,16(sp)
    8000552e:	69a2                	ld	s3,8(sp)
    80005530:	6145                	addi	sp,sp,48
    80005532:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005534:	6908                	ld	a0,16(a0)
    80005536:	00000097          	auipc	ra,0x0
    8000553a:	3c8080e7          	jalr	968(ra) # 800058fe <piperead>
    8000553e:	892a                	mv	s2,a0
    80005540:	b7d5                	j	80005524 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005542:	02451783          	lh	a5,36(a0)
    80005546:	03079693          	slli	a3,a5,0x30
    8000554a:	92c1                	srli	a3,a3,0x30
    8000554c:	4725                	li	a4,9
    8000554e:	02d76863          	bltu	a4,a3,8000557e <fileread+0xba>
    80005552:	0792                	slli	a5,a5,0x4
    80005554:	0001d717          	auipc	a4,0x1d
    80005558:	6d470713          	addi	a4,a4,1748 # 80022c28 <devsw>
    8000555c:	97ba                	add	a5,a5,a4
    8000555e:	639c                	ld	a5,0(a5)
    80005560:	c38d                	beqz	a5,80005582 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005562:	4505                	li	a0,1
    80005564:	9782                	jalr	a5
    80005566:	892a                	mv	s2,a0
    80005568:	bf75                	j	80005524 <fileread+0x60>
    panic("fileread");
    8000556a:	00004517          	auipc	a0,0x4
    8000556e:	32e50513          	addi	a0,a0,814 # 80009898 <syscalls+0x268>
    80005572:	ffffb097          	auipc	ra,0xffffb
    80005576:	fcc080e7          	jalr	-52(ra) # 8000053e <panic>
    return -1;
    8000557a:	597d                	li	s2,-1
    8000557c:	b765                	j	80005524 <fileread+0x60>
      return -1;
    8000557e:	597d                	li	s2,-1
    80005580:	b755                	j	80005524 <fileread+0x60>
    80005582:	597d                	li	s2,-1
    80005584:	b745                	j	80005524 <fileread+0x60>

0000000080005586 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005586:	715d                	addi	sp,sp,-80
    80005588:	e486                	sd	ra,72(sp)
    8000558a:	e0a2                	sd	s0,64(sp)
    8000558c:	fc26                	sd	s1,56(sp)
    8000558e:	f84a                	sd	s2,48(sp)
    80005590:	f44e                	sd	s3,40(sp)
    80005592:	f052                	sd	s4,32(sp)
    80005594:	ec56                	sd	s5,24(sp)
    80005596:	e85a                	sd	s6,16(sp)
    80005598:	e45e                	sd	s7,8(sp)
    8000559a:	e062                	sd	s8,0(sp)
    8000559c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000559e:	00954783          	lbu	a5,9(a0)
    800055a2:	10078663          	beqz	a5,800056ae <filewrite+0x128>
    800055a6:	892a                	mv	s2,a0
    800055a8:	8aae                	mv	s5,a1
    800055aa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800055ac:	411c                	lw	a5,0(a0)
    800055ae:	4705                	li	a4,1
    800055b0:	02e78263          	beq	a5,a4,800055d4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800055b4:	470d                	li	a4,3
    800055b6:	02e78663          	beq	a5,a4,800055e2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800055ba:	4709                	li	a4,2
    800055bc:	0ee79163          	bne	a5,a4,8000569e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800055c0:	0ac05d63          	blez	a2,8000567a <filewrite+0xf4>
    int i = 0;
    800055c4:	4981                	li	s3,0
    800055c6:	6b05                	lui	s6,0x1
    800055c8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800055cc:	6b85                	lui	s7,0x1
    800055ce:	c00b8b9b          	addiw	s7,s7,-1024
    800055d2:	a861                	j	8000566a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800055d4:	6908                	ld	a0,16(a0)
    800055d6:	00000097          	auipc	ra,0x0
    800055da:	22e080e7          	jalr	558(ra) # 80005804 <pipewrite>
    800055de:	8a2a                	mv	s4,a0
    800055e0:	a045                	j	80005680 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800055e2:	02451783          	lh	a5,36(a0)
    800055e6:	03079693          	slli	a3,a5,0x30
    800055ea:	92c1                	srli	a3,a3,0x30
    800055ec:	4725                	li	a4,9
    800055ee:	0cd76263          	bltu	a4,a3,800056b2 <filewrite+0x12c>
    800055f2:	0792                	slli	a5,a5,0x4
    800055f4:	0001d717          	auipc	a4,0x1d
    800055f8:	63470713          	addi	a4,a4,1588 # 80022c28 <devsw>
    800055fc:	97ba                	add	a5,a5,a4
    800055fe:	679c                	ld	a5,8(a5)
    80005600:	cbdd                	beqz	a5,800056b6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005602:	4505                	li	a0,1
    80005604:	9782                	jalr	a5
    80005606:	8a2a                	mv	s4,a0
    80005608:	a8a5                	j	80005680 <filewrite+0xfa>
    8000560a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000560e:	00000097          	auipc	ra,0x0
    80005612:	8b0080e7          	jalr	-1872(ra) # 80004ebe <begin_op>
      ilock(f->ip);
    80005616:	01893503          	ld	a0,24(s2)
    8000561a:	fffff097          	auipc	ra,0xfffff
    8000561e:	ed2080e7          	jalr	-302(ra) # 800044ec <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005622:	8762                	mv	a4,s8
    80005624:	02092683          	lw	a3,32(s2)
    80005628:	01598633          	add	a2,s3,s5
    8000562c:	4585                	li	a1,1
    8000562e:	01893503          	ld	a0,24(s2)
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	266080e7          	jalr	614(ra) # 80004898 <writei>
    8000563a:	84aa                	mv	s1,a0
    8000563c:	00a05763          	blez	a0,8000564a <filewrite+0xc4>
        f->off += r;
    80005640:	02092783          	lw	a5,32(s2)
    80005644:	9fa9                	addw	a5,a5,a0
    80005646:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000564a:	01893503          	ld	a0,24(s2)
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	f60080e7          	jalr	-160(ra) # 800045ae <iunlock>
      end_op();
    80005656:	00000097          	auipc	ra,0x0
    8000565a:	8e8080e7          	jalr	-1816(ra) # 80004f3e <end_op>

      if(r != n1){
    8000565e:	009c1f63          	bne	s8,s1,8000567c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005662:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005666:	0149db63          	bge	s3,s4,8000567c <filewrite+0xf6>
      int n1 = n - i;
    8000566a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000566e:	84be                	mv	s1,a5
    80005670:	2781                	sext.w	a5,a5
    80005672:	f8fb5ce3          	bge	s6,a5,8000560a <filewrite+0x84>
    80005676:	84de                	mv	s1,s7
    80005678:	bf49                	j	8000560a <filewrite+0x84>
    int i = 0;
    8000567a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000567c:	013a1f63          	bne	s4,s3,8000569a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005680:	8552                	mv	a0,s4
    80005682:	60a6                	ld	ra,72(sp)
    80005684:	6406                	ld	s0,64(sp)
    80005686:	74e2                	ld	s1,56(sp)
    80005688:	7942                	ld	s2,48(sp)
    8000568a:	79a2                	ld	s3,40(sp)
    8000568c:	7a02                	ld	s4,32(sp)
    8000568e:	6ae2                	ld	s5,24(sp)
    80005690:	6b42                	ld	s6,16(sp)
    80005692:	6ba2                	ld	s7,8(sp)
    80005694:	6c02                	ld	s8,0(sp)
    80005696:	6161                	addi	sp,sp,80
    80005698:	8082                	ret
    ret = (i == n ? n : -1);
    8000569a:	5a7d                	li	s4,-1
    8000569c:	b7d5                	j	80005680 <filewrite+0xfa>
    panic("filewrite");
    8000569e:	00004517          	auipc	a0,0x4
    800056a2:	20a50513          	addi	a0,a0,522 # 800098a8 <syscalls+0x278>
    800056a6:	ffffb097          	auipc	ra,0xffffb
    800056aa:	e98080e7          	jalr	-360(ra) # 8000053e <panic>
    return -1;
    800056ae:	5a7d                	li	s4,-1
    800056b0:	bfc1                	j	80005680 <filewrite+0xfa>
      return -1;
    800056b2:	5a7d                	li	s4,-1
    800056b4:	b7f1                	j	80005680 <filewrite+0xfa>
    800056b6:	5a7d                	li	s4,-1
    800056b8:	b7e1                	j	80005680 <filewrite+0xfa>

00000000800056ba <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800056ba:	7179                	addi	sp,sp,-48
    800056bc:	f406                	sd	ra,40(sp)
    800056be:	f022                	sd	s0,32(sp)
    800056c0:	ec26                	sd	s1,24(sp)
    800056c2:	e84a                	sd	s2,16(sp)
    800056c4:	e44e                	sd	s3,8(sp)
    800056c6:	e052                	sd	s4,0(sp)
    800056c8:	1800                	addi	s0,sp,48
    800056ca:	84aa                	mv	s1,a0
    800056cc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800056ce:	0005b023          	sd	zero,0(a1)
    800056d2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800056d6:	00000097          	auipc	ra,0x0
    800056da:	bf8080e7          	jalr	-1032(ra) # 800052ce <filealloc>
    800056de:	e088                	sd	a0,0(s1)
    800056e0:	c551                	beqz	a0,8000576c <pipealloc+0xb2>
    800056e2:	00000097          	auipc	ra,0x0
    800056e6:	bec080e7          	jalr	-1044(ra) # 800052ce <filealloc>
    800056ea:	00aa3023          	sd	a0,0(s4)
    800056ee:	c92d                	beqz	a0,80005760 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800056f0:	ffffb097          	auipc	ra,0xffffb
    800056f4:	404080e7          	jalr	1028(ra) # 80000af4 <kalloc>
    800056f8:	892a                	mv	s2,a0
    800056fa:	c125                	beqz	a0,8000575a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800056fc:	4985                	li	s3,1
    800056fe:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005702:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005706:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000570a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000570e:	00004597          	auipc	a1,0x4
    80005712:	1aa58593          	addi	a1,a1,426 # 800098b8 <syscalls+0x288>
    80005716:	ffffb097          	auipc	ra,0xffffb
    8000571a:	43e080e7          	jalr	1086(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000571e:	609c                	ld	a5,0(s1)
    80005720:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005724:	609c                	ld	a5,0(s1)
    80005726:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000572a:	609c                	ld	a5,0(s1)
    8000572c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005730:	609c                	ld	a5,0(s1)
    80005732:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005736:	000a3783          	ld	a5,0(s4)
    8000573a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000573e:	000a3783          	ld	a5,0(s4)
    80005742:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005746:	000a3783          	ld	a5,0(s4)
    8000574a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000574e:	000a3783          	ld	a5,0(s4)
    80005752:	0127b823          	sd	s2,16(a5)
  return 0;
    80005756:	4501                	li	a0,0
    80005758:	a025                	j	80005780 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000575a:	6088                	ld	a0,0(s1)
    8000575c:	e501                	bnez	a0,80005764 <pipealloc+0xaa>
    8000575e:	a039                	j	8000576c <pipealloc+0xb2>
    80005760:	6088                	ld	a0,0(s1)
    80005762:	c51d                	beqz	a0,80005790 <pipealloc+0xd6>
    fileclose(*f0);
    80005764:	00000097          	auipc	ra,0x0
    80005768:	c26080e7          	jalr	-986(ra) # 8000538a <fileclose>
  if(*f1)
    8000576c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005770:	557d                	li	a0,-1
  if(*f1)
    80005772:	c799                	beqz	a5,80005780 <pipealloc+0xc6>
    fileclose(*f1);
    80005774:	853e                	mv	a0,a5
    80005776:	00000097          	auipc	ra,0x0
    8000577a:	c14080e7          	jalr	-1004(ra) # 8000538a <fileclose>
  return -1;
    8000577e:	557d                	li	a0,-1
}
    80005780:	70a2                	ld	ra,40(sp)
    80005782:	7402                	ld	s0,32(sp)
    80005784:	64e2                	ld	s1,24(sp)
    80005786:	6942                	ld	s2,16(sp)
    80005788:	69a2                	ld	s3,8(sp)
    8000578a:	6a02                	ld	s4,0(sp)
    8000578c:	6145                	addi	sp,sp,48
    8000578e:	8082                	ret
  return -1;
    80005790:	557d                	li	a0,-1
    80005792:	b7fd                	j	80005780 <pipealloc+0xc6>

0000000080005794 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005794:	1101                	addi	sp,sp,-32
    80005796:	ec06                	sd	ra,24(sp)
    80005798:	e822                	sd	s0,16(sp)
    8000579a:	e426                	sd	s1,8(sp)
    8000579c:	e04a                	sd	s2,0(sp)
    8000579e:	1000                	addi	s0,sp,32
    800057a0:	84aa                	mv	s1,a0
    800057a2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800057a4:	ffffb097          	auipc	ra,0xffffb
    800057a8:	448080e7          	jalr	1096(ra) # 80000bec <acquire>
  if(writable){
    800057ac:	02090d63          	beqz	s2,800057e6 <pipeclose+0x52>
    pi->writeopen = 0;
    800057b0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800057b4:	21848513          	addi	a0,s1,536
    800057b8:	ffffd097          	auipc	ra,0xffffd
    800057bc:	7a2080e7          	jalr	1954(ra) # 80002f5a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800057c0:	2204b783          	ld	a5,544(s1)
    800057c4:	eb95                	bnez	a5,800057f8 <pipeclose+0x64>
    release(&pi->lock);
    800057c6:	8526                	mv	a0,s1
    800057c8:	ffffb097          	auipc	ra,0xffffb
    800057cc:	4de080e7          	jalr	1246(ra) # 80000ca6 <release>
    kfree((char*)pi);
    800057d0:	8526                	mv	a0,s1
    800057d2:	ffffb097          	auipc	ra,0xffffb
    800057d6:	226080e7          	jalr	550(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800057da:	60e2                	ld	ra,24(sp)
    800057dc:	6442                	ld	s0,16(sp)
    800057de:	64a2                	ld	s1,8(sp)
    800057e0:	6902                	ld	s2,0(sp)
    800057e2:	6105                	addi	sp,sp,32
    800057e4:	8082                	ret
    pi->readopen = 0;
    800057e6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800057ea:	21c48513          	addi	a0,s1,540
    800057ee:	ffffd097          	auipc	ra,0xffffd
    800057f2:	76c080e7          	jalr	1900(ra) # 80002f5a <wakeup>
    800057f6:	b7e9                	j	800057c0 <pipeclose+0x2c>
    release(&pi->lock);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffb097          	auipc	ra,0xffffb
    800057fe:	4ac080e7          	jalr	1196(ra) # 80000ca6 <release>
}
    80005802:	bfe1                	j	800057da <pipeclose+0x46>

0000000080005804 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005804:	7159                	addi	sp,sp,-112
    80005806:	f486                	sd	ra,104(sp)
    80005808:	f0a2                	sd	s0,96(sp)
    8000580a:	eca6                	sd	s1,88(sp)
    8000580c:	e8ca                	sd	s2,80(sp)
    8000580e:	e4ce                	sd	s3,72(sp)
    80005810:	e0d2                	sd	s4,64(sp)
    80005812:	fc56                	sd	s5,56(sp)
    80005814:	f85a                	sd	s6,48(sp)
    80005816:	f45e                	sd	s7,40(sp)
    80005818:	f062                	sd	s8,32(sp)
    8000581a:	ec66                	sd	s9,24(sp)
    8000581c:	1880                	addi	s0,sp,112
    8000581e:	84aa                	mv	s1,a0
    80005820:	8aae                	mv	s5,a1
    80005822:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005824:	ffffc097          	auipc	ra,0xffffc
    80005828:	67e080e7          	jalr	1662(ra) # 80001ea2 <myproc>
    8000582c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffb097          	auipc	ra,0xffffb
    80005834:	3bc080e7          	jalr	956(ra) # 80000bec <acquire>
  while(i < n){
    80005838:	0d405163          	blez	s4,800058fa <pipewrite+0xf6>
    8000583c:	8ba6                	mv	s7,s1
  int i = 0;
    8000583e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005840:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005842:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005846:	21c48c13          	addi	s8,s1,540
    8000584a:	a08d                	j	800058ac <pipewrite+0xa8>
      release(&pi->lock);
    8000584c:	8526                	mv	a0,s1
    8000584e:	ffffb097          	auipc	ra,0xffffb
    80005852:	458080e7          	jalr	1112(ra) # 80000ca6 <release>
      return -1;
    80005856:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005858:	854a                	mv	a0,s2
    8000585a:	70a6                	ld	ra,104(sp)
    8000585c:	7406                	ld	s0,96(sp)
    8000585e:	64e6                	ld	s1,88(sp)
    80005860:	6946                	ld	s2,80(sp)
    80005862:	69a6                	ld	s3,72(sp)
    80005864:	6a06                	ld	s4,64(sp)
    80005866:	7ae2                	ld	s5,56(sp)
    80005868:	7b42                	ld	s6,48(sp)
    8000586a:	7ba2                	ld	s7,40(sp)
    8000586c:	7c02                	ld	s8,32(sp)
    8000586e:	6ce2                	ld	s9,24(sp)
    80005870:	6165                	addi	sp,sp,112
    80005872:	8082                	ret
      wakeup(&pi->nread);
    80005874:	8566                	mv	a0,s9
    80005876:	ffffd097          	auipc	ra,0xffffd
    8000587a:	6e4080e7          	jalr	1764(ra) # 80002f5a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000587e:	85de                	mv	a1,s7
    80005880:	8562                	mv	a0,s8
    80005882:	ffffd097          	auipc	ra,0xffffd
    80005886:	530080e7          	jalr	1328(ra) # 80002db2 <sleep>
    8000588a:	a839                	j	800058a8 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000588c:	21c4a783          	lw	a5,540(s1)
    80005890:	0017871b          	addiw	a4,a5,1
    80005894:	20e4ae23          	sw	a4,540(s1)
    80005898:	1ff7f793          	andi	a5,a5,511
    8000589c:	97a6                	add	a5,a5,s1
    8000589e:	f9f44703          	lbu	a4,-97(s0)
    800058a2:	00e78c23          	sb	a4,24(a5)
      i++;
    800058a6:	2905                	addiw	s2,s2,1
  while(i < n){
    800058a8:	03495d63          	bge	s2,s4,800058e2 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800058ac:	2204a783          	lw	a5,544(s1)
    800058b0:	dfd1                	beqz	a5,8000584c <pipewrite+0x48>
    800058b2:	0409a783          	lw	a5,64(s3)
    800058b6:	fbd9                	bnez	a5,8000584c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800058b8:	2184a783          	lw	a5,536(s1)
    800058bc:	21c4a703          	lw	a4,540(s1)
    800058c0:	2007879b          	addiw	a5,a5,512
    800058c4:	faf708e3          	beq	a4,a5,80005874 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800058c8:	4685                	li	a3,1
    800058ca:	01590633          	add	a2,s2,s5
    800058ce:	f9f40593          	addi	a1,s0,-97
    800058d2:	0789b503          	ld	a0,120(s3)
    800058d6:	ffffc097          	auipc	ra,0xffffc
    800058da:	e36080e7          	jalr	-458(ra) # 8000170c <copyin>
    800058de:	fb6517e3          	bne	a0,s6,8000588c <pipewrite+0x88>
  wakeup(&pi->nread);
    800058e2:	21848513          	addi	a0,s1,536
    800058e6:	ffffd097          	auipc	ra,0xffffd
    800058ea:	674080e7          	jalr	1652(ra) # 80002f5a <wakeup>
  release(&pi->lock);
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffb097          	auipc	ra,0xffffb
    800058f4:	3b6080e7          	jalr	950(ra) # 80000ca6 <release>
  return i;
    800058f8:	b785                	j	80005858 <pipewrite+0x54>
  int i = 0;
    800058fa:	4901                	li	s2,0
    800058fc:	b7dd                	j	800058e2 <pipewrite+0xde>

00000000800058fe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800058fe:	715d                	addi	sp,sp,-80
    80005900:	e486                	sd	ra,72(sp)
    80005902:	e0a2                	sd	s0,64(sp)
    80005904:	fc26                	sd	s1,56(sp)
    80005906:	f84a                	sd	s2,48(sp)
    80005908:	f44e                	sd	s3,40(sp)
    8000590a:	f052                	sd	s4,32(sp)
    8000590c:	ec56                	sd	s5,24(sp)
    8000590e:	e85a                	sd	s6,16(sp)
    80005910:	0880                	addi	s0,sp,80
    80005912:	84aa                	mv	s1,a0
    80005914:	892e                	mv	s2,a1
    80005916:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005918:	ffffc097          	auipc	ra,0xffffc
    8000591c:	58a080e7          	jalr	1418(ra) # 80001ea2 <myproc>
    80005920:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005922:	8b26                	mv	s6,s1
    80005924:	8526                	mv	a0,s1
    80005926:	ffffb097          	auipc	ra,0xffffb
    8000592a:	2c6080e7          	jalr	710(ra) # 80000bec <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000592e:	2184a703          	lw	a4,536(s1)
    80005932:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005936:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000593a:	02f71463          	bne	a4,a5,80005962 <piperead+0x64>
    8000593e:	2244a783          	lw	a5,548(s1)
    80005942:	c385                	beqz	a5,80005962 <piperead+0x64>
    if(pr->killed){
    80005944:	040a2783          	lw	a5,64(s4)
    80005948:	ebc1                	bnez	a5,800059d8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000594a:	85da                	mv	a1,s6
    8000594c:	854e                	mv	a0,s3
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	464080e7          	jalr	1124(ra) # 80002db2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005956:	2184a703          	lw	a4,536(s1)
    8000595a:	21c4a783          	lw	a5,540(s1)
    8000595e:	fef700e3          	beq	a4,a5,8000593e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005962:	09505263          	blez	s5,800059e6 <piperead+0xe8>
    80005966:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005968:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000596a:	2184a783          	lw	a5,536(s1)
    8000596e:	21c4a703          	lw	a4,540(s1)
    80005972:	02f70d63          	beq	a4,a5,800059ac <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005976:	0017871b          	addiw	a4,a5,1
    8000597a:	20e4ac23          	sw	a4,536(s1)
    8000597e:	1ff7f793          	andi	a5,a5,511
    80005982:	97a6                	add	a5,a5,s1
    80005984:	0187c783          	lbu	a5,24(a5)
    80005988:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000598c:	4685                	li	a3,1
    8000598e:	fbf40613          	addi	a2,s0,-65
    80005992:	85ca                	mv	a1,s2
    80005994:	078a3503          	ld	a0,120(s4)
    80005998:	ffffc097          	auipc	ra,0xffffc
    8000599c:	ce8080e7          	jalr	-792(ra) # 80001680 <copyout>
    800059a0:	01650663          	beq	a0,s6,800059ac <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800059a4:	2985                	addiw	s3,s3,1
    800059a6:	0905                	addi	s2,s2,1
    800059a8:	fd3a91e3          	bne	s5,s3,8000596a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800059ac:	21c48513          	addi	a0,s1,540
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	5aa080e7          	jalr	1450(ra) # 80002f5a <wakeup>
  release(&pi->lock);
    800059b8:	8526                	mv	a0,s1
    800059ba:	ffffb097          	auipc	ra,0xffffb
    800059be:	2ec080e7          	jalr	748(ra) # 80000ca6 <release>
  return i;
}
    800059c2:	854e                	mv	a0,s3
    800059c4:	60a6                	ld	ra,72(sp)
    800059c6:	6406                	ld	s0,64(sp)
    800059c8:	74e2                	ld	s1,56(sp)
    800059ca:	7942                	ld	s2,48(sp)
    800059cc:	79a2                	ld	s3,40(sp)
    800059ce:	7a02                	ld	s4,32(sp)
    800059d0:	6ae2                	ld	s5,24(sp)
    800059d2:	6b42                	ld	s6,16(sp)
    800059d4:	6161                	addi	sp,sp,80
    800059d6:	8082                	ret
      release(&pi->lock);
    800059d8:	8526                	mv	a0,s1
    800059da:	ffffb097          	auipc	ra,0xffffb
    800059de:	2cc080e7          	jalr	716(ra) # 80000ca6 <release>
      return -1;
    800059e2:	59fd                	li	s3,-1
    800059e4:	bff9                	j	800059c2 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800059e6:	4981                	li	s3,0
    800059e8:	b7d1                	j	800059ac <piperead+0xae>

00000000800059ea <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800059ea:	df010113          	addi	sp,sp,-528
    800059ee:	20113423          	sd	ra,520(sp)
    800059f2:	20813023          	sd	s0,512(sp)
    800059f6:	ffa6                	sd	s1,504(sp)
    800059f8:	fbca                	sd	s2,496(sp)
    800059fa:	f7ce                	sd	s3,488(sp)
    800059fc:	f3d2                	sd	s4,480(sp)
    800059fe:	efd6                	sd	s5,472(sp)
    80005a00:	ebda                	sd	s6,464(sp)
    80005a02:	e7de                	sd	s7,456(sp)
    80005a04:	e3e2                	sd	s8,448(sp)
    80005a06:	ff66                	sd	s9,440(sp)
    80005a08:	fb6a                	sd	s10,432(sp)
    80005a0a:	f76e                	sd	s11,424(sp)
    80005a0c:	0c00                	addi	s0,sp,528
    80005a0e:	84aa                	mv	s1,a0
    80005a10:	dea43c23          	sd	a0,-520(s0)
    80005a14:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005a18:	ffffc097          	auipc	ra,0xffffc
    80005a1c:	48a080e7          	jalr	1162(ra) # 80001ea2 <myproc>
    80005a20:	892a                	mv	s2,a0

  begin_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	49c080e7          	jalr	1180(ra) # 80004ebe <begin_op>

  if((ip = namei(path)) == 0){
    80005a2a:	8526                	mv	a0,s1
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	276080e7          	jalr	630(ra) # 80004ca2 <namei>
    80005a34:	c92d                	beqz	a0,80005aa6 <exec+0xbc>
    80005a36:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	ab4080e7          	jalr	-1356(ra) # 800044ec <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005a40:	04000713          	li	a4,64
    80005a44:	4681                	li	a3,0
    80005a46:	e5040613          	addi	a2,s0,-432
    80005a4a:	4581                	li	a1,0
    80005a4c:	8526                	mv	a0,s1
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	d52080e7          	jalr	-686(ra) # 800047a0 <readi>
    80005a56:	04000793          	li	a5,64
    80005a5a:	00f51a63          	bne	a0,a5,80005a6e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005a5e:	e5042703          	lw	a4,-432(s0)
    80005a62:	464c47b7          	lui	a5,0x464c4
    80005a66:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005a6a:	04f70463          	beq	a4,a5,80005ab2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005a6e:	8526                	mv	a0,s1
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	cde080e7          	jalr	-802(ra) # 8000474e <iunlockput>
    end_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	4c6080e7          	jalr	1222(ra) # 80004f3e <end_op>
  }
  return -1;
    80005a80:	557d                	li	a0,-1
}
    80005a82:	20813083          	ld	ra,520(sp)
    80005a86:	20013403          	ld	s0,512(sp)
    80005a8a:	74fe                	ld	s1,504(sp)
    80005a8c:	795e                	ld	s2,496(sp)
    80005a8e:	79be                	ld	s3,488(sp)
    80005a90:	7a1e                	ld	s4,480(sp)
    80005a92:	6afe                	ld	s5,472(sp)
    80005a94:	6b5e                	ld	s6,464(sp)
    80005a96:	6bbe                	ld	s7,456(sp)
    80005a98:	6c1e                	ld	s8,448(sp)
    80005a9a:	7cfa                	ld	s9,440(sp)
    80005a9c:	7d5a                	ld	s10,432(sp)
    80005a9e:	7dba                	ld	s11,424(sp)
    80005aa0:	21010113          	addi	sp,sp,528
    80005aa4:	8082                	ret
    end_op();
    80005aa6:	fffff097          	auipc	ra,0xfffff
    80005aaa:	498080e7          	jalr	1176(ra) # 80004f3e <end_op>
    return -1;
    80005aae:	557d                	li	a0,-1
    80005ab0:	bfc9                	j	80005a82 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005ab2:	854a                	mv	a0,s2
    80005ab4:	ffffc097          	auipc	ra,0xffffc
    80005ab8:	4c6080e7          	jalr	1222(ra) # 80001f7a <proc_pagetable>
    80005abc:	8baa                	mv	s7,a0
    80005abe:	d945                	beqz	a0,80005a6e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005ac0:	e7042983          	lw	s3,-400(s0)
    80005ac4:	e8845783          	lhu	a5,-376(s0)
    80005ac8:	c7ad                	beqz	a5,80005b32 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005aca:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005acc:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005ace:	6c85                	lui	s9,0x1
    80005ad0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005ad4:	def43823          	sd	a5,-528(s0)
    80005ad8:	a42d                	j	80005d02 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005ada:	00004517          	auipc	a0,0x4
    80005ade:	de650513          	addi	a0,a0,-538 # 800098c0 <syscalls+0x290>
    80005ae2:	ffffb097          	auipc	ra,0xffffb
    80005ae6:	a5c080e7          	jalr	-1444(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005aea:	8756                	mv	a4,s5
    80005aec:	012d86bb          	addw	a3,s11,s2
    80005af0:	4581                	li	a1,0
    80005af2:	8526                	mv	a0,s1
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	cac080e7          	jalr	-852(ra) # 800047a0 <readi>
    80005afc:	2501                	sext.w	a0,a0
    80005afe:	1aaa9963          	bne	s5,a0,80005cb0 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005b02:	6785                	lui	a5,0x1
    80005b04:	0127893b          	addw	s2,a5,s2
    80005b08:	77fd                	lui	a5,0xfffff
    80005b0a:	01478a3b          	addw	s4,a5,s4
    80005b0e:	1f897163          	bgeu	s2,s8,80005cf0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005b12:	02091593          	slli	a1,s2,0x20
    80005b16:	9181                	srli	a1,a1,0x20
    80005b18:	95ea                	add	a1,a1,s10
    80005b1a:	855e                	mv	a0,s7
    80005b1c:	ffffb097          	auipc	ra,0xffffb
    80005b20:	560080e7          	jalr	1376(ra) # 8000107c <walkaddr>
    80005b24:	862a                	mv	a2,a0
    if(pa == 0)
    80005b26:	d955                	beqz	a0,80005ada <exec+0xf0>
      n = PGSIZE;
    80005b28:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005b2a:	fd9a70e3          	bgeu	s4,s9,80005aea <exec+0x100>
      n = sz - i;
    80005b2e:	8ad2                	mv	s5,s4
    80005b30:	bf6d                	j	80005aea <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005b32:	4901                	li	s2,0
  iunlockput(ip);
    80005b34:	8526                	mv	a0,s1
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	c18080e7          	jalr	-1000(ra) # 8000474e <iunlockput>
  end_op();
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	400080e7          	jalr	1024(ra) # 80004f3e <end_op>
  p = myproc();
    80005b46:	ffffc097          	auipc	ra,0xffffc
    80005b4a:	35c080e7          	jalr	860(ra) # 80001ea2 <myproc>
    80005b4e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005b50:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80005b54:	6785                	lui	a5,0x1
    80005b56:	17fd                	addi	a5,a5,-1
    80005b58:	993e                	add	s2,s2,a5
    80005b5a:	757d                	lui	a0,0xfffff
    80005b5c:	00a977b3          	and	a5,s2,a0
    80005b60:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b64:	6609                	lui	a2,0x2
    80005b66:	963e                	add	a2,a2,a5
    80005b68:	85be                	mv	a1,a5
    80005b6a:	855e                	mv	a0,s7
    80005b6c:	ffffc097          	auipc	ra,0xffffc
    80005b70:	8c4080e7          	jalr	-1852(ra) # 80001430 <uvmalloc>
    80005b74:	8b2a                	mv	s6,a0
  ip = 0;
    80005b76:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005b78:	12050c63          	beqz	a0,80005cb0 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005b7c:	75f9                	lui	a1,0xffffe
    80005b7e:	95aa                	add	a1,a1,a0
    80005b80:	855e                	mv	a0,s7
    80005b82:	ffffc097          	auipc	ra,0xffffc
    80005b86:	acc080e7          	jalr	-1332(ra) # 8000164e <uvmclear>
  stackbase = sp - PGSIZE;
    80005b8a:	7c7d                	lui	s8,0xfffff
    80005b8c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005b8e:	e0043783          	ld	a5,-512(s0)
    80005b92:	6388                	ld	a0,0(a5)
    80005b94:	c535                	beqz	a0,80005c00 <exec+0x216>
    80005b96:	e9040993          	addi	s3,s0,-368
    80005b9a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005b9e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005ba0:	ffffb097          	auipc	ra,0xffffb
    80005ba4:	2d2080e7          	jalr	722(ra) # 80000e72 <strlen>
    80005ba8:	2505                	addiw	a0,a0,1
    80005baa:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005bae:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005bb2:	13896363          	bltu	s2,s8,80005cd8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005bb6:	e0043d83          	ld	s11,-512(s0)
    80005bba:	000dba03          	ld	s4,0(s11)
    80005bbe:	8552                	mv	a0,s4
    80005bc0:	ffffb097          	auipc	ra,0xffffb
    80005bc4:	2b2080e7          	jalr	690(ra) # 80000e72 <strlen>
    80005bc8:	0015069b          	addiw	a3,a0,1
    80005bcc:	8652                	mv	a2,s4
    80005bce:	85ca                	mv	a1,s2
    80005bd0:	855e                	mv	a0,s7
    80005bd2:	ffffc097          	auipc	ra,0xffffc
    80005bd6:	aae080e7          	jalr	-1362(ra) # 80001680 <copyout>
    80005bda:	10054363          	bltz	a0,80005ce0 <exec+0x2f6>
    ustack[argc] = sp;
    80005bde:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005be2:	0485                	addi	s1,s1,1
    80005be4:	008d8793          	addi	a5,s11,8
    80005be8:	e0f43023          	sd	a5,-512(s0)
    80005bec:	008db503          	ld	a0,8(s11)
    80005bf0:	c911                	beqz	a0,80005c04 <exec+0x21a>
    if(argc >= MAXARG)
    80005bf2:	09a1                	addi	s3,s3,8
    80005bf4:	fb3c96e3          	bne	s9,s3,80005ba0 <exec+0x1b6>
  sz = sz1;
    80005bf8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005bfc:	4481                	li	s1,0
    80005bfe:	a84d                	j	80005cb0 <exec+0x2c6>
  sp = sz;
    80005c00:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005c02:	4481                	li	s1,0
  ustack[argc] = 0;
    80005c04:	00349793          	slli	a5,s1,0x3
    80005c08:	f9040713          	addi	a4,s0,-112
    80005c0c:	97ba                	add	a5,a5,a4
    80005c0e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005c12:	00148693          	addi	a3,s1,1
    80005c16:	068e                	slli	a3,a3,0x3
    80005c18:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005c1c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005c20:	01897663          	bgeu	s2,s8,80005c2c <exec+0x242>
  sz = sz1;
    80005c24:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005c28:	4481                	li	s1,0
    80005c2a:	a059                	j	80005cb0 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005c2c:	e9040613          	addi	a2,s0,-368
    80005c30:	85ca                	mv	a1,s2
    80005c32:	855e                	mv	a0,s7
    80005c34:	ffffc097          	auipc	ra,0xffffc
    80005c38:	a4c080e7          	jalr	-1460(ra) # 80001680 <copyout>
    80005c3c:	0a054663          	bltz	a0,80005ce8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005c40:	080ab783          	ld	a5,128(s5)
    80005c44:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005c48:	df843783          	ld	a5,-520(s0)
    80005c4c:	0007c703          	lbu	a4,0(a5)
    80005c50:	cf11                	beqz	a4,80005c6c <exec+0x282>
    80005c52:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005c54:	02f00693          	li	a3,47
    80005c58:	a039                	j	80005c66 <exec+0x27c>
      last = s+1;
    80005c5a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005c5e:	0785                	addi	a5,a5,1
    80005c60:	fff7c703          	lbu	a4,-1(a5)
    80005c64:	c701                	beqz	a4,80005c6c <exec+0x282>
    if(*s == '/')
    80005c66:	fed71ce3          	bne	a4,a3,80005c5e <exec+0x274>
    80005c6a:	bfc5                	j	80005c5a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005c6c:	4641                	li	a2,16
    80005c6e:	df843583          	ld	a1,-520(s0)
    80005c72:	180a8513          	addi	a0,s5,384
    80005c76:	ffffb097          	auipc	ra,0xffffb
    80005c7a:	1ca080e7          	jalr	458(ra) # 80000e40 <safestrcpy>
  oldpagetable = p->pagetable;
    80005c7e:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    80005c82:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    80005c86:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005c8a:	080ab783          	ld	a5,128(s5)
    80005c8e:	e6843703          	ld	a4,-408(s0)
    80005c92:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005c94:	080ab783          	ld	a5,128(s5)
    80005c98:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005c9c:	85ea                	mv	a1,s10
    80005c9e:	ffffc097          	auipc	ra,0xffffc
    80005ca2:	378080e7          	jalr	888(ra) # 80002016 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005ca6:	0004851b          	sext.w	a0,s1
    80005caa:	bbe1                	j	80005a82 <exec+0x98>
    80005cac:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005cb0:	e0843583          	ld	a1,-504(s0)
    80005cb4:	855e                	mv	a0,s7
    80005cb6:	ffffc097          	auipc	ra,0xffffc
    80005cba:	360080e7          	jalr	864(ra) # 80002016 <proc_freepagetable>
  if(ip){
    80005cbe:	da0498e3          	bnez	s1,80005a6e <exec+0x84>
  return -1;
    80005cc2:	557d                	li	a0,-1
    80005cc4:	bb7d                	j	80005a82 <exec+0x98>
    80005cc6:	e1243423          	sd	s2,-504(s0)
    80005cca:	b7dd                	j	80005cb0 <exec+0x2c6>
    80005ccc:	e1243423          	sd	s2,-504(s0)
    80005cd0:	b7c5                	j	80005cb0 <exec+0x2c6>
    80005cd2:	e1243423          	sd	s2,-504(s0)
    80005cd6:	bfe9                	j	80005cb0 <exec+0x2c6>
  sz = sz1;
    80005cd8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005cdc:	4481                	li	s1,0
    80005cde:	bfc9                	j	80005cb0 <exec+0x2c6>
  sz = sz1;
    80005ce0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ce4:	4481                	li	s1,0
    80005ce6:	b7e9                	j	80005cb0 <exec+0x2c6>
  sz = sz1;
    80005ce8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005cec:	4481                	li	s1,0
    80005cee:	b7c9                	j	80005cb0 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005cf0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005cf4:	2b05                	addiw	s6,s6,1
    80005cf6:	0389899b          	addiw	s3,s3,56
    80005cfa:	e8845783          	lhu	a5,-376(s0)
    80005cfe:	e2fb5be3          	bge	s6,a5,80005b34 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005d02:	2981                	sext.w	s3,s3
    80005d04:	03800713          	li	a4,56
    80005d08:	86ce                	mv	a3,s3
    80005d0a:	e1840613          	addi	a2,s0,-488
    80005d0e:	4581                	li	a1,0
    80005d10:	8526                	mv	a0,s1
    80005d12:	fffff097          	auipc	ra,0xfffff
    80005d16:	a8e080e7          	jalr	-1394(ra) # 800047a0 <readi>
    80005d1a:	03800793          	li	a5,56
    80005d1e:	f8f517e3          	bne	a0,a5,80005cac <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005d22:	e1842783          	lw	a5,-488(s0)
    80005d26:	4705                	li	a4,1
    80005d28:	fce796e3          	bne	a5,a4,80005cf4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005d2c:	e4043603          	ld	a2,-448(s0)
    80005d30:	e3843783          	ld	a5,-456(s0)
    80005d34:	f8f669e3          	bltu	a2,a5,80005cc6 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005d38:	e2843783          	ld	a5,-472(s0)
    80005d3c:	963e                	add	a2,a2,a5
    80005d3e:	f8f667e3          	bltu	a2,a5,80005ccc <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005d42:	85ca                	mv	a1,s2
    80005d44:	855e                	mv	a0,s7
    80005d46:	ffffb097          	auipc	ra,0xffffb
    80005d4a:	6ea080e7          	jalr	1770(ra) # 80001430 <uvmalloc>
    80005d4e:	e0a43423          	sd	a0,-504(s0)
    80005d52:	d141                	beqz	a0,80005cd2 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005d54:	e2843d03          	ld	s10,-472(s0)
    80005d58:	df043783          	ld	a5,-528(s0)
    80005d5c:	00fd77b3          	and	a5,s10,a5
    80005d60:	fba1                	bnez	a5,80005cb0 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005d62:	e2042d83          	lw	s11,-480(s0)
    80005d66:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005d6a:	f80c03e3          	beqz	s8,80005cf0 <exec+0x306>
    80005d6e:	8a62                	mv	s4,s8
    80005d70:	4901                	li	s2,0
    80005d72:	b345                	j	80005b12 <exec+0x128>

0000000080005d74 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005d74:	7179                	addi	sp,sp,-48
    80005d76:	f406                	sd	ra,40(sp)
    80005d78:	f022                	sd	s0,32(sp)
    80005d7a:	ec26                	sd	s1,24(sp)
    80005d7c:	e84a                	sd	s2,16(sp)
    80005d7e:	1800                	addi	s0,sp,48
    80005d80:	892e                	mv	s2,a1
    80005d82:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005d84:	fdc40593          	addi	a1,s0,-36
    80005d88:	ffffe097          	auipc	ra,0xffffe
    80005d8c:	ba8080e7          	jalr	-1112(ra) # 80003930 <argint>
    80005d90:	04054063          	bltz	a0,80005dd0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005d94:	fdc42703          	lw	a4,-36(s0)
    80005d98:	47bd                	li	a5,15
    80005d9a:	02e7ed63          	bltu	a5,a4,80005dd4 <argfd+0x60>
    80005d9e:	ffffc097          	auipc	ra,0xffffc
    80005da2:	104080e7          	jalr	260(ra) # 80001ea2 <myproc>
    80005da6:	fdc42703          	lw	a4,-36(s0)
    80005daa:	01e70793          	addi	a5,a4,30
    80005dae:	078e                	slli	a5,a5,0x3
    80005db0:	953e                	add	a0,a0,a5
    80005db2:	651c                	ld	a5,8(a0)
    80005db4:	c395                	beqz	a5,80005dd8 <argfd+0x64>
    return -1;
  if(pfd)
    80005db6:	00090463          	beqz	s2,80005dbe <argfd+0x4a>
    *pfd = fd;
    80005dba:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005dbe:	4501                	li	a0,0
  if(pf)
    80005dc0:	c091                	beqz	s1,80005dc4 <argfd+0x50>
    *pf = f;
    80005dc2:	e09c                	sd	a5,0(s1)
}
    80005dc4:	70a2                	ld	ra,40(sp)
    80005dc6:	7402                	ld	s0,32(sp)
    80005dc8:	64e2                	ld	s1,24(sp)
    80005dca:	6942                	ld	s2,16(sp)
    80005dcc:	6145                	addi	sp,sp,48
    80005dce:	8082                	ret
    return -1;
    80005dd0:	557d                	li	a0,-1
    80005dd2:	bfcd                	j	80005dc4 <argfd+0x50>
    return -1;
    80005dd4:	557d                	li	a0,-1
    80005dd6:	b7fd                	j	80005dc4 <argfd+0x50>
    80005dd8:	557d                	li	a0,-1
    80005dda:	b7ed                	j	80005dc4 <argfd+0x50>

0000000080005ddc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005ddc:	1101                	addi	sp,sp,-32
    80005dde:	ec06                	sd	ra,24(sp)
    80005de0:	e822                	sd	s0,16(sp)
    80005de2:	e426                	sd	s1,8(sp)
    80005de4:	1000                	addi	s0,sp,32
    80005de6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	0ba080e7          	jalr	186(ra) # 80001ea2 <myproc>
    80005df0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005df2:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd80f8>
    80005df6:	4501                	li	a0,0
    80005df8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005dfa:	6398                	ld	a4,0(a5)
    80005dfc:	cb19                	beqz	a4,80005e12 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005dfe:	2505                	addiw	a0,a0,1
    80005e00:	07a1                	addi	a5,a5,8
    80005e02:	fed51ce3          	bne	a0,a3,80005dfa <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005e06:	557d                	li	a0,-1
}
    80005e08:	60e2                	ld	ra,24(sp)
    80005e0a:	6442                	ld	s0,16(sp)
    80005e0c:	64a2                	ld	s1,8(sp)
    80005e0e:	6105                	addi	sp,sp,32
    80005e10:	8082                	ret
      p->ofile[fd] = f;
    80005e12:	01e50793          	addi	a5,a0,30
    80005e16:	078e                	slli	a5,a5,0x3
    80005e18:	963e                	add	a2,a2,a5
    80005e1a:	e604                	sd	s1,8(a2)
      return fd;
    80005e1c:	b7f5                	j	80005e08 <fdalloc+0x2c>

0000000080005e1e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005e1e:	715d                	addi	sp,sp,-80
    80005e20:	e486                	sd	ra,72(sp)
    80005e22:	e0a2                	sd	s0,64(sp)
    80005e24:	fc26                	sd	s1,56(sp)
    80005e26:	f84a                	sd	s2,48(sp)
    80005e28:	f44e                	sd	s3,40(sp)
    80005e2a:	f052                	sd	s4,32(sp)
    80005e2c:	ec56                	sd	s5,24(sp)
    80005e2e:	0880                	addi	s0,sp,80
    80005e30:	89ae                	mv	s3,a1
    80005e32:	8ab2                	mv	s5,a2
    80005e34:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005e36:	fb040593          	addi	a1,s0,-80
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	e86080e7          	jalr	-378(ra) # 80004cc0 <nameiparent>
    80005e42:	892a                	mv	s2,a0
    80005e44:	12050f63          	beqz	a0,80005f82 <create+0x164>
    return 0;

  ilock(dp);
    80005e48:	ffffe097          	auipc	ra,0xffffe
    80005e4c:	6a4080e7          	jalr	1700(ra) # 800044ec <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005e50:	4601                	li	a2,0
    80005e52:	fb040593          	addi	a1,s0,-80
    80005e56:	854a                	mv	a0,s2
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	b78080e7          	jalr	-1160(ra) # 800049d0 <dirlookup>
    80005e60:	84aa                	mv	s1,a0
    80005e62:	c921                	beqz	a0,80005eb2 <create+0x94>
    iunlockput(dp);
    80005e64:	854a                	mv	a0,s2
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	8e8080e7          	jalr	-1816(ra) # 8000474e <iunlockput>
    ilock(ip);
    80005e6e:	8526                	mv	a0,s1
    80005e70:	ffffe097          	auipc	ra,0xffffe
    80005e74:	67c080e7          	jalr	1660(ra) # 800044ec <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005e78:	2981                	sext.w	s3,s3
    80005e7a:	4789                	li	a5,2
    80005e7c:	02f99463          	bne	s3,a5,80005ea4 <create+0x86>
    80005e80:	0444d783          	lhu	a5,68(s1)
    80005e84:	37f9                	addiw	a5,a5,-2
    80005e86:	17c2                	slli	a5,a5,0x30
    80005e88:	93c1                	srli	a5,a5,0x30
    80005e8a:	4705                	li	a4,1
    80005e8c:	00f76c63          	bltu	a4,a5,80005ea4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005e90:	8526                	mv	a0,s1
    80005e92:	60a6                	ld	ra,72(sp)
    80005e94:	6406                	ld	s0,64(sp)
    80005e96:	74e2                	ld	s1,56(sp)
    80005e98:	7942                	ld	s2,48(sp)
    80005e9a:	79a2                	ld	s3,40(sp)
    80005e9c:	7a02                	ld	s4,32(sp)
    80005e9e:	6ae2                	ld	s5,24(sp)
    80005ea0:	6161                	addi	sp,sp,80
    80005ea2:	8082                	ret
    iunlockput(ip);
    80005ea4:	8526                	mv	a0,s1
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	8a8080e7          	jalr	-1880(ra) # 8000474e <iunlockput>
    return 0;
    80005eae:	4481                	li	s1,0
    80005eb0:	b7c5                	j	80005e90 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005eb2:	85ce                	mv	a1,s3
    80005eb4:	00092503          	lw	a0,0(s2)
    80005eb8:	ffffe097          	auipc	ra,0xffffe
    80005ebc:	49c080e7          	jalr	1180(ra) # 80004354 <ialloc>
    80005ec0:	84aa                	mv	s1,a0
    80005ec2:	c529                	beqz	a0,80005f0c <create+0xee>
  ilock(ip);
    80005ec4:	ffffe097          	auipc	ra,0xffffe
    80005ec8:	628080e7          	jalr	1576(ra) # 800044ec <ilock>
  ip->major = major;
    80005ecc:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005ed0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005ed4:	4785                	li	a5,1
    80005ed6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005eda:	8526                	mv	a0,s1
    80005edc:	ffffe097          	auipc	ra,0xffffe
    80005ee0:	546080e7          	jalr	1350(ra) # 80004422 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005ee4:	2981                	sext.w	s3,s3
    80005ee6:	4785                	li	a5,1
    80005ee8:	02f98a63          	beq	s3,a5,80005f1c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005eec:	40d0                	lw	a2,4(s1)
    80005eee:	fb040593          	addi	a1,s0,-80
    80005ef2:	854a                	mv	a0,s2
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	cec080e7          	jalr	-788(ra) # 80004be0 <dirlink>
    80005efc:	06054b63          	bltz	a0,80005f72 <create+0x154>
  iunlockput(dp);
    80005f00:	854a                	mv	a0,s2
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	84c080e7          	jalr	-1972(ra) # 8000474e <iunlockput>
  return ip;
    80005f0a:	b759                	j	80005e90 <create+0x72>
    panic("create: ialloc");
    80005f0c:	00004517          	auipc	a0,0x4
    80005f10:	9d450513          	addi	a0,a0,-1580 # 800098e0 <syscalls+0x2b0>
    80005f14:	ffffa097          	auipc	ra,0xffffa
    80005f18:	62a080e7          	jalr	1578(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005f1c:	04a95783          	lhu	a5,74(s2)
    80005f20:	2785                	addiw	a5,a5,1
    80005f22:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005f26:	854a                	mv	a0,s2
    80005f28:	ffffe097          	auipc	ra,0xffffe
    80005f2c:	4fa080e7          	jalr	1274(ra) # 80004422 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005f30:	40d0                	lw	a2,4(s1)
    80005f32:	00004597          	auipc	a1,0x4
    80005f36:	9be58593          	addi	a1,a1,-1602 # 800098f0 <syscalls+0x2c0>
    80005f3a:	8526                	mv	a0,s1
    80005f3c:	fffff097          	auipc	ra,0xfffff
    80005f40:	ca4080e7          	jalr	-860(ra) # 80004be0 <dirlink>
    80005f44:	00054f63          	bltz	a0,80005f62 <create+0x144>
    80005f48:	00492603          	lw	a2,4(s2)
    80005f4c:	00004597          	auipc	a1,0x4
    80005f50:	9ac58593          	addi	a1,a1,-1620 # 800098f8 <syscalls+0x2c8>
    80005f54:	8526                	mv	a0,s1
    80005f56:	fffff097          	auipc	ra,0xfffff
    80005f5a:	c8a080e7          	jalr	-886(ra) # 80004be0 <dirlink>
    80005f5e:	f80557e3          	bgez	a0,80005eec <create+0xce>
      panic("create dots");
    80005f62:	00004517          	auipc	a0,0x4
    80005f66:	99e50513          	addi	a0,a0,-1634 # 80009900 <syscalls+0x2d0>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5d4080e7          	jalr	1492(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005f72:	00004517          	auipc	a0,0x4
    80005f76:	99e50513          	addi	a0,a0,-1634 # 80009910 <syscalls+0x2e0>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5c4080e7          	jalr	1476(ra) # 8000053e <panic>
    return 0;
    80005f82:	84aa                	mv	s1,a0
    80005f84:	b731                	j	80005e90 <create+0x72>

0000000080005f86 <sys_dup>:
{
    80005f86:	7179                	addi	sp,sp,-48
    80005f88:	f406                	sd	ra,40(sp)
    80005f8a:	f022                	sd	s0,32(sp)
    80005f8c:	ec26                	sd	s1,24(sp)
    80005f8e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005f90:	fd840613          	addi	a2,s0,-40
    80005f94:	4581                	li	a1,0
    80005f96:	4501                	li	a0,0
    80005f98:	00000097          	auipc	ra,0x0
    80005f9c:	ddc080e7          	jalr	-548(ra) # 80005d74 <argfd>
    return -1;
    80005fa0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005fa2:	02054363          	bltz	a0,80005fc8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005fa6:	fd843503          	ld	a0,-40(s0)
    80005faa:	00000097          	auipc	ra,0x0
    80005fae:	e32080e7          	jalr	-462(ra) # 80005ddc <fdalloc>
    80005fb2:	84aa                	mv	s1,a0
    return -1;
    80005fb4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005fb6:	00054963          	bltz	a0,80005fc8 <sys_dup+0x42>
  filedup(f);
    80005fba:	fd843503          	ld	a0,-40(s0)
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	37a080e7          	jalr	890(ra) # 80005338 <filedup>
  return fd;
    80005fc6:	87a6                	mv	a5,s1
}
    80005fc8:	853e                	mv	a0,a5
    80005fca:	70a2                	ld	ra,40(sp)
    80005fcc:	7402                	ld	s0,32(sp)
    80005fce:	64e2                	ld	s1,24(sp)
    80005fd0:	6145                	addi	sp,sp,48
    80005fd2:	8082                	ret

0000000080005fd4 <sys_read>:
{
    80005fd4:	7179                	addi	sp,sp,-48
    80005fd6:	f406                	sd	ra,40(sp)
    80005fd8:	f022                	sd	s0,32(sp)
    80005fda:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fdc:	fe840613          	addi	a2,s0,-24
    80005fe0:	4581                	li	a1,0
    80005fe2:	4501                	li	a0,0
    80005fe4:	00000097          	auipc	ra,0x0
    80005fe8:	d90080e7          	jalr	-624(ra) # 80005d74 <argfd>
    return -1;
    80005fec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005fee:	04054163          	bltz	a0,80006030 <sys_read+0x5c>
    80005ff2:	fe440593          	addi	a1,s0,-28
    80005ff6:	4509                	li	a0,2
    80005ff8:	ffffe097          	auipc	ra,0xffffe
    80005ffc:	938080e7          	jalr	-1736(ra) # 80003930 <argint>
    return -1;
    80006000:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006002:	02054763          	bltz	a0,80006030 <sys_read+0x5c>
    80006006:	fd840593          	addi	a1,s0,-40
    8000600a:	4505                	li	a0,1
    8000600c:	ffffe097          	auipc	ra,0xffffe
    80006010:	946080e7          	jalr	-1722(ra) # 80003952 <argaddr>
    return -1;
    80006014:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006016:	00054d63          	bltz	a0,80006030 <sys_read+0x5c>
  return fileread(f, p, n);
    8000601a:	fe442603          	lw	a2,-28(s0)
    8000601e:	fd843583          	ld	a1,-40(s0)
    80006022:	fe843503          	ld	a0,-24(s0)
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	49e080e7          	jalr	1182(ra) # 800054c4 <fileread>
    8000602e:	87aa                	mv	a5,a0
}
    80006030:	853e                	mv	a0,a5
    80006032:	70a2                	ld	ra,40(sp)
    80006034:	7402                	ld	s0,32(sp)
    80006036:	6145                	addi	sp,sp,48
    80006038:	8082                	ret

000000008000603a <sys_write>:
{
    8000603a:	7179                	addi	sp,sp,-48
    8000603c:	f406                	sd	ra,40(sp)
    8000603e:	f022                	sd	s0,32(sp)
    80006040:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006042:	fe840613          	addi	a2,s0,-24
    80006046:	4581                	li	a1,0
    80006048:	4501                	li	a0,0
    8000604a:	00000097          	auipc	ra,0x0
    8000604e:	d2a080e7          	jalr	-726(ra) # 80005d74 <argfd>
    return -1;
    80006052:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006054:	04054163          	bltz	a0,80006096 <sys_write+0x5c>
    80006058:	fe440593          	addi	a1,s0,-28
    8000605c:	4509                	li	a0,2
    8000605e:	ffffe097          	auipc	ra,0xffffe
    80006062:	8d2080e7          	jalr	-1838(ra) # 80003930 <argint>
    return -1;
    80006066:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006068:	02054763          	bltz	a0,80006096 <sys_write+0x5c>
    8000606c:	fd840593          	addi	a1,s0,-40
    80006070:	4505                	li	a0,1
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	8e0080e7          	jalr	-1824(ra) # 80003952 <argaddr>
    return -1;
    8000607a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000607c:	00054d63          	bltz	a0,80006096 <sys_write+0x5c>
  return filewrite(f, p, n);
    80006080:	fe442603          	lw	a2,-28(s0)
    80006084:	fd843583          	ld	a1,-40(s0)
    80006088:	fe843503          	ld	a0,-24(s0)
    8000608c:	fffff097          	auipc	ra,0xfffff
    80006090:	4fa080e7          	jalr	1274(ra) # 80005586 <filewrite>
    80006094:	87aa                	mv	a5,a0
}
    80006096:	853e                	mv	a0,a5
    80006098:	70a2                	ld	ra,40(sp)
    8000609a:	7402                	ld	s0,32(sp)
    8000609c:	6145                	addi	sp,sp,48
    8000609e:	8082                	ret

00000000800060a0 <sys_close>:
{
    800060a0:	1101                	addi	sp,sp,-32
    800060a2:	ec06                	sd	ra,24(sp)
    800060a4:	e822                	sd	s0,16(sp)
    800060a6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800060a8:	fe040613          	addi	a2,s0,-32
    800060ac:	fec40593          	addi	a1,s0,-20
    800060b0:	4501                	li	a0,0
    800060b2:	00000097          	auipc	ra,0x0
    800060b6:	cc2080e7          	jalr	-830(ra) # 80005d74 <argfd>
    return -1;
    800060ba:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800060bc:	02054463          	bltz	a0,800060e4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800060c0:	ffffc097          	auipc	ra,0xffffc
    800060c4:	de2080e7          	jalr	-542(ra) # 80001ea2 <myproc>
    800060c8:	fec42783          	lw	a5,-20(s0)
    800060cc:	07f9                	addi	a5,a5,30
    800060ce:	078e                	slli	a5,a5,0x3
    800060d0:	97aa                	add	a5,a5,a0
    800060d2:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800060d6:	fe043503          	ld	a0,-32(s0)
    800060da:	fffff097          	auipc	ra,0xfffff
    800060de:	2b0080e7          	jalr	688(ra) # 8000538a <fileclose>
  return 0;
    800060e2:	4781                	li	a5,0
}
    800060e4:	853e                	mv	a0,a5
    800060e6:	60e2                	ld	ra,24(sp)
    800060e8:	6442                	ld	s0,16(sp)
    800060ea:	6105                	addi	sp,sp,32
    800060ec:	8082                	ret

00000000800060ee <sys_fstat>:
{
    800060ee:	1101                	addi	sp,sp,-32
    800060f0:	ec06                	sd	ra,24(sp)
    800060f2:	e822                	sd	s0,16(sp)
    800060f4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800060f6:	fe840613          	addi	a2,s0,-24
    800060fa:	4581                	li	a1,0
    800060fc:	4501                	li	a0,0
    800060fe:	00000097          	auipc	ra,0x0
    80006102:	c76080e7          	jalr	-906(ra) # 80005d74 <argfd>
    return -1;
    80006106:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006108:	02054563          	bltz	a0,80006132 <sys_fstat+0x44>
    8000610c:	fe040593          	addi	a1,s0,-32
    80006110:	4505                	li	a0,1
    80006112:	ffffe097          	auipc	ra,0xffffe
    80006116:	840080e7          	jalr	-1984(ra) # 80003952 <argaddr>
    return -1;
    8000611a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000611c:	00054b63          	bltz	a0,80006132 <sys_fstat+0x44>
  return filestat(f, st);
    80006120:	fe043583          	ld	a1,-32(s0)
    80006124:	fe843503          	ld	a0,-24(s0)
    80006128:	fffff097          	auipc	ra,0xfffff
    8000612c:	32a080e7          	jalr	810(ra) # 80005452 <filestat>
    80006130:	87aa                	mv	a5,a0
}
    80006132:	853e                	mv	a0,a5
    80006134:	60e2                	ld	ra,24(sp)
    80006136:	6442                	ld	s0,16(sp)
    80006138:	6105                	addi	sp,sp,32
    8000613a:	8082                	ret

000000008000613c <sys_link>:
{
    8000613c:	7169                	addi	sp,sp,-304
    8000613e:	f606                	sd	ra,296(sp)
    80006140:	f222                	sd	s0,288(sp)
    80006142:	ee26                	sd	s1,280(sp)
    80006144:	ea4a                	sd	s2,272(sp)
    80006146:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006148:	08000613          	li	a2,128
    8000614c:	ed040593          	addi	a1,s0,-304
    80006150:	4501                	li	a0,0
    80006152:	ffffe097          	auipc	ra,0xffffe
    80006156:	822080e7          	jalr	-2014(ra) # 80003974 <argstr>
    return -1;
    8000615a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000615c:	10054e63          	bltz	a0,80006278 <sys_link+0x13c>
    80006160:	08000613          	li	a2,128
    80006164:	f5040593          	addi	a1,s0,-176
    80006168:	4505                	li	a0,1
    8000616a:	ffffe097          	auipc	ra,0xffffe
    8000616e:	80a080e7          	jalr	-2038(ra) # 80003974 <argstr>
    return -1;
    80006172:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006174:	10054263          	bltz	a0,80006278 <sys_link+0x13c>
  begin_op();
    80006178:	fffff097          	auipc	ra,0xfffff
    8000617c:	d46080e7          	jalr	-698(ra) # 80004ebe <begin_op>
  if((ip = namei(old)) == 0){
    80006180:	ed040513          	addi	a0,s0,-304
    80006184:	fffff097          	auipc	ra,0xfffff
    80006188:	b1e080e7          	jalr	-1250(ra) # 80004ca2 <namei>
    8000618c:	84aa                	mv	s1,a0
    8000618e:	c551                	beqz	a0,8000621a <sys_link+0xde>
  ilock(ip);
    80006190:	ffffe097          	auipc	ra,0xffffe
    80006194:	35c080e7          	jalr	860(ra) # 800044ec <ilock>
  if(ip->type == T_DIR){
    80006198:	04449703          	lh	a4,68(s1)
    8000619c:	4785                	li	a5,1
    8000619e:	08f70463          	beq	a4,a5,80006226 <sys_link+0xea>
  ip->nlink++;
    800061a2:	04a4d783          	lhu	a5,74(s1)
    800061a6:	2785                	addiw	a5,a5,1
    800061a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800061ac:	8526                	mv	a0,s1
    800061ae:	ffffe097          	auipc	ra,0xffffe
    800061b2:	274080e7          	jalr	628(ra) # 80004422 <iupdate>
  iunlock(ip);
    800061b6:	8526                	mv	a0,s1
    800061b8:	ffffe097          	auipc	ra,0xffffe
    800061bc:	3f6080e7          	jalr	1014(ra) # 800045ae <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800061c0:	fd040593          	addi	a1,s0,-48
    800061c4:	f5040513          	addi	a0,s0,-176
    800061c8:	fffff097          	auipc	ra,0xfffff
    800061cc:	af8080e7          	jalr	-1288(ra) # 80004cc0 <nameiparent>
    800061d0:	892a                	mv	s2,a0
    800061d2:	c935                	beqz	a0,80006246 <sys_link+0x10a>
  ilock(dp);
    800061d4:	ffffe097          	auipc	ra,0xffffe
    800061d8:	318080e7          	jalr	792(ra) # 800044ec <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800061dc:	00092703          	lw	a4,0(s2)
    800061e0:	409c                	lw	a5,0(s1)
    800061e2:	04f71d63          	bne	a4,a5,8000623c <sys_link+0x100>
    800061e6:	40d0                	lw	a2,4(s1)
    800061e8:	fd040593          	addi	a1,s0,-48
    800061ec:	854a                	mv	a0,s2
    800061ee:	fffff097          	auipc	ra,0xfffff
    800061f2:	9f2080e7          	jalr	-1550(ra) # 80004be0 <dirlink>
    800061f6:	04054363          	bltz	a0,8000623c <sys_link+0x100>
  iunlockput(dp);
    800061fa:	854a                	mv	a0,s2
    800061fc:	ffffe097          	auipc	ra,0xffffe
    80006200:	552080e7          	jalr	1362(ra) # 8000474e <iunlockput>
  iput(ip);
    80006204:	8526                	mv	a0,s1
    80006206:	ffffe097          	auipc	ra,0xffffe
    8000620a:	4a0080e7          	jalr	1184(ra) # 800046a6 <iput>
  end_op();
    8000620e:	fffff097          	auipc	ra,0xfffff
    80006212:	d30080e7          	jalr	-720(ra) # 80004f3e <end_op>
  return 0;
    80006216:	4781                	li	a5,0
    80006218:	a085                	j	80006278 <sys_link+0x13c>
    end_op();
    8000621a:	fffff097          	auipc	ra,0xfffff
    8000621e:	d24080e7          	jalr	-732(ra) # 80004f3e <end_op>
    return -1;
    80006222:	57fd                	li	a5,-1
    80006224:	a891                	j	80006278 <sys_link+0x13c>
    iunlockput(ip);
    80006226:	8526                	mv	a0,s1
    80006228:	ffffe097          	auipc	ra,0xffffe
    8000622c:	526080e7          	jalr	1318(ra) # 8000474e <iunlockput>
    end_op();
    80006230:	fffff097          	auipc	ra,0xfffff
    80006234:	d0e080e7          	jalr	-754(ra) # 80004f3e <end_op>
    return -1;
    80006238:	57fd                	li	a5,-1
    8000623a:	a83d                	j	80006278 <sys_link+0x13c>
    iunlockput(dp);
    8000623c:	854a                	mv	a0,s2
    8000623e:	ffffe097          	auipc	ra,0xffffe
    80006242:	510080e7          	jalr	1296(ra) # 8000474e <iunlockput>
  ilock(ip);
    80006246:	8526                	mv	a0,s1
    80006248:	ffffe097          	auipc	ra,0xffffe
    8000624c:	2a4080e7          	jalr	676(ra) # 800044ec <ilock>
  ip->nlink--;
    80006250:	04a4d783          	lhu	a5,74(s1)
    80006254:	37fd                	addiw	a5,a5,-1
    80006256:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000625a:	8526                	mv	a0,s1
    8000625c:	ffffe097          	auipc	ra,0xffffe
    80006260:	1c6080e7          	jalr	454(ra) # 80004422 <iupdate>
  iunlockput(ip);
    80006264:	8526                	mv	a0,s1
    80006266:	ffffe097          	auipc	ra,0xffffe
    8000626a:	4e8080e7          	jalr	1256(ra) # 8000474e <iunlockput>
  end_op();
    8000626e:	fffff097          	auipc	ra,0xfffff
    80006272:	cd0080e7          	jalr	-816(ra) # 80004f3e <end_op>
  return -1;
    80006276:	57fd                	li	a5,-1
}
    80006278:	853e                	mv	a0,a5
    8000627a:	70b2                	ld	ra,296(sp)
    8000627c:	7412                	ld	s0,288(sp)
    8000627e:	64f2                	ld	s1,280(sp)
    80006280:	6952                	ld	s2,272(sp)
    80006282:	6155                	addi	sp,sp,304
    80006284:	8082                	ret

0000000080006286 <sys_unlink>:
{
    80006286:	7151                	addi	sp,sp,-240
    80006288:	f586                	sd	ra,232(sp)
    8000628a:	f1a2                	sd	s0,224(sp)
    8000628c:	eda6                	sd	s1,216(sp)
    8000628e:	e9ca                	sd	s2,208(sp)
    80006290:	e5ce                	sd	s3,200(sp)
    80006292:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80006294:	08000613          	li	a2,128
    80006298:	f3040593          	addi	a1,s0,-208
    8000629c:	4501                	li	a0,0
    8000629e:	ffffd097          	auipc	ra,0xffffd
    800062a2:	6d6080e7          	jalr	1750(ra) # 80003974 <argstr>
    800062a6:	18054163          	bltz	a0,80006428 <sys_unlink+0x1a2>
  begin_op();
    800062aa:	fffff097          	auipc	ra,0xfffff
    800062ae:	c14080e7          	jalr	-1004(ra) # 80004ebe <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800062b2:	fb040593          	addi	a1,s0,-80
    800062b6:	f3040513          	addi	a0,s0,-208
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	a06080e7          	jalr	-1530(ra) # 80004cc0 <nameiparent>
    800062c2:	84aa                	mv	s1,a0
    800062c4:	c979                	beqz	a0,8000639a <sys_unlink+0x114>
  ilock(dp);
    800062c6:	ffffe097          	auipc	ra,0xffffe
    800062ca:	226080e7          	jalr	550(ra) # 800044ec <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800062ce:	00003597          	auipc	a1,0x3
    800062d2:	62258593          	addi	a1,a1,1570 # 800098f0 <syscalls+0x2c0>
    800062d6:	fb040513          	addi	a0,s0,-80
    800062da:	ffffe097          	auipc	ra,0xffffe
    800062de:	6dc080e7          	jalr	1756(ra) # 800049b6 <namecmp>
    800062e2:	14050a63          	beqz	a0,80006436 <sys_unlink+0x1b0>
    800062e6:	00003597          	auipc	a1,0x3
    800062ea:	61258593          	addi	a1,a1,1554 # 800098f8 <syscalls+0x2c8>
    800062ee:	fb040513          	addi	a0,s0,-80
    800062f2:	ffffe097          	auipc	ra,0xffffe
    800062f6:	6c4080e7          	jalr	1732(ra) # 800049b6 <namecmp>
    800062fa:	12050e63          	beqz	a0,80006436 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800062fe:	f2c40613          	addi	a2,s0,-212
    80006302:	fb040593          	addi	a1,s0,-80
    80006306:	8526                	mv	a0,s1
    80006308:	ffffe097          	auipc	ra,0xffffe
    8000630c:	6c8080e7          	jalr	1736(ra) # 800049d0 <dirlookup>
    80006310:	892a                	mv	s2,a0
    80006312:	12050263          	beqz	a0,80006436 <sys_unlink+0x1b0>
  ilock(ip);
    80006316:	ffffe097          	auipc	ra,0xffffe
    8000631a:	1d6080e7          	jalr	470(ra) # 800044ec <ilock>
  if(ip->nlink < 1)
    8000631e:	04a91783          	lh	a5,74(s2)
    80006322:	08f05263          	blez	a5,800063a6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006326:	04491703          	lh	a4,68(s2)
    8000632a:	4785                	li	a5,1
    8000632c:	08f70563          	beq	a4,a5,800063b6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006330:	4641                	li	a2,16
    80006332:	4581                	li	a1,0
    80006334:	fc040513          	addi	a0,s0,-64
    80006338:	ffffb097          	auipc	ra,0xffffb
    8000633c:	9b6080e7          	jalr	-1610(ra) # 80000cee <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006340:	4741                	li	a4,16
    80006342:	f2c42683          	lw	a3,-212(s0)
    80006346:	fc040613          	addi	a2,s0,-64
    8000634a:	4581                	li	a1,0
    8000634c:	8526                	mv	a0,s1
    8000634e:	ffffe097          	auipc	ra,0xffffe
    80006352:	54a080e7          	jalr	1354(ra) # 80004898 <writei>
    80006356:	47c1                	li	a5,16
    80006358:	0af51563          	bne	a0,a5,80006402 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000635c:	04491703          	lh	a4,68(s2)
    80006360:	4785                	li	a5,1
    80006362:	0af70863          	beq	a4,a5,80006412 <sys_unlink+0x18c>
  iunlockput(dp);
    80006366:	8526                	mv	a0,s1
    80006368:	ffffe097          	auipc	ra,0xffffe
    8000636c:	3e6080e7          	jalr	998(ra) # 8000474e <iunlockput>
  ip->nlink--;
    80006370:	04a95783          	lhu	a5,74(s2)
    80006374:	37fd                	addiw	a5,a5,-1
    80006376:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000637a:	854a                	mv	a0,s2
    8000637c:	ffffe097          	auipc	ra,0xffffe
    80006380:	0a6080e7          	jalr	166(ra) # 80004422 <iupdate>
  iunlockput(ip);
    80006384:	854a                	mv	a0,s2
    80006386:	ffffe097          	auipc	ra,0xffffe
    8000638a:	3c8080e7          	jalr	968(ra) # 8000474e <iunlockput>
  end_op();
    8000638e:	fffff097          	auipc	ra,0xfffff
    80006392:	bb0080e7          	jalr	-1104(ra) # 80004f3e <end_op>
  return 0;
    80006396:	4501                	li	a0,0
    80006398:	a84d                	j	8000644a <sys_unlink+0x1c4>
    end_op();
    8000639a:	fffff097          	auipc	ra,0xfffff
    8000639e:	ba4080e7          	jalr	-1116(ra) # 80004f3e <end_op>
    return -1;
    800063a2:	557d                	li	a0,-1
    800063a4:	a05d                	j	8000644a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800063a6:	00003517          	auipc	a0,0x3
    800063aa:	57a50513          	addi	a0,a0,1402 # 80009920 <syscalls+0x2f0>
    800063ae:	ffffa097          	auipc	ra,0xffffa
    800063b2:	190080e7          	jalr	400(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800063b6:	04c92703          	lw	a4,76(s2)
    800063ba:	02000793          	li	a5,32
    800063be:	f6e7f9e3          	bgeu	a5,a4,80006330 <sys_unlink+0xaa>
    800063c2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800063c6:	4741                	li	a4,16
    800063c8:	86ce                	mv	a3,s3
    800063ca:	f1840613          	addi	a2,s0,-232
    800063ce:	4581                	li	a1,0
    800063d0:	854a                	mv	a0,s2
    800063d2:	ffffe097          	auipc	ra,0xffffe
    800063d6:	3ce080e7          	jalr	974(ra) # 800047a0 <readi>
    800063da:	47c1                	li	a5,16
    800063dc:	00f51b63          	bne	a0,a5,800063f2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800063e0:	f1845783          	lhu	a5,-232(s0)
    800063e4:	e7a1                	bnez	a5,8000642c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800063e6:	29c1                	addiw	s3,s3,16
    800063e8:	04c92783          	lw	a5,76(s2)
    800063ec:	fcf9ede3          	bltu	s3,a5,800063c6 <sys_unlink+0x140>
    800063f0:	b781                	j	80006330 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800063f2:	00003517          	auipc	a0,0x3
    800063f6:	54650513          	addi	a0,a0,1350 # 80009938 <syscalls+0x308>
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	144080e7          	jalr	324(ra) # 8000053e <panic>
    panic("unlink: writei");
    80006402:	00003517          	auipc	a0,0x3
    80006406:	54e50513          	addi	a0,a0,1358 # 80009950 <syscalls+0x320>
    8000640a:	ffffa097          	auipc	ra,0xffffa
    8000640e:	134080e7          	jalr	308(ra) # 8000053e <panic>
    dp->nlink--;
    80006412:	04a4d783          	lhu	a5,74(s1)
    80006416:	37fd                	addiw	a5,a5,-1
    80006418:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000641c:	8526                	mv	a0,s1
    8000641e:	ffffe097          	auipc	ra,0xffffe
    80006422:	004080e7          	jalr	4(ra) # 80004422 <iupdate>
    80006426:	b781                	j	80006366 <sys_unlink+0xe0>
    return -1;
    80006428:	557d                	li	a0,-1
    8000642a:	a005                	j	8000644a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000642c:	854a                	mv	a0,s2
    8000642e:	ffffe097          	auipc	ra,0xffffe
    80006432:	320080e7          	jalr	800(ra) # 8000474e <iunlockput>
  iunlockput(dp);
    80006436:	8526                	mv	a0,s1
    80006438:	ffffe097          	auipc	ra,0xffffe
    8000643c:	316080e7          	jalr	790(ra) # 8000474e <iunlockput>
  end_op();
    80006440:	fffff097          	auipc	ra,0xfffff
    80006444:	afe080e7          	jalr	-1282(ra) # 80004f3e <end_op>
  return -1;
    80006448:	557d                	li	a0,-1
}
    8000644a:	70ae                	ld	ra,232(sp)
    8000644c:	740e                	ld	s0,224(sp)
    8000644e:	64ee                	ld	s1,216(sp)
    80006450:	694e                	ld	s2,208(sp)
    80006452:	69ae                	ld	s3,200(sp)
    80006454:	616d                	addi	sp,sp,240
    80006456:	8082                	ret

0000000080006458 <sys_open>:

uint64
sys_open(void)
{
    80006458:	7131                	addi	sp,sp,-192
    8000645a:	fd06                	sd	ra,184(sp)
    8000645c:	f922                	sd	s0,176(sp)
    8000645e:	f526                	sd	s1,168(sp)
    80006460:	f14a                	sd	s2,160(sp)
    80006462:	ed4e                	sd	s3,152(sp)
    80006464:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006466:	08000613          	li	a2,128
    8000646a:	f5040593          	addi	a1,s0,-176
    8000646e:	4501                	li	a0,0
    80006470:	ffffd097          	auipc	ra,0xffffd
    80006474:	504080e7          	jalr	1284(ra) # 80003974 <argstr>
    return -1;
    80006478:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000647a:	0c054163          	bltz	a0,8000653c <sys_open+0xe4>
    8000647e:	f4c40593          	addi	a1,s0,-180
    80006482:	4505                	li	a0,1
    80006484:	ffffd097          	auipc	ra,0xffffd
    80006488:	4ac080e7          	jalr	1196(ra) # 80003930 <argint>
    8000648c:	0a054863          	bltz	a0,8000653c <sys_open+0xe4>

  begin_op();
    80006490:	fffff097          	auipc	ra,0xfffff
    80006494:	a2e080e7          	jalr	-1490(ra) # 80004ebe <begin_op>

  if(omode & O_CREATE){
    80006498:	f4c42783          	lw	a5,-180(s0)
    8000649c:	2007f793          	andi	a5,a5,512
    800064a0:	cbdd                	beqz	a5,80006556 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800064a2:	4681                	li	a3,0
    800064a4:	4601                	li	a2,0
    800064a6:	4589                	li	a1,2
    800064a8:	f5040513          	addi	a0,s0,-176
    800064ac:	00000097          	auipc	ra,0x0
    800064b0:	972080e7          	jalr	-1678(ra) # 80005e1e <create>
    800064b4:	892a                	mv	s2,a0
    if(ip == 0){
    800064b6:	c959                	beqz	a0,8000654c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800064b8:	04491703          	lh	a4,68(s2)
    800064bc:	478d                	li	a5,3
    800064be:	00f71763          	bne	a4,a5,800064cc <sys_open+0x74>
    800064c2:	04695703          	lhu	a4,70(s2)
    800064c6:	47a5                	li	a5,9
    800064c8:	0ce7ec63          	bltu	a5,a4,800065a0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800064cc:	fffff097          	auipc	ra,0xfffff
    800064d0:	e02080e7          	jalr	-510(ra) # 800052ce <filealloc>
    800064d4:	89aa                	mv	s3,a0
    800064d6:	10050263          	beqz	a0,800065da <sys_open+0x182>
    800064da:	00000097          	auipc	ra,0x0
    800064de:	902080e7          	jalr	-1790(ra) # 80005ddc <fdalloc>
    800064e2:	84aa                	mv	s1,a0
    800064e4:	0e054663          	bltz	a0,800065d0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800064e8:	04491703          	lh	a4,68(s2)
    800064ec:	478d                	li	a5,3
    800064ee:	0cf70463          	beq	a4,a5,800065b6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800064f2:	4789                	li	a5,2
    800064f4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800064f8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800064fc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006500:	f4c42783          	lw	a5,-180(s0)
    80006504:	0017c713          	xori	a4,a5,1
    80006508:	8b05                	andi	a4,a4,1
    8000650a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000650e:	0037f713          	andi	a4,a5,3
    80006512:	00e03733          	snez	a4,a4
    80006516:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000651a:	4007f793          	andi	a5,a5,1024
    8000651e:	c791                	beqz	a5,8000652a <sys_open+0xd2>
    80006520:	04491703          	lh	a4,68(s2)
    80006524:	4789                	li	a5,2
    80006526:	08f70f63          	beq	a4,a5,800065c4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000652a:	854a                	mv	a0,s2
    8000652c:	ffffe097          	auipc	ra,0xffffe
    80006530:	082080e7          	jalr	130(ra) # 800045ae <iunlock>
  end_op();
    80006534:	fffff097          	auipc	ra,0xfffff
    80006538:	a0a080e7          	jalr	-1526(ra) # 80004f3e <end_op>

  return fd;
}
    8000653c:	8526                	mv	a0,s1
    8000653e:	70ea                	ld	ra,184(sp)
    80006540:	744a                	ld	s0,176(sp)
    80006542:	74aa                	ld	s1,168(sp)
    80006544:	790a                	ld	s2,160(sp)
    80006546:	69ea                	ld	s3,152(sp)
    80006548:	6129                	addi	sp,sp,192
    8000654a:	8082                	ret
      end_op();
    8000654c:	fffff097          	auipc	ra,0xfffff
    80006550:	9f2080e7          	jalr	-1550(ra) # 80004f3e <end_op>
      return -1;
    80006554:	b7e5                	j	8000653c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006556:	f5040513          	addi	a0,s0,-176
    8000655a:	ffffe097          	auipc	ra,0xffffe
    8000655e:	748080e7          	jalr	1864(ra) # 80004ca2 <namei>
    80006562:	892a                	mv	s2,a0
    80006564:	c905                	beqz	a0,80006594 <sys_open+0x13c>
    ilock(ip);
    80006566:	ffffe097          	auipc	ra,0xffffe
    8000656a:	f86080e7          	jalr	-122(ra) # 800044ec <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000656e:	04491703          	lh	a4,68(s2)
    80006572:	4785                	li	a5,1
    80006574:	f4f712e3          	bne	a4,a5,800064b8 <sys_open+0x60>
    80006578:	f4c42783          	lw	a5,-180(s0)
    8000657c:	dba1                	beqz	a5,800064cc <sys_open+0x74>
      iunlockput(ip);
    8000657e:	854a                	mv	a0,s2
    80006580:	ffffe097          	auipc	ra,0xffffe
    80006584:	1ce080e7          	jalr	462(ra) # 8000474e <iunlockput>
      end_op();
    80006588:	fffff097          	auipc	ra,0xfffff
    8000658c:	9b6080e7          	jalr	-1610(ra) # 80004f3e <end_op>
      return -1;
    80006590:	54fd                	li	s1,-1
    80006592:	b76d                	j	8000653c <sys_open+0xe4>
      end_op();
    80006594:	fffff097          	auipc	ra,0xfffff
    80006598:	9aa080e7          	jalr	-1622(ra) # 80004f3e <end_op>
      return -1;
    8000659c:	54fd                	li	s1,-1
    8000659e:	bf79                	j	8000653c <sys_open+0xe4>
    iunlockput(ip);
    800065a0:	854a                	mv	a0,s2
    800065a2:	ffffe097          	auipc	ra,0xffffe
    800065a6:	1ac080e7          	jalr	428(ra) # 8000474e <iunlockput>
    end_op();
    800065aa:	fffff097          	auipc	ra,0xfffff
    800065ae:	994080e7          	jalr	-1644(ra) # 80004f3e <end_op>
    return -1;
    800065b2:	54fd                	li	s1,-1
    800065b4:	b761                	j	8000653c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800065b6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800065ba:	04691783          	lh	a5,70(s2)
    800065be:	02f99223          	sh	a5,36(s3)
    800065c2:	bf2d                	j	800064fc <sys_open+0xa4>
    itrunc(ip);
    800065c4:	854a                	mv	a0,s2
    800065c6:	ffffe097          	auipc	ra,0xffffe
    800065ca:	034080e7          	jalr	52(ra) # 800045fa <itrunc>
    800065ce:	bfb1                	j	8000652a <sys_open+0xd2>
      fileclose(f);
    800065d0:	854e                	mv	a0,s3
    800065d2:	fffff097          	auipc	ra,0xfffff
    800065d6:	db8080e7          	jalr	-584(ra) # 8000538a <fileclose>
    iunlockput(ip);
    800065da:	854a                	mv	a0,s2
    800065dc:	ffffe097          	auipc	ra,0xffffe
    800065e0:	172080e7          	jalr	370(ra) # 8000474e <iunlockput>
    end_op();
    800065e4:	fffff097          	auipc	ra,0xfffff
    800065e8:	95a080e7          	jalr	-1702(ra) # 80004f3e <end_op>
    return -1;
    800065ec:	54fd                	li	s1,-1
    800065ee:	b7b9                	j	8000653c <sys_open+0xe4>

00000000800065f0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800065f0:	7175                	addi	sp,sp,-144
    800065f2:	e506                	sd	ra,136(sp)
    800065f4:	e122                	sd	s0,128(sp)
    800065f6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800065f8:	fffff097          	auipc	ra,0xfffff
    800065fc:	8c6080e7          	jalr	-1850(ra) # 80004ebe <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006600:	08000613          	li	a2,128
    80006604:	f7040593          	addi	a1,s0,-144
    80006608:	4501                	li	a0,0
    8000660a:	ffffd097          	auipc	ra,0xffffd
    8000660e:	36a080e7          	jalr	874(ra) # 80003974 <argstr>
    80006612:	02054963          	bltz	a0,80006644 <sys_mkdir+0x54>
    80006616:	4681                	li	a3,0
    80006618:	4601                	li	a2,0
    8000661a:	4585                	li	a1,1
    8000661c:	f7040513          	addi	a0,s0,-144
    80006620:	fffff097          	auipc	ra,0xfffff
    80006624:	7fe080e7          	jalr	2046(ra) # 80005e1e <create>
    80006628:	cd11                	beqz	a0,80006644 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000662a:	ffffe097          	auipc	ra,0xffffe
    8000662e:	124080e7          	jalr	292(ra) # 8000474e <iunlockput>
  end_op();
    80006632:	fffff097          	auipc	ra,0xfffff
    80006636:	90c080e7          	jalr	-1780(ra) # 80004f3e <end_op>
  return 0;
    8000663a:	4501                	li	a0,0
}
    8000663c:	60aa                	ld	ra,136(sp)
    8000663e:	640a                	ld	s0,128(sp)
    80006640:	6149                	addi	sp,sp,144
    80006642:	8082                	ret
    end_op();
    80006644:	fffff097          	auipc	ra,0xfffff
    80006648:	8fa080e7          	jalr	-1798(ra) # 80004f3e <end_op>
    return -1;
    8000664c:	557d                	li	a0,-1
    8000664e:	b7fd                	j	8000663c <sys_mkdir+0x4c>

0000000080006650 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006650:	7135                	addi	sp,sp,-160
    80006652:	ed06                	sd	ra,152(sp)
    80006654:	e922                	sd	s0,144(sp)
    80006656:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006658:	fffff097          	auipc	ra,0xfffff
    8000665c:	866080e7          	jalr	-1946(ra) # 80004ebe <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006660:	08000613          	li	a2,128
    80006664:	f7040593          	addi	a1,s0,-144
    80006668:	4501                	li	a0,0
    8000666a:	ffffd097          	auipc	ra,0xffffd
    8000666e:	30a080e7          	jalr	778(ra) # 80003974 <argstr>
    80006672:	04054a63          	bltz	a0,800066c6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006676:	f6c40593          	addi	a1,s0,-148
    8000667a:	4505                	li	a0,1
    8000667c:	ffffd097          	auipc	ra,0xffffd
    80006680:	2b4080e7          	jalr	692(ra) # 80003930 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006684:	04054163          	bltz	a0,800066c6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006688:	f6840593          	addi	a1,s0,-152
    8000668c:	4509                	li	a0,2
    8000668e:	ffffd097          	auipc	ra,0xffffd
    80006692:	2a2080e7          	jalr	674(ra) # 80003930 <argint>
     argint(1, &major) < 0 ||
    80006696:	02054863          	bltz	a0,800066c6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000669a:	f6841683          	lh	a3,-152(s0)
    8000669e:	f6c41603          	lh	a2,-148(s0)
    800066a2:	458d                	li	a1,3
    800066a4:	f7040513          	addi	a0,s0,-144
    800066a8:	fffff097          	auipc	ra,0xfffff
    800066ac:	776080e7          	jalr	1910(ra) # 80005e1e <create>
     argint(2, &minor) < 0 ||
    800066b0:	c919                	beqz	a0,800066c6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800066b2:	ffffe097          	auipc	ra,0xffffe
    800066b6:	09c080e7          	jalr	156(ra) # 8000474e <iunlockput>
  end_op();
    800066ba:	fffff097          	auipc	ra,0xfffff
    800066be:	884080e7          	jalr	-1916(ra) # 80004f3e <end_op>
  return 0;
    800066c2:	4501                	li	a0,0
    800066c4:	a031                	j	800066d0 <sys_mknod+0x80>
    end_op();
    800066c6:	fffff097          	auipc	ra,0xfffff
    800066ca:	878080e7          	jalr	-1928(ra) # 80004f3e <end_op>
    return -1;
    800066ce:	557d                	li	a0,-1
}
    800066d0:	60ea                	ld	ra,152(sp)
    800066d2:	644a                	ld	s0,144(sp)
    800066d4:	610d                	addi	sp,sp,160
    800066d6:	8082                	ret

00000000800066d8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800066d8:	7135                	addi	sp,sp,-160
    800066da:	ed06                	sd	ra,152(sp)
    800066dc:	e922                	sd	s0,144(sp)
    800066de:	e526                	sd	s1,136(sp)
    800066e0:	e14a                	sd	s2,128(sp)
    800066e2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800066e4:	ffffb097          	auipc	ra,0xffffb
    800066e8:	7be080e7          	jalr	1982(ra) # 80001ea2 <myproc>
    800066ec:	892a                	mv	s2,a0
  
  begin_op();
    800066ee:	ffffe097          	auipc	ra,0xffffe
    800066f2:	7d0080e7          	jalr	2000(ra) # 80004ebe <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800066f6:	08000613          	li	a2,128
    800066fa:	f6040593          	addi	a1,s0,-160
    800066fe:	4501                	li	a0,0
    80006700:	ffffd097          	auipc	ra,0xffffd
    80006704:	274080e7          	jalr	628(ra) # 80003974 <argstr>
    80006708:	04054b63          	bltz	a0,8000675e <sys_chdir+0x86>
    8000670c:	f6040513          	addi	a0,s0,-160
    80006710:	ffffe097          	auipc	ra,0xffffe
    80006714:	592080e7          	jalr	1426(ra) # 80004ca2 <namei>
    80006718:	84aa                	mv	s1,a0
    8000671a:	c131                	beqz	a0,8000675e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000671c:	ffffe097          	auipc	ra,0xffffe
    80006720:	dd0080e7          	jalr	-560(ra) # 800044ec <ilock>
  if(ip->type != T_DIR){
    80006724:	04449703          	lh	a4,68(s1)
    80006728:	4785                	li	a5,1
    8000672a:	04f71063          	bne	a4,a5,8000676a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000672e:	8526                	mv	a0,s1
    80006730:	ffffe097          	auipc	ra,0xffffe
    80006734:	e7e080e7          	jalr	-386(ra) # 800045ae <iunlock>
  iput(p->cwd);
    80006738:	17893503          	ld	a0,376(s2)
    8000673c:	ffffe097          	auipc	ra,0xffffe
    80006740:	f6a080e7          	jalr	-150(ra) # 800046a6 <iput>
  end_op();
    80006744:	ffffe097          	auipc	ra,0xffffe
    80006748:	7fa080e7          	jalr	2042(ra) # 80004f3e <end_op>
  p->cwd = ip;
    8000674c:	16993c23          	sd	s1,376(s2)
  return 0;
    80006750:	4501                	li	a0,0
}
    80006752:	60ea                	ld	ra,152(sp)
    80006754:	644a                	ld	s0,144(sp)
    80006756:	64aa                	ld	s1,136(sp)
    80006758:	690a                	ld	s2,128(sp)
    8000675a:	610d                	addi	sp,sp,160
    8000675c:	8082                	ret
    end_op();
    8000675e:	ffffe097          	auipc	ra,0xffffe
    80006762:	7e0080e7          	jalr	2016(ra) # 80004f3e <end_op>
    return -1;
    80006766:	557d                	li	a0,-1
    80006768:	b7ed                	j	80006752 <sys_chdir+0x7a>
    iunlockput(ip);
    8000676a:	8526                	mv	a0,s1
    8000676c:	ffffe097          	auipc	ra,0xffffe
    80006770:	fe2080e7          	jalr	-30(ra) # 8000474e <iunlockput>
    end_op();
    80006774:	ffffe097          	auipc	ra,0xffffe
    80006778:	7ca080e7          	jalr	1994(ra) # 80004f3e <end_op>
    return -1;
    8000677c:	557d                	li	a0,-1
    8000677e:	bfd1                	j	80006752 <sys_chdir+0x7a>

0000000080006780 <sys_exec>:

uint64
sys_exec(void)
{
    80006780:	7145                	addi	sp,sp,-464
    80006782:	e786                	sd	ra,456(sp)
    80006784:	e3a2                	sd	s0,448(sp)
    80006786:	ff26                	sd	s1,440(sp)
    80006788:	fb4a                	sd	s2,432(sp)
    8000678a:	f74e                	sd	s3,424(sp)
    8000678c:	f352                	sd	s4,416(sp)
    8000678e:	ef56                	sd	s5,408(sp)
    80006790:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006792:	08000613          	li	a2,128
    80006796:	f4040593          	addi	a1,s0,-192
    8000679a:	4501                	li	a0,0
    8000679c:	ffffd097          	auipc	ra,0xffffd
    800067a0:	1d8080e7          	jalr	472(ra) # 80003974 <argstr>
    return -1;
    800067a4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800067a6:	0c054a63          	bltz	a0,8000687a <sys_exec+0xfa>
    800067aa:	e3840593          	addi	a1,s0,-456
    800067ae:	4505                	li	a0,1
    800067b0:	ffffd097          	auipc	ra,0xffffd
    800067b4:	1a2080e7          	jalr	418(ra) # 80003952 <argaddr>
    800067b8:	0c054163          	bltz	a0,8000687a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800067bc:	10000613          	li	a2,256
    800067c0:	4581                	li	a1,0
    800067c2:	e4040513          	addi	a0,s0,-448
    800067c6:	ffffa097          	auipc	ra,0xffffa
    800067ca:	528080e7          	jalr	1320(ra) # 80000cee <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800067ce:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800067d2:	89a6                	mv	s3,s1
    800067d4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800067d6:	02000a13          	li	s4,32
    800067da:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800067de:	00391513          	slli	a0,s2,0x3
    800067e2:	e3040593          	addi	a1,s0,-464
    800067e6:	e3843783          	ld	a5,-456(s0)
    800067ea:	953e                	add	a0,a0,a5
    800067ec:	ffffd097          	auipc	ra,0xffffd
    800067f0:	0aa080e7          	jalr	170(ra) # 80003896 <fetchaddr>
    800067f4:	02054a63          	bltz	a0,80006828 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800067f8:	e3043783          	ld	a5,-464(s0)
    800067fc:	c3b9                	beqz	a5,80006842 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800067fe:	ffffa097          	auipc	ra,0xffffa
    80006802:	2f6080e7          	jalr	758(ra) # 80000af4 <kalloc>
    80006806:	85aa                	mv	a1,a0
    80006808:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000680c:	cd11                	beqz	a0,80006828 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000680e:	6605                	lui	a2,0x1
    80006810:	e3043503          	ld	a0,-464(s0)
    80006814:	ffffd097          	auipc	ra,0xffffd
    80006818:	0d4080e7          	jalr	212(ra) # 800038e8 <fetchstr>
    8000681c:	00054663          	bltz	a0,80006828 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006820:	0905                	addi	s2,s2,1
    80006822:	09a1                	addi	s3,s3,8
    80006824:	fb491be3          	bne	s2,s4,800067da <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006828:	10048913          	addi	s2,s1,256
    8000682c:	6088                	ld	a0,0(s1)
    8000682e:	c529                	beqz	a0,80006878 <sys_exec+0xf8>
    kfree(argv[i]);
    80006830:	ffffa097          	auipc	ra,0xffffa
    80006834:	1c8080e7          	jalr	456(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006838:	04a1                	addi	s1,s1,8
    8000683a:	ff2499e3          	bne	s1,s2,8000682c <sys_exec+0xac>
  return -1;
    8000683e:	597d                	li	s2,-1
    80006840:	a82d                	j	8000687a <sys_exec+0xfa>
      argv[i] = 0;
    80006842:	0a8e                	slli	s5,s5,0x3
    80006844:	fc040793          	addi	a5,s0,-64
    80006848:	9abe                	add	s5,s5,a5
    8000684a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000684e:	e4040593          	addi	a1,s0,-448
    80006852:	f4040513          	addi	a0,s0,-192
    80006856:	fffff097          	auipc	ra,0xfffff
    8000685a:	194080e7          	jalr	404(ra) # 800059ea <exec>
    8000685e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006860:	10048993          	addi	s3,s1,256
    80006864:	6088                	ld	a0,0(s1)
    80006866:	c911                	beqz	a0,8000687a <sys_exec+0xfa>
    kfree(argv[i]);
    80006868:	ffffa097          	auipc	ra,0xffffa
    8000686c:	190080e7          	jalr	400(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006870:	04a1                	addi	s1,s1,8
    80006872:	ff3499e3          	bne	s1,s3,80006864 <sys_exec+0xe4>
    80006876:	a011                	j	8000687a <sys_exec+0xfa>
  return -1;
    80006878:	597d                	li	s2,-1
}
    8000687a:	854a                	mv	a0,s2
    8000687c:	60be                	ld	ra,456(sp)
    8000687e:	641e                	ld	s0,448(sp)
    80006880:	74fa                	ld	s1,440(sp)
    80006882:	795a                	ld	s2,432(sp)
    80006884:	79ba                	ld	s3,424(sp)
    80006886:	7a1a                	ld	s4,416(sp)
    80006888:	6afa                	ld	s5,408(sp)
    8000688a:	6179                	addi	sp,sp,464
    8000688c:	8082                	ret

000000008000688e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000688e:	7139                	addi	sp,sp,-64
    80006890:	fc06                	sd	ra,56(sp)
    80006892:	f822                	sd	s0,48(sp)
    80006894:	f426                	sd	s1,40(sp)
    80006896:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006898:	ffffb097          	auipc	ra,0xffffb
    8000689c:	60a080e7          	jalr	1546(ra) # 80001ea2 <myproc>
    800068a0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800068a2:	fd840593          	addi	a1,s0,-40
    800068a6:	4501                	li	a0,0
    800068a8:	ffffd097          	auipc	ra,0xffffd
    800068ac:	0aa080e7          	jalr	170(ra) # 80003952 <argaddr>
    return -1;
    800068b0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800068b2:	0e054063          	bltz	a0,80006992 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800068b6:	fc840593          	addi	a1,s0,-56
    800068ba:	fd040513          	addi	a0,s0,-48
    800068be:	fffff097          	auipc	ra,0xfffff
    800068c2:	dfc080e7          	jalr	-516(ra) # 800056ba <pipealloc>
    return -1;
    800068c6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800068c8:	0c054563          	bltz	a0,80006992 <sys_pipe+0x104>
  fd0 = -1;
    800068cc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800068d0:	fd043503          	ld	a0,-48(s0)
    800068d4:	fffff097          	auipc	ra,0xfffff
    800068d8:	508080e7          	jalr	1288(ra) # 80005ddc <fdalloc>
    800068dc:	fca42223          	sw	a0,-60(s0)
    800068e0:	08054c63          	bltz	a0,80006978 <sys_pipe+0xea>
    800068e4:	fc843503          	ld	a0,-56(s0)
    800068e8:	fffff097          	auipc	ra,0xfffff
    800068ec:	4f4080e7          	jalr	1268(ra) # 80005ddc <fdalloc>
    800068f0:	fca42023          	sw	a0,-64(s0)
    800068f4:	06054863          	bltz	a0,80006964 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800068f8:	4691                	li	a3,4
    800068fa:	fc440613          	addi	a2,s0,-60
    800068fe:	fd843583          	ld	a1,-40(s0)
    80006902:	7ca8                	ld	a0,120(s1)
    80006904:	ffffb097          	auipc	ra,0xffffb
    80006908:	d7c080e7          	jalr	-644(ra) # 80001680 <copyout>
    8000690c:	02054063          	bltz	a0,8000692c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006910:	4691                	li	a3,4
    80006912:	fc040613          	addi	a2,s0,-64
    80006916:	fd843583          	ld	a1,-40(s0)
    8000691a:	0591                	addi	a1,a1,4
    8000691c:	7ca8                	ld	a0,120(s1)
    8000691e:	ffffb097          	auipc	ra,0xffffb
    80006922:	d62080e7          	jalr	-670(ra) # 80001680 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006926:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006928:	06055563          	bgez	a0,80006992 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000692c:	fc442783          	lw	a5,-60(s0)
    80006930:	07f9                	addi	a5,a5,30
    80006932:	078e                	slli	a5,a5,0x3
    80006934:	97a6                	add	a5,a5,s1
    80006936:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    8000693a:	fc042503          	lw	a0,-64(s0)
    8000693e:	0579                	addi	a0,a0,30
    80006940:	050e                	slli	a0,a0,0x3
    80006942:	9526                	add	a0,a0,s1
    80006944:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006948:	fd043503          	ld	a0,-48(s0)
    8000694c:	fffff097          	auipc	ra,0xfffff
    80006950:	a3e080e7          	jalr	-1474(ra) # 8000538a <fileclose>
    fileclose(wf);
    80006954:	fc843503          	ld	a0,-56(s0)
    80006958:	fffff097          	auipc	ra,0xfffff
    8000695c:	a32080e7          	jalr	-1486(ra) # 8000538a <fileclose>
    return -1;
    80006960:	57fd                	li	a5,-1
    80006962:	a805                	j	80006992 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006964:	fc442783          	lw	a5,-60(s0)
    80006968:	0007c863          	bltz	a5,80006978 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000696c:	01e78513          	addi	a0,a5,30
    80006970:	050e                	slli	a0,a0,0x3
    80006972:	9526                	add	a0,a0,s1
    80006974:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006978:	fd043503          	ld	a0,-48(s0)
    8000697c:	fffff097          	auipc	ra,0xfffff
    80006980:	a0e080e7          	jalr	-1522(ra) # 8000538a <fileclose>
    fileclose(wf);
    80006984:	fc843503          	ld	a0,-56(s0)
    80006988:	fffff097          	auipc	ra,0xfffff
    8000698c:	a02080e7          	jalr	-1534(ra) # 8000538a <fileclose>
    return -1;
    80006990:	57fd                	li	a5,-1
}
    80006992:	853e                	mv	a0,a5
    80006994:	70e2                	ld	ra,56(sp)
    80006996:	7442                	ld	s0,48(sp)
    80006998:	74a2                	ld	s1,40(sp)
    8000699a:	6121                	addi	sp,sp,64
    8000699c:	8082                	ret
	...

00000000800069a0 <kernelvec>:
    800069a0:	7111                	addi	sp,sp,-256
    800069a2:	e006                	sd	ra,0(sp)
    800069a4:	e40a                	sd	sp,8(sp)
    800069a6:	e80e                	sd	gp,16(sp)
    800069a8:	ec12                	sd	tp,24(sp)
    800069aa:	f016                	sd	t0,32(sp)
    800069ac:	f41a                	sd	t1,40(sp)
    800069ae:	f81e                	sd	t2,48(sp)
    800069b0:	fc22                	sd	s0,56(sp)
    800069b2:	e0a6                	sd	s1,64(sp)
    800069b4:	e4aa                	sd	a0,72(sp)
    800069b6:	e8ae                	sd	a1,80(sp)
    800069b8:	ecb2                	sd	a2,88(sp)
    800069ba:	f0b6                	sd	a3,96(sp)
    800069bc:	f4ba                	sd	a4,104(sp)
    800069be:	f8be                	sd	a5,112(sp)
    800069c0:	fcc2                	sd	a6,120(sp)
    800069c2:	e146                	sd	a7,128(sp)
    800069c4:	e54a                	sd	s2,136(sp)
    800069c6:	e94e                	sd	s3,144(sp)
    800069c8:	ed52                	sd	s4,152(sp)
    800069ca:	f156                	sd	s5,160(sp)
    800069cc:	f55a                	sd	s6,168(sp)
    800069ce:	f95e                	sd	s7,176(sp)
    800069d0:	fd62                	sd	s8,184(sp)
    800069d2:	e1e6                	sd	s9,192(sp)
    800069d4:	e5ea                	sd	s10,200(sp)
    800069d6:	e9ee                	sd	s11,208(sp)
    800069d8:	edf2                	sd	t3,216(sp)
    800069da:	f1f6                	sd	t4,224(sp)
    800069dc:	f5fa                	sd	t5,232(sp)
    800069de:	f9fe                	sd	t6,240(sp)
    800069e0:	d83fc0ef          	jal	ra,80003762 <kerneltrap>
    800069e4:	6082                	ld	ra,0(sp)
    800069e6:	6122                	ld	sp,8(sp)
    800069e8:	61c2                	ld	gp,16(sp)
    800069ea:	7282                	ld	t0,32(sp)
    800069ec:	7322                	ld	t1,40(sp)
    800069ee:	73c2                	ld	t2,48(sp)
    800069f0:	7462                	ld	s0,56(sp)
    800069f2:	6486                	ld	s1,64(sp)
    800069f4:	6526                	ld	a0,72(sp)
    800069f6:	65c6                	ld	a1,80(sp)
    800069f8:	6666                	ld	a2,88(sp)
    800069fa:	7686                	ld	a3,96(sp)
    800069fc:	7726                	ld	a4,104(sp)
    800069fe:	77c6                	ld	a5,112(sp)
    80006a00:	7866                	ld	a6,120(sp)
    80006a02:	688a                	ld	a7,128(sp)
    80006a04:	692a                	ld	s2,136(sp)
    80006a06:	69ca                	ld	s3,144(sp)
    80006a08:	6a6a                	ld	s4,152(sp)
    80006a0a:	7a8a                	ld	s5,160(sp)
    80006a0c:	7b2a                	ld	s6,168(sp)
    80006a0e:	7bca                	ld	s7,176(sp)
    80006a10:	7c6a                	ld	s8,184(sp)
    80006a12:	6c8e                	ld	s9,192(sp)
    80006a14:	6d2e                	ld	s10,200(sp)
    80006a16:	6dce                	ld	s11,208(sp)
    80006a18:	6e6e                	ld	t3,216(sp)
    80006a1a:	7e8e                	ld	t4,224(sp)
    80006a1c:	7f2e                	ld	t5,232(sp)
    80006a1e:	7fce                	ld	t6,240(sp)
    80006a20:	6111                	addi	sp,sp,256
    80006a22:	10200073          	sret
    80006a26:	00000013          	nop
    80006a2a:	00000013          	nop
    80006a2e:	0001                	nop

0000000080006a30 <timervec>:
    80006a30:	34051573          	csrrw	a0,mscratch,a0
    80006a34:	e10c                	sd	a1,0(a0)
    80006a36:	e510                	sd	a2,8(a0)
    80006a38:	e914                	sd	a3,16(a0)
    80006a3a:	6d0c                	ld	a1,24(a0)
    80006a3c:	7110                	ld	a2,32(a0)
    80006a3e:	6194                	ld	a3,0(a1)
    80006a40:	96b2                	add	a3,a3,a2
    80006a42:	e194                	sd	a3,0(a1)
    80006a44:	4589                	li	a1,2
    80006a46:	14459073          	csrw	sip,a1
    80006a4a:	6914                	ld	a3,16(a0)
    80006a4c:	6510                	ld	a2,8(a0)
    80006a4e:	610c                	ld	a1,0(a0)
    80006a50:	34051573          	csrrw	a0,mscratch,a0
    80006a54:	30200073          	mret
	...

0000000080006a5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006a5a:	1141                	addi	sp,sp,-16
    80006a5c:	e422                	sd	s0,8(sp)
    80006a5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006a60:	0c0007b7          	lui	a5,0xc000
    80006a64:	4705                	li	a4,1
    80006a66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006a68:	c3d8                	sw	a4,4(a5)
}
    80006a6a:	6422                	ld	s0,8(sp)
    80006a6c:	0141                	addi	sp,sp,16
    80006a6e:	8082                	ret

0000000080006a70 <plicinithart>:

void
plicinithart(void)
{
    80006a70:	1141                	addi	sp,sp,-16
    80006a72:	e406                	sd	ra,8(sp)
    80006a74:	e022                	sd	s0,0(sp)
    80006a76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006a78:	ffffb097          	auipc	ra,0xffffb
    80006a7c:	3f6080e7          	jalr	1014(ra) # 80001e6e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006a80:	0085171b          	slliw	a4,a0,0x8
    80006a84:	0c0027b7          	lui	a5,0xc002
    80006a88:	97ba                	add	a5,a5,a4
    80006a8a:	40200713          	li	a4,1026
    80006a8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006a92:	00d5151b          	slliw	a0,a0,0xd
    80006a96:	0c2017b7          	lui	a5,0xc201
    80006a9a:	953e                	add	a0,a0,a5
    80006a9c:	00052023          	sw	zero,0(a0)
}
    80006aa0:	60a2                	ld	ra,8(sp)
    80006aa2:	6402                	ld	s0,0(sp)
    80006aa4:	0141                	addi	sp,sp,16
    80006aa6:	8082                	ret

0000000080006aa8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006aa8:	1141                	addi	sp,sp,-16
    80006aaa:	e406                	sd	ra,8(sp)
    80006aac:	e022                	sd	s0,0(sp)
    80006aae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006ab0:	ffffb097          	auipc	ra,0xffffb
    80006ab4:	3be080e7          	jalr	958(ra) # 80001e6e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006ab8:	00d5179b          	slliw	a5,a0,0xd
    80006abc:	0c201537          	lui	a0,0xc201
    80006ac0:	953e                	add	a0,a0,a5
  return irq;
}
    80006ac2:	4148                	lw	a0,4(a0)
    80006ac4:	60a2                	ld	ra,8(sp)
    80006ac6:	6402                	ld	s0,0(sp)
    80006ac8:	0141                	addi	sp,sp,16
    80006aca:	8082                	ret

0000000080006acc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006acc:	1101                	addi	sp,sp,-32
    80006ace:	ec06                	sd	ra,24(sp)
    80006ad0:	e822                	sd	s0,16(sp)
    80006ad2:	e426                	sd	s1,8(sp)
    80006ad4:	1000                	addi	s0,sp,32
    80006ad6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006ad8:	ffffb097          	auipc	ra,0xffffb
    80006adc:	396080e7          	jalr	918(ra) # 80001e6e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006ae0:	00d5151b          	slliw	a0,a0,0xd
    80006ae4:	0c2017b7          	lui	a5,0xc201
    80006ae8:	97aa                	add	a5,a5,a0
    80006aea:	c3c4                	sw	s1,4(a5)
}
    80006aec:	60e2                	ld	ra,24(sp)
    80006aee:	6442                	ld	s0,16(sp)
    80006af0:	64a2                	ld	s1,8(sp)
    80006af2:	6105                	addi	sp,sp,32
    80006af4:	8082                	ret

0000000080006af6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006af6:	1141                	addi	sp,sp,-16
    80006af8:	e406                	sd	ra,8(sp)
    80006afa:	e022                	sd	s0,0(sp)
    80006afc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006afe:	479d                	li	a5,7
    80006b00:	06a7c963          	blt	a5,a0,80006b72 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006b04:	0001d797          	auipc	a5,0x1d
    80006b08:	4fc78793          	addi	a5,a5,1276 # 80024000 <disk>
    80006b0c:	00a78733          	add	a4,a5,a0
    80006b10:	6789                	lui	a5,0x2
    80006b12:	97ba                	add	a5,a5,a4
    80006b14:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006b18:	e7ad                	bnez	a5,80006b82 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006b1a:	00451793          	slli	a5,a0,0x4
    80006b1e:	0001f717          	auipc	a4,0x1f
    80006b22:	4e270713          	addi	a4,a4,1250 # 80026000 <disk+0x2000>
    80006b26:	6314                	ld	a3,0(a4)
    80006b28:	96be                	add	a3,a3,a5
    80006b2a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006b2e:	6314                	ld	a3,0(a4)
    80006b30:	96be                	add	a3,a3,a5
    80006b32:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006b36:	6314                	ld	a3,0(a4)
    80006b38:	96be                	add	a3,a3,a5
    80006b3a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006b3e:	6318                	ld	a4,0(a4)
    80006b40:	97ba                	add	a5,a5,a4
    80006b42:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006b46:	0001d797          	auipc	a5,0x1d
    80006b4a:	4ba78793          	addi	a5,a5,1210 # 80024000 <disk>
    80006b4e:	97aa                	add	a5,a5,a0
    80006b50:	6509                	lui	a0,0x2
    80006b52:	953e                	add	a0,a0,a5
    80006b54:	4785                	li	a5,1
    80006b56:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006b5a:	0001f517          	auipc	a0,0x1f
    80006b5e:	4be50513          	addi	a0,a0,1214 # 80026018 <disk+0x2018>
    80006b62:	ffffc097          	auipc	ra,0xffffc
    80006b66:	3f8080e7          	jalr	1016(ra) # 80002f5a <wakeup>
}
    80006b6a:	60a2                	ld	ra,8(sp)
    80006b6c:	6402                	ld	s0,0(sp)
    80006b6e:	0141                	addi	sp,sp,16
    80006b70:	8082                	ret
    panic("free_desc 1");
    80006b72:	00003517          	auipc	a0,0x3
    80006b76:	dee50513          	addi	a0,a0,-530 # 80009960 <syscalls+0x330>
    80006b7a:	ffffa097          	auipc	ra,0xffffa
    80006b7e:	9c4080e7          	jalr	-1596(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006b82:	00003517          	auipc	a0,0x3
    80006b86:	dee50513          	addi	a0,a0,-530 # 80009970 <syscalls+0x340>
    80006b8a:	ffffa097          	auipc	ra,0xffffa
    80006b8e:	9b4080e7          	jalr	-1612(ra) # 8000053e <panic>

0000000080006b92 <virtio_disk_init>:
{
    80006b92:	1101                	addi	sp,sp,-32
    80006b94:	ec06                	sd	ra,24(sp)
    80006b96:	e822                	sd	s0,16(sp)
    80006b98:	e426                	sd	s1,8(sp)
    80006b9a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006b9c:	00003597          	auipc	a1,0x3
    80006ba0:	de458593          	addi	a1,a1,-540 # 80009980 <syscalls+0x350>
    80006ba4:	0001f517          	auipc	a0,0x1f
    80006ba8:	58450513          	addi	a0,a0,1412 # 80026128 <disk+0x2128>
    80006bac:	ffffa097          	auipc	ra,0xffffa
    80006bb0:	fa8080e7          	jalr	-88(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006bb4:	100017b7          	lui	a5,0x10001
    80006bb8:	4398                	lw	a4,0(a5)
    80006bba:	2701                	sext.w	a4,a4
    80006bbc:	747277b7          	lui	a5,0x74727
    80006bc0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006bc4:	0ef71163          	bne	a4,a5,80006ca6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006bc8:	100017b7          	lui	a5,0x10001
    80006bcc:	43dc                	lw	a5,4(a5)
    80006bce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006bd0:	4705                	li	a4,1
    80006bd2:	0ce79a63          	bne	a5,a4,80006ca6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006bd6:	100017b7          	lui	a5,0x10001
    80006bda:	479c                	lw	a5,8(a5)
    80006bdc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006bde:	4709                	li	a4,2
    80006be0:	0ce79363          	bne	a5,a4,80006ca6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006be4:	100017b7          	lui	a5,0x10001
    80006be8:	47d8                	lw	a4,12(a5)
    80006bea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006bec:	554d47b7          	lui	a5,0x554d4
    80006bf0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006bf4:	0af71963          	bne	a4,a5,80006ca6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006bf8:	100017b7          	lui	a5,0x10001
    80006bfc:	4705                	li	a4,1
    80006bfe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c00:	470d                	li	a4,3
    80006c02:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006c04:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006c06:	c7ffe737          	lui	a4,0xc7ffe
    80006c0a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80006c0e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006c10:	2701                	sext.w	a4,a4
    80006c12:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c14:	472d                	li	a4,11
    80006c16:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006c18:	473d                	li	a4,15
    80006c1a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006c1c:	6705                	lui	a4,0x1
    80006c1e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006c20:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006c24:	5bdc                	lw	a5,52(a5)
    80006c26:	2781                	sext.w	a5,a5
  if(max == 0)
    80006c28:	c7d9                	beqz	a5,80006cb6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006c2a:	471d                	li	a4,7
    80006c2c:	08f77d63          	bgeu	a4,a5,80006cc6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006c30:	100014b7          	lui	s1,0x10001
    80006c34:	47a1                	li	a5,8
    80006c36:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006c38:	6609                	lui	a2,0x2
    80006c3a:	4581                	li	a1,0
    80006c3c:	0001d517          	auipc	a0,0x1d
    80006c40:	3c450513          	addi	a0,a0,964 # 80024000 <disk>
    80006c44:	ffffa097          	auipc	ra,0xffffa
    80006c48:	0aa080e7          	jalr	170(ra) # 80000cee <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006c4c:	0001d717          	auipc	a4,0x1d
    80006c50:	3b470713          	addi	a4,a4,948 # 80024000 <disk>
    80006c54:	00c75793          	srli	a5,a4,0xc
    80006c58:	2781                	sext.w	a5,a5
    80006c5a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006c5c:	0001f797          	auipc	a5,0x1f
    80006c60:	3a478793          	addi	a5,a5,932 # 80026000 <disk+0x2000>
    80006c64:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006c66:	0001d717          	auipc	a4,0x1d
    80006c6a:	41a70713          	addi	a4,a4,1050 # 80024080 <disk+0x80>
    80006c6e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006c70:	0001e717          	auipc	a4,0x1e
    80006c74:	39070713          	addi	a4,a4,912 # 80025000 <disk+0x1000>
    80006c78:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006c7a:	4705                	li	a4,1
    80006c7c:	00e78c23          	sb	a4,24(a5)
    80006c80:	00e78ca3          	sb	a4,25(a5)
    80006c84:	00e78d23          	sb	a4,26(a5)
    80006c88:	00e78da3          	sb	a4,27(a5)
    80006c8c:	00e78e23          	sb	a4,28(a5)
    80006c90:	00e78ea3          	sb	a4,29(a5)
    80006c94:	00e78f23          	sb	a4,30(a5)
    80006c98:	00e78fa3          	sb	a4,31(a5)
}
    80006c9c:	60e2                	ld	ra,24(sp)
    80006c9e:	6442                	ld	s0,16(sp)
    80006ca0:	64a2                	ld	s1,8(sp)
    80006ca2:	6105                	addi	sp,sp,32
    80006ca4:	8082                	ret
    panic("could not find virtio disk");
    80006ca6:	00003517          	auipc	a0,0x3
    80006caa:	cea50513          	addi	a0,a0,-790 # 80009990 <syscalls+0x360>
    80006cae:	ffffa097          	auipc	ra,0xffffa
    80006cb2:	890080e7          	jalr	-1904(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006cb6:	00003517          	auipc	a0,0x3
    80006cba:	cfa50513          	addi	a0,a0,-774 # 800099b0 <syscalls+0x380>
    80006cbe:	ffffa097          	auipc	ra,0xffffa
    80006cc2:	880080e7          	jalr	-1920(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006cc6:	00003517          	auipc	a0,0x3
    80006cca:	d0a50513          	addi	a0,a0,-758 # 800099d0 <syscalls+0x3a0>
    80006cce:	ffffa097          	auipc	ra,0xffffa
    80006cd2:	870080e7          	jalr	-1936(ra) # 8000053e <panic>

0000000080006cd6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006cd6:	7159                	addi	sp,sp,-112
    80006cd8:	f486                	sd	ra,104(sp)
    80006cda:	f0a2                	sd	s0,96(sp)
    80006cdc:	eca6                	sd	s1,88(sp)
    80006cde:	e8ca                	sd	s2,80(sp)
    80006ce0:	e4ce                	sd	s3,72(sp)
    80006ce2:	e0d2                	sd	s4,64(sp)
    80006ce4:	fc56                	sd	s5,56(sp)
    80006ce6:	f85a                	sd	s6,48(sp)
    80006ce8:	f45e                	sd	s7,40(sp)
    80006cea:	f062                	sd	s8,32(sp)
    80006cec:	ec66                	sd	s9,24(sp)
    80006cee:	e86a                	sd	s10,16(sp)
    80006cf0:	1880                	addi	s0,sp,112
    80006cf2:	892a                	mv	s2,a0
    80006cf4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006cf6:	00c52c83          	lw	s9,12(a0)
    80006cfa:	001c9c9b          	slliw	s9,s9,0x1
    80006cfe:	1c82                	slli	s9,s9,0x20
    80006d00:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006d04:	0001f517          	auipc	a0,0x1f
    80006d08:	42450513          	addi	a0,a0,1060 # 80026128 <disk+0x2128>
    80006d0c:	ffffa097          	auipc	ra,0xffffa
    80006d10:	ee0080e7          	jalr	-288(ra) # 80000bec <acquire>
  for(int i = 0; i < 3; i++){
    80006d14:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006d16:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006d18:	0001db97          	auipc	s7,0x1d
    80006d1c:	2e8b8b93          	addi	s7,s7,744 # 80024000 <disk>
    80006d20:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006d22:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006d24:	8a4e                	mv	s4,s3
    80006d26:	a051                	j	80006daa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006d28:	00fb86b3          	add	a3,s7,a5
    80006d2c:	96da                	add	a3,a3,s6
    80006d2e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006d32:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006d34:	0207c563          	bltz	a5,80006d5e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006d38:	2485                	addiw	s1,s1,1
    80006d3a:	0711                	addi	a4,a4,4
    80006d3c:	25548063          	beq	s1,s5,80006f7c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006d40:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006d42:	0001f697          	auipc	a3,0x1f
    80006d46:	2d668693          	addi	a3,a3,726 # 80026018 <disk+0x2018>
    80006d4a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006d4c:	0006c583          	lbu	a1,0(a3)
    80006d50:	fde1                	bnez	a1,80006d28 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006d52:	2785                	addiw	a5,a5,1
    80006d54:	0685                	addi	a3,a3,1
    80006d56:	ff879be3          	bne	a5,s8,80006d4c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006d5a:	57fd                	li	a5,-1
    80006d5c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006d5e:	02905a63          	blez	s1,80006d92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006d62:	f9042503          	lw	a0,-112(s0)
    80006d66:	00000097          	auipc	ra,0x0
    80006d6a:	d90080e7          	jalr	-624(ra) # 80006af6 <free_desc>
      for(int j = 0; j < i; j++)
    80006d6e:	4785                	li	a5,1
    80006d70:	0297d163          	bge	a5,s1,80006d92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006d74:	f9442503          	lw	a0,-108(s0)
    80006d78:	00000097          	auipc	ra,0x0
    80006d7c:	d7e080e7          	jalr	-642(ra) # 80006af6 <free_desc>
      for(int j = 0; j < i; j++)
    80006d80:	4789                	li	a5,2
    80006d82:	0097d863          	bge	a5,s1,80006d92 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006d86:	f9842503          	lw	a0,-104(s0)
    80006d8a:	00000097          	auipc	ra,0x0
    80006d8e:	d6c080e7          	jalr	-660(ra) # 80006af6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006d92:	0001f597          	auipc	a1,0x1f
    80006d96:	39658593          	addi	a1,a1,918 # 80026128 <disk+0x2128>
    80006d9a:	0001f517          	auipc	a0,0x1f
    80006d9e:	27e50513          	addi	a0,a0,638 # 80026018 <disk+0x2018>
    80006da2:	ffffc097          	auipc	ra,0xffffc
    80006da6:	010080e7          	jalr	16(ra) # 80002db2 <sleep>
  for(int i = 0; i < 3; i++){
    80006daa:	f9040713          	addi	a4,s0,-112
    80006dae:	84ce                	mv	s1,s3
    80006db0:	bf41                	j	80006d40 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006db2:	20058713          	addi	a4,a1,512
    80006db6:	00471693          	slli	a3,a4,0x4
    80006dba:	0001d717          	auipc	a4,0x1d
    80006dbe:	24670713          	addi	a4,a4,582 # 80024000 <disk>
    80006dc2:	9736                	add	a4,a4,a3
    80006dc4:	4685                	li	a3,1
    80006dc6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006dca:	20058713          	addi	a4,a1,512
    80006dce:	00471693          	slli	a3,a4,0x4
    80006dd2:	0001d717          	auipc	a4,0x1d
    80006dd6:	22e70713          	addi	a4,a4,558 # 80024000 <disk>
    80006dda:	9736                	add	a4,a4,a3
    80006ddc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006de0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006de4:	7679                	lui	a2,0xffffe
    80006de6:	963e                	add	a2,a2,a5
    80006de8:	0001f697          	auipc	a3,0x1f
    80006dec:	21868693          	addi	a3,a3,536 # 80026000 <disk+0x2000>
    80006df0:	6298                	ld	a4,0(a3)
    80006df2:	9732                	add	a4,a4,a2
    80006df4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006df6:	6298                	ld	a4,0(a3)
    80006df8:	9732                	add	a4,a4,a2
    80006dfa:	4541                	li	a0,16
    80006dfc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006dfe:	6298                	ld	a4,0(a3)
    80006e00:	9732                	add	a4,a4,a2
    80006e02:	4505                	li	a0,1
    80006e04:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006e08:	f9442703          	lw	a4,-108(s0)
    80006e0c:	6288                	ld	a0,0(a3)
    80006e0e:	962a                	add	a2,a2,a0
    80006e10:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd700e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006e14:	0712                	slli	a4,a4,0x4
    80006e16:	6290                	ld	a2,0(a3)
    80006e18:	963a                	add	a2,a2,a4
    80006e1a:	05890513          	addi	a0,s2,88
    80006e1e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006e20:	6294                	ld	a3,0(a3)
    80006e22:	96ba                	add	a3,a3,a4
    80006e24:	40000613          	li	a2,1024
    80006e28:	c690                	sw	a2,8(a3)
  if(write)
    80006e2a:	140d0063          	beqz	s10,80006f6a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006e2e:	0001f697          	auipc	a3,0x1f
    80006e32:	1d26b683          	ld	a3,466(a3) # 80026000 <disk+0x2000>
    80006e36:	96ba                	add	a3,a3,a4
    80006e38:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006e3c:	0001d817          	auipc	a6,0x1d
    80006e40:	1c480813          	addi	a6,a6,452 # 80024000 <disk>
    80006e44:	0001f517          	auipc	a0,0x1f
    80006e48:	1bc50513          	addi	a0,a0,444 # 80026000 <disk+0x2000>
    80006e4c:	6114                	ld	a3,0(a0)
    80006e4e:	96ba                	add	a3,a3,a4
    80006e50:	00c6d603          	lhu	a2,12(a3)
    80006e54:	00166613          	ori	a2,a2,1
    80006e58:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006e5c:	f9842683          	lw	a3,-104(s0)
    80006e60:	6110                	ld	a2,0(a0)
    80006e62:	9732                	add	a4,a4,a2
    80006e64:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006e68:	20058613          	addi	a2,a1,512
    80006e6c:	0612                	slli	a2,a2,0x4
    80006e6e:	9642                	add	a2,a2,a6
    80006e70:	577d                	li	a4,-1
    80006e72:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006e76:	00469713          	slli	a4,a3,0x4
    80006e7a:	6114                	ld	a3,0(a0)
    80006e7c:	96ba                	add	a3,a3,a4
    80006e7e:	03078793          	addi	a5,a5,48
    80006e82:	97c2                	add	a5,a5,a6
    80006e84:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006e86:	611c                	ld	a5,0(a0)
    80006e88:	97ba                	add	a5,a5,a4
    80006e8a:	4685                	li	a3,1
    80006e8c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006e8e:	611c                	ld	a5,0(a0)
    80006e90:	97ba                	add	a5,a5,a4
    80006e92:	4809                	li	a6,2
    80006e94:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006e98:	611c                	ld	a5,0(a0)
    80006e9a:	973e                	add	a4,a4,a5
    80006e9c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006ea0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006ea4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006ea8:	6518                	ld	a4,8(a0)
    80006eaa:	00275783          	lhu	a5,2(a4)
    80006eae:	8b9d                	andi	a5,a5,7
    80006eb0:	0786                	slli	a5,a5,0x1
    80006eb2:	97ba                	add	a5,a5,a4
    80006eb4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006eb8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006ebc:	6518                	ld	a4,8(a0)
    80006ebe:	00275783          	lhu	a5,2(a4)
    80006ec2:	2785                	addiw	a5,a5,1
    80006ec4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006ec8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006ecc:	100017b7          	lui	a5,0x10001
    80006ed0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006ed4:	00492703          	lw	a4,4(s2)
    80006ed8:	4785                	li	a5,1
    80006eda:	02f71163          	bne	a4,a5,80006efc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006ede:	0001f997          	auipc	s3,0x1f
    80006ee2:	24a98993          	addi	s3,s3,586 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    80006ee6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006ee8:	85ce                	mv	a1,s3
    80006eea:	854a                	mv	a0,s2
    80006eec:	ffffc097          	auipc	ra,0xffffc
    80006ef0:	ec6080e7          	jalr	-314(ra) # 80002db2 <sleep>
  while(b->disk == 1) {
    80006ef4:	00492783          	lw	a5,4(s2)
    80006ef8:	fe9788e3          	beq	a5,s1,80006ee8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006efc:	f9042903          	lw	s2,-112(s0)
    80006f00:	20090793          	addi	a5,s2,512
    80006f04:	00479713          	slli	a4,a5,0x4
    80006f08:	0001d797          	auipc	a5,0x1d
    80006f0c:	0f878793          	addi	a5,a5,248 # 80024000 <disk>
    80006f10:	97ba                	add	a5,a5,a4
    80006f12:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006f16:	0001f997          	auipc	s3,0x1f
    80006f1a:	0ea98993          	addi	s3,s3,234 # 80026000 <disk+0x2000>
    80006f1e:	00491713          	slli	a4,s2,0x4
    80006f22:	0009b783          	ld	a5,0(s3)
    80006f26:	97ba                	add	a5,a5,a4
    80006f28:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006f2c:	854a                	mv	a0,s2
    80006f2e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006f32:	00000097          	auipc	ra,0x0
    80006f36:	bc4080e7          	jalr	-1084(ra) # 80006af6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006f3a:	8885                	andi	s1,s1,1
    80006f3c:	f0ed                	bnez	s1,80006f1e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006f3e:	0001f517          	auipc	a0,0x1f
    80006f42:	1ea50513          	addi	a0,a0,490 # 80026128 <disk+0x2128>
    80006f46:	ffffa097          	auipc	ra,0xffffa
    80006f4a:	d60080e7          	jalr	-672(ra) # 80000ca6 <release>
}
    80006f4e:	70a6                	ld	ra,104(sp)
    80006f50:	7406                	ld	s0,96(sp)
    80006f52:	64e6                	ld	s1,88(sp)
    80006f54:	6946                	ld	s2,80(sp)
    80006f56:	69a6                	ld	s3,72(sp)
    80006f58:	6a06                	ld	s4,64(sp)
    80006f5a:	7ae2                	ld	s5,56(sp)
    80006f5c:	7b42                	ld	s6,48(sp)
    80006f5e:	7ba2                	ld	s7,40(sp)
    80006f60:	7c02                	ld	s8,32(sp)
    80006f62:	6ce2                	ld	s9,24(sp)
    80006f64:	6d42                	ld	s10,16(sp)
    80006f66:	6165                	addi	sp,sp,112
    80006f68:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006f6a:	0001f697          	auipc	a3,0x1f
    80006f6e:	0966b683          	ld	a3,150(a3) # 80026000 <disk+0x2000>
    80006f72:	96ba                	add	a3,a3,a4
    80006f74:	4609                	li	a2,2
    80006f76:	00c69623          	sh	a2,12(a3)
    80006f7a:	b5c9                	j	80006e3c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006f7c:	f9042583          	lw	a1,-112(s0)
    80006f80:	20058793          	addi	a5,a1,512
    80006f84:	0792                	slli	a5,a5,0x4
    80006f86:	0001d517          	auipc	a0,0x1d
    80006f8a:	12250513          	addi	a0,a0,290 # 800240a8 <disk+0xa8>
    80006f8e:	953e                	add	a0,a0,a5
  if(write)
    80006f90:	e20d11e3          	bnez	s10,80006db2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006f94:	20058713          	addi	a4,a1,512
    80006f98:	00471693          	slli	a3,a4,0x4
    80006f9c:	0001d717          	auipc	a4,0x1d
    80006fa0:	06470713          	addi	a4,a4,100 # 80024000 <disk>
    80006fa4:	9736                	add	a4,a4,a3
    80006fa6:	0a072423          	sw	zero,168(a4)
    80006faa:	b505                	j	80006dca <virtio_disk_rw+0xf4>

0000000080006fac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006fac:	1101                	addi	sp,sp,-32
    80006fae:	ec06                	sd	ra,24(sp)
    80006fb0:	e822                	sd	s0,16(sp)
    80006fb2:	e426                	sd	s1,8(sp)
    80006fb4:	e04a                	sd	s2,0(sp)
    80006fb6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006fb8:	0001f517          	auipc	a0,0x1f
    80006fbc:	17050513          	addi	a0,a0,368 # 80026128 <disk+0x2128>
    80006fc0:	ffffa097          	auipc	ra,0xffffa
    80006fc4:	c2c080e7          	jalr	-980(ra) # 80000bec <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006fc8:	10001737          	lui	a4,0x10001
    80006fcc:	533c                	lw	a5,96(a4)
    80006fce:	8b8d                	andi	a5,a5,3
    80006fd0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006fd2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006fd6:	0001f797          	auipc	a5,0x1f
    80006fda:	02a78793          	addi	a5,a5,42 # 80026000 <disk+0x2000>
    80006fde:	6b94                	ld	a3,16(a5)
    80006fe0:	0207d703          	lhu	a4,32(a5)
    80006fe4:	0026d783          	lhu	a5,2(a3)
    80006fe8:	06f70163          	beq	a4,a5,8000704a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006fec:	0001d917          	auipc	s2,0x1d
    80006ff0:	01490913          	addi	s2,s2,20 # 80024000 <disk>
    80006ff4:	0001f497          	auipc	s1,0x1f
    80006ff8:	00c48493          	addi	s1,s1,12 # 80026000 <disk+0x2000>
    __sync_synchronize();
    80006ffc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007000:	6898                	ld	a4,16(s1)
    80007002:	0204d783          	lhu	a5,32(s1)
    80007006:	8b9d                	andi	a5,a5,7
    80007008:	078e                	slli	a5,a5,0x3
    8000700a:	97ba                	add	a5,a5,a4
    8000700c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000700e:	20078713          	addi	a4,a5,512
    80007012:	0712                	slli	a4,a4,0x4
    80007014:	974a                	add	a4,a4,s2
    80007016:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000701a:	e731                	bnez	a4,80007066 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000701c:	20078793          	addi	a5,a5,512
    80007020:	0792                	slli	a5,a5,0x4
    80007022:	97ca                	add	a5,a5,s2
    80007024:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007026:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000702a:	ffffc097          	auipc	ra,0xffffc
    8000702e:	f30080e7          	jalr	-208(ra) # 80002f5a <wakeup>

    disk.used_idx += 1;
    80007032:	0204d783          	lhu	a5,32(s1)
    80007036:	2785                	addiw	a5,a5,1
    80007038:	17c2                	slli	a5,a5,0x30
    8000703a:	93c1                	srli	a5,a5,0x30
    8000703c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007040:	6898                	ld	a4,16(s1)
    80007042:	00275703          	lhu	a4,2(a4)
    80007046:	faf71be3          	bne	a4,a5,80006ffc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000704a:	0001f517          	auipc	a0,0x1f
    8000704e:	0de50513          	addi	a0,a0,222 # 80026128 <disk+0x2128>
    80007052:	ffffa097          	auipc	ra,0xffffa
    80007056:	c54080e7          	jalr	-940(ra) # 80000ca6 <release>
}
    8000705a:	60e2                	ld	ra,24(sp)
    8000705c:	6442                	ld	s0,16(sp)
    8000705e:	64a2                	ld	s1,8(sp)
    80007060:	6902                	ld	s2,0(sp)
    80007062:	6105                	addi	sp,sp,32
    80007064:	8082                	ret
      panic("virtio_disk_intr status");
    80007066:	00003517          	auipc	a0,0x3
    8000706a:	98a50513          	addi	a0,a0,-1654 # 800099f0 <syscalls+0x3c0>
    8000706e:	ffff9097          	auipc	ra,0xffff9
    80007072:	4d0080e7          	jalr	1232(ra) # 8000053e <panic>

0000000080007076 <cas>:
    80007076:	100522af          	lr.w	t0,(a0)
    8000707a:	00b29563          	bne	t0,a1,80007084 <fail>
    8000707e:	18c5252f          	sc.w	a0,a2,(a0)
    80007082:	8082                	ret

0000000080007084 <fail>:
    80007084:	4505                	li	a0,1
    80007086:	8082                	ret
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
