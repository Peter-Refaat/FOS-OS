
obj/user/arrayOperations_mergesort:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	mov $0, %eax
  800020:	b8 00 00 00 00       	mov    $0x0,%eax
	cmpl $USTACKTOP, %esp
  800025:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  80002b:	75 04                	jne    800031 <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  80002d:	6a 00                	push   $0x0
	pushl $0
  80002f:	6a 00                	push   $0x0

00800031 <args_exist>:

args_exist:
	call libmain
  800031:	e8 c9 04 00 00       	call   8004ff <libmain>
1:      jmp 1b
  800036:	eb fe                	jmp    800036 <args_exist+0x5>

00800038 <_main>:

//int *Left;
//int *Right;

void _main(void)
{
  800038:	55                   	push   %ebp
  800039:	89 e5                	mov    %esp,%ebp
  80003b:	83 ec 38             	sub    $0x38,%esp
	int32 parentenvID = sys_getparentenvid();
  80003e:	e8 e9 1a 00 00       	call   801b2c <sys_getparentenvid>
  800043:	89 45 f0             	mov    %eax,-0x10(%ebp)

	int ret;

	/*[1] GET SEMAPHORES*/
	struct semaphore ready = get_semaphore(parentenvID, "Ready");
  800046:	8d 45 dc             	lea    -0x24(%ebp),%eax
  800049:	83 ec 04             	sub    $0x4,%esp
  80004c:	68 60 24 80 00       	push   $0x802460
  800051:	ff 75 f0             	pushl  -0x10(%ebp)
  800054:	50                   	push   %eax
  800055:	e8 54 1f 00 00       	call   801fae <get_semaphore>
  80005a:	83 c4 0c             	add    $0xc,%esp
	struct semaphore finished = get_semaphore(parentenvID, "Finished");
  80005d:	8d 45 d8             	lea    -0x28(%ebp),%eax
  800060:	83 ec 04             	sub    $0x4,%esp
  800063:	68 66 24 80 00       	push   $0x802466
  800068:	ff 75 f0             	pushl  -0x10(%ebp)
  80006b:	50                   	push   %eax
  80006c:	e8 3d 1f 00 00       	call   801fae <get_semaphore>
  800071:	83 c4 0c             	add    $0xc,%esp

	/*[2] WAIT A READY SIGNAL FROM THE MASTER*/
	wait_semaphore(ready);
  800074:	83 ec 0c             	sub    $0xc,%esp
  800077:	ff 75 dc             	pushl  -0x24(%ebp)
  80007a:	e8 49 1f 00 00       	call   801fc8 <wait_semaphore>
  80007f:	83 c4 10             	add    $0x10,%esp

	/*[3] GET SHARED VARs*/
	//Get the cons_mutex ownerID
	int* consMutexOwnerID = sget(parentenvID, "cons_mutex ownerID") ;
  800082:	83 ec 08             	sub    $0x8,%esp
  800085:	68 6f 24 80 00       	push   $0x80246f
  80008a:	ff 75 f0             	pushl  -0x10(%ebp)
  80008d:	e8 3b 17 00 00       	call   8017cd <sget>
  800092:	83 c4 10             	add    $0x10,%esp
  800095:	89 45 ec             	mov    %eax,-0x14(%ebp)
	struct semaphore cons_mutex = get_semaphore(*consMutexOwnerID, "Console Mutex");
  800098:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80009b:	8b 10                	mov    (%eax),%edx
  80009d:	8d 45 d4             	lea    -0x2c(%ebp),%eax
  8000a0:	83 ec 04             	sub    $0x4,%esp
  8000a3:	68 82 24 80 00       	push   $0x802482
  8000a8:	52                   	push   %edx
  8000a9:	50                   	push   %eax
  8000aa:	e8 ff 1e 00 00       	call   801fae <get_semaphore>
  8000af:	83 c4 0c             	add    $0xc,%esp

	//Get the shared array & its size
	int *numOfElements = NULL;
  8000b2:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
	int *sharedArray = NULL;
  8000b9:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	sharedArray = sget(parentenvID, "arr") ;
  8000c0:	83 ec 08             	sub    $0x8,%esp
  8000c3:	68 90 24 80 00       	push   $0x802490
  8000c8:	ff 75 f0             	pushl  -0x10(%ebp)
  8000cb:	e8 fd 16 00 00       	call   8017cd <sget>
  8000d0:	83 c4 10             	add    $0x10,%esp
  8000d3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	numOfElements = sget(parentenvID, "arrSize") ;
  8000d6:	83 ec 08             	sub    $0x8,%esp
  8000d9:	68 94 24 80 00       	push   $0x802494
  8000de:	ff 75 f0             	pushl  -0x10(%ebp)
  8000e1:	e8 e7 16 00 00       	call   8017cd <sget>
  8000e6:	83 c4 10             	add    $0x10,%esp
  8000e9:	89 45 e8             	mov    %eax,-0x18(%ebp)

	/*[4] DO THE JOB*/
	//take a copy from the original array
	int *sortedArray;

	sortedArray = smalloc("mergesortedArr", sizeof(int) * *numOfElements, 0) ;
  8000ec:	8b 45 e8             	mov    -0x18(%ebp),%eax
  8000ef:	8b 00                	mov    (%eax),%eax
  8000f1:	c1 e0 02             	shl    $0x2,%eax
  8000f4:	83 ec 04             	sub    $0x4,%esp
  8000f7:	6a 00                	push   $0x0
  8000f9:	50                   	push   %eax
  8000fa:	68 9c 24 80 00       	push   $0x80249c
  8000ff:	e8 95 16 00 00       	call   801799 <smalloc>
  800104:	83 c4 10             	add    $0x10,%esp
  800107:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int i ;
	for (i = 0 ; i < *numOfElements ; i++)
  80010a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  800111:	eb 25                	jmp    800138 <_main+0x100>
	{
		sortedArray[i] = sharedArray[i];
  800113:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800116:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  80011d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800120:	01 c2                	add    %eax,%edx
  800122:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800125:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
  80012c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80012f:	01 c8                	add    %ecx,%eax
  800131:	8b 00                	mov    (%eax),%eax
  800133:	89 02                	mov    %eax,(%edx)
	//take a copy from the original array
	int *sortedArray;

	sortedArray = smalloc("mergesortedArr", sizeof(int) * *numOfElements, 0) ;
	int i ;
	for (i = 0 ; i < *numOfElements ; i++)
  800135:	ff 45 f4             	incl   -0xc(%ebp)
  800138:	8b 45 e8             	mov    -0x18(%ebp),%eax
  80013b:	8b 00                	mov    (%eax),%eax
  80013d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  800140:	7f d1                	jg     800113 <_main+0xdb>
	}
//	//Create two temps array for "left" & "right"
//	Left = smalloc("mergesortLeftArr", sizeof(int) * (*numOfElements), 1) ;
//	Right = smalloc("mergesortRightArr", sizeof(int) * (*numOfElements), 1) ;

	MSort(sortedArray, 1, *numOfElements);
  800142:	8b 45 e8             	mov    -0x18(%ebp),%eax
  800145:	8b 00                	mov    (%eax),%eax
  800147:	83 ec 04             	sub    $0x4,%esp
  80014a:	50                   	push   %eax
  80014b:	6a 01                	push   $0x1
  80014d:	ff 75 e0             	pushl  -0x20(%ebp)
  800150:	e8 39 01 00 00       	call   80028e <MSort>
  800155:	83 c4 10             	add    $0x10,%esp

	wait_semaphore(cons_mutex);
  800158:	83 ec 0c             	sub    $0xc,%esp
  80015b:	ff 75 d4             	pushl  -0x2c(%ebp)
  80015e:	e8 65 1e 00 00       	call   801fc8 <wait_semaphore>
  800163:	83 c4 10             	add    $0x10,%esp
	{
		cprintf("Merge sort is Finished!!!!\n") ;
  800166:	83 ec 0c             	sub    $0xc,%esp
  800169:	68 ab 24 80 00       	push   $0x8024ab
  80016e:	e8 1c 06 00 00       	call   80078f <cprintf>
  800173:	83 c4 10             	add    $0x10,%esp
		cprintf("will notify the master now...\n");
  800176:	83 ec 0c             	sub    $0xc,%esp
  800179:	68 c8 24 80 00       	push   $0x8024c8
  80017e:	e8 0c 06 00 00       	call   80078f <cprintf>
  800183:	83 c4 10             	add    $0x10,%esp
		cprintf("Merge sort says GOOD BYE :)\n") ;
  800186:	83 ec 0c             	sub    $0xc,%esp
  800189:	68 e7 24 80 00       	push   $0x8024e7
  80018e:	e8 fc 05 00 00       	call   80078f <cprintf>
  800193:	83 c4 10             	add    $0x10,%esp
	}
	signal_semaphore(cons_mutex);
  800196:	83 ec 0c             	sub    $0xc,%esp
  800199:	ff 75 d4             	pushl  -0x2c(%ebp)
  80019c:	e8 41 1e 00 00       	call   801fe2 <signal_semaphore>
  8001a1:	83 c4 10             	add    $0x10,%esp

	/*[5] DECLARE FINISHING*/
	signal_semaphore(finished);
  8001a4:	83 ec 0c             	sub    $0xc,%esp
  8001a7:	ff 75 d8             	pushl  -0x28(%ebp)
  8001aa:	e8 33 1e 00 00       	call   801fe2 <signal_semaphore>
  8001af:	83 c4 10             	add    $0x10,%esp
}
  8001b2:	90                   	nop
  8001b3:	c9                   	leave  
  8001b4:	c3                   	ret    

008001b5 <Swap>:

void Swap(int *Elements, int First, int Second)
{
  8001b5:	55                   	push   %ebp
  8001b6:	89 e5                	mov    %esp,%ebp
  8001b8:	83 ec 10             	sub    $0x10,%esp
	int Tmp = Elements[First] ;
  8001bb:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001be:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  8001c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8001c8:	01 d0                	add    %edx,%eax
  8001ca:	8b 00                	mov    (%eax),%eax
  8001cc:	89 45 fc             	mov    %eax,-0x4(%ebp)
	Elements[First] = Elements[Second] ;
  8001cf:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001d2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  8001d9:	8b 45 08             	mov    0x8(%ebp),%eax
  8001dc:	01 c2                	add    %eax,%edx
  8001de:	8b 45 10             	mov    0x10(%ebp),%eax
  8001e1:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
  8001e8:	8b 45 08             	mov    0x8(%ebp),%eax
  8001eb:	01 c8                	add    %ecx,%eax
  8001ed:	8b 00                	mov    (%eax),%eax
  8001ef:	89 02                	mov    %eax,(%edx)
	Elements[Second] = Tmp ;
  8001f1:	8b 45 10             	mov    0x10(%ebp),%eax
  8001f4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  8001fb:	8b 45 08             	mov    0x8(%ebp),%eax
  8001fe:	01 c2                	add    %eax,%edx
  800200:	8b 45 fc             	mov    -0x4(%ebp),%eax
  800203:	89 02                	mov    %eax,(%edx)
}
  800205:	90                   	nop
  800206:	c9                   	leave  
  800207:	c3                   	ret    

00800208 <PrintElements>:


void PrintElements(int *Elements, int NumOfElements)
{
  800208:	55                   	push   %ebp
  800209:	89 e5                	mov    %esp,%ebp
  80020b:	83 ec 18             	sub    $0x18,%esp
	int i ;
	int NumsPerLine = 20 ;
  80020e:	c7 45 f0 14 00 00 00 	movl   $0x14,-0x10(%ebp)
	for (i = 0 ; i < NumOfElements-1 ; i++)
  800215:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  80021c:	eb 42                	jmp    800260 <PrintElements+0x58>
	{
		if (i%NumsPerLine == 0)
  80021e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800221:	99                   	cltd   
  800222:	f7 7d f0             	idivl  -0x10(%ebp)
  800225:	89 d0                	mov    %edx,%eax
  800227:	85 c0                	test   %eax,%eax
  800229:	75 10                	jne    80023b <PrintElements+0x33>
			cprintf("\n");
  80022b:	83 ec 0c             	sub    $0xc,%esp
  80022e:	68 04 25 80 00       	push   $0x802504
  800233:	e8 57 05 00 00       	call   80078f <cprintf>
  800238:	83 c4 10             	add    $0x10,%esp
		cprintf("%d, ",Elements[i]);
  80023b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80023e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  800245:	8b 45 08             	mov    0x8(%ebp),%eax
  800248:	01 d0                	add    %edx,%eax
  80024a:	8b 00                	mov    (%eax),%eax
  80024c:	83 ec 08             	sub    $0x8,%esp
  80024f:	50                   	push   %eax
  800250:	68 06 25 80 00       	push   $0x802506
  800255:	e8 35 05 00 00       	call   80078f <cprintf>
  80025a:	83 c4 10             	add    $0x10,%esp

void PrintElements(int *Elements, int NumOfElements)
{
	int i ;
	int NumsPerLine = 20 ;
	for (i = 0 ; i < NumOfElements-1 ; i++)
  80025d:	ff 45 f4             	incl   -0xc(%ebp)
  800260:	8b 45 0c             	mov    0xc(%ebp),%eax
  800263:	48                   	dec    %eax
  800264:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  800267:	7f b5                	jg     80021e <PrintElements+0x16>
	{
		if (i%NumsPerLine == 0)
			cprintf("\n");
		cprintf("%d, ",Elements[i]);
	}
	cprintf("%d\n",Elements[i]);
  800269:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80026c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  800273:	8b 45 08             	mov    0x8(%ebp),%eax
  800276:	01 d0                	add    %edx,%eax
  800278:	8b 00                	mov    (%eax),%eax
  80027a:	83 ec 08             	sub    $0x8,%esp
  80027d:	50                   	push   %eax
  80027e:	68 0b 25 80 00       	push   $0x80250b
  800283:	e8 07 05 00 00       	call   80078f <cprintf>
  800288:	83 c4 10             	add    $0x10,%esp

}
  80028b:	90                   	nop
  80028c:	c9                   	leave  
  80028d:	c3                   	ret    

0080028e <MSort>:


void MSort(int* A, int p, int r)
{
  80028e:	55                   	push   %ebp
  80028f:	89 e5                	mov    %esp,%ebp
  800291:	83 ec 18             	sub    $0x18,%esp
	if (p >= r)
  800294:	8b 45 0c             	mov    0xc(%ebp),%eax
  800297:	3b 45 10             	cmp    0x10(%ebp),%eax
  80029a:	7d 54                	jge    8002f0 <MSort+0x62>
	{
		return;
	}

	int q = (p + r) / 2;
  80029c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80029f:	8b 45 10             	mov    0x10(%ebp),%eax
  8002a2:	01 d0                	add    %edx,%eax
  8002a4:	89 c2                	mov    %eax,%edx
  8002a6:	c1 ea 1f             	shr    $0x1f,%edx
  8002a9:	01 d0                	add    %edx,%eax
  8002ab:	d1 f8                	sar    %eax
  8002ad:	89 45 f4             	mov    %eax,-0xc(%ebp)

	MSort(A, p, q);
  8002b0:	83 ec 04             	sub    $0x4,%esp
  8002b3:	ff 75 f4             	pushl  -0xc(%ebp)
  8002b6:	ff 75 0c             	pushl  0xc(%ebp)
  8002b9:	ff 75 08             	pushl  0x8(%ebp)
  8002bc:	e8 cd ff ff ff       	call   80028e <MSort>
  8002c1:	83 c4 10             	add    $0x10,%esp
//	cprintf("LEFT is sorted: from %d to %d\n", p, q);

	MSort(A, q + 1, r);
  8002c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8002c7:	40                   	inc    %eax
  8002c8:	83 ec 04             	sub    $0x4,%esp
  8002cb:	ff 75 10             	pushl  0x10(%ebp)
  8002ce:	50                   	push   %eax
  8002cf:	ff 75 08             	pushl  0x8(%ebp)
  8002d2:	e8 b7 ff ff ff       	call   80028e <MSort>
  8002d7:	83 c4 10             	add    $0x10,%esp
//	cprintf("RIGHT is sorted: from %d to %d\n", q+1, r);

	Merge(A, p, q, r);
  8002da:	ff 75 10             	pushl  0x10(%ebp)
  8002dd:	ff 75 f4             	pushl  -0xc(%ebp)
  8002e0:	ff 75 0c             	pushl  0xc(%ebp)
  8002e3:	ff 75 08             	pushl  0x8(%ebp)
  8002e6:	e8 08 00 00 00       	call   8002f3 <Merge>
  8002eb:	83 c4 10             	add    $0x10,%esp
  8002ee:	eb 01                	jmp    8002f1 <MSort+0x63>

void MSort(int* A, int p, int r)
{
	if (p >= r)
	{
		return;
  8002f0:	90                   	nop
//	cprintf("RIGHT is sorted: from %d to %d\n", q+1, r);

	Merge(A, p, q, r);
	//cprintf("[%d %d] + [%d %d] = [%d %d]\n", p, q, q+1, r, p, r);

}
  8002f1:	c9                   	leave  
  8002f2:	c3                   	ret    

008002f3 <Merge>:

void Merge(int* A, int p, int q, int r)
{
  8002f3:	55                   	push   %ebp
  8002f4:	89 e5                	mov    %esp,%ebp
  8002f6:	83 ec 38             	sub    $0x38,%esp
	int leftCapacity = q - p + 1;
  8002f9:	8b 45 10             	mov    0x10(%ebp),%eax
  8002fc:	2b 45 0c             	sub    0xc(%ebp),%eax
  8002ff:	40                   	inc    %eax
  800300:	89 45 e0             	mov    %eax,-0x20(%ebp)

	int rightCapacity = r - q;
  800303:	8b 45 14             	mov    0x14(%ebp),%eax
  800306:	2b 45 10             	sub    0x10(%ebp),%eax
  800309:	89 45 dc             	mov    %eax,-0x24(%ebp)

	int leftIndex = 0;
  80030c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	int rightIndex = 0;
  800313:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)

	int* Left = malloc(sizeof(int) * leftCapacity);
  80031a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80031d:	c1 e0 02             	shl    $0x2,%eax
  800320:	83 ec 0c             	sub    $0xc,%esp
  800323:	50                   	push   %eax
  800324:	e8 28 14 00 00       	call   801751 <malloc>
  800329:	83 c4 10             	add    $0x10,%esp
  80032c:	89 45 d8             	mov    %eax,-0x28(%ebp)

	int* Right = malloc(sizeof(int) * rightCapacity);
  80032f:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800332:	c1 e0 02             	shl    $0x2,%eax
  800335:	83 ec 0c             	sub    $0xc,%esp
  800338:	50                   	push   %eax
  800339:	e8 13 14 00 00       	call   801751 <malloc>
  80033e:	83 c4 10             	add    $0x10,%esp
  800341:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	int i, j, k;
	for (i = 0; i < leftCapacity; i++)
  800344:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  80034b:	eb 2f                	jmp    80037c <Merge+0x89>
	{
		Left[i] = A[p + i - 1];
  80034d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800350:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  800357:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80035a:	01 c2                	add    %eax,%edx
  80035c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80035f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800362:	01 c8                	add    %ecx,%eax
  800364:	05 ff ff ff 3f       	add    $0x3fffffff,%eax
  800369:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
  800370:	8b 45 08             	mov    0x8(%ebp),%eax
  800373:	01 c8                	add    %ecx,%eax
  800375:	8b 00                	mov    (%eax),%eax
  800377:	89 02                	mov    %eax,(%edx)
	int* Left = malloc(sizeof(int) * leftCapacity);

	int* Right = malloc(sizeof(int) * rightCapacity);

	int i, j, k;
	for (i = 0; i < leftCapacity; i++)
  800379:	ff 45 ec             	incl   -0x14(%ebp)
  80037c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80037f:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800382:	7c c9                	jl     80034d <Merge+0x5a>
	{
		Left[i] = A[p + i - 1];
	}
	for (j = 0; j < rightCapacity; j++)
  800384:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  80038b:	eb 2a                	jmp    8003b7 <Merge+0xc4>
	{
		Right[j] = A[q + j];
  80038d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  800390:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  800397:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80039a:	01 c2                	add    %eax,%edx
  80039c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80039f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  8003a2:	01 c8                	add    %ecx,%eax
  8003a4:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
  8003ab:	8b 45 08             	mov    0x8(%ebp),%eax
  8003ae:	01 c8                	add    %ecx,%eax
  8003b0:	8b 00                	mov    (%eax),%eax
  8003b2:	89 02                	mov    %eax,(%edx)
	int i, j, k;
	for (i = 0; i < leftCapacity; i++)
	{
		Left[i] = A[p + i - 1];
	}
	for (j = 0; j < rightCapacity; j++)
  8003b4:	ff 45 e8             	incl   -0x18(%ebp)
  8003b7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  8003ba:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  8003bd:	7c ce                	jl     80038d <Merge+0x9a>
	{
		Right[j] = A[q + j];
	}

	for ( k = p; k <= r; k++)
  8003bf:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003c5:	e9 0a 01 00 00       	jmp    8004d4 <Merge+0x1e1>
	{
		if (leftIndex < leftCapacity && rightIndex < rightCapacity)
  8003ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8003cd:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8003d0:	0f 8d 95 00 00 00    	jge    80046b <Merge+0x178>
  8003d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8003d9:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  8003dc:	0f 8d 89 00 00 00    	jge    80046b <Merge+0x178>
		{
			if (Left[leftIndex] < Right[rightIndex] )
  8003e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8003e5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  8003ec:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8003ef:	01 d0                	add    %edx,%eax
  8003f1:	8b 10                	mov    (%eax),%edx
  8003f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8003f6:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
  8003fd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800400:	01 c8                	add    %ecx,%eax
  800402:	8b 00                	mov    (%eax),%eax
  800404:	39 c2                	cmp    %eax,%edx
  800406:	7d 33                	jge    80043b <Merge+0x148>
			{
				A[k - 1] = Left[leftIndex++];
  800408:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80040b:	05 ff ff ff 3f       	add    $0x3fffffff,%eax
  800410:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  800417:	8b 45 08             	mov    0x8(%ebp),%eax
  80041a:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
  80041d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800420:	8d 50 01             	lea    0x1(%eax),%edx
  800423:	89 55 f4             	mov    %edx,-0xc(%ebp)
  800426:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  80042d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800430:	01 d0                	add    %edx,%eax
  800432:	8b 00                	mov    (%eax),%eax
  800434:	89 01                	mov    %eax,(%ecx)

	for ( k = p; k <= r; k++)
	{
		if (leftIndex < leftCapacity && rightIndex < rightCapacity)
		{
			if (Left[leftIndex] < Right[rightIndex] )
  800436:	e9 96 00 00 00       	jmp    8004d1 <Merge+0x1de>
			{
				A[k - 1] = Left[leftIndex++];
			}
			else
			{
				A[k - 1] = Right[rightIndex++];
  80043b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80043e:	05 ff ff ff 3f       	add    $0x3fffffff,%eax
  800443:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  80044a:	8b 45 08             	mov    0x8(%ebp),%eax
  80044d:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
  800450:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800453:	8d 50 01             	lea    0x1(%eax),%edx
  800456:	89 55 f0             	mov    %edx,-0x10(%ebp)
  800459:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  800460:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800463:	01 d0                	add    %edx,%eax
  800465:	8b 00                	mov    (%eax),%eax
  800467:	89 01                	mov    %eax,(%ecx)

	for ( k = p; k <= r; k++)
	{
		if (leftIndex < leftCapacity && rightIndex < rightCapacity)
		{
			if (Left[leftIndex] < Right[rightIndex] )
  800469:	eb 66                	jmp    8004d1 <Merge+0x1de>
			else
			{
				A[k - 1] = Right[rightIndex++];
			}
		}
		else if (leftIndex < leftCapacity)
  80046b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80046e:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800471:	7d 30                	jge    8004a3 <Merge+0x1b0>
		{
			A[k - 1] = Left[leftIndex++];
  800473:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800476:	05 ff ff ff 3f       	add    $0x3fffffff,%eax
  80047b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  800482:	8b 45 08             	mov    0x8(%ebp),%eax
  800485:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
  800488:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80048b:	8d 50 01             	lea    0x1(%eax),%edx
  80048e:	89 55 f4             	mov    %edx,-0xc(%ebp)
  800491:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  800498:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80049b:	01 d0                	add    %edx,%eax
  80049d:	8b 00                	mov    (%eax),%eax
  80049f:	89 01                	mov    %eax,(%ecx)
  8004a1:	eb 2e                	jmp    8004d1 <Merge+0x1de>
		}
		else
		{
			A[k - 1] = Right[rightIndex++];
  8004a3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8004a6:	05 ff ff ff 3f       	add    $0x3fffffff,%eax
  8004ab:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  8004b2:	8b 45 08             	mov    0x8(%ebp),%eax
  8004b5:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
  8004b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8004bb:	8d 50 01             	lea    0x1(%eax),%edx
  8004be:	89 55 f0             	mov    %edx,-0x10(%ebp)
  8004c1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  8004c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8004cb:	01 d0                	add    %edx,%eax
  8004cd:	8b 00                	mov    (%eax),%eax
  8004cf:	89 01                	mov    %eax,(%ecx)
	for (j = 0; j < rightCapacity; j++)
	{
		Right[j] = A[q + j];
	}

	for ( k = p; k <= r; k++)
  8004d1:	ff 45 e4             	incl   -0x1c(%ebp)
  8004d4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8004d7:	3b 45 14             	cmp    0x14(%ebp),%eax
  8004da:	0f 8e ea fe ff ff    	jle    8003ca <Merge+0xd7>
		{
			A[k - 1] = Right[rightIndex++];
		}
	}

	free(Left);
  8004e0:	83 ec 0c             	sub    $0xc,%esp
  8004e3:	ff 75 d8             	pushl  -0x28(%ebp)
  8004e6:	e8 94 12 00 00       	call   80177f <free>
  8004eb:	83 c4 10             	add    $0x10,%esp
	free(Right);
  8004ee:	83 ec 0c             	sub    $0xc,%esp
  8004f1:	ff 75 d4             	pushl  -0x2c(%ebp)
  8004f4:	e8 86 12 00 00       	call   80177f <free>
  8004f9:	83 c4 10             	add    $0x10,%esp

}
  8004fc:	90                   	nop
  8004fd:	c9                   	leave  
  8004fe:	c3                   	ret    

008004ff <libmain>:
volatile bool printStats = 1;

volatile char *binaryname = "(PROGRAM NAME UNKNOWN)";
void
libmain(int argc, char **argv)
{
  8004ff:	55                   	push   %ebp
  800500:	89 e5                	mov    %esp,%ebp
  800502:	57                   	push   %edi
  800503:	56                   	push   %esi
  800504:	53                   	push   %ebx
  800505:	83 ec 7c             	sub    $0x7c,%esp
	//printStats = 1;
	int envIndex = sys_getenvindex();
  800508:	e8 06 16 00 00       	call   801b13 <sys_getenvindex>
  80050d:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	myEnv = &(envs[envIndex]);
  800510:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800513:	89 d0                	mov    %edx,%eax
  800515:	c1 e0 02             	shl    $0x2,%eax
  800518:	01 d0                	add    %edx,%eax
  80051a:	c1 e0 03             	shl    $0x3,%eax
  80051d:	01 d0                	add    %edx,%eax
  80051f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  800526:	01 d0                	add    %edx,%eax
  800528:	c1 e0 02             	shl    $0x2,%eax
  80052b:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800530:	a3 20 30 80 00       	mov    %eax,0x803020

	//SET THE PROGRAM NAME
	if (myEnv->prog_name[0] != '\0')
  800535:	a1 20 30 80 00       	mov    0x803020,%eax
  80053a:	8a 40 20             	mov    0x20(%eax),%al
  80053d:	84 c0                	test   %al,%al
  80053f:	74 0d                	je     80054e <libmain+0x4f>
		binaryname = myEnv->prog_name;
  800541:	a1 20 30 80 00       	mov    0x803020,%eax
  800546:	83 c0 20             	add    $0x20,%eax
  800549:	a3 04 30 80 00       	mov    %eax,0x803004

	// set env to point at our env structure in envs[].
	// env = envs;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80054e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  800552:	7e 0a                	jle    80055e <libmain+0x5f>
		binaryname = argv[0];
  800554:	8b 45 0c             	mov    0xc(%ebp),%eax
  800557:	8b 00                	mov    (%eax),%eax
  800559:	a3 04 30 80 00       	mov    %eax,0x803004

	// call user main routine
	_main(argc, argv);
  80055e:	83 ec 08             	sub    $0x8,%esp
  800561:	ff 75 0c             	pushl  0xc(%ebp)
  800564:	ff 75 08             	pushl  0x8(%ebp)
  800567:	e8 cc fa ff ff       	call   800038 <_main>
  80056c:	83 c4 10             	add    $0x10,%esp

	if (printStats)
  80056f:	a1 00 30 80 00       	mov    0x803000,%eax
  800574:	85 c0                	test   %eax,%eax
  800576:	0f 84 01 01 00 00    	je     80067d <libmain+0x17e>
	{
		char isOPTReplCmd[100] = "__IsOPTRepl__" ;
  80057c:	8d 85 7c ff ff ff    	lea    -0x84(%ebp),%eax
  800582:	bb 08 26 80 00       	mov    $0x802608,%ebx
  800587:	ba 0e 00 00 00       	mov    $0xe,%edx
  80058c:	89 c7                	mov    %eax,%edi
  80058e:	89 de                	mov    %ebx,%esi
  800590:	89 d1                	mov    %edx,%ecx
  800592:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  800594:	8d 55 8a             	lea    -0x76(%ebp),%edx
  800597:	b9 56 00 00 00       	mov    $0x56,%ecx
  80059c:	b0 00                	mov    $0x0,%al
  80059e:	89 d7                	mov    %edx,%edi
  8005a0:	f3 aa                	rep stos %al,%es:(%edi)
		int isOPTRepl = 0;
  8005a2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		sys_utilities(isOPTReplCmd, (uint32)(&isOPTRepl));
  8005a9:	8d 45 e0             	lea    -0x20(%ebp),%eax
  8005ac:	83 ec 08             	sub    $0x8,%esp
  8005af:	50                   	push   %eax
  8005b0:	8d 85 7c ff ff ff    	lea    -0x84(%ebp),%eax
  8005b6:	50                   	push   %eax
  8005b7:	e8 8d 17 00 00       	call   801d49 <sys_utilities>
  8005bc:	83 c4 10             	add    $0x10,%esp

		sys_lock_cons();
  8005bf:	e8 d6 12 00 00       	call   80189a <sys_lock_cons>
		{
			cprintf("**************************************\n");
  8005c4:	83 ec 0c             	sub    $0xc,%esp
  8005c7:	68 28 25 80 00       	push   $0x802528
  8005cc:	e8 be 01 00 00       	call   80078f <cprintf>
  8005d1:	83 c4 10             	add    $0x10,%esp
			if (isOPTRepl)
  8005d4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005d7:	85 c0                	test   %eax,%eax
  8005d9:	74 18                	je     8005f3 <libmain+0xf4>
			{
				cprintf("OPTIMAL number of page faults = %d\n", sys_get_optimal_num_faults());
  8005db:	e8 87 17 00 00       	call   801d67 <sys_get_optimal_num_faults>
  8005e0:	83 ec 08             	sub    $0x8,%esp
  8005e3:	50                   	push   %eax
  8005e4:	68 50 25 80 00       	push   $0x802550
  8005e9:	e8 a1 01 00 00       	call   80078f <cprintf>
  8005ee:	83 c4 10             	add    $0x10,%esp
  8005f1:	eb 59                	jmp    80064c <libmain+0x14d>
			}
			else
			{
				cprintf("Num of PAGE faults = %d, modif = %d\n", myEnv->pageFaultsCounter, myEnv->nModifiedPages);
  8005f3:	a1 20 30 80 00       	mov    0x803020,%eax
  8005f8:	8b 90 a8 05 00 00    	mov    0x5a8(%eax),%edx
  8005fe:	a1 20 30 80 00       	mov    0x803020,%eax
  800603:	8b 80 98 05 00 00    	mov    0x598(%eax),%eax
  800609:	83 ec 04             	sub    $0x4,%esp
  80060c:	52                   	push   %edx
  80060d:	50                   	push   %eax
  80060e:	68 74 25 80 00       	push   $0x802574
  800613:	e8 77 01 00 00       	call   80078f <cprintf>
  800618:	83 c4 10             	add    $0x10,%esp
				cprintf("# PAGE IN (from disk) = %d, # PAGE OUT (on disk) = %d, # NEW PAGE ADDED (on disk) = %d\n", myEnv->nPageIn, myEnv->nPageOut,myEnv->nNewPageAdded);
  80061b:	a1 20 30 80 00       	mov    0x803020,%eax
  800620:	8b 88 bc 05 00 00    	mov    0x5bc(%eax),%ecx
  800626:	a1 20 30 80 00       	mov    0x803020,%eax
  80062b:	8b 90 b8 05 00 00    	mov    0x5b8(%eax),%edx
  800631:	a1 20 30 80 00       	mov    0x803020,%eax
  800636:	8b 80 b4 05 00 00    	mov    0x5b4(%eax),%eax
  80063c:	51                   	push   %ecx
  80063d:	52                   	push   %edx
  80063e:	50                   	push   %eax
  80063f:	68 9c 25 80 00       	push   $0x80259c
  800644:	e8 46 01 00 00       	call   80078f <cprintf>
  800649:	83 c4 10             	add    $0x10,%esp
			}
			//cprintf("Num of freeing scarce memory = %d, freeing full working set = %d\n", myEnv->freeingScarceMemCounter, myEnv->freeingFullWSCounter);
			cprintf("Num of clocks = %d\n", myEnv->nClocks);
  80064c:	a1 20 30 80 00       	mov    0x803020,%eax
  800651:	8b 80 c0 05 00 00    	mov    0x5c0(%eax),%eax
  800657:	83 ec 08             	sub    $0x8,%esp
  80065a:	50                   	push   %eax
  80065b:	68 f4 25 80 00       	push   $0x8025f4
  800660:	e8 2a 01 00 00       	call   80078f <cprintf>
  800665:	83 c4 10             	add    $0x10,%esp
			cprintf("**************************************\n");
  800668:	83 ec 0c             	sub    $0xc,%esp
  80066b:	68 28 25 80 00       	push   $0x802528
  800670:	e8 1a 01 00 00       	call   80078f <cprintf>
  800675:	83 c4 10             	add    $0x10,%esp
		}
		sys_unlock_cons();
  800678:	e8 37 12 00 00       	call   8018b4 <sys_unlock_cons>
	}

	// exit gracefully
	exit();
  80067d:	e8 1f 00 00 00       	call   8006a1 <exit>
}
  800682:	90                   	nop
  800683:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800686:	5b                   	pop    %ebx
  800687:	5e                   	pop    %esi
  800688:	5f                   	pop    %edi
  800689:	5d                   	pop    %ebp
  80068a:	c3                   	ret    

0080068b <destroy>:

#include <inc/lib.h>

void
destroy(void)
{
  80068b:	55                   	push   %ebp
  80068c:	89 e5                	mov    %esp,%ebp
  80068e:	83 ec 08             	sub    $0x8,%esp
	sys_destroy_env(0);
  800691:	83 ec 0c             	sub    $0xc,%esp
  800694:	6a 00                	push   $0x0
  800696:	e8 44 14 00 00       	call   801adf <sys_destroy_env>
  80069b:	83 c4 10             	add    $0x10,%esp
}
  80069e:	90                   	nop
  80069f:	c9                   	leave  
  8006a0:	c3                   	ret    

008006a1 <exit>:

void
exit(void)
{
  8006a1:	55                   	push   %ebp
  8006a2:	89 e5                	mov    %esp,%ebp
  8006a4:	83 ec 08             	sub    $0x8,%esp
	sys_exit_env();
  8006a7:	e8 99 14 00 00       	call   801b45 <sys_exit_env>
}
  8006ac:	90                   	nop
  8006ad:	c9                   	leave  
  8006ae:	c3                   	ret    

008006af <putch>:
	int idx; // current buffer index
	int cnt; // total bytes printed so far
	char buf[256];
};

static void putch(int ch, struct printbuf *b) {
  8006af:	55                   	push   %ebp
  8006b0:	89 e5                	mov    %esp,%ebp
  8006b2:	53                   	push   %ebx
  8006b3:	83 ec 04             	sub    $0x4,%esp
	b->buf[b->idx++] = ch;
  8006b6:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006b9:	8b 00                	mov    (%eax),%eax
  8006bb:	8d 48 01             	lea    0x1(%eax),%ecx
  8006be:	8b 55 0c             	mov    0xc(%ebp),%edx
  8006c1:	89 0a                	mov    %ecx,(%edx)
  8006c3:	8b 55 08             	mov    0x8(%ebp),%edx
  8006c6:	88 d1                	mov    %dl,%cl
  8006c8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8006cb:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
	if (b->idx == 256 - 1) {
  8006cf:	8b 45 0c             	mov    0xc(%ebp),%eax
  8006d2:	8b 00                	mov    (%eax),%eax
  8006d4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8006d9:	75 30                	jne    80070b <putch+0x5c>
		sys_cputs(b->buf, b->idx, printProgName, curTextClr);
  8006db:	8b 15 18 b1 81 00    	mov    0x81b118,%edx
  8006e1:	a0 44 30 80 00       	mov    0x803044,%al
  8006e6:	0f b6 c0             	movzbl %al,%eax
  8006e9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8006ec:	8b 09                	mov    (%ecx),%ecx
  8006ee:	89 cb                	mov    %ecx,%ebx
  8006f0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8006f3:	83 c1 08             	add    $0x8,%ecx
  8006f6:	52                   	push   %edx
  8006f7:	50                   	push   %eax
  8006f8:	53                   	push   %ebx
  8006f9:	51                   	push   %ecx
  8006fa:	e8 57 11 00 00       	call   801856 <sys_cputs>
  8006ff:	83 c4 10             	add    $0x10,%esp
		b->idx = 0;
  800702:	8b 45 0c             	mov    0xc(%ebp),%eax
  800705:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  80070b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80070e:	8b 40 04             	mov    0x4(%eax),%eax
  800711:	8d 50 01             	lea    0x1(%eax),%edx
  800714:	8b 45 0c             	mov    0xc(%ebp),%eax
  800717:	89 50 04             	mov    %edx,0x4(%eax)
}
  80071a:	90                   	nop
  80071b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  80071e:	c9                   	leave  
  80071f:	c3                   	ret    

00800720 <vcprintf>:

int vcprintf(const char *fmt, va_list ap) {
  800720:	55                   	push   %ebp
  800721:	89 e5                	mov    %esp,%ebp
  800723:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  800729:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800730:	00 00 00 
	b.cnt = 0;
  800733:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80073a:	00 00 00 
	vprintfmt((void*) putch, &b, fmt, ap);
  80073d:	ff 75 0c             	pushl  0xc(%ebp)
  800740:	ff 75 08             	pushl  0x8(%ebp)
  800743:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800749:	50                   	push   %eax
  80074a:	68 af 06 80 00       	push   $0x8006af
  80074f:	e8 5a 02 00 00       	call   8009ae <vprintfmt>
  800754:	83 c4 10             	add    $0x10,%esp
	sys_cputs(b.buf, b.idx, printProgName, curTextClr);
  800757:	8b 15 18 b1 81 00    	mov    0x81b118,%edx
  80075d:	a0 44 30 80 00       	mov    0x803044,%al
  800762:	0f b6 c0             	movzbl %al,%eax
  800765:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
  80076b:	52                   	push   %edx
  80076c:	50                   	push   %eax
  80076d:	51                   	push   %ecx
  80076e:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800774:	83 c0 08             	add    $0x8,%eax
  800777:	50                   	push   %eax
  800778:	e8 d9 10 00 00       	call   801856 <sys_cputs>
  80077d:	83 c4 10             	add    $0x10,%esp

	printProgName = 0;
  800780:	c6 05 44 30 80 00 00 	movb   $0x0,0x803044
	return b.cnt;
  800787:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  80078d:	c9                   	leave  
  80078e:	c3                   	ret    

0080078f <cprintf>:

//%@: to print the program name and ID before the message
//%~: to print the message directly
int cprintf(const char *fmt, ...) {
  80078f:	55                   	push   %ebp
  800790:	89 e5                	mov    %esp,%ebp
  800792:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;
	printProgName = 1 ;
  800795:	c6 05 44 30 80 00 01 	movb   $0x1,0x803044
	va_start(ap, fmt);
  80079c:	8d 45 0c             	lea    0xc(%ebp),%eax
  80079f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
  8007a2:	8b 45 08             	mov    0x8(%ebp),%eax
  8007a5:	83 ec 08             	sub    $0x8,%esp
  8007a8:	ff 75 f4             	pushl  -0xc(%ebp)
  8007ab:	50                   	push   %eax
  8007ac:	e8 6f ff ff ff       	call   800720 <vcprintf>
  8007b1:	83 c4 10             	add    $0x10,%esp
  8007b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
  8007b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  8007ba:	c9                   	leave  
  8007bb:	c3                   	ret    

008007bc <cprintf_colored>:

// *************** This text coloring feature is implemented by *************
// ********** Abd-Alrahman Zedan From Team Frozen-Bytes - FCIS'24-25 ********
int cprintf_colored(int textClr, const char *fmt, ...) {
  8007bc:	55                   	push   %ebp
  8007bd:	89 e5                	mov    %esp,%ebp
  8007bf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;
	printProgName = 1 ;
  8007c2:	c6 05 44 30 80 00 01 	movb   $0x1,0x803044
	curTextClr = (textClr << 8) ; //set text color by the given value
  8007c9:	8b 45 08             	mov    0x8(%ebp),%eax
  8007cc:	c1 e0 08             	shl    $0x8,%eax
  8007cf:	a3 18 b1 81 00       	mov    %eax,0x81b118
	va_start(ap, fmt);
  8007d4:	8d 45 0c             	lea    0xc(%ebp),%eax
  8007d7:	83 c0 04             	add    $0x4,%eax
  8007da:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
  8007dd:	8b 45 0c             	mov    0xc(%ebp),%eax
  8007e0:	83 ec 08             	sub    $0x8,%esp
  8007e3:	ff 75 f4             	pushl  -0xc(%ebp)
  8007e6:	50                   	push   %eax
  8007e7:	e8 34 ff ff ff       	call   800720 <vcprintf>
  8007ec:	83 c4 10             	add    $0x10,%esp
  8007ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);
	curTextClr = TEXT_DEFAULT_CLR; //restore default color
  8007f2:	c7 05 18 b1 81 00 00 	movl   $0x700,0x81b118
  8007f9:	07 00 00 

	return cnt;
  8007fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  8007ff:	c9                   	leave  
  800800:	c3                   	ret    

00800801 <atomic_cprintf>:

//%@: to print the program name and ID before the message
//%~: to print the message directly
int atomic_cprintf(const char *fmt, ...)
{
  800801:	55                   	push   %ebp
  800802:	89 e5                	mov    %esp,%ebp
  800804:	83 ec 18             	sub    $0x18,%esp
	int cnt;
	sys_lock_cons();
  800807:	e8 8e 10 00 00       	call   80189a <sys_lock_cons>
	{
		va_list ap;
		va_start(ap, fmt);
  80080c:	8d 45 0c             	lea    0xc(%ebp),%eax
  80080f:	89 45 f4             	mov    %eax,-0xc(%ebp)
		cnt = vcprintf(fmt, ap);
  800812:	8b 45 08             	mov    0x8(%ebp),%eax
  800815:	83 ec 08             	sub    $0x8,%esp
  800818:	ff 75 f4             	pushl  -0xc(%ebp)
  80081b:	50                   	push   %eax
  80081c:	e8 ff fe ff ff       	call   800720 <vcprintf>
  800821:	83 c4 10             	add    $0x10,%esp
  800824:	89 45 f0             	mov    %eax,-0x10(%ebp)
		va_end(ap);
	}
	sys_unlock_cons();
  800827:	e8 88 10 00 00       	call   8018b4 <sys_unlock_cons>
	return cnt;
  80082c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  80082f:	c9                   	leave  
  800830:	c3                   	ret    

00800831 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800831:	55                   	push   %ebp
  800832:	89 e5                	mov    %esp,%ebp
  800834:	53                   	push   %ebx
  800835:	83 ec 14             	sub    $0x14,%esp
  800838:	8b 45 10             	mov    0x10(%ebp),%eax
  80083b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  80083e:	8b 45 14             	mov    0x14(%ebp),%eax
  800841:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800844:	8b 45 18             	mov    0x18(%ebp),%eax
  800847:	ba 00 00 00 00       	mov    $0x0,%edx
  80084c:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  80084f:	77 55                	ja     8008a6 <printnum+0x75>
  800851:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  800854:	72 05                	jb     80085b <printnum+0x2a>
  800856:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  800859:	77 4b                	ja     8008a6 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80085b:	8b 45 1c             	mov    0x1c(%ebp),%eax
  80085e:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800861:	8b 45 18             	mov    0x18(%ebp),%eax
  800864:	ba 00 00 00 00       	mov    $0x0,%edx
  800869:	52                   	push   %edx
  80086a:	50                   	push   %eax
  80086b:	ff 75 f4             	pushl  -0xc(%ebp)
  80086e:	ff 75 f0             	pushl  -0x10(%ebp)
  800871:	e8 82 19 00 00       	call   8021f8 <__udivdi3>
  800876:	83 c4 10             	add    $0x10,%esp
  800879:	83 ec 04             	sub    $0x4,%esp
  80087c:	ff 75 20             	pushl  0x20(%ebp)
  80087f:	53                   	push   %ebx
  800880:	ff 75 18             	pushl  0x18(%ebp)
  800883:	52                   	push   %edx
  800884:	50                   	push   %eax
  800885:	ff 75 0c             	pushl  0xc(%ebp)
  800888:	ff 75 08             	pushl  0x8(%ebp)
  80088b:	e8 a1 ff ff ff       	call   800831 <printnum>
  800890:	83 c4 20             	add    $0x20,%esp
  800893:	eb 1a                	jmp    8008af <printnum+0x7e>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800895:	83 ec 08             	sub    $0x8,%esp
  800898:	ff 75 0c             	pushl  0xc(%ebp)
  80089b:	ff 75 20             	pushl  0x20(%ebp)
  80089e:	8b 45 08             	mov    0x8(%ebp),%eax
  8008a1:	ff d0                	call   *%eax
  8008a3:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8008a6:	ff 4d 1c             	decl   0x1c(%ebp)
  8008a9:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
  8008ad:	7f e6                	jg     800895 <printnum+0x64>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8008af:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8008b2:	bb 00 00 00 00       	mov    $0x0,%ebx
  8008b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8008ba:	8b 55 f4             	mov    -0xc(%ebp),%edx
  8008bd:	53                   	push   %ebx
  8008be:	51                   	push   %ecx
  8008bf:	52                   	push   %edx
  8008c0:	50                   	push   %eax
  8008c1:	e8 42 1a 00 00       	call   802308 <__umoddi3>
  8008c6:	83 c4 10             	add    $0x10,%esp
  8008c9:	05 94 28 80 00       	add    $0x802894,%eax
  8008ce:	8a 00                	mov    (%eax),%al
  8008d0:	0f be c0             	movsbl %al,%eax
  8008d3:	83 ec 08             	sub    $0x8,%esp
  8008d6:	ff 75 0c             	pushl  0xc(%ebp)
  8008d9:	50                   	push   %eax
  8008da:	8b 45 08             	mov    0x8(%ebp),%eax
  8008dd:	ff d0                	call   *%eax
  8008df:	83 c4 10             	add    $0x10,%esp
}
  8008e2:	90                   	nop
  8008e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8008e6:	c9                   	leave  
  8008e7:	c3                   	ret    

008008e8 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8008e8:	55                   	push   %ebp
  8008e9:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8008eb:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  8008ef:	7e 1c                	jle    80090d <getuint+0x25>
		return va_arg(*ap, unsigned long long);
  8008f1:	8b 45 08             	mov    0x8(%ebp),%eax
  8008f4:	8b 00                	mov    (%eax),%eax
  8008f6:	8d 50 08             	lea    0x8(%eax),%edx
  8008f9:	8b 45 08             	mov    0x8(%ebp),%eax
  8008fc:	89 10                	mov    %edx,(%eax)
  8008fe:	8b 45 08             	mov    0x8(%ebp),%eax
  800901:	8b 00                	mov    (%eax),%eax
  800903:	83 e8 08             	sub    $0x8,%eax
  800906:	8b 50 04             	mov    0x4(%eax),%edx
  800909:	8b 00                	mov    (%eax),%eax
  80090b:	eb 40                	jmp    80094d <getuint+0x65>
	else if (lflag)
  80090d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800911:	74 1e                	je     800931 <getuint+0x49>
		return va_arg(*ap, unsigned long);
  800913:	8b 45 08             	mov    0x8(%ebp),%eax
  800916:	8b 00                	mov    (%eax),%eax
  800918:	8d 50 04             	lea    0x4(%eax),%edx
  80091b:	8b 45 08             	mov    0x8(%ebp),%eax
  80091e:	89 10                	mov    %edx,(%eax)
  800920:	8b 45 08             	mov    0x8(%ebp),%eax
  800923:	8b 00                	mov    (%eax),%eax
  800925:	83 e8 04             	sub    $0x4,%eax
  800928:	8b 00                	mov    (%eax),%eax
  80092a:	ba 00 00 00 00       	mov    $0x0,%edx
  80092f:	eb 1c                	jmp    80094d <getuint+0x65>
	else
		return va_arg(*ap, unsigned int);
  800931:	8b 45 08             	mov    0x8(%ebp),%eax
  800934:	8b 00                	mov    (%eax),%eax
  800936:	8d 50 04             	lea    0x4(%eax),%edx
  800939:	8b 45 08             	mov    0x8(%ebp),%eax
  80093c:	89 10                	mov    %edx,(%eax)
  80093e:	8b 45 08             	mov    0x8(%ebp),%eax
  800941:	8b 00                	mov    (%eax),%eax
  800943:	83 e8 04             	sub    $0x4,%eax
  800946:	8b 00                	mov    (%eax),%eax
  800948:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80094d:	5d                   	pop    %ebp
  80094e:	c3                   	ret    

0080094f <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  80094f:	55                   	push   %ebp
  800950:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800952:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  800956:	7e 1c                	jle    800974 <getint+0x25>
		return va_arg(*ap, long long);
  800958:	8b 45 08             	mov    0x8(%ebp),%eax
  80095b:	8b 00                	mov    (%eax),%eax
  80095d:	8d 50 08             	lea    0x8(%eax),%edx
  800960:	8b 45 08             	mov    0x8(%ebp),%eax
  800963:	89 10                	mov    %edx,(%eax)
  800965:	8b 45 08             	mov    0x8(%ebp),%eax
  800968:	8b 00                	mov    (%eax),%eax
  80096a:	83 e8 08             	sub    $0x8,%eax
  80096d:	8b 50 04             	mov    0x4(%eax),%edx
  800970:	8b 00                	mov    (%eax),%eax
  800972:	eb 38                	jmp    8009ac <getint+0x5d>
	else if (lflag)
  800974:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800978:	74 1a                	je     800994 <getint+0x45>
		return va_arg(*ap, long);
  80097a:	8b 45 08             	mov    0x8(%ebp),%eax
  80097d:	8b 00                	mov    (%eax),%eax
  80097f:	8d 50 04             	lea    0x4(%eax),%edx
  800982:	8b 45 08             	mov    0x8(%ebp),%eax
  800985:	89 10                	mov    %edx,(%eax)
  800987:	8b 45 08             	mov    0x8(%ebp),%eax
  80098a:	8b 00                	mov    (%eax),%eax
  80098c:	83 e8 04             	sub    $0x4,%eax
  80098f:	8b 00                	mov    (%eax),%eax
  800991:	99                   	cltd   
  800992:	eb 18                	jmp    8009ac <getint+0x5d>
	else
		return va_arg(*ap, int);
  800994:	8b 45 08             	mov    0x8(%ebp),%eax
  800997:	8b 00                	mov    (%eax),%eax
  800999:	8d 50 04             	lea    0x4(%eax),%edx
  80099c:	8b 45 08             	mov    0x8(%ebp),%eax
  80099f:	89 10                	mov    %edx,(%eax)
  8009a1:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a4:	8b 00                	mov    (%eax),%eax
  8009a6:	83 e8 04             	sub    $0x4,%eax
  8009a9:	8b 00                	mov    (%eax),%eax
  8009ab:	99                   	cltd   
}
  8009ac:	5d                   	pop    %ebp
  8009ad:	c3                   	ret    

008009ae <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8009ae:	55                   	push   %ebp
  8009af:	89 e5                	mov    %esp,%ebp
  8009b1:	56                   	push   %esi
  8009b2:	53                   	push   %ebx
  8009b3:	83 ec 20             	sub    $0x20,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8009b6:	eb 17                	jmp    8009cf <vprintfmt+0x21>
			if (ch == '\0')
  8009b8:	85 db                	test   %ebx,%ebx
  8009ba:	0f 84 c1 03 00 00    	je     800d81 <vprintfmt+0x3d3>
				return;
			putch(ch, putdat);
  8009c0:	83 ec 08             	sub    $0x8,%esp
  8009c3:	ff 75 0c             	pushl  0xc(%ebp)
  8009c6:	53                   	push   %ebx
  8009c7:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ca:	ff d0                	call   *%eax
  8009cc:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8009cf:	8b 45 10             	mov    0x10(%ebp),%eax
  8009d2:	8d 50 01             	lea    0x1(%eax),%edx
  8009d5:	89 55 10             	mov    %edx,0x10(%ebp)
  8009d8:	8a 00                	mov    (%eax),%al
  8009da:	0f b6 d8             	movzbl %al,%ebx
  8009dd:	83 fb 25             	cmp    $0x25,%ebx
  8009e0:	75 d6                	jne    8009b8 <vprintfmt+0xa>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
  8009e2:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
		width = -1;
  8009e6:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
		precision = -1;
  8009ed:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
  8009f4:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
		altflag = 0;
  8009fb:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800a02:	8b 45 10             	mov    0x10(%ebp),%eax
  800a05:	8d 50 01             	lea    0x1(%eax),%edx
  800a08:	89 55 10             	mov    %edx,0x10(%ebp)
  800a0b:	8a 00                	mov    (%eax),%al
  800a0d:	0f b6 d8             	movzbl %al,%ebx
  800a10:	8d 43 dd             	lea    -0x23(%ebx),%eax
  800a13:	83 f8 5b             	cmp    $0x5b,%eax
  800a16:	0f 87 3d 03 00 00    	ja     800d59 <vprintfmt+0x3ab>
  800a1c:	8b 04 85 b8 28 80 00 	mov    0x8028b8(,%eax,4),%eax
  800a23:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
  800a25:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
			goto reswitch;
  800a29:	eb d7                	jmp    800a02 <vprintfmt+0x54>

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800a2b:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
			goto reswitch;
  800a2f:	eb d1                	jmp    800a02 <vprintfmt+0x54>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800a31:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
				precision = precision * 10 + ch - '0';
  800a38:	8b 55 e0             	mov    -0x20(%ebp),%edx
  800a3b:	89 d0                	mov    %edx,%eax
  800a3d:	c1 e0 02             	shl    $0x2,%eax
  800a40:	01 d0                	add    %edx,%eax
  800a42:	01 c0                	add    %eax,%eax
  800a44:	01 d8                	add    %ebx,%eax
  800a46:	83 e8 30             	sub    $0x30,%eax
  800a49:	89 45 e0             	mov    %eax,-0x20(%ebp)
				ch = *fmt;
  800a4c:	8b 45 10             	mov    0x10(%ebp),%eax
  800a4f:	8a 00                	mov    (%eax),%al
  800a51:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  800a54:	83 fb 2f             	cmp    $0x2f,%ebx
  800a57:	7e 3e                	jle    800a97 <vprintfmt+0xe9>
  800a59:	83 fb 39             	cmp    $0x39,%ebx
  800a5c:	7f 39                	jg     800a97 <vprintfmt+0xe9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800a5e:	ff 45 10             	incl   0x10(%ebp)
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800a61:	eb d5                	jmp    800a38 <vprintfmt+0x8a>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800a63:	8b 45 14             	mov    0x14(%ebp),%eax
  800a66:	83 c0 04             	add    $0x4,%eax
  800a69:	89 45 14             	mov    %eax,0x14(%ebp)
  800a6c:	8b 45 14             	mov    0x14(%ebp),%eax
  800a6f:	83 e8 04             	sub    $0x4,%eax
  800a72:	8b 00                	mov    (%eax),%eax
  800a74:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto process_precision;
  800a77:	eb 1f                	jmp    800a98 <vprintfmt+0xea>

		case '.':
			if (width < 0)
  800a79:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800a7d:	79 83                	jns    800a02 <vprintfmt+0x54>
				width = 0;
  800a7f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			goto reswitch;
  800a86:	e9 77 ff ff ff       	jmp    800a02 <vprintfmt+0x54>

		case '#':
			altflag = 1;
  800a8b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
  800a92:	e9 6b ff ff ff       	jmp    800a02 <vprintfmt+0x54>
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto process_precision;
  800a97:	90                   	nop
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
  800a98:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800a9c:	0f 89 60 ff ff ff    	jns    800a02 <vprintfmt+0x54>
				width = precision, precision = -1;
  800aa2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800aa5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800aa8:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
			goto reswitch;
  800aaf:	e9 4e ff ff ff       	jmp    800a02 <vprintfmt+0x54>

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800ab4:	ff 45 e8             	incl   -0x18(%ebp)
			goto reswitch;
  800ab7:	e9 46 ff ff ff       	jmp    800a02 <vprintfmt+0x54>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800abc:	8b 45 14             	mov    0x14(%ebp),%eax
  800abf:	83 c0 04             	add    $0x4,%eax
  800ac2:	89 45 14             	mov    %eax,0x14(%ebp)
  800ac5:	8b 45 14             	mov    0x14(%ebp),%eax
  800ac8:	83 e8 04             	sub    $0x4,%eax
  800acb:	8b 00                	mov    (%eax),%eax
  800acd:	83 ec 08             	sub    $0x8,%esp
  800ad0:	ff 75 0c             	pushl  0xc(%ebp)
  800ad3:	50                   	push   %eax
  800ad4:	8b 45 08             	mov    0x8(%ebp),%eax
  800ad7:	ff d0                	call   *%eax
  800ad9:	83 c4 10             	add    $0x10,%esp
			break;
  800adc:	e9 9b 02 00 00       	jmp    800d7c <vprintfmt+0x3ce>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800ae1:	8b 45 14             	mov    0x14(%ebp),%eax
  800ae4:	83 c0 04             	add    $0x4,%eax
  800ae7:	89 45 14             	mov    %eax,0x14(%ebp)
  800aea:	8b 45 14             	mov    0x14(%ebp),%eax
  800aed:	83 e8 04             	sub    $0x4,%eax
  800af0:	8b 18                	mov    (%eax),%ebx
			if (err < 0)
  800af2:	85 db                	test   %ebx,%ebx
  800af4:	79 02                	jns    800af8 <vprintfmt+0x14a>
				err = -err;
  800af6:	f7 db                	neg    %ebx
			if (err > MAXERROR || (p = error_string[err]) == NULL)
  800af8:	83 fb 64             	cmp    $0x64,%ebx
  800afb:	7f 0b                	jg     800b08 <vprintfmt+0x15a>
  800afd:	8b 34 9d 00 27 80 00 	mov    0x802700(,%ebx,4),%esi
  800b04:	85 f6                	test   %esi,%esi
  800b06:	75 19                	jne    800b21 <vprintfmt+0x173>
				printfmt(putch, putdat, "error %d", err);
  800b08:	53                   	push   %ebx
  800b09:	68 a5 28 80 00       	push   $0x8028a5
  800b0e:	ff 75 0c             	pushl  0xc(%ebp)
  800b11:	ff 75 08             	pushl  0x8(%ebp)
  800b14:	e8 70 02 00 00       	call   800d89 <printfmt>
  800b19:	83 c4 10             	add    $0x10,%esp
			else
				printfmt(putch, putdat, "%s", p);
			break;
  800b1c:	e9 5b 02 00 00       	jmp    800d7c <vprintfmt+0x3ce>
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
  800b21:	56                   	push   %esi
  800b22:	68 ae 28 80 00       	push   $0x8028ae
  800b27:	ff 75 0c             	pushl  0xc(%ebp)
  800b2a:	ff 75 08             	pushl  0x8(%ebp)
  800b2d:	e8 57 02 00 00       	call   800d89 <printfmt>
  800b32:	83 c4 10             	add    $0x10,%esp
			break;
  800b35:	e9 42 02 00 00       	jmp    800d7c <vprintfmt+0x3ce>

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800b3a:	8b 45 14             	mov    0x14(%ebp),%eax
  800b3d:	83 c0 04             	add    $0x4,%eax
  800b40:	89 45 14             	mov    %eax,0x14(%ebp)
  800b43:	8b 45 14             	mov    0x14(%ebp),%eax
  800b46:	83 e8 04             	sub    $0x4,%eax
  800b49:	8b 30                	mov    (%eax),%esi
  800b4b:	85 f6                	test   %esi,%esi
  800b4d:	75 05                	jne    800b54 <vprintfmt+0x1a6>
				p = "(null)";
  800b4f:	be b1 28 80 00       	mov    $0x8028b1,%esi
			if (width > 0 && padc != '-')
  800b54:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800b58:	7e 6d                	jle    800bc7 <vprintfmt+0x219>
  800b5a:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
  800b5e:	74 67                	je     800bc7 <vprintfmt+0x219>
				for (width -= strnlen(p, precision); width > 0; width--)
  800b60:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800b63:	83 ec 08             	sub    $0x8,%esp
  800b66:	50                   	push   %eax
  800b67:	56                   	push   %esi
  800b68:	e8 1e 03 00 00       	call   800e8b <strnlen>
  800b6d:	83 c4 10             	add    $0x10,%esp
  800b70:	29 45 e4             	sub    %eax,-0x1c(%ebp)
  800b73:	eb 16                	jmp    800b8b <vprintfmt+0x1dd>
					putch(padc, putdat);
  800b75:	0f be 45 db          	movsbl -0x25(%ebp),%eax
  800b79:	83 ec 08             	sub    $0x8,%esp
  800b7c:	ff 75 0c             	pushl  0xc(%ebp)
  800b7f:	50                   	push   %eax
  800b80:	8b 45 08             	mov    0x8(%ebp),%eax
  800b83:	ff d0                	call   *%eax
  800b85:	83 c4 10             	add    $0x10,%esp
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800b88:	ff 4d e4             	decl   -0x1c(%ebp)
  800b8b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800b8f:	7f e4                	jg     800b75 <vprintfmt+0x1c7>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800b91:	eb 34                	jmp    800bc7 <vprintfmt+0x219>
				if (altflag && (ch < ' ' || ch > '~'))
  800b93:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800b97:	74 1c                	je     800bb5 <vprintfmt+0x207>
  800b99:	83 fb 1f             	cmp    $0x1f,%ebx
  800b9c:	7e 05                	jle    800ba3 <vprintfmt+0x1f5>
  800b9e:	83 fb 7e             	cmp    $0x7e,%ebx
  800ba1:	7e 12                	jle    800bb5 <vprintfmt+0x207>
					putch('?', putdat);
  800ba3:	83 ec 08             	sub    $0x8,%esp
  800ba6:	ff 75 0c             	pushl  0xc(%ebp)
  800ba9:	6a 3f                	push   $0x3f
  800bab:	8b 45 08             	mov    0x8(%ebp),%eax
  800bae:	ff d0                	call   *%eax
  800bb0:	83 c4 10             	add    $0x10,%esp
  800bb3:	eb 0f                	jmp    800bc4 <vprintfmt+0x216>
				else
					putch(ch, putdat);
  800bb5:	83 ec 08             	sub    $0x8,%esp
  800bb8:	ff 75 0c             	pushl  0xc(%ebp)
  800bbb:	53                   	push   %ebx
  800bbc:	8b 45 08             	mov    0x8(%ebp),%eax
  800bbf:	ff d0                	call   *%eax
  800bc1:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800bc4:	ff 4d e4             	decl   -0x1c(%ebp)
  800bc7:	89 f0                	mov    %esi,%eax
  800bc9:	8d 70 01             	lea    0x1(%eax),%esi
  800bcc:	8a 00                	mov    (%eax),%al
  800bce:	0f be d8             	movsbl %al,%ebx
  800bd1:	85 db                	test   %ebx,%ebx
  800bd3:	74 24                	je     800bf9 <vprintfmt+0x24b>
  800bd5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800bd9:	78 b8                	js     800b93 <vprintfmt+0x1e5>
  800bdb:	ff 4d e0             	decl   -0x20(%ebp)
  800bde:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800be2:	79 af                	jns    800b93 <vprintfmt+0x1e5>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800be4:	eb 13                	jmp    800bf9 <vprintfmt+0x24b>
				putch(' ', putdat);
  800be6:	83 ec 08             	sub    $0x8,%esp
  800be9:	ff 75 0c             	pushl  0xc(%ebp)
  800bec:	6a 20                	push   $0x20
  800bee:	8b 45 08             	mov    0x8(%ebp),%eax
  800bf1:	ff d0                	call   *%eax
  800bf3:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800bf6:	ff 4d e4             	decl   -0x1c(%ebp)
  800bf9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800bfd:	7f e7                	jg     800be6 <vprintfmt+0x238>
				putch(' ', putdat);
			break;
  800bff:	e9 78 01 00 00       	jmp    800d7c <vprintfmt+0x3ce>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800c04:	83 ec 08             	sub    $0x8,%esp
  800c07:	ff 75 e8             	pushl  -0x18(%ebp)
  800c0a:	8d 45 14             	lea    0x14(%ebp),%eax
  800c0d:	50                   	push   %eax
  800c0e:	e8 3c fd ff ff       	call   80094f <getint>
  800c13:	83 c4 10             	add    $0x10,%esp
  800c16:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800c19:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((long long) num < 0) {
  800c1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800c1f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  800c22:	85 d2                	test   %edx,%edx
  800c24:	79 23                	jns    800c49 <vprintfmt+0x29b>
				putch('-', putdat);
  800c26:	83 ec 08             	sub    $0x8,%esp
  800c29:	ff 75 0c             	pushl  0xc(%ebp)
  800c2c:	6a 2d                	push   $0x2d
  800c2e:	8b 45 08             	mov    0x8(%ebp),%eax
  800c31:	ff d0                	call   *%eax
  800c33:	83 c4 10             	add    $0x10,%esp
				num = -(long long) num;
  800c36:	8b 45 f0             	mov    -0x10(%ebp),%eax
  800c39:	8b 55 f4             	mov    -0xc(%ebp),%edx
  800c3c:	f7 d8                	neg    %eax
  800c3e:	83 d2 00             	adc    $0x0,%edx
  800c41:	f7 da                	neg    %edx
  800c43:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800c46:	89 55 f4             	mov    %edx,-0xc(%ebp)
			}
			base = 10;
  800c49:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
  800c50:	e9 bc 00 00 00       	jmp    800d11 <vprintfmt+0x363>

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800c55:	83 ec 08             	sub    $0x8,%esp
  800c58:	ff 75 e8             	pushl  -0x18(%ebp)
  800c5b:	8d 45 14             	lea    0x14(%ebp),%eax
  800c5e:	50                   	push   %eax
  800c5f:	e8 84 fc ff ff       	call   8008e8 <getuint>
  800c64:	83 c4 10             	add    $0x10,%esp
  800c67:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800c6a:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 10;
  800c6d:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
			goto number;
  800c74:	e9 98 00 00 00       	jmp    800d11 <vprintfmt+0x363>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
  800c79:	83 ec 08             	sub    $0x8,%esp
  800c7c:	ff 75 0c             	pushl  0xc(%ebp)
  800c7f:	6a 58                	push   $0x58
  800c81:	8b 45 08             	mov    0x8(%ebp),%eax
  800c84:	ff d0                	call   *%eax
  800c86:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
  800c89:	83 ec 08             	sub    $0x8,%esp
  800c8c:	ff 75 0c             	pushl  0xc(%ebp)
  800c8f:	6a 58                	push   $0x58
  800c91:	8b 45 08             	mov    0x8(%ebp),%eax
  800c94:	ff d0                	call   *%eax
  800c96:	83 c4 10             	add    $0x10,%esp
			putch('X', putdat);
  800c99:	83 ec 08             	sub    $0x8,%esp
  800c9c:	ff 75 0c             	pushl  0xc(%ebp)
  800c9f:	6a 58                	push   $0x58
  800ca1:	8b 45 08             	mov    0x8(%ebp),%eax
  800ca4:	ff d0                	call   *%eax
  800ca6:	83 c4 10             	add    $0x10,%esp
			break;
  800ca9:	e9 ce 00 00 00       	jmp    800d7c <vprintfmt+0x3ce>

		// pointer
		case 'p':
			putch('0', putdat);
  800cae:	83 ec 08             	sub    $0x8,%esp
  800cb1:	ff 75 0c             	pushl  0xc(%ebp)
  800cb4:	6a 30                	push   $0x30
  800cb6:	8b 45 08             	mov    0x8(%ebp),%eax
  800cb9:	ff d0                	call   *%eax
  800cbb:	83 c4 10             	add    $0x10,%esp
			putch('x', putdat);
  800cbe:	83 ec 08             	sub    $0x8,%esp
  800cc1:	ff 75 0c             	pushl  0xc(%ebp)
  800cc4:	6a 78                	push   $0x78
  800cc6:	8b 45 08             	mov    0x8(%ebp),%eax
  800cc9:	ff d0                	call   *%eax
  800ccb:	83 c4 10             	add    $0x10,%esp
			num = (unsigned long long)
				(uint32) va_arg(ap, void *);
  800cce:	8b 45 14             	mov    0x14(%ebp),%eax
  800cd1:	83 c0 04             	add    $0x4,%eax
  800cd4:	89 45 14             	mov    %eax,0x14(%ebp)
  800cd7:	8b 45 14             	mov    0x14(%ebp),%eax
  800cda:	83 e8 04             	sub    $0x4,%eax
  800cdd:	8b 00                	mov    (%eax),%eax

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800cdf:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800ce2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
				(uint32) va_arg(ap, void *);
			base = 16;
  800ce9:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
			goto number;
  800cf0:	eb 1f                	jmp    800d11 <vprintfmt+0x363>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800cf2:	83 ec 08             	sub    $0x8,%esp
  800cf5:	ff 75 e8             	pushl  -0x18(%ebp)
  800cf8:	8d 45 14             	lea    0x14(%ebp),%eax
  800cfb:	50                   	push   %eax
  800cfc:	e8 e7 fb ff ff       	call   8008e8 <getuint>
  800d01:	83 c4 10             	add    $0x10,%esp
  800d04:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800d07:	89 55 f4             	mov    %edx,-0xc(%ebp)
			base = 16;
  800d0a:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
  800d11:	0f be 55 db          	movsbl -0x25(%ebp),%edx
  800d15:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800d18:	83 ec 04             	sub    $0x4,%esp
  800d1b:	52                   	push   %edx
  800d1c:	ff 75 e4             	pushl  -0x1c(%ebp)
  800d1f:	50                   	push   %eax
  800d20:	ff 75 f4             	pushl  -0xc(%ebp)
  800d23:	ff 75 f0             	pushl  -0x10(%ebp)
  800d26:	ff 75 0c             	pushl  0xc(%ebp)
  800d29:	ff 75 08             	pushl  0x8(%ebp)
  800d2c:	e8 00 fb ff ff       	call   800831 <printnum>
  800d31:	83 c4 20             	add    $0x20,%esp
			break;
  800d34:	eb 46                	jmp    800d7c <vprintfmt+0x3ce>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800d36:	83 ec 08             	sub    $0x8,%esp
  800d39:	ff 75 0c             	pushl  0xc(%ebp)
  800d3c:	53                   	push   %ebx
  800d3d:	8b 45 08             	mov    0x8(%ebp),%eax
  800d40:	ff d0                	call   *%eax
  800d42:	83 c4 10             	add    $0x10,%esp
			break;
  800d45:	eb 35                	jmp    800d7c <vprintfmt+0x3ce>

		/**********************************/
		/*2023*/
		// DON'T Print Program Name & UD
		case '~':
			printProgName = 0;
  800d47:	c6 05 44 30 80 00 00 	movb   $0x0,0x803044
			break;
  800d4e:	eb 2c                	jmp    800d7c <vprintfmt+0x3ce>
		// Print Program Name & UD
		case '@':
			printProgName = 1;
  800d50:	c6 05 44 30 80 00 01 	movb   $0x1,0x803044
			break;
  800d57:	eb 23                	jmp    800d7c <vprintfmt+0x3ce>
		/**********************************/

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  800d59:	83 ec 08             	sub    $0x8,%esp
  800d5c:	ff 75 0c             	pushl  0xc(%ebp)
  800d5f:	6a 25                	push   $0x25
  800d61:	8b 45 08             	mov    0x8(%ebp),%eax
  800d64:	ff d0                	call   *%eax
  800d66:	83 c4 10             	add    $0x10,%esp
			for (fmt--; fmt[-1] != '%'; fmt--)
  800d69:	ff 4d 10             	decl   0x10(%ebp)
  800d6c:	eb 03                	jmp    800d71 <vprintfmt+0x3c3>
  800d6e:	ff 4d 10             	decl   0x10(%ebp)
  800d71:	8b 45 10             	mov    0x10(%ebp),%eax
  800d74:	48                   	dec    %eax
  800d75:	8a 00                	mov    (%eax),%al
  800d77:	3c 25                	cmp    $0x25,%al
  800d79:	75 f3                	jne    800d6e <vprintfmt+0x3c0>
				/* do nothing */;
			break;
  800d7b:	90                   	nop
		}
	}
  800d7c:	e9 35 fc ff ff       	jmp    8009b6 <vprintfmt+0x8>
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
  800d81:	90                   	nop
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  800d82:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800d85:	5b                   	pop    %ebx
  800d86:	5e                   	pop    %esi
  800d87:	5d                   	pop    %ebp
  800d88:	c3                   	ret    

00800d89 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800d89:	55                   	push   %ebp
  800d8a:	89 e5                	mov    %esp,%ebp
  800d8c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  800d8f:	8d 45 10             	lea    0x10(%ebp),%eax
  800d92:	83 c0 04             	add    $0x4,%eax
  800d95:	89 45 f4             	mov    %eax,-0xc(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
  800d98:	8b 45 10             	mov    0x10(%ebp),%eax
  800d9b:	ff 75 f4             	pushl  -0xc(%ebp)
  800d9e:	50                   	push   %eax
  800d9f:	ff 75 0c             	pushl  0xc(%ebp)
  800da2:	ff 75 08             	pushl  0x8(%ebp)
  800da5:	e8 04 fc ff ff       	call   8009ae <vprintfmt>
  800daa:	83 c4 10             	add    $0x10,%esp
	va_end(ap);
}
  800dad:	90                   	nop
  800dae:	c9                   	leave  
  800daf:	c3                   	ret    

00800db0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800db0:	55                   	push   %ebp
  800db1:	89 e5                	mov    %esp,%ebp
	b->cnt++;
  800db3:	8b 45 0c             	mov    0xc(%ebp),%eax
  800db6:	8b 40 08             	mov    0x8(%eax),%eax
  800db9:	8d 50 01             	lea    0x1(%eax),%edx
  800dbc:	8b 45 0c             	mov    0xc(%ebp),%eax
  800dbf:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
  800dc2:	8b 45 0c             	mov    0xc(%ebp),%eax
  800dc5:	8b 10                	mov    (%eax),%edx
  800dc7:	8b 45 0c             	mov    0xc(%ebp),%eax
  800dca:	8b 40 04             	mov    0x4(%eax),%eax
  800dcd:	39 c2                	cmp    %eax,%edx
  800dcf:	73 12                	jae    800de3 <sprintputch+0x33>
		*b->buf++ = ch;
  800dd1:	8b 45 0c             	mov    0xc(%ebp),%eax
  800dd4:	8b 00                	mov    (%eax),%eax
  800dd6:	8d 48 01             	lea    0x1(%eax),%ecx
  800dd9:	8b 55 0c             	mov    0xc(%ebp),%edx
  800ddc:	89 0a                	mov    %ecx,(%edx)
  800dde:	8b 55 08             	mov    0x8(%ebp),%edx
  800de1:	88 10                	mov    %dl,(%eax)
}
  800de3:	90                   	nop
  800de4:	5d                   	pop    %ebp
  800de5:	c3                   	ret    

00800de6 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800de6:	55                   	push   %ebp
  800de7:	89 e5                	mov    %esp,%ebp
  800de9:	83 ec 18             	sub    $0x18,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
  800dec:	8b 45 08             	mov    0x8(%ebp),%eax
  800def:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800df2:	8b 45 0c             	mov    0xc(%ebp),%eax
  800df5:	8d 50 ff             	lea    -0x1(%eax),%edx
  800df8:	8b 45 08             	mov    0x8(%ebp),%eax
  800dfb:	01 d0                	add    %edx,%eax
  800dfd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  800e00:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800e07:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  800e0b:	74 06                	je     800e13 <vsnprintf+0x2d>
  800e0d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800e11:	7f 07                	jg     800e1a <vsnprintf+0x34>
		return -E_INVAL;
  800e13:	b8 03 00 00 00       	mov    $0x3,%eax
  800e18:	eb 20                	jmp    800e3a <vsnprintf+0x54>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800e1a:	ff 75 14             	pushl  0x14(%ebp)
  800e1d:	ff 75 10             	pushl  0x10(%ebp)
  800e20:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800e23:	50                   	push   %eax
  800e24:	68 b0 0d 80 00       	push   $0x800db0
  800e29:	e8 80 fb ff ff       	call   8009ae <vprintfmt>
  800e2e:	83 c4 10             	add    $0x10,%esp

	// null terminate the buffer
	*b.buf = '\0';
  800e31:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800e34:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800e37:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  800e3a:	c9                   	leave  
  800e3b:	c3                   	ret    

00800e3c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800e3c:	55                   	push   %ebp
  800e3d:	89 e5                	mov    %esp,%ebp
  800e3f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800e42:	8d 45 10             	lea    0x10(%ebp),%eax
  800e45:	83 c0 04             	add    $0x4,%eax
  800e48:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
  800e4b:	8b 45 10             	mov    0x10(%ebp),%eax
  800e4e:	ff 75 f4             	pushl  -0xc(%ebp)
  800e51:	50                   	push   %eax
  800e52:	ff 75 0c             	pushl  0xc(%ebp)
  800e55:	ff 75 08             	pushl  0x8(%ebp)
  800e58:	e8 89 ff ff ff       	call   800de6 <vsnprintf>
  800e5d:	83 c4 10             	add    $0x10,%esp
  800e60:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
  800e63:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  800e66:	c9                   	leave  
  800e67:	c3                   	ret    

00800e68 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
  800e68:	55                   	push   %ebp
  800e69:	89 e5                	mov    %esp,%ebp
  800e6b:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  800e6e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  800e75:	eb 06                	jmp    800e7d <strlen+0x15>
		n++;
  800e77:	ff 45 fc             	incl   -0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800e7a:	ff 45 08             	incl   0x8(%ebp)
  800e7d:	8b 45 08             	mov    0x8(%ebp),%eax
  800e80:	8a 00                	mov    (%eax),%al
  800e82:	84 c0                	test   %al,%al
  800e84:	75 f1                	jne    800e77 <strlen+0xf>
		n++;
	return n;
  800e86:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  800e89:	c9                   	leave  
  800e8a:	c3                   	ret    

00800e8b <strnlen>:

int
strnlen(const char *s, uint32 size)
{
  800e8b:	55                   	push   %ebp
  800e8c:	89 e5                	mov    %esp,%ebp
  800e8e:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800e91:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  800e98:	eb 09                	jmp    800ea3 <strnlen+0x18>
		n++;
  800e9a:	ff 45 fc             	incl   -0x4(%ebp)
int
strnlen(const char *s, uint32 size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800e9d:	ff 45 08             	incl   0x8(%ebp)
  800ea0:	ff 4d 0c             	decl   0xc(%ebp)
  800ea3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ea7:	74 09                	je     800eb2 <strnlen+0x27>
  800ea9:	8b 45 08             	mov    0x8(%ebp),%eax
  800eac:	8a 00                	mov    (%eax),%al
  800eae:	84 c0                	test   %al,%al
  800eb0:	75 e8                	jne    800e9a <strnlen+0xf>
		n++;
	return n;
  800eb2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  800eb5:	c9                   	leave  
  800eb6:	c3                   	ret    

00800eb7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800eb7:	55                   	push   %ebp
  800eb8:	89 e5                	mov    %esp,%ebp
  800eba:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  800ebd:	8b 45 08             	mov    0x8(%ebp),%eax
  800ec0:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  800ec3:	90                   	nop
  800ec4:	8b 45 08             	mov    0x8(%ebp),%eax
  800ec7:	8d 50 01             	lea    0x1(%eax),%edx
  800eca:	89 55 08             	mov    %edx,0x8(%ebp)
  800ecd:	8b 55 0c             	mov    0xc(%ebp),%edx
  800ed0:	8d 4a 01             	lea    0x1(%edx),%ecx
  800ed3:	89 4d 0c             	mov    %ecx,0xc(%ebp)
  800ed6:	8a 12                	mov    (%edx),%dl
  800ed8:	88 10                	mov    %dl,(%eax)
  800eda:	8a 00                	mov    (%eax),%al
  800edc:	84 c0                	test   %al,%al
  800ede:	75 e4                	jne    800ec4 <strcpy+0xd>
		/* do nothing */;
	return ret;
  800ee0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  800ee3:	c9                   	leave  
  800ee4:	c3                   	ret    

00800ee5 <strncpy>:

char *
strncpy(char *dst, const char *src, uint32 size) {
  800ee5:	55                   	push   %ebp
  800ee6:	89 e5                	mov    %esp,%ebp
  800ee8:	83 ec 10             	sub    $0x10,%esp
	uint32 i;
	char *ret;

	ret = dst;
  800eeb:	8b 45 08             	mov    0x8(%ebp),%eax
  800eee:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
  800ef1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  800ef8:	eb 1f                	jmp    800f19 <strncpy+0x34>
		*dst++ = *src;
  800efa:	8b 45 08             	mov    0x8(%ebp),%eax
  800efd:	8d 50 01             	lea    0x1(%eax),%edx
  800f00:	89 55 08             	mov    %edx,0x8(%ebp)
  800f03:	8b 55 0c             	mov    0xc(%ebp),%edx
  800f06:	8a 12                	mov    (%edx),%dl
  800f08:	88 10                	mov    %dl,(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  800f0a:	8b 45 0c             	mov    0xc(%ebp),%eax
  800f0d:	8a 00                	mov    (%eax),%al
  800f0f:	84 c0                	test   %al,%al
  800f11:	74 03                	je     800f16 <strncpy+0x31>
			src++;
  800f13:	ff 45 0c             	incl   0xc(%ebp)
strncpy(char *dst, const char *src, uint32 size) {
	uint32 i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800f16:	ff 45 fc             	incl   -0x4(%ebp)
  800f19:	8b 45 fc             	mov    -0x4(%ebp),%eax
  800f1c:	3b 45 10             	cmp    0x10(%ebp),%eax
  800f1f:	72 d9                	jb     800efa <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  800f21:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  800f24:	c9                   	leave  
  800f25:	c3                   	ret    

00800f26 <strlcpy>:

uint32
strlcpy(char *dst, const char *src, uint32 size)
{
  800f26:	55                   	push   %ebp
  800f27:	89 e5                	mov    %esp,%ebp
  800f29:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  800f2c:	8b 45 08             	mov    0x8(%ebp),%eax
  800f2f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  800f32:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  800f36:	74 30                	je     800f68 <strlcpy+0x42>
		while (--size > 0 && *src != '\0')
  800f38:	eb 16                	jmp    800f50 <strlcpy+0x2a>
			*dst++ = *src++;
  800f3a:	8b 45 08             	mov    0x8(%ebp),%eax
  800f3d:	8d 50 01             	lea    0x1(%eax),%edx
  800f40:	89 55 08             	mov    %edx,0x8(%ebp)
  800f43:	8b 55 0c             	mov    0xc(%ebp),%edx
  800f46:	8d 4a 01             	lea    0x1(%edx),%ecx
  800f49:	89 4d 0c             	mov    %ecx,0xc(%ebp)
  800f4c:	8a 12                	mov    (%edx),%dl
  800f4e:	88 10                	mov    %dl,(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800f50:	ff 4d 10             	decl   0x10(%ebp)
  800f53:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  800f57:	74 09                	je     800f62 <strlcpy+0x3c>
  800f59:	8b 45 0c             	mov    0xc(%ebp),%eax
  800f5c:	8a 00                	mov    (%eax),%al
  800f5e:	84 c0                	test   %al,%al
  800f60:	75 d8                	jne    800f3a <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  800f62:	8b 45 08             	mov    0x8(%ebp),%eax
  800f65:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800f68:	8b 55 08             	mov    0x8(%ebp),%edx
  800f6b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  800f6e:	29 c2                	sub    %eax,%edx
  800f70:	89 d0                	mov    %edx,%eax
}
  800f72:	c9                   	leave  
  800f73:	c3                   	ret    

00800f74 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800f74:	55                   	push   %ebp
  800f75:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  800f77:	eb 06                	jmp    800f7f <strcmp+0xb>
		p++, q++;
  800f79:	ff 45 08             	incl   0x8(%ebp)
  800f7c:	ff 45 0c             	incl   0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800f7f:	8b 45 08             	mov    0x8(%ebp),%eax
  800f82:	8a 00                	mov    (%eax),%al
  800f84:	84 c0                	test   %al,%al
  800f86:	74 0e                	je     800f96 <strcmp+0x22>
  800f88:	8b 45 08             	mov    0x8(%ebp),%eax
  800f8b:	8a 10                	mov    (%eax),%dl
  800f8d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800f90:	8a 00                	mov    (%eax),%al
  800f92:	38 c2                	cmp    %al,%dl
  800f94:	74 e3                	je     800f79 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800f96:	8b 45 08             	mov    0x8(%ebp),%eax
  800f99:	8a 00                	mov    (%eax),%al
  800f9b:	0f b6 d0             	movzbl %al,%edx
  800f9e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800fa1:	8a 00                	mov    (%eax),%al
  800fa3:	0f b6 c0             	movzbl %al,%eax
  800fa6:	29 c2                	sub    %eax,%edx
  800fa8:	89 d0                	mov    %edx,%eax
}
  800faa:	5d                   	pop    %ebp
  800fab:	c3                   	ret    

00800fac <strncmp>:

int
strncmp(const char *p, const char *q, uint32 n)
{
  800fac:	55                   	push   %ebp
  800fad:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  800faf:	eb 09                	jmp    800fba <strncmp+0xe>
		n--, p++, q++;
  800fb1:	ff 4d 10             	decl   0x10(%ebp)
  800fb4:	ff 45 08             	incl   0x8(%ebp)
  800fb7:	ff 45 0c             	incl   0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint32 n)
{
	while (n > 0 && *p && *p == *q)
  800fba:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  800fbe:	74 17                	je     800fd7 <strncmp+0x2b>
  800fc0:	8b 45 08             	mov    0x8(%ebp),%eax
  800fc3:	8a 00                	mov    (%eax),%al
  800fc5:	84 c0                	test   %al,%al
  800fc7:	74 0e                	je     800fd7 <strncmp+0x2b>
  800fc9:	8b 45 08             	mov    0x8(%ebp),%eax
  800fcc:	8a 10                	mov    (%eax),%dl
  800fce:	8b 45 0c             	mov    0xc(%ebp),%eax
  800fd1:	8a 00                	mov    (%eax),%al
  800fd3:	38 c2                	cmp    %al,%dl
  800fd5:	74 da                	je     800fb1 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  800fd7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  800fdb:	75 07                	jne    800fe4 <strncmp+0x38>
		return 0;
  800fdd:	b8 00 00 00 00       	mov    $0x0,%eax
  800fe2:	eb 14                	jmp    800ff8 <strncmp+0x4c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800fe4:	8b 45 08             	mov    0x8(%ebp),%eax
  800fe7:	8a 00                	mov    (%eax),%al
  800fe9:	0f b6 d0             	movzbl %al,%edx
  800fec:	8b 45 0c             	mov    0xc(%ebp),%eax
  800fef:	8a 00                	mov    (%eax),%al
  800ff1:	0f b6 c0             	movzbl %al,%eax
  800ff4:	29 c2                	sub    %eax,%edx
  800ff6:	89 d0                	mov    %edx,%eax
}
  800ff8:	5d                   	pop    %ebp
  800ff9:	c3                   	ret    

00800ffa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800ffa:	55                   	push   %ebp
  800ffb:	89 e5                	mov    %esp,%ebp
  800ffd:	83 ec 04             	sub    $0x4,%esp
  801000:	8b 45 0c             	mov    0xc(%ebp),%eax
  801003:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
  801006:	eb 12                	jmp    80101a <strchr+0x20>
		if (*s == c)
  801008:	8b 45 08             	mov    0x8(%ebp),%eax
  80100b:	8a 00                	mov    (%eax),%al
  80100d:	3a 45 fc             	cmp    -0x4(%ebp),%al
  801010:	75 05                	jne    801017 <strchr+0x1d>
			return (char *) s;
  801012:	8b 45 08             	mov    0x8(%ebp),%eax
  801015:	eb 11                	jmp    801028 <strchr+0x2e>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  801017:	ff 45 08             	incl   0x8(%ebp)
  80101a:	8b 45 08             	mov    0x8(%ebp),%eax
  80101d:	8a 00                	mov    (%eax),%al
  80101f:	84 c0                	test   %al,%al
  801021:	75 e5                	jne    801008 <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
  801023:	b8 00 00 00 00       	mov    $0x0,%eax
}
  801028:	c9                   	leave  
  801029:	c3                   	ret    

0080102a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80102a:	55                   	push   %ebp
  80102b:	89 e5                	mov    %esp,%ebp
  80102d:	83 ec 04             	sub    $0x4,%esp
  801030:	8b 45 0c             	mov    0xc(%ebp),%eax
  801033:	88 45 fc             	mov    %al,-0x4(%ebp)
	for (; *s; s++)
  801036:	eb 0d                	jmp    801045 <strfind+0x1b>
		if (*s == c)
  801038:	8b 45 08             	mov    0x8(%ebp),%eax
  80103b:	8a 00                	mov    (%eax),%al
  80103d:	3a 45 fc             	cmp    -0x4(%ebp),%al
  801040:	74 0e                	je     801050 <strfind+0x26>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  801042:	ff 45 08             	incl   0x8(%ebp)
  801045:	8b 45 08             	mov    0x8(%ebp),%eax
  801048:	8a 00                	mov    (%eax),%al
  80104a:	84 c0                	test   %al,%al
  80104c:	75 ea                	jne    801038 <strfind+0xe>
  80104e:	eb 01                	jmp    801051 <strfind+0x27>
		if (*s == c)
			break;
  801050:	90                   	nop
	return (char *) s;
  801051:	8b 45 08             	mov    0x8(%ebp),%eax
}
  801054:	c9                   	leave  
  801055:	c3                   	ret    

00801056 <memset>:

// *************** The faster implementation of memset & memcpy is implemented by *************
// ****************** Team80 (Yahia Khaled, Malek Ahmed et al) - FCIS'24-25 *******************
void *
memset(void *v, int c, uint32 n)
{
  801056:	55                   	push   %ebp
  801057:	89 e5                	mov    %esp,%ebp
  801059:	83 ec 10             	sub    $0x10,%esp
//	m = n;
//	while (--m >= 0)
//		*p++ = c;

	/*Faster Implementation*/
	uint64* p64 = (uint64*)v;
  80105c:	8b 45 08             	mov    0x8(%ebp),%eax
  80105f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if(n >= 8){
  801062:	83 7d 10 07          	cmpl   $0x7,0x10(%ebp)
  801066:	76 63                	jbe    8010cb <memset+0x75>
		uint64 data_block = c;
  801068:	8b 45 0c             	mov    0xc(%ebp),%eax
  80106b:	99                   	cltd   
  80106c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  80106f:	89 55 f4             	mov    %edx,-0xc(%ebp)
		data_block |= data_block << 8;
  801072:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801075:	8b 55 f4             	mov    -0xc(%ebp),%edx
  801078:	0f a4 c2 08          	shld   $0x8,%eax,%edx
  80107c:	c1 e0 08             	shl    $0x8,%eax
  80107f:	09 45 f0             	or     %eax,-0x10(%ebp)
  801082:	09 55 f4             	or     %edx,-0xc(%ebp)
		data_block |= data_block << 16;
  801085:	8b 45 f0             	mov    -0x10(%ebp),%eax
  801088:	8b 55 f4             	mov    -0xc(%ebp),%edx
  80108b:	0f a4 c2 10          	shld   $0x10,%eax,%edx
  80108f:	c1 e0 10             	shl    $0x10,%eax
  801092:	09 45 f0             	or     %eax,-0x10(%ebp)
  801095:	09 55 f4             	or     %edx,-0xc(%ebp)
		data_block |= data_block << 32;
  801098:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80109b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  80109e:	89 c2                	mov    %eax,%edx
  8010a0:	b8 00 00 00 00       	mov    $0x0,%eax
  8010a5:	09 45 f0             	or     %eax,-0x10(%ebp)
  8010a8:	09 55 f4             	or     %edx,-0xc(%ebp)

		while(n >= 8)
  8010ab:	eb 18                	jmp    8010c5 <memset+0x6f>
			*p64++ = data_block, n -= 8;
  8010ad:	8b 4d fc             	mov    -0x4(%ebp),%ecx
  8010b0:	8d 41 08             	lea    0x8(%ecx),%eax
  8010b3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  8010b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8010b9:	8b 55 f4             	mov    -0xc(%ebp),%edx
  8010bc:	89 01                	mov    %eax,(%ecx)
  8010be:	89 51 04             	mov    %edx,0x4(%ecx)
  8010c1:	83 6d 10 08          	subl   $0x8,0x10(%ebp)
		uint64 data_block = c;
		data_block |= data_block << 8;
		data_block |= data_block << 16;
		data_block |= data_block << 32;

		while(n >= 8)
  8010c5:	83 7d 10 07          	cmpl   $0x7,0x10(%ebp)
  8010c9:	77 e2                	ja     8010ad <memset+0x57>
			*p64++ = data_block, n -= 8;
	}

	if(n){
  8010cb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  8010cf:	74 23                	je     8010f4 <memset+0x9e>
		uint8* p8 = (uint8*)p64;
  8010d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  8010d4:	89 45 f8             	mov    %eax,-0x8(%ebp)
		while (n-- > 0)
  8010d7:	eb 0e                	jmp    8010e7 <memset+0x91>
			*p8++ = (uint8)c;
  8010d9:	8b 45 f8             	mov    -0x8(%ebp),%eax
  8010dc:	8d 50 01             	lea    0x1(%eax),%edx
  8010df:	89 55 f8             	mov    %edx,-0x8(%ebp)
  8010e2:	8b 55 0c             	mov    0xc(%ebp),%edx
  8010e5:	88 10                	mov    %dl,(%eax)
			*p64++ = data_block, n -= 8;
	}

	if(n){
		uint8* p8 = (uint8*)p64;
		while (n-- > 0)
  8010e7:	8b 45 10             	mov    0x10(%ebp),%eax
  8010ea:	8d 50 ff             	lea    -0x1(%eax),%edx
  8010ed:	89 55 10             	mov    %edx,0x10(%ebp)
  8010f0:	85 c0                	test   %eax,%eax
  8010f2:	75 e5                	jne    8010d9 <memset+0x83>
			*p8++ = (uint8)c;
	}

	return v;
  8010f4:	8b 45 08             	mov    0x8(%ebp),%eax
}
  8010f7:	c9                   	leave  
  8010f8:	c3                   	ret    

008010f9 <memcpy>:

void *
memcpy(void *dst, const void *src, uint32 n)
{
  8010f9:	55                   	push   %ebp
  8010fa:	89 e5                	mov    %esp,%ebp
  8010fc:	83 ec 10             	sub    $0x10,%esp
	//	s = src;
	//	d = dst;
	//	while (n-- > 0)
	//		*d++ = *s++;
	/*Faster Implementation*/
	uint64* s64 = (uint64*)src;
  8010ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  801102:	89 45 fc             	mov    %eax,-0x4(%ebp)
	uint64* d64 = (uint64*)dst;
  801105:	8b 45 08             	mov    0x8(%ebp),%eax
  801108:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if(n >= 8){
  80110b:	83 7d 10 07          	cmpl   $0x7,0x10(%ebp)
  80110f:	76 24                	jbe    801135 <memcpy+0x3c>
		while(n >= 8){
  801111:	eb 1c                	jmp    80112f <memcpy+0x36>
			*d64 = *s64;
  801113:	8b 45 fc             	mov    -0x4(%ebp),%eax
  801116:	8b 50 04             	mov    0x4(%eax),%edx
  801119:	8b 00                	mov    (%eax),%eax
  80111b:	8b 4d f8             	mov    -0x8(%ebp),%ecx
  80111e:	89 01                	mov    %eax,(%ecx)
  801120:	89 51 04             	mov    %edx,0x4(%ecx)
			n -= 8;
  801123:	83 6d 10 08          	subl   $0x8,0x10(%ebp)
			++s64;
  801127:	83 45 fc 08          	addl   $0x8,-0x4(%ebp)
			++d64;
  80112b:	83 45 f8 08          	addl   $0x8,-0x8(%ebp)
	//		*d++ = *s++;
	/*Faster Implementation*/
	uint64* s64 = (uint64*)src;
	uint64* d64 = (uint64*)dst;
	if(n >= 8){
		while(n >= 8){
  80112f:	83 7d 10 07          	cmpl   $0x7,0x10(%ebp)
  801133:	77 de                	ja     801113 <memcpy+0x1a>
			++s64;
			++d64;
		}
	}

	if(n){
  801135:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  801139:	74 31                	je     80116c <memcpy+0x73>
		uint8* s8 = (uint8*)s64;
  80113b:	8b 45 fc             	mov    -0x4(%ebp),%eax
  80113e:	89 45 f4             	mov    %eax,-0xc(%ebp)
		uint8* d8 = (uint8*)d64;
  801141:	8b 45 f8             	mov    -0x8(%ebp),%eax
  801144:	89 45 f0             	mov    %eax,-0x10(%ebp)
		while (n-- > 0)
  801147:	eb 16                	jmp    80115f <memcpy+0x66>
			*d8++ = *s8++;
  801149:	8b 45 f0             	mov    -0x10(%ebp),%eax
  80114c:	8d 50 01             	lea    0x1(%eax),%edx
  80114f:	89 55 f0             	mov    %edx,-0x10(%ebp)
  801152:	8b 55 f4             	mov    -0xc(%ebp),%edx
  801155:	8d 4a 01             	lea    0x1(%edx),%ecx
  801158:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  80115b:	8a 12                	mov    (%edx),%dl
  80115d:	88 10                	mov    %dl,(%eax)
	}

	if(n){
		uint8* s8 = (uint8*)s64;
		uint8* d8 = (uint8*)d64;
		while (n-- > 0)
  80115f:	8b 45 10             	mov    0x10(%ebp),%eax
  801162:	8d 50 ff             	lea    -0x1(%eax),%edx
  801165:	89 55 10             	mov    %edx,0x10(%ebp)
  801168:	85 c0                	test   %eax,%eax
  80116a:	75 dd                	jne    801149 <memcpy+0x50>
			*d8++ = *s8++;
	}
	return dst;
  80116c:	8b 45 08             	mov    0x8(%ebp),%eax
}
  80116f:	c9                   	leave  
  801170:	c3                   	ret    

00801171 <memmove>:

void *
memmove(void *dst, const void *src, uint32 n)
{
  801171:	55                   	push   %ebp
  801172:	89 e5                	mov    %esp,%ebp
  801174:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;

	s = src;
  801177:	8b 45 0c             	mov    0xc(%ebp),%eax
  80117a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
  80117d:	8b 45 08             	mov    0x8(%ebp),%eax
  801180:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (s < d && s + n > d) {
  801183:	8b 45 fc             	mov    -0x4(%ebp),%eax
  801186:	3b 45 f8             	cmp    -0x8(%ebp),%eax
  801189:	73 50                	jae    8011db <memmove+0x6a>
  80118b:	8b 55 fc             	mov    -0x4(%ebp),%edx
  80118e:	8b 45 10             	mov    0x10(%ebp),%eax
  801191:	01 d0                	add    %edx,%eax
  801193:	3b 45 f8             	cmp    -0x8(%ebp),%eax
  801196:	76 43                	jbe    8011db <memmove+0x6a>
		s += n;
  801198:	8b 45 10             	mov    0x10(%ebp),%eax
  80119b:	01 45 fc             	add    %eax,-0x4(%ebp)
		d += n;
  80119e:	8b 45 10             	mov    0x10(%ebp),%eax
  8011a1:	01 45 f8             	add    %eax,-0x8(%ebp)
		while (n-- > 0)
  8011a4:	eb 10                	jmp    8011b6 <memmove+0x45>
			*--d = *--s;
  8011a6:	ff 4d f8             	decl   -0x8(%ebp)
  8011a9:	ff 4d fc             	decl   -0x4(%ebp)
  8011ac:	8b 45 fc             	mov    -0x4(%ebp),%eax
  8011af:	8a 10                	mov    (%eax),%dl
  8011b1:	8b 45 f8             	mov    -0x8(%ebp),%eax
  8011b4:	88 10                	mov    %dl,(%eax)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
  8011b6:	8b 45 10             	mov    0x10(%ebp),%eax
  8011b9:	8d 50 ff             	lea    -0x1(%eax),%edx
  8011bc:	89 55 10             	mov    %edx,0x10(%ebp)
  8011bf:	85 c0                	test   %eax,%eax
  8011c1:	75 e3                	jne    8011a6 <memmove+0x35>
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8011c3:	eb 23                	jmp    8011e8 <memmove+0x77>
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
  8011c5:	8b 45 f8             	mov    -0x8(%ebp),%eax
  8011c8:	8d 50 01             	lea    0x1(%eax),%edx
  8011cb:	89 55 f8             	mov    %edx,-0x8(%ebp)
  8011ce:	8b 55 fc             	mov    -0x4(%ebp),%edx
  8011d1:	8d 4a 01             	lea    0x1(%edx),%ecx
  8011d4:	89 4d fc             	mov    %ecx,-0x4(%ebp)
  8011d7:	8a 12                	mov    (%edx),%dl
  8011d9:	88 10                	mov    %dl,(%eax)
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
  8011db:	8b 45 10             	mov    0x10(%ebp),%eax
  8011de:	8d 50 ff             	lea    -0x1(%eax),%edx
  8011e1:	89 55 10             	mov    %edx,0x10(%ebp)
  8011e4:	85 c0                	test   %eax,%eax
  8011e6:	75 dd                	jne    8011c5 <memmove+0x54>
			*d++ = *s++;

	return dst;
  8011e8:	8b 45 08             	mov    0x8(%ebp),%eax
}
  8011eb:	c9                   	leave  
  8011ec:	c3                   	ret    

008011ed <memcmp>:

int
memcmp(const void *v1, const void *v2, uint32 n)
{
  8011ed:	55                   	push   %ebp
  8011ee:	89 e5                	mov    %esp,%ebp
  8011f0:	83 ec 10             	sub    $0x10,%esp
	const uint8 *s1 = (const uint8 *) v1;
  8011f3:	8b 45 08             	mov    0x8(%ebp),%eax
  8011f6:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8 *s2 = (const uint8 *) v2;
  8011f9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8011fc:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
  8011ff:	eb 2a                	jmp    80122b <memcmp+0x3e>
		if (*s1 != *s2)
  801201:	8b 45 fc             	mov    -0x4(%ebp),%eax
  801204:	8a 10                	mov    (%eax),%dl
  801206:	8b 45 f8             	mov    -0x8(%ebp),%eax
  801209:	8a 00                	mov    (%eax),%al
  80120b:	38 c2                	cmp    %al,%dl
  80120d:	74 16                	je     801225 <memcmp+0x38>
			return (int) *s1 - (int) *s2;
  80120f:	8b 45 fc             	mov    -0x4(%ebp),%eax
  801212:	8a 00                	mov    (%eax),%al
  801214:	0f b6 d0             	movzbl %al,%edx
  801217:	8b 45 f8             	mov    -0x8(%ebp),%eax
  80121a:	8a 00                	mov    (%eax),%al
  80121c:	0f b6 c0             	movzbl %al,%eax
  80121f:	29 c2                	sub    %eax,%edx
  801221:	89 d0                	mov    %edx,%eax
  801223:	eb 18                	jmp    80123d <memcmp+0x50>
		s1++, s2++;
  801225:	ff 45 fc             	incl   -0x4(%ebp)
  801228:	ff 45 f8             	incl   -0x8(%ebp)
memcmp(const void *v1, const void *v2, uint32 n)
{
	const uint8 *s1 = (const uint8 *) v1;
	const uint8 *s2 = (const uint8 *) v2;

	while (n-- > 0) {
  80122b:	8b 45 10             	mov    0x10(%ebp),%eax
  80122e:	8d 50 ff             	lea    -0x1(%eax),%edx
  801231:	89 55 10             	mov    %edx,0x10(%ebp)
  801234:	85 c0                	test   %eax,%eax
  801236:	75 c9                	jne    801201 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  801238:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80123d:	c9                   	leave  
  80123e:	c3                   	ret    

0080123f <memfind>:

void *
memfind(const void *s, int c, uint32 n)
{
  80123f:	55                   	push   %ebp
  801240:	89 e5                	mov    %esp,%ebp
  801242:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  801245:	8b 55 08             	mov    0x8(%ebp),%edx
  801248:	8b 45 10             	mov    0x10(%ebp),%eax
  80124b:	01 d0                	add    %edx,%eax
  80124d:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  801250:	eb 15                	jmp    801267 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
  801252:	8b 45 08             	mov    0x8(%ebp),%eax
  801255:	8a 00                	mov    (%eax),%al
  801257:	0f b6 d0             	movzbl %al,%edx
  80125a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80125d:	0f b6 c0             	movzbl %al,%eax
  801260:	39 c2                	cmp    %eax,%edx
  801262:	74 0d                	je     801271 <memfind+0x32>

void *
memfind(const void *s, int c, uint32 n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  801264:	ff 45 08             	incl   0x8(%ebp)
  801267:	8b 45 08             	mov    0x8(%ebp),%eax
  80126a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  80126d:	72 e3                	jb     801252 <memfind+0x13>
  80126f:	eb 01                	jmp    801272 <memfind+0x33>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
  801271:	90                   	nop
	return (void *) s;
  801272:	8b 45 08             	mov    0x8(%ebp),%eax
}
  801275:	c9                   	leave  
  801276:	c3                   	ret    

00801277 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  801277:	55                   	push   %ebp
  801278:	89 e5                	mov    %esp,%ebp
  80127a:	83 ec 10             	sub    $0x10,%esp
	int neg = 0;
  80127d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
  801284:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  80128b:	eb 03                	jmp    801290 <strtol+0x19>
		s++;
  80128d:	ff 45 08             	incl   0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  801290:	8b 45 08             	mov    0x8(%ebp),%eax
  801293:	8a 00                	mov    (%eax),%al
  801295:	3c 20                	cmp    $0x20,%al
  801297:	74 f4                	je     80128d <strtol+0x16>
  801299:	8b 45 08             	mov    0x8(%ebp),%eax
  80129c:	8a 00                	mov    (%eax),%al
  80129e:	3c 09                	cmp    $0x9,%al
  8012a0:	74 eb                	je     80128d <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
  8012a2:	8b 45 08             	mov    0x8(%ebp),%eax
  8012a5:	8a 00                	mov    (%eax),%al
  8012a7:	3c 2b                	cmp    $0x2b,%al
  8012a9:	75 05                	jne    8012b0 <strtol+0x39>
		s++;
  8012ab:	ff 45 08             	incl   0x8(%ebp)
  8012ae:	eb 13                	jmp    8012c3 <strtol+0x4c>
	else if (*s == '-')
  8012b0:	8b 45 08             	mov    0x8(%ebp),%eax
  8012b3:	8a 00                	mov    (%eax),%al
  8012b5:	3c 2d                	cmp    $0x2d,%al
  8012b7:	75 0a                	jne    8012c3 <strtol+0x4c>
		s++, neg = 1;
  8012b9:	ff 45 08             	incl   0x8(%ebp)
  8012bc:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  8012c3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  8012c7:	74 06                	je     8012cf <strtol+0x58>
  8012c9:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
  8012cd:	75 20                	jne    8012ef <strtol+0x78>
  8012cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8012d2:	8a 00                	mov    (%eax),%al
  8012d4:	3c 30                	cmp    $0x30,%al
  8012d6:	75 17                	jne    8012ef <strtol+0x78>
  8012d8:	8b 45 08             	mov    0x8(%ebp),%eax
  8012db:	40                   	inc    %eax
  8012dc:	8a 00                	mov    (%eax),%al
  8012de:	3c 78                	cmp    $0x78,%al
  8012e0:	75 0d                	jne    8012ef <strtol+0x78>
		s += 2, base = 16;
  8012e2:	83 45 08 02          	addl   $0x2,0x8(%ebp)
  8012e6:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
  8012ed:	eb 28                	jmp    801317 <strtol+0xa0>
	else if (base == 0 && s[0] == '0')
  8012ef:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  8012f3:	75 15                	jne    80130a <strtol+0x93>
  8012f5:	8b 45 08             	mov    0x8(%ebp),%eax
  8012f8:	8a 00                	mov    (%eax),%al
  8012fa:	3c 30                	cmp    $0x30,%al
  8012fc:	75 0c                	jne    80130a <strtol+0x93>
		s++, base = 8;
  8012fe:	ff 45 08             	incl   0x8(%ebp)
  801301:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
  801308:	eb 0d                	jmp    801317 <strtol+0xa0>
	else if (base == 0)
  80130a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  80130e:	75 07                	jne    801317 <strtol+0xa0>
		base = 10;
  801310:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  801317:	8b 45 08             	mov    0x8(%ebp),%eax
  80131a:	8a 00                	mov    (%eax),%al
  80131c:	3c 2f                	cmp    $0x2f,%al
  80131e:	7e 19                	jle    801339 <strtol+0xc2>
  801320:	8b 45 08             	mov    0x8(%ebp),%eax
  801323:	8a 00                	mov    (%eax),%al
  801325:	3c 39                	cmp    $0x39,%al
  801327:	7f 10                	jg     801339 <strtol+0xc2>
			dig = *s - '0';
  801329:	8b 45 08             	mov    0x8(%ebp),%eax
  80132c:	8a 00                	mov    (%eax),%al
  80132e:	0f be c0             	movsbl %al,%eax
  801331:	83 e8 30             	sub    $0x30,%eax
  801334:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801337:	eb 42                	jmp    80137b <strtol+0x104>
		else if (*s >= 'a' && *s <= 'z')
  801339:	8b 45 08             	mov    0x8(%ebp),%eax
  80133c:	8a 00                	mov    (%eax),%al
  80133e:	3c 60                	cmp    $0x60,%al
  801340:	7e 19                	jle    80135b <strtol+0xe4>
  801342:	8b 45 08             	mov    0x8(%ebp),%eax
  801345:	8a 00                	mov    (%eax),%al
  801347:	3c 7a                	cmp    $0x7a,%al
  801349:	7f 10                	jg     80135b <strtol+0xe4>
			dig = *s - 'a' + 10;
  80134b:	8b 45 08             	mov    0x8(%ebp),%eax
  80134e:	8a 00                	mov    (%eax),%al
  801350:	0f be c0             	movsbl %al,%eax
  801353:	83 e8 57             	sub    $0x57,%eax
  801356:	89 45 f4             	mov    %eax,-0xc(%ebp)
  801359:	eb 20                	jmp    80137b <strtol+0x104>
		else if (*s >= 'A' && *s <= 'Z')
  80135b:	8b 45 08             	mov    0x8(%ebp),%eax
  80135e:	8a 00                	mov    (%eax),%al
  801360:	3c 40                	cmp    $0x40,%al
  801362:	7e 39                	jle    80139d <strtol+0x126>
  801364:	8b 45 08             	mov    0x8(%ebp),%eax
  801367:	8a 00                	mov    (%eax),%al
  801369:	3c 5a                	cmp    $0x5a,%al
  80136b:	7f 30                	jg     80139d <strtol+0x126>
			dig = *s - 'A' + 10;
  80136d:	8b 45 08             	mov    0x8(%ebp),%eax
  801370:	8a 00                	mov    (%eax),%al
  801372:	0f be c0             	movsbl %al,%eax
  801375:	83 e8 37             	sub    $0x37,%eax
  801378:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
  80137b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80137e:	3b 45 10             	cmp    0x10(%ebp),%eax
  801381:	7d 19                	jge    80139c <strtol+0x125>
			break;
		s++, val = (val * base) + dig;
  801383:	ff 45 08             	incl   0x8(%ebp)
  801386:	8b 45 f8             	mov    -0x8(%ebp),%eax
  801389:	0f af 45 10          	imul   0x10(%ebp),%eax
  80138d:	89 c2                	mov    %eax,%edx
  80138f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801392:	01 d0                	add    %edx,%eax
  801394:	89 45 f8             	mov    %eax,-0x8(%ebp)
		// we don't properly detect overflow!
	}
  801397:	e9 7b ff ff ff       	jmp    801317 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
			break;
  80139c:	90                   	nop
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
  80139d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8013a1:	74 08                	je     8013ab <strtol+0x134>
		*endptr = (char *) s;
  8013a3:	8b 45 0c             	mov    0xc(%ebp),%eax
  8013a6:	8b 55 08             	mov    0x8(%ebp),%edx
  8013a9:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
  8013ab:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  8013af:	74 07                	je     8013b8 <strtol+0x141>
  8013b1:	8b 45 f8             	mov    -0x8(%ebp),%eax
  8013b4:	f7 d8                	neg    %eax
  8013b6:	eb 03                	jmp    8013bb <strtol+0x144>
  8013b8:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  8013bb:	c9                   	leave  
  8013bc:	c3                   	ret    

008013bd <ltostr>:

void
ltostr(long value, char *str)
{
  8013bd:	55                   	push   %ebp
  8013be:	89 e5                	mov    %esp,%ebp
  8013c0:	83 ec 20             	sub    $0x20,%esp
	int neg = 0;
  8013c3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	int s = 0 ;
  8013ca:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

	// plus/minus sign
	if (value < 0)
  8013d1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  8013d5:	79 13                	jns    8013ea <ltostr+0x2d>
	{
		neg = 1;
  8013d7:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
		str[0] = '-';
  8013de:	8b 45 0c             	mov    0xc(%ebp),%eax
  8013e1:	c6 00 2d             	movb   $0x2d,(%eax)
		value = value * -1 ;
  8013e4:	f7 5d 08             	negl   0x8(%ebp)
		s++ ;
  8013e7:	ff 45 f8             	incl   -0x8(%ebp)
	}
	do
	{
		int mod = value % 10 ;
  8013ea:	8b 45 08             	mov    0x8(%ebp),%eax
  8013ed:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8013f2:	99                   	cltd   
  8013f3:	f7 f9                	idiv   %ecx
  8013f5:	89 55 ec             	mov    %edx,-0x14(%ebp)
		str[s++] = mod + '0' ;
  8013f8:	8b 45 f8             	mov    -0x8(%ebp),%eax
  8013fb:	8d 50 01             	lea    0x1(%eax),%edx
  8013fe:	89 55 f8             	mov    %edx,-0x8(%ebp)
  801401:	89 c2                	mov    %eax,%edx
  801403:	8b 45 0c             	mov    0xc(%ebp),%eax
  801406:	01 d0                	add    %edx,%eax
  801408:	8b 55 ec             	mov    -0x14(%ebp),%edx
  80140b:	83 c2 30             	add    $0x30,%edx
  80140e:	88 10                	mov    %dl,(%eax)
		value = value / 10 ;
  801410:	8b 4d 08             	mov    0x8(%ebp),%ecx
  801413:	b8 67 66 66 66       	mov    $0x66666667,%eax
  801418:	f7 e9                	imul   %ecx
  80141a:	c1 fa 02             	sar    $0x2,%edx
  80141d:	89 c8                	mov    %ecx,%eax
  80141f:	c1 f8 1f             	sar    $0x1f,%eax
  801422:	29 c2                	sub    %eax,%edx
  801424:	89 d0                	mov    %edx,%eax
  801426:	89 45 08             	mov    %eax,0x8(%ebp)
	/*2023 FIX el7 :)*/
	//} while (value % 10 != 0);
	} while (value != 0);
  801429:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  80142d:	75 bb                	jne    8013ea <ltostr+0x2d>

	//reverse the string
	int start = 0 ;
  80142f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int end = s-1 ;
  801436:	8b 45 f8             	mov    -0x8(%ebp),%eax
  801439:	48                   	dec    %eax
  80143a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (neg)
  80143d:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
  801441:	74 3d                	je     801480 <ltostr+0xc3>
		start = 1 ;
  801443:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
	while(start<end)
  80144a:	eb 34                	jmp    801480 <ltostr+0xc3>
	{
		char tmp = str[start] ;
  80144c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  80144f:	8b 45 0c             	mov    0xc(%ebp),%eax
  801452:	01 d0                	add    %edx,%eax
  801454:	8a 00                	mov    (%eax),%al
  801456:	88 45 eb             	mov    %al,-0x15(%ebp)
		str[start] = str[end] ;
  801459:	8b 55 f4             	mov    -0xc(%ebp),%edx
  80145c:	8b 45 0c             	mov    0xc(%ebp),%eax
  80145f:	01 c2                	add    %eax,%edx
  801461:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  801464:	8b 45 0c             	mov    0xc(%ebp),%eax
  801467:	01 c8                	add    %ecx,%eax
  801469:	8a 00                	mov    (%eax),%al
  80146b:	88 02                	mov    %al,(%edx)
		str[end] = tmp;
  80146d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  801470:	8b 45 0c             	mov    0xc(%ebp),%eax
  801473:	01 c2                	add    %eax,%edx
  801475:	8a 45 eb             	mov    -0x15(%ebp),%al
  801478:	88 02                	mov    %al,(%edx)
		start++ ;
  80147a:	ff 45 f4             	incl   -0xc(%ebp)
		end-- ;
  80147d:	ff 4d f0             	decl   -0x10(%ebp)
	//reverse the string
	int start = 0 ;
	int end = s-1 ;
	if (neg)
		start = 1 ;
	while(start<end)
  801480:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801483:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  801486:	7c c4                	jl     80144c <ltostr+0x8f>
		str[end] = tmp;
		start++ ;
		end-- ;
	}

	str[s] = 0 ;
  801488:	8b 55 f8             	mov    -0x8(%ebp),%edx
  80148b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80148e:	01 d0                	add    %edx,%eax
  801490:	c6 00 00             	movb   $0x0,(%eax)
	// we don't properly detect overflow!

}
  801493:	90                   	nop
  801494:	c9                   	leave  
  801495:	c3                   	ret    

00801496 <strcconcat>:

void
strcconcat(const char *str1, const char *str2, char *final)
{
  801496:	55                   	push   %ebp
  801497:	89 e5                	mov    %esp,%ebp
  801499:	83 ec 10             	sub    $0x10,%esp
	int len1 = strlen(str1);
  80149c:	ff 75 08             	pushl  0x8(%ebp)
  80149f:	e8 c4 f9 ff ff       	call   800e68 <strlen>
  8014a4:	83 c4 04             	add    $0x4,%esp
  8014a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	int len2 = strlen(str2);
  8014aa:	ff 75 0c             	pushl  0xc(%ebp)
  8014ad:	e8 b6 f9 ff ff       	call   800e68 <strlen>
  8014b2:	83 c4 04             	add    $0x4,%esp
  8014b5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	int s = 0 ;
  8014b8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	for (s=0 ; s < len1 ; s++)
  8014bf:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  8014c6:	eb 17                	jmp    8014df <strcconcat+0x49>
		final[s] = str1[s] ;
  8014c8:	8b 55 fc             	mov    -0x4(%ebp),%edx
  8014cb:	8b 45 10             	mov    0x10(%ebp),%eax
  8014ce:	01 c2                	add    %eax,%edx
  8014d0:	8b 4d fc             	mov    -0x4(%ebp),%ecx
  8014d3:	8b 45 08             	mov    0x8(%ebp),%eax
  8014d6:	01 c8                	add    %ecx,%eax
  8014d8:	8a 00                	mov    (%eax),%al
  8014da:	88 02                	mov    %al,(%edx)
strcconcat(const char *str1, const char *str2, char *final)
{
	int len1 = strlen(str1);
	int len2 = strlen(str2);
	int s = 0 ;
	for (s=0 ; s < len1 ; s++)
  8014dc:	ff 45 fc             	incl   -0x4(%ebp)
  8014df:	8b 45 fc             	mov    -0x4(%ebp),%eax
  8014e2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  8014e5:	7c e1                	jl     8014c8 <strcconcat+0x32>
		final[s] = str1[s] ;

	int i = 0 ;
  8014e7:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	for (i=0 ; i < len2 ; i++)
  8014ee:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  8014f5:	eb 1f                	jmp    801516 <strcconcat+0x80>
		final[s++] = str2[i] ;
  8014f7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  8014fa:	8d 50 01             	lea    0x1(%eax),%edx
  8014fd:	89 55 fc             	mov    %edx,-0x4(%ebp)
  801500:	89 c2                	mov    %eax,%edx
  801502:	8b 45 10             	mov    0x10(%ebp),%eax
  801505:	01 c2                	add    %eax,%edx
  801507:	8b 4d f8             	mov    -0x8(%ebp),%ecx
  80150a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80150d:	01 c8                	add    %ecx,%eax
  80150f:	8a 00                	mov    (%eax),%al
  801511:	88 02                	mov    %al,(%edx)
	int s = 0 ;
	for (s=0 ; s < len1 ; s++)
		final[s] = str1[s] ;

	int i = 0 ;
	for (i=0 ; i < len2 ; i++)
  801513:	ff 45 f8             	incl   -0x8(%ebp)
  801516:	8b 45 f8             	mov    -0x8(%ebp),%eax
  801519:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  80151c:	7c d9                	jl     8014f7 <strcconcat+0x61>
		final[s++] = str2[i] ;

	final[s] = 0;
  80151e:	8b 55 fc             	mov    -0x4(%ebp),%edx
  801521:	8b 45 10             	mov    0x10(%ebp),%eax
  801524:	01 d0                	add    %edx,%eax
  801526:	c6 00 00             	movb   $0x0,(%eax)
}
  801529:	90                   	nop
  80152a:	c9                   	leave  
  80152b:	c3                   	ret    

0080152c <strsplit>:
int strsplit(char *string, char *SPLIT_CHARS, char **argv, int * argc)
{
  80152c:	55                   	push   %ebp
  80152d:	89 e5                	mov    %esp,%ebp
	// Parse the command string into splitchars-separated arguments
	*argc = 0;
  80152f:	8b 45 14             	mov    0x14(%ebp),%eax
  801532:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	(argv)[*argc] = 0;
  801538:	8b 45 14             	mov    0x14(%ebp),%eax
  80153b:	8b 00                	mov    (%eax),%eax
  80153d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  801544:	8b 45 10             	mov    0x10(%ebp),%eax
  801547:	01 d0                	add    %edx,%eax
  801549:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	while (1)
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
  80154f:	eb 0c                	jmp    80155d <strsplit+0x31>
			*string++ = 0;
  801551:	8b 45 08             	mov    0x8(%ebp),%eax
  801554:	8d 50 01             	lea    0x1(%eax),%edx
  801557:	89 55 08             	mov    %edx,0x8(%ebp)
  80155a:	c6 00 00             	movb   $0x0,(%eax)
	*argc = 0;
	(argv)[*argc] = 0;
	while (1)
	{
		// trim splitchars
		while (*string && strchr(SPLIT_CHARS, *string))
  80155d:	8b 45 08             	mov    0x8(%ebp),%eax
  801560:	8a 00                	mov    (%eax),%al
  801562:	84 c0                	test   %al,%al
  801564:	74 18                	je     80157e <strsplit+0x52>
  801566:	8b 45 08             	mov    0x8(%ebp),%eax
  801569:	8a 00                	mov    (%eax),%al
  80156b:	0f be c0             	movsbl %al,%eax
  80156e:	50                   	push   %eax
  80156f:	ff 75 0c             	pushl  0xc(%ebp)
  801572:	e8 83 fa ff ff       	call   800ffa <strchr>
  801577:	83 c4 08             	add    $0x8,%esp
  80157a:	85 c0                	test   %eax,%eax
  80157c:	75 d3                	jne    801551 <strsplit+0x25>
			*string++ = 0;

		//if the command string is finished, then break the loop
		if (*string == 0)
  80157e:	8b 45 08             	mov    0x8(%ebp),%eax
  801581:	8a 00                	mov    (%eax),%al
  801583:	84 c0                	test   %al,%al
  801585:	74 5a                	je     8015e1 <strsplit+0xb5>
			break;

		//check current number of arguments
		if (*argc == MAX_ARGUMENTS-1)
  801587:	8b 45 14             	mov    0x14(%ebp),%eax
  80158a:	8b 00                	mov    (%eax),%eax
  80158c:	83 f8 0f             	cmp    $0xf,%eax
  80158f:	75 07                	jne    801598 <strsplit+0x6c>
		{
			return 0;
  801591:	b8 00 00 00 00       	mov    $0x0,%eax
  801596:	eb 66                	jmp    8015fe <strsplit+0xd2>
		}

		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
  801598:	8b 45 14             	mov    0x14(%ebp),%eax
  80159b:	8b 00                	mov    (%eax),%eax
  80159d:	8d 48 01             	lea    0x1(%eax),%ecx
  8015a0:	8b 55 14             	mov    0x14(%ebp),%edx
  8015a3:	89 0a                	mov    %ecx,(%edx)
  8015a5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  8015ac:	8b 45 10             	mov    0x10(%ebp),%eax
  8015af:	01 c2                	add    %eax,%edx
  8015b1:	8b 45 08             	mov    0x8(%ebp),%eax
  8015b4:	89 02                	mov    %eax,(%edx)
		while (*string && !strchr(SPLIT_CHARS, *string))
  8015b6:	eb 03                	jmp    8015bb <strsplit+0x8f>
			string++;
  8015b8:	ff 45 08             	incl   0x8(%ebp)
			return 0;
		}

		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
  8015bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8015be:	8a 00                	mov    (%eax),%al
  8015c0:	84 c0                	test   %al,%al
  8015c2:	74 8b                	je     80154f <strsplit+0x23>
  8015c4:	8b 45 08             	mov    0x8(%ebp),%eax
  8015c7:	8a 00                	mov    (%eax),%al
  8015c9:	0f be c0             	movsbl %al,%eax
  8015cc:	50                   	push   %eax
  8015cd:	ff 75 0c             	pushl  0xc(%ebp)
  8015d0:	e8 25 fa ff ff       	call   800ffa <strchr>
  8015d5:	83 c4 08             	add    $0x8,%esp
  8015d8:	85 c0                	test   %eax,%eax
  8015da:	74 dc                	je     8015b8 <strsplit+0x8c>
			string++;
	}
  8015dc:	e9 6e ff ff ff       	jmp    80154f <strsplit+0x23>
		while (*string && strchr(SPLIT_CHARS, *string))
			*string++ = 0;

		//if the command string is finished, then break the loop
		if (*string == 0)
			break;
  8015e1:	90                   	nop
		// save the previous argument and scan past next arg
		(argv)[(*argc)++] = string;
		while (*string && !strchr(SPLIT_CHARS, *string))
			string++;
	}
	(argv)[*argc] = 0;
  8015e2:	8b 45 14             	mov    0x14(%ebp),%eax
  8015e5:	8b 00                	mov    (%eax),%eax
  8015e7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  8015ee:	8b 45 10             	mov    0x10(%ebp),%eax
  8015f1:	01 d0                	add    %edx,%eax
  8015f3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return 1 ;
  8015f9:	b8 01 00 00 00       	mov    $0x1,%eax
}
  8015fe:	c9                   	leave  
  8015ff:	c3                   	ret    

00801600 <str2lower>:


char* str2lower(char *dst, const char *src)
{
  801600:	55                   	push   %ebp
  801601:	89 e5                	mov    %esp,%ebp
  801603:	83 ec 10             	sub    $0x10,%esp
	char* ret = dst;
  801606:	8b 45 08             	mov    0x8(%ebp),%eax
  801609:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (int i = 0; i < strlen(src); ++i)
  80160c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  801613:	eb 4a                	jmp    80165f <str2lower+0x5f>
	{
		dst[i] = src[i] ;
  801615:	8b 55 fc             	mov    -0x4(%ebp),%edx
  801618:	8b 45 08             	mov    0x8(%ebp),%eax
  80161b:	01 c2                	add    %eax,%edx
  80161d:	8b 4d fc             	mov    -0x4(%ebp),%ecx
  801620:	8b 45 0c             	mov    0xc(%ebp),%eax
  801623:	01 c8                	add    %ecx,%eax
  801625:	8a 00                	mov    (%eax),%al
  801627:	88 02                	mov    %al,(%edx)
		if (src[i] >= 'A' && src[i] <= 'Z')
  801629:	8b 55 fc             	mov    -0x4(%ebp),%edx
  80162c:	8b 45 0c             	mov    0xc(%ebp),%eax
  80162f:	01 d0                	add    %edx,%eax
  801631:	8a 00                	mov    (%eax),%al
  801633:	3c 40                	cmp    $0x40,%al
  801635:	7e 25                	jle    80165c <str2lower+0x5c>
  801637:	8b 55 fc             	mov    -0x4(%ebp),%edx
  80163a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80163d:	01 d0                	add    %edx,%eax
  80163f:	8a 00                	mov    (%eax),%al
  801641:	3c 5a                	cmp    $0x5a,%al
  801643:	7f 17                	jg     80165c <str2lower+0x5c>
		{
			dst[i] += 32 ;
  801645:	8b 55 fc             	mov    -0x4(%ebp),%edx
  801648:	8b 45 08             	mov    0x8(%ebp),%eax
  80164b:	01 d0                	add    %edx,%eax
  80164d:	8b 4d fc             	mov    -0x4(%ebp),%ecx
  801650:	8b 55 08             	mov    0x8(%ebp),%edx
  801653:	01 ca                	add    %ecx,%edx
  801655:	8a 12                	mov    (%edx),%dl
  801657:	83 c2 20             	add    $0x20,%edx
  80165a:	88 10                	mov    %dl,(%eax)


char* str2lower(char *dst, const char *src)
{
	char* ret = dst;
	for (int i = 0; i < strlen(src); ++i)
  80165c:	ff 45 fc             	incl   -0x4(%ebp)
  80165f:	ff 75 0c             	pushl  0xc(%ebp)
  801662:	e8 01 f8 ff ff       	call   800e68 <strlen>
  801667:	83 c4 04             	add    $0x4,%esp
  80166a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  80166d:	7f a6                	jg     801615 <str2lower+0x15>
		if (src[i] >= 'A' && src[i] <= 'Z')
		{
			dst[i] += 32 ;
		}
	}
	return ret;
  80166f:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  801672:	c9                   	leave  
  801673:	c3                   	ret    

00801674 <uheap_init>:
//==============================================
// [1] INITIALIZE USER HEAP:
//==============================================
int __firstTimeFlag = 1;
void uheap_init()
{
  801674:	55                   	push   %ebp
  801675:	89 e5                	mov    %esp,%ebp
  801677:	83 ec 08             	sub    $0x8,%esp
	if(__firstTimeFlag)
  80167a:	a1 08 30 80 00       	mov    0x803008,%eax
  80167f:	85 c0                	test   %eax,%eax
  801681:	74 42                	je     8016c5 <uheap_init+0x51>
	{
		initialize_dynamic_allocator(USER_HEAP_START, USER_HEAP_START + DYN_ALLOC_MAX_SIZE);
  801683:	83 ec 08             	sub    $0x8,%esp
  801686:	68 00 00 00 82       	push   $0x82000000
  80168b:	68 00 00 00 80       	push   $0x80000000
  801690:	e8 00 08 00 00       	call   801e95 <initialize_dynamic_allocator>
  801695:	83 c4 10             	add    $0x10,%esp
		uheapPlaceStrategy = sys_get_uheap_strategy();
  801698:	e8 e7 05 00 00       	call   801c84 <sys_get_uheap_strategy>
  80169d:	a3 60 b0 81 00       	mov    %eax,0x81b060
		uheapPageAllocStart = dynAllocEnd + PAGE_SIZE;
  8016a2:	a1 40 30 80 00       	mov    0x803040,%eax
  8016a7:	05 00 10 00 00       	add    $0x1000,%eax
  8016ac:	a3 10 b1 81 00       	mov    %eax,0x81b110
		uheapPageAllocBreak = uheapPageAllocStart;
  8016b1:	a1 10 b1 81 00       	mov    0x81b110,%eax
  8016b6:	a3 68 b0 81 00       	mov    %eax,0x81b068

		__firstTimeFlag = 0;
  8016bb:	c7 05 08 30 80 00 00 	movl   $0x0,0x803008
  8016c2:	00 00 00 
	}
}
  8016c5:	90                   	nop
  8016c6:	c9                   	leave  
  8016c7:	c3                   	ret    

008016c8 <get_page>:

//==============================================
// [2] GET A PAGE FROM THE KERNEL FOR DA:
//==============================================
int get_page(void* va)
{
  8016c8:	55                   	push   %ebp
  8016c9:	89 e5                	mov    %esp,%ebp
  8016cb:	83 ec 18             	sub    $0x18,%esp
	int ret = __sys_allocate_page(ROUNDDOWN(va, PAGE_SIZE), PERM_USER|PERM_WRITEABLE|PERM_UHPAGE);
  8016ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8016d1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  8016d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8016d7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  8016dc:	83 ec 08             	sub    $0x8,%esp
  8016df:	68 06 04 00 00       	push   $0x406
  8016e4:	50                   	push   %eax
  8016e5:	e8 e4 01 00 00       	call   8018ce <__sys_allocate_page>
  8016ea:	83 c4 10             	add    $0x10,%esp
  8016ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ret < 0)
  8016f0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  8016f4:	79 14                	jns    80170a <get_page+0x42>
		panic("get_page() in user: failed to allocate page from the kernel");
  8016f6:	83 ec 04             	sub    $0x4,%esp
  8016f9:	68 28 2a 80 00       	push   $0x802a28
  8016fe:	6a 1f                	push   $0x1f
  801700:	68 64 2a 80 00       	push   $0x802a64
  801705:	e8 fd 08 00 00       	call   802007 <_panic>
	return 0;
  80170a:	b8 00 00 00 00       	mov    $0x0,%eax
}
  80170f:	c9                   	leave  
  801710:	c3                   	ret    

00801711 <return_page>:

//==============================================
// [3] RETURN A PAGE FROM THE DA TO KERNEL:
//==============================================
void return_page(void* va)
{
  801711:	55                   	push   %ebp
  801712:	89 e5                	mov    %esp,%ebp
  801714:	83 ec 18             	sub    $0x18,%esp
	int ret = __sys_unmap_frame(ROUNDDOWN((uint32)va, PAGE_SIZE));
  801717:	8b 45 08             	mov    0x8(%ebp),%eax
  80171a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  80171d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801720:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  801725:	83 ec 0c             	sub    $0xc,%esp
  801728:	50                   	push   %eax
  801729:	e8 e7 01 00 00       	call   801915 <__sys_unmap_frame>
  80172e:	83 c4 10             	add    $0x10,%esp
  801731:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ret < 0)
  801734:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  801738:	79 14                	jns    80174e <return_page+0x3d>
		panic("return_page() in user: failed to return a page to the kernel");
  80173a:	83 ec 04             	sub    $0x4,%esp
  80173d:	68 70 2a 80 00       	push   $0x802a70
  801742:	6a 2a                	push   $0x2a
  801744:	68 64 2a 80 00       	push   $0x802a64
  801749:	e8 b9 08 00 00       	call   802007 <_panic>
}
  80174e:	90                   	nop
  80174f:	c9                   	leave  
  801750:	c3                   	ret    

00801751 <malloc>:

//=================================
// [1] ALLOCATE SPACE IN USER HEAP:
//=================================
void* malloc(uint32 size)
{
  801751:	55                   	push   %ebp
  801752:	89 e5                	mov    %esp,%ebp
  801754:	83 ec 08             	sub    $0x8,%esp
	//==============================================================
	//DON'T CHANGE THIS CODE========================================
	uheap_init();
  801757:	e8 18 ff ff ff       	call   801674 <uheap_init>
	if (size == 0) return NULL ;
  80175c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  801760:	75 07                	jne    801769 <malloc+0x18>
  801762:	b8 00 00 00 00       	mov    $0x0,%eax
  801767:	eb 14                	jmp    80177d <malloc+0x2c>
	//==============================================================
	//TODO: [PROJECT'25.IM#2] USER HEAP - #1 malloc
	//Your code is here
	//Comment the following line
	panic("malloc() is not implemented yet...!!");
  801769:	83 ec 04             	sub    $0x4,%esp
  80176c:	68 b0 2a 80 00       	push   $0x802ab0
  801771:	6a 3e                	push   $0x3e
  801773:	68 64 2a 80 00       	push   $0x802a64
  801778:	e8 8a 08 00 00       	call   802007 <_panic>
}
  80177d:	c9                   	leave  
  80177e:	c3                   	ret    

0080177f <free>:

//=================================
// [2] FREE SPACE FROM USER HEAP:
//=================================
void free(void* virtual_address)
{
  80177f:	55                   	push   %ebp
  801780:	89 e5                	mov    %esp,%ebp
  801782:	83 ec 08             	sub    $0x8,%esp
	//TODO: [PROJECT'25.IM#2] USER HEAP - #3 free
	//Your code is here
	//Comment the following line
	panic("free() is not implemented yet...!!");
  801785:	83 ec 04             	sub    $0x4,%esp
  801788:	68 d8 2a 80 00       	push   $0x802ad8
  80178d:	6a 49                	push   $0x49
  80178f:	68 64 2a 80 00       	push   $0x802a64
  801794:	e8 6e 08 00 00       	call   802007 <_panic>

00801799 <smalloc>:

//=================================
// [3] ALLOCATE SHARED VARIABLE:
//=================================
void* smalloc(char *sharedVarName, uint32 size, uint8 isWritable)
{
  801799:	55                   	push   %ebp
  80179a:	89 e5                	mov    %esp,%ebp
  80179c:	83 ec 18             	sub    $0x18,%esp
  80179f:	8b 45 10             	mov    0x10(%ebp),%eax
  8017a2:	88 45 f4             	mov    %al,-0xc(%ebp)
	//==============================================================
	//DON'T CHANGE THIS CODE========================================
	uheap_init();
  8017a5:	e8 ca fe ff ff       	call   801674 <uheap_init>
	if (size == 0) return NULL ;
  8017aa:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8017ae:	75 07                	jne    8017b7 <smalloc+0x1e>
  8017b0:	b8 00 00 00 00       	mov    $0x0,%eax
  8017b5:	eb 14                	jmp    8017cb <smalloc+0x32>
	//==============================================================

	//TODO: [PROJECT'25.IM#3] SHARED MEMORY - #2 smalloc
	//Your code is here
	//Comment the following line
	panic("smalloc() is not implemented yet...!!");
  8017b7:	83 ec 04             	sub    $0x4,%esp
  8017ba:	68 fc 2a 80 00       	push   $0x802afc
  8017bf:	6a 5a                	push   $0x5a
  8017c1:	68 64 2a 80 00       	push   $0x802a64
  8017c6:	e8 3c 08 00 00       	call   802007 <_panic>
}
  8017cb:	c9                   	leave  
  8017cc:	c3                   	ret    

008017cd <sget>:

//========================================
// [4] SHARE ON ALLOCATED SHARED VARIABLE:
//========================================
void* sget(int32 ownerEnvID, char *sharedVarName)
{
  8017cd:	55                   	push   %ebp
  8017ce:	89 e5                	mov    %esp,%ebp
  8017d0:	83 ec 08             	sub    $0x8,%esp
	//==============================================================
	//DON'T CHANGE THIS CODE========================================
	uheap_init();
  8017d3:	e8 9c fe ff ff       	call   801674 <uheap_init>
	//==============================================================

	//TODO: [PROJECT'25.IM#3] SHARED MEMORY - #4 sget
	//Your code is here
	//Comment the following line
	panic("sget() is not implemented yet...!!");
  8017d8:	83 ec 04             	sub    $0x4,%esp
  8017db:	68 24 2b 80 00       	push   $0x802b24
  8017e0:	6a 6a                	push   $0x6a
  8017e2:	68 64 2a 80 00       	push   $0x802a64
  8017e7:	e8 1b 08 00 00       	call   802007 <_panic>

008017ec <realloc>:
//  Hint: you may need to use the sys_move_user_mem(...)
//		which switches to the kernel mode, calls move_user_mem(...)
//		in "kern/mem/chunk_operations.c", then switch back to the user mode here
//	the move_user_mem() function is empty, make sure to implement it.
void *realloc(void *virtual_address, uint32 new_size)
{
  8017ec:	55                   	push   %ebp
  8017ed:	89 e5                	mov    %esp,%ebp
  8017ef:	83 ec 08             	sub    $0x8,%esp
	//==============================================================
	//DON'T CHANGE THIS CODE========================================
	uheap_init();
  8017f2:	e8 7d fe ff ff       	call   801674 <uheap_init>
	//==============================================================
	panic("realloc() is not implemented yet...!!");
  8017f7:	83 ec 04             	sub    $0x4,%esp
  8017fa:	68 48 2b 80 00       	push   $0x802b48
  8017ff:	68 88 00 00 00       	push   $0x88
  801804:	68 64 2a 80 00       	push   $0x802a64
  801809:	e8 f9 07 00 00       	call   802007 <_panic>

0080180e <sfree>:
//
//	use sys_delete_shared_object(...); which switches to the kernel mode,
//	calls delete_shared_object(...) in "shared_memory_manager.c", then switch back to the user mode here
//	the delete_shared_object() function is empty, make sure to implement it.
void sfree(void* virtual_address)
{
  80180e:	55                   	push   %ebp
  80180f:	89 e5                	mov    %esp,%ebp
  801811:	83 ec 08             	sub    $0x8,%esp
	//TODO: [PROJECT'25.BONUS#5] EXIT #2 - sfree
	//Your code is here
	//Comment the following line
	panic("sfree() is not implemented yet...!!");
  801814:	83 ec 04             	sub    $0x4,%esp
  801817:	68 70 2b 80 00       	push   $0x802b70
  80181c:	68 9b 00 00 00       	push   $0x9b
  801821:	68 64 2a 80 00       	push   $0x802a64
  801826:	e8 dc 07 00 00       	call   802007 <_panic>

0080182b <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline uint32
syscall(int num, uint32 a1, uint32 a2, uint32 a3, uint32 a4, uint32 a5)
{
  80182b:	55                   	push   %ebp
  80182c:	89 e5                	mov    %esp,%ebp
  80182e:	57                   	push   %edi
  80182f:	56                   	push   %esi
  801830:	53                   	push   %ebx
  801831:	83 ec 10             	sub    $0x10,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  801834:	8b 45 08             	mov    0x8(%ebp),%eax
  801837:	8b 55 0c             	mov    0xc(%ebp),%edx
  80183a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80183d:	8b 5d 14             	mov    0x14(%ebp),%ebx
  801840:	8b 7d 18             	mov    0x18(%ebp),%edi
  801843:	8b 75 1c             	mov    0x1c(%ebp),%esi
  801846:	cd 30                	int    $0x30
  801848:	89 45 f0             	mov    %eax,-0x10(%ebp)
				"b" (a3),
				"D" (a4),
				"S" (a5)
				: "cc", "memory");

	return ret;
  80184b:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  80184e:	83 c4 10             	add    $0x10,%esp
  801851:	5b                   	pop    %ebx
  801852:	5e                   	pop    %esi
  801853:	5f                   	pop    %edi
  801854:	5d                   	pop    %ebp
  801855:	c3                   	ret    

00801856 <sys_cputs>:

void
sys_cputs(const char *s, uint32 len, uint8 printProgName, int color)
{
  801856:	55                   	push   %ebp
  801857:	89 e5                	mov    %esp,%ebp
  801859:	83 ec 04             	sub    $0x4,%esp
  80185c:	8b 45 10             	mov    0x10(%ebp),%eax
  80185f:	88 45 fc             	mov    %al,-0x4(%ebp)
	syscall(SYS_cputs, (uint32) s, len, (uint32)printProgName, color, 0);
  801862:	8b 4d 14             	mov    0x14(%ebp),%ecx
  801865:	0f b6 55 fc          	movzbl -0x4(%ebp),%edx
  801869:	8b 45 08             	mov    0x8(%ebp),%eax
  80186c:	6a 00                	push   $0x0
  80186e:	51                   	push   %ecx
  80186f:	52                   	push   %edx
  801870:	ff 75 0c             	pushl  0xc(%ebp)
  801873:	50                   	push   %eax
  801874:	6a 00                	push   $0x0
  801876:	e8 b0 ff ff ff       	call   80182b <syscall>
  80187b:	83 c4 18             	add    $0x18,%esp
}
  80187e:	90                   	nop
  80187f:	c9                   	leave  
  801880:	c3                   	ret    

00801881 <sys_cgetc>:

int
sys_cgetc(void)
{
  801881:	55                   	push   %ebp
  801882:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0);
  801884:	6a 00                	push   $0x0
  801886:	6a 00                	push   $0x0
  801888:	6a 00                	push   $0x0
  80188a:	6a 00                	push   $0x0
  80188c:	6a 00                	push   $0x0
  80188e:	6a 02                	push   $0x2
  801890:	e8 96 ff ff ff       	call   80182b <syscall>
  801895:	83 c4 18             	add    $0x18,%esp
}
  801898:	c9                   	leave  
  801899:	c3                   	ret    

0080189a <sys_lock_cons>:

void sys_lock_cons(void)
{
  80189a:	55                   	push   %ebp
  80189b:	89 e5                	mov    %esp,%ebp
	syscall(SYS_lock_cons, 0, 0, 0, 0, 0);
  80189d:	6a 00                	push   $0x0
  80189f:	6a 00                	push   $0x0
  8018a1:	6a 00                	push   $0x0
  8018a3:	6a 00                	push   $0x0
  8018a5:	6a 00                	push   $0x0
  8018a7:	6a 03                	push   $0x3
  8018a9:	e8 7d ff ff ff       	call   80182b <syscall>
  8018ae:	83 c4 18             	add    $0x18,%esp
}
  8018b1:	90                   	nop
  8018b2:	c9                   	leave  
  8018b3:	c3                   	ret    

008018b4 <sys_unlock_cons>:
void sys_unlock_cons(void)
{
  8018b4:	55                   	push   %ebp
  8018b5:	89 e5                	mov    %esp,%ebp
	syscall(SYS_unlock_cons, 0, 0, 0, 0, 0);
  8018b7:	6a 00                	push   $0x0
  8018b9:	6a 00                	push   $0x0
  8018bb:	6a 00                	push   $0x0
  8018bd:	6a 00                	push   $0x0
  8018bf:	6a 00                	push   $0x0
  8018c1:	6a 04                	push   $0x4
  8018c3:	e8 63 ff ff ff       	call   80182b <syscall>
  8018c8:	83 c4 18             	add    $0x18,%esp
}
  8018cb:	90                   	nop
  8018cc:	c9                   	leave  
  8018cd:	c3                   	ret    

008018ce <__sys_allocate_page>:

int __sys_allocate_page(void *va, int perm)
{
  8018ce:	55                   	push   %ebp
  8018cf:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_allocate_page, (uint32) va, perm, 0 , 0, 0);
  8018d1:	8b 55 0c             	mov    0xc(%ebp),%edx
  8018d4:	8b 45 08             	mov    0x8(%ebp),%eax
  8018d7:	6a 00                	push   $0x0
  8018d9:	6a 00                	push   $0x0
  8018db:	6a 00                	push   $0x0
  8018dd:	52                   	push   %edx
  8018de:	50                   	push   %eax
  8018df:	6a 08                	push   $0x8
  8018e1:	e8 45 ff ff ff       	call   80182b <syscall>
  8018e6:	83 c4 18             	add    $0x18,%esp
}
  8018e9:	c9                   	leave  
  8018ea:	c3                   	ret    

008018eb <__sys_map_frame>:

int __sys_map_frame(int32 srcenv, void *srcva, int32 dstenv, void *dstva, int perm)
{
  8018eb:	55                   	push   %ebp
  8018ec:	89 e5                	mov    %esp,%ebp
  8018ee:	56                   	push   %esi
  8018ef:	53                   	push   %ebx
	return syscall(SYS_map_frame, srcenv, (uint32) srcva, dstenv, (uint32) dstva, perm);
  8018f0:	8b 75 18             	mov    0x18(%ebp),%esi
  8018f3:	8b 5d 14             	mov    0x14(%ebp),%ebx
  8018f6:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8018f9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8018fc:	8b 45 08             	mov    0x8(%ebp),%eax
  8018ff:	56                   	push   %esi
  801900:	53                   	push   %ebx
  801901:	51                   	push   %ecx
  801902:	52                   	push   %edx
  801903:	50                   	push   %eax
  801904:	6a 09                	push   $0x9
  801906:	e8 20 ff ff ff       	call   80182b <syscall>
  80190b:	83 c4 18             	add    $0x18,%esp
}
  80190e:	8d 65 f8             	lea    -0x8(%ebp),%esp
  801911:	5b                   	pop    %ebx
  801912:	5e                   	pop    %esi
  801913:	5d                   	pop    %ebp
  801914:	c3                   	ret    

00801915 <__sys_unmap_frame>:

int __sys_unmap_frame(uint32 va)
{
  801915:	55                   	push   %ebp
  801916:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_unmap_frame, va, 0, 0, 0, 0);
  801918:	6a 00                	push   $0x0
  80191a:	6a 00                	push   $0x0
  80191c:	6a 00                	push   $0x0
  80191e:	6a 00                	push   $0x0
  801920:	ff 75 08             	pushl  0x8(%ebp)
  801923:	6a 0a                	push   $0xa
  801925:	e8 01 ff ff ff       	call   80182b <syscall>
  80192a:	83 c4 18             	add    $0x18,%esp
}
  80192d:	c9                   	leave  
  80192e:	c3                   	ret    

0080192f <sys_calculate_required_frames>:

uint32 sys_calculate_required_frames(uint32 start_virtual_address, uint32 size)
{
  80192f:	55                   	push   %ebp
  801930:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_calc_req_frames, start_virtual_address, (uint32) size, 0, 0, 0);
  801932:	6a 00                	push   $0x0
  801934:	6a 00                	push   $0x0
  801936:	6a 00                	push   $0x0
  801938:	ff 75 0c             	pushl  0xc(%ebp)
  80193b:	ff 75 08             	pushl  0x8(%ebp)
  80193e:	6a 0b                	push   $0xb
  801940:	e8 e6 fe ff ff       	call   80182b <syscall>
  801945:	83 c4 18             	add    $0x18,%esp
}
  801948:	c9                   	leave  
  801949:	c3                   	ret    

0080194a <sys_calculate_free_frames>:

uint32 sys_calculate_free_frames()
{
  80194a:	55                   	push   %ebp
  80194b:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_calc_free_frames, 0, 0, 0, 0, 0);
  80194d:	6a 00                	push   $0x0
  80194f:	6a 00                	push   $0x0
  801951:	6a 00                	push   $0x0
  801953:	6a 00                	push   $0x0
  801955:	6a 00                	push   $0x0
  801957:	6a 0c                	push   $0xc
  801959:	e8 cd fe ff ff       	call   80182b <syscall>
  80195e:	83 c4 18             	add    $0x18,%esp
}
  801961:	c9                   	leave  
  801962:	c3                   	ret    

00801963 <sys_calculate_modified_frames>:
uint32 sys_calculate_modified_frames()
{
  801963:	55                   	push   %ebp
  801964:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_calc_modified_frames, 0, 0, 0, 0, 0);
  801966:	6a 00                	push   $0x0
  801968:	6a 00                	push   $0x0
  80196a:	6a 00                	push   $0x0
  80196c:	6a 00                	push   $0x0
  80196e:	6a 00                	push   $0x0
  801970:	6a 0d                	push   $0xd
  801972:	e8 b4 fe ff ff       	call   80182b <syscall>
  801977:	83 c4 18             	add    $0x18,%esp
}
  80197a:	c9                   	leave  
  80197b:	c3                   	ret    

0080197c <sys_calculate_notmod_frames>:

uint32 sys_calculate_notmod_frames()
{
  80197c:	55                   	push   %ebp
  80197d:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_calc_notmod_frames, 0, 0, 0, 0, 0);
  80197f:	6a 00                	push   $0x0
  801981:	6a 00                	push   $0x0
  801983:	6a 00                	push   $0x0
  801985:	6a 00                	push   $0x0
  801987:	6a 00                	push   $0x0
  801989:	6a 0e                	push   $0xe
  80198b:	e8 9b fe ff ff       	call   80182b <syscall>
  801990:	83 c4 18             	add    $0x18,%esp
}
  801993:	c9                   	leave  
  801994:	c3                   	ret    

00801995 <sys_pf_calculate_allocated_pages>:

int sys_pf_calculate_allocated_pages()
{
  801995:	55                   	push   %ebp
  801996:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_pf_calc_allocated_pages, 0,0,0,0,0);
  801998:	6a 00                	push   $0x0
  80199a:	6a 00                	push   $0x0
  80199c:	6a 00                	push   $0x0
  80199e:	6a 00                	push   $0x0
  8019a0:	6a 00                	push   $0x0
  8019a2:	6a 0f                	push   $0xf
  8019a4:	e8 82 fe ff ff       	call   80182b <syscall>
  8019a9:	83 c4 18             	add    $0x18,%esp
}
  8019ac:	c9                   	leave  
  8019ad:	c3                   	ret    

008019ae <sys_calculate_pages_tobe_removed_ready_exit>:

int sys_calculate_pages_tobe_removed_ready_exit(uint32 WS_or_MEMORY_flag)
{
  8019ae:	55                   	push   %ebp
  8019af:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_calculate_pages_tobe_removed_ready_exit, WS_or_MEMORY_flag,0,0,0,0);
  8019b1:	6a 00                	push   $0x0
  8019b3:	6a 00                	push   $0x0
  8019b5:	6a 00                	push   $0x0
  8019b7:	6a 00                	push   $0x0
  8019b9:	ff 75 08             	pushl  0x8(%ebp)
  8019bc:	6a 10                	push   $0x10
  8019be:	e8 68 fe ff ff       	call   80182b <syscall>
  8019c3:	83 c4 18             	add    $0x18,%esp
}
  8019c6:	c9                   	leave  
  8019c7:	c3                   	ret    

008019c8 <sys_scarce_memory>:

void sys_scarce_memory()
{
  8019c8:	55                   	push   %ebp
  8019c9:	89 e5                	mov    %esp,%ebp
	syscall(SYS_scarce_memory,0,0,0,0,0);
  8019cb:	6a 00                	push   $0x0
  8019cd:	6a 00                	push   $0x0
  8019cf:	6a 00                	push   $0x0
  8019d1:	6a 00                	push   $0x0
  8019d3:	6a 00                	push   $0x0
  8019d5:	6a 11                	push   $0x11
  8019d7:	e8 4f fe ff ff       	call   80182b <syscall>
  8019dc:	83 c4 18             	add    $0x18,%esp
}
  8019df:	90                   	nop
  8019e0:	c9                   	leave  
  8019e1:	c3                   	ret    

008019e2 <sys_cputc>:

void
sys_cputc(const char c)
{
  8019e2:	55                   	push   %ebp
  8019e3:	89 e5                	mov    %esp,%ebp
  8019e5:	83 ec 04             	sub    $0x4,%esp
  8019e8:	8b 45 08             	mov    0x8(%ebp),%eax
  8019eb:	88 45 fc             	mov    %al,-0x4(%ebp)
	syscall(SYS_cputc, (uint32) c, 0, 0, 0, 0);
  8019ee:	0f be 45 fc          	movsbl -0x4(%ebp),%eax
  8019f2:	6a 00                	push   $0x0
  8019f4:	6a 00                	push   $0x0
  8019f6:	6a 00                	push   $0x0
  8019f8:	6a 00                	push   $0x0
  8019fa:	50                   	push   %eax
  8019fb:	6a 01                	push   $0x1
  8019fd:	e8 29 fe ff ff       	call   80182b <syscall>
  801a02:	83 c4 18             	add    $0x18,%esp
}
  801a05:	90                   	nop
  801a06:	c9                   	leave  
  801a07:	c3                   	ret    

00801a08 <sys_clear_ffl>:


//NEW'12: BONUS2 Testing
void
sys_clear_ffl()
{
  801a08:	55                   	push   %ebp
  801a09:	89 e5                	mov    %esp,%ebp
	syscall(SYS_clearFFL,0, 0, 0, 0, 0);
  801a0b:	6a 00                	push   $0x0
  801a0d:	6a 00                	push   $0x0
  801a0f:	6a 00                	push   $0x0
  801a11:	6a 00                	push   $0x0
  801a13:	6a 00                	push   $0x0
  801a15:	6a 14                	push   $0x14
  801a17:	e8 0f fe ff ff       	call   80182b <syscall>
  801a1c:	83 c4 18             	add    $0x18,%esp
}
  801a1f:	90                   	nop
  801a20:	c9                   	leave  
  801a21:	c3                   	ret    

00801a22 <sys_create_shared_object>:

int sys_create_shared_object(char* shareName, uint32 size, uint8 isWritable, void* virtual_address)
{
  801a22:	55                   	push   %ebp
  801a23:	89 e5                	mov    %esp,%ebp
  801a25:	83 ec 04             	sub    $0x4,%esp
  801a28:	8b 45 10             	mov    0x10(%ebp),%eax
  801a2b:	88 45 fc             	mov    %al,-0x4(%ebp)
	return syscall(SYS_create_shared_object,(uint32)shareName, (uint32)size, isWritable, (uint32)virtual_address,  0);
  801a2e:	8b 4d 14             	mov    0x14(%ebp),%ecx
  801a31:	0f b6 55 fc          	movzbl -0x4(%ebp),%edx
  801a35:	8b 45 08             	mov    0x8(%ebp),%eax
  801a38:	6a 00                	push   $0x0
  801a3a:	51                   	push   %ecx
  801a3b:	52                   	push   %edx
  801a3c:	ff 75 0c             	pushl  0xc(%ebp)
  801a3f:	50                   	push   %eax
  801a40:	6a 15                	push   $0x15
  801a42:	e8 e4 fd ff ff       	call   80182b <syscall>
  801a47:	83 c4 18             	add    $0x18,%esp
}
  801a4a:	c9                   	leave  
  801a4b:	c3                   	ret    

00801a4c <sys_size_of_shared_object>:

//2017:
int sys_size_of_shared_object(int32 ownerID, char* shareName)
{
  801a4c:	55                   	push   %ebp
  801a4d:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_get_size_of_shared_object,(uint32) ownerID, (uint32)shareName, 0, 0, 0);
  801a4f:	8b 55 0c             	mov    0xc(%ebp),%edx
  801a52:	8b 45 08             	mov    0x8(%ebp),%eax
  801a55:	6a 00                	push   $0x0
  801a57:	6a 00                	push   $0x0
  801a59:	6a 00                	push   $0x0
  801a5b:	52                   	push   %edx
  801a5c:	50                   	push   %eax
  801a5d:	6a 16                	push   $0x16
  801a5f:	e8 c7 fd ff ff       	call   80182b <syscall>
  801a64:	83 c4 18             	add    $0x18,%esp
}
  801a67:	c9                   	leave  
  801a68:	c3                   	ret    

00801a69 <sys_get_shared_object>:
//==========

int sys_get_shared_object(int32 ownerID, char* shareName, void* virtual_address)
{
  801a69:	55                   	push   %ebp
  801a6a:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_get_shared_object,(uint32) ownerID, (uint32)shareName, (uint32)virtual_address, 0, 0);
  801a6c:	8b 4d 10             	mov    0x10(%ebp),%ecx
  801a6f:	8b 55 0c             	mov    0xc(%ebp),%edx
  801a72:	8b 45 08             	mov    0x8(%ebp),%eax
  801a75:	6a 00                	push   $0x0
  801a77:	6a 00                	push   $0x0
  801a79:	51                   	push   %ecx
  801a7a:	52                   	push   %edx
  801a7b:	50                   	push   %eax
  801a7c:	6a 17                	push   $0x17
  801a7e:	e8 a8 fd ff ff       	call   80182b <syscall>
  801a83:	83 c4 18             	add    $0x18,%esp
}
  801a86:	c9                   	leave  
  801a87:	c3                   	ret    

00801a88 <sys_delete_shared_object>:

int sys_delete_shared_object(int32 sharedObjectID, void *startVA)
{
  801a88:	55                   	push   %ebp
  801a89:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_free_shared_object,(uint32) sharedObjectID, (uint32) startVA, 0, 0, 0);
  801a8b:	8b 55 0c             	mov    0xc(%ebp),%edx
  801a8e:	8b 45 08             	mov    0x8(%ebp),%eax
  801a91:	6a 00                	push   $0x0
  801a93:	6a 00                	push   $0x0
  801a95:	6a 00                	push   $0x0
  801a97:	52                   	push   %edx
  801a98:	50                   	push   %eax
  801a99:	6a 18                	push   $0x18
  801a9b:	e8 8b fd ff ff       	call   80182b <syscall>
  801aa0:	83 c4 18             	add    $0x18,%esp
}
  801aa3:	c9                   	leave  
  801aa4:	c3                   	ret    

00801aa5 <sys_create_env>:

int sys_create_env(char* programName, unsigned int page_WS_size,unsigned int LRU_second_list_size,unsigned int percent_WS_pages_to_remove)
{
  801aa5:	55                   	push   %ebp
  801aa6:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_create_env,(uint32)programName, (uint32)page_WS_size,(uint32)LRU_second_list_size, (uint32)percent_WS_pages_to_remove, 0);
  801aa8:	8b 45 08             	mov    0x8(%ebp),%eax
  801aab:	6a 00                	push   $0x0
  801aad:	ff 75 14             	pushl  0x14(%ebp)
  801ab0:	ff 75 10             	pushl  0x10(%ebp)
  801ab3:	ff 75 0c             	pushl  0xc(%ebp)
  801ab6:	50                   	push   %eax
  801ab7:	6a 19                	push   $0x19
  801ab9:	e8 6d fd ff ff       	call   80182b <syscall>
  801abe:	83 c4 18             	add    $0x18,%esp
}
  801ac1:	c9                   	leave  
  801ac2:	c3                   	ret    

00801ac3 <sys_run_env>:

void sys_run_env(int32 envId)
{
  801ac3:	55                   	push   %ebp
  801ac4:	89 e5                	mov    %esp,%ebp
	syscall(SYS_run_env, (int32)envId, 0, 0, 0, 0);
  801ac6:	8b 45 08             	mov    0x8(%ebp),%eax
  801ac9:	6a 00                	push   $0x0
  801acb:	6a 00                	push   $0x0
  801acd:	6a 00                	push   $0x0
  801acf:	6a 00                	push   $0x0
  801ad1:	50                   	push   %eax
  801ad2:	6a 1a                	push   $0x1a
  801ad4:	e8 52 fd ff ff       	call   80182b <syscall>
  801ad9:	83 c4 18             	add    $0x18,%esp
}
  801adc:	90                   	nop
  801add:	c9                   	leave  
  801ade:	c3                   	ret    

00801adf <sys_destroy_env>:

int sys_destroy_env(int32  envid)
{
  801adf:	55                   	push   %ebp
  801ae0:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_destroy_env, envid, 0, 0, 0, 0);
  801ae2:	8b 45 08             	mov    0x8(%ebp),%eax
  801ae5:	6a 00                	push   $0x0
  801ae7:	6a 00                	push   $0x0
  801ae9:	6a 00                	push   $0x0
  801aeb:	6a 00                	push   $0x0
  801aed:	50                   	push   %eax
  801aee:	6a 1b                	push   $0x1b
  801af0:	e8 36 fd ff ff       	call   80182b <syscall>
  801af5:	83 c4 18             	add    $0x18,%esp
}
  801af8:	c9                   	leave  
  801af9:	c3                   	ret    

00801afa <sys_getenvid>:

int32 sys_getenvid(void)
{
  801afa:	55                   	push   %ebp
  801afb:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_getenvid, 0, 0, 0, 0, 0);
  801afd:	6a 00                	push   $0x0
  801aff:	6a 00                	push   $0x0
  801b01:	6a 00                	push   $0x0
  801b03:	6a 00                	push   $0x0
  801b05:	6a 00                	push   $0x0
  801b07:	6a 05                	push   $0x5
  801b09:	e8 1d fd ff ff       	call   80182b <syscall>
  801b0e:	83 c4 18             	add    $0x18,%esp
}
  801b11:	c9                   	leave  
  801b12:	c3                   	ret    

00801b13 <sys_getenvindex>:

//2017
int32 sys_getenvindex(void)
{
  801b13:	55                   	push   %ebp
  801b14:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_getenvindex, 0, 0, 0, 0, 0);
  801b16:	6a 00                	push   $0x0
  801b18:	6a 00                	push   $0x0
  801b1a:	6a 00                	push   $0x0
  801b1c:	6a 00                	push   $0x0
  801b1e:	6a 00                	push   $0x0
  801b20:	6a 06                	push   $0x6
  801b22:	e8 04 fd ff ff       	call   80182b <syscall>
  801b27:	83 c4 18             	add    $0x18,%esp
}
  801b2a:	c9                   	leave  
  801b2b:	c3                   	ret    

00801b2c <sys_getparentenvid>:

int32 sys_getparentenvid(void)
{
  801b2c:	55                   	push   %ebp
  801b2d:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_getparentenvid, 0, 0, 0, 0, 0);
  801b2f:	6a 00                	push   $0x0
  801b31:	6a 00                	push   $0x0
  801b33:	6a 00                	push   $0x0
  801b35:	6a 00                	push   $0x0
  801b37:	6a 00                	push   $0x0
  801b39:	6a 07                	push   $0x7
  801b3b:	e8 eb fc ff ff       	call   80182b <syscall>
  801b40:	83 c4 18             	add    $0x18,%esp
}
  801b43:	c9                   	leave  
  801b44:	c3                   	ret    

00801b45 <sys_exit_env>:


void sys_exit_env(void)
{
  801b45:	55                   	push   %ebp
  801b46:	89 e5                	mov    %esp,%ebp
	syscall(SYS_exit_env, 0, 0, 0, 0, 0);
  801b48:	6a 00                	push   $0x0
  801b4a:	6a 00                	push   $0x0
  801b4c:	6a 00                	push   $0x0
  801b4e:	6a 00                	push   $0x0
  801b50:	6a 00                	push   $0x0
  801b52:	6a 1c                	push   $0x1c
  801b54:	e8 d2 fc ff ff       	call   80182b <syscall>
  801b59:	83 c4 18             	add    $0x18,%esp
}
  801b5c:	90                   	nop
  801b5d:	c9                   	leave  
  801b5e:	c3                   	ret    

00801b5f <sys_get_virtual_time>:


struct uint64 sys_get_virtual_time()
{
  801b5f:	55                   	push   %ebp
  801b60:	89 e5                	mov    %esp,%ebp
  801b62:	83 ec 10             	sub    $0x10,%esp
	struct uint64 result;
	syscall(SYS_get_virtual_time, (uint32)&(result.low), (uint32)&(result.hi), 0, 0, 0);
  801b65:	8d 45 f8             	lea    -0x8(%ebp),%eax
  801b68:	8d 50 04             	lea    0x4(%eax),%edx
  801b6b:	8d 45 f8             	lea    -0x8(%ebp),%eax
  801b6e:	6a 00                	push   $0x0
  801b70:	6a 00                	push   $0x0
  801b72:	6a 00                	push   $0x0
  801b74:	52                   	push   %edx
  801b75:	50                   	push   %eax
  801b76:	6a 1d                	push   $0x1d
  801b78:	e8 ae fc ff ff       	call   80182b <syscall>
  801b7d:	83 c4 18             	add    $0x18,%esp
	return result;
  801b80:	8b 4d 08             	mov    0x8(%ebp),%ecx
  801b83:	8b 45 f8             	mov    -0x8(%ebp),%eax
  801b86:	8b 55 fc             	mov    -0x4(%ebp),%edx
  801b89:	89 01                	mov    %eax,(%ecx)
  801b8b:	89 51 04             	mov    %edx,0x4(%ecx)
}
  801b8e:	8b 45 08             	mov    0x8(%ebp),%eax
  801b91:	c9                   	leave  
  801b92:	c2 04 00             	ret    $0x4

00801b95 <sys_move_user_mem>:

// 2014
void sys_move_user_mem(uint32 src_virtual_address, uint32 dst_virtual_address, uint32 size)
{
  801b95:	55                   	push   %ebp
  801b96:	89 e5                	mov    %esp,%ebp
	syscall(SYS_move_user_mem, src_virtual_address, dst_virtual_address, size, 0, 0);
  801b98:	6a 00                	push   $0x0
  801b9a:	6a 00                	push   $0x0
  801b9c:	ff 75 10             	pushl  0x10(%ebp)
  801b9f:	ff 75 0c             	pushl  0xc(%ebp)
  801ba2:	ff 75 08             	pushl  0x8(%ebp)
  801ba5:	6a 13                	push   $0x13
  801ba7:	e8 7f fc ff ff       	call   80182b <syscall>
  801bac:	83 c4 18             	add    $0x18,%esp
	return ;
  801baf:	90                   	nop
}
  801bb0:	c9                   	leave  
  801bb1:	c3                   	ret    

00801bb2 <sys_rcr2>:
uint32 sys_rcr2()
{
  801bb2:	55                   	push   %ebp
  801bb3:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_rcr2, 0, 0, 0, 0, 0);
  801bb5:	6a 00                	push   $0x0
  801bb7:	6a 00                	push   $0x0
  801bb9:	6a 00                	push   $0x0
  801bbb:	6a 00                	push   $0x0
  801bbd:	6a 00                	push   $0x0
  801bbf:	6a 1e                	push   $0x1e
  801bc1:	e8 65 fc ff ff       	call   80182b <syscall>
  801bc6:	83 c4 18             	add    $0x18,%esp
}
  801bc9:	c9                   	leave  
  801bca:	c3                   	ret    

00801bcb <sys_bypassPageFault>:

void sys_bypassPageFault(uint8 instrLength)
{
  801bcb:	55                   	push   %ebp
  801bcc:	89 e5                	mov    %esp,%ebp
  801bce:	83 ec 04             	sub    $0x4,%esp
  801bd1:	8b 45 08             	mov    0x8(%ebp),%eax
  801bd4:	88 45 fc             	mov    %al,-0x4(%ebp)
	syscall(SYS_bypassPageFault, instrLength, 0, 0, 0, 0);
  801bd7:	0f b6 45 fc          	movzbl -0x4(%ebp),%eax
  801bdb:	6a 00                	push   $0x0
  801bdd:	6a 00                	push   $0x0
  801bdf:	6a 00                	push   $0x0
  801be1:	6a 00                	push   $0x0
  801be3:	50                   	push   %eax
  801be4:	6a 1f                	push   $0x1f
  801be6:	e8 40 fc ff ff       	call   80182b <syscall>
  801beb:	83 c4 18             	add    $0x18,%esp
	return ;
  801bee:	90                   	nop
}
  801bef:	c9                   	leave  
  801bf0:	c3                   	ret    

00801bf1 <rsttst>:
void rsttst()
{
  801bf1:	55                   	push   %ebp
  801bf2:	89 e5                	mov    %esp,%ebp
	syscall(SYS_rsttst, 0, 0, 0, 0, 0);
  801bf4:	6a 00                	push   $0x0
  801bf6:	6a 00                	push   $0x0
  801bf8:	6a 00                	push   $0x0
  801bfa:	6a 00                	push   $0x0
  801bfc:	6a 00                	push   $0x0
  801bfe:	6a 21                	push   $0x21
  801c00:	e8 26 fc ff ff       	call   80182b <syscall>
  801c05:	83 c4 18             	add    $0x18,%esp
	return ;
  801c08:	90                   	nop
}
  801c09:	c9                   	leave  
  801c0a:	c3                   	ret    

00801c0b <tst>:
void tst(uint32 n, uint32 v1, uint32 v2, char c, int inv)
{
  801c0b:	55                   	push   %ebp
  801c0c:	89 e5                	mov    %esp,%ebp
  801c0e:	83 ec 04             	sub    $0x4,%esp
  801c11:	8b 45 14             	mov    0x14(%ebp),%eax
  801c14:	88 45 fc             	mov    %al,-0x4(%ebp)
	syscall(SYS_testNum, n, v1, v2, c, inv);
  801c17:	8b 55 18             	mov    0x18(%ebp),%edx
  801c1a:	0f be 45 fc          	movsbl -0x4(%ebp),%eax
  801c1e:	52                   	push   %edx
  801c1f:	50                   	push   %eax
  801c20:	ff 75 10             	pushl  0x10(%ebp)
  801c23:	ff 75 0c             	pushl  0xc(%ebp)
  801c26:	ff 75 08             	pushl  0x8(%ebp)
  801c29:	6a 20                	push   $0x20
  801c2b:	e8 fb fb ff ff       	call   80182b <syscall>
  801c30:	83 c4 18             	add    $0x18,%esp
	return ;
  801c33:	90                   	nop
}
  801c34:	c9                   	leave  
  801c35:	c3                   	ret    

00801c36 <chktst>:
void chktst(uint32 n)
{
  801c36:	55                   	push   %ebp
  801c37:	89 e5                	mov    %esp,%ebp
	syscall(SYS_chktst, n, 0, 0, 0, 0);
  801c39:	6a 00                	push   $0x0
  801c3b:	6a 00                	push   $0x0
  801c3d:	6a 00                	push   $0x0
  801c3f:	6a 00                	push   $0x0
  801c41:	ff 75 08             	pushl  0x8(%ebp)
  801c44:	6a 22                	push   $0x22
  801c46:	e8 e0 fb ff ff       	call   80182b <syscall>
  801c4b:	83 c4 18             	add    $0x18,%esp
	return ;
  801c4e:	90                   	nop
}
  801c4f:	c9                   	leave  
  801c50:	c3                   	ret    

00801c51 <inctst>:

void inctst()
{
  801c51:	55                   	push   %ebp
  801c52:	89 e5                	mov    %esp,%ebp
	syscall(SYS_inctst, 0, 0, 0, 0, 0);
  801c54:	6a 00                	push   $0x0
  801c56:	6a 00                	push   $0x0
  801c58:	6a 00                	push   $0x0
  801c5a:	6a 00                	push   $0x0
  801c5c:	6a 00                	push   $0x0
  801c5e:	6a 23                	push   $0x23
  801c60:	e8 c6 fb ff ff       	call   80182b <syscall>
  801c65:	83 c4 18             	add    $0x18,%esp
	return ;
  801c68:	90                   	nop
}
  801c69:	c9                   	leave  
  801c6a:	c3                   	ret    

00801c6b <gettst>:
uint32 gettst()
{
  801c6b:	55                   	push   %ebp
  801c6c:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_gettst, 0, 0, 0, 0, 0);
  801c6e:	6a 00                	push   $0x0
  801c70:	6a 00                	push   $0x0
  801c72:	6a 00                	push   $0x0
  801c74:	6a 00                	push   $0x0
  801c76:	6a 00                	push   $0x0
  801c78:	6a 24                	push   $0x24
  801c7a:	e8 ac fb ff ff       	call   80182b <syscall>
  801c7f:	83 c4 18             	add    $0x18,%esp
}
  801c82:	c9                   	leave  
  801c83:	c3                   	ret    

00801c84 <sys_get_uheap_strategy>:

/*2025*/
uint32 sys_get_uheap_strategy()
{
  801c84:	55                   	push   %ebp
  801c85:	89 e5                	mov    %esp,%ebp
	uheapPlaceStrategy = syscall(SYS_get_heap_strategy, 0, 0, 0, 0, 0);
  801c87:	6a 00                	push   $0x0
  801c89:	6a 00                	push   $0x0
  801c8b:	6a 00                	push   $0x0
  801c8d:	6a 00                	push   $0x0
  801c8f:	6a 00                	push   $0x0
  801c91:	6a 25                	push   $0x25
  801c93:	e8 93 fb ff ff       	call   80182b <syscall>
  801c98:	83 c4 18             	add    $0x18,%esp
  801c9b:	a3 60 b0 81 00       	mov    %eax,0x81b060
	return uheapPlaceStrategy ;
  801ca0:	a1 60 b0 81 00       	mov    0x81b060,%eax
}
  801ca5:	c9                   	leave  
  801ca6:	c3                   	ret    

00801ca7 <sys_set_uheap_strategy>:

void sys_set_uheap_strategy(uint32 heapStrategy)
{
  801ca7:	55                   	push   %ebp
  801ca8:	89 e5                	mov    %esp,%ebp
	uheapPlaceStrategy = heapStrategy;
  801caa:	8b 45 08             	mov    0x8(%ebp),%eax
  801cad:	a3 60 b0 81 00       	mov    %eax,0x81b060
	syscall(SYS_set_heap_strategy, heapStrategy, 0, 0, 0, 0);
  801cb2:	6a 00                	push   $0x0
  801cb4:	6a 00                	push   $0x0
  801cb6:	6a 00                	push   $0x0
  801cb8:	6a 00                	push   $0x0
  801cba:	ff 75 08             	pushl  0x8(%ebp)
  801cbd:	6a 26                	push   $0x26
  801cbf:	e8 67 fb ff ff       	call   80182b <syscall>
  801cc4:	83 c4 18             	add    $0x18,%esp
	return ;
  801cc7:	90                   	nop
}
  801cc8:	c9                   	leave  
  801cc9:	c3                   	ret    

00801cca <sys_check_LRU_lists>:

//2020
int sys_check_LRU_lists(uint32* active_list_content, uint32* second_list_content, int actual_active_list_size, int actual_second_list_size)
{
  801cca:	55                   	push   %ebp
  801ccb:	89 e5                	mov    %esp,%ebp
  801ccd:	53                   	push   %ebx
	return syscall(SYS_check_LRU_lists, (uint32)active_list_content, (uint32)second_list_content, (uint32)actual_active_list_size, (uint32)actual_second_list_size, 0);
  801cce:	8b 5d 14             	mov    0x14(%ebp),%ebx
  801cd1:	8b 4d 10             	mov    0x10(%ebp),%ecx
  801cd4:	8b 55 0c             	mov    0xc(%ebp),%edx
  801cd7:	8b 45 08             	mov    0x8(%ebp),%eax
  801cda:	6a 00                	push   $0x0
  801cdc:	53                   	push   %ebx
  801cdd:	51                   	push   %ecx
  801cde:	52                   	push   %edx
  801cdf:	50                   	push   %eax
  801ce0:	6a 27                	push   $0x27
  801ce2:	e8 44 fb ff ff       	call   80182b <syscall>
  801ce7:	83 c4 18             	add    $0x18,%esp
}
  801cea:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  801ced:	c9                   	leave  
  801cee:	c3                   	ret    

00801cef <sys_check_LRU_lists_free>:

int sys_check_LRU_lists_free(uint32* list_content, int list_size)
{
  801cef:	55                   	push   %ebp
  801cf0:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_check_LRU_lists_free, (uint32)list_content, (uint32)list_size , 0, 0, 0);
  801cf2:	8b 55 0c             	mov    0xc(%ebp),%edx
  801cf5:	8b 45 08             	mov    0x8(%ebp),%eax
  801cf8:	6a 00                	push   $0x0
  801cfa:	6a 00                	push   $0x0
  801cfc:	6a 00                	push   $0x0
  801cfe:	52                   	push   %edx
  801cff:	50                   	push   %eax
  801d00:	6a 28                	push   $0x28
  801d02:	e8 24 fb ff ff       	call   80182b <syscall>
  801d07:	83 c4 18             	add    $0x18,%esp
}
  801d0a:	c9                   	leave  
  801d0b:	c3                   	ret    

00801d0c <sys_check_WS_list>:

int sys_check_WS_list(uint32* WS_list_content, int actual_WS_list_size, uint32 last_WS_element_content, bool chk_in_order)
{
  801d0c:	55                   	push   %ebp
  801d0d:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_check_WS_list, (uint32)WS_list_content, (uint32)actual_WS_list_size , last_WS_element_content, (uint32)chk_in_order, 0);
  801d0f:	8b 4d 14             	mov    0x14(%ebp),%ecx
  801d12:	8b 55 0c             	mov    0xc(%ebp),%edx
  801d15:	8b 45 08             	mov    0x8(%ebp),%eax
  801d18:	6a 00                	push   $0x0
  801d1a:	51                   	push   %ecx
  801d1b:	ff 75 10             	pushl  0x10(%ebp)
  801d1e:	52                   	push   %edx
  801d1f:	50                   	push   %eax
  801d20:	6a 29                	push   $0x29
  801d22:	e8 04 fb ff ff       	call   80182b <syscall>
  801d27:	83 c4 18             	add    $0x18,%esp
}
  801d2a:	c9                   	leave  
  801d2b:	c3                   	ret    

00801d2c <sys_allocate_chunk>:
void sys_allocate_chunk(uint32 virtual_address, uint32 size, uint32 perms)
{
  801d2c:	55                   	push   %ebp
  801d2d:	89 e5                	mov    %esp,%ebp
	syscall(SYS_allocate_chunk_in_mem, virtual_address, size, perms, 0, 0);
  801d2f:	6a 00                	push   $0x0
  801d31:	6a 00                	push   $0x0
  801d33:	ff 75 10             	pushl  0x10(%ebp)
  801d36:	ff 75 0c             	pushl  0xc(%ebp)
  801d39:	ff 75 08             	pushl  0x8(%ebp)
  801d3c:	6a 12                	push   $0x12
  801d3e:	e8 e8 fa ff ff       	call   80182b <syscall>
  801d43:	83 c4 18             	add    $0x18,%esp
	return ;
  801d46:	90                   	nop
}
  801d47:	c9                   	leave  
  801d48:	c3                   	ret    

00801d49 <sys_utilities>:
void sys_utilities(char* utilityName, int value)
{
  801d49:	55                   	push   %ebp
  801d4a:	89 e5                	mov    %esp,%ebp
	syscall(SYS_utilities, (uint32)utilityName, value, 0, 0, 0);
  801d4c:	8b 55 0c             	mov    0xc(%ebp),%edx
  801d4f:	8b 45 08             	mov    0x8(%ebp),%eax
  801d52:	6a 00                	push   $0x0
  801d54:	6a 00                	push   $0x0
  801d56:	6a 00                	push   $0x0
  801d58:	52                   	push   %edx
  801d59:	50                   	push   %eax
  801d5a:	6a 2a                	push   $0x2a
  801d5c:	e8 ca fa ff ff       	call   80182b <syscall>
  801d61:	83 c4 18             	add    $0x18,%esp
	return;
  801d64:	90                   	nop
}
  801d65:	c9                   	leave  
  801d66:	c3                   	ret    

00801d67 <sys_get_optimal_num_faults>:
/*2025*/
int sys_get_optimal_num_faults()
{
  801d67:	55                   	push   %ebp
  801d68:	89 e5                	mov    %esp,%ebp
	return syscall(SYS_get_optimal_num_faults, 0, 0, 0, 0, 0);
  801d6a:	6a 00                	push   $0x0
  801d6c:	6a 00                	push   $0x0
  801d6e:	6a 00                	push   $0x0
  801d70:	6a 00                	push   $0x0
  801d72:	6a 00                	push   $0x0
  801d74:	6a 2b                	push   $0x2b
  801d76:	e8 b0 fa ff ff       	call   80182b <syscall>
  801d7b:	83 c4 18             	add    $0x18,%esp
}
  801d7e:	c9                   	leave  
  801d7f:	c3                   	ret    

00801d80 <sys_free_user_mem>:

void sys_free_user_mem(uint32 virtual_address, uint32 size)
{
  801d80:	55                   	push   %ebp
  801d81:	89 e5                	mov    %esp,%ebp
	syscall(SYS_free_user_mem, virtual_address, size, 0, 0, 0);
  801d83:	6a 00                	push   $0x0
  801d85:	6a 00                	push   $0x0
  801d87:	6a 00                	push   $0x0
  801d89:	ff 75 0c             	pushl  0xc(%ebp)
  801d8c:	ff 75 08             	pushl  0x8(%ebp)
  801d8f:	6a 2d                	push   $0x2d
  801d91:	e8 95 fa ff ff       	call   80182b <syscall>
  801d96:	83 c4 18             	add    $0x18,%esp
	return;
  801d99:	90                   	nop
}
  801d9a:	c9                   	leave  
  801d9b:	c3                   	ret    

00801d9c <sys_allocate_user_mem>:

void sys_allocate_user_mem(uint32 virtual_address, uint32 size)
{
  801d9c:	55                   	push   %ebp
  801d9d:	89 e5                	mov    %esp,%ebp
	syscall(SYS_allocate_user_mem, virtual_address, size, 0, 0, 0);
  801d9f:	6a 00                	push   $0x0
  801da1:	6a 00                	push   $0x0
  801da3:	6a 00                	push   $0x0
  801da5:	ff 75 0c             	pushl  0xc(%ebp)
  801da8:	ff 75 08             	pushl  0x8(%ebp)
  801dab:	6a 2c                	push   $0x2c
  801dad:	e8 79 fa ff ff       	call   80182b <syscall>
  801db2:	83 c4 18             	add    $0x18,%esp
	return ;
  801db5:	90                   	nop
}
  801db6:	c9                   	leave  
  801db7:	c3                   	ret    

00801db8 <sys_env_set_priority>:


void sys_env_set_priority(int32 envID, int priority)
{
  801db8:	55                   	push   %ebp
  801db9:	89 e5                	mov    %esp,%ebp
  801dbb:	83 ec 08             	sub    $0x8,%esp
	//TODO: [PROJECT'25.IM#4] CPU SCHEDULING - #1 System Calls - Add suitable code here
	//Your code is here
	//Comment the following line
	panic("sys_env_set_priority() is not implemented yet...!!");
  801dbe:	83 ec 04             	sub    $0x4,%esp
  801dc1:	68 94 2b 80 00       	push   $0x802b94
  801dc6:	68 25 01 00 00       	push   $0x125
  801dcb:	68 c7 2b 80 00       	push   $0x802bc7
  801dd0:	e8 32 02 00 00       	call   802007 <_panic>

00801dd5 <to_page_va>:
//==================================
//==================================
// [1] GET PAGE VA:
//==================================
__inline__ uint32 to_page_va(struct PageInfoElement *ptrPageInfo)
{
  801dd5:	55                   	push   %ebp
  801dd6:	89 e5                	mov    %esp,%ebp
  801dd8:	83 ec 18             	sub    $0x18,%esp
	if (ptrPageInfo < &pageBlockInfoArr[0] || ptrPageInfo >= &pageBlockInfoArr[DYN_ALLOC_MAX_SIZE/PAGE_SIZE])
  801ddb:	81 7d 08 60 30 80 00 	cmpl   $0x803060,0x8(%ebp)
  801de2:	72 09                	jb     801ded <to_page_va+0x18>
  801de4:	81 7d 08 60 b0 81 00 	cmpl   $0x81b060,0x8(%ebp)
  801deb:	72 14                	jb     801e01 <to_page_va+0x2c>
			panic("to_page_va called with invalid pageInfoPtr");
  801ded:	83 ec 04             	sub    $0x4,%esp
  801df0:	68 d8 2b 80 00       	push   $0x802bd8
  801df5:	6a 15                	push   $0x15
  801df7:	68 03 2c 80 00       	push   $0x802c03
  801dfc:	e8 06 02 00 00       	call   802007 <_panic>
	//Get start VA of the page from the corresponding Page Info pointer
	int idxInPageInfoArr = (ptrPageInfo - pageBlockInfoArr);
  801e01:	8b 45 08             	mov    0x8(%ebp),%eax
  801e04:	ba 60 30 80 00       	mov    $0x803060,%edx
  801e09:	29 d0                	sub    %edx,%eax
  801e0b:	c1 f8 02             	sar    $0x2,%eax
  801e0e:	89 c2                	mov    %eax,%edx
  801e10:	89 d0                	mov    %edx,%eax
  801e12:	c1 e0 02             	shl    $0x2,%eax
  801e15:	01 d0                	add    %edx,%eax
  801e17:	c1 e0 02             	shl    $0x2,%eax
  801e1a:	01 d0                	add    %edx,%eax
  801e1c:	c1 e0 02             	shl    $0x2,%eax
  801e1f:	01 d0                	add    %edx,%eax
  801e21:	89 c1                	mov    %eax,%ecx
  801e23:	c1 e1 08             	shl    $0x8,%ecx
  801e26:	01 c8                	add    %ecx,%eax
  801e28:	89 c1                	mov    %eax,%ecx
  801e2a:	c1 e1 10             	shl    $0x10,%ecx
  801e2d:	01 c8                	add    %ecx,%eax
  801e2f:	01 c0                	add    %eax,%eax
  801e31:	01 d0                	add    %edx,%eax
  801e33:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return dynAllocStart + (idxInPageInfoArr << PGSHIFT);
  801e36:	8b 45 f4             	mov    -0xc(%ebp),%eax
  801e39:	c1 e0 0c             	shl    $0xc,%eax
  801e3c:	89 c2                	mov    %eax,%edx
  801e3e:	a1 64 b0 81 00       	mov    0x81b064,%eax
  801e43:	01 d0                	add    %edx,%eax
}
  801e45:	c9                   	leave  
  801e46:	c3                   	ret    

00801e47 <to_page_info>:

//==================================
// [2] GET PAGE INFO OF PAGE VA:
//==================================
__inline__ struct PageInfoElement * to_page_info(uint32 va)
{
  801e47:	55                   	push   %ebp
  801e48:	89 e5                	mov    %esp,%ebp
  801e4a:	83 ec 18             	sub    $0x18,%esp
	int idxInPageInfoArr = (va - dynAllocStart) >> PGSHIFT;
  801e4d:	a1 64 b0 81 00       	mov    0x81b064,%eax
  801e52:	8b 55 08             	mov    0x8(%ebp),%edx
  801e55:	29 c2                	sub    %eax,%edx
  801e57:	89 d0                	mov    %edx,%eax
  801e59:	c1 e8 0c             	shr    $0xc,%eax
  801e5c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (idxInPageInfoArr < 0 || idxInPageInfoArr >= DYN_ALLOC_MAX_SIZE/PAGE_SIZE)
  801e5f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  801e63:	78 09                	js     801e6e <to_page_info+0x27>
  801e65:	81 7d f4 ff 1f 00 00 	cmpl   $0x1fff,-0xc(%ebp)
  801e6c:	7e 14                	jle    801e82 <to_page_info+0x3b>
		panic("to_page_info called with invalid pa");
  801e6e:	83 ec 04             	sub    $0x4,%esp
  801e71:	68 1c 2c 80 00       	push   $0x802c1c
  801e76:	6a 22                	push   $0x22
  801e78:	68 03 2c 80 00       	push   $0x802c03
  801e7d:	e8 85 01 00 00       	call   802007 <_panic>
	return &pageBlockInfoArr[idxInPageInfoArr];
  801e82:	8b 55 f4             	mov    -0xc(%ebp),%edx
  801e85:	89 d0                	mov    %edx,%eax
  801e87:	01 c0                	add    %eax,%eax
  801e89:	01 d0                	add    %edx,%eax
  801e8b:	c1 e0 02             	shl    $0x2,%eax
  801e8e:	05 60 30 80 00       	add    $0x803060,%eax
}
  801e93:	c9                   	leave  
  801e94:	c3                   	ret    

00801e95 <initialize_dynamic_allocator>:
//==================================
// [1] INITIALIZE DYNAMIC ALLOCATOR:
//==================================
bool is_initialized = 0;
void initialize_dynamic_allocator(uint32 daStart, uint32 daEnd)
{
  801e95:	55                   	push   %ebp
  801e96:	89 e5                	mov    %esp,%ebp
  801e98:	83 ec 08             	sub    $0x8,%esp
	//==================================================================================
	//DON'T CHANGE THESE LINES==========================================================
	//==================================================================================
	{
		assert(daEnd <= daStart + DYN_ALLOC_MAX_SIZE);
  801e9b:	8b 45 08             	mov    0x8(%ebp),%eax
  801e9e:	05 00 00 00 02       	add    $0x2000000,%eax
  801ea3:	3b 45 0c             	cmp    0xc(%ebp),%eax
  801ea6:	73 16                	jae    801ebe <initialize_dynamic_allocator+0x29>
  801ea8:	68 40 2c 80 00       	push   $0x802c40
  801ead:	68 66 2c 80 00       	push   $0x802c66
  801eb2:	6a 34                	push   $0x34
  801eb4:	68 03 2c 80 00       	push   $0x802c03
  801eb9:	e8 49 01 00 00       	call   802007 <_panic>
		is_initialized = 1;
  801ebe:	c7 05 24 30 80 00 01 	movl   $0x1,0x803024
  801ec5:	00 00 00 
	//==================================================================================
	//==================================================================================
	//TODO: [PROJECT'25.GM#1] DYNAMIC ALLOCATOR - #1 initialize_dynamic_allocator
	//Your code is here
	//Comment the following line
	panic("initialize_dynamic_allocator() Not implemented yet");
  801ec8:	83 ec 04             	sub    $0x4,%esp
  801ecb:	68 7c 2c 80 00       	push   $0x802c7c
  801ed0:	6a 3c                	push   $0x3c
  801ed2:	68 03 2c 80 00       	push   $0x802c03
  801ed7:	e8 2b 01 00 00       	call   802007 <_panic>

00801edc <get_block_size>:

//===========================
// [2] GET BLOCK SIZE:
//===========================
__inline__ uint32 get_block_size(void *va)
{
  801edc:	55                   	push   %ebp
  801edd:	89 e5                	mov    %esp,%ebp
  801edf:	83 ec 08             	sub    $0x8,%esp
	//TODO: [PROJECT'25.GM#1] DYNAMIC ALLOCATOR - #2 get_block_size
	//Your code is here
	//Comment the following line
	panic("get_block_size() Not implemented yet");
  801ee2:	83 ec 04             	sub    $0x4,%esp
  801ee5:	68 b0 2c 80 00       	push   $0x802cb0
  801eea:	6a 48                	push   $0x48
  801eec:	68 03 2c 80 00       	push   $0x802c03
  801ef1:	e8 11 01 00 00       	call   802007 <_panic>

00801ef6 <alloc_block>:

//===========================
// 3) ALLOCATE BLOCK:
//===========================
void *alloc_block(uint32 size)
{
  801ef6:	55                   	push   %ebp
  801ef7:	89 e5                	mov    %esp,%ebp
  801ef9:	83 ec 08             	sub    $0x8,%esp
	//==================================================================================
	//DON'T CHANGE THESE LINES==========================================================
	//==================================================================================
	{
		assert(size <= DYN_ALLOC_MAX_BLOCK_SIZE);
  801efc:	81 7d 08 00 08 00 00 	cmpl   $0x800,0x8(%ebp)
  801f03:	76 16                	jbe    801f1b <alloc_block+0x25>
  801f05:	68 d8 2c 80 00       	push   $0x802cd8
  801f0a:	68 66 2c 80 00       	push   $0x802c66
  801f0f:	6a 54                	push   $0x54
  801f11:	68 03 2c 80 00       	push   $0x802c03
  801f16:	e8 ec 00 00 00       	call   802007 <_panic>
	//==================================================================================
	//==================================================================================
	//TODO: [PROJECT'25.GM#1] DYNAMIC ALLOCATOR - #3 alloc_block
	//Your code is here
	//Comment the following line
	panic("alloc_block() Not implemented yet");
  801f1b:	83 ec 04             	sub    $0x4,%esp
  801f1e:	68 fc 2c 80 00       	push   $0x802cfc
  801f23:	6a 5b                	push   $0x5b
  801f25:	68 03 2c 80 00       	push   $0x802c03
  801f2a:	e8 d8 00 00 00       	call   802007 <_panic>

00801f2f <free_block>:

//===========================
// [4] FREE BLOCK:
//===========================
void free_block(void *va)
{
  801f2f:	55                   	push   %ebp
  801f30:	89 e5                	mov    %esp,%ebp
  801f32:	83 ec 08             	sub    $0x8,%esp
	//==================================================================================
	//DON'T CHANGE THESE LINES==========================================================
	//==================================================================================
	{
		assert((uint32)va >= dynAllocStart && (uint32)va < dynAllocEnd);
  801f35:	8b 55 08             	mov    0x8(%ebp),%edx
  801f38:	a1 64 b0 81 00       	mov    0x81b064,%eax
  801f3d:	39 c2                	cmp    %eax,%edx
  801f3f:	72 0c                	jb     801f4d <free_block+0x1e>
  801f41:	8b 55 08             	mov    0x8(%ebp),%edx
  801f44:	a1 40 30 80 00       	mov    0x803040,%eax
  801f49:	39 c2                	cmp    %eax,%edx
  801f4b:	72 16                	jb     801f63 <free_block+0x34>
  801f4d:	68 20 2d 80 00       	push   $0x802d20
  801f52:	68 66 2c 80 00       	push   $0x802c66
  801f57:	6a 69                	push   $0x69
  801f59:	68 03 2c 80 00       	push   $0x802c03
  801f5e:	e8 a4 00 00 00       	call   802007 <_panic>
	//==================================================================================

	//TODO: [PROJECT'25.GM#1] DYNAMIC ALLOCATOR - #4 free_block
	//Your code is here
	//Comment the following line
	panic("free_block() Not implemented yet");
  801f63:	83 ec 04             	sub    $0x4,%esp
  801f66:	68 58 2d 80 00       	push   $0x802d58
  801f6b:	6a 71                	push   $0x71
  801f6d:	68 03 2c 80 00       	push   $0x802c03
  801f72:	e8 90 00 00 00       	call   802007 <_panic>

00801f77 <realloc_block>:

//===========================
// [1] REALLOCATE BLOCK:
//===========================
void *realloc_block(void* va, uint32 new_size)
{
  801f77:	55                   	push   %ebp
  801f78:	89 e5                	mov    %esp,%ebp
  801f7a:	83 ec 08             	sub    $0x8,%esp
	//TODO: [PROJECT'25.BONUS#2] KERNEL REALLOC - realloc_block
	//Your code is here
	//Comment the following line
	panic("realloc_block() Not implemented yet");
  801f7d:	83 ec 04             	sub    $0x4,%esp
  801f80:	68 7c 2d 80 00       	push   $0x802d7c
  801f85:	68 80 00 00 00       	push   $0x80
  801f8a:	68 03 2c 80 00       	push   $0x802c03
  801f8f:	e8 73 00 00 00       	call   802007 <_panic>

00801f94 <create_semaphore>:
// User-level Semaphore

#include "inc/lib.h"

struct semaphore create_semaphore(char *semaphoreName, uint32 value)
{
  801f94:	55                   	push   %ebp
  801f95:	89 e5                	mov    %esp,%ebp
  801f97:	83 ec 08             	sub    $0x8,%esp
	panic("create_semaphore() is not implemented yet...!!");
  801f9a:	83 ec 04             	sub    $0x4,%esp
  801f9d:	68 a0 2d 80 00       	push   $0x802da0
  801fa2:	6a 07                	push   $0x7
  801fa4:	68 cf 2d 80 00       	push   $0x802dcf
  801fa9:	e8 59 00 00 00       	call   802007 <_panic>

00801fae <get_semaphore>:
}
struct semaphore get_semaphore(int32 ownerEnvID, char* semaphoreName)
{
  801fae:	55                   	push   %ebp
  801faf:	89 e5                	mov    %esp,%ebp
  801fb1:	83 ec 08             	sub    $0x8,%esp
	panic("get_semaphore() is not implemented yet...!!");
  801fb4:	83 ec 04             	sub    $0x4,%esp
  801fb7:	68 e0 2d 80 00       	push   $0x802de0
  801fbc:	6a 0b                	push   $0xb
  801fbe:	68 cf 2d 80 00       	push   $0x802dcf
  801fc3:	e8 3f 00 00 00       	call   802007 <_panic>

00801fc8 <wait_semaphore>:
}

void wait_semaphore(struct semaphore sem)
{
  801fc8:	55                   	push   %ebp
  801fc9:	89 e5                	mov    %esp,%ebp
  801fcb:	83 ec 08             	sub    $0x8,%esp
	panic("wait_semaphore() is not implemented yet...!!");
  801fce:	83 ec 04             	sub    $0x4,%esp
  801fd1:	68 0c 2e 80 00       	push   $0x802e0c
  801fd6:	6a 10                	push   $0x10
  801fd8:	68 cf 2d 80 00       	push   $0x802dcf
  801fdd:	e8 25 00 00 00       	call   802007 <_panic>

00801fe2 <signal_semaphore>:
}

void signal_semaphore(struct semaphore sem)
{
  801fe2:	55                   	push   %ebp
  801fe3:	89 e5                	mov    %esp,%ebp
  801fe5:	83 ec 08             	sub    $0x8,%esp
	panic("signal_semaphore() is not implemented yet...!!");
  801fe8:	83 ec 04             	sub    $0x4,%esp
  801feb:	68 3c 2e 80 00       	push   $0x802e3c
  801ff0:	6a 15                	push   $0x15
  801ff2:	68 cf 2d 80 00       	push   $0x802dcf
  801ff7:	e8 0b 00 00 00       	call   802007 <_panic>

00801ffc <semaphore_count>:
}

int semaphore_count(struct semaphore sem)
{
  801ffc:	55                   	push   %ebp
  801ffd:	89 e5                	mov    %esp,%ebp
	return sem.semdata->count;
  801fff:	8b 45 08             	mov    0x8(%ebp),%eax
  802002:	8b 40 10             	mov    0x10(%eax),%eax
}
  802005:	5d                   	pop    %ebp
  802006:	c3                   	ret    

00802007 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes FOS to enter the FOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
  802007:	55                   	push   %ebp
  802008:	89 e5                	mov    %esp,%ebp
  80200a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	va_start(ap, fmt);
  80200d:	8d 45 10             	lea    0x10(%ebp),%eax
  802010:	83 c0 04             	add    $0x4,%eax
  802013:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// Print the panic message
	if (argv0)
  802016:	a1 1c b1 81 00       	mov    0x81b11c,%eax
  80201b:	85 c0                	test   %eax,%eax
  80201d:	74 16                	je     802035 <_panic+0x2e>
		cprintf("%s: ", argv0);
  80201f:	a1 1c b1 81 00       	mov    0x81b11c,%eax
  802024:	83 ec 08             	sub    $0x8,%esp
  802027:	50                   	push   %eax
  802028:	68 6c 2e 80 00       	push   $0x802e6c
  80202d:	e8 5d e7 ff ff       	call   80078f <cprintf>
  802032:	83 c4 10             	add    $0x10,%esp
	cprintf_colored(TEXT_PANIC_CLR, "user [EVAL_FINAL]panic in %s at %s:%d: ", binaryname, file, line);
  802035:	a1 04 30 80 00       	mov    0x803004,%eax
  80203a:	83 ec 0c             	sub    $0xc,%esp
  80203d:	ff 75 0c             	pushl  0xc(%ebp)
  802040:	ff 75 08             	pushl  0x8(%ebp)
  802043:	50                   	push   %eax
  802044:	68 74 2e 80 00       	push   $0x802e74
  802049:	6a 74                	push   $0x74
  80204b:	e8 6c e7 ff ff       	call   8007bc <cprintf_colored>
  802050:	83 c4 20             	add    $0x20,%esp
	vcprintf(fmt, ap);
  802053:	8b 45 10             	mov    0x10(%ebp),%eax
  802056:	83 ec 08             	sub    $0x8,%esp
  802059:	ff 75 f4             	pushl  -0xc(%ebp)
  80205c:	50                   	push   %eax
  80205d:	e8 be e6 ff ff       	call   800720 <vcprintf>
  802062:	83 c4 10             	add    $0x10,%esp
	vcprintf("\n", NULL);
  802065:	83 ec 08             	sub    $0x8,%esp
  802068:	6a 00                	push   $0x0
  80206a:	68 9c 2e 80 00       	push   $0x802e9c
  80206f:	e8 ac e6 ff ff       	call   800720 <vcprintf>
  802074:	83 c4 10             	add    $0x10,%esp
	// Cause a breakpoint exception
//	while (1);
//		asm volatile("int3");

	//2013: exit the panic env only
	exit() ;
  802077:	e8 25 e6 ff ff       	call   8006a1 <exit>

	// should not return here
	while (1) ;
  80207c:	eb fe                	jmp    80207c <_panic+0x75>

0080207e <CheckWSArrayWithoutLastIndex>:
}

void CheckWSArrayWithoutLastIndex(uint32 *expectedPages, int arraySize)
{
  80207e:	55                   	push   %ebp
  80207f:	89 e5                	mov    %esp,%ebp
  802081:	83 ec 28             	sub    $0x28,%esp
	if (arraySize != myEnv->page_WS_max_size)
  802084:	a1 20 30 80 00       	mov    0x803020,%eax
  802089:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
  80208f:	8b 45 0c             	mov    0xc(%ebp),%eax
  802092:	39 c2                	cmp    %eax,%edx
  802094:	74 14                	je     8020aa <CheckWSArrayWithoutLastIndex+0x2c>
	{
		panic("number of expected pages SHOULD BE EQUAL to max WS size... review your TA!!");
  802096:	83 ec 04             	sub    $0x4,%esp
  802099:	68 a0 2e 80 00       	push   $0x802ea0
  80209e:	6a 26                	push   $0x26
  8020a0:	68 ec 2e 80 00       	push   $0x802eec
  8020a5:	e8 5d ff ff ff       	call   802007 <_panic>
	}
	int expectedNumOfEmptyLocs = 0;
  8020aa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (int e = 0; e < arraySize; e++) {
  8020b1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  8020b8:	e9 c5 00 00 00       	jmp    802182 <CheckWSArrayWithoutLastIndex+0x104>
		if (expectedPages[e] == 0) {
  8020bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  8020c0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  8020c7:	8b 45 08             	mov    0x8(%ebp),%eax
  8020ca:	01 d0                	add    %edx,%eax
  8020cc:	8b 00                	mov    (%eax),%eax
  8020ce:	85 c0                	test   %eax,%eax
  8020d0:	75 08                	jne    8020da <CheckWSArrayWithoutLastIndex+0x5c>
			expectedNumOfEmptyLocs++;
  8020d2:	ff 45 f4             	incl   -0xc(%ebp)
			continue;
  8020d5:	e9 a5 00 00 00       	jmp    80217f <CheckWSArrayWithoutLastIndex+0x101>
		}
		int found = 0;
  8020da:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
		for (int w = 0; w < myEnv->page_WS_max_size; w++) {
  8020e1:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  8020e8:	eb 69                	jmp    802153 <CheckWSArrayWithoutLastIndex+0xd5>
			if (myEnv->__uptr_pws[w].empty == 0) {
  8020ea:	a1 20 30 80 00       	mov    0x803020,%eax
  8020ef:	8b 88 90 05 00 00    	mov    0x590(%eax),%ecx
  8020f5:	8b 55 e8             	mov    -0x18(%ebp),%edx
  8020f8:	89 d0                	mov    %edx,%eax
  8020fa:	01 c0                	add    %eax,%eax
  8020fc:	01 d0                	add    %edx,%eax
  8020fe:	c1 e0 03             	shl    $0x3,%eax
  802101:	01 c8                	add    %ecx,%eax
  802103:	8a 40 04             	mov    0x4(%eax),%al
  802106:	84 c0                	test   %al,%al
  802108:	75 46                	jne    802150 <CheckWSArrayWithoutLastIndex+0xd2>
				if (ROUNDDOWN(myEnv->__uptr_pws[w].virtual_address, PAGE_SIZE)
  80210a:	a1 20 30 80 00       	mov    0x803020,%eax
  80210f:	8b 88 90 05 00 00    	mov    0x590(%eax),%ecx
  802115:	8b 55 e8             	mov    -0x18(%ebp),%edx
  802118:	89 d0                	mov    %edx,%eax
  80211a:	01 c0                	add    %eax,%eax
  80211c:	01 d0                	add    %edx,%eax
  80211e:	c1 e0 03             	shl    $0x3,%eax
  802121:	01 c8                	add    %ecx,%eax
  802123:	8b 00                	mov    (%eax),%eax
  802125:	89 45 dc             	mov    %eax,-0x24(%ebp)
  802128:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80212b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  802130:	89 c2                	mov    %eax,%edx
						== expectedPages[e]) {
  802132:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802135:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
  80213c:	8b 45 08             	mov    0x8(%ebp),%eax
  80213f:	01 c8                	add    %ecx,%eax
  802141:	8b 00                	mov    (%eax),%eax
			continue;
		}
		int found = 0;
		for (int w = 0; w < myEnv->page_WS_max_size; w++) {
			if (myEnv->__uptr_pws[w].empty == 0) {
				if (ROUNDDOWN(myEnv->__uptr_pws[w].virtual_address, PAGE_SIZE)
  802143:	39 c2                	cmp    %eax,%edx
  802145:	75 09                	jne    802150 <CheckWSArrayWithoutLastIndex+0xd2>
						== expectedPages[e]) {
					found = 1;
  802147:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
					break;
  80214e:	eb 15                	jmp    802165 <CheckWSArrayWithoutLastIndex+0xe7>
		if (expectedPages[e] == 0) {
			expectedNumOfEmptyLocs++;
			continue;
		}
		int found = 0;
		for (int w = 0; w < myEnv->page_WS_max_size; w++) {
  802150:	ff 45 e8             	incl   -0x18(%ebp)
  802153:	a1 20 30 80 00       	mov    0x803020,%eax
  802158:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
  80215e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  802161:	39 c2                	cmp    %eax,%edx
  802163:	77 85                	ja     8020ea <CheckWSArrayWithoutLastIndex+0x6c>
					found = 1;
					break;
				}
			}
		}
		if (!found)
  802165:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  802169:	75 14                	jne    80217f <CheckWSArrayWithoutLastIndex+0x101>
			panic(
  80216b:	83 ec 04             	sub    $0x4,%esp
  80216e:	68 f8 2e 80 00       	push   $0x802ef8
  802173:	6a 3a                	push   $0x3a
  802175:	68 ec 2e 80 00       	push   $0x802eec
  80217a:	e8 88 fe ff ff       	call   802007 <_panic>
	if (arraySize != myEnv->page_WS_max_size)
	{
		panic("number of expected pages SHOULD BE EQUAL to max WS size... review your TA!!");
	}
	int expectedNumOfEmptyLocs = 0;
	for (int e = 0; e < arraySize; e++) {
  80217f:	ff 45 f0             	incl   -0x10(%ebp)
  802182:	8b 45 f0             	mov    -0x10(%ebp),%eax
  802185:	3b 45 0c             	cmp    0xc(%ebp),%eax
  802188:	0f 8c 2f ff ff ff    	jl     8020bd <CheckWSArrayWithoutLastIndex+0x3f>
		}
		if (!found)
			panic(
					"PAGE WS entry checking failed... trace it by printing page WS before & after fault");
	}
	int actualNumOfEmptyLocs = 0;
  80218e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	for (int w = 0; w < myEnv->page_WS_max_size; w++) {
  802195:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  80219c:	eb 26                	jmp    8021c4 <CheckWSArrayWithoutLastIndex+0x146>
		if (myEnv->__uptr_pws[w].empty == 1) {
  80219e:	a1 20 30 80 00       	mov    0x803020,%eax
  8021a3:	8b 88 90 05 00 00    	mov    0x590(%eax),%ecx
  8021a9:	8b 55 e0             	mov    -0x20(%ebp),%edx
  8021ac:	89 d0                	mov    %edx,%eax
  8021ae:	01 c0                	add    %eax,%eax
  8021b0:	01 d0                	add    %edx,%eax
  8021b2:	c1 e0 03             	shl    $0x3,%eax
  8021b5:	01 c8                	add    %ecx,%eax
  8021b7:	8a 40 04             	mov    0x4(%eax),%al
  8021ba:	3c 01                	cmp    $0x1,%al
  8021bc:	75 03                	jne    8021c1 <CheckWSArrayWithoutLastIndex+0x143>
			actualNumOfEmptyLocs++;
  8021be:	ff 45 e4             	incl   -0x1c(%ebp)
		if (!found)
			panic(
					"PAGE WS entry checking failed... trace it by printing page WS before & after fault");
	}
	int actualNumOfEmptyLocs = 0;
	for (int w = 0; w < myEnv->page_WS_max_size; w++) {
  8021c1:	ff 45 e0             	incl   -0x20(%ebp)
  8021c4:	a1 20 30 80 00       	mov    0x803020,%eax
  8021c9:	8b 90 84 00 00 00    	mov    0x84(%eax),%edx
  8021cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8021d2:	39 c2                	cmp    %eax,%edx
  8021d4:	77 c8                	ja     80219e <CheckWSArrayWithoutLastIndex+0x120>
		if (myEnv->__uptr_pws[w].empty == 1) {
			actualNumOfEmptyLocs++;
		}
	}
	if (expectedNumOfEmptyLocs != actualNumOfEmptyLocs)
  8021d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8021d9:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  8021dc:	74 14                	je     8021f2 <CheckWSArrayWithoutLastIndex+0x174>
		panic(
  8021de:	83 ec 04             	sub    $0x4,%esp
  8021e1:	68 4c 2f 80 00       	push   $0x802f4c
  8021e6:	6a 44                	push   $0x44
  8021e8:	68 ec 2e 80 00       	push   $0x802eec
  8021ed:	e8 15 fe ff ff       	call   802007 <_panic>
				"PAGE WS entry checking failed... number of empty locations is not correct");
}
  8021f2:	90                   	nop
  8021f3:	c9                   	leave  
  8021f4:	c3                   	ret    
  8021f5:	66 90                	xchg   %ax,%ax
  8021f7:	90                   	nop

008021f8 <__udivdi3>:
  8021f8:	55                   	push   %ebp
  8021f9:	57                   	push   %edi
  8021fa:	56                   	push   %esi
  8021fb:	53                   	push   %ebx
  8021fc:	83 ec 1c             	sub    $0x1c,%esp
  8021ff:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  802203:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  802207:	8b 7c 24 38          	mov    0x38(%esp),%edi
  80220b:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  80220f:	89 ca                	mov    %ecx,%edx
  802211:	89 f8                	mov    %edi,%eax
  802213:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  802217:	85 f6                	test   %esi,%esi
  802219:	75 2d                	jne    802248 <__udivdi3+0x50>
  80221b:	39 cf                	cmp    %ecx,%edi
  80221d:	77 65                	ja     802284 <__udivdi3+0x8c>
  80221f:	89 fd                	mov    %edi,%ebp
  802221:	85 ff                	test   %edi,%edi
  802223:	75 0b                	jne    802230 <__udivdi3+0x38>
  802225:	b8 01 00 00 00       	mov    $0x1,%eax
  80222a:	31 d2                	xor    %edx,%edx
  80222c:	f7 f7                	div    %edi
  80222e:	89 c5                	mov    %eax,%ebp
  802230:	31 d2                	xor    %edx,%edx
  802232:	89 c8                	mov    %ecx,%eax
  802234:	f7 f5                	div    %ebp
  802236:	89 c1                	mov    %eax,%ecx
  802238:	89 d8                	mov    %ebx,%eax
  80223a:	f7 f5                	div    %ebp
  80223c:	89 cf                	mov    %ecx,%edi
  80223e:	89 fa                	mov    %edi,%edx
  802240:	83 c4 1c             	add    $0x1c,%esp
  802243:	5b                   	pop    %ebx
  802244:	5e                   	pop    %esi
  802245:	5f                   	pop    %edi
  802246:	5d                   	pop    %ebp
  802247:	c3                   	ret    
  802248:	39 ce                	cmp    %ecx,%esi
  80224a:	77 28                	ja     802274 <__udivdi3+0x7c>
  80224c:	0f bd fe             	bsr    %esi,%edi
  80224f:	83 f7 1f             	xor    $0x1f,%edi
  802252:	75 40                	jne    802294 <__udivdi3+0x9c>
  802254:	39 ce                	cmp    %ecx,%esi
  802256:	72 0a                	jb     802262 <__udivdi3+0x6a>
  802258:	3b 44 24 08          	cmp    0x8(%esp),%eax
  80225c:	0f 87 9e 00 00 00    	ja     802300 <__udivdi3+0x108>
  802262:	b8 01 00 00 00       	mov    $0x1,%eax
  802267:	89 fa                	mov    %edi,%edx
  802269:	83 c4 1c             	add    $0x1c,%esp
  80226c:	5b                   	pop    %ebx
  80226d:	5e                   	pop    %esi
  80226e:	5f                   	pop    %edi
  80226f:	5d                   	pop    %ebp
  802270:	c3                   	ret    
  802271:	8d 76 00             	lea    0x0(%esi),%esi
  802274:	31 ff                	xor    %edi,%edi
  802276:	31 c0                	xor    %eax,%eax
  802278:	89 fa                	mov    %edi,%edx
  80227a:	83 c4 1c             	add    $0x1c,%esp
  80227d:	5b                   	pop    %ebx
  80227e:	5e                   	pop    %esi
  80227f:	5f                   	pop    %edi
  802280:	5d                   	pop    %ebp
  802281:	c3                   	ret    
  802282:	66 90                	xchg   %ax,%ax
  802284:	89 d8                	mov    %ebx,%eax
  802286:	f7 f7                	div    %edi
  802288:	31 ff                	xor    %edi,%edi
  80228a:	89 fa                	mov    %edi,%edx
  80228c:	83 c4 1c             	add    $0x1c,%esp
  80228f:	5b                   	pop    %ebx
  802290:	5e                   	pop    %esi
  802291:	5f                   	pop    %edi
  802292:	5d                   	pop    %ebp
  802293:	c3                   	ret    
  802294:	bd 20 00 00 00       	mov    $0x20,%ebp
  802299:	89 eb                	mov    %ebp,%ebx
  80229b:	29 fb                	sub    %edi,%ebx
  80229d:	89 f9                	mov    %edi,%ecx
  80229f:	d3 e6                	shl    %cl,%esi
  8022a1:	89 c5                	mov    %eax,%ebp
  8022a3:	88 d9                	mov    %bl,%cl
  8022a5:	d3 ed                	shr    %cl,%ebp
  8022a7:	89 e9                	mov    %ebp,%ecx
  8022a9:	09 f1                	or     %esi,%ecx
  8022ab:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8022af:	89 f9                	mov    %edi,%ecx
  8022b1:	d3 e0                	shl    %cl,%eax
  8022b3:	89 c5                	mov    %eax,%ebp
  8022b5:	89 d6                	mov    %edx,%esi
  8022b7:	88 d9                	mov    %bl,%cl
  8022b9:	d3 ee                	shr    %cl,%esi
  8022bb:	89 f9                	mov    %edi,%ecx
  8022bd:	d3 e2                	shl    %cl,%edx
  8022bf:	8b 44 24 08          	mov    0x8(%esp),%eax
  8022c3:	88 d9                	mov    %bl,%cl
  8022c5:	d3 e8                	shr    %cl,%eax
  8022c7:	09 c2                	or     %eax,%edx
  8022c9:	89 d0                	mov    %edx,%eax
  8022cb:	89 f2                	mov    %esi,%edx
  8022cd:	f7 74 24 0c          	divl   0xc(%esp)
  8022d1:	89 d6                	mov    %edx,%esi
  8022d3:	89 c3                	mov    %eax,%ebx
  8022d5:	f7 e5                	mul    %ebp
  8022d7:	39 d6                	cmp    %edx,%esi
  8022d9:	72 19                	jb     8022f4 <__udivdi3+0xfc>
  8022db:	74 0b                	je     8022e8 <__udivdi3+0xf0>
  8022dd:	89 d8                	mov    %ebx,%eax
  8022df:	31 ff                	xor    %edi,%edi
  8022e1:	e9 58 ff ff ff       	jmp    80223e <__udivdi3+0x46>
  8022e6:	66 90                	xchg   %ax,%ax
  8022e8:	8b 54 24 08          	mov    0x8(%esp),%edx
  8022ec:	89 f9                	mov    %edi,%ecx
  8022ee:	d3 e2                	shl    %cl,%edx
  8022f0:	39 c2                	cmp    %eax,%edx
  8022f2:	73 e9                	jae    8022dd <__udivdi3+0xe5>
  8022f4:	8d 43 ff             	lea    -0x1(%ebx),%eax
  8022f7:	31 ff                	xor    %edi,%edi
  8022f9:	e9 40 ff ff ff       	jmp    80223e <__udivdi3+0x46>
  8022fe:	66 90                	xchg   %ax,%ax
  802300:	31 c0                	xor    %eax,%eax
  802302:	e9 37 ff ff ff       	jmp    80223e <__udivdi3+0x46>
  802307:	90                   	nop

00802308 <__umoddi3>:
  802308:	55                   	push   %ebp
  802309:	57                   	push   %edi
  80230a:	56                   	push   %esi
  80230b:	53                   	push   %ebx
  80230c:	83 ec 1c             	sub    $0x1c,%esp
  80230f:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  802313:	8b 74 24 34          	mov    0x34(%esp),%esi
  802317:	8b 7c 24 38          	mov    0x38(%esp),%edi
  80231b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  80231f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  802323:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  802327:	89 f3                	mov    %esi,%ebx
  802329:	89 fa                	mov    %edi,%edx
  80232b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80232f:	89 34 24             	mov    %esi,(%esp)
  802332:	85 c0                	test   %eax,%eax
  802334:	75 1a                	jne    802350 <__umoddi3+0x48>
  802336:	39 f7                	cmp    %esi,%edi
  802338:	0f 86 a2 00 00 00    	jbe    8023e0 <__umoddi3+0xd8>
  80233e:	89 c8                	mov    %ecx,%eax
  802340:	89 f2                	mov    %esi,%edx
  802342:	f7 f7                	div    %edi
  802344:	89 d0                	mov    %edx,%eax
  802346:	31 d2                	xor    %edx,%edx
  802348:	83 c4 1c             	add    $0x1c,%esp
  80234b:	5b                   	pop    %ebx
  80234c:	5e                   	pop    %esi
  80234d:	5f                   	pop    %edi
  80234e:	5d                   	pop    %ebp
  80234f:	c3                   	ret    
  802350:	39 f0                	cmp    %esi,%eax
  802352:	0f 87 ac 00 00 00    	ja     802404 <__umoddi3+0xfc>
  802358:	0f bd e8             	bsr    %eax,%ebp
  80235b:	83 f5 1f             	xor    $0x1f,%ebp
  80235e:	0f 84 ac 00 00 00    	je     802410 <__umoddi3+0x108>
  802364:	bf 20 00 00 00       	mov    $0x20,%edi
  802369:	29 ef                	sub    %ebp,%edi
  80236b:	89 fe                	mov    %edi,%esi
  80236d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  802371:	89 e9                	mov    %ebp,%ecx
  802373:	d3 e0                	shl    %cl,%eax
  802375:	89 d7                	mov    %edx,%edi
  802377:	89 f1                	mov    %esi,%ecx
  802379:	d3 ef                	shr    %cl,%edi
  80237b:	09 c7                	or     %eax,%edi
  80237d:	89 e9                	mov    %ebp,%ecx
  80237f:	d3 e2                	shl    %cl,%edx
  802381:	89 14 24             	mov    %edx,(%esp)
  802384:	89 d8                	mov    %ebx,%eax
  802386:	d3 e0                	shl    %cl,%eax
  802388:	89 c2                	mov    %eax,%edx
  80238a:	8b 44 24 08          	mov    0x8(%esp),%eax
  80238e:	d3 e0                	shl    %cl,%eax
  802390:	89 44 24 04          	mov    %eax,0x4(%esp)
  802394:	8b 44 24 08          	mov    0x8(%esp),%eax
  802398:	89 f1                	mov    %esi,%ecx
  80239a:	d3 e8                	shr    %cl,%eax
  80239c:	09 d0                	or     %edx,%eax
  80239e:	d3 eb                	shr    %cl,%ebx
  8023a0:	89 da                	mov    %ebx,%edx
  8023a2:	f7 f7                	div    %edi
  8023a4:	89 d3                	mov    %edx,%ebx
  8023a6:	f7 24 24             	mull   (%esp)
  8023a9:	89 c6                	mov    %eax,%esi
  8023ab:	89 d1                	mov    %edx,%ecx
  8023ad:	39 d3                	cmp    %edx,%ebx
  8023af:	0f 82 87 00 00 00    	jb     80243c <__umoddi3+0x134>
  8023b5:	0f 84 91 00 00 00    	je     80244c <__umoddi3+0x144>
  8023bb:	8b 54 24 04          	mov    0x4(%esp),%edx
  8023bf:	29 f2                	sub    %esi,%edx
  8023c1:	19 cb                	sbb    %ecx,%ebx
  8023c3:	89 d8                	mov    %ebx,%eax
  8023c5:	8a 4c 24 0c          	mov    0xc(%esp),%cl
  8023c9:	d3 e0                	shl    %cl,%eax
  8023cb:	89 e9                	mov    %ebp,%ecx
  8023cd:	d3 ea                	shr    %cl,%edx
  8023cf:	09 d0                	or     %edx,%eax
  8023d1:	89 e9                	mov    %ebp,%ecx
  8023d3:	d3 eb                	shr    %cl,%ebx
  8023d5:	89 da                	mov    %ebx,%edx
  8023d7:	83 c4 1c             	add    $0x1c,%esp
  8023da:	5b                   	pop    %ebx
  8023db:	5e                   	pop    %esi
  8023dc:	5f                   	pop    %edi
  8023dd:	5d                   	pop    %ebp
  8023de:	c3                   	ret    
  8023df:	90                   	nop
  8023e0:	89 fd                	mov    %edi,%ebp
  8023e2:	85 ff                	test   %edi,%edi
  8023e4:	75 0b                	jne    8023f1 <__umoddi3+0xe9>
  8023e6:	b8 01 00 00 00       	mov    $0x1,%eax
  8023eb:	31 d2                	xor    %edx,%edx
  8023ed:	f7 f7                	div    %edi
  8023ef:	89 c5                	mov    %eax,%ebp
  8023f1:	89 f0                	mov    %esi,%eax
  8023f3:	31 d2                	xor    %edx,%edx
  8023f5:	f7 f5                	div    %ebp
  8023f7:	89 c8                	mov    %ecx,%eax
  8023f9:	f7 f5                	div    %ebp
  8023fb:	89 d0                	mov    %edx,%eax
  8023fd:	e9 44 ff ff ff       	jmp    802346 <__umoddi3+0x3e>
  802402:	66 90                	xchg   %ax,%ax
  802404:	89 c8                	mov    %ecx,%eax
  802406:	89 f2                	mov    %esi,%edx
  802408:	83 c4 1c             	add    $0x1c,%esp
  80240b:	5b                   	pop    %ebx
  80240c:	5e                   	pop    %esi
  80240d:	5f                   	pop    %edi
  80240e:	5d                   	pop    %ebp
  80240f:	c3                   	ret    
  802410:	3b 04 24             	cmp    (%esp),%eax
  802413:	72 06                	jb     80241b <__umoddi3+0x113>
  802415:	3b 7c 24 04          	cmp    0x4(%esp),%edi
  802419:	77 0f                	ja     80242a <__umoddi3+0x122>
  80241b:	89 f2                	mov    %esi,%edx
  80241d:	29 f9                	sub    %edi,%ecx
  80241f:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  802423:	89 14 24             	mov    %edx,(%esp)
  802426:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80242a:	8b 44 24 04          	mov    0x4(%esp),%eax
  80242e:	8b 14 24             	mov    (%esp),%edx
  802431:	83 c4 1c             	add    $0x1c,%esp
  802434:	5b                   	pop    %ebx
  802435:	5e                   	pop    %esi
  802436:	5f                   	pop    %edi
  802437:	5d                   	pop    %ebp
  802438:	c3                   	ret    
  802439:	8d 76 00             	lea    0x0(%esi),%esi
  80243c:	2b 04 24             	sub    (%esp),%eax
  80243f:	19 fa                	sbb    %edi,%edx
  802441:	89 d1                	mov    %edx,%ecx
  802443:	89 c6                	mov    %eax,%esi
  802445:	e9 71 ff ff ff       	jmp    8023bb <__umoddi3+0xb3>
  80244a:	66 90                	xchg   %ax,%ax
  80244c:	39 44 24 04          	cmp    %eax,0x4(%esp)
  802450:	72 ea                	jb     80243c <__umoddi3+0x134>
  802452:	89 d9                	mov    %ebx,%ecx
  802454:	e9 62 ff ff ff       	jmp    8023bb <__umoddi3+0xb3>
