// Renders the app icon: usage `swift scripts/make_icon.swift <output.png>`
// An open book: original lines on the left page, translation lines on the right, one aligned pair highlighted.
import AppKit
import CoreGraphics

let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let s = CGFloat(size)

// Background: deep teal.
let gradient = CGGradient(colorsSpace: space, colors: [
    CGColor(srgbRed: 0.02, green: 0.17, blue: 0.22, alpha: 1),
    CGColor(srgbRed: 0.04, green: 0.45, blue: 0.47, alpha: 1)
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: s, y: s), options: [])

func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

// Pages with a soft shadow.
let top = s * 0.76, bottom = s * 0.22
let left = CGRect(x: s * 0.13, y: bottom, width: s * 0.36, height: top - bottom)
let right = CGRect(x: s * 0.51, y: bottom, width: s * 0.36, height: top - bottom)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.04, color: CGColor(gray: 0, alpha: 0.35))
ctx.setFillColor(CGColor(srgbRed: 0.99, green: 0.97, blue: 0.92, alpha: 1))
ctx.addPath(rounded(left, s * 0.035)); ctx.addPath(rounded(right, s * 0.035))
ctx.fillPath()
ctx.restoreGState()

// Aligned highlight across both pages.
let rowHeight = s * 0.072
let firstRow = top - s * 0.115
let highlighted = 2
let bandY = firstRow - CGFloat(highlighted) * rowHeight - s * 0.022
ctx.setFillColor(CGColor(srgbRed: 1.0, green: 0.84, blue: 0.42, alpha: 1))
ctx.addPath(rounded(CGRect(x: left.minX + s * 0.025, y: bandY, width: left.width - s * 0.05, height: s * 0.075), s * 0.02))
ctx.addPath(rounded(CGRect(x: right.minX + s * 0.025, y: bandY, width: right.width - s * 0.05, height: s * 0.075), s * 0.02))
ctx.fillPath()

// Text lines: dark on the left (original), teal on the right (translation).
let widths: [CGFloat] = [0.27, 0.23, 0.26, 0.2, 0.25, 0.16]
for (page, color) in [(left, CGColor(srgbRed: 0.2, green: 0.24, blue: 0.28, alpha: 1)),
                      (right, CGColor(srgbRed: 0.04, green: 0.45, blue: 0.47, alpha: 1))] {
    ctx.setFillColor(color)
    for (i, w) in widths.enumerated() {
        let y = firstRow - CGFloat(i) * rowHeight
        ctx.addPath(rounded(CGRect(x: page.minX + s * 0.045, y: y, width: s * (page == right ? w * 0.92 : w), height: s * 0.03), s * 0.015))
    }
    ctx.fillPath()
}

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
