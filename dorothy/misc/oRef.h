/* Copyright (c) 2013 Jin Li, http://www.luvfight.me

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#ifndef __DOROTHY_MISC_OREF_H__
#define __DOROTHY_MISC_OREF_H__

NS_DOROTHY_BEGIN

/** @brief Used with Aggregation Relationship. */
template<class T = CCObject>
class oRef
{
public:
	oRef():_item(nullptr)
	{ }
	explicit oRef(T* item):_item(item)
	{
		if (item)
		{
			item->retain();
		}
	}
	oRef(const oRef& ref)
	{
		if (ref._item)
		{
			ref._item->retain();
		}
		_item = ref._item;
	}
	oRef(oRef&& ref)
	{
		_item = ref._item;
		ref._item = nullptr;
	}
	~oRef()
	{
		if (_item)
		{
			_item->release();
			_item = nullptr;
		}
	}
	inline T* operator->() const
	{
		return _item;
	}
	T* operator=(T* item)
	{
		/* ensure that assign same item is Ok
		 so first retain new item then release old item
		*/
		if (item)
		{
			item->retain();
		}
		if (_item)
		{
			_item->release();
		}
		_item = item;
		return item;
	}
	const oRef& operator=(const oRef& ref)
	{
		if (this == &ref) // handle self assign
		{
			return *this;
		}
		if (ref._item)
		{
			ref._item->retain();
		}
		if (_item)
		{
			_item->release();
		}
		_item = ref._item;
		return *this;
	}
	const oRef& operator=(oRef&& ref)
	{
		if (this == &ref) // handle self assign
		{
			return *this;
		}
		if (_item)
		{
			_item->release();
		}
		_item = ref._item;
		ref._item = nullptr;
		return *this;
	}
	bool operator==(const oRef& ref) const
	{
		return _item == ref._item;
	}
	bool operator!=(const oRef& ref) const
	{
		return _item != ref._item;
	}
	inline operator T*() const
	{
		return _item;
	}
	inline T* get() const
	{
		return _item;
	}
private:
	T* _item;
};

template <class name>
inline oRef<name> oRefMake(name* item)
{
	return oRef<name>(item);
}

NS_DOROTHY_END

#endif // __DOROTHY_MISC_OREF_H__
