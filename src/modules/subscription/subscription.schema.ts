import { z } from 'zod';

/**
 * RevenueCat webhook payload — deliberately lenient: only the fields
 * actually consumed are validated, the rest of the payload evolves freely on RevenueCat's side.
 */
export const revenueCatWebhookSchema = z.object({
  event: z.object({
    type: z.string().min(1),
    app_user_id: z.string().min(1),
    aliases: z.array(z.string()).optional(),
    product_id: z.string().nullish(),
    store: z.string().nullish(),
    environment: z.string().nullish(),
    expiration_at_ms: z.number().nullish(),
    event_timestamp_ms: z.number().nullish(),
  }),
});

export type RevenueCatWebhookBody = z.infer<typeof revenueCatWebhookSchema>;
