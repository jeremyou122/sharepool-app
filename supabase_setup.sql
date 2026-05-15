-- Sharepool Database Setup Script

-- 1. Create Posts table
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    intent TEXT NOT NULL,
    description TEXT NOT NULL,
    hidden_content TEXT,
    unlock_price INT DEFAULT 10,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    enterprise_name TEXT
);

-- 2. Create User Points table
CREATE TABLE IF NOT EXISTS public.user_points (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id),
    credits INT DEFAULT 1250,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create Unlocks table
CREATE TABLE IF NOT EXISTS public.user_unlocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    post_id UUID REFERENCES public.posts(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

-- 4. Trigger for automatic credits on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_points (user_id, credits)
  VALUES (new.id, 1250)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Enable RLS (Recommended for Supabase)
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_unlocks ENABLE ROW LEVEL SECURITY;

-- Basic Policies (Public read for posts, authenticated write)
CREATE POLICY "Public read posts" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Auth users can post" ON public.posts FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Policies for User Points (User can read own credits)
CREATE POLICY "Users can read own points" ON public.user_points FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can update points" ON public.user_points FOR UPDATE USING (auth.uid() = user_id);

-- Policies for Unlocks
CREATE POLICY "Users can read own unlocks" ON public.user_unlocks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create unlocks" ON public.user_unlocks FOR INSERT WITH CHECK (auth.uid() = user_id);
