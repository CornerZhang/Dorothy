/****************************************************************************
 Copyright (c) 2012 - 2013 cocos2d-x.org
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#include "CCDictionary.h"
#include "CCString.h"
#include "CCDouble.h"
#include "CCFloat.h"
#include "CCInteger.h"
#include "CCBool.h"
#include "CCInteger.h"
#include "platform/CCFileUtils.h"

using namespace std;

NS_CC_BEGIN

// -----------------------------------------------------------------------
// CCDictElement

CCDictElement::CCDictElement(const char* pszKey, int iSize, CCObject* pObject)
{
    CCAssert(pszKey && strlen(pszKey) > 0, "Invalid key value.");
    m_iKey = 0;
	m_szKey = new char[iSize+1];
	strcpy(m_szKey, pszKey);
    m_pObject = pObject;
    memset(&hh, 0, sizeof(hh));
}

CCDictElement::CCDictElement(intptr_t iKey, CCObject* pObject)
{
	m_szKey = NULL;
    m_iKey = iKey;
    m_pObject = pObject;
    memset(&hh, 0, sizeof(hh));
}

CCDictElement::~CCDictElement()
{
	CC_SAFE_DELETE_ARRAY(m_szKey);
}

// -----------------------------------------------------------------------
// CCDictionary

CCDictionary::CCDictionary()
: m_pElements(NULL)
, m_eDictType(kCCDictUnknown)
{ }

CCDictionary::~CCDictionary()
{
    removeAllObjects();
}

unsigned int CCDictionary::count()
{
    return HASH_COUNT(m_pElements);
}

CCArray* CCDictionary::allKeys()
{
    int iKeyCount = this->count();
    if (iKeyCount <= 0) return NULL;

    CCArray* pArray = CCArray::createWithCapacity(iKeyCount);

    CCDictElement *pElement, *tmp;
    if (m_eDictType == kCCDictStr)
    {
        HASH_ITER(hh, m_pElements, pElement, tmp) 
        {
            CCString* pOneKey = new CCString(pElement->m_szKey);
            pArray->addObject(pOneKey);
            CC_SAFE_RELEASE(pOneKey);
        }
    }
    else if (m_eDictType == kCCDictInt)
    {
        HASH_ITER(hh, m_pElements, pElement, tmp) 
        {
			CCInteger* pOneKey = new CCInteger((int)(pElement->m_iKey));
            pArray->addObject(pOneKey);
            CC_SAFE_RELEASE(pOneKey);
        }
    }
    
    return pArray;
}

CCArray* CCDictionary::allKeysForObject(CCObject* object)
{
    int iKeyCount = this->count();
    if (iKeyCount <= 0) return NULL;
    CCArray* pArray = CCArray::create();

    CCDictElement *pElement, *tmp;

    if (m_eDictType == kCCDictStr)
    {
        HASH_ITER(hh, m_pElements, pElement, tmp) 
        {
            if (object == pElement->m_pObject)
            {
                CCString* pOneKey = new CCString(pElement->m_szKey);
                pArray->addObject(pOneKey);
                CC_SAFE_RELEASE(pOneKey);
            }
        }
    }
    else if (m_eDictType == kCCDictInt)
    {
        HASH_ITER(hh, m_pElements, pElement, tmp) 
        {
            if (object == pElement->m_pObject)
            {
				CCInteger* pOneKey = new CCInteger((int)(pElement->m_iKey));
                pArray->addObject(pOneKey);
                CC_SAFE_RELEASE(pOneKey);
            }
        }
    }
    return pArray;
}

CCObject* CCDictionary::objectForKey(const char* key)
{
    // if dictionary wasn't initialized, return NULL directly.
    if (m_eDictType != kCCDictStr) return NULL;
    // CCDictionary only supports one kind of key, string or integer.
    // This method uses string as key, therefore we should make sure that the key type of this CCDictionary is string.
    //CCAssert(m_eDictType == kCCDictStr, "this dictionary does not use string as key.");

    CCObject* pRetObject = NULL;
    CCDictElement *pElement = NULL;
    HASH_FIND_STR(m_pElements, key, pElement);
    if (pElement != NULL)
    {
        pRetObject = pElement->m_pObject;
    }
    return pRetObject;
}

CCObject* CCDictionary::objectForKey(int key)
{
    // if dictionary wasn't initialized, return NULL directly.
    if (m_eDictType != kCCDictInt) return NULL;
    // CCDictionary only supports one kind of key, string or integer.
    // This method uses integer as key, therefore we should make sure that the key type of this CCDictionary is integer.
    //CCAssert(m_eDictType == kCCDictInt, "this dictionary does not use integer as key.");

    CCObject* pRetObject = NULL;
    CCDictElement *pElement = NULL;
    HASH_FIND_INT(m_pElements, &key, pElement);
    if (pElement != NULL)
    {
        pRetObject = pElement->m_pObject;
    }
    return pRetObject;
}

const CCString* CCDictionary::valueForKey(const char* key)
{
    CCString* pStr = CCLuaCast<CCString>(objectForKey(key));
	if (pStr) return pStr;
	return CCString::create("");
}

double CCDictionary::numberForKey(const char* key)
{
	CCObject* object = objectForKey(key);
	if (object)
	{
		CCInteger* pInteger = CCLuaCast<CCInteger>(object);
		if (pInteger) return pInteger->getValue();
		CCDouble* pDouble = CCLuaCast<CCDouble>(object);
		if (pDouble) return pDouble->getValue();
		CCFloat* pFloat = CCLuaCast<CCFloat>(object);
		if (pFloat) return pFloat->getValue();
		CCBool* pBool = CCLuaCast<CCBool>(object);
		if (pBool) return pBool->getValue() ? 1 : 0;
	}
	return 0;
}

const char* CCDictionary::stringForKey(const char* key)
{
	CCString* pString = CCLuaCast<CCString>(objectForKey(key));
	return pString ? pString->m_sString.c_str() : "";
}

const CCString* CCDictionary::valueForKey(int key)
{
	CCString* pStr = CCLuaCast<CCString>(objectForKey(key));
	if (pStr) return pStr;
	return CCString::create("");
}

void CCDictionary::setObject(CCObject* pObject, const char* key)
{
    CCAssert(key[0] && pObject != NULL, "Invalid Argument!");
    if (m_eDictType == kCCDictUnknown)
    {
        m_eDictType = kCCDictStr;
    }

    CCAssert(m_eDictType == kCCDictStr, "this dictionary doesn't use string as key.");

    CCDictElement *pElement = NULL;
    HASH_FIND_STR(m_pElements, key, pElement);
    if (pElement == NULL)
    {
        setObjectUnSafe(pObject, key);
    }
    else if (pElement->m_pObject != pObject)
    {
        CCObject* pTmpObj = pElement->m_pObject;
        pTmpObj->retain();
        removeObjectForElememt(pElement);
        setObjectUnSafe(pObject, key);
        pTmpObj->release();
    }
}

void CCDictionary::setObject(CCObject* pObject, int key)
{
    CCAssert(pObject != NULL, "Invalid Argument!");
    if (m_eDictType == kCCDictUnknown)
    {
        m_eDictType = kCCDictInt;
    }

    CCAssert(m_eDictType == kCCDictInt, "this dictionary doesn't use integer as key.");

    CCDictElement *pElement = NULL;
    HASH_FIND_INT(m_pElements, &key, pElement);
    if (pElement == NULL)
    {
        setObjectUnSafe(pObject, key);
    }
    else if (pElement->m_pObject != pObject)
    {
        CCObject* pTmpObj = pElement->m_pObject;
        pTmpObj->retain();
        removeObjectForElememt(pElement);
        setObjectUnSafe(pObject, key);
        pTmpObj->release();
    }

}

void CCDictionary::removeObjectForKey(const char* key)
{
    if (m_eDictType == kCCDictUnknown)
    {
        return;
    }
    
    CCAssert(m_eDictType == kCCDictStr, "this dictionary doesn't use string as its key");
    CCAssert(key[0] > 0, "Invalid Argument!");
    CCDictElement *pElement = NULL;
    HASH_FIND_STR(m_pElements, key, pElement);
    removeObjectForElememt(pElement);
}

void CCDictionary::removeObjectForKey(int key)
{
    if (m_eDictType == kCCDictUnknown)
    {
        return;
    }
    
    CCAssert(m_eDictType == kCCDictInt, "this dictionary doesn't use integer as its key");
    CCDictElement *pElement = NULL;
    HASH_FIND_INT(m_pElements, &key, pElement);
    removeObjectForElememt(pElement);
}

void CCDictionary::setObjectUnSafe(CCObject* pObject, const char* key)
{
    pObject->retain();
	int iSize = (int)strlen(key);
	CCDictElement* pElement = new CCDictElement(key, iSize, pObject);
	HASH_ADD_KEYPTR(hh, m_pElements, pElement->m_szKey, iSize, pElement);
}

void CCDictionary::setObjectUnSafe(CCObject* pObject, const int key)
{
    pObject->retain();
    CCDictElement* pElement = new CCDictElement(key, pObject);
    HASH_ADD_INT(m_pElements, m_iKey, pElement);
}

void CCDictionary::removeObjectsForKeys(CCArray* pKeyArray)
{
    CCObject* pObj = NULL;
    CCARRAY_FOREACH(pKeyArray, pObj)
    {
        CCString* pStr = (CCString*)pObj;
        removeObjectForKey(pStr->getCString());
    }
}

void CCDictionary::removeObjectForElememt(CCDictElement* pElement)
{
    if (pElement != NULL)
    {
        HASH_DEL(m_pElements, pElement);
        pElement->m_pObject->release();
        CC_SAFE_DELETE(pElement);
    }
}

void CCDictionary::removeAllObjects()
{
    CCDictElement *pElement, *tmp;
    HASH_ITER(hh, m_pElements, pElement, tmp) 
    {
        HASH_DEL(m_pElements, pElement);
        pElement->m_pObject->release();
        CC_SAFE_DELETE(pElement);

    }
}

CCObject* CCDictionary::copyWithZone(CCZone* pZone)
{
    CCAssert(pZone == NULL, "CCDictionary should not be inherited.");
    CCDictionary* pNewDict = new CCDictionary();

    CCDictElement* pElement = NULL;
    CCObject* pTmpObj = NULL;

    if (m_eDictType == kCCDictInt)
    {
        CCDICT_FOREACH(this, pElement)
        {
            pTmpObj = pElement->getObject()->copy();
            pNewDict->setObject(pTmpObj, (int)(pElement->getIntKey()));
            pTmpObj->release();
        }
    }
    else if (m_eDictType == kCCDictStr)
    {
        CCDICT_FOREACH(this, pElement)
        {
            pTmpObj = pElement->getObject()->copy();
            pNewDict->setObject(pTmpObj, pElement->getStrKey());
            pTmpObj->release();
        }
    }

    return pNewDict;
}

CCObject* CCDictionary::randomObject()
{
    if (m_eDictType == kCCDictUnknown)
    {
        return NULL;
    }
    
    CCObject* key = allKeys()->randomObject();
    
    if (m_eDictType == kCCDictInt)
    {
		return objectForKey(((CCInteger*)key)->getValue());
    }
    else if (m_eDictType == kCCDictStr)
    {
        return objectForKey(((CCString*)key)->getCString());
    }
    else
    {
        return NULL;
    }
}

CCDictionary* CCDictionary::create()
{
    CCDictionary* pRet = new CCDictionary();
    if (pRet != NULL)
    {
        pRet->autorelease();
    }
    return pRet;
}

CCDictionary* CCDictionary::createWithDictionary(CCDictionary* srcDict)
{
    CCDictionary* pNewDict = (CCDictionary*)srcDict->copy();
    pNewDict->autorelease();
    return pNewDict;
}

CCDictionary* CCDictionary::createWithContentsOfFileThreadSafe(const char *pFileName)
{
    return CCFileUtils::sharedFileUtils()->createCCDictionaryWithContentsOfFile(pFileName);
}

CCDictionary* CCDictionary::createWithContentsOfFile(const char *pFileName)
{
    CCDictionary* pRet = createWithContentsOfFileThreadSafe(pFileName);
    pRet->autorelease();
    return pRet;
}

CCDictionary* CCDictionary::createWithContents( const char* data, unsigned int length )
{
	CCDictionary* pRet = CCFileUtils::sharedFileUtils()->createCCDictionaryWithContents(data, length);
	pRet->autorelease();
	return pRet;
}

NS_CC_END
