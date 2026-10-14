/** Standard API envelope (see backend App\Http\Responses\ApiResponse). */
export interface ApiSuccess<T> {
  success: true
  message: string | null
  data: T
}

export interface ApiFailure {
  success: false
  message: string
  errors: Record<string, string[]> | null
}

/** Pulls `data` out of the success envelope. */
export function unwrap<T>(envelope: ApiSuccess<T>): T {
  return envelope.data
}
