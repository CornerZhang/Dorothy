/****************************************************************************
Copyright (c) 2010-2012 cocos2d-x.org
Copyright (c) 2008-2010 Ricardo Quesada

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
#ifndef __CCMENU_H_
#define __CCMENU_H_

#include "CCMenuItem.h"
#include "layers_scenes_transitions_nodes/CCLayer.h"

NS_CC_BEGIN

/**
 * @addtogroup GUI
 * @{
 * @addtogroup menu
 * @{
 */
	typedef enum
{
	kCCMenuStateWaiting,
	kCCMenuStateTrackingTouch
} tCCMenuState;

enum {
	//* priority used by the menu for the event handler
	kCCMenuHandlerPriority = -128,
};

/** @brief A CCMenu
*
* Features and Limitation:
*  - You can add MenuItem objects in runtime using addChild:
*  - But the only accepted children are MenuItem objects
*/
class CC_DLL CCMenu : public CCLayer
{
public:
	CCMenu() : m_pSelectedItem(NULL) { }
	virtual ~CCMenu() {}

	/** creates an empty CCMenu */
	static CCMenu* create();

	/** creates a CCMenu with CCMenuItem objects */
	static CCMenu* create(CCMenuItem* item, ...);

	/** creates a CCMenu with a CCArray of CCMenuItem objects */
	static CCMenu* createWithArray(CCArray* pArrayOfItems);

	/** creates a CCMenu with it's item, then use addChild() to add
	  * other items. It is used for script, it can't init with undetermined
	  * number of variables.
	*/
	static CCMenu* createWithItem(CCMenuItem* item);

	/** initializes an empty CCMenu */
	bool init();

	/** initializes a CCMenu with a NSArray of CCMenuItem objects */
	bool initWithArray(CCArray* pArrayOfItems);

	/** align items vertically with padding
	@since v0.7.2
	*/
	float alignItemsVerticallyWithPadding(float padding = 10);

	/** align items horizontally with padding
	@since v0.7.2
	*/
	float alignItemsHorizontallyWithPadding(float padding = 10);

	CCSize alignItemsWithPadding(float padding = 10);

	//super methods
	virtual void registerWithTouchDispatcher();
	virtual void removeChild(CCNode* child, bool cleanup);

	/**
	@brief For phone event handle functions
	*/
	virtual bool ccTouchBegan(CCTouch* touch, CCEvent* event);
	virtual void ccTouchEnded(CCTouch* touch, CCEvent* event);
	virtual void ccTouchCancelled(CCTouch *touch, CCEvent* event);
	virtual void ccTouchMoved(CCTouch* touch, CCEvent* event);

	/**
	@since v0.99.5
	override onExit
	*/
	virtual void onExit();

	inline bool isEnabled() { return m_bEnabled; }
	inline void setEnabled(bool value) { m_bEnabled = value; }

protected:
	CCMenuItem* itemForTouch(CCTouch* touch);
	/** whether or not the menu will receive events */
	bool m_bEnabled;
	tCCMenuState m_eState;
	CCMenuItem* m_pSelectedItem;
	CC_LUA_TYPE(CCMenu)
};

// end of GUI group
/// @}
/// @}

NS_CC_END

#endif//__CCMENU_H_
