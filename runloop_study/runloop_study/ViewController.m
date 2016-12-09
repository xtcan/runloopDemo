//
//  ViewController.m
//  runloop_study
//
//  Created by tcan on 16/8/2.
//  Copyright © 2016年 tcan. All rights reserved.
//  RunLoop:运行循环
//
//  一、[基本作用]
//  保持程序的持续运行
//  处理App中的各种事件（比如触摸事件、定时器事件、Selector事件）
//  节省CPU资源，提高程序性能：该做事时做事，该休息时休息
//
//  二、[RunLoop与线程]
//  每条线程都有唯一的一个与之对应的RunLoop对象
//  主线程的RunLoop已经自动创建好了，子线程的RunLoop需要主动创建
//  RunLoop在第一次获取时创建，在线程结束时销毁
//
//  三、[RunLoop相关类(Core Foundation中)]
//  1、CFRunLoopRef:RunLoop的运行模式
//  一个 RunLoop 包含若干个 Mode，每个Mode又包含若干个Source/Timer/Observer
//  每次RunLoop启动时，只能指定其中一个 Mode(CurrentMode)
//  如果需要切换Mode，只能退出Loop，再重新指定一个Mode进入
//  这样做主要是为了分隔开不同组的Source/Timer/Observer，让其互不影响
//
//  2、CFRunLoopModeRef
//  系统默认注册了5个Mode:
//  kCFRunLoopDefaultMode：App的默认Mode，通常主线程是在这个Mode下运行
//  UITrackingRunLoopMode：界面跟踪 Mode，用于 ScrollView 追踪触摸滑动，保证界面滑动时不受其他 Mode 影响
//  UIInitializationRunLoopMode: 在刚启动 App 时第进入的第一个 Mode，启动完成后就不再使用
//  GSEventReceiveRunLoopMode: 接受系统事件的内部 Mode，通常用不到
//  kCFRunLoopCommonModes: 这是一个占位用的Mode，不是一种真正的Mode

//  3、CFRunLoopSourceRef：事件源（输入源）分为：
//  Source0：非基于Port的，用于用户主动触发的事件
//  Source1：基于Port的，通过内核和其它线程相互发送消息

//  4、CFRunLoopTimerRef：是基于时间的触发器
//  基本上说的就是NSTimer，它会受到runloop的mode的影响
//  GCD的定时器不受Runloop的mode的影响

//  5、CFRunLoopObserverRef：观察者，能够监听RunLoop的状态改变
//  即将进入Loop
//  即将处理Timer
//  即将处理Source
//  即将进入休眠
//  刚从休眠中唤醒
//  即将退出Loop

//  mode至少要有一个source或timer，不然runloop会自动退出

// 四、[RunLoop的应用]
// 1、NSTimer  2、ImageView显示  3、PerformSelector  4、常驻线程  5、自动释放池

#import "ViewController.h"
#import "AlwaysExistThread.h"


@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong) NSArray *title_array;//标题数组
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) dispatch_source_t gcd_Timer;
@property(nonatomic, strong) NSThread *thread;
@end

@implementation ViewController

/**
 *  标题数组
 */
- (NSArray *)title_array{
    
    if (_title_array == nil) {
        
        _title_array = [NSArray arrayWithObjects:
                        @"0.获取runloop",
                        @"1.NSTimer,NSDefaultRunLoopMode",
                        @"2.NSTimer,UITrackingRunLoopMode",
                        @"3.NSTimer,DefaultMode & TrackingMode",
                        @"4.NSTimer,NSRunLoopCommonModes",
                        @"5.gcd定时器",
                        @"6.CFRunLoopSourceRef",
                        @"7.CFRunLoopObserverRef",
                        @"8.创建常驻线程",
                        @"  在常驻线程上调用方法",
                        @"9.自动释放池",
                        @"10.performSelector,NSDefaultRunLoopMode",
                        nil];
    }
    return _title_array;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //设置界面
    [self setupView];
}

/**
 *  设置界面
 */
- (void)setupView{
    
    UITableView *tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    [self.view addSubview:tableView];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.title_array.count * 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString  *cellId = @"runloopCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    if (indexPath.row < self.title_array.count) {
        
         cell.textLabel.text = self.title_array[indexPath.row];
    }else{
        
        cell.textLabel.text = nil;
    }
   
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [self.timer invalidate];
    self.timer = nil;
    
    self.gcd_Timer = nil;
    
    NSInteger row = indexPath.row;
    
    NSLog(@"%@",self.title_array[row]);
    
    switch (row) {
        case 0:
            //获取runloop
            [self runloop];
            break;
        case 1:
            //NSTimer,NSDefaultRunLoopMode
            [self timerWithDefaultRunLoopMode];
            break;
        case 2:
            //NSTimer,UITrackingRunLoopMode
            [self timerWithTrackingRunLoopMode];
            break;
        case 3:
            //NSTimer,NSDefaultRunLoopMode,UITrackingRunLoopMode
            [self timerWithDefaultAndTrackingRunLoopMode];
            break;
        case 4:
            //NSTimer,NSRunLoopCommonModes
            [self timerWithCommonModes];
            break;
        case 5:
            //gcd定时器
            [self gcdTimer];
            break;
        case 6:
            //CFRunLoopSourceRef
            [self showCFRunLoopSourceRefMsg];
            break;
        case 7:
            //CFRunLoopObserverRef
            [self observer];
            break;
        case 8:
            //常驻线程
            [self alwaysExistThread];
            break;
        case 9:
            //在常驻线程调用方法
            [self useThread];
            break;
        case 10:
            //自动释放池什么时候被释放
            [self autoreleasepoolRelease];
            break;
        case 11:
            //performSelector,NSDefaultRunLoopMode
            [self performSelectorInMode];
            break;
            
        default:
            break;
    }
}

/**
 *  创建线程，获取RunLoop
 */
- (void)runloop{
    
    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(getRunLoop) object:nil];
    [thread start];
}

/**
 *  获取当前线程RunLoop及主线程RunLoop
 */
- (void)getRunLoop{
    
    //iOS中有2套API来访问和使用RunLoop

    //---------Foundation框架-NSRunLoop(是基于CFRunLoopRef的一层OC包装)-------//
    
    //获得当前线程对应的runloop
    NSRunLoop *currentRunLoop_OC = [NSRunLoop currentRunLoop];//currentRunLoop是懒加载的，没有runloop就会创建
    //获得主线程对应的runloop
    NSRunLoop *mainRunLoop_OC = [NSRunLoop mainRunLoop];
    
    
    //------------Core Foundation框架-CFRunLoopRef-----------//
    //获得当前线程对应的runloop
    CFRunLoopRef currentRunLoop_C = CFRunLoopGetCurrent();
    //获得主线程对应的runloop
    CFRunLoopRef mainRunLoop_C = CFRunLoopGetMain();
    
    NSLog(@"currentRunLoop_OC:%p--mainRunLoop_OC:%p--currentRunLoop_C:%p--mainRunLoop_C:%p",currentRunLoop_OC,mainRunLoop_OC,currentRunLoop_C,mainRunLoop_C);
}

/**
 *  默认模式，ScrollView滚动timer停止工作
 */
- (void)timerWithDefaultRunLoopMode{
    
    NSLog(@"tableview滚动timer停止工作（打印）");
    //创建NSTimer
    self.timer = [NSTimer timerWithTimeInterval:2.0f target:self selector:@selector(showMsg) userInfo:nil repeats:YES];
    //把定时器添加到当前runloop中，选择的模式为NSDefaultRunLoopMode（默认模式，通常主线程是在这个mode下运行）
    [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

/**
 *  界面跟踪 Mode模式，ScrollView滚动timer才工作
 */
- (void)timerWithTrackingRunLoopMode{
    
    NSLog(@"tableview滚动timer才工作（打印）");
    //创建NSTimer
    self.timer = [NSTimer timerWithTimeInterval:2.0f target:self selector:@selector(showMsg) userInfo:nil repeats:YES];
    //把定时器添加到当前runloop中，选择的模式为UITrackingRunLoopMode（界面跟踪 Mode，用于 ScrollView 追踪触摸滑动，保证界面滑动时不受其他 Mode 影响）
    [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:UITrackingRunLoopMode];
}

/**
 *  把timer添加到了两种运行模式下，ScrollView滚动与不滚动，timer都工作（添加了两次，可直接用占位模式）
 */
- (void)timerWithDefaultAndTrackingRunLoopMode{
    
    NSLog(@"把timer添加到了两种运行模式下，ScrollView滚动与不滚动，timer都工作");
    self.timer = [NSTimer timerWithTimeInterval:2.0f target:self selector:@selector(showMsg) userInfo:nil repeats:YES];
    
    //默认模式
    [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSDefaultRunLoopMode];
    //界面追踪模式
    [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:UITrackingRunLoopMode];
    
}

/**
 *  NSRunLoopCommonModes标记,能持续正常工作
 */
- (void)timerWithCommonModes{
    
    NSLog(@"NSRunLoopCommonModes标记,能持续正常工作");
    self.timer = [NSTimer timerWithTimeInterval:2.0f target:self selector:@selector(showMsg) userInfo:nil repeats:YES];
    
    //NSRunLoopCommonModes标记，被打上该标记的模式有NSDefaultRunLoopMode，UITrackingRunLoopMode，相当于timer被添加到了这两种模式下
    [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)showMsg{
    
    NSLog(@"%@",[NSRunLoop currentRunLoop].currentMode);
}

/**
 *  gcd定时器（精准）
 */
- (void)gcdTimer{
    
    NSLog(@"gcd定时器（精准）,不受mode影响");
    //创建队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //创建一个gcd定时器
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    //注：需要强引用timer，不然等到两秒回调时该方法已执行完，timer被释放，不会执行到回调
    self.gcd_Timer = timer;
    
    //设置定时器的开始时间，间隔时间，精准度（一般为0，误差,若对精准度要求没那么高，设置大的误差可以提高性能）
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    
    //设置定时器要调用的方法
    dispatch_source_set_event_handler(timer, ^{
        
        NSLog(@"gcd定时器回调2秒打印一次");
    });
    
    //启动
    dispatch_resume(timer);
}

/**
 *  解释CFRunLoopSourceRef
 */
- (void)showCFRunLoopSourceRefMsg{
    
    /**
     *  CFRunLoopSourceRef是事件源（输入源）,分为Source0和Source1
     *  非基于端口的，用于用户主动触发的事件
     *  基于端口的，通过内核和其它线程相互发送消息
     */
    NSLog(@"\n CFRunLoopSourceRef是事件源（输入源）可分为：\n 1、Source0：非基于Port的，用于用户主动触发的事件\n 2、Source1：基于Port的，通过内核和其它线程相互发送消息");
}

/**
 *  观察者
 */
-(void)observer{
    
    //    CFRunLoopObserverCreate(<#CFAllocatorRef allocator#>, <#CFOptionFlags activities#>, <#Boolean repeats#>, <#CFIndex order#>, <#CFRunLoopObserverCallBack callout#>, <#CFRunLoopObserverContext *context#>)
    
    //创建一个监听对象
    /*
     第一个参数:分配存储空间的
     第二个参数:要监听的状态 kCFRunLoopAllActivities 所有状态
     第三个参数:是否要持续监听
     第四个参数:优先级
     第五个参数:回调
     */
    CFRunLoopObserverRef observer =  CFRunLoopObserverCreateWithHandler(CFAllocatorGetDefault(), kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        
        switch (activity) {
            case kCFRunLoopEntry:
                NSLog(@"runloop进入");
                break;
                
            case kCFRunLoopBeforeTimers:
                NSLog(@"runloop要去处理timer");
                break;
            case kCFRunLoopBeforeSources:
                NSLog(@"runloop要去处理Sources");
                break;
            case kCFRunLoopBeforeWaiting:
                NSLog(@"runloop要休眠了");
                break;
            case kCFRunLoopAfterWaiting:
                NSLog(@"runloop唤醒啦");
                break;
                
            case kCFRunLoopExit:
                NSLog(@"runloop退出");
                break;
            default:
                break;
        }
    });
    
    
    //给runloop添加监听者
    /*
     第一个参数:要监听哪个runloop
     第二个参数:监听者
     第三个参数:要监听runloop在哪种运行模式下的状态
     */
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(run1) userInfo:nil repeats:YES];
    
    CFRelease(observer);
    
}

-(void)run1
{
    NSLog(@"%s",__func__);
}

/**
 *  常驻线程
 */
- (void)alwaysExistThread{
 
 
    //1.创建线程
    //线程只能执行第一次封装的任务,不能尝试重新执行
    AlwaysExistThread *thread = [[AlwaysExistThread alloc]initWithTarget:self selector:@selector(show) object:nil];
    self.thread = thread;
    //2.启动线程
    [thread start];
}

/**
 *  在常驻线程上调用方法
 */
- (void)useThread {
    
    if (self.thread == nil) {
        return;
    }
    [self performSelector:@selector(show) onThread:self.thread withObject:nil waitUntilDone:YES];
}


-(void)show{
    
    NSLog(@"show---常驻线程");
    
    /*
     1.子线程的runloop是需要自己手动创建的
     2.子线程的runloop是需要主动开启的
     3.子线程的runloop里面至少要有一个source或者是timer,observer不行的
     */
    
    [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    
    /*
     NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(test) userInfo:nil repeats:YES];
     
     [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
     
     */
    
    [[NSRunLoop currentRunLoop]run];
}

/**
 *  自动释放池什么时候被释放
 */
- (void)autoreleasepoolRelease{
    
    //    NSLog(@"%@",[NSRunLoop currentRunLoop]);//看打印中的autorelease
    //    NSLog(@"%d---%d",0x1,0xa0);
    /*
     1.自动释放池什么时候创建和释放
     第一次创建:第一次进入runloop的时候
     最后一次释放:runloop退出的时候
     其他情况:
     当runloop将要休眠的时候会释放,然后创建一个新的
     _wrapRunLoopWithAutoreleasePoolHandler  activities = 0x1 （16进制，对应 1）
     _wrapRunLoopWithAutoreleasePoolHandler  activities = 0xa0（16进制，对应 160）
     kCFRunLoopBeforeWaiting
     +
     kCFRunLoopExit
     */
    NSLog(@"\n1.自动释放池什么时候创建和释放\n第一次创建:第一次进入runloop的时候\n最后一次释放:runloop退出的时候\n其他情况:当runloop将要休眠的时候会释放,然后创建一个新的");
}

/**
 *  在某种模式下performSelector
 */
- (void)performSelectorInMode{
    
    NSLog(@"\nperformSelector在default模式下运行,不滚动table，两秒后有打印，若table滚动,不执行");
     //performSelector默认是在default模式下运行,所以，scrollview滚动的时候不执行
    [self performSelector:@selector(show:) withObject:@"performSelector的打印" afterDelay:2.0 ];
    
    //会一直打印
//    [self performSelector:@selector(show:) withObject:@"performSelector的打印"  afterDelay:2.0 inModes:@[NSDefaultRunLoopMode,UITrackingRunLoopMode]];
    

}

- (void)show:(NSString *)msg{
    
    NSLog(@"%@",msg);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
