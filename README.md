# PPStickerKeyboard
最近在公司做了个表情键盘的需求，这个需求的技术难度不会很大，比较偏向业务。但是要把用户体验做的好也是不容易的，其中有几个点需要特别注意。话不多说，下面开始正文(注：本文对应的Demo放在Github上：[https://github.com/VernonVan/PPStickerKeyboard](https://github.com/VernonVan/PPStickerKeyboard))。

## 市面上的表情键盘的分析

首先来看一下市面上主要的几个APP上的表情键盘，平时使用的时候不会去关注细节，这次特意去使用了表情键盘，发现各个APP的体验还是有优有劣的。

首先是QQ和微信，这两者差不多，切换到表情键盘的时候都是没有光标的，这样的用户体验是非常不好的，没有办法在输入表情的时候框选区域，也不能拖动光标进行特定位置的复制黏贴删除等操作，微信甚至在输入框里显示的都不是点击的表情图片，而是文字描述。

![微信QQ表情键盘.JPG](http://upload-images.jianshu.io/upload_images/698554-2c59f42aa0dd0dd1.JPG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

接下来看一下微博国际版，国际版调起表情键盘时是有光标的，是一个"真正的"键盘，但是想要拖拽光标的时候，很大概率上会触发到保存图片的行为（如下图所示），导致根本没办法拖动光标。
![微博国际版误触.JPG](http://upload-images.jianshu.io/upload_images/698554-5f667795a7778a6e.JPG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

同时微博国际版输入框表情黏贴后的光标定位是错误的，如下图，开始时光标是在第4个表情后面，然后复制狗头+害羞两个表情黏贴到光标后，光标还是在第4个表情后，同时黏贴的表情前后都莫名多了空格。
![微博国际版黏贴.JPG](http://upload-images.jianshu.io/upload_images/698554-d4cddecefc22cfc9.JPG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

最后是微博，微博客户端的表情键盘的体验是非常好的，上面说到的问题都不存在，而且表情键盘的删除按钮还能长按删除输入框的内容。
![微博表情键盘.jpg](http://upload-images.jianshu.io/upload_images/698554-63023d1dfcce132b.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 表情键盘的实现

#### 实现效果

主要实现了以下几个功能

- 能输入表情，有光标，支持复制黏贴删除表情等
- 长按预览表情
- 删除表情、长按连续删除表情
- 适配 iPhone X
  ![演示.GIF](http://upload-images.jianshu.io/upload_images/698554-9d1661ee627dc3ca.GIF?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 基本思路

首先，表情包的图片是用bundle的形式组织的，用`PPSticker`类表征一套表情包，用`PPEmoji`类表征某一个表情，用一个plist作为配置文件，存储表情包的信息。
![表情的组织.jpg](http://upload-images.jianshu.io/upload_images/698554-10847f03391e9560.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

`PPStickerDataManager`类主要负责数据部分，用单例的形式，这样可以在初始化的时候只会读取一次plist文件中的所有表情信息；同时我们把输入框内容发到服务端以及从服务端请求到的都是纯文本的，比如会把 "笑死了🤣" 转成 "笑死了[笑哭]" 这样的纯文本，而不是直接把表情图片直接发到服务端，也就是说项目中有大量的地方会有把文本->表情的操作，所以`PPStickerDataManager`类也提供匹配某段纯文本中的表情，并把文本替换为图片的功能，`PPStickerDataManager`类的头文件如下：

```objective-c
@interface PPStickerDataManager : NSObject

+ (instancetype)sharedInstance;

/// 所有的表情包
@property (nonatomic, strong, readonly) NSArray<PPSticker *> *allStickers;

/* 匹配给定attributedString中的所有emoji，如果匹配到的emoji有本地图片的话会直接换成本地的图片
 *
 * @param attributedString 可能包含表情包的attributedString
 * @param font 表情图片的对齐字体大小
 */
- (void)replaceEmojiForAttributedString:(NSMutableAttributedString *)attributedString font:(UIFont *)font;

@end
```

#### "真正的"键盘

真正的键盘也就是说调起表情键盘时输入框是有光标的，能进行拖拽光标、选中区域等的操作，这样的体验才是与系统键盘一致的。其实系统已经提供好了接口给我们直接使用，`UITextView`和`UITextField`都有的`inputView`和`inputAccessoryView`就是用来实现自定义键盘的，这两个属性的定义如下：

```objective-c
// Presented when object becomes first responder.  If set to nil, reverts to following responder chain.  If
// set while first responder, will not take effect until reloadInputViews is called.
@property (nullable, readwrite, strong) UIView *inputView;             
@property (nullable, readwrite, strong) UIView *inputAccessoryView;
```

同时系统键盘在 设置->声音->按键音 选项打开且手机非静音状态下输入是有按键的声音的，这个按键音也是可以支持的，只要自定义键盘类遵循`UIInputViewAudioFeedback`协议，同时实现 `enableInputClicksWhenVisible`方法并返回YES，这样就可以在点击表情的时候调用`[[UIDevice currentDevice] playInputClick]`方法发出按键音了，详情请查看[苹果的官方文档](https://developer.apple.com/library/content/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html)。

下面是Demo中键盘切换方法的实现：

```objective-c
- (void)changeKeyboardTo:(PPKeyboardType)toType
{
    switch (toType) {
        case PPKeyboardTypeSystem:
            self.textView.inputView = nil;    // 切换到系统键盘
            [self.textView reloadInputViews]; // 调用reloadInputViews方法会立刻进行键盘的切换
            break;
        case PPKeyboardTypeSticker:            
            self.textView.inputView = self.stickerKeyboard; // 切换到自定义的表情键盘
            [self.textView reloadInputViews];
            break;
        default:
            break;
    }
}
```

#### 去除表情的拖拽交互

在iOS11上，`UITextView`上的`NSTextAttachment`（表情）默认可以进行拖拽交互，但是却导致拖动光标时很容易触发这个交互（图示可以查看上面说到的微博国际版中的误触）。一番查找之后才找到一个比较隐蔽的属性：`textDragInteraction`，直接设置为`NO`就能禁止掉`NSTextAttachment`的拖拽交互。

```objective-c
if (@available(iOS 11.0, *)) {	// 只在iOS11及以上才有这个属性
     _textView.textDragInteraction.enabled = NO;
}
```

#### 与服务端的交互

我们在输入框中输入的内容与服务端进行交互的时候都是用纯文本的，比如会把 "笑死了🤣" 转成 "笑死了[笑哭]" 这样的纯文本发到服务端，而不是直接发表情图片，向服务端请求内容的时候也是传回 "笑死了[笑哭]"，然后客户端再根据正则匹配找出表情替换成对应的表情图片，然后显示到页面上。具体过程可以看下图：
![与服务端的交互.png](http://upload-images.jianshu.io/upload_images/698554-00199a31ec46945d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



也就是说，我们设置到输入框的`NSAttributedString`中的每一个`NSTextAttachment`都有一个"隐藏的"属性—表情的文本描述，这里对`NSAttributedString`进行拓展就能实现。`pp_setTextBackedString`可以对`NSAttributedString`的指定`range`设置一个`PPTextBackedString`类型的属性，而`pp_plainTextForRange`能拿到`NSAttributedString`指定`range`的纯文本。具体实现如下：

```objective-c
@implementation NSAttributedString (PPAddition)

- (NSString *)pp_plainTextForRange:(NSRange)range
{
    if (range.location == NSNotFound || range.length == NSNotFound) {
        return nil;
    }

    NSMutableString *result = [[NSMutableString alloc] init];
    if (range.length == 0) {
        return result;
    }

    NSString *string = self.string;
    [self enumerateAttribute:PPTextBackedStringAttributeName inRange:range options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
        PPTextBackedString *backed = value;
        if (backed && backed.string) {
            [result appendString:backed.string];
        } else {
            [result appendString:[string substringWithRange:range]];
        }
    }];
    return result;
}

@end

@implementation NSMutableAttributedString (PPAddition)

- (void)pp_setTextBackedString:(PPTextBackedString *)textBackedString range:(NSRange)range
{
    if (textBackedString && ![NSNull isEqual:textBackedString]) {
        [self addAttribute:PPTextBackedStringAttributeName value:textBackedString range:range];
    } else {
        [self removeAttribute:PPTextBackedStringAttributeName range:range];
    }
}

@end
```

#### 灵活的光标

表情功能，`UITextView`都是用`NSAttributedString`进行赋值的，并且我们底层其实还是用上面说到的纯文本进行实现的，那么把 [笑死] 转成 🤣 就会从4个字符变成1个字符，这里是有差值的，如果不处理的话就会出现上面提到的微博国际版中复制黏贴输入框的表情会导致光标位置不对，甚至莫名其妙多出前后空格的问题。为了精准的定位光标，我们需要自行处理好这些问题。

这里自己继承并实现了`UITextView`的子类`PPStickerTextView`，在这个类中重载复制、黏贴、剪切等操作，分别对应的方法如下：

```objective-c
- (void)cut:(id)sender;		// 剪切

- (void)copy:(id)sender;	// 复制

- (void)paste:(id)sender;	// 黏贴
```

下面以剪切方法举例，看看怎么处理光标的问题，需要注意的地方请看对应的注释：

```objective-c
- (void)cut:(id)sender
{
    // 1.从textView中拿到对应的纯文本，比如：笑死了[笑死]
    NSString *string = [self.attributedText pp_plainTextForRange:self.selectedRange];
    if (string.length) {
      	// 2. 将纯文本写入到剪贴板中
        [UIPasteboard generalPasteboard].string = string;

      	// 3. 记住当前的光标位置
        NSRange selectedRange = self.selectedRange;
        NSMutableAttributedString *attributeContent = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
      	// 4. 将检测到是表情的文本替换成对应的图片
        [attributeContent replaceCharactersInRange:self.selectedRange withString:@""];
        self.attributedText = attributeContent;
      
      	// 5. 重新设置光标
        self.selectedRange = NSMakeRange(selectedRange.location, 0);
    }
}
```

技术点的分析就是以上这些，详细的代码可以clone代码查看：https://github.com/VernonVan/PPStickerKeyboard