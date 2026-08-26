import { z } from 'zod';

export const registerBodySchema = z.object({
  // Ignored — the email is taken from the verified JWT, never from the body.
  // Optional so clients can stop sending it; still validated when present.
  email: z.string().email().optional(),
  supabaseId: z.string().uuid(),
});

export type RegisterBody = z.infer<typeof registerBodySchema>;
