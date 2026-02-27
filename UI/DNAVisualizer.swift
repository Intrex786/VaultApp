// DNAVisualizer.swift
// Password Manager — Shared deterministic DNA art Canvas view

import SwiftUI

// MARK: - DNAArtView

/// Renders a deterministic double-helix pattern derived from the hash of `seed`.
/// Use wherever a visual password fingerprint is needed.
struct DNAArtView: View {
    let seed: String

    private func hashValue(_ s: String) -> Int {
        var h: UInt64 = 5381
        for byte in s.utf8 { h = (h &* 31) &+ UInt64(byte) }
        return Int(h)
    }

    var body: some View {
        Canvas { ctx, size in
            let h = hashValue(seed)
            let segments = 12
            let width    = size.width
            let height   = size.height
            let step     = width / CGFloat(segments)

            for i in 0..<segments {
                let seed1 = abs(hashValue(seed + "\(i)"))
                let seed2 = abs(hashValue(seed + "b\(i)"))
                let seed3 = abs(hashValue(seed + "c\(i)"))

                let x     = CGFloat(i) * step + step / 2
                let yOff1 = CGFloat(seed1 % 100) / 100.0 * height * 0.6 + height * 0.2
                let yOff2 = CGFloat(seed2 % 100) / 100.0 * height * 0.6 + height * 0.2
                let hue   = Double((h &+ seed3) % 360) / 360.0
                let color = Color(hue: hue, saturation: 0.7, brightness: 0.85)

                // Helix strand
                var path1 = Path()
                path1.move(to: CGPoint(x: x - step / 2, y: yOff1))
                path1.addCurve(
                    to: CGPoint(x: x + step / 2, y: yOff2),
                    control1: CGPoint(x: x - step / 4, y: yOff1 - 20),
                    control2: CGPoint(x: x + step / 4, y: yOff2 + 20)
                )
                ctx.stroke(path1,
                           with: .color(color.opacity(0.7)),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round))

                // Node dot
                let dotR: CGFloat = CGFloat(seed3 % 5 + 3)
                let dotRect = CGRect(x: x - dotR, y: yOff1 - dotR, width: dotR * 2, height: dotR * 2)
                ctx.fill(Path(ellipseIn: dotRect), with: .color(color))

                // Connector rung every 3rd segment
                if i % 3 == 0 {
                    var rung = Path()
                    rung.move(to: CGPoint(x: x, y: yOff1))
                    rung.addLine(to: CGPoint(x: x, y: yOff2))
                    ctx.stroke(rung,
                               with: .color(color.opacity(0.4)),
                               style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
        }
        .background(Color.obsidianRaised)
    }
}
