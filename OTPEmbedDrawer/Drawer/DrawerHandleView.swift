//
//  DrawerHandleView.swift
//  OTPEmbedDrawer
//
//  Created by Jeevan Pandey on 03/03/26.
//

import SwiftUI

struct RoundedCorner: Shape {
    
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
