/*
** Lua binding: DbCacheService
** Generated automatically by tolua++-1.0.92 on Fri Aug  3 02:38:15 2018.
*/

#ifndef __cplusplus
#include "stdlib.h"
#endif
#include "string.h"

#include "tolua++.h"

/* Exported function */
TOLUA_API int  tolua_DbCacheService_open (lua_State* tolua_S);

#include "../Service/DbCacheService.hpp"

/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
 tolua_usertype(tolua_S,"DbCacheService");
}

/* method: Instance of class  DbCacheService */
#ifndef TOLUA_DISABLE_tolua_DbCacheService_DbCacheService_Instance00
static int tolua_DbCacheService_DbCacheService_Instance00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"DbCacheService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   DbCacheService& tolua_ret = (DbCacheService&)  DbCacheService::Instance();
    tolua_pushusertype(tolua_S,(void*)&tolua_ret,"DbCacheService");
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

/* method: Init of class  DbCacheService */
#ifndef TOLUA_DISABLE_tolua_DbCacheService_DbCacheService_Init00
static int tolua_DbCacheService_DbCacheService_Init00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"DbCacheService",0,&tolua_err) ||
     !tolua_iscppstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  DbCacheService* self = (DbCacheService*)  tolua_tousertype(tolua_S,1,0);
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

/* method: Start of class  DbCacheService */
#ifndef TOLUA_DISABLE_tolua_DbCacheService_DbCacheService_Start00
static int tolua_DbCacheService_DbCacheService_Start00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"DbCacheService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  DbCacheService* self = (DbCacheService*)  tolua_tousertype(tolua_S,1,0);
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

/* method: Stop of class  DbCacheService */
#ifndef TOLUA_DISABLE_tolua_DbCacheService_DbCacheService_Stop00
static int tolua_DbCacheService_DbCacheService_Stop00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"DbCacheService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  DbCacheService* self = (DbCacheService*)  tolua_tousertype(tolua_S,1,0);
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

/* method: Running of class  DbCacheService */
#ifndef TOLUA_DISABLE_tolua_DbCacheService_DbCacheService_Running00
static int tolua_DbCacheService_DbCacheService_Running00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"DbCacheService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  DbCacheService* self = (DbCacheService*)  tolua_tousertype(tolua_S,1,0);
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

/* method: Boot of class  DbCacheService */
#ifndef TOLUA_DISABLE_tolua_DbCacheService_DbCacheService_Boot00
static int tolua_DbCacheService_DbCacheService_Boot00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"DbCacheService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  DbCacheService* self = (DbCacheService*)  tolua_tousertype(tolua_S,1,0);
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

/* method: ReadJson of class  DbCacheService */
#ifndef TOLUA_DISABLE_tolua_DbCacheService_DbCacheService_ReadJson00
static int tolua_DbCacheService_DbCacheService_ReadJson00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"DbCacheService",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  DbCacheService* self = (DbCacheService*)  tolua_tousertype(tolua_S,1,0);
  unsigned int id = ((unsigned int)  tolua_tonumber(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'ReadJson'", NULL);
#endif
  {
   std::string tolua_ret = (std::string)  self->ReadJson(id);
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

/* method: WriteJson of class  DbCacheService */
#ifndef TOLUA_DISABLE_tolua_DbCacheService_DbCacheService_WriteJson00
static int tolua_DbCacheService_DbCacheService_WriteJson00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"DbCacheService",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_iscppstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  DbCacheService* self = (DbCacheService*)  tolua_tousertype(tolua_S,1,0);
  unsigned int id = ((unsigned int)  tolua_tonumber(tolua_S,2,0));
  const std::string response = ((const std::string)  tolua_tocppstring(tolua_S,3,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'WriteJson'", NULL);
#endif
  {
   bool tolua_ret = (bool)  self->WriteJson(id,response);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
   tolua_pushcppstring(tolua_S,(const char*)response);
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

/* method: MysqlCommand of class  DbCacheService */
#ifndef TOLUA_DISABLE_tolua_DbCacheService_DbCacheService_MysqlCommand00
static int tolua_DbCacheService_DbCacheService_MysqlCommand00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"DbCacheService",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_iscppstring(tolua_S,3,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,4,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  DbCacheService* self = (DbCacheService*)  tolua_tousertype(tolua_S,1,0);
  unsigned int id = ((unsigned int)  tolua_tonumber(tolua_S,2,0));
  const std::string command_set_json = ((const std::string)  tolua_tocppstring(tolua_S,3,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'MysqlCommand'", NULL);
#endif
  {
   bool tolua_ret = (bool)  self->MysqlCommand(id,command_set_json);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
   tolua_pushcppstring(tolua_S,(const char*)command_set_json);
  }
 }
 return 2;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'MysqlCommand'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: MysqlReply of class  DbCacheService */
#ifndef TOLUA_DISABLE_tolua_DbCacheService_DbCacheService_MysqlReply00
static int tolua_DbCacheService_DbCacheService_MysqlReply00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"DbCacheService",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  DbCacheService* self = (DbCacheService*)  tolua_tousertype(tolua_S,1,0);
  unsigned int id = ((unsigned int)  tolua_tonumber(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'MysqlReply'", NULL);
#endif
  {
   std::string tolua_ret = (std::string)  self->MysqlReply(id);
   tolua_pushcppstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'MysqlReply'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* Open function */
TOLUA_API int tolua_DbCacheService_open (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
  tolua_cclass(tolua_S,"DbCacheService","DbCacheService","",NULL);
  tolua_beginmodule(tolua_S,"DbCacheService");
   tolua_function(tolua_S,"Instance",tolua_DbCacheService_DbCacheService_Instance00);
   tolua_function(tolua_S,"Init",tolua_DbCacheService_DbCacheService_Init00);
   tolua_function(tolua_S,"Start",tolua_DbCacheService_DbCacheService_Start00);
   tolua_function(tolua_S,"Stop",tolua_DbCacheService_DbCacheService_Stop00);
   tolua_function(tolua_S,"Running",tolua_DbCacheService_DbCacheService_Running00);
   tolua_function(tolua_S,"Boot",tolua_DbCacheService_DbCacheService_Boot00);
   tolua_function(tolua_S,"ReadJson",tolua_DbCacheService_DbCacheService_ReadJson00);
   tolua_function(tolua_S,"WriteJson",tolua_DbCacheService_DbCacheService_WriteJson00);
   tolua_function(tolua_S,"MysqlCommand",tolua_DbCacheService_DbCacheService_MysqlCommand00);
   tolua_function(tolua_S,"MysqlReply",tolua_DbCacheService_DbCacheService_MysqlReply00);
  tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 return 1;
}


#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 501
 TOLUA_API int luaopen_DbCacheService (lua_State* tolua_S) {
 return tolua_DbCacheService_open(tolua_S);
};
#endif

