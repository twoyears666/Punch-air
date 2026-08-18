#import "TerracottaViewController.h"
#import "TerracottaManager.h"
#import "LauncherPreferences.h"
#import "BackgroundManager.h"
#import "authenticator/BaseAuthenticator.h"

@interface TerracottaViewController ()
@property(nonatomic, strong) UILabel *statusLabel;
@property(nonatomic, strong) UILabel *detailLabel;
@property(nonatomic, strong) UITextField *playerField;
@property(nonatomic, strong) UITextField *roomField;
@property(nonatomic, strong) UITextField *portField;
@property(nonatomic, strong) UIButton *stopButton;
@end

@implementation TerracottaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"陶瓦联机";
    self.view.backgroundColor = UIColor.clearColor;
    [[BackgroundManager sharedManager] makeViewControllerTransparent:self];

    [self buildInterface];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stateChanged:)
                                                 name:TerracottaStateDidChangeNotification
                                               object:nil];

    if (TerracottaManager.sharedManager.available) {
        [TerracottaManager.sharedManager start];
        [self renderState:TerracottaManager.sharedManager.state];
    } else {
        self.statusLabel.text = @"当前构建不包含陶瓦联机库";
        self.statusLabel.textColor = UIColor.systemRedColor;
        [self setActionsEnabled:NO];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buildInterface {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.layoutMargins = UIEdgeInsetsMake(20, 20, 24, 20);
    stack.layoutMarginsRelativeArrangement = YES;
    [scroll addSubview:stack];

    UILabel *intro = [[UILabel alloc] init];
    intro.numberOfLines = 0;
    intro.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    intro.textColor = UIColor.secondaryLabelColor;
    intro.text = @"与 HMCL、FCL、ZL2 的陶瓦联机互通。房主需要先在 Minecraft 中“对局域网开放”，访客输入房间邀请码即可加入。";
    [stack addArrangedSubview:intro];

    UIView *statusCard = [self cardView];
    UIStackView *statusStack = [self verticalStackInCard:statusCard];
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont boldSystemFontOfSize:17];
    self.statusLabel.text = @"正在初始化…";
    [statusStack addArrangedSubview:self.statusLabel];
    self.detailLabel = [[UILabel alloc] init];
    self.detailLabel.numberOfLines = 0;
    self.detailLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.detailLabel.textColor = UIColor.secondaryLabelColor;
    [statusStack addArrangedSubview:self.detailLabel];
    [stack addArrangedSubview:statusCard];

    UIView *formCard = [self cardView];
    UIStackView *form = [self verticalStackInCard:formCard];
    self.playerField = [self fieldWithPlaceholder:@"玩家名称"];
    BaseAuthenticator *currentAuth = (BaseAuthenticator *)BaseAuthenticator.current;
    NSString *username = currentAuth.authData[@"username"];
    if ([username hasPrefix:@"Demo."]) username = [username substringFromIndex:5];
    self.playerField.text = username.length > 0 ? username : @"Player";
    [form addArrangedSubview:self.playerField];

    self.roomField = [self fieldWithPlaceholder:@"房间名称 / 邀请码"];
    self.roomField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.roomField.autocorrectionType = UITextAutocorrectionTypeNo;
    [form addArrangedSubview:self.roomField];

    self.portField = [self fieldWithPlaceholder:@"Minecraft 局域网端口（手动模式）"];
    self.portField.keyboardType = UIKeyboardTypeNumberPad;
    [form addArrangedSubview:self.portField];

    UIStackView *hostActions = [[UIStackView alloc] init];
    hostActions.axis = UILayoutConstraintAxisHorizontal;
    hostActions.spacing = 10;
    hostActions.distribution = UIStackViewDistributionFillEqually;
    [hostActions addArrangedSubview:[self buttonWithTitle:@"扫描局域网端口"
                                                  symbol:@"dot.radiowaves.left.and.right"
                                                  action:@selector(startScanning)]];
    [hostActions addArrangedSubview:[self buttonWithTitle:@"按端口创建房间"
                                                  symbol:@"network"
                                                  action:@selector(startManualHost)]];
    [form addArrangedSubview:hostActions];

    UIButton *join = [self buttonWithTitle:@"加入房间"
                                    symbol:@"person.2.fill"
                                    action:@selector(joinRoom)];
    [form addArrangedSubview:join];

    UIStackView *sessionActions = [[UIStackView alloc] init];
    sessionActions.axis = UILayoutConstraintAxisHorizontal;
    sessionActions.spacing = 10;
    sessionActions.distribution = UIStackViewDistributionFillEqually;
    [sessionActions addArrangedSubview:[self buttonWithTitle:@"复制邀请码"
                                                     symbol:@"doc.on.doc"
                                                     action:@selector(copyInvite)]];
    self.stopButton = [self buttonWithTitle:@"结束联机"
                                      symbol:@"stop.circle"
                                      action:@selector(stopSession)];
    self.stopButton.tintColor = UIColor.systemRedColor;
    [sessionActions addArrangedSubview:self.stopButton];
    [form addArrangedSubview:sessionActions];

    [stack addArrangedSubview:formCard];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];
}

- (UIView *)cardView {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor.secondarySystemBackgroundColor colorWithAlphaComponent:0.82];
    view.layer.cornerRadius = 14;
    view.layer.masksToBounds = YES;
    return view;
}

- (UIStackView *)verticalStackInCard:(UIView *)card {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.layoutMargins = UIEdgeInsetsMake(16, 16, 16, 16);
    stack.layoutMarginsRelativeArrangement = YES;
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor]
    ]];
    return stack;
}

- (UITextField *)fieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.backgroundColor = [UIColor.systemBackgroundColor colorWithAlphaComponent:0.75];
    [field.heightAnchor constraintGreaterThanOrEqualToConstant:42].active = YES;
    return field;
}

- (UIButton *)buttonWithTitle:(NSString *)title symbol:(NSString *)symbol action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.layer.cornerRadius = 10;
    button.backgroundColor = [accentColor() colorWithAlphaComponent:0.16];
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];
    button.tintColor = accentColor();
    button.imageEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 5);
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (BOOL)validateCommonFields {
    if (self.playerField.text.length == 0 || self.roomField.text.length == 0) {
        [self showMessage:@"请填写玩家名称和房间名称/邀请码"];
        return NO;
    }
    return YES;
}

- (void)startScanning {
    [self.view endEditing:YES];
    if (![self validateCommonFields]) return;
    if (![TerracottaManager.sharedManager hostWithRoom:self.roomField.text player:self.playerField.text]) {
        [self showMessage:@"无法开始扫描，请先结束当前联机会话"];
    }
}

- (void)startManualHost {
    [self.view endEditing:YES];
    if (![self validateCommonFields]) return;
    NSInteger port = self.portField.text.integerValue;
    if (port < 1 || port > UINT16_MAX) {
        [self showMessage:@"请输入 1–65535 的有效局域网端口"];
        return;
    }
    if (![TerracottaManager.sharedManager hostWithRoom:self.roomField.text
                                                  port:(NSUInteger)port
                                                player:self.playerField.text]) {
        [self showMessage:@"无法创建房间，请先结束当前联机会话"];
    }
}

- (void)joinRoom {
    [self.view endEditing:YES];
    if (![self validateCommonFields]) return;
    if (![TerracottaManager.sharedManager joinRoom:self.roomField.text player:self.playerField.text]) {
        [self showMessage:@"邀请码无效，或当前已有联机会话"];
    }
}

- (void)copyInvite {
    NSDictionary *state = TerracottaManager.sharedManager.state;
    NSString *invite = state[@"room"] ?: state[@"url"];
    if (invite.length == 0) invite = self.roomField.text;
    if (invite.length == 0) {
        [self showMessage:@"当前没有可复制的邀请码"];
        return;
    }
    UIPasteboard.generalPasteboard.string = invite;
    [self showMessage:@"邀请码已复制"];
}

- (void)stopSession {
    [TerracottaManager.sharedManager stop];
    [TerracottaManager.sharedManager start];
    [self renderState:TerracottaManager.sharedManager.state];
}

- (void)stateChanged:(NSNotification *)notification {
    [self renderState:notification.userInfo ?: @{}];
}

- (void)renderState:(NSDictionary *)state {
    NSString *value = state[@"state"] ?: @"unknown";
    NSDictionary *titles = @{
        @"waiting": @"等待操作",
        @"host-scanning": @"正在寻找 Minecraft 局域网端口",
        @"host-starting": @"正在创建房间",
        @"host-ok": @"房间已创建",
        @"guest-connecting": @"正在连接房间",
        @"guest-starting": @"正在启动访客通道",
        @"guest-ok": @"已加入房间",
        @"exception": @"联机发生错误",
        @"unknown": @"等待状态数据"
    };
    self.statusLabel.text = titles[value] ?: value;
    self.statusLabel.textColor = [value isEqualToString:@"exception"] ? UIColor.systemRedColor : UIColor.labelColor;

    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    for (NSString *key in @[@"room", @"url", @"difficulty"]) {
        id item = state[key];
        if (item && item != NSNull.null) [lines addObject:[NSString stringWithFormat:@"%@: %@", key, item]];
    }
    if (state[@"profile_index"]) [lines addObject:[NSString stringWithFormat:@"profile: %@", state[@"profile_index"]]];
    self.detailLabel.text = lines.count ? [lines componentsJoinedByString:@"\n"] : @"";
    self.stopButton.enabled = ![value isEqualToString:@"waiting"];
}

- (void)setActionsEnabled:(BOOL)enabled {
    for (UIView *view in self.view.subviews) view.userInteractionEnabled = enabled;
}

- (void)showMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"陶瓦联机"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
