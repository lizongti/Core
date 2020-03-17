#ifndef LOGGER_SERVICE
#define LOGGER_SERVICE

extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

// extern "C"
// {
//     int luaopen_special_base64(lua_State *l);
//     int luaopen_pb(lua_State *l);
//     int luaopen_protobuf_c(lua_State *l);
//     void toluafix_open(lua_State *l);
// }

class lua_service : public service
{
public:
    lua_service(){};

    virtual ~lua_service(){};

public:
    virtual bool init(const std::string &json)
    {
        std::string entry;
        CONFIG_CREATE_DOCUMENT(json, root);
        CONFIG_READ_MEMBER(root, "entry", entry);

        state_ = luaL_newstate();
        if (!state_)
        {
            LOG(SYS, ERROR) << boost::format("new lua state error: %s\n") % this % __FUNCTION__;
            return false;
        }

        if (luaL_dofile(state_, entry.c_str()))
        {
            std::string error = lua_tostring(state_, -1);
            lua_pop(state_, 1);

            LOG(SYS, ERROR) << boost::format("do lua entry error: %s\n") % this % __FUNCTION__ % error;
            return false;
        }

        // luaopen_special_base64(state_);
        // luaopen_pb(state_);
        // luaopen_protobuf_c(state_);
        // toluafix_open(state_);

        // extern int luaopen_util(lua_State * L);
        // luaopen_util(state_);

        // extern int luaopen_rapidjson(lua_State * L);
        // luaopen_rapidjson(state_);

        // LuaIntf::LuaBinding(state_)
        //     .beginModule("Base")
        //     .beginModule("Enviroment")
        //     .addConstant("cwd", Resource<std::string, std::string>::Get(STRING_WORK_DIRECTORY))
        //     .addConstant("pro_spec_t", Resource<std::string, std::string>::Get(STRING_ENVIROMENT_VARIABLE))
        //     .addConstant("config_path", (boost::format("%s/../Config/%s") %
        //                                  Resource<std::string, std::string>::Get(STRING_WORK_DIRECTORY) %
        //                                  Resource<std::string, std::string>::Get(STRING_ENVIROMENT_VARIABLE))
        //                                     .str())
        // .endModule()
        //     .endModule();

        lua_getglobal(state_, "init");
        lua_pcall(global_L, 1, 0, 0);

        return true;
    }

    virtual bool callback(MessageType type, void *data)
    {
        if (type == MSG_TYPE_PACKET)
        {
            lua_getglobal(state_, "callback");
            tolua_pushusertype(state_, data, "Packet");
            lua_pcall(state_, 2, 0, 0);
        }

        return true;
    }
    virtual bool release()
    {
        lua_getglobal(state_, "release");
        lua_pcall(state_, 1, 0, 0);

        lua_close(state_);

        return true;
    }

protected:
    lua_State *state_;
};

#endif // !LOGGER_SERVICE