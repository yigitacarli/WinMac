import Cocoa
import CoreGraphics

public struct WindowCalculation {
    
    public static func calculateRect(for action: SnapAction, visibleFrame: CGRect, gaps: CGFloat = 0) -> CGRect {
        let adjustedFrame = visibleFrame.insetBy(dx: gaps, dy: gaps)
        
        let halfWidth = (adjustedFrame.width - gaps) / 2.0
        let halfHeight = (adjustedFrame.height - gaps) / 2.0
        let thirdWidth = (adjustedFrame.width - (gaps * 2.0)) / 3.0
        let twoThirdsWidth = (adjustedFrame.width * 2.0) / 3.0
        
        switch action {
        case .leftHalf:
            return CGRect(
                x: adjustedFrame.minX,
                y: adjustedFrame.minY,
                width: halfWidth,
                height: adjustedFrame.height
            )
            
        case .rightHalf:
            return CGRect(
                x: adjustedFrame.minX + halfWidth + gaps,
                y: adjustedFrame.minY,
                width: halfWidth,
                height: adjustedFrame.height
            )
            
        case .topHalf:
            return CGRect(
                x: adjustedFrame.minX,
                y: adjustedFrame.minY + halfHeight + gaps,
                width: adjustedFrame.width,
                height: halfHeight
            )
            
        case .bottomHalf:
            return CGRect(
                x: adjustedFrame.minX,
                y: adjustedFrame.minY,
                width: adjustedFrame.width,
                height: halfHeight
            )
            
        case .maximize:
            return adjustedFrame
            
        case .topLeftQuarter:
            return CGRect(
                x: adjustedFrame.minX,
                y: adjustedFrame.minY + halfHeight + gaps,
                width: halfWidth,
                height: halfHeight
            )
            
        case .topRightQuarter:
            return CGRect(
                x: adjustedFrame.minX + halfWidth + gaps,
                y: adjustedFrame.minY + halfHeight + gaps,
                width: halfWidth,
                height: halfHeight
            )
            
        case .bottomLeftQuarter:
            return CGRect(
                x: adjustedFrame.minX,
                y: adjustedFrame.minY,
                width: halfWidth,
                height: halfHeight
            )
            
        case .bottomRightQuarter:
            return CGRect(
                x: adjustedFrame.minX + halfWidth + gaps,
                y: adjustedFrame.minY,
                width: halfWidth,
                height: halfHeight
            )
            
        case .leftThird:
            return CGRect(
                x: adjustedFrame.minX,
                y: adjustedFrame.minY,
                width: thirdWidth,
                height: adjustedFrame.height
            )
            
        case .centerThird:
            return CGRect(
                x: adjustedFrame.minX + thirdWidth + gaps,
                y: adjustedFrame.minY,
                width: thirdWidth,
                height: adjustedFrame.height
            )
            
        case .rightThird:
            return CGRect(
                x: adjustedFrame.minX + (thirdWidth * 2.0) + (gaps * 2.0),
                y: adjustedFrame.minY,
                width: thirdWidth,
                height: adjustedFrame.height
            )
            
        case .leftTwoThirds:
            return CGRect(
                x: adjustedFrame.minX,
                y: adjustedFrame.minY,
                width: twoThirdsWidth,
                height: adjustedFrame.height
            )
            
        case .rightTwoThirds:
            return CGRect(
                x: adjustedFrame.minX + (adjustedFrame.width - twoThirdsWidth),
                y: adjustedFrame.minY,
                width: twoThirdsWidth,
                height: adjustedFrame.height
            )
            
        case .center:
            let w = adjustedFrame.width * 0.75
            let h = adjustedFrame.height * 0.75
            return CGRect(
                x: adjustedFrame.minX + (adjustedFrame.width - w) / 2.0,
                y: adjustedFrame.minY + (adjustedFrame.height - h) / 2.0,
                width: w,
                height: h
            )
            
        case .nextDisplay, .previousDisplay, .expandSize, .shrinkSize:
            return adjustedFrame
        }
    }
}
