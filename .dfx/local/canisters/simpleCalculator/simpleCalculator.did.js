export const idlFactory = ({ IDL }) => {
  return IDL.Service({
    'add' : IDL.Func([IDL.Int], [IDL.Int], []),
    'reset' : IDL.Func([], [IDL.Int], []),
    'sub' : IDL.Func([IDL.Int], [IDL.Int], []),
  });
};
export const init = ({ IDL }) => { return []; };
