import SwiftUI

/// A high-performance, fully vector SwiftUI Logo representing
/// a fly-fishing fly mounted over a 3D-shaded compass rose.
struct AnglerCompassLogoView: View {
    var size: CGFloat = 300

    var body: some View {
        ZStack {
            // 1. Outer Compass Ring
            Circle()
                .stroke(
                    Color(red: 0.118, green: 0.235, blue: 0.145),
                    lineWidth: 5.0 * (size / 400)
                )
                .frame(width: size * 0.880, height: size * 0.880)

            // 1b. Circular Compass Ticks
            CompassTicksView(color: Color(red: 0.118, green: 0.235, blue: 0.145), size: size * 0.880)

            // 2. 3D-Shaded Compass Rose
            ZStack {
                GeometryReader { geo in
                    let cx = geo.size.width / 2
                    let cy = geo.size.height / 2
                    let w = 12.0 * (size / 400)
                    let hShort = 100.0 * (size / 400)
                    let hLong = 140.0 * (size / 400)

                    // North Needle - Right Half
                    Path { path in
                        path.move(to: CGPoint(x: cx, y: cy - hLong))
                        path.addLine(to: CGPoint(x: cx + w, y: cy))
                        path.addLine(to: CGPoint(x: cx, y: cy))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.255, green: 0.604, blue: 0.427))

                    // North Needle - Left Half
                    Path { path in
                        path.move(to: CGPoint(x: cx, y: cy - hLong))
                        path.addLine(to: CGPoint(x: cx - w, y: cy))
                        path.addLine(to: CGPoint(x: cx, y: cy))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.043, green: 0.145, blue: 0.071))

                    // South Needle - Left Half
                    Path { path in
                        path.move(to: CGPoint(x: cx, y: cy + hLong))
                        path.addLine(to: CGPoint(x: cx - w, y: cy))
                        path.addLine(to: CGPoint(x: cx, y: cy))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.255, green: 0.604, blue: 0.427))

                    // South Needle - Right Half
                    Path { path in
                        path.move(to: CGPoint(x: cx, y: cy + hLong))
                        path.addLine(to: CGPoint(x: cx + w, y: cy))
                        path.addLine(to: CGPoint(x: cx, y: cy))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.043, green: 0.145, blue: 0.071))

                    // West Needle - Top Half
                    Path { path in
                        path.move(to: CGPoint(x: cx - hShort, y: cy))
                        path.addLine(to: CGPoint(x: cx, y: cy - w))
                        path.addLine(to: CGPoint(x: cx, y: cy))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.255, green: 0.604, blue: 0.427))

                    // West Needle - Bottom Half
                    Path { path in
                        path.move(to: CGPoint(x: cx - hShort, y: cy))
                        path.addLine(to: CGPoint(x: cx, y: cy + w))
                        path.addLine(to: CGPoint(x: cx, y: cy))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.043, green: 0.145, blue: 0.071))

                    // East Needle - Bottom Half
                    Path { path in
                        path.move(to: CGPoint(x: cx + hShort, y: cy))
                        path.addLine(to: CGPoint(x: cx, y: cy + w))
                        path.addLine(to: CGPoint(x: cx, y: cy))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.255, green: 0.604, blue: 0.427))

                    // East Needle - Top Half
                    Path { path in
                        path.move(to: CGPoint(x: cx + hShort, y: cy))
                        path.addLine(to: CGPoint(x: cx, y: cy - w))
                        path.addLine(to: CGPoint(x: cx, y: cy))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.043, green: 0.145, blue: 0.071))
                }
            }
            .frame(width: size, height: size)

            // 3. Fly Fishing Fly (Rotated and Styled)
            FishingFlyView(size: size * 1.05)
                .rotationEffect(Angle(degrees: -30.0))
        }
        .frame(width: size, height: size)
    }
}

struct CompassTicksView: View {
    var color: Color
    var size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<12) { index in
                Rectangle()
                    .fill(color.opacity(0.4))
                    .frame(
                        width: 2 * (size / 300),
                        height: index % 3 == 0 ? 12 * (size / 300) : 6 * (size / 300)
                    )
                    .offset(y: -(size / 2) + 8)
                    .rotationEffect(Angle(degrees: Double(index) * 30))
            }
        }
    }
}

struct FishingFlyView: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            let scale = size / 160

            // A. Metal Hook
            Path { path in
                path.move(to: CGPoint(x: 40 * scale, y: 15 * scale))
                path.addLine(to: CGPoint(x: -30 * scale, y: 10 * scale))
                path.addCurve(
                    to: CGPoint(x: -10 * scale, y: 48 * scale),
                    control1: CGPoint(x: -60 * scale, y: 15 * scale),
                    control2: CGPoint(x: -55 * scale, y: 45 * scale)
                )
                path.addLine(to: CGPoint(x: 10 * scale, y: 28 * scale))
            }
            .stroke(Color(red: 0.549, green: 0.384, blue: 0.224),
                    style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round, lineJoin: .round))

            // B. Hackle fibers
            Path { path in
                let startCollar = CGPoint(x: 35 * scale, y: 15 * scale)
                let legEndpoints = [
                    CGPoint(x: 45 * scale, y: 35 * scale),
                    CGPoint(x: 36 * scale, y: 42 * scale),
                    CGPoint(x: 25 * scale, y: 45 * scale),
                    CGPoint(x: 12 * scale, y: 44 * scale),
                    CGPoint(x: 5 * scale, y: 38 * scale),
                ]
                for pt in legEndpoints {
                    path.move(to: startCollar)
                    path.addLine(to: pt)
                }
            }
            .stroke(Color(red: 0.102, green: 0.086, blue: 0.078),
                    style: StrokeStyle(lineWidth: 1.2 * scale, lineCap: .round))

            // C. Elk Hair Wing
            Path { path in
                path.move(to: CGPoint(x: 30 * scale, y: 12 * scale))
                path.addLine(to: CGPoint(x: -50 * scale, y: -25 * scale))
                path.addLine(to: CGPoint(x: -40 * scale, y: -10 * scale))
                path.addLine(to: CGPoint(x: -45 * scale, y: -5 * scale))
                path.addLine(to: CGPoint(x: -32 * scale, y: 10 * scale))
                path.closeSubpath()
            }
            .fill(Color(red: 0.800, green: 0.643, blue: 0.486))

            Path { path in
                let origin = CGPoint(x: 28 * scale, y: 12 * scale)
                path.move(to: origin); path.addLine(to: CGPoint(x: -48 * scale, y: -23 * scale))
                path.move(to: origin); path.addLine(to: CGPoint(x: -44 * scale, y: -18 * scale))
                path.move(to: origin); path.addLine(to: CGPoint(x: -42 * scale, y: -8 * scale))
                path.move(to: origin); path.addLine(to: CGPoint(x: -38 * scale, y: -3 * scale))
            }
            .stroke(Color(red: 0.800, green: 0.643, blue: 0.486).opacity(0.85),
                    style: StrokeStyle(lineWidth: 0.8 * scale, lineCap: .round))

            // D. Fly Body
            Capsule()
                .fill(Color(red: 0.243, green: 0.153, blue: 0.075))
                .frame(width: 70 * scale, height: 23 * scale)
                .rotationEffect(Angle(degrees: 5))
                .offset(x: -2 * scale, y: 11 * scale)

            // E. Golden Ribbing
            Group {
                ForEach(0..<5, id: \.self) { idx in
                    let step = CGFloat(idx) * 12.0 - 24.0
                    Path { p in
                        p.move(to: CGPoint(x: step * scale, y: 0 * scale))
                        p.addLine(to: CGPoint(x: (step + 6.0) * scale, y: 21 * scale))
                    }
                    .stroke(Color(red: 0.831, green: 0.686, blue: 0.216),
                            style: StrokeStyle(lineWidth: 1.5 * scale, lineCap: .round))
                }
            }
            .offset(x: -5 * scale, y: 1 * scale)

            // F. Thread collar
            Circle()
                .fill(Color(red: 0.102, green: 0.086, blue: 0.078))
                .frame(width: 12 * scale, height: 12 * scale)
                .offset(x: 36 * scale, y: 12 * scale)

            // G. Bead Head
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color.white.opacity(0.6),
                        Color(red: 0.831, green: 0.686, blue: 0.216),
                        Color(red: 0.831, green: 0.686, blue: 0.216).opacity(0.8),
                    ],
                    center: .topLeading, startRadius: 0, endRadius: 10 * scale
                ))
                .frame(width: 18 * scale, height: 18 * scale)
                .offset(x: 44 * scale, y: 9 * scale)
        }
        .frame(width: size, height: size)
    }
}
