#ifndef ANTS_SHARED_LIBRARY_H
#define ANTS_SHARED_LIBRARY_H

#ifdef __import
#undef __import
#endif

#ifndef __export
#define __export
#endif

#include <ants/interface/message.h>
#include <ants/interface/event.h>
#include <ants/interface/import.h>
#include <ants/interface/param.h>
#include <ants/interface/export.h>
#include <ants/interface/context.h>
#include <ants/interface/error.h>
#include <ants/interface/export_helper.h>

#endif // ANTS_SHARED_LIBRARY_H