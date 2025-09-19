// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:equatable_gen/src/models/equatable_element.dart';

extension _FieldElement on FieldElement2 {
  String get $name => displayName;
}

Extension writeExtension(EquatableElement element) {
  if (!element.isAutoInclude && !element.hasPropsField) {
    print('\n[EXT] class "${element.name}" does not have props getter\n');
  }

  final sanitizedName = element.name.replaceAll(RegExp('^_+'), '').toPascalCase();

  return Extension(
    (b) =>
        b
          ..name = '_\$${sanitizedName}EquatableAnnotations'
          ..on = refer(element.name)
          ..methods.add(
            Method(
              (b) =>
                  b
                    ..name = 'copyWith'
                    ..returns = refer(element.name)
                    ..optionalParameters.addAll(
                      element.props.map(
                        (field) => Parameter(
                          (b) =>
                              b
                                ..name = field.$name
                                ..named = true
                                ..type = refer(
                                  field.type.getDisplayString(withNullability: false).replaceAll('?', '') + '?',
                                ),
                        ),
                      ),
                    )
                    ..body =
                        refer(element.name)
                            .newInstance(
                              [],
                              Map.fromEntries(
                                element.props.map(
                                  (field) => MapEntry(
                                    field.$name,
                                    refer(field.$name).ifNullThen(refer('this.${field.$name}')),
                                  ),
                                ),
                              ),
                            )
                            .code,
            ),
          )
          ..methods.add(
            Method(
              (b) =>
                  b
                    ..name = 'scale'
                    ..returns = refer(element.name)
                    ..body =
                        refer(element.name)
                            .newInstance(
                              [],
                              Map.fromEntries(
                                element.props.map((field) {
                                  if (field.type.isDartCoreDouble) {
                                    final lowerName = field.$name.toLowerCase();
                                    var mapFunctionName = 'ScreenUtil().radius';
                                    if (lowerName.endsWith('_w')) {
                                      mapFunctionName = 'ScreenUtil().setWidth';
                                    } else if (lowerName.endsWith('_h')) {
                                      mapFunctionName = 'ScreenUtil().setHeight';
                                    } else if (lowerName.endsWith('_r')) {
                                      mapFunctionName = 'ScreenUtil().radius';
                                    } else if (lowerName.endsWith('_d')) {
                                      mapFunctionName = 'ScreenUtil().diameter';
                                    } else if (lowerName.endsWith('_sp')) {
                                      mapFunctionName = 'ScreenUtil().setSp';
                                    } else if (lowerName.endsWith('_dp')) {
                                      mapFunctionName = '';
                                    }
                                    if (mapFunctionName.isNotEmpty) {
                                      final mapFunction = refer(mapFunctionName);
                                      if (field.type.nullabilitySuffix != NullabilitySuffix.question) {
                                        return MapEntry(field.$name, mapFunction.call([refer(field.$name)]));
                                      } else {
                                        return MapEntry(
                                          field.$name,
                                          refer(field.$name)
                                              .equalTo(literalNull)
                                              .conditional(
                                                literalNull,
                                                mapFunction.call([refer(field.$name).nullChecked]),
                                              ),
                                        );
                                      }
                                    }
                                  }
                                  return MapEntry(field.$name, refer(field.$name));
                                }),
                              ),
                            )
                            .code,
            ),
          )
          ..methods.add(
            Method(
              (b) =>
                  b
                    ..returns = refer('List<Object?>')
                    ..type = MethodType.getter
                    ..name = '_\$props'
                    ..body =
                        literalList([
                          for (final FieldElement2 f in element.props)
                            if (f.name3 case final String name?) refer(name),
                        ]).code,
            ),
          ),
  );
}
