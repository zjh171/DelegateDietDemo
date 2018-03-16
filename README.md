# AppDelegate瘦身指南
`AppDelegate`瘦身是一个大家都很熟悉的话题，各家也有各自的解决方案。但方案无外乎两种，一种是从`AppDelegate`本身入手，通过各种方式减少AppDelegate的代码行数，另一种是通过架构层面就解决了。本文将分别介绍这两种方式的代表性库，并对比其优缺点。

### FRDModuleManager
[FRDModuleManager](https://github.com/lincode/FRDModuleManager)是豆瓣开源的轻量级模块管理工具。它通过减小`AppDelegate`的代码量来把很多职责拆分至各个模块中去，这样 AppDelegate 会变得容易维护。其主要类`FRDModuleManager`只有300多行代码，使用方式也很简单：

1. 加载模块

```
NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"ModulesRegister" ofType:@"plist"];
FRDModuleManager *manager = [FRDModuleManager sharedInstance];
[manager loadModulesWithPlistFile:plistPath];
```

2. 在 UIApplicationDelegate 各方法中留下钩子

```
NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"ModulesRegister" ofType:@"plist"];
FRDModuleManager *manager = [FRDModuleManager sharedInstance];
[manager loadModulesWithPlistFile:plistPath];
//...这里省略其他的多个生命周期方法
```

实现原理：
`FRDModuleManager`的实现很简单，其内部数组持有注册的模块的引用，通过依次调用数组中的每个模块的特定方法来达到解耦的目的：

![FRDModuleManager原理图](http://7xij1g.com1.z0.glb.clouddn.com/delegate/appdelegate_01.jpg)


优点：
- 简单，只需要几行代码就可以解决。
- 被添加的每个模块都可以“享受”AppDelegate的各个生命周期。

缺点：
- 每个模块都要初始化并分配内存，当`FRDModuleManager`里注册了大量模块时，会创建大量对象并影响App启动速度。
- 缺少模块初始化优先级，当有三个模块A,B,C时，正好C依赖于B，B依赖于A，如果在配置文件中配置A，B，C的顺序又是打乱时，初始化会出问题。

### JSDecoupledAppDelegate
[JSDecoupledAppDelegate](https://github.com/JaviSoto/JSDecoupledAppDelegate)是由`JSBadgeView`的作者开发的一款轻量级的`AppDelegate`解耦工具。它将`AppDelegate`各个功能点独立出来，并通过代理的方式将控制权下发。我们可以看到`JSDecoupledAppDelegate`类中有很多代理，这边列举几个:

| 代理名 | 协议 |描述|
|--------|--------|----|
|  appStateDelegate      |     JSApplicationStateDelegate   |App各种状态|
|  appDefaultOrientationDelegate      |     JSApplicationDefaultOrientationDelegate   |App的横竖屏切换|
|  remoteNotificationsDelegate      |     JSApplicationRemoteNotificationsDelegate   |App通知代理|



这些代理见名知意，例如`appStateDelegate`是用于处理App的各种状态（didFinishLaunchingWithOptions、applicationDidBecomeActive等）下的逻辑；`remoteNotificationsDelegate`是用于处理App的推送的逻辑。`JSDecoupledAppDelegate`使用起来也非常简单：

1. 将`main.m`中的`AppDelegate`替换成`JSDecoupledAppDelegate`：

```
return UIApplicationMain(argc, argv, nil, NSStringFromClass([JSDecoupledAppDelegate class]));
```

2. 指定你需要处理的各个`JSDecoupledAppDelegate`的子`delegate`。例如，你需要实现
`didFinishLaunchingWithOptions`方法，则新建一个类，在其中添加

```
+ (void)load
{
    [JSDecoupledAppDelegate sharedAppDelegate].appStateDelegate = [[self alloc] init];
}
```
然后就可以在里面实现我们以前在`didFinishLaunchingWithOptions`的方法。

实现原理：
iOS开发的小伙伴应该对Objective-C的消息转发机制有所了解，`JSDecoupledAppDelegate`就是通过转发`AppDelegate`的各个方法来实现`AppDelegate`的解耦的：

```
// JSDecoupledAppDelegate在相应方法前会调用respondsToSelector
- (BOOL)respondsToSelector:(SEL)aSelector
{
    // 找到子代理，如果代理中实现了对应的方法则交给子代理处理，否则交给上层处理
    if (protocolFound)
    {
        return delegateRespondsToSelector;
    }
    else
    {
        return [super respondsToSelector:aSelector];
    }
}
```

```
// 具体转发代码
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return [self.appStateDelegate application:application willFinishLaunchingWithOptions:launchOptions];
}
```

优点：
- `JSDecoupledAppDelegate`本身对于`AppDelegate`各个功能的拆分对我们理解`AppDelegate`有一定帮助——`AppDelegate`确实承载了太多的功能。
- 由于各个子代理对象的执行顺序是确定的，因此基本可以解决`FRDModuleManager`中相互依赖的问题。

缺点：
`JSDecoupledAppDelegate`的缺点非常明显：使用它必须废弃原生的`AppDelegate`，因此我们不能通过
```
((AppDelegate *)[UIApplication sharedApplication].delegate).window
```
来获取`window`，以及`window`的`rootViewController`。这个问题笔者曾经提issue给作者，作者的回答也是只能通过获取`view.window`等曲线救国的方式获取`window`。
![作者回复](http://7xij1g.com1.z0.glb.clouddn.com/delegate/delegate_01.png)


### AppDelegate分类(Category)
创建`AppDelegate`分类无疑是低投入高产出的最好解决方案了。目前笔者公司的项目正在使用该方式。不需要添加任何三方库，我们就可以给`AppDelegate`添加很多方法，并且能轻松控制方法的执行顺序，通过此方式，我们项目的`AppDelegate`的`.m`文件文件大小成功瘦身至200行+：

![新建分类文件](http://7xij1g.com1.z0.glb.clouddn.com/delegate/delegate_02.png)

![在AppDelegate中调用](http://7xij1g.com1.z0.glb.clouddn.com/delegate/delegate_03.png)

然而分类的缺点也不言而喻：添加新的属性比较繁琐，只能通过`runtime`或者[BlocksKit](https://github.com/BlocksKit/BlocksKit)等三方库实现。

以上三种方法都是通过对`AppDelegate`修改或添加的方式来达到降低耦合的，下面介绍几种从App架构层就降低`AppDelegate`耦合性的解决方案。

### JLRoutes
[JLRoutes](https://github.com/joeldev/JLRoutes)是`github`上Star数目比较多的URL解析库，可以很方便的处理不同`URL Scheme`以及解析它们的参数，并通过回调block来处理URL对应的操作。我们可以通过定义`URL`的规则来定制我们的页面跳转或其他逻辑。例如假设我们需要在执行`ServiceMediator`类中的`start`方法，只需要

1. 定义`URL`，这里我们设置为
```
NSString *customURL = @"JLRoutesDemo://Service/ServiceMediator";
```
`JLRoutesDemo`是我们项目的`URL Scheme`，需要在`plist`中添加。

2. 对我们注册的`URL`进行处理：
```
// 在route表中添加一条记录
[JLRoutes addRoute:@"/Service/:servicename" handler:^BOOL(NSDictionary<NSString *,NSString *> * _Nonnull parameters) {
    // 处理函数
    Class className = NSClassFromString(parameters[@"servicename"]);
    [className performSelector:@selector(startRoute)];
    return YES;
}];
```
具体代码大家可以看[笔者的Demo](https://github.com/kysonzhu/DelegateDietDemo)

实现原理：
`JLRoutes`在内部维护了一份`URL`字典，注册时添加元素，移除时删除元素。


### MGJRouter
[MGJRouter](https://github.com/meili/MGJRouter)是一个高效/灵活的iOS URL Router,解决了`JLRoutes`查找`URL`不够高效，通过遍历而不是匹配的问题。这里不多做介绍了,大家可以自行Google。


### Objection
[Objection](https://github.com/atomicobject/objection)是一个轻量级的依赖注入框架。依赖注入对于客户端开发的我们可能不太熟悉，但服务端中使用很多，比如Java的`Spring`框架和PHP的`laravel`框架。
依赖注入的核心思想就是控制权反转(Inversion of Control,IoC)。传统iOS程序设计，我们直接在对象内部通过new进行创建对象，是程序主动去创建依赖对象；而IoC是有专门一个容器来创建这些对象，即由Ioc容器来控制对象的创建。具体到Objective-C中就是，先定义一个协议(protocol)，然后通过objection来注册这个协议对应的class，需要的时候，可以获取该协议对应的object。对于使用方无需关心到底使用的是哪个Class，反正该有的方法、属性都有了(在协议中指定)：
```
// 先在App启动之前初始化容器
+(void)load
{
    JSObjectionInjector *injector = [JSObjection defaultInjector];
    injector = injector ? : [JSObjection createInjector];
    injector = [injector withModule:[[xxxModule alloc] init]];
    [JSObjection setDefaultInjector:injector];
}
```
`xxxModule`就是我们需要绑定绑定`protocol`和具体实现类的地方,假设我们有两个服务需要启动，可以如下处理：

```
//xxxModule.m文件
[self bindClass:[NotificationService class] toProtocol:@protocol(NotificationServiceProtocol)];
[self bindClass:[ShareService class] toProtocol:@protocol(ShareServiceProtocol)];
```
接着我们只要通过如下代码获取这两个对象：
```
// 通知服务
JSObjectionInjector *injector = [JSObjection defaultInjector];
NSObject<NotificationServiceProtocol> *notificationService = [injector getObject:@protocol(NotificationServiceProtocol)];
// 分享服务
NSObject<ShareServiceProtocol> *shareService = [injector getObject:@protocol(ShareServiceProtocol)];
```
这样一来`notificationService`和`shareService`就被创建了，我们可以在这两个对象中编写我们的逻辑，省去了在AppDelegate中编写相应的代码，从而降低了耦合性。如果大家对这个库还有疑问，可以参考笔者的Demo。

### 总结
本文主要讲解了通过两种方式来瘦身`AppDelegate`，虽然有所区别，但大致思路还是差不多的。希望对大家有所帮助。本文Demo的地址:[https://github.com/zjh171/DelegateDietDemo](https://github.com/zjh171/DelegateDietDemo)

### 参考

[豆瓣App的模块化实践](http://lincode.github.io/Modularity)

[AppDelegate解耦之JSDecoupledAppDelegate](https://zhongwuzw.github.io/2017/02/09/AppDelegate%E8%A7%A3%E8%80%A6%E4%B9%8BJSDecoupledAppDelegate/)

[【源码阅读】JLRoutes](https://www.jianshu.com/p/55393770805a)

[蘑菇街 App 的组件化之路](http://limboy.me/tech/2016/03/14/mgj-components-continued.html)

[dependency injection 关于IOS依赖注入那些事](https://www.jianshu.com/p/0d72a945f2dd)

[使用objection来模块化开发iOS项目](http://limboy.me/tech/2014/04/15/use-objection-to-decouple-ios-project.html)
