----------------------------------------------------------------------
--  Copyright (c) 2014-2016, XCKOO. All Rights Reserved.
--  Author :Tango
--  Time   :2014/11/25 19:43:35
--  Remark :声明全局变量
----------------------------------------------------------------------
module( "global", package.seeall )

-- 我的组织id
myOrgId = 0
appstoreReviewing = true

--是否在苹果审核期间
function isReviewing( )
	return is_applestore and appstoreReviewing
end