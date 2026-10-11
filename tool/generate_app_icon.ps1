param([string]$OutputDirectory = (Join-Path $PSScriptRoot '../windows/runner/resources'))
# Original vector-style portfolio/dashboard mark, rendered at each Windows size.
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
public static class PortfolioIcon {
  static GraphicsPath Round(float x,float y,float w,float h,float r) {
    var p=new GraphicsPath(); float d=r*2;
    p.AddArc(x,y,d,d,180,90); p.AddArc(x+w-d,y,d,d,270,90);
    p.AddArc(x+w-d,y+h-d,d,d,0,90); p.AddArc(x,y+h-d,d,d,90,90); p.CloseFigure(); return p;
  }
  static void Box(Graphics g, Color c,float x,float y,float w,float h,float r) {
    using(var b=new SolidBrush(c)) using(var p=Round(x,y,w,h,r)) g.FillPath(b,p);
  }
  static Bitmap Render(int size) {
    var b=new Bitmap(size,size,PixelFormat.Format32bppArgb);
    using(var g=Graphics.FromImage(b)) {
      g.Clear(Color.Transparent); g.SmoothingMode=SmoothingMode.AntiAlias;
      g.PixelOffsetMode=PixelOffsetMode.HighQuality; g.ScaleTransform(size/256f,size/256f);
      using(var p=Round(8,8,240,240,52))
      using(var brush=new LinearGradientBrush(new Point(25,10),new Point(230,250),Color.FromArgb(66,88,211),Color.FromArgb(20,34,56))) g.FillPath(brush,p);
      using(var p=Round(96,62,64,47,13)) using(var pen=new Pen(Color.FromArgb(240,245,255),12)) g.DrawPath(pen,p);
      Box(g,Color.FromArgb(35,8,17,45),51,97,154,112,20);
      Box(g,Color.FromArgb(246,249,255),51,90,154,112,20);
      Box(g,Color.FromArgb(46,66,130),67,107,35,78,8);
      Box(g,Color.FromArgb(117,211,233),75,118,19,6,3);
      Box(g,Color.FromArgb(163,179,223),75,134,19,5,2);
      Box(g,Color.FromArgb(163,179,223),75,148,13,5,2);
      Box(g,Color.FromArgb(65,91,216),113,107,76,33,8);
      Box(g,Color.FromArgb(205,219,248),113,150,32,35,7);
      Box(g,Color.FromArgb(72,183,201),155,150,34,35,7);
    }
    return b;
  }
  public static void Save(string directory) {
    Directory.CreateDirectory(directory);
    using(var preview=Render(512)) preview.Save(Path.Combine(directory,"app_icon.png"),ImageFormat.Png);
    int[] sizes={16,20,24,32,40,48,64,128,256};
    byte[][] images=new byte[sizes.Length][];
    for(int i=0;i<sizes.Length;i++) using(var b=Render(sizes[i])) using(var m=new MemoryStream()) { b.Save(m,ImageFormat.Png); images[i]=m.ToArray(); }
    using(var f=new BinaryWriter(File.Create(Path.Combine(directory,"app_icon.ico")))) {
      f.Write((ushort)0); f.Write((ushort)1); f.Write((ushort)sizes.Length);
      int offset=6+16*sizes.Length;
      for(int i=0;i<sizes.Length;i++) {
        f.Write((byte)(sizes[i]==256?0:sizes[i])); f.Write((byte)(sizes[i]==256?0:sizes[i]));
        f.Write((byte)0); f.Write((byte)0); f.Write((ushort)1); f.Write((ushort)32);
        f.Write(images[i].Length); f.Write(offset); offset+=images[i].Length;
      }
      foreach(var data in images) f.Write(data);
    }
  }
}
"@
[PortfolioIcon]::Save([System.IO.Path]::GetFullPath($OutputDirectory))
