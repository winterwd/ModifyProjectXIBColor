#ModifyProjectXIBColor
修改Xcode 工程内 所有xib或者storyBoard 控件颜色

设置以下属性即可完成 一键修改

    // 工程总目录 源文件路径绝对（这里路径直接将你的工程目录拖进来）
    NSString *sourcePath = @"/Users/winter/Desktop/OneKeyChangeXIBColor/test";

    // 工程修改前颜色 RGB
    NSInteger red_pre = 237;
    NSInteger green_pre = 109;
    NSInteger blue_pre = 31;

    // 修改后的颜色 RGB
    NSInteger red_mod = 255;
    NSInteger green_mod = 96;
    NSInteger blue_mod = 0;