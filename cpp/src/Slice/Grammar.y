%{

// **********************************************************************
//
// Copyright (c) 2001
// Mutable Realms, Inc.
// Huntsville, AL, USA
//
// All Rights Reserved
//
// **********************************************************************

#include <Slice/GrammarUtil.h>
#include <IceUtil/UUID.h>

#ifdef _WIN32
// I get this warning from some bison version:
// warning C4102: 'yyoverflowlab' : unreferenced label
#   pragma warning( disable : 4102 )
#endif

using namespace std;
using namespace Slice;

void
yyerror(const char* s)
{
    unit->error(s);
}

%}

%pure_parser

//
// All keyword tokens. Make sure to modify the "keyword" rule in this
// file if the list of keywords is changed. Also make sure to add the
// keyword to the keyword table in Scanner.l.
//
%token ICE_MODULE
%token ICE_CLASS
%token ICE_INTERFACE
%token ICE_EXCEPTION
%token ICE_STRUCT
%token ICE_SEQUENCE
%token ICE_DICTIONARY
%token ICE_ENUM
%token ICE_OUT
%token ICE_EXTENDS
%token ICE_IMPLEMENTS
%token ICE_THROWS
%token ICE_VOID
%token ICE_BYTE
%token ICE_BOOL
%token ICE_SHORT
%token ICE_INT
%token ICE_LONG
%token ICE_FLOAT
%token ICE_DOUBLE
%token ICE_STRING
%token ICE_OBJECT
%token ICE_LOCAL_OBJECT
%token ICE_LOCAL
%token ICE_CONST
%token ICE_FALSE
%token ICE_TRUE

//
// Other tokens.
//
%token ICE_SCOPE_DELIMITER
%token ICE_IDENTIFIER
%token ICE_STRING_LITERAL
%token ICE_INTEGER_LITERAL
%token ICE_FLOATING_POINT_LITERAL

%%


// ----------------------------------------------------------------------
start
// ----------------------------------------------------------------------
: definitions
{
}
;

// ----------------------------------------------------------------------
meta_data
// ----------------------------------------------------------------------
: '[' string_list ']'
{
    $$ = $2;
}
|
{
    $$ = new StringListTok;
}
;

// ----------------------------------------------------------------------
definitions
// ----------------------------------------------------------------------
: meta_data definition ';' definitions
{
    StringListTokPtr metaData = StringListTokPtr::dynamicCast($1);
    ContainedPtr contained = ContainedPtr::dynamicCast($2);
    if(contained && !metaData->v.empty())
    {
	contained->setMetaData(metaData->v);
    }
}
| error ';' definitions
{
    yyerrok;
}
| meta_data definition
{
    unit->error("`;' missing after definition");
}
|
{
}
;

// ----------------------------------------------------------------------
definition
// ----------------------------------------------------------------------
: module_def
{
}
| class_decl
{
}
| class_def
{
}
| interface_decl
{
}
| interface_def
{
}
| exception_decl
{
}
| exception_def
{
}
| struct_decl
{
}
| struct_def
{
}
| sequence_def
{
}
| dictionary_def
{
}
| enum_def
{
}
| const_def
{
}
;

// ----------------------------------------------------------------------
module_def
// ----------------------------------------------------------------------
: ICE_MODULE ICE_IDENTIFIER
{
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ContainerPtr cont = unit->currentContainer();
    ModulePtr module = cont->createModule(ident->v);
    if(!module)
    {
	YYERROR; // Can't continue, jump to next yyerrok
    }
    cont->checkIntroduced(ident->v, module);
    unit->pushContainer(module);
    $$ = module;
}
'{' definitions '}'
{
    unit->popContainer();
    $$ = $3;
}
;

// ----------------------------------------------------------------------
exception_id
// ----------------------------------------------------------------------
: ICE_EXCEPTION ICE_IDENTIFIER
{
    $$ = $2;
}
| ICE_EXCEPTION keyword
{
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    unit->error("keyword `" + ident->v + "' cannot be used as exception name");
    $$ = $2;
}
;

// ----------------------------------------------------------------------
exception_decl
// ----------------------------------------------------------------------
: local_qualifier exception_id
{
    unit->error("exceptions cannot be forward declared");
    $$ = $2;
}
;

// ----------------------------------------------------------------------
exception_def
// ----------------------------------------------------------------------
: local_qualifier exception_id exception_extends
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ExceptionPtr base = ExceptionPtr::dynamicCast($3);
    ContainerPtr cont = unit->currentContainer();
    ExceptionPtr ex = cont->createException(ident->v, base, local->v);
    if(!ex)
    {
	YYERROR; // Can't continue, jump to next yyerrok
    }
    cont->checkIntroduced(ident->v, ex);
    unit->pushContainer(ex);
    $$ = ex;
}
'{' exception_exports '}'
{
    unit->popContainer();
    $$ = $4;
}
;

// ----------------------------------------------------------------------
exception_extends
// ----------------------------------------------------------------------
: ICE_EXTENDS scoped_name
{
    StringTokPtr scoped = StringTokPtr::dynamicCast($2);
    ContainerPtr cont = unit->currentContainer();
    ContainedPtr contained = cont->lookupException(scoped->v);
    cont->checkIntroduced(scoped->v);
    $$ = contained;
}
|
{
    $$ = 0;
}
;

// ----------------------------------------------------------------------
exception_exports
// ----------------------------------------------------------------------
: meta_data exception_export ';' exception_exports
{
    StringListTokPtr metaData = StringListTokPtr::dynamicCast($1);
    ContainedPtr contained = ContainedPtr::dynamicCast($2);
    if(contained && !metaData->v.empty())
    {
	contained->setMetaData(metaData->v);
    }
}
| error ';' exception_exports
{
}
| meta_data exception_export
{
    unit->error("`;' missing after definition");
}
|
{
}
;

// ----------------------------------------------------------------------
exception_export
// ----------------------------------------------------------------------
: type_id
{
    TypeStringTokPtr tsp = TypeStringTokPtr::dynamicCast($1);
    TypePtr type = tsp->v.first;
    string ident = tsp->v.second;
    ExceptionPtr ex = ExceptionPtr::dynamicCast(unit->currentContainer());
    assert(ex);
    DataMemberPtr dm = ex->createDataMember(ident, type);
    unit->currentContainer()->checkIntroduced(ident, dm);
    $$ = dm;
}
| type keyword
{
    TypePtr type = TypePtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ExceptionPtr ex = ExceptionPtr::dynamicCast(unit->currentContainer());
    unit->error("keyword `" + ident->v + "' cannot be used as exception name");
    $$ = ex->createDataMember(ident->v, type);
}
| type
{
    TypePtr type = TypePtr::dynamicCast($1);
    ExceptionPtr ex = ExceptionPtr::dynamicCast(unit->currentContainer());
    unit->error("missing data member name");
    $$ = ex->createDataMember("", type);
}
;

// ----------------------------------------------------------------------
struct_id
// ----------------------------------------------------------------------
: ICE_STRUCT ICE_IDENTIFIER
{
    $$ = $2;
}
| ICE_STRUCT keyword
{
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    unit->error("keyword `" + ident->v + "' cannot be used as struct name");
    $$ = $2;
}
;

// ----------------------------------------------------------------------
struct_decl
// ----------------------------------------------------------------------
: local_qualifier struct_id
{
    unit->error("structs cannot be forward declared");
    $$ = $2;
}
;

// ----------------------------------------------------------------------
struct_def
// ----------------------------------------------------------------------
: local_qualifier struct_id
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ContainerPtr cont = unit->currentContainer();
    StructPtr st = cont->createStruct(ident->v, local->v);
    if(!st)
    {
	YYERROR; // Can't continue, jump to next yyerrok
    }
    cont->checkIntroduced(ident->v, st);
    unit->pushContainer(st);
    $$ = st;
}
'{' struct_exports '}'
{
    unit->popContainer();
    $$ = $3;

    //
    // Empty structures are not allowed
    //
    StructPtr st = StructPtr::dynamicCast($$);
    assert(st);
    if(st->dataMembers().empty())
    {
    	unit->error("struct `" + st->name() + "' must have at least one member");
    }
}
;

// ----------------------------------------------------------------------
struct_exports
// ----------------------------------------------------------------------
: meta_data struct_export ';' struct_exports
{
    StringListTokPtr metaData = StringListTokPtr::dynamicCast($1);
    ContainedPtr contained = ContainedPtr::dynamicCast($2);
    if(contained && !metaData->v.empty())
    {
	contained->setMetaData(metaData->v);
    }
}
| error ';' struct_exports
{
}
| meta_data struct_export
{
    unit->error("`;' missing after definition");
}
|
{
}
;

// ----------------------------------------------------------------------
struct_export
// ----------------------------------------------------------------------
: type_id
{
    TypeStringTokPtr tsp = TypeStringTokPtr::dynamicCast($1);
    TypePtr type = tsp->v.first;
    string ident = tsp->v.second;
    StructPtr st = StructPtr::dynamicCast(unit->currentContainer());
    assert(st);
    DataMemberPtr dm = st->createDataMember(ident, type);
    unit->currentContainer()->checkIntroduced(ident, dm);
    $$ = dm;
}
| type keyword
{
    TypePtr type = TypePtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    StructPtr st = StructPtr::dynamicCast(unit->currentContainer());
    assert(st);
    unit->error("keyword `" + ident->v + "' cannot be used as data member name");
    $$ = st->createDataMember(ident->v, type);
}
| type
{
    TypePtr type = TypePtr::dynamicCast($1);
    StructPtr st = StructPtr::dynamicCast(unit->currentContainer());
    assert(st);
    unit->error("missing data member name");
    $$ = st->createDataMember("", type);
}
;

// ----------------------------------------------------------------------
class_id
// ----------------------------------------------------------------------
: ICE_CLASS ICE_IDENTIFIER
{
    $$ = $2;
}
| ICE_CLASS keyword
{
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    unit->error("keyword `" + ident->v + "' cannot be used as class name");
    $$ = $2;
}
;

// ----------------------------------------------------------------------
class_decl
// ----------------------------------------------------------------------
: local_qualifier class_id
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ContainerPtr cont = unit->currentContainer();
    ClassDeclPtr cl = cont->createClassDecl(ident->v, false, local->v);
    $$ = cl;
}
;

// ----------------------------------------------------------------------
class_def
// ----------------------------------------------------------------------
: local_qualifier class_id class_extends implements
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ContainerPtr cont = unit->currentContainer();
    ClassDefPtr base = ClassDefPtr::dynamicCast($3);
    ClassListTokPtr bases = ClassListTokPtr::dynamicCast($4);
    if(base)
    {
	bases->v.push_front(base);
    }
    ClassDefPtr cl = cont->createClassDef(ident->v, false, bases->v, local->v);
    if(!cl)
    {
	YYERROR; // Can't continue, jump to next yyerrok
    }
    cont->checkIntroduced(ident->v, cl);
    unit->pushContainer(cl);
    $$ = cl;
}
'{' class_exports '}'
{
    unit->popContainer();
    $$ = $6;
}
;

// ----------------------------------------------------------------------
class_extends
// ----------------------------------------------------------------------
: ICE_EXTENDS scoped_name
{
    StringTokPtr scoped = StringTokPtr::dynamicCast($2);
    ContainerPtr cont = unit->currentContainer();
    TypeList types = cont->lookupType(scoped->v);
    $$ = 0;
    if(!types.empty())
    {
	ClassDeclPtr cl = ClassDeclPtr::dynamicCast(types.front());
	if(!cl)
	{
	    string msg = "`";
	    msg += scoped->v;
	    msg += "' is not a class";
	    unit->error(msg);
	}
	else
	{
	    ClassDefPtr def = cl->definition();
	    if(!def)
	    {
		string msg = "`";
		msg += scoped->v;
		msg += "' has been declared but not defined";
		unit->error(msg);
	    }
	    else
	    {
	    	cont->checkIntroduced(scoped->v);
		$$ = def;
	    }
	}
    }
}
|
{
    $$ = 0;
}
;

// ----------------------------------------------------------------------
implements
// ----------------------------------------------------------------------
: ICE_IMPLEMENTS interface_list
{
    $$ = $2;
}
|
{
    $$ = new ClassListTok;
}
;

// ----------------------------------------------------------------------
class_exports
// ----------------------------------------------------------------------
: meta_data class_export ';' class_exports
{
    StringListTokPtr metaData = StringListTokPtr::dynamicCast($1);
    ContainedPtr contained = ContainedPtr::dynamicCast($2);
    if(contained && !metaData->v.empty())
    {
	contained->setMetaData(metaData->v);
    }
}
| error ';' class_exports
{
}
| meta_data class_export
{
    unit->error("`;' missing after definition");
}
|
{
}
;

// ----------------------------------------------------------------------
class_export
// ----------------------------------------------------------------------
: operation
{
}
| type_id
{
    TypeStringTokPtr tsp = TypeStringTokPtr::dynamicCast($1);
    TypePtr type = tsp->v.first;
    string ident = tsp->v.second;
    ClassDefPtr cl = ClassDefPtr::dynamicCast(unit->currentContainer());
    assert(cl);
    DataMemberPtr dm = cl->createDataMember(ident, type);
    cl->checkIntroduced(ident, dm);
    $$ = dm;
}
| type keyword
{
    TypePtr type = TypePtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ClassDefPtr cl = ClassDefPtr::dynamicCast(unit->currentContainer());
    assert(cl);
    unit->error("keyword `" + ident->v + "' cannot be used as data member name");
    $$ = cl->createDataMember(ident->v, type);
}
| type
{
    TypePtr type = TypePtr::dynamicCast($1);
    ClassDefPtr cl = ClassDefPtr::dynamicCast(unit->currentContainer());
    assert(cl);
    unit->error("missing data member name");
    $$ = cl->createDataMember("", type);
}
;

// ----------------------------------------------------------------------
interface_id
// ----------------------------------------------------------------------
: ICE_INTERFACE ICE_IDENTIFIER
{
    $$ = $2;
}
| ICE_INTERFACE keyword
{
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    unit->error("keyword `" + ident->v + "' cannot be used as interface name");
    $$ = $2;
}
;

// ----------------------------------------------------------------------
interface_decl
// ----------------------------------------------------------------------
: local_qualifier interface_id
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ContainerPtr cont = unit->currentContainer();
    ClassDeclPtr cl = cont->createClassDecl(ident->v, true, local->v);
    cont->checkIntroduced(ident->v, cl);
    $$ = cl;
}
;

// ----------------------------------------------------------------------
interface_def
// ----------------------------------------------------------------------
: local_qualifier interface_id interface_extends
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ContainerPtr cont = unit->currentContainer();
    ClassListTokPtr bases = ClassListTokPtr::dynamicCast($3);
    ClassDefPtr cl = cont->createClassDef(ident->v, true, bases->v, local->v);
    if(!cl)
    {
	YYERROR; // Can't continue, jump to next yyerrok
    }
    cont->checkIntroduced(ident->v, cl);
    unit->pushContainer(cl);
    $$ = cl;
}
'{' interface_exports '}'
{
    unit->popContainer();
    $$ = $4;
}
;

// ----------------------------------------------------------------------
interface_list
// ----------------------------------------------------------------------
: scoped_name ',' interface_list
{
    ClassListTokPtr intfs = ClassListTokPtr::dynamicCast($3);
    StringTokPtr scoped = StringTokPtr::dynamicCast($1);
    ContainerPtr cont = unit->currentContainer();
    TypeList types = cont->lookupType(scoped->v);
    if(!types.empty())
    {
	ClassDeclPtr cl = ClassDeclPtr::dynamicCast(types.front());
	if(!cl || !cl->isInterface())
	{
	    string msg = "`";
	    msg += scoped->v;
	    msg += "' is not an interface";
	    unit->error(msg);
	}
	else
	{
	    ClassDefPtr def = cl->definition();
	    if(!def)
	    {
		string msg = "`";
		msg += scoped->v;
		msg += "' has been declared but not defined";
		unit->error(msg);
	    }
	    else
	    {
	    	cont->checkIntroduced(scoped->v);
		intfs->v.push_front(def);
	    }
	}
    }
    $$ = intfs;
}
| scoped_name
{
    ClassListTokPtr intfs = new ClassListTok;
    StringTokPtr scoped = StringTokPtr::dynamicCast($1);
    ContainerPtr cont = unit->currentContainer();
    TypeList types = cont->lookupType(scoped->v);
    if(!types.empty())
    {
	ClassDeclPtr cl = ClassDeclPtr::dynamicCast(types.front());
	if(!cl || !cl->isInterface())
	{
	    string msg = "`";
	    msg += scoped->v;
	    msg += "' is not an interface";
	    unit->error(msg);
	}
	else
	{
	    ClassDefPtr def = cl->definition();
	    if(!def)
	    {
		string msg = "`";
		msg += scoped->v;
		msg += "' has been declared but not defined";
		unit->error(msg);
	    }
	    else
	    {
	    	cont->checkIntroduced(scoped->v);
		intfs->v.push_front(def);
	    }
	}
    }
    $$ = intfs;
}
;

// ----------------------------------------------------------------------
interface_extends
// ----------------------------------------------------------------------
: ICE_EXTENDS interface_list
{
    $$ = $2;
}
|
{
    $$ = new ClassListTok;
}
;

// ----------------------------------------------------------------------
interface_exports
// ----------------------------------------------------------------------
: meta_data interface_export ';' interface_exports
{
    StringListTokPtr metaData = StringListTokPtr::dynamicCast($1);
    ContainedPtr contained = ContainedPtr::dynamicCast($2);
    if(contained && !metaData->v.empty())
    {
	contained->setMetaData(metaData->v);
    }
}
| error ';' interface_exports
{
}
| meta_data interface_export
{
    unit->error("`;' missing after definition");
}
|
{
}
;

// ----------------------------------------------------------------------
interface_export
// ----------------------------------------------------------------------
: operation
{
}
;

// ----------------------------------------------------------------------
exception_list
// ----------------------------------------------------------------------
: exception ',' exception_list
{
    ExceptionPtr exception = ExceptionPtr::dynamicCast($1);
    ExceptionListTokPtr exceptionList = ExceptionListTokPtr::dynamicCast($3);
    exceptionList->v.push_front(exception);
    $$ = exceptionList;
}
| exception
{
    ExceptionPtr exception = ExceptionPtr::dynamicCast($1);
    ExceptionListTokPtr exceptionList = new ExceptionListTok;
    exceptionList->v.push_front(exception);
    $$ = exceptionList;
}
;

// ----------------------------------------------------------------------
exception
// ----------------------------------------------------------------------
: scoped_name
{
    StringTokPtr scoped = StringTokPtr::dynamicCast($1);
    ContainerPtr cont = unit->currentContainer();
    ExceptionPtr exception = cont->lookupException(scoped->v);
    if(!exception)
    {
	exception = cont->createException(IceUtil::generateUUID(), 0, false);
    }
    cont->checkIntroduced(scoped->v, exception);
    $$ = exception;
}
| keyword
{
    StringTokPtr ident = StringTokPtr::dynamicCast($1);
    unit->error("keyword `" + ident->v + "' cannot be used as exception name");
    $$ = unit->currentContainer()->createException(IceUtil::generateUUID(), 0, false);
}
;

// ----------------------------------------------------------------------
sequence_def
// ----------------------------------------------------------------------
: local_qualifier ICE_SEQUENCE '<' type '>' ICE_IDENTIFIER
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($6);
    TypePtr type = TypePtr::dynamicCast($4);
    ContainerPtr cont = unit->currentContainer();
    $$ = cont->createSequence(ident->v, type, local->v);
}
| local_qualifier ICE_SEQUENCE '<' type '>' keyword
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($6);
    TypePtr type = TypePtr::dynamicCast($4);
    ContainerPtr cont = unit->currentContainer();
    $$ = cont->createSequence(ident->v, type, local->v);
    unit->error("keyword `" + ident->v + "' cannot be used as sequence name");
}
;

// ----------------------------------------------------------------------
dictionary_def
// ----------------------------------------------------------------------
: local_qualifier ICE_DICTIONARY '<' type ',' type '>' ICE_IDENTIFIER
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($8);
    TypePtr keyType = TypePtr::dynamicCast($4);
    TypePtr valueType = TypePtr::dynamicCast($6);
    ContainerPtr cont = unit->currentContainer();
    $$ = cont->createDictionary(ident->v, keyType, valueType, local->v);
}
| local_qualifier ICE_DICTIONARY '<' type ',' type '>' keyword
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($8);
    TypePtr keyType = TypePtr::dynamicCast($4);
    TypePtr valueType = TypePtr::dynamicCast($6);
    ContainerPtr cont = unit->currentContainer();
    $$ = cont->createDictionary(ident->v, keyType, valueType, local->v);
    unit->error("keyword `" + ident->v + "' cannot be used as dictionary name");
}
;

// ----------------------------------------------------------------------
enum_id
// ----------------------------------------------------------------------
: ICE_ENUM ICE_IDENTIFIER
{
    $$ = $2;
}
| ICE_ENUM keyword
{
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    unit->error("keyword `" + ident->v + "' cannot be used as enumeration name");
    $$ = $2;
}
;

// ----------------------------------------------------------------------
enum_def
// ----------------------------------------------------------------------
: local_qualifier enum_id
{
    BoolTokPtr local = BoolTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ContainerPtr cont = unit->currentContainer();
    EnumPtr en = cont->createEnum(ident->v, local->v);
    cont->checkIntroduced(ident->v, en);
    $$ = en;
}
'{' enumerator_list '}'
{
    EnumPtr en = EnumPtr::dynamicCast($3);
    if(en)
    {
	EnumeratorListTokPtr enumerators = EnumeratorListTokPtr::dynamicCast($5);
	if(enumerators->v.empty())
	{
	    unit->error("enum `" + en->name() + "' must have at least one enumerator");
	}
	en->setEnumerators(enumerators->v);
    }
    $$ = $3;
}
;

// ----------------------------------------------------------------------
enumerator_list
// ----------------------------------------------------------------------
: enumerator ',' enumerator_list
{
    EnumeratorListTokPtr ens = EnumeratorListTokPtr::dynamicCast($1);
    ens->v.splice(ens->v.end(), EnumeratorListTokPtr::dynamicCast($3)->v);
    $$ = ens;
}
| enumerator
{
}
;

// ----------------------------------------------------------------------
enumerator
// ----------------------------------------------------------------------
: ICE_IDENTIFIER
{
    StringTokPtr ident = StringTokPtr::dynamicCast($1);
    EnumeratorListTokPtr ens = new EnumeratorListTok;
    ContainerPtr cont = unit->currentContainer();
    EnumeratorPtr en = cont->createEnumerator(ident->v);
    if(en)
    {
	ens->v.push_front(en);
    }
    $$ = ens;
}
| keyword
{
    StringTokPtr ident = StringTokPtr::dynamicCast($1);
    unit->error("keyword `" + ident->v + "' cannot be used as enumerator");
    EnumeratorListTokPtr ens = new EnumeratorListTok;
    $$ = ens;
}
|
{
    EnumeratorListTokPtr ens = new EnumeratorListTok;
    $$ = ens;
}
;

// ----------------------------------------------------------------------
type_id
// ----------------------------------------------------------------------
: type ICE_IDENTIFIER
{
    TypePtr type = TypePtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    TypeStringTokPtr typestring = new TypeStringTok;
    typestring->v = make_pair(type, ident->v);
    $$ = typestring;
}
;

// ----------------------------------------------------------------------
operation_preamble
// ----------------------------------------------------------------------
: type_id
{
    TypeStringTokPtr tsp = TypeStringTokPtr::dynamicCast($1);
    TypePtr returnType = tsp->v.first;
    string name = tsp->v.second;
    ClassDefPtr cl = ClassDefPtr::dynamicCast(unit->currentContainer());
    assert(cl);
    OperationPtr op = cl->createOperation(name, returnType);
    cl->checkIntroduced(name, op);
    unit->pushContainer(op);
    $$ = op;
}
| ICE_VOID ICE_IDENTIFIER
{
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ClassDefPtr cl = ClassDefPtr::dynamicCast(unit->currentContainer());
    assert(cl);
    OperationPtr op = cl->createOperation(ident->v, 0);
    unit->currentContainer()->checkIntroduced(ident->v, op);
    unit->pushContainer(op);
    $$ = op;
}
| type keyword
{
    TypePtr returnType = TypePtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ClassDefPtr cl = ClassDefPtr::dynamicCast(unit->currentContainer());
    assert(cl);
    unit->error("keyword `" + ident->v + "' cannot be used as operation name");
    OperationPtr op = cl->createOperation(ident->v, returnType);
    unit->pushContainer(op);
    $$ = op;
}
| ICE_VOID keyword
{
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ClassDefPtr cl = ClassDefPtr::dynamicCast(unit->currentContainer());
    assert(cl);
    unit->error("keyword `" + ident->v + "' cannot be used as operation name");
    OperationPtr op = cl->createOperation(ident->v, 0);
    unit->pushContainer(op);
    $$ = op;
}
;

// ----------------------------------------------------------------------
operation
// ----------------------------------------------------------------------
: operation_preamble '(' parameters ')'
{
    unit->popContainer();
    $$ = $1;
}
throws
{
    OperationPtr op = OperationPtr::dynamicCast($5);
    ExceptionListTokPtr el = ExceptionListTokPtr::dynamicCast($6);
    assert(el);
    if(op)
    {
        op->setExceptionList(el->v);
    }
}
| operation_preamble '(' error ')'
{
    unit->popContainer();
    yyerrok;
}
throws
{
    OperationPtr op = OperationPtr::dynamicCast($5);
    ExceptionListTokPtr el = ExceptionListTokPtr::dynamicCast($6);
    assert(el);
    if(op)
    {
        op->setExceptionList(el->v);
    }
}
;
 
// ----------------------------------------------------------------------
out_qualifier
// ----------------------------------------------------------------------
: ICE_OUT
{
    BoolTokPtr out = new BoolTok;
    out->v = true;
    $$ = out;
}
|
{
    BoolTokPtr out = new BoolTok;
    out->v = false;
    $$ = out;
}
;

// ----------------------------------------------------------------------
parameters
// ----------------------------------------------------------------------
: // empty
{
}
| out_qualifier type_id
{
    BoolTokPtr isOutParam = BoolTokPtr::dynamicCast($1);
    TypeStringTokPtr tsp = TypeStringTokPtr::dynamicCast($2);
    TypePtr type = tsp->v.first;
    string ident = tsp->v.second;
    OperationPtr op = OperationPtr::dynamicCast(unit->currentContainer());
    assert(op);
    ParamDeclPtr pd = op->createParamDecl(ident, type, isOutParam->v);
    unit->currentContainer()->checkIntroduced(ident, pd);
}
| parameters ',' out_qualifier type_id
{
    BoolTokPtr isOutParam = BoolTokPtr::dynamicCast($3);
    TypeStringTokPtr tsp = TypeStringTokPtr::dynamicCast($4);
    TypePtr type = tsp->v.first;
    string ident = tsp->v.second;
    OperationPtr op = OperationPtr::dynamicCast(unit->currentContainer());
    assert(op);
    ParamDeclPtr pd = op->createParamDecl(ident, type, isOutParam->v);
    unit->currentContainer()->checkIntroduced(ident, pd);
}
| out_qualifier type keyword
{
    BoolTokPtr isOutParam = BoolTokPtr::dynamicCast($1);
    TypePtr type = TypePtr::dynamicCast($2);
    StringTokPtr ident = StringTokPtr::dynamicCast($3);
    OperationPtr op = OperationPtr::dynamicCast(unit->currentContainer());
    assert(op);
    op->createParamDecl(ident->v, type, isOutParam->v);
    unit->error("keyword `" + ident->v + "' cannot be used as parameter name");
}
| parameters ',' out_qualifier type keyword
{
    BoolTokPtr isOutParam = BoolTokPtr::dynamicCast($3);
    TypePtr type = TypePtr::dynamicCast($4);
    StringTokPtr ident = StringTokPtr::dynamicCast($5);
    OperationPtr op = OperationPtr::dynamicCast(unit->currentContainer());
    assert(op);
    op->createParamDecl(ident->v, type, isOutParam->v);
    unit->error("keyword `" + ident->v + "' cannot be used as parameter name");
}
| out_qualifier type
{
    BoolTokPtr isOutParam = BoolTokPtr::dynamicCast($1);
    TypePtr type = TypePtr::dynamicCast($2);
    OperationPtr op = OperationPtr::dynamicCast(unit->currentContainer());
    assert(op);
    op->createParamDecl(IceUtil::generateUUID(), type, isOutParam->v);
    unit->error("missing parameter name");
}
| parameters ',' out_qualifier type
{
    BoolTokPtr isOutParam = BoolTokPtr::dynamicCast($3);
    TypePtr type = TypePtr::dynamicCast($4);
    OperationPtr op = OperationPtr::dynamicCast(unit->currentContainer());
    assert(op);
    op->createParamDecl(IceUtil::generateUUID(), type, isOutParam->v);
    unit->error("missing parameter name");
}
;

// ----------------------------------------------------------------------
throws
// ----------------------------------------------------------------------
: ICE_THROWS exception_list
{
    $$ = $2;
}
|
{
    $$ = new ExceptionListTok;
}
;

// ----------------------------------------------------------------------
scoped_name
// ----------------------------------------------------------------------
: ICE_IDENTIFIER
{
}
| ICE_SCOPE_DELIMITER ICE_IDENTIFIER
{
    StringTokPtr ident = StringTokPtr::dynamicCast($2);
    ident->v = "::" + ident->v;
    $$ = ident;
}
| scoped_name ICE_SCOPE_DELIMITER ICE_IDENTIFIER
{
    StringTokPtr scoped = StringTokPtr::dynamicCast($1);
    StringTokPtr ident = StringTokPtr::dynamicCast($3);
    scoped->v += "::";
    scoped->v += ident->v;
    $$ = scoped;
}
;

// ----------------------------------------------------------------------
type
// ----------------------------------------------------------------------
: ICE_BYTE
{
    $$ = unit->builtin(Builtin::KindByte);
}
| ICE_BOOL
{
    $$ = unit->builtin(Builtin::KindBool);
}
| ICE_SHORT
{
    $$ = unit->builtin(Builtin::KindShort);
}
| ICE_INT
{
    $$ = unit->builtin(Builtin::KindInt);
}
| ICE_LONG
{
    $$ = unit->builtin(Builtin::KindLong);
}
| ICE_FLOAT
{
    $$ = unit->builtin(Builtin::KindFloat);
}
| ICE_DOUBLE
{
    $$ = unit->builtin(Builtin::KindDouble);
}
| ICE_STRING
{
    $$ = unit->builtin(Builtin::KindString);
}
| ICE_OBJECT
{
    $$ = unit->builtin(Builtin::KindObject);
}
| ICE_OBJECT '*'
{
    $$ = unit->builtin(Builtin::KindObjectProxy);
}
| ICE_LOCAL_OBJECT
{
    $$ = unit->builtin(Builtin::KindLocalObject);
}
| scoped_name
{
    StringTokPtr scoped = StringTokPtr::dynamicCast($1);
    ContainerPtr cont = unit->currentContainer();
    TypeList types = cont->lookupType(scoped->v);
    if(types.empty())
    {
	YYERROR; // Can't continue, jump to next yyerrok
    }
    cont->checkIntroduced(scoped->v);
    $$ = types.front();
}
| scoped_name '*'
{
    StringTokPtr scoped = StringTokPtr::dynamicCast($1);
    ContainerPtr cont = unit->currentContainer();
    TypeList types = cont->lookupType(scoped->v);
    if(types.empty())
    {
	YYERROR; // Can't continue, jump to next yyerrok
    }
    for(TypeList::iterator p = types.begin(); p != types.end(); ++p)
    {
	ClassDeclPtr cl = ClassDeclPtr::dynamicCast(*p);
	if(!cl)
	{
	    string msg = "`";
	    msg += scoped->v;
	    msg += "' must be class or interface";
	    unit->error(msg);
	    YYERROR; // Can't continue, jump to next yyerrok
	}
	cont->checkIntroduced(scoped->v);
	if(cl->isLocal())
	{
	    unit->error("cannot create proxy for " + cl->kindOf() + " `" + cl->name() + "'");
	}
	*p = new Proxy(cl);
    }
    $$ = types.front();
}
;

// ----------------------------------------------------------------------
string_literal
// ----------------------------------------------------------------------
: ICE_STRING_LITERAL string_literal // Adjacent string literals are concatenated
{
    StringTokPtr str1 = StringTokPtr::dynamicCast($1);
    StringTokPtr str2 = StringTokPtr::dynamicCast($2);
    str1->v += str2->v;
}
| ICE_STRING_LITERAL
{
}
;

// ----------------------------------------------------------------------
string_list
// ----------------------------------------------------------------------
: string_literal ',' string_list
{
    StringTokPtr str = StringTokPtr::dynamicCast($1);
    StringListTokPtr stringList = StringListTokPtr::dynamicCast($3);
    stringList->v.push_back(str->v);
    $$ = stringList;
}
| string_literal
{
    StringTokPtr str = StringTokPtr::dynamicCast($1);
    StringListTokPtr stringList = new StringListTok;
    stringList->v.push_back(str->v);
    $$ = stringList;
}
;

// ----------------------------------------------------------------------
local_qualifier
// ----------------------------------------------------------------------
: ICE_LOCAL
{
    BoolTokPtr local = new BoolTok;
    local->v = true;
    $$ = local;
}
|
{
    BoolTokPtr local = new BoolTok;
    local->v = false;
    $$ = local;
}
;

// ----------------------------------------------------------------------
const_initializer
// ----------------------------------------------------------------------
: ICE_INTEGER_LITERAL
{
    BuiltinPtr type = unit->builtin(Builtin::KindLong);
    IntegerTokPtr intVal = IntegerTokPtr::dynamicCast($1);
    ostringstream sstr;
    sstr << intVal->v;
    SyntaxTreeBaseStringTokPtr basestring = new SyntaxTreeBaseStringTok;
    basestring->v = make_pair(type, sstr.str());
    $$ = basestring;
}
| ICE_FLOATING_POINT_LITERAL
{
    BuiltinPtr type = unit->builtin(Builtin::KindDouble);
    FloatingTokPtr floatVal = FloatingTokPtr::dynamicCast($1);
    ostringstream sstr;
    sstr << floatVal->v;
    SyntaxTreeBaseStringTokPtr basestring = new SyntaxTreeBaseStringTok;
    basestring->v = make_pair(type, sstr.str());
    $$ = basestring;
}
| scoped_name
{
    StringTokPtr scoped = StringTokPtr::dynamicCast($1);
    SyntaxTreeBaseStringTokPtr basestring = new SyntaxTreeBaseStringTok;
    ContainedList cl = unit->currentContainer()->lookupContained(scoped->v);
    if(cl.empty())
    {
    	basestring->v = make_pair(TypePtr(0), scoped->v);
    }
    else
    {
	EnumeratorPtr enumerator = EnumeratorPtr::dynamicCast(cl.front());
	if(!enumerator)
	{
	    string msg = "illegal initializer: `" + scoped->v + "' is a";
	    static const string vowels = "aeiou";
	    string kindOf = cl.front()->kindOf();
	    if(vowels.find_first_of(kindOf[0]) != string::npos)
	    {
	    	msg += "n";
	    }
	    msg += " " + kindOf;
	    unit->error(msg);
	}
	unit->currentContainer()->checkIntroduced(scoped->v, enumerator);
	basestring->v = make_pair(enumerator, scoped->v);
    }
    $$ = basestring;
}
| ICE_STRING_LITERAL
{
    BuiltinPtr type = unit->builtin(Builtin::KindString);
    StringTokPtr literal = StringTokPtr::dynamicCast($1);
    SyntaxTreeBaseStringTokPtr basestring = new SyntaxTreeBaseStringTok;
    basestring->v = make_pair(type, literal->v);
    $$ = basestring;
}
| ICE_FALSE
{
    BuiltinPtr type = unit->builtin(Builtin::KindBool);
    StringTokPtr literal = StringTokPtr::dynamicCast($1);
    SyntaxTreeBaseStringTokPtr basestring = new SyntaxTreeBaseStringTok;
    basestring->v = make_pair(type, literal->v);
    $$ = basestring;
}
| ICE_TRUE
{
    BuiltinPtr type = unit->builtin(Builtin::KindBool);
    StringTokPtr literal = StringTokPtr::dynamicCast($1);
    SyntaxTreeBaseStringTokPtr basestring = new SyntaxTreeBaseStringTok;
    basestring->v = make_pair(type, literal->v);
    $$ = basestring;
}
;

// ----------------------------------------------------------------------
const_def
// ----------------------------------------------------------------------
: ICE_CONST type ICE_IDENTIFIER '=' const_initializer
{
    TypePtr const_type = TypePtr::dynamicCast($2);
    StringTokPtr ident = StringTokPtr::dynamicCast($3);
    SyntaxTreeBaseStringTokPtr value = SyntaxTreeBaseStringTokPtr::dynamicCast($5);
    $$ = unit->currentContainer()->createConstDef(ident->v, const_type, value->v.first, value->v.second);
}
| ICE_CONST type '=' const_initializer
{
    TypePtr const_type = TypePtr::dynamicCast($2);
    SyntaxTreeBaseStringTokPtr value = SyntaxTreeBaseStringTokPtr::dynamicCast($4);
    unit->error("missing constant name");
    $$ = unit->currentContainer()->createConstDef(IceUtil::generateUUID(), const_type, value->v.first, value->v.second);
}
;

// ----------------------------------------------------------------------
keyword
// ----------------------------------------------------------------------
: ICE_MODULE
{
}
| ICE_CLASS
{
}
| ICE_INTERFACE
{
}
| ICE_EXCEPTION
{
}
| ICE_STRUCT
{
}
| ICE_SEQUENCE
{
}
| ICE_DICTIONARY
{
}
| ICE_ENUM
{
}
| ICE_OUT
{
}
| ICE_EXTENDS
{
}
| ICE_IMPLEMENTS
{
}
| ICE_THROWS
{
}
| ICE_VOID
{
}
| ICE_BYTE
{
}
| ICE_BOOL
{
}
| ICE_SHORT
{
}
| ICE_INT
{
}
| ICE_LONG
{
}
| ICE_FLOAT
{
}
| ICE_DOUBLE
{
}
| ICE_STRING
{
}
| ICE_OBJECT
{
}
| ICE_LOCAL_OBJECT
{
}
| ICE_LOCAL
{
}
| ICE_CONST
{
}
| ICE_FALSE
{
}
| ICE_TRUE
{
}
;

%%
