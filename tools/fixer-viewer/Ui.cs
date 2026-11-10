// Bug Fixer app: the window (WPF, Windows 11 Mica, own title bar). Pages: For you / Board / Fixer runs; a side panel opens a report
// inside the app (both posts' messages) with the owner's actions: Open in Discord, Stop / Resume, Delete, write to the fixer.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Effects;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using System.Windows.Shell;
using System.Windows.Threading;

namespace FixerViewer
{
    static class Th
    {
        public static SolidColorBrush B(uint argb)
        {
            var b = new SolidColorBrush(Color.FromArgb((byte)(argb >> 24), (byte)(argb >> 16), (byte)(argb >> 8), (byte)argb)); b.Freeze(); return b;
        }
        public static readonly Brush Text = B(0xFFF3F4F6), Text2 = B(0xFFC4C8D0), Text3 = B(0xFF8D929C), Card = B(0x12FFFFFF), CardHover = B(0x1EFFFFFF),
            Stroke = B(0x1CFFFFFF), Layer = B(0x4D1C1C20), Solid = B(0xFF1F2024), Panel = B(0xFF232429), Dim = B(0x99000000),
            Orange = B(0xFFFF8C42), Blurple = B(0xFF5865F2), Green = B(0xFF3BA55D), Teal = B(0xFF23B5A5), Red = B(0xFFED4245), Yellow = B(0xFFF0B232),
            Pink = B(0xFFEB459E), Purple = B(0xFF9B6BFF), Blue = B(0xFF4EA1FF), Grey = B(0xFF80848E);
        public static readonly FontFamily Font = new FontFamily("Segoe UI Variable Text, Segoe UI"), Display = new FontFamily("Segoe UI Variable Display, Segoe UI"),
            Icons = new FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets");
        public static readonly Dictionary<string, uint> TagColor = new Dictionary<string, uint> {
            { "Needs info", 0xFFF0B232 }, { "With the developer", 0xFF7B86FF }, { "Fixed", 0xFF3BA55D }, { "Live", 0xFF23B5A5 }, { "Not possible", 0xFFED4245 }, { "Wish", 0xFFEB459E },
            { "Not a bug", 0xFF9AA0AA }, { "New report", 0xFF7B86FF }, { "Question for you", 0xFFFF8C42 }, { "Working on it", 0xFF4EA1FF }, { "Fixed, not live yet", 0xFF3BA55D },
            { "Request", 0xFF9B6BFF }, { "Stopped", 0xFF9AA0AA } };
        public const string HOME = "", BOARD = "", RUNS = "", ADD = "", PAUSE = "", PLAY = "", DELETE = "", OPEN = "",
            SEND = "", CLOSE = "", MIN = "", MAX = "", RESTORE = "", BUG = "", CHAT = "", PERSON = "", CLOCK = "",
            CHECK = "", WARN = "", UPLOAD = "", STOP = "", QUESTION = "", X = "";
    }

    class MainWin : Window
    {
        readonly Store store;
        readonly Grid root = new Grid(), overlay = new Grid(), pageHost = new Grid();
        readonly Dictionary<string, Button> navs = new Dictionary<string, Button>();
        readonly Dictionary<string, TextBlock> badges = new Dictionary<string, TextBlock>();
        readonly StackPanel titleStatus = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = VerticalAlignment.Center };
        readonly StackPanel navFixer = new StackPanel();
        readonly Border toast = new Border();
        string page = "you", lastSig = "", runSel = null; bool closedOpen;
        DateTime lastFull = DateTime.MinValue;
        Card detail; string detailTab = "fixer"; long detailLoaded = -1; StackPanel detailMsgs; ScrollViewer detailScroll; Grid detailPanel;
        public bool Quitting, Snapshotting;
        readonly Dictionary<string, double> scrolls = new Dictionary<string, double>();

        static readonly string Styles = @"<ResourceDictionary xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'>
  <Style x:Key='Btn' TargetType='Button'>
    <Setter Property='Foreground' Value='#FFF3F4F6'/><Setter Property='Background' Value='#1CFFFFFF'/><Setter Property='BorderBrush' Value='#1FFFFFFF'/>
    <Setter Property='BorderThickness' Value='1'/><Setter Property='Padding' Value='14,8'/><Setter Property='FontSize' Value='14'/><Setter Property='FontWeight' Value='SemiBold'/>
    <Setter Property='Cursor' Value='Hand'/><Setter Property='FocusVisualStyle' Value='{x:Null}'/><Setter Property='HorizontalContentAlignment' Value='Center'/>
    <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='Button'><Grid>
      <Border Background='{TemplateBinding Background}' BorderBrush='{TemplateBinding BorderBrush}' BorderThickness='{TemplateBinding BorderThickness}' CornerRadius='7'/>
      <Border x:Name='hv' Background='#1AFFFFFF' CornerRadius='7' Opacity='0'/>
      <ContentPresenter Margin='{TemplateBinding Padding}' HorizontalAlignment='{TemplateBinding HorizontalContentAlignment}' VerticalAlignment='Center'/>
    </Grid><ControlTemplate.Triggers>
      <Trigger Property='IsMouseOver' Value='True'><Setter TargetName='hv' Property='Opacity' Value='1'/></Trigger>
      <Trigger Property='IsPressed' Value='True'><Setter TargetName='hv' Property='Opacity' Value='0.45'/></Trigger>
      <Trigger Property='IsEnabled' Value='False'><Setter Property='Opacity' Value='0.4'/></Trigger>
    </ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter>
  </Style>
  <Style x:Key='Plain' TargetType='Button'><Setter Property='Cursor' Value='Hand'/><Setter Property='FocusVisualStyle' Value='{x:Null}'/>
    <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='Button'><ContentPresenter/></ControlTemplate></Setter.Value></Setter></Style>
  <Style x:Key='Caption' TargetType='Button'><Setter Property='Width' Value='46'/><Setter Property='Foreground' Value='#FFF3F4F6'/><Setter Property='FocusVisualStyle' Value='{x:Null}'/>
    <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='Button'><Border x:Name='b' Background='Transparent'><ContentPresenter HorizontalAlignment='Center' VerticalAlignment='Center'/></Border>
      <ControlTemplate.Triggers><Trigger Property='IsMouseOver' Value='True'><Setter TargetName='b' Property='Background' Value='#1AFFFFFF'/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
  <Style x:Key='CaptionClose' TargetType='Button'><Setter Property='Width' Value='46'/><Setter Property='Foreground' Value='#FFF3F4F6'/><Setter Property='FocusVisualStyle' Value='{x:Null}'/>
    <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='Button'><Border x:Name='b' Background='Transparent'><ContentPresenter HorizontalAlignment='Center' VerticalAlignment='Center'/></Border>
      <ControlTemplate.Triggers><Trigger Property='IsMouseOver' Value='True'><Setter TargetName='b' Property='Background' Value='#FFC42B1C'/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
  <Style TargetType='ScrollBar'><Setter Property='Width' Value='10'/><Setter Property='MinWidth' Value='10'/><Setter Property='Background' Value='Transparent'/>
    <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='ScrollBar'><Track x:Name='PART_Track' IsDirectionReversed='True' Focusable='False'>
      <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType='Thumb'><Border Background='#3DFFFFFF' CornerRadius='4' Margin='2'/></ControlTemplate></Thumb.Template></Thumb></Track.Thumb></Track></ControlTemplate></Setter.Value></Setter>
    <Style.Triggers><Trigger Property='Orientation' Value='Horizontal'><Setter Property='Width' Value='Auto'/><Setter Property='MinWidth' Value='0'/><Setter Property='Height' Value='10'/><Setter Property='MinHeight' Value='10'/>
      <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='ScrollBar'><Track x:Name='PART_Track' IsDirectionReversed='False' Focusable='False'>
        <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType='Thumb'><Border Background='#3DFFFFFF' CornerRadius='4' Margin='2'/></ControlTemplate></Thumb.Template></Thumb></Track.Thumb></Track></ControlTemplate></Setter.Value></Setter>
    </Trigger></Style.Triggers></Style>
  <Style TargetType='TextBox'><Setter Property='Foreground' Value='#FFF3F4F6'/><Setter Property='CaretBrush' Value='#FFF3F4F6'/><Setter Property='Background' Value='#14FFFFFF'/>
    <Setter Property='BorderBrush' Value='#29FFFFFF'/><Setter Property='Padding' Value='10,8'/><Setter Property='FontSize' Value='14'/><Setter Property='SelectionBrush' Value='#FFFF8C42'/>
    <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='TextBox'><Border x:Name='b' Background='{TemplateBinding Background}' BorderBrush='{TemplateBinding BorderBrush}' BorderThickness='{TemplateBinding BorderThickness}' CornerRadius='7'>
      <ScrollViewer x:Name='PART_ContentHost' Margin='{TemplateBinding Padding}' VerticalScrollBarVisibility='Auto'/></Border>
      <ControlTemplate.Triggers><Trigger Property='IsKeyboardFocused' Value='True'><Setter TargetName='b' Property='BorderBrush' Value='#FFFF8C42'/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
  <Style x:Key='ReadText' TargetType='TextBox'><Setter Property='Foreground' Value='#FFE6E8EC'/><Setter Property='Background' Value='Transparent'/><Setter Property='BorderThickness' Value='0'/>
    <Setter Property='IsReadOnly' Value='True'/><Setter Property='TextWrapping' Value='Wrap'/><Setter Property='SelectionBrush' Value='#FFFF8C42'/><Setter Property='FontSize' Value='14.5'/>
    <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='TextBox'><ScrollViewer x:Name='PART_ContentHost' VerticalScrollBarVisibility='Disabled'/></ControlTemplate></Setter.Value></Setter></Style>
  <Style TargetType='CheckBox'><Setter Property='Foreground' Value='#FFF3F4F6'/><Setter Property='Cursor' Value='Hand'/><Setter Property='FontSize' Value='14'/>
    <Setter Property='Template'><Setter.Value><ControlTemplate TargetType='CheckBox'><StackPanel Orientation='Horizontal' Background='Transparent'>
      <Border x:Name='box' Width='20' Height='20' CornerRadius='5' BorderThickness='1' BorderBrush='#66FFFFFF' Background='#14FFFFFF'>
        <TextBlock x:Name='tick' Text='&#xE73E;' FontFamily='Segoe Fluent Icons, Segoe MDL2 Assets' FontSize='12' Foreground='#FF1A0E04' HorizontalAlignment='Center' VerticalAlignment='Center' Visibility='Collapsed'/></Border>
      <ContentPresenter Margin='10,0,0,0' VerticalAlignment='Center'/></StackPanel>
      <ControlTemplate.Triggers><Trigger Property='IsChecked' Value='True'><Setter TargetName='box' Property='Background' Value='#FFFF8C42'/><Setter TargetName='box' Property='BorderBrush' Value='#FFFF8C42'/><Setter TargetName='tick' Property='Visibility' Value='Visible'/></Trigger></ControlTemplate.Triggers>
    </ControlTemplate></Setter.Value></Setter></Style>
  <Style TargetType='ToolTip'><Setter Property='Background' Value='#FF2B2C31'/><Setter Property='Foreground' Value='#FFF3F4F6'/><Setter Property='BorderBrush' Value='#33FFFFFF'/><Setter Property='Padding' Value='10,6'/><Setter Property='FontSize' Value='13'/></Style>
</ResourceDictionary>";

        public MainWin(Store store)
        {
            this.store = store;
            Title = "Bug Fixer";
            var wa = SystemParameters.WorkArea;
            Width = Math.Min(1720, wa.Width * 0.92); Height = Math.Min(1080, wa.Height * 0.92);
            MinWidth = 1080; MinHeight = 680;
            WindowStartupLocation = WindowStartupLocation.CenterScreen;
            Resources.MergedDictionaries.Add((ResourceDictionary)XamlReader.Parse(Styles));
            FontFamily = Th.Font; FontSize = 14; Foreground = Th.Text;
            Background = Th.Solid;
            WindowChrome.SetWindowChrome(this, new WindowChrome { CaptionHeight = 48, GlassFrameThickness = new Thickness(-1), ResizeBorderThickness = new Thickness(6), UseAeroCaptionButtons = false, CornerRadius = new CornerRadius(0) });
            TextOptions.SetTextFormattingMode(this, TextFormattingMode.Display);
            try { Icon = BitmapFrame.Create(typeof(MainWin).Assembly.GetManifestResourceStream("app.ico")); } catch { }
            SourceInitialized += (s, e) => ApplyMica();
            StateChanged += (s, e) => { root.Margin = WindowState == WindowState.Maximized ? new Thickness(7) : new Thickness(0); SetMaxGlyph(); };
            Build();
            var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(1500) };
            timer.Tick += (s, e) => Tick();
            timer.Start();
            Loaded += (s, e) => Tick();
            PreviewKeyDown += (s, e) => { if (e.Key == Key.Escape) { if (overlay.Children.Count > 0) CloseOverlay(); } };
        }

        // ---------- Windows 11 look
        [DllImport("dwmapi.dll")] static extern int DwmSetWindowAttribute(IntPtr h, int attr, ref int val, int size);
        void ApplyMica()
        {
            if (Snapshotting) return;
            try
            {
                var h = new WindowInteropHelper(this).Handle;
                int dark = 1; DwmSetWindowAttribute(h, 20, ref dark, 4);
                int mica = 2;
                if (DwmSetWindowAttribute(h, 38, ref mica, 4) == 0)
                {
                    Background = Brushes.Transparent;
                    HwndSource.FromHwnd(h).CompositionTarget.BackgroundColor = Colors.Transparent;
                }
            }
            catch { }
        }

        // ---------- small builders
        static TextBlock T(string text, double size = 14, Brush fg = null, FontWeight? w = null)
        {
            return new TextBlock { Text = text ?? "", FontSize = size, Foreground = fg ?? Th.Text, FontWeight = w ?? FontWeights.Normal, TextWrapping = TextWrapping.Wrap };
        }
        static TextBlock H(string text, double size) { return new TextBlock { Text = text, FontSize = size, FontFamily = Th.Display, FontWeight = FontWeights.SemiBold, Foreground = Th.Text, TextTrimming = TextTrimming.CharacterEllipsis }; }
        static TextBlock Ic(string g, double size = 16, Brush fg = null)
        {
            return new TextBlock { Text = g, FontFamily = Th.Icons, FontSize = size, Foreground = fg ?? Th.Text, VerticalAlignment = VerticalAlignment.Center };
        }
        Button Btn(string text, string glyph, string kind, Action click, string tip = null)
        {
            var sp = new StackPanel { Orientation = Orientation.Horizontal };
            Brush fg = kind == "accent" ? Th.B(0xFF1A0E04) : kind == "danger" ? Th.B(0xFFFF9C9E) : Th.Text;
            if (glyph != null) sp.Children.Add(new TextBlock { Text = glyph, FontFamily = Th.Icons, FontSize = 14, Foreground = fg, VerticalAlignment = VerticalAlignment.Center, Margin = new Thickness(0, 0, text != null ? 8 : 0, 0) });
            if (text != null) sp.Children.Add(new TextBlock { Text = text, Foreground = fg, VerticalAlignment = VerticalAlignment.Center });
            var b = new Button { Content = sp, Style = (Style)Resources["Btn"], ToolTip = tip };
            if (kind == "accent") { b.Background = Th.Orange; b.BorderBrush = Th.Orange; }
            else if (kind == "discord") { b.Background = Th.Blurple; b.BorderBrush = Th.Blurple; }
            else if (kind == "teal") { b.Background = Th.Teal; b.BorderBrush = Th.Teal; }
            else if (kind == "danger") { b.Background = Th.B(0x26ED4245); b.BorderBrush = Th.B(0x59ED4245); }
            else if (kind == "ghost") { b.Background = Brushes.Transparent; b.BorderBrush = Brushes.Transparent; }
            b.Click += (s, e) => click();
            return b;
        }
        static Border Chip(string text)
        {
            uint c; if (!Th.TagColor.TryGetValue(text, out c)) c = 0xFF9AA0AA;
            return new Border { CornerRadius = new CornerRadius(10), Padding = new Thickness(8, 2, 8, 3), Margin = new Thickness(0, 0, 6, 6), Background = Th.B((c & 0x00FFFFFF) | 0x26000000),
                BorderBrush = Th.B((c & 0x00FFFFFF) | 0x55000000), BorderThickness = new Thickness(1), Child = new TextBlock { Text = text, FontSize = 12, FontWeight = FontWeights.SemiBold, Foreground = Th.B(c) } };
        }
        static Border Surface(UIElement child, double pad = 18, Brush bg = null)
        {
            return new Border { Background = bg ?? Th.Card, BorderBrush = Th.Stroke, BorderThickness = new Thickness(1), CornerRadius = new CornerRadius(10), Padding = new Thickness(pad), Child = child };
        }
        public static string Ago(long ms)
        {
            if (ms <= 0) return "";
            var s = (DateTime.UtcNow - new DateTime(1970, 1, 1)).TotalMilliseconds / 1000 - ms / 1000.0;
            if (s < 60) return "just now";
            if (s < 3600) return Math.Round(s / 60) + " min ago";
            if (s < 86400) return Math.Round(s / 3600) + " h ago";
            var d = Math.Round(s / 86400); return d == 1 ? "yesterday" : d + " days ago";
        }
        static DateTime Local(long ms) { return new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc).AddMilliseconds(ms).ToLocalTime(); }
        static string Day(DateTime t)
        {
            if (t == DateTime.MinValue) return "";
            var d = t.Date == DateTime.Today ? "Today" : t.Date == DateTime.Today.AddDays(-1) ? "Yesterday" : t.ToString("ddd d MMM");
            return d + " " + t.ToString("HH:mm");
        }
        static string WhoName(string who) { return who == "you" ? "You" : who == "fixer" ? "Fixer" : who == "helper" ? "Helper bot" : who; }

        // ---------- layout
        Button captionMax;
        void Build()
        {
            Content = new Grid();
            var outer = (Grid)Content;
            outer.Children.Add(root);
            root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(48) });
            root.RowDefinitions.Add(new RowDefinition());

            // title bar
            var bar = new Grid();
            bar.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            bar.ColumnDefinitions.Add(new ColumnDefinition());
            bar.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            bar.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            var brand = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(16, 0, 0, 0), VerticalAlignment = VerticalAlignment.Center };
            try { brand.Children.Add(new Image { Source = BitmapFrame.Create(typeof(MainWin).Assembly.GetManifestResourceStream("app.png")), Width = 22, Height = 22, Margin = new Thickness(0, 0, 12, 0) }); } catch { }
            brand.Children.Add(new TextBlock { Text = "Bug Fixer", FontSize = 14, FontWeight = FontWeights.SemiBold, VerticalAlignment = VerticalAlignment.Center });
            brand.Children.Add(new TextBlock { Text = "  ·  Ninja Online Reborn", FontSize = 13, Foreground = Th.Text3, VerticalAlignment = VerticalAlignment.Center });
            bar.Children.Add(brand);
            Grid.SetColumn(titleStatus, 2); titleStatus.Margin = new Thickness(0, 0, 14, 0); bar.Children.Add(titleStatus);
            var caps = new StackPanel { Orientation = Orientation.Horizontal };
            var bmin = new Button { Content = Ic(Th.MIN, 10), Style = (Style)Resources["Caption"] }; bmin.Click += (s, e) => WindowState = WindowState.Minimized;
            captionMax = new Button { Content = Ic(Th.MAX, 10), Style = (Style)Resources["Caption"] }; captionMax.Click += (s, e) => WindowState = WindowState == WindowState.Maximized ? WindowState.Normal : WindowState.Maximized;
            var bclose = new Button { Content = Ic(Th.CLOSE, 10), Style = (Style)Resources["CaptionClose"] }; bclose.Click += (s, e) => Close();
            foreach (var b in new[] { bmin, captionMax, bclose }) { WindowChrome.SetIsHitTestVisibleInChrome(b, true); caps.Children.Add(b); }
            Grid.SetColumn(caps, 3); bar.Children.Add(caps);
            root.Children.Add(bar);

            // body: sidebar + content
            var body = new Grid(); Grid.SetRow(body, 1);
            body.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(250) });
            body.ColumnDefinitions.Add(new ColumnDefinition());
            var side = new DockPanel { Margin = new Thickness(12, 6, 12, 14), LastChildFill = false };
            var newReq = Btn("New request", Th.ADD, "accent", NewRequestDialog, "Ask the fixer for something: it opens a post in #bug-fixer");
            newReq.Padding = new Thickness(14, 10, 14, 10); newReq.Margin = new Thickness(0, 4, 0, 16); newReq.HorizontalContentAlignment = HorizontalAlignment.Left;
            DockPanel.SetDock(newReq, Dock.Top); side.Children.Add(newReq);
            foreach (var n in new[] { new[] { "you", Th.HOME, "For you" }, new[] { "board", Th.BOARD, "Board" }, new[] { "runs", Th.RUNS, "Fixer runs" } })
            {
                var g = new Grid();
                g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(32) });
                g.ColumnDefinitions.Add(new ColumnDefinition());
                g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                g.Children.Add(Ic(n[1], 16));
                var lbl = T(n[2], 14.5); lbl.VerticalAlignment = VerticalAlignment.Center; Grid.SetColumn(lbl, 1); g.Children.Add(lbl);
                var badge = new TextBlock { FontSize = 12, FontWeight = FontWeights.Bold, Foreground = Th.B(0xFF1A0E04), Padding = new Thickness(7, 1, 7, 2), VerticalAlignment = VerticalAlignment.Center };
                var badgeBox = new Border { Background = Th.Orange, CornerRadius = new CornerRadius(9), Child = badge, Visibility = Visibility.Collapsed };
                badges[n[0]] = badge; Grid.SetColumn(badgeBox, 2); g.Children.Add(badgeBox);
                var key = n[0];
                var b = new Button { Content = g, Style = (Style)Resources["Btn"], HorizontalContentAlignment = HorizontalAlignment.Stretch, Padding = new Thickness(12, 10, 12, 10), Margin = new Thickness(0, 0, 0, 4), Background = Brushes.Transparent, BorderBrush = Brushes.Transparent };
                b.Click += (s, e) => { page = key; lastSig = ""; Tick(); };
                navs[key] = b; DockPanel.SetDock(b, Dock.Top); side.Children.Add(b);
            }
            DockPanel.SetDock(navFixer, Dock.Bottom); side.Children.Add(navFixer);
            body.Children.Add(side);
            var content = new Border { Background = Th.Layer, BorderBrush = Th.Stroke, BorderThickness = new Thickness(1, 1, 0, 0), CornerRadius = new CornerRadius(10, 0, 0, 0), Child = pageHost };
            Grid.SetColumn(content, 1); body.Children.Add(content);
            root.Children.Add(body);

            // overlays: report panel, dialogs, toast
            Grid.SetRowSpan(overlay, 2); root.Children.Add(overlay);
            toast.Background = Th.B(0xFF2B2C31); toast.BorderBrush = Th.B(0x33FFFFFF); toast.BorderThickness = new Thickness(1); toast.CornerRadius = new CornerRadius(10);
            toast.Padding = new Thickness(18, 12, 18, 12); toast.HorizontalAlignment = HorizontalAlignment.Center; toast.VerticalAlignment = VerticalAlignment.Bottom;
            toast.Margin = new Thickness(0, 0, 0, 28); toast.Visibility = Visibility.Collapsed; toast.Effect = new DropShadowEffect { BlurRadius = 24, ShadowDepth = 4, Opacity = 0.5, Color = Colors.Black };
            Grid.SetRowSpan(toast, 2); root.Children.Add(toast);
        }

        void SetMaxGlyph() { if (captionMax != null) captionMax.Content = Ic(WindowState == WindowState.Maximized ? Th.RESTORE : Th.MAX, 10); }

        public void Toast(string text, bool bad = false)
        {
            var sp = new StackPanel { Orientation = Orientation.Horizontal };
            sp.Children.Add(Ic(bad ? Th.WARN : Th.CHECK, 15, bad ? Th.Red : Th.Green));
            var t = T(text, 14.5); t.Margin = new Thickness(10, 0, 0, 0); t.MaxWidth = 640; sp.Children.Add(t);
            toast.Child = sp; toast.Visibility = Visibility.Visible; toast.Opacity = 1;
            var a = new DoubleAnimation(1, 0, TimeSpan.FromMilliseconds(500)) { BeginTime = TimeSpan.FromSeconds(bad ? 7 : 4) };
            a.Completed += (s, e) => { if (toast.Opacity == 0) toast.Visibility = Visibility.Collapsed; };
            toast.BeginAnimation(OpacityProperty, a);
        }

        // ---------- refresh
        string Sig(Snapshot s)
        {
            var sb = new System.Text.StringBuilder();
            sb.Append(page).Append(s.Fixer).Append(s.Paused).Append(s.AppOpen).Append(s.Next.ToString("HHmm")).Append(s.DiscordError).Append(s.DiscordLoaded).Append(runSel);
            foreach (var c in s.Cards) sb.Append(c.Id).Append(c.Stage).Append(c.LastTime).Append(c.Now).Append(string.Join(",", c.AllTags));
            foreach (var g in s.GoLive) sb.Append(g);
            foreach (var r in s.Runs.Take(40)) sb.Append(r.Id).Append(r.State).Append(r.Lines.Count);
            return sb.ToString();
        }

        public void Tick()
        {
            var s = store.Current;
            RenderChrome(s);
            var sig = Sig(s);
            if (sig == lastSig && (DateTime.Now - lastFull).TotalSeconds < 30) return;
            lastSig = sig; lastFull = DateTime.Now;
            SaveScrolls(pageHost);
            pageHost.Children.Clear();
            if (!s.DiscordLoaded && s.DiscordError == "" && page != "runs") pageHost.Children.Add(Loading("Reading Discord…"));
            else if (page == "board") pageHost.Children.Add(BoardPage(s));
            else if (page == "runs") pageHost.Children.Add(RunsPage(s));
            else pageHost.Children.Add(YouPage(s));
            Dispatcher.BeginInvoke(DispatcherPriority.Loaded, (Action)(() => RestoreScrolls(pageHost)));
            if (detail != null) RefreshDetail(s);
        }

        void SaveScrolls(DependencyObject d)
        {
            var sv = d as ScrollViewer;
            if (sv != null && sv.Tag is string) scrolls[(string)sv.Tag] = sv.VerticalOffset;
            for (int i = 0; i < VisualTreeHelper.GetChildrenCount(d); i++) SaveScrolls(VisualTreeHelper.GetChild(d, i));
        }
        void RestoreScrolls(DependencyObject d)
        {
            var sv = d as ScrollViewer; double v;
            if (sv != null && sv.Tag is string && scrolls.TryGetValue((string)sv.Tag, out v)) sv.ScrollToVerticalOffset(v);
            for (int i = 0; i < VisualTreeHelper.GetChildrenCount(d); i++) RestoreScrolls(VisualTreeHelper.GetChild(d, i));
        }
        static ScrollViewer Scroll(UIElement child, string key)
        {
            return new ScrollViewer { Content = child, Tag = key, VerticalScrollBarVisibility = ScrollBarVisibility.Auto, HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled, Focusable = false };
        }
        static UIElement Loading(string text)
        {
            var sp = new StackPanel { HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            sp.Children.Add(new ProgressBar { IsIndeterminate = true, Width = 220, Height = 4, Foreground = Th.Orange, Background = Th.Card, BorderThickness = new Thickness(0) });
            var t = T(text, 15, Th.Text2); t.Margin = new Thickness(0, 14, 0, 0); t.HorizontalAlignment = HorizontalAlignment.Center; sp.Children.Add(t);
            return sp;
        }

        static string FixerLine(Snapshot s, out Brush color, out string glyph)
        {
            switch (s.Fixer)
            {
                case "working": color = Th.Orange; glyph = Th.BUG; return "Fixing a bug now";
                case "checking": color = Th.Blue; glyph = Th.BUG; return "Checking for news";
                case "stuck": color = Th.Red; glyph = Th.WARN; return "Looks stuck";
                case "paused": color = Th.Yellow; glyph = Th.PAUSE; return "Paused by you";
                case "off": color = Th.Grey; glyph = Th.STOP; return "Off: Claude app closed";
                default: color = Th.Green; glyph = Th.CHECK; return "Resting";
            }
        }

        void RenderChrome(Snapshot s)
        {
            Brush color; string glyph;
            var label = FixerLine(s, out color, out glyph);
            titleStatus.Children.Clear();
            var dot = new Ellipse { Width = 9, Height = 9, Fill = color, Margin = new Thickness(0, 0, 9, 0), VerticalAlignment = VerticalAlignment.Center };
            if (s.Fixer == "working" || s.Fixer == "checking") dot.BeginAnimation(OpacityProperty, new DoubleAnimation(1, 0.25, TimeSpan.FromMilliseconds(800)) { AutoReverse = true, RepeatBehavior = RepeatBehavior.Forever });
            titleStatus.Children.Add(dot);
            titleStatus.Children.Add(new TextBlock { Text = label, FontWeight = FontWeights.SemiBold, VerticalAlignment = VerticalAlignment.Center });
            titleStatus.Children.Add(new TextBlock { Text = "   " + NextText(s), Foreground = Th.Text3, VerticalAlignment = VerticalAlignment.Center });

            // sidebar: badges + fixer card
            var you = s.Cards.Count(c => c.Stage == "you" && !c.Test);
            SetBadge("you", you + (s.GoLive.Count > 0 ? 1 : 0));
            SetBadge("board", 0);
            foreach (var kv in navs) kv.Value.Background = kv.Key == page ? Th.B(0x1FFFFFFF) : Brushes.Transparent;
            navFixer.Children.Clear();
            var inner = new StackPanel();
            var row = new StackPanel { Orientation = Orientation.Horizontal };
            row.Children.Add(Ic(glyph, 15, color));
            var lt = T(label, 14, Th.Text, FontWeights.SemiBold); lt.Margin = new Thickness(9, 0, 0, 0); row.Children.Add(lt);
            inner.Children.Add(row);
            var sub = T(s.Fixer == "working" || s.Fixer == "checking" ? (s.Active != null ? s.Active.Result : "") : NextText(s), 12.5, Th.Text3);
            sub.Margin = new Thickness(0, 6, 0, 12); sub.MaxHeight = 52; sub.TextTrimming = TextTrimming.CharacterEllipsis; inner.Children.Add(sub);
            var pb = s.Paused ? Btn("Resume the fixer", Th.PLAY, "accent", () => PauseDialog(false)) : Btn("Pause the fixer", Th.PAUSE, null, () => PauseDialog(true));
            pb.HorizontalContentAlignment = HorizontalAlignment.Center; inner.Children.Add(pb);
            navFixer.Children.Add(Surface(inner, 14));
        }
        void SetBadge(string key, int n)
        {
            TextBlock b; if (!badges.TryGetValue(key, out b)) return;
            b.Text = n.ToString(); ((Border)b.Parent).Visibility = n > 0 ? Visibility.Visible : Visibility.Collapsed;
        }
        static string NextText(Snapshot s)
        {
            if (s.Paused) return "Paused: it skips its checks until you resume it";
            if (!s.AppOpen) return "Only runs while the Claude app is open";
            if (s.Fixer == "working" || s.Fixer == "checking") return s.Active != null ? "Running since " + s.Active.Start.ToString("HH:mm") : "";
            var m = (int)Math.Round((s.Next - DateTime.Now).TotalMinutes);
            return (m <= 0 ? "Next check any minute" : "Next check in " + m + " min") + " (" + s.Next.ToString("HH:mm") + ")";
        }

        // ---------- page: For you
        UIElement YouPage(Snapshot s)
        {
            var sp = new StackPanel { Margin = new Thickness(36, 30, 36, 36), MaxWidth = 1300 };
            var hour = DateTime.Now.Hour;
            sp.Children.Add(H(hour < 6 ? "Up late, Dean" : hour < 12 ? "Good morning, Dean" : hour < 18 ? "Good afternoon, Dean" : "Good evening, Dean", 30));
            var qs = s.Cards.Where(c => c.Stage == "you" && !c.Test).ToList();
            var summary = qs.Count == 0 && s.GoLive.Count == 0 ? "Nothing needs you right now." :
                string.Join(" ", new[] { qs.Count > 0 ? (qs.Count == 1 ? "1 question is waiting for you." : qs.Count + " questions are waiting for you.") : null,
                    s.GoLive.Count > 0 ? (s.GoLive.Count == 1 ? "1 fix is ready to go live." : s.GoLive.Count + " fixes are ready to go live.") : null }.Where(x => x != null));
            var st = T(summary, 16, Th.Text2); st.Margin = new Thickness(0, 6, 0, 24); sp.Children.Add(st);
            if (s.DiscordError != "") sp.Children.Add(ErrorBar(s.DiscordError));

            var grid = new Grid();
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1.25, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(20) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            // questions
            var ql = new StackPanel();
            ql.Children.Add(SectionTitle(Th.QUESTION, "Questions for you", qs.Count));
            if (qs.Count == 0)
            {
                var ok = new StackPanel { Orientation = Orientation.Horizontal };
                ok.Children.Add(Ic(Th.CHECK, 20, Th.Green));
                var okt = new StackPanel { Margin = new Thickness(14, 0, 0, 0) };
                okt.Children.Add(T("No questions right now", 15, Th.Text, FontWeights.SemiBold));
                okt.Children.Add(T("When the fixer needs a decision it shows up here, and the tray icon pops up.", 13.5, Th.Text3));
                ok.Children.Add(okt);
                ql.Children.Add(Surface(ok, 18, Th.B(0x143BA55D)));
            }
            foreach (var c in qs)
            {
                var g = new Grid();
                g.ColumnDefinitions.Add(new ColumnDefinition());
                g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                var t = new StackPanel();
                var tt = T(c.Title, 15.5, Th.Text, FontWeights.SemiBold); tt.TextTrimming = TextTrimming.CharacterEllipsis; tt.TextWrapping = TextWrapping.NoWrap; t.Children.Add(tt);
                var why = T(c.Why + (c.LastText != "" ? " · “" + c.LastText + "”" : ""), 13.5, Th.Text3); why.TextWrapping = TextWrapping.NoWrap; why.TextTrimming = TextTrimming.CharacterEllipsis; t.Children.Add(why);
                g.Children.Add(t);
                var cc = c;
                var b = Btn("Open", Th.CHAT, "accent", () => OpenDetail(cc)); b.Margin = new Thickness(14, 0, 0, 0); Grid.SetColumn(b, 1); g.Children.Add(b);
                var box = Surface(g, 14, Th.B(0x1AFF8C42)); box.BorderBrush = Th.B(0x55FF8C42); box.Margin = new Thickness(0, 0, 0, 10);
                ql.Children.Add(box);
            }
            grid.Children.Add(ql);
            // go live
            var gl = new StackPanel();
            gl.Children.Add(SectionTitle(Th.UPLOAD, "Ready to go live", s.GoLive.Count));
            var glIn = new StackPanel();
            if (!s.GoLiveKnown) glIn.Children.Add(T("The 📦 post in #bug-fixer was not found.", 14, Th.Text3));
            else if (s.GoLive.Count == 0)
            {
                var r = new StackPanel { Orientation = Orientation.Horizontal };
                r.Children.Add(Ic(Th.CHECK, 18, Th.Teal));
                var rt = T("The public server has every fix.", 15, Th.Text, FontWeights.SemiBold); rt.Margin = new Thickness(12, 0, 0, 0); r.Children.Add(rt);
                glIn.Children.Add(r);
            }
            else
            {
                foreach (var line in s.GoLive)
                {
                    var r = new Grid { Margin = new Thickness(0, 0, 0, 8) };
                    r.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(22) }); r.ColumnDefinitions.Add(new ColumnDefinition());
                    r.Children.Add(new Ellipse { Width = 6, Height = 6, Fill = Th.Teal, VerticalAlignment = VerticalAlignment.Top, Margin = new Thickness(4, 7, 0, 0), HorizontalAlignment = HorizontalAlignment.Left });
                    var lt = T(line, 14.5); Grid.SetColumn(lt, 1); r.Children.Add(lt);
                    glIn.Children.Add(r);
                }
                if (s.GoLiveBehind != "") { var b2 = T(s.GoLiveBehind, 13, Th.Text3); b2.Margin = new Thickness(22, 0, 0, 10); glIn.Children.Add(b2); }
                var live = Btn("Put it live", Th.UPLOAD, "teal", () => GoLiveDialog(s)); live.HorizontalAlignment = HorizontalAlignment.Left; live.Margin = new Thickness(0, 8, 0, 0);
                ((TextBlock)((StackPanel)live.Content).Children[1]).Foreground = Th.B(0xFF04201C); ((TextBlock)((StackPanel)live.Content).Children[0]).Foreground = Th.B(0xFF04201C);
                glIn.Children.Add(live);
            }
            if (s.PinnedId != null)
            {
                var pid = s.PinnedId;
                var ob = Btn("Open the 📦 post", Th.OPEN, "ghost", () => OpenDiscord(pid)); ob.HorizontalAlignment = HorizontalAlignment.Left; ob.Margin = new Thickness(-10, 8, 0, 0);
                glIn.Children.Add(ob);
            }
            var glBox = Surface(glIn, 18, s.GoLive.Count > 0 ? Th.B(0x1A23B5A5) : null);
            if (s.GoLive.Count > 0) glBox.BorderBrush = Th.B(0x5523B5A5);
            gl.Children.Add(glBox);
            Grid.SetColumn(gl, 2); grid.Children.Add(gl);
            sp.Children.Add(grid);

            // the fixer
            var fx = new StackPanel { Margin = new Thickness(0, 28, 0, 0) };
            fx.Children.Add(SectionTitle(Th.BUG, "The fixer", -1));
            fx.Children.Add(FixerCard(s, 12));
            sp.Children.Add(fx);
            return Scroll(sp, "you");
        }

        static UIElement SectionTitle(string glyph, string text, int count)
        {
            var sp = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0, 0, 0, 12) };
            sp.Children.Add(Ic(glyph, 16, Th.Text2));
            var t = H(text, 18); t.Margin = new Thickness(10, 0, 0, 0); sp.Children.Add(t);
            if (count > 0) sp.Children.Add(new Border { Background = Th.Orange, CornerRadius = new CornerRadius(10), Margin = new Thickness(10, 2, 0, 0), Padding = new Thickness(8, 0, 8, 1), VerticalAlignment = VerticalAlignment.Center,
                Child = new TextBlock { Text = count.ToString(), FontWeight = FontWeights.Bold, FontSize = 12.5, Foreground = Th.B(0xFF1A0E04) } });
            return sp;
        }
        static UIElement ErrorBar(string text)
        {
            var sp = new StackPanel { Orientation = Orientation.Horizontal };
            sp.Children.Add(Ic(Th.WARN, 16, Th.Red));
            var t = T("Can't read Discord right now: " + text + ". Showing what was read last.", 14, Th.B(0xFFFFC9CA)); t.Margin = new Thickness(10, 0, 0, 0); sp.Children.Add(t);
            var b = Surface(sp, 12, Th.B(0x1FED4245)); b.BorderBrush = Th.B(0x55ED4245); b.Margin = new Thickness(0, 0, 0, 18);
            return b;
        }

        UIElement FixerCard(Snapshot s, int lines)
        {
            Brush color; string glyph;
            var label = FixerLine(s, out color, out glyph);
            var sp = new StackPanel();
            var head = new Grid();
            head.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto }); head.ColumnDefinitions.Add(new ColumnDefinition());
            var icon = new Border { Width = 48, Height = 48, CornerRadius = new CornerRadius(12), Background = new SolidColorBrush(Color.FromArgb(0x2E, ((SolidColorBrush)color).Color.R, ((SolidColorBrush)color).Color.G, ((SolidColorBrush)color).Color.B)), Child = new TextBlock { Text = glyph, FontFamily = Th.Icons, FontSize = 22, Foreground = color, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center } };
            head.Children.Add(icon);
            var ht = new StackPanel { Margin = new Thickness(14, 0, 0, 0), VerticalAlignment = VerticalAlignment.Center };
            ht.Children.Add(T(label, 17, Th.Text, FontWeights.SemiBold));
            var last = s.Runs.FirstOrDefault(r => r.State != "working");
            string sub = s.Fixer == "working" || s.Fixer == "checking" ? "Started " + s.Active.Start.ToString("HH:mm") + " · " + NextText(s) :
                s.Fixer == "stuck" ? (s.Active != null ? s.Active.Result : "") : (last != null ? "Last check " + Day(last.Start) + ": " + last.Result : "No runs yet");
            var subT = T(sub, 13.5, Th.Text3); subT.MaxHeight = 44; subT.TextTrimming = TextTrimming.CharacterEllipsis; ht.Children.Add(subT);
            Grid.SetColumn(ht, 1); head.Children.Add(ht);
            sp.Children.Add(head);
            var run = s.Active;
            if (run != null)
            {
                if (s.Fixer == "working" || s.Fixer == "checking")
                {
                    var step = new StackPanel { Orientation = Orientation.Horizontal };
                    step.Children.Add(new ProgressBar { IsIndeterminate = true, Width = 40, Height = 3, Foreground = Th.Orange, Background = Th.Card, BorderThickness = new Thickness(0), VerticalAlignment = VerticalAlignment.Center });
                    var stt = T(run.Result, 14.5, Th.Text, FontWeights.SemiBold); stt.Margin = new Thickness(12, 0, 0, 0); step.Children.Add(stt);
                    var stepBox = Surface(step, 12, Th.B(0x0FFFFFFF)); stepBox.Margin = new Thickness(0, 14, 0, 10);
                    sp.Children.Add(stepBox);
                }
                foreach (var l in run.Lines.Skip(Math.Max(0, run.Lines.Count - lines))) sp.Children.Add(FeedLine(l, 13.5));
                var id = run.Id;
                var all = Btn("See the whole run", Th.RUNS, "ghost", () => { page = "runs"; runSel = id; lastSig = ""; Tick(); });
                all.HorizontalAlignment = HorizontalAlignment.Left; all.Margin = new Thickness(-10, 6, 0, 0);
                sp.Children.Add(all);
            }
            return Surface(sp, 18);
        }

        static UIElement FeedLine(Line l, double size)
        {
            var g = new Grid { Margin = new Thickness(0, 3, 0, 3) };
            g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(54) }); g.ColumnDefinitions.Add(new ColumnDefinition());
            g.Children.Add(new TextBlock { Text = l.Time == DateTime.MinValue ? "" : l.Time.ToString("HH:mm"), FontSize = size - 0.5, Foreground = Th.Text3 });
            Brush c = Th.Text; var w = FontWeights.Normal;
            switch (l.Kind)
            {
                case "say": c = Th.Text2; break;
                case "found": c = Th.Yellow; w = FontWeights.SemiBold; break;
                case "bad": c = Th.B(0xFFFF9C9E); w = FontWeights.SemiBold; break;
                case "good": case "summary": c = Th.B(0xFF8FE0A8); w = FontWeights.SemiBold; break;
                case "start": case "msg": c = Th.B(0xFFAAB3FF); w = FontWeights.SemiBold; break;
            }
            var t = T(l.Text, size, c, w); Grid.SetColumn(t, 1); g.Children.Add(t);
            return g;
        }

        // ---------- page: Board
        static readonly string[][] Cols = {
            new[] { "player", Th.CHAT, "Asking player", "The helper bot gets the details" },
            new[] { "fixer", Th.BUG, "With the fixer", "Next in line, or being fixed now" },
            new[] { "you", Th.QUESTION, "Your answer", "The fixer waits for you" },
            new[] { "ready", Th.UPLOAD, "Not live yet", "Fixed; goes live with the next update" },
            new[] { "live", Th.CHECK, "Live", "Players have the fix" } };

        UIElement BoardPage(Snapshot s)
        {
            var g = new Grid { Margin = new Thickness(28, 24, 28, 20) };
            g.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            g.RowDefinitions.Add(new RowDefinition());
            g.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            var head = new StackPanel { Margin = new Thickness(4, 0, 0, 18) };
            head.Children.Add(H("Board", 28));
            head.Children.Add(T("Every report, from the player's post to the fix being live. Click a card to open it.", 14.5, Th.Text3));
            if (s.DiscordError != "") { head.Children.Add(new Border { Height = 12 }); head.Children.Add(ErrorBar(s.DiscordError)); }
            g.Children.Add(head);
            var cols = new UniformGrid { Columns = 5, Rows = 1 }; Grid.SetRow(cols, 1);
            var cutoff = (long)(DateTime.UtcNow.AddDays(-14) - new DateTime(1970, 1, 1)).TotalMilliseconds;
            foreach (var col in Cols)
            {
                var list = s.Cards.Where(c => c.Stage == col[0] && (col[0] != "live" || Math.Max(c.LastTime, c.Created) > cutoff)).ToList();
                var colGrid = new Grid();
                colGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                colGrid.RowDefinitions.Add(new RowDefinition());
                var hd = new Grid { Margin = new Thickness(16, 14, 14, 12) };
                hd.ColumnDefinitions.Add(new ColumnDefinition()); hd.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                var ht = new StackPanel();
                var tr = new StackPanel { Orientation = Orientation.Horizontal };
                tr.Children.Add(Ic(col[1], 15, col[0] == "you" ? Th.Orange : Th.Text2));
                var tt = H(col[2], 16); tt.Margin = new Thickness(9, 0, 0, 0); tr.Children.Add(tt);
                ht.Children.Add(tr);
                var hint = T(col[3], 12.5, Th.Text3); hint.Margin = new Thickness(0, 3, 0, 0); hint.TextTrimming = TextTrimming.CharacterEllipsis; hint.TextWrapping = TextWrapping.NoWrap; ht.Children.Add(hint);
                hd.Children.Add(ht);
                var cnt = new Border { CornerRadius = new CornerRadius(10), Padding = new Thickness(8, 1, 8, 2), VerticalAlignment = VerticalAlignment.Top, Background = col[0] == "you" && list.Count > 0 ? Th.Orange : Th.B(0x1AFFFFFF),
                    Child = new TextBlock { Text = list.Count.ToString(), FontWeight = FontWeights.Bold, FontSize = 12.5, Foreground = col[0] == "you" && list.Count > 0 ? Th.B(0xFF1A0E04) : Th.Text2 } };
                Grid.SetColumn(cnt, 1); hd.Children.Add(cnt);
                colGrid.Children.Add(hd);
                var cards = new StackPanel { Margin = new Thickness(10, 0, 10, 10) };
                if (list.Count == 0) { var e = T("Nothing here", 13.5, Th.Text3); e.HorizontalAlignment = HorizontalAlignment.Center; e.Margin = new Thickness(0, 24, 0, 0); cards.Children.Add(e); }
                foreach (var c in list) cards.Children.Add(CardView(c));
                var sc = Scroll(cards, "col-" + col[0]); Grid.SetRow(sc, 1); colGrid.Children.Add(sc);
                var box = new Border { Background = Th.B(0x0AFFFFFF), BorderBrush = col[0] == "you" && list.Count > 0 ? Th.B(0x66FF8C42) : Th.Stroke, BorderThickness = new Thickness(1), CornerRadius = new CornerRadius(12), Margin = new Thickness(0, 0, 12, 0), Child = colGrid };
                cols.Children.Add(box);
            }
            g.Children.Add(cols);
            var closed = s.Cards.Where(c => c.Stage == "closed").ToList();
            if (closed.Count > 0)
            {
                var exp = new StackPanel { Margin = new Thickness(4, 14, 12, 0) };
                var hd = new StackPanel { Orientation = Orientation.Horizontal };
                hd.Children.Add(Ic(closedOpen ? "" : "", 12, Th.Text2));
                var ht = T("Stopped, wishes, not possible and not a bug (" + closed.Count + ")", 14, Th.Text2, FontWeights.SemiBold); ht.Margin = new Thickness(10, 0, 0, 0); hd.Children.Add(ht);
                var tog = new Button { Style = (Style)Resources["Plain"], Content = hd, HorizontalAlignment = HorizontalAlignment.Left };
                tog.Click += (o, e) => { closedOpen = !closedOpen; lastSig = ""; Tick(); };
                exp.Children.Add(tog);
                if (closedOpen)
                {
                    var wrap = new WrapPanel { Margin = new Thickness(0, 10, 0, 0) };
                    foreach (var c in closed) { var v = CardView(c); ((FrameworkElement)v).Width = 300; ((FrameworkElement)v).Margin = new Thickness(0, 0, 10, 10); wrap.Children.Add(v); }
                    exp.Children.Add(new ScrollViewer { Content = wrap, MaxHeight = 280, VerticalScrollBarVisibility = ScrollBarVisibility.Auto });
                }
                Grid.SetRow(exp, 2); g.Children.Add(exp);
            }
            return g;
        }

        UIElement CardView(Card c)
        {
            var sp = new StackPanel();
            if (c.Now)
            {
                var nr = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(0, 0, 0, 8) };
                nr.Children.Add(new ProgressBar { IsIndeterminate = true, Width = 26, Height = 3, Foreground = Th.Orange, Background = Th.Card, BorderThickness = new Thickness(0), VerticalAlignment = VerticalAlignment.Center });
                var nt = T("Being fixed right now", 12.5, Th.B(0xFFFFB067), FontWeights.SemiBold); nt.Margin = new Thickness(8, 0, 0, 0); nr.Children.Add(nt);
                sp.Children.Add(nr);
            }
            var title = T(c.Title, 15, Th.Text, FontWeights.SemiBold); title.MaxHeight = 62; title.TextTrimming = TextTrimming.CharacterEllipsis; sp.Children.Add(title);
            var meta = new WrapPanel { Margin = new Thickness(0, 6, 0, 8) };
            if (c.Player != "") { meta.Children.Add(Ic(Th.PERSON, 12, Th.Text3)); var pt = T(c.Player, 12.5, Th.Text3); pt.Margin = new Thickness(5, 0, 12, 0); meta.Children.Add(pt); }
            meta.Children.Add(Ic(Th.CLOCK, 12, Th.Text3)); var at = T(Ago(c.Created), 12.5, Th.Text3); at.Margin = new Thickness(5, 0, 0, 0); meta.Children.Add(at);
            sp.Children.Add(meta);
            if (c.Why != "") { var w = T(c.Why, 13, Th.B(0xFFFFB067), FontWeights.SemiBold); w.Margin = new Thickness(0, 0, 0, 8); sp.Children.Add(w); }
            var chips = new WrapPanel();
            if (c.Test) chips.Children.Add(Chip("TEST"));
            foreach (var t in c.AllTags) chips.Children.Add(Chip(t));
            if (chips.Children.Count > 0) sp.Children.Add(chips);
            if (c.LastText != "")
            {
                var lt = new TextBlock { TextWrapping = TextWrapping.Wrap, FontSize = 13, Foreground = Th.Text2, MaxHeight = 38, TextTrimming = TextTrimming.CharacterEllipsis };
                lt.Inlines.Add(new System.Windows.Documents.Run(WhoName(c.LastWho) + ": ") { FontWeight = FontWeights.SemiBold, Foreground = Th.Text });
                lt.Inlines.Add(new System.Windows.Documents.Run(c.LastText));
                sp.Children.Add(new Border { BorderBrush = Th.B(0x33FFFFFF), BorderThickness = new Thickness(2, 0, 0, 0), Padding = new Thickness(9, 0, 0, 0), Margin = new Thickness(0, 4, 0, 0), Child = lt });
            }
            var box = new Border { Background = c.Now ? Th.B(0x1FFF8C42) : Th.Card, BorderBrush = c.Now ? Th.Orange : Th.Stroke, BorderThickness = new Thickness(1), CornerRadius = new CornerRadius(9), Padding = new Thickness(13, 12, 13, 12), Margin = new Thickness(0, 0, 0, 9), Child = sp, Cursor = Cursors.Hand, ToolTip = "Open this report" };
            var normal = box.Background;
            box.MouseEnter += (s, e) => box.Background = c.Now ? Th.B(0x2BFF8C42) : Th.CardHover;
            box.MouseLeave += (s, e) => box.Background = normal;
            box.MouseLeftButtonUp += (s, e) => OpenDetail(c);
            return box;
        }

        // ---------- page: Fixer runs
        UIElement RunsPage(Snapshot s)
        {
            var g = new Grid { Margin = new Thickness(28, 24, 28, 20) };
            g.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto }); g.RowDefinitions.Add(new RowDefinition());
            var head = new StackPanel { Margin = new Thickness(4, 0, 0, 18) };
            head.Children.Add(H("Fixer runs", 28));
            head.Children.Add(T("Every 30 minutes the fixer looks for new reports and your answers. Pick a run to see what it did, step by step.", 14.5, Th.Text3));
            g.Children.Add(head);
            var body = new Grid(); Grid.SetRow(body, 1);
            body.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(400) }); body.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(18) }); body.ColumnDefinitions.Add(new ColumnDefinition());
            var list = new StackPanel();
            if (runSel == null || !s.Runs.Any(r => r.Id == runSel)) { var first = s.Runs.FirstOrDefault(r => !r.Quiet || r.State != "done") ?? s.Runs.FirstOrDefault(); runSel = first != null ? first.Id : null; }
            var quiet = new List<Run>();
            Action flush = () =>
            {
                if (quiet.Count == 0) return;
                var a = quiet[quiet.Count - 1]; var b = quiet[0];
                var t = T(quiet.Count == 1 ? Day(b.Start) + ": checked, nothing new" : quiet.Count + " quick checks, nothing new  (" + a.Start.ToString("HH:mm") + " – " + b.Start.ToString("HH:mm") + ")", 13, Th.Text3);
                list.Children.Add(new Border { BorderBrush = Th.Stroke, BorderThickness = new Thickness(1), CornerRadius = new CornerRadius(9), Padding = new Thickness(13, 9, 13, 9), Margin = new Thickness(0, 0, 0, 8), Child = t });
                quiet.Clear();
            };
            foreach (var r in s.Runs.Take(80))
            {
                if (r.Quiet && r.State == "done" && r.Id != runSel) { quiet.Add(r); continue; }
                flush();
                var sp = new StackPanel();
                var top = new Grid(); top.ColumnDefinitions.Add(new ColumnDefinition()); top.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                top.Children.Add(T(Day(r.Start), 14, Th.Text, FontWeights.SemiBold));
                string st; Brush sc;
                switch (r.State) { case "working": st = "Running now"; sc = Th.Orange; break; case "stuck": st = "Stuck?"; sc = Th.Red; break; case "stopped": st = "Stopped"; sc = Th.Yellow; break; default: st = r.Fixing ? "Worked on something" : "Done"; sc = Th.Green; break; }
                var stt = T(st, 12, sc, FontWeights.SemiBold); Grid.SetColumn(stt, 1); top.Children.Add(stt);
                sp.Children.Add(top);
                var res = T(r.State == "working" ? r.Result : r.Result, 13, Th.Text2); res.MaxHeight = 36; res.TextTrimming = TextTrimming.CharacterEllipsis; res.Margin = new Thickness(0, 4, 0, 0); sp.Children.Add(res);
                var sel = r.Id == runSel;
                var box = new Border { Background = sel ? Th.B(0x24FFFFFF) : Th.Card, BorderBrush = sel ? Th.Orange : Th.Stroke, BorderThickness = new Thickness(1), CornerRadius = new CornerRadius(9), Padding = new Thickness(13, 11, 13, 11), Margin = new Thickness(0, 0, 0, 8), Child = sp, Cursor = Cursors.Hand };
                var id = r.Id;
                box.MouseLeftButtonUp += (o, e) => { runSel = id; lastSig = ""; Tick(); };
                list.Children.Add(box);
            }
            flush();
            if (s.Runs.Count == 0) list.Children.Add(T("No runs in the last three days.", 14, Th.Text3));
            body.Children.Add(Scroll(list, "runlist"));
            var run = s.Runs.FirstOrDefault(r => r.Id == runSel);
            var tl = new StackPanel();
            if (run != null)
            {
                tl.Children.Add(H("Run of " + Day(run.Start), 20));
                var rt = T(run.Result + (run.Mode != "" && run.Mode != "bypassPermissions" ? "  ·  ran in Ask-first mode" : ""), 14, Th.Text2); rt.Margin = new Thickness(0, 4, 0, 16); tl.Children.Add(rt);
                foreach (var l in run.Lines) tl.Children.Add(FeedLine(l, 14));
            }
            var tlBox = Surface(Scroll(tl, "timeline-" + runSel), 20);
            Grid.SetColumn(tlBox, 2); body.Children.Add(tlBox);
            g.Children.Add(body);
            return g;
        }

        // ---------- report panel (opens a report inside the app)
        void OpenDetail(Card c)
        {
            detail = c; detailLoaded = -1;
            detailTab = c.FixerId != null ? "fixer" : "player";
            BuildDetail();
        }

        void BuildDetail()
        {
            overlay.Children.Clear();
            var c = detail;
            if (detailTab == "fixer" && c.FixerId == null) detailTab = "player";
            if (detailTab == "player" && c.PlayerId == null) detailTab = "fixer";
            var dim = new Border { Background = Th.Dim };
            dim.MouseLeftButtonUp += (s, e) => CloseOverlay();
            overlay.Children.Add(dim);
            detailPanel = new Grid { Width = Math.Min(700, Math.Max(560, ActualWidth * 0.42)), HorizontalAlignment = HorizontalAlignment.Right, Background = Th.Panel };
            detailPanel.Effect = new DropShadowEffect { BlurRadius = 40, ShadowDepth = 0, Opacity = 0.55, Color = Colors.Black };
            for (int i = 0; i < 4; i++) detailPanel.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            detailPanel.RowDefinitions.Add(new RowDefinition());
            detailPanel.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

            // header
            var head = new Grid { Margin = new Thickness(26, 22, 18, 0) };
            head.ColumnDefinitions.Add(new ColumnDefinition()); head.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            var ht = new StackPanel();
            var stageName = Cols.Where(x => x[0] == c.Stage).Select(x => x[2]).FirstOrDefault() ?? (c.Stopped ? "Stopped" : "Closed");
            ht.Children.Add(T(stageName.ToUpper(), 11.5, c.Stage == "you" ? Th.Orange : Th.Text3, FontWeights.Bold));
            var tt = T(c.Title, 21, Th.Text, FontWeights.SemiBold); tt.FontFamily = Th.Display; tt.Margin = new Thickness(0, 4, 0, 6); ht.Children.Add(tt);
            var meta = new WrapPanel();
            if (c.Player != "") { meta.Children.Add(Ic(Th.PERSON, 13, Th.Text3)); var pt = T(c.Player, 13.5, Th.Text3); pt.Margin = new Thickness(6, 0, 14, 0); meta.Children.Add(pt); }
            meta.Children.Add(Ic(Th.CLOCK, 13, Th.Text3)); var at = T("reported " + Ago(c.Created), 13.5, Th.Text3); at.Margin = new Thickness(6, 0, 0, 0); meta.Children.Add(at);
            ht.Children.Add(meta);
            var chips = new WrapPanel { Margin = new Thickness(0, 10, 0, 0) };
            if (c.Test) chips.Children.Add(Chip("TEST"));
            foreach (var t in c.AllTags) chips.Children.Add(Chip(t));
            ht.Children.Add(chips);
            head.Children.Add(ht);
            var close = new Button { Content = Ic(Th.X, 13), Style = (Style)Resources["Btn"], Background = Brushes.Transparent, BorderBrush = Brushes.Transparent, Padding = new Thickness(10), VerticalAlignment = VerticalAlignment.Top, ToolTip = "Close (Esc)" };
            close.Click += (s, e) => CloseOverlay();
            Grid.SetColumn(close, 1); head.Children.Add(close);
            detailPanel.Children.Add(head);

            // actions
            var acts = new WrapPanel { Margin = new Thickness(26, 12, 26, 4) };
            Action<Button> add = b => { b.Margin = new Thickness(0, 0, 8, 8); acts.Children.Add(b); };
            add(Btn("Open in Discord", Th.OPEN, "discord", () => OpenDiscord(detailTab == "player" ? c.PlayerId ?? c.FixerId : c.FixerId ?? c.PlayerId)));
            if (c.FixerId != null && !c.Stopped) add(Btn("Stop", Th.PAUSE, null, StopDialog, "The fixer leaves this report alone until you resume it"));
            if (c.FixerId != null && c.Stopped) add(Btn("Resume", Th.PLAY, "accent", ResumeDialog, "The fixer picks this report up again"));
            add(Btn("Delete", Th.DELETE, "danger", DeleteDialog, "Delete this report from Discord"));
            Grid.SetRow(acts, 1); detailPanel.Children.Add(acts);

            // tabs
            var tabs = new StackPanel { Orientation = Orientation.Horizontal, Margin = new Thickness(26, 6, 26, 0) };
            Action<string, string, string> tab = (key, label, id) =>
            {
                if (id == null) return;
                var sel = detailTab == key;
                var b = new Button { Style = (Style)Resources["Plain"], Margin = new Thickness(0, 0, 22, 0) };
                var sp = new StackPanel();
                sp.Children.Add(T(label, 14.5, sel ? Th.Text : Th.Text3, FontWeights.SemiBold));
                sp.Children.Add(new Border { Height = 3, CornerRadius = new CornerRadius(2), Background = sel ? Th.Orange : Brushes.Transparent, Margin = new Thickness(0, 8, 0, 0) });
                b.Content = sp;
                b.Click += (s, e) => { detailTab = key; detailLoaded = -1; BuildDetail(); };
                tabs.Children.Add(b);
            };
            tab("fixer", c.Request ? "Your request" : "Fixer's post", c.FixerId);
            tab("player", "Player's post", c.PlayerId);
            Grid.SetRow(tabs, 2); detailPanel.Children.Add(tabs);
            var line = new Border { Height = 1, Background = Th.Stroke }; Grid.SetRow(line, 3); detailPanel.Children.Add(line);

            // messages
            detailMsgs = new StackPanel { Margin = new Thickness(26, 18, 26, 18) };
            detailMsgs.Children.Add(Loading("Loading messages…"));
            detailScroll = new ScrollViewer { Content = detailMsgs, VerticalScrollBarVisibility = ScrollBarVisibility.Auto };
            Grid.SetRow(detailScroll, 4); detailPanel.Children.Add(detailScroll);

            // write box
            var bottom = new Border { BorderBrush = Th.Stroke, BorderThickness = new Thickness(0, 1, 0, 0), Padding = new Thickness(26, 14, 26, 18) };
            if (detailTab == "fixer" && c.FixerId != null)
            {
                var g = new Grid();
                g.ColumnDefinitions.Add(new ColumnDefinition()); g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                var box = new TextBox { AcceptsReturn = true, TextWrapping = TextWrapping.Wrap, MinHeight = 46, MaxHeight = 160, VerticalScrollBarVisibility = ScrollBarVisibility.Auto };
                var hint = new TextBlock { Text = "Write to the fixer…", Foreground = Th.Text3, Margin = new Thickness(12, 9, 0, 0), IsHitTestVisible = false, FontSize = 14 };
                box.TextChanged += (s, e) => hint.Visibility = box.Text.Length == 0 ? Visibility.Visible : Visibility.Collapsed;
                var holder = new Grid(); holder.Children.Add(box); holder.Children.Add(hint);
                g.Children.Add(holder);
                var send = Btn("Send", Th.SEND, "accent", null); send.Margin = new Thickness(10, 0, 0, 0); send.VerticalAlignment = VerticalAlignment.Bottom;
                Action doSend = () => SendToFixer(box, send);
                send.Click += (s, e) => doSend();
                box.PreviewKeyDown += (s, e) => { if (e.Key == Key.Enter && Keyboard.Modifiers == ModifierKeys.Control) { e.Handled = true; doSend(); } };
                Grid.SetColumn(send, 1); g.Children.Add(send);
                var sp = new StackPanel(); sp.Children.Add(g);
                var note = T("The fixer reads it on its next check (" + store.Current.Next.ToString("HH:mm") + "). Ctrl+Enter sends.", 12.5, Th.Text3); note.Margin = new Thickness(2, 8, 0, 0); sp.Children.Add(note);
                bottom.Child = sp;
            }
            else
            {
                bottom.Child = T("The helper bot and the fixer answer the player here. To write to the player yourself, open the post in Discord.", 13, Th.Text3);
            }
            Grid.SetRow(bottom, 5); detailPanel.Children.Add(bottom);

            overlay.Children.Add(detailPanel);
            var tr = new TranslateTransform(60, 0); detailPanel.RenderTransform = tr;
            tr.BeginAnimation(TranslateTransform.XProperty, new DoubleAnimation(60, 0, TimeSpan.FromMilliseconds(220)) { EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } });
            detailPanel.BeginAnimation(OpacityProperty, new DoubleAnimation(0, 1, TimeSpan.FromMilliseconds(180)));
            LoadMessages();
        }

        void RefreshDetail(Snapshot s)
        {
            var now = s.Cards.FirstOrDefault(x => x.Id == detail.Id || (x.PlayerId != null && x.PlayerId == detail.PlayerId) || (x.FixerId != null && x.FixerId == detail.FixerId));
            if (now == null) return;
            bool changed = now.Stage != detail.Stage || now.Stopped != detail.Stopped || string.Join(",", now.AllTags) != string.Join(",", detail.AllTags) || (now.FixerId != detail.FixerId);
            var newer = now.LastTime != detail.LastTime;
            detail = now;
            if (changed) BuildDetail(); else if (newer) LoadMessages();
        }

        async void LoadMessages()
        {
            var c = detail; var tab = detailTab;
            var id = tab == "player" ? c.PlayerId : c.FixerId;
            if (id == null) return;
            List<Msg> msgs = null; string err = null;
            if (store.Demo) msgs = DemoMessages(tab);
            else
            {
                try { msgs = await Task.Run(() => store.Discord.Messages(id, tab == "player" ? "bugs" : "fixer")); }
                catch (Exception e) { err = e.Message; }
            }
            if (detail != c || detailTab != tab || detailMsgs == null) return;
            detailLoaded = c.LastTime;
            detailMsgs.Children.Clear();
            if (err != null) { detailMsgs.Children.Add(ErrorBar(err)); return; }
            foreach (var m in msgs) detailMsgs.Children.Add(MessageView(m));
            if (msgs.Count == 0) detailMsgs.Children.Add(T("No messages.", 14, Th.Text3));
            var op = Dispatcher.BeginInvoke(DispatcherPriority.Loaded, (Action)(() => detailScroll.ScrollToEnd())); // newest message in view
        }

        UIElement MessageView(Msg m)
        {
            var g = new Grid { Margin = new Thickness(0, 0, 0, 18) };
            g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(48) }); g.ColumnDefinitions.Add(new ColumnDefinition());
            Brush bg; string glyph = null; string letter = null;
            if (m.Who == "fixer") { bg = Th.Orange; glyph = Th.BUG; }
            else if (m.Who == "helper") { bg = Th.Blurple; glyph = Th.CHAT; }
            else if (m.Who == "you") { bg = Th.B(0xFFFFB067); letter = "D"; }
            else { var palette = new[] { Th.Teal, Th.Pink, Th.Purple, Th.Blue, Th.Green }; bg = palette[Math.Abs(m.Who.GetHashCode()) % palette.Length]; letter = m.Who.Length > 0 ? m.Who.Substring(0, 1).ToUpper() : "?"; }
            var av = new Border { Width = 36, Height = 36, CornerRadius = new CornerRadius(18), Background = bg, VerticalAlignment = VerticalAlignment.Top };
            av.Child = glyph != null ? (UIElement)new TextBlock { Text = glyph, FontFamily = Th.Icons, FontSize = 16, Foreground = Th.B(0xFF15161A), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center }
                : new TextBlock { Text = letter, FontSize = 15, FontWeight = FontWeights.Bold, Foreground = Th.B(0xFF15161A), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            g.Children.Add(av);
            var sp = new StackPanel(); Grid.SetColumn(sp, 1);
            var top = new StackPanel { Orientation = Orientation.Horizontal };
            top.Children.Add(T(WhoName(m.Who), 14, m.Who == "you" ? Th.B(0xFFFFB067) : Th.Text, FontWeights.SemiBold));
            if (m.FromApp) top.Children.Add(new Border { Margin = new Thickness(8, 1, 0, 0), CornerRadius = new CornerRadius(6), Padding = new Thickness(6, 0, 6, 1), Background = Th.B(0x1AFFFFFF), Child = T("from this app", 11, Th.Text3) });
            var tm = T(Day(Local(m.Time)), 12, Th.Text3); tm.Margin = new Thickness(10, 1, 0, 0); top.Children.Add(tm);
            sp.Children.Add(top);
            var text = Regex.Replace(m.Text ?? "", @"\*\*(.+?)\*\*", "$1");
            text = Regex.Replace(text, @"__(.+?)__", "$1").Replace("`", "");
            if (text.Trim() != "") { var tb = new TextBox { Text = text, Style = (Style)Resources["ReadText"], Margin = new Thickness(0, 3, 0, 0) }; sp.Children.Add(tb); }
            foreach (var url in m.Images.Take(4))
            {
                try
                {
                    var bmp = new BitmapImage();
                    bmp.BeginInit(); bmp.UriSource = new Uri(url); bmp.DecodePixelWidth = 480; bmp.CacheOption = BitmapCacheOption.OnLoad; bmp.EndInit();
                    var img = new Image { Source = bmp, MaxHeight = 260, MaxWidth = 460, Stretch = Stretch.Uniform, HorizontalAlignment = HorizontalAlignment.Left, Cursor = Cursors.Hand, ToolTip = "Open the picture" };
                    var u = url;
                    img.MouseLeftButtonUp += (s, e) => { try { Process.Start(u); } catch { } };
                    sp.Children.Add(new Border { CornerRadius = new CornerRadius(8), Margin = new Thickness(0, 8, 0, 0), HorizontalAlignment = HorizontalAlignment.Left, BorderBrush = Th.Stroke, BorderThickness = new Thickness(1), Child = img });
                }
                catch { }
            }
            g.Children.Add(sp);
            return g;
        }

        void CloseOverlay() { overlay.Children.Clear(); detail = null; detailMsgs = null; }

        // ---------- dialogs
        void Dialog(string title, string body, string confirm, string kind, string check, bool checkOn, Action<bool> ok, UIElement extra = null)
        {
            var dim = new Border { Background = Th.Dim };
            var sp = new StackPanel();
            sp.Children.Add(H(title, 20));
            var bt = T(body, 14.5, Th.Text2); bt.Margin = new Thickness(0, 10, 0, 0); sp.Children.Add(bt);
            if (extra != null) sp.Children.Add(extra);
            CheckBox cb = null;
            if (check != null) { cb = new CheckBox { Content = T(check, 14), IsChecked = checkOn, Margin = new Thickness(0, 18, 0, 0) }; sp.Children.Add(cb); }
            var btns = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(0, 26, 0, 0) };
            var host = new Grid();
            Action closeMe = () => { overlay.Children.Remove(host); };
            var cancel = Btn("Cancel", null, null, () => closeMe()); cancel.Margin = new Thickness(0, 0, 10, 0);
            var yes = Btn(confirm, null, kind, () => { closeMe(); ok(cb != null && cb.IsChecked == true); });
            if (kind == "danger") { yes.Background = Th.Red; yes.BorderBrush = Th.Red; ((TextBlock)((StackPanel)yes.Content).Children[0]).Foreground = Brushes.White; }
            btns.Children.Add(cancel); btns.Children.Add(yes);
            sp.Children.Add(btns);
            var card = new Border { Width = 520, Background = Th.Panel, BorderBrush = Th.B(0x26FFFFFF), BorderThickness = new Thickness(1), CornerRadius = new CornerRadius(12), Padding = new Thickness(26, 24, 26, 22),
                HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center, Child = sp, Effect = new DropShadowEffect { BlurRadius = 40, ShadowDepth = 6, Opacity = 0.6, Color = Colors.Black } };
            host.Children.Add(dim); host.Children.Add(card);
            dim.MouseLeftButtonUp += (s, e) => closeMe();
            overlay.Children.Add(host);
            card.BeginAnimation(OpacityProperty, new DoubleAnimation(0, 1, TimeSpan.FromMilliseconds(150)));
        }

        async void Act(string done, Action work)
        {
            try { await Task.Run(work); Toast(done); store.RefreshSoon(); }
            catch (Exception e) { Toast("That didn't work: " + e.Message, true); }
        }

        void StopDialog()
        {
            var c = detail;
            Dialog("Stop this report?", "The fixer leaves it alone until you press Resume. Nothing is deleted, and the player is not told.", "Stop it", "accent", null, false, _ =>
                Act("Stopped. The fixer leaves this report alone.", () => { store.Discord.SetFixerTag(c.FixerId, "Stopped"); store.Discord.Write(c.FixerId, "⏸️ Stopped: leave this report alone until I resume it."); }));
        }
        void ResumeDialog()
        {
            var c = detail;
            Dialog("Resume this report?", "The fixer picks it up again on its next check (" + store.Current.Next.ToString("HH:mm") + ").", "Resume", "accent", null, false, _ =>
                Act("Resumed. The fixer picks it up on its next check.", () => { store.Discord.SetFixerTag(c.FixerId, "New report"); store.Discord.Write(c.FixerId, "▶️ Resumed: please pick this report up again."); }));
        }
        void DeleteDialog()
        {
            var c = detail;
            var parts = new List<string>();
            if (c.FixerId != null) parts.Add("the fixer's post in #bug-fixer");
            if (c.FixerId == null && c.PlayerId != null) parts.Add("the player's post in #bugs-and-issues");
            parts.Add("its report line in #bot-logs (so the fixer won't pick it up again)");
            var both = c.FixerId != null && c.PlayerId != null;
            Dialog("Delete this report?", "This deletes " + string.Join(", ", parts) + ". It can't be undone.", "Delete", "danger",
                both ? "Also delete the player's post in #bugs-and-issues" : null, c.Test, also =>
                {
                    Act("Deleted.", () => store.Discord.DeleteReport(c.FixerId, c.PlayerId, also || c.FixerId == null, c.ReportId));
                    CloseOverlay();
                });
        }
        void PauseDialog(bool pause)
        {
            if (pause)
                Dialog("Pause the bug fixer?", "It keeps starting every 30 minutes, but stops right away until you resume it. Players' reports still come in and wait on the board.", "Pause", "accent", null, false, _ =>
                { try { store.SetPaused(true); Toast("The fixer is paused."); lastSig = ""; Tick(); } catch (Exception e) { Toast("That didn't work: " + e.Message, true); } });
            else { try { store.SetPaused(false); Toast("The fixer is back on. Next check around " + store.Current.Next.ToString("HH:mm") + "."); lastSig = ""; Tick(); } catch (Exception e) { Toast("That didn't work: " + e.Message, true); } }
        }
        void GoLiveDialog(Snapshot s)
        {
            var pid = s.PinnedId;
            Dialog("Put the fixes live?", "The fixer updates the public server on its next check (around " + s.Next.ToString("HH:mm") + "), sets the posts to Live and tells the players. The game server is away for about 3 seconds.", "Put it live", "teal", null, false, _ =>
                Act("Sent. The fixer puts it live on its next check.", () => store.Discord.Write(pid, "update the public server")));
        }
        void NewRequestDialog()
        {
            var form = new StackPanel { Margin = new Thickness(0, 16, 0, 0) };
            form.Children.Add(T("Title", 13, Th.Text3, FontWeights.SemiBold));
            var title = new TextBox { Margin = new Thickness(0, 6, 0, 14) };
            form.Children.Add(title);
            form.Children.Add(T("What should the fixer do?", 13, Th.Text3, FontWeights.SemiBold));
            var text = new TextBox { Margin = new Thickness(0, 6, 0, 0), AcceptsReturn = true, TextWrapping = TextWrapping.Wrap, MinHeight = 110, MaxHeight = 220, VerticalScrollBarVisibility = ScrollBarVisibility.Auto };
            form.Children.Add(text);
            Dialog("New request", "Opens a post in #bug-fixer. The fixer reads it on its next check (" + store.Current.Next.ToString("HH:mm") + ") and answers in the post.", "Send request", "accent", null, false, _ =>
            {
                var t = title.Text.Trim(); var x = text.Text.Trim();
                if (t == "" || x == "") { Toast("Write a title and what the fixer should do.", true); return; }
                Act("Request sent. It shows on the board in a moment.", () => store.Discord.NewRequest(t, x));
            }, form);
            Dispatcher.BeginInvoke(DispatcherPriority.Input, (Action)(() => title.Focus()));
        }

        async void SendToFixer(TextBox box, Button send)
        {
            var text = box.Text.Trim();
            if (text == "") return;
            var c = detail;
            send.IsEnabled = false;
            try
            {
                await Task.Run(() => store.Discord.Write(c.FixerId, text));
                box.Text = ""; Toast("Sent. The fixer reads it on its next check."); store.RefreshSoon();
                detailLoaded = -1; LoadMessages();
            }
            catch (Exception e) { Toast("Not sent: " + e.Message, true); }
            finally { send.IsEnabled = true; }
        }

        void OpenDiscord(string id)
        {
            if (id == null) return;
            var url = store.Discord.Link(id);
            bool app = false;
            try { using (var k = Microsoft.Win32.Registry.ClassesRoot.OpenSubKey("discord")) app = k != null; } catch { }
            try { Process.Start(app ? "discord://-/channels/" + store.Discord.GuildId + "/" + id : url); } catch { try { Process.Start(url); } catch { } }
        }

        static List<Msg> DemoMessages(string tab)
        {
            long n = (long)(DateTime.UtcNow - new DateTime(1970, 1, 1)).TotalMilliseconds, m = 60000;
            if (tab == "player") return new List<Msg> {
                new Msg { Who = "Ronin", Text = "My pet doesn't attack in boss fights. It works in training.", Time = n - 130 * m },
                new Msg { Who = "helper", Text = "Thanks Ronin! Which boss was it, and does it happen every time?", Time = n - 128 * m },
                new Msg { Who = "Ronin", Text = "Chapter 5 boss, every time. Pet is Gamakichi level 40.", Time = n - 120 * m } };
            return new List<Msg> {
                new Msg { Who = "helper", Text = "🐞 Bug report from #bugs-and-issues (Ronin)\nPet does not attack in boss fights\n• Where: Training chapter 5, the boss\n• Every time: yes", Time = n - 118 * m },
                new Msg { Who = "fixer", Text = "Found it: the boss fight is built without the pet. Fixing it now and adding a check so it can't come back.", Time = n - 20 * m },
                new Msg { Who = "you", FromApp = true, Owner = true, Text = "Nice, also check the world boss please.", Time = n - 6 * m } };
        }

        protected override void OnClosing(System.ComponentModel.CancelEventArgs e)
        {
            if (!Quitting && !Snapshotting) { e.Cancel = true; Hide(); Program.TellTray(); }
            base.OnClosing(e);
        }

        // ---------- screenshots for checking the design without touching the screen (--snapshot)
        public void SaveSnapshot(string file)
        {
            UpdateLayout();
            var w = (int)ActualWidth; var h = (int)ActualHeight;
            var v = new DrawingVisual();
            using (var dc = v.RenderOpen()) dc.DrawRectangle(new LinearGradientBrush(Color.FromRgb(0x22, 0x23, 0x29), Color.FromRgb(0x1A, 0x1B, 0x20), 90), null, new Rect(0, 0, w, h));
            var bmp = new RenderTargetBitmap(w, h, 96, 96, PixelFormats.Pbgra32);
            bmp.Render(v);
            bmp.Render((Visual)Content);
            var enc = new PngBitmapEncoder(); enc.Frames.Add(BitmapFrame.Create(bmp));
            using (var fs = File.Create(file)) enc.Save(fs);
        }
        public void ShowPage(string p) { page = p; lastSig = ""; Tick(); }
        public void OpenFirst(string stage) { var c = store.Current.Cards.FirstOrDefault(x => x.Stage == stage) ?? store.Current.Cards.FirstOrDefault(); if (c != null) OpenDetail(c); }
    }

}
