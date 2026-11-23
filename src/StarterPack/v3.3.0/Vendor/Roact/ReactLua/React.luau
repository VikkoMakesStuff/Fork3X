local module = require(script.Parent:WaitForChild('node_modules'):WaitForChild('.luau-aliases'):WaitForChild('@jsdotlua'):WaitForChild('react'))
export type Object = module.Object
export type Binding<T> = module.Binding<T>
export type BindingUpdater<T> = module.BindingUpdater<T>
export type LazyComponent<T, P> = module.LazyComponent<T, P>
export type StatelessFunctionalComponent<P> = module.StatelessFunctionalComponent<
	P
>
export type ComponentType<P> = module.ComponentType<P>
export type AbstractComponent<Config, Instance> = module.AbstractComponent<
	Config,
	Instance
>
export type ElementType = module.ElementType
export type Element<C> = module.Element<C>
export type Key = module.Key
export type Ref<ElementType> = module.Ref<ElementType>
export type Node = module.Node
export type Context<T> = module.Context<T>
export type ElementProps<C> = module.ElementProps<C>
export type ElementConfig<T> = module.ElementConfig<T>
export type ElementRef<C> = module.ElementRef<C>
export type ComponentClass<P> = module.ComponentClass<P>
export type PureComponent<Props, State = nil> = module.PureComponent<
	Props,
	State
>
export type ReactElement<Props = Object, ElementType = any> = module.ReactElement<
	Props,
	ElementType
>
export type ReactChild = module.ReactChild
export type FC<P> = module.FC<P>
export type ReactNode = module.ReactNode
export type React_AbstractComponent<Props, Instance> =
	module.React_AbstractComponent<Props, Instance>
export type React_FowardRefComponent<Props, Instance> =
	module.React_FowardRefComponent<Props, Instance>
export type React_MemoComponent<Config, T> = module.React_MemoComponent<
	Config,
	T
>
export type React_Component<Props, State> = module.React_Component<Props, State>
export type React_ComponentType<P> = module.React_ComponentType<P>
export type React_Context<T> = module.React_Context<T>
export type React_Element<ElementType> = module.React_Element<ElementType>
export type React_ElementType = module.React_ElementType
export type React_Node = module.React_Node
return module
