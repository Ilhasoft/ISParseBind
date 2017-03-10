//
//  DictionaryExtension.swift
//  ISParseBind
//
//  Created by Daniel Amaral on 27/01/17.
//  Copyright © 2017 ilhasoft. All rights reserved.
//

extension Dictionary where Key: Hashable, Value: Any {
    func getValue(forKeyPath components : Array<Any>) -> Any? {
        var comps = components;
        let key = comps.remove(at: 0)
        if let k = key as? Key {
            if(comps.count == 0) {
                return self[k]
            }
            if let v = self[k] as? Dictionary<AnyHashable,Any> {
                return v.getValue(forKeyPath : comps)
            }
        }
        return nil
    }
}
