/*
** Lua binding: ContestClientService
** Generated automatically by tolua++-1.0.92 on 03/26/19 19:39:07.
*/

#ifndef __cplusplus
#include "stdlib.h"
#endif
#include "string.h"

#include "tolua++.h"

/* Exported function */
TOLUA_API int  tolua_ContestClientService_open (lua_State* tolua_S);

#include "../Service/ContestClientService.hpp"

/* function to register type */
static void tolua_reg_types (lua_State* tolua_S)
{
 tolua_usertype(tolua_S,"Packet");
 tolua_usertype(tolua_S,"ContestClientService");
}

/* get function: size of class  Packet */
#ifndef TOLUA_DISABLE_tolua_get_Packet_unsigned_size
static int tolua_get_Packet_unsigned_size(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'size'",NULL);
#endif
  tolua_pushnumber(tolua_S,(lua_Number)self->size);
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* set function: size of class  Packet */
#ifndef TOLUA_DISABLE_tolua_set_Packet_unsigned_size
static int tolua_set_Packet_unsigned_size(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  tolua_Error tolua_err;
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'size'",NULL);
  if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
   tolua_error(tolua_S,"#vinvalid type in variable assignment.",&tolua_err);
#endif
  self->size = ((unsigned short)  tolua_tonumber(tolua_S,2,0))
;
 return 0;
}
#endif //#ifndef TOLUA_DISABLE

/* get function: check_sum of class  Packet */
#ifndef TOLUA_DISABLE_tolua_get_Packet_unsigned_check_sum
static int tolua_get_Packet_unsigned_check_sum(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'check_sum'",NULL);
#endif
  tolua_pushnumber(tolua_S,(lua_Number)self->check_sum);
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* set function: check_sum of class  Packet */
#ifndef TOLUA_DISABLE_tolua_set_Packet_unsigned_check_sum
static int tolua_set_Packet_unsigned_check_sum(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  tolua_Error tolua_err;
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'check_sum'",NULL);
  if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
   tolua_error(tolua_S,"#vinvalid type in variable assignment.",&tolua_err);
#endif
  self->check_sum = ((unsigned int)  tolua_tonumber(tolua_S,2,0))
;
 return 0;
}
#endif //#ifndef TOLUA_DISABLE

/* get function: sequence_id of class  Packet */
#ifndef TOLUA_DISABLE_tolua_get_Packet_unsigned_sequence_id
static int tolua_get_Packet_unsigned_sequence_id(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'sequence_id'",NULL);
#endif
  tolua_pushnumber(tolua_S,(lua_Number)self->sequence_id);
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* set function: sequence_id of class  Packet */
#ifndef TOLUA_DISABLE_tolua_set_Packet_unsigned_sequence_id
static int tolua_set_Packet_unsigned_sequence_id(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  tolua_Error tolua_err;
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'sequence_id'",NULL);
  if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
   tolua_error(tolua_S,"#vinvalid type in variable assignment.",&tolua_err);
#endif
  self->sequence_id = ((unsigned int)  tolua_tonumber(tolua_S,2,0))
;
 return 0;
}
#endif //#ifndef TOLUA_DISABLE

/* get function: module_id of class  Packet */
#ifndef TOLUA_DISABLE_tolua_get_Packet_unsigned_module_id
static int tolua_get_Packet_unsigned_module_id(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'module_id'",NULL);
#endif
  tolua_pushnumber(tolua_S,(lua_Number)self->module_id);
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* set function: module_id of class  Packet */
#ifndef TOLUA_DISABLE_tolua_set_Packet_unsigned_module_id
static int tolua_set_Packet_unsigned_module_id(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  tolua_Error tolua_err;
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'module_id'",NULL);
  if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
   tolua_error(tolua_S,"#vinvalid type in variable assignment.",&tolua_err);
#endif
  self->module_id = ((unsigned short)  tolua_tonumber(tolua_S,2,0))
;
 return 0;
}
#endif //#ifndef TOLUA_DISABLE

/* get function: message_id of class  Packet */
#ifndef TOLUA_DISABLE_tolua_get_Packet_unsigned_message_id
static int tolua_get_Packet_unsigned_message_id(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'message_id'",NULL);
#endif
  tolua_pushnumber(tolua_S,(lua_Number)self->message_id);
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* set function: message_id of class  Packet */
#ifndef TOLUA_DISABLE_tolua_set_Packet_unsigned_message_id
static int tolua_set_Packet_unsigned_message_id(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  tolua_Error tolua_err;
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'message_id'",NULL);
  if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
   tolua_error(tolua_S,"#vinvalid type in variable assignment.",&tolua_err);
#endif
  self->message_id = ((unsigned short)  tolua_tonumber(tolua_S,2,0))
;
 return 0;
}
#endif //#ifndef TOLUA_DISABLE

/* get function: protobuf_size of class  Packet */
#ifndef TOLUA_DISABLE_tolua_get_Packet_unsigned_protobuf_size
static int tolua_get_Packet_unsigned_protobuf_size(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'protobuf_size'",NULL);
#endif
  tolua_pushnumber(tolua_S,(lua_Number)self->protobuf_size);
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* set function: protobuf_size of class  Packet */
#ifndef TOLUA_DISABLE_tolua_set_Packet_unsigned_protobuf_size
static int tolua_set_Packet_unsigned_protobuf_size(lua_State* tolua_S)
{
  Packet* self = (Packet*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  tolua_Error tolua_err;
  if (!self) tolua_error(tolua_S,"invalid 'self' in accessing variable 'protobuf_size'",NULL);
  if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
   tolua_error(tolua_S,"#vinvalid type in variable assignment.",&tolua_err);
#endif
  self->protobuf_size = ((unsigned int)  tolua_tonumber(tolua_S,2,0))
;
 return 0;
}
#endif //#ifndef TOLUA_DISABLE

/* get function: protobuf_content of class  Packet */
#ifndef TOLUA_DISABLE_tolua_get_ContestClientService_Packet_protobuf_content
static int tolua_get_ContestClientService_Packet_protobuf_content(lua_State* tolua_S)
{
 int tolua_index;
  Packet* self;
 lua_pushstring(tolua_S,".self");
 lua_rawget(tolua_S,1);
 self = (Packet*)  lua_touserdata(tolua_S,-1);
#ifndef TOLUA_RELEASE
 {
  tolua_Error tolua_err;
  if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
   tolua_error(tolua_S,"#vinvalid type in array indexing.",&tolua_err);
 }
#endif
 tolua_index = (int)tolua_tonumber(tolua_S,2,0);
#ifndef TOLUA_RELEASE
 if (tolua_index<0)
  tolua_error(tolua_S,"array indexing out of range.",NULL);
#endif
 tolua_pushnumber(tolua_S,(lua_Number)self->protobuf_content[tolua_index]);
 return 1;
}
#endif //#ifndef TOLUA_DISABLE

/* set function: protobuf_content of class  Packet */
#ifndef TOLUA_DISABLE_tolua_set_ContestClientService_Packet_protobuf_content
static int tolua_set_ContestClientService_Packet_protobuf_content(lua_State* tolua_S)
{
 int tolua_index;
  Packet* self;
 lua_pushstring(tolua_S,".self");
 lua_rawget(tolua_S,1);
 self = (Packet*)  lua_touserdata(tolua_S,-1);
#ifndef TOLUA_RELEASE
 {
  tolua_Error tolua_err;
  if (!tolua_isnumber(tolua_S,2,0,&tolua_err))
   tolua_error(tolua_S,"#vinvalid type in array indexing.",&tolua_err);
 }
#endif
 tolua_index = (int)tolua_tonumber(tolua_S,2,0);
#ifndef TOLUA_RELEASE
 if (tolua_index<0)
  tolua_error(tolua_S,"array indexing out of range.",NULL);
#endif
  self->protobuf_content[tolua_index] = ((char)  tolua_tonumber(tolua_S,3,0));
 return 0;
}
#endif //#ifndef TOLUA_DISABLE

/* method: CalculateCheckSum of class  Packet */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_Packet_CalculateCheckSum00
static int tolua_ContestClientService_Packet_CalculateCheckSum00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"Packet",0,&tolua_err) ||
     !tolua_isusertype(tolua_S,2,"Packet",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  Packet* packet = ((Packet*)  tolua_tousertype(tolua_S,2,0));
  {
   unsigned int tolua_ret = (unsigned int)  Packet::CalculateCheckSum(packet);
   tolua_pushnumber(tolua_S,(lua_Number)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'CalculateCheckSum'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: ProtobufString of class  Packet */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_Packet_ProtobufString00
static int tolua_ContestClientService_Packet_ProtobufString00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"Packet",0,&tolua_err) ||
     !tolua_isusertype(tolua_S,2,"Packet",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  Packet* packet = ((Packet*)  tolua_tousertype(tolua_S,2,0));
  {
   std::string tolua_ret = (std::string)  Packet::ProtobufString(packet);
   tolua_pushcppstring(tolua_S,(const char*)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'ProtobufString'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: Construct of class  Packet */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_Packet_Construct00
static int tolua_ContestClientService_Packet_Construct00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"Packet",0,&tolua_err) ||
     !tolua_isnumber(tolua_S,2,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,3,0,&tolua_err) ||
     !tolua_isnumber(tolua_S,4,0,&tolua_err) ||
     !tolua_iscppstring(tolua_S,5,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,6,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  unsigned int sequence_id = ((unsigned int)  tolua_tonumber(tolua_S,2,0));
  unsigned short module_id = ((unsigned short)  tolua_tonumber(tolua_S,3,0));
  unsigned short message_id = ((unsigned short)  tolua_tonumber(tolua_S,4,0));
  std::string protobuf_string = ((std::string)  tolua_tocppstring(tolua_S,5,0));
  {
   Packet* tolua_ret = (Packet*)  Packet::Construct(sequence_id,module_id,message_id,protobuf_string);
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"Packet");
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'Construct'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: Destroy of class  Packet */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_Packet_Destroy00
static int tolua_ContestClientService_Packet_Destroy00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"Packet",0,&tolua_err) ||
     !tolua_isusertype(tolua_S,2,"Packet",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  Packet* packet = ((Packet*)  tolua_tousertype(tolua_S,2,0));
  {
   Packet::Destroy(packet);
  }
 }
 return 0;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'Destroy'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: Create of class  ContestClientService */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_ContestClientService_Create00
static int tolua_ContestClientService_ContestClientService_Create00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertable(tolua_S,1,"ContestClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  {
   ContestClientService* tolua_ret = (ContestClientService*)  ContestClientService::Create();
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"ContestClientService");
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'Create'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: Init of class  ContestClientService */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_ContestClientService_Init00
static int tolua_ContestClientService_ContestClientService_Init00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"ContestClientService",0,&tolua_err) ||
     !tolua_iscppstring(tolua_S,2,0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  ContestClientService* self = (ContestClientService*)  tolua_tousertype(tolua_S,1,0);
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

/* method: Start of class  ContestClientService */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_ContestClientService_Start00
static int tolua_ContestClientService_ContestClientService_Start00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"ContestClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  ContestClientService* self = (ContestClientService*)  tolua_tousertype(tolua_S,1,0);
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

/* method: Stop of class  ContestClientService */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_ContestClientService_Stop00
static int tolua_ContestClientService_ContestClientService_Stop00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"ContestClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  ContestClientService* self = (ContestClientService*)  tolua_tousertype(tolua_S,1,0);
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

/* method: Running of class  ContestClientService */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_ContestClientService_Running00
static int tolua_ContestClientService_ContestClientService_Running00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"ContestClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  ContestClientService* self = (ContestClientService*)  tolua_tousertype(tolua_S,1,0);
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

/* method: Boot of class  ContestClientService */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_ContestClientService_Boot00
static int tolua_ContestClientService_ContestClientService_Boot00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"ContestClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  ContestClientService* self = (ContestClientService*)  tolua_tousertype(tolua_S,1,0);
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

/* method: ReadPacket of class  ContestClientService */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_ContestClientService_ReadPacket00
static int tolua_ContestClientService_ContestClientService_ReadPacket00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"ContestClientService",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,2,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  ContestClientService* self = (ContestClientService*)  tolua_tousertype(tolua_S,1,0);
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'ReadPacket'", NULL);
#endif
  {
   Packet* tolua_ret = (Packet*)  self->ReadPacket();
    tolua_pushusertype(tolua_S,(void*)tolua_ret,"Packet");
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'ReadPacket'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* method: WritePacket of class  ContestClientService */
#ifndef TOLUA_DISABLE_tolua_ContestClientService_ContestClientService_WritePacket00
static int tolua_ContestClientService_ContestClientService_WritePacket00(lua_State* tolua_S)
{
#ifndef TOLUA_RELEASE
 tolua_Error tolua_err;
 if (
     !tolua_isusertype(tolua_S,1,"ContestClientService",0,&tolua_err) ||
     !tolua_isusertype(tolua_S,2,"Packet",0,&tolua_err) ||
     !tolua_isnoobj(tolua_S,3,&tolua_err)
 )
  goto tolua_lerror;
 else
#endif
 {
  ContestClientService* self = (ContestClientService*)  tolua_tousertype(tolua_S,1,0);
  Packet* packet = ((Packet*)  tolua_tousertype(tolua_S,2,0));
#ifndef TOLUA_RELEASE
  if (!self) tolua_error(tolua_S,"invalid 'self' in function 'WritePacket'", NULL);
#endif
  {
   bool tolua_ret = (bool)  self->WritePacket(packet);
   tolua_pushboolean(tolua_S,(bool)tolua_ret);
  }
 }
 return 1;
#ifndef TOLUA_RELEASE
 tolua_lerror:
 tolua_error(tolua_S,"#ferror in function 'WritePacket'.",&tolua_err);
 return 0;
#endif
}
#endif //#ifndef TOLUA_DISABLE

/* Open function */
TOLUA_API int tolua_ContestClientService_open (lua_State* tolua_S)
{
 tolua_open(tolua_S);
 tolua_reg_types(tolua_S);
 tolua_module(tolua_S,NULL,0);
 tolua_beginmodule(tolua_S,NULL);
  tolua_cclass(tolua_S,"Packet","Packet","",NULL);
  tolua_beginmodule(tolua_S,"Packet");
   tolua_variable(tolua_S,"size",tolua_get_Packet_unsigned_size,tolua_set_Packet_unsigned_size);
   tolua_variable(tolua_S,"check_sum",tolua_get_Packet_unsigned_check_sum,tolua_set_Packet_unsigned_check_sum);
   tolua_variable(tolua_S,"sequence_id",tolua_get_Packet_unsigned_sequence_id,tolua_set_Packet_unsigned_sequence_id);
   tolua_variable(tolua_S,"module_id",tolua_get_Packet_unsigned_module_id,tolua_set_Packet_unsigned_module_id);
   tolua_variable(tolua_S,"message_id",tolua_get_Packet_unsigned_message_id,tolua_set_Packet_unsigned_message_id);
   tolua_variable(tolua_S,"protobuf_size",tolua_get_Packet_unsigned_protobuf_size,tolua_set_Packet_unsigned_protobuf_size);
   tolua_array(tolua_S,"protobuf_content",tolua_get_ContestClientService_Packet_protobuf_content,tolua_set_ContestClientService_Packet_protobuf_content);
   tolua_function(tolua_S,"CalculateCheckSum",tolua_ContestClientService_Packet_CalculateCheckSum00);
   tolua_function(tolua_S,"ProtobufString",tolua_ContestClientService_Packet_ProtobufString00);
   tolua_function(tolua_S,"Construct",tolua_ContestClientService_Packet_Construct00);
   tolua_function(tolua_S,"Destroy",tolua_ContestClientService_Packet_Destroy00);
  tolua_endmodule(tolua_S);
  tolua_cclass(tolua_S,"ContestClientService","ContestClientService","",NULL);
  tolua_beginmodule(tolua_S,"ContestClientService");
   tolua_function(tolua_S,"Create",tolua_ContestClientService_ContestClientService_Create00);
   tolua_function(tolua_S,"Init",tolua_ContestClientService_ContestClientService_Init00);
   tolua_function(tolua_S,"Start",tolua_ContestClientService_ContestClientService_Start00);
   tolua_function(tolua_S,"Stop",tolua_ContestClientService_ContestClientService_Stop00);
   tolua_function(tolua_S,"Running",tolua_ContestClientService_ContestClientService_Running00);
   tolua_function(tolua_S,"Boot",tolua_ContestClientService_ContestClientService_Boot00);
   tolua_function(tolua_S,"ReadPacket",tolua_ContestClientService_ContestClientService_ReadPacket00);
   tolua_function(tolua_S,"WritePacket",tolua_ContestClientService_ContestClientService_WritePacket00);
  tolua_endmodule(tolua_S);
 tolua_endmodule(tolua_S);
 return 1;
}


#if defined(LUA_VERSION_NUM) && LUA_VERSION_NUM >= 501
 TOLUA_API int luaopen_ContestClientService (lua_State* tolua_S) {
 return tolua_ContestClientService_open(tolua_S);
};
#endif

