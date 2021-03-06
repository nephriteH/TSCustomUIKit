//
//  TSTextField.swift
//  TSUIKit
//
//  Created by 小铭 on 2018/6/26.
//  Copyright © 2018年 caiqr. All rights reserved.
//

import UIKit
import SnapKit
import TSUtility

open class TSTextField: UITextField, UITextFieldDelegate {
    
    public var tsTextfieldDelegate: tsTextfieldProtocol?
    
    /**
        输入框类型
     */
    public var limitType: TSTextFieldLimitType?
    /**
     输入框内容是否合格
     默认不合格
     */
    public var isEligible = false
    
    /**
     是否允许输入非法字符
     */
    public var allowInputIllegal = false
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        //关闭输入框提示，首字母大写功能
        self.autocorrectionType = .no
        self.autocapitalizationType = .none
        self.addTarget(self, action: #selector(textFieldClick), for: .editingChanged)
        self.delegate = self
    }
    
    public convenience init(type : TSTextFieldLimitType) {
        self.init(frame: .zero)
        self.limitType = type
    }
    
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return self.tsTextfieldDelegate?.tsTextFieldShouldBeginEditing?(textField) ?? true
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.tsTextfieldDelegate?.tsTextFieldDidBeginEditing?(_:textField)
    }
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return self.tsTextfieldDelegate?.tsTextFieldShouldEndEditing?(textField) ?? true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.tsTextfieldDelegate?.tsTextFieldDidEndEditing?(textField)
    }
    
    //结束编辑
    @available(iOS 10.0, *)
    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        self.tsTextfieldDelegate?.tsTextFieldDidEndEditing?(textField, reason: reason)
    }
    
    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return self.tsTextfieldDelegate?.tsTextFieldShouldClear?(textField) ?? true
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.tsTextfieldDelegate?.tsTextFieldShouldReturn?(textField) ?? true
    }
    
    //MARK: --- 正在输入 核心方法  ---
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //输入为删除的情况
        if string == "" {
            return true
        }
        
        switch limitType! {
        case .tsTextFieldPhoneNumberType(let insertPlaceholder):
            //限制长度
            let proposeLength = (textField.text?.lengthOfBytes(using: String.Encoding.utf8))! - range.length + string.lengthOfBytes(using: String.Encoding.utf8)
            if proposeLength > (insertPlaceholder ? 13 : 11) { 
                return false
            }
            
            return isOnleyHasNumber(str: string)
            
        case .tsTextFieldEmailType :
            //邮箱
            return true
        case .tsTextFieldIDCardType:
            let proposeLength = (textField.text?.lengthOfBytes(using: String.Encoding.utf8))! - range.length + string.lengthOfBytes(using: String.Encoding.utf8)
            if proposeLength > 18 {
                return false
            }
            let isNumber = isOnleyHasNumber(str: string)
            var isX = false
            if string == "X" || string == "x" {
                isX = true
            }
            return (isNumber || isX)
        case .tsTextFieldCardCodeType:
            return isOnleyHasNumber(str: string)
        case .tsTextFieldWordAndNumberType(let rangeLimit) :
            //字母和数字
            //限制长度
            let proposeLength = (textField.text?.lengthOfBytes(using: String.Encoding.utf8))! - range.length + string.lengthOfBytes(using: String.Encoding.utf8)
            //超过限制
            if let masNums = rangeLimit.maxNum {
                if proposeLength > masNums {
                    return false
                }
            }
            
            if !isOnlyNumberAndEnglish(str: string) && !self.allowInputIllegal {
                
                return false
            }
            return true
        case .tsTextFieldOnlyNumberType(let rangeLimit):
            
            //限制长度
            let proposeLength = (textField.text?.lengthOfBytes(using: String.Encoding.utf8))! - range.length + string.lengthOfBytes(using: String.Encoding.utf8)
            //超过限制
            if let masNums = rangeLimit.maxNum {
                if proposeLength > masNums {
                    return false
                }
            }
        
            return isOnleyHasNumber(str: string)
        case .tsTextFieldCustomLimit(let limit):
            if limit.customLimit != nil {
                return limit.customLimit!()
            } else {
                return true
            }
        }
    }
    
    @objc func textFieldClick() -> Void {
        switch limitType! {
            case .tsTextFieldPhoneNumberType(let insertPlaceholder):
                if insertPlaceholder {
                    let tempString = self.text?.replacingOccurrences(of: " ", with: "")
                    if let countN = tempString?.count {
                        let outPutString : NSMutableString = NSMutableString.init(string: tempString!)
                        var insertN = 0
                        if countN > 3 && countN <= 7 {
                            insertN = 1
                        } else if countN > 7 {
                            insertN = 2
                        }
                        for i in 0..<insertN {
                            let index = (i + 1) * (i == 0 ? 3 : 4)
                            if index < outPutString.length {
                                outPutString.insert(" ", at: index)
                            }
                        }
                        let textString = "\(outPutString)" as String
                        self.text = textString
                    }
                    isEligible = (tempString?.count == 11) && isOnleyHasNumber(str: tempString ?? "")
                } else {
                    isEligible = (self.text?.count == 11) && isOnleyHasNumber(str: self.text ?? "")
                }
            case .tsTextFieldEmailType:
                isEligible = isValidateEmail(str: self.text ?? "")
            
            case .tsTextFieldCustomLimit(let range):
                if range.customLimit != nil {
                    isEligible = range.customLimit!()
                } else {
                    isEligible = false
                }

            case .tsTextFieldIDCardType:
                isEligible = false
                if let stringCount = self.text?.count {
                    let minT = stringCount >= 15
                    let maxT = stringCount <= 18
                    isEligible = (minT && maxT)
                }
            case .tsTextFieldCardCodeType:
                let tempString = self.text?.replacingOccurrences(of: " ", with: "")
                if let countN = tempString?.count {
                    let outPutString : NSMutableString = NSMutableString.init(string: tempString!)
                    let insertN = countN / 4
                    for i in 0..<insertN {
                        let index = (i + 1) * 4 + i
                        if index < outPutString.length {
                            outPutString.insert(" ", at: index)
                        }
                    }
                    let textString = "\(outPutString)" as String
                    self.text = textString
                    isEligible = true
                }
            case .tsTextFieldWordAndNumberType(let range):
                isEligible = false
                if let stringCount = self.text?.count {
                    var minT = true
                    var maxT = true
                    if let minN = range.minNum {
                        minT = stringCount >= minN
                    }
                    if let maxN = range.maxNum {
                        maxT = stringCount <= maxN
                    }
                    isEligible = (minT && maxT) && isOnlyNumberAndEnglish(str: self.text ?? "")
                }
            case .tsTextFieldOnlyNumberType(let range):
                isEligible = false
                if let stringCount = self.text?.count {
                    var minT = true
                    var maxT = true
                    if let minN = range.minNum {
                        minT = stringCount >= minN
                    }
                    if let maxN = range.maxNum {
                        maxT = stringCount <= maxN
                    }
                    isEligible = (minT && maxT) && isOnleyHasNumber(str: self.text ?? "")
                }
        }
        if self.text?.count == 0 {
            self.isEligible = false
        }
        self.tsTextfieldDelegate?.eligibleStatusCallBack?(textField: self, status: isEligible)
    }
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        //默认展示粘贴和复制
        if action.description == "copy:" || action.description == "paste:" {
            return true
        }
        return false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // private
    //限制输入数字和英文单词
    private func isOnlyNumberAndEnglish(str: String)->Bool{
        
        let num = str as NSString
        
        if num.length == 0 {
            return false
        }
    
        let numberStr = "^[A-Za-z0-9]+$"
        let regextestmobile = NSPredicate(format: "SELF MATCHES %@",numberStr)
        
        return regextestmobile.evaluate(with: num)
    }
    //限制邮箱输入
    private func isValidateEmail(str : String) -> Bool {
        if str.count == 0 {
            return false
        }
        let emailStr = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let regextestmobile = NSPredicate(format: "SELF MATCHES %@",emailStr)
        return regextestmobile.evaluate(with: str)
    }
    //是否为纯数字
    
    private func isOnleyHasNumber(str: String) -> Bool {
        if str.count == 0 {
            return false
        }
        let numberString = "^[0-9]+$"
        let regextestmobile = NSPredicate(format: "SELF MATCHES %@",numberString)
        return regextestmobile.evaluate(with: str)
    }
}
