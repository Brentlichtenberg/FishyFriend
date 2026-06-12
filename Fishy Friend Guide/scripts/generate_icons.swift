#!/usr/bin/env swift
import SwiftUI
import AppKit

struct AnglerCompassLogoView: View {
    var size: CGFloat = 300
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color(red: 0.06, green: 0.12, blue: 0.07))
            Circle()
                .stroke(Color(red: 0.118, green: 0.235, blue: 0.145), lineWidth: 5.0 * (size / 400))
                .frame(width: size * 0.76, height: size * 0.76)
            CompassTicksView(color: Color(red: 0.118, green: 0.235, blue: 0.145), size: size * 0.76)
            ZStack {
                GeometryReader { geo in
                    let cx = geo.size.width / 2; let cy = geo.size.height / 2
                    let w = 12.0*(size/400); let hS = 100.0*(size/400); let hL = 130.0*(size/400)
                    Path { p in p.move(to:CGPoint(x:cx,y:cy-hL)); p.addLine(to:CGPoint(x:cx+w,y:cy)); p.addLine(to:CGPoint(x:cx,y:cy)); p.closeSubpath() }.fill(Color(red:0.255,green:0.604,blue:0.427))
                    Path { p in p.move(to:CGPoint(x:cx,y:cy-hL)); p.addLine(to:CGPoint(x:cx-w,y:cy)); p.addLine(to:CGPoint(x:cx,y:cy)); p.closeSubpath() }.fill(Color(red:0.043,green:0.145,blue:0.071))
                    Path { p in p.move(to:CGPoint(x:cx,y:cy+hL)); p.addLine(to:CGPoint(x:cx-w,y:cy)); p.addLine(to:CGPoint(x:cx,y:cy)); p.closeSubpath() }.fill(Color(red:0.255,green:0.604,blue:0.427))
                    Path { p in p.move(to:CGPoint(x:cx,y:cy+hL)); p.addLine(to:CGPoint(x:cx+w,y:cy)); p.addLine(to:CGPoint(x:cx,y:cy)); p.closeSubpath() }.fill(Color(red:0.043,green:0.145,blue:0.071))
                    Path { p in p.move(to:CGPoint(x:cx-hS,y:cy)); p.addLine(to:CGPoint(x:cx,y:cy-w)); p.addLine(to:CGPoint(x:cx,y:cy)); p.closeSubpath() }.fill(Color(red:0.255,green:0.604,blue:0.427))
                    Path { p in p.move(to:CGPoint(x:cx-hS,y:cy)); p.addLine(to:CGPoint(x:cx,y:cy+w)); p.addLine(to:CGPoint(x:cx,y:cy)); p.closeSubpath() }.fill(Color(red:0.043,green:0.145,blue:0.071))
                    Path { p in p.move(to:CGPoint(x:cx+hS,y:cy)); p.addLine(to:CGPoint(x:cx,y:cy+w)); p.addLine(to:CGPoint(x:cx,y:cy)); p.closeSubpath() }.fill(Color(red:0.255,green:0.604,blue:0.427))
                    Path { p in p.move(to:CGPoint(x:cx+hS,y:cy)); p.addLine(to:CGPoint(x:cx,y:cy-w)); p.addLine(to:CGPoint(x:cx,y:cy)); p.closeSubpath() }.fill(Color(red:0.043,green:0.145,blue:0.071))
                }
            }.frame(width: size, height: size)
            FishingFlyView(size: size * 0.88).rotationEffect(.degrees(-30))
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}

struct CompassTicksView: View {
    var color: Color; var size: CGFloat
    var body: some View {
        ZStack {
            ForEach(0..<12) { i in
                Rectangle().fill(color.opacity(0.4))
                    .frame(width: 2*(size/300), height: i%3==0 ? 12*(size/300) : 6*(size/300))
                    .offset(y: -(size/2)+8).rotationEffect(.degrees(Double(i)*30))
            }
        }
    }
}

struct FishingFlyView: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            let s = size/160
            Path { p in p.move(to:CGPoint(x:40*s,y:15*s)); p.addLine(to:CGPoint(x:-30*s,y:10*s)); p.addCurve(to:CGPoint(x:-10*s,y:48*s),control1:CGPoint(x:-60*s,y:15*s),control2:CGPoint(x:-55*s,y:45*s)); p.addLine(to:CGPoint(x:10*s,y:28*s)) }
                .stroke(Color(red:0.549,green:0.384,blue:0.224),style:StrokeStyle(lineWidth:2.5*s,lineCap:.round,lineJoin:.round))
            Path { p in let c=CGPoint(x:35*s,y:15*s); for pt in [CGPoint(x:45*s,y:35*s),CGPoint(x:36*s,y:42*s),CGPoint(x:25*s,y:45*s),CGPoint(x:12*s,y:44*s),CGPoint(x:5*s,y:38*s)] { p.move(to:c); p.addLine(to:pt) } }
                .stroke(Color(red:0.102,green:0.086,blue:0.078),style:StrokeStyle(lineWidth:1.2*s,lineCap:.round))
            Path { p in p.move(to:CGPoint(x:30*s,y:12*s)); p.addLine(to:CGPoint(x:-50*s,y:-25*s)); p.addLine(to:CGPoint(x:-40*s,y:-10*s)); p.addLine(to:CGPoint(x:-45*s,y:-5*s)); p.addLine(to:CGPoint(x:-32*s,y:10*s)); p.closeSubpath() }
                .fill(Color(red:0.800,green:0.643,blue:0.486))
            Path { p in let o=CGPoint(x:28*s,y:12*s); for d in [CGPoint(x:-48*s,y:-23*s),CGPoint(x:-44*s,y:-18*s),CGPoint(x:-42*s,y:-8*s),CGPoint(x:-38*s,y:-3*s)] { p.move(to:o); p.addLine(to:d) } }
                .stroke(Color(red:0.800,green:0.643,blue:0.486).opacity(0.85),style:StrokeStyle(lineWidth:0.8*s,lineCap:.round))
            Capsule().fill(Color(red:0.243,green:0.153,blue:0.075)).frame(width:70*s,height:23*s).rotationEffect(.degrees(5)).offset(x:-2*s,y:11*s)
            Group { ForEach(0..<5,id:\.self) { i in let st=CGFloat(i)*12-24; Path { p in p.move(to:CGPoint(x:st*s,y:0)); p.addLine(to:CGPoint(x:(st+6)*s,y:21*s)) }.stroke(Color(red:0.831,green:0.686,blue:0.216),style:StrokeStyle(lineWidth:1.5*s,lineCap:.round)) } }.offset(x:-5*s,y:s)
            Circle().fill(Color(red:0.102,green:0.086,blue:0.078)).frame(width:12*s,height:12*s).offset(x:36*s,y:12*s)
            Circle().fill(RadialGradient(colors:[.white.opacity(0.6),Color(red:0.831,green:0.686,blue:0.216),Color(red:0.831,green:0.686,blue:0.216).opacity(0.8)],center:.topLeading,startRadius:0,endRadius:10*s)).frame(width:18*s,height:18*s).offset(x:44*s,y:9*s)
        }.frame(width:size,height:size)
    }
}

let iconDir = "FishyFriendGuide/Assets.xcassets/AppIcon.appiconset"
let iconSizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

let sema = DispatchSemaphore(value: 0)
DispatchQueue.main.async {
    if #available(macOS 13.0, *) {
        for (filename, size) in iconSizes {
            let renderer = ImageRenderer(content: AnglerCompassLogoView(size: size))
            renderer.scale = 1.0
            guard let img = renderer.nsImage,
                  let tiff = img.tiffRepresentation,
                  let bmp = NSBitmapImageRep(data: tiff),
                  let png = bmp.representation(using: .png, properties: [:]) else {
                print("❌ Failed: \(filename)"); continue
            }
            do {
                try png.write(to: URL(fileURLWithPath: "\(iconDir)/\(filename)"))
                print("✅ \(Int(size))×\(Int(size))px → \(filename)")
            } catch { print("❌ Write error \(filename): \(error)") }
        }
        print("\nAll icons rendered to \(iconDir)/")
    }
    sema.signal()
}
sema.wait()
