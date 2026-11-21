// SPDX-License-Identifier: AGPL-3.0-or-later
import {OpenAPIGeneratorCatalog} from '@star/openapi/src/generator/OpenAPIGeneratorCatalog';
import {loadSchemas} from '@star/openapi/src/registry/SchemaLoader';
import type {SchemaRegistry} from '@star/openapi/src/registry/SchemaRegistry';

export async function loadSchemasIntoRegistry(basePath: string, schemaRegistry: SchemaRegistry): Promise<void> {
	for (const [name, schema] of OpenAPIGeneratorCatalog.builtInSchemas) {
		schemaRegistry.register(name, schema);
	}
	for (const [name, zodSchema] of await loadSchemas(basePath)) {
		schemaRegistry.registerZod(name, zodSchema);
	}
}
