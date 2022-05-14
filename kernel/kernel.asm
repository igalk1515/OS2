
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
    80000068:	75c78793          	addi	a5,a5,1884 # 800067c0 <timervec>
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
    80000130:	f98080e7          	jalr	-104(ra) # 800030c4 <either_copyin>
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
    800001c8:	0c8080e7          	jalr	200(ra) # 8000228c <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00003097          	auipc	ra,0x3
    800001d8:	97c080e7          	jalr	-1668(ra) # 80002b50 <sleep>
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
    80000214:	e5e080e7          	jalr	-418(ra) # 8000306e <either_copyout>
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
    800002f6:	e28080e7          	jalr	-472(ra) # 8000311a <procdump>
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
    8000044a:	8b0080e7          	jalr	-1872(ra) # 80002cf6 <wakeup>
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
    800008a4:	456080e7          	jalr	1110(ra) # 80002cf6 <wakeup>
    
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
    80000930:	224080e7          	jalr	548(ra) # 80002b50 <sleep>
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
    80000b82:	6ea080e7          	jalr	1770(ra) # 80002268 <mycpu>
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
    80000bb4:	6b8080e7          	jalr	1720(ra) # 80002268 <mycpu>
    80000bb8:	08052783          	lw	a5,128(a0)
    80000bbc:	cf99                	beqz	a5,80000bda <push_off+0x42>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	6aa080e7          	jalr	1706(ra) # 80002268 <mycpu>
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
    80000bde:	68e080e7          	jalr	1678(ra) # 80002268 <mycpu>
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
    80000c20:	64c080e7          	jalr	1612(ra) # 80002268 <mycpu>
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
    80000c4c:	620080e7          	jalr	1568(ra) # 80002268 <mycpu>
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
    80000ea8:	3b4080e7          	jalr	948(ra) # 80002258 <cpuid>
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
    80000ec4:	398080e7          	jalr	920(ra) # 80002258 <cpuid>
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
    80000ee6:	378080e7          	jalr	888(ra) # 8000325a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eea:	00006097          	auipc	ra,0x6
    80000eee:	916080e7          	jalr	-1770(ra) # 80006800 <plicinithart>
  }

  scheduler();        
    80000ef2:	00002097          	auipc	ra,0x2
    80000ef6:	9e4080e7          	jalr	-1564(ra) # 800028d6 <scheduler>
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
    80000f56:	1b2080e7          	jalr	434(ra) # 80002104 <procinit>
    trapinit();      // trap vectors
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	2d8080e7          	jalr	728(ra) # 80003232 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	2f8080e7          	jalr	760(ra) # 8000325a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f6a:	00006097          	auipc	ra,0x6
    80000f6e:	880080e7          	jalr	-1920(ra) # 800067ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f72:	00006097          	auipc	ra,0x6
    80000f76:	88e080e7          	jalr	-1906(ra) # 80006800 <plicinithart>
    binit();         // buffer cache
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	a6c080e7          	jalr	-1428(ra) # 800039e6 <binit>
    iinit();         // inode table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	0fc080e7          	jalr	252(ra) # 8000407e <iinit>
    fileinit();      // file table
    80000f8a:	00004097          	auipc	ra,0x4
    80000f8e:	0a6080e7          	jalr	166(ra) # 80005030 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f92:	00006097          	auipc	ra,0x6
    80000f96:	990080e7          	jalr	-1648(ra) # 80006922 <virtio_disk_init>
    userinit();      // first user process
    80000f9a:	00001097          	auipc	ra,0x1
    80000f9e:	5e4080e7          	jalr	1508(ra) # 8000257e <userinit>
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
    80001252:	e20080e7          	jalr	-480(ra) # 8000206e <proc_mapstacks>
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
    80001b7c:	28e080e7          	jalr	654(ra) # 80006e06 <cas>
    80001b80:	f57d                	bnez	a0,80001b6e <cahnge_number_of_proc+0x2e>
}
    80001b82:	70a2                	ld	ra,40(sp)
    80001b84:	7402                	ld	s0,32(sp)
    80001b86:	64e2                	ld	s1,24(sp)
    80001b88:	6942                	ld	s2,16(sp)
    80001b8a:	69a2                	ld	s3,8(sp)
    80001b8c:	6145                	addi	sp,sp,48
    80001b8e:	8082                	ret

0000000080001b90 <acquire_list>:
struct spinlock zombie_lock;
struct spinlock sleeping_lock;
struct spinlock unused_lock;

void
acquire_list(int type, int cpu_id){
    80001b90:	1141                	addi	sp,sp,-16
    80001b92:	e406                	sd	ra,8(sp)
    80001b94:	e022                	sd	s0,0(sp)
    80001b96:	0800                	addi	s0,sp,16
  switch (type)
    80001b98:	4789                	li	a5,2
    80001b9a:	04f50e63          	beq	a0,a5,80001bf6 <acquire_list+0x66>
    80001b9e:	00a7cf63          	blt	a5,a0,80001bbc <acquire_list+0x2c>
    80001ba2:	c90d                	beqz	a0,80001bd4 <acquire_list+0x44>
    80001ba4:	4785                	li	a5,1
    80001ba6:	06f51163          	bne	a0,a5,80001c08 <acquire_list+0x78>
  {
  case READYL:
    acquire(&ready_lock[cpu_id]);
    break;
  case ZOMBIEL:
    acquire(&zombie_lock);
    80001baa:	00010517          	auipc	a0,0x10
    80001bae:	9be50513          	addi	a0,a0,-1602 # 80011568 <zombie_lock>
    80001bb2:	fffff097          	auipc	ra,0xfffff
    80001bb6:	03a080e7          	jalr	58(ra) # 80000bec <acquire>
    break;
    80001bba:	a815                	j	80001bee <acquire_list+0x5e>
  switch (type)
    80001bbc:	478d                	li	a5,3
    80001bbe:	04f51563          	bne	a0,a5,80001c08 <acquire_list+0x78>
  case SLEEPINGL:
    acquire(&sleeping_lock);
    break;
  case UNUSEDL:
    acquire(&unused_lock);
    80001bc2:	00010517          	auipc	a0,0x10
    80001bc6:	9d650513          	addi	a0,a0,-1578 # 80011598 <unused_lock>
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	022080e7          	jalr	34(ra) # 80000bec <acquire>
    break;
    80001bd2:	a831                	j	80001bee <acquire_list+0x5e>
    acquire(&ready_lock[cpu_id]);
    80001bd4:	00159513          	slli	a0,a1,0x1
    80001bd8:	95aa                	add	a1,a1,a0
    80001bda:	058e                	slli	a1,a1,0x3
    80001bdc:	00010517          	auipc	a0,0x10
    80001be0:	94450513          	addi	a0,a0,-1724 # 80011520 <ready_lock>
    80001be4:	952e                	add	a0,a0,a1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	006080e7          	jalr	6(ra) # 80000bec <acquire>
  
  default:
    panic("wrong type list");
  }
}
    80001bee:	60a2                	ld	ra,8(sp)
    80001bf0:	6402                	ld	s0,0(sp)
    80001bf2:	0141                	addi	sp,sp,16
    80001bf4:	8082                	ret
    acquire(&sleeping_lock);
    80001bf6:	00010517          	auipc	a0,0x10
    80001bfa:	98a50513          	addi	a0,a0,-1654 # 80011580 <sleeping_lock>
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	fee080e7          	jalr	-18(ra) # 80000bec <acquire>
    break;
    80001c06:	b7e5                	j	80001bee <acquire_list+0x5e>
    panic("wrong type list");
    80001c08:	00006517          	auipc	a0,0x6
    80001c0c:	66850513          	addi	a0,a0,1640 # 80008270 <digits+0x230>
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	92e080e7          	jalr	-1746(ra) # 8000053e <panic>

0000000080001c18 <get_head>:

struct proc* get_head(int type, int cpu_id){
  struct proc* p;

  switch (type)
    80001c18:	4789                	li	a5,2
    80001c1a:	04f50163          	beq	a0,a5,80001c5c <get_head+0x44>
    80001c1e:	00a7cb63          	blt	a5,a0,80001c34 <get_head+0x1c>
    80001c22:	c10d                	beqz	a0,80001c44 <get_head+0x2c>
    80001c24:	4785                	li	a5,1
    80001c26:	04f51063          	bne	a0,a5,80001c66 <get_head+0x4e>
  {
  case READYL:
    p = cpus[cpu_id].first;
    break;
  case ZOMBIEL:
    p = zombie_list;
    80001c2a:	00007517          	auipc	a0,0x7
    80001c2e:	40e53503          	ld	a0,1038(a0) # 80009038 <zombie_list>
    break;
    80001c32:	8082                	ret
  switch (type)
    80001c34:	478d                	li	a5,3
    80001c36:	02f51863          	bne	a0,a5,80001c66 <get_head+0x4e>
  case SLEEPINGL:
    p = sleeping_list;
    break;
  case UNUSEDL:
    p = unused_list;
    80001c3a:	00007517          	auipc	a0,0x7
    80001c3e:	3f653503          	ld	a0,1014(a0) # 80009030 <unused_list>
  
  default:
    panic("wrong type list");
  }
  return p;
}
    80001c42:	8082                	ret
    p = cpus[cpu_id].first;
    80001c44:	00359793          	slli	a5,a1,0x3
    80001c48:	95be                	add	a1,a1,a5
    80001c4a:	0592                	slli	a1,a1,0x4
    80001c4c:	0000f797          	auipc	a5,0xf
    80001c50:	69478793          	addi	a5,a5,1684 # 800112e0 <readyLock>
    80001c54:	95be                	add	a1,a1,a5
    80001c56:	1185b503          	ld	a0,280(a1)
    break;
    80001c5a:	8082                	ret
    p = sleeping_list;
    80001c5c:	00007517          	auipc	a0,0x7
    80001c60:	3cc53503          	ld	a0,972(a0) # 80009028 <sleeping_list>
    break;
    80001c64:	8082                	ret
struct proc* get_head(int type, int cpu_id){
    80001c66:	1141                	addi	sp,sp,-16
    80001c68:	e406                	sd	ra,8(sp)
    80001c6a:	e022                	sd	s0,0(sp)
    80001c6c:	0800                	addi	s0,sp,16
    panic("wrong type list");
    80001c6e:	00006517          	auipc	a0,0x6
    80001c72:	60250513          	addi	a0,a0,1538 # 80008270 <digits+0x230>
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	8c8080e7          	jalr	-1848(ra) # 8000053e <panic>

0000000080001c7e <set_head>:


void
set_head(struct proc* p, int type, int cpu_id)
{
  switch (type)
    80001c7e:	4789                	li	a5,2
    80001c80:	04f58163          	beq	a1,a5,80001cc2 <set_head+0x44>
    80001c84:	00b7cb63          	blt	a5,a1,80001c9a <set_head+0x1c>
    80001c88:	c18d                	beqz	a1,80001caa <set_head+0x2c>
    80001c8a:	4785                	li	a5,1
    80001c8c:	04f59063          	bne	a1,a5,80001ccc <set_head+0x4e>
  {
  case READYL:
    cpus[cpu_id].first = p;
    break;
  case ZOMBIEL:
    zombie_list = p;
    80001c90:	00007797          	auipc	a5,0x7
    80001c94:	3aa7b423          	sd	a0,936(a5) # 80009038 <zombie_list>
    break;
    80001c98:	8082                	ret
  switch (type)
    80001c9a:	478d                	li	a5,3
    80001c9c:	02f59863          	bne	a1,a5,80001ccc <set_head+0x4e>
  case SLEEPINGL:
    sleeping_list = p;
    break;
  case UNUSEDL:
    unused_list = p;
    80001ca0:	00007797          	auipc	a5,0x7
    80001ca4:	38a7b823          	sd	a0,912(a5) # 80009030 <unused_list>
    break;
    80001ca8:	8082                	ret
    cpus[cpu_id].first = p;
    80001caa:	00361793          	slli	a5,a2,0x3
    80001cae:	963e                	add	a2,a2,a5
    80001cb0:	0612                	slli	a2,a2,0x4
    80001cb2:	0000f797          	auipc	a5,0xf
    80001cb6:	62e78793          	addi	a5,a5,1582 # 800112e0 <readyLock>
    80001cba:	963e                	add	a2,a2,a5
    80001cbc:	10a63c23          	sd	a0,280(a2)
    break;
    80001cc0:	8082                	ret
    sleeping_list = p;
    80001cc2:	00007797          	auipc	a5,0x7
    80001cc6:	36a7b323          	sd	a0,870(a5) # 80009028 <sleeping_list>
    break;
    80001cca:	8082                	ret
{
    80001ccc:	1141                	addi	sp,sp,-16
    80001cce:	e406                	sd	ra,8(sp)
    80001cd0:	e022                	sd	s0,0(sp)
    80001cd2:	0800                	addi	s0,sp,16

  
  default:
    panic("wrong type list");
    80001cd4:	00006517          	auipc	a0,0x6
    80001cd8:	59c50513          	addi	a0,a0,1436 # 80008270 <digits+0x230>
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	862080e7          	jalr	-1950(ra) # 8000053e <panic>

0000000080001ce4 <release_list3>:
  }
}

void
release_list3(int number, int parent_cpu){
    80001ce4:	1141                	addi	sp,sp,-16
    80001ce6:	e406                	sd	ra,8(sp)
    80001ce8:	e022                	sd	s0,0(sp)
    80001cea:	0800                	addi	s0,sp,16
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001cec:	4785                	li	a5,1
    80001cee:	02f50763          	beq	a0,a5,80001d1c <release_list3+0x38>
      number == 2 ? release(&zombie_lock): 
    80001cf2:	4789                	li	a5,2
    80001cf4:	04f50263          	beq	a0,a5,80001d38 <release_list3+0x54>
        number == 3 ? release(&sleeping_lock): 
    80001cf8:	478d                	li	a5,3
    80001cfa:	04f50863          	beq	a0,a5,80001d4a <release_list3+0x66>
          number == 4 ? release(&unused_lock):  
    80001cfe:	4791                	li	a5,4
    80001d00:	04f51e63          	bne	a0,a5,80001d5c <release_list3+0x78>
    80001d04:	00010517          	auipc	a0,0x10
    80001d08:	89450513          	addi	a0,a0,-1900 # 80011598 <unused_lock>
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	f9a080e7          	jalr	-102(ra) # 80000ca6 <release>
            panic("wrong call in release_list3");
}
    80001d14:	60a2                	ld	ra,8(sp)
    80001d16:	6402                	ld	s0,0(sp)
    80001d18:	0141                	addi	sp,sp,16
    80001d1a:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001d1c:	00159513          	slli	a0,a1,0x1
    80001d20:	95aa                	add	a1,a1,a0
    80001d22:	058e                	slli	a1,a1,0x3
    80001d24:	0000f517          	auipc	a0,0xf
    80001d28:	7fc50513          	addi	a0,a0,2044 # 80011520 <ready_lock>
    80001d2c:	952e                	add	a0,a0,a1
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	f78080e7          	jalr	-136(ra) # 80000ca6 <release>
    80001d36:	bff9                	j	80001d14 <release_list3+0x30>
      number == 2 ? release(&zombie_lock): 
    80001d38:	00010517          	auipc	a0,0x10
    80001d3c:	83050513          	addi	a0,a0,-2000 # 80011568 <zombie_lock>
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	f66080e7          	jalr	-154(ra) # 80000ca6 <release>
    80001d48:	b7f1                	j	80001d14 <release_list3+0x30>
        number == 3 ? release(&sleeping_lock): 
    80001d4a:	00010517          	auipc	a0,0x10
    80001d4e:	83650513          	addi	a0,a0,-1994 # 80011580 <sleeping_lock>
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	f54080e7          	jalr	-172(ra) # 80000ca6 <release>
    80001d5a:	bf6d                	j	80001d14 <release_list3+0x30>
            panic("wrong call in release_list3");
    80001d5c:	00006517          	auipc	a0,0x6
    80001d60:	52450513          	addi	a0,a0,1316 # 80008280 <digits+0x240>
    80001d64:	ffffe097          	auipc	ra,0xffffe
    80001d68:	7da080e7          	jalr	2010(ra) # 8000053e <panic>

0000000080001d6c <release_list>:

void
release_list(int type, int parent_cpu){
    80001d6c:	1141                	addi	sp,sp,-16
    80001d6e:	e406                	sd	ra,8(sp)
    80001d70:	e022                	sd	s0,0(sp)
    80001d72:	0800                	addi	s0,sp,16
  type==READYL ? release_list3(1,parent_cpu): 
    80001d74:	c515                	beqz	a0,80001da0 <release_list+0x34>
    type==ZOMBIEL ? release_list3(2,parent_cpu):
    80001d76:	4785                	li	a5,1
    80001d78:	04f50263          	beq	a0,a5,80001dbc <release_list+0x50>
      type==SLEEPINGL ? release_list3(3,parent_cpu):
    80001d7c:	4789                	li	a5,2
    80001d7e:	04f50863          	beq	a0,a5,80001dce <release_list+0x62>
        type==UNUSEDL ? release_list3(4,parent_cpu):
    80001d82:	478d                	li	a5,3
    80001d84:	04f51e63          	bne	a0,a5,80001de0 <release_list+0x74>
          number == 4 ? release(&unused_lock):  
    80001d88:	00010517          	auipc	a0,0x10
    80001d8c:	81050513          	addi	a0,a0,-2032 # 80011598 <unused_lock>
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	f16080e7          	jalr	-234(ra) # 80000ca6 <release>
          panic("wrong type list");
}
    80001d98:	60a2                	ld	ra,8(sp)
    80001d9a:	6402                	ld	s0,0(sp)
    80001d9c:	0141                	addi	sp,sp,16
    80001d9e:	8082                	ret
    number == 1 ?  release(&ready_lock[parent_cpu]): 
    80001da0:	00159513          	slli	a0,a1,0x1
    80001da4:	95aa                	add	a1,a1,a0
    80001da6:	058e                	slli	a1,a1,0x3
    80001da8:	0000f517          	auipc	a0,0xf
    80001dac:	77850513          	addi	a0,a0,1912 # 80011520 <ready_lock>
    80001db0:	952e                	add	a0,a0,a1
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	ef4080e7          	jalr	-268(ra) # 80000ca6 <release>
}
    80001dba:	bff9                	j	80001d98 <release_list+0x2c>
      number == 2 ? release(&zombie_lock): 
    80001dbc:	0000f517          	auipc	a0,0xf
    80001dc0:	7ac50513          	addi	a0,a0,1964 # 80011568 <zombie_lock>
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	ee2080e7          	jalr	-286(ra) # 80000ca6 <release>
}
    80001dcc:	b7f1                	j	80001d98 <release_list+0x2c>
        number == 3 ? release(&sleeping_lock): 
    80001dce:	0000f517          	auipc	a0,0xf
    80001dd2:	7b250513          	addi	a0,a0,1970 # 80011580 <sleeping_lock>
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	ed0080e7          	jalr	-304(ra) # 80000ca6 <release>
}
    80001dde:	bf6d                	j	80001d98 <release_list+0x2c>
          panic("wrong type list");
    80001de0:	00006517          	auipc	a0,0x6
    80001de4:	49050513          	addi	a0,a0,1168 # 80008270 <digits+0x230>
    80001de8:	ffffe097          	auipc	ra,0xffffe
    80001dec:	756080e7          	jalr	1878(ra) # 8000053e <panic>

0000000080001df0 <add_to_list>:



void
add_to_list(struct proc* p, struct proc* head, int type, int cpu_id)
{
    80001df0:	7139                	addi	sp,sp,-64
    80001df2:	fc06                	sd	ra,56(sp)
    80001df4:	f822                	sd	s0,48(sp)
    80001df6:	f426                	sd	s1,40(sp)
    80001df8:	f04a                	sd	s2,32(sp)
    80001dfa:	ec4e                	sd	s3,24(sp)
    80001dfc:	e852                	sd	s4,16(sp)
    80001dfe:	e456                	sd	s5,8(sp)
    80001e00:	e05a                	sd	s6,0(sp)
    80001e02:	0080                	addi	s0,sp,64
  if(!p){
    80001e04:	c505                	beqz	a0,80001e2c <add_to_list+0x3c>
    80001e06:	8b2a                	mv	s6,a0
    80001e08:	84ae                	mv	s1,a1
    80001e0a:	8a32                	mv	s4,a2
    80001e0c:	8ab6                	mv	s5,a3
  if(!head){
      set_head(p, type, cpu_id);
      release_list(type, cpu_id);
  }
  else{
    struct proc* prev = 0;
    80001e0e:	4901                	li	s2,0
  if(!head){
    80001e10:	e1a1                	bnez	a1,80001e50 <add_to_list+0x60>
      set_head(p, type, cpu_id);
    80001e12:	8636                	mv	a2,a3
    80001e14:	85d2                	mv	a1,s4
    80001e16:	00000097          	auipc	ra,0x0
    80001e1a:	e68080e7          	jalr	-408(ra) # 80001c7e <set_head>
      release_list(type, cpu_id);
    80001e1e:	85d6                	mv	a1,s5
    80001e20:	8552                	mv	a0,s4
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	f4a080e7          	jalr	-182(ra) # 80001d6c <release_list>
    80001e2a:	a891                	j	80001e7e <add_to_list+0x8e>
    panic("can't add null to list");
    80001e2c:	00006517          	auipc	a0,0x6
    80001e30:	42c50513          	addi	a0,a0,1068 # 80008258 <digits+0x218>
    80001e34:	ffffe097          	auipc	ra,0xffffe
    80001e38:	70a080e7          	jalr	1802(ra) # 8000053e <panic>

      if(prev){
        release(&prev->list_lock);
      }
      else{
        release_list(type, cpu_id);
    80001e3c:	85d6                	mv	a1,s5
    80001e3e:	8552                	mv	a0,s4
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	f2c080e7          	jalr	-212(ra) # 80001d6c <release_list>
      }
      prev = head;
      head = head->next;
    80001e48:	68bc                	ld	a5,80(s1)
    while(head){
    80001e4a:	8926                	mv	s2,s1
    80001e4c:	c395                	beqz	a5,80001e70 <add_to_list+0x80>
      head = head->next;
    80001e4e:	84be                	mv	s1,a5
      acquire(&head->list_lock);
    80001e50:	01848993          	addi	s3,s1,24
    80001e54:	854e                	mv	a0,s3
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	d96080e7          	jalr	-618(ra) # 80000bec <acquire>
      if(prev){
    80001e5e:	fc090fe3          	beqz	s2,80001e3c <add_to_list+0x4c>
        release(&prev->list_lock);
    80001e62:	01890513          	addi	a0,s2,24
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	e40080e7          	jalr	-448(ra) # 80000ca6 <release>
    80001e6e:	bfe9                	j	80001e48 <add_to_list+0x58>
    }
    prev->next = p;
    80001e70:	0564b823          	sd	s6,80(s1)
    release(&prev->list_lock);
    80001e74:	854e                	mv	a0,s3
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e30080e7          	jalr	-464(ra) # 80000ca6 <release>
  }
}
    80001e7e:	70e2                	ld	ra,56(sp)
    80001e80:	7442                	ld	s0,48(sp)
    80001e82:	74a2                	ld	s1,40(sp)
    80001e84:	7902                	ld	s2,32(sp)
    80001e86:	69e2                	ld	s3,24(sp)
    80001e88:	6a42                	ld	s4,16(sp)
    80001e8a:	6aa2                	ld	s5,8(sp)
    80001e8c:	6b02                	ld	s6,0(sp)
    80001e8e:	6121                	addi	sp,sp,64
    80001e90:	8082                	ret

0000000080001e92 <add_proc_to_list>:


void 
add_proc_to_list(struct proc* p, int type, int cpu_id)
{
    80001e92:	7179                	addi	sp,sp,-48
    80001e94:	f406                	sd	ra,40(sp)
    80001e96:	f022                	sd	s0,32(sp)
    80001e98:	ec26                	sd	s1,24(sp)
    80001e9a:	e84a                	sd	s2,16(sp)
    80001e9c:	e44e                	sd	s3,8(sp)
    80001e9e:	1800                	addi	s0,sp,48
  // bad argument
  if(!p){
    80001ea0:	cd1d                	beqz	a0,80001ede <add_proc_to_list+0x4c>
    80001ea2:	89aa                	mv	s3,a0
    80001ea4:	84ae                	mv	s1,a1
    80001ea6:	8932                	mv	s2,a2
    panic("Add proc to list");
  }
  struct proc* head;
  acquire_list(type, cpu_id);
    80001ea8:	85b2                	mv	a1,a2
    80001eaa:	8526                	mv	a0,s1
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	ce4080e7          	jalr	-796(ra) # 80001b90 <acquire_list>
  head = get_head(type, cpu_id);
    80001eb4:	85ca                	mv	a1,s2
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	00000097          	auipc	ra,0x0
    80001ebc:	d60080e7          	jalr	-672(ra) # 80001c18 <get_head>
    80001ec0:	85aa                	mv	a1,a0
  add_to_list(p, head, type, cpu_id);
    80001ec2:	86ca                	mv	a3,s2
    80001ec4:	8626                	mv	a2,s1
    80001ec6:	854e                	mv	a0,s3
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	f28080e7          	jalr	-216(ra) # 80001df0 <add_to_list>
}
    80001ed0:	70a2                	ld	ra,40(sp)
    80001ed2:	7402                	ld	s0,32(sp)
    80001ed4:	64e2                	ld	s1,24(sp)
    80001ed6:	6942                	ld	s2,16(sp)
    80001ed8:	69a2                	ld	s3,8(sp)
    80001eda:	6145                	addi	sp,sp,48
    80001edc:	8082                	ret
    panic("Add proc to list");
    80001ede:	00006517          	auipc	a0,0x6
    80001ee2:	3c250513          	addi	a0,a0,962 # 800082a0 <digits+0x260>
    80001ee6:	ffffe097          	auipc	ra,0xffffe
    80001eea:	658080e7          	jalr	1624(ra) # 8000053e <panic>

0000000080001eee <remove_first>:



struct proc* 
remove_first(int type, int cpu_id)
{
    80001eee:	7179                	addi	sp,sp,-48
    80001ef0:	f406                	sd	ra,40(sp)
    80001ef2:	f022                	sd	s0,32(sp)
    80001ef4:	ec26                	sd	s1,24(sp)
    80001ef6:	e84a                	sd	s2,16(sp)
    80001ef8:	e44e                	sd	s3,8(sp)
    80001efa:	e052                	sd	s4,0(sp)
    80001efc:	1800                	addi	s0,sp,48
    80001efe:	892a                	mv	s2,a0
    80001f00:	89ae                	mv	s3,a1
  acquire_list(type, cpu_id);//acquire lock
    80001f02:	00000097          	auipc	ra,0x0
    80001f06:	c8e080e7          	jalr	-882(ra) # 80001b90 <acquire_list>
  struct proc* head = get_head(type, cpu_id);//aquire list after we have loock 
    80001f0a:	85ce                	mv	a1,s3
    80001f0c:	854a                	mv	a0,s2
    80001f0e:	00000097          	auipc	ra,0x0
    80001f12:	d0a080e7          	jalr	-758(ra) # 80001c18 <get_head>
    80001f16:	84aa                	mv	s1,a0
  if(!head){
    80001f18:	c529                	beqz	a0,80001f62 <remove_first+0x74>
    release_list(type, cpu_id);//realese loock 
  }
  else{
    acquire(&head->list_lock);
    80001f1a:	01850a13          	addi	s4,a0,24
    80001f1e:	8552                	mv	a0,s4
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	ccc080e7          	jalr	-820(ra) # 80000bec <acquire>

    set_head(head->next, type, cpu_id);
    80001f28:	864e                	mv	a2,s3
    80001f2a:	85ca                	mv	a1,s2
    80001f2c:	68a8                	ld	a0,80(s1)
    80001f2e:	00000097          	auipc	ra,0x0
    80001f32:	d50080e7          	jalr	-688(ra) # 80001c7e <set_head>
    head->next = 0;
    80001f36:	0404b823          	sd	zero,80(s1)
    release(&head->list_lock);
    80001f3a:	8552                	mv	a0,s4
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	d6a080e7          	jalr	-662(ra) # 80000ca6 <release>

    release_list(type, cpu_id);//realese loock 
    80001f44:	85ce                	mv	a1,s3
    80001f46:	854a                	mv	a0,s2
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	e24080e7          	jalr	-476(ra) # 80001d6c <release_list>

  }
  return head;
}
    80001f50:	8526                	mv	a0,s1
    80001f52:	70a2                	ld	ra,40(sp)
    80001f54:	7402                	ld	s0,32(sp)
    80001f56:	64e2                	ld	s1,24(sp)
    80001f58:	6942                	ld	s2,16(sp)
    80001f5a:	69a2                	ld	s3,8(sp)
    80001f5c:	6a02                	ld	s4,0(sp)
    80001f5e:	6145                	addi	sp,sp,48
    80001f60:	8082                	ret
    release_list(type, cpu_id);//realese loock 
    80001f62:	85ce                	mv	a1,s3
    80001f64:	854a                	mv	a0,s2
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	e06080e7          	jalr	-506(ra) # 80001d6c <release_list>
    80001f6e:	b7cd                	j	80001f50 <remove_first+0x62>

0000000080001f70 <remove_proc>:

int
remove_proc(struct proc* p, int type){
    80001f70:	7179                	addi	sp,sp,-48
    80001f72:	f406                	sd	ra,40(sp)
    80001f74:	f022                	sd	s0,32(sp)
    80001f76:	ec26                	sd	s1,24(sp)
    80001f78:	e84a                	sd	s2,16(sp)
    80001f7a:	e44e                	sd	s3,8(sp)
    80001f7c:	e052                	sd	s4,0(sp)
    80001f7e:	1800                	addi	s0,sp,48
    80001f80:	8a2a                	mv	s4,a0
    80001f82:	84ae                	mv	s1,a1
  acquire_list(type, p->parent_cpu);
    80001f84:	4d2c                	lw	a1,88(a0)
    80001f86:	8526                	mv	a0,s1
    80001f88:	00000097          	auipc	ra,0x0
    80001f8c:	c08080e7          	jalr	-1016(ra) # 80001b90 <acquire_list>
  struct proc* head = get_head(type, p->parent_cpu);
    80001f90:	058a2983          	lw	s3,88(s4) # fffffffffffff058 <end+0xffffffff7ffd9058>
    80001f94:	85ce                	mv	a1,s3
    80001f96:	8526                	mv	a0,s1
    80001f98:	00000097          	auipc	ra,0x0
    80001f9c:	c80080e7          	jalr	-896(ra) # 80001c18 <get_head>
  if(!head){
    80001fa0:	c521                	beqz	a0,80001fe8 <remove_proc+0x78>
    80001fa2:	892a                	mv	s2,a0
    release_list(type, p->parent_cpu);
    return 0;
  }
  else{
    struct proc* prev = 0;
    if(p == head){
    80001fa4:	04aa0a63          	beq	s4,a0,80001ff8 <remove_proc+0x88>
      release(&p->list_lock);
      release_list(type, p->parent_cpu);
    }
    else{
      while(head){
        acquire(&head->list_lock);
    80001fa8:	0561                	addi	a0,a0,24
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	c42080e7          	jalr	-958(ra) # 80000bec <acquire>
          release(&prev->list_lock);
          return 1;
        }

        if(!prev)
          release_list(type,p->parent_cpu);
    80001fb2:	058a2583          	lw	a1,88(s4)
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	db4080e7          	jalr	-588(ra) # 80001d6c <release_list>
          release(&prev->list_lock);
        }
          
        
        prev = head;
        head = head->next;
    80001fc0:	05093483          	ld	s1,80(s2)
      while(head){
    80001fc4:	c0dd                	beqz	s1,8000206a <remove_proc+0xfa>
        acquire(&head->list_lock);
    80001fc6:	01848993          	addi	s3,s1,24
    80001fca:	854e                	mv	a0,s3
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	c20080e7          	jalr	-992(ra) # 80000bec <acquire>
        if(p == head){
    80001fd4:	069a0263          	beq	s4,s1,80002038 <remove_proc+0xc8>
          release(&prev->list_lock);
    80001fd8:	01890513          	addi	a0,s2,24
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	cca080e7          	jalr	-822(ra) # 80000ca6 <release>
        head = head->next;
    80001fe4:	8926                	mv	s2,s1
    80001fe6:	bfe9                	j	80001fc0 <remove_proc+0x50>
    release_list(type, p->parent_cpu);
    80001fe8:	85ce                	mv	a1,s3
    80001fea:	8526                	mv	a0,s1
    80001fec:	00000097          	auipc	ra,0x0
    80001ff0:	d80080e7          	jalr	-640(ra) # 80001d6c <release_list>
    return 0;
    80001ff4:	4501                	li	a0,0
    80001ff6:	a095                	j	8000205a <remove_proc+0xea>
      acquire(&p->list_lock);
    80001ff8:	01850993          	addi	s3,a0,24
    80001ffc:	854e                	mv	a0,s3
    80001ffe:	fffff097          	auipc	ra,0xfffff
    80002002:	bee080e7          	jalr	-1042(ra) # 80000bec <acquire>
      set_head(p->next, type, p->parent_cpu);
    80002006:	05892603          	lw	a2,88(s2)
    8000200a:	85a6                	mv	a1,s1
    8000200c:	05093503          	ld	a0,80(s2)
    80002010:	00000097          	auipc	ra,0x0
    80002014:	c6e080e7          	jalr	-914(ra) # 80001c7e <set_head>
      p->next = 0;
    80002018:	04093823          	sd	zero,80(s2)
      release(&p->list_lock);
    8000201c:	854e                	mv	a0,s3
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	c88080e7          	jalr	-888(ra) # 80000ca6 <release>
      release_list(type, p->parent_cpu);
    80002026:	05892583          	lw	a1,88(s2)
    8000202a:	8526                	mv	a0,s1
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	d40080e7          	jalr	-704(ra) # 80001d6c <release_list>
      }
    }
    return 0;
    80002034:	4501                	li	a0,0
    80002036:	a015                	j	8000205a <remove_proc+0xea>
          prev->next = head->next;
    80002038:	68bc                	ld	a5,80(s1)
    8000203a:	04f93823          	sd	a5,80(s2)
          p->next = 0;
    8000203e:	0404b823          	sd	zero,80(s1)
          release(&head->list_lock);
    80002042:	854e                	mv	a0,s3
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	c62080e7          	jalr	-926(ra) # 80000ca6 <release>
          release(&prev->list_lock);
    8000204c:	01890513          	addi	a0,s2,24
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	c56080e7          	jalr	-938(ra) # 80000ca6 <release>
          return 1;
    80002058:	4505                	li	a0,1
  }
}
    8000205a:	70a2                	ld	ra,40(sp)
    8000205c:	7402                	ld	s0,32(sp)
    8000205e:	64e2                	ld	s1,24(sp)
    80002060:	6942                	ld	s2,16(sp)
    80002062:	69a2                	ld	s3,8(sp)
    80002064:	6a02                	ld	s4,0(sp)
    80002066:	6145                	addi	sp,sp,48
    80002068:	8082                	ret
    return 0;
    8000206a:	4501                	li	a0,0
    8000206c:	b7fd                	j	8000205a <remove_proc+0xea>

000000008000206e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000206e:	7139                	addi	sp,sp,-64
    80002070:	fc06                	sd	ra,56(sp)
    80002072:	f822                	sd	s0,48(sp)
    80002074:	f426                	sd	s1,40(sp)
    80002076:	f04a                	sd	s2,32(sp)
    80002078:	ec4e                	sd	s3,24(sp)
    8000207a:	e852                	sd	s4,16(sp)
    8000207c:	e456                	sd	s5,8(sp)
    8000207e:	e05a                	sd	s6,0(sp)
    80002080:	0080                	addi	s0,sp,64
    80002082:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80002084:	0000f497          	auipc	s1,0xf
    80002088:	55c48493          	addi	s1,s1,1372 # 800115e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000208c:	8b26                	mv	s6,s1
    8000208e:	00006a97          	auipc	s5,0x6
    80002092:	f72a8a93          	addi	s5,s5,-142 # 80008000 <etext>
    80002096:	04000937          	lui	s2,0x4000
    8000209a:	197d                	addi	s2,s2,-1
    8000209c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000209e:	00016a17          	auipc	s4,0x16
    800020a2:	942a0a13          	addi	s4,s4,-1726 # 800179e0 <tickslock>
    char *pa = kalloc();
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	a4e080e7          	jalr	-1458(ra) # 80000af4 <kalloc>
    800020ae:	862a                	mv	a2,a0
    if(pa == 0)
    800020b0:	c131                	beqz	a0,800020f4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800020b2:	416485b3          	sub	a1,s1,s6
    800020b6:	8591                	srai	a1,a1,0x4
    800020b8:	000ab783          	ld	a5,0(s5)
    800020bc:	02f585b3          	mul	a1,a1,a5
    800020c0:	2585                	addiw	a1,a1,1
    800020c2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800020c6:	4719                	li	a4,6
    800020c8:	6685                	lui	a3,0x1
    800020ca:	40b905b3          	sub	a1,s2,a1
    800020ce:	854e                	mv	a0,s3
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	08e080e7          	jalr	142(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	19048493          	addi	s1,s1,400
    800020dc:	fd4495e3          	bne	s1,s4,800020a6 <proc_mapstacks+0x38>
  }
}
    800020e0:	70e2                	ld	ra,56(sp)
    800020e2:	7442                	ld	s0,48(sp)
    800020e4:	74a2                	ld	s1,40(sp)
    800020e6:	7902                	ld	s2,32(sp)
    800020e8:	69e2                	ld	s3,24(sp)
    800020ea:	6a42                	ld	s4,16(sp)
    800020ec:	6aa2                	ld	s5,8(sp)
    800020ee:	6b02                	ld	s6,0(sp)
    800020f0:	6121                	addi	sp,sp,64
    800020f2:	8082                	ret
      panic("kalloc");
    800020f4:	00006517          	auipc	a0,0x6
    800020f8:	1c450513          	addi	a0,a0,452 # 800082b8 <digits+0x278>
    800020fc:	ffffe097          	auipc	ra,0xffffe
    80002100:	442080e7          	jalr	1090(ra) # 8000053e <panic>

0000000080002104 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80002104:	715d                	addi	sp,sp,-80
    80002106:	e486                	sd	ra,72(sp)
    80002108:	e0a2                	sd	s0,64(sp)
    8000210a:	fc26                	sd	s1,56(sp)
    8000210c:	f84a                	sd	s2,48(sp)
    8000210e:	f44e                	sd	s3,40(sp)
    80002110:	f052                	sd	s4,32(sp)
    80002112:	ec56                	sd	s5,24(sp)
    80002114:	e85a                	sd	s6,16(sp)
    80002116:	e45e                	sd	s7,8(sp)
    80002118:	e062                	sd	s8,0(sp)
    8000211a:	0880                	addi	s0,sp,80
  struct proc *p;
  //----------------------------------------------------------
  if(CPUS > NCPU){
    panic("recieved more CPUS than what is allowed");
  }
  initlock(&pid_lock, "nextpid");
    8000211c:	00006597          	auipc	a1,0x6
    80002120:	1a458593          	addi	a1,a1,420 # 800082c0 <digits+0x280>
    80002124:	0000f517          	auipc	a0,0xf
    80002128:	48c50513          	addi	a0,a0,1164 # 800115b0 <pid_lock>
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	a28080e7          	jalr	-1496(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80002134:	00006597          	auipc	a1,0x6
    80002138:	19458593          	addi	a1,a1,404 # 800082c8 <digits+0x288>
    8000213c:	0000f517          	auipc	a0,0xf
    80002140:	48c50513          	addi	a0,a0,1164 # 800115c8 <wait_lock>
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	a10080e7          	jalr	-1520(ra) # 80000b54 <initlock>
  initlock(&zombie_lock, "zombie lock");
    8000214c:	00006597          	auipc	a1,0x6
    80002150:	18c58593          	addi	a1,a1,396 # 800082d8 <digits+0x298>
    80002154:	0000f517          	auipc	a0,0xf
    80002158:	41450513          	addi	a0,a0,1044 # 80011568 <zombie_lock>
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	9f8080e7          	jalr	-1544(ra) # 80000b54 <initlock>
  initlock(&sleeping_lock, "sleeping lock");
    80002164:	00006597          	auipc	a1,0x6
    80002168:	18458593          	addi	a1,a1,388 # 800082e8 <digits+0x2a8>
    8000216c:	0000f517          	auipc	a0,0xf
    80002170:	41450513          	addi	a0,a0,1044 # 80011580 <sleeping_lock>
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	9e0080e7          	jalr	-1568(ra) # 80000b54 <initlock>
  initlock(&unused_lock, "unused lock");
    8000217c:	00006597          	auipc	a1,0x6
    80002180:	17c58593          	addi	a1,a1,380 # 800082f8 <digits+0x2b8>
    80002184:	0000f517          	auipc	a0,0xf
    80002188:	41450513          	addi	a0,a0,1044 # 80011598 <unused_lock>
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	9c8080e7          	jalr	-1592(ra) # 80000b54 <initlock>

  struct spinlock* s;
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    80002194:	0000f497          	auipc	s1,0xf
    80002198:	38c48493          	addi	s1,s1,908 # 80011520 <ready_lock>
    initlock(s, "ready lock");
    8000219c:	00006997          	auipc	s3,0x6
    800021a0:	16c98993          	addi	s3,s3,364 # 80008308 <digits+0x2c8>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    800021a4:	0000f917          	auipc	s2,0xf
    800021a8:	3c490913          	addi	s2,s2,964 # 80011568 <zombie_lock>
    initlock(s, "ready lock");
    800021ac:	85ce                	mv	a1,s3
    800021ae:	8526                	mv	a0,s1
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	9a4080e7          	jalr	-1628(ra) # 80000b54 <initlock>
  for(s = ready_lock; s <&ready_lock[CPUS]; s++){
    800021b8:	04e1                	addi	s1,s1,24
    800021ba:	ff2499e3          	bne	s1,s2,800021ac <procinit+0xa8>
  }
  //--------------------------------------------------
  for(p = proc; p < &proc[NPROC]; p++) {
    800021be:	0000f497          	auipc	s1,0xf
    800021c2:	42248493          	addi	s1,s1,1058 # 800115e0 <proc>
      initlock(&p->lock, "proc");
    800021c6:	00006c17          	auipc	s8,0x6
    800021ca:	152c0c13          	addi	s8,s8,338 # 80008318 <digits+0x2d8>
      //--------------------------------------------------
      initlock(&p->list_lock, "list lock");
    800021ce:	00006b97          	auipc	s7,0x6
    800021d2:	152b8b93          	addi	s7,s7,338 # 80008320 <digits+0x2e0>
      //--------------------------------------------------
      p->kstack = KSTACK((int) (p - proc));
    800021d6:	8b26                	mv	s6,s1
    800021d8:	00006a97          	auipc	s5,0x6
    800021dc:	e28a8a93          	addi	s5,s5,-472 # 80008000 <etext>
    800021e0:	04000937          	lui	s2,0x4000
    800021e4:	197d                	addi	s2,s2,-1
    800021e6:	0932                	slli	s2,s2,0xc
      //--------------------------------------------------
       p->parent_cpu = -1;
    800021e8:	5a7d                	li	s4,-1
  for(p = proc; p < &proc[NPROC]; p++) {
    800021ea:	00015997          	auipc	s3,0x15
    800021ee:	7f698993          	addi	s3,s3,2038 # 800179e0 <tickslock>
      initlock(&p->lock, "proc");
    800021f2:	85e2                	mv	a1,s8
    800021f4:	8526                	mv	a0,s1
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	95e080e7          	jalr	-1698(ra) # 80000b54 <initlock>
      initlock(&p->list_lock, "list lock");
    800021fe:	85de                	mv	a1,s7
    80002200:	01848513          	addi	a0,s1,24
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	950080e7          	jalr	-1712(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000220c:	416487b3          	sub	a5,s1,s6
    80002210:	8791                	srai	a5,a5,0x4
    80002212:	000ab703          	ld	a4,0(s5)
    80002216:	02e787b3          	mul	a5,a5,a4
    8000221a:	2785                	addiw	a5,a5,1
    8000221c:	00d7979b          	slliw	a5,a5,0xd
    80002220:	40f907b3          	sub	a5,s2,a5
    80002224:	f4bc                	sd	a5,104(s1)
       p->parent_cpu = -1;
    80002226:	0544ac23          	sw	s4,88(s1)
       add_proc_to_list(p, UNUSEDL, -1);
    8000222a:	567d                	li	a2,-1
    8000222c:	458d                	li	a1,3
    8000222e:	8526                	mv	a0,s1
    80002230:	00000097          	auipc	ra,0x0
    80002234:	c62080e7          	jalr	-926(ra) # 80001e92 <add_proc_to_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002238:	19048493          	addi	s1,s1,400
    8000223c:	fb349be3          	bne	s1,s3,800021f2 <procinit+0xee>
      
      //--------------------------------------------------
  }
}
    80002240:	60a6                	ld	ra,72(sp)
    80002242:	6406                	ld	s0,64(sp)
    80002244:	74e2                	ld	s1,56(sp)
    80002246:	7942                	ld	s2,48(sp)
    80002248:	79a2                	ld	s3,40(sp)
    8000224a:	7a02                	ld	s4,32(sp)
    8000224c:	6ae2                	ld	s5,24(sp)
    8000224e:	6b42                	ld	s6,16(sp)
    80002250:	6ba2                	ld	s7,8(sp)
    80002252:	6c02                	ld	s8,0(sp)
    80002254:	6161                	addi	sp,sp,80
    80002256:	8082                	ret

0000000080002258 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80002258:	1141                	addi	sp,sp,-16
    8000225a:	e422                	sd	s0,8(sp)
    8000225c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000225e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80002260:	2501                	sext.w	a0,a0
    80002262:	6422                	ld	s0,8(sp)
    80002264:	0141                	addi	sp,sp,16
    80002266:	8082                	ret

0000000080002268 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80002268:	1141                	addi	sp,sp,-16
    8000226a:	e422                	sd	s0,8(sp)
    8000226c:	0800                	addi	s0,sp,16
    8000226e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80002270:	0007851b          	sext.w	a0,a5
    80002274:	00351793          	slli	a5,a0,0x3
    80002278:	97aa                	add	a5,a5,a0
    8000227a:	0792                	slli	a5,a5,0x4
  return c;
}
    8000227c:	0000f517          	auipc	a0,0xf
    80002280:	0f450513          	addi	a0,a0,244 # 80011370 <cpus>
    80002284:	953e                	add	a0,a0,a5
    80002286:	6422                	ld	s0,8(sp)
    80002288:	0141                	addi	sp,sp,16
    8000228a:	8082                	ret

000000008000228c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    8000228c:	1101                	addi	sp,sp,-32
    8000228e:	ec06                	sd	ra,24(sp)
    80002290:	e822                	sd	s0,16(sp)
    80002292:	e426                	sd	s1,8(sp)
    80002294:	1000                	addi	s0,sp,32
  push_off();
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	902080e7          	jalr	-1790(ra) # 80000b98 <push_off>
    8000229e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800022a0:	0007871b          	sext.w	a4,a5
    800022a4:	00371793          	slli	a5,a4,0x3
    800022a8:	97ba                	add	a5,a5,a4
    800022aa:	0792                	slli	a5,a5,0x4
    800022ac:	0000f717          	auipc	a4,0xf
    800022b0:	03470713          	addi	a4,a4,52 # 800112e0 <readyLock>
    800022b4:	97ba                	add	a5,a5,a4
    800022b6:	6fc4                	ld	s1,152(a5)
  pop_off();
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	988080e7          	jalr	-1656(ra) # 80000c40 <pop_off>
  return p;
}
    800022c0:	8526                	mv	a0,s1
    800022c2:	60e2                	ld	ra,24(sp)
    800022c4:	6442                	ld	s0,16(sp)
    800022c6:	64a2                	ld	s1,8(sp)
    800022c8:	6105                	addi	sp,sp,32
    800022ca:	8082                	ret

00000000800022cc <get_cpu>:
{
    800022cc:	1141                	addi	sp,sp,-16
    800022ce:	e406                	sd	ra,8(sp)
    800022d0:	e022                	sd	s0,0(sp)
    800022d2:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	fb8080e7          	jalr	-72(ra) # 8000228c <myproc>
}
    800022dc:	4d28                	lw	a0,88(a0)
    800022de:	60a2                	ld	ra,8(sp)
    800022e0:	6402                	ld	s0,0(sp)
    800022e2:	0141                	addi	sp,sp,16
    800022e4:	8082                	ret

00000000800022e6 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800022e6:	1141                	addi	sp,sp,-16
    800022e8:	e406                	sd	ra,8(sp)
    800022ea:	e022                	sd	s0,0(sp)
    800022ec:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800022ee:	00000097          	auipc	ra,0x0
    800022f2:	f9e080e7          	jalr	-98(ra) # 8000228c <myproc>
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	9b0080e7          	jalr	-1616(ra) # 80000ca6 <release>

  if (first) {
    800022fe:	00006797          	auipc	a5,0x6
    80002302:	6827a783          	lw	a5,1666(a5) # 80008980 <first.1866>
    80002306:	eb89                	bnez	a5,80002318 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80002308:	00001097          	auipc	ra,0x1
    8000230c:	f6a080e7          	jalr	-150(ra) # 80003272 <usertrapret>
}
    80002310:	60a2                	ld	ra,8(sp)
    80002312:	6402                	ld	s0,0(sp)
    80002314:	0141                	addi	sp,sp,16
    80002316:	8082                	ret
    first = 0;
    80002318:	00006797          	auipc	a5,0x6
    8000231c:	6607a423          	sw	zero,1640(a5) # 80008980 <first.1866>
    fsinit(ROOTDEV);
    80002320:	4505                	li	a0,1
    80002322:	00002097          	auipc	ra,0x2
    80002326:	cdc080e7          	jalr	-804(ra) # 80003ffe <fsinit>
    8000232a:	bff9                	j	80002308 <forkret+0x22>

000000008000232c <allocpid>:
allocpid() {
    8000232c:	1101                	addi	sp,sp,-32
    8000232e:	ec06                	sd	ra,24(sp)
    80002330:	e822                	sd	s0,16(sp)
    80002332:	e426                	sd	s1,8(sp)
    80002334:	e04a                	sd	s2,0(sp)
    80002336:	1000                	addi	s0,sp,32
    pid = nextpid;
    80002338:	00006917          	auipc	s2,0x6
    8000233c:	64c90913          	addi	s2,s2,1612 # 80008984 <nextpid>
    80002340:	00092483          	lw	s1,0(s2)
  while(cas(&nextpid, pid, pid + 1));
    80002344:	0014861b          	addiw	a2,s1,1
    80002348:	85a6                	mv	a1,s1
    8000234a:	854a                	mv	a0,s2
    8000234c:	00005097          	auipc	ra,0x5
    80002350:	aba080e7          	jalr	-1350(ra) # 80006e06 <cas>
    80002354:	f575                	bnez	a0,80002340 <allocpid+0x14>
}
    80002356:	8526                	mv	a0,s1
    80002358:	60e2                	ld	ra,24(sp)
    8000235a:	6442                	ld	s0,16(sp)
    8000235c:	64a2                	ld	s1,8(sp)
    8000235e:	6902                	ld	s2,0(sp)
    80002360:	6105                	addi	sp,sp,32
    80002362:	8082                	ret

0000000080002364 <proc_pagetable>:
{
    80002364:	1101                	addi	sp,sp,-32
    80002366:	ec06                	sd	ra,24(sp)
    80002368:	e822                	sd	s0,16(sp)
    8000236a:	e426                	sd	s1,8(sp)
    8000236c:	e04a                	sd	s2,0(sp)
    8000236e:	1000                	addi	s0,sp,32
    80002370:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	fd6080e7          	jalr	-42(ra) # 80001348 <uvmcreate>
    8000237a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000237c:	c121                	beqz	a0,800023bc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    8000237e:	4729                	li	a4,10
    80002380:	00005697          	auipc	a3,0x5
    80002384:	c8068693          	addi	a3,a3,-896 # 80007000 <_trampoline>
    80002388:	6605                	lui	a2,0x1
    8000238a:	040005b7          	lui	a1,0x4000
    8000238e:	15fd                	addi	a1,a1,-1
    80002390:	05b2                	slli	a1,a1,0xc
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	d2c080e7          	jalr	-724(ra) # 800010be <mappages>
    8000239a:	02054863          	bltz	a0,800023ca <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    8000239e:	4719                	li	a4,6
    800023a0:	08093683          	ld	a3,128(s2)
    800023a4:	6605                	lui	a2,0x1
    800023a6:	020005b7          	lui	a1,0x2000
    800023aa:	15fd                	addi	a1,a1,-1
    800023ac:	05b6                	slli	a1,a1,0xd
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	d0e080e7          	jalr	-754(ra) # 800010be <mappages>
    800023b8:	02054163          	bltz	a0,800023da <proc_pagetable+0x76>
}
    800023bc:	8526                	mv	a0,s1
    800023be:	60e2                	ld	ra,24(sp)
    800023c0:	6442                	ld	s0,16(sp)
    800023c2:	64a2                	ld	s1,8(sp)
    800023c4:	6902                	ld	s2,0(sp)
    800023c6:	6105                	addi	sp,sp,32
    800023c8:	8082                	ret
    uvmfree(pagetable, 0);
    800023ca:	4581                	li	a1,0
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	176080e7          	jalr	374(ra) # 80001544 <uvmfree>
    return 0;
    800023d6:	4481                	li	s1,0
    800023d8:	b7d5                	j	800023bc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800023da:	4681                	li	a3,0
    800023dc:	4605                	li	a2,1
    800023de:	040005b7          	lui	a1,0x4000
    800023e2:	15fd                	addi	a1,a1,-1
    800023e4:	05b2                	slli	a1,a1,0xc
    800023e6:	8526                	mv	a0,s1
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	e9c080e7          	jalr	-356(ra) # 80001284 <uvmunmap>
    uvmfree(pagetable, 0);
    800023f0:	4581                	li	a1,0
    800023f2:	8526                	mv	a0,s1
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	150080e7          	jalr	336(ra) # 80001544 <uvmfree>
    return 0;
    800023fc:	4481                	li	s1,0
    800023fe:	bf7d                	j	800023bc <proc_pagetable+0x58>

0000000080002400 <proc_freepagetable>:
{
    80002400:	1101                	addi	sp,sp,-32
    80002402:	ec06                	sd	ra,24(sp)
    80002404:	e822                	sd	s0,16(sp)
    80002406:	e426                	sd	s1,8(sp)
    80002408:	e04a                	sd	s2,0(sp)
    8000240a:	1000                	addi	s0,sp,32
    8000240c:	84aa                	mv	s1,a0
    8000240e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002410:	4681                	li	a3,0
    80002412:	4605                	li	a2,1
    80002414:	040005b7          	lui	a1,0x4000
    80002418:	15fd                	addi	a1,a1,-1
    8000241a:	05b2                	slli	a1,a1,0xc
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	e68080e7          	jalr	-408(ra) # 80001284 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002424:	4681                	li	a3,0
    80002426:	4605                	li	a2,1
    80002428:	020005b7          	lui	a1,0x2000
    8000242c:	15fd                	addi	a1,a1,-1
    8000242e:	05b6                	slli	a1,a1,0xd
    80002430:	8526                	mv	a0,s1
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	e52080e7          	jalr	-430(ra) # 80001284 <uvmunmap>
  uvmfree(pagetable, sz);
    8000243a:	85ca                	mv	a1,s2
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	106080e7          	jalr	262(ra) # 80001544 <uvmfree>
}
    80002446:	60e2                	ld	ra,24(sp)
    80002448:	6442                	ld	s0,16(sp)
    8000244a:	64a2                	ld	s1,8(sp)
    8000244c:	6902                	ld	s2,0(sp)
    8000244e:	6105                	addi	sp,sp,32
    80002450:	8082                	ret

0000000080002452 <freeproc>:
{
    80002452:	1101                	addi	sp,sp,-32
    80002454:	ec06                	sd	ra,24(sp)
    80002456:	e822                	sd	s0,16(sp)
    80002458:	e426                	sd	s1,8(sp)
    8000245a:	1000                	addi	s0,sp,32
    8000245c:	84aa                	mv	s1,a0
  if(p->trapframe)
    8000245e:	6148                	ld	a0,128(a0)
    80002460:	c509                	beqz	a0,8000246a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002462:	ffffe097          	auipc	ra,0xffffe
    80002466:	596080e7          	jalr	1430(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    8000246a:	0804b023          	sd	zero,128(s1)
  if(p->pagetable)
    8000246e:	7ca8                	ld	a0,120(s1)
    80002470:	c511                	beqz	a0,8000247c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002472:	78ac                	ld	a1,112(s1)
    80002474:	00000097          	auipc	ra,0x0
    80002478:	f8c080e7          	jalr	-116(ra) # 80002400 <proc_freepagetable>
  p->pagetable = 0;
    8000247c:	0604bc23          	sd	zero,120(s1)
  p->sz = 0;
    80002480:	0604b823          	sd	zero,112(s1)
  p->pid = 0;
    80002484:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    80002488:	0604b023          	sd	zero,96(s1)
  p->name[0] = 0;
    8000248c:	18048023          	sb	zero,384(s1)
  p->chan = 0;
    80002490:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    80002494:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80002498:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    8000249c:	0204a823          	sw	zero,48(s1)
  remove_proc(p, ZOMBIEL);
    800024a0:	4585                	li	a1,1
    800024a2:	8526                	mv	a0,s1
    800024a4:	00000097          	auipc	ra,0x0
    800024a8:	acc080e7          	jalr	-1332(ra) # 80001f70 <remove_proc>
  add_proc_to_list(p, UNUSEDL, -1);
    800024ac:	567d                	li	a2,-1
    800024ae:	458d                	li	a1,3
    800024b0:	8526                	mv	a0,s1
    800024b2:	00000097          	auipc	ra,0x0
    800024b6:	9e0080e7          	jalr	-1568(ra) # 80001e92 <add_proc_to_list>
}
    800024ba:	60e2                	ld	ra,24(sp)
    800024bc:	6442                	ld	s0,16(sp)
    800024be:	64a2                	ld	s1,8(sp)
    800024c0:	6105                	addi	sp,sp,32
    800024c2:	8082                	ret

00000000800024c4 <allocproc>:
{
    800024c4:	7179                	addi	sp,sp,-48
    800024c6:	f406                	sd	ra,40(sp)
    800024c8:	f022                	sd	s0,32(sp)
    800024ca:	ec26                	sd	s1,24(sp)
    800024cc:	e84a                	sd	s2,16(sp)
    800024ce:	e44e                	sd	s3,8(sp)
    800024d0:	1800                	addi	s0,sp,48
  p = remove_first(UNUSEDL, -1);
    800024d2:	55fd                	li	a1,-1
    800024d4:	450d                	li	a0,3
    800024d6:	00000097          	auipc	ra,0x0
    800024da:	a18080e7          	jalr	-1512(ra) # 80001eee <remove_first>
    800024de:	84aa                	mv	s1,a0
  if(!p){
    800024e0:	cd39                	beqz	a0,8000253e <allocproc+0x7a>
  acquire(&p->lock);
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	70a080e7          	jalr	1802(ra) # 80000bec <acquire>
  p->pid = allocpid();
    800024ea:	00000097          	auipc	ra,0x0
    800024ee:	e42080e7          	jalr	-446(ra) # 8000232c <allocpid>
    800024f2:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    800024f4:	4785                	li	a5,1
    800024f6:	d89c                	sw	a5,48(s1)
  p->next = 0;
    800024f8:	0404b823          	sd	zero,80(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	5f8080e7          	jalr	1528(ra) # 80000af4 <kalloc>
    80002504:	892a                	mv	s2,a0
    80002506:	e0c8                	sd	a0,128(s1)
    80002508:	c139                	beqz	a0,8000254e <allocproc+0x8a>
  p->pagetable = proc_pagetable(p);
    8000250a:	8526                	mv	a0,s1
    8000250c:	00000097          	auipc	ra,0x0
    80002510:	e58080e7          	jalr	-424(ra) # 80002364 <proc_pagetable>
    80002514:	892a                	mv	s2,a0
    80002516:	fca8                	sd	a0,120(s1)
  if(p->pagetable == 0){
    80002518:	c539                	beqz	a0,80002566 <allocproc+0xa2>
  memset(&p->context, 0, sizeof(p->context));
    8000251a:	07000613          	li	a2,112
    8000251e:	4581                	li	a1,0
    80002520:	08848513          	addi	a0,s1,136
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	7ca080e7          	jalr	1994(ra) # 80000cee <memset>
  p->context.ra = (uint64)forkret;
    8000252c:	00000797          	auipc	a5,0x0
    80002530:	dba78793          	addi	a5,a5,-582 # 800022e6 <forkret>
    80002534:	e4dc                	sd	a5,136(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002536:	74bc                	ld	a5,104(s1)
    80002538:	6705                	lui	a4,0x1
    8000253a:	97ba                	add	a5,a5,a4
    8000253c:	e8dc                	sd	a5,144(s1)
}
    8000253e:	8526                	mv	a0,s1
    80002540:	70a2                	ld	ra,40(sp)
    80002542:	7402                	ld	s0,32(sp)
    80002544:	64e2                	ld	s1,24(sp)
    80002546:	6942                	ld	s2,16(sp)
    80002548:	69a2                	ld	s3,8(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
    freeproc(p);
    8000254e:	8526                	mv	a0,s1
    80002550:	00000097          	auipc	ra,0x0
    80002554:	f02080e7          	jalr	-254(ra) # 80002452 <freeproc>
    release(&p->lock);
    80002558:	8526                	mv	a0,s1
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	74c080e7          	jalr	1868(ra) # 80000ca6 <release>
    return 0;
    80002562:	84ca                	mv	s1,s2
    80002564:	bfe9                	j	8000253e <allocproc+0x7a>
    freeproc(p);
    80002566:	8526                	mv	a0,s1
    80002568:	00000097          	auipc	ra,0x0
    8000256c:	eea080e7          	jalr	-278(ra) # 80002452 <freeproc>
    release(&p->lock);
    80002570:	8526                	mv	a0,s1
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	734080e7          	jalr	1844(ra) # 80000ca6 <release>
    return 0;
    8000257a:	84ca                	mv	s1,s2
    8000257c:	b7c9                	j	8000253e <allocproc+0x7a>

000000008000257e <userinit>:
{
    8000257e:	1101                	addi	sp,sp,-32
    80002580:	ec06                	sd	ra,24(sp)
    80002582:	e822                	sd	s0,16(sp)
    80002584:	e426                	sd	s1,8(sp)
    80002586:	1000                	addi	s0,sp,32
  if(!init){
    80002588:	00007797          	auipc	a5,0x7
    8000258c:	ab87a783          	lw	a5,-1352(a5) # 80009040 <init>
    80002590:	e795                	bnez	a5,800025bc <userinit+0x3e>
      c->first = 0;
    80002592:	0000f797          	auipc	a5,0xf
    80002596:	d4e78793          	addi	a5,a5,-690 # 800112e0 <readyLock>
    8000259a:	1007bc23          	sd	zero,280(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    8000259e:	0807b823          	sd	zero,144(a5)
      c->first = 0;
    800025a2:	1a07b423          	sd	zero,424(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    800025a6:	1207b023          	sd	zero,288(a5)
      c->first = 0;
    800025aa:	2207bc23          	sd	zero,568(a5)
      BLNCFLG ?  c->queue_size = 0:counter_blance++;
    800025ae:	1a07b823          	sd	zero,432(a5)
    init = 1;
    800025b2:	4785                	li	a5,1
    800025b4:	00007717          	auipc	a4,0x7
    800025b8:	a8f72623          	sw	a5,-1396(a4) # 80009040 <init>
  p = allocproc();
    800025bc:	00000097          	auipc	ra,0x0
    800025c0:	f08080e7          	jalr	-248(ra) # 800024c4 <allocproc>
    800025c4:	84aa                	mv	s1,a0
  initproc = p;
    800025c6:	00007797          	auipc	a5,0x7
    800025ca:	a8a7bd23          	sd	a0,-1382(a5) # 80009060 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800025ce:	03400613          	li	a2,52
    800025d2:	00006597          	auipc	a1,0x6
    800025d6:	3be58593          	addi	a1,a1,958 # 80008990 <initcode>
    800025da:	7d28                	ld	a0,120(a0)
    800025dc:	fffff097          	auipc	ra,0xfffff
    800025e0:	d9a080e7          	jalr	-614(ra) # 80001376 <uvminit>
  p->sz = PGSIZE;
    800025e4:	6785                	lui	a5,0x1
    800025e6:	f8bc                	sd	a5,112(s1)
  p->trapframe->epc = 0;      // user program counter
    800025e8:	60d8                	ld	a4,128(s1)
    800025ea:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800025ee:	60d8                	ld	a4,128(s1)
    800025f0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800025f2:	4641                	li	a2,16
    800025f4:	00006597          	auipc	a1,0x6
    800025f8:	d3c58593          	addi	a1,a1,-708 # 80008330 <digits+0x2f0>
    800025fc:	18048513          	addi	a0,s1,384
    80002600:	fffff097          	auipc	ra,0xfffff
    80002604:	840080e7          	jalr	-1984(ra) # 80000e40 <safestrcpy>
  p->cwd = namei("/");
    80002608:	00006517          	auipc	a0,0x6
    8000260c:	d3850513          	addi	a0,a0,-712 # 80008340 <digits+0x300>
    80002610:	00002097          	auipc	ra,0x2
    80002614:	41c080e7          	jalr	1052(ra) # 80004a2c <namei>
    80002618:	16a4bc23          	sd	a0,376(s1)
  p->state = RUNNABLE;
    8000261c:	478d                	li	a5,3
    8000261e:	d89c                	sw	a5,48(s1)
  p->parent_cpu = 0;
    80002620:	0404ac23          	sw	zero,88(s1)
  cahnge_number_of_proc(p->parent_cpu,a);
    80002624:	4585                	li	a1,1
    80002626:	4501                	li	a0,0
    80002628:	fffff097          	auipc	ra,0xfffff
    8000262c:	518080e7          	jalr	1304(ra) # 80001b40 <cahnge_number_of_proc>
  cpus[p->parent_cpu].first = p;
    80002630:	4cb8                	lw	a4,88(s1)
    80002632:	00371793          	slli	a5,a4,0x3
    80002636:	97ba                	add	a5,a5,a4
    80002638:	0792                	slli	a5,a5,0x4
    8000263a:	0000f717          	auipc	a4,0xf
    8000263e:	ca670713          	addi	a4,a4,-858 # 800112e0 <readyLock>
    80002642:	97ba                	add	a5,a5,a4
    80002644:	1097bc23          	sd	s1,280(a5) # 1118 <_entry-0x7fffeee8>
  release(&p->lock);
    80002648:	8526                	mv	a0,s1
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	65c080e7          	jalr	1628(ra) # 80000ca6 <release>
}
    80002652:	60e2                	ld	ra,24(sp)
    80002654:	6442                	ld	s0,16(sp)
    80002656:	64a2                	ld	s1,8(sp)
    80002658:	6105                	addi	sp,sp,32
    8000265a:	8082                	ret

000000008000265c <growproc>:
{
    8000265c:	1101                	addi	sp,sp,-32
    8000265e:	ec06                	sd	ra,24(sp)
    80002660:	e822                	sd	s0,16(sp)
    80002662:	e426                	sd	s1,8(sp)
    80002664:	e04a                	sd	s2,0(sp)
    80002666:	1000                	addi	s0,sp,32
    80002668:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000266a:	00000097          	auipc	ra,0x0
    8000266e:	c22080e7          	jalr	-990(ra) # 8000228c <myproc>
    80002672:	892a                	mv	s2,a0
  sz = p->sz;
    80002674:	792c                	ld	a1,112(a0)
    80002676:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000267a:	00904f63          	bgtz	s1,80002698 <growproc+0x3c>
  } else if(n < 0){
    8000267e:	0204cc63          	bltz	s1,800026b6 <growproc+0x5a>
  p->sz = sz;
    80002682:	1602                	slli	a2,a2,0x20
    80002684:	9201                	srli	a2,a2,0x20
    80002686:	06c93823          	sd	a2,112(s2)
  return 0;
    8000268a:	4501                	li	a0,0
}
    8000268c:	60e2                	ld	ra,24(sp)
    8000268e:	6442                	ld	s0,16(sp)
    80002690:	64a2                	ld	s1,8(sp)
    80002692:	6902                	ld	s2,0(sp)
    80002694:	6105                	addi	sp,sp,32
    80002696:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002698:	9e25                	addw	a2,a2,s1
    8000269a:	1602                	slli	a2,a2,0x20
    8000269c:	9201                	srli	a2,a2,0x20
    8000269e:	1582                	slli	a1,a1,0x20
    800026a0:	9181                	srli	a1,a1,0x20
    800026a2:	7d28                	ld	a0,120(a0)
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	d8c080e7          	jalr	-628(ra) # 80001430 <uvmalloc>
    800026ac:	0005061b          	sext.w	a2,a0
    800026b0:	fa69                	bnez	a2,80002682 <growproc+0x26>
      return -1;
    800026b2:	557d                	li	a0,-1
    800026b4:	bfe1                	j	8000268c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800026b6:	9e25                	addw	a2,a2,s1
    800026b8:	1602                	slli	a2,a2,0x20
    800026ba:	9201                	srli	a2,a2,0x20
    800026bc:	1582                	slli	a1,a1,0x20
    800026be:	9181                	srli	a1,a1,0x20
    800026c0:	7d28                	ld	a0,120(a0)
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	d26080e7          	jalr	-730(ra) # 800013e8 <uvmdealloc>
    800026ca:	0005061b          	sext.w	a2,a0
    800026ce:	bf55                	j	80002682 <growproc+0x26>

00000000800026d0 <fork>:
{
    800026d0:	7179                	addi	sp,sp,-48
    800026d2:	f406                	sd	ra,40(sp)
    800026d4:	f022                	sd	s0,32(sp)
    800026d6:	ec26                	sd	s1,24(sp)
    800026d8:	e84a                	sd	s2,16(sp)
    800026da:	e44e                	sd	s3,8(sp)
    800026dc:	e052                	sd	s4,0(sp)
    800026de:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800026e0:	00000097          	auipc	ra,0x0
    800026e4:	bac080e7          	jalr	-1108(ra) # 8000228c <myproc>
    800026e8:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800026ea:	00000097          	auipc	ra,0x0
    800026ee:	dda080e7          	jalr	-550(ra) # 800024c4 <allocproc>
    800026f2:	12050863          	beqz	a0,80002822 <fork+0x152>
    800026f6:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800026f8:	0709b603          	ld	a2,112(s3)
    800026fc:	7d2c                	ld	a1,120(a0)
    800026fe:	0789b503          	ld	a0,120(s3)
    80002702:	fffff097          	auipc	ra,0xfffff
    80002706:	e7a080e7          	jalr	-390(ra) # 8000157c <uvmcopy>
    8000270a:	04054663          	bltz	a0,80002756 <fork+0x86>
  np->sz = p->sz;
    8000270e:	0709b783          	ld	a5,112(s3)
    80002712:	06f93823          	sd	a5,112(s2)
  *(np->trapframe) = *(p->trapframe);
    80002716:	0809b683          	ld	a3,128(s3)
    8000271a:	87b6                	mv	a5,a3
    8000271c:	08093703          	ld	a4,128(s2)
    80002720:	12068693          	addi	a3,a3,288
    80002724:	0007b803          	ld	a6,0(a5)
    80002728:	6788                	ld	a0,8(a5)
    8000272a:	6b8c                	ld	a1,16(a5)
    8000272c:	6f90                	ld	a2,24(a5)
    8000272e:	01073023          	sd	a6,0(a4)
    80002732:	e708                	sd	a0,8(a4)
    80002734:	eb0c                	sd	a1,16(a4)
    80002736:	ef10                	sd	a2,24(a4)
    80002738:	02078793          	addi	a5,a5,32
    8000273c:	02070713          	addi	a4,a4,32
    80002740:	fed792e3          	bne	a5,a3,80002724 <fork+0x54>
  np->trapframe->a0 = 0;
    80002744:	08093783          	ld	a5,128(s2)
    80002748:	0607b823          	sd	zero,112(a5)
    8000274c:	0f800493          	li	s1,248
  for(i = 0; i < NOFILE; i++)
    80002750:	17800a13          	li	s4,376
    80002754:	a03d                	j	80002782 <fork+0xb2>
    freeproc(np);
    80002756:	854a                	mv	a0,s2
    80002758:	00000097          	auipc	ra,0x0
    8000275c:	cfa080e7          	jalr	-774(ra) # 80002452 <freeproc>
    release(&np->lock);
    80002760:	854a                	mv	a0,s2
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	544080e7          	jalr	1348(ra) # 80000ca6 <release>
    return -1;
    8000276a:	5a7d                	li	s4,-1
    8000276c:	a055                	j	80002810 <fork+0x140>
      np->ofile[i] = filedup(p->ofile[i]);
    8000276e:	00003097          	auipc	ra,0x3
    80002772:	954080e7          	jalr	-1708(ra) # 800050c2 <filedup>
    80002776:	009907b3          	add	a5,s2,s1
    8000277a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000277c:	04a1                	addi	s1,s1,8
    8000277e:	01448763          	beq	s1,s4,8000278c <fork+0xbc>
    if(p->ofile[i])
    80002782:	009987b3          	add	a5,s3,s1
    80002786:	6388                	ld	a0,0(a5)
    80002788:	f17d                	bnez	a0,8000276e <fork+0x9e>
    8000278a:	bfcd                	j	8000277c <fork+0xac>
  np->cwd = idup(p->cwd);
    8000278c:	1789b503          	ld	a0,376(s3)
    80002790:	00002097          	auipc	ra,0x2
    80002794:	aa8080e7          	jalr	-1368(ra) # 80004238 <idup>
    80002798:	16a93c23          	sd	a0,376(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000279c:	4641                	li	a2,16
    8000279e:	18098593          	addi	a1,s3,384
    800027a2:	18090513          	addi	a0,s2,384
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	69a080e7          	jalr	1690(ra) # 80000e40 <safestrcpy>
  pid = np->pid;
    800027ae:	04892a03          	lw	s4,72(s2)
  release(&np->lock);
    800027b2:	854a                	mv	a0,s2
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	4f2080e7          	jalr	1266(ra) # 80000ca6 <release>
  acquire(&wait_lock);
    800027bc:	0000f497          	auipc	s1,0xf
    800027c0:	e0c48493          	addi	s1,s1,-500 # 800115c8 <wait_lock>
    800027c4:	8526                	mv	a0,s1
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	426080e7          	jalr	1062(ra) # 80000bec <acquire>
  np->parent = p;
    800027ce:	07393023          	sd	s3,96(s2)
  release(&wait_lock);
    800027d2:	8526                	mv	a0,s1
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	4d2080e7          	jalr	1234(ra) # 80000ca6 <release>
  acquire(&np->lock);
    800027dc:	854a                	mv	a0,s2
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	40e080e7          	jalr	1038(ra) # 80000bec <acquire>
  np->state = RUNNABLE;
    800027e6:	478d                	li	a5,3
    800027e8:	02f92823          	sw	a5,48(s2)
    int cpu_id = (BLNCFLG) ? get_lazy_cpu() : p->parent_cpu;
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	320080e7          	jalr	800(ra) # 80001b0c <get_lazy_cpu>
    800027f4:	862a                	mv	a2,a0
  np->parent_cpu = cpu_id;
    800027f6:	04a92c23          	sw	a0,88(s2)
  add_proc_to_list(np, READYL, cpu_id);
    800027fa:	4581                	li	a1,0
    800027fc:	854a                	mv	a0,s2
    800027fe:	fffff097          	auipc	ra,0xfffff
    80002802:	694080e7          	jalr	1684(ra) # 80001e92 <add_proc_to_list>
  release(&np->lock);
    80002806:	854a                	mv	a0,s2
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	49e080e7          	jalr	1182(ra) # 80000ca6 <release>
}
    80002810:	8552                	mv	a0,s4
    80002812:	70a2                	ld	ra,40(sp)
    80002814:	7402                	ld	s0,32(sp)
    80002816:	64e2                	ld	s1,24(sp)
    80002818:	6942                	ld	s2,16(sp)
    8000281a:	69a2                	ld	s3,8(sp)
    8000281c:	6a02                	ld	s4,0(sp)
    8000281e:	6145                	addi	sp,sp,48
    80002820:	8082                	ret
    return -1;
    80002822:	5a7d                	li	s4,-1
    80002824:	b7f5                	j	80002810 <fork+0x140>

0000000080002826 <blncflag_on>:
{
    80002826:	7139                	addi	sp,sp,-64
    80002828:	fc06                	sd	ra,56(sp)
    8000282a:	f822                	sd	s0,48(sp)
    8000282c:	f426                	sd	s1,40(sp)
    8000282e:	f04a                	sd	s2,32(sp)
    80002830:	ec4e                	sd	s3,24(sp)
    80002832:	e852                	sd	s4,16(sp)
    80002834:	e456                	sd	s5,8(sp)
    80002836:	e05a                	sd	s6,0(sp)
    80002838:	0080                	addi	s0,sp,64
    8000283a:	8792                	mv	a5,tp
  int id = r_tp();
    8000283c:	2781                	sext.w	a5,a5
    8000283e:	8a12                	mv	s4,tp
    80002840:	2a01                	sext.w	s4,s4
  c->proc = 0;
    80002842:	00379993          	slli	s3,a5,0x3
    80002846:	00f98733          	add	a4,s3,a5
    8000284a:	00471693          	slli	a3,a4,0x4
    8000284e:	0000f717          	auipc	a4,0xf
    80002852:	a9270713          	addi	a4,a4,-1390 # 800112e0 <readyLock>
    80002856:	9736                	add	a4,a4,a3
    80002858:	08073c23          	sd	zero,152(a4)
    swtch(&c->context, &p->context);
    8000285c:	0000f717          	auipc	a4,0xf
    80002860:	b2470713          	addi	a4,a4,-1244 # 80011380 <cpus+0x10>
    80002864:	00e689b3          	add	s3,a3,a4
    if(p->state!=RUNNABLE)
    80002868:	4a8d                	li	s5,3
    p->state = RUNNING;
    8000286a:	4b11                	li	s6,4
    c->proc = p;
    8000286c:	0000f917          	auipc	s2,0xf
    80002870:	a7490913          	addi	s2,s2,-1420 # 800112e0 <readyLock>
    80002874:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002876:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000287a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000287e:	10079073          	csrw	sstatus,a5
    p = remove_first(READYL, cpu_id);
    80002882:	85d2                	mv	a1,s4
    80002884:	4501                	li	a0,0
    80002886:	fffff097          	auipc	ra,0xfffff
    8000288a:	668080e7          	jalr	1640(ra) # 80001eee <remove_first>
    8000288e:	84aa                	mv	s1,a0
    if(!p){
    80002890:	d17d                	beqz	a0,80002876 <blncflag_on+0x50>
    acquire(&p->lock);
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	35a080e7          	jalr	858(ra) # 80000bec <acquire>
    if(p->state!=RUNNABLE)
    8000289a:	589c                	lw	a5,48(s1)
    8000289c:	03579563          	bne	a5,s5,800028c6 <blncflag_on+0xa0>
    p->state = RUNNING;
    800028a0:	0364a823          	sw	s6,48(s1)
    c->proc = p;
    800028a4:	08993c23          	sd	s1,152(s2)
    swtch(&c->context, &p->context);
    800028a8:	08848593          	addi	a1,s1,136
    800028ac:	854e                	mv	a0,s3
    800028ae:	00001097          	auipc	ra,0x1
    800028b2:	91a080e7          	jalr	-1766(ra) # 800031c8 <swtch>
    c->proc = 0;
    800028b6:	08093c23          	sd	zero,152(s2)
    release(&p->lock);
    800028ba:	8526                	mv	a0,s1
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	3ea080e7          	jalr	1002(ra) # 80000ca6 <release>
    800028c4:	bf4d                	j	80002876 <blncflag_on+0x50>
      panic("bad proc was selected");
    800028c6:	00006517          	auipc	a0,0x6
    800028ca:	a8250513          	addi	a0,a0,-1406 # 80008348 <digits+0x308>
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	c70080e7          	jalr	-912(ra) # 8000053e <panic>

00000000800028d6 <scheduler>:
{
    800028d6:	1141                	addi	sp,sp,-16
    800028d8:	e406                	sd	ra,8(sp)
    800028da:	e022                	sd	s0,0(sp)
    800028dc:	0800                	addi	s0,sp,16
      if(!print_flag){
    800028de:	00006797          	auipc	a5,0x6
    800028e2:	78e7a783          	lw	a5,1934(a5) # 8000906c <print_flag>
    800028e6:	c789                	beqz	a5,800028f0 <scheduler+0x1a>
    blncflag_on();
    800028e8:	00000097          	auipc	ra,0x0
    800028ec:	f3e080e7          	jalr	-194(ra) # 80002826 <blncflag_on>
      print_flag++;
    800028f0:	4785                	li	a5,1
    800028f2:	00006717          	auipc	a4,0x6
    800028f6:	76f72d23          	sw	a5,1914(a4) # 8000906c <print_flag>
      printf("BLNCFLG is ON\n");
    800028fa:	00006517          	auipc	a0,0x6
    800028fe:	a6650513          	addi	a0,a0,-1434 # 80008360 <digits+0x320>
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	c86080e7          	jalr	-890(ra) # 80000588 <printf>
    8000290a:	bff9                	j	800028e8 <scheduler+0x12>

000000008000290c <blncflag_off>:
{
    8000290c:	7139                	addi	sp,sp,-64
    8000290e:	fc06                	sd	ra,56(sp)
    80002910:	f822                	sd	s0,48(sp)
    80002912:	f426                	sd	s1,40(sp)
    80002914:	f04a                	sd	s2,32(sp)
    80002916:	ec4e                	sd	s3,24(sp)
    80002918:	e852                	sd	s4,16(sp)
    8000291a:	e456                	sd	s5,8(sp)
    8000291c:	e05a                	sd	s6,0(sp)
    8000291e:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    80002920:	8792                	mv	a5,tp
  int id = r_tp();
    80002922:	2781                	sext.w	a5,a5
    80002924:	8a12                	mv	s4,tp
    80002926:	2a01                	sext.w	s4,s4
  c->proc = 0;
    80002928:	00379993          	slli	s3,a5,0x3
    8000292c:	00f98733          	add	a4,s3,a5
    80002930:	00471693          	slli	a3,a4,0x4
    80002934:	0000f717          	auipc	a4,0xf
    80002938:	9ac70713          	addi	a4,a4,-1620 # 800112e0 <readyLock>
    8000293c:	9736                	add	a4,a4,a3
    8000293e:	08073c23          	sd	zero,152(a4)
        swtch(&c->context, &p->context);
    80002942:	0000f717          	auipc	a4,0xf
    80002946:	a3e70713          	addi	a4,a4,-1474 # 80011380 <cpus+0x10>
    8000294a:	00e689b3          	add	s3,a3,a4
      if(p->state != RUNNABLE)
    8000294e:	4a8d                	li	s5,3
        p->state = RUNNING;
    80002950:	4b11                	li	s6,4
        c->proc = p;
    80002952:	0000f917          	auipc	s2,0xf
    80002956:	98e90913          	addi	s2,s2,-1650 # 800112e0 <readyLock>
    8000295a:	9936                	add	s2,s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002960:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002964:	10079073          	csrw	sstatus,a5
    p = remove_first(READYL, cpu_id);
    80002968:	85d2                	mv	a1,s4
    8000296a:	4501                	li	a0,0
    8000296c:	fffff097          	auipc	ra,0xfffff
    80002970:	582080e7          	jalr	1410(ra) # 80001eee <remove_first>
    80002974:	84aa                	mv	s1,a0
    if(!p){ // no proces ready 
    80002976:	d17d                	beqz	a0,8000295c <blncflag_off+0x50>
      acquire(&p->lock);
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	274080e7          	jalr	628(ra) # 80000bec <acquire>
      if(p->state != RUNNABLE)
    80002980:	589c                	lw	a5,48(s1)
    80002982:	03579563          	bne	a5,s5,800029ac <blncflag_off+0xa0>
        p->state = RUNNING;
    80002986:	0364a823          	sw	s6,48(s1)
        c->proc = p;
    8000298a:	08993c23          	sd	s1,152(s2)
        swtch(&c->context, &p->context);
    8000298e:	08848593          	addi	a1,s1,136
    80002992:	854e                	mv	a0,s3
    80002994:	00001097          	auipc	ra,0x1
    80002998:	834080e7          	jalr	-1996(ra) # 800031c8 <swtch>
        c->proc = 0;
    8000299c:	08093c23          	sd	zero,152(s2)
      release(&p->lock);
    800029a0:	8526                	mv	a0,s1
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	304080e7          	jalr	772(ra) # 80000ca6 <release>
    800029aa:	bf4d                	j	8000295c <blncflag_off+0x50>
        panic("bad proc was selected");
    800029ac:	00006517          	auipc	a0,0x6
    800029b0:	99c50513          	addi	a0,a0,-1636 # 80008348 <digits+0x308>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	b8a080e7          	jalr	-1142(ra) # 8000053e <panic>

00000000800029bc <sched>:
{
    800029bc:	7179                	addi	sp,sp,-48
    800029be:	f406                	sd	ra,40(sp)
    800029c0:	f022                	sd	s0,32(sp)
    800029c2:	ec26                	sd	s1,24(sp)
    800029c4:	e84a                	sd	s2,16(sp)
    800029c6:	e44e                	sd	s3,8(sp)
    800029c8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800029ca:	00000097          	auipc	ra,0x0
    800029ce:	8c2080e7          	jalr	-1854(ra) # 8000228c <myproc>
    800029d2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	196080e7          	jalr	406(ra) # 80000b6a <holding>
    800029dc:	c959                	beqz	a0,80002a72 <sched+0xb6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800029de:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800029e0:	0007871b          	sext.w	a4,a5
    800029e4:	00371793          	slli	a5,a4,0x3
    800029e8:	97ba                	add	a5,a5,a4
    800029ea:	0792                	slli	a5,a5,0x4
    800029ec:	0000f717          	auipc	a4,0xf
    800029f0:	8f470713          	addi	a4,a4,-1804 # 800112e0 <readyLock>
    800029f4:	97ba                	add	a5,a5,a4
    800029f6:	1107a703          	lw	a4,272(a5)
    800029fa:	4785                	li	a5,1
    800029fc:	08f71363          	bne	a4,a5,80002a82 <sched+0xc6>
  if(p->state == RUNNING)
    80002a00:	5898                	lw	a4,48(s1)
    80002a02:	4791                	li	a5,4
    80002a04:	08f70763          	beq	a4,a5,80002a92 <sched+0xd6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a08:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a0c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002a0e:	ebd1                	bnez	a5,80002aa2 <sched+0xe6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a10:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002a12:	0000f917          	auipc	s2,0xf
    80002a16:	8ce90913          	addi	s2,s2,-1842 # 800112e0 <readyLock>
    80002a1a:	0007871b          	sext.w	a4,a5
    80002a1e:	00371793          	slli	a5,a4,0x3
    80002a22:	97ba                	add	a5,a5,a4
    80002a24:	0792                	slli	a5,a5,0x4
    80002a26:	97ca                	add	a5,a5,s2
    80002a28:	1147a983          	lw	s3,276(a5)
    80002a2c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002a2e:	0007859b          	sext.w	a1,a5
    80002a32:	00359793          	slli	a5,a1,0x3
    80002a36:	97ae                	add	a5,a5,a1
    80002a38:	0792                	slli	a5,a5,0x4
    80002a3a:	0000f597          	auipc	a1,0xf
    80002a3e:	94658593          	addi	a1,a1,-1722 # 80011380 <cpus+0x10>
    80002a42:	95be                	add	a1,a1,a5
    80002a44:	08848513          	addi	a0,s1,136
    80002a48:	00000097          	auipc	ra,0x0
    80002a4c:	780080e7          	jalr	1920(ra) # 800031c8 <swtch>
    80002a50:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002a52:	0007871b          	sext.w	a4,a5
    80002a56:	00371793          	slli	a5,a4,0x3
    80002a5a:	97ba                	add	a5,a5,a4
    80002a5c:	0792                	slli	a5,a5,0x4
    80002a5e:	97ca                	add	a5,a5,s2
    80002a60:	1137aa23          	sw	s3,276(a5)
}
    80002a64:	70a2                	ld	ra,40(sp)
    80002a66:	7402                	ld	s0,32(sp)
    80002a68:	64e2                	ld	s1,24(sp)
    80002a6a:	6942                	ld	s2,16(sp)
    80002a6c:	69a2                	ld	s3,8(sp)
    80002a6e:	6145                	addi	sp,sp,48
    80002a70:	8082                	ret
    panic("sched p->lock");
    80002a72:	00006517          	auipc	a0,0x6
    80002a76:	8fe50513          	addi	a0,a0,-1794 # 80008370 <digits+0x330>
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	ac4080e7          	jalr	-1340(ra) # 8000053e <panic>
    panic("sched locks");
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	8fe50513          	addi	a0,a0,-1794 # 80008380 <digits+0x340>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>
    panic("sched running");
    80002a92:	00006517          	auipc	a0,0x6
    80002a96:	8fe50513          	addi	a0,a0,-1794 # 80008390 <digits+0x350>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	aa4080e7          	jalr	-1372(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002aa2:	00006517          	auipc	a0,0x6
    80002aa6:	8fe50513          	addi	a0,a0,-1794 # 800083a0 <digits+0x360>
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	a94080e7          	jalr	-1388(ra) # 8000053e <panic>

0000000080002ab2 <yield>:
{
    80002ab2:	1101                	addi	sp,sp,-32
    80002ab4:	ec06                	sd	ra,24(sp)
    80002ab6:	e822                	sd	s0,16(sp)
    80002ab8:	e426                	sd	s1,8(sp)
    80002aba:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	7d0080e7          	jalr	2000(ra) # 8000228c <myproc>
    80002ac4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002ac6:	ffffe097          	auipc	ra,0xffffe
    80002aca:	126080e7          	jalr	294(ra) # 80000bec <acquire>
  p->state = RUNNABLE;
    80002ace:	478d                	li	a5,3
    80002ad0:	d89c                	sw	a5,48(s1)
  add_proc_to_list(p, READYL, p->parent_cpu);
    80002ad2:	4cb0                	lw	a2,88(s1)
    80002ad4:	4581                	li	a1,0
    80002ad6:	8526                	mv	a0,s1
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	3ba080e7          	jalr	954(ra) # 80001e92 <add_proc_to_list>
  sched();
    80002ae0:	00000097          	auipc	ra,0x0
    80002ae4:	edc080e7          	jalr	-292(ra) # 800029bc <sched>
  release(&p->lock);
    80002ae8:	8526                	mv	a0,s1
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	1bc080e7          	jalr	444(ra) # 80000ca6 <release>
}
    80002af2:	60e2                	ld	ra,24(sp)
    80002af4:	6442                	ld	s0,16(sp)
    80002af6:	64a2                	ld	s1,8(sp)
    80002af8:	6105                	addi	sp,sp,32
    80002afa:	8082                	ret

0000000080002afc <set_cpu>:
  if(cpu_num<0 || cpu_num>NCPU){
    80002afc:	47a1                	li	a5,8
    80002afe:	04a7e763          	bltu	a5,a0,80002b4c <set_cpu+0x50>
{
    80002b02:	1101                	addi	sp,sp,-32
    80002b04:	ec06                	sd	ra,24(sp)
    80002b06:	e822                	sd	s0,16(sp)
    80002b08:	e426                	sd	s1,8(sp)
    80002b0a:	e04a                	sd	s2,0(sp)
    80002b0c:	1000                	addi	s0,sp,32
    80002b0e:	84aa                	mv	s1,a0
  struct proc* p = myproc();
    80002b10:	fffff097          	auipc	ra,0xfffff
    80002b14:	77c080e7          	jalr	1916(ra) # 8000228c <myproc>
    80002b18:	892a                	mv	s2,a0
  cahnge_number_of_proc(p->parent_cpu,b);
    80002b1a:	55fd                	li	a1,-1
    80002b1c:	4d28                	lw	a0,88(a0)
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	022080e7          	jalr	34(ra) # 80001b40 <cahnge_number_of_proc>
  p->parent_cpu=cpu_num;
    80002b26:	04992c23          	sw	s1,88(s2)
  cahnge_number_of_proc(cpu_num,positive);
    80002b2a:	4585                	li	a1,1
    80002b2c:	8526                	mv	a0,s1
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	012080e7          	jalr	18(ra) # 80001b40 <cahnge_number_of_proc>
  yield();
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	f7c080e7          	jalr	-132(ra) # 80002ab2 <yield>
  return cpu_num;
    80002b3e:	8526                	mv	a0,s1
}
    80002b40:	60e2                	ld	ra,24(sp)
    80002b42:	6442                	ld	s0,16(sp)
    80002b44:	64a2                	ld	s1,8(sp)
    80002b46:	6902                	ld	s2,0(sp)
    80002b48:	6105                	addi	sp,sp,32
    80002b4a:	8082                	ret
    return -1;
    80002b4c:	557d                	li	a0,-1
}
    80002b4e:	8082                	ret

0000000080002b50 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002b50:	7179                	addi	sp,sp,-48
    80002b52:	f406                	sd	ra,40(sp)
    80002b54:	f022                	sd	s0,32(sp)
    80002b56:	ec26                	sd	s1,24(sp)
    80002b58:	e84a                	sd	s2,16(sp)
    80002b5a:	e44e                	sd	s3,8(sp)
    80002b5c:	1800                	addi	s0,sp,48
    80002b5e:	89aa                	mv	s3,a0
    80002b60:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	72a080e7          	jalr	1834(ra) # 8000228c <myproc>
    80002b6a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	080080e7          	jalr	128(ra) # 80000bec <acquire>
  release(lk);
    80002b74:	854a                	mv	a0,s2
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	130080e7          	jalr	304(ra) # 80000ca6 <release>

  // Go to sleep.
  p->chan = chan;
    80002b7e:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    80002b82:	4789                	li	a5,2
    80002b84:	d89c                	sw	a5,48(s1)
  // decrease_size(p->parent_cpu);
  int b=-1;
  cahnge_number_of_proc(p->parent_cpu,b);
    80002b86:	55fd                	li	a1,-1
    80002b88:	4ca8                	lw	a0,88(s1)
    80002b8a:	fffff097          	auipc	ra,0xfffff
    80002b8e:	fb6080e7          	jalr	-74(ra) # 80001b40 <cahnge_number_of_proc>
  //--------------------------------------------------------------------
    add_proc_to_list(p, SLEEPINGL,-1);
    80002b92:	567d                	li	a2,-1
    80002b94:	4589                	li	a1,2
    80002b96:	8526                	mv	a0,s1
    80002b98:	fffff097          	auipc	ra,0xfffff
    80002b9c:	2fa080e7          	jalr	762(ra) # 80001e92 <add_proc_to_list>
  //--------------------------------------------------------------------

  sched();
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	e1c080e7          	jalr	-484(ra) # 800029bc <sched>

  // Tidy up.
  p->chan = 0;
    80002ba8:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002bac:	8526                	mv	a0,s1
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	0f8080e7          	jalr	248(ra) # 80000ca6 <release>
  acquire(lk);
    80002bb6:	854a                	mv	a0,s2
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	034080e7          	jalr	52(ra) # 80000bec <acquire>

}
    80002bc0:	70a2                	ld	ra,40(sp)
    80002bc2:	7402                	ld	s0,32(sp)
    80002bc4:	64e2                	ld	s1,24(sp)
    80002bc6:	6942                	ld	s2,16(sp)
    80002bc8:	69a2                	ld	s3,8(sp)
    80002bca:	6145                	addi	sp,sp,48
    80002bcc:	8082                	ret

0000000080002bce <wait>:
{
    80002bce:	715d                	addi	sp,sp,-80
    80002bd0:	e486                	sd	ra,72(sp)
    80002bd2:	e0a2                	sd	s0,64(sp)
    80002bd4:	fc26                	sd	s1,56(sp)
    80002bd6:	f84a                	sd	s2,48(sp)
    80002bd8:	f44e                	sd	s3,40(sp)
    80002bda:	f052                	sd	s4,32(sp)
    80002bdc:	ec56                	sd	s5,24(sp)
    80002bde:	e85a                	sd	s6,16(sp)
    80002be0:	e45e                	sd	s7,8(sp)
    80002be2:	e062                	sd	s8,0(sp)
    80002be4:	0880                	addi	s0,sp,80
    80002be6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	6a4080e7          	jalr	1700(ra) # 8000228c <myproc>
    80002bf0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002bf2:	0000f517          	auipc	a0,0xf
    80002bf6:	9d650513          	addi	a0,a0,-1578 # 800115c8 <wait_lock>
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	ff2080e7          	jalr	-14(ra) # 80000bec <acquire>
    havekids = 0;
    80002c02:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002c04:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002c06:	00015997          	auipc	s3,0x15
    80002c0a:	dda98993          	addi	s3,s3,-550 # 800179e0 <tickslock>
        havekids = 1;
    80002c0e:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002c10:	0000fc17          	auipc	s8,0xf
    80002c14:	9b8c0c13          	addi	s8,s8,-1608 # 800115c8 <wait_lock>
    havekids = 0;
    80002c18:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002c1a:	0000f497          	auipc	s1,0xf
    80002c1e:	9c648493          	addi	s1,s1,-1594 # 800115e0 <proc>
    80002c22:	a0bd                	j	80002c90 <wait+0xc2>
          pid = np->pid;
    80002c24:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002c28:	000b0e63          	beqz	s6,80002c44 <wait+0x76>
    80002c2c:	4691                	li	a3,4
    80002c2e:	04448613          	addi	a2,s1,68
    80002c32:	85da                	mv	a1,s6
    80002c34:	07893503          	ld	a0,120(s2)
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	a48080e7          	jalr	-1464(ra) # 80001680 <copyout>
    80002c40:	02054563          	bltz	a0,80002c6a <wait+0x9c>
          freeproc(np);
    80002c44:	8526                	mv	a0,s1
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	80c080e7          	jalr	-2036(ra) # 80002452 <freeproc>
          release(&np->lock);
    80002c4e:	8526                	mv	a0,s1
    80002c50:	ffffe097          	auipc	ra,0xffffe
    80002c54:	056080e7          	jalr	86(ra) # 80000ca6 <release>
          release(&wait_lock);
    80002c58:	0000f517          	auipc	a0,0xf
    80002c5c:	97050513          	addi	a0,a0,-1680 # 800115c8 <wait_lock>
    80002c60:	ffffe097          	auipc	ra,0xffffe
    80002c64:	046080e7          	jalr	70(ra) # 80000ca6 <release>
          return pid;
    80002c68:	a09d                	j	80002cce <wait+0x100>
            release(&np->lock);
    80002c6a:	8526                	mv	a0,s1
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	03a080e7          	jalr	58(ra) # 80000ca6 <release>
            release(&wait_lock);
    80002c74:	0000f517          	auipc	a0,0xf
    80002c78:	95450513          	addi	a0,a0,-1708 # 800115c8 <wait_lock>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	02a080e7          	jalr	42(ra) # 80000ca6 <release>
            return -1;
    80002c84:	59fd                	li	s3,-1
    80002c86:	a0a1                	j	80002cce <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002c88:	19048493          	addi	s1,s1,400
    80002c8c:	03348463          	beq	s1,s3,80002cb4 <wait+0xe6>
      if(np->parent == p){
    80002c90:	70bc                	ld	a5,96(s1)
    80002c92:	ff279be3          	bne	a5,s2,80002c88 <wait+0xba>
        acquire(&np->lock);
    80002c96:	8526                	mv	a0,s1
    80002c98:	ffffe097          	auipc	ra,0xffffe
    80002c9c:	f54080e7          	jalr	-172(ra) # 80000bec <acquire>
        if(np->state == ZOMBIE){
    80002ca0:	589c                	lw	a5,48(s1)
    80002ca2:	f94781e3          	beq	a5,s4,80002c24 <wait+0x56>
        release(&np->lock);
    80002ca6:	8526                	mv	a0,s1
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	ffe080e7          	jalr	-2(ra) # 80000ca6 <release>
        havekids = 1;
    80002cb0:	8756                	mv	a4,s5
    80002cb2:	bfd9                	j	80002c88 <wait+0xba>
    if(!havekids || p->killed){
    80002cb4:	c701                	beqz	a4,80002cbc <wait+0xee>
    80002cb6:	04092783          	lw	a5,64(s2)
    80002cba:	c79d                	beqz	a5,80002ce8 <wait+0x11a>
      release(&wait_lock);
    80002cbc:	0000f517          	auipc	a0,0xf
    80002cc0:	90c50513          	addi	a0,a0,-1780 # 800115c8 <wait_lock>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	fe2080e7          	jalr	-30(ra) # 80000ca6 <release>
      return -1;
    80002ccc:	59fd                	li	s3,-1
}
    80002cce:	854e                	mv	a0,s3
    80002cd0:	60a6                	ld	ra,72(sp)
    80002cd2:	6406                	ld	s0,64(sp)
    80002cd4:	74e2                	ld	s1,56(sp)
    80002cd6:	7942                	ld	s2,48(sp)
    80002cd8:	79a2                	ld	s3,40(sp)
    80002cda:	7a02                	ld	s4,32(sp)
    80002cdc:	6ae2                	ld	s5,24(sp)
    80002cde:	6b42                	ld	s6,16(sp)
    80002ce0:	6ba2                	ld	s7,8(sp)
    80002ce2:	6c02                	ld	s8,0(sp)
    80002ce4:	6161                	addi	sp,sp,80
    80002ce6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002ce8:	85e2                	mv	a1,s8
    80002cea:	854a                	mv	a0,s2
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	e64080e7          	jalr	-412(ra) # 80002b50 <sleep>
    havekids = 0;
    80002cf4:	b715                	j	80002c18 <wait+0x4a>

0000000080002cf6 <wakeup>:
// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
//--------------------------------------------------------------------
void
wakeup(void *chan)
{
    80002cf6:	711d                	addi	sp,sp,-96
    80002cf8:	ec86                	sd	ra,88(sp)
    80002cfa:	e8a2                	sd	s0,80(sp)
    80002cfc:	e4a6                	sd	s1,72(sp)
    80002cfe:	e0ca                	sd	s2,64(sp)
    80002d00:	fc4e                	sd	s3,56(sp)
    80002d02:	f852                	sd	s4,48(sp)
    80002d04:	f456                	sd	s5,40(sp)
    80002d06:	f05a                	sd	s6,32(sp)
    80002d08:	ec5e                	sd	s7,24(sp)
    80002d0a:	e862                	sd	s8,16(sp)
    80002d0c:	e466                	sd	s9,8(sp)
    80002d0e:	e06a                	sd	s10,0(sp)
    80002d10:	1080                	addi	s0,sp,96
    80002d12:	8aaa                	mv	s5,a0
  int released_list = 0;
  struct proc *p;
  struct proc* prev = 0;
  struct proc* tmp;
  acquire_list(SLEEPINGL, -1);
    80002d14:	55fd                	li	a1,-1
    80002d16:	4509                	li	a0,2
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	e78080e7          	jalr	-392(ra) # 80001b90 <acquire_list>
  p = get_head(SLEEPINGL, -1);
    80002d20:	55fd                	li	a1,-1
    80002d22:	4509                	li	a0,2
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	ef4080e7          	jalr	-268(ra) # 80001c18 <get_head>
    80002d2c:	84aa                	mv	s1,a0
  while(p){
    80002d2e:	14050663          	beqz	a0,80002e7a <wakeup+0x184>
  struct proc* prev = 0;
    80002d32:	4a01                	li	s4,0
  int released_list = 0;
    80002d34:	4c01                	li	s8,0
    } 
    else{
      //we are not on the chan
      if(p == get_head(SLEEPINGL, -1)){
        release_list(SLEEPINGL,-1);
        released_list = 1;
    80002d36:	4b85                	li	s7,1
        p->state = RUNNABLE;
    80002d38:	4c8d                	li	s9,3
    80002d3a:	a8c9                	j	80002e0c <wakeup+0x116>
      if(p == get_head(SLEEPINGL, -1)){
    80002d3c:	55fd                	li	a1,-1
    80002d3e:	4509                	li	a0,2
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	ed8080e7          	jalr	-296(ra) # 80001c18 <get_head>
    80002d48:	04a48863          	beq	s1,a0,80002d98 <wakeup+0xa2>
        prev->next = p->next;
    80002d4c:	68bc                	ld	a5,80(s1)
    80002d4e:	04fa3823          	sd	a5,80(s4)
        p->next = 0;
    80002d52:	0404b823          	sd	zero,80(s1)
        p->state = RUNNABLE;
    80002d56:	0394a823          	sw	s9,48(s1)
        int cpu_id = (BLNCFLG) ? get_lazy_cpu() : p->parent_cpu;
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	db2080e7          	jalr	-590(ra) # 80001b0c <get_lazy_cpu>
    80002d62:	8b2a                	mv	s6,a0
        p->parent_cpu = cpu_id;
    80002d64:	cca8                	sw	a0,88(s1)
        cahnge_number_of_proc(cpu_id,a);
    80002d66:	85de                	mv	a1,s7
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	dd8080e7          	jalr	-552(ra) # 80001b40 <cahnge_number_of_proc>
        add_proc_to_list(p, READYL, cpu_id);
    80002d70:	865a                	mv	a2,s6
    80002d72:	4581                	li	a1,0
    80002d74:	8526                	mv	a0,s1
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	11c080e7          	jalr	284(ra) # 80001e92 <add_proc_to_list>
        release(&p->list_lock);
    80002d7e:	854a                	mv	a0,s2
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	f26080e7          	jalr	-218(ra) # 80000ca6 <release>
        release(&p->lock);
    80002d88:	8526                	mv	a0,s1
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	f1c080e7          	jalr	-228(ra) # 80000ca6 <release>
        p = prev->next;
    80002d92:	050a3483          	ld	s1,80(s4)
    80002d96:	a895                	j	80002e0a <wakeup+0x114>
        set_head(p->next, SLEEPINGL, -1);
    80002d98:	567d                	li	a2,-1
    80002d9a:	4589                	li	a1,2
    80002d9c:	68a8                	ld	a0,80(s1)
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	ee0080e7          	jalr	-288(ra) # 80001c7e <set_head>
        p = p->next;
    80002da6:	0504bd03          	ld	s10,80(s1)
        tmp->next = 0;
    80002daa:	0404b823          	sd	zero,80(s1)
        tmp->state = RUNNABLE;
    80002dae:	0394a823          	sw	s9,48(s1)
        int cpu_id = (BLNCFLG) ? get_lazy_cpu() : tmp->parent_cpu;
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	d5a080e7          	jalr	-678(ra) # 80001b0c <get_lazy_cpu>
    80002dba:	8b2a                	mv	s6,a0
        tmp->parent_cpu = cpu_id;
    80002dbc:	cca8                	sw	a0,88(s1)
        cahnge_number_of_proc(cpu_id,a);
    80002dbe:	85de                	mv	a1,s7
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	d80080e7          	jalr	-640(ra) # 80001b40 <cahnge_number_of_proc>
        add_proc_to_list(tmp, READYL, cpu_id);
    80002dc8:	865a                	mv	a2,s6
    80002dca:	4581                	li	a1,0
    80002dcc:	8526                	mv	a0,s1
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	0c4080e7          	jalr	196(ra) # 80001e92 <add_proc_to_list>
        release(&tmp->list_lock);
    80002dd6:	854a                	mv	a0,s2
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	ece080e7          	jalr	-306(ra) # 80000ca6 <release>
        release(&tmp->lock);
    80002de0:	8526                	mv	a0,s1
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	ec4080e7          	jalr	-316(ra) # 80000ca6 <release>
        p = p->next;
    80002dea:	84ea                	mv	s1,s10
    80002dec:	a839                	j	80002e0a <wakeup+0x114>
        release_list(SLEEPINGL,-1);
    80002dee:	55fd                	li	a1,-1
    80002df0:	4509                	li	a0,2
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	f7a080e7          	jalr	-134(ra) # 80001d6c <release_list>
        released_list = 1;
    80002dfa:	8c5e                	mv	s8,s7
      }
      else{
        release(&prev->list_lock);
      }
      release(&p->lock);  //because we dont need to change his fields
    80002dfc:	854e                	mv	a0,s3
    80002dfe:	ffffe097          	auipc	ra,0xffffe
    80002e02:	ea8080e7          	jalr	-344(ra) # 80000ca6 <release>
      prev = p;
      p = p->next;
    80002e06:	8a26                	mv	s4,s1
    80002e08:	68a4                	ld	s1,80(s1)
  while(p){
    80002e0a:	c0a1                	beqz	s1,80002e4a <wakeup+0x154>
    acquire(&p->lock);
    80002e0c:	89a6                	mv	s3,s1
    80002e0e:	8526                	mv	a0,s1
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	ddc080e7          	jalr	-548(ra) # 80000bec <acquire>
    acquire(&p->list_lock);
    80002e18:	01848913          	addi	s2,s1,24
    80002e1c:	854a                	mv	a0,s2
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	dce080e7          	jalr	-562(ra) # 80000bec <acquire>
    if(p->chan == chan){
    80002e26:	7c9c                	ld	a5,56(s1)
    80002e28:	f1578ae3          	beq	a5,s5,80002d3c <wakeup+0x46>
      if(p == get_head(SLEEPINGL, -1)){
    80002e2c:	55fd                	li	a1,-1
    80002e2e:	4509                	li	a0,2
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	de8080e7          	jalr	-536(ra) # 80001c18 <get_head>
    80002e38:	faa48be3          	beq	s1,a0,80002dee <wakeup+0xf8>
        release(&prev->list_lock);
    80002e3c:	018a0513          	addi	a0,s4,24
    80002e40:	ffffe097          	auipc	ra,0xffffe
    80002e44:	e66080e7          	jalr	-410(ra) # 80000ca6 <release>
    80002e48:	bf55                	j	80002dfc <wakeup+0x106>
    }
  }
  if(!released_list){
    80002e4a:	020c0963          	beqz	s8,80002e7c <wakeup+0x186>
    release_list(SLEEPINGL, -1);
  }
  if(prev){
    80002e4e:	000a0863          	beqz	s4,80002e5e <wakeup+0x168>
    release(&prev->list_lock);
    80002e52:	018a0513          	addi	a0,s4,24
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	e50080e7          	jalr	-432(ra) # 80000ca6 <release>
  }
}
    80002e5e:	60e6                	ld	ra,88(sp)
    80002e60:	6446                	ld	s0,80(sp)
    80002e62:	64a6                	ld	s1,72(sp)
    80002e64:	6906                	ld	s2,64(sp)
    80002e66:	79e2                	ld	s3,56(sp)
    80002e68:	7a42                	ld	s4,48(sp)
    80002e6a:	7aa2                	ld	s5,40(sp)
    80002e6c:	7b02                	ld	s6,32(sp)
    80002e6e:	6be2                	ld	s7,24(sp)
    80002e70:	6c42                	ld	s8,16(sp)
    80002e72:	6ca2                	ld	s9,8(sp)
    80002e74:	6d02                	ld	s10,0(sp)
    80002e76:	6125                	addi	sp,sp,96
    80002e78:	8082                	ret
  struct proc* prev = 0;
    80002e7a:	8a2a                	mv	s4,a0
    release_list(SLEEPINGL, -1);
    80002e7c:	55fd                	li	a1,-1
    80002e7e:	4509                	li	a0,2
    80002e80:	fffff097          	auipc	ra,0xfffff
    80002e84:	eec080e7          	jalr	-276(ra) # 80001d6c <release_list>
    80002e88:	b7d9                	j	80002e4e <wakeup+0x158>

0000000080002e8a <reparent>:
{
    80002e8a:	7179                	addi	sp,sp,-48
    80002e8c:	f406                	sd	ra,40(sp)
    80002e8e:	f022                	sd	s0,32(sp)
    80002e90:	ec26                	sd	s1,24(sp)
    80002e92:	e84a                	sd	s2,16(sp)
    80002e94:	e44e                	sd	s3,8(sp)
    80002e96:	e052                	sd	s4,0(sp)
    80002e98:	1800                	addi	s0,sp,48
    80002e9a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002e9c:	0000e497          	auipc	s1,0xe
    80002ea0:	74448493          	addi	s1,s1,1860 # 800115e0 <proc>
      pp->parent = initproc;
    80002ea4:	00006a17          	auipc	s4,0x6
    80002ea8:	1bca0a13          	addi	s4,s4,444 # 80009060 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002eac:	00015997          	auipc	s3,0x15
    80002eb0:	b3498993          	addi	s3,s3,-1228 # 800179e0 <tickslock>
    80002eb4:	a029                	j	80002ebe <reparent+0x34>
    80002eb6:	19048493          	addi	s1,s1,400
    80002eba:	01348d63          	beq	s1,s3,80002ed4 <reparent+0x4a>
    if(pp->parent == p){
    80002ebe:	70bc                	ld	a5,96(s1)
    80002ec0:	ff279be3          	bne	a5,s2,80002eb6 <reparent+0x2c>
      pp->parent = initproc;
    80002ec4:	000a3503          	ld	a0,0(s4)
    80002ec8:	f0a8                	sd	a0,96(s1)
      wakeup(initproc);
    80002eca:	00000097          	auipc	ra,0x0
    80002ece:	e2c080e7          	jalr	-468(ra) # 80002cf6 <wakeup>
    80002ed2:	b7d5                	j	80002eb6 <reparent+0x2c>
}
    80002ed4:	70a2                	ld	ra,40(sp)
    80002ed6:	7402                	ld	s0,32(sp)
    80002ed8:	64e2                	ld	s1,24(sp)
    80002eda:	6942                	ld	s2,16(sp)
    80002edc:	69a2                	ld	s3,8(sp)
    80002ede:	6a02                	ld	s4,0(sp)
    80002ee0:	6145                	addi	sp,sp,48
    80002ee2:	8082                	ret

0000000080002ee4 <exit>:
{
    80002ee4:	7179                	addi	sp,sp,-48
    80002ee6:	f406                	sd	ra,40(sp)
    80002ee8:	f022                	sd	s0,32(sp)
    80002eea:	ec26                	sd	s1,24(sp)
    80002eec:	e84a                	sd	s2,16(sp)
    80002eee:	e44e                	sd	s3,8(sp)
    80002ef0:	e052                	sd	s4,0(sp)
    80002ef2:	1800                	addi	s0,sp,48
    80002ef4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	396080e7          	jalr	918(ra) # 8000228c <myproc>
    80002efe:	89aa                	mv	s3,a0
  if(p == initproc)
    80002f00:	00006797          	auipc	a5,0x6
    80002f04:	1607b783          	ld	a5,352(a5) # 80009060 <initproc>
    80002f08:	0f850493          	addi	s1,a0,248
    80002f0c:	17850913          	addi	s2,a0,376
    80002f10:	02a79363          	bne	a5,a0,80002f36 <exit+0x52>
    panic("init exiting");
    80002f14:	00005517          	auipc	a0,0x5
    80002f18:	4a450513          	addi	a0,a0,1188 # 800083b8 <digits+0x378>
    80002f1c:	ffffd097          	auipc	ra,0xffffd
    80002f20:	622080e7          	jalr	1570(ra) # 8000053e <panic>
      fileclose(f);
    80002f24:	00002097          	auipc	ra,0x2
    80002f28:	1f0080e7          	jalr	496(ra) # 80005114 <fileclose>
      p->ofile[fd] = 0;
    80002f2c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002f30:	04a1                	addi	s1,s1,8
    80002f32:	01248563          	beq	s1,s2,80002f3c <exit+0x58>
    if(p->ofile[fd]){
    80002f36:	6088                	ld	a0,0(s1)
    80002f38:	f575                	bnez	a0,80002f24 <exit+0x40>
    80002f3a:	bfdd                	j	80002f30 <exit+0x4c>
  begin_op();
    80002f3c:	00002097          	auipc	ra,0x2
    80002f40:	d0c080e7          	jalr	-756(ra) # 80004c48 <begin_op>
  iput(p->cwd);
    80002f44:	1789b503          	ld	a0,376(s3)
    80002f48:	00001097          	auipc	ra,0x1
    80002f4c:	4e8080e7          	jalr	1256(ra) # 80004430 <iput>
  end_op();
    80002f50:	00002097          	auipc	ra,0x2
    80002f54:	d78080e7          	jalr	-648(ra) # 80004cc8 <end_op>
  p->cwd = 0;
    80002f58:	1609bc23          	sd	zero,376(s3)
  acquire(&wait_lock);
    80002f5c:	0000e497          	auipc	s1,0xe
    80002f60:	66c48493          	addi	s1,s1,1644 # 800115c8 <wait_lock>
    80002f64:	8526                	mv	a0,s1
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	c86080e7          	jalr	-890(ra) # 80000bec <acquire>
  reparent(p);
    80002f6e:	854e                	mv	a0,s3
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	f1a080e7          	jalr	-230(ra) # 80002e8a <reparent>
  wakeup(p->parent);
    80002f78:	0609b503          	ld	a0,96(s3)
    80002f7c:	00000097          	auipc	ra,0x0
    80002f80:	d7a080e7          	jalr	-646(ra) # 80002cf6 <wakeup>
  acquire(&p->lock);
    80002f84:	854e                	mv	a0,s3
    80002f86:	ffffe097          	auipc	ra,0xffffe
    80002f8a:	c66080e7          	jalr	-922(ra) # 80000bec <acquire>
  p->xstate = status;
    80002f8e:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    80002f92:	4795                	li	a5,5
    80002f94:	02f9a823          	sw	a5,48(s3)
  cahnge_number_of_proc(p->parent_cpu,b);
    80002f98:	55fd                	li	a1,-1
    80002f9a:	0589a503          	lw	a0,88(s3)
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	ba2080e7          	jalr	-1118(ra) # 80001b40 <cahnge_number_of_proc>
  add_proc_to_list(p, ZOMBIEL, -1);
    80002fa6:	567d                	li	a2,-1
    80002fa8:	4585                	li	a1,1
    80002faa:	854e                	mv	a0,s3
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	ee6080e7          	jalr	-282(ra) # 80001e92 <add_proc_to_list>
  release(&wait_lock);
    80002fb4:	8526                	mv	a0,s1
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	cf0080e7          	jalr	-784(ra) # 80000ca6 <release>
  sched();
    80002fbe:	00000097          	auipc	ra,0x0
    80002fc2:	9fe080e7          	jalr	-1538(ra) # 800029bc <sched>
  panic("zombie exit");
    80002fc6:	00005517          	auipc	a0,0x5
    80002fca:	40250513          	addi	a0,a0,1026 # 800083c8 <digits+0x388>
    80002fce:	ffffd097          	auipc	ra,0xffffd
    80002fd2:	570080e7          	jalr	1392(ra) # 8000053e <panic>

0000000080002fd6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002fd6:	7179                	addi	sp,sp,-48
    80002fd8:	f406                	sd	ra,40(sp)
    80002fda:	f022                	sd	s0,32(sp)
    80002fdc:	ec26                	sd	s1,24(sp)
    80002fde:	e84a                	sd	s2,16(sp)
    80002fe0:	e44e                	sd	s3,8(sp)
    80002fe2:	1800                	addi	s0,sp,48
    80002fe4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002fe6:	0000e497          	auipc	s1,0xe
    80002fea:	5fa48493          	addi	s1,s1,1530 # 800115e0 <proc>
    80002fee:	00015997          	auipc	s3,0x15
    80002ff2:	9f298993          	addi	s3,s3,-1550 # 800179e0 <tickslock>
    acquire(&p->lock);
    80002ff6:	8526                	mv	a0,s1
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	bf4080e7          	jalr	-1036(ra) # 80000bec <acquire>
    if(p->pid == pid){
    80003000:	44bc                	lw	a5,72(s1)
    80003002:	01278d63          	beq	a5,s2,8000301c <kill+0x46>
        cahnge_number_of_proc(p->parent_cpu,a);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80003006:	8526                	mv	a0,s1
    80003008:	ffffe097          	auipc	ra,0xffffe
    8000300c:	c9e080e7          	jalr	-866(ra) # 80000ca6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80003010:	19048493          	addi	s1,s1,400
    80003014:	ff3491e3          	bne	s1,s3,80002ff6 <kill+0x20>
  }
  return -1;
    80003018:	557d                	li	a0,-1
    8000301a:	a829                	j	80003034 <kill+0x5e>
      p->killed = 1;
    8000301c:	4785                	li	a5,1
    8000301e:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    80003020:	5898                	lw	a4,48(s1)
    80003022:	4789                	li	a5,2
    80003024:	00f70f63          	beq	a4,a5,80003042 <kill+0x6c>
      release(&p->lock);
    80003028:	8526                	mv	a0,s1
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	c7c080e7          	jalr	-900(ra) # 80000ca6 <release>
      return 0;
    80003032:	4501                	li	a0,0
}
    80003034:	70a2                	ld	ra,40(sp)
    80003036:	7402                	ld	s0,32(sp)
    80003038:	64e2                	ld	s1,24(sp)
    8000303a:	6942                	ld	s2,16(sp)
    8000303c:	69a2                	ld	s3,8(sp)
    8000303e:	6145                	addi	sp,sp,48
    80003040:	8082                	ret
        p->state = RUNNABLE;
    80003042:	478d                	li	a5,3
    80003044:	d89c                	sw	a5,48(s1)
        remove_proc(p, SLEEPINGL);
    80003046:	4589                	li	a1,2
    80003048:	8526                	mv	a0,s1
    8000304a:	fffff097          	auipc	ra,0xfffff
    8000304e:	f26080e7          	jalr	-218(ra) # 80001f70 <remove_proc>
        add_proc_to_list(p, READYL, p->parent_cpu);
    80003052:	4cb0                	lw	a2,88(s1)
    80003054:	4581                	li	a1,0
    80003056:	8526                	mv	a0,s1
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	e3a080e7          	jalr	-454(ra) # 80001e92 <add_proc_to_list>
        cahnge_number_of_proc(p->parent_cpu,a);
    80003060:	4585                	li	a1,1
    80003062:	4ca8                	lw	a0,88(s1)
    80003064:	fffff097          	auipc	ra,0xfffff
    80003068:	adc080e7          	jalr	-1316(ra) # 80001b40 <cahnge_number_of_proc>
    8000306c:	bf75                	j	80003028 <kill+0x52>

000000008000306e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000306e:	7179                	addi	sp,sp,-48
    80003070:	f406                	sd	ra,40(sp)
    80003072:	f022                	sd	s0,32(sp)
    80003074:	ec26                	sd	s1,24(sp)
    80003076:	e84a                	sd	s2,16(sp)
    80003078:	e44e                	sd	s3,8(sp)
    8000307a:	e052                	sd	s4,0(sp)
    8000307c:	1800                	addi	s0,sp,48
    8000307e:	84aa                	mv	s1,a0
    80003080:	892e                	mv	s2,a1
    80003082:	89b2                	mv	s3,a2
    80003084:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	206080e7          	jalr	518(ra) # 8000228c <myproc>
  if(user_dst){
    8000308e:	c08d                	beqz	s1,800030b0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80003090:	86d2                	mv	a3,s4
    80003092:	864e                	mv	a2,s3
    80003094:	85ca                	mv	a1,s2
    80003096:	7d28                	ld	a0,120(a0)
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	5e8080e7          	jalr	1512(ra) # 80001680 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800030a0:	70a2                	ld	ra,40(sp)
    800030a2:	7402                	ld	s0,32(sp)
    800030a4:	64e2                	ld	s1,24(sp)
    800030a6:	6942                	ld	s2,16(sp)
    800030a8:	69a2                	ld	s3,8(sp)
    800030aa:	6a02                	ld	s4,0(sp)
    800030ac:	6145                	addi	sp,sp,48
    800030ae:	8082                	ret
    memmove((char *)dst, src, len);
    800030b0:	000a061b          	sext.w	a2,s4
    800030b4:	85ce                	mv	a1,s3
    800030b6:	854a                	mv	a0,s2
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	c96080e7          	jalr	-874(ra) # 80000d4e <memmove>
    return 0;
    800030c0:	8526                	mv	a0,s1
    800030c2:	bff9                	j	800030a0 <either_copyout+0x32>

00000000800030c4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800030c4:	7179                	addi	sp,sp,-48
    800030c6:	f406                	sd	ra,40(sp)
    800030c8:	f022                	sd	s0,32(sp)
    800030ca:	ec26                	sd	s1,24(sp)
    800030cc:	e84a                	sd	s2,16(sp)
    800030ce:	e44e                	sd	s3,8(sp)
    800030d0:	e052                	sd	s4,0(sp)
    800030d2:	1800                	addi	s0,sp,48
    800030d4:	892a                	mv	s2,a0
    800030d6:	84ae                	mv	s1,a1
    800030d8:	89b2                	mv	s3,a2
    800030da:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800030dc:	fffff097          	auipc	ra,0xfffff
    800030e0:	1b0080e7          	jalr	432(ra) # 8000228c <myproc>
  if(user_src){
    800030e4:	c08d                	beqz	s1,80003106 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800030e6:	86d2                	mv	a3,s4
    800030e8:	864e                	mv	a2,s3
    800030ea:	85ca                	mv	a1,s2
    800030ec:	7d28                	ld	a0,120(a0)
    800030ee:	ffffe097          	auipc	ra,0xffffe
    800030f2:	61e080e7          	jalr	1566(ra) # 8000170c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800030f6:	70a2                	ld	ra,40(sp)
    800030f8:	7402                	ld	s0,32(sp)
    800030fa:	64e2                	ld	s1,24(sp)
    800030fc:	6942                	ld	s2,16(sp)
    800030fe:	69a2                	ld	s3,8(sp)
    80003100:	6a02                	ld	s4,0(sp)
    80003102:	6145                	addi	sp,sp,48
    80003104:	8082                	ret
    memmove(dst, (char*)src, len);
    80003106:	000a061b          	sext.w	a2,s4
    8000310a:	85ce                	mv	a1,s3
    8000310c:	854a                	mv	a0,s2
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	c40080e7          	jalr	-960(ra) # 80000d4e <memmove>
    return 0;
    80003116:	8526                	mv	a0,s1
    80003118:	bff9                	j	800030f6 <either_copyin+0x32>

000000008000311a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000311a:	715d                	addi	sp,sp,-80
    8000311c:	e486                	sd	ra,72(sp)
    8000311e:	e0a2                	sd	s0,64(sp)
    80003120:	fc26                	sd	s1,56(sp)
    80003122:	f84a                	sd	s2,48(sp)
    80003124:	f44e                	sd	s3,40(sp)
    80003126:	f052                	sd	s4,32(sp)
    80003128:	ec56                	sd	s5,24(sp)
    8000312a:	e85a                	sd	s6,16(sp)
    8000312c:	e45e                	sd	s7,8(sp)
    8000312e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80003130:	00005517          	auipc	a0,0x5
    80003134:	f9850513          	addi	a0,a0,-104 # 800080c8 <digits+0x88>
    80003138:	ffffd097          	auipc	ra,0xffffd
    8000313c:	450080e7          	jalr	1104(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003140:	0000e497          	auipc	s1,0xe
    80003144:	62048493          	addi	s1,s1,1568 # 80011760 <proc+0x180>
    80003148:	00015917          	auipc	s2,0x15
    8000314c:	a1890913          	addi	s2,s2,-1512 # 80017b60 <bcache+0x168>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003150:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80003152:	00005997          	auipc	s3,0x5
    80003156:	28698993          	addi	s3,s3,646 # 800083d8 <digits+0x398>
    printf("%d %s %s", p->pid, state, p->name);
    8000315a:	00005a97          	auipc	s5,0x5
    8000315e:	286a8a93          	addi	s5,s5,646 # 800083e0 <digits+0x3a0>
    printf("\n");
    80003162:	00005a17          	auipc	s4,0x5
    80003166:	f66a0a13          	addi	s4,s4,-154 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000316a:	00005b97          	auipc	s7,0x5
    8000316e:	2aeb8b93          	addi	s7,s7,686 # 80008418 <states.1912>
    80003172:	a00d                	j	80003194 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80003174:	ec86a583          	lw	a1,-312(a3)
    80003178:	8556                	mv	a0,s5
    8000317a:	ffffd097          	auipc	ra,0xffffd
    8000317e:	40e080e7          	jalr	1038(ra) # 80000588 <printf>
    printf("\n");
    80003182:	8552                	mv	a0,s4
    80003184:	ffffd097          	auipc	ra,0xffffd
    80003188:	404080e7          	jalr	1028(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000318c:	19048493          	addi	s1,s1,400
    80003190:	03248163          	beq	s1,s2,800031b2 <procdump+0x98>
    if(p->state == UNUSED)
    80003194:	86a6                	mv	a3,s1
    80003196:	eb04a783          	lw	a5,-336(s1)
    8000319a:	dbed                	beqz	a5,8000318c <procdump+0x72>
      state = "???";
    8000319c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000319e:	fcfb6be3          	bltu	s6,a5,80003174 <procdump+0x5a>
    800031a2:	1782                	slli	a5,a5,0x20
    800031a4:	9381                	srli	a5,a5,0x20
    800031a6:	078e                	slli	a5,a5,0x3
    800031a8:	97de                	add	a5,a5,s7
    800031aa:	6390                	ld	a2,0(a5)
    800031ac:	f661                	bnez	a2,80003174 <procdump+0x5a>
      state = "???";
    800031ae:	864e                	mv	a2,s3
    800031b0:	b7d1                	j	80003174 <procdump+0x5a>
  }
}
    800031b2:	60a6                	ld	ra,72(sp)
    800031b4:	6406                	ld	s0,64(sp)
    800031b6:	74e2                	ld	s1,56(sp)
    800031b8:	7942                	ld	s2,48(sp)
    800031ba:	79a2                	ld	s3,40(sp)
    800031bc:	7a02                	ld	s4,32(sp)
    800031be:	6ae2                	ld	s5,24(sp)
    800031c0:	6b42                	ld	s6,16(sp)
    800031c2:	6ba2                	ld	s7,8(sp)
    800031c4:	6161                	addi	sp,sp,80
    800031c6:	8082                	ret

00000000800031c8 <swtch>:
    800031c8:	00153023          	sd	ra,0(a0)
    800031cc:	00253423          	sd	sp,8(a0)
    800031d0:	e900                	sd	s0,16(a0)
    800031d2:	ed04                	sd	s1,24(a0)
    800031d4:	03253023          	sd	s2,32(a0)
    800031d8:	03353423          	sd	s3,40(a0)
    800031dc:	03453823          	sd	s4,48(a0)
    800031e0:	03553c23          	sd	s5,56(a0)
    800031e4:	05653023          	sd	s6,64(a0)
    800031e8:	05753423          	sd	s7,72(a0)
    800031ec:	05853823          	sd	s8,80(a0)
    800031f0:	05953c23          	sd	s9,88(a0)
    800031f4:	07a53023          	sd	s10,96(a0)
    800031f8:	07b53423          	sd	s11,104(a0)
    800031fc:	0005b083          	ld	ra,0(a1)
    80003200:	0085b103          	ld	sp,8(a1)
    80003204:	6980                	ld	s0,16(a1)
    80003206:	6d84                	ld	s1,24(a1)
    80003208:	0205b903          	ld	s2,32(a1)
    8000320c:	0285b983          	ld	s3,40(a1)
    80003210:	0305ba03          	ld	s4,48(a1)
    80003214:	0385ba83          	ld	s5,56(a1)
    80003218:	0405bb03          	ld	s6,64(a1)
    8000321c:	0485bb83          	ld	s7,72(a1)
    80003220:	0505bc03          	ld	s8,80(a1)
    80003224:	0585bc83          	ld	s9,88(a1)
    80003228:	0605bd03          	ld	s10,96(a1)
    8000322c:	0685bd83          	ld	s11,104(a1)
    80003230:	8082                	ret

0000000080003232 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003232:	1141                	addi	sp,sp,-16
    80003234:	e406                	sd	ra,8(sp)
    80003236:	e022                	sd	s0,0(sp)
    80003238:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000323a:	00005597          	auipc	a1,0x5
    8000323e:	20e58593          	addi	a1,a1,526 # 80008448 <states.1912+0x30>
    80003242:	00014517          	auipc	a0,0x14
    80003246:	79e50513          	addi	a0,a0,1950 # 800179e0 <tickslock>
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	90a080e7          	jalr	-1782(ra) # 80000b54 <initlock>
}
    80003252:	60a2                	ld	ra,8(sp)
    80003254:	6402                	ld	s0,0(sp)
    80003256:	0141                	addi	sp,sp,16
    80003258:	8082                	ret

000000008000325a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000325a:	1141                	addi	sp,sp,-16
    8000325c:	e422                	sd	s0,8(sp)
    8000325e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003260:	00003797          	auipc	a5,0x3
    80003264:	4d078793          	addi	a5,a5,1232 # 80006730 <kernelvec>
    80003268:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000326c:	6422                	ld	s0,8(sp)
    8000326e:	0141                	addi	sp,sp,16
    80003270:	8082                	ret

0000000080003272 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003272:	1141                	addi	sp,sp,-16
    80003274:	e406                	sd	ra,8(sp)
    80003276:	e022                	sd	s0,0(sp)
    80003278:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000327a:	fffff097          	auipc	ra,0xfffff
    8000327e:	012080e7          	jalr	18(ra) # 8000228c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003282:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003286:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003288:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000328c:	00004617          	auipc	a2,0x4
    80003290:	d7460613          	addi	a2,a2,-652 # 80007000 <_trampoline>
    80003294:	00004697          	auipc	a3,0x4
    80003298:	d6c68693          	addi	a3,a3,-660 # 80007000 <_trampoline>
    8000329c:	8e91                	sub	a3,a3,a2
    8000329e:	040007b7          	lui	a5,0x4000
    800032a2:	17fd                	addi	a5,a5,-1
    800032a4:	07b2                	slli	a5,a5,0xc
    800032a6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800032a8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800032ac:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800032ae:	180026f3          	csrr	a3,satp
    800032b2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800032b4:	6158                	ld	a4,128(a0)
    800032b6:	7534                	ld	a3,104(a0)
    800032b8:	6585                	lui	a1,0x1
    800032ba:	96ae                	add	a3,a3,a1
    800032bc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800032be:	6158                	ld	a4,128(a0)
    800032c0:	00000697          	auipc	a3,0x0
    800032c4:	13868693          	addi	a3,a3,312 # 800033f8 <usertrap>
    800032c8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800032ca:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800032cc:	8692                	mv	a3,tp
    800032ce:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032d0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800032d4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800032d8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032dc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800032e0:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032e2:	6f18                	ld	a4,24(a4)
    800032e4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800032e8:	7d2c                	ld	a1,120(a0)
    800032ea:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800032ec:	00004717          	auipc	a4,0x4
    800032f0:	da470713          	addi	a4,a4,-604 # 80007090 <userret>
    800032f4:	8f11                	sub	a4,a4,a2
    800032f6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800032f8:	577d                	li	a4,-1
    800032fa:	177e                	slli	a4,a4,0x3f
    800032fc:	8dd9                	or	a1,a1,a4
    800032fe:	02000537          	lui	a0,0x2000
    80003302:	157d                	addi	a0,a0,-1
    80003304:	0536                	slli	a0,a0,0xd
    80003306:	9782                	jalr	a5
}
    80003308:	60a2                	ld	ra,8(sp)
    8000330a:	6402                	ld	s0,0(sp)
    8000330c:	0141                	addi	sp,sp,16
    8000330e:	8082                	ret

0000000080003310 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003310:	1101                	addi	sp,sp,-32
    80003312:	ec06                	sd	ra,24(sp)
    80003314:	e822                	sd	s0,16(sp)
    80003316:	e426                	sd	s1,8(sp)
    80003318:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000331a:	00014497          	auipc	s1,0x14
    8000331e:	6c648493          	addi	s1,s1,1734 # 800179e0 <tickslock>
    80003322:	8526                	mv	a0,s1
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	8c8080e7          	jalr	-1848(ra) # 80000bec <acquire>
  ticks++;
    8000332c:	00006517          	auipc	a0,0x6
    80003330:	d4450513          	addi	a0,a0,-700 # 80009070 <ticks>
    80003334:	411c                	lw	a5,0(a0)
    80003336:	2785                	addiw	a5,a5,1
    80003338:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	9bc080e7          	jalr	-1604(ra) # 80002cf6 <wakeup>
  release(&tickslock);
    80003342:	8526                	mv	a0,s1
    80003344:	ffffe097          	auipc	ra,0xffffe
    80003348:	962080e7          	jalr	-1694(ra) # 80000ca6 <release>
}
    8000334c:	60e2                	ld	ra,24(sp)
    8000334e:	6442                	ld	s0,16(sp)
    80003350:	64a2                	ld	s1,8(sp)
    80003352:	6105                	addi	sp,sp,32
    80003354:	8082                	ret

0000000080003356 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003356:	1101                	addi	sp,sp,-32
    80003358:	ec06                	sd	ra,24(sp)
    8000335a:	e822                	sd	s0,16(sp)
    8000335c:	e426                	sd	s1,8(sp)
    8000335e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003360:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003364:	00074d63          	bltz	a4,8000337e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003368:	57fd                	li	a5,-1
    8000336a:	17fe                	slli	a5,a5,0x3f
    8000336c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000336e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003370:	06f70363          	beq	a4,a5,800033d6 <devintr+0x80>
  }
}
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	64a2                	ld	s1,8(sp)
    8000337a:	6105                	addi	sp,sp,32
    8000337c:	8082                	ret
     (scause & 0xff) == 9){
    8000337e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003382:	46a5                	li	a3,9
    80003384:	fed792e3          	bne	a5,a3,80003368 <devintr+0x12>
    int irq = plic_claim();
    80003388:	00003097          	auipc	ra,0x3
    8000338c:	4b0080e7          	jalr	1200(ra) # 80006838 <plic_claim>
    80003390:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003392:	47a9                	li	a5,10
    80003394:	02f50763          	beq	a0,a5,800033c2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003398:	4785                	li	a5,1
    8000339a:	02f50963          	beq	a0,a5,800033cc <devintr+0x76>
    return 1;
    8000339e:	4505                	li	a0,1
    } else if(irq){
    800033a0:	d8f1                	beqz	s1,80003374 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800033a2:	85a6                	mv	a1,s1
    800033a4:	00005517          	auipc	a0,0x5
    800033a8:	0ac50513          	addi	a0,a0,172 # 80008450 <states.1912+0x38>
    800033ac:	ffffd097          	auipc	ra,0xffffd
    800033b0:	1dc080e7          	jalr	476(ra) # 80000588 <printf>
      plic_complete(irq);
    800033b4:	8526                	mv	a0,s1
    800033b6:	00003097          	auipc	ra,0x3
    800033ba:	4a6080e7          	jalr	1190(ra) # 8000685c <plic_complete>
    return 1;
    800033be:	4505                	li	a0,1
    800033c0:	bf55                	j	80003374 <devintr+0x1e>
      uartintr();
    800033c2:	ffffd097          	auipc	ra,0xffffd
    800033c6:	5e6080e7          	jalr	1510(ra) # 800009a8 <uartintr>
    800033ca:	b7ed                	j	800033b4 <devintr+0x5e>
      virtio_disk_intr();
    800033cc:	00004097          	auipc	ra,0x4
    800033d0:	970080e7          	jalr	-1680(ra) # 80006d3c <virtio_disk_intr>
    800033d4:	b7c5                	j	800033b4 <devintr+0x5e>
    if(cpuid() == 0){
    800033d6:	fffff097          	auipc	ra,0xfffff
    800033da:	e82080e7          	jalr	-382(ra) # 80002258 <cpuid>
    800033de:	c901                	beqz	a0,800033ee <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800033e0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800033e4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800033e6:	14479073          	csrw	sip,a5
    return 2;
    800033ea:	4509                	li	a0,2
    800033ec:	b761                	j	80003374 <devintr+0x1e>
      clockintr();
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	f22080e7          	jalr	-222(ra) # 80003310 <clockintr>
    800033f6:	b7ed                	j	800033e0 <devintr+0x8a>

00000000800033f8 <usertrap>:
{
    800033f8:	1101                	addi	sp,sp,-32
    800033fa:	ec06                	sd	ra,24(sp)
    800033fc:	e822                	sd	s0,16(sp)
    800033fe:	e426                	sd	s1,8(sp)
    80003400:	e04a                	sd	s2,0(sp)
    80003402:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003404:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003408:	1007f793          	andi	a5,a5,256
    8000340c:	e3ad                	bnez	a5,8000346e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000340e:	00003797          	auipc	a5,0x3
    80003412:	32278793          	addi	a5,a5,802 # 80006730 <kernelvec>
    80003416:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000341a:	fffff097          	auipc	ra,0xfffff
    8000341e:	e72080e7          	jalr	-398(ra) # 8000228c <myproc>
    80003422:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003424:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003426:	14102773          	csrr	a4,sepc
    8000342a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000342c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003430:	47a1                	li	a5,8
    80003432:	04f71c63          	bne	a4,a5,8000348a <usertrap+0x92>
    if(p->killed)
    80003436:	413c                	lw	a5,64(a0)
    80003438:	e3b9                	bnez	a5,8000347e <usertrap+0x86>
    p->trapframe->epc += 4;
    8000343a:	60d8                	ld	a4,128(s1)
    8000343c:	6f1c                	ld	a5,24(a4)
    8000343e:	0791                	addi	a5,a5,4
    80003440:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003442:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003446:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000344a:	10079073          	csrw	sstatus,a5
    syscall();
    8000344e:	00000097          	auipc	ra,0x0
    80003452:	2e0080e7          	jalr	736(ra) # 8000372e <syscall>
  if(p->killed)
    80003456:	40bc                	lw	a5,64(s1)
    80003458:	ebc1                	bnez	a5,800034e8 <usertrap+0xf0>
  usertrapret();
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	e18080e7          	jalr	-488(ra) # 80003272 <usertrapret>
}
    80003462:	60e2                	ld	ra,24(sp)
    80003464:	6442                	ld	s0,16(sp)
    80003466:	64a2                	ld	s1,8(sp)
    80003468:	6902                	ld	s2,0(sp)
    8000346a:	6105                	addi	sp,sp,32
    8000346c:	8082                	ret
    panic("usertrap: not from user mode");
    8000346e:	00005517          	auipc	a0,0x5
    80003472:	00250513          	addi	a0,a0,2 # 80008470 <states.1912+0x58>
    80003476:	ffffd097          	auipc	ra,0xffffd
    8000347a:	0c8080e7          	jalr	200(ra) # 8000053e <panic>
      exit(-1);
    8000347e:	557d                	li	a0,-1
    80003480:	00000097          	auipc	ra,0x0
    80003484:	a64080e7          	jalr	-1436(ra) # 80002ee4 <exit>
    80003488:	bf4d                	j	8000343a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	ecc080e7          	jalr	-308(ra) # 80003356 <devintr>
    80003492:	892a                	mv	s2,a0
    80003494:	c501                	beqz	a0,8000349c <usertrap+0xa4>
  if(p->killed)
    80003496:	40bc                	lw	a5,64(s1)
    80003498:	c3a1                	beqz	a5,800034d8 <usertrap+0xe0>
    8000349a:	a815                	j	800034ce <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000349c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800034a0:	44b0                	lw	a2,72(s1)
    800034a2:	00005517          	auipc	a0,0x5
    800034a6:	fee50513          	addi	a0,a0,-18 # 80008490 <states.1912+0x78>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	0de080e7          	jalr	222(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034b2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800034b6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800034ba:	00005517          	auipc	a0,0x5
    800034be:	00650513          	addi	a0,a0,6 # 800084c0 <states.1912+0xa8>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	0c6080e7          	jalr	198(ra) # 80000588 <printf>
    p->killed = 1;
    800034ca:	4785                	li	a5,1
    800034cc:	c0bc                	sw	a5,64(s1)
    exit(-1);
    800034ce:	557d                	li	a0,-1
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	a14080e7          	jalr	-1516(ra) # 80002ee4 <exit>
  if(which_dev == 2)
    800034d8:	4789                	li	a5,2
    800034da:	f8f910e3          	bne	s2,a5,8000345a <usertrap+0x62>
    yield();
    800034de:	fffff097          	auipc	ra,0xfffff
    800034e2:	5d4080e7          	jalr	1492(ra) # 80002ab2 <yield>
    800034e6:	bf95                	j	8000345a <usertrap+0x62>
  int which_dev = 0;
    800034e8:	4901                	li	s2,0
    800034ea:	b7d5                	j	800034ce <usertrap+0xd6>

00000000800034ec <kerneltrap>:
{
    800034ec:	7179                	addi	sp,sp,-48
    800034ee:	f406                	sd	ra,40(sp)
    800034f0:	f022                	sd	s0,32(sp)
    800034f2:	ec26                	sd	s1,24(sp)
    800034f4:	e84a                	sd	s2,16(sp)
    800034f6:	e44e                	sd	s3,8(sp)
    800034f8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034fa:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034fe:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003502:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003506:	1004f793          	andi	a5,s1,256
    8000350a:	cb85                	beqz	a5,8000353a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000350c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003510:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003512:	ef85                	bnez	a5,8000354a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003514:	00000097          	auipc	ra,0x0
    80003518:	e42080e7          	jalr	-446(ra) # 80003356 <devintr>
    8000351c:	cd1d                	beqz	a0,8000355a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000351e:	4789                	li	a5,2
    80003520:	06f50a63          	beq	a0,a5,80003594 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003524:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003528:	10049073          	csrw	sstatus,s1
}
    8000352c:	70a2                	ld	ra,40(sp)
    8000352e:	7402                	ld	s0,32(sp)
    80003530:	64e2                	ld	s1,24(sp)
    80003532:	6942                	ld	s2,16(sp)
    80003534:	69a2                	ld	s3,8(sp)
    80003536:	6145                	addi	sp,sp,48
    80003538:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000353a:	00005517          	auipc	a0,0x5
    8000353e:	fa650513          	addi	a0,a0,-90 # 800084e0 <states.1912+0xc8>
    80003542:	ffffd097          	auipc	ra,0xffffd
    80003546:	ffc080e7          	jalr	-4(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000354a:	00005517          	auipc	a0,0x5
    8000354e:	fbe50513          	addi	a0,a0,-66 # 80008508 <states.1912+0xf0>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	fec080e7          	jalr	-20(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000355a:	85ce                	mv	a1,s3
    8000355c:	00005517          	auipc	a0,0x5
    80003560:	fcc50513          	addi	a0,a0,-52 # 80008528 <states.1912+0x110>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000356c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003570:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003574:	00005517          	auipc	a0,0x5
    80003578:	fc450513          	addi	a0,a0,-60 # 80008538 <states.1912+0x120>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	00c080e7          	jalr	12(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003584:	00005517          	auipc	a0,0x5
    80003588:	fcc50513          	addi	a0,a0,-52 # 80008550 <states.1912+0x138>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	fb2080e7          	jalr	-78(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003594:	fffff097          	auipc	ra,0xfffff
    80003598:	cf8080e7          	jalr	-776(ra) # 8000228c <myproc>
    8000359c:	d541                	beqz	a0,80003524 <kerneltrap+0x38>
    8000359e:	fffff097          	auipc	ra,0xfffff
    800035a2:	cee080e7          	jalr	-786(ra) # 8000228c <myproc>
    800035a6:	5918                	lw	a4,48(a0)
    800035a8:	4791                	li	a5,4
    800035aa:	f6f71de3          	bne	a4,a5,80003524 <kerneltrap+0x38>
    yield();
    800035ae:	fffff097          	auipc	ra,0xfffff
    800035b2:	504080e7          	jalr	1284(ra) # 80002ab2 <yield>
    800035b6:	b7bd                	j	80003524 <kerneltrap+0x38>

00000000800035b8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800035b8:	1101                	addi	sp,sp,-32
    800035ba:	ec06                	sd	ra,24(sp)
    800035bc:	e822                	sd	s0,16(sp)
    800035be:	e426                	sd	s1,8(sp)
    800035c0:	1000                	addi	s0,sp,32
    800035c2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800035c4:	fffff097          	auipc	ra,0xfffff
    800035c8:	cc8080e7          	jalr	-824(ra) # 8000228c <myproc>
  switch (n) {
    800035cc:	4795                	li	a5,5
    800035ce:	0497e163          	bltu	a5,s1,80003610 <argraw+0x58>
    800035d2:	048a                	slli	s1,s1,0x2
    800035d4:	00005717          	auipc	a4,0x5
    800035d8:	fb470713          	addi	a4,a4,-76 # 80008588 <states.1912+0x170>
    800035dc:	94ba                	add	s1,s1,a4
    800035de:	409c                	lw	a5,0(s1)
    800035e0:	97ba                	add	a5,a5,a4
    800035e2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800035e4:	615c                	ld	a5,128(a0)
    800035e6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800035e8:	60e2                	ld	ra,24(sp)
    800035ea:	6442                	ld	s0,16(sp)
    800035ec:	64a2                	ld	s1,8(sp)
    800035ee:	6105                	addi	sp,sp,32
    800035f0:	8082                	ret
    return p->trapframe->a1;
    800035f2:	615c                	ld	a5,128(a0)
    800035f4:	7fa8                	ld	a0,120(a5)
    800035f6:	bfcd                	j	800035e8 <argraw+0x30>
    return p->trapframe->a2;
    800035f8:	615c                	ld	a5,128(a0)
    800035fa:	63c8                	ld	a0,128(a5)
    800035fc:	b7f5                	j	800035e8 <argraw+0x30>
    return p->trapframe->a3;
    800035fe:	615c                	ld	a5,128(a0)
    80003600:	67c8                	ld	a0,136(a5)
    80003602:	b7dd                	j	800035e8 <argraw+0x30>
    return p->trapframe->a4;
    80003604:	615c                	ld	a5,128(a0)
    80003606:	6bc8                	ld	a0,144(a5)
    80003608:	b7c5                	j	800035e8 <argraw+0x30>
    return p->trapframe->a5;
    8000360a:	615c                	ld	a5,128(a0)
    8000360c:	6fc8                	ld	a0,152(a5)
    8000360e:	bfe9                	j	800035e8 <argraw+0x30>
  panic("argraw");
    80003610:	00005517          	auipc	a0,0x5
    80003614:	f5050513          	addi	a0,a0,-176 # 80008560 <states.1912+0x148>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	f26080e7          	jalr	-218(ra) # 8000053e <panic>

0000000080003620 <fetchaddr>:
{
    80003620:	1101                	addi	sp,sp,-32
    80003622:	ec06                	sd	ra,24(sp)
    80003624:	e822                	sd	s0,16(sp)
    80003626:	e426                	sd	s1,8(sp)
    80003628:	e04a                	sd	s2,0(sp)
    8000362a:	1000                	addi	s0,sp,32
    8000362c:	84aa                	mv	s1,a0
    8000362e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003630:	fffff097          	auipc	ra,0xfffff
    80003634:	c5c080e7          	jalr	-932(ra) # 8000228c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003638:	793c                	ld	a5,112(a0)
    8000363a:	02f4f863          	bgeu	s1,a5,8000366a <fetchaddr+0x4a>
    8000363e:	00848713          	addi	a4,s1,8
    80003642:	02e7e663          	bltu	a5,a4,8000366e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003646:	46a1                	li	a3,8
    80003648:	8626                	mv	a2,s1
    8000364a:	85ca                	mv	a1,s2
    8000364c:	7d28                	ld	a0,120(a0)
    8000364e:	ffffe097          	auipc	ra,0xffffe
    80003652:	0be080e7          	jalr	190(ra) # 8000170c <copyin>
    80003656:	00a03533          	snez	a0,a0
    8000365a:	40a00533          	neg	a0,a0
}
    8000365e:	60e2                	ld	ra,24(sp)
    80003660:	6442                	ld	s0,16(sp)
    80003662:	64a2                	ld	s1,8(sp)
    80003664:	6902                	ld	s2,0(sp)
    80003666:	6105                	addi	sp,sp,32
    80003668:	8082                	ret
    return -1;
    8000366a:	557d                	li	a0,-1
    8000366c:	bfcd                	j	8000365e <fetchaddr+0x3e>
    8000366e:	557d                	li	a0,-1
    80003670:	b7fd                	j	8000365e <fetchaddr+0x3e>

0000000080003672 <fetchstr>:
{
    80003672:	7179                	addi	sp,sp,-48
    80003674:	f406                	sd	ra,40(sp)
    80003676:	f022                	sd	s0,32(sp)
    80003678:	ec26                	sd	s1,24(sp)
    8000367a:	e84a                	sd	s2,16(sp)
    8000367c:	e44e                	sd	s3,8(sp)
    8000367e:	1800                	addi	s0,sp,48
    80003680:	892a                	mv	s2,a0
    80003682:	84ae                	mv	s1,a1
    80003684:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003686:	fffff097          	auipc	ra,0xfffff
    8000368a:	c06080e7          	jalr	-1018(ra) # 8000228c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000368e:	86ce                	mv	a3,s3
    80003690:	864a                	mv	a2,s2
    80003692:	85a6                	mv	a1,s1
    80003694:	7d28                	ld	a0,120(a0)
    80003696:	ffffe097          	auipc	ra,0xffffe
    8000369a:	102080e7          	jalr	258(ra) # 80001798 <copyinstr>
  if(err < 0)
    8000369e:	00054763          	bltz	a0,800036ac <fetchstr+0x3a>
  return strlen(buf);
    800036a2:	8526                	mv	a0,s1
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	7ce080e7          	jalr	1998(ra) # 80000e72 <strlen>
}
    800036ac:	70a2                	ld	ra,40(sp)
    800036ae:	7402                	ld	s0,32(sp)
    800036b0:	64e2                	ld	s1,24(sp)
    800036b2:	6942                	ld	s2,16(sp)
    800036b4:	69a2                	ld	s3,8(sp)
    800036b6:	6145                	addi	sp,sp,48
    800036b8:	8082                	ret

00000000800036ba <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800036ba:	1101                	addi	sp,sp,-32
    800036bc:	ec06                	sd	ra,24(sp)
    800036be:	e822                	sd	s0,16(sp)
    800036c0:	e426                	sd	s1,8(sp)
    800036c2:	1000                	addi	s0,sp,32
    800036c4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	ef2080e7          	jalr	-270(ra) # 800035b8 <argraw>
    800036ce:	c088                	sw	a0,0(s1)
  return 0;
}
    800036d0:	4501                	li	a0,0
    800036d2:	60e2                	ld	ra,24(sp)
    800036d4:	6442                	ld	s0,16(sp)
    800036d6:	64a2                	ld	s1,8(sp)
    800036d8:	6105                	addi	sp,sp,32
    800036da:	8082                	ret

00000000800036dc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800036dc:	1101                	addi	sp,sp,-32
    800036de:	ec06                	sd	ra,24(sp)
    800036e0:	e822                	sd	s0,16(sp)
    800036e2:	e426                	sd	s1,8(sp)
    800036e4:	1000                	addi	s0,sp,32
    800036e6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	ed0080e7          	jalr	-304(ra) # 800035b8 <argraw>
    800036f0:	e088                	sd	a0,0(s1)
  return 0;
}
    800036f2:	4501                	li	a0,0
    800036f4:	60e2                	ld	ra,24(sp)
    800036f6:	6442                	ld	s0,16(sp)
    800036f8:	64a2                	ld	s1,8(sp)
    800036fa:	6105                	addi	sp,sp,32
    800036fc:	8082                	ret

00000000800036fe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800036fe:	1101                	addi	sp,sp,-32
    80003700:	ec06                	sd	ra,24(sp)
    80003702:	e822                	sd	s0,16(sp)
    80003704:	e426                	sd	s1,8(sp)
    80003706:	e04a                	sd	s2,0(sp)
    80003708:	1000                	addi	s0,sp,32
    8000370a:	84ae                	mv	s1,a1
    8000370c:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000370e:	00000097          	auipc	ra,0x0
    80003712:	eaa080e7          	jalr	-342(ra) # 800035b8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003716:	864a                	mv	a2,s2
    80003718:	85a6                	mv	a1,s1
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	f58080e7          	jalr	-168(ra) # 80003672 <fetchstr>
}
    80003722:	60e2                	ld	ra,24(sp)
    80003724:	6442                	ld	s0,16(sp)
    80003726:	64a2                	ld	s1,8(sp)
    80003728:	6902                	ld	s2,0(sp)
    8000372a:	6105                	addi	sp,sp,32
    8000372c:	8082                	ret

000000008000372e <syscall>:
[SYS_set_cpu] sys_set_cpu,
};

void
syscall(void)
{
    8000372e:	1101                	addi	sp,sp,-32
    80003730:	ec06                	sd	ra,24(sp)
    80003732:	e822                	sd	s0,16(sp)
    80003734:	e426                	sd	s1,8(sp)
    80003736:	e04a                	sd	s2,0(sp)
    80003738:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000373a:	fffff097          	auipc	ra,0xfffff
    8000373e:	b52080e7          	jalr	-1198(ra) # 8000228c <myproc>
    80003742:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003744:	08053903          	ld	s2,128(a0)
    80003748:	0a893783          	ld	a5,168(s2)
    8000374c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003750:	37fd                	addiw	a5,a5,-1
    80003752:	4759                	li	a4,22
    80003754:	00f76f63          	bltu	a4,a5,80003772 <syscall+0x44>
    80003758:	00369713          	slli	a4,a3,0x3
    8000375c:	00005797          	auipc	a5,0x5
    80003760:	e4478793          	addi	a5,a5,-444 # 800085a0 <syscalls>
    80003764:	97ba                	add	a5,a5,a4
    80003766:	639c                	ld	a5,0(a5)
    80003768:	c789                	beqz	a5,80003772 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000376a:	9782                	jalr	a5
    8000376c:	06a93823          	sd	a0,112(s2)
    80003770:	a839                	j	8000378e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003772:	18048613          	addi	a2,s1,384
    80003776:	44ac                	lw	a1,72(s1)
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	df050513          	addi	a0,a0,-528 # 80008568 <states.1912+0x150>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	e08080e7          	jalr	-504(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003788:	60dc                	ld	a5,128(s1)
    8000378a:	577d                	li	a4,-1
    8000378c:	fbb8                	sd	a4,112(a5)
  }
}
    8000378e:	60e2                	ld	ra,24(sp)
    80003790:	6442                	ld	s0,16(sp)
    80003792:	64a2                	ld	s1,8(sp)
    80003794:	6902                	ld	s2,0(sp)
    80003796:	6105                	addi	sp,sp,32
    80003798:	8082                	ret

000000008000379a <sys_set_cpu>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_set_cpu(void)
{
    8000379a:	1101                	addi	sp,sp,-32
    8000379c:	ec06                	sd	ra,24(sp)
    8000379e:	e822                	sd	s0,16(sp)
    800037a0:	1000                	addi	s0,sp,32
  int a;

  if(argint(0, &a) < 0)
    800037a2:	fec40593          	addi	a1,s0,-20
    800037a6:	4501                	li	a0,0
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	f12080e7          	jalr	-238(ra) # 800036ba <argint>
    800037b0:	87aa                	mv	a5,a0
    return -1;
    800037b2:	557d                	li	a0,-1
  if(argint(0, &a) < 0)
    800037b4:	0007c863          	bltz	a5,800037c4 <sys_set_cpu+0x2a>
  return set_cpu(a);
    800037b8:	fec42503          	lw	a0,-20(s0)
    800037bc:	fffff097          	auipc	ra,0xfffff
    800037c0:	340080e7          	jalr	832(ra) # 80002afc <set_cpu>
}
    800037c4:	60e2                	ld	ra,24(sp)
    800037c6:	6442                	ld	s0,16(sp)
    800037c8:	6105                	addi	sp,sp,32
    800037ca:	8082                	ret

00000000800037cc <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800037cc:	1141                	addi	sp,sp,-16
    800037ce:	e406                	sd	ra,8(sp)
    800037d0:	e022                	sd	s0,0(sp)
    800037d2:	0800                	addi	s0,sp,16
  return get_cpu();
    800037d4:	fffff097          	auipc	ra,0xfffff
    800037d8:	af8080e7          	jalr	-1288(ra) # 800022cc <get_cpu>
}
    800037dc:	60a2                	ld	ra,8(sp)
    800037de:	6402                	ld	s0,0(sp)
    800037e0:	0141                	addi	sp,sp,16
    800037e2:	8082                	ret

00000000800037e4 <sys_exit>:

uint64
sys_exit(void)
{
    800037e4:	1101                	addi	sp,sp,-32
    800037e6:	ec06                	sd	ra,24(sp)
    800037e8:	e822                	sd	s0,16(sp)
    800037ea:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800037ec:	fec40593          	addi	a1,s0,-20
    800037f0:	4501                	li	a0,0
    800037f2:	00000097          	auipc	ra,0x0
    800037f6:	ec8080e7          	jalr	-312(ra) # 800036ba <argint>
    return -1;
    800037fa:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800037fc:	00054963          	bltz	a0,8000380e <sys_exit+0x2a>
  exit(n);
    80003800:	fec42503          	lw	a0,-20(s0)
    80003804:	fffff097          	auipc	ra,0xfffff
    80003808:	6e0080e7          	jalr	1760(ra) # 80002ee4 <exit>
  return 0;  // not reached
    8000380c:	4781                	li	a5,0
}
    8000380e:	853e                	mv	a0,a5
    80003810:	60e2                	ld	ra,24(sp)
    80003812:	6442                	ld	s0,16(sp)
    80003814:	6105                	addi	sp,sp,32
    80003816:	8082                	ret

0000000080003818 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003818:	1141                	addi	sp,sp,-16
    8000381a:	e406                	sd	ra,8(sp)
    8000381c:	e022                	sd	s0,0(sp)
    8000381e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003820:	fffff097          	auipc	ra,0xfffff
    80003824:	a6c080e7          	jalr	-1428(ra) # 8000228c <myproc>
}
    80003828:	4528                	lw	a0,72(a0)
    8000382a:	60a2                	ld	ra,8(sp)
    8000382c:	6402                	ld	s0,0(sp)
    8000382e:	0141                	addi	sp,sp,16
    80003830:	8082                	ret

0000000080003832 <sys_fork>:

uint64
sys_fork(void)
{
    80003832:	1141                	addi	sp,sp,-16
    80003834:	e406                	sd	ra,8(sp)
    80003836:	e022                	sd	s0,0(sp)
    80003838:	0800                	addi	s0,sp,16
  return fork();
    8000383a:	fffff097          	auipc	ra,0xfffff
    8000383e:	e96080e7          	jalr	-362(ra) # 800026d0 <fork>
}
    80003842:	60a2                	ld	ra,8(sp)
    80003844:	6402                	ld	s0,0(sp)
    80003846:	0141                	addi	sp,sp,16
    80003848:	8082                	ret

000000008000384a <sys_wait>:

uint64
sys_wait(void)
{
    8000384a:	1101                	addi	sp,sp,-32
    8000384c:	ec06                	sd	ra,24(sp)
    8000384e:	e822                	sd	s0,16(sp)
    80003850:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003852:	fe840593          	addi	a1,s0,-24
    80003856:	4501                	li	a0,0
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	e84080e7          	jalr	-380(ra) # 800036dc <argaddr>
    80003860:	87aa                	mv	a5,a0
    return -1;
    80003862:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003864:	0007c863          	bltz	a5,80003874 <sys_wait+0x2a>
  return wait(p);
    80003868:	fe843503          	ld	a0,-24(s0)
    8000386c:	fffff097          	auipc	ra,0xfffff
    80003870:	362080e7          	jalr	866(ra) # 80002bce <wait>
}
    80003874:	60e2                	ld	ra,24(sp)
    80003876:	6442                	ld	s0,16(sp)
    80003878:	6105                	addi	sp,sp,32
    8000387a:	8082                	ret

000000008000387c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000387c:	7179                	addi	sp,sp,-48
    8000387e:	f406                	sd	ra,40(sp)
    80003880:	f022                	sd	s0,32(sp)
    80003882:	ec26                	sd	s1,24(sp)
    80003884:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003886:	fdc40593          	addi	a1,s0,-36
    8000388a:	4501                	li	a0,0
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	e2e080e7          	jalr	-466(ra) # 800036ba <argint>
    80003894:	87aa                	mv	a5,a0
    return -1;
    80003896:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003898:	0207c063          	bltz	a5,800038b8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000389c:	fffff097          	auipc	ra,0xfffff
    800038a0:	9f0080e7          	jalr	-1552(ra) # 8000228c <myproc>
    800038a4:	5924                	lw	s1,112(a0)
  if(growproc(n) < 0)
    800038a6:	fdc42503          	lw	a0,-36(s0)
    800038aa:	fffff097          	auipc	ra,0xfffff
    800038ae:	db2080e7          	jalr	-590(ra) # 8000265c <growproc>
    800038b2:	00054863          	bltz	a0,800038c2 <sys_sbrk+0x46>
    return -1;
  return addr;
    800038b6:	8526                	mv	a0,s1
}
    800038b8:	70a2                	ld	ra,40(sp)
    800038ba:	7402                	ld	s0,32(sp)
    800038bc:	64e2                	ld	s1,24(sp)
    800038be:	6145                	addi	sp,sp,48
    800038c0:	8082                	ret
    return -1;
    800038c2:	557d                	li	a0,-1
    800038c4:	bfd5                	j	800038b8 <sys_sbrk+0x3c>

00000000800038c6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800038c6:	7139                	addi	sp,sp,-64
    800038c8:	fc06                	sd	ra,56(sp)
    800038ca:	f822                	sd	s0,48(sp)
    800038cc:	f426                	sd	s1,40(sp)
    800038ce:	f04a                	sd	s2,32(sp)
    800038d0:	ec4e                	sd	s3,24(sp)
    800038d2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800038d4:	fcc40593          	addi	a1,s0,-52
    800038d8:	4501                	li	a0,0
    800038da:	00000097          	auipc	ra,0x0
    800038de:	de0080e7          	jalr	-544(ra) # 800036ba <argint>
    return -1;
    800038e2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800038e4:	06054563          	bltz	a0,8000394e <sys_sleep+0x88>
  acquire(&tickslock);
    800038e8:	00014517          	auipc	a0,0x14
    800038ec:	0f850513          	addi	a0,a0,248 # 800179e0 <tickslock>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	2fc080e7          	jalr	764(ra) # 80000bec <acquire>
  ticks0 = ticks;
    800038f8:	00005917          	auipc	s2,0x5
    800038fc:	77892903          	lw	s2,1912(s2) # 80009070 <ticks>
  while(ticks - ticks0 < n){
    80003900:	fcc42783          	lw	a5,-52(s0)
    80003904:	cf85                	beqz	a5,8000393c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003906:	00014997          	auipc	s3,0x14
    8000390a:	0da98993          	addi	s3,s3,218 # 800179e0 <tickslock>
    8000390e:	00005497          	auipc	s1,0x5
    80003912:	76248493          	addi	s1,s1,1890 # 80009070 <ticks>
    if(myproc()->killed){
    80003916:	fffff097          	auipc	ra,0xfffff
    8000391a:	976080e7          	jalr	-1674(ra) # 8000228c <myproc>
    8000391e:	413c                	lw	a5,64(a0)
    80003920:	ef9d                	bnez	a5,8000395e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003922:	85ce                	mv	a1,s3
    80003924:	8526                	mv	a0,s1
    80003926:	fffff097          	auipc	ra,0xfffff
    8000392a:	22a080e7          	jalr	554(ra) # 80002b50 <sleep>
  while(ticks - ticks0 < n){
    8000392e:	409c                	lw	a5,0(s1)
    80003930:	412787bb          	subw	a5,a5,s2
    80003934:	fcc42703          	lw	a4,-52(s0)
    80003938:	fce7efe3          	bltu	a5,a4,80003916 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000393c:	00014517          	auipc	a0,0x14
    80003940:	0a450513          	addi	a0,a0,164 # 800179e0 <tickslock>
    80003944:	ffffd097          	auipc	ra,0xffffd
    80003948:	362080e7          	jalr	866(ra) # 80000ca6 <release>
  return 0;
    8000394c:	4781                	li	a5,0
}
    8000394e:	853e                	mv	a0,a5
    80003950:	70e2                	ld	ra,56(sp)
    80003952:	7442                	ld	s0,48(sp)
    80003954:	74a2                	ld	s1,40(sp)
    80003956:	7902                	ld	s2,32(sp)
    80003958:	69e2                	ld	s3,24(sp)
    8000395a:	6121                	addi	sp,sp,64
    8000395c:	8082                	ret
      release(&tickslock);
    8000395e:	00014517          	auipc	a0,0x14
    80003962:	08250513          	addi	a0,a0,130 # 800179e0 <tickslock>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	340080e7          	jalr	832(ra) # 80000ca6 <release>
      return -1;
    8000396e:	57fd                	li	a5,-1
    80003970:	bff9                	j	8000394e <sys_sleep+0x88>

0000000080003972 <sys_kill>:

uint64
sys_kill(void)
{
    80003972:	1101                	addi	sp,sp,-32
    80003974:	ec06                	sd	ra,24(sp)
    80003976:	e822                	sd	s0,16(sp)
    80003978:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000397a:	fec40593          	addi	a1,s0,-20
    8000397e:	4501                	li	a0,0
    80003980:	00000097          	auipc	ra,0x0
    80003984:	d3a080e7          	jalr	-710(ra) # 800036ba <argint>
    80003988:	87aa                	mv	a5,a0
    return -1;
    8000398a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000398c:	0007c863          	bltz	a5,8000399c <sys_kill+0x2a>
  return kill(pid);
    80003990:	fec42503          	lw	a0,-20(s0)
    80003994:	fffff097          	auipc	ra,0xfffff
    80003998:	642080e7          	jalr	1602(ra) # 80002fd6 <kill>
}
    8000399c:	60e2                	ld	ra,24(sp)
    8000399e:	6442                	ld	s0,16(sp)
    800039a0:	6105                	addi	sp,sp,32
    800039a2:	8082                	ret

00000000800039a4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800039a4:	1101                	addi	sp,sp,-32
    800039a6:	ec06                	sd	ra,24(sp)
    800039a8:	e822                	sd	s0,16(sp)
    800039aa:	e426                	sd	s1,8(sp)
    800039ac:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800039ae:	00014517          	auipc	a0,0x14
    800039b2:	03250513          	addi	a0,a0,50 # 800179e0 <tickslock>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	236080e7          	jalr	566(ra) # 80000bec <acquire>
  xticks = ticks;
    800039be:	00005497          	auipc	s1,0x5
    800039c2:	6b24a483          	lw	s1,1714(s1) # 80009070 <ticks>
  release(&tickslock);
    800039c6:	00014517          	auipc	a0,0x14
    800039ca:	01a50513          	addi	a0,a0,26 # 800179e0 <tickslock>
    800039ce:	ffffd097          	auipc	ra,0xffffd
    800039d2:	2d8080e7          	jalr	728(ra) # 80000ca6 <release>
  return xticks;
}
    800039d6:	02049513          	slli	a0,s1,0x20
    800039da:	9101                	srli	a0,a0,0x20
    800039dc:	60e2                	ld	ra,24(sp)
    800039de:	6442                	ld	s0,16(sp)
    800039e0:	64a2                	ld	s1,8(sp)
    800039e2:	6105                	addi	sp,sp,32
    800039e4:	8082                	ret

00000000800039e6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800039e6:	7179                	addi	sp,sp,-48
    800039e8:	f406                	sd	ra,40(sp)
    800039ea:	f022                	sd	s0,32(sp)
    800039ec:	ec26                	sd	s1,24(sp)
    800039ee:	e84a                	sd	s2,16(sp)
    800039f0:	e44e                	sd	s3,8(sp)
    800039f2:	e052                	sd	s4,0(sp)
    800039f4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800039f6:	00005597          	auipc	a1,0x5
    800039fa:	c6a58593          	addi	a1,a1,-918 # 80008660 <syscalls+0xc0>
    800039fe:	00014517          	auipc	a0,0x14
    80003a02:	ffa50513          	addi	a0,a0,-6 # 800179f8 <bcache>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	14e080e7          	jalr	334(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003a0e:	0001c797          	auipc	a5,0x1c
    80003a12:	fea78793          	addi	a5,a5,-22 # 8001f9f8 <bcache+0x8000>
    80003a16:	0001c717          	auipc	a4,0x1c
    80003a1a:	24a70713          	addi	a4,a4,586 # 8001fc60 <bcache+0x8268>
    80003a1e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003a22:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a26:	00014497          	auipc	s1,0x14
    80003a2a:	fea48493          	addi	s1,s1,-22 # 80017a10 <bcache+0x18>
    b->next = bcache.head.next;
    80003a2e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003a30:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003a32:	00005a17          	auipc	s4,0x5
    80003a36:	c36a0a13          	addi	s4,s4,-970 # 80008668 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003a3a:	2b893783          	ld	a5,696(s2)
    80003a3e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003a40:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003a44:	85d2                	mv	a1,s4
    80003a46:	01048513          	addi	a0,s1,16
    80003a4a:	00001097          	auipc	ra,0x1
    80003a4e:	4bc080e7          	jalr	1212(ra) # 80004f06 <initsleeplock>
    bcache.head.next->prev = b;
    80003a52:	2b893783          	ld	a5,696(s2)
    80003a56:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003a58:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a5c:	45848493          	addi	s1,s1,1112
    80003a60:	fd349de3          	bne	s1,s3,80003a3a <binit+0x54>
  }
}
    80003a64:	70a2                	ld	ra,40(sp)
    80003a66:	7402                	ld	s0,32(sp)
    80003a68:	64e2                	ld	s1,24(sp)
    80003a6a:	6942                	ld	s2,16(sp)
    80003a6c:	69a2                	ld	s3,8(sp)
    80003a6e:	6a02                	ld	s4,0(sp)
    80003a70:	6145                	addi	sp,sp,48
    80003a72:	8082                	ret

0000000080003a74 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003a74:	7179                	addi	sp,sp,-48
    80003a76:	f406                	sd	ra,40(sp)
    80003a78:	f022                	sd	s0,32(sp)
    80003a7a:	ec26                	sd	s1,24(sp)
    80003a7c:	e84a                	sd	s2,16(sp)
    80003a7e:	e44e                	sd	s3,8(sp)
    80003a80:	1800                	addi	s0,sp,48
    80003a82:	89aa                	mv	s3,a0
    80003a84:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003a86:	00014517          	auipc	a0,0x14
    80003a8a:	f7250513          	addi	a0,a0,-142 # 800179f8 <bcache>
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	15e080e7          	jalr	350(ra) # 80000bec <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003a96:	0001c497          	auipc	s1,0x1c
    80003a9a:	21a4b483          	ld	s1,538(s1) # 8001fcb0 <bcache+0x82b8>
    80003a9e:	0001c797          	auipc	a5,0x1c
    80003aa2:	1c278793          	addi	a5,a5,450 # 8001fc60 <bcache+0x8268>
    80003aa6:	02f48f63          	beq	s1,a5,80003ae4 <bread+0x70>
    80003aaa:	873e                	mv	a4,a5
    80003aac:	a021                	j	80003ab4 <bread+0x40>
    80003aae:	68a4                	ld	s1,80(s1)
    80003ab0:	02e48a63          	beq	s1,a4,80003ae4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003ab4:	449c                	lw	a5,8(s1)
    80003ab6:	ff379ce3          	bne	a5,s3,80003aae <bread+0x3a>
    80003aba:	44dc                	lw	a5,12(s1)
    80003abc:	ff2799e3          	bne	a5,s2,80003aae <bread+0x3a>
      b->refcnt++;
    80003ac0:	40bc                	lw	a5,64(s1)
    80003ac2:	2785                	addiw	a5,a5,1
    80003ac4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003ac6:	00014517          	auipc	a0,0x14
    80003aca:	f3250513          	addi	a0,a0,-206 # 800179f8 <bcache>
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	1d8080e7          	jalr	472(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003ad6:	01048513          	addi	a0,s1,16
    80003ada:	00001097          	auipc	ra,0x1
    80003ade:	466080e7          	jalr	1126(ra) # 80004f40 <acquiresleep>
      return b;
    80003ae2:	a8b9                	j	80003b40 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003ae4:	0001c497          	auipc	s1,0x1c
    80003ae8:	1c44b483          	ld	s1,452(s1) # 8001fca8 <bcache+0x82b0>
    80003aec:	0001c797          	auipc	a5,0x1c
    80003af0:	17478793          	addi	a5,a5,372 # 8001fc60 <bcache+0x8268>
    80003af4:	00f48863          	beq	s1,a5,80003b04 <bread+0x90>
    80003af8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003afa:	40bc                	lw	a5,64(s1)
    80003afc:	cf81                	beqz	a5,80003b14 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003afe:	64a4                	ld	s1,72(s1)
    80003b00:	fee49de3          	bne	s1,a4,80003afa <bread+0x86>
  panic("bget: no buffers");
    80003b04:	00005517          	auipc	a0,0x5
    80003b08:	b6c50513          	addi	a0,a0,-1172 # 80008670 <syscalls+0xd0>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	a32080e7          	jalr	-1486(ra) # 8000053e <panic>
      b->dev = dev;
    80003b14:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003b18:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003b1c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003b20:	4785                	li	a5,1
    80003b22:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b24:	00014517          	auipc	a0,0x14
    80003b28:	ed450513          	addi	a0,a0,-300 # 800179f8 <bcache>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	17a080e7          	jalr	378(ra) # 80000ca6 <release>
      acquiresleep(&b->lock);
    80003b34:	01048513          	addi	a0,s1,16
    80003b38:	00001097          	auipc	ra,0x1
    80003b3c:	408080e7          	jalr	1032(ra) # 80004f40 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003b40:	409c                	lw	a5,0(s1)
    80003b42:	cb89                	beqz	a5,80003b54 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003b44:	8526                	mv	a0,s1
    80003b46:	70a2                	ld	ra,40(sp)
    80003b48:	7402                	ld	s0,32(sp)
    80003b4a:	64e2                	ld	s1,24(sp)
    80003b4c:	6942                	ld	s2,16(sp)
    80003b4e:	69a2                	ld	s3,8(sp)
    80003b50:	6145                	addi	sp,sp,48
    80003b52:	8082                	ret
    virtio_disk_rw(b, 0);
    80003b54:	4581                	li	a1,0
    80003b56:	8526                	mv	a0,s1
    80003b58:	00003097          	auipc	ra,0x3
    80003b5c:	f0e080e7          	jalr	-242(ra) # 80006a66 <virtio_disk_rw>
    b->valid = 1;
    80003b60:	4785                	li	a5,1
    80003b62:	c09c                	sw	a5,0(s1)
  return b;
    80003b64:	b7c5                	j	80003b44 <bread+0xd0>

0000000080003b66 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003b66:	1101                	addi	sp,sp,-32
    80003b68:	ec06                	sd	ra,24(sp)
    80003b6a:	e822                	sd	s0,16(sp)
    80003b6c:	e426                	sd	s1,8(sp)
    80003b6e:	1000                	addi	s0,sp,32
    80003b70:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003b72:	0541                	addi	a0,a0,16
    80003b74:	00001097          	auipc	ra,0x1
    80003b78:	466080e7          	jalr	1126(ra) # 80004fda <holdingsleep>
    80003b7c:	cd01                	beqz	a0,80003b94 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003b7e:	4585                	li	a1,1
    80003b80:	8526                	mv	a0,s1
    80003b82:	00003097          	auipc	ra,0x3
    80003b86:	ee4080e7          	jalr	-284(ra) # 80006a66 <virtio_disk_rw>
}
    80003b8a:	60e2                	ld	ra,24(sp)
    80003b8c:	6442                	ld	s0,16(sp)
    80003b8e:	64a2                	ld	s1,8(sp)
    80003b90:	6105                	addi	sp,sp,32
    80003b92:	8082                	ret
    panic("bwrite");
    80003b94:	00005517          	auipc	a0,0x5
    80003b98:	af450513          	addi	a0,a0,-1292 # 80008688 <syscalls+0xe8>
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	9a2080e7          	jalr	-1630(ra) # 8000053e <panic>

0000000080003ba4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003ba4:	1101                	addi	sp,sp,-32
    80003ba6:	ec06                	sd	ra,24(sp)
    80003ba8:	e822                	sd	s0,16(sp)
    80003baa:	e426                	sd	s1,8(sp)
    80003bac:	e04a                	sd	s2,0(sp)
    80003bae:	1000                	addi	s0,sp,32
    80003bb0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003bb2:	01050913          	addi	s2,a0,16
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	00001097          	auipc	ra,0x1
    80003bbc:	422080e7          	jalr	1058(ra) # 80004fda <holdingsleep>
    80003bc0:	c92d                	beqz	a0,80003c32 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003bc2:	854a                	mv	a0,s2
    80003bc4:	00001097          	auipc	ra,0x1
    80003bc8:	3d2080e7          	jalr	978(ra) # 80004f96 <releasesleep>

  acquire(&bcache.lock);
    80003bcc:	00014517          	auipc	a0,0x14
    80003bd0:	e2c50513          	addi	a0,a0,-468 # 800179f8 <bcache>
    80003bd4:	ffffd097          	auipc	ra,0xffffd
    80003bd8:	018080e7          	jalr	24(ra) # 80000bec <acquire>
  b->refcnt--;
    80003bdc:	40bc                	lw	a5,64(s1)
    80003bde:	37fd                	addiw	a5,a5,-1
    80003be0:	0007871b          	sext.w	a4,a5
    80003be4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003be6:	eb05                	bnez	a4,80003c16 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003be8:	68bc                	ld	a5,80(s1)
    80003bea:	64b8                	ld	a4,72(s1)
    80003bec:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003bee:	64bc                	ld	a5,72(s1)
    80003bf0:	68b8                	ld	a4,80(s1)
    80003bf2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003bf4:	0001c797          	auipc	a5,0x1c
    80003bf8:	e0478793          	addi	a5,a5,-508 # 8001f9f8 <bcache+0x8000>
    80003bfc:	2b87b703          	ld	a4,696(a5)
    80003c00:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003c02:	0001c717          	auipc	a4,0x1c
    80003c06:	05e70713          	addi	a4,a4,94 # 8001fc60 <bcache+0x8268>
    80003c0a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003c0c:	2b87b703          	ld	a4,696(a5)
    80003c10:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003c12:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003c16:	00014517          	auipc	a0,0x14
    80003c1a:	de250513          	addi	a0,a0,-542 # 800179f8 <bcache>
    80003c1e:	ffffd097          	auipc	ra,0xffffd
    80003c22:	088080e7          	jalr	136(ra) # 80000ca6 <release>
}
    80003c26:	60e2                	ld	ra,24(sp)
    80003c28:	6442                	ld	s0,16(sp)
    80003c2a:	64a2                	ld	s1,8(sp)
    80003c2c:	6902                	ld	s2,0(sp)
    80003c2e:	6105                	addi	sp,sp,32
    80003c30:	8082                	ret
    panic("brelse");
    80003c32:	00005517          	auipc	a0,0x5
    80003c36:	a5e50513          	addi	a0,a0,-1442 # 80008690 <syscalls+0xf0>
    80003c3a:	ffffd097          	auipc	ra,0xffffd
    80003c3e:	904080e7          	jalr	-1788(ra) # 8000053e <panic>

0000000080003c42 <bpin>:

void
bpin(struct buf *b) {
    80003c42:	1101                	addi	sp,sp,-32
    80003c44:	ec06                	sd	ra,24(sp)
    80003c46:	e822                	sd	s0,16(sp)
    80003c48:	e426                	sd	s1,8(sp)
    80003c4a:	1000                	addi	s0,sp,32
    80003c4c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c4e:	00014517          	auipc	a0,0x14
    80003c52:	daa50513          	addi	a0,a0,-598 # 800179f8 <bcache>
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	f96080e7          	jalr	-106(ra) # 80000bec <acquire>
  b->refcnt++;
    80003c5e:	40bc                	lw	a5,64(s1)
    80003c60:	2785                	addiw	a5,a5,1
    80003c62:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c64:	00014517          	auipc	a0,0x14
    80003c68:	d9450513          	addi	a0,a0,-620 # 800179f8 <bcache>
    80003c6c:	ffffd097          	auipc	ra,0xffffd
    80003c70:	03a080e7          	jalr	58(ra) # 80000ca6 <release>
}
    80003c74:	60e2                	ld	ra,24(sp)
    80003c76:	6442                	ld	s0,16(sp)
    80003c78:	64a2                	ld	s1,8(sp)
    80003c7a:	6105                	addi	sp,sp,32
    80003c7c:	8082                	ret

0000000080003c7e <bunpin>:

void
bunpin(struct buf *b) {
    80003c7e:	1101                	addi	sp,sp,-32
    80003c80:	ec06                	sd	ra,24(sp)
    80003c82:	e822                	sd	s0,16(sp)
    80003c84:	e426                	sd	s1,8(sp)
    80003c86:	1000                	addi	s0,sp,32
    80003c88:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c8a:	00014517          	auipc	a0,0x14
    80003c8e:	d6e50513          	addi	a0,a0,-658 # 800179f8 <bcache>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	f5a080e7          	jalr	-166(ra) # 80000bec <acquire>
  b->refcnt--;
    80003c9a:	40bc                	lw	a5,64(s1)
    80003c9c:	37fd                	addiw	a5,a5,-1
    80003c9e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ca0:	00014517          	auipc	a0,0x14
    80003ca4:	d5850513          	addi	a0,a0,-680 # 800179f8 <bcache>
    80003ca8:	ffffd097          	auipc	ra,0xffffd
    80003cac:	ffe080e7          	jalr	-2(ra) # 80000ca6 <release>
}
    80003cb0:	60e2                	ld	ra,24(sp)
    80003cb2:	6442                	ld	s0,16(sp)
    80003cb4:	64a2                	ld	s1,8(sp)
    80003cb6:	6105                	addi	sp,sp,32
    80003cb8:	8082                	ret

0000000080003cba <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003cba:	1101                	addi	sp,sp,-32
    80003cbc:	ec06                	sd	ra,24(sp)
    80003cbe:	e822                	sd	s0,16(sp)
    80003cc0:	e426                	sd	s1,8(sp)
    80003cc2:	e04a                	sd	s2,0(sp)
    80003cc4:	1000                	addi	s0,sp,32
    80003cc6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003cc8:	00d5d59b          	srliw	a1,a1,0xd
    80003ccc:	0001c797          	auipc	a5,0x1c
    80003cd0:	4087a783          	lw	a5,1032(a5) # 800200d4 <sb+0x1c>
    80003cd4:	9dbd                	addw	a1,a1,a5
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	d9e080e7          	jalr	-610(ra) # 80003a74 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003cde:	0074f713          	andi	a4,s1,7
    80003ce2:	4785                	li	a5,1
    80003ce4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003ce8:	14ce                	slli	s1,s1,0x33
    80003cea:	90d9                	srli	s1,s1,0x36
    80003cec:	00950733          	add	a4,a0,s1
    80003cf0:	05874703          	lbu	a4,88(a4)
    80003cf4:	00e7f6b3          	and	a3,a5,a4
    80003cf8:	c69d                	beqz	a3,80003d26 <bfree+0x6c>
    80003cfa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003cfc:	94aa                	add	s1,s1,a0
    80003cfe:	fff7c793          	not	a5,a5
    80003d02:	8ff9                	and	a5,a5,a4
    80003d04:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003d08:	00001097          	auipc	ra,0x1
    80003d0c:	118080e7          	jalr	280(ra) # 80004e20 <log_write>
  brelse(bp);
    80003d10:	854a                	mv	a0,s2
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	e92080e7          	jalr	-366(ra) # 80003ba4 <brelse>
}
    80003d1a:	60e2                	ld	ra,24(sp)
    80003d1c:	6442                	ld	s0,16(sp)
    80003d1e:	64a2                	ld	s1,8(sp)
    80003d20:	6902                	ld	s2,0(sp)
    80003d22:	6105                	addi	sp,sp,32
    80003d24:	8082                	ret
    panic("freeing free block");
    80003d26:	00005517          	auipc	a0,0x5
    80003d2a:	97250513          	addi	a0,a0,-1678 # 80008698 <syscalls+0xf8>
    80003d2e:	ffffd097          	auipc	ra,0xffffd
    80003d32:	810080e7          	jalr	-2032(ra) # 8000053e <panic>

0000000080003d36 <balloc>:
{
    80003d36:	711d                	addi	sp,sp,-96
    80003d38:	ec86                	sd	ra,88(sp)
    80003d3a:	e8a2                	sd	s0,80(sp)
    80003d3c:	e4a6                	sd	s1,72(sp)
    80003d3e:	e0ca                	sd	s2,64(sp)
    80003d40:	fc4e                	sd	s3,56(sp)
    80003d42:	f852                	sd	s4,48(sp)
    80003d44:	f456                	sd	s5,40(sp)
    80003d46:	f05a                	sd	s6,32(sp)
    80003d48:	ec5e                	sd	s7,24(sp)
    80003d4a:	e862                	sd	s8,16(sp)
    80003d4c:	e466                	sd	s9,8(sp)
    80003d4e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003d50:	0001c797          	auipc	a5,0x1c
    80003d54:	36c7a783          	lw	a5,876(a5) # 800200bc <sb+0x4>
    80003d58:	cbd1                	beqz	a5,80003dec <balloc+0xb6>
    80003d5a:	8baa                	mv	s7,a0
    80003d5c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003d5e:	0001cb17          	auipc	s6,0x1c
    80003d62:	35ab0b13          	addi	s6,s6,858 # 800200b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d66:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003d68:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d6a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003d6c:	6c89                	lui	s9,0x2
    80003d6e:	a831                	j	80003d8a <balloc+0x54>
    brelse(bp);
    80003d70:	854a                	mv	a0,s2
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	e32080e7          	jalr	-462(ra) # 80003ba4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003d7a:	015c87bb          	addw	a5,s9,s5
    80003d7e:	00078a9b          	sext.w	s5,a5
    80003d82:	004b2703          	lw	a4,4(s6)
    80003d86:	06eaf363          	bgeu	s5,a4,80003dec <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003d8a:	41fad79b          	sraiw	a5,s5,0x1f
    80003d8e:	0137d79b          	srliw	a5,a5,0x13
    80003d92:	015787bb          	addw	a5,a5,s5
    80003d96:	40d7d79b          	sraiw	a5,a5,0xd
    80003d9a:	01cb2583          	lw	a1,28(s6)
    80003d9e:	9dbd                	addw	a1,a1,a5
    80003da0:	855e                	mv	a0,s7
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	cd2080e7          	jalr	-814(ra) # 80003a74 <bread>
    80003daa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003dac:	004b2503          	lw	a0,4(s6)
    80003db0:	000a849b          	sext.w	s1,s5
    80003db4:	8662                	mv	a2,s8
    80003db6:	faa4fde3          	bgeu	s1,a0,80003d70 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003dba:	41f6579b          	sraiw	a5,a2,0x1f
    80003dbe:	01d7d69b          	srliw	a3,a5,0x1d
    80003dc2:	00c6873b          	addw	a4,a3,a2
    80003dc6:	00777793          	andi	a5,a4,7
    80003dca:	9f95                	subw	a5,a5,a3
    80003dcc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003dd0:	4037571b          	sraiw	a4,a4,0x3
    80003dd4:	00e906b3          	add	a3,s2,a4
    80003dd8:	0586c683          	lbu	a3,88(a3)
    80003ddc:	00d7f5b3          	and	a1,a5,a3
    80003de0:	cd91                	beqz	a1,80003dfc <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003de2:	2605                	addiw	a2,a2,1
    80003de4:	2485                	addiw	s1,s1,1
    80003de6:	fd4618e3          	bne	a2,s4,80003db6 <balloc+0x80>
    80003dea:	b759                	j	80003d70 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003dec:	00005517          	auipc	a0,0x5
    80003df0:	8c450513          	addi	a0,a0,-1852 # 800086b0 <syscalls+0x110>
    80003df4:	ffffc097          	auipc	ra,0xffffc
    80003df8:	74a080e7          	jalr	1866(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003dfc:	974a                	add	a4,a4,s2
    80003dfe:	8fd5                	or	a5,a5,a3
    80003e00:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e04:	854a                	mv	a0,s2
    80003e06:	00001097          	auipc	ra,0x1
    80003e0a:	01a080e7          	jalr	26(ra) # 80004e20 <log_write>
        brelse(bp);
    80003e0e:	854a                	mv	a0,s2
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	d94080e7          	jalr	-620(ra) # 80003ba4 <brelse>
  bp = bread(dev, bno);
    80003e18:	85a6                	mv	a1,s1
    80003e1a:	855e                	mv	a0,s7
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	c58080e7          	jalr	-936(ra) # 80003a74 <bread>
    80003e24:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e26:	40000613          	li	a2,1024
    80003e2a:	4581                	li	a1,0
    80003e2c:	05850513          	addi	a0,a0,88
    80003e30:	ffffd097          	auipc	ra,0xffffd
    80003e34:	ebe080e7          	jalr	-322(ra) # 80000cee <memset>
  log_write(bp);
    80003e38:	854a                	mv	a0,s2
    80003e3a:	00001097          	auipc	ra,0x1
    80003e3e:	fe6080e7          	jalr	-26(ra) # 80004e20 <log_write>
  brelse(bp);
    80003e42:	854a                	mv	a0,s2
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	d60080e7          	jalr	-672(ra) # 80003ba4 <brelse>
}
    80003e4c:	8526                	mv	a0,s1
    80003e4e:	60e6                	ld	ra,88(sp)
    80003e50:	6446                	ld	s0,80(sp)
    80003e52:	64a6                	ld	s1,72(sp)
    80003e54:	6906                	ld	s2,64(sp)
    80003e56:	79e2                	ld	s3,56(sp)
    80003e58:	7a42                	ld	s4,48(sp)
    80003e5a:	7aa2                	ld	s5,40(sp)
    80003e5c:	7b02                	ld	s6,32(sp)
    80003e5e:	6be2                	ld	s7,24(sp)
    80003e60:	6c42                	ld	s8,16(sp)
    80003e62:	6ca2                	ld	s9,8(sp)
    80003e64:	6125                	addi	sp,sp,96
    80003e66:	8082                	ret

0000000080003e68 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003e68:	7179                	addi	sp,sp,-48
    80003e6a:	f406                	sd	ra,40(sp)
    80003e6c:	f022                	sd	s0,32(sp)
    80003e6e:	ec26                	sd	s1,24(sp)
    80003e70:	e84a                	sd	s2,16(sp)
    80003e72:	e44e                	sd	s3,8(sp)
    80003e74:	e052                	sd	s4,0(sp)
    80003e76:	1800                	addi	s0,sp,48
    80003e78:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003e7a:	47ad                	li	a5,11
    80003e7c:	04b7fe63          	bgeu	a5,a1,80003ed8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003e80:	ff45849b          	addiw	s1,a1,-12
    80003e84:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003e88:	0ff00793          	li	a5,255
    80003e8c:	0ae7e363          	bltu	a5,a4,80003f32 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003e90:	08052583          	lw	a1,128(a0)
    80003e94:	c5ad                	beqz	a1,80003efe <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003e96:	00092503          	lw	a0,0(s2)
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	bda080e7          	jalr	-1062(ra) # 80003a74 <bread>
    80003ea2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003ea4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ea8:	02049593          	slli	a1,s1,0x20
    80003eac:	9181                	srli	a1,a1,0x20
    80003eae:	058a                	slli	a1,a1,0x2
    80003eb0:	00b784b3          	add	s1,a5,a1
    80003eb4:	0004a983          	lw	s3,0(s1)
    80003eb8:	04098d63          	beqz	s3,80003f12 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003ebc:	8552                	mv	a0,s4
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	ce6080e7          	jalr	-794(ra) # 80003ba4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ec6:	854e                	mv	a0,s3
    80003ec8:	70a2                	ld	ra,40(sp)
    80003eca:	7402                	ld	s0,32(sp)
    80003ecc:	64e2                	ld	s1,24(sp)
    80003ece:	6942                	ld	s2,16(sp)
    80003ed0:	69a2                	ld	s3,8(sp)
    80003ed2:	6a02                	ld	s4,0(sp)
    80003ed4:	6145                	addi	sp,sp,48
    80003ed6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003ed8:	02059493          	slli	s1,a1,0x20
    80003edc:	9081                	srli	s1,s1,0x20
    80003ede:	048a                	slli	s1,s1,0x2
    80003ee0:	94aa                	add	s1,s1,a0
    80003ee2:	0504a983          	lw	s3,80(s1)
    80003ee6:	fe0990e3          	bnez	s3,80003ec6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003eea:	4108                	lw	a0,0(a0)
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	e4a080e7          	jalr	-438(ra) # 80003d36 <balloc>
    80003ef4:	0005099b          	sext.w	s3,a0
    80003ef8:	0534a823          	sw	s3,80(s1)
    80003efc:	b7e9                	j	80003ec6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003efe:	4108                	lw	a0,0(a0)
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	e36080e7          	jalr	-458(ra) # 80003d36 <balloc>
    80003f08:	0005059b          	sext.w	a1,a0
    80003f0c:	08b92023          	sw	a1,128(s2)
    80003f10:	b759                	j	80003e96 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003f12:	00092503          	lw	a0,0(s2)
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	e20080e7          	jalr	-480(ra) # 80003d36 <balloc>
    80003f1e:	0005099b          	sext.w	s3,a0
    80003f22:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003f26:	8552                	mv	a0,s4
    80003f28:	00001097          	auipc	ra,0x1
    80003f2c:	ef8080e7          	jalr	-264(ra) # 80004e20 <log_write>
    80003f30:	b771                	j	80003ebc <bmap+0x54>
  panic("bmap: out of range");
    80003f32:	00004517          	auipc	a0,0x4
    80003f36:	79650513          	addi	a0,a0,1942 # 800086c8 <syscalls+0x128>
    80003f3a:	ffffc097          	auipc	ra,0xffffc
    80003f3e:	604080e7          	jalr	1540(ra) # 8000053e <panic>

0000000080003f42 <iget>:
{
    80003f42:	7179                	addi	sp,sp,-48
    80003f44:	f406                	sd	ra,40(sp)
    80003f46:	f022                	sd	s0,32(sp)
    80003f48:	ec26                	sd	s1,24(sp)
    80003f4a:	e84a                	sd	s2,16(sp)
    80003f4c:	e44e                	sd	s3,8(sp)
    80003f4e:	e052                	sd	s4,0(sp)
    80003f50:	1800                	addi	s0,sp,48
    80003f52:	89aa                	mv	s3,a0
    80003f54:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003f56:	0001c517          	auipc	a0,0x1c
    80003f5a:	18250513          	addi	a0,a0,386 # 800200d8 <itable>
    80003f5e:	ffffd097          	auipc	ra,0xffffd
    80003f62:	c8e080e7          	jalr	-882(ra) # 80000bec <acquire>
  empty = 0;
    80003f66:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f68:	0001c497          	auipc	s1,0x1c
    80003f6c:	18848493          	addi	s1,s1,392 # 800200f0 <itable+0x18>
    80003f70:	0001e697          	auipc	a3,0x1e
    80003f74:	c1068693          	addi	a3,a3,-1008 # 80021b80 <log>
    80003f78:	a039                	j	80003f86 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003f7a:	02090b63          	beqz	s2,80003fb0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f7e:	08848493          	addi	s1,s1,136
    80003f82:	02d48a63          	beq	s1,a3,80003fb6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003f86:	449c                	lw	a5,8(s1)
    80003f88:	fef059e3          	blez	a5,80003f7a <iget+0x38>
    80003f8c:	4098                	lw	a4,0(s1)
    80003f8e:	ff3716e3          	bne	a4,s3,80003f7a <iget+0x38>
    80003f92:	40d8                	lw	a4,4(s1)
    80003f94:	ff4713e3          	bne	a4,s4,80003f7a <iget+0x38>
      ip->ref++;
    80003f98:	2785                	addiw	a5,a5,1
    80003f9a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003f9c:	0001c517          	auipc	a0,0x1c
    80003fa0:	13c50513          	addi	a0,a0,316 # 800200d8 <itable>
    80003fa4:	ffffd097          	auipc	ra,0xffffd
    80003fa8:	d02080e7          	jalr	-766(ra) # 80000ca6 <release>
      return ip;
    80003fac:	8926                	mv	s2,s1
    80003fae:	a03d                	j	80003fdc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fb0:	f7f9                	bnez	a5,80003f7e <iget+0x3c>
    80003fb2:	8926                	mv	s2,s1
    80003fb4:	b7e9                	j	80003f7e <iget+0x3c>
  if(empty == 0)
    80003fb6:	02090c63          	beqz	s2,80003fee <iget+0xac>
  ip->dev = dev;
    80003fba:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003fbe:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003fc2:	4785                	li	a5,1
    80003fc4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003fc8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003fcc:	0001c517          	auipc	a0,0x1c
    80003fd0:	10c50513          	addi	a0,a0,268 # 800200d8 <itable>
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	cd2080e7          	jalr	-814(ra) # 80000ca6 <release>
}
    80003fdc:	854a                	mv	a0,s2
    80003fde:	70a2                	ld	ra,40(sp)
    80003fe0:	7402                	ld	s0,32(sp)
    80003fe2:	64e2                	ld	s1,24(sp)
    80003fe4:	6942                	ld	s2,16(sp)
    80003fe6:	69a2                	ld	s3,8(sp)
    80003fe8:	6a02                	ld	s4,0(sp)
    80003fea:	6145                	addi	sp,sp,48
    80003fec:	8082                	ret
    panic("iget: no inodes");
    80003fee:	00004517          	auipc	a0,0x4
    80003ff2:	6f250513          	addi	a0,a0,1778 # 800086e0 <syscalls+0x140>
    80003ff6:	ffffc097          	auipc	ra,0xffffc
    80003ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>

0000000080003ffe <fsinit>:
fsinit(int dev) {
    80003ffe:	7179                	addi	sp,sp,-48
    80004000:	f406                	sd	ra,40(sp)
    80004002:	f022                	sd	s0,32(sp)
    80004004:	ec26                	sd	s1,24(sp)
    80004006:	e84a                	sd	s2,16(sp)
    80004008:	e44e                	sd	s3,8(sp)
    8000400a:	1800                	addi	s0,sp,48
    8000400c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000400e:	4585                	li	a1,1
    80004010:	00000097          	auipc	ra,0x0
    80004014:	a64080e7          	jalr	-1436(ra) # 80003a74 <bread>
    80004018:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000401a:	0001c997          	auipc	s3,0x1c
    8000401e:	09e98993          	addi	s3,s3,158 # 800200b8 <sb>
    80004022:	02000613          	li	a2,32
    80004026:	05850593          	addi	a1,a0,88
    8000402a:	854e                	mv	a0,s3
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	d22080e7          	jalr	-734(ra) # 80000d4e <memmove>
  brelse(bp);
    80004034:	8526                	mv	a0,s1
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	b6e080e7          	jalr	-1170(ra) # 80003ba4 <brelse>
  if(sb.magic != FSMAGIC)
    8000403e:	0009a703          	lw	a4,0(s3)
    80004042:	102037b7          	lui	a5,0x10203
    80004046:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000404a:	02f71263          	bne	a4,a5,8000406e <fsinit+0x70>
  initlog(dev, &sb);
    8000404e:	0001c597          	auipc	a1,0x1c
    80004052:	06a58593          	addi	a1,a1,106 # 800200b8 <sb>
    80004056:	854a                	mv	a0,s2
    80004058:	00001097          	auipc	ra,0x1
    8000405c:	b4c080e7          	jalr	-1204(ra) # 80004ba4 <initlog>
}
    80004060:	70a2                	ld	ra,40(sp)
    80004062:	7402                	ld	s0,32(sp)
    80004064:	64e2                	ld	s1,24(sp)
    80004066:	6942                	ld	s2,16(sp)
    80004068:	69a2                	ld	s3,8(sp)
    8000406a:	6145                	addi	sp,sp,48
    8000406c:	8082                	ret
    panic("invalid file system");
    8000406e:	00004517          	auipc	a0,0x4
    80004072:	68250513          	addi	a0,a0,1666 # 800086f0 <syscalls+0x150>
    80004076:	ffffc097          	auipc	ra,0xffffc
    8000407a:	4c8080e7          	jalr	1224(ra) # 8000053e <panic>

000000008000407e <iinit>:
{
    8000407e:	7179                	addi	sp,sp,-48
    80004080:	f406                	sd	ra,40(sp)
    80004082:	f022                	sd	s0,32(sp)
    80004084:	ec26                	sd	s1,24(sp)
    80004086:	e84a                	sd	s2,16(sp)
    80004088:	e44e                	sd	s3,8(sp)
    8000408a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000408c:	00004597          	auipc	a1,0x4
    80004090:	67c58593          	addi	a1,a1,1660 # 80008708 <syscalls+0x168>
    80004094:	0001c517          	auipc	a0,0x1c
    80004098:	04450513          	addi	a0,a0,68 # 800200d8 <itable>
    8000409c:	ffffd097          	auipc	ra,0xffffd
    800040a0:	ab8080e7          	jalr	-1352(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800040a4:	0001c497          	auipc	s1,0x1c
    800040a8:	05c48493          	addi	s1,s1,92 # 80020100 <itable+0x28>
    800040ac:	0001e997          	auipc	s3,0x1e
    800040b0:	ae498993          	addi	s3,s3,-1308 # 80021b90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800040b4:	00004917          	auipc	s2,0x4
    800040b8:	65c90913          	addi	s2,s2,1628 # 80008710 <syscalls+0x170>
    800040bc:	85ca                	mv	a1,s2
    800040be:	8526                	mv	a0,s1
    800040c0:	00001097          	auipc	ra,0x1
    800040c4:	e46080e7          	jalr	-442(ra) # 80004f06 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800040c8:	08848493          	addi	s1,s1,136
    800040cc:	ff3498e3          	bne	s1,s3,800040bc <iinit+0x3e>
}
    800040d0:	70a2                	ld	ra,40(sp)
    800040d2:	7402                	ld	s0,32(sp)
    800040d4:	64e2                	ld	s1,24(sp)
    800040d6:	6942                	ld	s2,16(sp)
    800040d8:	69a2                	ld	s3,8(sp)
    800040da:	6145                	addi	sp,sp,48
    800040dc:	8082                	ret

00000000800040de <ialloc>:
{
    800040de:	715d                	addi	sp,sp,-80
    800040e0:	e486                	sd	ra,72(sp)
    800040e2:	e0a2                	sd	s0,64(sp)
    800040e4:	fc26                	sd	s1,56(sp)
    800040e6:	f84a                	sd	s2,48(sp)
    800040e8:	f44e                	sd	s3,40(sp)
    800040ea:	f052                	sd	s4,32(sp)
    800040ec:	ec56                	sd	s5,24(sp)
    800040ee:	e85a                	sd	s6,16(sp)
    800040f0:	e45e                	sd	s7,8(sp)
    800040f2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800040f4:	0001c717          	auipc	a4,0x1c
    800040f8:	fd072703          	lw	a4,-48(a4) # 800200c4 <sb+0xc>
    800040fc:	4785                	li	a5,1
    800040fe:	04e7fa63          	bgeu	a5,a4,80004152 <ialloc+0x74>
    80004102:	8aaa                	mv	s5,a0
    80004104:	8bae                	mv	s7,a1
    80004106:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004108:	0001ca17          	auipc	s4,0x1c
    8000410c:	fb0a0a13          	addi	s4,s4,-80 # 800200b8 <sb>
    80004110:	00048b1b          	sext.w	s6,s1
    80004114:	0044d593          	srli	a1,s1,0x4
    80004118:	018a2783          	lw	a5,24(s4)
    8000411c:	9dbd                	addw	a1,a1,a5
    8000411e:	8556                	mv	a0,s5
    80004120:	00000097          	auipc	ra,0x0
    80004124:	954080e7          	jalr	-1708(ra) # 80003a74 <bread>
    80004128:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000412a:	05850993          	addi	s3,a0,88
    8000412e:	00f4f793          	andi	a5,s1,15
    80004132:	079a                	slli	a5,a5,0x6
    80004134:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004136:	00099783          	lh	a5,0(s3)
    8000413a:	c785                	beqz	a5,80004162 <ialloc+0x84>
    brelse(bp);
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	a68080e7          	jalr	-1432(ra) # 80003ba4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004144:	0485                	addi	s1,s1,1
    80004146:	00ca2703          	lw	a4,12(s4)
    8000414a:	0004879b          	sext.w	a5,s1
    8000414e:	fce7e1e3          	bltu	a5,a4,80004110 <ialloc+0x32>
  panic("ialloc: no inodes");
    80004152:	00004517          	auipc	a0,0x4
    80004156:	5c650513          	addi	a0,a0,1478 # 80008718 <syscalls+0x178>
    8000415a:	ffffc097          	auipc	ra,0xffffc
    8000415e:	3e4080e7          	jalr	996(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80004162:	04000613          	li	a2,64
    80004166:	4581                	li	a1,0
    80004168:	854e                	mv	a0,s3
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	b84080e7          	jalr	-1148(ra) # 80000cee <memset>
      dip->type = type;
    80004172:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004176:	854a                	mv	a0,s2
    80004178:	00001097          	auipc	ra,0x1
    8000417c:	ca8080e7          	jalr	-856(ra) # 80004e20 <log_write>
      brelse(bp);
    80004180:	854a                	mv	a0,s2
    80004182:	00000097          	auipc	ra,0x0
    80004186:	a22080e7          	jalr	-1502(ra) # 80003ba4 <brelse>
      return iget(dev, inum);
    8000418a:	85da                	mv	a1,s6
    8000418c:	8556                	mv	a0,s5
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	db4080e7          	jalr	-588(ra) # 80003f42 <iget>
}
    80004196:	60a6                	ld	ra,72(sp)
    80004198:	6406                	ld	s0,64(sp)
    8000419a:	74e2                	ld	s1,56(sp)
    8000419c:	7942                	ld	s2,48(sp)
    8000419e:	79a2                	ld	s3,40(sp)
    800041a0:	7a02                	ld	s4,32(sp)
    800041a2:	6ae2                	ld	s5,24(sp)
    800041a4:	6b42                	ld	s6,16(sp)
    800041a6:	6ba2                	ld	s7,8(sp)
    800041a8:	6161                	addi	sp,sp,80
    800041aa:	8082                	ret

00000000800041ac <iupdate>:
{
    800041ac:	1101                	addi	sp,sp,-32
    800041ae:	ec06                	sd	ra,24(sp)
    800041b0:	e822                	sd	s0,16(sp)
    800041b2:	e426                	sd	s1,8(sp)
    800041b4:	e04a                	sd	s2,0(sp)
    800041b6:	1000                	addi	s0,sp,32
    800041b8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800041ba:	415c                	lw	a5,4(a0)
    800041bc:	0047d79b          	srliw	a5,a5,0x4
    800041c0:	0001c597          	auipc	a1,0x1c
    800041c4:	f105a583          	lw	a1,-240(a1) # 800200d0 <sb+0x18>
    800041c8:	9dbd                	addw	a1,a1,a5
    800041ca:	4108                	lw	a0,0(a0)
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	8a8080e7          	jalr	-1880(ra) # 80003a74 <bread>
    800041d4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800041d6:	05850793          	addi	a5,a0,88
    800041da:	40c8                	lw	a0,4(s1)
    800041dc:	893d                	andi	a0,a0,15
    800041de:	051a                	slli	a0,a0,0x6
    800041e0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800041e2:	04449703          	lh	a4,68(s1)
    800041e6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800041ea:	04649703          	lh	a4,70(s1)
    800041ee:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800041f2:	04849703          	lh	a4,72(s1)
    800041f6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800041fa:	04a49703          	lh	a4,74(s1)
    800041fe:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004202:	44f8                	lw	a4,76(s1)
    80004204:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004206:	03400613          	li	a2,52
    8000420a:	05048593          	addi	a1,s1,80
    8000420e:	0531                	addi	a0,a0,12
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	b3e080e7          	jalr	-1218(ra) # 80000d4e <memmove>
  log_write(bp);
    80004218:	854a                	mv	a0,s2
    8000421a:	00001097          	auipc	ra,0x1
    8000421e:	c06080e7          	jalr	-1018(ra) # 80004e20 <log_write>
  brelse(bp);
    80004222:	854a                	mv	a0,s2
    80004224:	00000097          	auipc	ra,0x0
    80004228:	980080e7          	jalr	-1664(ra) # 80003ba4 <brelse>
}
    8000422c:	60e2                	ld	ra,24(sp)
    8000422e:	6442                	ld	s0,16(sp)
    80004230:	64a2                	ld	s1,8(sp)
    80004232:	6902                	ld	s2,0(sp)
    80004234:	6105                	addi	sp,sp,32
    80004236:	8082                	ret

0000000080004238 <idup>:
{
    80004238:	1101                	addi	sp,sp,-32
    8000423a:	ec06                	sd	ra,24(sp)
    8000423c:	e822                	sd	s0,16(sp)
    8000423e:	e426                	sd	s1,8(sp)
    80004240:	1000                	addi	s0,sp,32
    80004242:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004244:	0001c517          	auipc	a0,0x1c
    80004248:	e9450513          	addi	a0,a0,-364 # 800200d8 <itable>
    8000424c:	ffffd097          	auipc	ra,0xffffd
    80004250:	9a0080e7          	jalr	-1632(ra) # 80000bec <acquire>
  ip->ref++;
    80004254:	449c                	lw	a5,8(s1)
    80004256:	2785                	addiw	a5,a5,1
    80004258:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000425a:	0001c517          	auipc	a0,0x1c
    8000425e:	e7e50513          	addi	a0,a0,-386 # 800200d8 <itable>
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	a44080e7          	jalr	-1468(ra) # 80000ca6 <release>
}
    8000426a:	8526                	mv	a0,s1
    8000426c:	60e2                	ld	ra,24(sp)
    8000426e:	6442                	ld	s0,16(sp)
    80004270:	64a2                	ld	s1,8(sp)
    80004272:	6105                	addi	sp,sp,32
    80004274:	8082                	ret

0000000080004276 <ilock>:
{
    80004276:	1101                	addi	sp,sp,-32
    80004278:	ec06                	sd	ra,24(sp)
    8000427a:	e822                	sd	s0,16(sp)
    8000427c:	e426                	sd	s1,8(sp)
    8000427e:	e04a                	sd	s2,0(sp)
    80004280:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004282:	c115                	beqz	a0,800042a6 <ilock+0x30>
    80004284:	84aa                	mv	s1,a0
    80004286:	451c                	lw	a5,8(a0)
    80004288:	00f05f63          	blez	a5,800042a6 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000428c:	0541                	addi	a0,a0,16
    8000428e:	00001097          	auipc	ra,0x1
    80004292:	cb2080e7          	jalr	-846(ra) # 80004f40 <acquiresleep>
  if(ip->valid == 0){
    80004296:	40bc                	lw	a5,64(s1)
    80004298:	cf99                	beqz	a5,800042b6 <ilock+0x40>
}
    8000429a:	60e2                	ld	ra,24(sp)
    8000429c:	6442                	ld	s0,16(sp)
    8000429e:	64a2                	ld	s1,8(sp)
    800042a0:	6902                	ld	s2,0(sp)
    800042a2:	6105                	addi	sp,sp,32
    800042a4:	8082                	ret
    panic("ilock");
    800042a6:	00004517          	auipc	a0,0x4
    800042aa:	48a50513          	addi	a0,a0,1162 # 80008730 <syscalls+0x190>
    800042ae:	ffffc097          	auipc	ra,0xffffc
    800042b2:	290080e7          	jalr	656(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042b6:	40dc                	lw	a5,4(s1)
    800042b8:	0047d79b          	srliw	a5,a5,0x4
    800042bc:	0001c597          	auipc	a1,0x1c
    800042c0:	e145a583          	lw	a1,-492(a1) # 800200d0 <sb+0x18>
    800042c4:	9dbd                	addw	a1,a1,a5
    800042c6:	4088                	lw	a0,0(s1)
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	7ac080e7          	jalr	1964(ra) # 80003a74 <bread>
    800042d0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800042d2:	05850593          	addi	a1,a0,88
    800042d6:	40dc                	lw	a5,4(s1)
    800042d8:	8bbd                	andi	a5,a5,15
    800042da:	079a                	slli	a5,a5,0x6
    800042dc:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800042de:	00059783          	lh	a5,0(a1)
    800042e2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800042e6:	00259783          	lh	a5,2(a1)
    800042ea:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800042ee:	00459783          	lh	a5,4(a1)
    800042f2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800042f6:	00659783          	lh	a5,6(a1)
    800042fa:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800042fe:	459c                	lw	a5,8(a1)
    80004300:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004302:	03400613          	li	a2,52
    80004306:	05b1                	addi	a1,a1,12
    80004308:	05048513          	addi	a0,s1,80
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	a42080e7          	jalr	-1470(ra) # 80000d4e <memmove>
    brelse(bp);
    80004314:	854a                	mv	a0,s2
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	88e080e7          	jalr	-1906(ra) # 80003ba4 <brelse>
    ip->valid = 1;
    8000431e:	4785                	li	a5,1
    80004320:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004322:	04449783          	lh	a5,68(s1)
    80004326:	fbb5                	bnez	a5,8000429a <ilock+0x24>
      panic("ilock: no type");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	41050513          	addi	a0,a0,1040 # 80008738 <syscalls+0x198>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	20e080e7          	jalr	526(ra) # 8000053e <panic>

0000000080004338 <iunlock>:
{
    80004338:	1101                	addi	sp,sp,-32
    8000433a:	ec06                	sd	ra,24(sp)
    8000433c:	e822                	sd	s0,16(sp)
    8000433e:	e426                	sd	s1,8(sp)
    80004340:	e04a                	sd	s2,0(sp)
    80004342:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004344:	c905                	beqz	a0,80004374 <iunlock+0x3c>
    80004346:	84aa                	mv	s1,a0
    80004348:	01050913          	addi	s2,a0,16
    8000434c:	854a                	mv	a0,s2
    8000434e:	00001097          	auipc	ra,0x1
    80004352:	c8c080e7          	jalr	-884(ra) # 80004fda <holdingsleep>
    80004356:	cd19                	beqz	a0,80004374 <iunlock+0x3c>
    80004358:	449c                	lw	a5,8(s1)
    8000435a:	00f05d63          	blez	a5,80004374 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000435e:	854a                	mv	a0,s2
    80004360:	00001097          	auipc	ra,0x1
    80004364:	c36080e7          	jalr	-970(ra) # 80004f96 <releasesleep>
}
    80004368:	60e2                	ld	ra,24(sp)
    8000436a:	6442                	ld	s0,16(sp)
    8000436c:	64a2                	ld	s1,8(sp)
    8000436e:	6902                	ld	s2,0(sp)
    80004370:	6105                	addi	sp,sp,32
    80004372:	8082                	ret
    panic("iunlock");
    80004374:	00004517          	auipc	a0,0x4
    80004378:	3d450513          	addi	a0,a0,980 # 80008748 <syscalls+0x1a8>
    8000437c:	ffffc097          	auipc	ra,0xffffc
    80004380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>

0000000080004384 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004384:	7179                	addi	sp,sp,-48
    80004386:	f406                	sd	ra,40(sp)
    80004388:	f022                	sd	s0,32(sp)
    8000438a:	ec26                	sd	s1,24(sp)
    8000438c:	e84a                	sd	s2,16(sp)
    8000438e:	e44e                	sd	s3,8(sp)
    80004390:	e052                	sd	s4,0(sp)
    80004392:	1800                	addi	s0,sp,48
    80004394:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004396:	05050493          	addi	s1,a0,80
    8000439a:	08050913          	addi	s2,a0,128
    8000439e:	a021                	j	800043a6 <itrunc+0x22>
    800043a0:	0491                	addi	s1,s1,4
    800043a2:	01248d63          	beq	s1,s2,800043bc <itrunc+0x38>
    if(ip->addrs[i]){
    800043a6:	408c                	lw	a1,0(s1)
    800043a8:	dde5                	beqz	a1,800043a0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800043aa:	0009a503          	lw	a0,0(s3)
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	90c080e7          	jalr	-1780(ra) # 80003cba <bfree>
      ip->addrs[i] = 0;
    800043b6:	0004a023          	sw	zero,0(s1)
    800043ba:	b7dd                	j	800043a0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800043bc:	0809a583          	lw	a1,128(s3)
    800043c0:	e185                	bnez	a1,800043e0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800043c2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800043c6:	854e                	mv	a0,s3
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	de4080e7          	jalr	-540(ra) # 800041ac <iupdate>
}
    800043d0:	70a2                	ld	ra,40(sp)
    800043d2:	7402                	ld	s0,32(sp)
    800043d4:	64e2                	ld	s1,24(sp)
    800043d6:	6942                	ld	s2,16(sp)
    800043d8:	69a2                	ld	s3,8(sp)
    800043da:	6a02                	ld	s4,0(sp)
    800043dc:	6145                	addi	sp,sp,48
    800043de:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800043e0:	0009a503          	lw	a0,0(s3)
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	690080e7          	jalr	1680(ra) # 80003a74 <bread>
    800043ec:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800043ee:	05850493          	addi	s1,a0,88
    800043f2:	45850913          	addi	s2,a0,1112
    800043f6:	a811                	j	8000440a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800043f8:	0009a503          	lw	a0,0(s3)
    800043fc:	00000097          	auipc	ra,0x0
    80004400:	8be080e7          	jalr	-1858(ra) # 80003cba <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004404:	0491                	addi	s1,s1,4
    80004406:	01248563          	beq	s1,s2,80004410 <itrunc+0x8c>
      if(a[j])
    8000440a:	408c                	lw	a1,0(s1)
    8000440c:	dde5                	beqz	a1,80004404 <itrunc+0x80>
    8000440e:	b7ed                	j	800043f8 <itrunc+0x74>
    brelse(bp);
    80004410:	8552                	mv	a0,s4
    80004412:	fffff097          	auipc	ra,0xfffff
    80004416:	792080e7          	jalr	1938(ra) # 80003ba4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000441a:	0809a583          	lw	a1,128(s3)
    8000441e:	0009a503          	lw	a0,0(s3)
    80004422:	00000097          	auipc	ra,0x0
    80004426:	898080e7          	jalr	-1896(ra) # 80003cba <bfree>
    ip->addrs[NDIRECT] = 0;
    8000442a:	0809a023          	sw	zero,128(s3)
    8000442e:	bf51                	j	800043c2 <itrunc+0x3e>

0000000080004430 <iput>:
{
    80004430:	1101                	addi	sp,sp,-32
    80004432:	ec06                	sd	ra,24(sp)
    80004434:	e822                	sd	s0,16(sp)
    80004436:	e426                	sd	s1,8(sp)
    80004438:	e04a                	sd	s2,0(sp)
    8000443a:	1000                	addi	s0,sp,32
    8000443c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000443e:	0001c517          	auipc	a0,0x1c
    80004442:	c9a50513          	addi	a0,a0,-870 # 800200d8 <itable>
    80004446:	ffffc097          	auipc	ra,0xffffc
    8000444a:	7a6080e7          	jalr	1958(ra) # 80000bec <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000444e:	4498                	lw	a4,8(s1)
    80004450:	4785                	li	a5,1
    80004452:	02f70363          	beq	a4,a5,80004478 <iput+0x48>
  ip->ref--;
    80004456:	449c                	lw	a5,8(s1)
    80004458:	37fd                	addiw	a5,a5,-1
    8000445a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000445c:	0001c517          	auipc	a0,0x1c
    80004460:	c7c50513          	addi	a0,a0,-900 # 800200d8 <itable>
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	842080e7          	jalr	-1982(ra) # 80000ca6 <release>
}
    8000446c:	60e2                	ld	ra,24(sp)
    8000446e:	6442                	ld	s0,16(sp)
    80004470:	64a2                	ld	s1,8(sp)
    80004472:	6902                	ld	s2,0(sp)
    80004474:	6105                	addi	sp,sp,32
    80004476:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004478:	40bc                	lw	a5,64(s1)
    8000447a:	dff1                	beqz	a5,80004456 <iput+0x26>
    8000447c:	04a49783          	lh	a5,74(s1)
    80004480:	fbf9                	bnez	a5,80004456 <iput+0x26>
    acquiresleep(&ip->lock);
    80004482:	01048913          	addi	s2,s1,16
    80004486:	854a                	mv	a0,s2
    80004488:	00001097          	auipc	ra,0x1
    8000448c:	ab8080e7          	jalr	-1352(ra) # 80004f40 <acquiresleep>
    release(&itable.lock);
    80004490:	0001c517          	auipc	a0,0x1c
    80004494:	c4850513          	addi	a0,a0,-952 # 800200d8 <itable>
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	80e080e7          	jalr	-2034(ra) # 80000ca6 <release>
    itrunc(ip);
    800044a0:	8526                	mv	a0,s1
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	ee2080e7          	jalr	-286(ra) # 80004384 <itrunc>
    ip->type = 0;
    800044aa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800044ae:	8526                	mv	a0,s1
    800044b0:	00000097          	auipc	ra,0x0
    800044b4:	cfc080e7          	jalr	-772(ra) # 800041ac <iupdate>
    ip->valid = 0;
    800044b8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800044bc:	854a                	mv	a0,s2
    800044be:	00001097          	auipc	ra,0x1
    800044c2:	ad8080e7          	jalr	-1320(ra) # 80004f96 <releasesleep>
    acquire(&itable.lock);
    800044c6:	0001c517          	auipc	a0,0x1c
    800044ca:	c1250513          	addi	a0,a0,-1006 # 800200d8 <itable>
    800044ce:	ffffc097          	auipc	ra,0xffffc
    800044d2:	71e080e7          	jalr	1822(ra) # 80000bec <acquire>
    800044d6:	b741                	j	80004456 <iput+0x26>

00000000800044d8 <iunlockput>:
{
    800044d8:	1101                	addi	sp,sp,-32
    800044da:	ec06                	sd	ra,24(sp)
    800044dc:	e822                	sd	s0,16(sp)
    800044de:	e426                	sd	s1,8(sp)
    800044e0:	1000                	addi	s0,sp,32
    800044e2:	84aa                	mv	s1,a0
  iunlock(ip);
    800044e4:	00000097          	auipc	ra,0x0
    800044e8:	e54080e7          	jalr	-428(ra) # 80004338 <iunlock>
  iput(ip);
    800044ec:	8526                	mv	a0,s1
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	f42080e7          	jalr	-190(ra) # 80004430 <iput>
}
    800044f6:	60e2                	ld	ra,24(sp)
    800044f8:	6442                	ld	s0,16(sp)
    800044fa:	64a2                	ld	s1,8(sp)
    800044fc:	6105                	addi	sp,sp,32
    800044fe:	8082                	ret

0000000080004500 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004500:	1141                	addi	sp,sp,-16
    80004502:	e422                	sd	s0,8(sp)
    80004504:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004506:	411c                	lw	a5,0(a0)
    80004508:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000450a:	415c                	lw	a5,4(a0)
    8000450c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000450e:	04451783          	lh	a5,68(a0)
    80004512:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004516:	04a51783          	lh	a5,74(a0)
    8000451a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000451e:	04c56783          	lwu	a5,76(a0)
    80004522:	e99c                	sd	a5,16(a1)
}
    80004524:	6422                	ld	s0,8(sp)
    80004526:	0141                	addi	sp,sp,16
    80004528:	8082                	ret

000000008000452a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000452a:	457c                	lw	a5,76(a0)
    8000452c:	0ed7e963          	bltu	a5,a3,8000461e <readi+0xf4>
{
    80004530:	7159                	addi	sp,sp,-112
    80004532:	f486                	sd	ra,104(sp)
    80004534:	f0a2                	sd	s0,96(sp)
    80004536:	eca6                	sd	s1,88(sp)
    80004538:	e8ca                	sd	s2,80(sp)
    8000453a:	e4ce                	sd	s3,72(sp)
    8000453c:	e0d2                	sd	s4,64(sp)
    8000453e:	fc56                	sd	s5,56(sp)
    80004540:	f85a                	sd	s6,48(sp)
    80004542:	f45e                	sd	s7,40(sp)
    80004544:	f062                	sd	s8,32(sp)
    80004546:	ec66                	sd	s9,24(sp)
    80004548:	e86a                	sd	s10,16(sp)
    8000454a:	e46e                	sd	s11,8(sp)
    8000454c:	1880                	addi	s0,sp,112
    8000454e:	8baa                	mv	s7,a0
    80004550:	8c2e                	mv	s8,a1
    80004552:	8ab2                	mv	s5,a2
    80004554:	84b6                	mv	s1,a3
    80004556:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004558:	9f35                	addw	a4,a4,a3
    return 0;
    8000455a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000455c:	0ad76063          	bltu	a4,a3,800045fc <readi+0xd2>
  if(off + n > ip->size)
    80004560:	00e7f463          	bgeu	a5,a4,80004568 <readi+0x3e>
    n = ip->size - off;
    80004564:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004568:	0a0b0963          	beqz	s6,8000461a <readi+0xf0>
    8000456c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000456e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004572:	5cfd                	li	s9,-1
    80004574:	a82d                	j	800045ae <readi+0x84>
    80004576:	020a1d93          	slli	s11,s4,0x20
    8000457a:	020ddd93          	srli	s11,s11,0x20
    8000457e:	05890613          	addi	a2,s2,88
    80004582:	86ee                	mv	a3,s11
    80004584:	963a                	add	a2,a2,a4
    80004586:	85d6                	mv	a1,s5
    80004588:	8562                	mv	a0,s8
    8000458a:	fffff097          	auipc	ra,0xfffff
    8000458e:	ae4080e7          	jalr	-1308(ra) # 8000306e <either_copyout>
    80004592:	05950d63          	beq	a0,s9,800045ec <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004596:	854a                	mv	a0,s2
    80004598:	fffff097          	auipc	ra,0xfffff
    8000459c:	60c080e7          	jalr	1548(ra) # 80003ba4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045a0:	013a09bb          	addw	s3,s4,s3
    800045a4:	009a04bb          	addw	s1,s4,s1
    800045a8:	9aee                	add	s5,s5,s11
    800045aa:	0569f763          	bgeu	s3,s6,800045f8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800045ae:	000ba903          	lw	s2,0(s7)
    800045b2:	00a4d59b          	srliw	a1,s1,0xa
    800045b6:	855e                	mv	a0,s7
    800045b8:	00000097          	auipc	ra,0x0
    800045bc:	8b0080e7          	jalr	-1872(ra) # 80003e68 <bmap>
    800045c0:	0005059b          	sext.w	a1,a0
    800045c4:	854a                	mv	a0,s2
    800045c6:	fffff097          	auipc	ra,0xfffff
    800045ca:	4ae080e7          	jalr	1198(ra) # 80003a74 <bread>
    800045ce:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800045d0:	3ff4f713          	andi	a4,s1,1023
    800045d4:	40ed07bb          	subw	a5,s10,a4
    800045d8:	413b06bb          	subw	a3,s6,s3
    800045dc:	8a3e                	mv	s4,a5
    800045de:	2781                	sext.w	a5,a5
    800045e0:	0006861b          	sext.w	a2,a3
    800045e4:	f8f679e3          	bgeu	a2,a5,80004576 <readi+0x4c>
    800045e8:	8a36                	mv	s4,a3
    800045ea:	b771                	j	80004576 <readi+0x4c>
      brelse(bp);
    800045ec:	854a                	mv	a0,s2
    800045ee:	fffff097          	auipc	ra,0xfffff
    800045f2:	5b6080e7          	jalr	1462(ra) # 80003ba4 <brelse>
      tot = -1;
    800045f6:	59fd                	li	s3,-1
  }
  return tot;
    800045f8:	0009851b          	sext.w	a0,s3
}
    800045fc:	70a6                	ld	ra,104(sp)
    800045fe:	7406                	ld	s0,96(sp)
    80004600:	64e6                	ld	s1,88(sp)
    80004602:	6946                	ld	s2,80(sp)
    80004604:	69a6                	ld	s3,72(sp)
    80004606:	6a06                	ld	s4,64(sp)
    80004608:	7ae2                	ld	s5,56(sp)
    8000460a:	7b42                	ld	s6,48(sp)
    8000460c:	7ba2                	ld	s7,40(sp)
    8000460e:	7c02                	ld	s8,32(sp)
    80004610:	6ce2                	ld	s9,24(sp)
    80004612:	6d42                	ld	s10,16(sp)
    80004614:	6da2                	ld	s11,8(sp)
    80004616:	6165                	addi	sp,sp,112
    80004618:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000461a:	89da                	mv	s3,s6
    8000461c:	bff1                	j	800045f8 <readi+0xce>
    return 0;
    8000461e:	4501                	li	a0,0
}
    80004620:	8082                	ret

0000000080004622 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004622:	457c                	lw	a5,76(a0)
    80004624:	10d7e863          	bltu	a5,a3,80004734 <writei+0x112>
{
    80004628:	7159                	addi	sp,sp,-112
    8000462a:	f486                	sd	ra,104(sp)
    8000462c:	f0a2                	sd	s0,96(sp)
    8000462e:	eca6                	sd	s1,88(sp)
    80004630:	e8ca                	sd	s2,80(sp)
    80004632:	e4ce                	sd	s3,72(sp)
    80004634:	e0d2                	sd	s4,64(sp)
    80004636:	fc56                	sd	s5,56(sp)
    80004638:	f85a                	sd	s6,48(sp)
    8000463a:	f45e                	sd	s7,40(sp)
    8000463c:	f062                	sd	s8,32(sp)
    8000463e:	ec66                	sd	s9,24(sp)
    80004640:	e86a                	sd	s10,16(sp)
    80004642:	e46e                	sd	s11,8(sp)
    80004644:	1880                	addi	s0,sp,112
    80004646:	8b2a                	mv	s6,a0
    80004648:	8c2e                	mv	s8,a1
    8000464a:	8ab2                	mv	s5,a2
    8000464c:	8936                	mv	s2,a3
    8000464e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004650:	00e687bb          	addw	a5,a3,a4
    80004654:	0ed7e263          	bltu	a5,a3,80004738 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004658:	00043737          	lui	a4,0x43
    8000465c:	0ef76063          	bltu	a4,a5,8000473c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004660:	0c0b8863          	beqz	s7,80004730 <writei+0x10e>
    80004664:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004666:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000466a:	5cfd                	li	s9,-1
    8000466c:	a091                	j	800046b0 <writei+0x8e>
    8000466e:	02099d93          	slli	s11,s3,0x20
    80004672:	020ddd93          	srli	s11,s11,0x20
    80004676:	05848513          	addi	a0,s1,88
    8000467a:	86ee                	mv	a3,s11
    8000467c:	8656                	mv	a2,s5
    8000467e:	85e2                	mv	a1,s8
    80004680:	953a                	add	a0,a0,a4
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	a42080e7          	jalr	-1470(ra) # 800030c4 <either_copyin>
    8000468a:	07950263          	beq	a0,s9,800046ee <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000468e:	8526                	mv	a0,s1
    80004690:	00000097          	auipc	ra,0x0
    80004694:	790080e7          	jalr	1936(ra) # 80004e20 <log_write>
    brelse(bp);
    80004698:	8526                	mv	a0,s1
    8000469a:	fffff097          	auipc	ra,0xfffff
    8000469e:	50a080e7          	jalr	1290(ra) # 80003ba4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046a2:	01498a3b          	addw	s4,s3,s4
    800046a6:	0129893b          	addw	s2,s3,s2
    800046aa:	9aee                	add	s5,s5,s11
    800046ac:	057a7663          	bgeu	s4,s7,800046f8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800046b0:	000b2483          	lw	s1,0(s6)
    800046b4:	00a9559b          	srliw	a1,s2,0xa
    800046b8:	855a                	mv	a0,s6
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	7ae080e7          	jalr	1966(ra) # 80003e68 <bmap>
    800046c2:	0005059b          	sext.w	a1,a0
    800046c6:	8526                	mv	a0,s1
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	3ac080e7          	jalr	940(ra) # 80003a74 <bread>
    800046d0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800046d2:	3ff97713          	andi	a4,s2,1023
    800046d6:	40ed07bb          	subw	a5,s10,a4
    800046da:	414b86bb          	subw	a3,s7,s4
    800046de:	89be                	mv	s3,a5
    800046e0:	2781                	sext.w	a5,a5
    800046e2:	0006861b          	sext.w	a2,a3
    800046e6:	f8f674e3          	bgeu	a2,a5,8000466e <writei+0x4c>
    800046ea:	89b6                	mv	s3,a3
    800046ec:	b749                	j	8000466e <writei+0x4c>
      brelse(bp);
    800046ee:	8526                	mv	a0,s1
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	4b4080e7          	jalr	1204(ra) # 80003ba4 <brelse>
  }

  if(off > ip->size)
    800046f8:	04cb2783          	lw	a5,76(s6)
    800046fc:	0127f463          	bgeu	a5,s2,80004704 <writei+0xe2>
    ip->size = off;
    80004700:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004704:	855a                	mv	a0,s6
    80004706:	00000097          	auipc	ra,0x0
    8000470a:	aa6080e7          	jalr	-1370(ra) # 800041ac <iupdate>

  return tot;
    8000470e:	000a051b          	sext.w	a0,s4
}
    80004712:	70a6                	ld	ra,104(sp)
    80004714:	7406                	ld	s0,96(sp)
    80004716:	64e6                	ld	s1,88(sp)
    80004718:	6946                	ld	s2,80(sp)
    8000471a:	69a6                	ld	s3,72(sp)
    8000471c:	6a06                	ld	s4,64(sp)
    8000471e:	7ae2                	ld	s5,56(sp)
    80004720:	7b42                	ld	s6,48(sp)
    80004722:	7ba2                	ld	s7,40(sp)
    80004724:	7c02                	ld	s8,32(sp)
    80004726:	6ce2                	ld	s9,24(sp)
    80004728:	6d42                	ld	s10,16(sp)
    8000472a:	6da2                	ld	s11,8(sp)
    8000472c:	6165                	addi	sp,sp,112
    8000472e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004730:	8a5e                	mv	s4,s7
    80004732:	bfc9                	j	80004704 <writei+0xe2>
    return -1;
    80004734:	557d                	li	a0,-1
}
    80004736:	8082                	ret
    return -1;
    80004738:	557d                	li	a0,-1
    8000473a:	bfe1                	j	80004712 <writei+0xf0>
    return -1;
    8000473c:	557d                	li	a0,-1
    8000473e:	bfd1                	j	80004712 <writei+0xf0>

0000000080004740 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004740:	1141                	addi	sp,sp,-16
    80004742:	e406                	sd	ra,8(sp)
    80004744:	e022                	sd	s0,0(sp)
    80004746:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004748:	4639                	li	a2,14
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	67c080e7          	jalr	1660(ra) # 80000dc6 <strncmp>
}
    80004752:	60a2                	ld	ra,8(sp)
    80004754:	6402                	ld	s0,0(sp)
    80004756:	0141                	addi	sp,sp,16
    80004758:	8082                	ret

000000008000475a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000475a:	7139                	addi	sp,sp,-64
    8000475c:	fc06                	sd	ra,56(sp)
    8000475e:	f822                	sd	s0,48(sp)
    80004760:	f426                	sd	s1,40(sp)
    80004762:	f04a                	sd	s2,32(sp)
    80004764:	ec4e                	sd	s3,24(sp)
    80004766:	e852                	sd	s4,16(sp)
    80004768:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000476a:	04451703          	lh	a4,68(a0)
    8000476e:	4785                	li	a5,1
    80004770:	00f71a63          	bne	a4,a5,80004784 <dirlookup+0x2a>
    80004774:	892a                	mv	s2,a0
    80004776:	89ae                	mv	s3,a1
    80004778:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000477a:	457c                	lw	a5,76(a0)
    8000477c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000477e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004780:	e79d                	bnez	a5,800047ae <dirlookup+0x54>
    80004782:	a8a5                	j	800047fa <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004784:	00004517          	auipc	a0,0x4
    80004788:	fcc50513          	addi	a0,a0,-52 # 80008750 <syscalls+0x1b0>
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	db2080e7          	jalr	-590(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004794:	00004517          	auipc	a0,0x4
    80004798:	fd450513          	addi	a0,a0,-44 # 80008768 <syscalls+0x1c8>
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	da2080e7          	jalr	-606(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047a4:	24c1                	addiw	s1,s1,16
    800047a6:	04c92783          	lw	a5,76(s2)
    800047aa:	04f4f763          	bgeu	s1,a5,800047f8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047ae:	4741                	li	a4,16
    800047b0:	86a6                	mv	a3,s1
    800047b2:	fc040613          	addi	a2,s0,-64
    800047b6:	4581                	li	a1,0
    800047b8:	854a                	mv	a0,s2
    800047ba:	00000097          	auipc	ra,0x0
    800047be:	d70080e7          	jalr	-656(ra) # 8000452a <readi>
    800047c2:	47c1                	li	a5,16
    800047c4:	fcf518e3          	bne	a0,a5,80004794 <dirlookup+0x3a>
    if(de.inum == 0)
    800047c8:	fc045783          	lhu	a5,-64(s0)
    800047cc:	dfe1                	beqz	a5,800047a4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800047ce:	fc240593          	addi	a1,s0,-62
    800047d2:	854e                	mv	a0,s3
    800047d4:	00000097          	auipc	ra,0x0
    800047d8:	f6c080e7          	jalr	-148(ra) # 80004740 <namecmp>
    800047dc:	f561                	bnez	a0,800047a4 <dirlookup+0x4a>
      if(poff)
    800047de:	000a0463          	beqz	s4,800047e6 <dirlookup+0x8c>
        *poff = off;
    800047e2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800047e6:	fc045583          	lhu	a1,-64(s0)
    800047ea:	00092503          	lw	a0,0(s2)
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	754080e7          	jalr	1876(ra) # 80003f42 <iget>
    800047f6:	a011                	j	800047fa <dirlookup+0xa0>
  return 0;
    800047f8:	4501                	li	a0,0
}
    800047fa:	70e2                	ld	ra,56(sp)
    800047fc:	7442                	ld	s0,48(sp)
    800047fe:	74a2                	ld	s1,40(sp)
    80004800:	7902                	ld	s2,32(sp)
    80004802:	69e2                	ld	s3,24(sp)
    80004804:	6a42                	ld	s4,16(sp)
    80004806:	6121                	addi	sp,sp,64
    80004808:	8082                	ret

000000008000480a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000480a:	711d                	addi	sp,sp,-96
    8000480c:	ec86                	sd	ra,88(sp)
    8000480e:	e8a2                	sd	s0,80(sp)
    80004810:	e4a6                	sd	s1,72(sp)
    80004812:	e0ca                	sd	s2,64(sp)
    80004814:	fc4e                	sd	s3,56(sp)
    80004816:	f852                	sd	s4,48(sp)
    80004818:	f456                	sd	s5,40(sp)
    8000481a:	f05a                	sd	s6,32(sp)
    8000481c:	ec5e                	sd	s7,24(sp)
    8000481e:	e862                	sd	s8,16(sp)
    80004820:	e466                	sd	s9,8(sp)
    80004822:	1080                	addi	s0,sp,96
    80004824:	84aa                	mv	s1,a0
    80004826:	8b2e                	mv	s6,a1
    80004828:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000482a:	00054703          	lbu	a4,0(a0)
    8000482e:	02f00793          	li	a5,47
    80004832:	02f70363          	beq	a4,a5,80004858 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004836:	ffffe097          	auipc	ra,0xffffe
    8000483a:	a56080e7          	jalr	-1450(ra) # 8000228c <myproc>
    8000483e:	17853503          	ld	a0,376(a0)
    80004842:	00000097          	auipc	ra,0x0
    80004846:	9f6080e7          	jalr	-1546(ra) # 80004238 <idup>
    8000484a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000484c:	02f00913          	li	s2,47
  len = path - s;
    80004850:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004852:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004854:	4c05                	li	s8,1
    80004856:	a865                	j	8000490e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004858:	4585                	li	a1,1
    8000485a:	4505                	li	a0,1
    8000485c:	fffff097          	auipc	ra,0xfffff
    80004860:	6e6080e7          	jalr	1766(ra) # 80003f42 <iget>
    80004864:	89aa                	mv	s3,a0
    80004866:	b7dd                	j	8000484c <namex+0x42>
      iunlockput(ip);
    80004868:	854e                	mv	a0,s3
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	c6e080e7          	jalr	-914(ra) # 800044d8 <iunlockput>
      return 0;
    80004872:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004874:	854e                	mv	a0,s3
    80004876:	60e6                	ld	ra,88(sp)
    80004878:	6446                	ld	s0,80(sp)
    8000487a:	64a6                	ld	s1,72(sp)
    8000487c:	6906                	ld	s2,64(sp)
    8000487e:	79e2                	ld	s3,56(sp)
    80004880:	7a42                	ld	s4,48(sp)
    80004882:	7aa2                	ld	s5,40(sp)
    80004884:	7b02                	ld	s6,32(sp)
    80004886:	6be2                	ld	s7,24(sp)
    80004888:	6c42                	ld	s8,16(sp)
    8000488a:	6ca2                	ld	s9,8(sp)
    8000488c:	6125                	addi	sp,sp,96
    8000488e:	8082                	ret
      iunlock(ip);
    80004890:	854e                	mv	a0,s3
    80004892:	00000097          	auipc	ra,0x0
    80004896:	aa6080e7          	jalr	-1370(ra) # 80004338 <iunlock>
      return ip;
    8000489a:	bfe9                	j	80004874 <namex+0x6a>
      iunlockput(ip);
    8000489c:	854e                	mv	a0,s3
    8000489e:	00000097          	auipc	ra,0x0
    800048a2:	c3a080e7          	jalr	-966(ra) # 800044d8 <iunlockput>
      return 0;
    800048a6:	89d2                	mv	s3,s4
    800048a8:	b7f1                	j	80004874 <namex+0x6a>
  len = path - s;
    800048aa:	40b48633          	sub	a2,s1,a1
    800048ae:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800048b2:	094cd463          	bge	s9,s4,8000493a <namex+0x130>
    memmove(name, s, DIRSIZ);
    800048b6:	4639                	li	a2,14
    800048b8:	8556                	mv	a0,s5
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	494080e7          	jalr	1172(ra) # 80000d4e <memmove>
  while(*path == '/')
    800048c2:	0004c783          	lbu	a5,0(s1)
    800048c6:	01279763          	bne	a5,s2,800048d4 <namex+0xca>
    path++;
    800048ca:	0485                	addi	s1,s1,1
  while(*path == '/')
    800048cc:	0004c783          	lbu	a5,0(s1)
    800048d0:	ff278de3          	beq	a5,s2,800048ca <namex+0xc0>
    ilock(ip);
    800048d4:	854e                	mv	a0,s3
    800048d6:	00000097          	auipc	ra,0x0
    800048da:	9a0080e7          	jalr	-1632(ra) # 80004276 <ilock>
    if(ip->type != T_DIR){
    800048de:	04499783          	lh	a5,68(s3)
    800048e2:	f98793e3          	bne	a5,s8,80004868 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800048e6:	000b0563          	beqz	s6,800048f0 <namex+0xe6>
    800048ea:	0004c783          	lbu	a5,0(s1)
    800048ee:	d3cd                	beqz	a5,80004890 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800048f0:	865e                	mv	a2,s7
    800048f2:	85d6                	mv	a1,s5
    800048f4:	854e                	mv	a0,s3
    800048f6:	00000097          	auipc	ra,0x0
    800048fa:	e64080e7          	jalr	-412(ra) # 8000475a <dirlookup>
    800048fe:	8a2a                	mv	s4,a0
    80004900:	dd51                	beqz	a0,8000489c <namex+0x92>
    iunlockput(ip);
    80004902:	854e                	mv	a0,s3
    80004904:	00000097          	auipc	ra,0x0
    80004908:	bd4080e7          	jalr	-1068(ra) # 800044d8 <iunlockput>
    ip = next;
    8000490c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000490e:	0004c783          	lbu	a5,0(s1)
    80004912:	05279763          	bne	a5,s2,80004960 <namex+0x156>
    path++;
    80004916:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004918:	0004c783          	lbu	a5,0(s1)
    8000491c:	ff278de3          	beq	a5,s2,80004916 <namex+0x10c>
  if(*path == 0)
    80004920:	c79d                	beqz	a5,8000494e <namex+0x144>
    path++;
    80004922:	85a6                	mv	a1,s1
  len = path - s;
    80004924:	8a5e                	mv	s4,s7
    80004926:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004928:	01278963          	beq	a5,s2,8000493a <namex+0x130>
    8000492c:	dfbd                	beqz	a5,800048aa <namex+0xa0>
    path++;
    8000492e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004930:	0004c783          	lbu	a5,0(s1)
    80004934:	ff279ce3          	bne	a5,s2,8000492c <namex+0x122>
    80004938:	bf8d                	j	800048aa <namex+0xa0>
    memmove(name, s, len);
    8000493a:	2601                	sext.w	a2,a2
    8000493c:	8556                	mv	a0,s5
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	410080e7          	jalr	1040(ra) # 80000d4e <memmove>
    name[len] = 0;
    80004946:	9a56                	add	s4,s4,s5
    80004948:	000a0023          	sb	zero,0(s4)
    8000494c:	bf9d                	j	800048c2 <namex+0xb8>
  if(nameiparent){
    8000494e:	f20b03e3          	beqz	s6,80004874 <namex+0x6a>
    iput(ip);
    80004952:	854e                	mv	a0,s3
    80004954:	00000097          	auipc	ra,0x0
    80004958:	adc080e7          	jalr	-1316(ra) # 80004430 <iput>
    return 0;
    8000495c:	4981                	li	s3,0
    8000495e:	bf19                	j	80004874 <namex+0x6a>
  if(*path == 0)
    80004960:	d7fd                	beqz	a5,8000494e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004962:	0004c783          	lbu	a5,0(s1)
    80004966:	85a6                	mv	a1,s1
    80004968:	b7d1                	j	8000492c <namex+0x122>

000000008000496a <dirlink>:
{
    8000496a:	7139                	addi	sp,sp,-64
    8000496c:	fc06                	sd	ra,56(sp)
    8000496e:	f822                	sd	s0,48(sp)
    80004970:	f426                	sd	s1,40(sp)
    80004972:	f04a                	sd	s2,32(sp)
    80004974:	ec4e                	sd	s3,24(sp)
    80004976:	e852                	sd	s4,16(sp)
    80004978:	0080                	addi	s0,sp,64
    8000497a:	892a                	mv	s2,a0
    8000497c:	8a2e                	mv	s4,a1
    8000497e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004980:	4601                	li	a2,0
    80004982:	00000097          	auipc	ra,0x0
    80004986:	dd8080e7          	jalr	-552(ra) # 8000475a <dirlookup>
    8000498a:	e93d                	bnez	a0,80004a00 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000498c:	04c92483          	lw	s1,76(s2)
    80004990:	c49d                	beqz	s1,800049be <dirlink+0x54>
    80004992:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004994:	4741                	li	a4,16
    80004996:	86a6                	mv	a3,s1
    80004998:	fc040613          	addi	a2,s0,-64
    8000499c:	4581                	li	a1,0
    8000499e:	854a                	mv	a0,s2
    800049a0:	00000097          	auipc	ra,0x0
    800049a4:	b8a080e7          	jalr	-1142(ra) # 8000452a <readi>
    800049a8:	47c1                	li	a5,16
    800049aa:	06f51163          	bne	a0,a5,80004a0c <dirlink+0xa2>
    if(de.inum == 0)
    800049ae:	fc045783          	lhu	a5,-64(s0)
    800049b2:	c791                	beqz	a5,800049be <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049b4:	24c1                	addiw	s1,s1,16
    800049b6:	04c92783          	lw	a5,76(s2)
    800049ba:	fcf4ede3          	bltu	s1,a5,80004994 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800049be:	4639                	li	a2,14
    800049c0:	85d2                	mv	a1,s4
    800049c2:	fc240513          	addi	a0,s0,-62
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	43c080e7          	jalr	1084(ra) # 80000e02 <strncpy>
  de.inum = inum;
    800049ce:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049d2:	4741                	li	a4,16
    800049d4:	86a6                	mv	a3,s1
    800049d6:	fc040613          	addi	a2,s0,-64
    800049da:	4581                	li	a1,0
    800049dc:	854a                	mv	a0,s2
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	c44080e7          	jalr	-956(ra) # 80004622 <writei>
    800049e6:	872a                	mv	a4,a0
    800049e8:	47c1                	li	a5,16
  return 0;
    800049ea:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049ec:	02f71863          	bne	a4,a5,80004a1c <dirlink+0xb2>
}
    800049f0:	70e2                	ld	ra,56(sp)
    800049f2:	7442                	ld	s0,48(sp)
    800049f4:	74a2                	ld	s1,40(sp)
    800049f6:	7902                	ld	s2,32(sp)
    800049f8:	69e2                	ld	s3,24(sp)
    800049fa:	6a42                	ld	s4,16(sp)
    800049fc:	6121                	addi	sp,sp,64
    800049fe:	8082                	ret
    iput(ip);
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	a30080e7          	jalr	-1488(ra) # 80004430 <iput>
    return -1;
    80004a08:	557d                	li	a0,-1
    80004a0a:	b7dd                	j	800049f0 <dirlink+0x86>
      panic("dirlink read");
    80004a0c:	00004517          	auipc	a0,0x4
    80004a10:	d6c50513          	addi	a0,a0,-660 # 80008778 <syscalls+0x1d8>
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	b2a080e7          	jalr	-1238(ra) # 8000053e <panic>
    panic("dirlink");
    80004a1c:	00004517          	auipc	a0,0x4
    80004a20:	e6c50513          	addi	a0,a0,-404 # 80008888 <syscalls+0x2e8>
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	b1a080e7          	jalr	-1254(ra) # 8000053e <panic>

0000000080004a2c <namei>:

struct inode*
namei(char *path)
{
    80004a2c:	1101                	addi	sp,sp,-32
    80004a2e:	ec06                	sd	ra,24(sp)
    80004a30:	e822                	sd	s0,16(sp)
    80004a32:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004a34:	fe040613          	addi	a2,s0,-32
    80004a38:	4581                	li	a1,0
    80004a3a:	00000097          	auipc	ra,0x0
    80004a3e:	dd0080e7          	jalr	-560(ra) # 8000480a <namex>
}
    80004a42:	60e2                	ld	ra,24(sp)
    80004a44:	6442                	ld	s0,16(sp)
    80004a46:	6105                	addi	sp,sp,32
    80004a48:	8082                	ret

0000000080004a4a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004a4a:	1141                	addi	sp,sp,-16
    80004a4c:	e406                	sd	ra,8(sp)
    80004a4e:	e022                	sd	s0,0(sp)
    80004a50:	0800                	addi	s0,sp,16
    80004a52:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004a54:	4585                	li	a1,1
    80004a56:	00000097          	auipc	ra,0x0
    80004a5a:	db4080e7          	jalr	-588(ra) # 8000480a <namex>
}
    80004a5e:	60a2                	ld	ra,8(sp)
    80004a60:	6402                	ld	s0,0(sp)
    80004a62:	0141                	addi	sp,sp,16
    80004a64:	8082                	ret

0000000080004a66 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004a66:	1101                	addi	sp,sp,-32
    80004a68:	ec06                	sd	ra,24(sp)
    80004a6a:	e822                	sd	s0,16(sp)
    80004a6c:	e426                	sd	s1,8(sp)
    80004a6e:	e04a                	sd	s2,0(sp)
    80004a70:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004a72:	0001d917          	auipc	s2,0x1d
    80004a76:	10e90913          	addi	s2,s2,270 # 80021b80 <log>
    80004a7a:	01892583          	lw	a1,24(s2)
    80004a7e:	02892503          	lw	a0,40(s2)
    80004a82:	fffff097          	auipc	ra,0xfffff
    80004a86:	ff2080e7          	jalr	-14(ra) # 80003a74 <bread>
    80004a8a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004a8c:	02c92683          	lw	a3,44(s2)
    80004a90:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004a92:	02d05763          	blez	a3,80004ac0 <write_head+0x5a>
    80004a96:	0001d797          	auipc	a5,0x1d
    80004a9a:	11a78793          	addi	a5,a5,282 # 80021bb0 <log+0x30>
    80004a9e:	05c50713          	addi	a4,a0,92
    80004aa2:	36fd                	addiw	a3,a3,-1
    80004aa4:	1682                	slli	a3,a3,0x20
    80004aa6:	9281                	srli	a3,a3,0x20
    80004aa8:	068a                	slli	a3,a3,0x2
    80004aaa:	0001d617          	auipc	a2,0x1d
    80004aae:	10a60613          	addi	a2,a2,266 # 80021bb4 <log+0x34>
    80004ab2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004ab4:	4390                	lw	a2,0(a5)
    80004ab6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004ab8:	0791                	addi	a5,a5,4
    80004aba:	0711                	addi	a4,a4,4
    80004abc:	fed79ce3          	bne	a5,a3,80004ab4 <write_head+0x4e>
  }
  bwrite(buf);
    80004ac0:	8526                	mv	a0,s1
    80004ac2:	fffff097          	auipc	ra,0xfffff
    80004ac6:	0a4080e7          	jalr	164(ra) # 80003b66 <bwrite>
  brelse(buf);
    80004aca:	8526                	mv	a0,s1
    80004acc:	fffff097          	auipc	ra,0xfffff
    80004ad0:	0d8080e7          	jalr	216(ra) # 80003ba4 <brelse>
}
    80004ad4:	60e2                	ld	ra,24(sp)
    80004ad6:	6442                	ld	s0,16(sp)
    80004ad8:	64a2                	ld	s1,8(sp)
    80004ada:	6902                	ld	s2,0(sp)
    80004adc:	6105                	addi	sp,sp,32
    80004ade:	8082                	ret

0000000080004ae0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ae0:	0001d797          	auipc	a5,0x1d
    80004ae4:	0cc7a783          	lw	a5,204(a5) # 80021bac <log+0x2c>
    80004ae8:	0af05d63          	blez	a5,80004ba2 <install_trans+0xc2>
{
    80004aec:	7139                	addi	sp,sp,-64
    80004aee:	fc06                	sd	ra,56(sp)
    80004af0:	f822                	sd	s0,48(sp)
    80004af2:	f426                	sd	s1,40(sp)
    80004af4:	f04a                	sd	s2,32(sp)
    80004af6:	ec4e                	sd	s3,24(sp)
    80004af8:	e852                	sd	s4,16(sp)
    80004afa:	e456                	sd	s5,8(sp)
    80004afc:	e05a                	sd	s6,0(sp)
    80004afe:	0080                	addi	s0,sp,64
    80004b00:	8b2a                	mv	s6,a0
    80004b02:	0001da97          	auipc	s5,0x1d
    80004b06:	0aea8a93          	addi	s5,s5,174 # 80021bb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b0a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b0c:	0001d997          	auipc	s3,0x1d
    80004b10:	07498993          	addi	s3,s3,116 # 80021b80 <log>
    80004b14:	a035                	j	80004b40 <install_trans+0x60>
      bunpin(dbuf);
    80004b16:	8526                	mv	a0,s1
    80004b18:	fffff097          	auipc	ra,0xfffff
    80004b1c:	166080e7          	jalr	358(ra) # 80003c7e <bunpin>
    brelse(lbuf);
    80004b20:	854a                	mv	a0,s2
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	082080e7          	jalr	130(ra) # 80003ba4 <brelse>
    brelse(dbuf);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	078080e7          	jalr	120(ra) # 80003ba4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b34:	2a05                	addiw	s4,s4,1
    80004b36:	0a91                	addi	s5,s5,4
    80004b38:	02c9a783          	lw	a5,44(s3)
    80004b3c:	04fa5963          	bge	s4,a5,80004b8e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b40:	0189a583          	lw	a1,24(s3)
    80004b44:	014585bb          	addw	a1,a1,s4
    80004b48:	2585                	addiw	a1,a1,1
    80004b4a:	0289a503          	lw	a0,40(s3)
    80004b4e:	fffff097          	auipc	ra,0xfffff
    80004b52:	f26080e7          	jalr	-218(ra) # 80003a74 <bread>
    80004b56:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b58:	000aa583          	lw	a1,0(s5)
    80004b5c:	0289a503          	lw	a0,40(s3)
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	f14080e7          	jalr	-236(ra) # 80003a74 <bread>
    80004b68:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004b6a:	40000613          	li	a2,1024
    80004b6e:	05890593          	addi	a1,s2,88
    80004b72:	05850513          	addi	a0,a0,88
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	1d8080e7          	jalr	472(ra) # 80000d4e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004b7e:	8526                	mv	a0,s1
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	fe6080e7          	jalr	-26(ra) # 80003b66 <bwrite>
    if(recovering == 0)
    80004b88:	f80b1ce3          	bnez	s6,80004b20 <install_trans+0x40>
    80004b8c:	b769                	j	80004b16 <install_trans+0x36>
}
    80004b8e:	70e2                	ld	ra,56(sp)
    80004b90:	7442                	ld	s0,48(sp)
    80004b92:	74a2                	ld	s1,40(sp)
    80004b94:	7902                	ld	s2,32(sp)
    80004b96:	69e2                	ld	s3,24(sp)
    80004b98:	6a42                	ld	s4,16(sp)
    80004b9a:	6aa2                	ld	s5,8(sp)
    80004b9c:	6b02                	ld	s6,0(sp)
    80004b9e:	6121                	addi	sp,sp,64
    80004ba0:	8082                	ret
    80004ba2:	8082                	ret

0000000080004ba4 <initlog>:
{
    80004ba4:	7179                	addi	sp,sp,-48
    80004ba6:	f406                	sd	ra,40(sp)
    80004ba8:	f022                	sd	s0,32(sp)
    80004baa:	ec26                	sd	s1,24(sp)
    80004bac:	e84a                	sd	s2,16(sp)
    80004bae:	e44e                	sd	s3,8(sp)
    80004bb0:	1800                	addi	s0,sp,48
    80004bb2:	892a                	mv	s2,a0
    80004bb4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004bb6:	0001d497          	auipc	s1,0x1d
    80004bba:	fca48493          	addi	s1,s1,-54 # 80021b80 <log>
    80004bbe:	00004597          	auipc	a1,0x4
    80004bc2:	bca58593          	addi	a1,a1,-1078 # 80008788 <syscalls+0x1e8>
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	f8c080e7          	jalr	-116(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004bd0:	0149a583          	lw	a1,20(s3)
    80004bd4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004bd6:	0109a783          	lw	a5,16(s3)
    80004bda:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004bdc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004be0:	854a                	mv	a0,s2
    80004be2:	fffff097          	auipc	ra,0xfffff
    80004be6:	e92080e7          	jalr	-366(ra) # 80003a74 <bread>
  log.lh.n = lh->n;
    80004bea:	4d3c                	lw	a5,88(a0)
    80004bec:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004bee:	02f05563          	blez	a5,80004c18 <initlog+0x74>
    80004bf2:	05c50713          	addi	a4,a0,92
    80004bf6:	0001d697          	auipc	a3,0x1d
    80004bfa:	fba68693          	addi	a3,a3,-70 # 80021bb0 <log+0x30>
    80004bfe:	37fd                	addiw	a5,a5,-1
    80004c00:	1782                	slli	a5,a5,0x20
    80004c02:	9381                	srli	a5,a5,0x20
    80004c04:	078a                	slli	a5,a5,0x2
    80004c06:	06050613          	addi	a2,a0,96
    80004c0a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004c0c:	4310                	lw	a2,0(a4)
    80004c0e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004c10:	0711                	addi	a4,a4,4
    80004c12:	0691                	addi	a3,a3,4
    80004c14:	fef71ce3          	bne	a4,a5,80004c0c <initlog+0x68>
  brelse(buf);
    80004c18:	fffff097          	auipc	ra,0xfffff
    80004c1c:	f8c080e7          	jalr	-116(ra) # 80003ba4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c20:	4505                	li	a0,1
    80004c22:	00000097          	auipc	ra,0x0
    80004c26:	ebe080e7          	jalr	-322(ra) # 80004ae0 <install_trans>
  log.lh.n = 0;
    80004c2a:	0001d797          	auipc	a5,0x1d
    80004c2e:	f807a123          	sw	zero,-126(a5) # 80021bac <log+0x2c>
  write_head(); // clear the log
    80004c32:	00000097          	auipc	ra,0x0
    80004c36:	e34080e7          	jalr	-460(ra) # 80004a66 <write_head>
}
    80004c3a:	70a2                	ld	ra,40(sp)
    80004c3c:	7402                	ld	s0,32(sp)
    80004c3e:	64e2                	ld	s1,24(sp)
    80004c40:	6942                	ld	s2,16(sp)
    80004c42:	69a2                	ld	s3,8(sp)
    80004c44:	6145                	addi	sp,sp,48
    80004c46:	8082                	ret

0000000080004c48 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c48:	1101                	addi	sp,sp,-32
    80004c4a:	ec06                	sd	ra,24(sp)
    80004c4c:	e822                	sd	s0,16(sp)
    80004c4e:	e426                	sd	s1,8(sp)
    80004c50:	e04a                	sd	s2,0(sp)
    80004c52:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c54:	0001d517          	auipc	a0,0x1d
    80004c58:	f2c50513          	addi	a0,a0,-212 # 80021b80 <log>
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	f90080e7          	jalr	-112(ra) # 80000bec <acquire>
  while(1){
    if(log.committing){
    80004c64:	0001d497          	auipc	s1,0x1d
    80004c68:	f1c48493          	addi	s1,s1,-228 # 80021b80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c6c:	4979                	li	s2,30
    80004c6e:	a039                	j	80004c7c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004c70:	85a6                	mv	a1,s1
    80004c72:	8526                	mv	a0,s1
    80004c74:	ffffe097          	auipc	ra,0xffffe
    80004c78:	edc080e7          	jalr	-292(ra) # 80002b50 <sleep>
    if(log.committing){
    80004c7c:	50dc                	lw	a5,36(s1)
    80004c7e:	fbed                	bnez	a5,80004c70 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004c80:	509c                	lw	a5,32(s1)
    80004c82:	0017871b          	addiw	a4,a5,1
    80004c86:	0007069b          	sext.w	a3,a4
    80004c8a:	0027179b          	slliw	a5,a4,0x2
    80004c8e:	9fb9                	addw	a5,a5,a4
    80004c90:	0017979b          	slliw	a5,a5,0x1
    80004c94:	54d8                	lw	a4,44(s1)
    80004c96:	9fb9                	addw	a5,a5,a4
    80004c98:	00f95963          	bge	s2,a5,80004caa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004c9c:	85a6                	mv	a1,s1
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffe097          	auipc	ra,0xffffe
    80004ca4:	eb0080e7          	jalr	-336(ra) # 80002b50 <sleep>
    80004ca8:	bfd1                	j	80004c7c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004caa:	0001d517          	auipc	a0,0x1d
    80004cae:	ed650513          	addi	a0,a0,-298 # 80021b80 <log>
    80004cb2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	ff2080e7          	jalr	-14(ra) # 80000ca6 <release>
      break;
    }
  }
}
    80004cbc:	60e2                	ld	ra,24(sp)
    80004cbe:	6442                	ld	s0,16(sp)
    80004cc0:	64a2                	ld	s1,8(sp)
    80004cc2:	6902                	ld	s2,0(sp)
    80004cc4:	6105                	addi	sp,sp,32
    80004cc6:	8082                	ret

0000000080004cc8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004cc8:	7139                	addi	sp,sp,-64
    80004cca:	fc06                	sd	ra,56(sp)
    80004ccc:	f822                	sd	s0,48(sp)
    80004cce:	f426                	sd	s1,40(sp)
    80004cd0:	f04a                	sd	s2,32(sp)
    80004cd2:	ec4e                	sd	s3,24(sp)
    80004cd4:	e852                	sd	s4,16(sp)
    80004cd6:	e456                	sd	s5,8(sp)
    80004cd8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004cda:	0001d497          	auipc	s1,0x1d
    80004cde:	ea648493          	addi	s1,s1,-346 # 80021b80 <log>
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	f08080e7          	jalr	-248(ra) # 80000bec <acquire>
  log.outstanding -= 1;
    80004cec:	509c                	lw	a5,32(s1)
    80004cee:	37fd                	addiw	a5,a5,-1
    80004cf0:	0007891b          	sext.w	s2,a5
    80004cf4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004cf6:	50dc                	lw	a5,36(s1)
    80004cf8:	efb9                	bnez	a5,80004d56 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004cfa:	06091663          	bnez	s2,80004d66 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004cfe:	0001d497          	auipc	s1,0x1d
    80004d02:	e8248493          	addi	s1,s1,-382 # 80021b80 <log>
    80004d06:	4785                	li	a5,1
    80004d08:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	f9a080e7          	jalr	-102(ra) # 80000ca6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d14:	54dc                	lw	a5,44(s1)
    80004d16:	06f04763          	bgtz	a5,80004d84 <end_op+0xbc>
    acquire(&log.lock);
    80004d1a:	0001d497          	auipc	s1,0x1d
    80004d1e:	e6648493          	addi	s1,s1,-410 # 80021b80 <log>
    80004d22:	8526                	mv	a0,s1
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	ec8080e7          	jalr	-312(ra) # 80000bec <acquire>
    log.committing = 0;
    80004d2c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d30:	8526                	mv	a0,s1
    80004d32:	ffffe097          	auipc	ra,0xffffe
    80004d36:	fc4080e7          	jalr	-60(ra) # 80002cf6 <wakeup>
    release(&log.lock);
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	f6a080e7          	jalr	-150(ra) # 80000ca6 <release>
}
    80004d44:	70e2                	ld	ra,56(sp)
    80004d46:	7442                	ld	s0,48(sp)
    80004d48:	74a2                	ld	s1,40(sp)
    80004d4a:	7902                	ld	s2,32(sp)
    80004d4c:	69e2                	ld	s3,24(sp)
    80004d4e:	6a42                	ld	s4,16(sp)
    80004d50:	6aa2                	ld	s5,8(sp)
    80004d52:	6121                	addi	sp,sp,64
    80004d54:	8082                	ret
    panic("log.committing");
    80004d56:	00004517          	auipc	a0,0x4
    80004d5a:	a3a50513          	addi	a0,a0,-1478 # 80008790 <syscalls+0x1f0>
    80004d5e:	ffffb097          	auipc	ra,0xffffb
    80004d62:	7e0080e7          	jalr	2016(ra) # 8000053e <panic>
    wakeup(&log);
    80004d66:	0001d497          	auipc	s1,0x1d
    80004d6a:	e1a48493          	addi	s1,s1,-486 # 80021b80 <log>
    80004d6e:	8526                	mv	a0,s1
    80004d70:	ffffe097          	auipc	ra,0xffffe
    80004d74:	f86080e7          	jalr	-122(ra) # 80002cf6 <wakeup>
  release(&log.lock);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	f2c080e7          	jalr	-212(ra) # 80000ca6 <release>
  if(do_commit){
    80004d82:	b7c9                	j	80004d44 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d84:	0001da97          	auipc	s5,0x1d
    80004d88:	e2ca8a93          	addi	s5,s5,-468 # 80021bb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004d8c:	0001da17          	auipc	s4,0x1d
    80004d90:	df4a0a13          	addi	s4,s4,-524 # 80021b80 <log>
    80004d94:	018a2583          	lw	a1,24(s4)
    80004d98:	012585bb          	addw	a1,a1,s2
    80004d9c:	2585                	addiw	a1,a1,1
    80004d9e:	028a2503          	lw	a0,40(s4)
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	cd2080e7          	jalr	-814(ra) # 80003a74 <bread>
    80004daa:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004dac:	000aa583          	lw	a1,0(s5)
    80004db0:	028a2503          	lw	a0,40(s4)
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	cc0080e7          	jalr	-832(ra) # 80003a74 <bread>
    80004dbc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004dbe:	40000613          	li	a2,1024
    80004dc2:	05850593          	addi	a1,a0,88
    80004dc6:	05848513          	addi	a0,s1,88
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	f84080e7          	jalr	-124(ra) # 80000d4e <memmove>
    bwrite(to);  // write the log
    80004dd2:	8526                	mv	a0,s1
    80004dd4:	fffff097          	auipc	ra,0xfffff
    80004dd8:	d92080e7          	jalr	-622(ra) # 80003b66 <bwrite>
    brelse(from);
    80004ddc:	854e                	mv	a0,s3
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	dc6080e7          	jalr	-570(ra) # 80003ba4 <brelse>
    brelse(to);
    80004de6:	8526                	mv	a0,s1
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	dbc080e7          	jalr	-580(ra) # 80003ba4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004df0:	2905                	addiw	s2,s2,1
    80004df2:	0a91                	addi	s5,s5,4
    80004df4:	02ca2783          	lw	a5,44(s4)
    80004df8:	f8f94ee3          	blt	s2,a5,80004d94 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004dfc:	00000097          	auipc	ra,0x0
    80004e00:	c6a080e7          	jalr	-918(ra) # 80004a66 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e04:	4501                	li	a0,0
    80004e06:	00000097          	auipc	ra,0x0
    80004e0a:	cda080e7          	jalr	-806(ra) # 80004ae0 <install_trans>
    log.lh.n = 0;
    80004e0e:	0001d797          	auipc	a5,0x1d
    80004e12:	d807af23          	sw	zero,-610(a5) # 80021bac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e16:	00000097          	auipc	ra,0x0
    80004e1a:	c50080e7          	jalr	-944(ra) # 80004a66 <write_head>
    80004e1e:	bdf5                	j	80004d1a <end_op+0x52>

0000000080004e20 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e20:	1101                	addi	sp,sp,-32
    80004e22:	ec06                	sd	ra,24(sp)
    80004e24:	e822                	sd	s0,16(sp)
    80004e26:	e426                	sd	s1,8(sp)
    80004e28:	e04a                	sd	s2,0(sp)
    80004e2a:	1000                	addi	s0,sp,32
    80004e2c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e2e:	0001d917          	auipc	s2,0x1d
    80004e32:	d5290913          	addi	s2,s2,-686 # 80021b80 <log>
    80004e36:	854a                	mv	a0,s2
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	db4080e7          	jalr	-588(ra) # 80000bec <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e40:	02c92603          	lw	a2,44(s2)
    80004e44:	47f5                	li	a5,29
    80004e46:	06c7c563          	blt	a5,a2,80004eb0 <log_write+0x90>
    80004e4a:	0001d797          	auipc	a5,0x1d
    80004e4e:	d527a783          	lw	a5,-686(a5) # 80021b9c <log+0x1c>
    80004e52:	37fd                	addiw	a5,a5,-1
    80004e54:	04f65e63          	bge	a2,a5,80004eb0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004e58:	0001d797          	auipc	a5,0x1d
    80004e5c:	d487a783          	lw	a5,-696(a5) # 80021ba0 <log+0x20>
    80004e60:	06f05063          	blez	a5,80004ec0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004e64:	4781                	li	a5,0
    80004e66:	06c05563          	blez	a2,80004ed0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004e6a:	44cc                	lw	a1,12(s1)
    80004e6c:	0001d717          	auipc	a4,0x1d
    80004e70:	d4470713          	addi	a4,a4,-700 # 80021bb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004e74:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004e76:	4314                	lw	a3,0(a4)
    80004e78:	04b68c63          	beq	a3,a1,80004ed0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004e7c:	2785                	addiw	a5,a5,1
    80004e7e:	0711                	addi	a4,a4,4
    80004e80:	fef61be3          	bne	a2,a5,80004e76 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004e84:	0621                	addi	a2,a2,8
    80004e86:	060a                	slli	a2,a2,0x2
    80004e88:	0001d797          	auipc	a5,0x1d
    80004e8c:	cf878793          	addi	a5,a5,-776 # 80021b80 <log>
    80004e90:	963e                	add	a2,a2,a5
    80004e92:	44dc                	lw	a5,12(s1)
    80004e94:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004e96:	8526                	mv	a0,s1
    80004e98:	fffff097          	auipc	ra,0xfffff
    80004e9c:	daa080e7          	jalr	-598(ra) # 80003c42 <bpin>
    log.lh.n++;
    80004ea0:	0001d717          	auipc	a4,0x1d
    80004ea4:	ce070713          	addi	a4,a4,-800 # 80021b80 <log>
    80004ea8:	575c                	lw	a5,44(a4)
    80004eaa:	2785                	addiw	a5,a5,1
    80004eac:	d75c                	sw	a5,44(a4)
    80004eae:	a835                	j	80004eea <log_write+0xca>
    panic("too big a transaction");
    80004eb0:	00004517          	auipc	a0,0x4
    80004eb4:	8f050513          	addi	a0,a0,-1808 # 800087a0 <syscalls+0x200>
    80004eb8:	ffffb097          	auipc	ra,0xffffb
    80004ebc:	686080e7          	jalr	1670(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004ec0:	00004517          	auipc	a0,0x4
    80004ec4:	8f850513          	addi	a0,a0,-1800 # 800087b8 <syscalls+0x218>
    80004ec8:	ffffb097          	auipc	ra,0xffffb
    80004ecc:	676080e7          	jalr	1654(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004ed0:	00878713          	addi	a4,a5,8
    80004ed4:	00271693          	slli	a3,a4,0x2
    80004ed8:	0001d717          	auipc	a4,0x1d
    80004edc:	ca870713          	addi	a4,a4,-856 # 80021b80 <log>
    80004ee0:	9736                	add	a4,a4,a3
    80004ee2:	44d4                	lw	a3,12(s1)
    80004ee4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004ee6:	faf608e3          	beq	a2,a5,80004e96 <log_write+0x76>
  }
  release(&log.lock);
    80004eea:	0001d517          	auipc	a0,0x1d
    80004eee:	c9650513          	addi	a0,a0,-874 # 80021b80 <log>
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	db4080e7          	jalr	-588(ra) # 80000ca6 <release>
}
    80004efa:	60e2                	ld	ra,24(sp)
    80004efc:	6442                	ld	s0,16(sp)
    80004efe:	64a2                	ld	s1,8(sp)
    80004f00:	6902                	ld	s2,0(sp)
    80004f02:	6105                	addi	sp,sp,32
    80004f04:	8082                	ret

0000000080004f06 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f06:	1101                	addi	sp,sp,-32
    80004f08:	ec06                	sd	ra,24(sp)
    80004f0a:	e822                	sd	s0,16(sp)
    80004f0c:	e426                	sd	s1,8(sp)
    80004f0e:	e04a                	sd	s2,0(sp)
    80004f10:	1000                	addi	s0,sp,32
    80004f12:	84aa                	mv	s1,a0
    80004f14:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f16:	00004597          	auipc	a1,0x4
    80004f1a:	8c258593          	addi	a1,a1,-1854 # 800087d8 <syscalls+0x238>
    80004f1e:	0521                	addi	a0,a0,8
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	c34080e7          	jalr	-972(ra) # 80000b54 <initlock>
  lk->name = name;
    80004f28:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f2c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f30:	0204a423          	sw	zero,40(s1)
}
    80004f34:	60e2                	ld	ra,24(sp)
    80004f36:	6442                	ld	s0,16(sp)
    80004f38:	64a2                	ld	s1,8(sp)
    80004f3a:	6902                	ld	s2,0(sp)
    80004f3c:	6105                	addi	sp,sp,32
    80004f3e:	8082                	ret

0000000080004f40 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f40:	1101                	addi	sp,sp,-32
    80004f42:	ec06                	sd	ra,24(sp)
    80004f44:	e822                	sd	s0,16(sp)
    80004f46:	e426                	sd	s1,8(sp)
    80004f48:	e04a                	sd	s2,0(sp)
    80004f4a:	1000                	addi	s0,sp,32
    80004f4c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f4e:	00850913          	addi	s2,a0,8
    80004f52:	854a                	mv	a0,s2
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	c98080e7          	jalr	-872(ra) # 80000bec <acquire>
  while (lk->locked) {
    80004f5c:	409c                	lw	a5,0(s1)
    80004f5e:	cb89                	beqz	a5,80004f70 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f60:	85ca                	mv	a1,s2
    80004f62:	8526                	mv	a0,s1
    80004f64:	ffffe097          	auipc	ra,0xffffe
    80004f68:	bec080e7          	jalr	-1044(ra) # 80002b50 <sleep>
  while (lk->locked) {
    80004f6c:	409c                	lw	a5,0(s1)
    80004f6e:	fbed                	bnez	a5,80004f60 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004f70:	4785                	li	a5,1
    80004f72:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004f74:	ffffd097          	auipc	ra,0xffffd
    80004f78:	318080e7          	jalr	792(ra) # 8000228c <myproc>
    80004f7c:	453c                	lw	a5,72(a0)
    80004f7e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004f80:	854a                	mv	a0,s2
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	d24080e7          	jalr	-732(ra) # 80000ca6 <release>
}
    80004f8a:	60e2                	ld	ra,24(sp)
    80004f8c:	6442                	ld	s0,16(sp)
    80004f8e:	64a2                	ld	s1,8(sp)
    80004f90:	6902                	ld	s2,0(sp)
    80004f92:	6105                	addi	sp,sp,32
    80004f94:	8082                	ret

0000000080004f96 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004f96:	1101                	addi	sp,sp,-32
    80004f98:	ec06                	sd	ra,24(sp)
    80004f9a:	e822                	sd	s0,16(sp)
    80004f9c:	e426                	sd	s1,8(sp)
    80004f9e:	e04a                	sd	s2,0(sp)
    80004fa0:	1000                	addi	s0,sp,32
    80004fa2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fa4:	00850913          	addi	s2,a0,8
    80004fa8:	854a                	mv	a0,s2
    80004faa:	ffffc097          	auipc	ra,0xffffc
    80004fae:	c42080e7          	jalr	-958(ra) # 80000bec <acquire>
  lk->locked = 0;
    80004fb2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fb6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004fba:	8526                	mv	a0,s1
    80004fbc:	ffffe097          	auipc	ra,0xffffe
    80004fc0:	d3a080e7          	jalr	-710(ra) # 80002cf6 <wakeup>
  release(&lk->lk);
    80004fc4:	854a                	mv	a0,s2
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	ce0080e7          	jalr	-800(ra) # 80000ca6 <release>
}
    80004fce:	60e2                	ld	ra,24(sp)
    80004fd0:	6442                	ld	s0,16(sp)
    80004fd2:	64a2                	ld	s1,8(sp)
    80004fd4:	6902                	ld	s2,0(sp)
    80004fd6:	6105                	addi	sp,sp,32
    80004fd8:	8082                	ret

0000000080004fda <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004fda:	7179                	addi	sp,sp,-48
    80004fdc:	f406                	sd	ra,40(sp)
    80004fde:	f022                	sd	s0,32(sp)
    80004fe0:	ec26                	sd	s1,24(sp)
    80004fe2:	e84a                	sd	s2,16(sp)
    80004fe4:	e44e                	sd	s3,8(sp)
    80004fe6:	1800                	addi	s0,sp,48
    80004fe8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004fea:	00850913          	addi	s2,a0,8
    80004fee:	854a                	mv	a0,s2
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	bfc080e7          	jalr	-1028(ra) # 80000bec <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ff8:	409c                	lw	a5,0(s1)
    80004ffa:	ef99                	bnez	a5,80005018 <holdingsleep+0x3e>
    80004ffc:	4481                	li	s1,0
  release(&lk->lk);
    80004ffe:	854a                	mv	a0,s2
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	ca6080e7          	jalr	-858(ra) # 80000ca6 <release>
  return r;
}
    80005008:	8526                	mv	a0,s1
    8000500a:	70a2                	ld	ra,40(sp)
    8000500c:	7402                	ld	s0,32(sp)
    8000500e:	64e2                	ld	s1,24(sp)
    80005010:	6942                	ld	s2,16(sp)
    80005012:	69a2                	ld	s3,8(sp)
    80005014:	6145                	addi	sp,sp,48
    80005016:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005018:	0284a983          	lw	s3,40(s1)
    8000501c:	ffffd097          	auipc	ra,0xffffd
    80005020:	270080e7          	jalr	624(ra) # 8000228c <myproc>
    80005024:	4524                	lw	s1,72(a0)
    80005026:	413484b3          	sub	s1,s1,s3
    8000502a:	0014b493          	seqz	s1,s1
    8000502e:	bfc1                	j	80004ffe <holdingsleep+0x24>

0000000080005030 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005030:	1141                	addi	sp,sp,-16
    80005032:	e406                	sd	ra,8(sp)
    80005034:	e022                	sd	s0,0(sp)
    80005036:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005038:	00003597          	auipc	a1,0x3
    8000503c:	7b058593          	addi	a1,a1,1968 # 800087e8 <syscalls+0x248>
    80005040:	0001d517          	auipc	a0,0x1d
    80005044:	c8850513          	addi	a0,a0,-888 # 80021cc8 <ftable>
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	b0c080e7          	jalr	-1268(ra) # 80000b54 <initlock>
}
    80005050:	60a2                	ld	ra,8(sp)
    80005052:	6402                	ld	s0,0(sp)
    80005054:	0141                	addi	sp,sp,16
    80005056:	8082                	ret

0000000080005058 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005058:	1101                	addi	sp,sp,-32
    8000505a:	ec06                	sd	ra,24(sp)
    8000505c:	e822                	sd	s0,16(sp)
    8000505e:	e426                	sd	s1,8(sp)
    80005060:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005062:	0001d517          	auipc	a0,0x1d
    80005066:	c6650513          	addi	a0,a0,-922 # 80021cc8 <ftable>
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	b82080e7          	jalr	-1150(ra) # 80000bec <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005072:	0001d497          	auipc	s1,0x1d
    80005076:	c6e48493          	addi	s1,s1,-914 # 80021ce0 <ftable+0x18>
    8000507a:	0001e717          	auipc	a4,0x1e
    8000507e:	c0670713          	addi	a4,a4,-1018 # 80022c80 <ftable+0xfb8>
    if(f->ref == 0){
    80005082:	40dc                	lw	a5,4(s1)
    80005084:	cf99                	beqz	a5,800050a2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005086:	02848493          	addi	s1,s1,40
    8000508a:	fee49ce3          	bne	s1,a4,80005082 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000508e:	0001d517          	auipc	a0,0x1d
    80005092:	c3a50513          	addi	a0,a0,-966 # 80021cc8 <ftable>
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	c10080e7          	jalr	-1008(ra) # 80000ca6 <release>
  return 0;
    8000509e:	4481                	li	s1,0
    800050a0:	a819                	j	800050b6 <filealloc+0x5e>
      f->ref = 1;
    800050a2:	4785                	li	a5,1
    800050a4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800050a6:	0001d517          	auipc	a0,0x1d
    800050aa:	c2250513          	addi	a0,a0,-990 # 80021cc8 <ftable>
    800050ae:	ffffc097          	auipc	ra,0xffffc
    800050b2:	bf8080e7          	jalr	-1032(ra) # 80000ca6 <release>
}
    800050b6:	8526                	mv	a0,s1
    800050b8:	60e2                	ld	ra,24(sp)
    800050ba:	6442                	ld	s0,16(sp)
    800050bc:	64a2                	ld	s1,8(sp)
    800050be:	6105                	addi	sp,sp,32
    800050c0:	8082                	ret

00000000800050c2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800050c2:	1101                	addi	sp,sp,-32
    800050c4:	ec06                	sd	ra,24(sp)
    800050c6:	e822                	sd	s0,16(sp)
    800050c8:	e426                	sd	s1,8(sp)
    800050ca:	1000                	addi	s0,sp,32
    800050cc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800050ce:	0001d517          	auipc	a0,0x1d
    800050d2:	bfa50513          	addi	a0,a0,-1030 # 80021cc8 <ftable>
    800050d6:	ffffc097          	auipc	ra,0xffffc
    800050da:	b16080e7          	jalr	-1258(ra) # 80000bec <acquire>
  if(f->ref < 1)
    800050de:	40dc                	lw	a5,4(s1)
    800050e0:	02f05263          	blez	a5,80005104 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800050e4:	2785                	addiw	a5,a5,1
    800050e6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800050e8:	0001d517          	auipc	a0,0x1d
    800050ec:	be050513          	addi	a0,a0,-1056 # 80021cc8 <ftable>
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	bb6080e7          	jalr	-1098(ra) # 80000ca6 <release>
  return f;
}
    800050f8:	8526                	mv	a0,s1
    800050fa:	60e2                	ld	ra,24(sp)
    800050fc:	6442                	ld	s0,16(sp)
    800050fe:	64a2                	ld	s1,8(sp)
    80005100:	6105                	addi	sp,sp,32
    80005102:	8082                	ret
    panic("filedup");
    80005104:	00003517          	auipc	a0,0x3
    80005108:	6ec50513          	addi	a0,a0,1772 # 800087f0 <syscalls+0x250>
    8000510c:	ffffb097          	auipc	ra,0xffffb
    80005110:	432080e7          	jalr	1074(ra) # 8000053e <panic>

0000000080005114 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005114:	7139                	addi	sp,sp,-64
    80005116:	fc06                	sd	ra,56(sp)
    80005118:	f822                	sd	s0,48(sp)
    8000511a:	f426                	sd	s1,40(sp)
    8000511c:	f04a                	sd	s2,32(sp)
    8000511e:	ec4e                	sd	s3,24(sp)
    80005120:	e852                	sd	s4,16(sp)
    80005122:	e456                	sd	s5,8(sp)
    80005124:	0080                	addi	s0,sp,64
    80005126:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005128:	0001d517          	auipc	a0,0x1d
    8000512c:	ba050513          	addi	a0,a0,-1120 # 80021cc8 <ftable>
    80005130:	ffffc097          	auipc	ra,0xffffc
    80005134:	abc080e7          	jalr	-1348(ra) # 80000bec <acquire>
  if(f->ref < 1)
    80005138:	40dc                	lw	a5,4(s1)
    8000513a:	06f05163          	blez	a5,8000519c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000513e:	37fd                	addiw	a5,a5,-1
    80005140:	0007871b          	sext.w	a4,a5
    80005144:	c0dc                	sw	a5,4(s1)
    80005146:	06e04363          	bgtz	a4,800051ac <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000514a:	0004a903          	lw	s2,0(s1)
    8000514e:	0094ca83          	lbu	s5,9(s1)
    80005152:	0104ba03          	ld	s4,16(s1)
    80005156:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000515a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000515e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005162:	0001d517          	auipc	a0,0x1d
    80005166:	b6650513          	addi	a0,a0,-1178 # 80021cc8 <ftable>
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	b3c080e7          	jalr	-1220(ra) # 80000ca6 <release>

  if(ff.type == FD_PIPE){
    80005172:	4785                	li	a5,1
    80005174:	04f90d63          	beq	s2,a5,800051ce <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005178:	3979                	addiw	s2,s2,-2
    8000517a:	4785                	li	a5,1
    8000517c:	0527e063          	bltu	a5,s2,800051bc <fileclose+0xa8>
    begin_op();
    80005180:	00000097          	auipc	ra,0x0
    80005184:	ac8080e7          	jalr	-1336(ra) # 80004c48 <begin_op>
    iput(ff.ip);
    80005188:	854e                	mv	a0,s3
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	2a6080e7          	jalr	678(ra) # 80004430 <iput>
    end_op();
    80005192:	00000097          	auipc	ra,0x0
    80005196:	b36080e7          	jalr	-1226(ra) # 80004cc8 <end_op>
    8000519a:	a00d                	j	800051bc <fileclose+0xa8>
    panic("fileclose");
    8000519c:	00003517          	auipc	a0,0x3
    800051a0:	65c50513          	addi	a0,a0,1628 # 800087f8 <syscalls+0x258>
    800051a4:	ffffb097          	auipc	ra,0xffffb
    800051a8:	39a080e7          	jalr	922(ra) # 8000053e <panic>
    release(&ftable.lock);
    800051ac:	0001d517          	auipc	a0,0x1d
    800051b0:	b1c50513          	addi	a0,a0,-1252 # 80021cc8 <ftable>
    800051b4:	ffffc097          	auipc	ra,0xffffc
    800051b8:	af2080e7          	jalr	-1294(ra) # 80000ca6 <release>
  }
}
    800051bc:	70e2                	ld	ra,56(sp)
    800051be:	7442                	ld	s0,48(sp)
    800051c0:	74a2                	ld	s1,40(sp)
    800051c2:	7902                	ld	s2,32(sp)
    800051c4:	69e2                	ld	s3,24(sp)
    800051c6:	6a42                	ld	s4,16(sp)
    800051c8:	6aa2                	ld	s5,8(sp)
    800051ca:	6121                	addi	sp,sp,64
    800051cc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800051ce:	85d6                	mv	a1,s5
    800051d0:	8552                	mv	a0,s4
    800051d2:	00000097          	auipc	ra,0x0
    800051d6:	34c080e7          	jalr	844(ra) # 8000551e <pipeclose>
    800051da:	b7cd                	j	800051bc <fileclose+0xa8>

00000000800051dc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800051dc:	715d                	addi	sp,sp,-80
    800051de:	e486                	sd	ra,72(sp)
    800051e0:	e0a2                	sd	s0,64(sp)
    800051e2:	fc26                	sd	s1,56(sp)
    800051e4:	f84a                	sd	s2,48(sp)
    800051e6:	f44e                	sd	s3,40(sp)
    800051e8:	0880                	addi	s0,sp,80
    800051ea:	84aa                	mv	s1,a0
    800051ec:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800051ee:	ffffd097          	auipc	ra,0xffffd
    800051f2:	09e080e7          	jalr	158(ra) # 8000228c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800051f6:	409c                	lw	a5,0(s1)
    800051f8:	37f9                	addiw	a5,a5,-2
    800051fa:	4705                	li	a4,1
    800051fc:	04f76763          	bltu	a4,a5,8000524a <filestat+0x6e>
    80005200:	892a                	mv	s2,a0
    ilock(f->ip);
    80005202:	6c88                	ld	a0,24(s1)
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	072080e7          	jalr	114(ra) # 80004276 <ilock>
    stati(f->ip, &st);
    8000520c:	fb840593          	addi	a1,s0,-72
    80005210:	6c88                	ld	a0,24(s1)
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	2ee080e7          	jalr	750(ra) # 80004500 <stati>
    iunlock(f->ip);
    8000521a:	6c88                	ld	a0,24(s1)
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	11c080e7          	jalr	284(ra) # 80004338 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005224:	46e1                	li	a3,24
    80005226:	fb840613          	addi	a2,s0,-72
    8000522a:	85ce                	mv	a1,s3
    8000522c:	07893503          	ld	a0,120(s2)
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	450080e7          	jalr	1104(ra) # 80001680 <copyout>
    80005238:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000523c:	60a6                	ld	ra,72(sp)
    8000523e:	6406                	ld	s0,64(sp)
    80005240:	74e2                	ld	s1,56(sp)
    80005242:	7942                	ld	s2,48(sp)
    80005244:	79a2                	ld	s3,40(sp)
    80005246:	6161                	addi	sp,sp,80
    80005248:	8082                	ret
  return -1;
    8000524a:	557d                	li	a0,-1
    8000524c:	bfc5                	j	8000523c <filestat+0x60>

000000008000524e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000524e:	7179                	addi	sp,sp,-48
    80005250:	f406                	sd	ra,40(sp)
    80005252:	f022                	sd	s0,32(sp)
    80005254:	ec26                	sd	s1,24(sp)
    80005256:	e84a                	sd	s2,16(sp)
    80005258:	e44e                	sd	s3,8(sp)
    8000525a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000525c:	00854783          	lbu	a5,8(a0)
    80005260:	c3d5                	beqz	a5,80005304 <fileread+0xb6>
    80005262:	84aa                	mv	s1,a0
    80005264:	89ae                	mv	s3,a1
    80005266:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005268:	411c                	lw	a5,0(a0)
    8000526a:	4705                	li	a4,1
    8000526c:	04e78963          	beq	a5,a4,800052be <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005270:	470d                	li	a4,3
    80005272:	04e78d63          	beq	a5,a4,800052cc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005276:	4709                	li	a4,2
    80005278:	06e79e63          	bne	a5,a4,800052f4 <fileread+0xa6>
    ilock(f->ip);
    8000527c:	6d08                	ld	a0,24(a0)
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	ff8080e7          	jalr	-8(ra) # 80004276 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005286:	874a                	mv	a4,s2
    80005288:	5094                	lw	a3,32(s1)
    8000528a:	864e                	mv	a2,s3
    8000528c:	4585                	li	a1,1
    8000528e:	6c88                	ld	a0,24(s1)
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	29a080e7          	jalr	666(ra) # 8000452a <readi>
    80005298:	892a                	mv	s2,a0
    8000529a:	00a05563          	blez	a0,800052a4 <fileread+0x56>
      f->off += r;
    8000529e:	509c                	lw	a5,32(s1)
    800052a0:	9fa9                	addw	a5,a5,a0
    800052a2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052a4:	6c88                	ld	a0,24(s1)
    800052a6:	fffff097          	auipc	ra,0xfffff
    800052aa:	092080e7          	jalr	146(ra) # 80004338 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800052ae:	854a                	mv	a0,s2
    800052b0:	70a2                	ld	ra,40(sp)
    800052b2:	7402                	ld	s0,32(sp)
    800052b4:	64e2                	ld	s1,24(sp)
    800052b6:	6942                	ld	s2,16(sp)
    800052b8:	69a2                	ld	s3,8(sp)
    800052ba:	6145                	addi	sp,sp,48
    800052bc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800052be:	6908                	ld	a0,16(a0)
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	3c8080e7          	jalr	968(ra) # 80005688 <piperead>
    800052c8:	892a                	mv	s2,a0
    800052ca:	b7d5                	j	800052ae <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800052cc:	02451783          	lh	a5,36(a0)
    800052d0:	03079693          	slli	a3,a5,0x30
    800052d4:	92c1                	srli	a3,a3,0x30
    800052d6:	4725                	li	a4,9
    800052d8:	02d76863          	bltu	a4,a3,80005308 <fileread+0xba>
    800052dc:	0792                	slli	a5,a5,0x4
    800052de:	0001d717          	auipc	a4,0x1d
    800052e2:	94a70713          	addi	a4,a4,-1718 # 80021c28 <devsw>
    800052e6:	97ba                	add	a5,a5,a4
    800052e8:	639c                	ld	a5,0(a5)
    800052ea:	c38d                	beqz	a5,8000530c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800052ec:	4505                	li	a0,1
    800052ee:	9782                	jalr	a5
    800052f0:	892a                	mv	s2,a0
    800052f2:	bf75                	j	800052ae <fileread+0x60>
    panic("fileread");
    800052f4:	00003517          	auipc	a0,0x3
    800052f8:	51450513          	addi	a0,a0,1300 # 80008808 <syscalls+0x268>
    800052fc:	ffffb097          	auipc	ra,0xffffb
    80005300:	242080e7          	jalr	578(ra) # 8000053e <panic>
    return -1;
    80005304:	597d                	li	s2,-1
    80005306:	b765                	j	800052ae <fileread+0x60>
      return -1;
    80005308:	597d                	li	s2,-1
    8000530a:	b755                	j	800052ae <fileread+0x60>
    8000530c:	597d                	li	s2,-1
    8000530e:	b745                	j	800052ae <fileread+0x60>

0000000080005310 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005310:	715d                	addi	sp,sp,-80
    80005312:	e486                	sd	ra,72(sp)
    80005314:	e0a2                	sd	s0,64(sp)
    80005316:	fc26                	sd	s1,56(sp)
    80005318:	f84a                	sd	s2,48(sp)
    8000531a:	f44e                	sd	s3,40(sp)
    8000531c:	f052                	sd	s4,32(sp)
    8000531e:	ec56                	sd	s5,24(sp)
    80005320:	e85a                	sd	s6,16(sp)
    80005322:	e45e                	sd	s7,8(sp)
    80005324:	e062                	sd	s8,0(sp)
    80005326:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005328:	00954783          	lbu	a5,9(a0)
    8000532c:	10078663          	beqz	a5,80005438 <filewrite+0x128>
    80005330:	892a                	mv	s2,a0
    80005332:	8aae                	mv	s5,a1
    80005334:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005336:	411c                	lw	a5,0(a0)
    80005338:	4705                	li	a4,1
    8000533a:	02e78263          	beq	a5,a4,8000535e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000533e:	470d                	li	a4,3
    80005340:	02e78663          	beq	a5,a4,8000536c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005344:	4709                	li	a4,2
    80005346:	0ee79163          	bne	a5,a4,80005428 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000534a:	0ac05d63          	blez	a2,80005404 <filewrite+0xf4>
    int i = 0;
    8000534e:	4981                	li	s3,0
    80005350:	6b05                	lui	s6,0x1
    80005352:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005356:	6b85                	lui	s7,0x1
    80005358:	c00b8b9b          	addiw	s7,s7,-1024
    8000535c:	a861                	j	800053f4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000535e:	6908                	ld	a0,16(a0)
    80005360:	00000097          	auipc	ra,0x0
    80005364:	22e080e7          	jalr	558(ra) # 8000558e <pipewrite>
    80005368:	8a2a                	mv	s4,a0
    8000536a:	a045                	j	8000540a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000536c:	02451783          	lh	a5,36(a0)
    80005370:	03079693          	slli	a3,a5,0x30
    80005374:	92c1                	srli	a3,a3,0x30
    80005376:	4725                	li	a4,9
    80005378:	0cd76263          	bltu	a4,a3,8000543c <filewrite+0x12c>
    8000537c:	0792                	slli	a5,a5,0x4
    8000537e:	0001d717          	auipc	a4,0x1d
    80005382:	8aa70713          	addi	a4,a4,-1878 # 80021c28 <devsw>
    80005386:	97ba                	add	a5,a5,a4
    80005388:	679c                	ld	a5,8(a5)
    8000538a:	cbdd                	beqz	a5,80005440 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000538c:	4505                	li	a0,1
    8000538e:	9782                	jalr	a5
    80005390:	8a2a                	mv	s4,a0
    80005392:	a8a5                	j	8000540a <filewrite+0xfa>
    80005394:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005398:	00000097          	auipc	ra,0x0
    8000539c:	8b0080e7          	jalr	-1872(ra) # 80004c48 <begin_op>
      ilock(f->ip);
    800053a0:	01893503          	ld	a0,24(s2)
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	ed2080e7          	jalr	-302(ra) # 80004276 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053ac:	8762                	mv	a4,s8
    800053ae:	02092683          	lw	a3,32(s2)
    800053b2:	01598633          	add	a2,s3,s5
    800053b6:	4585                	li	a1,1
    800053b8:	01893503          	ld	a0,24(s2)
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	266080e7          	jalr	614(ra) # 80004622 <writei>
    800053c4:	84aa                	mv	s1,a0
    800053c6:	00a05763          	blez	a0,800053d4 <filewrite+0xc4>
        f->off += r;
    800053ca:	02092783          	lw	a5,32(s2)
    800053ce:	9fa9                	addw	a5,a5,a0
    800053d0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800053d4:	01893503          	ld	a0,24(s2)
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	f60080e7          	jalr	-160(ra) # 80004338 <iunlock>
      end_op();
    800053e0:	00000097          	auipc	ra,0x0
    800053e4:	8e8080e7          	jalr	-1816(ra) # 80004cc8 <end_op>

      if(r != n1){
    800053e8:	009c1f63          	bne	s8,s1,80005406 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800053ec:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800053f0:	0149db63          	bge	s3,s4,80005406 <filewrite+0xf6>
      int n1 = n - i;
    800053f4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800053f8:	84be                	mv	s1,a5
    800053fa:	2781                	sext.w	a5,a5
    800053fc:	f8fb5ce3          	bge	s6,a5,80005394 <filewrite+0x84>
    80005400:	84de                	mv	s1,s7
    80005402:	bf49                	j	80005394 <filewrite+0x84>
    int i = 0;
    80005404:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005406:	013a1f63          	bne	s4,s3,80005424 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000540a:	8552                	mv	a0,s4
    8000540c:	60a6                	ld	ra,72(sp)
    8000540e:	6406                	ld	s0,64(sp)
    80005410:	74e2                	ld	s1,56(sp)
    80005412:	7942                	ld	s2,48(sp)
    80005414:	79a2                	ld	s3,40(sp)
    80005416:	7a02                	ld	s4,32(sp)
    80005418:	6ae2                	ld	s5,24(sp)
    8000541a:	6b42                	ld	s6,16(sp)
    8000541c:	6ba2                	ld	s7,8(sp)
    8000541e:	6c02                	ld	s8,0(sp)
    80005420:	6161                	addi	sp,sp,80
    80005422:	8082                	ret
    ret = (i == n ? n : -1);
    80005424:	5a7d                	li	s4,-1
    80005426:	b7d5                	j	8000540a <filewrite+0xfa>
    panic("filewrite");
    80005428:	00003517          	auipc	a0,0x3
    8000542c:	3f050513          	addi	a0,a0,1008 # 80008818 <syscalls+0x278>
    80005430:	ffffb097          	auipc	ra,0xffffb
    80005434:	10e080e7          	jalr	270(ra) # 8000053e <panic>
    return -1;
    80005438:	5a7d                	li	s4,-1
    8000543a:	bfc1                	j	8000540a <filewrite+0xfa>
      return -1;
    8000543c:	5a7d                	li	s4,-1
    8000543e:	b7f1                	j	8000540a <filewrite+0xfa>
    80005440:	5a7d                	li	s4,-1
    80005442:	b7e1                	j	8000540a <filewrite+0xfa>

0000000080005444 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005444:	7179                	addi	sp,sp,-48
    80005446:	f406                	sd	ra,40(sp)
    80005448:	f022                	sd	s0,32(sp)
    8000544a:	ec26                	sd	s1,24(sp)
    8000544c:	e84a                	sd	s2,16(sp)
    8000544e:	e44e                	sd	s3,8(sp)
    80005450:	e052                	sd	s4,0(sp)
    80005452:	1800                	addi	s0,sp,48
    80005454:	84aa                	mv	s1,a0
    80005456:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005458:	0005b023          	sd	zero,0(a1)
    8000545c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005460:	00000097          	auipc	ra,0x0
    80005464:	bf8080e7          	jalr	-1032(ra) # 80005058 <filealloc>
    80005468:	e088                	sd	a0,0(s1)
    8000546a:	c551                	beqz	a0,800054f6 <pipealloc+0xb2>
    8000546c:	00000097          	auipc	ra,0x0
    80005470:	bec080e7          	jalr	-1044(ra) # 80005058 <filealloc>
    80005474:	00aa3023          	sd	a0,0(s4)
    80005478:	c92d                	beqz	a0,800054ea <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000547a:	ffffb097          	auipc	ra,0xffffb
    8000547e:	67a080e7          	jalr	1658(ra) # 80000af4 <kalloc>
    80005482:	892a                	mv	s2,a0
    80005484:	c125                	beqz	a0,800054e4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005486:	4985                	li	s3,1
    80005488:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000548c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005490:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005494:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005498:	00003597          	auipc	a1,0x3
    8000549c:	39058593          	addi	a1,a1,912 # 80008828 <syscalls+0x288>
    800054a0:	ffffb097          	auipc	ra,0xffffb
    800054a4:	6b4080e7          	jalr	1716(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800054a8:	609c                	ld	a5,0(s1)
    800054aa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800054ae:	609c                	ld	a5,0(s1)
    800054b0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800054b4:	609c                	ld	a5,0(s1)
    800054b6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800054ba:	609c                	ld	a5,0(s1)
    800054bc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800054c0:	000a3783          	ld	a5,0(s4)
    800054c4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800054c8:	000a3783          	ld	a5,0(s4)
    800054cc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800054d0:	000a3783          	ld	a5,0(s4)
    800054d4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800054d8:	000a3783          	ld	a5,0(s4)
    800054dc:	0127b823          	sd	s2,16(a5)
  return 0;
    800054e0:	4501                	li	a0,0
    800054e2:	a025                	j	8000550a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800054e4:	6088                	ld	a0,0(s1)
    800054e6:	e501                	bnez	a0,800054ee <pipealloc+0xaa>
    800054e8:	a039                	j	800054f6 <pipealloc+0xb2>
    800054ea:	6088                	ld	a0,0(s1)
    800054ec:	c51d                	beqz	a0,8000551a <pipealloc+0xd6>
    fileclose(*f0);
    800054ee:	00000097          	auipc	ra,0x0
    800054f2:	c26080e7          	jalr	-986(ra) # 80005114 <fileclose>
  if(*f1)
    800054f6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800054fa:	557d                	li	a0,-1
  if(*f1)
    800054fc:	c799                	beqz	a5,8000550a <pipealloc+0xc6>
    fileclose(*f1);
    800054fe:	853e                	mv	a0,a5
    80005500:	00000097          	auipc	ra,0x0
    80005504:	c14080e7          	jalr	-1004(ra) # 80005114 <fileclose>
  return -1;
    80005508:	557d                	li	a0,-1
}
    8000550a:	70a2                	ld	ra,40(sp)
    8000550c:	7402                	ld	s0,32(sp)
    8000550e:	64e2                	ld	s1,24(sp)
    80005510:	6942                	ld	s2,16(sp)
    80005512:	69a2                	ld	s3,8(sp)
    80005514:	6a02                	ld	s4,0(sp)
    80005516:	6145                	addi	sp,sp,48
    80005518:	8082                	ret
  return -1;
    8000551a:	557d                	li	a0,-1
    8000551c:	b7fd                	j	8000550a <pipealloc+0xc6>

000000008000551e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000551e:	1101                	addi	sp,sp,-32
    80005520:	ec06                	sd	ra,24(sp)
    80005522:	e822                	sd	s0,16(sp)
    80005524:	e426                	sd	s1,8(sp)
    80005526:	e04a                	sd	s2,0(sp)
    80005528:	1000                	addi	s0,sp,32
    8000552a:	84aa                	mv	s1,a0
    8000552c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000552e:	ffffb097          	auipc	ra,0xffffb
    80005532:	6be080e7          	jalr	1726(ra) # 80000bec <acquire>
  if(writable){
    80005536:	02090d63          	beqz	s2,80005570 <pipeclose+0x52>
    pi->writeopen = 0;
    8000553a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000553e:	21848513          	addi	a0,s1,536
    80005542:	ffffd097          	auipc	ra,0xffffd
    80005546:	7b4080e7          	jalr	1972(ra) # 80002cf6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000554a:	2204b783          	ld	a5,544(s1)
    8000554e:	eb95                	bnez	a5,80005582 <pipeclose+0x64>
    release(&pi->lock);
    80005550:	8526                	mv	a0,s1
    80005552:	ffffb097          	auipc	ra,0xffffb
    80005556:	754080e7          	jalr	1876(ra) # 80000ca6 <release>
    kfree((char*)pi);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffb097          	auipc	ra,0xffffb
    80005560:	49c080e7          	jalr	1180(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005564:	60e2                	ld	ra,24(sp)
    80005566:	6442                	ld	s0,16(sp)
    80005568:	64a2                	ld	s1,8(sp)
    8000556a:	6902                	ld	s2,0(sp)
    8000556c:	6105                	addi	sp,sp,32
    8000556e:	8082                	ret
    pi->readopen = 0;
    80005570:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005574:	21c48513          	addi	a0,s1,540
    80005578:	ffffd097          	auipc	ra,0xffffd
    8000557c:	77e080e7          	jalr	1918(ra) # 80002cf6 <wakeup>
    80005580:	b7e9                	j	8000554a <pipeclose+0x2c>
    release(&pi->lock);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffb097          	auipc	ra,0xffffb
    80005588:	722080e7          	jalr	1826(ra) # 80000ca6 <release>
}
    8000558c:	bfe1                	j	80005564 <pipeclose+0x46>

000000008000558e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000558e:	7159                	addi	sp,sp,-112
    80005590:	f486                	sd	ra,104(sp)
    80005592:	f0a2                	sd	s0,96(sp)
    80005594:	eca6                	sd	s1,88(sp)
    80005596:	e8ca                	sd	s2,80(sp)
    80005598:	e4ce                	sd	s3,72(sp)
    8000559a:	e0d2                	sd	s4,64(sp)
    8000559c:	fc56                	sd	s5,56(sp)
    8000559e:	f85a                	sd	s6,48(sp)
    800055a0:	f45e                	sd	s7,40(sp)
    800055a2:	f062                	sd	s8,32(sp)
    800055a4:	ec66                	sd	s9,24(sp)
    800055a6:	1880                	addi	s0,sp,112
    800055a8:	84aa                	mv	s1,a0
    800055aa:	8aae                	mv	s5,a1
    800055ac:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800055ae:	ffffd097          	auipc	ra,0xffffd
    800055b2:	cde080e7          	jalr	-802(ra) # 8000228c <myproc>
    800055b6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffb097          	auipc	ra,0xffffb
    800055be:	632080e7          	jalr	1586(ra) # 80000bec <acquire>
  while(i < n){
    800055c2:	0d405163          	blez	s4,80005684 <pipewrite+0xf6>
    800055c6:	8ba6                	mv	s7,s1
  int i = 0;
    800055c8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800055ca:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800055cc:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800055d0:	21c48c13          	addi	s8,s1,540
    800055d4:	a08d                	j	80005636 <pipewrite+0xa8>
      release(&pi->lock);
    800055d6:	8526                	mv	a0,s1
    800055d8:	ffffb097          	auipc	ra,0xffffb
    800055dc:	6ce080e7          	jalr	1742(ra) # 80000ca6 <release>
      return -1;
    800055e0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800055e2:	854a                	mv	a0,s2
    800055e4:	70a6                	ld	ra,104(sp)
    800055e6:	7406                	ld	s0,96(sp)
    800055e8:	64e6                	ld	s1,88(sp)
    800055ea:	6946                	ld	s2,80(sp)
    800055ec:	69a6                	ld	s3,72(sp)
    800055ee:	6a06                	ld	s4,64(sp)
    800055f0:	7ae2                	ld	s5,56(sp)
    800055f2:	7b42                	ld	s6,48(sp)
    800055f4:	7ba2                	ld	s7,40(sp)
    800055f6:	7c02                	ld	s8,32(sp)
    800055f8:	6ce2                	ld	s9,24(sp)
    800055fa:	6165                	addi	sp,sp,112
    800055fc:	8082                	ret
      wakeup(&pi->nread);
    800055fe:	8566                	mv	a0,s9
    80005600:	ffffd097          	auipc	ra,0xffffd
    80005604:	6f6080e7          	jalr	1782(ra) # 80002cf6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005608:	85de                	mv	a1,s7
    8000560a:	8562                	mv	a0,s8
    8000560c:	ffffd097          	auipc	ra,0xffffd
    80005610:	544080e7          	jalr	1348(ra) # 80002b50 <sleep>
    80005614:	a839                	j	80005632 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005616:	21c4a783          	lw	a5,540(s1)
    8000561a:	0017871b          	addiw	a4,a5,1
    8000561e:	20e4ae23          	sw	a4,540(s1)
    80005622:	1ff7f793          	andi	a5,a5,511
    80005626:	97a6                	add	a5,a5,s1
    80005628:	f9f44703          	lbu	a4,-97(s0)
    8000562c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005630:	2905                	addiw	s2,s2,1
  while(i < n){
    80005632:	03495d63          	bge	s2,s4,8000566c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005636:	2204a783          	lw	a5,544(s1)
    8000563a:	dfd1                	beqz	a5,800055d6 <pipewrite+0x48>
    8000563c:	0409a783          	lw	a5,64(s3)
    80005640:	fbd9                	bnez	a5,800055d6 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005642:	2184a783          	lw	a5,536(s1)
    80005646:	21c4a703          	lw	a4,540(s1)
    8000564a:	2007879b          	addiw	a5,a5,512
    8000564e:	faf708e3          	beq	a4,a5,800055fe <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005652:	4685                	li	a3,1
    80005654:	01590633          	add	a2,s2,s5
    80005658:	f9f40593          	addi	a1,s0,-97
    8000565c:	0789b503          	ld	a0,120(s3)
    80005660:	ffffc097          	auipc	ra,0xffffc
    80005664:	0ac080e7          	jalr	172(ra) # 8000170c <copyin>
    80005668:	fb6517e3          	bne	a0,s6,80005616 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000566c:	21848513          	addi	a0,s1,536
    80005670:	ffffd097          	auipc	ra,0xffffd
    80005674:	686080e7          	jalr	1670(ra) # 80002cf6 <wakeup>
  release(&pi->lock);
    80005678:	8526                	mv	a0,s1
    8000567a:	ffffb097          	auipc	ra,0xffffb
    8000567e:	62c080e7          	jalr	1580(ra) # 80000ca6 <release>
  return i;
    80005682:	b785                	j	800055e2 <pipewrite+0x54>
  int i = 0;
    80005684:	4901                	li	s2,0
    80005686:	b7dd                	j	8000566c <pipewrite+0xde>

0000000080005688 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005688:	715d                	addi	sp,sp,-80
    8000568a:	e486                	sd	ra,72(sp)
    8000568c:	e0a2                	sd	s0,64(sp)
    8000568e:	fc26                	sd	s1,56(sp)
    80005690:	f84a                	sd	s2,48(sp)
    80005692:	f44e                	sd	s3,40(sp)
    80005694:	f052                	sd	s4,32(sp)
    80005696:	ec56                	sd	s5,24(sp)
    80005698:	e85a                	sd	s6,16(sp)
    8000569a:	0880                	addi	s0,sp,80
    8000569c:	84aa                	mv	s1,a0
    8000569e:	892e                	mv	s2,a1
    800056a0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800056a2:	ffffd097          	auipc	ra,0xffffd
    800056a6:	bea080e7          	jalr	-1046(ra) # 8000228c <myproc>
    800056aa:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800056ac:	8b26                	mv	s6,s1
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffb097          	auipc	ra,0xffffb
    800056b4:	53c080e7          	jalr	1340(ra) # 80000bec <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056b8:	2184a703          	lw	a4,536(s1)
    800056bc:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056c0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056c4:	02f71463          	bne	a4,a5,800056ec <piperead+0x64>
    800056c8:	2244a783          	lw	a5,548(s1)
    800056cc:	c385                	beqz	a5,800056ec <piperead+0x64>
    if(pr->killed){
    800056ce:	040a2783          	lw	a5,64(s4)
    800056d2:	ebc1                	bnez	a5,80005762 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056d4:	85da                	mv	a1,s6
    800056d6:	854e                	mv	a0,s3
    800056d8:	ffffd097          	auipc	ra,0xffffd
    800056dc:	478080e7          	jalr	1144(ra) # 80002b50 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056e0:	2184a703          	lw	a4,536(s1)
    800056e4:	21c4a783          	lw	a5,540(s1)
    800056e8:	fef700e3          	beq	a4,a5,800056c8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800056ec:	09505263          	blez	s5,80005770 <piperead+0xe8>
    800056f0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800056f2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800056f4:	2184a783          	lw	a5,536(s1)
    800056f8:	21c4a703          	lw	a4,540(s1)
    800056fc:	02f70d63          	beq	a4,a5,80005736 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005700:	0017871b          	addiw	a4,a5,1
    80005704:	20e4ac23          	sw	a4,536(s1)
    80005708:	1ff7f793          	andi	a5,a5,511
    8000570c:	97a6                	add	a5,a5,s1
    8000570e:	0187c783          	lbu	a5,24(a5)
    80005712:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005716:	4685                	li	a3,1
    80005718:	fbf40613          	addi	a2,s0,-65
    8000571c:	85ca                	mv	a1,s2
    8000571e:	078a3503          	ld	a0,120(s4)
    80005722:	ffffc097          	auipc	ra,0xffffc
    80005726:	f5e080e7          	jalr	-162(ra) # 80001680 <copyout>
    8000572a:	01650663          	beq	a0,s6,80005736 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000572e:	2985                	addiw	s3,s3,1
    80005730:	0905                	addi	s2,s2,1
    80005732:	fd3a91e3          	bne	s5,s3,800056f4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005736:	21c48513          	addi	a0,s1,540
    8000573a:	ffffd097          	auipc	ra,0xffffd
    8000573e:	5bc080e7          	jalr	1468(ra) # 80002cf6 <wakeup>
  release(&pi->lock);
    80005742:	8526                	mv	a0,s1
    80005744:	ffffb097          	auipc	ra,0xffffb
    80005748:	562080e7          	jalr	1378(ra) # 80000ca6 <release>
  return i;
}
    8000574c:	854e                	mv	a0,s3
    8000574e:	60a6                	ld	ra,72(sp)
    80005750:	6406                	ld	s0,64(sp)
    80005752:	74e2                	ld	s1,56(sp)
    80005754:	7942                	ld	s2,48(sp)
    80005756:	79a2                	ld	s3,40(sp)
    80005758:	7a02                	ld	s4,32(sp)
    8000575a:	6ae2                	ld	s5,24(sp)
    8000575c:	6b42                	ld	s6,16(sp)
    8000575e:	6161                	addi	sp,sp,80
    80005760:	8082                	ret
      release(&pi->lock);
    80005762:	8526                	mv	a0,s1
    80005764:	ffffb097          	auipc	ra,0xffffb
    80005768:	542080e7          	jalr	1346(ra) # 80000ca6 <release>
      return -1;
    8000576c:	59fd                	li	s3,-1
    8000576e:	bff9                	j	8000574c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005770:	4981                	li	s3,0
    80005772:	b7d1                	j	80005736 <piperead+0xae>

0000000080005774 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005774:	df010113          	addi	sp,sp,-528
    80005778:	20113423          	sd	ra,520(sp)
    8000577c:	20813023          	sd	s0,512(sp)
    80005780:	ffa6                	sd	s1,504(sp)
    80005782:	fbca                	sd	s2,496(sp)
    80005784:	f7ce                	sd	s3,488(sp)
    80005786:	f3d2                	sd	s4,480(sp)
    80005788:	efd6                	sd	s5,472(sp)
    8000578a:	ebda                	sd	s6,464(sp)
    8000578c:	e7de                	sd	s7,456(sp)
    8000578e:	e3e2                	sd	s8,448(sp)
    80005790:	ff66                	sd	s9,440(sp)
    80005792:	fb6a                	sd	s10,432(sp)
    80005794:	f76e                	sd	s11,424(sp)
    80005796:	0c00                	addi	s0,sp,528
    80005798:	84aa                	mv	s1,a0
    8000579a:	dea43c23          	sd	a0,-520(s0)
    8000579e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800057a2:	ffffd097          	auipc	ra,0xffffd
    800057a6:	aea080e7          	jalr	-1302(ra) # 8000228c <myproc>
    800057aa:	892a                	mv	s2,a0

  begin_op();
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	49c080e7          	jalr	1180(ra) # 80004c48 <begin_op>

  if((ip = namei(path)) == 0){
    800057b4:	8526                	mv	a0,s1
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	276080e7          	jalr	630(ra) # 80004a2c <namei>
    800057be:	c92d                	beqz	a0,80005830 <exec+0xbc>
    800057c0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	ab4080e7          	jalr	-1356(ra) # 80004276 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800057ca:	04000713          	li	a4,64
    800057ce:	4681                	li	a3,0
    800057d0:	e5040613          	addi	a2,s0,-432
    800057d4:	4581                	li	a1,0
    800057d6:	8526                	mv	a0,s1
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	d52080e7          	jalr	-686(ra) # 8000452a <readi>
    800057e0:	04000793          	li	a5,64
    800057e4:	00f51a63          	bne	a0,a5,800057f8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800057e8:	e5042703          	lw	a4,-432(s0)
    800057ec:	464c47b7          	lui	a5,0x464c4
    800057f0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800057f4:	04f70463          	beq	a4,a5,8000583c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800057f8:	8526                	mv	a0,s1
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	cde080e7          	jalr	-802(ra) # 800044d8 <iunlockput>
    end_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	4c6080e7          	jalr	1222(ra) # 80004cc8 <end_op>
  }
  return -1;
    8000580a:	557d                	li	a0,-1
}
    8000580c:	20813083          	ld	ra,520(sp)
    80005810:	20013403          	ld	s0,512(sp)
    80005814:	74fe                	ld	s1,504(sp)
    80005816:	795e                	ld	s2,496(sp)
    80005818:	79be                	ld	s3,488(sp)
    8000581a:	7a1e                	ld	s4,480(sp)
    8000581c:	6afe                	ld	s5,472(sp)
    8000581e:	6b5e                	ld	s6,464(sp)
    80005820:	6bbe                	ld	s7,456(sp)
    80005822:	6c1e                	ld	s8,448(sp)
    80005824:	7cfa                	ld	s9,440(sp)
    80005826:	7d5a                	ld	s10,432(sp)
    80005828:	7dba                	ld	s11,424(sp)
    8000582a:	21010113          	addi	sp,sp,528
    8000582e:	8082                	ret
    end_op();
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	498080e7          	jalr	1176(ra) # 80004cc8 <end_op>
    return -1;
    80005838:	557d                	li	a0,-1
    8000583a:	bfc9                	j	8000580c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000583c:	854a                	mv	a0,s2
    8000583e:	ffffd097          	auipc	ra,0xffffd
    80005842:	b26080e7          	jalr	-1242(ra) # 80002364 <proc_pagetable>
    80005846:	8baa                	mv	s7,a0
    80005848:	d945                	beqz	a0,800057f8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000584a:	e7042983          	lw	s3,-400(s0)
    8000584e:	e8845783          	lhu	a5,-376(s0)
    80005852:	c7ad                	beqz	a5,800058bc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005854:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005856:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005858:	6c85                	lui	s9,0x1
    8000585a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000585e:	def43823          	sd	a5,-528(s0)
    80005862:	a42d                	j	80005a8c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005864:	00003517          	auipc	a0,0x3
    80005868:	fcc50513          	addi	a0,a0,-52 # 80008830 <syscalls+0x290>
    8000586c:	ffffb097          	auipc	ra,0xffffb
    80005870:	cd2080e7          	jalr	-814(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005874:	8756                	mv	a4,s5
    80005876:	012d86bb          	addw	a3,s11,s2
    8000587a:	4581                	li	a1,0
    8000587c:	8526                	mv	a0,s1
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	cac080e7          	jalr	-852(ra) # 8000452a <readi>
    80005886:	2501                	sext.w	a0,a0
    80005888:	1aaa9963          	bne	s5,a0,80005a3a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000588c:	6785                	lui	a5,0x1
    8000588e:	0127893b          	addw	s2,a5,s2
    80005892:	77fd                	lui	a5,0xfffff
    80005894:	01478a3b          	addw	s4,a5,s4
    80005898:	1f897163          	bgeu	s2,s8,80005a7a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000589c:	02091593          	slli	a1,s2,0x20
    800058a0:	9181                	srli	a1,a1,0x20
    800058a2:	95ea                	add	a1,a1,s10
    800058a4:	855e                	mv	a0,s7
    800058a6:	ffffb097          	auipc	ra,0xffffb
    800058aa:	7d6080e7          	jalr	2006(ra) # 8000107c <walkaddr>
    800058ae:	862a                	mv	a2,a0
    if(pa == 0)
    800058b0:	d955                	beqz	a0,80005864 <exec+0xf0>
      n = PGSIZE;
    800058b2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800058b4:	fd9a70e3          	bgeu	s4,s9,80005874 <exec+0x100>
      n = sz - i;
    800058b8:	8ad2                	mv	s5,s4
    800058ba:	bf6d                	j	80005874 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800058bc:	4901                	li	s2,0
  iunlockput(ip);
    800058be:	8526                	mv	a0,s1
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	c18080e7          	jalr	-1000(ra) # 800044d8 <iunlockput>
  end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	400080e7          	jalr	1024(ra) # 80004cc8 <end_op>
  p = myproc();
    800058d0:	ffffd097          	auipc	ra,0xffffd
    800058d4:	9bc080e7          	jalr	-1604(ra) # 8000228c <myproc>
    800058d8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800058da:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    800058de:	6785                	lui	a5,0x1
    800058e0:	17fd                	addi	a5,a5,-1
    800058e2:	993e                	add	s2,s2,a5
    800058e4:	757d                	lui	a0,0xfffff
    800058e6:	00a977b3          	and	a5,s2,a0
    800058ea:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800058ee:	6609                	lui	a2,0x2
    800058f0:	963e                	add	a2,a2,a5
    800058f2:	85be                	mv	a1,a5
    800058f4:	855e                	mv	a0,s7
    800058f6:	ffffc097          	auipc	ra,0xffffc
    800058fa:	b3a080e7          	jalr	-1222(ra) # 80001430 <uvmalloc>
    800058fe:	8b2a                	mv	s6,a0
  ip = 0;
    80005900:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005902:	12050c63          	beqz	a0,80005a3a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005906:	75f9                	lui	a1,0xffffe
    80005908:	95aa                	add	a1,a1,a0
    8000590a:	855e                	mv	a0,s7
    8000590c:	ffffc097          	auipc	ra,0xffffc
    80005910:	d42080e7          	jalr	-702(ra) # 8000164e <uvmclear>
  stackbase = sp - PGSIZE;
    80005914:	7c7d                	lui	s8,0xfffff
    80005916:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005918:	e0043783          	ld	a5,-512(s0)
    8000591c:	6388                	ld	a0,0(a5)
    8000591e:	c535                	beqz	a0,8000598a <exec+0x216>
    80005920:	e9040993          	addi	s3,s0,-368
    80005924:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005928:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000592a:	ffffb097          	auipc	ra,0xffffb
    8000592e:	548080e7          	jalr	1352(ra) # 80000e72 <strlen>
    80005932:	2505                	addiw	a0,a0,1
    80005934:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005938:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000593c:	13896363          	bltu	s2,s8,80005a62 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005940:	e0043d83          	ld	s11,-512(s0)
    80005944:	000dba03          	ld	s4,0(s11)
    80005948:	8552                	mv	a0,s4
    8000594a:	ffffb097          	auipc	ra,0xffffb
    8000594e:	528080e7          	jalr	1320(ra) # 80000e72 <strlen>
    80005952:	0015069b          	addiw	a3,a0,1
    80005956:	8652                	mv	a2,s4
    80005958:	85ca                	mv	a1,s2
    8000595a:	855e                	mv	a0,s7
    8000595c:	ffffc097          	auipc	ra,0xffffc
    80005960:	d24080e7          	jalr	-732(ra) # 80001680 <copyout>
    80005964:	10054363          	bltz	a0,80005a6a <exec+0x2f6>
    ustack[argc] = sp;
    80005968:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000596c:	0485                	addi	s1,s1,1
    8000596e:	008d8793          	addi	a5,s11,8
    80005972:	e0f43023          	sd	a5,-512(s0)
    80005976:	008db503          	ld	a0,8(s11)
    8000597a:	c911                	beqz	a0,8000598e <exec+0x21a>
    if(argc >= MAXARG)
    8000597c:	09a1                	addi	s3,s3,8
    8000597e:	fb3c96e3          	bne	s9,s3,8000592a <exec+0x1b6>
  sz = sz1;
    80005982:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005986:	4481                	li	s1,0
    80005988:	a84d                	j	80005a3a <exec+0x2c6>
  sp = sz;
    8000598a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000598c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000598e:	00349793          	slli	a5,s1,0x3
    80005992:	f9040713          	addi	a4,s0,-112
    80005996:	97ba                	add	a5,a5,a4
    80005998:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000599c:	00148693          	addi	a3,s1,1
    800059a0:	068e                	slli	a3,a3,0x3
    800059a2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800059a6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800059aa:	01897663          	bgeu	s2,s8,800059b6 <exec+0x242>
  sz = sz1;
    800059ae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800059b2:	4481                	li	s1,0
    800059b4:	a059                	j	80005a3a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800059b6:	e9040613          	addi	a2,s0,-368
    800059ba:	85ca                	mv	a1,s2
    800059bc:	855e                	mv	a0,s7
    800059be:	ffffc097          	auipc	ra,0xffffc
    800059c2:	cc2080e7          	jalr	-830(ra) # 80001680 <copyout>
    800059c6:	0a054663          	bltz	a0,80005a72 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800059ca:	080ab783          	ld	a5,128(s5)
    800059ce:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800059d2:	df843783          	ld	a5,-520(s0)
    800059d6:	0007c703          	lbu	a4,0(a5)
    800059da:	cf11                	beqz	a4,800059f6 <exec+0x282>
    800059dc:	0785                	addi	a5,a5,1
    if(*s == '/')
    800059de:	02f00693          	li	a3,47
    800059e2:	a039                	j	800059f0 <exec+0x27c>
      last = s+1;
    800059e4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800059e8:	0785                	addi	a5,a5,1
    800059ea:	fff7c703          	lbu	a4,-1(a5)
    800059ee:	c701                	beqz	a4,800059f6 <exec+0x282>
    if(*s == '/')
    800059f0:	fed71ce3          	bne	a4,a3,800059e8 <exec+0x274>
    800059f4:	bfc5                	j	800059e4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800059f6:	4641                	li	a2,16
    800059f8:	df843583          	ld	a1,-520(s0)
    800059fc:	180a8513          	addi	a0,s5,384
    80005a00:	ffffb097          	auipc	ra,0xffffb
    80005a04:	440080e7          	jalr	1088(ra) # 80000e40 <safestrcpy>
  oldpagetable = p->pagetable;
    80005a08:	078ab503          	ld	a0,120(s5)
  p->pagetable = pagetable;
    80005a0c:	077abc23          	sd	s7,120(s5)
  p->sz = sz;
    80005a10:	076ab823          	sd	s6,112(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005a14:	080ab783          	ld	a5,128(s5)
    80005a18:	e6843703          	ld	a4,-408(s0)
    80005a1c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005a1e:	080ab783          	ld	a5,128(s5)
    80005a22:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005a26:	85ea                	mv	a1,s10
    80005a28:	ffffd097          	auipc	ra,0xffffd
    80005a2c:	9d8080e7          	jalr	-1576(ra) # 80002400 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005a30:	0004851b          	sext.w	a0,s1
    80005a34:	bbe1                	j	8000580c <exec+0x98>
    80005a36:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005a3a:	e0843583          	ld	a1,-504(s0)
    80005a3e:	855e                	mv	a0,s7
    80005a40:	ffffd097          	auipc	ra,0xffffd
    80005a44:	9c0080e7          	jalr	-1600(ra) # 80002400 <proc_freepagetable>
  if(ip){
    80005a48:	da0498e3          	bnez	s1,800057f8 <exec+0x84>
  return -1;
    80005a4c:	557d                	li	a0,-1
    80005a4e:	bb7d                	j	8000580c <exec+0x98>
    80005a50:	e1243423          	sd	s2,-504(s0)
    80005a54:	b7dd                	j	80005a3a <exec+0x2c6>
    80005a56:	e1243423          	sd	s2,-504(s0)
    80005a5a:	b7c5                	j	80005a3a <exec+0x2c6>
    80005a5c:	e1243423          	sd	s2,-504(s0)
    80005a60:	bfe9                	j	80005a3a <exec+0x2c6>
  sz = sz1;
    80005a62:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a66:	4481                	li	s1,0
    80005a68:	bfc9                	j	80005a3a <exec+0x2c6>
  sz = sz1;
    80005a6a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a6e:	4481                	li	s1,0
    80005a70:	b7e9                	j	80005a3a <exec+0x2c6>
  sz = sz1;
    80005a72:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a76:	4481                	li	s1,0
    80005a78:	b7c9                	j	80005a3a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005a7a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a7e:	2b05                	addiw	s6,s6,1
    80005a80:	0389899b          	addiw	s3,s3,56
    80005a84:	e8845783          	lhu	a5,-376(s0)
    80005a88:	e2fb5be3          	bge	s6,a5,800058be <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005a8c:	2981                	sext.w	s3,s3
    80005a8e:	03800713          	li	a4,56
    80005a92:	86ce                	mv	a3,s3
    80005a94:	e1840613          	addi	a2,s0,-488
    80005a98:	4581                	li	a1,0
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	a8e080e7          	jalr	-1394(ra) # 8000452a <readi>
    80005aa4:	03800793          	li	a5,56
    80005aa8:	f8f517e3          	bne	a0,a5,80005a36 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005aac:	e1842783          	lw	a5,-488(s0)
    80005ab0:	4705                	li	a4,1
    80005ab2:	fce796e3          	bne	a5,a4,80005a7e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005ab6:	e4043603          	ld	a2,-448(s0)
    80005aba:	e3843783          	ld	a5,-456(s0)
    80005abe:	f8f669e3          	bltu	a2,a5,80005a50 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005ac2:	e2843783          	ld	a5,-472(s0)
    80005ac6:	963e                	add	a2,a2,a5
    80005ac8:	f8f667e3          	bltu	a2,a5,80005a56 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005acc:	85ca                	mv	a1,s2
    80005ace:	855e                	mv	a0,s7
    80005ad0:	ffffc097          	auipc	ra,0xffffc
    80005ad4:	960080e7          	jalr	-1696(ra) # 80001430 <uvmalloc>
    80005ad8:	e0a43423          	sd	a0,-504(s0)
    80005adc:	d141                	beqz	a0,80005a5c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005ade:	e2843d03          	ld	s10,-472(s0)
    80005ae2:	df043783          	ld	a5,-528(s0)
    80005ae6:	00fd77b3          	and	a5,s10,a5
    80005aea:	fba1                	bnez	a5,80005a3a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005aec:	e2042d83          	lw	s11,-480(s0)
    80005af0:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005af4:	f80c03e3          	beqz	s8,80005a7a <exec+0x306>
    80005af8:	8a62                	mv	s4,s8
    80005afa:	4901                	li	s2,0
    80005afc:	b345                	j	8000589c <exec+0x128>

0000000080005afe <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005afe:	7179                	addi	sp,sp,-48
    80005b00:	f406                	sd	ra,40(sp)
    80005b02:	f022                	sd	s0,32(sp)
    80005b04:	ec26                	sd	s1,24(sp)
    80005b06:	e84a                	sd	s2,16(sp)
    80005b08:	1800                	addi	s0,sp,48
    80005b0a:	892e                	mv	s2,a1
    80005b0c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005b0e:	fdc40593          	addi	a1,s0,-36
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	ba8080e7          	jalr	-1112(ra) # 800036ba <argint>
    80005b1a:	04054063          	bltz	a0,80005b5a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005b1e:	fdc42703          	lw	a4,-36(s0)
    80005b22:	47bd                	li	a5,15
    80005b24:	02e7ed63          	bltu	a5,a4,80005b5e <argfd+0x60>
    80005b28:	ffffc097          	auipc	ra,0xffffc
    80005b2c:	764080e7          	jalr	1892(ra) # 8000228c <myproc>
    80005b30:	fdc42703          	lw	a4,-36(s0)
    80005b34:	01e70793          	addi	a5,a4,30
    80005b38:	078e                	slli	a5,a5,0x3
    80005b3a:	953e                	add	a0,a0,a5
    80005b3c:	651c                	ld	a5,8(a0)
    80005b3e:	c395                	beqz	a5,80005b62 <argfd+0x64>
    return -1;
  if(pfd)
    80005b40:	00090463          	beqz	s2,80005b48 <argfd+0x4a>
    *pfd = fd;
    80005b44:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005b48:	4501                	li	a0,0
  if(pf)
    80005b4a:	c091                	beqz	s1,80005b4e <argfd+0x50>
    *pf = f;
    80005b4c:	e09c                	sd	a5,0(s1)
}
    80005b4e:	70a2                	ld	ra,40(sp)
    80005b50:	7402                	ld	s0,32(sp)
    80005b52:	64e2                	ld	s1,24(sp)
    80005b54:	6942                	ld	s2,16(sp)
    80005b56:	6145                	addi	sp,sp,48
    80005b58:	8082                	ret
    return -1;
    80005b5a:	557d                	li	a0,-1
    80005b5c:	bfcd                	j	80005b4e <argfd+0x50>
    return -1;
    80005b5e:	557d                	li	a0,-1
    80005b60:	b7fd                	j	80005b4e <argfd+0x50>
    80005b62:	557d                	li	a0,-1
    80005b64:	b7ed                	j	80005b4e <argfd+0x50>

0000000080005b66 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005b66:	1101                	addi	sp,sp,-32
    80005b68:	ec06                	sd	ra,24(sp)
    80005b6a:	e822                	sd	s0,16(sp)
    80005b6c:	e426                	sd	s1,8(sp)
    80005b6e:	1000                	addi	s0,sp,32
    80005b70:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005b72:	ffffc097          	auipc	ra,0xffffc
    80005b76:	71a080e7          	jalr	1818(ra) # 8000228c <myproc>
    80005b7a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005b7c:	0f850793          	addi	a5,a0,248 # fffffffffffff0f8 <end+0xffffffff7ffd90f8>
    80005b80:	4501                	li	a0,0
    80005b82:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005b84:	6398                	ld	a4,0(a5)
    80005b86:	cb19                	beqz	a4,80005b9c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005b88:	2505                	addiw	a0,a0,1
    80005b8a:	07a1                	addi	a5,a5,8
    80005b8c:	fed51ce3          	bne	a0,a3,80005b84 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005b90:	557d                	li	a0,-1
}
    80005b92:	60e2                	ld	ra,24(sp)
    80005b94:	6442                	ld	s0,16(sp)
    80005b96:	64a2                	ld	s1,8(sp)
    80005b98:	6105                	addi	sp,sp,32
    80005b9a:	8082                	ret
      p->ofile[fd] = f;
    80005b9c:	01e50793          	addi	a5,a0,30
    80005ba0:	078e                	slli	a5,a5,0x3
    80005ba2:	963e                	add	a2,a2,a5
    80005ba4:	e604                	sd	s1,8(a2)
      return fd;
    80005ba6:	b7f5                	j	80005b92 <fdalloc+0x2c>

0000000080005ba8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005ba8:	715d                	addi	sp,sp,-80
    80005baa:	e486                	sd	ra,72(sp)
    80005bac:	e0a2                	sd	s0,64(sp)
    80005bae:	fc26                	sd	s1,56(sp)
    80005bb0:	f84a                	sd	s2,48(sp)
    80005bb2:	f44e                	sd	s3,40(sp)
    80005bb4:	f052                	sd	s4,32(sp)
    80005bb6:	ec56                	sd	s5,24(sp)
    80005bb8:	0880                	addi	s0,sp,80
    80005bba:	89ae                	mv	s3,a1
    80005bbc:	8ab2                	mv	s5,a2
    80005bbe:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005bc0:	fb040593          	addi	a1,s0,-80
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	e86080e7          	jalr	-378(ra) # 80004a4a <nameiparent>
    80005bcc:	892a                	mv	s2,a0
    80005bce:	12050f63          	beqz	a0,80005d0c <create+0x164>
    return 0;

  ilock(dp);
    80005bd2:	ffffe097          	auipc	ra,0xffffe
    80005bd6:	6a4080e7          	jalr	1700(ra) # 80004276 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005bda:	4601                	li	a2,0
    80005bdc:	fb040593          	addi	a1,s0,-80
    80005be0:	854a                	mv	a0,s2
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	b78080e7          	jalr	-1160(ra) # 8000475a <dirlookup>
    80005bea:	84aa                	mv	s1,a0
    80005bec:	c921                	beqz	a0,80005c3c <create+0x94>
    iunlockput(dp);
    80005bee:	854a                	mv	a0,s2
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	8e8080e7          	jalr	-1816(ra) # 800044d8 <iunlockput>
    ilock(ip);
    80005bf8:	8526                	mv	a0,s1
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	67c080e7          	jalr	1660(ra) # 80004276 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c02:	2981                	sext.w	s3,s3
    80005c04:	4789                	li	a5,2
    80005c06:	02f99463          	bne	s3,a5,80005c2e <create+0x86>
    80005c0a:	0444d783          	lhu	a5,68(s1)
    80005c0e:	37f9                	addiw	a5,a5,-2
    80005c10:	17c2                	slli	a5,a5,0x30
    80005c12:	93c1                	srli	a5,a5,0x30
    80005c14:	4705                	li	a4,1
    80005c16:	00f76c63          	bltu	a4,a5,80005c2e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005c1a:	8526                	mv	a0,s1
    80005c1c:	60a6                	ld	ra,72(sp)
    80005c1e:	6406                	ld	s0,64(sp)
    80005c20:	74e2                	ld	s1,56(sp)
    80005c22:	7942                	ld	s2,48(sp)
    80005c24:	79a2                	ld	s3,40(sp)
    80005c26:	7a02                	ld	s4,32(sp)
    80005c28:	6ae2                	ld	s5,24(sp)
    80005c2a:	6161                	addi	sp,sp,80
    80005c2c:	8082                	ret
    iunlockput(ip);
    80005c2e:	8526                	mv	a0,s1
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	8a8080e7          	jalr	-1880(ra) # 800044d8 <iunlockput>
    return 0;
    80005c38:	4481                	li	s1,0
    80005c3a:	b7c5                	j	80005c1a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005c3c:	85ce                	mv	a1,s3
    80005c3e:	00092503          	lw	a0,0(s2)
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	49c080e7          	jalr	1180(ra) # 800040de <ialloc>
    80005c4a:	84aa                	mv	s1,a0
    80005c4c:	c529                	beqz	a0,80005c96 <create+0xee>
  ilock(ip);
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	628080e7          	jalr	1576(ra) # 80004276 <ilock>
  ip->major = major;
    80005c56:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005c5a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005c5e:	4785                	li	a5,1
    80005c60:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c64:	8526                	mv	a0,s1
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	546080e7          	jalr	1350(ra) # 800041ac <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005c6e:	2981                	sext.w	s3,s3
    80005c70:	4785                	li	a5,1
    80005c72:	02f98a63          	beq	s3,a5,80005ca6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005c76:	40d0                	lw	a2,4(s1)
    80005c78:	fb040593          	addi	a1,s0,-80
    80005c7c:	854a                	mv	a0,s2
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	cec080e7          	jalr	-788(ra) # 8000496a <dirlink>
    80005c86:	06054b63          	bltz	a0,80005cfc <create+0x154>
  iunlockput(dp);
    80005c8a:	854a                	mv	a0,s2
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	84c080e7          	jalr	-1972(ra) # 800044d8 <iunlockput>
  return ip;
    80005c94:	b759                	j	80005c1a <create+0x72>
    panic("create: ialloc");
    80005c96:	00003517          	auipc	a0,0x3
    80005c9a:	bba50513          	addi	a0,a0,-1094 # 80008850 <syscalls+0x2b0>
    80005c9e:	ffffb097          	auipc	ra,0xffffb
    80005ca2:	8a0080e7          	jalr	-1888(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005ca6:	04a95783          	lhu	a5,74(s2)
    80005caa:	2785                	addiw	a5,a5,1
    80005cac:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005cb0:	854a                	mv	a0,s2
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	4fa080e7          	jalr	1274(ra) # 800041ac <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005cba:	40d0                	lw	a2,4(s1)
    80005cbc:	00003597          	auipc	a1,0x3
    80005cc0:	ba458593          	addi	a1,a1,-1116 # 80008860 <syscalls+0x2c0>
    80005cc4:	8526                	mv	a0,s1
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	ca4080e7          	jalr	-860(ra) # 8000496a <dirlink>
    80005cce:	00054f63          	bltz	a0,80005cec <create+0x144>
    80005cd2:	00492603          	lw	a2,4(s2)
    80005cd6:	00003597          	auipc	a1,0x3
    80005cda:	b9258593          	addi	a1,a1,-1134 # 80008868 <syscalls+0x2c8>
    80005cde:	8526                	mv	a0,s1
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	c8a080e7          	jalr	-886(ra) # 8000496a <dirlink>
    80005ce8:	f80557e3          	bgez	a0,80005c76 <create+0xce>
      panic("create dots");
    80005cec:	00003517          	auipc	a0,0x3
    80005cf0:	b8450513          	addi	a0,a0,-1148 # 80008870 <syscalls+0x2d0>
    80005cf4:	ffffb097          	auipc	ra,0xffffb
    80005cf8:	84a080e7          	jalr	-1974(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005cfc:	00003517          	auipc	a0,0x3
    80005d00:	b8450513          	addi	a0,a0,-1148 # 80008880 <syscalls+0x2e0>
    80005d04:	ffffb097          	auipc	ra,0xffffb
    80005d08:	83a080e7          	jalr	-1990(ra) # 8000053e <panic>
    return 0;
    80005d0c:	84aa                	mv	s1,a0
    80005d0e:	b731                	j	80005c1a <create+0x72>

0000000080005d10 <sys_dup>:
{
    80005d10:	7179                	addi	sp,sp,-48
    80005d12:	f406                	sd	ra,40(sp)
    80005d14:	f022                	sd	s0,32(sp)
    80005d16:	ec26                	sd	s1,24(sp)
    80005d18:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005d1a:	fd840613          	addi	a2,s0,-40
    80005d1e:	4581                	li	a1,0
    80005d20:	4501                	li	a0,0
    80005d22:	00000097          	auipc	ra,0x0
    80005d26:	ddc080e7          	jalr	-548(ra) # 80005afe <argfd>
    return -1;
    80005d2a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005d2c:	02054363          	bltz	a0,80005d52 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005d30:	fd843503          	ld	a0,-40(s0)
    80005d34:	00000097          	auipc	ra,0x0
    80005d38:	e32080e7          	jalr	-462(ra) # 80005b66 <fdalloc>
    80005d3c:	84aa                	mv	s1,a0
    return -1;
    80005d3e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005d40:	00054963          	bltz	a0,80005d52 <sys_dup+0x42>
  filedup(f);
    80005d44:	fd843503          	ld	a0,-40(s0)
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	37a080e7          	jalr	890(ra) # 800050c2 <filedup>
  return fd;
    80005d50:	87a6                	mv	a5,s1
}
    80005d52:	853e                	mv	a0,a5
    80005d54:	70a2                	ld	ra,40(sp)
    80005d56:	7402                	ld	s0,32(sp)
    80005d58:	64e2                	ld	s1,24(sp)
    80005d5a:	6145                	addi	sp,sp,48
    80005d5c:	8082                	ret

0000000080005d5e <sys_read>:
{
    80005d5e:	7179                	addi	sp,sp,-48
    80005d60:	f406                	sd	ra,40(sp)
    80005d62:	f022                	sd	s0,32(sp)
    80005d64:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d66:	fe840613          	addi	a2,s0,-24
    80005d6a:	4581                	li	a1,0
    80005d6c:	4501                	li	a0,0
    80005d6e:	00000097          	auipc	ra,0x0
    80005d72:	d90080e7          	jalr	-624(ra) # 80005afe <argfd>
    return -1;
    80005d76:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d78:	04054163          	bltz	a0,80005dba <sys_read+0x5c>
    80005d7c:	fe440593          	addi	a1,s0,-28
    80005d80:	4509                	li	a0,2
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	938080e7          	jalr	-1736(ra) # 800036ba <argint>
    return -1;
    80005d8a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d8c:	02054763          	bltz	a0,80005dba <sys_read+0x5c>
    80005d90:	fd840593          	addi	a1,s0,-40
    80005d94:	4505                	li	a0,1
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	946080e7          	jalr	-1722(ra) # 800036dc <argaddr>
    return -1;
    80005d9e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005da0:	00054d63          	bltz	a0,80005dba <sys_read+0x5c>
  return fileread(f, p, n);
    80005da4:	fe442603          	lw	a2,-28(s0)
    80005da8:	fd843583          	ld	a1,-40(s0)
    80005dac:	fe843503          	ld	a0,-24(s0)
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	49e080e7          	jalr	1182(ra) # 8000524e <fileread>
    80005db8:	87aa                	mv	a5,a0
}
    80005dba:	853e                	mv	a0,a5
    80005dbc:	70a2                	ld	ra,40(sp)
    80005dbe:	7402                	ld	s0,32(sp)
    80005dc0:	6145                	addi	sp,sp,48
    80005dc2:	8082                	ret

0000000080005dc4 <sys_write>:
{
    80005dc4:	7179                	addi	sp,sp,-48
    80005dc6:	f406                	sd	ra,40(sp)
    80005dc8:	f022                	sd	s0,32(sp)
    80005dca:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dcc:	fe840613          	addi	a2,s0,-24
    80005dd0:	4581                	li	a1,0
    80005dd2:	4501                	li	a0,0
    80005dd4:	00000097          	auipc	ra,0x0
    80005dd8:	d2a080e7          	jalr	-726(ra) # 80005afe <argfd>
    return -1;
    80005ddc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dde:	04054163          	bltz	a0,80005e20 <sys_write+0x5c>
    80005de2:	fe440593          	addi	a1,s0,-28
    80005de6:	4509                	li	a0,2
    80005de8:	ffffe097          	auipc	ra,0xffffe
    80005dec:	8d2080e7          	jalr	-1838(ra) # 800036ba <argint>
    return -1;
    80005df0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005df2:	02054763          	bltz	a0,80005e20 <sys_write+0x5c>
    80005df6:	fd840593          	addi	a1,s0,-40
    80005dfa:	4505                	li	a0,1
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	8e0080e7          	jalr	-1824(ra) # 800036dc <argaddr>
    return -1;
    80005e04:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e06:	00054d63          	bltz	a0,80005e20 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005e0a:	fe442603          	lw	a2,-28(s0)
    80005e0e:	fd843583          	ld	a1,-40(s0)
    80005e12:	fe843503          	ld	a0,-24(s0)
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	4fa080e7          	jalr	1274(ra) # 80005310 <filewrite>
    80005e1e:	87aa                	mv	a5,a0
}
    80005e20:	853e                	mv	a0,a5
    80005e22:	70a2                	ld	ra,40(sp)
    80005e24:	7402                	ld	s0,32(sp)
    80005e26:	6145                	addi	sp,sp,48
    80005e28:	8082                	ret

0000000080005e2a <sys_close>:
{
    80005e2a:	1101                	addi	sp,sp,-32
    80005e2c:	ec06                	sd	ra,24(sp)
    80005e2e:	e822                	sd	s0,16(sp)
    80005e30:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005e32:	fe040613          	addi	a2,s0,-32
    80005e36:	fec40593          	addi	a1,s0,-20
    80005e3a:	4501                	li	a0,0
    80005e3c:	00000097          	auipc	ra,0x0
    80005e40:	cc2080e7          	jalr	-830(ra) # 80005afe <argfd>
    return -1;
    80005e44:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005e46:	02054463          	bltz	a0,80005e6e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005e4a:	ffffc097          	auipc	ra,0xffffc
    80005e4e:	442080e7          	jalr	1090(ra) # 8000228c <myproc>
    80005e52:	fec42783          	lw	a5,-20(s0)
    80005e56:	07f9                	addi	a5,a5,30
    80005e58:	078e                	slli	a5,a5,0x3
    80005e5a:	97aa                	add	a5,a5,a0
    80005e5c:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005e60:	fe043503          	ld	a0,-32(s0)
    80005e64:	fffff097          	auipc	ra,0xfffff
    80005e68:	2b0080e7          	jalr	688(ra) # 80005114 <fileclose>
  return 0;
    80005e6c:	4781                	li	a5,0
}
    80005e6e:	853e                	mv	a0,a5
    80005e70:	60e2                	ld	ra,24(sp)
    80005e72:	6442                	ld	s0,16(sp)
    80005e74:	6105                	addi	sp,sp,32
    80005e76:	8082                	ret

0000000080005e78 <sys_fstat>:
{
    80005e78:	1101                	addi	sp,sp,-32
    80005e7a:	ec06                	sd	ra,24(sp)
    80005e7c:	e822                	sd	s0,16(sp)
    80005e7e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005e80:	fe840613          	addi	a2,s0,-24
    80005e84:	4581                	li	a1,0
    80005e86:	4501                	li	a0,0
    80005e88:	00000097          	auipc	ra,0x0
    80005e8c:	c76080e7          	jalr	-906(ra) # 80005afe <argfd>
    return -1;
    80005e90:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005e92:	02054563          	bltz	a0,80005ebc <sys_fstat+0x44>
    80005e96:	fe040593          	addi	a1,s0,-32
    80005e9a:	4505                	li	a0,1
    80005e9c:	ffffe097          	auipc	ra,0xffffe
    80005ea0:	840080e7          	jalr	-1984(ra) # 800036dc <argaddr>
    return -1;
    80005ea4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ea6:	00054b63          	bltz	a0,80005ebc <sys_fstat+0x44>
  return filestat(f, st);
    80005eaa:	fe043583          	ld	a1,-32(s0)
    80005eae:	fe843503          	ld	a0,-24(s0)
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	32a080e7          	jalr	810(ra) # 800051dc <filestat>
    80005eba:	87aa                	mv	a5,a0
}
    80005ebc:	853e                	mv	a0,a5
    80005ebe:	60e2                	ld	ra,24(sp)
    80005ec0:	6442                	ld	s0,16(sp)
    80005ec2:	6105                	addi	sp,sp,32
    80005ec4:	8082                	ret

0000000080005ec6 <sys_link>:
{
    80005ec6:	7169                	addi	sp,sp,-304
    80005ec8:	f606                	sd	ra,296(sp)
    80005eca:	f222                	sd	s0,288(sp)
    80005ecc:	ee26                	sd	s1,280(sp)
    80005ece:	ea4a                	sd	s2,272(sp)
    80005ed0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ed2:	08000613          	li	a2,128
    80005ed6:	ed040593          	addi	a1,s0,-304
    80005eda:	4501                	li	a0,0
    80005edc:	ffffe097          	auipc	ra,0xffffe
    80005ee0:	822080e7          	jalr	-2014(ra) # 800036fe <argstr>
    return -1;
    80005ee4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ee6:	10054e63          	bltz	a0,80006002 <sys_link+0x13c>
    80005eea:	08000613          	li	a2,128
    80005eee:	f5040593          	addi	a1,s0,-176
    80005ef2:	4505                	li	a0,1
    80005ef4:	ffffe097          	auipc	ra,0xffffe
    80005ef8:	80a080e7          	jalr	-2038(ra) # 800036fe <argstr>
    return -1;
    80005efc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005efe:	10054263          	bltz	a0,80006002 <sys_link+0x13c>
  begin_op();
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	d46080e7          	jalr	-698(ra) # 80004c48 <begin_op>
  if((ip = namei(old)) == 0){
    80005f0a:	ed040513          	addi	a0,s0,-304
    80005f0e:	fffff097          	auipc	ra,0xfffff
    80005f12:	b1e080e7          	jalr	-1250(ra) # 80004a2c <namei>
    80005f16:	84aa                	mv	s1,a0
    80005f18:	c551                	beqz	a0,80005fa4 <sys_link+0xde>
  ilock(ip);
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	35c080e7          	jalr	860(ra) # 80004276 <ilock>
  if(ip->type == T_DIR){
    80005f22:	04449703          	lh	a4,68(s1)
    80005f26:	4785                	li	a5,1
    80005f28:	08f70463          	beq	a4,a5,80005fb0 <sys_link+0xea>
  ip->nlink++;
    80005f2c:	04a4d783          	lhu	a5,74(s1)
    80005f30:	2785                	addiw	a5,a5,1
    80005f32:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f36:	8526                	mv	a0,s1
    80005f38:	ffffe097          	auipc	ra,0xffffe
    80005f3c:	274080e7          	jalr	628(ra) # 800041ac <iupdate>
  iunlock(ip);
    80005f40:	8526                	mv	a0,s1
    80005f42:	ffffe097          	auipc	ra,0xffffe
    80005f46:	3f6080e7          	jalr	1014(ra) # 80004338 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005f4a:	fd040593          	addi	a1,s0,-48
    80005f4e:	f5040513          	addi	a0,s0,-176
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	af8080e7          	jalr	-1288(ra) # 80004a4a <nameiparent>
    80005f5a:	892a                	mv	s2,a0
    80005f5c:	c935                	beqz	a0,80005fd0 <sys_link+0x10a>
  ilock(dp);
    80005f5e:	ffffe097          	auipc	ra,0xffffe
    80005f62:	318080e7          	jalr	792(ra) # 80004276 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005f66:	00092703          	lw	a4,0(s2)
    80005f6a:	409c                	lw	a5,0(s1)
    80005f6c:	04f71d63          	bne	a4,a5,80005fc6 <sys_link+0x100>
    80005f70:	40d0                	lw	a2,4(s1)
    80005f72:	fd040593          	addi	a1,s0,-48
    80005f76:	854a                	mv	a0,s2
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	9f2080e7          	jalr	-1550(ra) # 8000496a <dirlink>
    80005f80:	04054363          	bltz	a0,80005fc6 <sys_link+0x100>
  iunlockput(dp);
    80005f84:	854a                	mv	a0,s2
    80005f86:	ffffe097          	auipc	ra,0xffffe
    80005f8a:	552080e7          	jalr	1362(ra) # 800044d8 <iunlockput>
  iput(ip);
    80005f8e:	8526                	mv	a0,s1
    80005f90:	ffffe097          	auipc	ra,0xffffe
    80005f94:	4a0080e7          	jalr	1184(ra) # 80004430 <iput>
  end_op();
    80005f98:	fffff097          	auipc	ra,0xfffff
    80005f9c:	d30080e7          	jalr	-720(ra) # 80004cc8 <end_op>
  return 0;
    80005fa0:	4781                	li	a5,0
    80005fa2:	a085                	j	80006002 <sys_link+0x13c>
    end_op();
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	d24080e7          	jalr	-732(ra) # 80004cc8 <end_op>
    return -1;
    80005fac:	57fd                	li	a5,-1
    80005fae:	a891                	j	80006002 <sys_link+0x13c>
    iunlockput(ip);
    80005fb0:	8526                	mv	a0,s1
    80005fb2:	ffffe097          	auipc	ra,0xffffe
    80005fb6:	526080e7          	jalr	1318(ra) # 800044d8 <iunlockput>
    end_op();
    80005fba:	fffff097          	auipc	ra,0xfffff
    80005fbe:	d0e080e7          	jalr	-754(ra) # 80004cc8 <end_op>
    return -1;
    80005fc2:	57fd                	li	a5,-1
    80005fc4:	a83d                	j	80006002 <sys_link+0x13c>
    iunlockput(dp);
    80005fc6:	854a                	mv	a0,s2
    80005fc8:	ffffe097          	auipc	ra,0xffffe
    80005fcc:	510080e7          	jalr	1296(ra) # 800044d8 <iunlockput>
  ilock(ip);
    80005fd0:	8526                	mv	a0,s1
    80005fd2:	ffffe097          	auipc	ra,0xffffe
    80005fd6:	2a4080e7          	jalr	676(ra) # 80004276 <ilock>
  ip->nlink--;
    80005fda:	04a4d783          	lhu	a5,74(s1)
    80005fde:	37fd                	addiw	a5,a5,-1
    80005fe0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005fe4:	8526                	mv	a0,s1
    80005fe6:	ffffe097          	auipc	ra,0xffffe
    80005fea:	1c6080e7          	jalr	454(ra) # 800041ac <iupdate>
  iunlockput(ip);
    80005fee:	8526                	mv	a0,s1
    80005ff0:	ffffe097          	auipc	ra,0xffffe
    80005ff4:	4e8080e7          	jalr	1256(ra) # 800044d8 <iunlockput>
  end_op();
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	cd0080e7          	jalr	-816(ra) # 80004cc8 <end_op>
  return -1;
    80006000:	57fd                	li	a5,-1
}
    80006002:	853e                	mv	a0,a5
    80006004:	70b2                	ld	ra,296(sp)
    80006006:	7412                	ld	s0,288(sp)
    80006008:	64f2                	ld	s1,280(sp)
    8000600a:	6952                	ld	s2,272(sp)
    8000600c:	6155                	addi	sp,sp,304
    8000600e:	8082                	ret

0000000080006010 <sys_unlink>:
{
    80006010:	7151                	addi	sp,sp,-240
    80006012:	f586                	sd	ra,232(sp)
    80006014:	f1a2                	sd	s0,224(sp)
    80006016:	eda6                	sd	s1,216(sp)
    80006018:	e9ca                	sd	s2,208(sp)
    8000601a:	e5ce                	sd	s3,200(sp)
    8000601c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000601e:	08000613          	li	a2,128
    80006022:	f3040593          	addi	a1,s0,-208
    80006026:	4501                	li	a0,0
    80006028:	ffffd097          	auipc	ra,0xffffd
    8000602c:	6d6080e7          	jalr	1750(ra) # 800036fe <argstr>
    80006030:	18054163          	bltz	a0,800061b2 <sys_unlink+0x1a2>
  begin_op();
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	c14080e7          	jalr	-1004(ra) # 80004c48 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000603c:	fb040593          	addi	a1,s0,-80
    80006040:	f3040513          	addi	a0,s0,-208
    80006044:	fffff097          	auipc	ra,0xfffff
    80006048:	a06080e7          	jalr	-1530(ra) # 80004a4a <nameiparent>
    8000604c:	84aa                	mv	s1,a0
    8000604e:	c979                	beqz	a0,80006124 <sys_unlink+0x114>
  ilock(dp);
    80006050:	ffffe097          	auipc	ra,0xffffe
    80006054:	226080e7          	jalr	550(ra) # 80004276 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006058:	00003597          	auipc	a1,0x3
    8000605c:	80858593          	addi	a1,a1,-2040 # 80008860 <syscalls+0x2c0>
    80006060:	fb040513          	addi	a0,s0,-80
    80006064:	ffffe097          	auipc	ra,0xffffe
    80006068:	6dc080e7          	jalr	1756(ra) # 80004740 <namecmp>
    8000606c:	14050a63          	beqz	a0,800061c0 <sys_unlink+0x1b0>
    80006070:	00002597          	auipc	a1,0x2
    80006074:	7f858593          	addi	a1,a1,2040 # 80008868 <syscalls+0x2c8>
    80006078:	fb040513          	addi	a0,s0,-80
    8000607c:	ffffe097          	auipc	ra,0xffffe
    80006080:	6c4080e7          	jalr	1732(ra) # 80004740 <namecmp>
    80006084:	12050e63          	beqz	a0,800061c0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006088:	f2c40613          	addi	a2,s0,-212
    8000608c:	fb040593          	addi	a1,s0,-80
    80006090:	8526                	mv	a0,s1
    80006092:	ffffe097          	auipc	ra,0xffffe
    80006096:	6c8080e7          	jalr	1736(ra) # 8000475a <dirlookup>
    8000609a:	892a                	mv	s2,a0
    8000609c:	12050263          	beqz	a0,800061c0 <sys_unlink+0x1b0>
  ilock(ip);
    800060a0:	ffffe097          	auipc	ra,0xffffe
    800060a4:	1d6080e7          	jalr	470(ra) # 80004276 <ilock>
  if(ip->nlink < 1)
    800060a8:	04a91783          	lh	a5,74(s2)
    800060ac:	08f05263          	blez	a5,80006130 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800060b0:	04491703          	lh	a4,68(s2)
    800060b4:	4785                	li	a5,1
    800060b6:	08f70563          	beq	a4,a5,80006140 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800060ba:	4641                	li	a2,16
    800060bc:	4581                	li	a1,0
    800060be:	fc040513          	addi	a0,s0,-64
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	c2c080e7          	jalr	-980(ra) # 80000cee <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060ca:	4741                	li	a4,16
    800060cc:	f2c42683          	lw	a3,-212(s0)
    800060d0:	fc040613          	addi	a2,s0,-64
    800060d4:	4581                	li	a1,0
    800060d6:	8526                	mv	a0,s1
    800060d8:	ffffe097          	auipc	ra,0xffffe
    800060dc:	54a080e7          	jalr	1354(ra) # 80004622 <writei>
    800060e0:	47c1                	li	a5,16
    800060e2:	0af51563          	bne	a0,a5,8000618c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800060e6:	04491703          	lh	a4,68(s2)
    800060ea:	4785                	li	a5,1
    800060ec:	0af70863          	beq	a4,a5,8000619c <sys_unlink+0x18c>
  iunlockput(dp);
    800060f0:	8526                	mv	a0,s1
    800060f2:	ffffe097          	auipc	ra,0xffffe
    800060f6:	3e6080e7          	jalr	998(ra) # 800044d8 <iunlockput>
  ip->nlink--;
    800060fa:	04a95783          	lhu	a5,74(s2)
    800060fe:	37fd                	addiw	a5,a5,-1
    80006100:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006104:	854a                	mv	a0,s2
    80006106:	ffffe097          	auipc	ra,0xffffe
    8000610a:	0a6080e7          	jalr	166(ra) # 800041ac <iupdate>
  iunlockput(ip);
    8000610e:	854a                	mv	a0,s2
    80006110:	ffffe097          	auipc	ra,0xffffe
    80006114:	3c8080e7          	jalr	968(ra) # 800044d8 <iunlockput>
  end_op();
    80006118:	fffff097          	auipc	ra,0xfffff
    8000611c:	bb0080e7          	jalr	-1104(ra) # 80004cc8 <end_op>
  return 0;
    80006120:	4501                	li	a0,0
    80006122:	a84d                	j	800061d4 <sys_unlink+0x1c4>
    end_op();
    80006124:	fffff097          	auipc	ra,0xfffff
    80006128:	ba4080e7          	jalr	-1116(ra) # 80004cc8 <end_op>
    return -1;
    8000612c:	557d                	li	a0,-1
    8000612e:	a05d                	j	800061d4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006130:	00002517          	auipc	a0,0x2
    80006134:	76050513          	addi	a0,a0,1888 # 80008890 <syscalls+0x2f0>
    80006138:	ffffa097          	auipc	ra,0xffffa
    8000613c:	406080e7          	jalr	1030(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006140:	04c92703          	lw	a4,76(s2)
    80006144:	02000793          	li	a5,32
    80006148:	f6e7f9e3          	bgeu	a5,a4,800060ba <sys_unlink+0xaa>
    8000614c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006150:	4741                	li	a4,16
    80006152:	86ce                	mv	a3,s3
    80006154:	f1840613          	addi	a2,s0,-232
    80006158:	4581                	li	a1,0
    8000615a:	854a                	mv	a0,s2
    8000615c:	ffffe097          	auipc	ra,0xffffe
    80006160:	3ce080e7          	jalr	974(ra) # 8000452a <readi>
    80006164:	47c1                	li	a5,16
    80006166:	00f51b63          	bne	a0,a5,8000617c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000616a:	f1845783          	lhu	a5,-232(s0)
    8000616e:	e7a1                	bnez	a5,800061b6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006170:	29c1                	addiw	s3,s3,16
    80006172:	04c92783          	lw	a5,76(s2)
    80006176:	fcf9ede3          	bltu	s3,a5,80006150 <sys_unlink+0x140>
    8000617a:	b781                	j	800060ba <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000617c:	00002517          	auipc	a0,0x2
    80006180:	72c50513          	addi	a0,a0,1836 # 800088a8 <syscalls+0x308>
    80006184:	ffffa097          	auipc	ra,0xffffa
    80006188:	3ba080e7          	jalr	954(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000618c:	00002517          	auipc	a0,0x2
    80006190:	73450513          	addi	a0,a0,1844 # 800088c0 <syscalls+0x320>
    80006194:	ffffa097          	auipc	ra,0xffffa
    80006198:	3aa080e7          	jalr	938(ra) # 8000053e <panic>
    dp->nlink--;
    8000619c:	04a4d783          	lhu	a5,74(s1)
    800061a0:	37fd                	addiw	a5,a5,-1
    800061a2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800061a6:	8526                	mv	a0,s1
    800061a8:	ffffe097          	auipc	ra,0xffffe
    800061ac:	004080e7          	jalr	4(ra) # 800041ac <iupdate>
    800061b0:	b781                	j	800060f0 <sys_unlink+0xe0>
    return -1;
    800061b2:	557d                	li	a0,-1
    800061b4:	a005                	j	800061d4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800061b6:	854a                	mv	a0,s2
    800061b8:	ffffe097          	auipc	ra,0xffffe
    800061bc:	320080e7          	jalr	800(ra) # 800044d8 <iunlockput>
  iunlockput(dp);
    800061c0:	8526                	mv	a0,s1
    800061c2:	ffffe097          	auipc	ra,0xffffe
    800061c6:	316080e7          	jalr	790(ra) # 800044d8 <iunlockput>
  end_op();
    800061ca:	fffff097          	auipc	ra,0xfffff
    800061ce:	afe080e7          	jalr	-1282(ra) # 80004cc8 <end_op>
  return -1;
    800061d2:	557d                	li	a0,-1
}
    800061d4:	70ae                	ld	ra,232(sp)
    800061d6:	740e                	ld	s0,224(sp)
    800061d8:	64ee                	ld	s1,216(sp)
    800061da:	694e                	ld	s2,208(sp)
    800061dc:	69ae                	ld	s3,200(sp)
    800061de:	616d                	addi	sp,sp,240
    800061e0:	8082                	ret

00000000800061e2 <sys_open>:

uint64
sys_open(void)
{
    800061e2:	7131                	addi	sp,sp,-192
    800061e4:	fd06                	sd	ra,184(sp)
    800061e6:	f922                	sd	s0,176(sp)
    800061e8:	f526                	sd	s1,168(sp)
    800061ea:	f14a                	sd	s2,160(sp)
    800061ec:	ed4e                	sd	s3,152(sp)
    800061ee:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800061f0:	08000613          	li	a2,128
    800061f4:	f5040593          	addi	a1,s0,-176
    800061f8:	4501                	li	a0,0
    800061fa:	ffffd097          	auipc	ra,0xffffd
    800061fe:	504080e7          	jalr	1284(ra) # 800036fe <argstr>
    return -1;
    80006202:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006204:	0c054163          	bltz	a0,800062c6 <sys_open+0xe4>
    80006208:	f4c40593          	addi	a1,s0,-180
    8000620c:	4505                	li	a0,1
    8000620e:	ffffd097          	auipc	ra,0xffffd
    80006212:	4ac080e7          	jalr	1196(ra) # 800036ba <argint>
    80006216:	0a054863          	bltz	a0,800062c6 <sys_open+0xe4>

  begin_op();
    8000621a:	fffff097          	auipc	ra,0xfffff
    8000621e:	a2e080e7          	jalr	-1490(ra) # 80004c48 <begin_op>

  if(omode & O_CREATE){
    80006222:	f4c42783          	lw	a5,-180(s0)
    80006226:	2007f793          	andi	a5,a5,512
    8000622a:	cbdd                	beqz	a5,800062e0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000622c:	4681                	li	a3,0
    8000622e:	4601                	li	a2,0
    80006230:	4589                	li	a1,2
    80006232:	f5040513          	addi	a0,s0,-176
    80006236:	00000097          	auipc	ra,0x0
    8000623a:	972080e7          	jalr	-1678(ra) # 80005ba8 <create>
    8000623e:	892a                	mv	s2,a0
    if(ip == 0){
    80006240:	c959                	beqz	a0,800062d6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006242:	04491703          	lh	a4,68(s2)
    80006246:	478d                	li	a5,3
    80006248:	00f71763          	bne	a4,a5,80006256 <sys_open+0x74>
    8000624c:	04695703          	lhu	a4,70(s2)
    80006250:	47a5                	li	a5,9
    80006252:	0ce7ec63          	bltu	a5,a4,8000632a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006256:	fffff097          	auipc	ra,0xfffff
    8000625a:	e02080e7          	jalr	-510(ra) # 80005058 <filealloc>
    8000625e:	89aa                	mv	s3,a0
    80006260:	10050263          	beqz	a0,80006364 <sys_open+0x182>
    80006264:	00000097          	auipc	ra,0x0
    80006268:	902080e7          	jalr	-1790(ra) # 80005b66 <fdalloc>
    8000626c:	84aa                	mv	s1,a0
    8000626e:	0e054663          	bltz	a0,8000635a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006272:	04491703          	lh	a4,68(s2)
    80006276:	478d                	li	a5,3
    80006278:	0cf70463          	beq	a4,a5,80006340 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000627c:	4789                	li	a5,2
    8000627e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006282:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006286:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000628a:	f4c42783          	lw	a5,-180(s0)
    8000628e:	0017c713          	xori	a4,a5,1
    80006292:	8b05                	andi	a4,a4,1
    80006294:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006298:	0037f713          	andi	a4,a5,3
    8000629c:	00e03733          	snez	a4,a4
    800062a0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800062a4:	4007f793          	andi	a5,a5,1024
    800062a8:	c791                	beqz	a5,800062b4 <sys_open+0xd2>
    800062aa:	04491703          	lh	a4,68(s2)
    800062ae:	4789                	li	a5,2
    800062b0:	08f70f63          	beq	a4,a5,8000634e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800062b4:	854a                	mv	a0,s2
    800062b6:	ffffe097          	auipc	ra,0xffffe
    800062ba:	082080e7          	jalr	130(ra) # 80004338 <iunlock>
  end_op();
    800062be:	fffff097          	auipc	ra,0xfffff
    800062c2:	a0a080e7          	jalr	-1526(ra) # 80004cc8 <end_op>

  return fd;
}
    800062c6:	8526                	mv	a0,s1
    800062c8:	70ea                	ld	ra,184(sp)
    800062ca:	744a                	ld	s0,176(sp)
    800062cc:	74aa                	ld	s1,168(sp)
    800062ce:	790a                	ld	s2,160(sp)
    800062d0:	69ea                	ld	s3,152(sp)
    800062d2:	6129                	addi	sp,sp,192
    800062d4:	8082                	ret
      end_op();
    800062d6:	fffff097          	auipc	ra,0xfffff
    800062da:	9f2080e7          	jalr	-1550(ra) # 80004cc8 <end_op>
      return -1;
    800062de:	b7e5                	j	800062c6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800062e0:	f5040513          	addi	a0,s0,-176
    800062e4:	ffffe097          	auipc	ra,0xffffe
    800062e8:	748080e7          	jalr	1864(ra) # 80004a2c <namei>
    800062ec:	892a                	mv	s2,a0
    800062ee:	c905                	beqz	a0,8000631e <sys_open+0x13c>
    ilock(ip);
    800062f0:	ffffe097          	auipc	ra,0xffffe
    800062f4:	f86080e7          	jalr	-122(ra) # 80004276 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800062f8:	04491703          	lh	a4,68(s2)
    800062fc:	4785                	li	a5,1
    800062fe:	f4f712e3          	bne	a4,a5,80006242 <sys_open+0x60>
    80006302:	f4c42783          	lw	a5,-180(s0)
    80006306:	dba1                	beqz	a5,80006256 <sys_open+0x74>
      iunlockput(ip);
    80006308:	854a                	mv	a0,s2
    8000630a:	ffffe097          	auipc	ra,0xffffe
    8000630e:	1ce080e7          	jalr	462(ra) # 800044d8 <iunlockput>
      end_op();
    80006312:	fffff097          	auipc	ra,0xfffff
    80006316:	9b6080e7          	jalr	-1610(ra) # 80004cc8 <end_op>
      return -1;
    8000631a:	54fd                	li	s1,-1
    8000631c:	b76d                	j	800062c6 <sys_open+0xe4>
      end_op();
    8000631e:	fffff097          	auipc	ra,0xfffff
    80006322:	9aa080e7          	jalr	-1622(ra) # 80004cc8 <end_op>
      return -1;
    80006326:	54fd                	li	s1,-1
    80006328:	bf79                	j	800062c6 <sys_open+0xe4>
    iunlockput(ip);
    8000632a:	854a                	mv	a0,s2
    8000632c:	ffffe097          	auipc	ra,0xffffe
    80006330:	1ac080e7          	jalr	428(ra) # 800044d8 <iunlockput>
    end_op();
    80006334:	fffff097          	auipc	ra,0xfffff
    80006338:	994080e7          	jalr	-1644(ra) # 80004cc8 <end_op>
    return -1;
    8000633c:	54fd                	li	s1,-1
    8000633e:	b761                	j	800062c6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006340:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006344:	04691783          	lh	a5,70(s2)
    80006348:	02f99223          	sh	a5,36(s3)
    8000634c:	bf2d                	j	80006286 <sys_open+0xa4>
    itrunc(ip);
    8000634e:	854a                	mv	a0,s2
    80006350:	ffffe097          	auipc	ra,0xffffe
    80006354:	034080e7          	jalr	52(ra) # 80004384 <itrunc>
    80006358:	bfb1                	j	800062b4 <sys_open+0xd2>
      fileclose(f);
    8000635a:	854e                	mv	a0,s3
    8000635c:	fffff097          	auipc	ra,0xfffff
    80006360:	db8080e7          	jalr	-584(ra) # 80005114 <fileclose>
    iunlockput(ip);
    80006364:	854a                	mv	a0,s2
    80006366:	ffffe097          	auipc	ra,0xffffe
    8000636a:	172080e7          	jalr	370(ra) # 800044d8 <iunlockput>
    end_op();
    8000636e:	fffff097          	auipc	ra,0xfffff
    80006372:	95a080e7          	jalr	-1702(ra) # 80004cc8 <end_op>
    return -1;
    80006376:	54fd                	li	s1,-1
    80006378:	b7b9                	j	800062c6 <sys_open+0xe4>

000000008000637a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000637a:	7175                	addi	sp,sp,-144
    8000637c:	e506                	sd	ra,136(sp)
    8000637e:	e122                	sd	s0,128(sp)
    80006380:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006382:	fffff097          	auipc	ra,0xfffff
    80006386:	8c6080e7          	jalr	-1850(ra) # 80004c48 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000638a:	08000613          	li	a2,128
    8000638e:	f7040593          	addi	a1,s0,-144
    80006392:	4501                	li	a0,0
    80006394:	ffffd097          	auipc	ra,0xffffd
    80006398:	36a080e7          	jalr	874(ra) # 800036fe <argstr>
    8000639c:	02054963          	bltz	a0,800063ce <sys_mkdir+0x54>
    800063a0:	4681                	li	a3,0
    800063a2:	4601                	li	a2,0
    800063a4:	4585                	li	a1,1
    800063a6:	f7040513          	addi	a0,s0,-144
    800063aa:	fffff097          	auipc	ra,0xfffff
    800063ae:	7fe080e7          	jalr	2046(ra) # 80005ba8 <create>
    800063b2:	cd11                	beqz	a0,800063ce <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800063b4:	ffffe097          	auipc	ra,0xffffe
    800063b8:	124080e7          	jalr	292(ra) # 800044d8 <iunlockput>
  end_op();
    800063bc:	fffff097          	auipc	ra,0xfffff
    800063c0:	90c080e7          	jalr	-1780(ra) # 80004cc8 <end_op>
  return 0;
    800063c4:	4501                	li	a0,0
}
    800063c6:	60aa                	ld	ra,136(sp)
    800063c8:	640a                	ld	s0,128(sp)
    800063ca:	6149                	addi	sp,sp,144
    800063cc:	8082                	ret
    end_op();
    800063ce:	fffff097          	auipc	ra,0xfffff
    800063d2:	8fa080e7          	jalr	-1798(ra) # 80004cc8 <end_op>
    return -1;
    800063d6:	557d                	li	a0,-1
    800063d8:	b7fd                	j	800063c6 <sys_mkdir+0x4c>

00000000800063da <sys_mknod>:

uint64
sys_mknod(void)
{
    800063da:	7135                	addi	sp,sp,-160
    800063dc:	ed06                	sd	ra,152(sp)
    800063de:	e922                	sd	s0,144(sp)
    800063e0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800063e2:	fffff097          	auipc	ra,0xfffff
    800063e6:	866080e7          	jalr	-1946(ra) # 80004c48 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063ea:	08000613          	li	a2,128
    800063ee:	f7040593          	addi	a1,s0,-144
    800063f2:	4501                	li	a0,0
    800063f4:	ffffd097          	auipc	ra,0xffffd
    800063f8:	30a080e7          	jalr	778(ra) # 800036fe <argstr>
    800063fc:	04054a63          	bltz	a0,80006450 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006400:	f6c40593          	addi	a1,s0,-148
    80006404:	4505                	li	a0,1
    80006406:	ffffd097          	auipc	ra,0xffffd
    8000640a:	2b4080e7          	jalr	692(ra) # 800036ba <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000640e:	04054163          	bltz	a0,80006450 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006412:	f6840593          	addi	a1,s0,-152
    80006416:	4509                	li	a0,2
    80006418:	ffffd097          	auipc	ra,0xffffd
    8000641c:	2a2080e7          	jalr	674(ra) # 800036ba <argint>
     argint(1, &major) < 0 ||
    80006420:	02054863          	bltz	a0,80006450 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006424:	f6841683          	lh	a3,-152(s0)
    80006428:	f6c41603          	lh	a2,-148(s0)
    8000642c:	458d                	li	a1,3
    8000642e:	f7040513          	addi	a0,s0,-144
    80006432:	fffff097          	auipc	ra,0xfffff
    80006436:	776080e7          	jalr	1910(ra) # 80005ba8 <create>
     argint(2, &minor) < 0 ||
    8000643a:	c919                	beqz	a0,80006450 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000643c:	ffffe097          	auipc	ra,0xffffe
    80006440:	09c080e7          	jalr	156(ra) # 800044d8 <iunlockput>
  end_op();
    80006444:	fffff097          	auipc	ra,0xfffff
    80006448:	884080e7          	jalr	-1916(ra) # 80004cc8 <end_op>
  return 0;
    8000644c:	4501                	li	a0,0
    8000644e:	a031                	j	8000645a <sys_mknod+0x80>
    end_op();
    80006450:	fffff097          	auipc	ra,0xfffff
    80006454:	878080e7          	jalr	-1928(ra) # 80004cc8 <end_op>
    return -1;
    80006458:	557d                	li	a0,-1
}
    8000645a:	60ea                	ld	ra,152(sp)
    8000645c:	644a                	ld	s0,144(sp)
    8000645e:	610d                	addi	sp,sp,160
    80006460:	8082                	ret

0000000080006462 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006462:	7135                	addi	sp,sp,-160
    80006464:	ed06                	sd	ra,152(sp)
    80006466:	e922                	sd	s0,144(sp)
    80006468:	e526                	sd	s1,136(sp)
    8000646a:	e14a                	sd	s2,128(sp)
    8000646c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000646e:	ffffc097          	auipc	ra,0xffffc
    80006472:	e1e080e7          	jalr	-482(ra) # 8000228c <myproc>
    80006476:	892a                	mv	s2,a0
  
  begin_op();
    80006478:	ffffe097          	auipc	ra,0xffffe
    8000647c:	7d0080e7          	jalr	2000(ra) # 80004c48 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006480:	08000613          	li	a2,128
    80006484:	f6040593          	addi	a1,s0,-160
    80006488:	4501                	li	a0,0
    8000648a:	ffffd097          	auipc	ra,0xffffd
    8000648e:	274080e7          	jalr	628(ra) # 800036fe <argstr>
    80006492:	04054b63          	bltz	a0,800064e8 <sys_chdir+0x86>
    80006496:	f6040513          	addi	a0,s0,-160
    8000649a:	ffffe097          	auipc	ra,0xffffe
    8000649e:	592080e7          	jalr	1426(ra) # 80004a2c <namei>
    800064a2:	84aa                	mv	s1,a0
    800064a4:	c131                	beqz	a0,800064e8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800064a6:	ffffe097          	auipc	ra,0xffffe
    800064aa:	dd0080e7          	jalr	-560(ra) # 80004276 <ilock>
  if(ip->type != T_DIR){
    800064ae:	04449703          	lh	a4,68(s1)
    800064b2:	4785                	li	a5,1
    800064b4:	04f71063          	bne	a4,a5,800064f4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800064b8:	8526                	mv	a0,s1
    800064ba:	ffffe097          	auipc	ra,0xffffe
    800064be:	e7e080e7          	jalr	-386(ra) # 80004338 <iunlock>
  iput(p->cwd);
    800064c2:	17893503          	ld	a0,376(s2)
    800064c6:	ffffe097          	auipc	ra,0xffffe
    800064ca:	f6a080e7          	jalr	-150(ra) # 80004430 <iput>
  end_op();
    800064ce:	ffffe097          	auipc	ra,0xffffe
    800064d2:	7fa080e7          	jalr	2042(ra) # 80004cc8 <end_op>
  p->cwd = ip;
    800064d6:	16993c23          	sd	s1,376(s2)
  return 0;
    800064da:	4501                	li	a0,0
}
    800064dc:	60ea                	ld	ra,152(sp)
    800064de:	644a                	ld	s0,144(sp)
    800064e0:	64aa                	ld	s1,136(sp)
    800064e2:	690a                	ld	s2,128(sp)
    800064e4:	610d                	addi	sp,sp,160
    800064e6:	8082                	ret
    end_op();
    800064e8:	ffffe097          	auipc	ra,0xffffe
    800064ec:	7e0080e7          	jalr	2016(ra) # 80004cc8 <end_op>
    return -1;
    800064f0:	557d                	li	a0,-1
    800064f2:	b7ed                	j	800064dc <sys_chdir+0x7a>
    iunlockput(ip);
    800064f4:	8526                	mv	a0,s1
    800064f6:	ffffe097          	auipc	ra,0xffffe
    800064fa:	fe2080e7          	jalr	-30(ra) # 800044d8 <iunlockput>
    end_op();
    800064fe:	ffffe097          	auipc	ra,0xffffe
    80006502:	7ca080e7          	jalr	1994(ra) # 80004cc8 <end_op>
    return -1;
    80006506:	557d                	li	a0,-1
    80006508:	bfd1                	j	800064dc <sys_chdir+0x7a>

000000008000650a <sys_exec>:

uint64
sys_exec(void)
{
    8000650a:	7145                	addi	sp,sp,-464
    8000650c:	e786                	sd	ra,456(sp)
    8000650e:	e3a2                	sd	s0,448(sp)
    80006510:	ff26                	sd	s1,440(sp)
    80006512:	fb4a                	sd	s2,432(sp)
    80006514:	f74e                	sd	s3,424(sp)
    80006516:	f352                	sd	s4,416(sp)
    80006518:	ef56                	sd	s5,408(sp)
    8000651a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000651c:	08000613          	li	a2,128
    80006520:	f4040593          	addi	a1,s0,-192
    80006524:	4501                	li	a0,0
    80006526:	ffffd097          	auipc	ra,0xffffd
    8000652a:	1d8080e7          	jalr	472(ra) # 800036fe <argstr>
    return -1;
    8000652e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006530:	0c054a63          	bltz	a0,80006604 <sys_exec+0xfa>
    80006534:	e3840593          	addi	a1,s0,-456
    80006538:	4505                	li	a0,1
    8000653a:	ffffd097          	auipc	ra,0xffffd
    8000653e:	1a2080e7          	jalr	418(ra) # 800036dc <argaddr>
    80006542:	0c054163          	bltz	a0,80006604 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006546:	10000613          	li	a2,256
    8000654a:	4581                	li	a1,0
    8000654c:	e4040513          	addi	a0,s0,-448
    80006550:	ffffa097          	auipc	ra,0xffffa
    80006554:	79e080e7          	jalr	1950(ra) # 80000cee <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006558:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000655c:	89a6                	mv	s3,s1
    8000655e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006560:	02000a13          	li	s4,32
    80006564:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006568:	00391513          	slli	a0,s2,0x3
    8000656c:	e3040593          	addi	a1,s0,-464
    80006570:	e3843783          	ld	a5,-456(s0)
    80006574:	953e                	add	a0,a0,a5
    80006576:	ffffd097          	auipc	ra,0xffffd
    8000657a:	0aa080e7          	jalr	170(ra) # 80003620 <fetchaddr>
    8000657e:	02054a63          	bltz	a0,800065b2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006582:	e3043783          	ld	a5,-464(s0)
    80006586:	c3b9                	beqz	a5,800065cc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006588:	ffffa097          	auipc	ra,0xffffa
    8000658c:	56c080e7          	jalr	1388(ra) # 80000af4 <kalloc>
    80006590:	85aa                	mv	a1,a0
    80006592:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006596:	cd11                	beqz	a0,800065b2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006598:	6605                	lui	a2,0x1
    8000659a:	e3043503          	ld	a0,-464(s0)
    8000659e:	ffffd097          	auipc	ra,0xffffd
    800065a2:	0d4080e7          	jalr	212(ra) # 80003672 <fetchstr>
    800065a6:	00054663          	bltz	a0,800065b2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800065aa:	0905                	addi	s2,s2,1
    800065ac:	09a1                	addi	s3,s3,8
    800065ae:	fb491be3          	bne	s2,s4,80006564 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065b2:	10048913          	addi	s2,s1,256
    800065b6:	6088                	ld	a0,0(s1)
    800065b8:	c529                	beqz	a0,80006602 <sys_exec+0xf8>
    kfree(argv[i]);
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	43e080e7          	jalr	1086(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065c2:	04a1                	addi	s1,s1,8
    800065c4:	ff2499e3          	bne	s1,s2,800065b6 <sys_exec+0xac>
  return -1;
    800065c8:	597d                	li	s2,-1
    800065ca:	a82d                	j	80006604 <sys_exec+0xfa>
      argv[i] = 0;
    800065cc:	0a8e                	slli	s5,s5,0x3
    800065ce:	fc040793          	addi	a5,s0,-64
    800065d2:	9abe                	add	s5,s5,a5
    800065d4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800065d8:	e4040593          	addi	a1,s0,-448
    800065dc:	f4040513          	addi	a0,s0,-192
    800065e0:	fffff097          	auipc	ra,0xfffff
    800065e4:	194080e7          	jalr	404(ra) # 80005774 <exec>
    800065e8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065ea:	10048993          	addi	s3,s1,256
    800065ee:	6088                	ld	a0,0(s1)
    800065f0:	c911                	beqz	a0,80006604 <sys_exec+0xfa>
    kfree(argv[i]);
    800065f2:	ffffa097          	auipc	ra,0xffffa
    800065f6:	406080e7          	jalr	1030(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065fa:	04a1                	addi	s1,s1,8
    800065fc:	ff3499e3          	bne	s1,s3,800065ee <sys_exec+0xe4>
    80006600:	a011                	j	80006604 <sys_exec+0xfa>
  return -1;
    80006602:	597d                	li	s2,-1
}
    80006604:	854a                	mv	a0,s2
    80006606:	60be                	ld	ra,456(sp)
    80006608:	641e                	ld	s0,448(sp)
    8000660a:	74fa                	ld	s1,440(sp)
    8000660c:	795a                	ld	s2,432(sp)
    8000660e:	79ba                	ld	s3,424(sp)
    80006610:	7a1a                	ld	s4,416(sp)
    80006612:	6afa                	ld	s5,408(sp)
    80006614:	6179                	addi	sp,sp,464
    80006616:	8082                	ret

0000000080006618 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006618:	7139                	addi	sp,sp,-64
    8000661a:	fc06                	sd	ra,56(sp)
    8000661c:	f822                	sd	s0,48(sp)
    8000661e:	f426                	sd	s1,40(sp)
    80006620:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006622:	ffffc097          	auipc	ra,0xffffc
    80006626:	c6a080e7          	jalr	-918(ra) # 8000228c <myproc>
    8000662a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000662c:	fd840593          	addi	a1,s0,-40
    80006630:	4501                	li	a0,0
    80006632:	ffffd097          	auipc	ra,0xffffd
    80006636:	0aa080e7          	jalr	170(ra) # 800036dc <argaddr>
    return -1;
    8000663a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000663c:	0e054063          	bltz	a0,8000671c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006640:	fc840593          	addi	a1,s0,-56
    80006644:	fd040513          	addi	a0,s0,-48
    80006648:	fffff097          	auipc	ra,0xfffff
    8000664c:	dfc080e7          	jalr	-516(ra) # 80005444 <pipealloc>
    return -1;
    80006650:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006652:	0c054563          	bltz	a0,8000671c <sys_pipe+0x104>
  fd0 = -1;
    80006656:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000665a:	fd043503          	ld	a0,-48(s0)
    8000665e:	fffff097          	auipc	ra,0xfffff
    80006662:	508080e7          	jalr	1288(ra) # 80005b66 <fdalloc>
    80006666:	fca42223          	sw	a0,-60(s0)
    8000666a:	08054c63          	bltz	a0,80006702 <sys_pipe+0xea>
    8000666e:	fc843503          	ld	a0,-56(s0)
    80006672:	fffff097          	auipc	ra,0xfffff
    80006676:	4f4080e7          	jalr	1268(ra) # 80005b66 <fdalloc>
    8000667a:	fca42023          	sw	a0,-64(s0)
    8000667e:	06054863          	bltz	a0,800066ee <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006682:	4691                	li	a3,4
    80006684:	fc440613          	addi	a2,s0,-60
    80006688:	fd843583          	ld	a1,-40(s0)
    8000668c:	7ca8                	ld	a0,120(s1)
    8000668e:	ffffb097          	auipc	ra,0xffffb
    80006692:	ff2080e7          	jalr	-14(ra) # 80001680 <copyout>
    80006696:	02054063          	bltz	a0,800066b6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000669a:	4691                	li	a3,4
    8000669c:	fc040613          	addi	a2,s0,-64
    800066a0:	fd843583          	ld	a1,-40(s0)
    800066a4:	0591                	addi	a1,a1,4
    800066a6:	7ca8                	ld	a0,120(s1)
    800066a8:	ffffb097          	auipc	ra,0xffffb
    800066ac:	fd8080e7          	jalr	-40(ra) # 80001680 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800066b0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066b2:	06055563          	bgez	a0,8000671c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800066b6:	fc442783          	lw	a5,-60(s0)
    800066ba:	07f9                	addi	a5,a5,30
    800066bc:	078e                	slli	a5,a5,0x3
    800066be:	97a6                	add	a5,a5,s1
    800066c0:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800066c4:	fc042503          	lw	a0,-64(s0)
    800066c8:	0579                	addi	a0,a0,30
    800066ca:	050e                	slli	a0,a0,0x3
    800066cc:	9526                	add	a0,a0,s1
    800066ce:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800066d2:	fd043503          	ld	a0,-48(s0)
    800066d6:	fffff097          	auipc	ra,0xfffff
    800066da:	a3e080e7          	jalr	-1474(ra) # 80005114 <fileclose>
    fileclose(wf);
    800066de:	fc843503          	ld	a0,-56(s0)
    800066e2:	fffff097          	auipc	ra,0xfffff
    800066e6:	a32080e7          	jalr	-1486(ra) # 80005114 <fileclose>
    return -1;
    800066ea:	57fd                	li	a5,-1
    800066ec:	a805                	j	8000671c <sys_pipe+0x104>
    if(fd0 >= 0)
    800066ee:	fc442783          	lw	a5,-60(s0)
    800066f2:	0007c863          	bltz	a5,80006702 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800066f6:	01e78513          	addi	a0,a5,30
    800066fa:	050e                	slli	a0,a0,0x3
    800066fc:	9526                	add	a0,a0,s1
    800066fe:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006702:	fd043503          	ld	a0,-48(s0)
    80006706:	fffff097          	auipc	ra,0xfffff
    8000670a:	a0e080e7          	jalr	-1522(ra) # 80005114 <fileclose>
    fileclose(wf);
    8000670e:	fc843503          	ld	a0,-56(s0)
    80006712:	fffff097          	auipc	ra,0xfffff
    80006716:	a02080e7          	jalr	-1534(ra) # 80005114 <fileclose>
    return -1;
    8000671a:	57fd                	li	a5,-1
}
    8000671c:	853e                	mv	a0,a5
    8000671e:	70e2                	ld	ra,56(sp)
    80006720:	7442                	ld	s0,48(sp)
    80006722:	74a2                	ld	s1,40(sp)
    80006724:	6121                	addi	sp,sp,64
    80006726:	8082                	ret
	...

0000000080006730 <kernelvec>:
    80006730:	7111                	addi	sp,sp,-256
    80006732:	e006                	sd	ra,0(sp)
    80006734:	e40a                	sd	sp,8(sp)
    80006736:	e80e                	sd	gp,16(sp)
    80006738:	ec12                	sd	tp,24(sp)
    8000673a:	f016                	sd	t0,32(sp)
    8000673c:	f41a                	sd	t1,40(sp)
    8000673e:	f81e                	sd	t2,48(sp)
    80006740:	fc22                	sd	s0,56(sp)
    80006742:	e0a6                	sd	s1,64(sp)
    80006744:	e4aa                	sd	a0,72(sp)
    80006746:	e8ae                	sd	a1,80(sp)
    80006748:	ecb2                	sd	a2,88(sp)
    8000674a:	f0b6                	sd	a3,96(sp)
    8000674c:	f4ba                	sd	a4,104(sp)
    8000674e:	f8be                	sd	a5,112(sp)
    80006750:	fcc2                	sd	a6,120(sp)
    80006752:	e146                	sd	a7,128(sp)
    80006754:	e54a                	sd	s2,136(sp)
    80006756:	e94e                	sd	s3,144(sp)
    80006758:	ed52                	sd	s4,152(sp)
    8000675a:	f156                	sd	s5,160(sp)
    8000675c:	f55a                	sd	s6,168(sp)
    8000675e:	f95e                	sd	s7,176(sp)
    80006760:	fd62                	sd	s8,184(sp)
    80006762:	e1e6                	sd	s9,192(sp)
    80006764:	e5ea                	sd	s10,200(sp)
    80006766:	e9ee                	sd	s11,208(sp)
    80006768:	edf2                	sd	t3,216(sp)
    8000676a:	f1f6                	sd	t4,224(sp)
    8000676c:	f5fa                	sd	t5,232(sp)
    8000676e:	f9fe                	sd	t6,240(sp)
    80006770:	d7dfc0ef          	jal	ra,800034ec <kerneltrap>
    80006774:	6082                	ld	ra,0(sp)
    80006776:	6122                	ld	sp,8(sp)
    80006778:	61c2                	ld	gp,16(sp)
    8000677a:	7282                	ld	t0,32(sp)
    8000677c:	7322                	ld	t1,40(sp)
    8000677e:	73c2                	ld	t2,48(sp)
    80006780:	7462                	ld	s0,56(sp)
    80006782:	6486                	ld	s1,64(sp)
    80006784:	6526                	ld	a0,72(sp)
    80006786:	65c6                	ld	a1,80(sp)
    80006788:	6666                	ld	a2,88(sp)
    8000678a:	7686                	ld	a3,96(sp)
    8000678c:	7726                	ld	a4,104(sp)
    8000678e:	77c6                	ld	a5,112(sp)
    80006790:	7866                	ld	a6,120(sp)
    80006792:	688a                	ld	a7,128(sp)
    80006794:	692a                	ld	s2,136(sp)
    80006796:	69ca                	ld	s3,144(sp)
    80006798:	6a6a                	ld	s4,152(sp)
    8000679a:	7a8a                	ld	s5,160(sp)
    8000679c:	7b2a                	ld	s6,168(sp)
    8000679e:	7bca                	ld	s7,176(sp)
    800067a0:	7c6a                	ld	s8,184(sp)
    800067a2:	6c8e                	ld	s9,192(sp)
    800067a4:	6d2e                	ld	s10,200(sp)
    800067a6:	6dce                	ld	s11,208(sp)
    800067a8:	6e6e                	ld	t3,216(sp)
    800067aa:	7e8e                	ld	t4,224(sp)
    800067ac:	7f2e                	ld	t5,232(sp)
    800067ae:	7fce                	ld	t6,240(sp)
    800067b0:	6111                	addi	sp,sp,256
    800067b2:	10200073          	sret
    800067b6:	00000013          	nop
    800067ba:	00000013          	nop
    800067be:	0001                	nop

00000000800067c0 <timervec>:
    800067c0:	34051573          	csrrw	a0,mscratch,a0
    800067c4:	e10c                	sd	a1,0(a0)
    800067c6:	e510                	sd	a2,8(a0)
    800067c8:	e914                	sd	a3,16(a0)
    800067ca:	6d0c                	ld	a1,24(a0)
    800067cc:	7110                	ld	a2,32(a0)
    800067ce:	6194                	ld	a3,0(a1)
    800067d0:	96b2                	add	a3,a3,a2
    800067d2:	e194                	sd	a3,0(a1)
    800067d4:	4589                	li	a1,2
    800067d6:	14459073          	csrw	sip,a1
    800067da:	6914                	ld	a3,16(a0)
    800067dc:	6510                	ld	a2,8(a0)
    800067de:	610c                	ld	a1,0(a0)
    800067e0:	34051573          	csrrw	a0,mscratch,a0
    800067e4:	30200073          	mret
	...

00000000800067ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800067ea:	1141                	addi	sp,sp,-16
    800067ec:	e422                	sd	s0,8(sp)
    800067ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800067f0:	0c0007b7          	lui	a5,0xc000
    800067f4:	4705                	li	a4,1
    800067f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800067f8:	c3d8                	sw	a4,4(a5)
}
    800067fa:	6422                	ld	s0,8(sp)
    800067fc:	0141                	addi	sp,sp,16
    800067fe:	8082                	ret

0000000080006800 <plicinithart>:

void
plicinithart(void)
{
    80006800:	1141                	addi	sp,sp,-16
    80006802:	e406                	sd	ra,8(sp)
    80006804:	e022                	sd	s0,0(sp)
    80006806:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006808:	ffffc097          	auipc	ra,0xffffc
    8000680c:	a50080e7          	jalr	-1456(ra) # 80002258 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006810:	0085171b          	slliw	a4,a0,0x8
    80006814:	0c0027b7          	lui	a5,0xc002
    80006818:	97ba                	add	a5,a5,a4
    8000681a:	40200713          	li	a4,1026
    8000681e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006822:	00d5151b          	slliw	a0,a0,0xd
    80006826:	0c2017b7          	lui	a5,0xc201
    8000682a:	953e                	add	a0,a0,a5
    8000682c:	00052023          	sw	zero,0(a0)
}
    80006830:	60a2                	ld	ra,8(sp)
    80006832:	6402                	ld	s0,0(sp)
    80006834:	0141                	addi	sp,sp,16
    80006836:	8082                	ret

0000000080006838 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006838:	1141                	addi	sp,sp,-16
    8000683a:	e406                	sd	ra,8(sp)
    8000683c:	e022                	sd	s0,0(sp)
    8000683e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006840:	ffffc097          	auipc	ra,0xffffc
    80006844:	a18080e7          	jalr	-1512(ra) # 80002258 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006848:	00d5179b          	slliw	a5,a0,0xd
    8000684c:	0c201537          	lui	a0,0xc201
    80006850:	953e                	add	a0,a0,a5
  return irq;
}
    80006852:	4148                	lw	a0,4(a0)
    80006854:	60a2                	ld	ra,8(sp)
    80006856:	6402                	ld	s0,0(sp)
    80006858:	0141                	addi	sp,sp,16
    8000685a:	8082                	ret

000000008000685c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000685c:	1101                	addi	sp,sp,-32
    8000685e:	ec06                	sd	ra,24(sp)
    80006860:	e822                	sd	s0,16(sp)
    80006862:	e426                	sd	s1,8(sp)
    80006864:	1000                	addi	s0,sp,32
    80006866:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006868:	ffffc097          	auipc	ra,0xffffc
    8000686c:	9f0080e7          	jalr	-1552(ra) # 80002258 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006870:	00d5151b          	slliw	a0,a0,0xd
    80006874:	0c2017b7          	lui	a5,0xc201
    80006878:	97aa                	add	a5,a5,a0
    8000687a:	c3c4                	sw	s1,4(a5)
}
    8000687c:	60e2                	ld	ra,24(sp)
    8000687e:	6442                	ld	s0,16(sp)
    80006880:	64a2                	ld	s1,8(sp)
    80006882:	6105                	addi	sp,sp,32
    80006884:	8082                	ret

0000000080006886 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006886:	1141                	addi	sp,sp,-16
    80006888:	e406                	sd	ra,8(sp)
    8000688a:	e022                	sd	s0,0(sp)
    8000688c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000688e:	479d                	li	a5,7
    80006890:	06a7c963          	blt	a5,a0,80006902 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006894:	0001c797          	auipc	a5,0x1c
    80006898:	76c78793          	addi	a5,a5,1900 # 80023000 <disk>
    8000689c:	00a78733          	add	a4,a5,a0
    800068a0:	6789                	lui	a5,0x2
    800068a2:	97ba                	add	a5,a5,a4
    800068a4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800068a8:	e7ad                	bnez	a5,80006912 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800068aa:	00451793          	slli	a5,a0,0x4
    800068ae:	0001e717          	auipc	a4,0x1e
    800068b2:	75270713          	addi	a4,a4,1874 # 80025000 <disk+0x2000>
    800068b6:	6314                	ld	a3,0(a4)
    800068b8:	96be                	add	a3,a3,a5
    800068ba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800068be:	6314                	ld	a3,0(a4)
    800068c0:	96be                	add	a3,a3,a5
    800068c2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800068c6:	6314                	ld	a3,0(a4)
    800068c8:	96be                	add	a3,a3,a5
    800068ca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800068ce:	6318                	ld	a4,0(a4)
    800068d0:	97ba                	add	a5,a5,a4
    800068d2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800068d6:	0001c797          	auipc	a5,0x1c
    800068da:	72a78793          	addi	a5,a5,1834 # 80023000 <disk>
    800068de:	97aa                	add	a5,a5,a0
    800068e0:	6509                	lui	a0,0x2
    800068e2:	953e                	add	a0,a0,a5
    800068e4:	4785                	li	a5,1
    800068e6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800068ea:	0001e517          	auipc	a0,0x1e
    800068ee:	72e50513          	addi	a0,a0,1838 # 80025018 <disk+0x2018>
    800068f2:	ffffc097          	auipc	ra,0xffffc
    800068f6:	404080e7          	jalr	1028(ra) # 80002cf6 <wakeup>
}
    800068fa:	60a2                	ld	ra,8(sp)
    800068fc:	6402                	ld	s0,0(sp)
    800068fe:	0141                	addi	sp,sp,16
    80006900:	8082                	ret
    panic("free_desc 1");
    80006902:	00002517          	auipc	a0,0x2
    80006906:	fce50513          	addi	a0,a0,-50 # 800088d0 <syscalls+0x330>
    8000690a:	ffffa097          	auipc	ra,0xffffa
    8000690e:	c34080e7          	jalr	-972(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006912:	00002517          	auipc	a0,0x2
    80006916:	fce50513          	addi	a0,a0,-50 # 800088e0 <syscalls+0x340>
    8000691a:	ffffa097          	auipc	ra,0xffffa
    8000691e:	c24080e7          	jalr	-988(ra) # 8000053e <panic>

0000000080006922 <virtio_disk_init>:
{
    80006922:	1101                	addi	sp,sp,-32
    80006924:	ec06                	sd	ra,24(sp)
    80006926:	e822                	sd	s0,16(sp)
    80006928:	e426                	sd	s1,8(sp)
    8000692a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000692c:	00002597          	auipc	a1,0x2
    80006930:	fc458593          	addi	a1,a1,-60 # 800088f0 <syscalls+0x350>
    80006934:	0001e517          	auipc	a0,0x1e
    80006938:	7f450513          	addi	a0,a0,2036 # 80025128 <disk+0x2128>
    8000693c:	ffffa097          	auipc	ra,0xffffa
    80006940:	218080e7          	jalr	536(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006944:	100017b7          	lui	a5,0x10001
    80006948:	4398                	lw	a4,0(a5)
    8000694a:	2701                	sext.w	a4,a4
    8000694c:	747277b7          	lui	a5,0x74727
    80006950:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006954:	0ef71163          	bne	a4,a5,80006a36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006958:	100017b7          	lui	a5,0x10001
    8000695c:	43dc                	lw	a5,4(a5)
    8000695e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006960:	4705                	li	a4,1
    80006962:	0ce79a63          	bne	a5,a4,80006a36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006966:	100017b7          	lui	a5,0x10001
    8000696a:	479c                	lw	a5,8(a5)
    8000696c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000696e:	4709                	li	a4,2
    80006970:	0ce79363          	bne	a5,a4,80006a36 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006974:	100017b7          	lui	a5,0x10001
    80006978:	47d8                	lw	a4,12(a5)
    8000697a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000697c:	554d47b7          	lui	a5,0x554d4
    80006980:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006984:	0af71963          	bne	a4,a5,80006a36 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006988:	100017b7          	lui	a5,0x10001
    8000698c:	4705                	li	a4,1
    8000698e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006990:	470d                	li	a4,3
    80006992:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006994:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006996:	c7ffe737          	lui	a4,0xc7ffe
    8000699a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000699e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800069a0:	2701                	sext.w	a4,a4
    800069a2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069a4:	472d                	li	a4,11
    800069a6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069a8:	473d                	li	a4,15
    800069aa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800069ac:	6705                	lui	a4,0x1
    800069ae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800069b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800069b4:	5bdc                	lw	a5,52(a5)
    800069b6:	2781                	sext.w	a5,a5
  if(max == 0)
    800069b8:	c7d9                	beqz	a5,80006a46 <virtio_disk_init+0x124>
  if(max < NUM)
    800069ba:	471d                	li	a4,7
    800069bc:	08f77d63          	bgeu	a4,a5,80006a56 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800069c0:	100014b7          	lui	s1,0x10001
    800069c4:	47a1                	li	a5,8
    800069c6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800069c8:	6609                	lui	a2,0x2
    800069ca:	4581                	li	a1,0
    800069cc:	0001c517          	auipc	a0,0x1c
    800069d0:	63450513          	addi	a0,a0,1588 # 80023000 <disk>
    800069d4:	ffffa097          	auipc	ra,0xffffa
    800069d8:	31a080e7          	jalr	794(ra) # 80000cee <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800069dc:	0001c717          	auipc	a4,0x1c
    800069e0:	62470713          	addi	a4,a4,1572 # 80023000 <disk>
    800069e4:	00c75793          	srli	a5,a4,0xc
    800069e8:	2781                	sext.w	a5,a5
    800069ea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800069ec:	0001e797          	auipc	a5,0x1e
    800069f0:	61478793          	addi	a5,a5,1556 # 80025000 <disk+0x2000>
    800069f4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800069f6:	0001c717          	auipc	a4,0x1c
    800069fa:	68a70713          	addi	a4,a4,1674 # 80023080 <disk+0x80>
    800069fe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006a00:	0001d717          	auipc	a4,0x1d
    80006a04:	60070713          	addi	a4,a4,1536 # 80024000 <disk+0x1000>
    80006a08:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006a0a:	4705                	li	a4,1
    80006a0c:	00e78c23          	sb	a4,24(a5)
    80006a10:	00e78ca3          	sb	a4,25(a5)
    80006a14:	00e78d23          	sb	a4,26(a5)
    80006a18:	00e78da3          	sb	a4,27(a5)
    80006a1c:	00e78e23          	sb	a4,28(a5)
    80006a20:	00e78ea3          	sb	a4,29(a5)
    80006a24:	00e78f23          	sb	a4,30(a5)
    80006a28:	00e78fa3          	sb	a4,31(a5)
}
    80006a2c:	60e2                	ld	ra,24(sp)
    80006a2e:	6442                	ld	s0,16(sp)
    80006a30:	64a2                	ld	s1,8(sp)
    80006a32:	6105                	addi	sp,sp,32
    80006a34:	8082                	ret
    panic("could not find virtio disk");
    80006a36:	00002517          	auipc	a0,0x2
    80006a3a:	eca50513          	addi	a0,a0,-310 # 80008900 <syscalls+0x360>
    80006a3e:	ffffa097          	auipc	ra,0xffffa
    80006a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006a46:	00002517          	auipc	a0,0x2
    80006a4a:	eda50513          	addi	a0,a0,-294 # 80008920 <syscalls+0x380>
    80006a4e:	ffffa097          	auipc	ra,0xffffa
    80006a52:	af0080e7          	jalr	-1296(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006a56:	00002517          	auipc	a0,0x2
    80006a5a:	eea50513          	addi	a0,a0,-278 # 80008940 <syscalls+0x3a0>
    80006a5e:	ffffa097          	auipc	ra,0xffffa
    80006a62:	ae0080e7          	jalr	-1312(ra) # 8000053e <panic>

0000000080006a66 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006a66:	7159                	addi	sp,sp,-112
    80006a68:	f486                	sd	ra,104(sp)
    80006a6a:	f0a2                	sd	s0,96(sp)
    80006a6c:	eca6                	sd	s1,88(sp)
    80006a6e:	e8ca                	sd	s2,80(sp)
    80006a70:	e4ce                	sd	s3,72(sp)
    80006a72:	e0d2                	sd	s4,64(sp)
    80006a74:	fc56                	sd	s5,56(sp)
    80006a76:	f85a                	sd	s6,48(sp)
    80006a78:	f45e                	sd	s7,40(sp)
    80006a7a:	f062                	sd	s8,32(sp)
    80006a7c:	ec66                	sd	s9,24(sp)
    80006a7e:	e86a                	sd	s10,16(sp)
    80006a80:	1880                	addi	s0,sp,112
    80006a82:	892a                	mv	s2,a0
    80006a84:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006a86:	00c52c83          	lw	s9,12(a0)
    80006a8a:	001c9c9b          	slliw	s9,s9,0x1
    80006a8e:	1c82                	slli	s9,s9,0x20
    80006a90:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006a94:	0001e517          	auipc	a0,0x1e
    80006a98:	69450513          	addi	a0,a0,1684 # 80025128 <disk+0x2128>
    80006a9c:	ffffa097          	auipc	ra,0xffffa
    80006aa0:	150080e7          	jalr	336(ra) # 80000bec <acquire>
  for(int i = 0; i < 3; i++){
    80006aa4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006aa6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006aa8:	0001cb97          	auipc	s7,0x1c
    80006aac:	558b8b93          	addi	s7,s7,1368 # 80023000 <disk>
    80006ab0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006ab2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006ab4:	8a4e                	mv	s4,s3
    80006ab6:	a051                	j	80006b3a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006ab8:	00fb86b3          	add	a3,s7,a5
    80006abc:	96da                	add	a3,a3,s6
    80006abe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006ac2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006ac4:	0207c563          	bltz	a5,80006aee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006ac8:	2485                	addiw	s1,s1,1
    80006aca:	0711                	addi	a4,a4,4
    80006acc:	25548063          	beq	s1,s5,80006d0c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006ad0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006ad2:	0001e697          	auipc	a3,0x1e
    80006ad6:	54668693          	addi	a3,a3,1350 # 80025018 <disk+0x2018>
    80006ada:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006adc:	0006c583          	lbu	a1,0(a3)
    80006ae0:	fde1                	bnez	a1,80006ab8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006ae2:	2785                	addiw	a5,a5,1
    80006ae4:	0685                	addi	a3,a3,1
    80006ae6:	ff879be3          	bne	a5,s8,80006adc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006aea:	57fd                	li	a5,-1
    80006aec:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006aee:	02905a63          	blez	s1,80006b22 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006af2:	f9042503          	lw	a0,-112(s0)
    80006af6:	00000097          	auipc	ra,0x0
    80006afa:	d90080e7          	jalr	-624(ra) # 80006886 <free_desc>
      for(int j = 0; j < i; j++)
    80006afe:	4785                	li	a5,1
    80006b00:	0297d163          	bge	a5,s1,80006b22 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b04:	f9442503          	lw	a0,-108(s0)
    80006b08:	00000097          	auipc	ra,0x0
    80006b0c:	d7e080e7          	jalr	-642(ra) # 80006886 <free_desc>
      for(int j = 0; j < i; j++)
    80006b10:	4789                	li	a5,2
    80006b12:	0097d863          	bge	a5,s1,80006b22 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b16:	f9842503          	lw	a0,-104(s0)
    80006b1a:	00000097          	auipc	ra,0x0
    80006b1e:	d6c080e7          	jalr	-660(ra) # 80006886 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b22:	0001e597          	auipc	a1,0x1e
    80006b26:	60658593          	addi	a1,a1,1542 # 80025128 <disk+0x2128>
    80006b2a:	0001e517          	auipc	a0,0x1e
    80006b2e:	4ee50513          	addi	a0,a0,1262 # 80025018 <disk+0x2018>
    80006b32:	ffffc097          	auipc	ra,0xffffc
    80006b36:	01e080e7          	jalr	30(ra) # 80002b50 <sleep>
  for(int i = 0; i < 3; i++){
    80006b3a:	f9040713          	addi	a4,s0,-112
    80006b3e:	84ce                	mv	s1,s3
    80006b40:	bf41                	j	80006ad0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006b42:	20058713          	addi	a4,a1,512
    80006b46:	00471693          	slli	a3,a4,0x4
    80006b4a:	0001c717          	auipc	a4,0x1c
    80006b4e:	4b670713          	addi	a4,a4,1206 # 80023000 <disk>
    80006b52:	9736                	add	a4,a4,a3
    80006b54:	4685                	li	a3,1
    80006b56:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006b5a:	20058713          	addi	a4,a1,512
    80006b5e:	00471693          	slli	a3,a4,0x4
    80006b62:	0001c717          	auipc	a4,0x1c
    80006b66:	49e70713          	addi	a4,a4,1182 # 80023000 <disk>
    80006b6a:	9736                	add	a4,a4,a3
    80006b6c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006b70:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b74:	7679                	lui	a2,0xffffe
    80006b76:	963e                	add	a2,a2,a5
    80006b78:	0001e697          	auipc	a3,0x1e
    80006b7c:	48868693          	addi	a3,a3,1160 # 80025000 <disk+0x2000>
    80006b80:	6298                	ld	a4,0(a3)
    80006b82:	9732                	add	a4,a4,a2
    80006b84:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006b86:	6298                	ld	a4,0(a3)
    80006b88:	9732                	add	a4,a4,a2
    80006b8a:	4541                	li	a0,16
    80006b8c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006b8e:	6298                	ld	a4,0(a3)
    80006b90:	9732                	add	a4,a4,a2
    80006b92:	4505                	li	a0,1
    80006b94:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006b98:	f9442703          	lw	a4,-108(s0)
    80006b9c:	6288                	ld	a0,0(a3)
    80006b9e:	962a                	add	a2,a2,a0
    80006ba0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006ba4:	0712                	slli	a4,a4,0x4
    80006ba6:	6290                	ld	a2,0(a3)
    80006ba8:	963a                	add	a2,a2,a4
    80006baa:	05890513          	addi	a0,s2,88
    80006bae:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006bb0:	6294                	ld	a3,0(a3)
    80006bb2:	96ba                	add	a3,a3,a4
    80006bb4:	40000613          	li	a2,1024
    80006bb8:	c690                	sw	a2,8(a3)
  if(write)
    80006bba:	140d0063          	beqz	s10,80006cfa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006bbe:	0001e697          	auipc	a3,0x1e
    80006bc2:	4426b683          	ld	a3,1090(a3) # 80025000 <disk+0x2000>
    80006bc6:	96ba                	add	a3,a3,a4
    80006bc8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006bcc:	0001c817          	auipc	a6,0x1c
    80006bd0:	43480813          	addi	a6,a6,1076 # 80023000 <disk>
    80006bd4:	0001e517          	auipc	a0,0x1e
    80006bd8:	42c50513          	addi	a0,a0,1068 # 80025000 <disk+0x2000>
    80006bdc:	6114                	ld	a3,0(a0)
    80006bde:	96ba                	add	a3,a3,a4
    80006be0:	00c6d603          	lhu	a2,12(a3)
    80006be4:	00166613          	ori	a2,a2,1
    80006be8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006bec:	f9842683          	lw	a3,-104(s0)
    80006bf0:	6110                	ld	a2,0(a0)
    80006bf2:	9732                	add	a4,a4,a2
    80006bf4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006bf8:	20058613          	addi	a2,a1,512
    80006bfc:	0612                	slli	a2,a2,0x4
    80006bfe:	9642                	add	a2,a2,a6
    80006c00:	577d                	li	a4,-1
    80006c02:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c06:	00469713          	slli	a4,a3,0x4
    80006c0a:	6114                	ld	a3,0(a0)
    80006c0c:	96ba                	add	a3,a3,a4
    80006c0e:	03078793          	addi	a5,a5,48
    80006c12:	97c2                	add	a5,a5,a6
    80006c14:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006c16:	611c                	ld	a5,0(a0)
    80006c18:	97ba                	add	a5,a5,a4
    80006c1a:	4685                	li	a3,1
    80006c1c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c1e:	611c                	ld	a5,0(a0)
    80006c20:	97ba                	add	a5,a5,a4
    80006c22:	4809                	li	a6,2
    80006c24:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006c28:	611c                	ld	a5,0(a0)
    80006c2a:	973e                	add	a4,a4,a5
    80006c2c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006c30:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006c34:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006c38:	6518                	ld	a4,8(a0)
    80006c3a:	00275783          	lhu	a5,2(a4)
    80006c3e:	8b9d                	andi	a5,a5,7
    80006c40:	0786                	slli	a5,a5,0x1
    80006c42:	97ba                	add	a5,a5,a4
    80006c44:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006c48:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006c4c:	6518                	ld	a4,8(a0)
    80006c4e:	00275783          	lhu	a5,2(a4)
    80006c52:	2785                	addiw	a5,a5,1
    80006c54:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006c58:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006c5c:	100017b7          	lui	a5,0x10001
    80006c60:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006c64:	00492703          	lw	a4,4(s2)
    80006c68:	4785                	li	a5,1
    80006c6a:	02f71163          	bne	a4,a5,80006c8c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006c6e:	0001e997          	auipc	s3,0x1e
    80006c72:	4ba98993          	addi	s3,s3,1210 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006c76:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006c78:	85ce                	mv	a1,s3
    80006c7a:	854a                	mv	a0,s2
    80006c7c:	ffffc097          	auipc	ra,0xffffc
    80006c80:	ed4080e7          	jalr	-300(ra) # 80002b50 <sleep>
  while(b->disk == 1) {
    80006c84:	00492783          	lw	a5,4(s2)
    80006c88:	fe9788e3          	beq	a5,s1,80006c78 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006c8c:	f9042903          	lw	s2,-112(s0)
    80006c90:	20090793          	addi	a5,s2,512
    80006c94:	00479713          	slli	a4,a5,0x4
    80006c98:	0001c797          	auipc	a5,0x1c
    80006c9c:	36878793          	addi	a5,a5,872 # 80023000 <disk>
    80006ca0:	97ba                	add	a5,a5,a4
    80006ca2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006ca6:	0001e997          	auipc	s3,0x1e
    80006caa:	35a98993          	addi	s3,s3,858 # 80025000 <disk+0x2000>
    80006cae:	00491713          	slli	a4,s2,0x4
    80006cb2:	0009b783          	ld	a5,0(s3)
    80006cb6:	97ba                	add	a5,a5,a4
    80006cb8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006cbc:	854a                	mv	a0,s2
    80006cbe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006cc2:	00000097          	auipc	ra,0x0
    80006cc6:	bc4080e7          	jalr	-1084(ra) # 80006886 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006cca:	8885                	andi	s1,s1,1
    80006ccc:	f0ed                	bnez	s1,80006cae <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006cce:	0001e517          	auipc	a0,0x1e
    80006cd2:	45a50513          	addi	a0,a0,1114 # 80025128 <disk+0x2128>
    80006cd6:	ffffa097          	auipc	ra,0xffffa
    80006cda:	fd0080e7          	jalr	-48(ra) # 80000ca6 <release>
}
    80006cde:	70a6                	ld	ra,104(sp)
    80006ce0:	7406                	ld	s0,96(sp)
    80006ce2:	64e6                	ld	s1,88(sp)
    80006ce4:	6946                	ld	s2,80(sp)
    80006ce6:	69a6                	ld	s3,72(sp)
    80006ce8:	6a06                	ld	s4,64(sp)
    80006cea:	7ae2                	ld	s5,56(sp)
    80006cec:	7b42                	ld	s6,48(sp)
    80006cee:	7ba2                	ld	s7,40(sp)
    80006cf0:	7c02                	ld	s8,32(sp)
    80006cf2:	6ce2                	ld	s9,24(sp)
    80006cf4:	6d42                	ld	s10,16(sp)
    80006cf6:	6165                	addi	sp,sp,112
    80006cf8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006cfa:	0001e697          	auipc	a3,0x1e
    80006cfe:	3066b683          	ld	a3,774(a3) # 80025000 <disk+0x2000>
    80006d02:	96ba                	add	a3,a3,a4
    80006d04:	4609                	li	a2,2
    80006d06:	00c69623          	sh	a2,12(a3)
    80006d0a:	b5c9                	j	80006bcc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d0c:	f9042583          	lw	a1,-112(s0)
    80006d10:	20058793          	addi	a5,a1,512
    80006d14:	0792                	slli	a5,a5,0x4
    80006d16:	0001c517          	auipc	a0,0x1c
    80006d1a:	39250513          	addi	a0,a0,914 # 800230a8 <disk+0xa8>
    80006d1e:	953e                	add	a0,a0,a5
  if(write)
    80006d20:	e20d11e3          	bnez	s10,80006b42 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006d24:	20058713          	addi	a4,a1,512
    80006d28:	00471693          	slli	a3,a4,0x4
    80006d2c:	0001c717          	auipc	a4,0x1c
    80006d30:	2d470713          	addi	a4,a4,724 # 80023000 <disk>
    80006d34:	9736                	add	a4,a4,a3
    80006d36:	0a072423          	sw	zero,168(a4)
    80006d3a:	b505                	j	80006b5a <virtio_disk_rw+0xf4>

0000000080006d3c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006d3c:	1101                	addi	sp,sp,-32
    80006d3e:	ec06                	sd	ra,24(sp)
    80006d40:	e822                	sd	s0,16(sp)
    80006d42:	e426                	sd	s1,8(sp)
    80006d44:	e04a                	sd	s2,0(sp)
    80006d46:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006d48:	0001e517          	auipc	a0,0x1e
    80006d4c:	3e050513          	addi	a0,a0,992 # 80025128 <disk+0x2128>
    80006d50:	ffffa097          	auipc	ra,0xffffa
    80006d54:	e9c080e7          	jalr	-356(ra) # 80000bec <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006d58:	10001737          	lui	a4,0x10001
    80006d5c:	533c                	lw	a5,96(a4)
    80006d5e:	8b8d                	andi	a5,a5,3
    80006d60:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006d62:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006d66:	0001e797          	auipc	a5,0x1e
    80006d6a:	29a78793          	addi	a5,a5,666 # 80025000 <disk+0x2000>
    80006d6e:	6b94                	ld	a3,16(a5)
    80006d70:	0207d703          	lhu	a4,32(a5)
    80006d74:	0026d783          	lhu	a5,2(a3)
    80006d78:	06f70163          	beq	a4,a5,80006dda <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006d7c:	0001c917          	auipc	s2,0x1c
    80006d80:	28490913          	addi	s2,s2,644 # 80023000 <disk>
    80006d84:	0001e497          	auipc	s1,0x1e
    80006d88:	27c48493          	addi	s1,s1,636 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006d8c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006d90:	6898                	ld	a4,16(s1)
    80006d92:	0204d783          	lhu	a5,32(s1)
    80006d96:	8b9d                	andi	a5,a5,7
    80006d98:	078e                	slli	a5,a5,0x3
    80006d9a:	97ba                	add	a5,a5,a4
    80006d9c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006d9e:	20078713          	addi	a4,a5,512
    80006da2:	0712                	slli	a4,a4,0x4
    80006da4:	974a                	add	a4,a4,s2
    80006da6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006daa:	e731                	bnez	a4,80006df6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006dac:	20078793          	addi	a5,a5,512
    80006db0:	0792                	slli	a5,a5,0x4
    80006db2:	97ca                	add	a5,a5,s2
    80006db4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006db6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006dba:	ffffc097          	auipc	ra,0xffffc
    80006dbe:	f3c080e7          	jalr	-196(ra) # 80002cf6 <wakeup>

    disk.used_idx += 1;
    80006dc2:	0204d783          	lhu	a5,32(s1)
    80006dc6:	2785                	addiw	a5,a5,1
    80006dc8:	17c2                	slli	a5,a5,0x30
    80006dca:	93c1                	srli	a5,a5,0x30
    80006dcc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006dd0:	6898                	ld	a4,16(s1)
    80006dd2:	00275703          	lhu	a4,2(a4)
    80006dd6:	faf71be3          	bne	a4,a5,80006d8c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006dda:	0001e517          	auipc	a0,0x1e
    80006dde:	34e50513          	addi	a0,a0,846 # 80025128 <disk+0x2128>
    80006de2:	ffffa097          	auipc	ra,0xffffa
    80006de6:	ec4080e7          	jalr	-316(ra) # 80000ca6 <release>
}
    80006dea:	60e2                	ld	ra,24(sp)
    80006dec:	6442                	ld	s0,16(sp)
    80006dee:	64a2                	ld	s1,8(sp)
    80006df0:	6902                	ld	s2,0(sp)
    80006df2:	6105                	addi	sp,sp,32
    80006df4:	8082                	ret
      panic("virtio_disk_intr status");
    80006df6:	00002517          	auipc	a0,0x2
    80006dfa:	b6a50513          	addi	a0,a0,-1174 # 80008960 <syscalls+0x3c0>
    80006dfe:	ffff9097          	auipc	ra,0xffff9
    80006e02:	740080e7          	jalr	1856(ra) # 8000053e <panic>

0000000080006e06 <cas>:
    80006e06:	100522af          	lr.w	t0,(a0)
    80006e0a:	00b29563          	bne	t0,a1,80006e14 <fail>
    80006e0e:	18c5252f          	sc.w	a0,a2,(a0)
    80006e12:	8082                	ret

0000000080006e14 <fail>:
    80006e14:	4505                	li	a0,1
    80006e16:	8082                	ret
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
