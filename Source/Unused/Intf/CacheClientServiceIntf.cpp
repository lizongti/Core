/*
** Lua binding: CacheClientService
** Generated automatically by tolua++-1.0.92 on 03/26/19 19:39:06.
*/

#ifndef __cplusplus
#include "stdlib.h"
#endif
#include "string.h"

#include "tolua++.h"

/* Exported function */
TOLUA_API int  tolua_CacheClientService_open (lua_State* tolua_S);

#include "../Service/CacheClientService.hpp"

/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
 tolua_usertype(tolua_S,"CacheClientService");
}

/* method: Instance of class  CacheClientService */
#ifndef TOLUA_DISABLE_tolua_CacheClientService_CacheClientService_Instance00
static int tolua_CacheClientService_CacheClientService_Instance00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"CacheClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   CacheClientService& tolua_ret = (CacheClientService&)  CacheClientService::Instance();
    tolua_pushusertype(tolua_S,(void*)&tolua_ret,"CacheClientService");
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'Instance'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: Init of class  CacheClientService */
#ifndef TOLUA_DISABLE_tolua_CacheClientService_CacheClientService_Init00
static int tolua_CacheClientService_CacheClientService_Init00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"CacheClientService",0,&tolua_err) ||
     !tolua_iscppstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  CacheClientService* self = (CacheClientService*)  tolua_tousertype(tolua_S,1,0);
  const std::string json = ((const std::string)  tolua_tocppstring(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'Init'", NULL);
#endif
  {
   bool tolua_ret = (bool)  self->Init(json);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
   tolua_pushcppstring(tolua_S,(const char*)json);
  }
 }
 return 2;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'Init'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: Start of class  CacheClientService */
#ifndef TOLUA_DISABLE_tolua_CacheClientService_CacheClientService_Start00
static int tolua_CacheClientService_CacheClientService_Start00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"CacheClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  CacheClientService* self = (CacheClientService*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'Start'", NULL);
#endif
  {
   bool tolua_ret = (bool)  self->Start();
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'Start'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: Stop of class  CacheClientService */
#ifndef TOLUA_DISABLE_tolua_CacheClientService_CacheClientService_Stop00
static int tolua_CacheClientService_CacheClientService_Stop00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"CacheClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  CacheClientService* self = (CacheClientService*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'Stop'", NULL);
#endif
  {
   bool tolua_ret = (bool)  self->Stop();
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'Stop'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: Running of class  CacheClientService */
#ifndef TOLUA_DISABLE_tolua_CacheClientService_CacheClientService_Running00
static int tolua_CacheClientService_CacheClientService_Running00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"CacheClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  CacheClientService* self = (CacheClientService*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'Running'", NULL);
#endif
  {
   bool tolua_ret = (bool)  self->Running();
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'Running'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: Boot of class  CacheClientService */
#ifndef TOLUA_DISABLE_tolua_CacheClientService_CacheClientService_Boot00
static int tolua_CacheClientService_CacheClientService_Boot00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"CacheClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  CacheClientService* self = (CacheClientService*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'Boot'", NULL);
#endif
  {
   bool tolua_ret = (bool)  self->Boot();
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'Boot'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: ReadJson of class  CacheClientService */
#ifndef TOLUA_DISABLE_tolua_CacheClientService_CacheClientService_ReadJson00
static int tolua_CacheClientService_CacheClientService_ReadJson00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"CacheClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  CacheClientService* self = (CacheClientService*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'ReadJson'", NULL);
#endif
  {
   std::string tolua_ret = (std::string)  self->ReadJson();
   tolua_pushcppstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'ReadJson'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: WriteJson of class  CacheClientService */
#ifndef TOLUA_DISABLE_tolua_CacheClientService_CacheClientService_WriteJson00
static int tolua_CacheClientService_CacheClientService_WriteJson00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"CacheClientService",0,&tolua_err) ||
     !tolua_iscppstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  CacheClientService* self = (CacheClientService*)  tolua_tousertype(tolua_S,1,0);
  const std::string request = ((const std::string)  tolua_tocppstring(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'WriteJson'", NULL);
#endif
  {
   bool tolua_ret = (bool)  self->WriteJson(request);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
   tolua_pushcppstring(tolua_S,(const char*)request);
  }
 }
 return 2;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'WriteJson'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* Open function */
TOLUA_API int tolua_CacheClientService_open (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
  tolua_cclass(tolua_S,"CacheClientService","CacheClientService","",NULL);
  tolua_beginmodule(tolua_S,"CacheClientService");
   tolua_function(tolua_S,"Instance",tolua_CacheClientService_CacheClientService_Instance00);
   tolua_function(tolua_S,"Init",tolua_CacheClientService_CacheClientService_Init00);
   tolua_function(tolua_S,"Start",tolua_CacheClientService_CacheClientService_Start00);
   tolua_function(tolua_S,"Stop",tolua_CacheClientService_CacheClientService_Stop00);
   tolua_function(tolua_S,"Running",tolua_CacheClientService_CacheClientService_Running00);
   tolua_function(tolua_S,"Boot",tolua_CacheClientService_CacheClientService_Boot00);
   tolua_function(tolua_S,"ReadJson",tolua_CacheClientService_CacheClientService_ReadJson00);
   tolua_function(tolua_S,"WriteJson",tolua_CacheClientService_CacheClientService_WriteJson00);
  tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 return 1;
}


#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 501
 TOLUA_API int luaopen_CacheClientService (lua_State* tolua_S) {
 return tolua_CacheClientService_open(tolua_S);
};
#endif

