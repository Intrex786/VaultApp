#!/usr/bin/env swift
// gen_icon.swift — Generates VaultApp icon using CoreGraphics (no dependencies)
// Usage: swift scripts/gen_icon.swift

import Foundation
import CoreGraphics
import ImageIO

let outDir  = "Assets.xcassets/AppIcon.appiconset"
let sizes   = [40, 40, 58, 58, 80, 80, 120, 120, 1024]
let names   = ["Icon-40@2x","Icon-40@3x","Icon-58@2x","Icon-58@3x",
                "Icon-80@2x","Icon-80@3x","Icon-120@2x","Icon-120@3x","Icon-1024"]

func makeIcon(size: Int) -> CGImage {
    let s = CGFloat(size)
    let ctx = CGContext(data: nil, width: size, height: size,
                        bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.translateBy(x: 0, y: s); ctx.scaleBy(x: 1, y: -1) // flip Y

    // ── Background gradient: #0D0F1C → #1A1A3E ──────────────────────────────
    let bgColors = [CGColor(red:0.05,green:0.06,blue:0.11,alpha:1),
                    CGColor(red:0.10,green:0.10,blue:0.24,alpha:1)] as CFArray
    let bgGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                            colors: bgColors, locations: [0,1])!
    ctx.drawLinearGradient(bgGrad, start: CGPoint(x:0,y:0), end: CGPoint(x:s,y:s), options:[])

    // ── Shield shape ─────────────────────────────────────────────────────────
    let cx = s/2, pad = s*0.20
    let shieldPath = CGMutablePath()
    shieldPath.move(to: CGPoint(x:cx, y:pad))
    shieldPath.addLine(to: CGPoint(x:s-pad, y:s*0.28))
    shieldPath.addLine(to: CGPoint(x:s-pad, y:s*0.55))
    shieldPath.addCurve(to: CGPoint(x:cx, y:s-pad),
                        control1: CGPoint(x:s-pad,y:s*0.76),
                        control2: CGPoint(x:s*0.72,y:s*0.86))
    shieldPath.addCurve(to: CGPoint(x:pad, y:s*0.55),
                        control1: CGPoint(x:s*0.28,y:s*0.86),
                        control2: CGPoint(x:pad,y:s*0.76))
    shieldPath.addLine(to: CGPoint(x:pad, y:s*0.28))
    shieldPath.closeSubpath()

    // Shield fill: indigo gradient
    let sColors = [CGColor(red:0.37,green:0.36,blue:0.90,alpha:1),
                   CGColor(red:0.48,green:0.47,blue:1.0, alpha:1)] as CFArray
    let sGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: sColors, locations: [0,1])!
    ctx.addPath(shieldPath); ctx.clip()
    ctx.drawLinearGradient(sGrad, start: CGPoint(x:pad,y:pad),
                           end: CGPoint(x:s-pad,y:s-pad), options:[])
    ctx.resetClip()

    // ── Lock body ─────────────────────────────────────────────────────────────
    let lw = s*0.30, lh = s*0.24
    let lx = cx - lw/2, ly = s*0.52
    let lockRect = CGRect(x:lx, y:ly, width:lw, height:lh)
    let r = s*0.04
    ctx.setFillColor(CGColor(red:1,green:1,blue:1,alpha:0.95))
    ctx.addPath(CGPath(roundedRect: lockRect, cornerWidth: r, cornerHeight: r, transform: nil))
    ctx.fillPath()

    // ── Shackle (lock arch) ───────────────────────────────────────────────────
    ctx.setStrokeColor(CGColor(red:1,green:1,blue:1,alpha:0.95))
    ctx.setLineWidth(s*0.055); ctx.setLineCap(.round)
    let sr = s*0.11
    let archPath = CGMutablePath()
    archPath.move(to: CGPoint(x:cx-sr, y:ly))
    archPath.addLine(to: CGPoint(x:cx-sr, y:s*0.42))
    archPath.addArc(center: CGPoint(x:cx,y:s*0.42), radius:sr,
                    startAngle:.pi, endAngle:0, clockwise:false)
    archPath.addLine(to: CGPoint(x:cx+sr, y:ly))
    ctx.addPath(archPath); ctx.strokePath()

    // ── Keyhole ───────────────────────────────────────────────────────────────
    let kr = s*0.038
    ctx.setFillColor(CGColor(red:0.37,green:0.36,blue:0.90,alpha:1))
    ctx.addEllipse(in: CGRect(x:cx-kr, y:ly+lh*0.25, width:kr*2, height:kr*2)); ctx.fillPath()
    ctx.fill(CGRect(x:cx-kr*0.55, y:ly+lh*0.25+kr*2, width:kr*1.1, height:lh*0.30))

    return ctx.makeImage()!
}

func savePNG(_ img: CGImage, to path: String) {
    let url  = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)
    else { fatalError("Cannot create destination: \(path)") }
    CGImageDestinationAddImage(dest, img, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("Failed to write \(path)") }
}

for (name, size) in zip(names, sizes) {
    let img  = makeIcon(size: size)
    let path = "\(outDir)/\(name).png"
    savePNG(img, to: path)
    print("✓ \(path)")
}
print("Icons generated successfully.")
