/* Obj-C Re-defintions */

#define ALStringify AL_STRINGIFY
#define ALEvaluatedStringify AL_EVALUATED_STRINGIFY
#define ALEqualBools AL_EQUAL_BOOLS
#define ALVar AL_VAR
#define ALMin AL_MIN
#define ALMax AL_MAX
#define ALCapMin AL_CAP_MIN
#define ALCapMax AL_CAP_MAX
#define ALCapRange AL_CAP_RANGE
#define ALValueInRange AL_VALUE_IN_RANGE
#define ALValueInRangeExclusive AL_VALUE_IN_RANGE_EXCLUSIVE
#define ALFillStaticArray AL_FILL_STATIC_ARRAY
#define ALStaticArrayCount AL_STATIC_ARRAY_COUNT
#define ALConfirmOrPerform AL_CONFIRM_OR_PERFORM
#define ALCompilerIf AL_COMPILER_IF
#define ALCompilerElse AL_COMPILER_ELSE
#define ALCompilerEndIf AL_COMPILER_END_IF
#define ALCompilerTypesCompatible AL_COMPILER_TYPES_COMPATIBLE
#define ALCompilerAssert AL_COMPILER_ASSERT
#define ALIntType AL_INT_TYPE
#define ALFloatType AL_FLOAT_TYPE
#define ALCompatibleScalarTypes AL_COMPATIBLE_SCALAR_TYPES
#define ALNoOp AL_NO_OP

/* Obj-C-Only Definitions */

#define ALStringConstExtern(constantName) extern NSString *const constantName;
#define ALStringConst(constantName) NSString *const constantName = @ALStringify(constantName)
#define ALUniqueStringForThisMethod [NSString stringWithFormat: @"%@_%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd)]
#define ALUniqueStringForThisMethodAndInstance [NSString stringWithFormat: @"%@_%@_%p", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self]

#define ALFlippedPoint(point, rect) NSMakePoint(point.x, NSHeight(rect) - point.y - 1.0)
#define ALConditionalFlippedPoint(point, rect, flip) (flip ? ALFlippedPoint(point, rect) : point)

#define ALRoundedEqualPoints(p1, p2) ((round((p1).x) == round((p2).x)) && (round((p1).y) == round((p2).y)))
#define ALRoundedEqualSizes(s1, s2) ((round((s1).width) == round((s2).width)) && (round((s1).height) == round((s2).height)))
#define ALRoundedEqualRects(r1, r2) (ALRoundedEqualPoints(r1.origin, r2.origin) && ALRoundedEqualSizes(r1.size, r2.size))

#define ALTryCatch(tryAction, catchAction) ({ @try { tryAction; } @catch(id exception) { catchAction; } })